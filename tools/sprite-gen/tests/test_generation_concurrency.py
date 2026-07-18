from __future__ import annotations

import base64
import json
import os
import shutil
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts"))

import serve_curation as server  # noqa: E402
from sprite_gen import extract as extractor  # noqa: E402


SAMPLE_RUN = ROOT.parent.parent / "assets" / "generated" / "sprites" / "cat_8way"


class GenerationConcurrencyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.run_dir = Path(self.temp.name) / "run"
        self.run_dir.mkdir()
        shutil.copy2(SAMPLE_RUN / "sprite-request.json", self.run_dir / "sprite-request.json")
        shutil.copy2(SAMPLE_RUN / "base-source.png", self.run_dir / "base-source.png")
        request_path = self.run_dir / "sprite-request.json"
        request = json.loads(request_path.read_text(encoding="utf-8"))
        for spec in request["states"].values():
            spec.pop("takes", None)
        request_path.write_text(json.dumps(request, ensure_ascii=False), encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_different_states_generate_in_parallel_without_lost_takes(self) -> None:
        active = 0
        max_active = 0
        active_lock = threading.Lock()

        def fake_generate(_provider, _prompt, out, **_kwargs):
            nonlocal active, max_active
            with active_lock:
                active += 1
                max_active = max(max_active, active)
            time.sleep(0.15)
            shutil.copy2(self.run_dir / "base-source.png", out)
            with active_lock:
                active -= 1
            return SimpleNamespace(provider="test")

        errors = []

        def run(state: str) -> None:
            try:
                server.generate_state_take(self.run_dir, {"state": state})
            except BaseException as exc:  # surface thread failures in the assertion
                errors.append(exc)

        with (
            mock.patch.object(server, "generate_image", side_effect=fake_generate),
            mock.patch.object(server, "_extract_state", return_value={"ok": True}),
            mock.patch.object(server, "_select_generated_phase"),
        ):
            threads = [
                threading.Thread(target=run, args=("down_idle",)),
                threading.Thread(target=run, args=("right_idle",)),
            ]
            for thread in threads:
                thread.start()
            for thread in threads:
                thread.join()

        self.assertEqual(errors, [])
        self.assertGreaterEqual(max_active, 2)
        request = json.loads((self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        self.assertEqual(request["states"]["down_idle"].get("takes") or [], [])
        self.assertEqual(request["states"]["right_idle"].get("takes") or [], [])
        self.assertTrue((self.run_dir / server.raw_rel(request, "down_idle")).is_file())
        self.assertTrue((self.run_dir / server.raw_rel(request, "right_idle")).is_file())

    def test_windows_publish_falls_back_to_guarded_copy_when_staging_rename_is_denied(self) -> None:
        staging = self.run_dir / ".frames.sg-staging"
        frames_final = self.run_dir / "frames"
        staging.mkdir()
        (staging / "frame.png").write_bytes(b"sprite-frame")
        original_rename = Path.rename

        def deny_staging_rename(path, target):
            if path == staging:
                raise PermissionError(5, "simulated Windows sharing violation", str(path))
            return original_rename(path, target)

        with (
            mock.patch.object(Path, "rename", new=deny_staging_rename),
            mock.patch.object(extractor.time, "sleep", return_value=None),
        ):
            extractor._publish_staging_dir(staging, frames_final)

        self.assertFalse(staging.exists())
        self.assertEqual((frames_final / "frame.png").read_bytes(), b"sprite-frame")

    def test_same_state_duplicate_is_rejected(self) -> None:
        entered = threading.Event()
        release = threading.Event()
        errors = []

        def fake_generate(_provider, _prompt, out, **_kwargs):
            entered.set()
            release.wait(2)
            shutil.copy2(self.run_dir / "base-source.png", out)
            return SimpleNamespace(provider="test")

        def first_request() -> None:
            try:
                server.generate_state_take(self.run_dir, {"state": "down_walk"})
            except BaseException as exc:
                errors.append(exc)

        with (
            mock.patch.object(server, "generate_image", side_effect=fake_generate),
            mock.patch.object(server, "_extract_state", return_value={"ok": True}),
            mock.patch.object(server, "_select_generated_phase"),
        ):
            thread = threading.Thread(target=first_request)
            thread.start()
            self.assertTrue(entered.wait(1))
            with self.assertRaisesRegex(RuntimeError, "already running for down_walk full section"):
                server.generate_state_take(self.run_dir, {"state": "down_walk"})
            release.set()
            thread.join()

        self.assertEqual(errors, [])

    def test_different_cards_in_same_state_generate_in_parallel(self) -> None:
        active = 0
        max_active = 0
        active_lock = threading.Lock()
        errors = []

        def fake_generate(_provider, _prompt, out, **_kwargs):
            nonlocal active, max_active
            with active_lock:
                active += 1
                max_active = max(max_active, active)
            time.sleep(0.15)
            shutil.copy2(self.run_dir / "base-source.png", out)
            with active_lock:
                active -= 1
            return SimpleNamespace(provider="test")

        def run(phase: int) -> None:
            try:
                server.generate_state_take(
                    self.run_dir, {"state": "down_walk", "phase": phase})
            except BaseException as exc:
                errors.append(exc)

        with (
            mock.patch.object(server, "generate_image", side_effect=fake_generate),
            mock.patch.object(server, "_extract_state", return_value={"ok": True}),
            mock.patch.object(server, "_select_generated_phase"),
        ):
            threads = [
                threading.Thread(target=run, args=(0,)),
                threading.Thread(target=run, args=(2,)),
            ]
            for thread in threads:
                thread.start()
            for thread in threads:
                thread.join()

        self.assertEqual(errors, [])
        self.assertGreaterEqual(max_active, 2)
        request = json.loads((self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        self.assertEqual(len(request["states"]["down_walk"]["takes"]), 1)
        self.assertTrue((self.run_dir / server.raw_rel(request, "down_walk")).is_file())

    def test_first_generation_publishes_primary_strip_before_extraction(self) -> None:
        observed = []

        def fake_generate(_provider, _prompt, out, **_kwargs):
            shutil.copy2(self.run_dir / "base-source.png", out)
            return SimpleNamespace(provider="test")

        def fake_extract(_run_dir, state):
            request = json.loads((self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
            observed.append({
                "primary": (self.run_dir / server.raw_rel(request, state)).is_file(),
                "takes": list(request["states"][state].get("takes") or []),
            })
            return {"ok": True}

        with (
            mock.patch.object(server, "generate_image", side_effect=fake_generate),
            mock.patch.object(server, "_extract_state", side_effect=fake_extract),
            mock.patch.object(server, "_select_generated_phase"),
        ):
            result = server.generate_state_take(self.run_dir, {"state": "down_idle"})

        self.assertTrue(result["publishedAsPrimary"])
        self.assertEqual(observed, [{"primary": True, "takes": []}])

    def test_run_snapshot_waits_for_request_and_manifest_commit(self) -> None:
        entered_snapshot = threading.Event()
        finished_snapshot = threading.Event()
        result = []

        def fake_build(_run_dir):
            entered_snapshot.set()
            return {"ok": True}

        def read_snapshot():
            result.append(server.build_run_state(self.run_dir))
            finished_snapshot.set()

        with mock.patch.object(server, "_build_run_state_impl", side_effect=fake_build):
            with server._generation_commit_lock:
                thread = threading.Thread(target=read_snapshot)
                thread.start()
                time.sleep(0.05)
                self.assertFalse(entered_snapshot.is_set())
                self.assertFalse(finished_snapshot.is_set())
            thread.join(1)

        self.assertTrue(entered_snapshot.is_set())
        self.assertTrue(finished_snapshot.is_set())
        self.assertEqual(result, [{"ok": True}])

    def test_run_snapshot_retries_transient_candidate_count_mismatch(self) -> None:
        mismatch = SystemExit(
            "corrupt frames manifest run: row 'custom_animation' has 12 frame(s), "
            "request expects 18"
        )
        with (
            mock.patch.object(
                server, "_build_run_state_impl", side_effect=[mismatch, {"ok": True}]
            ) as build,
            mock.patch.object(server, "_transient_generation_mismatch", return_value=True),
            mock.patch.object(server.time, "sleep"),
        ):
            result = server.build_run_state(self.run_dir)

        self.assertEqual(result, {"ok": True})
        self.assertEqual(build.call_count, 2)

    def test_run_snapshot_does_not_hide_permanent_manifest_corruption(self) -> None:
        mismatch = SystemExit(
            "corrupt frames manifest run: row 'custom_animation' has 12 frame(s), "
            "request expects 18"
        )
        with (
            mock.patch.object(server, "_build_run_state_impl", side_effect=mismatch),
            mock.patch.object(server, "_transient_generation_mismatch", return_value=False),
        ):
            with self.assertRaises(SystemExit):
                server.build_run_state(self.run_dir)

    def test_diagonal_direction_uses_the_longest_matching_prefix(self) -> None:
        request = json.loads((self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        request["directions"]["match_longest"] = True
        self.assertEqual(server.raw_rel(request, "down_right_idle"), "raw/down_right/idle.png")
        self.assertEqual(server.raw_rel(request, "down_left_walk"), "raw/down_left/walk.png")
        self.assertEqual(server.raw_rel(request, "up_right_idle"), "raw/up_right/idle.png")
        self.assertEqual(server.raw_rel(request, "up_left_walk"), "raw/up_left/walk.png")

    def test_legacy_run_keeps_its_published_direction_paths(self) -> None:
        request = json.loads((self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        request["directions"].pop("match_longest", None)
        self.assertEqual(server.raw_rel(request, "down_right_idle"), "raw/down/right_idle.png")

    def test_orphaned_generated_take_is_recovered_without_regeneration(self) -> None:
        request = json.loads((self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        orphan = self.run_dir / server.take_raw_rel(request, "down_idle", "studio-orphan")
        orphan.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(self.run_dir / "base-source.png", orphan)
        old = time.time() - 10
        os.utime(orphan, (old, old))

        with mock.patch.object(server, "_extract_state", return_value={"ok": True}):
            recovered = server.recover_orphan_generations(self.run_dir)

        primary = self.run_dir / server.raw_rel(request, "down_idle")
        self.assertEqual(recovered, ["down_idle"])
        self.assertTrue(primary.is_file())
        self.assertFalse(orphan.exists())

    def test_auto_generation_runs_missing_states_in_request_order(self) -> None:
        request_path = self.run_dir / "sprite-request.json"
        request = json.loads(request_path.read_text(encoding="utf-8"))
        request["states"] = {
            name: request["states"][name]
            for name in ("down_idle", "down_walk")
        }
        request_path.write_text(json.dumps(request, ensure_ascii=False), encoding="utf-8")

        # Existing sections are preserved; automatic generation fills only blank ones.
        existing_dir = self.run_dir / server.frames_dir_rel(request, "down_idle")
        existing_dir.mkdir(parents=True)
        shutil.copy2(self.run_dir / "base-source.png", existing_dir / "frame-0.png")
        calls = []

        def fake_state_generation(_run_dir, payload):
            calls.append(payload["state"])
            return {"ok": True, "poseTemplateUsed": True}

        skeleton = (self.run_dir, {
            "profileId": "saved-skeleton",
            "states": {"down_idle": {}, "down_walk": {}},
        })
        with (
            mock.patch.object(server, "_active_skeleton_profile", return_value=skeleton),
            mock.patch.object(server, "generate_state_take", side_effect=fake_state_generation),
        ):
            started = server.start_auto_generation(self.run_dir, {})
            deadline = time.monotonic() + 2
            status = server.auto_generation_status(self.run_dir)
            while status["status"] in ("queued", "running") and time.monotonic() < deadline:
                time.sleep(0.01)
                status = server.auto_generation_status(self.run_dir)

        self.assertEqual(started["states"], ["down_walk"])
        self.assertEqual(calls, ["down_walk"])
        self.assertEqual(status["status"], "completed")
        self.assertEqual(status["completed"], 1)
        self.assertTrue(status["results"][0]["poseTemplateUsed"])

    def test_auto_generation_progress_is_persisted_and_resumes_after_memory_loss(self) -> None:
        request_path = self.run_dir / "sprite-request.json"
        request = json.loads(request_path.read_text(encoding="utf-8"))
        request["states"] = {
            name: request["states"][name]
            for name in ("down_idle", "down_walk")
        }
        request_path.write_text(json.dumps(request, ensure_ascii=False), encoding="utf-8")
        calls = []

        def fake_state_generation(_run_dir, payload):
            calls.append(payload["state"])
            return {"ok": True, "poseTemplateUsed": True}

        persisted = {
            "id": "persisted-job",
            "status": "running",
            "total": 2,
            "completed": 1,
            "currentState": "down_walk",
            "currentIndex": 1,
            "states": ["down_idle", "down_walk"],
            "results": [{"state": "down_idle", "poseTemplateUsed": True}],
            "kind": "skeleton_generation",
            "startedAt": "2026-07-16T20:00:00+0900",
            "regenerateExisting": False,
        }
        server._atomic_json(server._auto_generation_path(self.run_dir), persisted)
        key = server._auto_generation_key(self.run_dir)
        with server._auto_generation_jobs_lock:
            server._auto_generation_jobs.pop(key, None)
            server._auto_generation_workers.discard(key)

        with mock.patch.object(
            server, "generate_state_take", side_effect=fake_state_generation
        ):
            restored = server.auto_generation_status(self.run_dir)
            deadline = time.monotonic() + 2
            status = restored
            while status["status"] in ("queued", "running") and time.monotonic() < deadline:
                time.sleep(0.01)
                status = server.auto_generation_status(self.run_dir)

        self.assertTrue(restored["resumed"])
        self.assertEqual(calls, ["down_walk"])
        self.assertEqual(status["status"], "completed")
        self.assertEqual(status["completed"], 2)
        saved = json.loads(
            server._auto_generation_path(self.run_dir).read_text(encoding="utf-8"))
        self.assertEqual(saved["status"], "completed")
        self.assertEqual(saved["completed"], 2)

    def test_auto_generation_retries_chroma_contaminated_take_once(self) -> None:
        request_path = self.run_dir / "sprite-request.json"
        request = json.loads(request_path.read_text(encoding="utf-8"))
        request["states"] = {"down_idle": request["states"]["down_idle"]}
        request_path.write_text(json.dumps(request, ensure_ascii=False), encoding="utf-8")
        calls = []

        def fake_state_generation(_run_dir, payload):
            calls.append(payload)
            if len(calls) == 1:
                raise RuntimeError("down_idle: frame 02 has 271 chroma-adjacent pixels")
            return {"ok": True, "poseTemplateUsed": False}

        skeleton = (self.run_dir, {
            "profileId": "saved-skeleton",
            "states": {"down_idle": {}},
        })
        with (
            mock.patch.object(server, "_active_skeleton_profile", return_value=skeleton),
            mock.patch.object(server, "generate_state_take", side_effect=fake_state_generation),
        ):
            server.start_auto_generation(self.run_dir, {})
            deadline = time.monotonic() + 2
            status = server.auto_generation_status(self.run_dir)
            while status["status"] in ("queued", "running") and time.monotonic() < deadline:
                time.sleep(0.01)
                status = server.auto_generation_status(self.run_dir)

        self.assertEqual(status["status"], "completed")
        self.assertEqual(len(calls), 2)
        self.assertNotIn("extraPrompt", calls[0])
        self.assertIn("foreground pixels blended", calls[1]["extraPrompt"])
        self.assertTrue(status["results"][0]["qualityRetry"])

    def test_base_character_can_regenerate_from_saved_upload(self) -> None:
        uploaded = base64.b64encode((self.run_dir / "base-source.png").read_bytes()).decode("ascii")
        prompts = []

        def fake_generate(_provider, prompt, out, **kwargs):
            prompts.append(prompt)
            shutil.copy2(kwargs["refs"][0], out)
            return SimpleNamespace(provider="test")

        with mock.patch.object(server, "generate_image", side_effect=fake_generate):
            first = server.create_base_character(self.run_dir, {
                "dataUrl": f"data:image/png;base64,{uploaded}",
                "prompt": "dress this character as a chef",
            })
            second = server.create_base_character(self.run_dir, {
                "dataUrl": None,
                "prompt": "dress this character as a medic",
            })

        self.assertTrue(first["generated"])
        self.assertFalse(first["referenceReused"])
        self.assertTrue(second["generated"])
        self.assertTrue(second["referenceReused"])
        self.assertTrue((self.run_dir / "base-reference.png").is_file())
        self.assertIn("chef", prompts[0])
        self.assertIn("medic", prompts[1])

    def test_custom_animation_adds_and_generates_exactly_one_section(self) -> None:
        created = server.create_custom_animation(self.run_dir, {
            "name": "칼 찌르기",
            "frames": 6,
            "prompt": "칼을 앞으로 빠르게 찌른 뒤 경계 자세로 돌아온다",
        })

        self.assertEqual(len(created["states"]), 1)
        state = created["state"]
        request = json.loads((self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        self.assertEqual(request["states"][state]["frames"], 6)
        self.assertEqual(request["states"][state]["custom_animation"]["name"], "칼 찌르기")
        prompt = server._generation_prompt(request, state, "", None)
        self.assertIn("exactly 6 panels", prompt)
        self.assertIn("칼을 앞으로 빠르게 찌른 뒤", prompt)

        def fake_generate(_provider, _prompt, out, **_kwargs):
            shutil.copy2(self.run_dir / "base-source.png", out)
            return SimpleNamespace(provider="test")

        with (
            mock.patch.object(server, "generate_image", side_effect=fake_generate),
            mock.patch.object(server, "_extract_state", return_value={"ok": True}),
            mock.patch.object(server, "_select_generated_phase"),
        ):
            result = server.generate_state_take(self.run_dir, {"state": state})
        self.assertEqual(len(result["generatedIndices"]), 6)

    def test_directional_custom_animation_uses_requested_screen_direction(self) -> None:
        request = json.loads((self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        request["states"]["up_right_action"] = {
            "frames": 4,
            "fps": 8,
            "loop": True,
            "action": "swing a sword",
            "custom_animation": {
                "name": "swing",
                "prompt": "swing a sword",
                "directional_skeleton": True,
            },
        }
        prompt = server._generation_prompt(request, "up_right_action", "", None)

        self.assertIn("facing the upper-right corner of the image", prompt)
        self.assertNotIn("same canonical facing direction", prompt)
        self.assertIn("Do not add motion trails, slash arcs", prompt)
        self.assertIn("colors are reserved exclusively for the removable background", prompt)

    def test_notifications_are_persistent_and_readable(self) -> None:
        first = server._add_notification(self.run_dir, "state_generated", state="down_idle")
        server._add_notification(self.run_dir, "phase_generated", state="down_walk", phase=2)
        listed = server.list_notifications(self.run_dir)
        self.assertEqual(listed["unread"], 2)
        self.assertEqual(listed["notifications"][0]["phase"], 2)
        server.mark_notifications_read(self.run_dir, {"id": first["id"]})
        self.assertEqual(server.list_notifications(self.run_dir)["unread"], 1)
        server.mark_notifications_read(self.run_dir, {"all": True})
        self.assertEqual(server.list_notifications(self.run_dir)["unread"], 0)


if __name__ == "__main__":
    unittest.main()

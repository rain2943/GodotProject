from __future__ import annotations

import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts"))

import serve_curation as server  # noqa: E402


SAMPLE_RUN = ROOT.parent.parent / "assets" / "generated" / "sprites" / "cat_8way"


class SkeletonProfileTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.studio_root = Path(self.temp.name) / "sprites"
        self.run_dir = self.studio_root / "source-character"
        self.run_dir.mkdir(parents=True)

        request = json.loads((SAMPLE_RUN / "sprite-request.json").read_text(encoding="utf-8"))
        kept_states = {name: request["states"][name] for name in ("down_idle", "down_walk")}
        for spec in kept_states.values():
            spec.pop("takes", None)
        request["states"] = kept_states
        request["character"]["id"] = "source-character"
        (self.run_dir / "sprite-request.json").write_text(
            json.dumps(request, ensure_ascii=False), encoding="utf-8")
        shutil.copy2(SAMPLE_RUN / "base-source.png", self.run_dir / "base-source.png")

        source_manifest = json.loads(
            (SAMPLE_RUN / "frames" / "frames-manifest.json").read_text(encoding="utf-8"))
        rows = []
        for source_row in source_manifest["rows"]:
            state = source_row.get("state")
            if state not in kept_states:
                continue
            row = dict(source_row)
            row["frames"] = 4
            row["files"] = list(source_row["files"][:4])
            if isinstance(source_row.get("frame_records"), list):
                row["frame_records"] = list(source_row["frame_records"][:4])
            rows.append(row)
            for rel in row["files"]:
                target = self.run_dir / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(SAMPLE_RUN / rel, target)
        source_manifest["rows"] = rows
        source_manifest["run_dir"] = str(self.run_dir)
        manifest_path = self.run_dir / "frames" / "frames-manifest.json"
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text(json.dumps(source_manifest), encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_saved_profile_is_shared_and_keeps_four_pose_phases(self) -> None:
        result = server.save_skeleton_profile(self.run_dir)

        self.assertTrue(result["ok"])
        self.assertEqual(result["stateCount"], 2)
        profile_dir, metadata = server._active_skeleton_profile(self.run_dir)
        self.assertEqual(set(metadata["states"]), {"down_idle", "down_walk"})

        for state, entry in metadata["states"].items():
            strip_path = profile_dir / entry["strip"]
            self.assertTrue(strip_path.is_file())
            self.assertEqual(len(entry["phases"]), 4)
            with Image.open(strip_path) as strip:
                self.assertEqual(strip.size, (1024, 256))
            for rel in entry["phases"]:
                self.assertTrue((profile_dir / rel).is_file())

        sibling_run = self.studio_root / "new-character"
        targeted = server._skeleton_generation_refs(sibling_run, "down_walk", 2)
        self.assertEqual(len(targeted), 2)
        self.assertEqual(targeted[0].name, "frame-3.png")
        self.assertEqual(targeted[1].name, "down_walk.png")
        self.assertEqual(
            len(server._skeleton_generation_refs(sibling_run, "down_walk", None)), 1)

    def test_pose_prompt_separates_identity_from_skeleton(self) -> None:
        request = json.loads((self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        prompt = server._generation_prompt(request, "down_walk", "", 2, pose_template=True)

        self.assertIn("first attached image is the ONLY identity", prompt)
        self.assertIn("second attached image is the exact target-frame pose guide", prompt)
        self.assertIn("third is the complete four-frame pose strip", prompt)
        self.assertIn("left/right foot crossing", prompt)

    def test_direction_anchor_precedes_pose_guide(self) -> None:
        request = json.loads((self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        anchor = server._accepted_direction_anchor_ref(
            self.run_dir, request, "down_walk")
        pose = self.run_dir / "pose-guide.png"
        Image.new("RGBA", (32, 32), (120, 120, 120, 255)).save(pose)

        self.assertIsNotNone(anchor)
        refs = server._generation_refs(
            self.run_dir, request, "down_walk", [pose], anchor)
        self.assertEqual(refs[0], self.run_dir / "base-source.png")
        self.assertEqual(refs[1], anchor)
        self.assertEqual(refs[2], pose)

    def test_up_right_prompt_locks_viewer_screen_axis(self) -> None:
        request = json.loads((SAMPLE_RUN / "sprite-request.json").read_text(encoding="utf-8"))
        prompt = server._generation_prompt(
            request, "up_right_walk", "", 2,
            pose_template=True, direction_anchor=True,
        )

        self.assertIn("upper-right corner of the image", prompt)
        self.assertIn("RIGHT means the right-hand edge", prompt)
        self.assertIn("Never mirror the pose to face screen-left", prompt)
        self.assertIn("second attached image is an accepted sprite", prompt)
        self.assertIn("third attached image is the exact target-frame pose guide", prompt)
        self.assertIn("fourth is the complete four-frame pose strip", prompt)

    def test_unchecked_section_is_excluded_from_shared_skeleton(self) -> None:
        payload = {
            "version": 1,
            "kind": "sprite-gen-curation",
            "states": {
                "down_idle": {"selected": [0, 1, 2, 3], "skeleton_included": True},
                "down_walk": {"selected": [0, 1, 2, 3], "skeleton_included": False},
            },
        }
        server.write_curation_atomic(self.run_dir, payload)
        result = server.save_skeleton_profile(self.run_dir)
        _profile_dir, metadata = server._active_skeleton_profile(self.run_dir)

        self.assertEqual(result["stateCount"], 1)
        self.assertEqual(set(metadata["states"]), {"down_idle"})
        self.assertEqual(set(metadata["stateSpecs"]), {"down_idle"})

    def test_named_profile_is_listed_and_can_be_selected_for_a_new_character(self) -> None:
        saved = server.save_skeleton_profile(self.run_dir, "8방향 이동")
        profiles = server.list_skeleton_profiles(self.run_dir)

        self.assertEqual(len(profiles), 1)
        self.assertEqual(profiles[0]["profileId"], saved["profileId"])
        self.assertEqual(profiles[0]["name"], "8방향 이동")
        self.assertTrue(profiles[0]["selected"])

        created = server.create_studio_character(
            self.studio_root,
            self.run_dir,
            "female cat",
            {"mode": "existing", "profileId": saved["profileId"]},
        )
        request = json.loads(
            (self.studio_root / created["path"] / "sprite-request.json").read_text(encoding="utf-8"))
        self.assertEqual(set(request["states"]), {"down_idle", "down_walk"})
        self.assertEqual(request["studio_skeleton"]["profileId"], saved["profileId"])
        self.assertEqual(request["studio_skeleton"]["name"], "8방향 이동")

    def test_new_skeleton_character_creates_one_animation_in_eight_directions(self) -> None:
        created = server.create_studio_character(
            self.studio_root,
            self.run_dir,
            "rolling cat",
            {
                "mode": "new",
                "name": "구르기",
                "frames": 6,
                "prompt": "앞으로 한 바퀴 구른 뒤 시작 자세로 돌아온다",
            },
        )
        run_dir = self.studio_root / created["path"]
        request = json.loads((run_dir / "sprite-request.json").read_text(encoding="utf-8"))

        self.assertEqual(len(request["states"]), 8)
        self.assertEqual(
            set(request["states"]),
            {f"{direction}_action" for direction in server._DIRECTION_VIEW},
        )
        self.assertTrue(all(spec["frames"] == 6 for spec in request["states"].values()))
        self.assertTrue(all(spec["action"].startswith("앞으로") for spec in request["states"].values()))
        self.assertEqual(request["studio_skeleton"]["mode"], "new")
        self.assertIsNone(server._active_skeleton_profile(run_dir))

    def test_directionless_character_has_no_precreated_animation_sections(self) -> None:
        created = server.create_studio_character(
            self.studio_root,
            self.run_dir,
            "portrait-only cat",
            {"mode": "none"},
        )
        run_dir = self.studio_root / created["path"]
        request = json.loads((run_dir / "sprite-request.json").read_text(encoding="utf-8"))

        self.assertEqual(request["states"], {})
        self.assertNotIn("directions", request)
        self.assertEqual(request["studio_skeleton"], {"mode": "none"})
        self.assertIsNone(server._active_skeleton_profile(run_dir))

        Image.new("RGBA", (32, 32), (80, 60, 40, 255)).save(run_dir / "base-source.png")
        animation = server.create_custom_animation(run_dir, {
            "name": "blink",
            "frames": 3,
            "prompt": "blink once and return to the neutral pose",
        })
        request = json.loads((run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        self.assertEqual(animation["states"], ["custom_blink"])
        self.assertEqual(set(request["states"]), {"custom_blink"})
        self.assertEqual(request["states"]["custom_blink"]["frames"], 3)
        self.assertNotIn("directions", request)

    def test_character_list_has_thumbnail_and_deletes_non_template_character(self) -> None:
        created = server.create_studio_character(
            self.studio_root,
            self.run_dir,
            "female cat",
        )
        created_dir = self.studio_root / created["path"]
        Image.new("RGBA", (32, 32), (20, 30, 40, 255)).save(
            created_dir / "base-source.png")

        listed = server.studio_character_list(
            self.studio_root, self.run_dir, created_dir)
        template = next(item for item in listed if item["id"] == "source-character")
        character = next(item for item in listed if item["id"] == created["id"])
        self.assertFalse(template["deletable"])
        self.assertTrue(character["deletable"])
        self.assertEqual(
            character["baseUrl"],
            f"/api/characters/base?characterId={created['id']}",
        )

        deleted = server.delete_studio_character(
            self.studio_root, self.run_dir, created_dir, created["id"])
        self.assertTrue(deleted["ok"])
        self.assertEqual(deleted["activeId"], "source-character")
        self.assertFalse(created_dir.exists())
        remaining = server.load_studio_registry(self.studio_root, self.run_dir)
        self.assertEqual(
            [item["id"] for item in remaining["characters"]],
            ["source-character"],
        )

        with self.assertRaisesRegex(ValueError, "startup template"):
            server.delete_studio_character(
                self.studio_root, self.run_dir, self.run_dir, "source-character")

    def test_deleting_active_duplicate_skeleton_reassigns_to_compatible_version(self) -> None:
        first = server.save_skeleton_profile(self.run_dir, "8방향 이동")
        request_path = self.run_dir / "sprite-request.json"
        request = json.loads(request_path.read_text(encoding="utf-8"))
        request["studio_skeleton"] = {"mode": "new", "name": "8방향 이동"}
        request_path.write_text(json.dumps(request, ensure_ascii=False), encoding="utf-8")
        second = server.save_skeleton_profile(self.run_dir, "8방향 이동")

        before = server.list_skeleton_profiles(self.run_dir)
        self.assertEqual(len(before), 2)
        active = next(profile for profile in before if profile["selected"])
        self.assertEqual(active["profileId"], second["profileId"])
        self.assertTrue(active["deletable"])
        self.assertEqual(active["usedBy"], ["source-character"])

        result = server.delete_skeleton_profile(self.run_dir, second["profileId"])
        self.assertEqual(result["fallbackId"], first["profileId"])
        self.assertEqual(result["reassignedCharacters"], ["source-character"])
        self.assertFalse(
            (self.studio_root / ".sprite-skeleton" / "profiles" / second["profileId"]).exists())

        request = json.loads(
            (self.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
        self.assertEqual(request["studio_skeleton"]["profileId"], first["profileId"])
        remaining = server.list_skeleton_profiles(self.run_dir)
        self.assertEqual(len(remaining), 1)
        self.assertTrue(remaining[0]["selected"])
        self.assertFalse(remaining[0]["deletable"])

    def test_skeleton_update_replaces_prior_compatible_version(self) -> None:
        first = server.save_skeleton_profile(self.run_dir, "8방향 이동")
        second = server.save_skeleton_profile(self.run_dir, "8방향 이동")

        self.assertEqual(second["replacedProfileId"], first["profileId"])
        self.assertFalse(
            (self.studio_root / ".sprite-skeleton" / "profiles" / first["profileId"]).exists())
        profiles = server.list_skeleton_profiles(self.run_dir)
        self.assertEqual([profile["profileId"] for profile in profiles], [second["profileId"]])

    def test_only_in_use_skeleton_cannot_be_deleted(self) -> None:
        saved = server.save_skeleton_profile(self.run_dir, "8방향 이동")

        with self.assertRaisesRegex(ValueError, "used by source-character"):
            server.delete_skeleton_profile(self.run_dir, saved["profileId"])
        self.assertIsNotNone(server._skeleton_profile_by_id(self.run_dir, saved["profileId"]))

    def test_character_list_reports_resolved_skeleton_for_legacy_character(self) -> None:
        saved = server.save_skeleton_profile(self.run_dir, "8방향 이동")
        request_path = self.run_dir / "sprite-request.json"
        request = json.loads(request_path.read_text(encoding="utf-8"))
        request.pop("studio_skeleton", None)
        request_path.write_text(json.dumps(request, ensure_ascii=False), encoding="utf-8")

        character = server.studio_character_list(
            self.studio_root, self.run_dir, self.run_dir)[0]
        self.assertEqual(character["skeleton"]["profileId"], saved["profileId"])
        self.assertEqual(character["skeleton"]["name"], "8방향 이동")


if __name__ == "__main__":
    unittest.main()

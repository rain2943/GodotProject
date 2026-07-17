# GodotProject

Minimal Godot 4 project with automatic Windows and Web exports.

## Local development

1. Install Godot 4.5.1 or a compatible Godot 4 release.
2. Open this folder in Godot.
3. Run the project with F6/F5.

## Godot MCP

The Godot MCP editor plugin is included in `addons/godot_mcp` and enabled for this project.
Codex should register the local server with:

```powershell
codex mcp add godot -- cmd /c npx -y godot-mcp-server
```

Restart Codex after registering the server. With this project open in Godot, the editor toolbar
shows the MCP connection state. Runtime inspection and screenshots are enabled for debug runs and
disabled in release exports.

## Automatic build

Pushing to `main` starts `.github/workflows/build.yml`.

The workflow:

- validates the project in headless mode;
- exports a Windows build;
- exports a Web build;
- stores both builds as workflow artifacts;
- deploys the Web build to GitHub Pages.

After enabling GitHub Pages with `GitHub Actions` as the source in repository settings, the workflow will publish the phone-test URL after each successful push.

## Sprite generation pipeline

The project vendors a pinned snapshot of [`aldegad/sprite-gen`](https://github.com/aldegad/sprite-gen) under `tools/sprite-gen`. It converts a base character image and per-state image-generation rows into transparent frames, QA previews, a runtime atlas, and `manifest.json` frame rectangles.

On Windows, prepare a run first:

```powershell
.\tools\run_sprite_pipeline.ps1 -CharacterId survivor -BaseImage assets\characters\survivor_base.png -Description "survivor with a rifle" -PrepareOnly -Force
```

Place one generated row PNG per prompt under `assets\generated\sprites\survivor\raw\`, then finish the deterministic stages:

```powershell
.\tools\run_sprite_pipeline.ps1 -CharacterId survivor -RunDir assets\generated\sprites\survivor -SkipPrepare -OpenCuration
```

To let the upstream provider adapter create each row, choose `-Provider codex` or `-Provider grok` (the corresponding CLI/authentication must already be available):

```powershell
.\tools\run_sprite_pipeline.ps1 -CharacterId survivor -BaseImage assets\characters\survivor_base.png -Provider codex -OpenCuration
```

The default `-Provider none` mode is deterministic: put row PNGs under the run's `raw` folder, then the pipeline runs extraction, preview, atlas composition, inspection, and scoring without making an external generation call. The final runtime files are written to `assets/generated/sprites/<character-id>/`.

For a clean machine, run `.\tools\setup_sprite_pipeline.ps1` once. A runtime bridge is available at `scripts/sprite_gen_atlas.gd`; call `SpriteGenAtlas.build_sprite_frames("res://assets/generated/sprites/<id>/sprite-sheet-alpha.png", "res://assets/generated/sprites/<id>/manifest.json")` when wiring a generated atlas into an `AnimatedSprite3D`.

### Cat reference starter

The supplied cat sheet is preserved as `assets/generated/sources/cat_reference_sheet.png` and the matching 8-direction/4-frame request is `tools/requests/cat_8way_walk.json`. The sheet is a style reference, not a valid `base-image`: first create a clean single-pose `cat_base.png` (one full-body cat on a flat magenta background), then run:

```powershell
.\tools\run_sprite_pipeline.ps1 `
  -CharacterId cat `
  -BaseImage assets\generated\sources\cat_base.png `
  -RequestJson tools\requests\cat_8way_walk.json `
  -Provider codex `
  -OpenCuration `
  -Force
```

This generates the eight directional idle anchors and walking rows, then writes the atlas and runtime manifest under `assets\generated\sprites\cat\`.

The curated game-facing walk-only asset is already built at `assets\generated\sprites\cat_8way\walk-atlas.png` with `walk-manifest.json`. It is an 8-row × 4-column atlas in the order `down, down_right, right, up_right, up, up_left, left, down_left`; each row follows `left_forward → feet_together → right_forward → feet_together`.

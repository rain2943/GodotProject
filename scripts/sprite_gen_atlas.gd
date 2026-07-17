class_name SpriteGenAtlas
extends RefCounted

## Runtime bridge for an atlas produced by tools/run_sprite_pipeline.ps1.
## The generated manifest is the source of truth for frame rectangles; this
## loader never guesses a grid from the texture dimensions.

static func build_sprite_frames(atlas_path: String, manifest_path: String) -> SpriteFrames:
	var atlas_texture := load(atlas_path) as Texture2D
	if atlas_texture == null:
		push_error("SpriteGenAtlas: could not load atlas: %s" % atlas_path)
		return null
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		push_error("SpriteGenAtlas: could not read manifest: %s" % manifest_path)
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("SpriteGenAtlas: manifest is not a JSON object")
		return null
	var layout: Dictionary = parsed.get("frame_layout", {})
	var rows: Dictionary = layout.get("rows", {})
	var animation_meta: Dictionary = parsed.get("animation", {}).get("rows", {})
	var result := SpriteFrames.new()
	result.remove_animation("default")

	for state in rows.keys():
		var state_name := str(state)
		var frame_rects: Array = rows[state]
		var meta: Dictionary = animation_meta.get(state_name, {})
		var animation_name := state_name.replace("/", "_")
		result.add_animation(animation_name)
		result.set_animation_loop(animation_name, bool(meta.get("loop", true)))
		result.set_animation_speed(animation_name, float(meta.get("fps", 8.0)))
		for rect_data in frame_rects:
			var rect := Rect2(
				float(rect_data.get("x", 0)),
				float(rect_data.get("y", 0)),
				float(rect_data.get("w", layout.get("cellWidth", 1))),
				float(rect_data.get("h", layout.get("cellHeight", 1)))
			)
			var frame := AtlasTexture.new()
			frame.atlas = atlas_texture
			frame.region = rect
			result.add_frame(animation_name, frame)
	return result

class_name ResidentPortraitCatalog
extends RefCounted

const PORTRAIT_SIZE := 72
const FACE_REGION := Rect2i(48, 5, 160, 160)
const SOURCE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/characters/worker_cat/down_idle-frame-0.png"),
	preload("res://assets/characters/worker_cat/down_idle-frame-1.png"),
	preload("res://assets/characters/worker_cat/down_idle-frame-2.png"),
	preload("res://assets/characters/worker_cat/down_idle-frame-3.png"),
	preload("res://assets/characters/worker_cat/down_right_idle-frame-0.png"),
]

static var portrait_cache: Dictionary = {}


static func get_portrait(portrait_index: int) -> Texture2D:
	var safe_index := posmod(portrait_index, SOURCE_TEXTURES.size())
	if portrait_cache.has(safe_index):
		return portrait_cache[safe_index] as Texture2D
	var source_image := SOURCE_TEXTURES[safe_index].get_image()
	if source_image == null or source_image.is_empty():
		return SOURCE_TEXTURES[safe_index]
	var face_image := source_image.get_region(FACE_REGION)
	face_image.resize(PORTRAIT_SIZE, PORTRAIT_SIZE, Image.INTERPOLATE_NEAREST)
	var portrait := ImageTexture.create_from_image(face_image)
	portrait_cache[safe_index] = portrait
	return portrait

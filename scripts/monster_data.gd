class_name MonsterData
extends RefCounted

const MAX_LEVEL_INDEX: int = 14
const SPAWN_POOL_SIZE: int = 5

const EARLY_GAME_DURATION := 30.0
const TUTORIAL_DROPS := 3
const MID_GAME_DURATION := 60.0
const JUNK_UNLOCK_LEVEL_INDEX := 9
const JUNK_CHANCE := 0.10

const TRASH_SPRITE := "res://assets/Sprites/Trash.png"
const BOMB_SPRITE := "res://assets/Sprites/Bomb.png"

const SIZE_TRASH := 50.0
const SIZE_BOMB := 55.0

const LEVEL_SIZES: Array[float] = [
	60.0, 68.0, 78.0, 89.0, 95.0, 100.0, 103.0, 121.0, 141.0,
	163.0, 187.0, 213.0, 241.0, 271.0, 303.0,
]

const REFERENCE_RADIUS := 16.0

const SPRITE_PATHS: Array[String] = [
	"res://assets/Sprites/Monster_1.png",
	"res://assets/Sprites/Monster_2.png",
	"res://assets/Sprites/Monster_3.png",
	"res://assets/Sprites/Monster_4.png",
	"res://assets/Sprites/Monster_5.png",
	"res://assets/Sprites/Monster_6.png",
	"res://assets/Sprites/Monster_7.png",
	"res://assets/Sprites/Monster_8.png",
	"res://assets/Sprites/Monster_9.png",
	"res://assets/Sprites/Monster_10.png",
	"res://assets/Sprites/Monster_11.png",
	"res://assets/Sprites/Monster_12.png",
	"res://assets/Sprites/Monster_13.png",
	"res://assets/Sprites/Monster_14.png",
	"res://assets/Sprites/Monster_15.png",
]

static var _texture_cache: Dictionary = {}
static var LEVELS: Array[Dictionary] = _build_levels()


static func _build_levels() -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	for i in range(MAX_LEVEL_INDEX + 1):
		var level_num := i + 1
		var diameter := LEVEL_SIZES[i]
		var radius := diameter * 0.5
		var texture := _load_trimmed_texture(SPRITE_PATHS[i])
		var mass := (radius / REFERENCE_RADIUS) ** 2
		levels.append({
			"id": level_num,
			"name": "%02d" % level_num,
			"level": level_num,
			"diameter": diameter,
			"radius": radius, # Абсолютно фиксированный радиус
			"mass": mass,
			"score": 10 * (2 ** i),
			"sprite": texture,
			"scale": get_sprite_scale(texture, diameter), # Возвращает Vector2
		})
	return levels


static func _load_trimmed_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]

	var tex: Texture2D = load(path)
	if tex == null:
		return null

	var image := tex.get_image()
	if image.is_empty():
		_texture_cache[path] = tex
		return tex

	var crop_rect := _get_opaque_rect(image)
	if crop_rect.size.x > 0 and crop_rect.size.y > 0 and crop_rect.size != image.get_size():
		image = image.get_region(crop_rect)

	var trimmed := ImageTexture.create_from_image(image)
	_texture_cache[path] = trimmed
	return trimmed


static func _get_opaque_rect(image: Image) -> Rect2i:
	var width := image.get_width()
	var height := image.get_height()
	if width == 0 or height == 0:
		return Rect2i()

	var min_x := width
	var min_y := height
	var max_x := -1
	var max_y := -1

	for y in height:
		for x in width:
			if image.get_pixel(x, y).a > 0.01:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)

	if max_x < min_x:
		return Rect2i(0, 0, width, height)

	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


static func _load_texture(path: String) -> Texture2D:
	return _load_trimmed_texture(path)


static func get_sprite_scale(texture: Texture2D, target_diameter: float) -> Vector2:
	if texture == null:
		return Vector2.ONE
	var tex_size := texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Vector2.ONE
	
	# Рассчитываем независимый масштаб по X и Y, 
	# чтобы растянуть/сжать любую неквадратную картинку в точный круг/квадрат
	return Vector2(
		target_diameter / tex_size.x,
		target_diameter / tex_size.y
	)


static func get_level_data(level_index: int) -> Dictionary:
	var idx := clampi(level_index, 0, MAX_LEVEL_INDEX)
	return LEVELS[idx]


static func can_merge(level_index: int) -> bool:
	return level_index < MAX_LEVEL_INDEX


static func get_spawn_cooldown(round_time: float) -> float:
	if round_time < EARLY_GAME_DURATION:
		return 0.45
	if round_time < MID_GAME_DURATION:
		return 0.38
	return 0.30


static func roll_spawn_entry(
	round_time: float,
	drops_count: int,
	highest_level_index: int
) -> SpawnEntry:
	if drops_count < TUTORIAL_DROPS:
		return SpawnEntry.normal(0)

	if round_time < EARLY_GAME_DURATION:
		return SpawnEntry.normal(randi() % 2)

	if highest_level_index >= JUNK_UNLOCK_LEVEL_INDEX and randf() < JUNK_CHANCE:
		return SpawnEntry.junk()

	if round_time < MID_GAME_DURATION:
		return SpawnEntry.normal(randi() % 3)

	return SpawnEntry.normal(randi() % SPAWN_POOL_SIZE)


static func get_sprite_for_entry(entry: SpawnEntry) -> Texture2D:
	match entry.kind:
		SpawnEntry.Kind.JUNK:
			return _load_texture(TRASH_SPRITE)
		SpawnEntry.Kind.BOMB:
			return _load_texture(BOMB_SPRITE)
		_:
			return get_level_data(entry.level_index)["sprite"]


static func get_visual_for_entry(entry: SpawnEntry) -> Dictionary:
	match entry.kind:
		SpawnEntry.Kind.JUNK:
			var trash_tex := _load_trimmed_texture(TRASH_SPRITE)
			var diameter := SIZE_TRASH
			var radius := diameter * 0.5
			var base := get_level_data(0)
			return {
				"diameter": diameter,
				"radius": radius,
				"mass": base["mass"] * 0.9,
				"sprite": trash_tex,
				"scale": get_sprite_scale(trash_tex, diameter),
			}
		SpawnEntry.Kind.BOMB:
			var bomb_tex := _load_trimmed_texture(BOMB_SPRITE)
			var bomb_diameter := SIZE_BOMB
			return {
				"diameter": bomb_diameter,
				"radius": bomb_diameter * 0.5,
				"mass": 1.2,
				"sprite": bomb_tex,
				"scale": get_sprite_scale(bomb_tex, bomb_diameter),
			}
		_:
			return get_level_data(entry.level_index)

class_name MonsterData
extends RefCounted

## 15-level merge chain: 01 + 01 → 02, …, 14 + 14 → 15.

const MAX_LEVEL_INDEX: int = 14
const SPAWN_POOL_SIZE: int = 5

const _COLORS: Array[Color] = [
	Color("#FF6B6B"),
	Color("#FFA94D"),
	Color("#FFD43B"),
	Color("#69DB7C"),
	Color("#4DABF7"),
	Color("#9775FA"),
	Color("#F06595"),
	Color("#20C997"),
	Color("#FD7E14"),
	Color("#51CF66"),
	Color("#339AF0"),
	Color("#CC5DE8"),
	Color("#FF922B"),
	Color("#37B24D"),
	Color("#E03131"),
]

static var LEVELS: Array[Dictionary] = _build_levels()


static func _build_levels() -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	for i in range(MAX_LEVEL_INDEX + 1):
		var level_num := i + 1
		var radius := 18.0 + (75.0 - 18.0) * float(i) / float(MAX_LEVEL_INDEX)
		var mass := (radius / 18.0) ** 2
		levels.append({
			"id": level_num,
			"name": "%02d" % level_num,
			"level": level_num,
			"radius": radius,
			"mass": mass,
			"score": 10 * (2 ** i),
			"color": _COLORS[i],
		})
	return levels


static func get_level_data(level_index: int) -> Dictionary:
	var idx := clampi(level_index, 0, MAX_LEVEL_INDEX)
	return LEVELS[idx]


static func can_merge(level_index: int) -> bool:
	return level_index < MAX_LEVEL_INDEX


static func get_spawn_pool() -> Array[int]:
	var pool: Array[int] = []
	for i in range(SPAWN_POOL_SIZE):
		pool.append(i)
	return pool

class_name Monster
extends RigidBody2D

signal merged(new_level: int, position: Vector2, score_gained: int)
signal exploded(position: Vector2, score_gained: int)
signal junk_destroyed(position: Vector2)

@export var level: int = 0
@export var kind: SpawnEntry.Kind = SpawnEntry.Kind.NORMAL

var is_merging: bool = false
var is_exploding: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

static var _circle_textures: Dictionary = {}


func _ready() -> void:
	add_to_group("monsters")
	_apply_stats()
	body_entered.connect(_on_body_entered)


func get_level() -> int:
	return level


func setup_from_entry(entry: SpawnEntry) -> void:
	kind = entry.kind
	level = entry.level_index
	if is_node_ready():
		_apply_stats()


func setup(new_level: int) -> void:
	kind = SpawnEntry.Kind.NORMAL
	level = new_level
	if is_node_ready():
		_apply_stats()


func _apply_stats() -> void:
	var visual := MonsterData.get_visual_for_entry(_entry_from_self())

	var circle := CircleShape2D.new()
	circle.radius = visual["radius"]
	collision_shape.shape = circle

	mass = visual["mass"]
	sprite.texture = _get_texture_for_visual(visual)
	sprite.scale = Vector2.ONE

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.15 if kind != SpawnEntry.Kind.BOMB else 0.05
	mat.friction = 0.7
	physics_material_override = mat

	linear_damp = 0.05
	angular_damp = 0.8
	can_sleep = true


func get_visual_data() -> Dictionary:
	return MonsterData.get_visual_for_entry(_entry_from_self())


func _entry_from_self() -> SpawnEntry:
	match kind:
		SpawnEntry.Kind.JUNK:
			return SpawnEntry.junk()
		SpawnEntry.Kind.BOMB:
			return SpawnEntry.bomb()
		_:
			return SpawnEntry.normal(level)


func _get_texture_for_visual(visual: Dictionary) -> ImageTexture:
	if kind == SpawnEntry.Kind.BOMB:
		return _get_bomb_texture(visual["radius"])
	return _get_circle_texture(visual["radius"], visual["color"])


func _get_circle_texture(radius: float, color: Color) -> ImageTexture:
	var key := "%d_%s" % [int(radius), color.to_html(false)]
	if _circle_textures.has(key):
		return _circle_textures[key]

	var size := int(radius * 2.0)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	var center := Vector2(radius, radius)
	var r_sq := radius * radius
	for y in range(size):
		for x in range(size):
			var offset := Vector2(x + 0.5, y + 0.5) - center
			if offset.length_squared() <= r_sq:
				var edge := offset.length() / radius
				var shade := 1.0 - edge * 0.25
				image.set_pixel(x, y, color * shade)

	var texture := ImageTexture.create_from_image(image)
	_circle_textures[key] = texture
	return texture


func _get_bomb_texture(radius: float) -> ImageTexture:
	var key := "bomb_%d" % int(radius)
	if _circle_textures.has(key):
		return _circle_textures[key]

	var size := int(radius * 2.0)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	var center := Vector2(radius, radius)
	var r_sq := radius * radius
	for y in range(size):
		for x in range(size):
			var offset := Vector2(x + 0.5, y + 0.5) - center
			if offset.length_squared() <= r_sq:
				image.set_pixel(x, y, MonsterData.BOMB_COLOR)

	# Fuse dot on top.
	var fuse_center := Vector2(radius, radius * 0.35)
	for y in range(size):
		for x in range(size):
			var offset := Vector2(x + 0.5, y + 0.5) - fuse_center
			if offset.length_squared() <= 16.0:
				image.set_pixel(x, y, MonsterData.BOMB_FUSE_COLOR)

	var texture := ImageTexture.create_from_image(image)
	_circle_textures[key] = texture
	return texture


func _on_body_entered(body: Node) -> void:
	if is_merging or is_exploding or not body is Monster:
		return

	var other := body as Monster
	if other.is_merging or other.is_exploding:
		return

	if kind == SpawnEntry.Kind.BOMB or other.kind == SpawnEntry.Kind.BOMB:
		_trigger_bomb_explosion(other if kind == SpawnEntry.Kind.BOMB else self)
		return

	if kind == SpawnEntry.Kind.JUNK and other.kind == SpawnEntry.Kind.JUNK:
		if get_instance_id() > other.get_instance_id():
			return
		call_deferred("_destroy_junk_pair", other)
		return

	if kind != SpawnEntry.Kind.NORMAL or other.kind != SpawnEntry.Kind.NORMAL:
		return
	if other.get_level() != level:
		return
	if not MonsterData.can_merge(level):
		return
	if get_instance_id() > other.get_instance_id():
		return

	call_deferred("_start_merge", other)


func _destroy_junk_pair(other: Monster) -> void:
	if is_merging or other.is_merging or not is_instance_valid(other):
		return
	is_merging = true
	other.is_merging = true
	var pos := (global_position + other.global_position) * 0.5
	junk_destroyed.emit(pos)
	other.queue_free()
	queue_free()


func _start_merge(other: Monster) -> void:
	if is_merging or other.is_merging or not is_instance_valid(other):
		return
	is_merging = true
	other.is_merging = true

	var merge_pos := (global_position + other.global_position) * 0.5
	var new_level := level + 1
	var data := MonsterData.get_level_data(new_level)

	merged.emit(new_level, merge_pos, data["score"])

	other.queue_free()
	queue_free()


func _trigger_bomb_explosion(bomb: Monster) -> void:
	if bomb.is_exploding:
		return
	bomb.call_deferred("_explode")


func _explode() -> void:
	if is_exploding:
		return
	is_exploding = true

	var explosion_pos := global_position
	var explosion_radius := 90.0
	var destroyed_score := 0

	for node in get_tree().get_nodes_in_group("monsters"):
		if node == self or not node is Monster:
			continue
		var monster := node as Monster
		if monster.is_exploding or monster.is_merging:
			continue
		if monster.global_position.distance_to(explosion_pos) <= explosion_radius:
			if monster.kind == SpawnEntry.Kind.NORMAL:
				var data := MonsterData.get_level_data(monster.get_level())
				destroyed_score += data["score"]
			monster.queue_free()

	var final_score := int(float(destroyed_score) * 0.25)
	exploded.emit(explosion_pos, final_score)
	queue_free()

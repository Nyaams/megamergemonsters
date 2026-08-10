class_name Monster
extends RigidBody2D

signal merged(new_level: int, position: Vector2, score_gained: int)

@export var level: int = 0

var is_merging: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

static var _circle_textures: Dictionary = {}


func _ready() -> void:
	add_to_group("monsters")
	_apply_level_stats()
	body_entered.connect(_on_body_entered)


func get_level() -> int:
	return level


func setup(new_level: int) -> void:
	level = new_level
	if is_node_ready():
		_apply_level_stats()


func _apply_level_stats() -> void:
	var data := MonsterData.get_level_data(level)

	var circle := CircleShape2D.new()
	circle.radius = data["radius"]
	collision_shape.shape = circle

	mass = data["mass"]
	sprite.texture = _get_circle_texture(data["radius"], data["color"])
	sprite.scale = Vector2.ONE

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.15
	mat.friction = 0.7
	physics_material_override = mat

	linear_damp = 0.05
	angular_damp = 0.8
	can_sleep = true


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


func _on_body_entered(body: Node) -> void:
	if is_merging or not body is Monster:
		return

	var other := body as Monster
	if other.is_merging:
		return
	if other.get_level() != level:
		return
	if not MonsterData.can_merge(level):
		return

	# Only the body with the lower instance id initiates merge (prevents double merge).
	if get_instance_id() > other.get_instance_id():
		return

	# Deferred merge prevents same-frame double contact callbacks.
	call_deferred("_start_merge", other)


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

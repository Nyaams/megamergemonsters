class_name Monster
extends RigidBody2D

signal merged(new_level: int, position: Vector2, score_gained: int)
signal junk_destroyed(position: Vector2)

@export var level: int = 0
@export var kind: SpawnEntry.Kind = SpawnEntry.Kind.NORMAL

var is_merging: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D


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
	var hitbox_margin := 0.94
	var circle := CircleShape2D.new()
	circle.radius = visual["radius"] * hitbox_margin
	collision_shape.shape = circle

	mass = visual["mass"]
	sprite.texture = visual["sprite"]
	
	var s = visual.get("scale", Vector2.ONE)
	if s is float:
		sprite.scale = Vector2(s, s)
	else:
		sprite.scale = s

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.15
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


func _on_body_entered(body: Node) -> void:
	if is_merging or not body is Monster:
		return

	var other := body as Monster
	if other.is_merging:
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

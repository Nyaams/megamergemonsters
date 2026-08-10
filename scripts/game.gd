extends Node2D

enum State { PLAYING, GAME_OVER }

const MONSTER_SCENE := preload("res://scenes/monster.tscn")
const SAVE_PATH := "user://save.cfg"

const CONTAINER_LEFT := 70.0
const CONTAINER_RIGHT := 470.0
const CONTAINER_TOP := 120.0
const CONTAINER_BOTTOM := 900.0
const DROP_Y := CONTAINER_TOP + 10.0
const DANGER_LINE_Y := CONTAINER_TOP + 30.0
const DANGER_TIMEOUT := 2.0
const SPAWN_COOLDOWN := 0.35
const SETTLED_VELOCITY := 30.0

@onready var monsters_root: Node2D = $Monsters
@onready var preview_current: Sprite2D = $PreviewCurrent
@onready var preview_next: Sprite2D = $PreviewNext
@onready var score_label: Label = $UI/ScoreLabel
@onready var best_label: Label = $UI/BestLabel
@onready var level_label: Label = $UI/LevelLabel
@onready var drop_line: Line2D = $DropLine
@onready var danger_line: Line2D = $DangerLine
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var final_score_label: Label = $UI/GameOverPanel/FinalScoreLabel
@onready var game_over_best_label: Label = $UI/GameOverPanel/GameOverBestLabel
@onready var retry_button: Button = $UI/GameOverPanel/RetryButton

var state: State = State.PLAYING
var score: int = 0
var best_score: int = 0
var highest_level: int = 0
var current_level: int = 0
var next_level: int = 0
var drop_x: float = (CONTAINER_LEFT + CONTAINER_RIGHT) * 0.5
var can_drop: bool = true
var _cooldown_timer: float = 0.0
var _danger_timer: float = 0.0


func _ready() -> void:
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	_load_best_score()
	_setup_lines()
	_start_round()


func _setup_lines() -> void:
	drop_line.points = PackedVector2Array([
		Vector2(CONTAINER_LEFT, DROP_Y),
		Vector2(CONTAINER_RIGHT, DROP_Y),
	])
	drop_line.width = 2.0
	drop_line.default_color = Color(1, 1, 1, 0.35)

	danger_line.points = PackedVector2Array([
		Vector2(CONTAINER_LEFT, DANGER_LINE_Y),
		Vector2(CONTAINER_RIGHT, DANGER_LINE_Y),
	])
	danger_line.width = 2.0
	danger_line.default_color = Color(1, 0.3, 0.3, 0.6)


func _start_round() -> void:
	state = State.PLAYING
	score = 0
	highest_level = 0
	_cooldown_timer = 0.0
	_danger_timer = 0.0
	can_drop = true
	drop_x = (CONTAINER_LEFT + CONTAINER_RIGHT) * 0.5
	_clear_monsters()
	_init_queue()
	_update_ui()
	game_over_panel.hide()


func _clear_monsters() -> void:
	for child in monsters_root.get_children():
		child.queue_free()


func _init_queue() -> void:
	current_level = _roll_spawn_level()
	next_level = _roll_spawn_level()
	_update_previews()


func _advance_queue() -> void:
	current_level = next_level
	next_level = _roll_spawn_level()
	_update_previews()


func _roll_spawn_level() -> int:
	var pool := MonsterData.get_spawn_pool()
	return pool[randi() % pool.size()]


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return

	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		can_drop = _cooldown_timer <= 0.0

	_update_drop_position_from_input()
	preview_current.global_position = Vector2(drop_x, DROP_Y)
	preview_current.modulate.a = 0.55 if can_drop else 0.25
	preview_current.visible = true


func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return

	if _check_danger_zone():
		_danger_timer += delta
		if _danger_timer >= DANGER_TIMEOUT:
			_trigger_game_over()
	else:
		_danger_timer = 0.0


func _check_danger_zone() -> bool:
	for node in get_tree().get_nodes_in_group("monsters"):
		if not node is Monster:
			continue
		var monster := node as Monster
		var data := MonsterData.get_level_data(monster.get_level())
		var radius: float = data["radius"]
		var top_y := monster.global_position.y - radius
		if top_y < DANGER_LINE_Y and monster.linear_velocity.length() < SETTLED_VELOCITY:
			return true
	return false


func _trigger_game_over() -> void:
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	preview_current.visible = false

	if score > best_score:
		best_score = score
		_save_best_score()

	if final_score_label:
		final_score_label.text = "Score: %d" % score
	if game_over_best_label:
		game_over_best_label.text = "Best: %d" % best_score
	game_over_panel.show()
	_update_ui()


func _on_retry_pressed() -> void:
	_start_round()


func _update_drop_position_from_input() -> void:
	var radius: float = MonsterData.get_level_data(current_level)["radius"]
	var min_x := CONTAINER_LEFT + radius
	var max_x := CONTAINER_RIGHT - radius
	drop_x = clampf(get_global_mouse_position().x, min_x, max_x)


func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLAYING:
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_handle_touch(touch)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_set_drop_x_from_screen(drag.position.x)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_try_drop()


func _handle_touch(touch: InputEventScreenTouch) -> void:
	_set_drop_x_from_screen(touch.position.x)
	if touch.pressed:
		_try_drop()


func _set_drop_x_from_screen(screen_x: float) -> void:
	var radius: float = MonsterData.get_level_data(current_level)["radius"]
	var min_x := CONTAINER_LEFT + radius
	var max_x := CONTAINER_RIGHT - radius
	var world_x := get_viewport().get_canvas_transform().affine_inverse() * Vector2(screen_x, 0)
	drop_x = clampf(world_x.x, min_x, max_x)


func _try_drop() -> void:
	if state != State.PLAYING or not can_drop:
		return
	_spawn_monster(current_level, Vector2(drop_x, DROP_Y))
	_advance_queue()
	_cooldown_timer = SPAWN_COOLDOWN
	can_drop = false


func _spawn_monster(monster_level: int, pos: Vector2) -> Monster:
	var monster: Monster = MONSTER_SCENE.instantiate()
	monster.level = monster_level
	monster.global_position = pos
	monster.merged.connect(_on_monster_merged)
	monsters_root.add_child(monster)
	return monster


func _on_monster_merged(new_level: int, pos: Vector2, score_gained: int) -> void:
	if state != State.PLAYING:
		return
	score += score_gained
	highest_level = maxi(highest_level, new_level)
	_update_ui()
	call_deferred("_spawn_merged_monster", new_level, pos)


func _spawn_merged_monster(new_level: int, pos: Vector2) -> void:
	if state != State.PLAYING:
		return
	var data := MonsterData.get_level_data(new_level)
	var radius: float = data["radius"]
	var spawn_pos := pos + Vector2(0, -radius * 0.15)
	var monster := _spawn_monster(new_level, spawn_pos)
	monster.linear_velocity = Vector2.ZERO
	monster.angular_velocity = 0.0


func _update_previews() -> void:
	var current_data := MonsterData.get_level_data(current_level)
	preview_current.texture = _create_preview_texture(current_data["radius"], current_data["color"])

	var next_data := MonsterData.get_level_data(next_level)
	preview_next.texture = _create_preview_texture(next_data["radius"], next_data["color"])


func _create_preview_texture(radius: float, color: Color) -> ImageTexture:
	var size := maxi(int(radius * 2.0), 2)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	var center := Vector2(radius, radius)
	var r_sq := radius * radius
	for y in range(size):
		for x in range(size):
			var offset := Vector2(x + 0.5, y + 0.5) - center
			if offset.length_squared() <= r_sq:
				image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)


func _update_ui() -> void:
	score_label.text = "Score: %d" % score
	best_label.text = "Best: %d" % best_score
	var level_name: String = MonsterData.get_level_data(highest_level)["name"]
	level_label.text = "Level: %s" % level_name


func _load_best_score() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_score = config.get_value("game", "best_score", 0)


func _save_best_score() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "best_score", best_score)
	config.save(SAVE_PATH)

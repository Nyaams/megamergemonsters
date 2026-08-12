extends Node2D

enum State { PLAYING, GAME_OVER }

const MONSTER_SCENE := preload("res://scenes/monster.tscn")
const SAVE_PATH := "user://save.cfg"

const BASE_CONTAINER_LEFT := 70.0
const BASE_CONTAINER_RIGHT := 470.0
const CONTAINER_TOP := 120.0
const CONTAINER_BOTTOM := 900.0
const DROP_Y := CONTAINER_TOP + 10.0
const DANGER_LINE_Y := CONTAINER_TOP + 30.0
const DANGER_TIMEOUT := 2.0
const SETTLED_VELOCITY := 30.0
const WALL_THICKNESS := 20.0
const NARROW_INTERVAL := 45.0
const NARROW_STEP := 4.0
const MAX_NARROW := 40.0

@onready var camera: Camera2D = $Camera2D
@onready var monsters_root: Node2D = $Monsters
@onready var effects: MergeEffects = $Effects
@onready var preview_current: Sprite2D = $PreviewCurrent
@onready var preview_next: Sprite2D = $PreviewNext
@onready var score_label: Label = $UI/ScoreLabel
@onready var best_label: Label = $UI/BestLabel
@onready var level_label: Label = $UI/LevelLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var drop_line: Line2D = $DropLine
@onready var danger_line: Line2D = $DangerLine
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var final_score_label: Label = $UI/GameOverPanel/VBox/FinalScoreLabel
@onready var game_over_best_label: Label = $UI/GameOverPanel/VBox/GameOverBestLabel
@onready var retry_button: Button = $UI/GameOverPanel/VBox/RetryButton
@onready var flash_rect: ColorRect = $UI/FlashRect
@onready var danger_vignette: ColorRect = $UI/DangerVignette
@onready var left_wall: StaticBody2D = $Walls/LeftWall
@onready var right_wall: StaticBody2D = $Walls/RightWall
@onready var left_wall_visual: ColorRect = $BackgroundLayer/LeftWallVisual
@onready var right_wall_visual: ColorRect = $BackgroundLayer/RightWallVisual

var state: State = State.PLAYING
var score: int = 0
var best_score: int = 0
var highest_level: int = 0
var container_left: float = BASE_CONTAINER_LEFT
var container_right: float = BASE_CONTAINER_RIGHT
var current_entry: SpawnEntry
var next_entry: SpawnEntry
var drop_x: float = (BASE_CONTAINER_LEFT + BASE_CONTAINER_RIGHT) * 0.5
var can_drop: bool = true

var _cooldown_timer: float = 0.0
var _danger_timer: float = 0.0
var _round_time: float = 0.0
var _drops_count: int = 0
var _narrow_amount: float = 0.0
var _next_narrow_at: float = NARROW_INTERVAL
var _combo_tracker := ComboTracker.new()
var _danger_feedback := DangerFeedback.new()
var _combo_hide_timer: float = 0.0


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	effects.setup(camera, flash_rect)
	_danger_feedback.setup(left_wall_visual, right_wall_visual, danger_line, danger_vignette)
	_load_best_score()
	_apply_container_width(BASE_CONTAINER_LEFT, BASE_CONTAINER_RIGHT)
	_setup_lines()
	_start_round()


func _setup_lines() -> void:
	_update_line_positions()


func _update_line_positions() -> void:
	drop_line.points = PackedVector2Array([
		Vector2(container_left, DROP_Y),
		Vector2(container_right, DROP_Y),
	])
	danger_line.points = PackedVector2Array([
		Vector2(container_left, DANGER_LINE_Y),
		Vector2(container_right, DANGER_LINE_Y),
	])


func _start_round() -> void:
	state = State.PLAYING
	score = 0
	highest_level = 0
	_cooldown_timer = 0.0
	_danger_timer = 0.0
	_round_time = 0.0
	_drops_count = 0
	_narrow_amount = 0.0
	_next_narrow_at = NARROW_INTERVAL
	can_drop = true
	drop_x = (BASE_CONTAINER_LEFT + BASE_CONTAINER_RIGHT) * 0.5
	_combo_tracker.reset()
	_danger_feedback.reset()
	combo_label.visible = false
	_combo_hide_timer = 0.0
	_apply_container_width(BASE_CONTAINER_LEFT, BASE_CONTAINER_RIGHT)
	_clear_monsters()
	_init_queue()
	_update_ui()
	game_over_panel.hide()


func _clear_monsters() -> void:
	for child in monsters_root.get_children():
		child.queue_free()


func _init_queue() -> void:
	current_entry = _roll_spawn_entry()
	next_entry = _roll_spawn_entry()
	_update_previews()


func _advance_queue() -> void:
	current_entry = next_entry
	next_entry = _roll_spawn_entry()
	_update_previews()


func _roll_spawn_entry() -> SpawnEntry:
	return MonsterData.roll_spawn_entry(_round_time, _drops_count)


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return

	_round_time += delta
	_combo_tracker.update(delta)
	_update_progression()

	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		can_drop = _cooldown_timer <= 0.0

	if _combo_hide_timer > 0.0:
		_combo_hide_timer -= delta
		if _combo_hide_timer <= 0.0:
			combo_label.visible = false

	_update_drop_position_from_input()
	preview_current.global_position = Vector2(drop_x, DROP_Y)
	preview_current.modulate.a = 0.55 if can_drop else 0.25
	preview_current.visible = true


func _update_progression() -> void:
	if _round_time >= _next_narrow_at and _narrow_amount < MAX_NARROW:
		_narrow_amount = minf(_narrow_amount + NARROW_STEP, MAX_NARROW)
		_next_narrow_at += NARROW_INTERVAL
		var left := BASE_CONTAINER_LEFT + _narrow_amount
		var right := BASE_CONTAINER_RIGHT - _narrow_amount
		_apply_container_width(left, right)


func _apply_container_width(left: float, right: float) -> void:
	container_left = left
	container_right = right

	var wall_center_y := (CONTAINER_TOP + CONTAINER_BOTTOM) * 0.5
	left_wall.position = Vector2(left - WALL_THICKNESS * 0.5, wall_center_y)
	right_wall.position = Vector2(right + WALL_THICKNESS * 0.5, wall_center_y)

	left_wall_visual.offset_left = left - WALL_THICKNESS - 10.0
	left_wall_visual.offset_right = left - 10.0
	right_wall_visual.offset_left = right + 10.0
	right_wall_visual.offset_right = right + WALL_THICKNESS + 10.0

	_update_line_positions()

	var radius := _preview_radius(current_entry)
	drop_x = clampf(drop_x, container_left + radius, container_right - radius)


func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return

	var in_danger := _check_danger_zone()
	if in_danger:
		_danger_timer += delta
		if _danger_timer >= DANGER_TIMEOUT:
			_trigger_game_over()
	else:
		_danger_timer = 0.0

	var ratio := _danger_timer / DANGER_TIMEOUT if in_danger else 0.0
	_danger_feedback.update(delta, ratio)


func _check_danger_zone() -> bool:
	for node in get_tree().get_nodes_in_group("monsters"):
		if not node is Monster:
			continue
		var monster := node as Monster
		var visual := monster.get_visual_data()
		var radius: float = visual["radius"]
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

	final_score_label.text = "Score: %d" % score
	game_over_best_label.text = "Best: %d" % best_score
	game_over_panel.show()
	_update_ui()


func _on_retry_pressed() -> void:
	_start_round()


func _preview_radius(entry: SpawnEntry) -> float:
	if entry == null:
		return MonsterData.get_level_data(0)["radius"]
	return MonsterData.get_visual_for_entry(entry)["radius"]


func _update_drop_position_from_input() -> void:
	var radius := _preview_radius(current_entry)
	drop_x = clampf(get_global_mouse_position().x, container_left + radius, container_right - radius)


func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLAYING:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_set_drop_x_from_screen((event as InputEventScreenDrag).position.x)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_try_drop()


func _handle_touch(touch: InputEventScreenTouch) -> void:
	_set_drop_x_from_screen(touch.position.x)
	if touch.pressed:
		_try_drop()


func _set_drop_x_from_screen(screen_x: float) -> void:
	var radius := _preview_radius(current_entry)
	var world_x := get_viewport().get_canvas_transform().affine_inverse() * Vector2(screen_x, 0)
	drop_x = clampf(world_x.x, container_left + radius, container_right - radius)


func _try_drop() -> void:
	if state != State.PLAYING or not can_drop:
		return
	_spawn_from_entry(current_entry, Vector2(drop_x, DROP_Y))
	_drops_count += 1
	_advance_queue()
	_cooldown_timer = MonsterData.get_spawn_cooldown(_round_time)
	can_drop = false


func _spawn_from_entry(entry: SpawnEntry, pos: Vector2) -> Monster:
	var monster: Monster = MONSTER_SCENE.instantiate()
	monster.setup_from_entry(entry)
	monster.global_position = pos
	monster.merged.connect(_on_monster_merged)
	monster.exploded.connect(_on_monster_exploded)
	monster.junk_destroyed.connect(_on_junk_destroyed)
	monsters_root.add_child(monster)
	return monster


func _on_monster_merged(new_level: int, pos: Vector2, score_gained: int) -> void:
	if state != State.PLAYING:
		return

	var multiplier := _combo_tracker.register_merge()
	var final_score := score_gained * multiplier
	score += final_score
	highest_level = maxi(highest_level, new_level)
	_update_ui()

	if multiplier > 1:
		_show_combo(multiplier)

	call_deferred("_spawn_merged_monster", new_level, pos, final_score)


func _spawn_merged_monster(new_level: int, pos: Vector2, final_score: int) -> void:
	if state != State.PLAYING:
		return
	var data := MonsterData.get_level_data(new_level)
	var radius: float = data["radius"]
	var spawn_pos := pos + Vector2(0, -radius * 0.15)
	var monster := _spawn_from_entry(SpawnEntry.normal(new_level), spawn_pos)
	monster.linear_velocity = Vector2.ZERO
	monster.angular_velocity = 0.0
	effects.play_merge(pos, final_score, monster)


func _on_monster_exploded(pos: Vector2, score_gained: int) -> void:
	if state != State.PLAYING:
		return
	score += score_gained
	_update_ui()
	effects.play_explosion(pos, score_gained)


func _on_junk_destroyed(_pos: Vector2) -> void:
	effects.play_particles(_pos, Color(0.5, 0.5, 0.5, 0.8), 6)


func _show_combo(multiplier: int) -> void:
	combo_label.text = "COMBO x%d" % multiplier
	combo_label.visible = true
	combo_label.scale = Vector2(1.4, 1.4)
	combo_label.modulate.a = 1.0
	var tween := combo_label.create_tween()
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
	_combo_hide_timer = 1.5


func _update_previews() -> void:
	var current_visual := MonsterData.get_visual_for_entry(current_entry)
	preview_current.texture = _create_preview_texture(current_visual)

	var next_visual := MonsterData.get_visual_for_entry(next_entry)
	preview_next.texture = _create_preview_texture(next_visual)


func _create_preview_texture(visual: Dictionary) -> ImageTexture:
	var radius: float = visual["radius"]
	var color: Color = visual["color"]
	if visual.has("fuse_color"):
		return _create_bomb_preview(radius)
	return _create_circle_preview(radius, color)


func _create_circle_preview(radius: float, color: Color) -> ImageTexture:
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


func _create_bomb_preview(radius: float) -> ImageTexture:
	var size := maxi(int(radius * 2.0), 2)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center := Vector2(radius, radius)
	var r_sq := radius * radius
	for y in range(size):
		for x in range(size):
			var offset := Vector2(x + 0.5, y + 0.5) - center
			if offset.length_squared() <= r_sq:
				image.set_pixel(x, y, MonsterData.BOMB_COLOR)
	var fuse_center := Vector2(radius, radius * 0.35)
	for y in range(size):
		for x in range(size):
			var offset := Vector2(x + 0.5, y + 0.5) - fuse_center
			if offset.length_squared() <= 16.0:
				image.set_pixel(x, y, MonsterData.BOMB_FUSE_COLOR)
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
		# Hook for future prestige system.
		var _prestige: int = config.get_value("game", "prestige_level", 0)


func _save_best_score() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("game", "best_score", best_score)
	config.save(SAVE_PATH)

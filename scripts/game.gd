extends Node2D

enum State { PLAYING, PAUSED, GAME_OVER }

const MONSTER_SCENE := preload("res://scenes/monster.tscn")

const DANGER_TIMEOUT := 2.0
const SETTLED_VELOCITY := 30.0
const WALL_THICKNESS := 20.0

@onready var camera: Camera2D = $Camera2D
@onready var monsters_root: Node2D = $Monsters
@onready var effects: MergeEffects = $Effects
@onready var preview_current: Sprite2D = $PreviewCurrent
@onready var field_sprite: Sprite2D = $FieldSprite
@onready var drop_line: Line2D = $DropLine
@onready var aim_line: Line2D = $AimLine
@onready var danger_line: Line2D = $DangerLine
@onready var left_wall: StaticBody2D = $Walls/LeftWall
@onready var right_wall: StaticBody2D = $Walls/RightWall
@onready var bottom_wall: StaticBody2D = $Walls/BottomWall
@onready var flash_rect: ColorRect = $UI/FlashRect
@onready var danger_vignette: ColorRect = $UI/DangerVignette
@onready var hud: Control = $UI/HUD

@onready var score_label: Label = $UI/HUD/HudPanel/HudVBox/HudBottomRow/StatsVBox/ScoreLabel
@onready var best_label: Label = $UI/HUD/HudPanel/HudVBox/HudBottomRow/StatsVBox/BestLabel
@onready var coins_value_label: Label = $UI/HUD/HudPanel/HudVBox/HudBottomRow/CoinsHBox/CoinsValueLabel
@onready var combo_label: Label = $UI/HUD/ComboLabel
@onready var next_preview: TextureRect = $UI/HUD/HudPanel/HudVBox/HudBottomRow/NextPanel/NextPreview

@onready var pause_button: Button = $UI/HUD/ActionBar/PauseButton
@onready var hud_sound_btn: Button = $UI/HUD/ActionBar/SoundButton
@onready var bomb_button: TextureButton = $UI/HUD/AbilityBar/BombButton
@onready var bomb_count_label: Label = $UI/HUD/AbilityBar/BombCountLabel

@onready var pause_panel: Control = $UI/PausePanel
@onready var upgrades_panel: Control = $UI/UpgradesPanel
@onready var revive_offer_panel: Control = $UI/ReviveOfferPanel
@onready var revive_title: Label = $UI/ReviveOfferPanel/ReviveVBox/ReviveTitle
@onready var revive_question: Label = $UI/ReviveOfferPanel/ReviveVBox/ReviveQuestion
@onready var revive_benefit: Label = $UI/ReviveOfferPanel/ReviveVBox/ReviveBenefit
@onready var revive_extra_life_btn: Button = $UI/ReviveOfferPanel/ReviveVBox/ReviveExtraLifeButton
@onready var revive_watch_ad_btn: Button = $UI/ReviveOfferPanel/ReviveVBox/ReviveWatchAdButton
@onready var revive_decline_btn: Button = $UI/ReviveOfferPanel/ReviveVBox/ReviveDeclineButton

@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var leaderboard_panel: Control = $UI/LeaderboardPanel

@onready var final_score_label: Label = $UI/GameOverPanel/GameOverVBox/FinalScoreLabel
@onready var game_over_best_label: Label = $UI/GameOverPanel/GameOverVBox/GameOverBestLabel
@onready var coins_earned_label: Label = $UI/GameOverPanel/GameOverVBox/CoinsEarnedLabel
@onready var retry_button: Button = $UI/GameOverPanel/GameOverVBox/RetryButton
@onready var game_over_menu_button: Button = $UI/GameOverPanel/GameOverVBox/GameOverMenuButton
@onready var upgrades_from_game_over: Button = $UI/GameOverPanel/GameOverVBox/GameOverUpgradesButton

@onready var upgrades_coins_label: Label = $UI/UpgradesPanel/UpgradesVBox/UpgradesCoinsLabel
@onready var extra_life_btn: Button = $UI/UpgradesPanel/UpgradesVBox/ExtraLifeButton
@onready var coin_bonus_btn: Button = $UI/UpgradesPanel/UpgradesVBox/CoinBonusButton
@onready var combo_duration_btn: Button = $UI/UpgradesPanel/UpgradesVBox/ComboDurationButton
@onready var bomb_unlock_btn: Button = $UI/UpgradesPanel/UpgradesVBox/BombUnlockButton
@onready var upgrades_close_btn: Button = $UI/UpgradesPanel/UpgradesVBox/UpgradesCloseButton

@onready var pause_resume_btn: Button = $UI/PausePanel/PauseVBox/ResumeButton
@onready var pause_restart_btn: Button = $UI/PausePanel/PauseVBox/PauseRestartButton
@onready var pause_sound_btn: Button = $UI/PausePanel/PauseVBox/PauseQuickControls/PauseSoundButton
@onready var pause_lang_btn: Button = $UI/PausePanel/PauseVBox/PauseQuickControls/PauseLanguageButton
@onready var pause_menu_btn: Button = $UI/PausePanel/PauseVBox/PauseMenuButton
@onready var pause_label: Label = $UI/PausePanel/PauseVBox/PauseLabel
@onready var pause_vbox: VBoxContainer = $UI/PausePanel/PauseVBox
@onready var next_label: Label = $UI/HUD/HudPanel/HudVBox/HudBottomRow/NextPanel/NextLabel
@onready var upgrades_title: Label = $UI/UpgradesPanel/UpgradesVBox/UpgradesTitle
@onready var game_over_label: Label = $UI/GameOverPanel/GameOverVBox/GameOverLabel

var state: State = State.PLAYING
var score: int = 0
var highest_level: int = 0
var container_left: float = 70.0
var container_right: float = 470.0
var container_top: float = 100.0
var container_bottom: float = 900.0
var drop_y: float = 110.0
var danger_line_y: float = 130.0
var current_entry: SpawnEntry
var next_entry: SpawnEntry
var drop_x: float = 270.0
var can_drop: bool = true

var _save := SaveData.new()
var _combo_tracker := ComboTracker.new()
var _danger_feedback := DangerFeedback.new()
var _cooldown_timer: float = 0.0
var _danger_timer: float = 0.0
var _round_time: float = 0.0
var _drops_count: int = 0
var _combo_hide_timer: float = 0.0
var _revive_used: bool = false
var _round_milestones: Array[int] = []
var _last_coins_earned: int = 0
var _platform_paused: bool = false
var _new_best_this_round: bool = false


func _ready() -> void:
	_save.load()
	if not _save.user_selected_language or _save.language == "":
		var raw_sdk_lang := YandexManager.get_sdk_language()
		_save.language = Locale.resolve_yandex_language(raw_sdk_lang)
		_save.save()
	YandexManager.load_cloud_save_async(_save)
	Locale.load_from_save(_save)
	AudioManager.apply_settings()
	_combo_tracker.window = UpgradeShop.get_combo_window(_save.combo_duration_level)
	effects.setup(camera, flash_rect)
	_danger_feedback.setup(field_sprite, danger_line, danger_vignette)
	_setup_panels()
	_connect_buttons()
	YandexManager.platform_pause.connect(_on_platform_pause)
	YandexManager.platform_resume.connect(_on_platform_resume)
	YandexManager.sdk_ready.connect(func(): YandexManager.notify_loading_ready())
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()
	_apply_locale()

	if GameFlow.restore_session and _save.has_active_session:
		_restore_session(_save.session_data)
	else:
		_start_round()


func _setup_panels() -> void:
	UIHelpers.wrap_panel($UI/PausePanel/PauseVBox)
	UIHelpers.wrap_panel($UI/UpgradesPanel/UpgradesVBox)
	UIHelpers.wrap_panel($UI/ReviveOfferPanel/ReviveVBox)
	UIHelpers.wrap_panel($UI/GameOverPanel/GameOverVBox)
	UIHelpers.apply_readable_tree($UI/HUD/HudPanel)
	UIHelpers.apply_readable_tree($UI/HUD/ComboLabel)
	UIHelpers.apply_readable_tree($UI/HUD/AbilityBar)
	UIHelpers.apply_readable_tree($UI/PausePanel)
	UIHelpers.apply_readable_tree($UI/ReviveOfferPanel)
	UIHelpers.apply_readable_tree($UI/GameOverPanel)

	UIHelpers.style_icon_button(hud_sound_btn)
	UIHelpers.style_icon_button(pause_sound_btn)
	UIHelpers.style_icon_button(pause_lang_btn)


func _connect_buttons() -> void:
	pause_button.pressed.connect(_on_pause_pressed)
	hud_sound_btn.pressed.connect(_on_toggle_sound)
	bomb_button.pressed.connect(_on_bomb_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	game_over_menu_button.pressed.connect(_on_game_over_menu_pressed)
	upgrades_from_game_over.pressed.connect(_on_upgrades_pressed)
	pause_resume_btn.pressed.connect(_on_resume_pressed)
	pause_restart_btn.pressed.connect(_on_restart_pressed)
	pause_sound_btn.pressed.connect(_on_toggle_sound)
	pause_lang_btn.pressed.connect(_on_toggle_language)
	pause_menu_btn.pressed.connect(_on_main_menu_pressed)
	upgrades_close_btn.pressed.connect(_on_upgrades_close)
	extra_life_btn.pressed.connect(_on_buy_extra_life)
	coin_bonus_btn.pressed.connect(_on_buy_coin_bonus)
	combo_duration_btn.pressed.connect(_on_buy_combo_duration)
	bomb_unlock_btn.pressed.connect(_on_buy_bomb)

	revive_extra_life_btn.pressed.connect(_on_revive_extra_life_pressed)
	revive_watch_ad_btn.pressed.connect(_on_revive_watch_ad_pressed)
	revive_decline_btn.pressed.connect(_on_revive_decline_pressed)


func _apply_locale() -> void:
	pause_button.text = Locale.get_text("pause")
	pause_label.text = Locale.get_text("pause")
	pause_resume_btn.text = Locale.get_text("resume")
	pause_restart_btn.text = Locale.get_text("restart")
	pause_menu_btn.text = Locale.get_text("main_menu")
	upgrades_title.text = Locale.get_text("upgrades")
	upgrades_close_btn.text = Locale.get_text("close")
	next_label.text = Locale.get_text("next")
	game_over_label.text = Locale.get_text("game_over")
	retry_button.text = Locale.get_text("play_again")
	game_over_menu_button.text = Locale.get_text("main_menu")
	upgrades_from_game_over.text = Locale.get_text("upgrades")

	revive_title.text = Locale.get_text("revive_title")
	revive_question.text = Locale.get_text("revive_question")
	revive_benefit.text = Locale.get_text("revive_benefit")
	revive_extra_life_btn.text = Locale.get_text("revive_extra_life")
	revive_watch_ad_btn.text = Locale.get_text("revive_watch_ad")
	revive_decline_btn.text = Locale.get_text("revive_decline")

	_update_settings_ui()
	_update_ui()


func _on_viewport_resized() -> void:
	var layout := GameLayout.compute(get_viewport().get_visible_rect().size)
	container_left = layout["left"]
	container_right = layout["right"]
	container_top = layout["top"]
	container_bottom = layout["bottom"]
	drop_y = layout["drop_y"]
	danger_line_y = layout["danger_y"]
	camera.position = layout["center"]
	var zoom: float = layout["zoom"]
	camera.zoom = Vector2(zoom, zoom)
	hud.scale = Vector2(zoom, zoom)
	_apply_container_geometry()
	if current_entry:
		drop_x = clampf(drop_x, container_left + _preview_radius(current_entry), container_right - _preview_radius(current_entry))


func _apply_container_geometry() -> void:
	var wall_center_y := (container_top + container_bottom) * 0.5
	left_wall.position = Vector2(container_left - WALL_THICKNESS * 0.5, wall_center_y)
	right_wall.position = Vector2(container_right + WALL_THICKNESS * 0.5, wall_center_y)
	bottom_wall.position = Vector2((container_left + container_right) * 0.5, container_bottom + WALL_THICKNESS * 0.5)

	var bottom_shape := bottom_wall.get_node("CollisionShape2D").shape as RectangleShape2D
	bottom_shape.size = Vector2(container_right - container_left + WALL_THICKNESS * 2.0, WALL_THICKNESS)

	field_sprite.position = Vector2((container_left + container_right) * 0.5, (container_top + container_bottom) * 0.5)
	if field_sprite.texture:
		var tex_size := field_sprite.texture.get_size()
		field_sprite.scale = Vector2(
			(container_right - container_left + 40.0) / tex_size.x,
			(container_bottom - container_top + 40.0) / tex_size.y
		)
	_update_lines()


func _update_lines() -> void:
	drop_line.points = PackedVector2Array([
		Vector2(container_left, drop_y),
		Vector2(container_right, drop_y),
	])
	danger_line.points = PackedVector2Array([
		Vector2(container_left, danger_line_y),
		Vector2(container_right, danger_line_y),
	])
	aim_line.points = PackedVector2Array([
		Vector2(drop_x, drop_y),
		Vector2(drop_x, container_bottom),
	])


func _start_round() -> void:
	state = State.PLAYING
	score = 0
	highest_level = 0
	_cooldown_timer = 0.0
	_danger_timer = 0.0
	_round_time = 0.0
	_drops_count = 0
	_revive_used = false
	_new_best_this_round = false
	_round_milestones.clear()
	_last_coins_earned = 0
	can_drop = true
	drop_x = (container_left + container_right) * 0.5
	_combo_tracker.window = UpgradeShop.get_combo_window(_save.combo_duration_level)
	_combo_tracker.reset()
	_danger_feedback.reset()
	combo_label.visible = false
	_combo_hide_timer = 0.0
	aim_line.visible = true
	_clear_monsters()
	_init_queue()
	_hide_all_panels()
	_save.clear_session()
	_save.total_games += 1
	_update_ui()
	YandexManager.notify_gameplay_started()
	AudioManager.set_gameplay_active(true)


func _hide_all_panels() -> void:
	pause_panel.hide()
	revive_offer_panel.hide()
	upgrades_panel.hide()
	game_over_panel.hide()
	leaderboard_panel.hide()


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
	return MonsterData.roll_spawn_entry(_round_time, _drops_count, highest_level)


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return

	_round_time += delta
	_combo_tracker.update(delta)

	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		can_drop = _cooldown_timer <= 0.0

	if _combo_hide_timer > 0.0:
		_combo_hide_timer -= delta
		if _combo_hide_timer <= 0.0:
			combo_label.visible = false

	_update_drop_position_from_input()
	preview_current.global_position = Vector2(drop_x, drop_y)
	preview_current.modulate.a = 0.55 if can_drop else 0.25
	preview_current.visible = true
	_update_lines()


func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return

	var in_danger := _check_danger_zone()
	if in_danger:
		_danger_timer += delta
		if _danger_timer >= DANGER_TIMEOUT:
			_on_defeat()
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
		if top_y < danger_line_y and monster.linear_velocity.length() < SETTLED_VELOCITY:
			return true
	return false


func _on_defeat() -> void:
	if state != State.PLAYING:
		return

	preview_current.visible = false
	aim_line.visible = false
	AudioManager.set_gameplay_active(false)
	AudioManager.play_game_over()
	YandexManager.notify_gameplay_stopped()

	if not _revive_used:
		state = State.PAUSED
		revive_extra_life_btn.visible = _save.extra_life_owned
		revive_offer_panel.show()
	else:
		_trigger_game_over()


func _on_revive_watch_ad_pressed() -> void:
	var rewarded := false
	YandexManager.show_rewarded(
		func(): rewarded = true,
		func(_was_shown: bool):
			if rewarded:
				_do_revive_and_clear_monsters()
			else:
				revive_offer_panel.hide()
				_trigger_game_over()
	)


func _on_revive_extra_life_pressed() -> void:
	if not _save.extra_life_owned or _revive_used:
		return
	_save.extra_life_owned = false
	_save.save()
	_do_revive_and_clear_monsters()


func _on_revive_decline_pressed() -> void:
	revive_offer_panel.hide()
	_trigger_game_over()


func _do_revive_and_clear_monsters() -> void:
	_revive_used = true
	revive_offer_panel.hide()

	for node in monsters_root.get_children():
		if node is Monster:
			var m := node as Monster
			if m.level < 3 or m.kind == SpawnEntry.Kind.JUNK:
				effects.play_particles(m.global_position, Color(1.0, 0.85, 0.3, 0.9), 10)
				m.queue_free()

	_danger_feedback.reset()
	_danger_timer = 0.0
	state = State.PLAYING
	preview_current.visible = true
	aim_line.visible = true
	_save_session()
	YandexManager.notify_gameplay_started()
	AudioManager.set_gameplay_active(true)
	_update_ui()


func _trigger_game_over() -> void:
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	revive_offer_panel.hide()
	preview_current.visible = false
	aim_line.visible = false
	AudioManager.set_gameplay_active(false)
	YandexManager.notify_gameplay_stopped()

	_new_best_this_round = score > _save.best_score
	if _new_best_this_round:
		_save.best_score = score
		YandexManager.upload_score(score)

	_award_round_coins()
	_save.total_score += score
	_save.clear_session()
	_save.save()

	final_score_label.text = "%s: %d" % [Locale.get_text("score"), score]
	game_over_best_label.text = "%s: %d" % [Locale.get_text("best"), _save.best_score]
	coins_earned_label.text = "%s: +%d" % [Locale.get_text("coins"), _last_coins_earned]
	game_over_panel.show()
	_update_ui()


func _award_round_coins() -> void:
	var max_level_1based := highest_level + 1
	var new_milestones: Array[int] = []
	for level in CoinRewards.MILESTONE_BONUSES.keys():
		if max_level_1based >= level and not _save.milestones.has(level):
			new_milestones.append(level)

	var result := CoinRewards.calc_total_round_coins(
		max_level_1based,
		_save.coin_bonus_level,
		new_milestones,
		_save.milestones
	)
	_last_coins_earned = result["total"]
	_save.coins += _last_coins_earned
	_save.unlock_milestones(new_milestones)


func _on_retry_pressed() -> void:
	YandexManager.show_interstitial(func(_was_shown: bool): _start_round())


func _on_game_over_menu_pressed() -> void:
	YandexManager.show_interstitial(func(_was_shown: bool): GameFlow.go_to_main_menu())


func _on_restart_pressed() -> void:
	_start_round()


func _on_pause_pressed() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	_save_session()
	pause_panel.show()
	YandexManager.notify_gameplay_stopped()
	AudioManager.set_gameplay_active(false)


func _on_resume_pressed() -> void:
	if state != State.PAUSED:
		return
	state = State.PLAYING
	pause_panel.hide()
	YandexManager.notify_gameplay_started()
	AudioManager.set_gameplay_active(true)


func _on_main_menu_pressed() -> void:
	_save_session()
	YandexManager.notify_gameplay_stopped()
	GameFlow.go_to_main_menu()


func _on_platform_pause() -> void:
	if state != State.PLAYING:
		return
	_platform_paused = true
	state = State.PAUSED
	pause_panel.show()
	AudioServer.set_bus_mute(0, true)
	AudioManager.set_gameplay_active(false)


func _on_platform_resume() -> void:
	if not _platform_paused:
		return
	_platform_paused = false
	if state == State.PAUSED:
		state = State.PLAYING
		pause_panel.hide()
		YandexManager.notify_gameplay_started()
		AudioServer.set_bus_mute(0, not Locale.sound_enabled)
		AudioManager.set_gameplay_active(true)


func _on_upgrades_pressed() -> void:
	_update_upgrades_ui()
	upgrades_panel.show()
	upgrades_panel.move_to_front()


func _on_upgrades_close() -> void:
	upgrades_panel.hide()


func _on_toggle_sound() -> void:
	Locale.sound_enabled = not Locale.sound_enabled
	Locale.apply_to_save(_save)
	_save.save()
	AudioManager.apply_settings()
	if state == State.PLAYING:
		AudioManager.set_gameplay_active(true)
	_update_settings_ui()


func _on_toggle_language() -> void:
	Locale.language = "en" if Locale.language == "ru" else "ru"
	_save.user_selected_language = true
	Locale.apply_to_save(_save)
	_save.save()
	YandexManager.queue_cloud_save(_save)
	_apply_locale()
	_update_upgrades_ui()


func _on_buy_extra_life() -> void:
	if UpgradeShop.buy_extra_life(_save):
		_update_upgrades_ui()
		_update_ui()


func _on_buy_coin_bonus() -> void:
	if UpgradeShop.buy_coin_bonus(_save):
		_update_upgrades_ui()
		_update_ui()


func _on_buy_combo_duration() -> void:
	if UpgradeShop.buy_combo_duration(_save):
		_combo_tracker.window = UpgradeShop.get_combo_window(_save.combo_duration_level)
		_update_upgrades_ui()
		_update_ui()


func _on_buy_bomb() -> void:
	if UpgradeShop.buy_bomb(_save):
		_update_upgrades_ui()
		_update_ui()


func _on_bomb_pressed() -> void:
	if state != State.PLAYING:
		return
	if not UpgradeShop.can_use_bomb(_save):
		return

	var candidates: Array[Monster] = []
	for node in get_tree().get_nodes_in_group("monsters"):
		if not node is Monster:
			continue
		var m := node as Monster
		if m.kind == SpawnEntry.Kind.JUNK:
			candidates.append(m)
		elif m.kind == SpawnEntry.Kind.NORMAL and m.get_level() <= 2:
			candidates.append(m)

	if candidates.is_empty():
		return

	candidates.sort_custom(func(a: Monster, b: Monster) -> bool:
		var ra: float = a.get_visual_data()["radius"]
		var rb: float = b.get_visual_data()["radius"]
		if absf(ra - rb) > 0.01:
			return ra < rb
		if a.kind == SpawnEntry.Kind.JUNK and b.kind != SpawnEntry.Kind.JUNK:
			return true
		return a.get_level() < b.get_level()
	)

	var remove_count := mini(randi_range(2, 3), candidates.size())
	if not UpgradeShop.use_bomb(_save):
		return

	var center := Vector2.ZERO
	for i in range(remove_count):
		center += candidates[i].global_position
		candidates[i].queue_free()
	center /= float(remove_count)

	effects.play_explosion(center, 0)
	_save_session()
	_update_ui()


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
	if pause_panel.visible or upgrades_panel.visible or revive_offer_panel.visible or game_over_panel.visible:
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
	_spawn_from_entry(current_entry, Vector2(drop_x, drop_y))
	_drops_count += 1
	_advance_queue()
	_cooldown_timer = MonsterData.get_spawn_cooldown(_round_time)
	can_drop = false
	_save_session()


func _spawn_from_entry(entry: SpawnEntry, pos: Vector2) -> Monster:
	var monster: Monster = MONSTER_SCENE.instantiate()
	monster.setup_from_entry(entry)
	monster.global_position = pos
	monster.merged.connect(_on_monster_merged)
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
	_save.total_merges += 1

	var level_1based := new_level + 1
	if CoinRewards.MILESTONE_BONUSES.has(level_1based) and not _round_milestones.has(level_1based):
		_round_milestones.append(level_1based)

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
	_save_session()


func _on_junk_destroyed(pos: Vector2) -> void:
	effects.play_particles(pos, Color(0.5, 0.5, 0.5, 0.8), 6)


func _show_combo(multiplier: int) -> void:
	combo_label.text = "COMBO x%d" % multiplier
	combo_label.visible = true
	combo_label.scale = Vector2(1.4, 1.4)
	var tween := combo_label.create_tween()
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
	_combo_hide_timer = 1.5
	AudioManager.play_combo()


func _update_previews() -> void:
	var current_visual := MonsterData.get_visual_for_entry(current_entry)
	preview_current.texture = current_visual["sprite"]
	var cs = current_visual["scale"]
	preview_current.scale = cs if cs is Vector2 else Vector2(cs, cs)

	var next_visual := MonsterData.get_visual_for_entry(next_entry)
	next_preview.texture = next_visual["sprite"]
	var ns = next_visual["scale"]
	var preview_scale: float = ns if ns is float else (ns as Vector2).x
	var preview_size := 36.0
	next_preview.custom_minimum_size = Vector2(preview_size, preview_size)
	next_preview.scale = Vector2.ONE


func _update_ui() -> void:
	score_label.text = "%s: %d" % [Locale.get_text("score"), score]
	best_label.text = "%s: %d" % [Locale.get_text("best"), _save.best_score]
	coins_value_label.text = str(_save.coins)
	bomb_button.visible = _save.bomb_count > 0
	bomb_count_label.visible = _save.bomb_count > 0
	if _save.bomb_count > 0:
		bomb_count_label.text = Locale.get_text("bomb_count") % _save.bomb_count
		bomb_button.disabled = state != State.PLAYING


func _update_settings_ui() -> void:
	var sound_icon := UIHelpers.get_sound_icon(Locale.sound_enabled)
	var sound_tip := Locale.get_text("sound_on" if Locale.sound_enabled else "sound_off")
	hud_sound_btn.icon = sound_icon
	hud_sound_btn.tooltip_text = sound_tip
	pause_sound_btn.icon = sound_icon
	pause_sound_btn.tooltip_text = sound_tip

	var lang_icon := UIHelpers.get_lang_icon(Locale.language)
	var lang_tip := "%s (%s)" % [
		Locale.get_text("language"),
		Locale.get_text("lang_ru" if Locale.language == "ru" else "lang_en"),
	]
	pause_lang_btn.icon = lang_icon
	pause_lang_btn.tooltip_text = lang_tip


func _update_upgrades_ui() -> void:
	UpgradesPanel.update_ui(
		_save,
		upgrades_coins_label,
		extra_life_btn,
		coin_bonus_btn,
		combo_duration_btn,
		bomb_unlock_btn
	)


func _entry_to_dict(entry: SpawnEntry) -> Dictionary:
	return {"kind": entry.kind, "level_index": entry.level_index}


func _entry_from_dict(data: Dictionary) -> SpawnEntry:
	var kind: int = data.get("kind", SpawnEntry.Kind.NORMAL)
	match kind:
		SpawnEntry.Kind.JUNK:
			return SpawnEntry.junk()
		SpawnEntry.Kind.BOMB:
			return SpawnEntry.bomb()
		_:
			return SpawnEntry.normal(data.get("level_index", 0))


func _save_session() -> void:
	if state == State.GAME_OVER:
		return

	var monsters_data: Array = []
	for node in monsters_root.get_children():
		if not node is Monster:
			continue
		var m := node as Monster
		monsters_data.append({
			"x": m.global_position.x,
			"y": m.global_position.y,
			"level": m.level,
			"kind": m.kind,
			"lv_x": m.linear_velocity.x,
			"lv_y": m.linear_velocity.y,
			"av": m.angular_velocity,
		})

	_save.save_session({
		"score": score,
		"highest_level": highest_level,
		"round_time": _round_time,
		"drops_count": _drops_count,
		"revive_used": _revive_used,
		"round_milestones": _round_milestones.duplicate(),
		"current_entry": _entry_to_dict(current_entry),
		"next_entry": _entry_to_dict(next_entry),
		"drop_x": drop_x,
		"cooldown_timer": _cooldown_timer,
		"danger_timer": _danger_timer,
		"monsters": monsters_data,
	})


func _restore_session(data: Dictionary) -> void:
	state = State.PLAYING
	score = data.get("score", 0)
	highest_level = data.get("highest_level", 0)
	_round_time = data.get("round_time", 0.0)
	_drops_count = data.get("drops_count", 0)
	_revive_used = data.get("revive_used", data.get("extra_life_used", false))
	_round_milestones = []
	for m in data.get("round_milestones", []):
		_round_milestones.append(int(m))
	drop_x = data.get("drop_x", (container_left + container_right) * 0.5)
	_cooldown_timer = data.get("cooldown_timer", 0.0)
	_danger_timer = data.get("danger_timer", 0.0)
	can_drop = _cooldown_timer <= 0.0

	current_entry = _entry_from_dict(data.get("current_entry", {}))
	next_entry = _entry_from_dict(data.get("next_entry", {}))

	_combo_tracker.window = UpgradeShop.get_combo_window(_save.combo_duration_level)
	_combo_tracker.reset()
	_danger_feedback.reset()
	aim_line.visible = true
	_clear_monsters()

	for md in data.get("monsters", []):
		var entry := _entry_from_dict({"kind": md.get("kind", 0), "level_index": md.get("level", 0)})
		var monster := _spawn_from_entry(entry, Vector2(md.get("x", 0.0), md.get("y", 0.0)))
		monster.linear_velocity = Vector2(md.get("lv_x", 0.0), md.get("lv_y", 0.0))
		monster.angular_velocity = md.get("av", 0.0)

	_hide_all_panels()
	_update_previews()
	_update_ui()
	YandexManager.notify_gameplay_started()
	AudioManager.set_gameplay_active(true)

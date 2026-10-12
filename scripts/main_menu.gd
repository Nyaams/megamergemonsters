extends Control

const MERGE_GUIDE_SCENE := preload("res://scenes/merge_guide.tscn")
const LEADERBOARD_SCENE := preload("res://scenes/leaderboard_panel.tscn")

@onready var logo: TextureRect = $RootVBox/Logo
@onready var auth_btn: Button = $RootVBox/AuthButton
@onready var start_btn: Button = $RootVBox/MenuPanel/MenuVBox/StartButton
@onready var continue_btn: Button = $RootVBox/MenuPanel/MenuVBox/ContinueButton
@onready var upgrades_btn: Button = $RootVBox/MenuPanel/MenuVBox/UpgradesButton
@onready var settings_btn: Button = $RootVBox/MenuPanel/MenuVBox/SettingsButton
@onready var leaderboard_btn: Button = $RootVBox/MenuPanel/MenuVBox/LeaderboardButton
@onready var rules_btn: Button = $RootVBox/MenuPanel/MenuVBox/RulesButton

@onready var rules_panel: Control = $RulesPanel
@onready var rules_title: Label = $RulesPanel/RulesFrame/RulesVBox/RulesTitle
@onready var rules_guide_host: Control = $RulesPanel/RulesFrame/RulesVBox/RulesGuideHost
@onready var rules_close_btn: Button = $RulesPanel/RulesFrame/RulesVBox/RulesCloseButton

@onready var upgrades_panel: Control = $UpgradesPanel
@onready var settings_panel: Control = $SettingsPanel

@onready var upgrades_coins_label: Label = $UpgradesPanel/UpgradesVBox/UpgradesCoinsLabel
@onready var extra_life_btn: Button = $UpgradesPanel/UpgradesVBox/ExtraLifeButton
@onready var coin_bonus_btn: Button = $UpgradesPanel/UpgradesVBox/CoinBonusButton
@onready var combo_duration_btn: Button = $UpgradesPanel/UpgradesVBox/ComboDurationButton
@onready var bomb_unlock_btn: Button = $UpgradesPanel/UpgradesVBox/BombUnlockButton
@onready var upgrades_close_btn: Button = $UpgradesPanel/UpgradesVBox/UpgradesCloseButton

@onready var sound_btn: Button = $SettingsPanel/SettingsVBox/SoundButton
@onready var language_btn: Button = $SettingsPanel/SettingsVBox/LanguageButton
@onready var settings_close_btn: Button = $SettingsPanel/SettingsVBox/SettingsCloseButton
@onready var settings_title: Label = $SettingsPanel/SettingsVBox/SettingsTitle
@onready var upgrades_title: Label = $UpgradesPanel/UpgradesVBox/UpgradesTitle

var _save := SaveData.new()
var _leaderboard_panel: Control


func _ready() -> void:
	_save.load()
	YandexManager.load_cloud_save_async(_save)
	Locale.load_from_save(_save)
	AudioManager.apply_settings()

	UIHelpers.wrap_panel($UpgradesPanel/UpgradesVBox)
	UIHelpers.wrap_panel($SettingsPanel/SettingsVBox)
	UIHelpers.apply_readable_tree(self)

	var guide := MERGE_GUIDE_SCENE.instantiate()
	rules_guide_host.add_child(guide)
	guide.set_anchors_preset(Control.PRESET_FULL_RECT)

	_leaderboard_panel = LEADERBOARD_SCENE.instantiate()
	add_child(_leaderboard_panel)

	start_btn.pressed.connect(_on_start_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	upgrades_btn.pressed.connect(_on_upgrades_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	leaderboard_btn.pressed.connect(_on_leaderboard_pressed)
	rules_btn.pressed.connect(_on_rules_pressed)
	auth_btn.pressed.connect(func(): YandexManager.offer_auth())
	upgrades_close_btn.pressed.connect(func(): upgrades_panel.hide())
	settings_close_btn.pressed.connect(func(): settings_panel.hide())
	rules_close_btn.pressed.connect(func(): rules_panel.hide())
	extra_life_btn.pressed.connect(_on_buy_extra_life)
	coin_bonus_btn.pressed.connect(_on_buy_coin_bonus)
	combo_duration_btn.pressed.connect(_on_buy_combo_duration)
	bomb_unlock_btn.pressed.connect(_on_buy_bomb)
	sound_btn.pressed.connect(_on_toggle_sound)
	language_btn.pressed.connect(_on_toggle_language)

	YandexManager.sdk_ready.connect(func(): YandexManager.notify_loading_ready())
	YandexManager.cloud_loaded.connect(_on_cloud_loaded)

	_apply_locale()
	_update_continue_button()
	_update_settings_ui()


func _apply_locale() -> void:
	logo.texture = UIHelpers.get_logo_texture()
	auth_btn.text = Locale.get_text("auth_login")
	start_btn.text = Locale.get_text("start_game")
	continue_btn.text = Locale.get_text("continue_game")
	upgrades_btn.text = Locale.get_text("upgrades")
	settings_btn.text = Locale.get_text("settings")
	leaderboard_btn.text = Locale.get_text("leaderboard")
	rules_btn.text = Locale.get_text("rules")
	rules_title.text = Locale.get_text("rules")
	upgrades_title.text = Locale.get_text("upgrades")
	settings_title.text = Locale.get_text("settings")
	upgrades_close_btn.text = Locale.get_text("close")
	settings_close_btn.text = Locale.get_text("close")
	rules_close_btn.text = Locale.get_text("close")


func _update_continue_button() -> void:
	continue_btn.disabled = not _save.has_active_session


func _on_cloud_loaded(_data: Dictionary) -> void:
	Locale.load_from_save(_save)
	AudioManager.apply_settings()
	_apply_locale()
	_update_continue_button()
	_update_settings_ui()


func _on_start_pressed() -> void:
	_save.clear_session()
	_save.save()
	GameFlow.start_new_game()


func _on_continue_pressed() -> void:
	if not _save.has_active_session:
		return
	GameFlow.continue_game()


func _on_upgrades_pressed() -> void:
	_update_upgrades_ui()
	upgrades_panel.show()


func _on_settings_pressed() -> void:
	_update_settings_ui()
	settings_panel.show()


func _on_rules_pressed() -> void:
	rules_panel.show()


func _on_leaderboard_pressed() -> void:
	if _leaderboard_panel.has_method("open"):
		_leaderboard_panel.open(_save.best_score)


func _update_upgrades_ui() -> void:
	UpgradesPanel.update_ui(
		_save,
		upgrades_coins_label,
		extra_life_btn,
		coin_bonus_btn,
		combo_duration_btn,
		bomb_unlock_btn
	)


func _update_settings_ui() -> void:
	sound_btn.text = Locale.get_text("sound_on") if Locale.sound_enabled else Locale.get_text("sound_off")
	language_btn.text = "%s: %s" % [
		Locale.get_text("language"),
		Locale.get_text("lang_ru") if Locale.language == "ru" else Locale.get_text("lang_en"),
	]


func _on_buy_extra_life() -> void:
	if UpgradeShop.buy_extra_life(_save):
		_update_upgrades_ui()


func _on_buy_coin_bonus() -> void:
	if UpgradeShop.buy_coin_bonus(_save):
		_update_upgrades_ui()


func _on_buy_combo_duration() -> void:
	if UpgradeShop.buy_combo_duration(_save):
		_update_upgrades_ui()


func _on_buy_bomb() -> void:
	if UpgradeShop.buy_bomb(_save):
		_update_upgrades_ui()


func _on_toggle_sound() -> void:
	Locale.sound_enabled = not Locale.sound_enabled
	Locale.apply_to_save(_save)
	_save.save()
	AudioManager.apply_settings()
	_update_settings_ui()


func _on_toggle_language() -> void:
	Locale.language = "en" if Locale.language == "ru" else "ru"
	Locale.apply_to_save(_save)
	_save.save()
	_apply_locale()
	_update_settings_ui()
	_update_upgrades_ui()

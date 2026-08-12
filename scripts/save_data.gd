class_name SaveData
extends RefCounted

const SAVE_PATH := "user://save.cfg"

var coins: int = 0
var best_score: int = 0
var coin_bonus_level: int = 0
var combo_duration_level: int = 0
var extra_life_owned: bool = false
var bomb_owned: bool = false
var milestones: Array = []
var prestige_level: int = 0
var sound_enabled: bool = true
var language: String = "ru"
var has_active_session: bool = false
var session_data: Dictionary = {}


func load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	coins = config.get_value("game", "coins", 0)
	best_score = config.get_value("game", "best_score", 0)
	coin_bonus_level = config.get_value("game", "coin_bonus_level", 0)
	combo_duration_level = config.get_value("game", "combo_duration_level", 0)
	extra_life_owned = config.get_value("game", "extra_life_owned", false)
	bomb_owned = config.get_value("game", "bomb_owned", false)
	milestones = config.get_value("game", "milestones", [])
	prestige_level = config.get_value("game", "prestige_level", 0)
	sound_enabled = config.get_value("game", "sound_enabled", true)
	language = config.get_value("game", "language", "ru")
	has_active_session = config.get_value("session", "active", false)
	session_data = config.get_value("session", "data", {})


func save() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("game", "coins", coins)
	config.set_value("game", "best_score", best_score)
	config.set_value("game", "coin_bonus_level", coin_bonus_level)
	config.set_value("game", "combo_duration_level", combo_duration_level)
	config.set_value("game", "extra_life_owned", extra_life_owned)
	config.set_value("game", "bomb_owned", bomb_owned)
	config.set_value("game", "milestones", milestones)
	config.set_value("game", "prestige_level", prestige_level)
	config.set_value("game", "sound_enabled", sound_enabled)
	config.set_value("game", "language", language)
	config.set_value("session", "active", has_active_session)
	config.set_value("session", "data", session_data)
	config.save(SAVE_PATH)


func unlock_milestones(levels: Array[int]) -> void:
	for level in levels:
		if CoinRewards.MILESTONE_BONUSES.has(level) and not milestones.has(level):
			milestones.append(level)


func save_session(data: Dictionary) -> void:
	has_active_session = true
	session_data = data
	save()


func clear_session() -> void:
	has_active_session = false
	session_data = {}
	save()

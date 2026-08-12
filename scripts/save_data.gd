class_name SaveData
extends RefCounted

const SAVE_PATH := "user://save.cfg"
const CLOUD_KEY := "save_blob"

var coins: int = 0
var best_score: int = 0
var coin_bonus_level: int = 0
var combo_duration_level: int = 0
var extra_life_owned: bool = false
var bomb_count: int = 0
var milestones: Array = []
var prestige_level: int = 0
var sound_enabled: bool = true
var language: String = "ru"
var has_active_session: bool = false
var session_data: Dictionary = {}
var total_games: int = 0
var total_score: int = 0
var total_merges: int = 0
var cloud_updated_at: int = 0


func load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	coins = config.get_value("game", "coins", 0)
	best_score = config.get_value("game", "best_score", 0)
	coin_bonus_level = config.get_value("game", "coin_bonus_level", 0)
	combo_duration_level = config.get_value("game", "combo_duration_level", 0)
	extra_life_owned = config.get_value("game", "extra_life_owned", false)
	bomb_count = config.get_value("game", "bomb_count", -1)
	if bomb_count < 0:
		var legacy_owned: bool = config.get_value("game", "bomb_owned", false)
		bomb_count = 1 if legacy_owned else 0
	milestones = config.get_value("game", "milestones", [])
	prestige_level = config.get_value("game", "prestige_level", 0)
	sound_enabled = config.get_value("game", "sound_enabled", true)
	language = config.get_value("game", "language", "ru")
	total_games = config.get_value("stats", "total_games", 0)
	total_score = config.get_value("stats", "total_score", 0)
	total_merges = config.get_value("stats", "total_merges", 0)
	cloud_updated_at = config.get_value("meta", "cloud_updated_at", 0)
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
	config.set_value("game", "bomb_count", bomb_count)
	config.set_value("game", "milestones", milestones)
	config.set_value("game", "prestige_level", prestige_level)
	config.set_value("game", "sound_enabled", sound_enabled)
	config.set_value("game", "language", language)
	config.set_value("stats", "total_games", total_games)
	config.set_value("stats", "total_score", total_score)
	config.set_value("stats", "total_merges", total_merges)
	config.set_value("meta", "cloud_updated_at", cloud_updated_at)
	config.set_value("session", "active", has_active_session)
	config.set_value("session", "data", session_data)
	config.save(SAVE_PATH)
	if YandexManager:
		YandexManager.queue_cloud_save(self)


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


func to_cloud_dict() -> Dictionary:
	return {
		"coins": coins,
		"best_score": best_score,
		"coin_bonus_level": coin_bonus_level,
		"combo_duration_level": combo_duration_level,
		"extra_life_owned": extra_life_owned,
		"bomb_count": bomb_count,
		"milestones": milestones.duplicate(),
		"prestige_level": prestige_level,
		"sound_enabled": sound_enabled,
		"language": language,
		"total_games": total_games,
		"total_score": total_score,
		"total_merges": total_merges,
		"updated_at": Time.get_unix_time_from_system(),
	}


func from_cloud_dict(data: Dictionary) -> void:
	coins = int(data.get("coins", coins))
	best_score = int(data.get("best_score", best_score))
	coin_bonus_level = int(data.get("coin_bonus_level", coin_bonus_level))
	combo_duration_level = int(data.get("combo_duration_level", combo_duration_level))
	extra_life_owned = bool(data.get("extra_life_owned", extra_life_owned))
	bomb_count = int(data.get("bomb_count", bomb_count))
	milestones = data.get("milestones", milestones)
	prestige_level = int(data.get("prestige_level", prestige_level))
	sound_enabled = bool(data.get("sound_enabled", sound_enabled))
	language = str(data.get("language", language))
	total_games = int(data.get("total_games", total_games))
	total_score = int(data.get("total_score", total_score))
	total_merges = int(data.get("total_merges", total_merges))
	cloud_updated_at = int(data.get("updated_at", cloud_updated_at))


func merge_from_cloud(cloud: Dictionary) -> void:
	var cloud_ts := int(cloud.get("updated_at", 0))
	if cloud_ts >= cloud_updated_at:
		from_cloud_dict(cloud)
		cloud_updated_at = cloud_ts
		save()

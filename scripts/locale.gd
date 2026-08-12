extends Node

## Autoload-friendly locale + sound flag holder.

const STRINGS: Dictionary = {
	"ru": {
		"score": "Счёт",
		"best": "Рекорд",
		"coins": "Монеты",
		"next": "СЛЕД.",
		"pause": "Пауза",
		"settings": "Настройки",
		"restart": "Рестарт",
		"resume": "Продолжить",
		"game_over": "Игра окончена",
		"play_again": "Играть снова",
		"continue_life": "Продолжить",
		"upgrades": "Улучшения",
		"close": "Закрыть",
		"sound": "Звук",
		"sound_on": "Звук: вкл",
		"sound_off": "Звук: выкл",
		"language": "Язык",
		"lang_ru": "Русский",
		"lang_en": "English",
		"main_menu": "Главное меню",
		"start_game": "Начать игру",
		"continue_game": "Продолжить игру",
		"extra_life": "Доп. жизнь",
		"coin_bonus": "Бонус монет",
		"combo_duration": "Длина комбо",
		"bomb_unlock": "Бомба",
		"bomb_owned": "Бомба (куплена)",
		"owned": "куплено",
		"max": "МАКС",
	},
	"en": {
		"score": "Score",
		"best": "Best",
		"coins": "Coins",
		"next": "NEXT",
		"pause": "Pause",
		"settings": "Settings",
		"restart": "Restart",
		"resume": "Resume",
		"game_over": "Game Over",
		"play_again": "Play Again",
		"continue_life": "Continue",
		"upgrades": "Upgrades",
		"close": "Close",
		"sound": "Sound",
		"sound_on": "Sound: on",
		"sound_off": "Sound: off",
		"language": "Language",
		"lang_ru": "Russian",
		"lang_en": "English",
		"main_menu": "Main Menu",
		"start_game": "Start Game",
		"continue_game": "Continue Game",
		"extra_life": "Extra Life",
		"coin_bonus": "Coin Bonus",
		"combo_duration": "Combo Duration",
		"bomb_unlock": "Bomb",
		"bomb_owned": "Bomb (owned)",
		"owned": "owned",
		"max": "MAX",
	},
}

var language: String = "ru"
var sound_enabled: bool = true


func get_text(key: String) -> String:
	var lang_table: Dictionary = STRINGS.get(language, STRINGS["en"])
	return lang_table.get(key, key)


func load_from_save(save: SaveData) -> void:
	language = save.language
	sound_enabled = save.sound_enabled


func apply_to_save(save: SaveData) -> void:
	save.language = language
	save.sound_enabled = sound_enabled

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
		"sound_tooltip": "Звук (вкл / выкл)",
		"language": "Язык",
		"lang_ru": "Русский",
		"lang_en": "English",
		"lang_tooltip": "Сменить язык (RU / EN)",
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
		"merge_hint": "Одинаковые монстры сливаются",
		"bomb_buy_first": "Бомба +1 — %d",
		"bomb_buy_refill": "Бомба +1 — %d",
		"bomb_count": "x%d",
		"watch_ad_continue": "▶ Смотреть рекламу",
		"leaderboard": "Лидеры",
		"leaderboard_title": "🏆 ЛИДЕРЫ",
		"your_score": "Ваш результат",
		"login_for_lb": "Войдите для онлайн-рейтинга",
		"auth_login": "Войти в аккаунт",
		"rules": "Правила",
		"rules_title": "ПРАВИЛА ИГРЫ",
		"rule_1": "1. Перемещайте и сбрасывайте монстров в котёл.",
		"rule_2": "2. Одинаковые монстры сливаются в более крупного.",
		"rule_3": "3. Не позволяйте котлу переполниться выше красной линии!",
		"rule_4": "4. Делайте комбо и используйте бомбы для рекорда.",
		"merge_chain_title": "Схема слияния:",
		"loading": "Загрузка...",
		"rank_format": "#%d",
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
		"sound_tooltip": "Sound (on / off)",
		"language": "Language",
		"lang_ru": "Russian",
		"lang_en": "English",
		"lang_tooltip": "Change language (RU / EN)",
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
		"merge_hint": "Same monsters merge together",
		"bomb_buy_first": "Bomb +1 — %d",
		"bomb_buy_refill": "Bomb +1 — %d",
		"bomb_count": "x%d",
		"watch_ad_continue": "▶ Watch ad",
		"leaderboard": "Leaders",
		"leaderboard_title": "🏆 LEADERS",
		"your_score": "Your score",
		"login_for_lb": "Sign in for online ranking",
		"auth_login": "Sign in to account",
		"rules": "Rules",
		"rules_title": "HOW TO PLAY",
		"rule_1": "1. Aim and drop monsters into the cauldron.",
		"rule_2": "2. Matching monsters merge into a bigger one.",
		"rule_3": "3. Don't let monsters overflow above the red line!",
		"rule_4": "4. Build combos and use bombs to set high scores.",
		"merge_chain_title": "Merge chain:",
		"loading": "Loading...",
		"rank_format": "#%d",
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

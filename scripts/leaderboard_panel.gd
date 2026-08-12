extends Control

@onready var title_label: Label = $PanelFrame/LeaderboardVBox/TitleLabel
@onready var entries_label: Label = $PanelFrame/LeaderboardVBox/EntriesLabel
@onready var player_label: Label = $PanelFrame/LeaderboardVBox/PlayerLabel
@onready var close_btn: Button = $PanelFrame/LeaderboardVBox/CloseButton

var _local_best := 0


func _ready() -> void:
	close_btn.pressed.connect(hide)
	YandexManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
	hide()


func open(local_best: int) -> void:
	_local_best = local_best
	title_label.text = Locale.get_text("leaderboard_title")
	close_btn.text = Locale.get_text("close")
	entries_label.text = Locale.get_text("loading")
	player_label.text = "%s: %d" % [Locale.get_text("your_score"), local_best]
	show()
	YandexManager.fetch_leaderboard()


func _on_leaderboard_loaded(data: Dictionary) -> void:
	if data.get("offline", false) or not data.has("entries"):
		entries_label.text = Locale.get_text("login_for_lb")
		player_label.text = "%s: %d" % [Locale.get_text("your_score"), _local_best]
		return

	var lines: PackedStringArray = []
	var entries: Array = data.get("entries", [])
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var player: Dictionary = entry.get("player", {})
		var name: String = str(player.get("publicName", "???"))
		var sc: int = int(entry.get("score", 0))
		var rank: int = int(entry.get("rank", i)) + 1
		lines.append("%d. %-12s %s" % [rank, name.substr(0, 12), _format_score(sc)])

	entries_label.text = "\n".join(lines) if lines.size() > 0 else "—"

	var user_rank: int = int(data.get("userRank", 0))
	if user_rank > 0:
		player_label.text = "%s: %s  %s" % [
			Locale.get_text("your_score"),
			_format_score(_local_best),
			Locale.get_text("rank_format") % user_rank,
		]
	else:
		player_label.text = "%s: %s" % [Locale.get_text("your_score"), _format_score(_local_best)]


func _format_score(value: int) -> String:
	var s := str(value)
	if s.length() <= 3:
		return s
	var parts: PackedStringArray = []
	while s.length() > 3:
		parts.insert(0, s.substr(s.length() - 3, 3))
		s = s.substr(0, s.length() - 3)
	if s.length() > 0:
		parts.insert(0, s)
	return " ".join(parts)

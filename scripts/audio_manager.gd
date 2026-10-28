extends Node

const BG_MUSIC := preload("res://audio/bg_music.mp3")
const BOILING := preload("res://audio/boiling.wav")
const MERGE := preload("res://audio/merge.wav")
const COMBO := preload("res://audio/combo.wav")
const GAME_OVER := preload("res://audio/game_over.wav")

var _bg: AudioStreamPlayer
var _boiling: AudioStreamPlayer
var _sfx: AudioStreamPlayer


func _ready() -> void:
	_bg = _make_player()
	_boiling = _make_player()
	_sfx = _make_player()

	var bg_stream := BG_MUSIC.duplicate()
	if bg_stream is AudioStreamMP3:
		bg_stream.loop = true
	_bg.stream = bg_stream

	var boiling_stream := BOILING.duplicate()
	if boiling_stream is AudioStreamWAV:
		boiling_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_boiling.stream = boiling_stream

	apply_settings()
	_play_bg()


func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	return p


static func set_master_mute(mute: bool) -> void:
	if AudioServer.get_bus_count() <= 0:
		return
	var idx := AudioServer.get_bus_index("Master")
	if idx < 0:
		idx = 0
	if idx >= 0 and idx < AudioServer.get_bus_count():
		AudioServer.set_bus_mute(idx, mute)


func apply_settings() -> void:
	var muted := not Locale.sound_enabled
	set_master_mute(muted)
	if muted:
		_bg.stop()
		_boiling.stop()
	elif not _bg.playing:
		_play_bg()


func _play_bg() -> void:
	if not Locale.sound_enabled:
		return
	_bg.volume_db = 0.0
	_bg.play()


func set_gameplay_active(active: bool) -> void:
	if not Locale.sound_enabled:
		return
	if active:
		if not _boiling.playing:
			_boiling.volume_db = 0.0
			_boiling.play()
	else:
		_boiling.stop()


func play_merge() -> void:
	_play_sfx(MERGE)


func play_combo() -> void:
	_play_sfx(COMBO)


func play_game_over() -> void:
	_boiling.stop()
	_play_sfx(GAME_OVER)


func _play_sfx(stream: AudioStream) -> void:
	if not Locale.sound_enabled:
		return
	_sfx.stream = stream
	_sfx.play()

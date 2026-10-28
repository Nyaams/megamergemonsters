extends Node

signal sdk_ready
signal platform_pause
signal platform_resume
signal cloud_loaded(data: Dictionary)
signal leaderboard_loaded(data: Dictionary)
signal language_detected(lang_code: String)

const LEADERBOARD_NAME := "bestScore"
const CLOUD_DEBOUNCE := 3.0
const INTERSTITIAL_COOLDOWN := 65.0

var is_web := false
var sdk_initialized := false
var player_authorized := false
var environment_language: String = "ru"

var _gameplay_active := false
var _pending_save: SaveData = null
var _cloud_timer := 0.0
var _init_done := false
var _loading_ready_pending := false
var _last_interstitial_time: float = -100.0

var _window_interface: JavaScriptObject = null
var _pause_cb: JavaScriptObject = null
var _resume_cb: JavaScriptObject = null
var _mute_cb: JavaScriptObject = null
var _unmute_cb: JavaScriptObject = null
var _interstitial_cb: JavaScriptObject = null
var _rewarded_reward_cb: JavaScriptObject = null
var _rewarded_close_cb: JavaScriptObject = null

var _init_pending := false
var _cloud_loading_save: SaveData = null
var _auth_pending := false
var _player_pending := false
var _leaderboard_pending := false


func _ready() -> void:
	is_web = OS.has_feature("web")
	if is_web:
		_setup_js_callbacks()
		_init_sdk_web()
	else:
		sdk_initialized = true
		_init_done = true
		sdk_ready.emit()


func _setup_js_callbacks() -> void:
	_window_interface = JavaScriptBridge.get_interface("window")
	if _window_interface == null:
		return

	_pause_cb = JavaScriptBridge.create_callback(func(_args):
		AudioManager.set_master_mute(true)
		platform_pause.emit()
	)
	_resume_cb = JavaScriptBridge.create_callback(func(_args):
		AudioManager.set_master_mute(not Locale.sound_enabled)
		platform_resume.emit()
	)
	_mute_cb = JavaScriptBridge.create_callback(func(_args):
		AudioManager.set_master_mute(true)
	)
	_unmute_cb = JavaScriptBridge.create_callback(func(_args):
		AudioManager.set_master_mute(not Locale.sound_enabled)
	)

	_window_interface.call("setGodotCallbacks", _pause_cb, _resume_cb, _mute_cb, _unmute_cb)


func _init_sdk_web() -> void:
	var early_lang: Variant = JavaScriptBridge.eval("window.YandexBridge ? window.YandexBridge.getLanguage() : ''", true)
	if early_lang != null and str(early_lang) != "":
		environment_language = str(early_lang)

	_init_pending = true
	JavaScriptBridge.eval("""
		(async () => {
			if (!window.YandexBridge) {
				window.godotYandexInitResult = JSON.stringify({ ok: false });
				return;
			}
			const r = await window.YandexBridge.init();
			window.godotYandexInitResult = JSON.stringify(r);
		})();
	""", true)


func get_sdk_language() -> String:
	if is_web:
		var raw: Variant = JavaScriptBridge.eval("window.YandexBridge ? window.YandexBridge.getLanguage() : ''", true)
		if raw != null and str(raw) != "":
			return str(raw)
	if environment_language != "":
		return environment_language
	return "ru"


func notify_loading_ready() -> void:
	_loading_ready_pending = true
	if is_web and sdk_initialized:
		JavaScriptBridge.eval("window.YandexBridge && window.YandexBridge.loadingReady();", true)


func notify_gameplay_started() -> void:
	if _gameplay_active:
		return
	_gameplay_active = true
	if is_web and sdk_initialized:
		JavaScriptBridge.eval("window.YandexBridge && window.YandexBridge.gameplayStart();", true)


func notify_gameplay_stopped() -> void:
	if not _gameplay_active:
		return
	_gameplay_active = false
	if is_web and sdk_initialized:
		JavaScriptBridge.eval("window.YandexBridge && window.YandexBridge.gameplayStop();", true)


func queue_cloud_save(save: SaveData) -> void:
	if not sdk_initialized:
		return
	_pending_save = save
	_cloud_timer = CLOUD_DEBOUNCE


func _process(delta: float) -> void:
	if _cloud_timer > 0.0:
		_cloud_timer -= delta
		if _cloud_timer <= 0.0 and _pending_save:
			_push_cloud_save(_pending_save)
			_pending_save = null

	if is_web:
		_poll_web_tasks()


func _poll_web_tasks() -> void:
	if _init_pending:
		var raw: Variant = JavaScriptBridge.eval("window.godotYandexInitResult || null", true)
		if raw != null:
			_init_pending = false
			_init_done = true
			var result: Dictionary = JSON.parse_string(str(raw))
			sdk_initialized = bool(result.get("ok", false))
			if result.has("lang") and str(result["lang"]) != "":
				environment_language = str(result["lang"])
				language_detected.emit(environment_language)
			if sdk_initialized:
				_refresh_player_web()
				if _loading_ready_pending:
					notify_loading_ready()
			sdk_ready.emit()

	if _cloud_loading_save != null:
		var raw: Variant = JavaScriptBridge.eval("window.godotCloudResult || null", true)
		if raw != null:
			JavaScriptBridge.eval("window.godotCloudResult = null;", true)
			var data: Dictionary = JSON.parse_string(str(raw))
			if not data.is_empty():
				_cloud_loading_save.merge_from_cloud(data)
				_cloud_loading_save.save()
			cloud_loaded.emit(data)
			_cloud_loading_save = null

	if _auth_pending:
		var done: Variant = JavaScriptBridge.eval("window.godotAuthDone || null", true)
		if done != null:
			JavaScriptBridge.eval("window.godotAuthDone = null;", true)
			_auth_pending = false
			_refresh_player_web()

	if _player_pending:
		var raw: Variant = JavaScriptBridge.eval("window.godotPlayerInfo || null", true)
		if raw != null:
			JavaScriptBridge.eval("window.godotPlayerInfo = null;", true)
			var info: Dictionary = JSON.parse_string(str(raw))
			player_authorized = bool(info.get("authorized", false))
			_player_pending = false

	if _leaderboard_pending:
		var raw: Variant = JavaScriptBridge.eval("window.godotLeaderboardResult || null", true)
		if raw != null:
			JavaScriptBridge.eval("window.godotLeaderboardResult = null;", true)
			var data: Dictionary = JSON.parse_string(str(raw))
			leaderboard_loaded.emit(data)
			_leaderboard_pending = false


func load_cloud_save_async(save: SaveData) -> void:
	if not is_web or not sdk_initialized:
		cloud_loaded.emit({})
		return
	_cloud_loading_save = save
	JavaScriptBridge.eval("""
		(async () => {
			const p = await window.YandexBridge.getPlayer();
			if (!p) {
				window.godotCloudResult = JSON.stringify({});
				return;
			}
			const d = await window.YandexBridge.getData();
			window.godotCloudResult = JSON.stringify(d && d.save_blob ? d.save_blob : {});
		})();
	""", true)


func _push_cloud_save(save: SaveData) -> void:
	if not is_web or not sdk_initialized:
		return
	var payload := JSON.stringify(save.to_cloud_dict())
	JavaScriptBridge.eval("window._godotCloudPayload = %s;" % payload, true)
	JavaScriptBridge.eval("(async () => { await window.YandexBridge.setData(window._godotCloudPayload); })();", true)


func offer_auth() -> void:
	if not is_web or not sdk_initialized:
		return
	_auth_pending = true
	JavaScriptBridge.eval("""
		(async () => {
			await window.YandexBridge.openAuth();
			window.godotAuthDone = '1';
		})();
	""", true)


func _refresh_player_web() -> void:
	_player_pending = true
	JavaScriptBridge.eval("""
		(async () => {
			const p = await window.YandexBridge.getPlayer();
			window.godotPlayerInfo = JSON.stringify(p || { authorized: false });
		})();
	""", true)


func upload_score(score: int) -> void:
	if not is_web or not sdk_initialized or not player_authorized:
		return
	JavaScriptBridge.eval(
		"window.YandexBridge.setScore('%s', %d);" % [LEADERBOARD_NAME, score],
		true
	)


func fetch_leaderboard() -> void:
	if not is_web or not sdk_initialized:
		leaderboard_loaded.emit({ "offline": true })
		return
	_leaderboard_pending = true
	JavaScriptBridge.eval("""
		(async () => {
			const r = await window.YandexBridge.getEntries('%s');
			window.godotLeaderboardResult = JSON.stringify(r || { offline: true });
		})();
	""" % LEADERBOARD_NAME, true)


func show_interstitial(on_closed: Callable) -> void:
	notify_gameplay_stopped()
	if not is_web or not sdk_initialized:
		on_closed.call(false)
		return

	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - _last_interstitial_time < INTERSTITIAL_COOLDOWN:
		on_closed.call(false)
		return
	_last_interstitial_time = current_time

	AudioManager.set_master_mute(true)
	_interstitial_cb = JavaScriptBridge.create_callback(func(args):
		AudioManager.set_master_mute(not Locale.sound_enabled)
		var was_shown := false
		if args.size() > 0:
			was_shown = bool(args[0])
		on_closed.call(was_shown)
	)
	if _window_interface != null:
		var bridge = _window_interface.get("YandexBridge")
		if bridge != null:
			bridge.call("showFullscreenAdv", _interstitial_cb)
			return
	on_closed.call(false)


func show_rewarded(on_rewarded: Callable, on_closed: Callable) -> void:
	notify_gameplay_stopped()
	if not is_web or not sdk_initialized:
		on_closed.call(false)
		return

	AudioManager.set_master_mute(true)
	_rewarded_reward_cb = JavaScriptBridge.create_callback(func(_args): on_rewarded.call())
	_rewarded_close_cb = JavaScriptBridge.create_callback(func(args):
		AudioManager.set_master_mute(not Locale.sound_enabled)
		var was_shown := false
		if args.size() > 0:
			was_shown = bool(args[0])
		on_closed.call(was_shown)
	)
	if _window_interface != null:
		var bridge = _window_interface.get("YandexBridge")
		if bridge != null:
			bridge.call("showRewardedVideo", _rewarded_reward_cb, _rewarded_close_cb)
			return
	on_closed.call(false)

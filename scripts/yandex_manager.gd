extends Node

signal sdk_ready
signal platform_pause
signal platform_resume
signal cloud_loaded(data: Dictionary)
signal leaderboard_loaded(data: Dictionary)

const LEADERBOARD_NAME := "best_score"
const CLOUD_DEBOUNCE := 3.0

var is_web := false
var sdk_initialized := false
var player_authorized := false

var _gameplay_active := false
var _pending_save: SaveData = null
var _cloud_timer := 0.0
var _init_done := false


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
	var pause_cb := JavaScriptBridge.create_callback(func(_args): platform_pause.emit())
	var resume_cb := JavaScriptBridge.create_callback(func(_args): platform_resume.emit())
	JavaScriptBridge.eval("window.godotYandexPause = %s; window.godotYandexResume = %s;" % [pause_cb, resume_cb], true)


func _init_sdk_web() -> void:
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
	call_deferred("_poll_init")


func _poll_init() -> void:
	if _init_done:
		return
	var raw: Variant = JavaScriptBridge.eval("window.godotYandexInitResult || null", true)
	if raw == null:
		call_deferred("_poll_init")
		return
	var result: Dictionary = JSON.parse_string(str(raw))
	sdk_initialized = bool(result.get("ok", false))
	_init_done = true
	if sdk_initialized:
		_refresh_player_web()
	sdk_ready.emit()


func notify_loading_ready() -> void:
	pass


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
	if not sdk_initialized or not player_authorized:
		return
	_pending_save = save
	_cloud_timer = CLOUD_DEBOUNCE


func _process(delta: float) -> void:
	if _cloud_timer > 0.0:
		_cloud_timer -= delta
		if _cloud_timer <= 0.0 and _pending_save:
			_push_cloud_save(_pending_save)
			_pending_save = null


func load_cloud_save_async(save: SaveData) -> void:
	if not is_web or not sdk_initialized:
		cloud_loaded.emit({})
		return
	JavaScriptBridge.eval("""
		(async () => {
			const p = await window.YandexBridge.getPlayer();
			if (!p || !p.authorized) {
				window.godotCloudResult = JSON.stringify({});
				return;
			}
			const d = await window.YandexBridge.getData();
			window.godotCloudResult = JSON.stringify(d && d.save_blob ? d.save_blob : {});
		})();
	""", true)
	call_deferred("_poll_cloud", save)


func _poll_cloud(save: SaveData) -> void:
	var raw: Variant = JavaScriptBridge.eval("window.godotCloudResult", true)
	if raw == null:
		call_deferred("_poll_cloud", save)
		return
	var data: Dictionary = JSON.parse_string(str(raw))
	if not data.is_empty():
		save.merge_from_cloud(data)
		save.save()
	cloud_loaded.emit(data)


func _push_cloud_save(save: SaveData) -> void:
	if not is_web or not sdk_initialized or not player_authorized:
		return
	var payload := JSON.stringify(save.to_cloud_dict())
	JavaScriptBridge.eval("window._godotCloudPayload = %s;" % payload, true)
	JavaScriptBridge.eval("(async () => { await window.YandexBridge.setData(window._godotCloudPayload); })();", true)


func offer_auth() -> void:
	if not is_web or not sdk_initialized:
		return
	JavaScriptBridge.eval("""
		(async () => {
			await window.YandexBridge.openAuth();
			window.godotAuthDone = '1';
		})();
	""", true)
	call_deferred("_poll_auth")


func _poll_auth() -> void:
	var done: Variant = JavaScriptBridge.eval("window.godotAuthDone || null", true)
	if done == null:
		call_deferred("_poll_auth")
		return
	_refresh_player_web()


func _refresh_player_web() -> void:
	JavaScriptBridge.eval("""
		(async () => {
			const p = await window.YandexBridge.getPlayer();
			window.godotPlayerInfo = JSON.stringify(p || { authorized: false });
		})();
	""", true)
	call_deferred("_poll_player")


func _poll_player() -> void:
	var raw: Variant = JavaScriptBridge.eval("window.godotPlayerInfo", true)
	if raw == null:
		call_deferred("_poll_player")
		return
	var info: Dictionary = JSON.parse_string(str(raw))
	player_authorized = bool(info.get("authorized", false))


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
	JavaScriptBridge.eval("""
		(async () => {
			const r = await window.YandexBridge.getEntries('%s');
			window.godotLeaderboardResult = JSON.stringify(r || { offline: true });
		})();
	""" % LEADERBOARD_NAME, true)
	call_deferred("_poll_leaderboard")


func _poll_leaderboard() -> void:
	var raw: Variant = JavaScriptBridge.eval("window.godotLeaderboardResult", true)
	if raw == null:
		call_deferred("_poll_leaderboard")
		return
	var data: Dictionary = JSON.parse_string(str(raw))
	leaderboard_loaded.emit(data)


func show_interstitial(on_closed: Callable) -> void:
	notify_gameplay_stopped()
	if not is_web or not sdk_initialized:
		on_closed.call(false)
		return
	var cb := JavaScriptBridge.create_callback(func(args):
		var was_shown := false
		if args.size() > 0:
			was_shown = bool(args[0])
		on_closed.call(was_shown)
	)
	JavaScriptBridge.eval(
		"window.YandexBridge.showFullscreenAdv(%s);" % cb,
		true
	)


func show_rewarded(on_rewarded: Callable, on_closed: Callable) -> void:
	notify_gameplay_stopped()
	if not is_web or not sdk_initialized:
		on_closed.call(false)
		return
	var reward_cb := JavaScriptBridge.create_callback(func(_args): on_rewarded.call())
	var close_cb := JavaScriptBridge.create_callback(func(args):
		var was_shown := false
		if args.size() > 0:
			was_shown = bool(args[0])
		on_closed.call(was_shown)
	)
	JavaScriptBridge.eval(
		"window.YandexBridge.showRewardedVideo(%s, %s);" % [reward_cb, close_cb],
		true
	)

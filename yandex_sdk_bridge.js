// Yandex Games SDK bridge for Godot Web export.
window.YandexBridge = {
	ysdk: null,
	player: null,
	ready: false,
	_initPromise: null,

	init: function () {
		if (this.ready) {
			return Promise.resolve({ ok: true, lang: this.getLanguage() });
		}
		if (this._initPromise) {
			return this._initPromise;
		}
		this._initPromise = this._doInit();
		return this._initPromise;
	},

	_doInit: async function () {
		// Wait for YaGames script if still downloading
		if (typeof YaGames === 'undefined') {
			for (let i = 0; i < 35; i++) {
				await new Promise((r) => setTimeout(r, 100));
				if (typeof YaGames !== 'undefined') break;
			}
		}
		if (typeof YaGames === 'undefined') {
			return { ok: false, error: 'YaGames undefined' };
		}
		try {
			this.ysdk = await YaGames.init();
			this.ready = true;

			// Handle platform pause/resume
			this.ysdk.on('game_api_pause', () => {
				if (window.godotYandexPause) window.godotYandexPause();
			});
			this.ysdk.on('game_api_resume', () => {
				if (window.godotYandexResume) window.godotYandexResume();
			});

			// Handle browser tab switching
			document.addEventListener('visibilitychange', () => {
				if (document.hidden) {
					if (window.godotYandexPause) window.godotYandexPause();
				} else {
					if (window.godotYandexResume) window.godotYandexResume();
				}
			});

			return { ok: true, lang: this.getLanguage() };
		} catch (e) {
			return { ok: false, error: String(e) };
		}
	},

	loadingReady: function () {
		if (this.ysdk && this.ysdk.features && this.ysdk.features.LoadingAPI) {
			this.ysdk.features.LoadingAPI.ready();
		}
	},

	gameplayStart: function () {
		if (this.ysdk && this.ysdk.features && this.ysdk.features.GameplayAPI) {
			this.ysdk.features.GameplayAPI.start();
		}
	},

	gameplayStop: function () {
		if (this.ysdk && this.ysdk.features && this.ysdk.features.GameplayAPI) {
			this.ysdk.features.GameplayAPI.stop();
		}
	},

	getLanguage: function () {
		if (this.ysdk && this.ysdk.environment && this.ysdk.environment.i18n && this.ysdk.environment.i18n.lang) {
			return this.ysdk.environment.i18n.lang;
		}
		try {
			var params = new URLSearchParams(window.location.search);
			var urlLang = params.get('lang');
			if (urlLang) return urlLang;
		} catch (e) {}
		var nav = navigator.language || navigator.userLanguage || 'ru';
		return nav;
	},

	getPlayer: async function () {
		if (!this.ysdk) return null;
		try {
			this.player = await this.ysdk.getPlayer({ scopes: false });
			return {
				authorized: this.player.isAuthorized(),
				name: this.player.getName ? this.player.getName() : '',
				id: this.player.getUniqueID ? this.player.getUniqueID() : '',
			};
		} catch (e) {
			return null;
		}
	},

	openAuth: async function () {
		if (!this.ysdk || !this.ysdk.auth) return false;
		try {
			await this.ysdk.auth.openAuthDialog();
			this.player = await this.ysdk.getPlayer({ scopes: false });
			return this.player.isAuthorized();
		} catch (e) {
			return false;
		}
	},

	getData: async function () {
		if (!this.player) return null;
		try {
			return await this.player.getData(['save_blob']);
		} catch (e) {
			return null;
		}
	},

	setData: async function (data) {
		if (!this.player) return false;
		try {
			await this.player.setData({ save_blob: data }, false);
			return true;
		} catch (e) {
			return false;
		}
	},

	setScore: async function (leaderboardName, score) {
		if (!this.ysdk || !this.ysdk.leaderboards) return false;
		try {
			await this.ysdk.leaderboards.setScore(leaderboardName, score);
			return true;
		} catch (e) {
			return false;
		}
	},

	getEntries: async function (leaderboardName) {
		if (!this.ysdk || !this.ysdk.leaderboards) return null;
		try {
			return await this.ysdk.leaderboards.getEntries(leaderboardName, {
				quantityTop: 10,
				includeUser: true,
				quantityAround: 3,
			});
		} catch (e) {
			return null;
		}
	},

	showFullscreenAdv: function (onClose) {
		if (!this.ysdk || !this.ysdk.adv) {
			if (onClose) onClose(false);
			return;
		}
		if (window.godotYandexMute) window.godotYandexMute();
		try {
			this.ysdk.adv.showFullscreenAdv({
				callbacks: {
					onOpen: () => {
						if (window.godotYandexMute) window.godotYandexMute();
					},
					onClose: (wasShown) => {
						if (window.godotYandexUnmute) window.godotYandexUnmute();
						if (onClose) onClose(Boolean(wasShown));
					},
					onError: (err) => {
						console.warn('[YandexBridge] showFullscreenAdv onError:', err);
						if (window.godotYandexUnmute) window.godotYandexUnmute();
						if (onClose) onClose(false);
					},
				},
			});
		} catch (err) {
			console.warn('[YandexBridge] showFullscreenAdv exception:', err);
			if (window.godotYandexUnmute) window.godotYandexUnmute();
			if (onClose) onClose(false);
		}
	},

	showRewardedVideo: function (onRewarded, onClose) {
		if (!this.ysdk || !this.ysdk.adv) {
			if (onClose) onClose(false);
			return;
		}
		if (window.godotYandexMute) window.godotYandexMute();
		try {
			this.ysdk.adv.showRewardedVideo({
				callbacks: {
					onOpen: () => {
						if (window.godotYandexMute) window.godotYandexMute();
					},
					onRewarded: () => {
						if (onRewarded) onRewarded();
					},
					onClose: (wasShown) => {
						if (window.godotYandexUnmute) window.godotYandexUnmute();
						if (onClose) onClose(Boolean(wasShown));
					},
					onError: (err) => {
						console.warn('[YandexBridge] showRewardedVideo onError:', err);
						if (window.godotYandexUnmute) window.godotYandexUnmute();
						if (onClose) onClose(false);
					},
				},
			});
		} catch (err) {
			console.warn('[YandexBridge] showRewardedVideo exception:', err);
			if (window.godotYandexUnmute) window.godotYandexUnmute();
			if (onClose) onClose(false);
		}
	},

	call: function (methodName, ...args) {
		if (typeof this[methodName] === 'function') {
			return this[methodName].apply(this, args);
		}
		return undefined;
	},
};

window.call = function (methodName, ...args) {
	if (typeof window[methodName] === 'function') {
		return window[methodName].apply(window, args);
	}
	return undefined;
};

window.initSDK = function () {
	if (window.YandexBridge) {
		window.YandexBridge.init();
	}
};

window.setGodotCallbacks = function (pauseCb, resumeCb, muteCb, unmuteCb) {
	window.godotYandexPause = pauseCb;
	window.godotYandexResume = resumeCb;
	window.godotYandexMute = muteCb;
	window.godotYandexUnmute = unmuteCb;
};

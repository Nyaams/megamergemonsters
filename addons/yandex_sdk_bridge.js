// Yandex Games SDK bridge for Godot Web export.
window.YandexBridge = {
	ysdk: null,
	player: null,
	ready: false,

	init: async function () {
		if (typeof YaGames === 'undefined') {
			return { ok: false, error: 'YaGames undefined' };
		}
		try {
			this.ysdk = await YaGames.init();
			this.ready = true;
			if (this.ysdk.features && this.ysdk.features.LoadingAPI) {
				this.ysdk.features.LoadingAPI.ready();
			}
			this.ysdk.on('game_api_pause', () => {
				if (window.godotYandexPause) window.godotYandexPause();
			});
			this.ysdk.on('game_api_resume', () => {
				if (window.godotYandexResume) window.godotYandexResume();
			});
			return { ok: true };
		} catch (e) {
			return { ok: false, error: String(e) };
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

	getPlayer: async function () {
		if (!this.ysdk) return null;
		try {
			this.player = await this.ysdk.getPlayer();
			return {
				authorized: this.player.isAuthorized(),
				name: this.player.getName(),
				id: this.player.getUniqueID(),
			};
		} catch (e) {
			return null;
		}
	},

	openAuth: async function () {
		if (!this.ysdk) return false;
		try {
			await this.ysdk.auth.openAuthDialog();
			this.player = await this.ysdk.getPlayer();
			return this.player.isAuthorized();
		} catch (e) {
			return false;
		}
	},

	getData: async function () {
		if (!this.player || !this.player.isAuthorized()) return null;
		try {
			return await this.player.getData(['save_blob']);
		} catch (e) {
			return null;
		}
	},

	setData: async function (data) {
		if (!this.player || !this.player.isAuthorized()) return false;
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
		this.ysdk.adv.showFullscreenAdv({
			callbacks: {
				onClose: (wasShown) => { if (onClose) onClose(wasShown); },
				onError: () => { if (onClose) onClose(false); },
			},
		});
	},

	showRewardedVideo: function (onRewarded, onClose) {
		if (!this.ysdk || !this.ysdk.adv) {
			if (onClose) onClose(false);
			return;
		}
		this.ysdk.adv.showRewardedVideo({
			callbacks: {
				onRewarded: () => { if (onRewarded) onRewarded(); },
				onClose: (wasShown) => { if (onClose) onClose(wasShown); },
				onError: () => { if (onClose) onClose(false); },
			},
		});
	},
};

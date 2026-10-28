class_name UpgradesPanel
extends RefCounted

static func update_ui(
	save: SaveData,
	coins_label: Label,
	extra_life_btn: Button,
	coin_bonus_btn: Button,
	combo_duration_btn: Button,
	bomb_btn: Button
) -> void:
	coins_label.text = "%s: %d" % [Locale.get_text("coins"), save.coins]

	extra_life_btn.text = "%s — %d" % [Locale.get_text("extra_life"), UpgradeShop.EXTRA_LIFE_COST]
	extra_life_btn.disabled = not UpgradeShop.can_buy_extra_life(save)
	if save.extra_life_owned:
		extra_life_btn.text = "%s (%s)" % [Locale.get_text("extra_life"), Locale.get_text("owned")]
		extra_life_btn.disabled = true

	var cb_level := save.coin_bonus_level
	if cb_level >= UpgradeShop.MAX_LEVEL:
		coin_bonus_btn.text = "%s (%s: +%d%%)" % [
			Locale.get_text("coin_bonus"),
			Locale.get_text("max"),
			cb_level * 10,
		]
		coin_bonus_btn.disabled = true
	else:
		coin_bonus_btn.text = "%s Lv%d (+%d%%) — %d" % [
			Locale.get_text("coin_bonus"),
			cb_level + 1,
			(cb_level + 1) * 10,
			UpgradeShop.coin_bonus_cost(cb_level),
		]
		coin_bonus_btn.disabled = not UpgradeShop.can_buy_coin_bonus(save)

	var cd_level := save.combo_duration_level
	var sec_label := Locale.get_text("sec_short")
	if cd_level >= UpgradeShop.MAX_LEVEL:
		combo_duration_btn.text = "%s (%s: %.1f%s)" % [
			Locale.get_text("combo_duration"),
			Locale.get_text("max"),
			UpgradeShop.get_combo_window(cd_level),
			sec_label,
		]
		combo_duration_btn.disabled = true
	else:
		combo_duration_btn.text = "%s Lv%d (%.1f%s) — %d" % [
			Locale.get_text("combo_duration"),
			cd_level + 1,
			UpgradeShop.get_combo_window(cd_level + 1),
			sec_label,
			UpgradeShop.combo_duration_cost(cd_level),
		]
		combo_duration_btn.disabled = not UpgradeShop.can_buy_combo_duration(save)

	var bomb_cost := UpgradeShop.bomb_purchase_cost(save)
	var bomb_key := "bomb_buy_first" if save.bomb_count <= 0 else "bomb_buy_refill"
	bomb_btn.text = Locale.get_text(bomb_key) % bomb_cost
	bomb_btn.disabled = not UpgradeShop.can_buy_bomb(save)

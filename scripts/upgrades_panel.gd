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

	extra_life_btn.text = "%s - %d" % [Locale.get_text("extra_life"), UpgradeShop.EXTRA_LIFE_COST]
	extra_life_btn.disabled = not UpgradeShop.can_buy_extra_life(save)
	if save.extra_life_owned:
		extra_life_btn.text = "%s (%s)" % [Locale.get_text("extra_life"), Locale.get_text("owned")]
		extra_life_btn.disabled = true

	coin_bonus_btn.text = "%s Lv%d - %d" % [
		Locale.get_text("coin_bonus"),
		save.coin_bonus_level,
		UpgradeShop.coin_bonus_cost(save.coin_bonus_level),
	]
	coin_bonus_btn.disabled = not UpgradeShop.can_buy_coin_bonus(save)
	if save.coin_bonus_level >= UpgradeShop.MAX_LEVEL:
		coin_bonus_btn.text = "%s (%s)" % [Locale.get_text("coin_bonus"), Locale.get_text("max")]
		coin_bonus_btn.disabled = true

	combo_duration_btn.text = "%s Lv%d - %d" % [
		Locale.get_text("combo_duration"),
		save.combo_duration_level,
		UpgradeShop.combo_duration_cost(save.combo_duration_level),
	]
	combo_duration_btn.disabled = not UpgradeShop.can_buy_combo_duration(save)
	if save.combo_duration_level >= UpgradeShop.MAX_LEVEL:
		combo_duration_btn.text = "%s (%s)" % [Locale.get_text("combo_duration"), Locale.get_text("max")]
		combo_duration_btn.disabled = true

	var bomb_cost := UpgradeShop.bomb_purchase_cost(save)
	var bomb_key := "bomb_buy_first" if save.bomb_count <= 0 else "bomb_buy_refill"
	bomb_btn.text = Locale.get_text(bomb_key) % bomb_cost
	bomb_btn.disabled = not UpgradeShop.can_buy_bomb(save)

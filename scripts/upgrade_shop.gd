class_name UpgradeShop
extends RefCounted

const MAX_LEVEL := 5
const EXTRA_LIFE_COST := 1000
const COIN_BONUS_BASE_COST := 100
const COMBO_DURATION_BASE_COST := 250
const BOMB_UNLOCK_COST := 500
const BOMB_REFILL_COST := 100


static func coin_bonus_cost(current_level: int) -> int:
	return COIN_BONUS_BASE_COST * (current_level + 1)


static func combo_duration_cost(current_level: int) -> int:
	return COMBO_DURATION_BASE_COST * (current_level + 1)


static func bomb_purchase_cost(save: SaveData) -> int:
	if save.bomb_count <= 0:
		return BOMB_UNLOCK_COST
	return BOMB_REFILL_COST


static func can_buy_extra_life(save: SaveData) -> bool:
	return not save.extra_life_owned and save.coins >= EXTRA_LIFE_COST


static func can_buy_coin_bonus(save: SaveData) -> bool:
	return save.coin_bonus_level < MAX_LEVEL and save.coins >= coin_bonus_cost(save.coin_bonus_level)


static func can_buy_combo_duration(save: SaveData) -> bool:
	return save.combo_duration_level < MAX_LEVEL and save.coins >= combo_duration_cost(save.combo_duration_level)


static func can_buy_bomb(save: SaveData) -> bool:
	return save.coins >= bomb_purchase_cost(save)


static func buy_extra_life(save: SaveData) -> bool:
	if not can_buy_extra_life(save):
		return false
	save.coins -= EXTRA_LIFE_COST
	save.extra_life_owned = true
	save.save()
	return true


static func buy_coin_bonus(save: SaveData) -> bool:
	if not can_buy_coin_bonus(save):
		return false
	save.coins -= coin_bonus_cost(save.coin_bonus_level)
	save.coin_bonus_level += 1
	save.save()
	return true


static func buy_combo_duration(save: SaveData) -> bool:
	if not can_buy_combo_duration(save):
		return false
	save.coins -= combo_duration_cost(save.combo_duration_level)
	save.combo_duration_level += 1
	save.save()
	return true


static func buy_bomb(save: SaveData) -> bool:
	if not can_buy_bomb(save):
		return false
	save.coins -= bomb_purchase_cost(save)
	save.bomb_count += 1
	save.save()
	return true


static func get_combo_window(level: int) -> float:
	return 2.0 + clampi(level, 0, MAX_LEVEL) * 0.1


static func can_use_bomb(save: SaveData) -> bool:
	return save.bomb_count > 0


static func use_bomb(save: SaveData) -> bool:
	if not can_use_bomb(save):
		return false
	save.bomb_count -= 1
	save.save()
	return true

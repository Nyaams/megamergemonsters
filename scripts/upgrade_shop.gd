class_name UpgradeShop
extends RefCounted

const MAX_LEVEL := 5
const EXTRA_LIFE_COST := 350
const BOMB_UNLOCK_COST := 120
const BOMB_REFILL_COST := 50

# Progression calibrated for 55 min/day, 35+ yo audience (Day 1 purchase within 10-15m)
const COIN_BONUS_COSTS: Array[int] = [40, 90, 160, 260, 400]
const COMBO_DURATION_COSTS: Array[int] = [50, 110, 190, 300, 450]


static func coin_bonus_cost(current_level: int) -> int:
	if current_level < 0 or current_level >= COIN_BONUS_COSTS.size():
		return COIN_BONUS_COSTS.back()
	return COIN_BONUS_COSTS[current_level]


static func combo_duration_cost(current_level: int) -> int:
	if current_level < 0 or current_level >= COMBO_DURATION_COSTS.size():
		return COMBO_DURATION_COSTS.back()
	return COMBO_DURATION_COSTS[current_level]


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
	# Base 2.5s window + 0.4s per level (up to 4.5s at Lv 5)
	# Tailored for casual players & mobile touch controls
	return 2.5 + clampi(level, 0, MAX_LEVEL) * 0.4


static func can_use_bomb(save: SaveData) -> bool:
	return save.bomb_count > 0


static func use_bomb(save: SaveData) -> bool:
	if not can_use_bomb(save):
		return false
	save.bomb_count -= 1
	save.save()
	return true

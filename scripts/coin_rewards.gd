class_name CoinRewards
extends RefCounted

const REWARDS: Array[int] = [
	2, 4, 7, 12, 20, 32, 48, 70, 100, 140, 190, 250, 330, 430, 600,
]

const MILESTONE_BONUSES: Dictionary = {
	5: 15,
	8: 40,
	10: 80,
	12: 150,
	15: 500,
}


static func get_base_reward(max_level_1based: int) -> int:
	var idx := clampi(max_level_1based - 1, 0, REWARDS.size() - 1)
	return REWARDS[idx]


static func apply_coin_bonus(base: int, coin_bonus_level: int) -> int:
	var bonus_pct := coin_bonus_level * 0.10
	return int(round(float(base) * (1.0 + bonus_pct)))


static func calc_milestone_bonus(new_levels: Array[int], unlocked_milestones: Array) -> int:
	var bonus := 0
	for level in new_levels:
		if MILESTONE_BONUSES.has(level) and not unlocked_milestones.has(level):
			bonus += MILESTONE_BONUSES[level]
	return bonus


static func calc_total_round_coins(
	max_level_1based: int,
	coin_bonus_level: int,
	new_milestone_levels: Array[int],
	unlocked_milestones: Array
) -> Dictionary:
	var base := get_base_reward(max_level_1based)
	var with_bonus := apply_coin_bonus(base, coin_bonus_level)
	var milestone := calc_milestone_bonus(new_milestone_levels, unlocked_milestones)
	return {
		"base": base,
		"with_bonus": with_bonus,
		"milestone": milestone,
		"total": with_bonus + milestone,
	}

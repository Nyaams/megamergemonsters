class_name ComboTracker
extends RefCounted

var window: float = 2.0

var _combo_count: int = 0
var _time_since_last: float = 999.0


func reset() -> void:
	_combo_count = 0
	_time_since_last = window + 1.0


func update(delta: float) -> void:
	if _combo_count > 0:
		_time_since_last += delta
		if _time_since_last > window:
			_combo_count = 0


func register_merge() -> int:
	if _time_since_last <= window and _combo_count > 0:
		_combo_count += 1
	else:
		_combo_count = 1
	_time_since_last = 0.0
	return _combo_count

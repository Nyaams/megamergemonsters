class_name DangerFeedback
extends RefCounted

const FIELD_BASE := Color(1, 1, 1, 1)

var _field_visual: CanvasItem
var _danger_line: Line2D
var _danger_vignette: ColorRect
var _pulse_time: float = 0.0


func setup(field_visual: CanvasItem, danger_line: Line2D, vignette: ColorRect) -> void:
	_field_visual = field_visual
	_danger_line = danger_line
	_danger_vignette = vignette


func reset() -> void:
	_pulse_time = 0.0
	if _field_visual:
		_field_visual.modulate = FIELD_BASE
	if _danger_line:
		_danger_line.default_color = Color(1, 0.3, 0.3, 0.6)
		_danger_line.width = 2.0
	if _danger_vignette:
		_danger_vignette.color = Color(0, 0, 0, 0)


func update(delta: float, ratio: float) -> void:
	_pulse_time += delta
	if ratio <= 0.0:
		reset()
		return

	if ratio < 0.25:
		return

	if ratio < 0.6:
		_apply_warning(ratio)
	else:
		_apply_danger(ratio)


func _apply_warning(ratio: float) -> void:
	var t := (ratio - 0.25) / 0.35
	if _field_visual:
		_field_visual.modulate = FIELD_BASE.lerp(Color(1.1, 1.0, 0.7, 1.0), t)
	if _danger_line:
		var pulse := 0.5 + 0.5 * sin(_pulse_time * 6.0)
		_danger_line.default_color = Color(1, 0.8, 0.2, 0.4 + pulse * 0.4)
		_danger_line.width = 2.0 + pulse * 1.5
	if _danger_vignette:
		_danger_vignette.color = Color(0.4, 0.3, 0.0, t * 0.12)


func _apply_danger(ratio: float) -> void:
	var t := clampf((ratio - 0.6) / 0.4, 0.0, 1.0)
	if _field_visual:
		_field_visual.modulate = Color(1.1, 0.85, 0.85, 1.0).lerp(Color(1.2, 0.6, 0.6, 1.0), t)
	if _danger_line:
		var pulse := 0.5 + 0.5 * sin(_pulse_time * 10.0)
		_danger_line.default_color = Color(1, 0.15, 0.15, 0.6 + pulse * 0.4)
		_danger_line.width = 3.0 + pulse * 2.0
	if _danger_vignette:
		_danger_vignette.color = Color(0.5, 0.0, 0.0, 0.15 + t * 0.35)

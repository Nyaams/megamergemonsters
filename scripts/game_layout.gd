class_name GameLayout
extends RefCounted

## Fixed design space 540x960 (9:16).

const DESIGN_SIZE := Vector2(540.0, 960.0)
const CONTAINER_LEFT := 70.0
const CONTAINER_RIGHT := 470.0
const CONTAINER_TOP := 100.0
const CONTAINER_BOTTOM := 920.0
const DROP_OFFSET := 10.0
const DANGER_OFFSET := 30.0


static func compute(viewport_size: Vector2) -> Dictionary:
	var vp := viewport_size
	if vp.x <= 0.0 or vp.y <= 0.0:
		vp = DESIGN_SIZE

	var zoom := minf(vp.x / DESIGN_SIZE.x, vp.y / DESIGN_SIZE.y)
	var top := CONTAINER_TOP
	var bottom := CONTAINER_BOTTOM
	var left := CONTAINER_LEFT
	var right := CONTAINER_RIGHT

	return {
		"zoom": zoom,
		"center": DESIGN_SIZE * 0.5,
		"left": left,
		"right": right,
		"top": top,
		"bottom": bottom,
		"drop_y": top + DROP_OFFSET,
		"danger_y": top + DANGER_OFFSET,
		"viewport": vp,
		"field_size": Vector2(right - left + 40.0, bottom - top + 40.0),
	}

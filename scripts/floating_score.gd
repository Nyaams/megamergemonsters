extends Label

const DURATION := 0.9
const RISE := 60.0


func setup(amount: int, pos: Vector2) -> void:
	text = "+%d" % amount
	global_position = pos
	modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", pos.y - RISE, DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION).set_delay(DURATION * 0.35)
	tween.chain().tween_callback(queue_free)

class_name MergeEffects
extends Node2D

const FLOATING_SCORE_SCENE := preload("res://scenes/floating_score.tscn")

var _camera: Camera2D
var _flash_rect: ColorRect
var _audio: AudioStreamPlayer
var _shake_strength: float = 0.0
var _shake_time: float = 0.0


func setup(camera: Camera2D, flash_rect: ColorRect) -> void:
	_camera = camera
	_flash_rect = flash_rect
	_audio = AudioStreamPlayer.new()
	add_child(_audio)


func _process(delta: float) -> void:
	if _shake_time > 0.0 and _camera:
		_shake_time -= delta
		var offset := Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
		_camera.offset = offset if _shake_time > 0.0 else Vector2.ZERO
	elif _camera and _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO


func play_merge(pos: Vector2, score: int, monster: Monster) -> void:
	_play_scale_pop(monster)
	_play_particles(pos, Color(1, 1, 1, 0.9))
	_play_flash()
	_play_shake(4.0, 0.12)
	_play_sound(440.0)
	_spawn_floating_score(pos, score)


func play_particles(pos: Vector2, color: Color, count: int = 10) -> void:
	_play_particles(pos, color, count)


func play_explosion(pos: Vector2, score: int) -> void:
	_play_particles(pos, Color(1, 0.4, 0.1, 0.9), 16)
	_play_flash(Color(1, 0.5, 0.2, 0.35))
	_play_shake(6.0, 0.18)
	_play_sound(220.0)
	if score > 0:
		_spawn_floating_score(pos, score)


func _play_scale_pop(monster: Monster) -> void:
	if not is_instance_valid(monster):
		return
	monster.scale = Vector2(0.3, 0.3)
	var tween := monster.create_tween()
	tween.tween_property(monster, "scale", Vector2(1.1, 1.1), 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(monster, "scale", Vector2.ONE, 0.13).set_ease(Tween.EASE_IN)


func _play_particles(pos: Vector2, color: Color, count: int = 10) -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = count
	particles.lifetime = 0.45
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 140.0
	particles.gravity = Vector2(0, 200)
	particles.color = color
	particles.global_position = pos
	add_child(particles)
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(particles.queue_free)


func _play_flash(color: Color = Color(1, 1, 1, 0.3)) -> void:
	if not _flash_rect:
		return
	_flash_rect.color = color
	_flash_rect.visible = true
	var tween := _flash_rect.create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, 0.12)
	tween.tween_callback(func(): _flash_rect.visible = false)


func _play_shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_time = duration


func _play_sound(frequency: float) -> void:
	if not Locale.sound_enabled:
		return
	if not _audio:
		return
	var sample := AudioStreamGenerator.new()
	sample.mix_rate = 22050.0
	sample.buffer_length = 0.08
	_audio.stream = sample
	_audio.play()
	# Simple beep via pitch scale on a generator placeholder.
	_audio.pitch_scale = frequency / 440.0


func _spawn_floating_score(pos: Vector2, amount: int) -> void:
	var label: Label = FLOATING_SCORE_SCENE.instantiate()
	add_child(label)
	if label.has_method("setup"):
		label.setup(amount, pos)

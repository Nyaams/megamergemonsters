extends Control

const PREVIEW_SIZE := 28.0
const ROW_COUNT := 3


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var hint := Label.new()
	hint.text = Locale.get_text("merge_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	UIHelpers.apply_readable_label(hint)
	root.add_child(hint)

	for i in ROW_COUNT:
		root.add_child(_make_row(i))


func _make_row(level_index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)

	var left_tex: Texture2D = MonsterData.get_level_data(level_index)["sprite"]
	var right_tex: Texture2D = MonsterData.get_level_data(level_index + 1)["sprite"]

	row.add_child(_icon(left_tex, MonsterData.LEVEL_SIZES[level_index]))
	row.add_child(_symbol("+"))
	row.add_child(_icon(left_tex, MonsterData.LEVEL_SIZES[level_index]))
	row.add_child(_symbol("="))
	row.add_child(_icon(right_tex, MonsterData.LEVEL_SIZES[level_index + 1]))
	return row


func _icon(texture: Texture2D, diameter: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(PREVIEW_SIZE, PREVIEW_SIZE)
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect


func _symbol(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	UIHelpers.apply_readable_label(label)
	return label

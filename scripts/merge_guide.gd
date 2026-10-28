extends Control

const PREVIEW_SIZE := 26.0
const ROW_COUNT := 3


func _ready() -> void:
	apply_locale()


func apply_locale() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	# Rules text bullets
	var rules := [
		Locale.get_text("rule_1"),
		Locale.get_text("rule_2"),
		Locale.get_text("rule_3"),
		Locale.get_text("rule_4"),
	]

	for r in rules:
		var lbl := Label.new()
		lbl.text = r
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.94, 0.92, 0.98, 0.95))
		UIHelpers.apply_readable_label(lbl, 2)
		root.add_child(lbl)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	root.add_child(spacer)

	# Merge chain header
	var chain_title := Label.new()
	chain_title.text = Locale.get_text("merge_chain_title")
	chain_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chain_title.add_theme_font_size_override("font_size", 13)
	chain_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45, 1.0))
	UIHelpers.apply_readable_label(chain_title, 2)
	root.add_child(chain_title)

	# Merge chain visual rows
	for i in ROW_COUNT:
		root.add_child(_make_row(i))


func _make_row(level_index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)

	var left_tex: Texture2D = MonsterData.get_level_data(level_index)["sprite"]
	var right_tex: Texture2D = MonsterData.get_level_data(level_index + 1)["sprite"]

	row.add_child(_icon(left_tex))
	row.add_child(_symbol("+"))
	row.add_child(_icon(left_tex))
	row.add_child(_symbol("="))
	row.add_child(_icon(right_tex))
	return row


func _icon(texture: Texture2D) -> TextureRect:
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
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	UIHelpers.apply_readable_label(label, 2)
	return label

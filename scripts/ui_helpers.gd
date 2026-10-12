class_name UIHelpers
extends RefCounted

const PANEL_STYLE := preload("res://assets/ui/panel_frame.tres")
const LOGO_RU := preload("res://assets/Sprites/logo_ru.png")
const LOGO_EN := preload("res://assets/Sprites/logo_en.png")
const COIN_ICON := preload("res://assets/Sprites/coin.png")


static func wrap_panel(vbox: Control) -> void:
	var parent := vbox.get_parent()
	if parent is PanelContainer:
		return

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PANEL_STYLE.duplicate())

	var idx := vbox.get_index()
	parent.remove_child(vbox)
	parent.add_child(panel)
	parent.move_child(panel, idx)
	panel.add_child(vbox)

	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL


static func apply_readable_label(label: Label, outline_size: int = 3) -> void:
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", outline_size)


static func apply_readable_tree(root: Node, outline_size: int = 3) -> void:
	if root is Label:
		apply_readable_label(root, outline_size)
	for child in root.get_children():
		apply_readable_tree(child, outline_size)


static func get_logo_texture() -> Texture2D:
	return LOGO_EN if Locale.language == "en" else LOGO_RU

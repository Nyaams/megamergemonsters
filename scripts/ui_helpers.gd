class_name UIHelpers
extends RefCounted

const PANEL_STYLE := preload("res://assets/ui/panel_frame.tres")


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

class_name UIHelpers
extends RefCounted

const PANEL_STYLE := preload("res://assets/ui/panel_frame.tres")
const LOGO_RU := preload("res://assets/Sprites/logo_ru.png")
const LOGO_EN := preload("res://assets/Sprites/logo_en.png")
const COIN_ICON := preload("res://assets/Sprites/coin.png")

const ICON_BTN_NORMAL := preload("res://assets/ui/icon_button_normal.tres")
const ICON_BTN_HOVER := preload("res://assets/ui/icon_button_hover.tres")
const ICON_BTN_PRESSED := preload("res://assets/ui/icon_button_pressed.tres")

static var _icon_cache: Dictionary = {}


static func style_icon_button(button: Button) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", ICON_BTN_NORMAL)
	button.add_theme_stylebox_override("hover", ICON_BTN_HOVER)
	button.add_theme_stylebox_override("pressed", ICON_BTN_PRESSED)
	button.add_theme_stylebox_override("focus", ICON_BTN_NORMAL)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER


static func get_ui_texture(name: String) -> Texture2D:
	if _icon_cache.has(name):
		return _icon_cache[name]

	var tex: Texture2D = null

	var png_res := "res://assets/ui/%s.png" % name
	if ResourceLoader.exists(png_res):
		var res = load(png_res)
		if res is Texture2D:
			tex = res

	if tex == null:
		var svg_res := "res://assets/ui/%s.svg" % name
		if ResourceLoader.exists(svg_res):
			var res = load(svg_res)
			if res is Texture2D:
				tex = res

	if tex == null:
		var global_png := ProjectSettings.globalize_path(png_res)
		if FileAccess.file_exists(global_png):
			var img := Image.load_from_file(global_png)
			if img:
				tex = ImageTexture.create_from_image(img)

	if tex == null:
		var global_svg := ProjectSettings.globalize_path("res://assets/ui/%s.svg" % name)
		if FileAccess.file_exists(global_svg):
			var img := Image.load_from_file(global_svg)
			if img:
				tex = ImageTexture.create_from_image(img)

	if tex != null:
		_icon_cache[name] = tex
	return tex


static func get_sound_icon(enabled: bool) -> Texture2D:
	return get_ui_texture("sound_on" if enabled else "sound_off")


static func get_lang_icon(lang: String) -> Texture2D:
	return get_ui_texture("lang_en" if lang == "en" else "lang_ru")


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

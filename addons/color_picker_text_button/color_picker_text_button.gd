@tool
extends Button

signal popup_hide
signal color_changed(color)

@export var text_value = "Click Me": set = set_label_text
@export var style: StyleBoxFlat: set = set_styles
@export var mouseover_darkening_factor = 0.1 # (float, 0.1, 0.8)
@export var custom_font: FontFile: set = set_font
@export var color: Color = Color.WHITE: set = set_colors_in_tool
@export var light_text_color: Color = Color.WHITE: set = update_light_text_color
@export var dark_text_color: Color = Color.BLACK: set = update_dark_text_color
@export var text_color_flip_threshold = 0.5 # (float, 0.2, 0.8)
@export var popup_centered = true
@export var simple_color_picker = true
@export var enable_text = true: set = show_hide_label
@export var fresh = true
@export var font_size = 20

var panel
var color_picker
var center
var label


func _ready():
	# Add panel with color picker
	panel = PopupPanel.new()
	add_child(panel)
	color_picker = ColorPicker.new()
	color_picker.color = color
	panel.add_child(color_picker)

	# Connect signals
	var _e = connect("pressed", Callable(self, "show_panel"))
	_e = color_picker.connect("color_changed", Callable(self, "set_colors"))
	_e = panel.connect("popup_hide", Callable(self, "panel_closed"))
	_e = connect("item_rect_changed", Callable(self, "rect_changed"))


	if simple_color_picker:
		# Hide color picker elements
		for n in range(3, color_picker.get_child_count()):
			color_picker.get_child(n).hide()

	# Make panel resize to fit contents
	panel.size.y = 0

	# Initially style the button
	if Engine.is_editor_hint() and fresh:
		self.style = load("res://addons/color_picker_text_button/styleboxflat.tres")
		position = Vector2(20, 10)

	setup_label()


func setup_label():
	center = CenterContainer.new()
	add_child(center)
	label = Label.new()
	center.add_child(label)
	if custom_font:
		label.set("theme_override_fonts/font", custom_font)
	label.set("theme_override_font_sizes/font_size", font_size)
	call_deferred("init_size")
	label.text = text_value
	text = ""
	set_colors(color)
	center.mouse_filter = MOUSE_FILTER_PASS
	center.visible = enable_text


func show_hide_label(show_text):
	enable_text = show_text
	center.visible = enable_text


func rect_changed():
	if center:
		center.size = size


func init_size():
	if Engine.is_editor_hint() and fresh:
		size = Vector2(200, 60)
		fresh = false
	rect_changed()


func set_font(font):
	custom_font = font
	if Engine.is_editor_hint() and label:
		label.set("theme_override_fonts/font", font)


func set_styles(s):
	style = s
	if style == null:
		style = get("theme_override_styles/normal")
		if style == null:
			return # Stick with default button style
	else:
		set("theme_override_styles/normal", style)
	var next_style = set_style(style, "theme_override_styles/hover")
	next_style = set_style(next_style, "theme_override_styles/pressed")


func set_style(current_style, path):
	var new_style = get(path)
	if new_style == null:
		new_style = current_style.duplicate()
		new_style.bg_color = new_style.bg_color.darkened(mouseover_darkening_factor)
		set(path, new_style)
	return new_style


func set_label_text(txt):
	text_value = txt
	text = ""
	if Engine.is_editor_hint() and label:
		# Export setter is called before the _ready() function when running scene.
		label.text = txt


func show_panel():
	if popup_centered:
		panel.popup_centered()
	else:
		panel.popup()


func panel_closed():
	release_focus()
	emit_signal("popup_hide")


func set_colors_in_tool(c):
	color = c
	if Engine.is_editor_hint() and label:
		set_colors(c)


func update_light_text_color(c):
	light_text_color = c
	if Engine.is_editor_hint() and label:
		set_colors(color)


func update_dark_text_color(c):
	dark_text_color = c
	if Engine.is_editor_hint() and label:
		set_colors(color)


func set_colors(c):
	if not Engine.is_editor_hint():
		emit_signal("color_changed", c)
	self_modulate = c
	color = c
	var grey_value = (c.r + c.g + c.b) / 3
	if grey_value > text_color_flip_threshold:
		label.set("theme_override_colors/font_color", dark_text_color)
	else:
		label.set("theme_override_colors/font_color", light_text_color)

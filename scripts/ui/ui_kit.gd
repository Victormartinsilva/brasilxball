class_name UIKit
## Paleta, tema e construtores de UI. Estética: madeira escura + ouro + nanquim (como as referências).

const BG := Color("#14110d")
const WOOD := Color("#3b2416")
const WOOD_LIGHT := Color("#5a3a22")
const GOLD := Color("#e8b04a")
const CREAM := Color("#f3e3c3")
const RED := Color("#c2412d")
const TEAL := Color("#3fb8a5")
const INK := Color("#120d08")
const MUTED := Color("#a89a86")

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 18
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(MUTED, 0.6))
	t.set_stylebox("normal", "Button", box(WOOD, GOLD.darkened(0.35), 2, 6))
	t.set_stylebox("hover", "Button", box(WOOD_LIGHT, GOLD, 2, 6))
	t.set_stylebox("pressed", "Button", box(WOOD.darkened(0.3), GOLD, 2, 6))
	t.set_stylebox("disabled", "Button", box(Color(WOOD, 0.5), Color(MUTED, 0.3), 2, 6))
	t.set_stylebox("focus", "Button", box(Color.TRANSPARENT, CREAM, 2, 6))
	t.set_stylebox("panel", "PanelContainer", box(Color(BG, 0.92), GOLD.darkened(0.4), 2, 8))
	t.set_stylebox("panel", "Panel", box(Color(BG, 0.92), GOLD.darkened(0.4), 2, 8))
	t.set_stylebox("panel", "TabContainer", box(Color(BG, 0.94), GOLD.darkened(0.4), 2, 8))
	t.set_stylebox("tab_selected", "TabContainer", box(WOOD_LIGHT, GOLD, 2, 6))
	t.set_stylebox("tab_unselected", "TabContainer", box(WOOD, GOLD.darkened(0.5), 1, 6))
	t.set_stylebox("tab_hovered", "TabContainer", box(WOOD_LIGHT, GOLD.darkened(0.2), 1, 6))
	t.set_color("font_selected_color", "TabContainer", GOLD)
	t.set_color("font_unselected_color", "TabContainer", CREAM)
	t.set_color("font_hovered_color", "TabContainer", Color.WHITE)
	t.set_font_size("font_size", "TabContainer", 18)
	t.set_stylebox("background", "ProgressBar", box(Color(INK, 0.8), GOLD.darkened(0.5), 1, 4))
	t.set_stylebox("fill", "ProgressBar", box(GOLD, Color.TRANSPARENT, 0, 4))
	_theme = t
	return t


static func box(bg: Color, border: Color, border_w := 2, radius := 6, pad := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 3
	return s


static func label(text: String, size := 18, color := Color(0.953, 0.89, 0.765), outline := 4) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = outline
	ls.outline_color = INK
	l.label_settings = ls
	return l


static func wrap_label(text: String, size := 16, color := Color(0.953, 0.89, 0.765)) -> Label:
	var l := label(text, size, color, 2)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 120
	return l


static func button(text: String, cb: Callable, size := 20, min_w := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	if min_w > 0.0:
		b.custom_minimum_size.x = min_w
	b.pressed.connect(cb)
	return b


static func panel(bg := Color(0.078, 0.067, 0.051, 0.92), border := Color(0.59, 0.43, 0.18)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border, 2, 8, 14))
	return p


static func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


## Ícone circular desenhado (placeholder de arte) com a cor do item e a inicial.
static func icon(color: Color, letter: String, size := 44.0, level := 0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var r := size * 0.5
		var center := Vector2(r, r)
		c.draw_circle(center, r, INK)
		c.draw_circle(center, r - 2.5, color.darkened(0.25))
		c.draw_circle(center + Vector2(-r * 0.15, -r * 0.15), r * 0.62, color)
		c.draw_circle(center + Vector2(-r * 0.32, -r * 0.32), r * 0.18, Color(1, 1, 1, 0.55))
		var font := ThemeDB.fallback_font
		var fs := int(size * 0.42)
		var ts := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		c.draw_string_outline(font, center + Vector2(-ts.x * 0.5, fs * 0.36), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, INK)
		c.draw_string(font, center + Vector2(-ts.x * 0.5, fs * 0.36), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, CREAM)
		if level > 0:
			var lv := str(level)
			var p := Vector2(size - 14, size - 2)
			c.draw_circle(p + Vector2(4, -6), 9, INK)
			c.draw_string(font, p + Vector2(0, -1), lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, GOLD)
	)
	return c


## Posiciona um Control por âncora + deslocamento (independe do tamanho do pai no momento).
static func place(c: Control, anchor: Vector2, offset: Vector2, size := Vector2.ZERO) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x + size.x
	c.offset_bottom = offset.y + size.y
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN if anchor.x >= 1.0 else (Control.GROW_DIRECTION_BOTH if anchor.x > 0.0 else Control.GROW_DIRECTION_END)
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN if anchor.y >= 1.0 else (Control.GROW_DIRECTION_BOTH if anchor.y > 0.0 else Control.GROW_DIRECTION_END)


static func format_time(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [s / 60, s % 60]

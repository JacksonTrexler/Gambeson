class_name CostButton
extends Button

# A purchase: what it does on the left, its cost in a square on the right (the skills screen's Unlock
# and Rank up). Enabled only while it can be bought; its tooltip says why not.

const GOLD := Color("#e8c547")
const INK := Color("#1d1a12")

var cost := 0:
	set(v):
		cost = v
		_fit()


func _init() -> void:
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	focus_mode = FOCUS_NONE


# What it does and what it costs: "Unlock", 1.
func set_offer(what: String, price: int) -> void:
	text = what
	cost = price


func _side() -> float:
	return get_theme_font(&"font").get_height(get_theme_font_size(&"font_size")) + 2.0


# Room for the label, then the square.
func _fit() -> void:
	var font := get_theme_font(&"font")
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size(&"font_size")).x
	custom_minimum_size.x = w + _side() + 14.0
	queue_redraw()


func _draw() -> void:
	var side := minf(_side(), size.y - 4.0)
	var box := Rect2(size.x - side - 2.0, (size.y - side) / 2.0, side, side)
	draw_rect(box, Color(GOLD, 0.25) if disabled else GOLD)
	var font := get_theme_font(&"font")
	var fs := get_theme_font_size(&"font_size")
	var label := str(cost)
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(box.get_center().x - w / 2.0, box.get_center().y + font.get_ascent(fs) / 2.0 - 1.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(INK, 0.6) if disabled else INK)

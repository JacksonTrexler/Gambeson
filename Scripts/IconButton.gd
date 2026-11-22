class_name IconButton
extends Button

# A small square button that draws its own glyph, standing in for icon art: branch (skills), cog
# (settings), character, book (spellbook). `badge` lights a dot in its corner (points to spend).

const BADGE := Color("#e8c547")

@export_enum("branch", "cog", "character", "book") var glyph := "branch":
	set(v):
		glyph = v
		queue_redraw()
var badge := false:
	set(v):
		badge = v
		queue_redraw()


func _init() -> void:
	focus_mode = FOCUS_NONE
	custom_minimum_size = Vector2(15, 15)


func _draw() -> void:
	var col := get_theme_color(&"font_disabled_color" if disabled else (&"font_hover_color" if is_hovered() else &"font_color"))
	var c := (size / 2.0).round() + Vector2(0.5, 0.5)
	match glyph:
		"branch":  # a trunk splitting into two, with a skill at each tip
			var root := c + Vector2(0, 4)
			var fork := c + Vector2(0, 0.5)
			draw_line(root, fork, col, 1.0)
			for tip in [c + Vector2(-3.5, -3.5), c + Vector2(3.5, -3.5)]:
				draw_line(fork, tip, col, 1.0)
				draw_circle(tip, 1.5, col)
			draw_circle(root, 1.5, col)
		"cog":
			for i in 8:
				var a := TAU * i / 8.0
				draw_line(c + Vector2.from_angle(a) * 3.0, c + Vector2.from_angle(a) * 5.2, col, 1.8)
			draw_arc(c, 3.0, 0.0, TAU, 16, col, 1.6)
		"character":  # head and shoulders
			draw_circle(c + Vector2(0, -2.5), 2.1, col)
			draw_arc(c + Vector2(0, 5.0), 4.2, PI, TAU, 12, col, 1.6)
		"book":
			var r := Rect2(c - Vector2(4, 4.5), Vector2(8, 9))
			draw_rect(r, col, false, 1.0)
			draw_line(r.position + Vector2(2, 0), r.position + Vector2(2, r.size.y), col, 1.0)
			for y in [2.5, 4.5, 6.5]:
				draw_line(r.position + Vector2(3.5, y), r.position + Vector2(6.5, y), col, 1.0)
	if badge:
		draw_circle(Vector2(size.x - 3, 3), 2.0, BADGE)

class_name PortalMark
extends Node2D

# An escape portal on the map (the Meadows'; a Rift's domain; a pocket dimension): a ring, filling as
# it forms, with the turns it has left - or a bright, full one once it's open. `turns` < 0: lasting
# (a channeled Rift: infinite until its Wizard stops).

const SIZE := 13.0
const COLOR := Color("#b58cff")

var turns := 0:
	set(v):
		turns = v
		queue_redraw()


func _draw() -> void:
	var open := turns == 0
	draw_circle(Vector2.ZERO, SIZE, Color(COLOR, 0.35 if open else 0.12))
	draw_arc(Vector2.ZERO, SIZE, 0.0, TAU, 32, Color(COLOR, 1.0 if open else 0.6), 2.0 if open else 1.0)
	var font := ThemeDB.fallback_font
	var text := "OPEN" if open else ("∞" if turns < 0 else str(turns))
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(font, Vector2(-w / 2.0, 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

extends Test

# Prestidigitation: a little magic for an ally in reach - AP to move with, the caster's cha mod + rank, at once.

var presti: Skill = load("res://Skills/prestidigitation.tres")


func test_prestidigitation() -> void:
	v(1).learned.append(slot(presti, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3)})
	v(1).charisma = 14  # mod 2
	var left := v(2).ap_for(&"move")
	ok(b.cast(v(1), presti, v(2)) and is_equal_approx(v(2).ap_for(&"move"), left + 4.0), "cha mod 2 + rank 2: 4 AP to move with (%s -> %s)" % [left, v(2).ap_for(&"move")])

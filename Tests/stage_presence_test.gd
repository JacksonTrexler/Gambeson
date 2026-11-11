extends Test

# Stage Presence: a passive, charisma +rank.

var presence: Skill = load("res://Skills/stage_presence.tres")


func test_stage_presence() -> void:
	var cha := v(1).stat(&"charisma")
	v(1).learned.append(slot(presence, 2))
	stage(lancin, {v(1): Vector2i(4, 3)})
	ok(is_equal_approx(v(1).stat(&"charisma"), cha + 2.0), "rank II: charisma +2 (%s -> %s)" % [cha, v(1).stat(&"charisma")])
	ok(presence.passive, "a passive")

extends Test

# Moving units without their walking: pushes (Battle.push(), Skill.push) and teleports (Battle.place(),
# send()); and investigating on contact (Battle._contact()): coming beside a hidden foe, a unit looks
# into what hides it, against the hider's own roll.

var hide: Skill = load("res://Skills/hide.tres")


func test_push() -> void:
	stage(lancin, {v(1): Vector2i(3, 3), v(3): Vector2i(4, 3), v(4): Vector2i(7, 3)})
	ok(b.push(v(3), v(1), 5) == 2 and v(3).cell == Vector2i(6, 3), "driven straight away, stopping short of a unit in the way (%s)" % v(3).cell)
	stage(lancin, {v(1): Vector2i(3, 3), v(3): Vector2i(4, 4)})
	ok(b.push(v(3), v(1), 1) == 1 and v(3).cell == Vector2i(5, 5), "diagonally too")
	var shove: Skill = hex.duplicate()
	shove.push = 2
	ok("Drives it up to 4 tiles straight away from the caster" in shove.describe(2), shove.describe(2))


func test_place() -> void:
	stage(lancin, {v(1): Vector2i(3, 3), v(3): Vector2i(8, 5)})
	v(1).refresh()
	ok(b.place(v(1), Vector2i(6, 3)) and v(1).cell == Vector2i(6, 3) and v(1).moved == 0.0, "teleported: no movement paid")
	ok(not b.place(v(1), Vector2i(8, 5)), "not onto another unit")


# v(3) hiding with a roll of 12, from Hide.
func hidden(u: Unit, roll := 12) -> void:
	var a := u.afflict(hide.effects[0], 9)
	a.skill = hide
	a.roll = roll


func test_contact() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(5, 4)})
	hidden(v(3))
	v(1).wisdom = 60  # wis mod 25: sees through anything
	v(1).refresh()
	var seen := []
	b.investigated.connect(func(by, of, _s, total, against, _close): seen.append([by, of, total, against]))
	b.travel(v(1), Vector2i(7, 3))
	ok(seen.size() == 1 and seen[0][0] == v(1) and seen[0][1] == v(3) and seen[0][3] == 12, "brushing past it, it looks, against the hider's roll (%s)" % [seen])
	ok(v(1) in v(3).timed[hide.effects[0]].known_to, "and sees through it")
	seen.clear()
	v(1).refresh()
	ok(b.travel(v(1), Vector2i(2, 3)).has(Vector2i(5, 3)) and seen.is_empty(), "back past it, seen through already: nothing more to look into")


func test_contact_hider_moves() -> void:
	stage(nemes, {v(1): Vector2i(2, 3), v(3): Vector2i(6, 3)})
	hidden(v(3), 30)
	v(3).refresh()
	var seen := []
	b.investigated.connect(func(by, of, _s, total, against, _close): seen.append([by, of, against]))
	b.travel(v(3), Vector2i(3, 3))
	ok(seen.size() == 1 and seen[0][0] == v(1) and seen[0][1] == v(3) and seen[0][2] == 30, "a hider ending beside a foe: the foe looks into it (%s)" % [seen])
	ok(v(1) not in v(3).timed[hide.effects[0]].known_to, "a roll of 30 holds")

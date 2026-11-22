extends Test

# Switcheroo: caster and target trade places - an ally freely, a foe failing a dex save.

var swap: Skill = load("res://Skills/switcheroo.tres")


func test_switcheroo() -> void:
	v(1).learned.append(slot(swap, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(6, 3), v(3): Vector2i(5, 4)})
	ok(b.cast(v(1), swap, v(2)) and v(1).cell == Vector2i(6, 3) and v(2).cell == Vector2i(4, 3)
			and b.unit_at(Vector2i(6, 3)) == v(1) and b.unit_at(Vector2i(4, 3)) == v(2), "an ally: places traded")
	v(1).charisma = 60
	v(3).dexterity = 1
	v(1).ap.clear()
	v(1).refresh()
	b.turn = nemes
	b.turn = lancin
	ok(b.cast(v(1), swap, v(3)) and v(1).cell == Vector2i(5, 4) and v(3).cell == Vector2i(6, 3), "a foe that fails its save: traded too")
	ok("trade places" in swap.describe(1), swap.describe(1))

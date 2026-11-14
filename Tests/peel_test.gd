extends Test

# Peel (Skills/peel.tres, Behaviours/peel.gd, passive): stepping toward a foe engaged with an ally costs
# half the tiles closed less, at most half the step, for rank steps a turn. Battle.walk() asks it, so
# the HUD's costs do too.

var peel: Skill = load("res://Skills/peel.tres")


func walker(r := 2) -> void:
	v(1).learned.append(slot(peel, r))
	v(1).wisdom = 18  # + its wis mod: the ally's in range from the first step
	v(1).movement = 9
	stage(lancin, {v(1): Vector2i(1, 3), v(2): Vector2i(1, 8), v(3): Vector2i(8, 3)})
	v(1).refresh()


func cost(w: Dictionary) -> float:
	return w.costs.reduce(func(sum, x): return sum + x, 0.0)


func test_cheaper() -> void:
	walker()
	var plain := cost(b.walk(v(1), Vector2i(4, 3), true))
	ok(is_equal_approx(plain, 3.0), "no ally engaged with it: no discount (%s)" % plain)
	stage(lancin, {v(1): Vector2i(1, 3), v(2): Vector2i(5, 3), v(3): Vector2i(6, 3)})
	var w := b.walk(v(1), Vector2i(4, 3), true)
	ok(is_equal_approx(cost(w), plain - 1.0), "two steps half price, the third full (%s vs %s)" % [cost(w), plain])
	var moved := v(1).moved
	b.travel(v(1), Vector2i(4, 3))
	ok(is_equal_approx(v(1).moved - moved, cost(w)), "the walk costs what the preview said")
	b.move(v(1), Vector2i(1, 3))
	ok(is_equal_approx(cost(b.walk(v(1), Vector2i(4, 3), true)), plain), "its 2 steps this turn spent")
	ok(not peel.ai and peel.passive and "ally" in peel.describe(2), peel.describe(2))

extends Test

# Difficulty (the ladder of check difficulties and magnitudes), evading (Battle.evade(): a dex check;
# none, half or all of it landing) and Wildfire (Battle._wildfire()).

var wildfire: Skill = load("res://Skills/wildfire.tres")
var leaves: Terrain = load("res://Terrain/leaves.tres")


func test_ladder() -> void:
	var at := func(r: int) -> Array: return Difficulty.LADDER.keys().map(func(t): return Difficulty.dc(t, r))
	ok(at.call(1) == [1, 3, 5, 6, 8, 9, 10], "rank I: trivial 1 .. impossible 10 (%s)" % [at.call(1)])
	ok(at.call(3) == [1, 7, 11, 12, 16, 17, 18], "rank III (%s)" % [at.call(3)])
	ok(at.call(0) == [1, 4, 8, 12, 16, 20, 30], "with no rank: the flat thresholds")
	ok(Difficulty.scaled(&"intense", 1) == 3 and Difficulty.scaled(&"extreme", 3) == 9 and Difficulty.scaled(&"faint", 1) == 1, "magnitudes: rank x a share, rounded up")
	ok(Check.versus(2, &"unfair", 2).target == 13, "a Check against a difficulty at a rank")


func test_evade() -> void:
	stage(lancin, {v(1): Vector2i(1, 2)})
	var seen := []
	b.evaded.connect(func(_u, total, dc, share): seen.append([total, dc, share]))
	for i in 300:
		b.evade(v(1), 16)
	ok(seen.all(func(x): return x[2] == (0.0 if x[0] >= 16 else (0.5 if x[0] >= 12 else 1.0))),
			"passing: none of it; failing by a quarter of the DC or less (12-15 against 16): half; else all of it")
	ok([0.0, 0.5, 1.0].all(func(s): return seen.any(func(x): return x[2] == s)), "all three happen")


# A Wildfire that deals a flat 5 + wis mod, so a crit shows plainly.
func flat_fire() -> Skill:
	var w: Skill = wildfire.duplicate(true)
	w.tiers[0].dice = Vector2i.ZERO
	w.tiers[0].power = 5
	w.dice_scale = &""
	w.ap = 1.0
	w.cost = 0
	return w


func test_wildfire() -> void:
	var w := flat_fire()
	var earthy := v(3)
	stage(lancin, {v(1): Vector2i(1, 3), earthy: Vector2i(2, 3), v(2): Vector2i(3, 3), v(4): Vector2i(5, 3)})
	v(1).learned.append(slot(w))
	v(1).refresh()
	for u in [v(2), earthy, v(4)]:
		u.dexterity = -30  # can't dodge
	earthy.tags.append(&"earth")
	b.lay_layer(Vector2i(4, 3), leaves)
	var hits := {}
	b.exploded.connect(func(_c, _s, _at, h): hits.merge(h))  # a lambda can't rebind hits, but it can fill it
	ok(b.cast_at(v(1), w, Vector2i(4, 3)), "cast toward a tile")
	ok(v(2) in hits and hits[v(2)] > 0 and v(4) not in hits and v(1) not in hits, "a 60 degree cone, 3 tiles long at rank I: the unit 2 out is hit, the one 4 out isn't, nor the caster")
	ok(hits[earthy] >= 2 * hits[v(2)] - 1, "earth: hit as a crit (%d vs %d)" % [hits[earthy], hits[v(2)]])
	ok(b.top_layer(Vector2i(4, 3)) == null and Vector2i(4, 3) in b.flames, "the leaves in its path burn")


func test_wildfire_dodged() -> void:
	var w := flat_fire()
	stage(lancin, {v(1): Vector2i(1, 3), v(2): Vector2i(3, 3)})
	v(1).learned.append(slot(w))
	v(1).refresh()
	v(2).dexterity = 90  # mod 40: clears any DC here
	var hp := v(2).hp
	b.cast_at(v(1), w, Vector2i(4, 3))
	ok(v(2).hp == hp, "a quick enough unit dodges it entirely (difficult, DC 8 at rank I)")
	v(2).tags.append(&"earth")
	v(1).refresh()
	var dcs := []
	b.evaded.connect(func(_u, _t, dc, _s): dcs.append(dc))
	b.cast_at(v(1), w, Vector2i(4, 3))
	ok(dcs == [Difficulty.dc(&"impossible", 1)], "of the earth, it dodges at impossible instead")


func test_described() -> void:
	var d := wildfire.describe(3)
	ok(d.begins_with("Area · range 2.5 x rank · 10 AP · 10 cost"), d.split("\n")[0])
	ok("9d6 + wis mod" in d and "Evadable: a Difficult check (dex mod, DC 16)" in d and "dodge it at impossible" in d, d)

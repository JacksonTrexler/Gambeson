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
	ok(Difficulty.scaled(&"intense", 1) == 3 and Difficulty.scaled(&"severe", 3) == 9 and Difficulty.scaled(&"faint", 1) == 1, "magnitudes: rank x a share, rounded up")
	ok(Check.versus(2, &"unfair", 2).target == 13, "a Check against a difficulty at a rank")


# The one table of difficulty words (Difficulty.WORDS): every word resolves to a rung, a synonym is its rung's
# DC, the old numbers stand, and the words the other scales used (cost levels, the user's intensities, "very
# high" int) are the same words.
func test_words() -> void:
	var rows := [["none", &"trivial"], ["easy", &"easy"], ["low", &"easy"], ["light", &"easy"], ["moderate low", &"approachable"], ["Moderate_Low", &"approachable"],
			["moderate", &"standard"], ["medium", &"standard"], ["normal", &"standard"], ["high", &"difficult"], ["hard", &"difficult"], ["heavy", &"difficult"],
			["very high", &"unfair"], ["very  hard", &"unfair"], ["very_heavy", &"unfair"], ["extreme", &"impossible"], ["impossible", &"impossible"]]
	ok(rows.all(func(r): return Difficulty.word(r[0]) == r[1]), "synonyms, any case, _ or a space: %s" % [rows.filter(func(r): return Difficulty.word(r[0]) != r[1])])
	ok(Difficulty.LADDER.keys().all(func(r): return Difficulty.word(r) == r) and Difficulty.WORDS.values().all(func(r): return r in Difficulty.LADDER), "every rung names itself; every word lands on a rung")
	ok(Difficulty.word("nonsense") == &"" and Difficulty.word(&"") == &"" and Difficulty.index("nonsense") == -1 and Difficulty.index("very high") == 5, "a non-word is none")
	ok(Difficulty.dc(&"hard", 3) == Difficulty.dc(&"difficult", 3) and Difficulty.dc(&"hard", 3) == 16 and Difficulty.dc(&"very high") == 20 and Difficulty.dc(&"low", 2) == 5, "a synonym sets the rung's own DC")
	var old := {&"trivial": [1, 1, 1, 1, 1, 1], &"easy": [4, 3, 5, 7, 9, 11], &"approachable": [8, 5, 8, 11, 14, 17], &"standard": [12, 6, 9, 12, 15, 18],
			&"difficult": [16, 8, 12, 16, 20, 24], &"unfair": [20, 9, 13, 17, 21, 25], &"impossible": [30, 10, 14, 18, 22, 26]}  # ranks 0 (flat) to 5, before the table
	ok(old.keys().all(func(r): return range(6).map(func(k): return Difficulty.dc(r, k)) == old[r]), "no DC moved: the ladder at ranks 0 to 5 is as it was")
	ok(Difficulty.dc(RecoveryEndurance.CHECK_DC) == 12, "Recovery Endurance's save is the flat Standard rung, 12")
	# the user's intensities and "very high" are words on the ladder, a magnitude each
	var mags := {"low": &"faint", "moderate_low": &"mild", "moderate": &"moderate", "high": &"strong", "extreme": &"severe", "very high": &"intense"}
	ok(mags.keys().all(func(w): return Difficulty.magnitude(w) == mags[w]) and Difficulty.magnitude("nonsense") == &"", "the user's intensities read through the ladder")
	# cost levels: the old words, the old weights (prices never move); the rest of the ladder is no cost level
	var cost := {"none": 0.0, "no": 0.0, "free": 0.0, "low": 0.5, "light": 0.5, "cheap": 0.5, "moderate": 1.0, "medium": 1.0, "normal": 1.0, "even": 1.0,
			"high": 1.5, "heavy": 1.5, "very high": 2.0, "very heavy": 2.0, "hard": 1.5, "very hard": 2.0}
	ok(cost.keys().all(func(w): return Pricing.level_weight(StringName(w)) == cost[w]), "cost levels, old words and new, weigh what they did")
	ok(Pricing.profile("very hard ap, light mana")[&"ap"] == 2.0 and Pricing.profile("extreme ap")[&"error"] != "" and Pricing.profile("moderate low ap")[&"error"] != "", "a profile reads the shared words; a rung with no weight is no level")
	# who sees the knobs: very high int, 16
	ok(Difficulty.stat_at(Modifiers.KNOB_SIGHT) == 16 and Difficulty.stat_at(&"very high") == 16 and Difficulty.stat_at(&"low") == 0, "very high is an int of 16 (the adventurer's)")


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

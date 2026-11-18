extends Test

# Cost profiles (Skill.costs, Pricing.profile(); docs/plans/w2-cost.md): the words a skill's cost is
# declared in, how they skew the computed price, every skill's profile, and a preferred reserve paying first.

var focus_skill: Skill = load("res://Skills/focus.tres")
var focus: Reserve = load("res://Reserves/focus.tres")


# A skill whose points grow with rank: 1d6 (moderate-ish), +2 to hit a rank.
func grower() -> Skill:
	var s := Skill.new()
	s.name = "Grower ??"
	s.tags = [&"physical"]
	s.radius = 3.0
	s.roll_per_rank = 2
	var t := Tier.new()
	t.dice = Vector2i(1, 6)
	s.tiers = [t]
	return s


# The words: [profile, w_ap, w_cost, rank growth, reserve, only]; and what each costs a skill of known points.
func test_profiles() -> void:
	var table := [
		["even", 1.0, 1.0, 1.0, &"", false],
		["high mana, low ap", 0.5, 1.5, 1.0, &"mana", false],
		["High mana cost, low AP cost", 0.5, 1.5, 1.0, &"mana", false],
		["very heavy ap and no cost", 2.0, 0.0, 1.0, &"", false],
		["light stamina; steep rank", 1.0, 0.5, 2.0, &"stamina", false],
		["sweet nothings only, flat rank", 1.0, 1.0, 0.0, &"sweet_nothings", true],
		["prefers focus", 1.0, 1.0, 1.0, &"focus", false],
		["free ap, cheap energy", 0.0, 0.5, 1.0, &"", false],
	]
	for row in table:
		var p := Pricing.profile(row[0])
		ok(p[&"error"] == "" and [p[&"ap"], p[&"cost"], p[&"rank"], p[&"reserve"], p[&"only"]] == row.slice(1), "%s: %s" % [row[0], p])
	for bad in ["high health", "high mana, low stamina", "bogus ap", "only cost", "prefers ap", "high"]:
		ok(Pricing.profile(bad)[&"error"] != "", "refused: %s (%s)" % [bad, Pricing.profile(bad)[&"error"]])
	var s := grower()
	var p1 := Pricing.points(s, 1)
	var p3 := Pricing.points(s, 3)
	ok(p3 - p1 == 4.0, "rank adds points: %s -> %s" % [p1, p3])
	# [profile, rank, AP, cost]: AP = round(1 + q x 0.5 x w_ap), cost = round(q x 0.5 x w_cost), q = p1 + g (pr - p1)
	var costs := [
		["even", 1, roundf(1.0 + 0.5 * p1), roundi(0.5 * p1)],
		["even", 3, roundf(1.0 + 0.5 * p3), roundi(0.5 * p3)],
		["high mana, low ap", 3, roundf(1.0 + 0.25 * p3), roundi(0.75 * p3)],
		["very high ap, no cost", 3, roundf(1.0 + p3), 0],
		["flat rank", 3, roundf(1.0 + 0.5 * p1), roundi(0.5 * p1)],
		["steep rank", 3, roundf(1.0 + 0.5 * (p1 + 8.0)), roundi(0.5 * (p1 + 8.0))],
		["no ap", 3, 1.0, roundi(0.5 * p3)],
	]
	for row in costs:
		s.costs = row[0]
		ok(Pricing.ap(s, row[1]) == row[2] and Pricing.energy(s, row[1]) == row[3], "%s at rank %d: %s AP, %d (want %s, %d)" % [row[0], row[1], Pricing.ap(s, row[1]), Pricing.energy(s, row[1]), row[2], row[3]])
	s.costs = ""
	s.ap = 7.0
	s.cost = 1
	ok(not s.priced() and Pricing.ap(s, 1) == roundf(1.0 + 0.5 * p1), "no profile: hand-priced, its computed price the baseline's")


# Every skill's profile parses, sits on an active, and the reserve it names can pay it ("X only": its needs).
func test_every_profile() -> void:
	var n := 0
	for f in ResourceLoader.list_directory("res://Skills/"):
		var s: Skill = load("res://Skills/" + f) if f.ends_with(".tres") else null
		if not s or not s.priced():
			continue
		n += 1
		var p := Pricing.profile(s.costs)
		var id: StringName = p[&"reserve"]
		var r: Reserve = load("res://Reserves/%s.tres" % id) if id else null
		ok(p[&"error"] == "" and (not s.passive or s.hybrid), "%s: \"%s\" %s" % [f, s.costs, p[&"error"]])
		ok(not r or r.only.is_empty() or r.only.any(func(t): return s.tagged(t)), "%s: %s can pay for it" % [f, id])
		ok((s.needs == r) if p[&"only"] else (s.needs == null), "%s: \"only\" is its needs" % f)
	ok(n >= 50, "%d skills have a profile" % n)


# A reserve its profile prefers pays first, where it would otherwise come last (Focus, for a melee blow).
func test_prefers() -> void:
	var s := grower()
	s.radius = 1.0
	s.costs = "even"
	v(1).learned.append(slot(focus_skill, 1))
	v(1).learned.append(slot(s, 1))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(1).set_store(focus, 3)
	v(1).energy = 10
	ok(v(1).funding(s) == &"energy", "even: Energy first, Focus only once it can't")
	s.costs = "prefers focus"
	ok(v(1).funding(s) == focus, "prefers focus: Focus first")
	v(1).set_store(focus, 0)
	ok(v(1).funding(s) == &"energy", "...and Energy once Focus can't")

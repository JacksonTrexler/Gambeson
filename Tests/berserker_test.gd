extends Test

# The Berserker (Roles/berserker.tres): Reckless Abandon - Offender (+1 Affinity offensive),
# Unsupportive and Indefensible (-1) - and skipping defensive and supportive steps on its trees.
# Affinity sets the cost curve of a skill's ranks, and so the rank its points buy, live (Unit.worth(),
# Unit.rank_for(), Unit.affinity(), Unit.base_rank()).

func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func berserker() -> Unit:
	var u := b.starter({faction = lancin, role = load("res://Roles/berserker.tres"), name = "Brute"})
	b.get_node("Units").add_child(u)
	return u


func test_curves() -> void:
	var curve := func(a: int) -> Array: return range(1, 6).map(func(n): return Unit.worth(n, a))
	ok(curve.call(0) == [1, 3, 8, 18, 35], "even: unlock 1, then 1 + r^2 a rank - about n^2 (%s)" % [curve.call(0)])
	ok(curve.call(1) == [1, 2, 5, 8, 12], "+1: n log2 n, no less than n (%s)" % [curve.call(1)])
	ok(curve.call(2) == [1, 2, 3, 4, 5], "+2: n")
	ok(curve.call(-1) == [1, 8, 27, 64, 125], "-1: n^3")
	ok(Unit.rank_for(5, 0) == 2 and Unit.rank_for(5, 1) == 3 and Unit.rank_for(5, 2) == 5 and Unit.rank_for(5, -1) == 1, "5 points: rank II even, III at +1, V at +2, I at -1")


func test_reckless_abandon() -> void:
	var u := berserker()
	ok(u.rank(sk("reckless_abandon")) == 1 and sk("reckless_abandon").inherent, "a Berserker is born reckless: an inherent trait")
	ok(u.affinity(sk("crushing_blow")) == 1 and u.affinity(strike) == 1 and u.affinity(sk("frenzy")) == 1, "Offender: +1 to what attacks (Frenzy is tagged offensive outright)")
	ok(u.affinity(sk("rally")) == -1 and u.affinity(sk("bulwark")) == -1 and u.affinity(sk("second_wind")) == -1, "Unsupportive, Indefensible: -1 to helping and guarding")
	ok(u.missing(sk("crushing_blow")) == "" and u.missing(sk("savage_swing")) == "", "it skips Bulwark and Rally on its way to its blows")
	var tabs: Array = u.role.trees().map(func(t: SkillTab): return t.title())
	ok(tabs == ["Berserker", "Prowess: Brawn", "Prowess: Fury", "Prowess: Havoc"], "its own tab and three prowesses (%s)" % [tabs])


func test_live_reranking() -> void:
	var u := berserker()
	var blow := sk("crushing_blow")
	u.skill_points = 10
	ok(u.unlock(blow) and u.raise_cost(blow) == 1, "on the +1 curve, rank II takes 1 point (even: 2)")
	ok(u.raise(blow) and u.raise_cost(blow) == 3 and u.raise(blow), "III takes 3 more (5 in all)")
	ok(u.base_rank(blow) == 3 and u.points_in(blow) == 5, "5 points: rank III")
	var cancel := effect("affinity", -1, [&"offensive"])
	u.afflict(cancel, 3)
	ok(u.base_rank(blow) == 2, "its Offender cancelled (a curse): 5 points on the even curve buy only II, at once")
	u.timed.erase(cancel)
	u.afflict(effect("affinity", 1, [&"offensive"]), 3)
	ok(u.base_rank(blow) == 5, "+2 for a while: the same 5 points buy V")
	var plain := b.starter({faction = lancin, role = load("res://Roles/fighter.tres"), name = "Plain"})
	b.get_node("Units").add_child(plain)
	plain.learned.append(slot(blow, 3))
	ok(plain.affinity(blow) == 0 and plain.base_rank(blow) == 3 and plain.raise_cost(blow) == 10, "without Affinity, nothing changes: rank III, IV for 10")

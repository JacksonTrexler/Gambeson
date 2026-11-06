extends Test

# The Fighter's tree - Protector (shared as the Paladin's Prowess), Vanguard and Slayer - and what's
# built on it: Shields Up! (Unit.guard), Obstruct (Battle.obstruction()), Interdict (a str save; Attack
# Down and AP off by the caster's str mod, set as it lands: Effect.by_mod), Turtle Tactics (the check
# effect: Unit.check_bonus()) and Jugular (disadvantage, a hit is a critical, a natural 20 recasts).

var fighter: Role = load("res://Roles/fighter.tres")
var shields_up: Skill = load("res://Skills/shields_up.tres")
var obstruct: Skill = load("res://Skills/obstruct.tres")
var interdict: Skill = load("res://Skills/interdict.tres")
var turtle: Skill = load("res://Skills/turtle_tactics.tres")
var jugular: Skill = load("res://Skills/jugular.tres")


func test_tree() -> void:
	ok(fighter.roots.map(func(r: SkillRoot): return r.name) == ["Protector", "Vanguard", "Slayer"]
			and fighter.roots.all(func(r: SkillRoot): return r.tag == &"martial"), "three martial roots")
	ok(fighter.tier(shields_up) == 1 and fighter.tier(jugular) == 1 and fighter.tier(interdict) == 2 and fighter.tier(load("res://Skills/snapping_turtle.tres")) == 3,
			"each root opens on an active; the rest come after it")
	var u := b.starter({faction = lancin, role = fighter, name = "Brick"})
	var offered: Array = u.options()[&"class"]
	ok([wary, shields_up, jugular].all(func(s): return s in offered) and interdict not in offered, "on offer: Wary, then the root openers")
	u.skill_points = 5
	ok(u.unlock(shields_up) and u.unlock(interdict) and u.unlock(turtle), "Shields Up! opens the rest of Protector")
	ok(not u.unlock(load("res://Skills/interject.tres")), "a stub can't be learned")
	ok(load("res://Skills/warcry.tres").describe().begins_with("Not built yet. Waits on Tile marks"), "a stub waiting on a system says which")
	u.free()
	for s in [shields_up, obstruct, interdict, turtle, jugular]:
		ok(s.describe(3) != "" and s.stub == "", "%s describes itself" % s.name)


func test_turtle_tactics() -> void:
	v(1).armor = null
	v(1).learned.append(slot(turtle, 3))
	ok(v(1).check_bonus(&"dexterity", &"defensive") == 6 and v(1).check_bonus(&"wisdom", &"defensive") == 6, "rank III: +6 to defensive checks, any stat, no armor needed")
	ok(v(1).check_bonus(&"strength", &"offensive") == -3, "-3 to offensive ones")
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).armor = bulwark()
	v(1).strength = 50
	var with := Battle.hit_chance(v(1), strike, v(3))
	v(1).learned.clear()
	ok(with < Battle.hit_chance(v(1), strike, v(3)), "attack rolls are offensive: they take the penalty")
	ok("Checks: +4 to defensive checks" in turtle.describe(2) and "Checks: -2 to offensive checks" in turtle.describe(2), turtle.describe(2))


func test_shields_up() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(6, 3), v(4): Vector2i(2, 3)})
	v(1).learned.append(slot(shields_up, 2))
	v(1).refresh()
	v(1).max_hp = 1000
	v(1).hp = 1000
	var plain := v(1).hit(100, [&"physical"] as Array[StringName], v(3))
	ok(b.cast_at(v(1), shields_up, Vector2i(6, 3)), "faces a tile")
	ok(v(1).guard == Vector2(2, 0) and is_equal_approx(v(1).stat(&"guard"), 0.4), "rank II: 20% + 10% x 2")
	ok(v(1).hit(100, [&"physical"] as Array[StringName], v(3)) == plain - 40, "a blow from the way it faces: 40% off")
	ok(v(1).hit(100, [&"physical"] as Array[StringName], v(4)) == plain, "from behind: nothing off")
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 4)})
	ok(v(1).guarding(Vector2i(5, 4)) and not v(1).guarding(Vector2i(4, 4)), "the cone is 90 degrees: 45 to either side")
	var a: Unit.Applied = v(1).timed[shields_up.effects[0]]
	ok(a.turns == 2, "until its next turn is through (put on during its own turn: one more)")


func test_obstruct() -> void:
	stage(lancin, {v(1): Vector2i(2, 2), v(2): Vector2i(2, 4), v(3): Vector2i(5, 3)})
	v(1).movement = 30
	v(1).refresh()
	v(1).ap[0].amount = 100.0  # enough to walk the whole way, beside it or not
	var bare: float = b.walk(v(1), Vector2i(8, 2), true).costs.reduce(func(s, x): return s + x, 0.0)
	v(3).learned.append(slot(obstruct, 2))
	var extra := maxf(0.5 * b.pass_cost(v(1), v(3)), 0.5 * v(3).mod(&"constitution") / 10.0) * 1.5
	ok(is_equal_approx(b.obstruction(v(1), Vector2i(4, 2)), extra), "beside it: the larger of half its size penalty and half its con mod / 10, +50%% at rank II (%s)" % b.obstruction(v(1), Vector2i(4, 2)))
	ok(b.obstruction(v(1), Vector2i(2, 2)) == 0.0, "not beside it: nothing")
	ok(b.obstruction(v(4), Vector2i(4, 2)) == 0.0, "its allies pass freely")
	var cost: float = b.walk(v(1), Vector2i(8, 2), true).costs.reduce(func(s, x): return s + x, 0.0)
	ok(is_equal_approx(cost, bare + 3 * extra), "walking past: three tiles beside it, each paying (%s vs %s)" % [cost, bare])


func test_interdict() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).learned.append(slot(interdict, 2))
	v(1).strength = 16  # str mod 3
	v(1).energy = 10
	v(1).refresh()
	v(3).strength = -30  # can't win the save
	v(3).refresh()
	var plain := v(3).ap[0].amount
	var seen := []
	b.contested.connect(func(_c, _t, mine, theirs): seen.append([mine, theirs]))
	ok(b.cast(v(1), interdict, v(3)) and seen.size() == 1 and seen[0][0] >= seen[0][1], "a str save, won")
	ok(is_equal_approx(v(3).stat(&"damage"), -0.4), "Attack Down: -20% x rank damage")
	ok(is_equal_approx(v(3).stat(&"base_ap"), -3.0), "less the caster's str mod in AP, set as it landed")
	v(1).strength = 30
	ok(is_equal_approx(v(3).stat(&"base_ap"), -3.0), "...and fixed then")
	v(3).refresh()
	ok(is_equal_approx(v(3).ap[0].amount, plain - 3.0), "its next turn's AP (%s vs %s)" % [v(3).ap[0].amount, plain])
	ok(v(3).timed[interdict.effects[0]].turns == 1, "for one of its turns")
	ok("AP: -1 each turn x the caster's str mod for 1 turn" in interdict.describe() and "Damage dealt: -40%" in interdict.describe(2), interdict.describe(2))


func test_jugular_crits() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).learned.append(slot(jugular, 1))
	v(1).strength = 50  # str mod 20: hits whatever the worse d20
	v(1).energy = 50
	v(1).weapon = null
	v(3).armor = null
	v(3).max_hp = 1000
	v(3).hp = 1000
	var rolls := []
	b.attacked.connect(func(_c, _t, d20, _total, _def): rolls.append(d20))
	v(1).refresh()
	ok(b.cast(v(1), jugular, v(3)), "used")
	ok(1000 - v(3).hp >= 2 * (1 + 20), "a hit is a critical: double damage (%d)" % (1000 - v(3).hp))
	ok(Battle.hit_chance(v(1), jugular, v(3)) == 1.0, "sure to hit with mod 20")
	v(1).strength = 10
	v(3).armor = bulwark()
	ok(is_equal_approx(Battle.hit_chance(v(1), jugular, v(3)), pow(Battle.hit_chance(v(1), strike, v(3)), 2)), "at disadvantage: the chance squared")
	ok("with Disadvantage" in jugular.describe(1) and "(str mod)" in jugular.describe(1) and "(str mod + 2)" in jugular.describe(3), jugular.describe(3))


func test_jugular_recasts() -> void:
	var j: Skill = jugular.duplicate()
	j.disadvantage = false  # a natural 20 1 in 20, to see it often
	j.cost = 0
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).learned.append(slot(j, 1))
	v(3).max_hp = 1000000
	v(3).hp = 1000000
	var rolls := []
	b.attacked.connect(func(_c, _t, d20, _total, _def): rolls.append(d20))
	for i in 200:
		v(1).refresh()
		b.cast(v(1), j, v(3))
	var twenties := rolls.count(20)
	ok(twenties > 0 and rolls.size() == 200 + twenties, "each natural 20 casts it again at once, free (%d rolls, %d twenties)" % [rolls.size(), twenties])


func test_defend_order() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(7, 3), v(4): Vector2i(1, 6)})
	v(1).learned.append(slot(shields_up, 1))
	v(1).hotbar = [shields_up]
	v(1).refresh()
	ok(v(1).intent_skill(&"defensive") == shields_up, "Shields Up! is a defensive move")
	AI.act(b, v(1), &"defensive")
	ok(v(1).guard == Vector2(3, 0) and v(1).stat(&"guard") > 0.0, "told to defend, it faces the nearest foe it makes out (%s)" % v(1).guard)

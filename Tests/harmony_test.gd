extends Test

# The Bard's three of Wave 7: String Theory (a stand-in for cha on cha-tagged skills), Conductor (an Effect that holds
# only after a rested turn: Effect.rested) and Harmony (Behaviours/harmony.gd: Cadence from checks a commanded unit
# passes, First Chair's impact on a side's first use). Skills/symphony.tres is the Wizard's study, a different skill.

var string_theory: Skill = load("res://Skills/string_theory.tres")
var conductor: Skill = load("res://Skills/conductor.tres")
var harmony: Skill = load("res://Skills/harmony.tres")
var cadence: Effect = load("res://Effects/cadence.tres")


func test_string_theory() -> void:
	var u := v(1)
	u.charisma = 8
	u.intelligence = 16
	var cha: Array[StringName] = [&"cha"]
	ok(u.mod(&"charisma", cha) == -1, "without it, cha -1 on a cha-tagged skill")
	u.learned.append(slot(string_theory, 5)); u.sync_bar()
	ok(u.mod(&"charisma", cha) == 3 and u.mod(&"charisma") == -1 and u.mod(&"charisma", [&"specialist"] as Array[StringName]) == -1, "rank V: its int mod (+3) on a cha-tagged skill, plain cha anywhere else")
	u.charisma = 18
	ok(u.mod(&"charisma", cha) == 4, "the higher of the two: cha 18 stays +4")
	ok(string_theory.describe(1) != "" and not string_theory.ai, "described, and the user's name")


func test_conductor() -> void:
	var c := Command.new(b, v(1))
	v(1).charisma = 12  # +1
	var plain := [c.ally_cap(), c.order_cap(), c.reach(), c.party_reach()]
	v(1).learned.append(slot(conductor, 2)); v(1).sync_bar()
	ok([c.ally_cap(), c.order_cap(), c.reach(), c.party_reach()] == plain, "not rested: its command is as it was")
	v(1).rested_turns = 1
	ok(c.ally_cap() == plain[0] + 2 and c.order_cap() == plain[1] + 2 and c.reach() == plain[2] + 2 and c.party_reach() == (plain[2] + 2) * 2.0, "rested last turn: + rank to allies, orders and reach (the party hears from twice as far)")
	ok(conductor.describe(2).contains("rested"), conductor.describe(2))


func test_harmony() -> void:
	var lead := v(1)
	lead.learned.append(slot(harmony, 2)); lead.sync_bar()
	lead.charisma = 14  # reach 2
	stage(lancin, {lead: Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(5, 4), b.get_node("Units/Alabaster"): Vector2i(9, 3)})
	var far: Unit = b.get_node("Units/Alabaster")
	ok(Command.hears(lead, v(2)) and not Command.hears(lead, far), "v(2) is in its command range, Alabaster 5 tiles off is not")
	b.check(lead, &"strength", null, -50)
	ok(not v(2).timed.has(cadence), "its own check is not a commanded unit's")
	b.check(v(2), &"strength", null, -50)
	ok(v(2).timed[cadence].rank == 1 and lead.timed[cadence].rank == 1 and not far.timed.has(cadence), "a check v(2) passes: +1 on checks for those in range, not those out of it")
	b.check(v(2), &"strength", null, 99)
	ok(v(2).timed[cadence].rank == 1, "a check it fails builds nothing")
	b.check(v(2), &"strength", null, -50)
	b.check(v(2), &"strength", null, -50)
	ok(v(2).timed[cadence].rank == 2 and v(2).check_bonus(&"strength", &"offensive") == 2, "up to rank (II): +2 on checks")
	v(2).tick()
	lead.tick()
	ok(not v(2).timed.has(cadence), "gone as its turn ends")
	b.check(far, &"strength", null, -50)
	ok(not lead.timed.has(cadence), "a unit out of range isn't commanded")


func test_first_chair() -> void:
	var lead := v(1)
	lead.learned.append(slot(harmony, 3)); lead.sync_bar()
	lead.charisma = 14
	var power := 80
	stage(lancin, {lead: Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(5, 2)})
	v(2).learned.append(slot(strike, 1)); v(2).sync_bar()
	soak(v(3))
	var seen: Array[int] = []
	var note := func(c: Unit, _t: Unit, _d: int, _tot: int, _def: int): seen.append(b.impact_of(c))
	b.attacked.connect(note)
	v(2).strength = 40
	ok(b.first_to_act(v(2)) and b.first_to_act(lead), "no one has acted: either is first")
	ok(b.cast(v(2), strike, v(3)), "v(2) strikes")
	ok(not seen.is_empty() and seen.all(func(i): return i == 3), "First Chair: +rank impact on every blow of it %s" % [seen])
	ok(not b.first_to_act(lead) and v(2).hp > 0, "it was the first: no one else is")
	seen.clear()
	v(2).refresh()
	b.cast(v(2), strike, v(3))
	ok(not seen.is_empty() and seen.all(func(i): return i == 0), "its second skill, no impact %s" % [seen])
	b.turn = nemes
	b.turn = lancin
	ok(b.first_to_act(lead), "a new turn of its side: someone is first again")
	b.attacked.disconnect(note)
	# ...and it lands: the same rolls with and without being first, in each place a use's impact is counted
	var kick := sk("kick")
	var aid := sk("first_aid")
	v(2).learned.append(slot(kick, 1)); v(2).sync_bar()
	v(2).learned.append(slot(aid, 1)); v(2).sync_bar()
	for pair in [[strike, v(3)], [kick, v(3)]]:
		var a := _blows(v(2), pair[0], pair[1], true)
		var n := _blows(v(2), pair[0], pair[1], false)
		ok(a > n and (a - n) % 3 == 0, "%s: First Chair's +3 on each blow that landed (%d against %d)" % [pair[0].name, a, n])
	soak(lead)
	var healed := func(first: bool) -> int:
		lead.hp = 1
		v(2).refresh()
		b.acted.clear()
		if not first:
			b.acted[v(1)] = b.turns_begun
		b.cast(v(2), aid, lead)
		return lead.hp - 1
	ok(healed.call(true) - healed.call(false) == 3, "and +3 on a heal")


# The previews read First Chair: damage_range() (the HUD's span, the AI's score) of the first to act carries its +rank on each
# blow, once it is no longer first or not in range it doesn't, and a use under way reports what it really carries.
func test_first_chair_forecast() -> void:
	var lead := v(1)
	lead.learned.append(slot(harmony, 3)); lead.sync_bar()
	lead.charisma = 14
	stage(lancin, {lead: Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(5, 2), b.get_node("Units/Alabaster"): Vector2i(9, 3)})
	v(2).learned.append(slot(strike, 1)); v(2).sync_bar()
	var far: Unit = b.get_node("Units/Alabaster")
	far.learned.append(slot(strike, 1)); far.sync_bar()
	var plain := Battle.damage_range(v(2), strike, v(3))  # (no battle: no passives to ask)
	var first := Battle.damage_range(v(2), strike, v(3), b)
	ok(first.lo == plain.lo + 3 and first.hi == plain.hi + 3 and first.avg == plain.avg + 3, "first to act, in range: + rank on the span (%s against %s)" % [first, plain])
	ok(Battle.damage_range(far, strike, v(3), b).hi == Battle.damage_range(far, strike, v(3)).hi, "out of its command range: nothing added")
	ok(AI.score(v(2), strike, b.read(v(1), v(3)), b, v(3)) > AI.score(v(2), strike, b.read(v(1), v(3)), null, v(3)), "the AI's score counts it too")
	b.acted[v(1)] = b.turns_begun
	ok(Battle.damage_range(v(2), strike, v(3), b).hi == plain.hi, "someone has acted: no longer first, the span is the plain one")
	b.acted.clear()
	b.turn = nemes
	ok(Battle.damage_range(v(2), strike, v(3), b).hi == plain.hi, "not its side's turn (a reaction): not first")


func test_cadence_shown() -> void:
	var lead := v(1)
	lead.learned.append(slot(harmony, 2)); lead.sync_bar()
	lead.charisma = 14
	stage(lancin, {lead: Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(5, 4)})
	var signs := []
	b.passive_fired.connect(func(u: Unit, s: Skill, n: int, stat: StringName, _r: int): signs.append([u, s, n, stat]))
	b.check(v(2), &"strength", null, -50)
	ok(signs.size() == 2 and signs.map(func(x): return x[0]).has(lead) and signs.all(func(x): return x[1] == harmony and x[2] == 1 and x[3] == &"cadence"), "each unit Cadence grows on (the holder, v(2); v(3) is a foe) gets a sign, in Harmony's name (%d)" % signs.size())
	var h := await hud(lead)
	var chip := func(u: Unit) -> Array: return h.effect_icons(u).filter(func(i: Array): return i[0].begins_with("Ca"))
	ok(chip.call(v(2))[0][3] == "", "rank I: no numeral")
	b.check(v(2), &"strength", null, -50)
	ok(chip.call(v(2))[0][3] == "2", "rank II: the chip carries it (%s)" % [chip.call(v(2))])
	h.free()


# The HP v(3) loses to caster's use of s on t, from the same rolls, as the first of its side to act or not.
func _blows(caster: Unit, s: Skill, t: Unit, first: bool) -> int:
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(5, 2)})  # (a kick drives its target off)
	soak(t)
	caster.refresh()
	caster.energy = caster.max_energy
	b.acted.clear()
	if not first:
		b.acted[v(1)] = b.turns_begun
	b.rng.seed = 11
	b.cast(caster, s, t)
	return t.max_hp - t.hp

extends Test

# The Warlock: a tab per patron (Elmon, Hogel) sharing a static tier 1 row (Role.shared), Sweet
# Nothings - a reserve of cha mod x rank that pays a Warlock skill's whole cost with one point, some
# skills needing it, back for each foe slain and as its patron is satisfied (Analysis Dialysis) - and
# wauaw, whose strength climbs to the middle of its turns and back down (Effect.arc).

var sn: Reserve = load("res://Reserves/sweet_nothings.tres")
var sweet: Skill = load("res://Skills/sweet_nothings.tres")
var brainfog: Skill = load("res://Skills/brainfog.tres")
var dialysis: Skill = load("res://Skills/analysis_dialysis.tres")
var wauaw: Skill = load("res://Skills/wauaw.tres")
var warlock: Role = load("res://Roles/warlock.tres")


func sweeten(u: Unit, cha := 14) -> void:
	u.charisma = cha
	u.learned.append(slot(sweet))
	u.set_store(sn, u.pools().get(sn, 0))
	u.refresh()


func test_tree() -> void:
	var trees := warlock.trees()
	ok(trees.map(func(t: SkillTab): return t.title()) == ["Warlock", "Patron: Elmon", "Patron: Hogel"], "its own tab, where it picks a patron, then a tab per patron: %s" % [trees.map(func(t: SkillTab): return t.title())])
	ok(trees.all(func(t: SkillTab): return t.core.slice(0, 3) == [hex, sweet, load("res://Skills/chant.tres")]), "each with the shared row first")
	ok(warlock.tier(hex) == 0 and warlock.tier(sweet) == 0 and warlock.tier(brainfog) == 2 and warlock.tier(load("res://Skills/haluca.tres")) == 2,
			"the shared row it starts with is tier 0; Elmon's path from tier 2 (Brainfog, Haluca)")
	var u := b.starter({faction = lancin, role = warlock, name = "Vex"})
	u.cell = Vector2i(9, 7)
	b.get_node("Units").add_child(u)
	ok(u.rank(hex) == 1 and u.rank(sweet) == 1 and u.pools()[sn] == 2 and u.store(sn) == 2, "it starts with the row learned, its Sweet Nothings full (cha 15: 2)")
	u.skill_points = 1
	ok(u.missing(brainfog) == "Pick Patron: Elmon first", "Elmon's skills wait for Elmon")
	ok(u.pick(warlock.choices[0], warlock.choices[0].tabs[0]) and brainfog in u.options()[&"class"] and u.unlock(brainfog), "Elmon picked: Brainfog, open once Hex is learned")


func test_sweet_nothings() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	sweeten(v(3))
	ok(v(3).pools()[sn] == 2 and v(3).main_reserve() == sn, "max: cha mod (+2) x rank")
	v(3).charisma = 10
	ok(v(3).pools()[sn] == 0, "cha mod +0: none")
	v(3).charisma = 14
	v(3).learned.append(slot(brainfog))
	ok(v(3).funding(brainfog) == sn and v(3).cost_from(brainfog, sn) == 1, "a Warlock skill's whole cost (3) for one Sweet Nothing")
	ok(v(3).funding(hex) == &"energy", "only Warlock skills")
	var energy := v(3).energy
	ok(v(3).pay_for(brainfog) and v(3).store(sn) == 1 and v(3).energy == energy, "paid: one Sweet Nothing, no Energy")
	var cheap := Skill.new()
	cheap.tags = [&"warlock"]
	cheap.cost = 1
	v(3).learned.append(slot(cheap))
	ok(v(3).funding(cheap) == &"energy", "a cost of 1 saves nothing: Energy pays")
	var needy := Skill.new()
	needy.tags = [&"warlock"]
	needy.needs = sn
	v(3).learned.append(slot(needy))
	ok(v(3).funding(needy) == sn and v(3).cost_from(needy, sn) == 1, "a skill that needs one: a Sweet Nothing, even at no cost")
	v(3).set_store(sn, 0)
	ok(v(3).funding(needy) == null, "none left: it can't be used")
	v(1).hp = 1
	for i in 20:
		if not v(1).is_alive():
			break
		v(3).refresh()
		b.cast(v(3), strike, v(1))
	ok(not v(1).is_alive() and v(3).store(sn) == 1, "a foe slain: one back")


func test_dialysis() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(3, 1)})
	sweeten(v(3), 18)  # 4
	v(3).learned.append(slot(dialysis))
	v(3).set_store(sn, 0)
	v(1).afflict(effect("concealment", 3), 9)
	b.suspect(v(3), v(1))
	ok(v(3).store(sn) == 1, "a level of concealment off a hiding foe: 1 x rank")
	b.suspect(v(3), v(1).cell)
	ok(v(3).store(sn) == 2, "suspicion of its tile does it too")
	v(1).timed.clear()
	v(3).suspicion.clear()
	v(3).set_store(sn, 0)
	v(1).afflict(effect("trickery", 1), 9)
	v(1).afflict(effect("persona", 2), 9)
	v(1).stance = "Friendly"
	ok(b.read(v(3), v(1)).attitude(v(3)) == &"ally", "it takes the foe for a friend")
	b.suspect(v(3), v(1))
	ok(b.read(v(3), v(1)).attitude(v(3)) == &"foe" and v(3).store(sn) == 2, "unmasked: 2 x rank")


func test_wauaw() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1), v(4): Vector2i(5, 2)})
	v(3).learned.append(slot(wauaw))
	v(3).refresh()
	ok(b.cast(v(3), wauaw, v(1)), "on a foe, no roll")
	var seen := []
	for i in 5:
		seen.append([roundi(v(1).stat(&"damage") * 100), roundi(v(1).mitigation([&"sound"]) * 100)])
		v(1).tick()
	ok(seen == [[10, -10], [20, -20], [30, -30], [20, -20], [10, -10]], "rank I, 5 turns: 10, 20, 30, 20, 10%% more damage dealt and taken %s" % [seen])
	ok(v(1).stat(&"damage") == 0.0, "then gone")
	v(3).refresh()
	ok(b.cast(v(3), wauaw, v(4)) and v(4).stat(&"damage") > 0.0, "on an ally too")
	ok("Ally or foe" in wauaw.describe(1) and "climbing a step a turn" in wauaw.describe(1), wauaw.describe(1))


func test_toggle() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(4, 1)})
	sweeten(v(3))
	v(3).learned.append(slot(wauaw))
	ok(sweet.toggle and v(3).is_on(sweet), "Sweet Nothings: a toggle, on to start")
	ok(v(3).funding(wauaw) == sn, "on: a Sweet Nothing pays")
	v(3).toggle(sweet)
	ok(v(3).funding(wauaw) == &"energy" and v(3).pools()[sn] == 2 and v(3).store(sn) == 2, "off: nothing spent from it, but it's kept")
	var dear := Skill.new()
	dear.ap = 1.0
	dear.cost = 1
	dear.tags = [&"warlock"]
	dear.needs = sn
	v(3).learned.append(slot(dear))
	ok(v(3).funding(dear) == null, "a skill that needs one can't be paid for")
	v(3).toggle(sweet)
	ok(v(3).funding(dear) == sn, "on again: it can")
	ok(sn.color.r > 0.9 and sn.color.b > 0.6, "pink")


func test_hex_on_cha() -> void:
	var u := b.starter({faction = lancin, role = warlock, name = "Vex"})
	u.wisdom = 8
	u.charisma = 16
	ok(u.mod(&"wisdom", hex.tags) == 3 and u.attack_mod(hex) == 3, "a Warlock's Hex: cha mod (+3) where it'd use wis")
	ok(u.mod(&"wisdom") == -1, "its wisdom is still its own")
	u.free()


func test_one_patron() -> void:
	var role := Role.new()
	role.name = "Pact"
	var tabs: Array[SkillTab] = []
	var learnt: Array[Skill] = []
	for n in ["Elmon", "Hogel"]:
		var s := Skill.new()
		s.name = n + "'s gift"
		s.passive = true
		var br := Branch.new()
		br.skill = s
		var r := SkillRoot.new()
		r.name = n
		r.branches = [br]
		var t := SkillTab.new()
		t.name = n
		t.devotes = true
		t.roots = [r]
		tabs.append(t)
		learnt.append(s)
	var patron := TreeChoice.new()
	patron.name = "Patron"
	patron.tabs = tabs
	role.choices = [patron]
	var u := b.starter({faction = lancin, role = role, name = "Vex"})
	u.skill_points = 2
	ok(u.devotion() == null and tabs.all(func(t: SkillTab): return u.pick_missing(patron, t) == ""), "undevoted: either patron can be picked")
	ok(u.pick(patron, tabs[0]) and u.devotion() == tabs[0] and u.unlock(learnt[0]), "Elmon picked: devoted to Elmon, his gift open")
	ok(u.pick_missing(patron, tabs[1]) == "Took up Elmon" and u.missing(learnt[1]) == "Pick Hogel first" and not u.unlock(learnt[1]), "Hogel stays shut")
	ok(warlock.choices[0].tabs.all(func(t: SkillTab): return t.devotes) and warlock.choices[0].picks == 1, "the Warlock picks one patron, who devotes it")
	u.free()

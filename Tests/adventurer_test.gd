extends Test

# The Adventurer: its starting skills, its skill tree (Role roots and core, Unit.missing()), raising
# ranks (1 + r^2), the starter spells that work on allies and foes alike (Skill.dual), Energy that
# counts as a category's resource (Working Knowledge), slots typed by category (the capstones' Basic
# Skill Slot +1), and the stubs that wait on open questions. Also tiers (Role.tier()), and the Mana
# passive Wizards start with: the starter spells at half cost paid with mana, up to its rank in tier.

var adventurer: Role = load("res://Roles/adventurer.tres")
var mana: Reserve = load("res://Reserves/mana.tres")
var field_experience: Skill = load("res://Skills/field_experience.tres")
var working_knowledge: Skill = load("res://Skills/working_knowledge.tres")
var everyman: Skill = load("res://Skills/everyman.tres")
var sola: Skill = load("res://Skills/sola.tres")
var nadira: Skill = load("res://Skills/nadira.tres")
var astera: Skill = load("res://Skills/astera.tres")
var igna: Skill = load("res://Skills/igna.tres")
var aetha: Skill = load("res://Skills/aetha.tres")
var terestera: Skill = load("res://Skills/terestera.tres")
var hydera: Skill = load("res://Skills/hydera.tres")
var magic_slot: Skill = load("res://Skills/magic_slot.tres")
var martial_slot: Skill = load("res://Skills/martial_slot.tres")
var snare: Skill = load("res://Skills/snare.tres")
var hazard_expert: Skill = load("res://Skills/hazard_expert.tres")
var darkvision: Skill = load("res://Skills/darkvision.tres")
var skill_slot: Skill = load("res://Skills/skill_slot.tres")
var trade_skills: Skill = load("res://Skills/trade_skills.tres")
var grind: Skill = load("res://Skills/grind.tres")
var rejuvinate: Skill = load("res://Skills/rejuvinate.tres")
var wizard: Role = load("res://Roles/wizard.tres")
var mana_skill: Skill = load("res://Skills/mana.tres")


# A starter Adventurer (int 10: mod 0), on the board.
func shrike() -> Unit:
	var u := b.starter({faction = lancin, role = adventurer, name = "Shrike"})
	b.get_node("Units").add_child(u)
	return u


func test_starting_skills() -> void:
	var u := shrike()
	ok([strike, field_experience, working_knowledge, everyman].all(func(s: Skill): return u.rank(s) == 1),
			"starts with Strike, Field Experience, Working Knowledge and Everyman")
	ok(u.hotbar[0] == strike and u.hotbar.count(null) == u.hotbar.size() - 1, "only Strike goes on the bar")
	var offered: Array = u.options()[&"class"]
	ok([hex, sola, nadira, astera, terestera, hydera, wary, snare, darkvision].all(func(s): return s in offered),
			"on offer: Hex at the core, the starter spells, and the first skill of each path")
	ok([hazard_expert, magic_slot, martial_slot, igna, aetha, rejuvinate, skill_slot, trade_skills, grind].all(func(s): return s not in offered),
			"not yet: skills further along, capstones, and stubs")
	ok(igna in u.sources()[&"class"] and skill_slot in adventurer.offered(), "stubs are still part of the tree")
	ok(u.missing(hazard_expert) == "Learn Snare first", "Hazard Expert comes after Snare (%s)" % u.missing(hazard_expert))
	ok(u.missing(magic_slot) == "Needs 3 Magic skills (0 so far)", "the Magic capstone needs 3 of its root (%s)" % u.missing(magic_slot))
	ok(adventurer.root_of(sola).tag == &"magical" and adventurer.root_of(hex) == null, "Sola is on the Magic root; Hex at the core")
	u.free()


func test_tree_unlocks() -> void:
	var u := shrike()
	u.skill_points = 10
	ok(u.unlock(snare) and u.missing(hazard_expert) == "" and hazard_expert in u.options()[&"class"], "Snare opens Hazard Expert")
	ok(not u.unlock(magic_slot) and u.unlock(sola) and u.unlock(nadira), "the capstone waits")
	ok(u.missing(magic_slot) == "Needs 3 Magic skills (2 so far)", "...counting the root's skills learned")
	ok(u.unlock(astera) and u.unlock(magic_slot), "a third: the capstone can be learned")
	ok(not u.unlock(igna) and not u.unlock(skill_slot) and u.rank(igna) == 0, "a stub never can, points or not")
	ok(u.skill_points == 5, "a point each (%d left)" % u.skill_points)
	u.free()


func test_ranks() -> void:
	var u := shrike()
	u.skill_points = 10
	u.unlock(sola)
	ok(u.raise_cost(sola) == 2 and u.raise(sola) and u.rank(sola) == 2 and u.skill_points == 7, "rank II: 1 + 1² = 2 points")
	ok(u.raise_cost(sola) == 5 and u.raise(sola) and u.rank(sola) == 3 and u.skill_points == 2, "rank III: 1 + 2² = 5")
	ok(u.raise_cost(sola) == 10 and not u.raise(sola) and u.rank(sola) == 3 and u.skill_points == 2, "IV would be 10: not enough, nothing spent")
	ok(not u.can_raise(field_experience) and not u.raise(field_experience), "Field Experience stops at its rank cap (I)")
	ok(not u.can_raise(hex) and not u.raise(hex), "only skills it has")
	ok(u.raise(strike) and u.rank(strike) == 2 and adventurer.innate[0].rank == 1, "a starting skill goes up for this unit, not the class")
	u.free()


func test_starter_spells_on_allies() -> void:
	var u := shrike()
	stage(lancin, {u: Vector2i(4, 3), v(1): Vector2i(5, 3), v(3): Vector2i(8, 6)})
	u.learned.append(slot(sola))
	u.refresh()
	ok(sola.for_allies() and sola.for_foes() and not sola.hostile, "Sola works on allies and foes alike")
	ok(b.cast(u, sola, v(1)), "cast on an ally")
	ok(v(1).stat(&"persona") == 1.0 and v(1).timed[sola.effects[0]].turns == 1, "it gets +1 persona for rank (1) turns")
	ok(u.energy == u.max_energy - 2 and is_equal_approx(u.ap_left(), u.full_ap() - 3.0), "2 energy (2 x rank I), 3 AP")
	u.learned[-1].rank = 3
	u.refresh()
	b.cast(u, sola, v(1))
	ok(v(1).timed[sola.effects[0]].turns == 3 and u.energy == u.max_energy - 8, "rank III: 3 turns, for 6 energy")
	ok(is_equal_approx(b.skill_range(u, sola), 1.21), "range int mod (0), but always the adjacent: 1 + reach and sizes")
	u.intelligence = 16
	ok(is_equal_approx(b.skill_range(u, sola), 3.21), "int 16: range 3")
	ok("On an ally: Persona: +1 for 3 turns" in sola.describe(3) and "On a foe: deals 1d4 + int" in sola.describe(3),
			"described both ways (%s)" % sola.describe(3))
	u.free()


func test_starter_spells_on_foes() -> void:
	var u := shrike()
	stage(lancin, {u: Vector2i(4, 3), v(3): Vector2i(5, 3)})
	u.learned.append(slot(sola))
	v(3).max_hp = 200
	v(3).heal(200)
	var rolls := []
	b.attacked.connect(func(_c, _t, d20: int, _total, _def): rolls.append(d20))
	var hits := 0
	for i in 20:
		u.refresh()
		u.energy = u.max_energy
		var was := v(3).hp
		ok(b.cast(u, sola, v(3)), "cast on a foe")
		var lost := was - v(3).hp
		var hit: bool = rolls[-1] + u.attack_mod(sola) >= v(3).defense(sola.tags) or rolls[-1] == 20
		ok(lost == 0 if not hit else lost in range(1, 9), "a hit deals 1d4 + int mod (0); a miss nothing (rolled %d, lost %d)" % [rolls[-1], lost])
		hits += int(hit)
	ok(rolls.size() == 20 and hits > 0, "it rolls to hit, every time")
	ok(v(3).stat(&"persona") == 0.0 and sola.effects[0] not in v(3).timed, "a foe doesn't get the persona")
	u.free()


func test_defense_spells() -> void:
	var u := shrike()
	stage(lancin, {u: Vector2i(4, 3), v(1): Vector2i(5, 3)})
	u.learned.append(slot(terestera, 2))
	u.learned.append(slot(hydera, 1))
	u.refresh()
	var plain := v(1).defense()
	ok(b.cast(u, terestera, v(1)) and v(1).defense([&"pierce"]) == plain + 2 and v(1).defense() == plain,
			"Terestera II: +2 physical Defense, nothing against the rest")
	ok(v(1).timed[terestera.effects[0]].turns == 3, "for 3 turns")
	ok(b.cast(u, hydera, v(1)) and v(1).defense([&"magical"]) == plain + 1, "Hydera I: +1 magical Defense")
	ok(v(1).tagged_defense() == {&"physical": 2, &"magical": 1}, "both show on its card (%s)" % v(1).tagged_defense())
	u.free()


func test_shadow_and_luck_spells() -> void:
	var u := shrike()
	stage(lancin, {u: Vector2i(4, 3), v(1): Vector2i(5, 3)})
	u.learned.append(slot(nadira))
	u.learned.append(slot(astera, 2))
	u.refresh()
	var luck := v(1).luck
	ok(b.cast(u, nadira, v(1)) and Perception.cover(b, v(1)) == 1, "Nadira: a level of dark concealment")
	ok(b.cast(u, astera, v(1)) and v(1).luck == luck + 1 and v(1).timed[astera.effects[0]].turns == 2, "Astera II: +1 luck for 2 turns")
	u.free()


func test_working_knowledge() -> void:
	var u := shrike()
	u.learned.append(slot(hex))
	v(1).learned.append(slot(hex))
	ok(u.energy_tags() == [&"martial", &"magical", &"specialist"], "Field Experience, Working Knowledge, Everyman")
	ok(u.funding(hex) == &"energy" and is_equal_approx(u.ap_cost(hex, &"energy"), 2.0), "Hex paid with Energy: half AP, as with Mana")
	ok(is_equal_approx(v(1).ap_cost(hex, &"energy"), 4.0), "...where a villager's Energy is just Energy")
	var stamina := Reserve.new()
	stamina.only.assign([&"martial"])
	var bash := Skill.new()
	bash.tags.assign([&"physical", &"martial"])
	bash.ap = 4.0
	bash.ap_with[stamina] = 0.25
	ok(is_equal_approx(u.ap_cost(bash, &"energy"), 1.0) and is_equal_approx(v(1).ap_cost(bash, &"energy"), 4.0),
			"Field Experience: martial resources' bonuses (a stamina skill at a quarter AP)")
	bash.tags.assign([&"physical"])
	ok(is_equal_approx(u.ap_cost(bash, &"energy"), 4.0), "...only for martial skills")
	stage(lancin, {u: Vector2i(4, 3), v(3): Vector2i(5, 3)})
	ok(b.cast(u, hex, v(3)) and is_equal_approx(u.ap_left(), u.full_ap() - 2.0), "a cast takes 2 AP")
	ok("Energy paid for magic skills counts as their own resources" in working_knowledge.describe(), "described")
	u.free()


func test_typed_slots() -> void:
	var u := shrike()
	u.skill_points = 20
	for s in [sola, nadira, astera]:
		u.unlock(s)
	ok(same(u.hotbar, [strike, sola, nadira, astera, null]), "spells fill the free slots (the fifth, a clover, needs luck)")
	ok(u.unlock(magic_slot) and u.granted_slots() == [&"magical"], "the capstone grants a Magic slot")
	ok(u.slot_kinds() == [&"", &"", &"", &"", &"magical", &"clover"] and u.clover() == 5, "after the sure slots, before the clover one")
	ok(same(u.hotbar, [strike, sola, nadira, astera, null, null]), "nothing moved")
	ok(not u.bar_place(strike, 4) and u.bar_place(sola, 4), "it holds only magical skills")
	ok(u.unlock(terestera) and u.hotbar[1] == terestera, "the next spell takes the free sure slot first")
	u.level_up()
	u.level_up()
	u.level_up()
	ok(same(u.hotbar, [strike, terestera, nadira, astera, null, sola]), "level 4: a plain fifth slot; the Magic slot moves along, keeping Sola")
	u.level_up()
	ok(same(u.hotbar, [strike, terestera, nadira, astera, null, sola, null]) and u.clover() == 6, "level 5: the clover slot comes back, last")
	ok(u.bar_place(nadira, 5) and same(u.hotbar, [strike, terestera, sola, astera, null, nadira, null]), "a swap: Sola fits the sure slot")
	ok(u.bar_place(nadira, 0) and same(u.hotbar, [nadira, terestera, sola, astera, null, null, null]), "...Strike doesn't fit the Magic slot: off the bar")
	ok("Skill slots: +1 Magic" in magic_slot.describe(), "described (%s)" % magic_slot.describe())
	u.free()


func test_stubs() -> void:
	ok(igna.stub == "?10" and igna.mark() == "?10" and aetha.mark() == "?10", "Igna and Aetha wait on question 10")
	ok(igna.describe().begins_with("Not built yet. Waits on open question 10 (todo.md)") and "skill AP" in igna.describe(), "it says so, and what it's meant to do")
	ok(trade_skills.waits() == "Waits on open questions 2 and 11 (todo.md)" and grind.mark() == "?2", "two questions")
	ok(skill_slot.mark() == "?3" and rejuvinate.mark() == "?12", "Skill Slot +1: 3; Rejuvinate: 12")
	ok(sola.mark() == "So" and field_experience.mark() == "FE" and magic_slot.mark() == "+1", "the rest: initials, or a glyph")
	ok(igna.summary() == "Not built yet", "listed as not built")


func test_tiers() -> void:
	var u := shrike()
	ok([skill_slot, hex, strike, working_knowledge, igna, sola, wary, snare, darkvision].all(func(s: Skill): return adventurer.tier(s) == 1),
			"tier 1: the centre, the core ring, and the start of each root")
	ok(adventurer.tier(hazard_expert) == 2 and u.tier(hazard_expert) == 2, "Hazard Expert: tier 2, after Snare")
	ok(adventurer.tier(magic_slot) == 4 and adventurer.tier(martial_slot) == 4, "the capstones: tier 4, after 3 of their root")
	var stoneskin: Skill = load("res://Skills/stoneskin.tres")
	ok(adventurer.tier(stoneskin) == 0 and u.tier(stoneskin) == 1, "a skill its class doesn't offer: tier 1 for a unit")
	ok(wizard.tier(sola) == 1 and wizard.tier(mana_skill) == 1, "a Wizard's list: all tier 1")
	var x := Skill.new()
	var y := Skill.new()
	var z := Skill.new()
	var root := SkillRoot.new()
	for pair in [[x, []], [y, [x]], [z, [y, x]]]:
		var br := Branch.new()
		br.skill = pair[0]
		br.after.assign(pair[1])
		root.branches.append(br)
	var role := Role.new()
	role.roots.append(root)
	ok(role.tier(x) == 1 and role.tier(y) == 2 and role.tier(z) == 3, "a chain: 1, 2, 3 (z needs x and y, x counted once)")
	u.free()


# A starter Wizard: Mana I, and 10 mana.
func ember() -> Unit:
	var u := b.starter({faction = lancin, role = wizard, name = "Ember"})
	b.get_node("Units").add_child(u)
	return u


func test_mana_casting() -> void:
	var u := ember()
	ok(u.rank(mana_skill) == 1 and mana_skill in wizard.options and u.store(mana) == 10 and u.opened(mana) == 1,
			"a Wizard starts with Mana I and 10 mana")
	u.learned.append(slot(sola, 2))
	ok(u.price(sola) == 4 and u.cost_from(sola, &"energy") == 4 and u.cost_from(sola, mana) == 2, "Sola II: 4 Energy, or 2 mana")
	ok(u.funding(sola) == mana, "mana pays first")
	stage(lancin, {u: Vector2i(4, 3), v(1): Vector2i(5, 3)})
	u.refresh()
	ok(b.cast(u, sola, v(1)) and u.store(mana) == 8 and u.energy == u.max_energy, "cast: 2 mana, no energy")
	u.set_store(mana, 1)
	ok(u.funding(sola) == &"energy" and u.cost_from(sola, &"energy") == 4, "short of mana: 4 Energy")
	var deep := sola.duplicate()
	var root := SkillRoot.new()
	for pair in [[sola, []], [deep, [sola]]]:
		var br := Branch.new()
		br.skill = pair[0]
		br.after.assign(pair[1])
		root.branches.append(br)
	u.role = Role.new()
	u.role.roots.append(root)
	u.learned.append(slot(deep, 1))
	ok(u.tier(deep) == 2 and u.cost_from(deep, mana) == 2 and u.cost_from(sola, mana) == 2, "a tier 2 spell: full cost at Mana I")
	u.learned.append(slot(mana_skill, 2))
	ok(u.opened(mana) == 2 and u.cost_from(deep, mana) == 1, "Mana II: half cost up to tier 2")
	ok("Half cost paid with Mana, once the caster's Mana rank reaches its tier" in sola.describe() and "Half AP paid with Mana" in hex.describe(),
			"described (%s)" % sola.describe())
	ok("skills up to tier 2 get the savings they list for it" in mana_skill.describe(2), "Mana described by rank (%s)" % mana_skill.describe(2))
	u.free()
	var s := shrike()
	s.reserves[mana] = 10
	s.set_store(mana, 10)
	s.learned.append(slot(sola))
	ok(s.cost_from(sola, mana) == 2 and s.cost_from(sola, &"energy") == 2, "an Adventurer, without Mana: 2 either way")
	s.learned.append(slot(mana_skill))
	ok(s.cost_from(sola, mana) == 1 and s.cost_from(sola, &"energy") == 1, "with it, Working Knowledge passes the saving to Energy")
	s.free()


func same(a: Array, x: Array) -> bool:
	return a.size() == x.size() and range(a.size()).all(func(i): return a[i] == x[i])

extends Test

# The Adventurer's Specialist skills: Move +1, Meander (standing still while walking a little, and
# passing by weak ground: Unit.still(), passes_by()), Hide (concealment until it moves) and Clever
# Disguise (trickery that holds, then fades), both investigated by the enemies that can see them
# used, against one roll (Battle.investigate()); Self-evaluation (seeing allies' rolls:
# Battle.evaluators()); Clever Disguise's own rank costs; and the Rogue's and Bard's Calling:
# Freedom tabs. Trap at (5,4).

const TRAP := Vector2i(5, 4)
var trap: Terrain = load("res://Terrain/trap.tres")
var snare: Skill = load("res://Skills/snare.tres")
var darkvision: Skill = load("res://Skills/darkvision.tres")
var move_plus_one: Skill = load("res://Skills/move_plus_one.tres")
var meander: Skill = load("res://Skills/meander.tres")
var hide: Skill = load("res://Skills/hide.tres")
var clever: Skill = load("res://Skills/clever_disguise.tres")
var evaluation: Skill = load("res://Skills/self_evaluation.tres")
var adventurer: Role = load("res://Roles/adventurer.tres")


func shrike() -> Unit:
	var u := b.starter({faction = lancin, role = adventurer, name = "Shrike"})
	b.get_node("Units").add_child(u)
	return u


func test_tree() -> void:
	ok(adventurer.tier(move_plus_one) == 2 and adventurer.tier(meander) == 2, "Move +1 and Meander: tier 2")
	ok(adventurer.tier(hide) == 3 and adventurer.tier(clever) == 3, "Hide and Clever Disguise: tier 3")
	ok([move_plus_one, meander, hide, clever].all(func(s: Skill): return adventurer.root_of(s).tag == &"specialist"), "all on the Specialist root")
	var u := shrike()
	u.skill_points = 10
	ok(u.missing(hide) == "Learn Meander first" and u.missing(meander) == "Learn Darkvision first" and u.missing(move_plus_one) == "Learn Snare first",
			"each after the one before it")
	ok(u.unlock(darkvision) and u.unlock(meander) and u.unlock(hide) and u.unlock(clever), "Darkvision, Meander, then Hide and Clever Disguise")
	ok(u.unlock(snare) and u.unlock(move_plus_one) and not u.can_raise(move_plus_one), "Snare, then Move +1, which stops at rank I")
	u.free()


func test_rank_costs() -> void:
	var u := shrike()
	u.learned.append(slot(clever))
	u.skill_points = 30
	ok(u.raise_cost(clever) == 4 and u.raise(clever) and u.skill_points == 26, "Clever Disguise II: 4 points")
	ok(u.raise_cost(clever) == 8 and u.raise(clever) and u.raise_cost(clever) == 16, "then 8, then 16")
	ok(u.raise_cost(snare) == 1 and u.raise_cost(strike) == 2, "other skills keep 1 + r²")
	ok("Ranks cost more: II takes 4 points, then x2 each rank" in clever.describe(), "described")
	u.free()


func test_move_plus_one() -> void:
	var was := v(1).stat(&"movement")
	v(1).learned.append(slot(move_plus_one))
	ok(v(1).stat(&"movement") == was + 1, "+1 movement (%d)" % v(1).stat(&"movement"))


func test_meander() -> void:
	stage(lancin, {v(1): Vector2i(1, 1), v(2): Vector2i(1, 6), v(3): Vector2i(9, 7)})
	v(1).learned.append(slot(meander, 2))
	v(1).refresh()
	v(2).refresh()
	ok(v(1).meander() == 2 and v(1).still(2) and not v(1).still(3), "Meander II: 2 tiles a turn while standing still")
	b.travel(v(1), Vector2i(3, 1))
	ok(v(1).steps == 2 and v(1).still() and v(1).activity() == &"rest", "2 tiles: still standing still, so it rests")
	b.travel(v(2), Vector2i(2, 6))
	ok(v(2).activity() != &"rest", "without Meander, a tile is moving")
	b.travel(v(1), Vector2i(4, 1))
	ok(not v(1).still() and v(1).activity() != &"rest", "a third tile: it's moved")
	v(1).toggle(meander)
	ok(v(1).meander() == 0 and not v(1).still(1), "switched off: no tiles")


func test_meander_passes_by() -> void:
	trap.dice = Vector2i(4, 1)
	var poison := effect("poison", 0.1)
	trap.afflicts = [poison]
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(9, 0)})
	v(1).learned.append(slot(meander, 1))
	v(1).refresh()
	var sprung := []
	b.sprung.connect(func(c: Vector2i, by: Unit): sprung.append([c, by]))
	var passed := b.travel(v(1), Vector2i(6, 4))
	ok(passed.size() == 2 and v(1).cell == Vector2i(6, 4), "Meander I: over the trap (level 1) without stopping")
	ok(sprung.is_empty() and v(1).hp == v(1).max_hp and poison not in v(1).timed and not b.revealed.has(TRAP), "nothing sprung, nothing put on it")
	stage(lancin, {v(2): Vector2i(4, 4), v(3): Vector2i(9, 0)})
	v(2).refresh()
	ok(b.travel(v(2), Vector2i(6, 4)).size() == 1 and sprung.size() == 1 and poison in v(2).timed, "without it: stops on the trap, springs it")
	trap.afflicts = []
	trap.dice = Vector2i(1, 6)
	v(3).learned.append(slot(snare, 2))
	var laid := b.lay(v(3), snare, Vector2i(7, 1))
	ok(laid.terrain.level == 2, "a Snare II is level 2")
	stage(lancin, {v(1): Vector2i(6, 1), v(3): Vector2i(9, 7)})
	v(1).refresh()
	b.travel(v(1), Vector2i(8, 1))
	ok(sprung.size() == 2 and v(1).cell == Vector2i(7, 1), "...more than Meander I passes by: it springs")


func test_hide() -> void:
	stage(lancin, {v(1): Vector2i(1, 1), v(3): Vector2i(8, 6)})
	v(1).learned.append(slot(hide, 2))
	v(1).refresh()
	var looks := []
	b.investigated.connect(func(by: Unit, _of: Unit, _s: Skill, total: int, against: int, close: bool): looks.append([by, total, against, close]))
	ok(b.watchers(v(1)) == [v(3)], "the enemy in sight is watching")
	ok(not b.cast(v(1), hide, v(2)), "only on itself")
	ok(b.cast(v(1), hide, v(1)), "it hides")
	var a: Unit.Applied = v(1).timed[hide.effects[0]]
	ok(roundi(v(1).stat(&"concealment")) == 2 and a.until_move and a.turns == 0, "Hide II: 2 concealment, until it moves")
	ok(looks.size() == 1 and looks[0][0] == v(3) and not looks[0][3], "the watcher investigates (far off: no advantage)")
	ok((v(3) in a.known_to) == (looks[0][1] >= looks[0][2]), "seeing through it on meeting the roll (%d vs %d)" % [looks[0][1], looks[0][2]])
	a.known_to.clear()
	ok(b.read(v(3), v(1)).net < -1, "fooled: it loses track of it")
	a.known_to.append(v(3))
	ok(b.read(v(3), v(1)).net >= 0 and b.read(v(4), v(1)).net < -1, "seen through: only for the one that did")
	for i in 4:
		b.end_turn()
	ok(hide.effects[0] in v(1).timed, "turns pass: still hidden")
	v(1).refresh()
	b.travel(v(1), Vector2i(2, 1))
	ok(hide.effects[0] not in v(1).timed and roundi(v(1).stat(&"concealment")) == 0, "it moves: out of hiding")
	ok("Concealment: +2 until it moves" in hide.describe(2) and "Self · 2 AP · 1 cost · on itself" in hide.describe(2)
			and "Enemies that can see it investigate" in hide.describe(2), "described (%s)" % hide.describe(2))


func test_hide_meandering() -> void:
	stage(lancin, {v(1): Vector2i(1, 1), v(3): Vector2i(8, 6)})
	v(1).learned.append(slot(hide))
	v(1).learned.append(slot(meander, 1))
	v(1).refresh()
	b.cast(v(1), hide, v(1))
	b.travel(v(1), Vector2i(2, 1))
	ok(hide.effects[0] in v(1).timed, "Meander I: a tile and it's still hidden")
	b.travel(v(1), Vector2i(3, 1))
	ok(hide.effects[0] not in v(1).timed, "a second: it's moved")


func test_close_investigators() -> void:
	stage(lancin, {v(1): Vector2i(2, 1), v(3): Vector2i(3, 1)})
	v(3).wisdom = 18  # mod 4
	v(1).learned.append(slot(hide, 2))
	v(1).refresh()
	var looks := []
	b.investigated.connect(func(by: Unit, _of: Unit, _s: Skill, _t: int, _a: int, close: bool): looks.append(close))
	b.cast(v(1), hide, v(1))
	ok(looks == [true], "adjacent, within wis mod (4) - rank (2) tiles: at advantage")


func test_clever_disguise() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(7, 3)})
	v(1).learned.append(slot(clever, 2))
	v(1).refresh()
	ok(b.cast(v(1), clever, v(1)), "disguised")
	var a: Unit.Applied = v(1).timed[clever.effects[0]]
	ok(roundi(v(1).stat(&"trickery")) == 2 and a.fades and a.turns == 3, "Clever Disguise II: 2 trickery, holding for 2 turns after this one")
	a.known_to.clear()
	var r := b.read(v(3), v(1))
	ok(r.deceived and r.faction == nemes, "fooled, the enemy takes it for one of its own")
	a.known_to.append(v(3))
	ok(not b.read(v(3), v(1)).deceived, "seen through: not fooled")
	for i in 4:
		b.end_turn()
	ok(roundi(v(1).stat(&"trickery")) == 2, "two of its turns on: holding")
	b.end_turn()
	ok(roundi(v(1).stat(&"trickery")) == 1, "then a level less")
	b.end_turn()
	b.end_turn()
	ok(clever.effects[0] not in v(1).timed, "and gone")
	ok("Trickery: +2 for 2 turns, then a level less each turn" in clever.describe(2) and "Rolls once as it's used: d20 + cha mod + 2" in clever.describe(2),
			"described (%s)" % clever.describe(2))


func test_one_roll() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(7, 3), v(4): Vector2i(7, 5)})
	v(1).learned.append(slot(clever, 2))
	v(1).refresh()
	ok(b.watchers(v(1)).size() == 2, "two enemies watching")
	var against := []
	b.investigated.connect(func(_by: Unit, _of: Unit, _s: Skill, _t: int, a: int, _c: bool): against.append(a))
	b.cast(v(1), clever, v(1))
	var a: Unit.Applied = v(1).timed[clever.effects[0]]
	var lo := 1 + v(1).mod(&"charisma") + 2
	ok(against.size() == 2 and against[0] == against[1] and against[0] == a.roll, "one roll, for every investigator, kept on the disguise (%s)" % [against])
	ok(a.roll >= lo and a.roll <= lo + 19 and a.skill == clever, "d20 + cha mod + rank (%d)" % a.roll)


func test_self_evaluation() -> void:
	ok(adventurer.tier(evaluation) == 1 and adventurer.root_of(evaluation).tag == &"specialist", "tier 1, first on the Specialist root")
	ok("Self-evaluation: sees the rolls of allies using active skills within 2 tiles, its own too" in evaluation.describe(2), "described (%s)" % evaluation.describe(2))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(6, 3), v(3): Vector2i(9, 3)})
	v(1).learned.append(slot(clever))
	v(2).learned.append(slot(evaluation, 1))
	v(3).learned.append(slot(evaluation, 9))
	v(1).refresh()
	var seen := []
	b.evaluated.connect(func(u: Unit, s: Skill, d20: int, total: int): seen.append([u, s, d20, total]))
	ok(b.evaluators(v(1)).is_empty(), "two tiles off, Self-evaluation I doesn't reach; an enemy's doesn't count")
	b.cast(v(1), clever, v(1))
	ok(seen.is_empty() and not v(1).timed[clever.effects[0]].evaluated, "its roll goes unseen")
	stage(lancin, {v(1): Vector2i(5, 3), v(2): Vector2i(6, 3), v(3): Vector2i(9, 3)})
	v(1).refresh()
	ok(b.evaluators(v(1)) == [v(2)], "a tile off: in reach")
	b.cast(v(1), clever, v(1))
	var a: Unit.Applied = v(1).timed[clever.effects[0]]
	ok(seen.size() == 1 and seen[0][0] == v(1) and seen[0][1] == clever and seen[0][3] == a.roll and seen[0][3] - seen[0][2] == v(1).mod(&"charisma") + 1,
			"the ally sees it: d20 %d, total %d" % [seen[0][2], seen[0][3]] if seen else "the ally sees it")
	ok(a.evaluated, "and the disguise keeps it, seen")
	stage(lancin, {v(1): Vector2i(5, 3), v(3): Vector2i(6, 3)})
	v(1).learned.append(slot(evaluation))
	v(1).learned.append(slot(strike))
	v(1).refresh()
	ok(b.evaluators(v(1)) == [v(1)], "on its own: it evaluates itself")
	b.cast(v(1), strike, v(3))
	ok(seen.size() == 2 and seen[1][1] == strike and seen[1][3] - seen[1][2] == v(1).attack_mod(strike), "attack rolls too")


func test_rogue_and_bard() -> void:
	var rogue: Role = load("res://Roles/rogue.tres")
	var bard: Role = load("res://Roles/bard.tres")
	var wary: Skill = load("res://Skills/wary.tres")
	ok(rogue.has_tree() and bard.has_tree(), "both have trees (stubs for now)")
	ok(rogue.trees().map(func(t: SkillTab): return t.title()) == ["Rogue", "Calling: Freedom"] and bard.trees()[1].title() == "Calling: Freedom",
			"each: its own tab, then Calling: Freedom")
	var own := rogue.trees()[0]
	var free := rogue.trees()[1]
	ok(own.core.is_empty() and own.offers(wary) and not own.offers(move_plus_one) and not own.offers(snare),
			"the Rogue's own: Wary (Strike is the General tree's; Move +1 shows under Freedom)")
	ok(free.center == hide and [move_plus_one, darkvision, evaluation].all(func(s: Skill): return s in free.core)
			and [snare, meander, clever].all(free.offers), "its specialist skills under Freedom: Hide at the centre, Snare, Move +1, Meander...")
	ok(rogue.tier(hide) == 1 and rogue.tier(clever) == 2 and rogue.tier(load("res://Skills/hazard_expert.tres")) == 2, "tiers, across tabs")
	var song := bard.trees()[0]
	var roam := bard.trees()[1]
	ok(song.offers(load("res://Skills/sola.tres")) and bard.tier(load("res://Skills/astera.tres")) == 2 and not song.offers(meander),
			"the Bard's own: songs (Sola, then Astera)")
	ok(roam.center == clever and [meander, move_plus_one, evaluation].all(func(s: Skill): return s in roam.core)
			and roam.offers(load("res://Skills/tonefoolery.tres")), "its Freedom: Clever Disguise at the centre, Meander, Move +1, Performance")
	var r := b.starter({faction = lancin, role = rogue, name = "Wren"})
	var d := b.starter({faction = lancin, role = bard, name = "Lark"})
	b.get_node("Units").add_child(r)
	b.get_node("Units").add_child(d)
	ok(r.rank(move_plus_one) == 1 and r.dexterity == 15 and hide in r.options()[&"class"] and snare in r.options()[&"class"],
			"a Rogue starts with Move +1 and can learn Hide or Snare at once")
	ok(r.missing(load("res://Skills/hazard_expert.tres")) == "Learn Snare first", "a tab's branches hold")
	ok(d.rank(meander) == 1 and d.charisma == 15 and clever in d.options()[&"class"], "a Bard starts meandering, and can learn Clever Disguise at once")
	r.free()
	d.free()

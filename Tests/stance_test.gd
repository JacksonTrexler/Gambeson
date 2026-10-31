extends Test

# Persona among allies: stances that claim the wrong team (Unit.stance, Read.attitude()), teammates
# for orders and parties (Battle.teammates()), low-wisdom allies reading each other (Perception._dim()),
# Conspire, and the AI acting on stances and Craven behaviour.

var conspire: Skill = load("res://Skills/conspire.tres")


# v(2) fronts persona rank p with stance s; v(1) (wis 10) isn't insightful, so fronting fools it.
func pose(s: String, p := 3) -> void:
	v(2).afflict(effect("persona", p), 9)
	v(2).stance = s
	v(1).wisdom = 10


func test_stances() -> void:
	pose("Enemy")
	var r := b.read(v(1), v(2))
	ok(r.deceived and r.stance == &"enemy" and r.faction == nemes and r.attitude(v(1)) == &"foe", "Enemy: its ally takes it for a foe")
	v(2).stance = "Aggressive"
	ok(b.read(v(1), v(2)).attitude(v(1)) == &"avoid", "Aggressive: dangerous, to be avoided")
	v(2).stance = "Passive"
	r = b.read(v(1), v(2))
	ok(r.attitude(v(1)) == &"ignore" and r.faction == lancin, "Passive: mostly ignored")
	v(2).stance = "Friendly"
	ok(b.read(v(1), v(2)).attitude(v(1)) == &"ally", "Friendly: a candidate for support")
	v(2).stance = "Traitor"
	ok(b.read(v(1), v(2)).attitude(v(1)) == &"foe", "Traitor: against its real allies...")
	ok(b.read(v(3), v(2)).attitude(v(3)) == &"foe", "...but its enemies need trickery to be fooled")
	v(2).afflict(effect("trickery", 5), 9)
	ok(b.read(v(3), v(2)).attitude(v(3)) == &"ally" and b.read(v(3), v(2)).faction == nemes, "with it, its real enemies take it for one of theirs")
	v(2).timed.clear()
	pose("Enemy", 2)
	ok(b.read(v(1), v(2)).stance == &"" and b.read(v(1), v(2)).attitude(v(1)) == &"ally", "the wrong team takes Persona III")
	v(1).wisdom = 12
	pose("Enemy")
	v(1).wisdom = 12
	ok(b.read(v(1), v(2)).attitude(v(1)) == &"ally", "an insightful ally isn't fooled by fronting alone")


func test_teammates() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	var c := Command.new(b, v(1))
	ok(c.can_order(v(2)) and c.can_join(v(2)) and b.teammates(v(1), v(2)), "allies: teammates, to order and party with")
	pose("Enemy")
	ok(not b.teammates(v(1), v(2)) and not c.can_order(v(2)) and not c.can_join(v(2)), "taken for an enemy: no orders, no party")
	v(2).stance = "Passive"
	ok(not c.can_order(v(2)), "nor if it seems to be on no side")
	v(2).stance = "Friendly"
	ok(c.can_order(v(2)), "Friendly: still a teammate")


func test_low_wisdom_reads() -> void:
	v(1).wisdom = 8
	var r := b.read(v(1), v(2))
	ok(r.name == "Villager2" and r.healthy == true and r.hp == null and r.stats.is_empty() and r.level == null, "wis mod -1: no details, only healthy or bloodied")
	ok(r.traits == Perception.traits(v(2), {}) and r.traits[0] in ["Imposing", "Insignificant", "Average"] + Perception.TRAITS.values(),
			"and a word or two for it (%s)" % ", ".join(r.traits))
	ok(b.read(v(3), v(2)).hp == null or b.read(v(3), v(2)).traits.is_empty(), "enemies read as before: no traits")
	v(2).afflict(effect("persona", 2), 9)
	ok(b.read(v(1), v(2)).hp == v(2).hp, "unless its persona advertises its HP")
	v(2).timed.clear()
	v(1).wisdom = 2
	r = b.read(v(1), v(2))
	ok(r.name == "" and r.faction == lancin and r.looks == "Everyman" and r.healthy == null and r.traits.is_empty(), "wis mod -4: only its side, and what it looks like")
	var siren: Unit = b.get_node("Units/Siren")
	v(3).wisdom = 2
	ok(b.read(v(3), siren).looks == siren.alias_noun, "a persona's noun, from rank 3 (%s)" % siren.alias_noun)
	ok(b.read(v(3), b.get_node("Units/Icor")).looks == "Caster", "else its kind's (Wizard: Caster)")


func test_conspire() -> void:
	for path in ["res://Roles/adventurer.tres", "res://Roles/bard.tres"]:
		ok((load(path) as Role).tier(conspire) == 4, "%s: Conspire, tier 4" % path.get_file())
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(8, 2)})
	v(2).charisma = 12
	v(2).learned.append(slot(conspire, 2))
	v(2).refresh()
	ok(v(1).insightful() and b.read(v(1), v(2)).deceived, "allies within rank + cha mod tiles let it fool them, insightful or not")
	ok(Perception.trickery(v(2), Read.new(), null, b) == Perception.trickery(v(2), Read.new()) + 1.0, "and each gives it rank - 1 trickery")
	v(2).afflict(effect("persona", 3), 9)
	v(2).stance = "Enemy"
	var r := b.read(v(1), v(2))
	ok(r.attitude(v(1)) == &"ally" and b.teammates(v(1), v(2)), "no infighting: they defect together")
	var from_ally := v(2).hit(10.0, [], v(1))
	var from_foe := v(2).hit(10.0, [], v(3))
	ok(from_ally < from_foe and from_ally <= 4, "66%% less friendly fire (%d against %d)" % [from_ally, from_foe])
	v(2).learned[-1].on = false
	v(1).wisdom = 10
	ok(v(2).candid() and not b.read(v(1), v(2)).deceived, "switched off: its allies see straight through it")


func test_craven() -> void:
	stage(nemes, {v(3): Vector2i(8, 2), v(4): Vector2i(8, 6), v(1): Vector2i(1, 2)})
	v(3).behaviour = &"craven"
	AI.act(b, v(3))
	ok(v(3).cell == Vector2i(8, 2), "craven, with no stronger ally near: it stays put")
	v(4).level = 2
	b.move(v(4), Vector2i(8, 4))
	AI.act(b, v(3))
	ok(v(3).cell == Vector2i(8, 2), "a higher-level ally it can't tell is higher-level: it still stays")
	v(4).afflict(effect("persona", 2), 9)
	AI.act(b, v(3))
	ok(v(3).cell != Vector2i(8, 2), "advertised (Persona II): it advances")


func test_craven_flees() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).behaviour = &"craven"
	v(3).afflict(effect("persona", 3), 9)
	v(3).afflict(effect("trickery", 5), 9)
	v(3).stance = "Aggressive"
	ok(b.read(v(1), v(3)).attitude(v(1)) == &"avoid", "it takes the foe for aggressive")
	AI.act(b, v(1))
	ok(Command.tiles(v(1).cell, v(3).cell) > 1, "craven: it backs away (%s)" % v(1).cell)


func test_ai_stances() -> void:
	stage(nemes, {v(3): Vector2i(1, 1), v(1): Vector2i(2, 1)})
	var swings := []
	b.attacked.connect(func(c: Unit, _t: Unit, _d: int, _x: int, _df: int): swings.append(c))
	v(1).afflict(effect("persona", 3), 9)
	v(1).afflict(effect("trickery", 5), 9)
	v(1).stance = "Aggressive"
	AI.act(b, v(3))
	ok(swings.is_empty(), "taken for aggressive: avoided, not struck")
	v(1).stance = "Passive"
	v(3).refresh()
	AI.act(b, v(3))
	ok(swings.is_empty(), "taken for passive: left be")
	v(1).stance = ""
	v(1).timed.clear()
	v(3).refresh()
	AI.act(b, v(3))
	ok(not swings.is_empty(), "otherwise, struck")

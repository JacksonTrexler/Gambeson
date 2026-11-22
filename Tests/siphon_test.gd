extends Test

# The siphon tag (Glossary.TERMS; Unit.siphon(), read in Battle.cast() before the energy rule): a siphon
# attack's damage, past mitigation and luck, comes off the target's resources and never its HP - its
# Overcharge first, then the fund it last paid from, then Energy, then its other reserves it spends,
# fullest first, spilling from one to the next. A powered target loses Unit.POWER_SIPHON (x1.5) as much.

var transfer: Skill = load("res://Skills/energy_transfer.tres")
var mana: Reserve = load("res://Reserves/mana.tres")
var stamina: Reserve = load("res://Reserves/stamina.tres")
const TAGS: Array[StringName] = [&"energy", &"siphon"]


func test_siphon() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(3).energy = 10
	var hp := v(3).hp
	ok(v(3).siphon(4, TAGS, null) == 4 and v(3).energy == 6 and v(3).hp == hp, "4 off its Energy, none off its HP")
	ok(v(3).siphon(9, TAGS, null) == 6 and v(3).energy == 0 and v(3).hp == hp, "only what it holds: 6, and its HP untouched")
	ok(v(3).siphon(3, TAGS, null) == 0 and v(3).hp == hp, "empty: nothing, still no HP")


func test_order() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(3).reserves = {mana: 5, stamina: 8}
	v(3).set_store(mana, 5)
	v(3).set_store(stamina, 8)
	v(3).energy = 4
	v(3).add_overcharge(2, 3)
	ok(v(3).siphon_order() == [&"energy", stamina, mana], "after Overcharge: Energy, then its reserves fullest first")
	v(3).paid_with = mana
	ok(v(3).siphon_order() == [mana, &"energy", stamina], "what it last paid from goes first")
	ok(v(3).siphon(5, TAGS, null) == 5 and v(3).overcharge == 0 and v(3).store(mana) == 2 and v(3).energy == 4, "Overcharge first (2), then Mana (3)")
	ok(Unit.OVERCHARGE not in v(3).timed, "Overcharge spent: its status ends")
	ok(v(3).siphon(4, TAGS, null) == 4 and v(3).store(mana) == 0 and v(3).energy == 2, "Mana runs out: it spills on to Energy")


func test_power() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	v(3).afflict(effect("powered", 1.0), 9)
	v(3).energy = 10
	ok(v(3).powered(), "powered")
	ok(v(3).siphon(4, TAGS, null) == 6 and v(3).energy == 4, "Power is easier to siphon: 4 takes 6")


func test_cast() -> void:
	v(1).learned.append(slot(transfer))
	v(1).intelligence = 40
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	v(1).refresh()
	v(3).energy = 10
	var hp := v(3).hp
	ok(b.cast(v(1), transfer, v(3)), "Energy Transfer lands")
	ok(v(3).hp == hp and v(3).energy < 10 and v(3).energy >= 6, "its 1d4 off the foe's Energy (%d), none off its HP" % v(3).energy)
	ok(Glossary.TERMS.has(&"siphon") and Glossary.TERMS.has(&"overcharge"), "both are Glossary terms")

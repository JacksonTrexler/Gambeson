extends Test

# Borrowed Time (Skills/borrowed_time.tres), the Wizard's Arcane root after Blink (needing 3 others):
# passive, defer +rank (Unit.defer(), Battle._borrowed()). On its last life, taken to 0 HP, it doesn't
# die - once a battle - for rank of its side's rounds: its HP stops at 0 and it acts. It logs what harmed
# it (HP lost, debuffs) over the last rank rounds; as each of its rounds ends, that is replayed in order.
# Its last round over, a check against an execute at its rank: failing, it falls as it would have
# (Downed first, with Tenacity); passing, it lives. Bless helps (hale, + rank to checks that execute).

var borrowed: Skill = load("res://Skills/borrowed_time.tres")
var tenacity: Skill = load("res://Skills/tenacity.tres")
var intervention: Skill = load("res://Skills/intervention.tres")


func ready(r := 2) -> void:
	v(3).learned.append(slot(borrowed, r))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(1, 1), v(3): Vector2i(5, 3), v(4): Vector2i(8, 6)})
	v(3).refresh()
	v(3).max_hp = 100
	v(3).hp = 100
	ok(v(3).lives_left() == 0 and v(3).defers() == r, "on its last life, defer %d" % r)


# Turns pass until v(3)'s side's turn has ended once: one of its rounds.
func its_round() -> void:
	while b.turn != v(3).faction:
		b.end_turn()
	b.end_turn()


func test_defer() -> void:
	ready()
	var told := []
	b.borrowed.connect(func(u: Unit, how: StringName): told.append(how))
	var hex := effect("luck", -2.0)
	v(3).damage(40)
	v(3).afflict(hex, 3)
	v(3).damage(999)
	ok(v(3).is_alive() and v(3).hp == 0 and v(3).deferred == 2 and told == [&"begin"], "taken to 0 it lives on, its death put off 2 rounds (%s)" % [told])
	ok(not b.cast(v(1), strike, v(3)) or v(3).is_alive(), "nothing kills it meanwhile")
	ok(v(3).harms.size() >= 3 and v(3).harms[2].get(&"hp") == 999 and v(3).harms[0].get(&"hp") == 40 and v(3).harms[1].get(&"effect") == hex, "it logged the blows and the hex, in order, the strike after too (%s)" % [v(3).harms])
	v(3).hp = 60  # healed meanwhile
	v(3).timed.erase(hex)  # cleansed meanwhile
	its_round()
	ok(v(3).hp == 0 and &"replay" in told and v(3).deferred == 1, "the replay takes it back to 0 (%d, %s)" % [v(3).hp, told])
	ok(hex in v(3).timed, "the hex goes on again")
	its_round()
	ok(not v(3).is_alive() and &"executed" in told, "its time up at 0 HP, the execute takes it (%s)" % [told])


func test_downed() -> void:
	ready(1)
	v(3).learned.append(slot(tenacity, 2))
	v(3).refresh()
	v(3).damage(999)
	ok(v(3).deferred == 1 and v(3).dbno == null, "Borrowed Time before Downed")
	its_round()
	ok(v(3).is_alive() and v(3).dbno != null and v(3).deferred == 0, "the execute failing, it goes Downed as it would have")
	v(3).damage(999)
	ok(not v(3).is_alive(), "once a battle: next time it dies past its limit")


func test_bless() -> void:
	ready(1)
	v(3).afflict(effect("hale", 1.0), 9)
	v(3).afflict(effect("check", 30.0, [&"execute"]), 9)
	v(3).damage(999)
	its_round()
	ok(v(3).is_alive() and v(3).hp == 1 and v(3).deferred == 0, "hale and steeled against executes, it passes and lives, at 1 HP (%d)" % v(3).hp)
	ok(Glossary.plain(borrowed.markup(2)).contains("2 rounds"), "described: %s" % Glossary.plain(borrowed.markup(2)))

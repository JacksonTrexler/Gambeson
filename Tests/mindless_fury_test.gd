extends Test

# Mindless Fury (Skills/mindless_fury.tres; the mindless stat), the Berserker's capstone on Fury: the
# generic permit against helpless. Whatever takes all its actions - Stunned, asleep, Downed without the
# will to fight on - it still takes rank skill uses a turn, in a reduced capacity (Unit.reduced()): its
# mental stats count as 1. Spent, it's stopped and tapped like anyone: no endless actions.

var fury: Skill = load("res://Skills/mindless_fury.tres")
var stunned: Effect = load("res://Effects/stunned.tres")
var tenacity: Skill = load("res://Skills/tenacity.tres")


func berserk(r := 2) -> void:
	v(3).learned.append(slot(fury, r))
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(5, 4)})
	v(3).refresh()
	v(1).max_hp = 300
	v(1).hp = 300
	v(3).intelligence = 18


func test_fury() -> void:
	berserk(2)
	ok(v(3).mod(&"intelligence") == 4 and not v(3).reduced(), "standing: its own mind (int mod +4)")
	v(3).afflict(stunned, 3, 3)
	ok(v(3).helpless() and not v(3).stopped() and not v(3).tapped() and v(3).reduced(), "Stunned, but its fury lets it act: reduced capacity")
	ok(v(3).mod(&"intelligence") == Unit.FURY_MOD, "its mental stats count as 1 (mod %d)" % Unit.FURY_MOD)
	var c := Command.new(b, v(4))
	ok(c.can_order(v(3)), "it takes orders")
	ok(b.cast(v(3), strike, v(1)), "a first skill use")
	for p in v(3).ap:
		p.amount = 20.0
	ok(b.cast(v(3), strike, v(1)), "a second (rank II)")
	ok(v(3).stopped() and v(3).tapped() and not b.cast(v(3), strike, v(1)), "its fury spent: stopped, AP or not")
	ok(c.tapped(v(3)) and not c.can_order(v(3)), "and takes no more orders")
	v(3).refresh()
	ok(not v(3).stopped() and v(3).reduced(), "its next turn: rank uses again")
	ok(fury.describe(2).contains("Mindless Fury actions"), "described: %s" % fury.describe(2))


func test_through_sleep_and_downed() -> void:
	berserk(1)
	v(3).afflict(effect("sleep", 1.0), 3)
	ok(v(3).asleep() and v(3).helpless() and not v(3).stopped(), "asleep is helpless too: it acts through it")
	v(3).timed.clear()
	v(3).learned.append(slot(tenacity, 2))
	v(3).damage(999)
	ok(v(3).dbno != null and v(3).helpless() and not v(3).stopped() and b.cast(v(3), strike, v(1)), "Downed under Tenacity: it still fights on")


func test_without() -> void:
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(3).refresh()
	v(3).afflict(stunned, 3, 1)
	ok(v(3).stopped() and not v(3).reduced(), "no permit: Stunned stops it outright")

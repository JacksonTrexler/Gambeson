extends Test

# Jam (Skills/jam.tres, Behaviours/jam.gd): a low-damage melee blow, the Rogue's (Blade) and the Slayer
# Prowess tree's. Landing, it interrupts its foe (Battle.interrupt()): its channel, hiding, Shields Up!'s
# guard, a primed Chant and its resting watch all end; then, the instant stun, it's Jammed through its
# next turn - it can't dodge, guard or obstruct.

var jam: Skill = load("res://Skills/jam.tres")
var metea: Skill = load("res://Skills/metea.tres")
var shields_up: Skill = load("res://Skills/shields_up.tres")


# v(1) jamming at rank r, sure to hit (dex 40), at v(3) beside it, sturdy, keeping up all it can.
func jammer(r := 1) -> void:
	v(1).learned.append(slot(jam, r))
	v(1).dexterity = 40
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	v(3).max_hp = 300
	v(3).hp = 300
	v(3).channel = Unit.Channel.new(metea, Vector2i(2, 2))
	var hid := v(3).afflict(effect("luck", 0.0), 0)
	hid.until_move = true
	v(3).guard = Vector2(-1, 0)
	v(3).afflict(shields_up.effects[0], 2).skill = shields_up
	v(3).chant_up = true
	v(3).rested_turns = 2


func test_interrupts() -> void:
	jammer()
	ok(v(3).guarding(Vector2i(4, 3)), "guarding toward it before")
	var got := []
	b.interrupted.connect(func(u: Unit, ended: Array[StringName]): got.append([u, ended]))
	ok(b.cast(v(1), jam, v(3)), "Jam lands")
	ok(v(3).hp < 300 and 300 - v(3).hp <= 4 + v(1).mod(&"dexterity"), "low damage: 1d4 + dex mod (%d)" % (300 - v(3).hp))
	ok(v(3).channel == null and v(3).guard == Vector2.ZERO and not v(3).chant_up and v(3).rested_turns == 0, "its channel, guard, Chant and watch: all ended")
	ok(not v(3).timed.values().any(func(a: Unit.Applied): return a.until_move or (a.skill == shields_up)), "hiding and the guard's effects gone")
	ok(got.size() == 1 and got[0][1] == [&"channel", &"hiding", &"guard", &"chant", &"watch"], "it says what it ended: %s" % [got])
	ok(v(3).stat(&"jammed") > 0.0, "Jammed")


func test_jammed() -> void:
	jammer()
	b.cast(v(1), jam, v(3))
	v(3).guard = Vector2(-1, 0)
	ok(not v(3).guarding(Vector2i(4, 3)), "Jammed: no guard")
	ok(is_equal_approx(b.evade(v(3), 1), 1.0), "no dodge: all of it lands, even against DC 1")
	v(3).afflict(effect("obstruct", 3.0), 9)
	ok(is_zero_approx(b.obstruction(v(1), Vector2i(5, 4))), "no obstructing")
	b.end_turn()
	ok(v(3).stat(&"jammed") > 0.0, "through its own next turn...")
	b.end_turn()
	ok(v(3).stat(&"jammed") <= 0.0 and b.obstruction(v(1), Vector2i(5, 4)) > 0.0, "...and gone once that's over")


func test_who() -> void:
	ok(load("res://Trees/slayer.tres").branches.any(func(x: Branch): return x.skill == jam), "on the Slayer tree (the Paladin's most offensive Prowess)")
	var rogue := b.starter({faction = lancin, role = load("res://Roles/rogue.tres"), name = "Elman"})
	b.get_node("Units").add_child(rogue)
	ok(rogue.missing(jam) == "", "the Rogue can learn it (%s)" % rogue.missing(jam))
	ok(not jam.ai and jam.name == "Jam", "the user's name")
	var said := jam.describe(1)
	ok("Interrupts" in said and "Jammed" in said and "1d4" in said, said)

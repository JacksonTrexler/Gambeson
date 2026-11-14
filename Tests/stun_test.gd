extends Test

# Stun (Skills/stun.tres, Behaviours/stun.gd), Brawn's deepest skill: a very difficult blow; landing,
# the foe makes a difficult con check (one that taps) or is Stunned for rank turns. Stunned
# (Effects/stunned.tres) is helpless - so tapped (Unit.tapped(), Command.tapped()) - a wound a heal of
# its rank clears, and easy to cleanse (ease 2). Tapped is never stored: lift the stun and the unit is
# free at once. Also the check tag seam: a `check` effect tagged `taps` helps with every check that taps.

var stun: Skill = load("res://Skills/stun.tres")
var stunned: Effect = load("res://Effects/stunned.tres")
var metea: Skill = load("res://Skills/metea.tres")


# v(1) stunning at rank r, sure to hit, at v(3) beside it: sturdy, but with con 1 (mod -5) it can't
# make the check from rank III (DC 16).
func stunner(r := 3) -> void:
	v(1).learned.append(slot(stun, r))
	v(1).strength = 40
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(5, 4)})
	v(1).refresh()
	v(3).refresh()
	v(3).max_hp = 300
	v(3).hp = 300
	v(3).constitution = 1


func test_stun() -> void:
	stunner()
	ok(stun.roll_bonus == -5 and &"taps" in stun.tags, "a very difficult attack (-5), whose check taps")
	v(3).channel = Unit.Channel.new(metea, Vector2i(2, 2))
	ok(b.cast(v(1), stun, v(3)), "Stun lands")
	ok(stunned in v(3).timed and v(3).timed[stunned].rank == 3, "con 1 against DC 16: Stunned, at rank III")
	ok(v(3).helpless() and v(3).stopped() and v(3).tapped() and v(3).ap_left() > 0.0, "helpless, so tapped, AP or not")
	ok(v(3).channel == null, "a stun that stops it breaks its channel")
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(5, 4)})
	v(3).refresh()
	var c := Command.new(b, v(4))
	ok(c.tapped(v(3)) and not c.can_order(v(3)), "it takes no orders")
	ok(not b.cast(v(3), strike, v(1)) and b.travel(v(3), Vector2i(6, 3)).is_empty(), "it can't act or move")
	ok(AI.act(b, v(3)).is_empty(), "left to itself, it does nothing")
	ok(stunned.helps() == -1 and stunned.wound, "a debuff, and a wound")
	ok(stun.describe(3).contains("DC 16") and Glossary.plain(stun.markup(3)).contains("Stunned"), "described: %s" % Glossary.plain(stun.markup(3)))


func test_lifted() -> void:
	stunner()
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(5, 4)})
	var c := Command.new(b, v(4))
	v(3).refresh()
	v(3).afflict(stunned, 3, 3)
	ok(c.tapped(v(3)), "Stunned III: tapped")
	ok(b.mend(v(3), 0, 2) == 0 and c.tapped(v(3)), "a heal clearing rank II wounds doesn't take it off")
	ok(b.mend(v(3), 0, 3) == 1 and not c.tapped(v(3)) and c.can_order(v(3)), "one clearing rank III does: free at once, it takes orders")
	v(3).afflict(stunned, 3, 4)
	ok(b.cleanse(v(3), 2) == 2 and stunned not in v(3).timed and not v(3).tapped(), "easy to cleanse: 2 ranks take off Stunned IV")
	for p in v(3).ap:
		p.amount = 0.0
	ok(v(3).tapped() and c.tapped(v(3)) and not v(3).stopped(), "out of AP: tapped too, without being helpless")
	v(3).refresh()
	ok(not c.tapped(v(3)), "AP back: no longer")


func test_save() -> void:
	stunner()
	var steel := effect("check", 40.0, [&"taps"])
	v(3).afflict(steel, 9)
	ok(v(3).check_bonus(&"constitution", &"defensive", [&"taps"]) == 40 and v(3).check_bonus(&"constitution", &"defensive") == 0,
			"a check effect tagged taps: every check that taps, and no other")
	ok(b.cast(v(1), stun, v(3)) and stunned not in v(3).timed and not v(3).tapped(), "with it, the check is made: not Stunned")

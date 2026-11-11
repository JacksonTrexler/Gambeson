extends Test

# Vanishing Act: concealment and trickery of rank on its user till it moves, investigated (cha) by
# foes that saw it. One that doesn't see through it watched it vanish before its eyes: it goes on
# taking it for its side (Battle._vanish()) - unless the act's trickery fools it, as here.

var act: Skill = load("res://Skills/vanishing_act.tres")


func test_vanishing_act() -> void:
	v(1).learned.append(slot(act, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(6, 3)})
	v(1).charisma = 60  # its act's roll is past seeing through
	var gone := []
	b.vanished.connect(func(by: Unit, of: Unit, _was: Read): gone.append([by, of]))
	ok(b.read(v(3), v(1)).faction == lancin, "v(3) makes it out")
	ok(b.cast(v(1), act, v(1)), "it vanishes")
	ok(is_equal_approx(v(1).stat(&"concealment"), 2.0) and v(1).stat(&"trickery") >= 2.0, "concealment and trickery +2")
	var r := b.read(v(3), v(1))
	ok([v(3), v(1)] in gone and v(3).assumed.get(v(1)) == lancin, "it vanished before v(3)'s eyes, which takes it for the Lancin it seemed")
	ok(r.deceived and r.faction == nemes, "but its trickery fools v(3) still: it seems one of v(3)'s own (net %d)" % r.net)

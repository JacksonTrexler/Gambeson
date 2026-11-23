extends Test

# Disturbance (Skills/disturbance.tres, Behaviours/disturb.gd) and Disturbed (Effects/disturbed.tres,
# Unit.disturbed()): a wisdom check, easy for a leader and very difficult (unfair) for anyone else; failing,
# the target is Disturbed for the skill's rank in turns: Command refuses it and its orders, and it plays
# itself by its own behaviour (HUD autopilot / Command.idle()), on whichever side it is.

var disturbance: Skill = load("res://Skills/disturbance.tres")
var disturb: GDScript = load("res://Behaviours/disturb.gd")


# v(1) casts at rank r; v(3), a leader (v(4) follows it), and v(4), not one, stand beside it; both with wisdom
# mod `m` (score 10 + 2m).
func caster(r: int, m: int) -> void:
	v(1).learned.append(slot(disturbance, r)); v(1).sync_bar()
	roomy(v(1))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(4, 4), v(2): Vector2i(1, 5)})
	v(4).follows = v(3)
	for u in [v(2), v(3), v(4)]:
		u.wisdom = 10 + 2 * m
		soak(u)
	v(1).refresh()


func test_difficulty_by_leader() -> void:
	caster(10, 20)  # rank X: easy 21, unfair 45 - against a d20 + 20 a leader always passes, anyone else never
	ok(b.leads(v(3)) and not b.leads(v(4)), "a unit with a party leads; its follower doesn't")
	ok(disturb.dc(b, v(3), 10) == Difficulty.dc(&"easy", 10) and disturb.dc(b, v(4), 10) == Difficulty.dc(&"unfair", 10), "easy for a leader, unfair (very difficult) for the rest")
	ok(b.cast(v(1), disturbance, v(3)) and not v(3).disturbed(), "the leader shrugs it off")
	v(1).refresh()
	ok(b.cast(v(1), disturbance, v(4)) and v(4).disturbed(), "its follower can't")
	b.player = v(4)
	ok(b.leads(v(4)) and disturb.dc(b, v(4), 10) == Difficulty.dc(&"easy", 10), "the player's unit leads")


func test_duration() -> void:
	caster(3, -20)
	ok(b.cast(v(1), disturbance, v(3)) and v(3).disturbed(), "it lands on a unit that fails the check")
	ok(not b.cast(v(1), disturbance, v(3)) or v(3).timed.size() == 1, "not twice over (fits)")
	var n := 0
	while v(3).disturbed() and n < 20:
		b.end_turn()
		n += 1
	ok(n == 6, "Disturbed for rank (3) of its own turns: gone after %d turn changes" % n)
	v(3).afflict(effect("disturbed", 1), 99)
	ok(v(3).disturbed(), "any source of the stat will do: a status, an item, a trait")


# The Nemes' v(3) disturbs the Lancin's v(2) (a foe to it), beside v(1), the Lancin leader; then it's the Lancin's turn.
func foe_disturbs() -> void:
	v(3).learned.append(slot(disturbance, 1)); v(3).sync_bar()
	roomy(v(3))
	stage(nemes, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(6, 3), v(4): Vector2i(9, 0)})
	v(2).wisdom = -30
	v(3).refresh()
	ok(b.cast(v(3), disturbance, v(2)) and v(2).disturbed(), "the Nemes disturb a Lancin ally")
	b.turn = lancin
	calm()


func test_command_blocked() -> void:
	var c := Command.new(b, v(1))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(8, 3)})
	ok(c.can_order(v(2)) and c.can_join(v(2)), "before: v(2) takes orders and may join")
	foe_disturbs()
	ok(not c.could_order(v(2)) and not c.can_join(v(2)) and not Command.hears(v(1), v(2), 9), "Disturbed: no orders, no party, out of its leader's hearing")
	c.lock(v(2))
	ok(v(2) in c.idle(), "even held, it acts on its own as the turn ends")
	v(2).timed.clear()
	c.new_turn()
	ok(c.could_order(v(2)), "and orders again when it lifts")
	v(1).afflict(effect("disturbed", 1), 9)
	ok(not c.could_order(v(2)) and not c.can_join(v(2)) and not Command.hears(v(1), v(2), 9) and not c.could_order(v(1)), "a Disturbed leader commands no one, itself included")


func test_ai_takes_over() -> void:
	foe_disturbs()
	v(2).wisdom = 10
	b.move(v(2), Vector2i(6, 4))
	var h := await hud(v(1))
	ok(h.my_turn() and not h.command.could_order(v(2)), "the player's turn, but v(2) isn't theirs to command")
	var was := v(3).hp
	var ap := v(2).ap_left()
	h.end_turn()
	ok(v(3).hp < was or v(2).ap_left() < ap or v(2).cell != Vector2i(6, 4), "it took its turn under the AI")
	await tree.process_frame
	h.free()
	await tree.process_frame  # its overlay goes with it
	b.turn = lancin
	v(1).afflict(effect("disturbed", 1), 9)
	var g := await hud(v(1))
	ok(g.autopilot() and not g.my_turn(), "a Disturbed player: no one at the helm, the side plays itself")
	await tree.process_frame
	g.free()
	await tree.process_frame

extends Test

# The Coyote items (docs/plans/w4-coyote.md), a seam each: the disabling hook (Unit.disable() ->
# Behaviour.disabling(), the target's side: Coyote Charm; the disabler's: Coyote Scepter) with the postpone
# stat (disablings and curse debuffs wait), the overcome stat (Curse of the Coyote: cleanses and heals hit it
# first), and the instant-death hook (Unit.slay() -> Behaviour.slain(): an enchanted Charm lends Borrowed Time).

var charm: Item = load("res://Items/coyote_charm.tres")
var scepter: Item = load("res://Items/coyote_scepter.tres")
var brainfog: Skill = load("res://Skills/brainfog.tres")
var buff: Effect = load("res://Effects/coyote_charm.tres")
var curse: Effect = load("res://Effects/curse_of_the_coyote.tres")


func wear(u: Unit, it: Item, r: int, enchanted := false) -> Unit:
	var x: Item = it.duplicate()
	x.rank = r
	if enchanted:
		x.tags = x.tags.duplicate()  # duplicate() shares the original's
		x.tags.append(&"enchanted")
	u.equip(x)
	u.refresh()
	return u


func test_postpones() -> void:
	stage(nemes, {v(1): Vector2i(1, 1), v(3): Vector2i(5, 1)})
	wear(v(1), charm, 2)
	v(1).disable(favour, 3)
	ok(favour not in v(1).disabled and v(1).postponed.get(favour, [0])[0] == 3 and v(1).luck == 1, "the disabling waits: Favour still works (%s)" % [v(1).postponed])
	ok(buff in v(1).timed and curse in v(1).timed and v(1).timed[buff].rank == 2 and v(1).timed[curse].rank == 2 and v(1).timed.keys().back() == curse, "the buff and the curse at its rank, the curse rightmost")
	var held: int = v(1).timed[buff].turns
	ok(held == 2, "for rank turns, off its own side's turn (%d)" % held)
	v(1).disable(strike, 1)
	ok(v(1).timed[buff].turns == held and strike in v(1).postponed, "another waits too; the buff isn't renewed")
	for i in held:
		ok(favour not in v(1).disabled and v(1).timed[curse].turns == held, "turn %d: still waiting, the curse not counting down" % i)
		v(1).tick()
	ok(buff not in v(1).timed and v(1).disabled.get(favour) == 3 and v(1).disabled.get(strike) == 1 and v(1).postponed.is_empty(), "the buff over, both land for their full turns (%s)" % [v(1).disabled])
	ok(v(1).luck == 0 and v(1).timed[curse].turns == held, "Favour's luck goes; the curse starts counting")
	v(1).tick()
	ok(v(1).timed[curse].turns == held - 1, "and counts down now")


func test_overcome() -> void:
	stage(lancin, {v(1): Vector2i(1, 1)})
	soak(v(1), 100)
	v(1).hp = 50
	var wound := effect("luck", -1.0)
	wound.wound = true
	var hexed := effect("luck", -2.0)
	v(1).afflict(wound, 5, 1)
	v(1).afflict(hexed, 5, 3)
	v(1).afflict(curse, 5, 2)
	ok(b.cleanse(v(1), 1) == 1 and v(1).timed[curse].rank == 1 and v(1).timed[hexed].rank == 3, "a cleanse hits the curse first, though the hex ranks higher")
	ok(b.mend(v(1), 20, 3) == 0 and curse not in v(1).timed and v(1).hp == 50 and wound in v(1).timed, "a heal only wears the curse away: no HP, no wound cleared")
	ok(b.mend(v(1), 20, 3) == 1 and v(1).hp == 70, "overcome, heals work again")
	ok(b.cleanse(v(1), 3) == 3 and hexed not in v(1).timed, "and cleanses")


func test_scepter() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(1, 1)})
	v(3).charisma = 20
	v(3).learned.append(slot(brainfog, 1))
	roomy(v(3))
	wear(v(3), scepter, 3)
	ok(v(3).equipped(load("res://Skills/coyote_scepter.tres")), "the Scepter's skill is on")
	v(1).wisdom = 1
	for i in 30:
		v(3).refresh()
		b.cast(v(3), brainfog, v(1))
		if not v(1).postponed.is_empty() or not v(1).disabled.is_empty():
			break
	ok(v(1).disabled.is_empty() and v(1).postponed.get(favour, [0])[0] == 2 + 3, "rank I's 2 turns + the Scepter's 3, held (%s %s)" % [v(1).postponed, v(1).disabled])
	ok(v(1).timed.get(buff) and v(1).timed[buff].rank == 3 and v(1).timed.get(curse) and v(1).timed[curse].rank == 3, "its target gets the Charm buff and the curse at the Scepter's rank")


# The AI prices a disable by what its target postpones (any postpone status, Unit.postponed): a Brainfog on a unit under the Charm's
# buff is worth less than on one that is not (statuses read at recon 3), and less again for each disabling already held; Strike's price is unchanged.
func test_ai_weighs_a_postponed_disable() -> void:
	stage(nemes, {v(3): Vector2i(5, 1), v(1): Vector2i(1, 1)})
	v(3).learned.append(slot(brainfog, 1))
	roomy(v(3))
	sharp(v(3))
	v(3).refresh()
	var worth := func(s: Skill) -> float: return AI.score(v(3), s, b.read(v(3), v(1)), b, v(1))
	var plain: float = worth.call(brainfog)
	var hit: float = worth.call(strike)
	ok(plain > 0.0, "a disable is worth something (%s)" % plain)
	v(1).afflict(buff, 3, 1)
	var waiting: float = worth.call(brainfog)
	ok(waiting < plain and is_equal_approx(worth.call(strike), hit), "postponing: less of it, a blow the same (%s, %s)" % [waiting, plain])
	v(1).postponed[favour] = [2, true]
	ok(worth.call(brainfog) < waiting, "and less for what it already holds (%s)" % worth.call(brainfog))
	v(1).timed.erase(buff)
	ok(is_equal_approx(worth.call(brainfog), plain), "the postpone over: whole again")


func test_instant_death() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	wear(v(3), charm, 2, true)
	soak(v(3), 100)
	ok(v(3).lives_left() == 0, "on its last life")
	v(3).slay()
	ok(v(3).is_alive() and v(3).hp == 0 and v(3).deferred == v(3).rank(load("res://Skills/coyote_charm.tres")), "an instant death puts it on Borrowed Time at the Charm's rank (%d)" % v(3).deferred)
	wear(v(4), charm, 2)
	soak(v(4), 100)
	v(4).slay()
	ok(not v(4).is_alive(), "not enchanted: it dies")
	wear(v(2), charm, 2, true)
	soak(v(2), 100)
	v(2).damage(999)
	ok(not v(2).is_alive() or v(2).dbno != null, "a blow taking its HP isn't an instant death: the Charm doesn't step in")

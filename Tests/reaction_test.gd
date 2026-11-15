extends Test

# Reactions (docs/plans/reactions.md): the one seam (Battle.react()) - every switched-on passive whose
# behaviour reacts (Behaviour.react()) is asked about a moment (attacked, hit, fallen), in a fixed order
# (who brought it about, whom it happens to, then the rest by distance), each at most once, and only
# while its holder reacts() (not Jammed, not helpless). Skills that react carry the reaction tag. And the
# interrupt turn (Battle.grant_interrupt()): one unit acts out of turn, free of AP; the turn resumes.

var jam: Skill = load("res://Skills/jam.tres")


# A throwaway reaction: notes each moment it's asked about, reacting (true) or not.
class Echo:
	extends Behaviour
	var heard: Array = []
	var answer := true

	func react(r: Reaction, holder: Unit, _rank: int) -> bool:
		heard.append([r.trigger, holder, r.subject, r.by])
		return answer


func echo(u: Unit, e: Echo) -> Skill:
	var s := Skill.new()
	s.name = "Echo"
	s.passive = true
	s.tags = [&"reaction"] as Array[StringName]
	s.behaviours = [e] as Array[Behaviour]
	u.learned.append(slot(s))
	return s


# v(3) (Nemes) Jams v(1), sure to hit; v(2) beside v(1), v(4) further off.
func scene() -> void:
	v(3).learned.append(slot(jam))
	v(3).dexterity = 40
	stage(nemes, {v(1): Vector2i(4, 3), v(2): Vector2i(4, 4), v(3): Vector2i(5, 3), v(4): Vector2i(8, 3)})
	for i in [1, 2, 3, 4]:
		v(i).refresh()
		soak(v(i), 300)


func test_joins() -> void:
	scene()
	var e := Echo.new()
	e.answer = false
	echo(v(2), e)
	ok(b.cast(v(3), jam, v(1)), "Jam lands")
	ok(e.heard.size() == 2 and e.heard[0] == [&"attacked", v(2), v(1), v(3)] and e.heard[1] == [&"hit", v(2), v(1), v(3)],
			"a passive joins by implementing the hook: asked as v(1) is attacked, then hit (%s)" % [e.heard])
	var got := []
	b.reacted.connect(func(u: Unit, s: Skill, r: Behaviour.Reaction): got.append([u, s.name, r.trigger]))
	e.answer = true
	b.cast(v(3), jam, v(1))
	ok(got.size() == 2 and got[0] == [v(2), "Echo", &"attacked"], "reacting, it's told (reacted): %s" % [got])
	ok(b.times_reacted(v(2), v(2).learned.back().skill) == 2, "and counted for the battle")


func test_order() -> void:
	scene()
	var e := Echo.new()
	e.answer = false
	for i in [4, 2, 1, 3]:
		echo(v(i), e)
	b.react(&"attacked", v(1), v(3))
	ok(e.heard.map(func(h: Array): return h[1]) == [v(3), v(1), v(2), v(4)], "who brought it about, whom it happens to, then the nearest first: %s" % [e.heard.map(func(h: Array): return h[1].name)])


func test_once() -> void:
	scene()
	var e := Echo.new()
	var s := echo(v(2), e)
	var r := b.react(&"attacked", v(1), v(3))
	ok(e.heard.size() == 1 and r.done == [[v(2), s]], "asked once, and noted as done")
	ok(not b.react_with(r, v(2), v(2).on_passives.filter(func(x: Slot): return x.skill == s)[0]) and e.heard.size() == 1, "not again for the same moment")
	b.react(&"attacked", v(1), v(3))
	ok(e.heard.size() == 2, "a new moment asks again")


func test_gated() -> void:
	scene()
	var e := Echo.new()
	echo(v(2), e)
	v(2).afflict(load("res://Effects/jammed.tres"), 2)
	b.react(&"hit", v(1), v(3))
	ok(e.heard.is_empty() and not v(2).reacts(), "Jammed: no reactions")
	v(2).timed.clear()
	v(2).afflict(effect("helpless", 1.0), 2)
	b.react(&"hit", v(1), v(3))
	ok(e.heard.is_empty() and v(2).stopped(), "helpless: none either")
	v(2).timed.clear()
	b.react(&"hit", v(1), v(3))
	ok(e.heard.size() == 1, "free of both, it reacts")


func test_jam_takes_reactions() -> void:
	scene()
	var e := Echo.new()
	echo(v(1), e)
	b.cast(v(3), jam, v(1))
	var n := e.heard.size()
	ok(v(1).stat(&"jammed") > 0.0, "Jammed by the hit")
	b.cast(v(3), jam, v(1))
	ok(e.heard.size() == n, "then reacts to nothing: %d, %d" % [n, e.heard.size()])


func test_tagged() -> void:
	ok(&"reaction" in Glossary.TERMS and Tags.COLOR.has(&"reaction"), "a Glossary term with a colour")
	for id in ["interject", "gallantry", "final_act", "snapping_turtle"]:
		var s: Skill = load("res://Skills/%s.tres" % id)
		ok(&"reaction" in s.tags and s.stub == "" and not s.ai, "%s reacts, built, the user's name" % s.name)


func test_keyed() -> void:
	scene()
	v(2).afflict((load("res://Tests/interject_test.gd") as GDScript).keen(), 9)
	var interject: Skill = load("res://Skills/interject.tres")
	ok(v(2).check_mod(&"dexterity", &"defensive", v(2).skill_tags(interject)) == v(2).check_mod(&"dexterity", &"defensive") + 60,
			"an effect tagged reaction counts on a reaction's check, and on no other")


func test_interrupt() -> void:
	scene()
	b.directed = func(_u: Unit): return true  # a person's: nothing picks for it but the test
	v(1).learned.append(slot(jam))
	v(1).dexterity = 40
	v(1).refresh()
	var ap := v(1).ap_left()
	var seen := []
	b.interrupt_began.connect(func(u: Unit): seen.append([&"began", u]))
	b.interrupt_ended.connect(func(u: Unit): seen.append([&"ended", u]))
	b.grant_interrupt(v(1))
	ok(b.interrupter == v(1) and seen == [[&"began", v(1)]], "it opens at once, nothing being cast")
	ok(not b.cast(v(3), jam, v(1)), "the side whose turn it is waits")
	ok(b.travel(v(1), Vector2i(3, 3)).is_empty(), "an interrupt is a skill use: no walking")
	ok(b.cast(v(1), jam, v(3)), "the interrupter acts out of turn")
	ok(is_equal_approx(v(1).ap_left(), ap), "free: its own AP untouched (%s, %s)" % [ap, v(1).ap_left()])
	ok(b.interrupter == null and seen.back() == [&"ended", v(1)], "one action, and it's over")
	ok(b.turn == nemes and b.cast(v(3), jam, v(1)), "the interrupted turn resumes")
	ok(not b.cast(v(1), jam, v(3)), "and the interrupter is out of turn again")


func test_interrupt_queued() -> void:
	scene()
	b.directed = func(_u: Unit): return true  # a person's: nothing picks for it but the test
	b.grant_interrupt(v(1))
	b.grant_interrupt(v(2))
	ok(b.interrupter == v(1), "the first granted goes first")
	b.end_interrupt()
	ok(b.interrupter == v(2), "passing, the next opens")
	b.end_turn()
	ok(b.interrupter == null and b.turn == lancin, "a turn ending passes what's still open")


func test_ai_interrupt() -> void:
	scene()
	b.directed = func(_u: Unit): return true  # a person's: nothing picks for it but the test
	v(1).learned.append(slot(jam))
	v(1).dexterity = 40
	b.grant_interrupt(v(1))
	var log := AI.interrupt(b, v(1))
	ok(v(3).hp < 300 and b.interrupter == null, "the AI picks a blow at a foe in reach: %s" % [log])
	stage(nemes, {v(1): Vector2i(1, 1), v(3): Vector2i(8, 8)})
	b.grant_interrupt(v(1))
	log = AI.interrupt(b, v(1))
	ok(b.interrupter == null and "passes" in log.back(), "nothing to do, it passes: %s" % [log])


# Left undirected, Battle asks the AI itself as the interrupt opens (item 2 of docs/plans/gaps-react-marks.md):
# a headless simulation and the real game alike. The directed one (the player's) waits for its person.
func test_ai_interrupts() -> void:
	scene()
	v(1).learned.append(slot(jam))
	v(1).dexterity = 40
	var seen := []
	b.interrupt_ended.connect(func(u: Unit): seen.append(u))
	b.grant_interrupt(v(1))
	ok(v(3).hp < 300 and b.interrupter == null and seen == [v(1)], "no one directs it: the AI strikes and the interrupt is over")
	b.directed = func(u: Unit): return u == v(1)
	b.grant_interrupt(v(1))
	ok(b.interrupter == v(1), "directed: it waits for its person")
	b.end_interrupt()
	b.grant_interrupt(v(2))
	ok(b.interrupter == null and seen.back() == v(2), "while another's still the AI's: %s" % [seen])

# Area blows go through the same moments (item 1 of docs/plans/gaps-react-marks.md): Solar's cone asks
# `attacked` then `hit` for a foe in it, not for an ally, nor the caster; a dodged Wildfire is attacked, not hit;
# flames and traps, which have no cast to swap, ask `hit`.
func test_area_moments() -> void:
	var solar: Skill = load("res://Skills/solar.tres").duplicate(true)
	solar.ap = 1.0
	solar.cost = 0
	var wild: Skill = load("res://Skills/wildfire.tres").duplicate(true)
	wild.ap = 1.0
	wild.cost = 0
	stage(nemes, {v(3): Vector2i(1, 3), v(1): Vector2i(3, 3), v(2): Vector2i(3, 4), v(4): Vector2i(2, 3)})  # v(4) an ally, in the cone's way
	v(3).learned.append(slot(solar))
	v(3).learned.append(slot(wild))
	v(3).wisdom = 40  # Solar's reach is its wis mod
	v(3).refresh()
	for i in [1, 2, 3, 4]:
		soak(v(i), 300)
	var e := Echo.new()
	e.answer = false
	echo(v(2), e)  # beside v(1), a foe
	v(4).faction = nemes
	ok(b.cast_at(v(3), solar, Vector2i(3, 3)), "Solar cast on a tile")
	var moments := e.heard.map(func(h: Array): return [h[0], h[2]])
	ok([&"attacked", v(1)] in moments and [&"hit", v(1)] in moments, "a foe in the cone is attacked, then hit (%s)" % [moments])
	ok(not moments.any(func(m: Array): return m[1] in [v(3), v(4)]), "not the caster, nor its ally")
	e.heard.clear()
	v(1).dexterity = 90  # mod 40: dodges
	ok(b.cast_at(v(3), wild, Vector2i(3, 3)), "Wildfire cast")
	moments = e.heard.map(func(h: Array): return [h[0], h[2]])
	ok([&"attacked", v(1)] in moments and [&"hit", v(1)] not in moments, "dodged: attacked, and not hit (%s)" % [moments])
	e.heard.clear()
	b.flame(v(1), Battle.Flame.new(v(3), 1), "test")
	ok(e.heard.size() == 1 and e.heard[0][0] == &"hit" and e.heard[0][3] == v(3), "a flame's damage is a hit, no cast: %s" % [e.heard])


# Interject takes an area blow in the ally's place, as it does a single one.
func test_area_interject() -> void:
	var solar: Skill = load("res://Skills/solar.tres").duplicate(true)
	solar.ap = 1.0
	solar.cost = 0
	var interject: Skill = load("res://Skills/interject.tres")
	stage(nemes, {v(3): Vector2i(1, 3), v(1): Vector2i(3, 3), v(2): Vector2i(3, 4), v(4): Vector2i(8, 8)})
	v(3).learned.append(slot(solar))
	v(3).refresh()
	v(2).learned.append(slot(interject, 5))
	v(2).dexterity = 90
	v(2).refresh()
	for i in [1, 2, 3, 4]:
		soak(v(i), 300)
	v(3).wisdom = 40
	var got := []
	b.reacted.connect(func(u: Unit, s: Skill, _r): got.append([u, s]))
	b.cast_at(v(3), solar, Vector2i(3, 3))
	ok([v(2), interject] in got, "Interject answers an area hit on the ally beside it (%s)" % [got.size()])

extends Test

# The Restless Dead ?? (Unit.restless(): undead + Disturbed; Scripts/Undead.gd, AI._restless(), Read.dead_eye /
# restless): it goes for the nearest living unit it sees, its own side first on ties, leaving the dead be; allies that
# see it act and pass a medium-easy wisdom check take it for a foe; it acts after its side's cognizant
# (Command.cognizant_first()); losing Disturbed (taken off, run out) lays it to rest. And Summon's soft cap
# (Behaviours/summon_per_rank.gd): past rank + stat mod in hand, the furthest raised go Disturbed for good.

var skeleton: Skill = load("res://Skills/skeleton.tres")
var bones: PackedScene = load("res://Scenes/skeleton.tscn")
const Undead := preload("res://Scripts/Undead.gd")


func raise(f: Faction, c: Vector2i) -> Unit:
	var s := b.summon(bones, f, c)
	sharp(s)
	return s


func restless(u: Unit, turns := 99) -> Unit:
	u.afflict(effect("disturbed", 1), turns)
	return u


# A Lancin skeleton at (5, 3), v(1) (its ally) and v(3) (a Nemes foe) 2 tiles either side, another skeleton beside it.
func ring() -> Array[Unit]:
	stage(lancin, {v(1): Vector2i(3, 3), v(3): Vector2i(7, 3), v(2): Vector2i(5, 9), v(4): Vector2i(12, 9)})
	var s := raise(lancin, Vector2i(5, 3))
	var t := raise(lancin, Vector2i(5, 4))
	return [s, t]


func test_targets() -> void:
	var st := ring()
	var s := st[0]
	ok(b.read(s, v(1)).attitude(s) == &"ally" and AI._prey(s, AI._reads(b, s)) != v(1), "in hand: its side is its side")
	restless(s)
	var reads := AI._reads(b, s)
	ok(s.restless() and reads[v(1)].attitude(s) == &"foe" and reads[v(3)].attitude(s) == &"foe" and reads[st[1]].attitude(s) == &"ally",
			"Restless: the living are foes, the dead are not")
	ok(AI._prey(s, reads) == v(1), "a tie (2 tiles each): its own side's first")
	b.move(v(1), Vector2i(2, 3))
	ok(AI._prey(s, AI._reads(b, s)) == v(3), "otherwise the nearest")
	b.move(v(3), Vector2i(6, 3))
	soak(v(3))
	var was := v(3).hp
	AI.act(b, s)
	ok(v(3).hp < was, "it strikes it, Disturbed by any source")
	var it := restless(v(2))
	ok(not it.restless(), "a Disturbed living unit isn't Restless Dead")


func test_noticing() -> void:
	var s := ring()[0]
	v(1).wisdom = 50  # a d20 + 20 always passes DC 8
	v(2).wisdom = -30  # never does
	b.move(v(2), Vector2i(5, 1))
	restless(s)
	b.move(v(3), Vector2i(6, 3))
	s.refresh()
	ok(b.cast(s, strike, v(3)), "it acts in view")
	ok(b.read(v(1), s).attitude(v(1)) == &"foe" and b.read(v(2), s).attitude(v(2)) == &"ally", "the ally who passed takes it for a foe; the one who failed doesn't")
	ok(not b.teammates(v(1), s), "nor for a teammate")
	ok(Difficulty.dc(Undead.NOTICE) == Difficulty.dc(&"moderate low"), "medium easy: approachable")
	var calm_ally := v(1)
	ok(Command.cognizant_first([s, calm_ally, v(2)] as Array[Unit]) == ([calm_ally, v(2), s] as Array[Unit]), "a side acts with its Disturbed last")


func test_laid_to_rest() -> void:
	var st := ring()
	restless(st[0])
	restless(st[1], 1)
	restless(v(1))
	Undead.settle(b)
	ok(st[0] in b.restless and st[1] in b.restless and v(1) not in b.restless, "the Restless Dead are kept")
	st[0].timed.clear()
	v(1).timed.clear()
	Undead.settle(b)
	ok(not st[0].is_alive() and v(1).is_alive(), "Disturbed taken off: the dead lie down; the living just come round")
	b.end_turn()
	ok(not st[1].is_alive(), "and when it runs out")


func test_soft_cap() -> void:
	var c := v(1)
	c.learned.append(slot(skeleton, 2))
	roomy(c)
	c.intelligence = 10  # mod 0: cap 2
	c.ap[0].amount = 99.0
	stage(lancin, {c: Vector2i(4, 3), v(3): Vector2i(14, 3)})
	ok(b.cast_at(c, skeleton, Vector2i(7, 3)), "rank II raises four")
	var raised := b.units.values().filter(func(u: Unit): return u.raised_by == c)
	var gone := raised.filter(func(u: Unit): return u.disturbed())
	var kept := raised.filter(func(u: Unit): return not u.disturbed())
	ok(raised.size() == 4 and gone.size() == 2, "past the cap (2 + 0), two go Disturbed (%d of %d)" % [gone.size(), raised.size()])
	var far := func(u: Unit) -> float: return Vector2(c.cell).distance_to(Vector2(u.cell))
	ok(gone.all(func(g: Unit): return kept.all(func(k: Unit): return far.call(g) >= far.call(k))), "the furthest first")
	ok(gone.all(func(g: Unit): return g.timed.values().any(func(a: Unit.Applied): return a.lasting)) and gone.all(func(g: Unit): return g.restless()), "for good: Restless Dead")
	var bh: Behaviour = skeleton.behaviours[0]
	ok(bh.bodies(b.cast_of(c, skeleton, null, 2, true)) == 0, "the AI sees no bodies left to keep")
	kept[0].hp = 0
	ok(bh.bodies(b.cast_of(c, skeleton, null, 2, true)) == 1, "one falls: room for one")
	ok(skeleton.describe(2).contains("in hand"), "it says so: %s" % skeleton.describe(2))

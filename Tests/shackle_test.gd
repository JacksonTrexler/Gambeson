extends Test

# Judgement and its Shackles (Battle._bind(), Battle.unshackle(), AI._unshackle()): on a hit, shackles
# of the rank's weight take the place of the target's trinket, locked while Shackled lasts; locked, they
# can be picked (approachable, dex) or pried apart (unfair, str), each try their rank in AP; unlocked,
# they come off for their rank in AP. Difficulty checks scale by rank (Difficulty).

var judgement: Skill = load("res://Skills/judgement.tres")
var ring: Item = load("res://Items/quartz_ring.tres")


func icor() -> Unit:
	return b.get_node("Units/Icor")


# v(1) judges Icor at rank r, sure to hit.
func judge(r: int) -> void:
	stage(lancin, {v(1): Vector2i(3, 3), icor(): Vector2i(4, 3)})
	v(1).wisdom = 90  # sure to hit - and to hit hard, so Icor gets the HP to take it
	icor().max_hp = 999
	icor().hp = 999
	v(1).learned.append(slot(judgement, r))
	v(1).refresh()
	v(1).energy = v(1).max_energy
	icor().trinket = ring
	ok(b.cast(v(1), judgement, icor()), "Judgement at rank %d" % r)


# Icor's own turn, where it stands.
func icors_turn() -> void:
	stage(nemes, {v(1): Vector2i(3, 3), icor(): Vector2i(4, 3)})
	icor().refresh()


func test_judgement() -> void:
	icor().trinket = ring
	var before := icor().weight()
	judge(2)
	var it := icor().trinket
	ok(it.name == "Shackles" and it.rank == 2 and it.heft() == 2 and icor().stowed == ring, "shackles of weight 2 in place of its ring, the ring kept")
	ok(icor().weight() == before + 2 and icor().shackled(), "heavier by 2, and locked")
	ok(not b.equip(icor(), ring) and b.unequip(icor(), "trinket") == null, "they can't be swapped out or simply taken off")
	ok("On a hit: Shackles, weight 1, take the place of its trinket" in judgement.describe(1), judgement.describe(1))
	ok("lockpicked (Approachable, DC 5) or pried apart (Unfair, DC 9)" in judgement.describe(1), judgement.describe(1))


func test_pick() -> void:
	judge(2)
	icors_turn()
	ok(not b.unshackle(icor(), &"unlock"), "locked: they won't simply come off")
	icor().dexterity = 90
	var ap := icor().ap_left()
	ok(b.unshackle(icor(), &"pick") and icor().trinket == ring and not icor().shackled() and is_equal_approx(icor().ap_left(), ap - 2),
			"a deft hand picks the lock (approachable): its ring back on, 2 AP spent")


func test_pry() -> void:
	judge(4)
	icors_turn()
	icor().strength = 1
	var ap := icor().ap_left()
	ok(not b.unshackle(icor(), &"pry") and icor().trinket.name == "Shackles" and is_equal_approx(icor().ap_left(), ap - 4),
			"rank IV shackles pried at unfair (DC 21): a weakling can't, and the try still costs 4 AP")


func test_unlocked() -> void:
	judge(1)
	icors_turn()
	for e in icor().timed.keys().filter(func(x: Effect): return x.stat == "shackled"):
		icor().timed.erase(e)  # cleansed, or run out
	ok(b.unshackle(icor(), &"unlock") and icor().trinket == ring, "unlocked: off for 1 AP")


func test_ai_works_free() -> void:
	judge(1)
	icors_turn()
	icor().dexterity = 90
	AI.act(b, icor())
	ok(icor().trinket == ring, "an AI unit spends its turn's first AP getting its shackles off")

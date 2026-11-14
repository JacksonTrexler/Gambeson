extends Test

# Burnout (docs/plans/recovery.md; Scripts/Burnout.gd): every recovery but regen goes through
# Unit.recovered. Energy grants always spend 1 Recovery Endurance (RE: max(con mod, 0) as a battle
# starts); with RE 0 or below, a recovery asks a con check (DC 12) and failing cuts that pool's max by
# 10% x (1 + |RE|) of it, for good; one heal past con mod x 20% of max HP asks a con check against the
# excess (-1 RE failing). RE refills on a resting turn at full.

var mana: Reserve = load("res://Reserves/mana.tres")


# u with con c (its mod: (c - 10) / 2), RE fresh.
func con(u: Unit, c: int) -> Unit:
	u.constitution = c
	u.endurance = u.endurance_max()
	return u


func test_start() -> void:
	stage(lancin, {v(1): Vector2i(3, 3)})
	ok(con(v(1), 14).endurance == 2, "con 14: RE 2")
	ok(con(v(1), 6).endurance == 0, "negative con mod: RE 0, not below")


func test_energy_spends() -> void:
	stage(lancin, {v(1): Vector2i(3, 3)})
	var u := con(v(1), 40)  # con mod 15: passes every check
	u.max_energy = 20
	u.energy = 0
	u.endurance = 1
	u.grant_energy(3)
	ok(u.endurance == 0 and u.max_energy == 20, "a grant spends 1 RE")
	u.grant_energy(3)
	ok(u.endurance == -1 and u.max_energy == 20, "at 0: a passed check, but reenergizing still spends RE")
	u.energy = u.max_energy
	u.grant_energy(3)
	ok(u.endurance == -1, "a grant that gives nothing (bar full) spends nothing")
	u.recover()  # its turn: nothing paid, nothing moved - a resting turn
	ok(u.activity() == &"rest" and u.endurance == u.endurance_max(), "a resting turn at full refills RE")


func test_burns() -> void:
	stage(lancin, {v(1): Vector2i(3, 3)})
	var u := con(v(1), -20)  # con mod -15: fails every check
	u.max_energy = 20
	u.energy = 0
	u.endurance = 0
	u.grant_energy(10)
	ok(u.max_energy == 19 and u.endurance == -1, "RE 0, failed: max Energy -10% x (1 + 0) x 10 = 1; RE -1")
	u.energy = 0
	u.grant_energy(10)
	ok(u.max_energy == 17 and u.endurance == -2, "RE -1: -10% x 2 x 10 = 2")
	u.max_hp = 40
	u.hp = 10
	var before := u.max_hp
	u.heal(10)
	ok(u.burnt.get(&"hp", 0) == 3 and u.max_hp == before - 3 and u.endurance == -4,
			"a heal while depleted: max HP -10% x 3 x 10 = 3, RE -1; and past con mod x 20% (0): -1 more")
	u.refit()
	ok(u.max_hp == before - 3, "the loss lasts through refit()")
	u.set_store(mana, 0)
	u.note_recovery(mana, 4)
	ok(u.burnt.get(mana, 0) == 2 and u.endurance == -5, "a reserve counts as Energy: 10% x 5 x 4 = 2, and 1 RE")


func test_big_heal() -> void:
	stage(lancin, {v(1): Vector2i(3, 3)})
	var u := con(v(1), 14)  # con mod 2: 40% of max HP in one heal is fine
	u.max_hp = 50
	u.hp = 1
	u.endurance = 2
	u.constitution = -20  # now it fails, RE kept
	u.heal(20)
	ok(u.endurance == 1, "a heal past con mod x 20% of max HP: a failed check against the excess costs 1 RE")
	u.constitution = 14
	u.endurance = 2
	u.heal(5)
	ok(u.endurance == 2, "under the threshold (2 x 20% x 50 = 20): no check, no RE")



func test_card() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	var u := con(v(1), 14)
	var info: Dictionary = h._info(u)
	ok(info.rows.any(func(r): return r[0] == "RE" and r[1] == "2/2"), "the card shows RE 2/2")
	u.max_hp = 30
	u.burn(&"hp", 3)
	info = h._info(u)
	ok(info.chips.any(func(c): return c[0] == "Burnt -3 HP") and u.max_hp == 27, "and what Burnout took: Burnt -3 HP, max 27")
	h.free()

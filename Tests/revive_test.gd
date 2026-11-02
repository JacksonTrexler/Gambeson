extends Test

# The Red Spinel Ring (a life once a battle: up at rank x 10% of max HP, more than full past rank 10,
# with Resurrection Sickness), the player's side playing itself while the player is down
# (HUD.autopilot()), and Synergy (Battle.synergized(), Battle.read(), Battle._synergize()).

var ring: Item = load("res://Items/red_spinel_ring.tres")
var synergy: Skill = load("res://Skills/synergy.tres")
var hide: Skill = load("res://Skills/hide.tres")


func test_ring() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	v(1).equip(ring)
	ok(v(1).lives() == 1 and v(1).lives_left() == 1, "a life while worn")
	v(1).hp = 0
	ok(v(1).reviving and v(1) in b.fallen, "falling: down, not dead")
	b.end_turn()
	ok(v(1).is_alive() and v(1).hp == roundi(v(1).max_hp * 0.1), "up at 10%% of max HP (%d)" % v(1).hp)
	ok(Battle.SICKNESS in v(1).timed and v(1).timed[Battle.SICKNESS].turns >= 1, "with Resurrection Sickness")
	ok(v(1).lives_left() == 0, "once a battle")
	v(1).hp = v(1).max_hp
	b._mend(v(1))
	ok(Battle.SICKNESS not in v(1).timed, "a turn starting at full HP cures it")
	v(1).afflict(Battle.SICKNESS, 3)
	v(1).hp = 50 if v(1).max_hp > 50 else v(1).max_hp - 1
	var was := v(1).hp
	b._mend(v(1))
	ok(v(1).hp == maxi(was - maxi(roundi(0.1 * v(1).max_hp), 1), 1), "hurt: 10% of max HP as its turn starts")


func test_ring_overheal() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2)})
	var big: Item = ring.duplicate()
	big.rank = 12
	v(1).equip(big)
	v(1).hp = 0
	b.end_turn()
	ok(v(1).hp == roundi(v(1).max_hp * 1.2) and v(1).hp > v(1).max_hp, "rank XII: 120%%, more than full (%d / %d)" % [v(1).hp, v(1).max_hp])
	v(1).damage(v(1).hp - v(1).max_hp + 1)
	v(1).heal(10)
	ok(v(1).hp == v(1).max_hp, "once below full, it heals no further than full")


func test_autopilot() -> void:
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(1, 5), v(3): Vector2i(8, 2)})
	b.player = v(1)
	var h: HUD = load("res://Scenes/UI/hud.tscn").instantiate()
	h.battle = b
	h.auto = false
	h.pace = 0.0
	tree.root.add_child(h)
	await tree.process_frame
	ok(not h.autopilot() and h.my_turn(), "standing: the player plays")
	v(1).hearts = 1
	v(1).hp = 0
	ok(h.autopilot() and not h.my_turn(), "down: its side plays itself")
	h.free()


func test_synergy() -> void:
	ok(synergy in v(1).sources()[&"class"] and synergy in load("res://Races/human.tres").options, "any class can learn it; so can humans")
	ok(v(1).tier(synergy) == 2 and &"specialist" in synergy.tags, "a tier 2 specialist skill")
	stage(lancin, {v(1): Vector2i(1, 2), v(2): Vector2i(2, 2), v(3): Vector2i(8, 2)})
	v(2).follows = v(1)
	ok(b.synergized(v(1)).is_empty(), "no Synergy: nothing shared")
	v(2).learned.append(slot(synergy))
	ok(Array(b.synergized(v(1))) == [v(2)] and Array(b.synergized(v(2))) == [v(1)], "a member with it: it and its leader share")
	v(1).wisdom = 1
	v(2).wisdom = 40
	ok(b.read(v(1), v(3)).net >= b._read(v(2), v(3)).net, "the leader makes out what its member does")


func test_synergy_investigates() -> void:
	stage(nemes, {v(3): Vector2i(5, 2), v(1): Vector2i(1, 2), v(2): Vector2i(2, 2)})
	v(3).learned.append(slot(hide))
	v(3).refresh()
	b.rng.seed = 2
	b.cast(v(3), hide, v(3))
	var a: Unit.Applied = null
	for e in v(3).timed:
		if v(3).timed[e].skill == hide:
			a = v(3).timed[e]
	ok(a != null, "hidden")
	a.known_to.erase(v(1))
	if v(2) not in a.known_to:
		a.known_to.append(v(2))
	v(2).follows = v(1)
	v(2).learned.append(slot(synergy))
	var looks := []
	b.investigated.connect(func(by: Unit, _of: Unit, _s: Skill, _t: int, _a: int, _c: bool): looks.append(by))
	b._synergize(v(1))
	ok(looks == [v(1)] and v(1).noticed.has(v(3)), "its member saw through: the leader gets its own first look")
	b._synergize(v(1))
	ok(looks.size() == 1, "once")

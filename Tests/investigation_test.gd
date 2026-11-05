extends Test

# Wisdom checks against concealment and trickery, the suspicion they earn, warnings, bumping,
# Opportunist, Ambush / Coordinate, Sing, and the Siren's ambush. Trap at (5,4).

const TRAP := Vector2i(5, 4)
var opportunist: Skill = load("res://Skills/opportunist.tres")
var ambush: Skill = load("res://Skills/ambush.tres")
var coordinate: Skill = load("res://Skills/coordinate.tres")
var sing: Skill = load("res://Skills/sing.tres")
var stonegift: Skill = load("res://Skills/stonegift.tres")


func siren() -> Unit:
	return b.get_node("Units/Siren")


func alabaster() -> Unit:
	return b.get_node("Units/Alabaster")


func sharp(u: Unit) -> void:
	u.wisdom = 40  # mod +15: never misses a DC up to 16


func dull(u: Unit) -> void:
	u.wisdom = -20  # mod -15: never makes one


func test_dcs() -> void:
	stage(lancin, {v(1): Vector2i(4, 4), siren(): Vector2i(8, 6), v(3): Vector2i(0, 7)})
	ok(Investigation.dc(b, v(1), TRAP) == 14, "trap at net -2: 10 + 2 x 2")
	ok(Investigation.dc(b, v(1), siren()) == 11, "the Siren fooling it at net 0: 10 + 0 + dex mod 1")
	v(3).afflict(effect("concealment", 2, [&"dark"]), 9)
	ok(Investigation.dc(b, v(1), v(3)) == 13, "a dex-12 unit hidden 2 deep: 10 + 2 + 1")


func test_contact_check() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(9, 0)})
	sharp(v(1))
	v(1).afflict(effect("investigation", -14), 9)  # range back to 1: the trap only comes into range on arrival
	b.travel(v(1), Vector2i(4, 4))
	ok(v(1).suspicion_at(TRAP) >= 1 and b.read(v(1), TRAP).known_bad(), "moving up to the trap: a check, passed, and it knows the trap")
	ok(v(1).suspicion[0].center == TRAP and v(1).suspicion[0].levels == 14, "wis mod 15 - distance 1 = 14 levels, for that area")
	ok(v(1).suspicion_at(Vector2i(0, 0)) == 0, "only for that area")


func test_min_one_level() -> void:
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(9, 0)})
	var passes := 0
	for seed in 40:
		b.rng.seed = seed
		v(1).suspicion.clear()
		if Investigation.run(b, v(1)):
			passes += 1
			ok(v(1).suspicion[0].levels == 1, "wis mod 1 - distance 1 = 0 -> at least 1")
	ok(passes > 5 and passes < 30, "a villager passes DC 14 about 40%% of the time (%d/40)" % passes)


func test_contact_is_once() -> void:
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(9, 0)})
	sharp(v(1))
	b.travel(v(1), Vector2i(4, 5))
	b.travel(v(1), Vector2i(4, 4))
	ok(v(1).suspicion.is_empty(), "shuffling about near what it already had in range earns nothing")


func test_out_of_range() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(9, 0)})
	ok(Investigation.lead(b, v(1)) == null and not Investigation.run(b, v(1)), "nothing obscured within its range (wis mod 1): no check")
	v(1).afflict(effect("investigation", 3), 9)
	ok(Investigation.lead(b, v(1)) == TRAP, "investigation effects widen it")


func test_warning() -> void:
	stage(lancin, {v(1): Vector2i(4, 4), v(2): Vector2i(3, 3), alabaster(): Vector2i(0, 7), v(3): Vector2i(9, 0)})
	sharp(v(1))
	v(1).charisma = 14  # mod +2
	Investigation.run(b, v(1))
	ok(v(2).suspicion_at(TRAP) == 1 and alabaster().suspicion_at(TRAP) == 0, "cha mod 2: one level to allies within 2 tiles")
	v(1).charisma = 8
	v(2).suspicion.clear()
	v(1).suspicion.clear()
	Investigation.run(b, v(1))
	ok(v(2).suspicion.is_empty(), "no warning without a positive cha mod")


func test_idle_check() -> void:
	stage(lancin, {v(1): Vector2i(4, 4), v(2): Vector2i(0, 0), v(3): Vector2i(9, 0)})
	sharp(v(1))
	sharp(v(2))
	b.travel(v(2), Vector2i(0, 1))
	v(2).suspicion.clear()
	b.end_turn()
	ok(not v(1).suspicion.is_empty(), "held still: it looks around at the end of its turn")
	ok(v(2).suspicion.is_empty(), "a unit that acted doesn't")


func test_attacked_from_hiding() -> void:
	stage(nemes, {v(3): Vector2i(5, 3), v(1): Vector2i(4, 3)})
	v(3).afflict(effect("concealment", 2, [&"dark"]), 9)
	sharp(v(1))
	ok(b.read(v(1), v(3)).net == -2, "Lancin can't make out its attacker")
	b.cast(v(3), strike, v(1))
	ok(v(3).exposed == 1 and v(1).provoked, "the attack costs it a level of concealment")
	ok(not v(1).suspicion.is_empty() and b.read(v(1), v(3)).faction == nemes, "and the target's free check identifies it")


func test_bumping() -> void:
	stage(lancin, {v(1): Vector2i(1, 3), v(3): Vector2i(3, 3)})
	v(3).afflict(effect("concealment", 4), 9)
	ok(not b.read(v(1), v(3)).located(), "an undetectable Nemes unit")
	var p := b.travel(v(1), Vector2i(5, 3))
	ok(p == cells([Vector2i(2, 3)]) and v(3).exposed == 2, "runs into it: stops short, and it loses two levels")
	stage(lancin, {v(1): Vector2i(1, 3), v(2): Vector2i(2, 3), v(3): Vector2i(8, 7)})
	ok(b.travel(v(1), Vector2i(4, 3)).back() == Vector2i(4, 3), "allies can still be passed")


func test_trap_exposure() -> void:
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(9, 0)})
	b.travel(v(1), TRAP)
	ok(b.exposed[TRAP] == 2 and not b.hidden(TRAP), "a sprung trap loses two levels (all of this one's)")


func test_opportunist() -> void:
	v(3).learned.append(slot(opportunist))
	stage(lancin, {v(1): Vector2i(1, 3), v(3): Vector2i(3, 3)})
	var ap := v(3).ap_for(&"skill")
	b.travel(v(1), Vector2i(5, 3))
	ok(v(1).hp == 9 and v(3).ap_for(&"skill") == ap, "running into it: it Strikes for free (1 + 1 - Favour's rounding)")


func test_ambush() -> void:
	v(3).learned.append(slot(ambush, 2))
	stage(nemes, {v(3): Vector2i(4, 2), v(1): Vector2i(1, 3)})  # beside the path, not on it
	ok(not b.set_watch(v(3), ambush, strike, cells([Vector2i(4, 3), Vector2i(5, 2), Vector2i(3, 2)])), "rank 2: two tiles at most")
	ok(not b.set_watch(v(3), ambush, strike, cells([Vector2i(2, 3)])), "only within Strike's range")
	ok(not b.set_watch(v(3), ambush, wary, cells([Vector2i(4, 3)])), "must be an offensive skill")
	ok(b.set_watch(v(3), ambush, strike, cells([Vector2i(4, 3), Vector2i(5, 2)])), "set")
	b.end_turn()
	var p := b.travel(v(1), Vector2i(7, 3))
	ok(p.back() == Vector2i(4, 3) and v(1).hp == 9, "walks in: struck, and stopped there")
	ok(b.watches[0].cells == cells([Vector2i(5, 2)]), "that tile's used up")
	b.end_turn()
	ok(b.watches.is_empty(), "gone once Nemes' turn comes round")


func test_ambush_spares_beloved() -> void:
	v(1).learned.append(slot(ambush, 1))
	stage(lancin, {v(1): Vector2i(6, 5), siren(): Vector2i(8, 6)})
	b.set_watch(v(1), ambush, strike, cells([Vector2i(7, 5)]))
	b.end_turn()
	siren().provoked = true
	b.travel(siren(), Vector2i(7, 5))
	ok(siren().hp == 16, "the 'harmless ally' walks right past a fooled ambusher")
	stage(lancin, {v(1): Vector2i(6, 5), siren(): Vector2i(8, 6)})
	b.set_watch(v(1), ambush, strike, cells([Vector2i(7, 5)]), true)
	b.end_turn()
	b.travel(siren(), Vector2i(7, 5))
	ok(siren().hp < 16, "set to fire on anyone, it doesn't")


func test_coordinate() -> void:
	alabaster().learned.append(slot(coordinate, 1))
	stage(lancin, {alabaster(): Vector2i(2, 4), v(1): Vector2i(5, 4), v(3): Vector2i(9, 0)})
	ok(b.set_watch(alabaster(), coordinate, stonegift, cells([Vector2i(3, 4)])), "Coordinate with Stonegift")
	ok(not b.set_watch(alabaster(), coordinate, strike, cells([Vector2i(3, 3)])), "must be a support skill")
	b.travel(v(1), Vector2i(3, 4))
	ok(v(1).timed.has(stonegift.grants.effects[0]), "an ally stepping in gets Stoneskin")


func test_sing() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 6)})
	v(1).suspect(siren().cell, 4)  # seen through (4 > trickery 2)
	ok(is_equal_approx(b.skill_range(siren(), sing, v(1)), 4.21), "range: cha mod 4 + 0.15 + 0.06")
	dull(v(1))
	ok(b.cast(siren(), sing, v(1)) and v(1).suspicion_at(siren().cell) == 3, "fails its wis check: loses a level of what it knew")
	ok(not b.cast(siren(), sing, v(1)), "her movement's spent: no second song this turn")
	siren().moved = 0
	sharp(v(1))
	b.cast(siren(), sing, v(1))
	ok(v(1).suspicion_at(siren().cell) == 3, "passes: keeps it")
	ok(siren().energy == 6, "2 energy a song")


func test_siren_boasts() -> void:
	var r := b.read(v(1), siren())
	ok(r.deceived and r.boon == "Something extremely beneficial", "the fooled hear of something extremely beneficial")
	ok(b.read(v(3), siren()).boon == "", "its own side doesn't")


func test_siren_ambusher() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 6), v(2): Vector2i(0, 0)})
	AI.act(b, siren())
	ok(siren().cell == Vector2i(8, 6) and v(1).hp == 10, "unprovoked: it stays put and doesn't attack")
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(7, 5), v(2): Vector2i(0, 0)})
	siren().strength = 40  # the grab always lands
	v(1).max_hp = 100
	v(1).heal(100)
	AI.act(b, siren())
	ok(v(1).hp < 100, "but whoever ends up beside it gets raked or drowned")
	ok(siren().cell == Vector2i(8, 6) or &"water" in siren().ground, "still not walking anywhere (a drown may take it into the water)")
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 6), v(2): Vector2i(0, 0)})
	siren().provoked = true
	v(1).heal(100)
	AI.act(b, siren())
	ok(siren().cell != Vector2i(8, 6) or v(1).hp < 100, "once hit by a hostile skill, it goes after them")


func test_checks_see_through_the_siren() -> void:
	stage(lancin, {v(1): Vector2i(7, 6), siren(): Vector2i(8, 6)})
	sharp(v(1))
	for i in 2:
		Investigation.run(b, v(1), siren())
	var r := b.read(v(1), siren())
	ok(not r.deceived and r.faction == nemes, "enough suspicion outweighs its trickery: the truth")


func test_watch_moved_caster() -> void:
	v(3).learned.append(slot(ambush, 1))
	stage(nemes, {v(3): Vector2i(4, 2), v(1): Vector2i(1, 3)})
	b.set_watch(v(3), ambush, strike, cells([Vector2i(4, 3)]))
	b.travel(v(3), Vector2i(7, 1))
	b.end_turn()
	var p := b.travel(v(1), Vector2i(6, 3))
	ok(p.back() == Vector2i(6, 3) and v(1).hp == 10, "the ambusher walked off: the tile no longer pins anyone")


func test_watch_on_trap() -> void:
	v(3).learned.append(slot(ambush, 1))
	stage(nemes, {v(3): Vector2i(5, 3), v(1): Vector2i(3, 4)})
	b.set_watch(v(3), ambush, strike, cells([TRAP]))
	b.end_turn()
	var trap: Terrain = load("res://Terrain/trap.tres")
	trap.dice = Vector2i(1, 1)
	b.travel(v(1), Vector2i(7, 4))
	trap.dice = Vector2i(1, 6)
	ok(b.watches.is_empty() or b.watches[0].cells.is_empty(), "an ambushed trap tile still fires the ambush")
	ok(v(1).hp == 9, "trap 1 x 0.99 -> 0, Strike 1.98 -> 1")


func test_support_watch_passing() -> void:
	alabaster().learned.append(slot(coordinate, 1))
	stage(lancin, {alabaster(): Vector2i(2, 4), v(1): Vector2i(3, 2), v(3): Vector2i(9, 0)})
	b.set_watch(alabaster(), coordinate, stonegift, cells([Vector2i(3, 3)]))
	b.travel(v(1), Vector2i(3, 6))
	ok(v(1).timed.has(stonegift.grants.effects[0]), "an ally walking on through still gets the support")


func test_exposure_only_when_hidden() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(7, 6)})
	siren().provoked = true
	b.cast(siren(), strike, v(1))
	ok(siren().exposed == 0, "a deceiver that wasn't concealed loses nothing by attacking")
	stage(lancin, {v(1): Vector2i(1, 3), v(3): Vector2i(3, 3)})
	v(3).afflict(effect("concealment", 2), 9)
	b.travel(v(1), Vector2i(5, 3))
	ok(v(3).exposed == 2, "bumping a partly hidden unit (net -2) exposes it too")
	ok(b.read(v(1), v(3)).net == 0 and b.read(v(1), v(3)).seen, "exposure peels its concealment, so it's seen")


func test_sing_only_when_seen_through() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(5, 6)})
	v(1).suspect(siren().cell, 3)
	siren().moved = 2  # no movement to pay for a song
	AI.act(b, siren())
	ok(siren().energy == 10, "no movement left: no song")
	siren().moved = 0
	AI.act(b, siren())
	ok(siren().energy == 8, "one has: it sings to scrub that")


func test_lead_ignores_own_side() -> void:
	stage(lancin, {v(1): Vector2i(4, 4), v(2): Vector2i(4, 5), v(3): Vector2i(9, 0)})
	v(2).afflict(effect("concealment", 2), 9)
	ok(Investigation.lead(b, v(1)) == TRAP, "its own (hidden) ally isn't a lead; the trap is")


func test_look_into_area() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(7, 4)})
	v(3).afflict(effect("concealment", 3), 9)
	ok(not b.read(v(1), v(3)).located(), "only an area of suspicion")
	AI.act(b, v(1))
	ok(v(1).cell != Vector2i(1, 4), "it goes to look anyway")


func test_boon_reach() -> void:
	siren().afflict(effect("concealment", 3, [&"dark"]), 9)
	ok(b.read(v(1), siren()).boon == "", "no boasting through deep concealment")


func cells(a: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(a)
	return out

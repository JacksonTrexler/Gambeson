extends Test

# What the AI reads when it picks an attack and a turn (Scripts/AI.gd; docs/plans/ai-tactics.md): the hit
# chance the player sees (Gank's ambush, Spike's Defense, Poach's advantage), what its behaviours foresee
# (Kick's tile), what they give back or cost it (refunds(): Poach, Slam Jam; unguarded(): Sutemi's Off
# Balance); resting for Focus rather than a poor shot; Resuscitate before Heal on the Downed; and the cheap
# halves of playing against Grudge (starving it of melee) and as it (healing itself back up).

var gank: Skill = load("res://Skills/gank.tres")
var spike: Skill = load("res://Skills/spike.tres")
var sutemi: Skill = load("res://Skills/sutemi.tres")
var poach: Skill = load("res://Skills/poach.tres")
var slam_jam: Skill = load("res://Skills/slam_jam.tres")
var kick: Skill = untuned("kick")  # as written: these are Kick's rules at rank II, not its balance (Skills/kick.tres scales its range at half)
var heal: Skill = load("res://Skills/heal.tres")
var resuscitate: Skill = load("res://Skills/resuscitate.tres")
var grudge: Skill = load("res://Skills/grudge.tres")
var focus: Skill = load("res://Skills/focus.tres")
var focus_pool: Reserve = load("res://Reserves/focus.tres")
var missile: Skill = load("res://Skills/energy_missile.tres")
var intervention: Skill = load("res://Skills/intervention.tres")


func score(u: Unit, s: Skill, t: Unit) -> float:
	return AI.score(u, s, b.read(u, t), b, t)


func test_ambush_counts() -> void:
	v(1).learned.append(slot(gank))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(2): Vector2i(6, 3)})
	v(1).refresh()
	soak(v(3), 300)
	v(3).afflict(effect("defense", 12), 5)  # so the roll isn't a sure thing either way
	var plain := score(v(1), gank, v(3))
	v(1).afflict(effect("concealment", 4), 3)
	ok(b.ambushes(v(1), v(3)), "concealed: an ambush")
	ok(score(v(1), gank, v(3)) > plain, "Gank is worth more as an ambush than in plain view: no disadvantage (%.2f > %.2f)" % [score(v(1), gank, v(3)), plain])


func test_spike_defense_counts() -> void:
	duel(spike)
	v(1).refresh()
	soak(v(3), 300)
	var p := Battle.hit_chance(v(1), spike, v(3), b)
	var plain := score(v(1), spike, v(3))
	v(3).unspent = 12.0
	ok(Battle.hit_chance(v(1), spike, v(3), b) < p and score(v(1), spike, v(3)) < plain, "its target's unspent AP on its Defense lowers the Spike's worth (%.2f < %.2f)" % [score(v(1), spike, v(3)), plain])


func test_chance_picks_the_foe() -> void:
	v(1).learned.append(slot(spike))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3), v(4): Vector2i(4, 4)})
	v(1).refresh()
	for x in [v(3), v(4)]:
		soak(x, 300)
	v(3).unspent = 14.0
	var reads := AI.reads_from({v(3): b.read(v(1), v(3)), v(4): b.read(v(1), v(4))})
	var log: Array[String] = []
	ok(AI._strike(b, v(1), reads, log) and "Villager4" in log[0], "it takes the foe the Spike is likelier to hit (%s)" % [log])


func test_sutemi_toll() -> void:
	duel(sutemi, 2)
	v(1).refresh()
	soak(v(3), 300)
	var beside := score(v(1), sutemi, v(3))
	b.move(v(1), Vector2i(2, 3))
	var far := score(v(1), sutemi, v(3))
	ok(is_equal_approx(beside - far, AI.DEFENSE * 2.0), "lunging 2 tiles costs it Defense 2: %.2f less than beside it (%.2f vs %.2f)" % [beside - far, beside, far])
	ok(sutemi.behaviours[0].unguarded(b.cast_of(v(1), sutemi, v(3), 2, true)) == 2, "the hook: 2")


func test_refunds() -> void:
	v(1).learned.append(slot(poach))
	duel(slam_jam)
	v(1).refresh()
	soak(v(3), 300)
	var cp := b.cast_of(v(1), poach, v(3), 1, true)
	ok(poach.behaviours[0].refunds(cp, 0.5) == 0.0, "a hale foe: Poach gives nothing back")
	v(3).hp = 100
	ok(poach.behaviours[0].refunds(cp, 0.5) == 0.5, "bloodied and never aimed at: half its AP back, sure")
	var cs := b.cast_of(v(1), slam_jam, v(3), 2, true)
	ok(is_equal_approx(slam_jam.behaviours[0].refunds(cs, 0.5), 0.5 / 4.0), "Slam Jam II: 1/4 of its AP on a hit, so as likely as it lands")
	var easy := score(v(1), poach, v(3))
	v(3).hp = 300
	v(3).max_hp = 300
	ok(easy > score(v(1), poach, v(3)), "so Poach is worth more on the bloodied (%.2f)" % easy)


func kicker() -> Unit:
	v(1).learned.append(slot(kick, 2))
	v(1).strength = 40
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3)})
	v(1).refresh()
	soak(v(3), 300)
	return v(1)


func test_kick_foreseen() -> void:
	var u := kicker()
	ok(b.foresee(u, kick, v(3)).is_empty(), "bare ground: nothing more to foresee")
	var bare := score(u, kick, v(3))
	b.paint(Vector2i(3, 3), load("res://Terrain/trap.tres"))
	var f := b.foresee(u, kick, v(3))
	ok(f.lo == 1 and f.hi == 6 and f.notes.size() == 1 and "springs" in f.notes[0], "a trap between: its 1d6 springs on the foe (%s)" % [f])
	ok(score(u, kick, v(3)) > bare + AI.RIDER, "and the AI counts it (%.2f vs %.2f)" % [score(u, kick, v(3)), bare])
	b.paint(Vector2i(3, 3), load("res://Terrain/shallows.tres"))
	ok(b.foresee(u, kick, v(3)).notes == ["Soaks it (2 turns)"], "water: Soaked, said so (%s)" % [b.foresee(u, kick, v(3)).notes])
	b.map.erase_cell(Vector2i(3, 3))
	ok(b.foresee(u, kick, v(3)).notes == ["Drives it 2 tiles back to (6, 3)"], "a hole: 2 tiles back, and where")
	ok(b.foresee(u, strike, v(3)).is_empty(), "a skill with no behaviours: nothing")


func test_kick_in_the_forecast() -> void:
	var u := kicker()
	b.paint(Vector2i(3, 3), load("res://Terrain/trap.tres"))
	var h := await hud(u)
	var d := Battle.damage_range(u, kick, v(3), b)
	var it := {kind = &"use", ready = true, target = v(3), skill = kick, unit = u}
	var hurt: Dictionary = h._hurt(it)
	ok(not hurt.is_empty() and hurt.lo == d.lo + 1 and hurt.hi == d.hi + 6 and hurt.notes.size() == 1, "the HUD's forecast adds the trap's damage and carries its note (%s vs %s)" % [hurt, d])
	h.queue_free()


func test_rests_for_a_better_shot() -> void:
	v(1).learned.append(slot(focus, 1))
	v(1).learned.append(slot(missile))
	stage(lancin, {v(1): Vector2i(5, 3), v(3): Vector2i(7, 3)})
	v(1).refresh()
	v(3).afflict(effect("defense", 40), 5)  # a poor shot: only a natural 20
	var u := v(1)
	ok(b.in_reach(u, missile, v(3)) and Battle.hit_chance(u, missile, v(3), b) < AI.SHOT, "in reach, but under SHOT (%.2f)" % Battle.hit_chance(u, missile, v(3), b))
	u.set_store(focus_pool, 0)
	var log := AI.act(b, u)
	ok(u.cell == Vector2i(5, 3) and u.idle() and u.activity() == &"rest" and not log.any(func(l: String): return "uses" in l), "Focus empty: it rests rather than throw the shot (%s)" % ", ".join(log))
	stage(lancin, {u: Vector2i(5, 3), v(3): Vector2i(7, 3)})
	u.refresh()
	u.set_store(focus_pool, u.pools()[focus_pool])
	log = AI.act(b, u)
	ok(log.any(func(l: String): return "uses Energy Missile" in l), "Focus full: no rest to be had, it shoots (%s)" % ", ".join(log))
	stage(lancin, {u: Vector2i(5, 3), v(3): Vector2i(7, 3)})
	u.refresh()
	u.set_store(focus_pool, 1)  # it can pay for the shot from Focus already
	log = AI.act(b, u)
	ok(log.any(func(l: String): return "uses Energy Missile" in l), "Focus enough for the shot already: it takes it (%s)" % ", ".join(log))


func test_resuscitate_before_heal() -> void:
	v(1).learned.append(slot(heal, 2))  # listed first: it used to win the tie
	v(1).learned.append(slot(resuscitate, 1))
	v(2).learned.append(slot(load("res://Skills/tenacity.tres"), 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(8, 6)})
	v(1).refresh()
	soak(v(2), 100)
	v(2).damage(100)
	v(2).damage(20)
	ok(v(2).dbno != null, "Downed")
	var used := []
	b.used.connect(func(_c: Unit, s: Skill, _at: Variant, _n: int): used.append(s))
	AI.act(b, v(1))
	ok(used.size() >= 1 and used[0] == resuscitate and v(2).dbno == null, "it resuscitates, not heals (%s)" % [used.map(func(s: Skill): return s.name)])
	ok(not AI._revives(b, v(1), heal, v(2)), "Heal doesn't revive")


# v(3), Nemes, Downed under Grudge with its melee owed, the last foe v(1) has.
func grudged(near: Vector2i) -> Unit:
	v(3).learned.append(slot(grudge, 2))
	stage(lancin, {v(1): near, v(3): Vector2i(1, 1)})
	v(3).refresh()
	v(1).refresh()
	v(3).damage(999)
	v(3).dbno.fresh = false
	return v(3)


func test_starves_grudge() -> void:
	var g := grudged(Vector2i(3, 3))
	v(1).strength = 0
	var reach := ceili(g.stat(&"movement")) + 1
	b.move(v(1), Vector2i(8, 6))
	ok(Command.tiles(v(1).cell, g.cell) > reach, "set well out of its reach (%d tiles, its reach %d)" % [Command.tiles(v(1).cell, g.cell), reach])
	var at := v(1).cell
	var log := AI.act(b, v(1))
	ok(v(1).cell == at and log.is_empty(), "beyond its reach: it holds where it stands rather than close (%s)" % [log])
	b.move(v(1), Vector2i(3, 3))
	log = AI.act(b, v(1))
	ok(Command.tiles(v(1).cell, g.cell) > Command.tiles(Vector2i(3, 3), g.cell) and log.any(func(l: String): return "starving" in l), "within it: it keeps away (%s)" % [log])
	b.move(v(1), Vector2i(2, 1))
	v(1).refresh()
	v(1).strength = 60
	v(1).dexterity = 60
	log = AI.act(b, v(1))
	ok(not g.is_alive() or g.dbno == null, "a blow that ends it: it strikes (%s)" % [log])
	ok(not log.any(func(l: String): return "starving" in l), "...no keeping away")


# docs/plans/ai-tuning.md. Keeping from a Grudge unit's reach, it backs into a tile it can back off from again next
# round, not the corner furthest away (where the next round has it cornered, handing over the blow).
func test_starving_keeps_room_to_retreat() -> void:
	var g := grudged(Vector2i(4, 3))
	v(1).strength = 0
	var from: Array[Vector2i] = [g.cell]
	var gap := func(c: Vector2i) -> int: return Command.tiles(g.cell, c)
	var reach := ceili(g.stat(&"movement")) + 1
	var far := AI._retreat(b, v(1), from)
	var wise := AI._retreat(b, v(1), from, reach + 1)
	ok(gap.call(wise) > reach, "out of its reach (%s, %d tiles, its reach %d)" % [wise, gap.call(wise), reach])
	ok(AI._room(b, v(1), wise, gap) > AI._room(b, v(1), far, gap), "with more room to back off again than the furthest tile (%s: %d, against %s: %d)" % [wise, AI._room(b, v(1), wise, gap), far, AI._room(b, v(1), far, gap)])
	ok(AI._room(b, v(1), Vector2i(9, 7), gap) == 0 and AI._room(b, v(1), Vector2i(0, 0), func(c: Vector2i) -> int: return Command.tiles(Vector2i(9, 7), c)) == 0, "a corner has none")
	var start := v(1).cell
	var log := AI.act(b, v(1))
	var went := v(1).cell
	b.move(v(1), start)
	v(1).refresh()
	b.travel(v(1), wise)
	ok(log.any(func(l: String): return "starving" in l) and went == v(1).cell and went != start, "the starving turn backs off there (%s, %s from %s, to %s)" % [log, went, start, wise])


# docs/plans/ai-findings.md. Backing off a Grudge unit together: among tiles alike in distance and room, u leaves the one an ally
# still to move would choose for itself (the room count can't say it: the ally stands elsewhere now), and an ally that has moved claims none.
func test_retreat_leaves_an_allys_tile() -> void:
	var g := grudged(Vector2i(5, 3))
	v(1).strength = 0
	var from: Array[Vector2i] = [g.cell]
	var safe := ceili(g.stat(&"movement")) + 2
	var alone := AI._retreat(b, v(1), from, safe)
	var theirs := Vector2i(-1, -1)
	for c in b.cells_near(v(1).cell, 3):  # an ally standing where its own retreat is that same tile
		if c == v(1).cell or not b.on_map(c) or b.unit_at(c) or Command.tiles(g.cell, c) >= safe:
			continue
		stage(lancin, {v(1): Vector2i(5, 3), v(2): c, v(3): Vector2i(1, 1)})
		if AI._retreat(b, v(2), from, safe, {}, false) == alone:
			theirs = c
			break
	ok(theirs != Vector2i(-1, -1), "an ally position whose own retreat is the same tile %s (%s)" % [alone, theirs])
	var gap := func(c: Vector2i) -> int: return Command.tiles(g.cell, c)
	var shared := AI._retreat(b, v(1), from, safe)
	ok(shared != alone and mini(gap.call(shared), safe) == mini(gap.call(alone), safe) and AI._room(b, v(1), shared, gap) == AI._room(b, v(1), alone, gap),
			"it takes another as good (%s for %s: gap %d, room %d)" % [shared, alone, gap.call(shared), AI._room(b, v(1), shared, gap)])
	v(2).moved = v(2).stat(&"movement")
	ok(AI._retreat(b, v(1), from, safe) == alone, "an ally that has already moved claims nothing")


func test_grudge_heals_itself() -> void:
	roomy(v(3))
	v(3).learned.append(slot(grudge, 2))
	v(3).learned.append(slot(heal, 2))
	stage(lancin, {v(1): Vector2i(5, 3), v(3): Vector2i(4, 3)})
	v(3).refresh()
	v(3).energy = v(3).max_energy
	v(3).damage(999)
	ok(v(3).dbno != null, "Downed under Grudge")
	b.end_turn()
	var log := AI.act(b, v(3))
	ok(v(3).dbno == null and v(3).hp > 0 and log.any(func(l: String): return "heals itself back up" in l), "it heals itself back above 0 rather than spend itself (%d, %s)" % [v(3).hp, log])


# docs/plans/ai-prices.md. A foe's Defense is what its Read has (armor shows at net 0), else a guess.
func test_defense_from_read() -> void:
	duel(strike)
	v(1).refresh()
	soak(v(3), 300)
	v(3).afflict(effect("defense", 14), 5)  # a hard target the AI can see is one
	var seen := b.read(v(1), v(3))
	ok(seen.defense == v(3).defense(), "its armor shows: the read has its Defense (%s)" % [seen.defense])
	var hidden := b.read(v(1), v(3))
	hidden.defense = null
	var known := AI.score(v(1), strike, seen, b, v(3))
	ok(AI.score(v(1), strike, hidden, b, v(3)) > known, "unseen, it is guessed (%d) lower than a 14 more than a plain one is: the blow is worth more" % AI.GUESS_DEFENSE)
	v(3).afflict(effect("concealment", 4), 5)
	ok(b.read(v(1), v(3)).defense == null, "concealed past net 0: no Defense in the read, as the HUD's odds can't show it either")


# docs/plans/ai-prices.md. What a blow's behaviours add that damage doesn't: Poach's cost back, its regain on
# a felling blow, Slam Jam's interrupt at its contest's odds, a trap's blast and a drive's real distance.
func test_prices_the_rest() -> void:
	v(1).learned.append(slot(poach))
	duel(slam_jam, 2)
	v(1).refresh()
	soak(v(3), 300)
	v(3).hp = 140  # bloodied, so Poach halves its price
	var cp := b.cast_of(v(1), poach, v(3), 1, true)
	var d := Battle.damage_range(v(1), poach, v(3), b)
	var fund: Variant = v(1).funding(poach)
	var saved := 0.5 * (v(1).ap_cost(poach, fund) * AI.AP + v(1).cost_from(poach, fund) * AI.POINT)
	ok(v(1).cost_from(poach, fund) > 0 and is_equal_approx(score(v(1), poach, v(3)), Battle.hit_chance(v(1), poach, v(3), b) * d.avg + saved), "Poach's half price counts its cost beside its AP (%.2f)" % saved)
	ok(b.foresee(v(1), poach, v(3)).is_empty(), "a blow that leaves it standing regains nothing")
	v(3).hp = 1
	var f := b.foresee(v(1), poach, v(3))
	ok(f.riders == 1.0 and "regains" in f.notes[0], "one that fells it does (%s)" % [f.notes])
	var js := b.foresee(v(1), slam_jam, v(3))
	var odds := Battle.odds(v(1), &"strength", v(3), &"constitution", {bonus = 2, tags = cp.tags, their_tags = slam_jam.tags, kind = Check.Kind.SAVE})
	ok(is_equal_approx(js.afflicts, odds * load("res://Behaviours/jam.gd").JAMMED_TURN) and js.riders == 0.0 and odds > 0.0 and odds < 1.0, "Slam Jam's Jammed is a cc as likely as its contest (%.2f), a share of a turn" % js.afflicts)


func trap_blast(radius: float) -> void:
	var t: Terrain = load("res://Terrain/trap.tres").duplicate()
	t.blast = radius
	b.paint(Vector2i(3, 3), t)


func test_kick_spill_and_drive() -> void:
	var u := kicker()
	trap_blast(1.0)
	var plain := b.foresee(u, kick, v(3))
	ok(plain.spill < 0.0, "the kicker beside the trap is in its blast: it costs (%s)" % [plain.spill])  # the kicker at (2,3) is a tile from the trap
	v(4).faction = nemes
	b.move(v(4), Vector2i(3, 4))  # a foe a tile from the trap
	var both := b.foresee(u, kick, v(3))
	ok(is_equal_approx(both.spill, 0.0) and both.notes.size() == 2 and both.riders == 1.0, "a foe in the blast offsets the kicker's own cost (%s)" % [both])
	b.map.erase_cell(Vector2i(3, 3))  # a hole: drives it 2 back
	var free := b.foresee(u, kick, v(3))
	ok(free.notes == ["Drives it 2 tiles back to (6, 3)"] and is_equal_approx(free.riders, 2 * load("res://Behaviours/kick.gd").PUSH), "a free drive: its distance in riders (%s)" % [free])
	b.move(v(2), Vector2i(6, 3))  # an ally of the kicker's behind it
	var short := b.foresee(u, kick, v(3))
	ok(short.notes[0].begins_with("Drives it 1 tile back to (5, 3), then slams") and short.lo == Battle.SLAM and short.spill == -float(Battle.SLAM), "stopped by an ally after 1 tile: it slams both (%s)" % [short])


# docs/plans/ai-walks.md. Lining up a shove: it walks to the tile its Kick tells most from (a foe's own side behind it,
# so the slam lands on them), by Battle.foresee() from each tile; with nothing to gain, or it would cost its own side, it stays.
func test_lines_up_a_shove() -> void:
	v(1).learned.append(slot(kick, 2))
	roomy(v(1))
	v(1).strength = 40
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(5, 4), v(4): Vector2i(5, 5)})
	v(4).faction = nemes  # the foe's own side below it: a kick from above slams them
	v(1).refresh()
	soak(v(3), 300)
	var log: Array[String] = []
	var reads := AI.reads_from({v(3): b.read(v(1), v(3)), v(4): b.read(v(1), v(4))})
	ok(AI._line_up(b, v(1), reads, log) and v(1).cell != Vector2i(4, 4) and Command.tiles(v(1).cell, v(3).cell) == 1, "to beside the foe, from where it can drive it into the foe behind it (%s, %s)" % [v(1).cell, log])
	ok(b.foresee(v(1), kick, v(3)).hi == Battle.SLAM, "which slams them (%s)" % [b.foresee(v(1), kick, v(3))])
	v(4).faction = lancin  # its own side behind the foe now: that tile costs it
	b.move(v(1), Vector2i(4, 4))
	v(1).refresh()
	reads = {v(3): b.read(v(1), v(3)), v(4): b.read(v(1), v(4))}
	ok(not AI._line_up(b, v(1), reads, log) and v(1).cell == Vector2i(4, 4), "into its own side: it stays where it is (%s)" % [v(1).cell])
	b.move(v(4), Vector2i(9, 0))
	reads = {v(3): b.read(v(1), v(3))}
	ok(not AI._line_up(b, v(1), reads, log) and v(1).cell == Vector2i(4, 4), "nothing to line up in the open: it stays")


# docs/plans/ai-findings.md. The line-up's threshold is one tile of shove (Battle.PUSH x AI.RIDER), the least a drive can
# differ by: a tile that tells exactly that much more is worth the walk, one that tells no more isn't.
func test_line_up_gain_threshold() -> void:
	v(1).learned.append(slot(kick, 2))
	roomy(v(1))
	v(1).strength = 40
	stage(lancin, {v(1): Vector2i(6, 3), v(3): Vector2i(6, 4), v(2): Vector2i(0, 0), v(4): Vector2i(0, 1)})
	v(1).refresh()
	soak(v(3), 300)
	b.paint(Vector2i(5, 4), load("res://Terrain/shallows.tres"))  # kicked from (4, 4): Soaks it, a rider; from beside, a 1-tile push is half of one
	var reads := AI.reads_from({v(3): b.read(v(1), v(3))})
	var here: float = b.standing(v(1), v(1).cell, func() -> float: return AI._driven(b, v(1), kick, v(3)))
	var there: float = b.standing(v(1), Vector2i(4, 4), func() -> float: return AI._driven(b, v(1), kick, v(3)))
	ok(is_equal_approx(there - here, Battle.PUSH * AI.RIDER), "the water tile tells one tile of shove more (%.2f vs %.2f)" % [there, here])
	var log: Array[String] = []
	ok(AI._line_up(b, v(1), reads, log) and v(1).cell == Vector2i(4, 4), "exactly that much more: it walks there (%s, %s)" % [v(1).cell, log])
	b.paint(Vector2i(5, 4), Battle.PLAIN)
	b.move(v(3), Vector2i(5, 4))
	b.move(v(1), Vector2i(2, 4))
	v(1).movement = 1  # the one tile it can walk to is in Kick's reach, bare ground between: no better than the poorest tile in reach, itself
	v(1).refresh()
	reads = {v(3): b.read(v(1), v(3))}
	ok(not AI._line_up(b, v(1), reads, log) and v(1).cell == Vector2i(2, 4), "no more to be had from any tile in reach: it stays (%s)" % [v(1).cell])


# docs/plans/ai-walks.md. Its retreat weighs being driven: a tile on the map's edge is one a foe's Kick slams it against
# (Battle.course() through foresee()), so with the blow read it stops a tile short; and it prices the way there by
# route(), so it won't back onto a trap it knows of when another tile is as far.
func test_retreat_weighs_shoves_and_price() -> void:
	v(3).learned.append(slot(kick, 2))
	stage(lancin, {v(1): Vector2i(6, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	sharp(v(1))
	var from: Array[Vector2i] = [Vector2i(5, 3)]
	var reads := AI.reads_from({v(3): b.read(v(1), v(3))})
	ok(kick in reads[v(3)].skills, "it has read the foe's Kick")
	var edge := Vector2i(9, 3)
	ok(AI._shoved(b, v(1), edge, reads) > 0.0 and AI._shoved(b, v(1), Vector2i(8, 3), reads) == 0.0, "the edge is a wall to be slammed into (%.1f), a tile in is not" % AI._shoved(b, v(1), edge, reads))
	var plain := AI._retreat(b, v(1), from)
	var wary := AI._retreat(b, v(1), from, 0, reads)
	ok(AI._shoved(b, v(1), plain, reads) > 0.0 and AI._shoved(b, v(1), wary, reads) == 0.0, "the furthest tile %s is on the edge; with the Kick read it takes %s" % [plain, wary])
	var trap: Terrain = load("res://Terrain/trap.tres")
	b.paint(plain, trap)
	var again := AI._retreat(b, v(1), from)
	ok(again != plain and again != Vector2i(6, 3), "a trap on the furthest tile: it backs off to another (%s, not %s)" % [again, plain])


# docs/plans/ai-walks.md. A Downed Grudge unit makes its blow this round or dies of it: it goes for the foe it can
# walk up to, not the one it would otherwise want most (the strongest, here, out of its reach).
func test_grudge_goes_for_what_it_reaches() -> void:
	var g := grudged(Vector2i(2, 3))
	roomy(g)
	g.strategy = [&"strongest"]
	g.refresh()
	v(4).faction = lancin
	b.move(v(4), Vector2i(9, 7))
	v(4).level = 20
	sharp(g)
	b.end_turn()  # its side's turn
	var reads := AI.reads_from({v(1): b.read(g, v(1)), v(4): b.read(g, v(4))})
	ok(AI._best_target(g, reads) == v(4), "of the two it would want the strong one, far off")
	ok(AI._best_target(g, AI._reachable(b, g, reads)) == v(1), "but it can only walk up to the near one this round")
	var log: Array[String] = []
	AI._last_blows(b, g, reads, log)
	ok(Battle.next_to(g.cell, v(1).cell), "and it closes with it (%s at %s)" % [log, g.cell])


# docs/plans/ai-prices.md. Starving a Grudge unit is worth a kill shared by the allies in its reach, nothing
# when it dies of its rounds anyway, and is weighed against the strikes it gives up.
func test_starve_worth() -> void:
	var g := grudged(Vector2i(3, 3))
	ok(g.dbno.left > 1, "Grudge II lingers %d rounds" % g.dbno.left)
	var alone := AI.starve_worth(b, v(1), g)
	ok(alone == AI.STARVE, "alone in its reach: a whole kill (%.2f)" % alone)
	b.move(v(2), Vector2i(2, 2))
	ok(AI.starve_worth(b, v(1), g) == AI.STARVE / 2.0, "an ally in its reach shares it")
	g.dbno.left = 1
	ok(AI.starve_worth(b, v(1), g) == 0.0, "its last round: it dies anyway, nothing to starve")
	g.dbno.left = 2
	b.move(v(2), Vector2i(9, 9))
	v(4).faction = nemes
	b.move(v(4), Vector2i(4, 3))  # a standing foe beside it, a blow worth more than the starving
	v(1).strength = 30
	v(1).refresh()
	var log := AI.act(b, v(1))
	ok(not log.any(func(l: String): return "starving" in l) and log.any(func(l: String): return "uses" in l), "another foe worth striking: it does not give that up (%s)" % [log])


# docs/plans/ai-prices.md. Finishing a unit with a Final Act left hands it a free action: the blow is worth that
# less, though never nothing (it is left for last, not left alone).
func test_final_act_is_priced() -> void:
	var final_act: Skill = load("res://Skills/final_act.tres")
	v(3).learned.append(slot(final_act))
	duel(strike)
	v(1).refresh()
	v(3).refresh()
	v(3).hp = 1
	var reads := AI.reads_from({v(3): b.read(v(1), v(3))})
	var cost := AI._reprisal(b, v(1), strike, v(3), reads)
	ok(cost == 0.0, "its Final Act unread: nothing to weigh (%.2f)" % cost)
	sharp(v(1))
	reads = {v(3): b.read(v(1), v(3))}
	cost = AI._reprisal(b, v(1), strike, v(3), reads)
	ok(cost > 0.0, "read, its free action is a cost (%.2f)" % cost)
	v(4).faction = nemes
	b.move(v(4), Vector2i(4, 4))
	v(4).hp = 1
	reads[v(4)] = b.read(v(1), v(4))
	var log: Array[String] = []
	ok(AI._strike(b, v(1), reads, log) and "Villager4" in log[0], "of two alike foes about to fall, it takes the one with no free action to give (%s)" % [log])
	b.move(v(4), Vector2i(-99, -99))
	reads.erase(v(4))
	v(3).hp = 1
	log.clear()
	ok(AI._strike(b, v(1), reads, log), "alone it is still finished: left for last, not left alone (%s)" % [log])


# docs/plans/ai-support-2.md. What a worn skill's raised cost takes off its worth in _strike(), so a unit with
# another blow nearly as good varies - and the floor, so a lone worn skill is still used.
func test_wear_varies_the_blow() -> void:
	duel(spike)
	v(1).refresh()
	soak(v(3), 900)
	Exhaustion.on = true
	var reads := AI.reads_from({v(3): b.read(v(1), v(3))})
	var first := ""
	var picked := func() -> String:
		var log: Array[String] = []
		v(1).refresh()
		AI._strike(b, v(1), reads, log)
		return log[0].split(" uses ")[1].split(" on ")[0]
	ok(AI._wear(v(1), strike) == 0.0, "fresh: no wear")
	var a: String = picked.call()
	var skills := {"Strike": strike, "Spike": spike}
	var worn: Skill = skills[a]
	var other: Skill = skills["Spike" if a == "Strike" else "Strike"]
	ok(score(v(1), worn, v(3)) > score(v(1), other, v(3)), "the %s it picks fresh scores higher (%s)" % [a, [score(v(1), strike, v(3)), score(v(1), spike, v(3))]])
	for i in 6:
		v(1).exhaustion.used(worn)
	var w := AI._wear(v(1), worn)
	ok(w > 0.0, "worn, it costs it %.2f" % w)
	ok(picked.call() == other.name, "worn out, it takes the other blow (%s)" % picked.call())
	for i in 10:
		v(1).exhaustion.used(other)
	v(1).ap = [AP.new(100.0, &"")]
	ok(AI._strike(b, v(1), reads, []), "both worn: a worn blow is still better than none")
	Exhaustion.on = false


# docs/plans/ai-walks.md. A heal or a support that exhaustion has made dearer is worth less than a fresher one that
# does as well - but a lone worn one is still cast.
func test_wear_weighs_heals_and_supports() -> void:
	var mega: Skill = load("res://Skills/megaheal.tres")
	var twin: Skill = load("res://Skills/stonegift.tres")
	for s in [heal, mega]:
		v(1).learned.append(slot(s, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(8, 6)})
	Exhaustion.on = true
	var rested := func() -> void:
		v(1).refresh()
		v(1).max_energy = 200
		v(1).energy = 200
		v(1).ap = [AP.new(100.0, &"")]  # whatever the wear has made them cost
	var healed := func() -> Skill:  # the heal it casts on a wounded ally
		rested.call()
		v(2).max_hp = 100
		v(2).hp = 40
		var before := {heal: v(1).exhaustion.uses.get(heal, 0.0), mega: v(1).exhaustion.uses.get(mega, 0.0)}
		AI._heal(b, v(1), AI.reads_from({v(2): b.read(v(1), v(2))}), [])
		return heal if v(1).exhaustion.uses.get(heal, 0.0) > before[heal] else (mega if v(1).exhaustion.uses.get(mega, 0.0) > before[mega] else null)
	ok(AI._fresh(v(1), heal) == 1.0, "fresh: the whole of its worth")
	ok(healed.call() == heal, "of two heals that do alike, the first")
	for i in 8:
		v(1).exhaustion.used(heal)
	ok(AI._fresh(v(1), heal) < 1.0 and AI._fresh(v(1), heal) >= 1.0 - AI.WORN, "worn: less, never past the floor (%.2f)" % AI._fresh(v(1), heal))
	ok(healed.call() == mega, "worn, Heal gives way to Megaheal")
	for i in 10:
		v(1).exhaustion.used(mega)
		v(1).exhaustion.used(heal)
	ok(healed.call() != null, "both worn out: a worn heal is still better than none")
	var u := v(2)  # the supports are another's: a unit holds four skills at a time
	for s in [intervention, twin]:
		u.learned.append(slot(s, 2))
	var gave := func() -> String:  # the support it gives an ally with nothing on
		u.refresh()
		u.max_energy = 200
		u.energy = 200
		u.ap = [AP.new(100.0, &"")]
		for e in v(1).timed.keys():
			v(1).timed.erase(e)
		var log: Array[String] = []
		AI._support(b, u, AI.reads_from({v(1): b.read(u, v(1))}), log)
		return log[0].split(" gives ")[1].split(" to ")[0] if not log.is_empty() else ""
	var first: String = gave.call()
	var skills := {"Intervention": intervention, "Stonegift": twin}
	for i in 8:
		u.exhaustion.used(skills[first])
	var then: String = gave.call()
	ok(first != "" and then != "" and then != first, "a worn support gives way to the fresher (%s, then %s)" % [first, then])
	Exhaustion.on = false


# Forced moves are harm to the unit they land on, a rider to the one who lands them (docs/plans/forced-forecast.md):
# a shove is worth more on a foe than none, less pushed into its own ally, and a support skill that carries one
# isn't cast on allies.
func test_forced_moves_are_priced() -> void:
	var s: Skill = hex.duplicate()
	s.rolls = false
	v(1).learned.append(slot(s))
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(4, 3), v(2): Vector2i(1, 8)})
	v(1).refresh()
	soak(v(3), 300)
	var bare := score(v(1), s, v(3))
	s.effects = [effect("shove", 2.0)] as Array[Effect]
	var shoved := score(v(1), s, v(3))
	ok(shoved >= bare + 2 * Battle.PUSH * AI.RIDER, "a shove is sought, a rider a tile: %.2f vs %.2f" % [shoved, bare])
	b.move(v(2), Vector2i(5, 3))
	var into_ally := score(v(1), s, v(3))
	v(2).faction = nemes
	ok(into_ally < score(v(1), s, v(3)), "into its own ally it is worth less than into a foe (%.2f, %.2f)" % [into_ally, score(v(1), s, v(3))])
	v(2).faction = lancin
	b.move(v(2), Vector2i(1, 8))
	var buff: Skill = load("res://Skills/intervention.tres").duplicate()
	buff.effects = [effect("fear", 1.0)] as Array[Effect]
	v(1).learned.append(slot(buff))
	var log: Array[String] = []
	AI._support(b, v(1), AI.reads_from({v(2): b.read(v(1), v(2))}), log)
	ok(log.is_empty(), "and a support skill carrying fear isn't given to an ally (%s)" % [log])
	buff.effects = [effect("mitigate", 0.2)] as Array[Effect]
	AI._support(b, v(1), AI.reads_from({v(2): b.read(v(1), v(2))}), log)
	ok(not log.is_empty(), "though one that helps is (%s)" % [log])


# What a cc takes from a foe's turn (docs/plans/w5-ai1.md): a skill's cc is worth the share of the foe's next turn its
# behaviour foresees (Battle.foresee() `afflicts`; CC where only the tag says it is one) of what that turn is worth
# (_threat(): its skills, else its stats, else BLOW), less for each cc it already bears, none from one stopped.
func test_prices_a_cc() -> void:
	var stun := sk("stun")
	v(1).learned.append(slot(stun, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	soak(v(1), 500)
	soak(v(3), 300)
	v(1).refresh()
	var f := b.foresee(v(1), stun, v(3))
	ok(f.afflicts > 0.0 and f.afflicts < 1.0 and f.riders == 0.0, "Stun reports its odds as a cc, not a rider (%s)" % [f])
	var worth := func() -> float: return AI._afflicting(b, v(1), stun, b.read(v(1), v(3)), v(3), f)
	ok(is_equal_approx(worth.call(), f.afflicts * AI.BLOW), "unread: its turn is a BLOW (%.2f)" % worth.call())
	v(3).strength = 40
	sharp(v(1))
	var hard: float = worth.call()
	v(3).strength = 1
	var weak: float = worth.call()
	ok(hard > weak and hard > 1.5 * AI.BLOW * f.afflicts, "read, a hard hitter's turn is worth more to take than a weak foe's (%.2f, %.2f)" % [hard, weak])
	v(3).strength = 40
	v(3).afflict(load("res://Effects/winded.tres"), 3)
	ok(is_equal_approx(worth.call(), hard / 2.0), "a cc it already bears halves it (%.2f)" % worth.call())
	v(3).afflict(load("res://Effects/stunned.tres"), 1)
	ok(worth.call() == 0.0 and v(3).stopped() and v(3).afflicted(&"cc").size() == 2, "none from a unit that is stopped")
	var stopped := score(v(1), stun, v(3))
	v(3).timed.clear()
	ok(score(v(1), stun, v(3)) > stopped + 0.9 * hard * 0.5, "the price is in the score: a Stun on a foe not yet stopped outbids one on a foe already")
	var fog := sk("brainfog")
	ok(AI._afflicting(b, v(1), fog, b.read(v(1), v(3)), v(3), {}) > 0.0 and is_equal_approx(AI._afflicting(b, v(1), fog, b.read(v(1), v(3)), v(3), {}) / AI._threat(b, v(1), b.read(v(1), v(3)), v(3)), AI.CC), "a cc with nothing foreseen is worth the CC share")
	ok(AI._afflicting(b, v(1), hex, b.read(v(1), v(3)), v(3), {}) == 0.0, "a hostile skill with no cc tag is worth none")


# A foe's cc is read on the threat side (AI._stunners(): the foe's skills it makes out, each foresee()'s `afflicts` as likely as it
# lands, over 1 + the cc it already bears; AI._dread(): the share of its next turn they take at a tile their walk and reach cover):
# it closes on a target from the side out of a Stunner's reach (_approach()) and backs off to a tile out of it (_retreat()).
func test_dreads_a_cc() -> void:
	var stun := sk("stun")
	v(4).learned.append(slot(stun, 2))
	stage(lancin, {v(1): Vector2i(4, 6), v(3): Vector2i(7, 3), v(4): Vector2i(0, 3)})
	soak(v(1), 500)
	soak(v(3), 500)
	v(4).refresh()
	var reads := AI.reads_from({v(3): b.read(v(1), v(3)), v(4): b.read(v(1), v(4))})
	ok(AI._stunners(b, v(1), reads).is_empty(), "unread, the foe's Stun is unknown: nothing to dread")
	sharp(v(1))
	reads = {v(3): b.read(v(1), v(3)), v(4): b.read(v(1), v(4))}
	var foes := AI._stunners(b, v(1), reads)
	var reach: float = foes[0][1]
	ok(foes.size() == 1 and foes[0][0] == v(4) and foes[0][2] > 0.0 and foes[0][2] < 1.0 and reach > 4.0, "read, v(4)'s Stun counts, v(3)'s Strike doesn't (%s)" % [foes])
	ok(AI._dread(foes, Vector2i(ceili(reach) - 1, 3)) == foes[0][2] and AI._dread(foes, Vector2i(ceili(reach) + 1, 3)) == 0.0, "its odds in its reach, none out of it")
	var winded := load("res://Effects/winded.tres")
	v(1).afflict(winded, 3)
	ok(is_equal_approx(AI._stunners(b, v(1), reads)[0][2], foes[0][2] / 2.0), "a cc it already bears halves it (Unit.afflicted())")
	v(1).timed.clear()
	var plain := AI._approach(b, v(1), v(3), AI.reads_from({v(3): reads[v(3)]}))
	var wary := AI._approach(b, v(1), v(3), reads)
	ok(AI._dread(foes, plain) > 0.0 and AI._dread(foes, wary) == 0.0 and Command.tiles(wary, v(3).cell) == 1, "it closes from a side out of the Stunner's reach, not the one that is nearer: %s, not %s" % [wary, plain])
	var from: Array[Vector2i] = [v(3).cell]
	var back := AI._retreat(b, v(1), from, 0, reads)
	ok(AI._dread(foes, back) == 0.0, "backing off from another foe, it keeps out of the Stunner's reach (%s)" % back)


# What a planning stretch holds (Unit.begin_read(), held()) and what the planners ask in part: a skill's reach is asked once a stretch and
# a fresh one finds a change; skill_range() is skill_reach() plus the target's part; survey()'s bounded suspicious() is the full list cut.
func test_planning_holds_and_bounds() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(8, 1)})
	var strike: Skill = load("res://Skills/strike.tres")
	var u := v(1)
	u.wisdom = 16
	var before := b.skill_reach(u, strike)
	ok(b.skill_range(u, strike, v(3)) == before + 0.02 * v(3).stat(&"size"), "skill_range is skill_reach and the target's part")
	Unit.begin_read()
	ok(b.skill_reach(u, strike) == before and u.held(strike) == before, "held in the stretch")
	Unit.end_read()
	u.afflict(effect("reach", 3), 3)
	ok(u.held(strike) == null and b.skill_reach(u, strike) > before, "a new stretch finds what changed (%.2f > %.2f)" % [b.skill_reach(u, strike), before])
	var all := b.suspicious(u)
	ok(not all.is_empty(), "the trap and what hides are suspicious")
	for reach in [3, 4, 5]:  # the trap is 4 tiles off
		ok(b.suspicious(u, {}, u.cell, reach) == all.filter(func(c: Vector2i): return Command.tiles(u.cell, c) <= reach), "bounded to %d tiles is the list cut there" % reach)


# What a read asks of a unit again and again is found once a stretch (Unit.begin_read()): its kit, plain Defense, working passives
# (mod() asks them every time) and core stats. In a stretch they equal the plain answers, a reader's change to the copy it got
# doesn't reach the next reader, and a fresh stretch finds a change (a disabled passive, a Defense effect).
func test_stretch_holds_what_a_read_asks() -> void:
	stage(lancin, {v(1): Vector2i(1, 4), v(3): Vector2i(8, 1)})
	var u := roomy(v(1))
	var bracing: Skill = load("res://Skills/agility_bracing.tres")
	u.learned.append(slot(bracing))
	u._arrange()
	var kit := u.kit
	var defense := u.defense()
	var core := u.core_stats()
	ok(bracing in u.passives and bracing in kit, "the passive works and is in its kit")
	Unit.begin_read()
	ok(u.kit == kit and u.defense() == defense and u.core_stats() == core and u.on_passives == u._on_passives(), "in a stretch the held answers are the plain ones")
	u.kit.append(null)
	u.on_passives.clear()
	u.core_stats()[&"strength"] = 99.0
	ok(u.kit == kit and not u.on_passives.is_empty() and u.core_stats() == core, "a reader changing its copy leaves the next reader's")
	Unit.end_read()
	u.disable(bracing, 3)
	u.afflict(effect("defense", 3), 3)
	Unit.begin_read()
	ok(bracing not in u.passives and bracing in u.kit and u.defense() == defense + 3, "a fresh stretch finds a disabled passive (still in the kit) and a Defense effect (%d vs %d)" % [u.defense(), defense])
	Unit.end_read()


# The cheaper ways of asking (docs/plans/w11-cast.md) answer as the plain ones did, for a field of mixed units: what is held for a
# stretch (rank, suspicious) is what a plain ask finds, and the shortcuts (restless's tag first, evaluates first, cover in one stretch,
# slots in one pass, link past item-less items, the reaction-tagged passives alone) equal their long forms. And the premise of the
# last: every behaviour that reacts (defines react()) sits on skills that carry the reaction tag, as skill.py check holds.
func test_cast_cost_answers_as_before() -> void:
	var gal: Skill = sk("gallantry")
	var interject: Skill = sk("interject")
	v(1).learned.append(slot(gal))
	v(2).learned.append(slot(interject))
	v(3).learned.append(slot(sk("self_evaluation")))
	v(4).learned.append(slot(sk("agility_bracing")))
	v(4).learned.append(slot(sk("self_evaluation")))
	for u: Unit in [v(1), v(2), v(3), v(4)]:
		roomy(u, 4)
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 3), v(3): Vector2i(6, 3), v(4): Vector2i(7, 3)})
	v(2).afflict(load("res://Effects/disturbed.tres"), 5)
	v(3).afflict(effect("concealment", 2), 5)
	v(4).tags.append(&"undead")
	v(4).afflict(effect("sleep", 1.0), 5)  # an evaluator asleep sees nothing
	v(4).afflict(load("res://Effects/disturbed.tres"), 5)
	var units: Array[Unit] = [v(1), v(2), v(3), v(4)]
	for u in units:
		var slots_was := {}  # slots() as it was: _own() then granted(), each skill's first entry of its highest rank
		for x in u._own() + u.granted():
			if x and x.skill and (x.skill not in slots_was or x.rank > slots_was[x.skill].rank):
				slots_was[x.skill] = x
		ok(u.slots == slots_was.values(), "%s: slots in one pass are the two-step list" % u.name)
		ok(u.restless() == (u.disturbed() and u.has_tag(&"undead")), "%s: restless is its two parts" % u.name)
		ok(Perception.cover(b, u) == Perception._levels(b, u.cell, u).values().reduce(func(sum, x): return sum + x, 0), "%s: cover" % u.name)
		var evaluating := units.filter(func(o: Unit): return o.faction == u.faction and o.is_alive() and not o.asleep() and o.evaluates() > 0 and Command.tiles(o.cell, u.cell) <= o.evaluates())
		ok(b.evaluators(u).map(func(o: Unit): return o.name) == evaluating.map(func(o: Unit): return o.name), "%s: evaluators" % u.name)
		var reacting: Array[Slot] = []
		reacting.assign(Battle.reactions_of(u).filter(func(x: Slot): return &"reaction" in x.skill.tags))
		ok(Battle.reactions_of(u, Battle.REACTION) == reacting and u.on_passives_tagged(Battle.REACTION).size() == u.on_passives.filter(func(x: Slot): return Battle.REACTION in x.skill.tags).size(), "%s: the reaction-tagged passives alone" % u.name)
		for s: Skill in [gal, interject, strike, hex]:
			var items_link := &""  # link() as it was: every item asked
			for it in u.items():
				match it.link(s):
					&"free":
						items_link = &"free"
					&"optional":
						if items_link == &"":
							items_link = &"optional"
			ok(u.link(s) == (&"" if items_link == &"" or u.own_rank(s) > 0 else items_link), "%s: link %s" % [u.name, s.name])
		var plain := {}
		for x in u.slots:
			plain[x.skill] = u.rank(x.skill)
		Unit.begin_read()
		for x in u.slots:  # twice: asked, then held
			ok(u.rank(x.skill) == plain[x.skill] and u.rank(x.skill) == plain[x.skill], "%s: rank of %s held" % [u.name, x.skill.name])
		Unit.end_read()
		var all := b.suspicious(u)
		Unit.begin_read()
		var known: Dictionary[Unit, Read] = {}
		for t in units:
			if t != u:
				known[t] = b.read(u, t)
		ok(b.suspicious(u, known) == all, "%s: suspicious with the reads in hand is the same list" % u.name)
		Unit.end_read()
	ok(v(4).restless() and not v(2).restless() and Perception.cover(b, v(3)) > 0 and b.evaluators(v(3)).size() == 1 and v(4).asleep(), "the field has a restless one, a disturbed living one, a hider, an evaluator and a sleeping one")
	var untagged: Array[String] = []
	for p in DirAccess.get_files_at("res://Behaviours"):
		if not p.ends_with(".gd") or not FileAccess.get_file_as_string("res://Behaviours/" + p).contains("func react("):
			continue
		for f in DirAccess.get_files_at("res://Skills"):
			if f.ends_with(".tres"):
				var st := FileAccess.get_file_as_string("res://Skills/" + f)
				if st.contains("res://Behaviours/" + p) and not st.contains("&\"reaction\""):
					untagged.append(f)
	ok(untagged.is_empty(), "skills whose behaviour reacts carry the reaction tag, or react() never asks them: %s" % [untagged])


# The warm-read floor (docs/plans/w12-warm.md): the shortcuts a read takes answer as their long forms did. has_tag (loops, the tag asked
# before the bar) and emblems over a unit with an item's tag and emblem, a skill off the bar, a toggle off, a form; restless in a stretch (the
# held stat first) and out of it; lends(): false only where the stat is its bare 0 (over several stats and every source of effects: a skill
# off the bar, a status, an item, a property), and a fresh stretch finds an effect put on since. Perception._seem's brood skip rests on
# lends() and persona_test.test_brood holds what it skips.
func test_warm_read_answers_as_before() -> void:
	var badge := Item.new()
	badge.slot = "trinket"
	badge.tags = [&"badge"] as Array[StringName]
	badge.emblem = &"rho_up"
	badge.effects = [effect("brood", 5)] as Array[Effect]
	v(1).learned.append(slot(sk("gallantry")))
	v(2).trinket = badge
	roomy(v(2), 4)
	v(2).learned.append(slot(sk("interject")))
	v(3).tags.append(&"undead")
	v(3).afflict(load("res://Effects/disturbed.tres"), 5)
	v(2).afflict(load("res://Effects/disturbed.tres"), 5)  # disturbed but living: not restless
	v(3).afflict(effect("sleep", 1.0), 5)
	v(4).form = &"mole"
	var units: Array[Unit] = [v(1), v(2), v(3), v(4)]
	for u in units:
		u._arrange()
		for t: StringName in [&"undead", &"reaction", &"martial", &"badge", &"nothing", &"tunneler"]:
			var was: bool = t in u.tags or u.items().any(func(it: Item): return t in it.tags) \
					or u.slots.any(func(x: Slot): return x.rank > 0 and (not x.skill.passive or (x.on and u.equipped(x.skill))) and (t in x.skill.tags or (u.emblems() and t in u.mods(x.skill).tags))) \
					or (u.form != &"" and t in Battle.FORMS[u.form][2])
			ok(u.has_tag(t) == was, "%s: has_tag %s" % [u.name, t])
		ok(u.emblems() == u.items().any(func(it: Item): return it.emblem != &""), "%s: emblems" % u.name)
		var long := u.has_tag(&"undead") and u.disturbed()
		Unit.begin_read()
		ok(u.restless() == long, "%s: restless in a stretch" % u.name)
		Unit.end_read()
		ok(u.restless() == long, "%s: restless out of one" % u.name)
		for st: StringName in [&"brood", &"embellish", &"sleep", &"recon", &"concealment", &"helpless"]:
			Unit.begin_read()
			ok(u.lends(st) or u.stat(st) == 0.0, "%s: no %s lent, none held" % [u.name, st])
			ok(u.lends(st) == u._lends_any(st), "%s: lends %s held is lends found" % [u.name, st])
			Unit.end_read()
	ok(v(2).has_tag(&"badge") and v(2).has_tag(&"martial") and v(3).restless() and not v(2).restless() and v(4).has_tag(&"tunneler"), "the field has an item's tag, a skill on the bar, a restless one, a form")
	ok(v(2).lends(&"brood") and v(3).lends(&"sleep") and not v(1).lends(&"sleep") and not v(3).lends(&"brood"), "an item's effect and a status are lent, nothing else")
	Unit.begin_read()
	ok(not v(1).lends(&"brood"), "none yet")
	Unit.end_read()
	v(1).afflict(effect("brood", 5), 5)
	Unit.begin_read()
	ok(v(1).lends(&"brood"), "a new stretch finds the status put on")
	Unit.end_read()


# A foe's Opportunist (Behaviour.strikes(): its first active at a walker that ends beside it) is priced into a walk (AI._struck(): the
# expected blow x STRUCK, tiles of walking), as _approach() plans it: with the Siren read, it closes on its target from a tile her first active doesn't reach.
func test_approach_weighs_opportunist() -> void:
	var siren: Unit = b.get_node("Units/Siren")
	stage(lancin, {siren: Vector2i(6, 5), v(1): Vector2i(6, 7), v(3): Vector2i(6, 3)})
	siren.faction = nemes
	siren.strength = 40
	siren.refresh()
	soak(v(1), 500)
	sharp(v(1))
	var reads := AI.reads_from({v(3): b.read(v(1), v(3)), siren: b.read(v(1), siren)})
	var strikers := AI._strikers(b, v(1), v(3).cell, 2, reads)
	ok(strikers.size() == 1 and strikers[0][0] == siren, "the Siren's Opportunist is read (%s)" % [strikers.size()])
	var near := Vector2i(6, 4)
	ok(AI._struck(b, v(1), near, strikers) > 0.0 and AI._struck(b, v(1), Vector2i(6, 2), strikers) == 0.0 and v(1).cell == Vector2i(6, 7), "a tile beside her costs the blow; one out of her reach, nothing; the walker is left where it was")
	var plain := AI._approach(b, v(1), v(3), AI.reads_from({v(3): reads[v(3)]}))
	var wary := AI._approach(b, v(1), v(3), reads)
	ok(AI._struck(b, v(1), plain, strikers) > 0.0 and AI._struck(b, v(1), wary, strikers) == 0.0 and Command.tiles(wary, v(3).cell) == 1, "it closes from a side she can't strike: %s, not %s" % [wary, plain])
	var rake: Skill = siren.actives[0]  # free as it is: priced, she can pay for it only with the Energy to
	rake.cost = 3
	var kept := siren.energy
	siren.energy = 0
	ok(AI._struck(b, v(1), near, strikers) == 0.0, "a Siren that cannot pay for her first active strikes no one: nothing to price")
	siren.energy = kept
	ok(AI._struck(b, v(1), near, strikers) > 0.0, "with the Energy for it, she does")
	rake.cost = 0
	siren.faction = lancin
	ok(AI._strikers(b, v(1), v(3).cell, 2, AI.reads_from({v(3): reads[v(3)], siren: b.read(v(1), siren)})).is_empty(), "an ally's reaction is none to weigh")
	# the other walks: backing off and lining up end beside her reaction too
	stage(lancin, {siren: Vector2i(6, 5), v(1): Vector2i(6, 7), v(3): Vector2i(6, 9)})
	v(1).moved = v(1).stat(&"movement") - 2.0  # two tiles of walk left: the furthest it can get from v(3) is a row beside her
	siren.faction = nemes
	var from: Array[Vector2i] = [v(3).cell]
	var wide := AI.reads_from({v(3): b.read(v(1), v(3)), siren: b.read(v(1), siren)})
	var cells := b.cells_near(v(1).cell, ceili(v(1).move_left()))
	var beside := cells.filter(func(c: Vector2i): return AI._struck(b, v(1), c, AI._strikers(b, v(1), v(1).cell, 9, wide)) > 0.0)
	ok(not beside.is_empty(), "(setup) tiles in the walk lie in her reach")
	var blind := AI._retreat(b, v(1), from)
	ok(blind in beside and AI._retreat(b, v(1), from, 0, wide) not in beside, "backing off, it does not end where she strikes: %s, not %s" % [AI._retreat(b, v(1), from, 0, wide), blind])
	v(1).learned.append(slot(kick, 2))  # test_lines_up_a_shove's scene: the slam tile (5, 3) lies beside her at (5, 2)
	roomy(v(1))
	v(1).strength = 40
	stage(lancin, {v(1): Vector2i(4, 4), v(3): Vector2i(5, 4), v(4): Vector2i(5, 5), siren: Vector2i(5, 2)})
	v(4).faction = nemes
	v(1).refresh()
	soak(v(3), 300)
	var log: Array[String] = []
	ok(not AI._line_up(b, v(1), AI.reads_from({v(3): b.read(v(1), v(3)), v(4): b.read(v(1), v(4)), siren: b.read(v(1), siren)}), log) and v(1).cell == Vector2i(4, 4), "lining up, it stays out of her reach rather than take her blow for the slam (%s)" % [v(1).cell])
	ok(AI._line_up(b, v(1), AI.reads_from({v(3): b.read(v(1), v(3)), v(4): b.read(v(1), v(4))}), log) and v(1).cell == Vector2i(5, 3), "not reading her, it takes the tile (%s)" % [v(1).cell])
	siren.faction = lancin


# A calm follower of a skilled leader drills (AI._calm(), _drill()): no preferences weighed, so a stoic one
# still closes in; anything out of the way and it takes a full turn by its temper again.
func test_calm_followers_drill() -> void:
	stage(nemes, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 2), v(4): Vector2i(9, 2)})
	var lead := v(3)
	var u := v(4)
	lead.charisma = 14
	u.follows = lead
	u.bio = Bio.new()
	u.bio.behaviour = &"stoic"
	ok(AI._calm(b, u), "a follower in reach of a skilled leader it sees: calm")
	ok(not AI._calm(b, lead), "the leader itself follows no one")
	var cc := effect("nothing", 0.0)
	cc.bears = [&"cc"] as Array[StringName]
	var cases := {
		"an unskilled leader (cha +0)": [func(): lead.charisma = 10, func(): lead.charisma = 14],
		"hurt since its last turn": [func(): u.hp -= 1, func(): u.hp += 1],
		"cc'd": [func(): u.afflict(cc, 2), func(): u.timed.erase(cc)],
		"its leader down": [func(): lead.hp = 0, func(): lead.hp = lead.max_hp],
		"its leader out of reach": [func(): b.move(lead, Vector2i(1, 9)), func(): b.move(lead, Vector2i(8, 2))],
		"struck by its leader": [func(): u.last_hit_by = lead, func(): u.last_hit_by = null],
		"Restless": [func(): u.tags.append(&"undead"); u.afflict(load("res://Effects/disturbed.tres"), 2), func(): u.tags.erase(&"undead"); u.timed.clear()],
	}
	for why: String in cases:
		cases[why][0].call()
		ok(not AI._calm(b, u), "not calm: %s" % why)
		cases[why][1].call()
		ok(AI._calm(b, u), "calm again after: %s" % why)
	AI.act(b, u)
	ok(u.cell != Vector2i(9, 2), "calm, the stoic follower drills: it closes in")
	b.move(u, Vector2i(9, 2))
	u.refresh()
	u.hp -= 1
	AI.act(b, u)
	ok(u.cell == Vector2i(9, 2), "hurt, it takes a full turn by its temper: it holds")
	b.lazy_looks = true  # watched (HUD): a side's opening looks wait for the turn change's frames, or for each to act
	b.turn = lancin
	b.turn = nemes
	ok(lead in b._to_look and u in b._to_look, "watched: the side's opening looks are owed")
	AI.act(b, u)
	ok(u not in b._to_look and lead in b._to_look, "a unit takes its own as it acts")
	b.lazy_looks = false

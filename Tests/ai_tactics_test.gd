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
var kick: Skill = load("res://Skills/kick.tres")
var heal: Skill = load("res://Skills/heal.tres")
var resuscitate: Skill = load("res://Skills/resuscitate.tres")
var grudge: Skill = load("res://Skills/grudge.tres")
var focus: Skill = load("res://Skills/focus.tres")
var focus_pool: Reserve = load("res://Reserves/focus.tres")
var missile: Skill = load("res://Skills/energy_missile.tres")


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
	var reads := {v(3): b.read(v(1), v(3)), v(4): b.read(v(1), v(4))}
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
	ok(is_equal_approx(js.riders, odds) and odds > 0.0 and odds < 1.0, "Slam Jam's interrupt is a rider as likely as its contest (%.2f)" % js.riders)


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
	var reads := {v(3): b.read(v(1), v(3))}
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
	var reads := {v(3): b.read(v(1), v(3))}
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
	for i in 40:
		v(1).exhaustion.used(other)
	v(1).ap = [AP.new(100.0, &"")]
	ok(AI._strike(b, v(1), reads, []), "both worn: a worn blow is still better than none")
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
	AI._support(b, v(1), {v(2): b.read(v(1), v(2))}, log)
	ok(log.is_empty(), "and a support skill carrying fear isn't given to an ally (%s)" % [log])
	buff.effects = [effect("mitigate", 0.2)] as Array[Effect]
	AI._support(b, v(1), {v(2): b.read(v(1), v(2))}, log)
	ok(not log.is_empty(), "though one that helps is (%s)" % [log])

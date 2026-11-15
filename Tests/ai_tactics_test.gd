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
	v(1).learned.append(slot(spike))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
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
	v(1).learned.append(slot(sutemi, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).refresh()
	soak(v(3), 300)
	var beside := score(v(1), sutemi, v(3))
	b.move(v(1), Vector2i(2, 3))
	var far := score(v(1), sutemi, v(3))
	ok(is_equal_approx(beside - far, AI.DEFENSE * 2.0), "lunging 2 tiles costs it Defense 2: %.2f less than beside it (%.2f vs %.2f)" % [beside - far, beside, far])
	ok(sutemi.behaviours[0].unguarded(b.cast_of(v(1), sutemi, v(3), 2, true)) == 2, "the hook: 2")


func test_refunds() -> void:
	v(1).learned.append(slot(poach))
	v(1).learned.append(slot(slam_jam))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
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
	ok(b.foresee(u, kick, v(3)).notes == ["Drives it 2 tiles back"], "a hole: 2 tiles back")
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

extends Test

# What the AI does with the skills it used to ignore (Scripts/AI.gd; docs/plans/ai-support.md): it heals,
# rescues and refills from what a skill's behaviours declare they restore (Behaviour.restores()); it
# buffs an ally with Intervention; it switches Mana and Stamina when what it runs on can pay for nothing
# it wants and the other can; it rests to build Focus with nothing to shoot; it casts Clairvoyance when
# it has nothing to go on.

var heal: Skill = load("res://Skills/heal.tres")
var megaheal: Skill = load("res://Skills/megaheal.tres")
var energize: Skill = load("res://Skills/energize.tres")
var resuscitate: Skill = load("res://Skills/resuscitate.tres")
var intervention: Skill = load("res://Skills/intervention.tres")
var tenacity: Skill = load("res://Skills/tenacity.tres")
var mana_skill: Skill = load("res://Skills/mana.tres")
var mana: Reserve = load("res://Reserves/mana.tres")
var stamina: Skill = load("res://Skills/stamina.tres")
var stamina_pool: Reserve = load("res://Reserves/stamina.tres")
var crushing: Skill = load("res://Skills/crushing_blow.tres")
var focus: Skill = load("res://Skills/focus.tres")
var focus_pool: Reserve = load("res://Reserves/focus.tres")
var missile: Skill = load("res://Skills/energy_missile.tres")
var clairvoyance: Skill = load("res://Skills/clairvoyance.tres")


func test_declared() -> void:
	v(1).learned.append(slot(heal, 2))
	v(1).learned.append(slot(megaheal, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3)})
	ok(not heal.heals(), "Skill.heals() doesn't know Heal: the behaviours say what it restores")
	var got := AI._restores(b, v(1), heal, v(2))
	ok(got.has(&"hp") and got[&"hp"] >= 3 * 4 + 2, "Heal II restores HP, about 3d8 + mod + 2 (%s)" % [got])
	ok(AI._restores(b, v(1), megaheal, v(2))[&"hp"] > got[&"hp"], "Megaheal more")
	ok(AI._restores(b, v(1), energize, v(1)).has(&"energy") and AI._mends(b, v(1), heal) and not AI._mends(b, v(1), energize), "Energize restores Energy, not HP")


func test_heals() -> void:
	for s in [heal, megaheal]:
		v(1).learned.append(slot(s, 2))
		v(1).refresh()
		v(1).energy = v(1).max_energy
		stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(8, 6)})
		v(2).max_hp = 100
		v(2).hp = 40
		var log := AI.act(b, v(1))
		ok(v(2).hp > 40, "%s: the wounded ally is healed (%d, %s)" % [s.name, v(2).hp, ", ".join(log)])
		v(1).learned.clear()


func test_energizes() -> void:
	v(1).learned.append(slot(energize, 2))
	v(1).refresh()
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 6)})
	v(1).max_energy = 10
	v(1).energy = 3
	var log := AI.act(b, v(1))
	ok(v(1).energy > 3, "low on Energy, spare AP: Energize (%d, %s)" % [v(1).energy, ", ".join(log)])
	v(1).refresh()
	v(1).energy = 9
	AI.act(b, v(1))
	ok(v(1).energy == 9, "plenty of Energy: it doesn't")


func test_resuscitates() -> void:
	v(1).learned.append(slot(resuscitate, 1))
	v(2).learned.append(slot(tenacity, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(8, 6)})
	v(1).refresh()
	v(2).max_hp = 100
	v(2).hp = 100
	AI.act(b, v(1))
	ok(v(1).energy == v(1).max_energy, "a standing ally: nothing is spent")
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(5, 3), v(3): Vector2i(8, 6)})
	v(2).damage(100)
	v(2).damage(20)
	ok(v(2).dbno != null, "Downed")
	var log := AI.act(b, v(1))
	ok(v(2).dbno == null and v(2).hp > 0, "the Downed ally beside it is brought back up (%d, %s)" % [v(2).hp, ", ".join(log)])


func test_intervenes() -> void:
	v(1).learned.append(slot(intervention, 3))
	stage(lancin, {v(1): Vector2i(4, 3), v(2): Vector2i(6, 3), v(3): Vector2i(8, 6)})
	v(1).refresh()
	var log := AI.act(b, v(1))
	ok(v(2).timed.keys().filter(func(e: Effect): return e.name == "Bless").size() == 3, "an ally in reach gets Bless (%s)" % ", ".join(log))
	for i in 2:  # it blesses itself too, and then has none left to give
		v(1).refresh()
		AI.act(b, v(1))
	v(1).refresh()
	var spent := v(1).energy
	AI.act(b, v(1))
	ok(v(1).energy == spent, "and not again while they have it")


# A Wizard with Mana and Stamina, Mana empty, Stamina full, a martial skill only Stamina pays for.
func two_reserves() -> Unit:
	var u: Unit = b.get_node("Units/Icor")
	u.learned.append(slot(stamina))
	u.learned.append(slot(crushing))
	u.constitution = 14
	u._one_replacer()
	u.refresh()
	stage(nemes, {u: Vector2i(1, 2), v(1): Vector2i(8, 6)})
	u.set_store(stamina_pool, u.pools()[stamina_pool])
	return u


func test_switches() -> void:
	var u := two_reserves()
	u.set_store(mana, 0)
	ok(u.runs_on() == mana and not u.can_afford(crushing), "running on empty Mana, a martial skill it can't pay for")
	var log := AI.act(b, u)
	ok(u.switching() == stamina_pool and u.cell == Vector2i(1, 2), "it begins switching to Stamina and holds still (%s)" % ", ".join(log))
	AI.act(b, u)
	ok(u.channel == null and u.runs_on() == stamina_pool, "and finishes it next turn")


func test_doesnt_switch() -> void:
	var u := two_reserves()
	AI.act(b, u)
	ok(u.switching() == null and u.runs_on() == mana, "Mana full: it stays on it")
	u.set_store(mana, 0)
	stage(nemes, {u: Vector2i(1, 2), v(2): Vector2i(2, 2)})
	u.refresh()
	AI.act(b, u)
	ok(u.switching() == null and u.runs_on() == mana, "a foe beside it, it strikes instead")
	u.learned.erase(u.learned.filter(func(x: Slot): return x.skill == stamina)[0])
	u.refresh()
	stage(nemes, {u: Vector2i(1, 2), v(2): Vector2i(8, 6)})
	AI.act(b, u)
	ok(u.switching() == null, "nothing else to run on that holds anything: it stays")


func focused(store: int) -> Unit:
	v(1).learned.append(slot(focus, 1))
	v(1).learned.append(slot(missile))
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(8, 6)})
	v(1).refresh()
	v(1).set_store(focus_pool, store)
	return v(1)


func test_rests_for_focus() -> void:
	var u := focused(0)
	var log := AI.act(b, u)
	ok(u.cell == Vector2i(1, 2) and u.idle() and u.activity() == &"rest", "no foe in reach, Focus empty: it rests where it stands (%s)" % ", ".join(log))
	b.end_turn()
	ok(u.store(focus_pool) > 0, "and Focus builds (%d)" % u.store(focus_pool))
	stage(lancin, {u: Vector2i(1, 2), v(3): Vector2i(8, 6)})
	u.refresh()
	u.set_store(focus_pool, u.pools()[focus_pool])
	AI.act(b, u)
	ok(u.cell != Vector2i(1, 2), "Focus full: it goes after the foe")


func test_shoots_without_waiting() -> void:
	var u := focused(0)
	stage(lancin, {u: Vector2i(5, 3), v(3): Vector2i(7, 3)})
	var log := AI.act(b, u)
	ok(log.any(func(l: String): return "uses Energy Missile" in l), "a foe in reach: it shoots, without waiting")


func test_shot_with_the_last_of_focus() -> void:
	var u := focused(1)  # one point: Energy Missile costs 1
	stage(lancin, {u: Vector2i(5, 3), v(3): Vector2i(7, 3)})
	AI.act(b, u)
	ok(u.store(focus_pool) == 0, "it shoots with the Focus it has: to its last point")


func test_scries() -> void:
	v(1).learned.append(slot(clairvoyance, 1))
	v(1).refresh()
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(7, 2)})
	b.sightings.clear()
	v(3).afflict(effect("concealment", 9), 99)
	var log := AI.act(b, v(1))
	ok(v(1).channel != null and v(1).channel.skill == clairvoyance, "no foe in sight, nothing to go on: Clairvoyance (%s)" % ", ".join(log))
	AI.act(b, v(1))
	ok(v(1).channel == null or v(1).channel.skill == clairvoyance, "and next turn it acts on what it sensed, not stuck holding it")
	stage(lancin, {v(1): Vector2i(1, 2), v(3): Vector2i(7, 2)})
	b.end_channel(v(1))
	v(1).refresh()
	AI.act(b, v(1))
	ok(v(1).channel == null, "a foe it sees: it doesn't")

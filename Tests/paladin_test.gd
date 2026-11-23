extends Test

# The Paladin's tree - Idealism: Chivalry on its own tab, and three slots its god fills (God.pool,
# TreeChoice.kinds): a Prowess, a Domain (Divinity: Eros, opened with no pick when its god offers just
# the one) and a Flex (Unit.pick(), Unit.offered(), Unit.class_trees()) - and Eros's
# skills on it: Rejuvinate (regeneration whose strength falls with distance, set as it's cast:
# Battle.decay(), Unit.Applied.scale), Send Off (a teleport away: Battle.send()), Lovely Caster
# (Battle._lovely()) and Impassioned Fighter (Battle.passion()).

var paladin: Role = load("res://Roles/paladin.tres")
var rejuvinate: Skill = load("res://Skills/rejuvinate.tres")
var send_off: Skill = load("res://Skills/send_off.tres")
var lovely: Skill = load("res://Skills/lovely_caster.tres")
var impassioned: Skill = load("res://Skills/impassioned_fighter.tres")
var mana: Reserve = load("res://Reserves/mana.tres")


func test_tree() -> void:
	ok(paladin.roots.map(func(r: SkillRoot): return r.name) == ["Idealism: Chivalry"], "Idealism on its own tab")
	ok(paladin.choices.map(func(c: TreeChoice): return [c.name, c.kinds, c.picks]) == [["Prowess", ["Prowess"], 1], ["Domain", ["Divinity"], 1],
			["Flex", ["Prowess", "Divinity", "School"], 1]], "three slots: a prowess, a domain and a flex")
	var prowess: TreeChoice = paladin.choices[0]
	ok(prowess.all().size() >= 2 and prowess.all().all(func(t: SkillTab): return t.title().begins_with("Prowess: ")), "every prowess a god offers (%s)" % [prowess.all().map(func(t: SkillTab): return t.title())])
	ok(paladin_tab(prowess, "Protector").roots[0] == load("res://Roles/fighter.tres").roots[0] and paladin_tab(prowess, "Brawn").roots[0] == load("res://Roles/berserker.tres").tabs[0].roots[0],
			"the same Protector root as the Fighter's, the same Brawn as the Berserker's")
	ok(paladin.root_of(load("res://Skills/renew.tres")).tag == &"magical" and paladin.root_of(load("res://Skills/coordinate.tres")).tag == &"specialist",
			"Renew on Divinity, Coordinate on Idealism")
	ok(paladin.tier(rejuvinate) > 0 and [send_off, lovely, impassioned].all(func(s: Skill): return paladin.tier(s) > paladin.tier(rejuvinate)), "Rejuvinate opens Eros's path")
	ok(load("res://Skills/final_act.tres").stub == "" and load("res://Skills/gallantry.tres").stub == "" and paladin.tier(load("res://Skills/final_act.tres")) > paladin.tier(load("res://Skills/coordinate.tres"))
			and paladin.tier(load("res://Skills/gallantry.tres")) > paladin.tier(load("res://Skills/coordinate.tres")), "Final Act and Gallantry built (Reactions), after Coordinate")
	for s in [rejuvinate, send_off, lovely, impassioned]:
		ok(s.stub == "" and s.describe(2) != "", "%s is built: %s" % [s.name, s.describe(2)])


func paladin_tab(c: TreeChoice, n: String) -> SkillTab:
	return c.all().filter(func(t: SkillTab): return t.name == n)[0]


func prowess_tabs(u: Unit) -> Array:
	return u.class_trees().filter(func(t: SkillTab): return t.kind == "Prowess").map(func(t: SkillTab): return t.name)


# The Prowess trees it's offered: those that suit its god.
func offered(u: Unit) -> Array:
	return u.offered(paladin.choices[0]).map(func(t: SkillTab): return t.name)


func prowess(n: String) -> SkillTab:
	return paladin_tab(paladin.choices[0], n)


# Any prowess somewhat aligned with its god: Eros's are Protector and Vanguard; one taken up closes the rest.
func test_prowess() -> void:
	var u := b.starter({faction = lancin, role = paladin, name = "Pip"})
	b.get_node("Units").add_child(u)
	u.skill_points = 5
	var choice: TreeChoice = paladin.choices[0]
	ok(offered(u) == ["Protector", "Vanguard"], "Eros's ways: Protector and Vanguard (%s)" % [offered(u)])
	ok(prowess_tabs(u).is_empty() and u.missing(sk("shields_up")) == "Pick Prowess: Protector first", "no Prowess tab until it's picked")
	ok(u.pick_missing(choice, prowess("Brawn")) == "Not Eros's way" and u.pick_missing(choice, prowess("Slayer")) == "Not Eros's way", "Brawn and Slayer aren't (%s)" % u.pick_missing(choice, prowess("Brawn")))
	ok(u.pick(choice, prowess("Protector")) and prowess_tabs(u) == ["Protector"] and u.unlock(sk("shields_up")), "Protector picked: its tab opens, Shields Up!")
	ok(u.pick_missing(choice, prowess("Vanguard")) == "Took up Prowess: Protector" and not u.pick(choice, prowess("Vanguard")), "one Prowess")
	var war := b.starter({faction = lancin, role = paladin, name = "Ram"})
	b.get_node("Units").add_child(war)
	war.god = &"ramut"
	war.skill_points = 5
	ok(offered(war) == ["Havoc", "Slayer", "Vanguard", "Brawn", "Fury"], "Ramut's: all but Protector (%s)" % [offered(war)])
	ok(war.pick(choice, prowess("Brawn")) and war.unlock(sk("bulwark")) and war.missing(sk("second_wind")) == "Pick Prowess: Fury first" and war.missing(sk("crushing_blow")) == "",
			"Brawn picked: Fury stays shut, Brawn goes on (%s)" % war.missing(sk("second_wind")))
	var fighter := b.starter({faction = lancin, role = load("res://Roles/fighter.tres"), name = "Fen"})
	b.get_node("Units").add_child(fighter)
	fighter.skill_points = 5
	ok(fighter.unlock(sk("shields_up")) and not fighter.missing(sk("jugular")).begins_with("Took"), "a Fighter's roots aren't a choice")


# Mitigation and damage reduction serve DEFEND (Skill.serves): Bulwark, Hydera and Terestera too, still
# attacking and helping as they did.
func test_mitigation_defends() -> void:
	for n in ["bulwark", "flamecharm", "flamedance", "hydera", "terestera", "shields_up"]:
		ok(sk(n).serves(&"defensive"), "%s serves DEFEND" % n)
	ok(sk("hydera").serves(&"offensive") and sk("hydera").serves(&"supportive"), "Hydera still attacks and supports")
	for n in ["stoneskin", "mage_armor", "favour", "wary", "conspire", "flamecharmed"]:
		ok(&"defensive" in sk(n).tags, "%s is tagged defensive" % n)
	ok(not sk("frenzy").serves(&"defensive"), "Frenzy drops its guard: offensive only")


# A Paladin with cha 16 (mod 3), beside v(1) at (4, 3), with skill s at rank r.
func pally(s: Skill, r := 1) -> Unit:
	var u := b.starter({faction = lancin, role = paladin, name = "Pip"})
	b.get_node("Units").add_child(u)
	stage(lancin, {u: Vector2i(3, 3), v(1): Vector2i(4, 3), v(3): Vector2i(8, 5)})
	u.charisma = 16
	u.learned.append(slot(s, r)); u.sync_bar()
	u.energy = u.max_energy
	u.refresh()
	return u


func test_rejuvinate() -> void:
	var u := pally(rejuvinate, 1)
	v(1).max_hp = 100
	v(1).hp = 50
	ok(b.cast(u, rejuvinate, v(1)), "on an adjacent ally")
	ok(v(1).hp == 50, "nothing at once: it's regeneration")
	ok(is_equal_approx(v(1).stat(&"regen"), 0.15) and is_equal_approx(v(1).stat(&"regen_hp"), 3.0), "10% + 5% a rank of max HP a turn, + the caster's cha mod")
	b._mend(v(1))
	ok(v(1).hp == 68, "as its turn starts: 15 + 3 (%d)" % v(1).hp)
	ok(v(1).timed[rejuvinate.effects[0]].turns == 4, "for 3 of its turns (put on during its own side's turn: one more)")


func test_rejuvinate_decays() -> void:
	var u := pally(rejuvinate, 3)
	stage(lancin, {u: Vector2i(1, 3), v(1): Vector2i(4, 3)})
	ok(is_equal_approx(b.decay(u, rejuvinate, v(1)), 0.9), "3 tiles off: 5% less a tile past the first")
	ok(b.cast(u, rejuvinate, v(1)), "rank III reaches 3 tiles")
	ok(is_equal_approx(v(1).stat(&"regen"), 0.25 * 0.9) and is_equal_approx(v(1).stat(&"regen_hp"), 3.0 * 0.9), "everything it does, 10% weaker")
	stage(lancin, {u: Vector2i(1, 3), v(1): Vector2i(4, 3)})
	ok(is_equal_approx(v(1).stat(&"regen"), 0.25 * 0.9), "set as it was cast: moving doesn't change it")
	u.reserves[mana] = 20
	u.set_store(mana, 20)
	ok(u.funding(rejuvinate) == mana and is_equal_approx(b.decay(u, rejuvinate, v(1)), 1.0), "paid wholly with mana: no decay")


# Any skill's `decays` (Skill.decays) reaches every effect it puts on, whichever way it puts it: its own
# effects (above), a behaviour's (Cast.put(): Stun's), an aura's (Aura: its share times what's left).
func test_decay_reaches_behaviours() -> void:
	var stun: Skill = load("res://Skills/stun.tres").duplicate()
	stun.decays = 0.1
	stun.radius = 3.0  # (reach for the distance)
	var stunned: Effect = load("res://Effects/stunned.tres")
	v(1).learned.append(slot(stun, 3)); v(1).sync_bar()
	v(1).strength = 40
	stage(lancin, {v(1): Vector2i(1, 3), v(3): Vector2i(3, 3)})
	v(1).refresh()
	v(3).constitution = 1
	soak(v(3), 300)
	ok(b.cast(v(1), stun, v(3)) and stunned in v(3).timed, "a Stun, 2 tiles off, lands")
	ok(is_equal_approx(v(3).timed[stunned].scale, 0.9), "what the behaviour put on is 10%% weaker: scale %s" % v(3).timed[stunned].scale)
	var flamecharm: Skill = load("res://Skills/flamecharm.tres").duplicate()
	flamecharm.decays = 0.1
	var c := Behaviour.Cast.new()
	c.battle = b
	c.caster = v(1)
	c.target = v(1)
	c.skill = flamecharm
	c.rank = 1
	c.strength = 0.5
	flamecharm.behaviours[0].apply(c)
	ok(is_equal_approx(v(1).timed[flamecharm.effects[0]].scale, 0.5), "an aura's own: its share (1) x what's left (0.5): %s" % v(1).timed[flamecharm.effects[0]].scale)


func test_send_off() -> void:
	var u := pally(send_off, 2)
	var from := v(1).cell
	ok(b.cast(u, send_off, v(1)), "on an adjacent ally")
	ok(v(1).cell.y == from.y and v(1).cell.x > from.x + 1 and v(1).cell.x <= from.x + 5, "teleported straight away: up to cha mod 3 + rank 2 tiles (%s)" % v(1).cell)
	ok(b.unit_at(v(1).cell) == v(1) and b.unit_at(from) == null, "really there, and gone from where it was")
	stage(lancin, {u: Vector2i(3, 3), v(1): Vector2i(4, 3), v(4): Vector2i(7, 3)})
	ok(b.send(v(1), u, 3) and v(1).cell == Vector2i(6, 3), "a unit in the way: the furthest free tile short of it (%s)" % v(1).cell)


func test_lovely_caster() -> void:
	var u := pally(lovely, 2)
	u.learned.append(slot(rejuvinate, 3)); u.sync_bar()
	u.refresh()
	v(1).max_hp = 100
	v(1).hp = 50
	b.cast(u, rejuvinate, v(1))
	ok(v(1).hp == 70, "a love skill on an adjacent ally: 20%% of its max HP at once, Lovely Caster at rank II (%d)" % v(1).hp)
	stage(lancin, {u: Vector2i(3, 3), v(1): Vector2i(3, 5)})
	u.refresh()
	u.energy = u.max_energy
	var hp := v(1).hp  # the turn started over: its regeneration has ticked
	ok(b.cast(u, rejuvinate, v(1)) and v(1).hp == hp, "2 tiles off, in Rejuvinate's reach but not adjacent: nothing at once")
	var renew: Skill = load("res://Skills/renew.tres")
	ok(&"love" not in Battle.hit_tags(u, renew), "Renew isn't a love skill")


func test_impassioned_fighter() -> void:
	var u := pally(impassioned, 3)
	ok(Battle.passion(u, v(1)) == 3 and Battle.passion(u, u) == 0, "+rank on an adjacent unit")
	stage(lancin, {u: Vector2i(3, 3), v(3): Vector2i(4, 3), v(1): Vector2i(6, 3)})
	ok(Battle.passion(u, v(1)) == 0, "not beside it: nothing")
	v(3).armor = bulwark()
	u.weapon = null
	var with := Battle.hit_chance(u, strike, v(3))
	u.learned.clear(); u.sync_bar()
	ok(with > Battle.hit_chance(u, strike, v(3)), "Strike's roll, beside its target")
	u.learned.append(slot(impassioned, 3)); u.sync_bar()
	var totals := []
	b.attacked.connect(func(_c, _t, d20, total, _def): totals.append(total - d20))
	u.refresh()
	b.cast(u, strike, v(3))
	ok(not totals.is_empty() and totals[0] == u.attack_mod(strike) + u.check_bonus(&"strength", &"offensive") + 3, "+3 on the roll (%s)" % [totals])

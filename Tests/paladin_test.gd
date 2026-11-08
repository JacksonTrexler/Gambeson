extends Test

# The Paladin's tree - Divinity: Eros, Idealism: Chivalry, and a Prowess of its choosing that suits its
# god (SkillTab.one_of, SkillRoot.gods: Unit.taken(), Unit.suits(), Unit.class_trees()) - and Eros's
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
	ok(paladin.roots.map(func(r: SkillRoot): return r.name) == ["Divinity: Eros", "Idealism: Chivalry"], "Divinity and Idealism on its own tab")
	ok(paladin.tabs.map(func(t: SkillTab): return t.title()) == ["Prowess: Protector", "Prowess: Vanguard", "Prowess: Brawn", "Prowess: Fury",
			"Prowess: Havoc", "Prowess: Slayer"] and paladin.tabs.all(func(t: SkillTab): return t.one_of == &"prowess"), "a Prowess tab for each, one to choose")
	ok(paladin.tabs[0].roots[0] == load("res://Roles/fighter.tres").roots[0] and paladin.tabs[2].roots[0] == load("res://Roles/berserker.tres").tabs[0].roots[0],
			"the same Protector root as the Fighter's, the same Brawn as the Berserker's")
	ok(paladin.root_of(load("res://Skills/renew.tres")).tag == &"magical" and paladin.root_of(load("res://Skills/coordinate.tres")).tag == &"specialist",
			"Renew on Divinity, Coordinate on Idealism")
	ok(paladin.tier(rejuvinate) == 1 and paladin.tier(send_off) == 2 and paladin.tier(lovely) == 2 and paladin.tier(impassioned) == 2, "Rejuvinate opens Eros's path")
	ok(load("res://Skills/final_act.tres").stub == "?12" and load("res://Skills/gallantry.tres").stub.begins_with("Reactions"), "Final Act and Gallantry wait")
	for s in [rejuvinate, send_off, lovely, impassioned]:
		ok(s.stub == "" and s.describe(2) != "", "%s is built: %s" % [s.name, s.describe(2)])


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func prowess_tabs(u: Unit) -> Array:
	return u.class_trees().filter(func(t: SkillTab): return t.one_of).map(func(t: SkillTab): return t.name)


# Any prowess somewhat aligned with its god: Eros's are Protector and Vanguard; one taken up closes the rest.
func test_prowess() -> void:
	var u := b.starter({faction = lancin, role = paladin, name = "Pip"})
	b.get_node("Units").add_child(u)
	u.skill_points = 5
	ok(prowess_tabs(u) == ["Protector", "Vanguard"], "Eros's ways: Protector and Vanguard (%s)" % [prowess_tabs(u)])
	ok(u.missing(sk("shields_up")) == "", "Protector is open")
	ok(u.missing(sk("bulwark")) == "Not Eros's way" and u.missing(sk("jugular")) == "Not Eros's way", "Brawn and Slayer aren't (%s)" % u.missing(sk("bulwark")))
	ok(u.unlock(sk("shields_up")) and prowess_tabs(u) == ["Protector"], "Shields Up! takes up Protector: the other tabs go")
	var war := b.starter({faction = lancin, role = paladin, name = "Ram"})
	b.get_node("Units").add_child(war)
	war.god = &"ramut"
	war.skill_points = 5
	ok(prowess_tabs(war) == ["Vanguard", "Brawn", "Fury", "Havoc", "Slayer"], "Ramut's: all but Protector (%s)" % [prowess_tabs(war)])
	ok(war.unlock(sk("bulwark")) and war.missing(sk("second_wind")) == "Took up Prowess: Brawn" and war.missing(sk("crushing_blow")) == "",
			"Bulwark takes up Brawn: Fury closes, Brawn goes on (%s)" % war.missing(sk("second_wind")))
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
	u.learned.append(slot(s, r))
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
	u.learned.append(slot(rejuvinate, 3))
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
	u.learned.clear()
	ok(with > Battle.hit_chance(u, strike, v(3)), "Strike's roll, beside its target")
	u.learned.append(slot(impassioned, 3))
	var totals := []
	b.attacked.connect(func(_c, _t, d20, total, _def): totals.append(total - d20))
	u.refresh()
	b.cast(u, strike, v(3))
	ok(not totals.is_empty() and totals[0] == u.attack_mod(strike) + u.check_bonus(&"strength", &"offensive") + 3, "+3 on the roll (%s)" % [totals])

extends Test

# The Monster class (Roles/monster.tres): one Path picked at level 1 (TreeChoice.free), its traits learned
# free at rank I (Unit.take_free()), ranked past I with skill points; pre-selected by a pick set beforehand
# (Unit.monster(), a scene's picked) or by a path's trait the unit was made with.

const PATHS := {"Starmen": ["floaty", "hop"], "Sirens": ["alluring", "seaborn", "opportunist"], "Skeletons": ["undead"]}


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func traits() -> Array:
	var out := []
	for p in PATHS:
		out.append_array(PATHS[p].map(sk))
	return out


func held(u: Unit) -> Array:
	return traits().filter(func(s: Skill): return u.own_rank(s) > 0).map(func(s: Skill): return s.resource_path.get_file().get_basename())


func path(u: Unit) -> TreeChoice:
	return u.role.choices[0]


# Each path at level 3 (Unit.monster(): Thesis of Theseus's hook): its traits, no others, at rank I for no points; the
# other paths shut; a rank past I costs skill points; saved and loaded without doubling.
func test_paths() -> void:
	for p in PATHS:
		var u := Unit.monster(lancin, p, 3)
		u.path_auto = false  # unspent, as a player's: test_ai covers the spending
		b.get_node("Units").add_child(u)
		roomy(u, 8)
		ok(u.role.name == "Monster" and u.level == 3 and u.skill_points == 2, "%s: a level 3 Monster, 2 points to spend" % p)
		ok(held(u) == PATHS[p] and PATHS[p].all(func(id: String): return u.rank(sk(id)) == 1), "%s: its traits %s, free at rank I (holds %s)" % [p, PATHS[p], held(u)])
		var c := path(u)
		ok(u.picks(c).map(func(t: SkillTab): return t.name) == [p] and u.free_due() == 0, "%s: the one path taken" % p)
		for o in PATHS:
			if o != p:
				var t: SkillTab = c.tabs.filter(func(x: SkillTab): return x.name == o)[0]
				ok(not u.pick(c, t) and u.pick_missing(c, t) == "Took up Path: %s" % p and not u.open_tab(t), "%s: %s can't be taken too (%s)" % [p, o, u.pick_missing(c, t)])
		var first := sk(PATHS[p][0])
		ok(u.raise_cost(first) == 2 and u.raise(first) and u.rank(first) == 2 and u.skill_points == 0, "%s: %s to rank II for 2 points" % [p, first.name])
		var back := Battle.from_role(lancin, u.role, "back")
		back.from_dict(u.to_dict())
		b.get_node("Units").add_child(back)
		ok(held(back) == PATHS[p] and back.rank(first) == 2 and back.skill_points == 0
				and back.learned.filter(func(x: Slot): return x.skill == first).size() == 1, "%s: saved and loaded, rank II kept, nothing doubled" % p)
	ok(Unit.monster(lancin, "Wizards") == null, "no such path: null")


# A Monster made from its class picks its path at level 1 (its skills badge owes it); one made with a path's trait
# has that path pre-selected, and the rest of its traits come free.
func test_pick() -> void:
	var u := b.starter({faction = lancin, role = load("res://Roles/monster.tres"), name = "Mon"})
	b.get_node("Units").add_child(u)
	ok(u.free_due() == 1 and held(u).is_empty(), "no path yet: one to pick, no traits")
	var sirens: SkillTab = path(u).tabs[1]
	ok(u.pick(path(u), sirens) and held(u) == PATHS["Sirens"] and u.skill_points == 0 and u.free_due() == 0, "picking Sirens at level 1: its traits, no points spent")
	ok(u.equipped(sk("alluring")) and sk("seaborn") in u.traits(), "its traits on, at once")
	var m := Battle.from_role(lancin, load("res://Roles/monster.tres"), "Mote")
	var x := Slot.new()
	x.skill = sk("floaty")
	m.learned.append(x)
	b.get_node("Units").add_child(m)
	ok(path(m).key(path(m).tabs[0]) not in m.picked and held(m) == PATHS["Starmen"], "made with Floaty: Starmen pre-selected, Hop free (holds %s)" % [held(m)])


<<<<<<< HEAD
# An NPC's (bio) or summoned Monster takes the path its side holds fewest of and spends level - 1 points on its traits,
# cheapest first (Unit.take_path()); a player's Monster does neither. Rows: path pre-picked or "" , level.
func test_ai() -> void:
	var role: Role = load("res://Roles/monster.tres")
	for row in [["Starmen", 1], ["Sirens", 5], ["Skeletons", 5], ["Starmen", 8], ["", 1], ["", 5]]:
		var u: Unit = b.from_role(lancin, role, "npc")
		u.bio = Bio.new()
		u.level = row[1]
		if row[0]:
			u.picked.append(path(u).key(path(u).tabs.filter(func(t: SkillTab): return t.name == row[0])[0]))
		b.get_node("Units").add_child(u)
		roomy(u, 8)
		var ts := path(u).tabs.filter(func(t: SkillTab): return u.picks(path(u)).has(t))
		ok(ts.size() == 1 and (not row[0] or ts[0].name == row[0]), "%s L%d: one path taken (%s)" % [row[0], row[1], ts.map(func(t: SkillTab): return t.name)])
		var tr := Unit.openers(ts[0])
		var spent := 0
		for s in tr:
			spent += u.purchases.filter(func(p: Array): return p[0] == s).reduce(func(n: int, p: Array): return n + p[1], 0)
		var floor_cost := tr.filter(func(s: Skill): return u.can_raise(s)).map(func(s: Skill): return u.raise_cost(s))
		ok(spent + u.skill_points == row[1] - 1, "%s L%d: %d points, %d spent on traits, %d left" % [row[0], row[1], row[1] - 1, spent, u.skill_points])
		ok(floor_cost.is_empty() or u.skill_points < floor_cost.min(), "%s L%d: none left that buys a rank" % [row[0], row[1]])
		ok(row[1] == 1 or tr.any(func(s: Skill): return u.own_rank(s) > 1), "%s L%d: a trait ranked up" % [row[0], row[1]])
		ok(row[1] < 8 or tr.all(func(s: Skill): return u.own_rank(s) == 2), "%s L%d: cheapest first, every trait to II before any to III" % [row[0], row[1]])
	# fewest: two Starmen and a Siren on its side, so a third unpicked takes Skeletons
	var side: Array[Unit] = []
	for p in ["Starmen", "Starmen", "Sirens"]:
		var m := Unit.monster(lancin, p, 1)
		b.get_node("Units").add_child(m)
		side.append(m)
	ok(Unit.fewest_path(side) == "Skeletons", "fewest: Skeletons (the side has none)")
	var npc: Unit = b.from_role(lancin, role, "npc")
	npc.bio = Bio.new()
	b.get_node("Units").add_child(npc)
	ok(npc.picks(path(npc)).map(func(t: SkillTab): return t.name) == ["Skeletons"], "an unpicked NPC takes the path its side lacks")
	# a player's Monster (no bio, not summoned): no pick, no spending
	var pl: Unit = b.from_role(lancin, role, "pl")
	pl.level = 5
	pl.skill_points = 4
	b.get_node("Units").add_child(pl)
	ok(pl.picks(path(pl)).is_empty() and pl.skill_points == 4 and pl.free_due() == 1, "a player's Monster is left to pick and spend")
	# summoned (Unit.monster): level 5 spends its 4 points
	var sm := Unit.monster(lancin, "Starmen", 5)
	b.get_node("Units").add_child(sm)
	ok(sm.skill_points == 0 and sm.own_rank(sk("floaty")) == 2 and sm.own_rank(sk("hop")) == 2, "a summoned level 5 Monster spent its points (floaty %d, hop %d, %d left)" % [sm.own_rank(sk("floaty")), sm.own_rank(sk("hop")), sm.skill_points])
=======
# Undead ?? (the Skeletons path): bones turn piercing, +1 Defense against it per rank; blunt and slash unmoved.
func test_undead_rank() -> void:
	var u := Unit.monster(lancin, "Skeletons", 4)
	b.get_node("Units").add_child(u)
	u.skill_points = 9
	var undead := sk("undead")
	var base := u.defense([&"pierce"])
	var plain := u.defense([&"blunt"])
	for r in [1, 2, 3]:
		ok(u.rank(undead) == r and u.defense([&"pierce"]) == base + (r - 1) and u.defense([&"blunt"]) == plain, "Undead rank %d: pierce Defense +%d over rank I, blunt unmoved" % [r, r - 1])
		u.raise(undead)
	ok(u.has_tag(&"undead"), "still undead")
>>>>>>> w18-undead-rank

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

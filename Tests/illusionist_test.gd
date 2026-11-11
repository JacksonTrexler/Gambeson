extends Test

# Illusionist, the Trickster tab's Deception capstone: opens the Illusion school to its Rogue, picked on
# the class's own tab (Role.choices: TreeChoice.by), a guest tree at -1 Affinity - but the first rank of
# its spells learned rank as the Rogue's own (Behaviour.affinity(), Unit.guest_affinity()).

var rogue: Role = load("res://Roles/rogue.tres")


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func test_illusionist() -> void:
	var u := b.starter({faction = lancin, role = rogue, name = "Wick"})
	b.get_node("Units").add_child(u)
	u.skill_points = 60
	var c: TreeChoice = rogue.choices.filter(func(x: TreeChoice): return x.name == "Illusion")[0]
	var school: SkillTab = c.tabs[0]
	ok(c.by == sk("illusionist") and c.affinity == -1 and school.title() == "School: Illusion", "the choice: opened by Illusionist, a guest school")
	ok(u.pick_missing(c, school) == "Learn Illusionist first", "shut till then")
	ok(u.unlock(sk("vanishing_act")) and u.unlock(sk("double_bluff")) and u.unlock(sk("illusionist")), "Deception: Vanishing Act, Double Bluff, Illusionist")
	ok(rogue.tier(sk("illusionist")) == 3, "its capstone, tier 3")
	ok(u.pick(c, school) and "School: Illusion" in u.class_trees().map(func(t: SkillTab): return t.title()), "picked: its tab opens")
	ok(u.affinity(sk("blur")) == 0, "the first spell: no penalty")
	ok(u.unlock(sk("blur")) and u.affinity(sk("blur")) == 0, "learned, still its own")
	ok(u.affinity(sk("disguise_self")) == -1, "the second, at Illusionist I: -1")
	ok(u.raise(sk("illusionist")) and u.affinity(sk("disguise_self")) == 0, "Illusionist II: two spells")
	ok("Illusion" in sk("illusionist").describe(2) and "{r:2}" in sk("illusionist").behaviours[0].describe(2), sk("illusionist").describe(2))


func test_mage_school() -> void:
	var mage: Role = load("res://Roles/mage.tres")
	var schools: TreeChoice = mage.choices.filter(func(x: TreeChoice): return x.name == "School")[0]
	ok(schools.tabs.any(func(t: SkillTab): return t.name == "Illusion" and t.roots[0] == rogue.choices[0].tabs[0].roots[0]), "a Mage's school too, the same tree")

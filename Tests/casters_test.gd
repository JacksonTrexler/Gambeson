extends Test

# The Wizard and the Mage, stubbed trees for now (?70). The Wizard: flexible, a tab for everything it
# dabbles in - its own Arcane and Transgression roots, a pact per patron and an affiliation per god (a
# choice each: SkillTab.one_of), and the World's elements and leylines. The Mage: its own Refinement and
# Commitment roots, one school (an element's path, after its starter spell) and one college.

var wizard: Role = load("res://Roles/wizard.tres")
var mage: Role = load("res://Roles/mage.tres")


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func titles(tabs: Array) -> Array:
	return tabs.map(func(t: SkillTab): return t.title())


func starter(role: Role) -> Unit:
	var u := b.starter({faction = lancin, role = role, name = role.name})
	b.get_node("Units").add_child(u)
	u.skill_points = 5
	return u


func test_wizard_tree() -> void:
	ok(titles(wizard.trees()) == ["Wizard", "Pact: Elmon", "Pact: Hogel", "Affiliation: Urlo", "Affiliation: Sol", "World: Nature"],
			"its own tab, a pact per patron, an affiliation per god, the World: %s" % [titles(wizard.trees())])
	ok(wizard.roots.map(func(r: SkillRoot): return r.name) == ["Arcane", "Transgression"], "Arcane and Transgression on its own tab")
	ok(sk("igna") in wizard.options and sk("aetha") in wizard.options and sk("darkstone") in wizard.options, "every starter spell, and Darkstone, on its core ring")
	ok(wizard.tier(sk("sola")) == 1 and wizard.tier(sk("mana")) == 0 and wizard.tier(sk("spellweave")) == 2 and wizard.tier(sk("unbound")) == 5,
			"spells tier 1, Spellweave after Arcana, Unbound a capstone of 4")
	ok(wizard.tabs.slice(0, 4).all(func(t: SkillTab): return t.one_of) and wizard.tabs[0].one_of != wizard.tabs[2].one_of, "a pact and an affiliation: one of each")
	ok(wizard.tabs[2].tone() == SkillTab.GODS[&"urlo"] and wizard.tabs[0].tone() == SkillTab.PATRONS["Elmon"], "pacts and gods in their own colours")


func test_wizard_stubs() -> void:
	var u := starter(wizard)
	ok(u.missing(sk("arcana")) == "Waits on open question 70 (todo.md)", "its own skills wait on 70: %s" % u.missing(sk("arcana")))
	ok(u.missing(sk("counterspell")).begins_with("Waits on Reactions") and u.missing(sk("rift")).begins_with("Waits on Spawning"), "some on systems")
	ok(u.missing(sk("brainfog")) == "Learn Pact of Elmon first" and u.missing(sk("flamewall")) == "Learn Sol's Favour first",
			"a patron's or god's own skills, behind the pact or favour: %s" % u.missing(sk("brainfog")))
	ok(u.missing(sk("igna")) == "" and u.unlock(sk("igna")), "Igna, a starter spell, is learnable")


func test_mage_tree() -> void:
	ok(titles(mage.trees()) == ["Mage", "School: Radiance", "School: Currents", "School: Stone", "School: Shadow", "School: Stars",
			"College: Battle", "College: Wards", "College: Concord"], "its own tab, five schools, three colleges: %s" % [titles(mage.trees())])
	ok(mage.roots.map(func(r: SkillRoot): return r.name) == ["Refinement", "Commitment"], "Refinement and Commitment on its own tab")
	ok(mage.tabs.slice(0, 5).all(func(t: SkillTab): return t.one_of == &"school") and mage.tabs.slice(5).all(func(t: SkillTab): return t.one_of == &"college"),
			"a school, and a college, to choose")
	ok(mage.tier(sk("searing")) == 2 and mage.tier(sk("sunburst")) == 5 and mage.tier(sk("darkstone")) == 2, "a school opens after its starter spell; Sunburst after both its paths (Igna, Searing, Sola, Radiant Lance)")
	ok(mage.vigor_per_level() == 1 and mage.reserves.values() == [10] and mage.items.size() == 3, "a caster: 1 HP a level, 10 Mana, a robe, staff and potion")
	var plans: Array[Skill] = mage.offered() + wizard.offered()
	ok(plans.filter(func(s: Skill): return s.stub and not s.plan).is_empty(), "every stub carries its plan")


# Darkstone, after Nadira, takes up the Shadow school: the other schools go; the colleges stay a choice.
func test_mage_choice() -> void:
	var u := starter(mage)
	ok(titles(u.class_trees()).size() == 9, "undecided: every school and college shows")
	ok(u.missing(sk("darkstone")) == "Learn Nadira first" and u.unlock(sk("nadira")) and u.unlock(sk("darkstone")), "Nadira, then Darkstone")
	ok(titles(u.class_trees()) == ["Mage", "School: Shadow", "College: Battle", "College: Wards", "College: Concord"],
			"Shadow taken up, the rest of the schools go: %s" % [titles(u.class_trees())])
	ok(u.taken(&"school").name == "Shadow" and u.taken(&"college") == null, "no college yet")

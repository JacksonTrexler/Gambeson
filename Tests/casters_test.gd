extends Test

# The Wizard and the Mage. The Wizard: flexible, its own Arcane and Transgression roots (stubs, ?70), a
# World tab, and its Dabblings - expanded studies (Divinity, Symphony, Witchery, Mastery) that let it
# pick other classes' trees, up to their rank, as guest trees at -1 Affinity (a Mage's school at none):
# every other class's own tree of the kind each borrows, found as the game runs (TreeChoice.borrows).
# The Mage: its own Refinement and Commitment roots, then one school and one college picked on its own
# tab (Role.choices, TreeChoice: Unit.pick()).

var wizard: Role = load("res://Roles/wizard.tres")
var mage: Role = load("res://Roles/mage.tres")


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func titles(tabs: Array) -> Array:
	return tabs.map(func(t: SkillTab): return t.title())


func starter(role: Role) -> Unit:
	var u := b.starter({faction = lancin, role = role, name = role.name})
	b.get_node("Units").add_child(u)
	u.skill_points = 20
	return u


func choice(role: Role, n: String) -> TreeChoice:
	return role.choices.filter(func(c: TreeChoice): return c.name == n)[0]


func named(c: TreeChoice, n: String) -> SkillTab:
	return c.all().filter(func(t: SkillTab): return t.name == n)[0]


func test_wizard_tree() -> void:
	var every: Array = wizard.choices.reduce(func(all: Array, c: TreeChoice): return all + c.all(), [wizard.trees()[0]])
	ok(titles(wizard.trees().filter(func(t: SkillTab): return t.kind != "World")) == titles(every), "its own tab, the World, then every tree it can pick: %s" % [titles(wizard.trees())])
	ok(wizard.choices.all(func(c: TreeChoice): return c.tabs.is_empty() and not c.borrows.is_empty()), "no list of its own: each borrows a kind of tree")
	ok(wizard.choices.all(func(c: TreeChoice): return c.by != null and c.affinity == (0 if c.name == "School" else -1)), "each opened by its study; guest trees at -1, a Mage's school at none")
	ok(named(choice(wizard, "Domain"), "Luun").roots[0] == God.of(&"luun").own.roots[0]
			and named(choice(wizard, "Pact"), "Elmon").roots[0] == God.of(&"elmon").own.roots[0]
			and named(choice(wizard, "Genre"), "Song").roots[0] == load("res://Roles/bard.tres").tabs[0].roots[0]
			and named(choice(wizard, "School"), "Shadow").roots[0] == named(choice(mage, "School"), "Shadow").roots[0], "the other classes' own trees, shared")
	ok(named(choice(wizard, "Domain"), "Luun").core == [sk("pray"), sk("renew")] and named(choice(wizard, "Pact"), "Hogel").core == [sk("hex"), sk("sweet_nothings"), sk("chant")],
			"each with its class's shared row first: a Cleric's Pray and Renew, a Warlock's Hex, Sweet Nothings and Chant")
	var callings := TreeChoice.new()
	callings.borrows = ["Calling", "Prowess", "Divinity"]
	ok(titles(callings.all()) == ["Divinity: Eros", "Divinity: Luun", "Divinity: Sol"],
			"caster trees of the kinds it borrows, from any class, each once; no martial Prowess, no specialist Calling: %s" % [titles(callings.all())])
	ok(sk("igna") in wizard.options and sk("aetha") in wizard.options and sk("darkstone") in wizard.options, "every starter spell, and Darkstone, on its core ring")
	ok(wizard.tier(sk("sola")) == 1 and wizard.tier(sk("igna")) == 1 and wizard.tier(sk("mana")) == 0 and wizard.tier(sk("spellweave")) > wizard.tier(sk("sola")) and wizard.tier(sk("unbound")) > wizard.tier(sk("spellweave")),
			"its own spells tier 1 (Sola and Igna, on the Bard's and Sol's trees too), Spellweave after them, Unbound a capstone past it")
	ok(sk("arcana").ai and sk("arcana").title() == "Arcana ??" and not sk("divinity").ai, "an AI's designs end with ??; your Divinity doesn't")


func test_wizard_dabblings() -> void:
	var u := starter(wizard)
	var domain := choice(wizard, "Domain")
	ok(titles(u.class_trees()) == ["Wizard", "World: Nature"], "nothing picked: its own tab and the World")
	ok(u.missing(sk("arcana")) == "Waits on open question 70 (todo.md)" and u.missing(sk("counterspell")).begins_with("Waits on Reactions"), "its stubs wait")
	ok(u.missing(sk("igna")) == "" and u.unlock(sk("igna")) and u.affinity(sk("igna")) == 0, "Igna is its own: learnable, no guest Affinity")
	ok(u.pick_missing(domain, named(domain, "Luun")) == "Learn Divinity first" and u.pick_cap(domain) == 0, "a domain waits on Divinity")
	ok(u.unlock(sk("divinity")) and u.pick(domain, named(domain, "Luun")) and titles(u.class_trees()).has("Divinity: Luun") and u.deity() == &"luun",
			"Divinity I: Luun picked, its tab open, whom it prays to")
	ok(u.pick_missing(domain, named(domain, "Sol")) == "Took up Divinity: Luun", "Divinity I: one domain")
	ok(u.unlock(sk("pray")) and u.unlock(sk("level_down")) and u.affinity(sk("level_down")) == -1, "Pray on its domain's tab, then Level Down: a guest skill, -1 Affinity")
	ok(u.raise(sk("divinity")) and u.pick_cap(domain) == 2 and u.pick(domain, named(domain, "Sol")), "Divinity II: a second domain")
	var pact := choice(wizard, "Pact")
	ok(u.unlock(sk("witchery")) and u.pick(pact, named(pact, "Hogel")) and u.devotions().map(func(t: SkillTab): return t.name) == ["Luun", "Sol", "Hogel"],
			"Witchery: Hogel too - gods and a patron")
	ok(u.missing(sk("brainfog")) == "Pick Patron: Elmon first" and u.missing(sk("hex")) == "" and u.unlock(sk("gasp")), "Hogel's tab open (Hex on it too), Elmon's shut")
	ok(u.raise(sk("divinity")) and u.pick(domain, named(domain, "Eros")) and u.unlock(sk("rejuvinate")) and u.missing(sk("send_off")) == ""
			and u.missing(sk("smite")) == "Paladin only" and u.missing(sk("lovely_caster")) == "Paladin only" and u.missing(sk("impassioned_fighter")) == "Paladin only",
			"Divinity III: Eros too, its spells but none of the Paladin's features")
	var school := choice(wizard, "School")
	ok(u.unlock(sk("mastery")) and u.pick(school, named(school, "Stars")) and u.affinity(sk("fortune")) == 0, "Mastery: a Mage school, no Affinity penalty")


func test_mage_tree() -> void:
	ok(mage.trees()[0].title() == "Mage" and mage.trees().slice(1).all(func(t: SkillTab): return t.kind in ["School", "College"]), "its own tab, then schools and colleges to pick: %s" % [titles(mage.trees())])
	ok(mage.choices.all(func(c: TreeChoice): return c.picks == 1 and c.by == null and c.affinity == 0 and c.all().all(func(t: SkillTab): return t.kind == c.name)), "a school and a college, one each, no study needed, no penalty")
	ok(mage.tier(sk("searing")) > mage.tier(sk("igna")) and mage.tier(sk("sunburst")) > mage.tier(sk("searing")) and mage.tier(sk("darkstone")) > mage.tier(sk("sola")),
			"a school opens after its starter spells; Sunburst after both its paths (Igna, Searing, Sola, Radiant Lance)")
	ok(mage.vigor_per_level() == 1 and mage.reserves.values() == [10] and mage.items.size() == 3, "a caster: 1 HP a level, 10 Mana, a robe, staff and potion")
	var plans: Array[Skill] = mage.offered() + wizard.offered()
	ok(plans.filter(func(s: Skill): return s.stub and not s.plan).is_empty(), "every stub carries its plan")


# The Shadow school picked: its tab opens, Darkstone after Nadira; the other schools stay shut, the
# colleges are still a choice.
func test_mage_choice() -> void:
	var u := starter(mage)
	var school := choice(mage, "School")
	var college := choice(mage, "College")
	ok(titles(u.class_trees()) == ["Mage"], "nothing picked: its own tab alone")
	ok(u.unlock(sk("nadira")) and u.missing(sk("darkstone")) == "Pick School: Shadow first", "Darkstone waits for Shadow")
	ok(u.pick(school, named(school, "Shadow")) and u.unlock(sk("darkstone")) and u.affinity(sk("darkstone")) == 0, "Shadow picked: Darkstone, at no Affinity penalty")
	ok(u.pick_missing(school, named(school, "Stars")) == "Took up School: Shadow" and u.pick(college, named(college, "Wards")), "one school; a college as well")
	ok(titles(u.class_trees()) == ["Mage", "School: Shadow", "College: Wards"] and u.taken("School").name == "Shadow", "%s" % [titles(u.class_trees())])

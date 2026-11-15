extends Test

# Capstones that open a guest choice (TreeChoice.by) and are an efficiency stack (Behaviours/efficiency.gd):
# one table over every role, so a new capstone is covered the moment its .tres is wired. Then the Warlock's
# two, which reach its patron trees: Bargaining (and what opens its Flex slots, TreeChoice.after / burns)
# and Acceptance.

var bargaining: Skill = load("res://Skills/bargaining.tres")
var acceptance: Skill = load("res://Skills/acceptance.tres")
var warlock: Role = load("res://Roles/warlock.tres")


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func efficient(s: Skill) -> bool:
	return s != null and s.behaviours.any(func(h: Behaviour): return h.get_script().resource_path.ends_with("efficiency.gd"))


func make(role: Role) -> Unit:
	var u := b.starter({faction = lancin, role = role, name = "Wren"})
	b.get_node("Units").add_child(u)
	u.skill_points = 20
	return u


func test_capstone_table() -> void:
	var rows := 0
	for f in DirAccess.get_files_at("res://Roles"):
		if not f.ends_with(".tres"):
			continue
		var role: Role = load("res://Roles/" + f)
		for c in role.choices.filter(func(x: TreeChoice): return efficient(x.by)):
			rows += 1
			var cap: Skill = c.by
			var u := make(role)
			var who := "%s: %s opens %s" % [role.name, cap.name, c.name]
			ok(u.missing(cap).begins_with("Needs"), "%s; a capstone, it waits on its root (%s)" % [who, u.missing(cap)])
			for r in role.roots:
				for s in r.skills():
					if s != cap and not s.stub and u.tier(s) < u.tier(cap):
						u.learned.append(slot(s))
			ok(u.missing(cap) == "" and u.unlock(cap), "%s; learned midway up its root (%s, tier %d)" % [who, u.missing(cap), u.tier(cap)])
			var guest: SkillTab
			var probe: Skill
			for t in u.offered(c):
				for r in t.roots:
					for s in r.skills():
						if not probe and u.tier(s) == 1:
							guest = t
							probe = s
			ok(probe != null and u.pick(c, guest), "%s; a guest tree picked (%s)" % [who, guest.title() if guest else "none offered"])
			ok(probe != null and u.tier(probe) == 1 and u.affinity(probe) == c.affinity + 1, "%s; rank I: a stack on its tier 1 skills, the guest penalty eased" % who)
			ok(cap.describe(2).contains("tier"), "%s; it says what it does: %s" % [who, cap.describe(2)])
	ok(rows >= 3, "the table found the Ranger's capstones (%d rows)" % rows)


func test_acceptance() -> void:
	var u := make(warlock)
	var humble := sk("humble")
	ok(u.tier(acceptance) == 10 and acceptance.max_rank == 5, "Acceptance: tier 10")
	ok(u.pick(u.role.choices[0], God.of(&"hogel").own), "Hogel its patron")
	var before := u.affinity(humble)
	u.learned.append(slot(acceptance, 5))
	ok(u.affinity(humble) == before + 1, "Acceptance V: a stack on Hogel's tree")
	u.learned.append(slot(bargaining, 5))
	ok(u.affinity(humble) == before + 2, "with Bargaining: two stacks")
	ok(acceptance.describe(2) != "", "it says what it does: %s" % acceptance.describe(2))


func test_bargaining() -> void:
	var u := make(warlock)
	var patron: TreeChoice = warlock.choices[0]
	var flex: TreeChoice = warlock.choices[1]
	var hogel: SkillTab = God.of(&"hogel").own
	var elmon: SkillTab = God.of(&"elmon").own
	ok(flex.name == "Flex" and flex.picks == 2 and flex.burns and flex.after == bargaining and u.tier(bargaining) == 5, "two Flex slots, after Bargaining (tier 5)")
	ok(u.pick(patron, hogel) and u.pick_missing(flex, elmon) == "Learn Bargaining first", "Hogel its patron; Flex waits on Bargaining")
	var humble := sk("humble")
	var before := u.affinity(humble)
	u.learned.append(slot(bargaining, 1))
	ok(u.affinity(humble) == before + (1 if u.tier(humble) <= 1 else 0), "Bargaining I: a stack on Hogel's tier 1 skills")
	u.learned[-1].rank = 5
	ok(u.affinity(humble) == before + 1 and u.affinity(sk("analysis_dialysis")) == 0, "Bargaining V: Humble eased; Elmon's tree isn't open to it")
	ok(u.burnable(flex) == hogel and u.pick_missing(flex, hogel) == "", "its own patron is on offer in Flex: to burn a slot into")
	ok(u.pick(flex, hogel) and u.burned(hogel) == 1 and u.affinity(humble) == before + 2, "a slot burned: another stack")
	ok(u.pick(flex, elmon) and u.open_tab(elmon) and u.affinity(sk("analysis_dialysis")) == 1 and u.burned(elmon) == 0,
			"the other slot a pact with Elmon: his tree opens, no penalty, Bargaining's stack on it too (every patron tree it holds)")
	ok(u.pick_missing(flex, hogel) == "Picked 2 of 2" and u.burned(hogel) == 1, "both slots used")
	var w := make(warlock)
	w.learned.append(slot(bargaining, 1))
	ok(w.pick(patron, elmon) and w.pick(flex, elmon) and w.pick(flex, elmon) and w.burned(elmon) == 2, "both slots burned into Elmon: two stacks")
	ok(bargaining.describe(2).contains("Patron"), "it says what it does: %s" % bargaining.describe(2))

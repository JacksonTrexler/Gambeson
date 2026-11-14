extends Test

# Bargaining (t5, the Warlock's own tab): an efficiency stack on its patron trees - +1 Affinity up to its
# rank's tier (Behaviours/efficiency.gd, Unit.efficiency()) - and what opens the Warlock's two Flex slots
# (TreeChoice.after): a pact with another patron, or a slot burned into its own patron's tree, each burn
# another efficiency stack (Unit.burned()).

var bargaining: Skill = load("res://Skills/bargaining.tres")
var warlock: Role = load("res://Roles/warlock.tres")


func sk(n: String) -> Skill:
	return load("res://Skills/%s.tres" % n)


func make() -> Unit:
	var u := b.starter({faction = lancin, role = warlock, name = "Vex"})
	b.get_node("Units").add_child(u)
	return u


func test_bargaining() -> void:
	var u := make()
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
	var w := make()
	w.learned.append(slot(bargaining, 1))
	ok(w.pick(patron, elmon) and w.pick(flex, elmon) and w.pick(flex, elmon) and w.burned(elmon) == 2, "both slots burned into Elmon: two stacks")
	ok(bargaining.describe(2).contains("Patron"), "it says what it does: %s" % bargaining.describe(2))

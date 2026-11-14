extends Test

# Acceptance (t10, the Warlock's own tab): the same efficiency stack as Bargaining, on its patron trees up
# to its rank's tier; the two stack (Behaviours/efficiency.gd).

var acceptance: Skill = load("res://Skills/acceptance.tres")


func test_acceptance() -> void:
	var u := b.starter({faction = lancin, role = load("res://Roles/warlock.tres"), name = "Vex"})
	b.get_node("Units").add_child(u)
	var humble: Skill = load("res://Skills/humble.tres")
	ok(u.tier(acceptance) == 10 and acceptance.max_rank == 5, "tier 10")
	ok(u.pick(u.role.choices[0], God.of(&"hogel").own), "Hogel its patron")
	var before := u.affinity(humble)
	u.learned.append(slot(acceptance, 5))
	ok(u.affinity(humble) == before + 1, "Acceptance V: a stack on Hogel's tree")
	u.learned.append(slot(load("res://Skills/bargaining.tres"), 5))
	ok(u.affinity(humble) == before + 2, "with Bargaining: two stacks")
	ok(acceptance.describe(2) != "", "it says what it does: %s" % acceptance.describe(2))

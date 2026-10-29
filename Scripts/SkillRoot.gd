class_name SkillRoot
extends Resource

# One root of a class's skill tree (the Adventurer's Magic, Martial and Specialist): the skills on
# it, each with what must be learned first (Role.roots; the skills screen draws them as a wheel).
@export var name := ""
@export var tag := &""  # its category: magical, martial or specialist - its colour, and the typed slots its skills fit
@export var branches: Array[Branch] = []


func skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for b in branches:
		if b and b.skill:
			out.append(b.skill)
	return out


func branch(s: Skill) -> Branch:
	for b in branches:
		if b and b.skill == s:
			return b
	return null


# How far out a skill sits: 1 for one open from the start of the root, one more than the furthest
# skill it needs; capstones (needing a count of the root's skills) sit past everything else.
func depth(s: Skill) -> int:
	var b := branch(s)
	if not b:
		return 0
	if b.after.is_empty() and b.needs > 0:
		return _deepest() + 1
	var d := 1
	for x in b.after:
		d = maxi(d, depth(x) + 1)
	return d


func max_depth() -> int:
	var d := 0
	for s in skills():
		d = maxi(d, depth(s))
	return d


func _deepest() -> int:
	var d := 1
	for b in branches:
		if b and b.skill and not (b.after.is_empty() and b.needs > 0):
			d = maxi(d, depth(b.skill))
	return d

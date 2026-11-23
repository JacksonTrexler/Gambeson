class_name SkillRoot
extends Resource

# One root of a class's skill tree (the Adventurer's Magic, Martial and Specialist): the skills on
# it, each with what must be learned first (Role.roots; the skills screen draws them as a wheel).
@export var name := ""
@export var tag := &""  # its category: magical, martial or specialist - its colour, and the typed slots its skills fit
@export var branches: Array[Branch] = []
@export var inverted := false  # an inverted page: a tab holding it sells flex trees for base stats (Unit.buy_flex(): a Jester's Inverted, Jovia's)
@export var includes: Array[SkillRoot] = []  # trees composed into this one, by reference (the Caster tree: Student): their branches, tiers and prerequisites show here as if its own, so a skill put on them shows here with no more wiring (Student is on the Specialist tree too)


# Its branches, then every included tree's (and theirs), each skill once: its own branch wins.
func all_branches() -> Array[Branch]:
	var out: Array[Branch] = []
	_collect(out, [self])
	return out


func _collect(out: Array[Branch], seen: Array[SkillRoot]) -> void:
	for b in branches:
		if b and b.skill and not out.any(func(x: Branch): return x.skill == b.skill):
			out.append(b)
	for r in includes:
		if r and r not in seen:
			seen.append(r)
			r._collect(out, seen)


# Its skills, included trees' too.
func skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for b in all_branches() if not includes.is_empty() else branches:
		if b and b.skill:
			out.append(b.skill)
	return out


# Only the skills on its own branches: what it is the home of (Skill.kinds(): an included skill keeps its own tree's kind).
func own_skills() -> Array[Skill]:
	var out: Array[Skill] = []
	for b in branches:
		if b and b.skill:
			out.append(b.skill)
	return out


func branch(s: Skill) -> Branch:
	for b in all_branches() if not includes.is_empty() else branches:
		if b and b.skill == s:
			return b
	return null


# The tree whose own branch holds s: itself, or the one it is included from (Role.category(): Discipline is Student's, a specialist skill, wherever it shows).
func source(s: Skill, seen: Array[SkillRoot] = []) -> SkillRoot:
	if branches.any(func(b: Branch): return b and b.skill == s):
		return self
	seen.append(self)
	for r in includes:
		var found := r.source(s, seen) if r and r not in seen else null
		if found:
			return found
	return null


# How far out a skill sits: 1 for one open from the start of the root, one more than the furthest
# skill it needs; capstones (needing a count of the root's skills) sit past everything else.
func depth(s: Skill) -> int:
	var b := branch(s)
	if not b:
		return 0
	if b.tier > 0:
		return b.tier
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
	for b in all_branches():
		if b and b.skill and not (b.after.is_empty() and b.needs > 0):
			d = maxi(d, depth(b.skill))
	return d

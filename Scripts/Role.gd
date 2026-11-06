class_name Role
extends Resource

# A unit's class ("class" is reserved in GDScript).
@export var name := ""
@export var tends := &""
@export var god := &""  # whom its units pray to, by default (Unit.god; Paladin: eros, its Divinity root)  # how its units heal, by default (Unit.tends; Adventurer: loyal)
@export var noun := ""  # what its units look like to an ally that can barely read them ("Caster"; empty: its name)
@export var look: Texture2D
@export var race: Race  # default race for units created from this role (Paladin: Halfling)
@export var innate: Array[Slot] = []  # skills its units start with (Adventurer: Strike and its three starting passives)
@export var options: Array[Skill] = []  # the class's skills a unit can unlock with skill points, as a plain list
@export var stats: Dictionary[StringName, int] = {}  # starting stats for new units
@export var reserves: Dictionary[Reserve, int] = {}  # reserves new units start with, by max (Wizard: mana 10)
@export var swaps: Dictionary[StringName, StringName] = {}  # its units' magical skills use the second stat where they'd use the first (Warlock: wisdom -> charisma, for Hex)
@export var general: Array[StringName] = []  # the general trees its units get besides the base one: martial, specialist, magical (the Adventurer: all three)
@export var items: Array[Item] = []  # what a starter of this class first wears (Entry: Game.outfit): its armor, weapon and trinket
@export var vigor := 0  # max HP a level beyond the con mod: 1 casters, 2 specialists and generalists, 3 martialists; 0 reads it off its general trees (vigor_per_level())

@export_group("Tree")  # a class with a skill tree (the Adventurer's, drawn as a wheel on the skills screen)
@export var center: Skill  # the one skill at the very centre (Adventurer: Skill Slot +1)
@export var core: Array[Skill] = []  # around it, with its innate skills: a first choice at any time (Hex)
@export var roots: Array[SkillRoot] = []  # reaching out from there (Magic, Martial, Specialist)
@export var tabs: Array[SkillTab] = []  # more of its tree, beside its own, each a wheel of its own (Rogue: Calling: Freedom)
@export var radial := false  # its own tab drawn as a wheel (the Adventurer)
@export var shared: Array[Skill] = []  # a static tier 1 row on every tab's core ring, learned from the start as innate skills (Warlock: Hex, Sweet Nothings, Chant)


# Max HP each level brings its units beyond their con mod: set (vigor), or by the general trees the
# class gets - all three a generalist (2), martial a martialist (3), specialist 2, a caster 1.
func vigor_per_level() -> int:
	if vigor > 0:
		return vigor
	if general.size() >= 3:
		return 2
	if &"martial" in general:
		return 3
	return 2 if &"specialist" in general else 1


func has_tree() -> bool:
	return not roots.is_empty() or center != null or not core.is_empty() or not tabs.is_empty()


# Its tree, a tab at a time: its own (named after it, with its innate skills on the core ring
# where no other tab has them; left out when that leaves it empty beside other tabs), then its tabs,
# each with the shared row first on its core ring (Warlock: a tab per patron).
func trees() -> Array[SkillTab]:
	var own := SkillTab.new()
	own.name = name
	own.center = center
	for x in innate:
		if x and x.skill and x.skill not in own.core and x.skill not in shared and not tabs.any(func(t: SkillTab): return t and t.offers(x.skill)) \
				and not Unit.GENERAL_TREES.any(func(g: SkillTab): return g.offers(x.skill)):  # Strike is the General tree's
			own.core.append(x.skill)
	for s in core + options:  # a class without a tree: its options, by tier
		if s and s not in own.core:
			own.core.append(s)
	own.roots = roots
	own.radial = radial
	var out: Array[SkillTab] = []
	if own.center or not own.core.is_empty() or not own.roots.is_empty() or tabs.is_empty():
		out.append(own)
	for t in tabs:
		if t and not shared.is_empty():
			var copy: SkillTab = t.duplicate()
			var row: Array[Skill] = []
			row.assign(shared.filter(func(s: Skill): return s != null and s not in t.core) + t.core)
			copy.core = row
			out.append(copy)
		elif t:
			out.append(t)
	return out


# Every skill it offers: its options, then its tree's centres, cores and roots, tab by tab.
func offered() -> Array[Skill]:
	var out: Array[Skill] = []
	var firsts: Array = options + ([center] if center else []) + core + shared
	for t in tabs:
		if t:
			firsts.append_array(([t.center] if t.center else []) + t.core)
	for s in firsts:
		if s and s not in out:
			out.append(s)
	for r in all_roots():
		for s in r.skills():
			if s not in out:
				out.append(s)
	return out


# A skill's tier: 1, plus how many skills must be learned before it's reached - those its branch
# comes after, and theirs in turn, or the count of its root's skills a capstone needs (the starter
# spells 1, Hazard Expert 2, the capstones 4). What its units start with (innate) is tier 0; its
# centre, core and listed options tier 1; -1 for a skill it doesn't offer.
func tier(s: Skill) -> int:
	if innate.any(func(x: Slot): return x and x.skill == s):
		return 0
	var root := root_of(s)
	if root:
		var seen: Array[Skill] = []
		return 1 + maxi(_before(s, seen).size(), root.branch(s).needs)
	if s in offered() or s in shared:
		return 1
	return -1


# The category of a skill on its tree - its root's tag (a Cleric's Sol: magical) - else its own
# category tag; empty for none. What general-tree tiers it opens (Unit.missing()).
func category(s: Skill) -> StringName:
	var root := root_of(s)
	if root and root.tag:
		return root.tag
	for t in [&"martial", &"specialist", &"magical"]:
		if t in s.tags:
			return t
	return &""


# Every skill that must be learned before s on its tree, added to out.
func _before(s: Skill, out: Array[Skill]) -> Array[Skill]:
	var root := root_of(s)
	if root:
		for x in root.branch(s).after:
			if x not in out:
				out.append(x)
				_before(x, out)
	return out


# The tab beside its own that offers s, or null (Unit.devotion(): a Warlock's patrons).
func tab_of(s: Skill) -> SkillTab:
	for t in tabs:
		if t and t.offers(s) and s not in shared:
			return t
	return null


# Its starting items by slot (weapon, armor, trinket): a starter's first outfit.
func outfit() -> Dictionary:
	var out := {}
	for it in items:
		if it:
			out[it.slot] = it
	return out


# The root a skill is on, in any of its tabs, or null (a centre or core, or not in its tree).
func root_of(s: Skill) -> SkillRoot:
	for r in all_roots():
		if r.branch(s):
			return r
	return null


# Its roots, then its tabs'.
func all_roots() -> Array[SkillRoot]:
	var out: Array[SkillRoot] = []
	for r in roots:
		if r:
			out.append(r)
	for t in tabs:
		if t:
			for r in t.roots:
				if r:
					out.append(r)
	return out

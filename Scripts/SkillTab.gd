class_name SkillTab
extends Resource

# A tab of a class's skill tree (Role.trees()): its own first, then any beside it (Role.tabs: the
# Rogue's and Bard's Calling: Freedom, later a Warlock's patrons). Laid out the same way - a centre,
# a core ring and roots - and drawn as a wheel of its own on the skills screen.
@export var name := ""
@export var kind := ""  # the kind of path it is, shown before its name ("Calling"); empty: the class's own
@export var radial := false  # drawn as a wheel (the Adventurer's own: SkillWheel) rather than growing from the bottom (SkillGrid)
@export var category := &""  # a general tree's (kind General): martial, specialist or magical (the Caster tree); empty: the base General tree (Unit.general_trees())
@export var center: Skill
@export var core: Array[Skill] = []
@export var roots: Array[SkillRoot] = []
@export var god := &""  # the god its devotees worship (a Cleric's Luun, Sol: Unit.deity())
@export var devotes := false
@export var satisfied_by := &""  # what wins its devotees Sweet Nothings back (Hogel: rest_whole, resting a turn out at full HP; Battle.end_turn())  # learning a skill on its roots devotes its learner to it: other devoting tabs close (a Warlock's patron; Unit.devotion())


# "Calling: Freedom".
func title() -> String:
	return "%s: %s" % [kind, name] if kind else name


func offers(s: Skill) -> bool:
	return s == center or s in core or roots.any(func(r: SkillRoot): return r and r.branch(s))


# A general tree (kind General): its tiers are set on its branches, and its skills are anyone's whose
# class opens it (Role.general), or who has learned what opens it (Martialist, Thaumaturgist).
func general() -> bool:
	return kind == "General"


# Its colour on the skills screen: its category's (Caster light purple, Specialist green, Martial red),
# dark gray for the base General tree.
func tone() -> Color:
	if not general():
		return Color(0.6, 0.63, 0.7)
	return SkillSlot.TYPES[category].lightened(0.3) if category in SkillSlot.TYPES else Color(0.42, 0.43, 0.47)


# The tier of s on it: its branch's set tier, or 0 for what's on its core (Strike, learned from the start).
func tier_of(s: Skill) -> int:
	if s in core or s == center:
		return 0
	for r in roots:
		if r and r.branch(s):
			return r.branch(s).tier
	return -1

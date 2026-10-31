class_name SkillTab
extends Resource

# A tab of a class's skill tree (Role.trees()): its own first, then any beside it (Role.tabs: the
# Rogue's and Bard's Calling: Freedom, later a Warlock's patrons). Laid out the same way - a centre,
# a core ring and roots - and drawn as a wheel of its own on the skills screen.
@export var name := ""
@export var kind := ""  # the kind of path it is, shown before its name ("Calling"); empty: the class's own
@export var center: Skill
@export var core: Array[Skill] = []
@export var roots: Array[SkillRoot] = []


# "Calling: Freedom".
func title() -> String:
	return "%s: %s" % [kind, name] if kind else name


func offers(s: Skill) -> bool:
	return s == center or s in core or roots.any(func(r: SkillRoot): return r and r.branch(s))

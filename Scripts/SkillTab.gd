class_name SkillTab
extends Resource

# A tab of a class's skill tree (Role.trees()): its own first, then any beside it (Role.tabs: the
# Rogue's and Bard's Calling: Freedom, later a Warlock's patrons). Laid out the same way - a centre,
# a core ring and roots - and drawn as a wheel of its own on the skills screen.
@export var name := ""
@export var kind := ""  # the kind of path it is, shown before its name ("Calling"); empty: the class's own
@export var radial := false  # drawn as a wheel (the Adventurer's own: SkillWheel) rather than growing from the bottom (SkillGrid)
@export var category := &""  # a general tree's (kind General): martial, specialist or magical (the Caster tree); empty: the base General tree (Unit.general_trees())
@export var color := Color(0, 0, 0, 0)  # its colour, if set; else by what it is (tone())
@export var center: Skill
@export var core: Array[Skill] = []
@export var roots: Array[SkillRoot] = []
@export var god := &""  # the god its devotees worship (a Cleric's Luun, Sol: Unit.deity())
@export var devotes := false
@export var one_of := &""  # one of a choice of tabs (a Paladin's Prowess): learning a skill on one closes the rest, and only those its roots suit its god are open (Unit.taken(), Unit.suits())
@export var satisfied_by := &""  # what wins its devotees Sweet Nothings back (Hogel: rest_whole, resting a turn out at full HP; Battle.end_turn())  # learning a skill on its roots devotes its learner to it: other devoting tabs close (a Warlock's patron; Unit.devotion())


const GENERAL := {&"": Color("#7a7d85"), &"martial": Color("#d27a70"), &"specialist": Color("#82b86e"), &"magical": Color("#a98bdb")}
const GODS := {&"ramut": Color("#c08a5a"), &"eros": Color("#ee95c0"), &"sol": Color("#f08a55"), &"urlo": Color("#6fd8e4"),
		&"luun": Color("#8f86d6"), &"drael": Color("#68aee8"), &"vetruvis": Color("#b8935e")}
const PATRONS := {"Elmon": Color("#5fc4b0"), "Hogel": Color("#d6d27a")}
const KINDS := {"Prowess": Color("#d9935e"), "Path": Color("#9fc7a3"), "Calling": Color("#7cc4d8"), "Species": Color("#b59a78"), "Knowledge": Color("#c9b98a")}
const CLASSES := {"Adventurer": Color("#c9a66b"), "Fighter": Color("#a7b1bd"), "Paladin": Color("#e3c873"), "Rogue": Color("#7fa6a0"),
		"Bard": Color("#d98bb0"), "Wizard": Color("#6f9be0"), "Warlock": Color("#9a7bd1"), "Cleric": Color("#e8dcb0"),
		"Berserker": Color("#c25a3c")}


# "Calling: Freedom".
func title() -> String:
	return "%s: %s" % [kind, name] if kind else name


func offers(s: Skill) -> bool:
	return s == center or s in core or roots.any(func(r: SkillRoot): return r and r.branch(s))


# A general tree (kind General): its tiers are set on its branches, and its skills are anyone's whose
# class opens it (Role.general), or who has learned what opens it (Martialist, Thaumaturgist).
func general() -> bool:
	return kind == "General"


# Its colour (its primary) on the skills screen: its own text in it, its background and its tree's in
# it darker. Set (color), or by what it is: a general tree by category (Martial a light, muted red,
# Specialist green, Caster light purple, the base tree dark gray), a god's by domain, a patron's, a
# calling's, species and knowledge, else its class's.
func tone() -> Color:
	if color.a > 0.0:
		return color
	if general():
		return GENERAL.get(category, GENERAL[&""])
	if god in GODS:
		return GODS[god]
	for table in [PATRONS, KINDS, CLASSES]:
		if name in table:
			return table[name]
		if kind in table:
			return table[kind]
	return Color(0.6, 0.63, 0.7)


# The tier of s on it: its branch's set tier, or 0 for what's on its core (Strike, learned from the start).
func tier_of(s: Skill) -> int:
	if s in core or s == center:
		return 0
	for r in roots:
		if r and r.branch(s):
			return r.branch(s).tier
	return -1

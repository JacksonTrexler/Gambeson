class_name Prep

# Preparation's uses (docs/plans/w7-prep.md): what a unit may spend, before the initiative roll, on the
# field it is about to fight on. One table, one rule (Battle.prepare()); Study is two rows of it.
# A use has:
#   of          the kinds of target it fits: &"tile", &"ally" (a unit that seems its side's friend) or &"foe"
#   intel       it reads the target a recon level better for the battle (Battle.studied, _read())
#   suspicion   it looks harder at the target: a tile is inspected, a unit that fools it doubted (Battle.inspect(), doubt())
#   edge        +1: those looks are at advantage (an intel-only use rolls nothing, so it carries none to use)
#   mod         how many it has: the mod of this stat of its user (Study), else the Effect stat `prep_use` tagged
#               with the use's id (Surveyor, Evaluator, Inquisitor: a rank each), so one tag is both the use and
#               the in-battle checks of its kind that the same skill adds a rank to (Battle.inspect(), doubt())
#   label, noun, verb   how the HUD says it: a line "Surveys: 2 tiles", a log "X surveys Y"
# The click spends the first row that fits and still gives the target something (Battle.prep_use()).
const USES := {
	&"study_ally": {label = "Study", noun = "ally", verb = "studies", of = [&"ally"], intel = true, suspicion = false, edge = 0, mod = &"charisma"},
	&"study": {label = "Study", noun = "foe or tile", verb = "studies", of = [&"foe", &"tile"], intel = true, suspicion = true, edge = 0, mod = &"wisdom"},
	&"survey": {label = "Surveys", noun = "tile", verb = "surveys", of = [&"tile"], intel = true, suspicion = false, edge = 1},
	&"evaluate": {label = "Evaluates", noun = "unit", verb = "evaluates", of = [&"ally", &"foe"], intel = true, suspicion = false, edge = 1},
	&"inquire": {label = "Inquisitions", noun = "unit", verb = "inquires about", of = [&"ally", &"foe"], intel = false, suspicion = true, edge = 1},
}


# How many of use `id` o has: its mod in the use's stat (none below 0), or its ranks of the skills that grant it.
static func total(o: Unit, id: StringName) -> int:
	var use: Dictionary = USES[id]
	return maxi(o.mod(use.mod) if use.has("mod") else roundi(o.stat(&"prep_use", [id])), 0)


# Whether the use is one a skill grants (it gets a line of its own in the top box, and says so in the skill).
static func granted(id: StringName) -> bool:
	return not USES[id].has("mod")


# What the plural of use's noun is: "ally" -> "allies", "foe or tile" -> "foes or tiles".
static func plural(noun: String, n: int) -> String:
	if n == 1:
		return noun
	return noun.replace("ally", "allies").replace("foe", "foes").replace("tile", "tiles").replace("unit", "units")

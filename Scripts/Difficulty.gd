class_name Difficulty

# How hard a check is, as a tag a skill, item or tile carries (Glossary: the Checks page). Each rung
# names a DC that grows with the rank of whatever imposes it - (rank + base) + rank x per - or, where
# there's no rank, a flat one. Units expected to meet a kind of check regularly are assumed to bring
# bonuses about equal to its rank: a fledgling rogue picks a rank I lock with an OK chance.
#
# Magnitudes do the same for how much: a share of rank (an intense cone runs 2.5 x rank tiles, severe
# damage rolls 3 x rank dice).

# tag -> [base, per, flat]: dc(rank) = (rank + base) + rank x per; trivial is always 1.
const LADDER := {
	&"trivial": [1, -1, 1],
	&"easy": [1, 1, 4],
	&"approachable": [2, 2, 8],
	&"standard": [3, 2, 12],
	&"difficult": [4, 3, 16],
	&"unfair": [5, 3, 20],
	&"impossible": [6, 3, 30],
}

# An area's difficulty (Battle.difficulty: dungeons, scenarios) -> the rung its own checks sit on, and
# how much of everything it throws at you (the Meadows: live spawns, how long its portal takes).
const AREA := {0.5: &"approachable", 1.0: &"standard", 1.5: &"difficult"}
const AREA_NAMES := {0.5: "Gentle", 1.0: "Standard", 1.5: "Harsh"}


# The rung an area of difficulty x sits on (approachable, standard, difficult).
static func area(x: float) -> StringName:
	return AREA.get(snappedf(clampf(x, 0.5, 1.5), 0.5), &"standard")


# tag -> share of rank (rounded up): how far, how many, how much.
const MAGNITUDE := {
	&"faint": 0.5,
	&"mild": 1.0,
	&"moderate": 1.5,
	&"strong": 2.0,
	&"intense": 2.5,
	&"severe": 3.0,
	&"overwhelming": 4.0,
}


# The DC of a check of this difficulty imposed at `rank` (below 1: its flat DC, with no rank to scale by).
static func dc(tag: StringName, rank := 0) -> int:
	assert(tag in LADDER, "no difficulty %s" % tag)
	var d: Array = LADDER[tag]
	if rank < 1:
		return d[2]
	return (rank + d[0]) + rank * d[1]


# A magnitude at a rank: rank x its share, rounded up, at least 1.
static func scaled(tag: StringName, rank: int) -> int:
	assert(tag in MAGNITUDE, "no magnitude %s" % tag)
	return maxi(ceili(rank * MAGNITUDE[tag]), 1)


# "(rank + 4) + rank x 3, or 16".
static func formula(tag: StringName) -> String:
	var d: Array = LADDER[tag]
	if tag == &"trivial":
		return "always 1"
	return "(rank + %d) + rank%s, or %d without a rank" % [d[0], " x %d" % d[1] if d[1] != 1 else "", d[2]]

class_name Difficulty

# How hard a check is, as a tag a skill, item or tile carries (Glossary: the Checks page). Each rung
# names a DC that grows with the rank of whatever imposes it - (rank + base) + rank x per - or, where
# there's no rank, a flat one. Units expected to meet a kind of check regularly are assumed to bring
# bonuses about equal to its rank: a fledgling rogue picks a rank I lock with an OK chance.
#
# The ladder is the one reference for "how hard / how much / how high": WORDS maps every word anyone uses
# for a rung (low, hard, very high...) to it, word() is the one lookup, and everything that sets a
# difficulty (an imposed check, a lock, an attack or cost level, an int to see a secret) reads through it.
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

# Every word for a rung -> the rung (word() reads this, lowercased, "_" as a space). The five levels cost
# profiles and the user's intensities use (none, low, moderate, high, very high) land on trivial, easy,
# standard, difficult and unfair; "moderate low" (the user's) is the approachable between low and moderate.
const WORDS := {
	&"trivial": &"trivial", &"none": &"trivial", &"effortless": &"trivial",
	&"easy": &"easy", &"low": &"easy", &"light": &"easy", &"simple": &"easy",
	&"approachable": &"approachable", &"moderate low": &"approachable",
	&"standard": &"standard", &"moderate": &"standard", &"medium": &"standard", &"normal": &"standard", &"average": &"standard",
	&"difficult": &"difficult", &"high": &"difficult", &"hard": &"difficult", &"heavy": &"difficult",
	&"unfair": &"unfair", &"very high": &"unfair", &"very hard": &"unfair", &"very heavy": &"unfair", &"very difficult": &"unfair",
	&"impossible": &"impossible", &"extreme": &"impossible", &"extremely high": &"impossible", &"extremely hard": &"impossible",
}

# Where a rung stands as an ability score (Unit.stat), for rules that ask "is this stat that high": only
# what's been asked so far. Unfair ("very high") reads 16, the adventurer's score across; a flat DC isn't
# a score (very high is 20 as a DC), so this is its own named entry, not derived.
const STAT_SCORE := {&"unfair": 16}

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


# The rung a word names (a rung itself, or any of its synonyms: hard, very high...), or &"" for none.
static func word(name: Variant) -> StringName:
	var key := StringName(" ".join(String(name).to_lower().replace("_", " ").split(" ", false)))
	return WORDS.get(key, &"")


# The ladder's order, 0 for trivial: where a word sits (-1: not a difficulty word).
static func index(name: Variant) -> int:
	var rung := word(name)
	return LADDER.keys().find(rung) if rung != &"" else -1


# The magnitude parallel to a rung (faint to easy, mild to approachable... severe to impossible): the
# user's intensities (low faint, moderate low mild, moderate moderate, high strong, extreme severe) and
# "very high" (intense) are words on the ladder. Trivial reads faint; &"" for a non-word.
static func magnitude(name: Variant) -> StringName:
	var i := index(name)
	return &"" if i < 0 else MAGNITUDE.keys()[maxi(i - 1, 0)]


# The ability score a word stands for (STAT_SCORE; 0 where it's not been set): int >= this "sees" a secret.
static func stat_at(name: Variant) -> int:
	return STAT_SCORE.get(word(name), 0)


# The DC of a check of this difficulty (any word for it) imposed at `rank` (below 1: its flat DC, with no rank to scale by).
static func dc(tag: StringName, rank := 0) -> int:
	tag = word(tag)
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
	tag = word(tag)
	var d: Array = LADDER[tag]
	if tag == &"trivial":
		return "always 1"
	return "(rank + %d) + rank%s, or %d without a rank" % [d[0], " x %d" % d[1] if d[1] != 1 else "", d[2]]

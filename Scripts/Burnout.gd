class_name Burnout
extends RefCounted

# Burnout (Glossary: burnout), the user's child of exhaustion: every int skill (tagged int) wears its user
# out by Exhaustion's own rule - the same pressure, the same thresholds - with a harsher penalty, PENALTY
# times exhaustion's wear, and harsher still on a cost paid from a reserve that burns (Reserve.burns: Mana).
# penalty() is the one read of it (Exhaustion.penalty, set by Unit): what scales Burnout scales it there.

const PENALTY := 1.25  # exhaustion's wear on an int skill, multiplied by this


# Whether s burns out rather than only exhausts: an int skill.
static func of(s: Skill) -> bool:
	return s.tagged(&"int")


# What exhaustion's wear on s is multiplied by for u: PENALTY on an int skill, else 1.
static func penalty(_u: Unit, s: Skill) -> float:
	return PENALTY if of(s) else 1.0


# What that wear is multiplied by again on s's cost paid from fund: the reserve's burns (Mana 1.5) on an
# int skill, else 1.
static func on_cost(s: Skill, fund: Variant) -> float:
	return fund.burns if fund is Reserve and of(s) else 1.0

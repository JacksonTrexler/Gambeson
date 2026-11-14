extends Behaviour

# Efficiency: an efficiency stack on trees of its holder's class - +1 Affinity (cheaper rank-ups) on
# their skills up to its rank's tier (Unit.efficiency()). The trees it reaches, by kind or name
# (a Warlock's Bargaining and Acceptance: Patron; a Ranger's capstones: the guest tree each opens).
# Two skills with it stack.

@export var reaches: Array[String] = []


func affinity(holder: Unit, rank: int, s: Skill, t: SkillTab, a: int) -> int:
	if t and (t.kind in reaches or t.name in reaches) and holder.tier(s) <= rank:
		return a + 1
	return a


func describe(rank: int) -> String:
	return "An efficiency stack on %s trees: +1 Affinity, cheaper rank-ups, for their skills up to tier {r:%d}" % [" and ".join(reaches), rank]

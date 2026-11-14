extends Behaviour

# Resuscitate: used only on a Downed ally beside it (fits()), which comes back up at once with rank x
# 5% of its max HP: healed what it is below 0 plus that share, through the one heal every recovery
# passes (Battle.mend(), Unit.heal(): others' passives may take their cut), so it's saved
# (Battle.rescued(): the rescue XP to the caster).

const SHARE := 0.05


func fits(_b: Battle, _caster: Unit, target: Unit) -> bool:
	return target.dbno != null


func apply(c: Cast) -> void:
	if c.foe or c.target.dbno == null:
		return
	c.target.healed_by = c.caster
	c.battle.mend(c.target, maxi(-c.target.hp, 0) + amount(c.target.max_hp, c.rank), 0)


# The HP it comes back up with, at least 1.
static func amount(max_hp: int, rank: int) -> int:
	return maxi(roundi(SHARE * rank * max_hp), 1)


func describe(rank: int) -> String:
	return "Only on a %s ally: it comes back up at once with {r:%d}%% of its max HP (healed what it's below 0, and that)" % [
			Glossary.term(&"downed", "Downed"), roundi(SHARE * 100 * rank)]

extends Behaviour

# A heal by magnitude (Heal, Megaheal): the ally gets back d8s as many as its `magnitude` of its rank (Difficulty.MAGNITUDE: Heal moderate, 1.5 x rank; Megaheal severe, 3 x rank),
# + the caster's mod in the skill's stat (Skill.stat()) + rank, at least 1 - through Battle.mend(), so
# Molothrus and Recovery Endurance hear it as any heal.

const DIE := 8

@export var magnitude := &"moderate"  # Difficulty.MAGNITUDE: how many d8 a rank (Heal moderate, Megaheal severe)


# How many d8 it rolls at rank r.
func dice(r: int) -> int:
	return Difficulty.scaled(magnitude, r)


# What it gets back on average: the dice's mean + the caster's mod + rank.
func restores(c: Cast) -> Dictionary:
	var r := c.impact_rank()
	return {&"hp": maxi(roundi(dice(r) * (DIE + 1) / 2.0) + c.stat_mod(c.caster.mod(c.skill.stat(), c.skill.tags)) + r, 1)}


func apply(c: Cast) -> void:
	if c.foe or not c.target.is_alive():
		return
	var r := c.impact_rank()  # dice and + rank, and its stat mod, through its modifiers
	var n := c.battle.roll(Vector2i(dice(r), DIE)) + c.stat_mod(c.caster.mod(c.skill.stat(), c.skill.tags)) + r
	c.target.healed_by = c.caster
	c.bag[&"healed"] = c.target.hp
	c.battle.mend(c.target, maxi(n, 1), 0)
	c.bag[&"healed"] = c.target.hp - c.bag[&"healed"]


# Its terms: dice and + rank grow with rank (impact); the caster's mod adds to it (stat impact); tame.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "heal")
	t.add(&"stat_impact", "heal")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var rank := c.impact_rank()
	return "An ally gets back {r:%dd%d} (%s: %s x rank) + %s + {r:%d} HP" % [dice(rank), DIE, String(magnitude).capitalize(), Skill.num(Difficulty.MAGNITUDE[magnitude]), c.mod_text(&"wisdom"), rank]

extends Behaviour

# A heal by magnitude (Heal, Megaheal): the ally gets back d8s as many as its `magnitude` of its rank (Difficulty.MAGNITUDE: Heal moderate, 1.5 x rank; Megaheal extreme, 3 x rank),
# + the caster's mod in the skill's stat (Skill.stat()) + rank, at least 1 - through Battle.mend(), so
# Molothrus and Burnout hear it as any heal.

const DIE := 8

@export var magnitude := &"moderate"  # Difficulty.MAGNITUDE: how many d8 a rank (Heal moderate, Megaheal extreme)


# How many d8 it rolls at rank r.
func dice(r: int) -> int:
	return Difficulty.scaled(magnitude, r)


func apply(c: Cast) -> void:
	if c.foe or not c.target.is_alive():
		return
	var n := c.battle.roll(Vector2i(dice(c.rank), DIE)) + c.caster.mod(c.skill.stat(), c.skill.tags) + c.rank
	c.target.healed_by = c.caster
	c.bag[&"healed"] = c.target.hp
	c.battle.mend(c.target, maxi(n, 1), 0)
	c.bag[&"healed"] = c.target.hp - c.bag[&"healed"]


func describe(rank: int) -> String:
	return "An ally gets back {r:%dd%d} (%s: %s x rank) + {o:wis mod} + {r:%d} HP" % [dice(rank), DIE, String(magnitude).capitalize(), Skill.num(Difficulty.MAGNITUDE[magnitude]), rank]

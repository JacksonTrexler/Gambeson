extends Behaviour

# Move: its user gains rank tiles of movement this turn (rank move AP, and rank tiles past what its
# movement allows: Unit.stride()) - and rank more if it was paid with Stamina (the stamina tag's extra:
# Unit.paid_as(), an Adventurer's Energy counting as Stamina through Field Experience or Everyman).

const STAMINA: Reserve = preload("res://Reserves/stamina.tres")


# The tiles a cast gains: rank, doubled paid with Stamina.
static func tiles(c: Cast) -> int:
	return c.impact_rank() * (2 if c.caster.paid_as(STAMINA, c.skill) else 1)


# What it would give if used now, the AI's forecast: the payment funding() would make, not the last one.
func strides(c: Cast) -> int:
	return c.impact_rank() * (2 if c.caster.pays_as(c.skill, c.caster.funding(c.skill), STAMINA) else 1)


func apply(c: Cast) -> void:
	c.bag[&"strode"] = tiles(c)
	c.caster.stride(tiles(c))


# Its terms: the tiles it gains grow with rank (impact); a tame effect.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "tiles")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var rank := c.impact_rank()
	return "On itself: {r:%d} tile%s more movement this turn; paid with %s, {r:%d} more" % [rank, "" if rank == 1 else "s", Glossary.term(&"stamina"), rank]

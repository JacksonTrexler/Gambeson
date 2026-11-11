extends Behaviour

# Move: its user gains rank tiles of movement this turn (rank move AP, and rank tiles past what its
# movement allows: Unit.stride()) - and rank more if it was paid with Stamina (the stamina tag's extra:
# Unit.paid_as(), an Adventurer's Energy counting as Stamina through Field Experience or Everyman).

const STAMINA: Reserve = preload("res://Reserves/stamina.tres")


# The tiles a cast gains: rank, doubled paid with Stamina.
static func tiles(c: Cast) -> int:
	return c.rank * (2 if c.caster.paid_as(STAMINA, c.skill) else 1)


func apply(c: Cast) -> void:
	c.bag[&"strode"] = tiles(c)
	c.caster.stride(tiles(c))


func describe(rank: int) -> String:
	return "On itself: {r:%d} tile%s more movement this turn; paid with %s, {r:%d} more" % [rank, "" if rank == 1 else "s", Glossary.term(&"stamina"), rank]

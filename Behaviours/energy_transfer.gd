extends Behaviour

# Energy Transfer: a low-damage energy bolt tagged siphon - its damage comes off the foe's resources,
# not its HP (Unit.siphon()). The caster then gets what it drained back as Energy (Power, if it's
# powered: Unit.grant_energy()), up to its max; what doesn't fit - its bar full, or none at all - comes as
# Overcharge at rank x 20%, rounded down, decaying over rank of its turns (Unit.add_overcharge()).

const EFFICIENCY := 0.2  # of the overflow kept as Overcharge, a rank


func dealt(c: Cast, _n: int) -> void:
	if not c.foe or c.siphoned <= 0:
		return
	var over := c.siphoned - c.caster.grant_energy(c.siphoned)
	var kept := floori(over * EFFICIENCY * c.rank + 0.0001)
	c.caster.add_overcharge(kept, c.rank, 1 if c.caster.faction == c.battle.turn else 0)


func describe(rank: int) -> String:
	return "Its damage is %s: it comes off the foe's resources, not its HP. You get what it drains as Energy (Power, if yours is), up to your max; past that, or with no Energy, {r:%d%%} of the rest as %s for {t:%d turn%s}" % [
			Glossary.term(&"siphon", "siphoned"), roundi(EFFICIENCY * 100.0 * rank), Glossary.term(&"overcharge", "Overcharge"), rank, "" if rank == 1 else "s"]

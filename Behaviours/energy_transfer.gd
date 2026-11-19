extends Behaviour

# Energy Transfer: a low-damage energy bolt tagged siphon - its damage comes off the foe's resources,
# not its HP (Unit.siphon()). The caster then gets what it drained back as Energy (Power, if it's
# powered: Unit.grant_energy()), up to its max; what doesn't fit - its bar full, or none at all - comes as
# Overcharge at rank x 20%, rounded down, decaying over rank of its turns (Unit.add_overcharge()): the
# rank is rank impact, through its caster's modifiers.

const EFFICIENCY := 0.2  # of the overflow kept as Overcharge, a rank


func dealt(c: Cast, _n: int) -> void:
	if not c.foe or c.siphoned <= 0:
		return
	var got := c.caster.grant_energy(c.siphoned, false)
	var r := c.impact_rank()
	var kept := floori((c.siphoned - got) * EFFICIENCY * r + 0.0001)
	c.caster.add_overcharge(kept, r, 1 if c.caster.faction == c.battle.turn else 0)
	c.caster.note_recovery(&"energy", got + kept)  # one recovery, Overcharge and all (Recovery Endurance)


# Its terms: the share kept as Overcharge and the turns it lasts grow with rank (impact); a tame effect.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "overcharge")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var rank := c.impact_rank()
	return "Its damage is %s: it comes off the foe's resources, not its HP. You get what it drains as Energy (Power, if yours is), up to your max; past that, or with no Energy, {r:%d%%} of the rest as %s for {t:%d turn%s}" % [
			Glossary.term(&"siphon", "siphoned"), roundi(EFFICIENCY * 100.0 * rank), Glossary.term(&"overcharge", "Overcharge"), rank, "" if rank == 1 else "s"]

extends Behaviour

# Symphony (the Bard's: the Wizard's study of the same name is Skills/symphony.tres): units in the holder's command range
# (Command.hears()) play off one another. Each time one it commands (any in range but itself) passes a check
# (Behaviour.passed(): a contest or save won, an attack landed), every unit in range gets +1 on checks (Cadence, one
# of its side's turns), up to rank. And the first unit of its side to use a skill in a turn, if in range, is First
# Chair: +rank impact on that use, each blow and each heal of it (Behaviour.opening(), Volley.impact).

const CADENCE: Effect = preload("res://Effects/cadence.tres")


func opening(_b: Battle, holder: Unit, rank: int, v: Volley) -> void:
	if v.first and Command.hears(holder, v.caster):
		v.impact += holder_rank(holder, rank)


func passed(b: Battle, holder: Unit, rank: int, u: Unit) -> void:
	if u == holder or not Command.hears(holder, u):
		return
	var cap := holder_rank(holder, rank)
	for o in b.members(holder.faction):
		if Command.hears(holder, o):
			var now: int = o.timed[CADENCE].rank if CADENCE in o.timed else 0
			if now < cap:
				o.afflict(CADENCE, 1, now + 1)


# Its terms: rank is both the most Cadence stacks and First Chair's impact.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "check bonus, First Chair impact")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	return ("Each time an ally you command passes a {k:check}, every ally in command range gets +1 on checks until their turn ends, up to {r:%d}. "
			+ "The first of your side to use a skill each turn is the {k:first_chair|First Chair}: +{r:%d} {k:impact} on it.") % [c.impact_rank(), c.impact_rank()]

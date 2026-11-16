extends Behaviour

# Bandwagon: surrounded by the enamored, it's ill-advised to state the obvious. A foe that grows
# suspicious of it must pass a cha check to tell each ally (Battle.spread()), against a standard DC
# at its rank plus its cha mod - while no more than rank + 1 of its foes suspect it. Past that, the
# word's out.

const DIFFICULTY := &"standard"


# How many of the holder's foes suspect it.
static func doubters(b: Battle, holder: Unit) -> int:
	return b.units.values().filter(func(x: Unit): return x.is_alive() and x.faction and not Faction.friends(x.faction, holder.faction) \
			and x.suspects(holder) > 0).size()


# Its DC at rank (as its modifiers read it: m) plus the holder's cha mod (through m).
static func dc(holder: Unit, rank: int, m := Modifiers.NONE) -> int:
	return Difficulty.dc(DIFFICULTY, m.irank(rank, &"rank_impact")) + m.stat(holder.mod(&"charisma"), &"stat_impact")


func lets_word(b: Battle, holder: Unit, rank: int, teller: Unit, _listener: Unit) -> bool:
	var m := mods_on(holder)
	if doubters(b, holder) > m.irank(rank, &"rank_impact") + 1:
		return true
	return b.check(teller, &"charisma", null, dc(holder, rank, m)).won


# Its terms: rank raises the DC and how many may doubt it (impact); its cha mod adds to the DC (impact).
# The check is the teller's, so check tags don't fit it.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "DC, doubters")
	t.add(&"stat_impact", "DC")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	return "A foe that grows suspicious of it must pass a {k:check|Check} of its {d:cha mod} against {r:%d} + %s to tell each ally, while no more than {r:%d} foes suspect it." \
			% [Difficulty.dc(DIFFICULTY, c.impact_rank()), c.mod_text(&"charisma"), c.impact_rank() + 1]

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


static func dc(holder: Unit, rank: int) -> int:
	return Difficulty.dc(DIFFICULTY, rank) + holder.mod(&"charisma")


func lets_word(b: Battle, holder: Unit, rank: int, teller: Unit, _listener: Unit) -> bool:
	if doubters(b, holder) > rank + 1:
		return true
	return b.resolve(Check.check(teller.check_mod(&"charisma", &"offensive"), dc(holder, rank))).hit


func describe(rank: int) -> String:
	return "A foe that grows suspicious of it must pass a {k:check|Check} of its {d:cha mod} against {r:%d} + {o:cha mod} to tell each ally, while no more than {r:%d} foes suspect it." \
			% [Difficulty.dc(DIFFICULTY, rank), rank + 1]

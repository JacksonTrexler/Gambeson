extends Behaviour

# Energize: AP into Energy. Its own 2 AP are the first pair; it then spends every further pair of AP it
# can, up to rank pairs in all, and only as many as there is room for. Each pair gives 1 Energy
# (Unit.grant_energy(): Power to a powered unit); past a full bar the rest comes as Overcharge, up to
# rank x 20% of its total resource (max Energy and every reserve's max) held at once, for rank turns.
# One recovery, Overcharge and all (Burnout).

const PAIR := 2.0  # AP a point of Energy
const OVER := 0.2  # of its total resource, a rank, it may hold as Overcharge


# How much Overcharge u may hold from Energize at rank r.
static func over_cap(u: Unit, r: int) -> int:
	var total := u.max_energy
	for x in u.pools().values():
		total += x
	return floori(total * OVER * r + 0.0001)


# Energy and Overcharge it still has room for.
static func room(u: Unit, r: int) -> int:
	return maxi(u.max_energy - u.energy, 0) + maxi(over_cap(u, r) - u.overcharge, 0)


# The Energy it can give now: its own pair, and every further pair of AP it can spend, within room().
func restores(c: Cast) -> Dictionary:
	var u := c.caster
	var more := mini(c.rank - 1, floori((u.ap_for(&"skill") - PAIR) / PAIR + 0.0001))
	return {&"energy": mini(1 + maxi(more, 0), room(u, c.rank))}


func apply(c: Cast) -> void:
	var u := c.caster
	var more := mini(mini(c.rank - 1, floori(u.ap_for(&"skill") / PAIR + 0.0001)), room(u, c.rank) - 1)
	if more > 0:
		u.pay(more * PAIR, &"skill")
	var n := mini(1 + maxi(more, 0), room(u, c.rank))
	var got := u.grant_energy(n, false)
	var over := mini(n - got, maxi(over_cap(u, c.rank) - u.overcharge, 0))
	u.add_overcharge(over, c.rank, 1 if u.faction == c.battle.turn else 0)
	c.bag[&"energized"] = got + over
	u.note_recovery(&"energy", got + over)


func describe(rank: int) -> String:
	return "On itself: {r:1} Energy for every 2 AP, spending all it can up to {r:%d} Energy (its own 2 AP the first) - and no more than it has room for. Past a full bar, the rest as %s, up to {r:%d%%} of its total resource (max Energy and every reserve), for {t:%d turn%s}. Energy this way counts toward %s" % [
			rank, Glossary.term(&"overcharge", "Overcharge"), roundi(OVER * 100.0 * rank), rank, "" if rank == 1 else "s", Glossary.term(&"burnout", "Burnout")]

extends Behaviour

# Molothrus: a cowbird in another's nest. Those it fools within rank tiles (Perception.fools()) feed
# it and shield it: it siphons rank x 10% of each heal they get, and they take rank x 20% of each hit
# it takes in its place, shared between them (what doesn't share out evenly it takes itself). Its
# persona goes by Precious by default (the skill's shows_adjectives).

const SIPHON := 0.1
const SHIELD := 0.2


# The units the holder fools within rank tiles.
static func fooled(b: Battle, holder: Unit, rank: int) -> Array[Unit]:
	var out: Array[Unit] = []
	for o: Unit in b.units.values():
		if o != holder and o.is_alive() and Command.tiles(o.cell, holder.cell) <= rank and Perception.fools(b, o, holder):
			out.append(o)
	return out


func hurt(b: Battle, holder: Unit, rank: int, d: int) -> int:
	if d <= 0:
		return d
	var shields := fooled(b, holder, rank)
	if shields.is_empty():
		return d
	var each := roundi(d * minf(SHIELD * rank, 1.0)) / shields.size()
	for o in shields:
		o.damage(each)
	return d - each * shields.size()


func healing(b: Battle, holder: Unit, rank: int, t: Unit, n: int) -> int:
	if n <= 0 or t not in fooled(b, holder, rank):
		return n
	var cut := roundi(n * SIPHON * rank)
	holder.heal(cut, false)
	return n - cut


func describe(rank: int) -> String:
	return "Those it fools within {r:%d} tiles feed it {r:%d%%} of each heal they get, and take {r:%d%%} of each hit it takes in its place, shared." \
			% [rank, roundi(SIPHON * rank * 100), mini(roundi(SHIELD * rank * 100), 100)]

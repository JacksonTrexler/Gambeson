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
	var m := mods_on(holder)
	var shields := fooled(b, holder, m.irank(rank, &"rank_range"))
	if shields.is_empty():
		return d
	var each := roundi(d * minf(SHIELD * m.irank(rank, &"rank_impact"), 1.0)) / shields.size()
	for o in shields:
		o.damage(each)
	return d - each * shields.size()


func healing(b: Battle, holder: Unit, rank: int, t: Unit, n: int) -> int:
	var m := mods_on(holder)
	if n <= 0 or t not in fooled(b, holder, m.irank(rank, &"rank_range")):
		return n
	var cut := roundi(n * SIPHON * m.irank(rank, &"rank_impact"))
	holder.heal(cut, false)
	return n - cut


# Its terms: those it fools within rank tiles (range) give rank shares of heals and hits (impact); tame.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_range", "fooled within")
	t.add(&"rank_impact", "siphon, shield")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return "Those it fools within {r:%d} tiles feed it {r:%d%%} of each heal they get, and take {r:%d%%} of each hit it takes in its place, shared." \
			% [rank, roundi(SIPHON * rank * 100), mini(roundi(SHIELD * rank * 100), 100)]

extends Behaviour

# Deathlust: the fight feeds it. Any unit, of either side, killed within rank tiles of it (rank I: its
# neighbours, diagonals too) takes a share of each of its skills' exhaustion off (Exhaustion.relieve_share()),
# curved: 1 - (1 - EASE)^rank (25%, 44%, 58% ...) - and a skill it used that killed (not downed) a unit
# gains no exhaustion from that use (wearing(): Wear.killed()). Both are generic hooks (neutralized,
# wearing) any passive may use; this is only the first.

const REACH := 1  # tiles a rank
const EASE := 0.25  # of every count off at rank I; each rank more takes this share of what's left


# The share of every count a death takes off at rank r: 1 - (1 - EASE)^r.
static func share(r: int) -> float:
	return 1.0 - pow(1.0 - EASE, maxi(r, 0))


func neutralized(_b: Battle, holder: Unit, rank: int, u: Unit, _by: Unit, how: StringName) -> void:
	if how != &"killed":
		return
	var m := mods_on(holder)
	if Command.tiles(u.cell, holder.cell) <= REACH * m.irank(rank, &"rank_range"):
		holder.exhaustion.relieve_share(share(m.irank(rank, &"rank_impact")))


func wearing(_b: Battle, _holder: Unit, _rank: int, w: Exhaustion.Wear) -> void:
	if w.killed():
		w.uses = 0.0


# Its terms: rank widens the reach it feels deaths in (range) and eases more (impact); tame.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_range", "deaths felt within")
	t.add(&"rank_impact", "exhaustion eased")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	return "A unit killed within {r:%d} tile%s of it, either side's, takes {r:%d%%} off each skill's {k:exhaustion}. A skill it used that killed a unit (not downed one) gains no exhaustion from that use." \
			% [REACH * c.range_rank(), "" if REACH * c.range_rank() == 1 else "s", roundi(100.0 * share(c.impact_rank()))]

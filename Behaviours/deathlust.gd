extends Behaviour

# Deathlust: the fight feeds it. Any unit, of either side, killed within 2 tiles a rank of it takes a
# quarter of a use a rank off each of its skills' exhaustion (Exhaustion.relieve()) - and a skill it
# used that killed (not downed) a unit gains no exhaustion from that use (wearing(): Wear.killed()).
# Both are generic hooks (neutralized, wearing) any passive may use; this is only the first.

const REACH := 2  # tiles a rank
const EASE := 0.25  # uses a rank


func neutralized(_b: Battle, holder: Unit, rank: int, u: Unit, _by: Unit, how: StringName) -> void:
	if how != &"killed":
		return
	var m := mods_on(holder)
	if Command.tiles(u.cell, holder.cell) <= REACH * m.irank(rank, &"rank_range"):
		holder.exhaustion.relieve(EASE * m.irank(rank, &"rank_impact"))


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
	return "A unit killed within {r:%d} tiles of it, either side's, takes {r:%s} of a use off each skill's {k:exhaustion}. A skill it used that killed a unit (not downed one) gains no exhaustion from that use." \
			% [REACH * c.range_rank(), Skill.num(EASE * c.impact_rank())]

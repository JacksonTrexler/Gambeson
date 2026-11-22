extends Behaviour

# Wake and Rake (a passive): its rank is added to the AP a summoned unit keeps on arriving (Summon's
# keeps(): it asks every passive its summoner has, so any skill that says summon_ap() joins in). It reads
# the unit's `summon` tag, not a unit by name: whoever a summon raises with that tag keeps the AP.


func summon_ap(holder: Unit, rank: int, who: Unit) -> int:
	return holder_rank(holder, rank) if &"summon" in who.tags else 0


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "keeps")


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	return "Units tagged {k:summon|Summon} that you summon keep {r:%d} more AP on arriving." % c.impact_rank()

extends Behaviour

# Heavy Strike (a Strike form): Strike's hits are rolled as usual, but none deals its damage as it lands;
# their damage is pooled into one attack. Once the hits are rolled, a last attack roll + successes (the
# hits that landed) + rank must hit the target, or the whole Strike misses; on a hit it deals the pool +
# successes + rank (a critical doubles it, a glance halves it, as any roll's outcome). Through the
# generic `striking` hook on a Strike's Volley (Behaviour.Volley; Battle._chain()).

const POOL := &"heavy_pool"  # the damage held back so far, in the Volley's bag


func striking(b: Battle, holder: Unit, rank: int, v: Volley) -> void:
	if v.stage == &"hit":
		v.bag[POOL] = int(v.bag.get(POOL, 0)) + v.dealt
		v.dealt = 0  # held back
		return
	var pool := int(v.bag.get(POOL, 0))
	v.bag.erase(POOL)
	if v.landed <= 0 or not v.target or not v.target.is_alive():
		return  # nothing landed: the Strike already missed
	var more := v.landed + holder_rank(holder, rank)
	var last := b.roll_attack(holder, v.target, Battle.attack_check(holder, v.skill, v.bonus + more, v.defense, v.edge, v.tags))
	if not last.hit:
		v.missed = true
		return
	v.dealt = Battle.as_rolled(pool + more, last)


# Its terms: rank adds to the last roll and its damage (impact); tame.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "to hit and damage on the last roll")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	return "Strike's hits are rolled as usual but their damage is held as one {k:attack}: a last roll, + the hits that landed + {r:%d}, must hit or it all misses; hitting, it deals their damage + the hits that landed + {r:%d}." \
			% [c.impact_rank(), c.impact_rank()]

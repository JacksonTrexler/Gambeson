extends Behaviour

# Heavy Strike (a Strike form): the attacks of one skill use (Battle.use_of()) made with a Strike skill (the
# strike tag: Strike, Waterstrike, Silent Strike) - a Strike's many hits, its automatic restrikes, a Strike
# used as a Chaser's chase - are rolled as usual, but none deals its damage as it lands; their damage on each
# unit is pooled into one attack. Any other skill's attacks land as they would (a Jam that crits, then chased).
# As the use closes, a last attack roll + successes (the hits on it that landed) + rank must hit that unit,
# or the pool misses; on a hit it deals the pool + successes + rank (a critical doubles it, a glance halves
# it, as any roll's outcome). Through the generic `striking` hook on a use's Volley (Behaviour.Volley).
# A use picked afresh (aimed again by hand, an interrupt's: Chaser) is another blow.

const POOL := &"heavy_pool"  # in the use's bag: Unit -> [damage held, then its last hit's skill, bonus, defense, edge, tags]


func striking(b: Battle, holder: Unit, rank: int, v: Volley) -> void:
	var pools: Dictionary = v.bag.get_or_add(POOL, {})
	if v.stage == &"hit":
		if &"strike" not in v.tags:
			return  # not a Strike skill's: it lands
		var held: int = pools[v.target][0] if pools.has(v.target) else 0
		pools[v.target] = [held + v.dealt, v.skill, v.bonus, v.defense, v.edge, v.tags]
		v.dealt = 0  # held back
		return
	if not pools.has(v.target):
		return
	var p: Array = pools[v.target]
	pools.erase(v.target)
	if v.landed <= 0 or not v.target.is_alive():
		return
	var more := v.landed + holder_rank(holder, rank)
	v.tags = p[5]
	var last := b.roll_attack(holder, v.target, Battle.attack_check(holder, p[1], p[2] + more, p[3], p[4], p[5]))
	if not last.hit:
		v.missed = true
		return
	v.dealt = Battle.as_rolled(p[0] + more, last)


# For the AI: the use's expected damage is one blow, the pool of what lands (f.spread(): a chain stops at its first
# miss, friction counted) + a success each + rank, that lands as often as the last roll does (+ the hits and rank, at
# the friction of the roll after them): the same reading striking() makes, over every number of hits it may be.
func forecasting(_b: Battle, holder: Unit, rank: int, f: Forecast) -> void:
	if &"strike" not in f.tags:
		return
	var more := holder_rank(holder, rank)
	var sum := 0.0
	var spread := f.spread()
	for k in range(1, spread.size()):
		sum += spread[k] * (k * (f.per + 1.0) + more) * f.odds(k + (1 if k < f.rolls else 0), k + more)[0]
	f.worth = sum


# Its terms: rank adds to the last roll and its damage (impact); tame.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "to hit and damage on the last roll")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	return "The hits of one use of a {k:strike} skill (a Strike's many, its restrikes) are made as usual but their damage on a foe is held as one {k:attack}: a last attack, + the hits that landed + {r:%d} to hit, must hit or it all misses; hitting, it deals their damage + the hits that landed + {r:%d}." \
			% [c.impact_rank(), c.impact_rank()]

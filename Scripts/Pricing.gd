class_name Pricing

# The cost calculator: what a skill's AP and Energy cost come to from its terms (SkillTerms), at a rank,
# under its user's modifiers (Modifiers). One tuning table (TABLE). docs/plans/skill-modifiers.md.
#
# Points, then price:
#   its damage: its intensity's points (exponential toward the extremes), x its dice count by rank
#   + its rank bonus to hit (roll_per_rank) and to damage, x rank
#   + its stat impact, x its stat_impact factor (stat range, like rank range, is neutral)
#   + its unique effect (tame, impactful) and its contingency's payoff, tapered by how easy the
#     contingency is to meet (its share: easy costs in full, hard less)
#   - its penalty (flat, even at the extreme)
#   - adjacent (range 1, no range scaling)
# AP = ap_base + points x ap_per, rounded; Energy = points x energy_per, rounded.
#
# A skill set `priced` costs this outright. Any other keeps its hand-set ap and cost, scaled by what its
# modifiers do to its points (computed under them / computed without), so every price follows them.

const TABLE := {
	&"intensity": {&"faint": 1.5, &"mild": 2.5, &"moderate": 3.5, &"strong": 5.0, &"intense": 7.0, &"severe": 10.0, &"overwhelming": 16.0},
	&"hit_rank": 1.0,  # each + to hit a rank brings
	&"damage_rank": 1.0,  # each + damage a rank brings
	&"stat": 0.5,  # a stat adding to what it does
	&"impact": {&"": 0.0, &"tame": 2.0, &"impactful": 5.0},
	&"payoff": 1.0,  # each + to hit or damage a contingency gives; advantage counts 2
	&"taper": 0.4,  # an effect behind a contingency costs (taper + (1 - taper) x share) of itself
	&"penalty": {&"": 0.0, &"minor": 1.0, &"major": 2.0, &"severe": 3.0},
	&"adjacent": 1.0,
	&"floor": 1.0,  # the fewest points a skill comes to
	&"ap_base": 1.0,
	&"ap_per": 0.5,
	&"ap_max": 12.0,
	&"energy_per": 0.5,
}


# Its points at rank r under m.
static func points(s: Skill, r: int, m: Modifiers = Modifiers.NONE) -> float:
	var t := SkillTerms.of(s)
	var ri := m.irank(maxi(r, 1), &"rank_impact")
	var p := 0.0
	if t.damage:
		var count := 1
		if s.dice_per_rank:
			count = ri
		elif s.dice_scale:
			count = Difficulty.scaled(s.dice_scale, ri)
		p += _intensity_points(s, s.tier(ri)) * count
	p += (t.hit_per_rank * TABLE[&"hit_rank"] + t.damage_per_rank * TABLE[&"damage_rank"]) * ri
	if t.has(&"stat_impact"):
		p += TABLE[&"stat"] * m.k[&"stat_impact"]
	var share := 1.0
	var payoff := 0.0
	if s.requires:
		var q := s.requires
		share = m.share(q.share) if q.beneficial() else q.share
		if q.beneficial():
			payoff = (maxf(m.pay(q.hit), 0) + maxf(m.pay(q.damage), 0) + 2.0 * maxi(q.edge, 0)) * TABLE[&"payoff"]
	var taper: float = TABLE[&"taper"] + (1.0 - TABLE[&"taper"]) * share
	p += (TABLE[&"impact"].get(t.impact, 0.0) + payoff) * taper
	p -= TABLE[&"penalty"].get(t.penalty, 0.0)
	if adjacent(s, t):
		p -= TABLE[&"adjacent"]
	return maxf(p, TABLE[&"floor"])


# Reaches only an adjacent unit, with nothing growing it.
static func adjacent(s: Skill, t: SkillTerms) -> bool:
	return not s.passive and not s.self_only and not s.on_tile() and not s.reach_scale and s.radius <= 1.5 \
			and not t.has(&"rank_range") and not t.has(&"stat_range")


static func _intensity_points(s: Skill, tier: Tier) -> float:
	var word: StringName = s.intensity
	if not word:
		word = &"overwhelming"
		var avg := SkillTerms.average(tier)
		for b in SkillTerms.BANDS:
			if avg <= b[0]:
				word = b[1]
				break
	return TABLE[&"intensity"].get(word, 0.0)


# AP and Energy as computed at rank r under m.
static func ap(s: Skill, r: int, m: Modifiers = Modifiers.NONE) -> float:
	return clampf(roundf(TABLE[&"ap_base"] + points(s, r, m) * TABLE[&"ap_per"]), 1.0, TABLE[&"ap_max"])


static func energy(s: Skill, r: int, m: Modifiers = Modifiers.NONE) -> int:
	return roundi(points(s, r, m) * TABLE[&"energy_per"])


# What u pays in AP for s, before reserves and exhaustion (Unit.ap_cost()): computed if s is priced;
# else its ap, x what u's modifiers do to its points.
static func ap_for(u: Unit, s: Skill) -> float:
	var r := maxi(u.rank(s), 1)
	var m := u.mods(s)
	if s.priced:
		return ap(s, r, m)
	if m.empty():
		return s.ap
	return maxf(snappedf(s.ap * points(s, r, m) / points(s, r), 0.5), 0.5 if s.ap > 0.0 else 0.0)


# ...and in Energy (Unit.price()).
static func cost_for(u: Unit, s: Skill) -> int:
	var r := maxi(u.rank(s), 1)
	var m := u.mods(s)
	if s.priced:
		return energy(s, r, m)
	if m.empty():
		return s.price(r)
	return roundi(s.price(r) * points(s, r, m) / points(s, r))

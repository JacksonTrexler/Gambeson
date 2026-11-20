class_name Pricing

# The cost calculator: what a skill's AP and Energy cost come to from its terms (SkillTerms), at a rank,
# under its user's modifiers (Modifiers). One tuning table (TABLE). docs/plans/skill-modifiers.md.
#
# Points, then price:
#   its damage: its intensity's points (exponential toward the extremes), x its dice count by rank
#   + its rank bonus to hit (roll_per_rank) and to damage, x rank; a little for anything else rank adds
#   + its stat impact, x its stat_impact factor (stat range, like rank range, is neutral)
#   + its unique effect (tame, impactful) and its contingency's payoff, tapered by how easy the
#     contingency is to meet (its share: easy costs in full, hard less)
#   - its penalty (flat, even at the extreme)
#   - adjacent (range 1, no range scaling)
# AP = ap_base + points x ap_per, rounded; Energy = points x energy_per, rounded.
#
# A skill with a cost profile (Skill.costs: "high mana, low ap", "even") costs this outright, the profile
# skewing that budget: AP = ap_base + q x ap_per x w_ap, cost = q x energy_per x w_cost, its weights from
# the profile's words (levels), q its points with rank's growth past rank I x the profile's rank word.
# Any other (costs "") keeps its hand-set ap and cost, scaled by what its modifiers do to its points
# (computed under them / computed without), so every price follows them. docs/plans/w2-cost.md.

const TABLE := {
	&"intensity": {&"faint": 1.5, &"mild": 2.5, &"moderate": 3.5, &"strong": 5.0, &"intense": 7.0, &"severe": 10.0, &"overwhelming": 16.0},
	&"hit_rank": 1.0,  # each + to hit a rank brings
	&"damage_rank": 1.0,  # each + damage a rank brings
	&"rank_term": 0.25,  # each other thing rank adds to what it does (turns, push, per-rank effects...), a rank past I
	&"stat": 0.5,  # a stat adding to what it does
	&"impact": {&"": 0.0, &"tame": 2.0, &"impactful": 5.0},
	&"payoff": 1.0,  # each + to hit or damage a contingency gives; advantage counts 2, a turn half, +100% strength 2
	&"taper": 0.4,  # an effect behind a contingency costs (taper + (1 - taper) x share) of itself
	&"penalty": {&"": 0.0, &"minor": 1.0, &"major": 2.0, &"severe": 3.0},
	&"adjacent": 1.0,
	&"floor": 1.0,  # the fewest points a skill comes to
	&"ap_base": 1.0,
	&"ap_per": 0.5,
	&"ap_max": 12.0,
	&"energy_per": 0.5,
	# Cost profiles (Skill.costs): "[level] [only|needs|prefers] <dimension>" clauses, or "<word> rank", or "even".
	# The weight of each Difficulty rung a profile can name (none/low/moderate/high/very high and every synonym
	# Difficulty.WORDS has for them); LEVEL_WORDS adds what only a cost says.
	&"levels": {&"trivial": 0.0, &"easy": 0.5, &"standard": 1.0, &"difficult": 1.5, &"unfair": 2.0},
	&"level_words": {&"no": &"trivial", &"free": &"trivial", &"cheap": &"easy", &"even": &"standard"},
	&"rank": {&"flat": 0.0, &"scaled": 1.0, &"steep": 2.0},  # x rank's growth past rank I
	&"generic": [&"cost", &"energy", &"resource"],  # the resource cost, paid by whatever its tags let pay
	&"reserves": [&"mana", &"stamina", &"focus", &"sweet_nothings"],  # Reserves/<id>.tres
}

static var _profiles := {}  # profile text -> its parse (profile())


# A cost level word's weight (Difficulty's words, TABLE's levels), or -1 if it isn't one.
static func level_weight(word: StringName) -> float:
	var rung: StringName = TABLE[&"level_words"].get(word, Difficulty.word(word))
	return TABLE[&"levels"].get(rung, -1.0)


# Every word a profile takes as a level, in the order the error lists them.
static func level_names() -> Array:
	var out := []
	for w in Difficulty.WORDS:
		if level_weight(w) >= 0.0:
			out.append(w)
	return out + TABLE[&"level_words"].keys()


# A cost profile read: {ap, cost (weights), rank (growth), reserve (a Reserves/ id or &""), only (bool),
# error ("" if it parsed)}. Words in TABLE; Util/skill.py mirrors them.
static func profile(text: String) -> Dictionary:
	if _profiles.has(text):
		return _profiles[text]
	var out := {&"ap": 1.0, &"cost": 1.0, &"rank": 1.0, &"reserve": &"", &"only": false, &"error": ""}
	var clauses := text.to_lower().replace(";", ",").replace(" and ", ",").split(",", false)
	var seen_cost := false
	for raw in clauses:
		var words := Array(raw.strip_edges().replace("sweet nothings", "sweet_nothings").replace("sweet nothing", "sweet_nothings").split(" ", false))
		while words.size() > 1 and words[-1] in ["cost", "costs"] and StringName(words[-2]) in [&"ap"] + TABLE[&"generic"] + TABLE[&"reserves"]:
			words.pop_back()  # "high mana cost", "low ap cost": the dimension is mana, ap
		if words.is_empty():
			continue
		var w := " ".join(PackedStringArray(words))
		if w == "even":
			continue
		if words.size() == 2 and words[1] == "rank" and TABLE[&"rank"].has(StringName(words[0])):
			out[&"rank"] = TABLE[&"rank"][StringName(words[0])]
			continue
		var how := ""
		for x in ["only", "needs", "prefers"]:
			if x in words:
				how = x
				words.erase(x)
		if words.is_empty():
			out[&"error"] = "\"%s\": %s what?" % [raw.strip_edges(), how]
			break
		var dim := StringName(words.pop_back())
		var level := 1.0
		if not words.is_empty():
			var lw := StringName(" ".join(PackedStringArray(words)))
			level = level_weight(lw)
			if level < 0.0:
				out[&"error"] = "\"%s\": no level \"%s\" (%s)" % [raw.strip_edges(), lw, ", ".join(PackedStringArray(level_names()))]
				break
		if dim in [&"health", &"hp", &"life"]:
			out[&"error"] = "\"%s\": no skill costs health yet (a mechanic first: new-mechanic)" % raw.strip_edges()
			break
		if dim == &"ap":
			if how:
				out[&"error"] = "\"%s\": only, needs and prefers name a resource, not AP" % raw.strip_edges()
				break
			out[&"ap"] = level
			continue
		if dim not in TABLE[&"generic"] and dim not in TABLE[&"reserves"]:
			out[&"error"] = "\"%s\": no dimension \"%s\" (ap, %s, or <flat|scaled|steep> rank)" % [raw.strip_edges(), dim, ", ".join(PackedStringArray(TABLE[&"generic"] + TABLE[&"reserves"]))]
			break
		if seen_cost:
			out[&"error"] = "\"%s\": a second resource (a skill has one cost)" % raw.strip_edges()
			break
		seen_cost = true
		if how and dim in TABLE[&"generic"]:
			out[&"error"] = "\"%s\": only, needs and prefers name a reserve (%s)" % [raw.strip_edges(), ", ".join(PackedStringArray(TABLE[&"reserves"]))]
			break
		out[&"cost"] = level
		if dim in TABLE[&"reserves"]:
			out[&"reserve"] = dim
			out[&"only"] = how in ["only", "needs"]
	_profiles[text] = out
	return out


# The profile s's cost follows: its own, or the baseline's (a hand-priced skill's computed price: drift).
static func profile_of(s: Skill) -> Dictionary:
	return profile(s.costs if s.costs else "even")


# Its points at rank r under m, with rank's growth past rank I x its profile's rank word.
static func budget(s: Skill, r: int, m: Modifiers = Modifiers.NONE) -> float:
	var g: float = profile_of(s)[&"rank"]
	if r <= 1 or g == 1.0:
		return points(s, r, m)
	var p1 := points(s, 1, m)
	return maxf(p1 + g * (points(s, r, m) - p1), TABLE[&"floor"])


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
	var others: Array = t.channels[&"rank_impact"].filter(func(x: String): return x not in ["tiers", "dice_per_rank", "dice_scale", "roll_per_rank"])  # priced above
	p += TABLE[&"rank_term"] * others.size() * (ri - 1)  # whatever else rank adds to what it does
	if t.has(&"stat_impact"):
		p += TABLE[&"stat"] * m.k[&"stat_impact"]
	var share := 1.0
	var payoff := 0.0
	if s.requires:
		var q := s.requires
		share = m.share(q.share) if q.beneficial() else q.share
		if q.beneficial():
			payoff = (maxf(m.pay(q.hit), 0) + maxf(m.pay(q.damage), 0) + 2.0 * maxi(q.edge, 0) + 0.5 * maxf(m.pay(q.turns), 0)
					+ 2.0 * maxf(q.strength * m.potency, 0.0)) * TABLE[&"payoff"]  # a turn counts half; x2 strength counts 2
	elif not t.contingencies.is_empty():  # a behaviour's (Poach's bloodied foe, Gank's backing ally): the hardest tapers
		share = t.contingencies.map(func(x: Array): return m.share(x[1]) if x[2] else x[1]).min()
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


# AP and Energy as computed at rank r under m, by its profile.
static func ap(s: Skill, r: int, m: Modifiers = Modifiers.NONE) -> float:
	return clampf(roundf(TABLE[&"ap_base"] + budget(s, r, m) * TABLE[&"ap_per"] * profile_of(s)[&"ap"]), 1.0, TABLE[&"ap_max"])


static func energy(s: Skill, r: int, m: Modifiers = Modifiers.NONE) -> int:
	return roundi(budget(s, r, m) * TABLE[&"energy_per"] * profile_of(s)[&"cost"])


# The reserve its profile prefers (paid with first, Unit._funding()) or needs: a Reserves/ id, or &"".
static func reserve_of(s: Skill) -> StringName:
	return profile(s.costs)[&"reserve"] if s.costs else &""


# What u pays in AP for s, before reserves and exhaustion (Unit.ap_cost()): computed if s is priced;
# else its ap, x what u's modifiers do to its points.
static func ap_for(u: Unit, s: Skill) -> float:
	return ap_at(u, s, u.rank(s))


# ...at rank r (a description of s at some rank, as u holds it: Skill.spec()).
static func ap_at(u: Unit, s: Skill, rank: int) -> float:
	var r := maxi(rank, 1)
	var m := u.mods(s).priced()  # without the skill's own balance knobs: a tweak doesn't change its price
	if s.priced():
		return ap(s, r, m)
	if m.empty():
		return s.ap
	return maxf(snappedf(s.ap * points(s, r, m) / points(s, r), 0.5), 0.5 if s.ap > 0.0 else 0.0)


# ...and in Energy (Unit.price()).
static func cost_for(u: Unit, s: Skill) -> int:
	return cost_at(u, s, u.rank(s))


static func cost_at(u: Unit, s: Skill, rank: int) -> int:
	var r := maxi(rank, 1)
	var m := u.mods(s).priced()  # without the skill's own balance knobs: a tweak doesn't change its price

	if s.priced():
		return energy(s, r, m)
	if m.empty():
		return s.price(r)
	return roundi(s.price(r) * points(s, r, m) / points(s, r))

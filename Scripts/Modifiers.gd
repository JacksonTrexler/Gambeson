class_name Modifiers
extends RefCounted

# The modifiers on one unit's use of one skill - the skill as its holder uses it is its base plus
# these, computed here alone (Unit.mods()) - and the reader every per-rank and per-stat value goes
# through, so a modifier changes it everywhere. docs/plans/skill-modifiers.md.
#
# A modifier is a symbol or a tag. Symbols work on a skill's scaling channels (SkillTerms):
#   rho up (Density)        rank impact x (1 + f); rank range nullified, its whole range / (1 + f), its
#                           checks DENSE_CHECK x f harder (docs/plans/w4-density.md)
#   rho down (Diluted)      rank impact nullified; rank range x (1 + f), its checks DILUTE_CHECK x f easier
#   (both only on a skill SkillTerms.density_why() passes: rank impact and something to trade against it)
#   sigma down (Concentrated) stat range nullified, stat impact x (1 + f)
#   sigma up (Dispersed)    stat impact nullified, stat range x (1 + f)
#   lambda up (Restrictive) a requirement's permissive share p -> p^(1 + f), its payoff x (1 + f)
#   lambda down (Unrestrictive) p -> p^(1 / (1 + f)), its payoff / (1 + f)
# f is !RSC (rsc()) of the source's rank and how many skills it reaches. Nullified rank works as at rank
# I; a nullified stat adds nothing. A tag is added to the skill's own (Unit.skill_tags(): its damage,
# checks and everything that asks Unit.has_tag see it), if its Glossary kind fits what the skill does
# (eligible()); a tag added to the Glossary later works with no code here.

const SYMBOLS := {
	&"rho_up": ["ρ↑", "Density"], &"rho_down": ["ρ↓", "Diluted"],
	&"sigma_down": ["σ↓", "Concentrated"], &"sigma_up": ["σ↑", "Dispersed"],
	&"lambda_up": ["λ↑", "Restrictive"], &"lambda_down": ["λ↓", "Unrestrictive"],
}
# An emblem's kind (Item.scope) -> how many skills it reaches, for !RSC.
const SCOPES := {&"sigil": &"one", &"crest": &"some", &"badge": &"some", &"insignia": &"all"}
const SCOPE_NAMES := {&"sigil": "Sigil", &"insignia": "Insignia", &"crest": "Crest", &"badge": "Badge"}

# Density's and Diluted's shift on the caster's side of every check the skill makes, x f: the knobs to
# tune the bargain by (the user: "dramatically more difficult checks" dense, "easier checks" diluted).
const DENSE_CHECK := 5.0
const DILUTE_CHECK := 3.0

# Balance knobs (docs/plans/w4-knobs.md): what a skill's own data does to how it scales, tools kept for a
# skill that scales badly, never applied defensively. They ride the same factors the symbols do, so every
# read of a scaled value (rank(), irank(), stat(), Skill.reach_markup()...) takes them with no new call site:
#   Skill.scaling   a coefficient per channel, default 1 (COEFFICIENTS): x on its k; under 1 never reads
#                   below rank I, so a weaker rank scaling still lets rank I be rank I
#   beta_up / beta_down (tags, β+ / β-)   every channel's k x (1 + BETA) or / (1 + BETA)
#   cohen_up / cohen_down (tags, d+ / d-) rank impact reads COHEN / rank more (or less) than the rank
#                   itself: a big nudge at rank I, smoothing out as rank rises
# Only the tags β and d are secret: sees_knobs() says who they're shown to (KNOB_SIGHT int).
const COEFFICIENTS := {&"impact": [&"rank_impact"], &"range": [&"rank_range"], &"modified": [&"stat_impact", &"stat_range"]}
const KNOBS: Array[StringName] = [&"beta_up", &"beta_down", &"cohen_up", &"cohen_down"]
const BETA := 0.25
const COHEN := 1.5
const KNOB_SIGHT := &"very high"  # the int a viewer needs to see β and d (Difficulty.stat_at: 16, which the adventurer has across)

static var NONE := Modifiers.new()  # no modifiers: shared, never added to

var applied: Array = []  # [word, rank, scope] as added
var k := {&"rank_range": 1.0, &"rank_impact": 1.0, &"stat_range": 1.0, &"stat_impact": 1.0}
var reach := 1.0  # the skill's whole range (Skill.span()) is multiplied by this
var check := 0  # + on the caster's side of its checks (Battle.requirement(): attack rolls, saves, contests)
var lam := 1.0  # a requirement's permissive share is raised to this
var potency := 1.0  # its payoff is multiplied by this
var tags: Array[StringName] = []
var tuned := false  # the skill's own knobs are in k and cohen (tuned_for()): not a modifier, so not in applied
var cohen := 0  # +1 / -1: rank impact reads COHEN / rank more / less than rank (cohen_up, cohen_down)
static var _tuned := {}  # [effect, lam, potency] -> its tuned copy (effect())


# !RSC, the rank scaling calculation: what a source of rank r adds to a factor (1 + rsc), by how many
# skills it reaches - one (a Sigil), some (a Crest, a Badge) or all (an Insignia). Each approaches 1, so
# the boost approaches x2; the fewer skills it reaches, the less it loses.
static func rsc(rank: int, scope: StringName) -> float:
	var r := float(maxi(rank, 0))
	match scope:
		&"one":
			return (2.0 + r) / (3.0 + r)
		&"some":
			return (1.0 + r) / (2.0 + r)
		_:
			return r / (1.0 + r)


# The modifiers on u's use of s: from the emblems it wears (Item.emblem), each on the skills its scope
# reaches that it's eligible for. NONE when there are none.
static func of(u: Unit, s: Skill) -> Modifiers:
	var m: Modifiers = null
	var own := SkillTerms.of(s).knobs
	if own:
		m = own.copy()
	for it in u.items():
		if it.emblem == &"" or not eligible(it.emblem, s) or not _reaches(u, s, it):
			continue
		if m == null:
			m = Modifiers.new()
		m.add(it.emblem, it.ranked(), SCOPES.get(it.scope, &"all"))
	return m if m else NONE


static func _reaches(u: Unit, s: Skill, it: Item) -> bool:
	match it.scope:
		&"sigil":  # the leftmost eligible skill on its hotbar, of those that work there (Unit.equipped())
			for x in u.hotbar:
				if x and eligible(it.emblem, x) and u.equipped(x):
					return x == s
			return false
		&"crest":
			return not s.passive
		&"badge":
			return s.passive
	return true


# A skill's own knobs as modifiers (SkillTerms.knobs), or null if it has none.
static func tuned_for(s: Skill) -> Modifiers:
	var m := Modifiers.new()
	for w in COEFFICIENTS:
		for c in COEFFICIENTS[w]:
			m.k[c] *= float(s.scaling.get(w, 1.0))
	var beta := 1.0
	if &"beta_up" in s.tags:
		beta *= 1.0 + BETA
	if &"beta_down" in s.tags:
		beta /= 1.0 + BETA
	for c in m.k:
		m.k[c] *= beta
	m.cohen = int(&"cohen_up" in s.tags) - int(&"cohen_down" in s.tags)
	m.tuned = m.cohen != 0 or m.k.values().any(func(x: float): return x != 1.0)
	return m if m.tuned else null


# s as nobody holds it: its own knobs, or NONE (the skills screen's base values).
static func base(s: Skill) -> Modifiers:
	return SkillTerms.of(s).knobs if SkillTerms.of(s).knobs else NONE


func copy() -> Modifiers:
	var m := Modifiers.new()
	m.k = k.duplicate()
	m.cohen = cohen
	m.tuned = tuned
	return m


# Whether a viewer is shown the secret knobs (β and d): an int of KNOB_SIGHT (very high).
static func sees_knobs(u: Unit) -> bool:
	return u != null and u.stat(&"intelligence") >= Difficulty.stat_at(KNOB_SIGHT)


# These modifiers without the skill's own knobs: what its price is read under (Pricing.ap_at()), so a
# balance tweak doesn't also cost or save its user.
func priced() -> Modifiers:
	if not tuned:
		return self
	var m := Modifiers.new()
	for a in applied:
		m.add(a[0], a[1], a[2])
	return m


# Adds a modifier: a symbol, or a tag.
func add(word: StringName, rank: int, scope: StringName) -> void:
	var f := rsc(rank, scope)
	applied.append([word, rank, scope])
	match word:
		&"rho_up":
			k[&"rank_range"] = 0.0
			k[&"rank_impact"] *= 1.0 + f
			reach /= 1.0 + f
			check -= roundi(DENSE_CHECK * f)
		&"rho_down":
			k[&"rank_impact"] = 0.0
			k[&"rank_range"] *= 1.0 + f
			check += roundi(DILUTE_CHECK * f)
		&"sigma_down":
			k[&"stat_range"] = 0.0
			k[&"stat_impact"] *= 1.0 + f
		&"sigma_up":
			k[&"stat_impact"] = 0.0
			k[&"stat_range"] *= 1.0 + f
		&"lambda_up":
			lam *= 1.0 + f
			potency *= 1.0 + f
		&"lambda_down":
			lam /= 1.0 + f
			potency /= 1.0 + f
		_:
			if word not in tags:
				tags.append(word)


func empty() -> bool:
	return applied.is_empty()


# Rank r as channel c reads it: x its factor; nullified, as at rank I.
func rank(r: float, c: StringName) -> float:
	var x: float = k[c]
	if x == 0.0:
		return 1.0
	if cohen and c == &"rank_impact" and r >= 1.0:
		r = maxf(r + cohen * COHEN / r, 1.0)
	return r * x if x >= 1.0 or r < 1.0 else maxf(r * x, 1.0)  # a weaker scaling never reads below rank I


# ...as a whole number, at least 1 (r itself when nothing changes it).
func irank(r: int, c: StringName) -> int:
	return r if k[c] == 1.0 and not (cohen and c == &"rank_impact") else maxi(roundi(rank(r, c)), 1)


# A stat mod m as channel c reads it: x its factor (nullified: 0).
func stat(m: int, c: StringName) -> int:
	return m if k[c] == 1.0 else roundi(m * k[c])


func statf(x: float, c: StringName) -> float:
	return x * k[c]


# A requirement's permissive share p, tightened or loosened by lambda.
func share(p: float) -> float:
	return p if lam == 1.0 else pow(clampf(p, 0.0, 1.0), lam)


# A contingent payoff n, made more or less potent by lambda: at least 1 where it was more than 0.
func pay(n: int) -> int:
	if potency == 1.0 or n == 0:
		return n
	var x := roundi(n * potency)
	return maxi(x, 1) if n > 0 else mini(x, -1)


# A passive's effect e at rank r and strength, as the holder's stats read it (Unit._gather_effects()):
# [effect, rank, strength]. A per-rank effect takes its rank_impact rank; a per-stat one its stat_impact
# factor in its strength; one that holds above some HP (Stoneskin) has its threshold and, where it
# helps, its amount tuned by lambda (a copy, kept).
func effect(e: Effect, r: int, strength := 1.0) -> Array:
	var r2 := irank(r, &"rank_impact") if e.per_rank else r
	var s2: float = strength * (k[&"stat_impact"] if e.per_mod or e.per_stat else 1.0)
	var e2 := e
	if e.above_hp > 0.0 and (lam != 1.0 or potency != 1.0):
		var key := [e, lam, potency]
		if key not in _tuned:
			var c: Effect = e.duplicate()
			c.above_hp = 1.0 - share(1.0 - e.above_hp)
			if e.helps() > 0:
				c.amount = 1.0 + (e.amount - 1.0) * potency if e.op == "mul" else e.amount * potency
			_tuned[key] = c
		e2 = _tuned[key]
	return [e2, r2, s2]


# The modifiers as a short label: "ρ↑ σ↓ fire" (the HUD's tooltip).
func label() -> String:
	var out: PackedStringArray = []
	for a in applied:
		out.append(SYMBOLS[a[0]][0] if a[0] in SYMBOLS else String(a[0]))
	return " ".join(out)


# A tag's kind as the Glossary has it: its term's kind, or damage for a blow's stuff (fire, light...: Glossary.DAMAGE_TAGS); ""
# for a word the Glossary doesn't know.
static func kind(t: StringName) -> StringName:
	return Glossary.kind(t)


static func eligible(word: StringName, s: Skill) -> bool:
	return why_not(word, s) == ""


# Why modifier `word` can't act on s ("" if it can): a symbol needs the channel it boosts (or, for
# lambda, a contingency that helps); a tag needs what its kind acts on - damage, a check, effects it
# puts on, a tile it's aimed at.
static func why_not(word: StringName, s: Skill) -> String:
	if s == null or s.stub:
		return "not built"
	var t := SkillTerms.of(s)
	match word:
		&"rho_up", &"rho_down":
			return t.density_why()
		&"sigma_down":
			return "" if t.has(&"stat_impact") else "no stat impact scaling"
		&"sigma_up":
			return "" if t.has(&"stat_range") else "no stat range scaling"
		&"lambda_up", &"lambda_down":
			return "" if t.beneficial_contingency() else "no contingency"
	if word in s.tags:
		return "already %s" % word
	if word in Difficulty.LADDER or word in Difficulty.MAGNITUDE:  # the rungs, not their synonyms: light and heavy are tags too
		return "a difficulty, not a tag"
	match kind(word):
		&"damage":
			return "" if t.damage else "deals no damage"
		&"check":
			return "" if t.check else "has no check"
		&"condition":
			return "" if t.conditions else "puts no effects on"
		&"ground":
			return "" if t.ground else "not aimed at a tile"
		&"target":
			return "a target word"
	return "not a Glossary tag"


# Every modifier word: the symbols, then every tag the Glossary knows of an eligible kind.
static func words() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(SYMBOLS.keys())
	for t in Glossary.TERMS:
		if Glossary.TERMS[t][1] != &"target" and t not in Difficulty.LADDER and t not in Difficulty.MAGNITUDE:  # not the difficulty words
			out.append(t)
	for t in Glossary.added:
		if Glossary.added[t][1] != &"target":
			out.append(t)
	for t in Glossary.DAMAGE_TAGS:
		if t not in out:
			out.append(t)
	return out

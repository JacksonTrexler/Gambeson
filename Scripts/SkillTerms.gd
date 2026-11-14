class_name SkillTerms
extends RefCounted

# What a skill does and how it scales, in one description the cost calculator (Pricing) and modifiers
# (Modifiers) read. Derived from its fields, so every skill has terms without edits; a behaviour adds
# its own (Behaviour.terms()). docs/plans/skill-modifiers.md.
#
# Four channels of scaling, each a list of what scales that way:
#   rank_range   what rank adds to its reach: radius_per_rank, reach_scale, blast
#   rank_impact  what rank adds to what it does: tiers by rank, roll_per_rank, dice_per_rank, dice_scale,
#                turns_per_rank, push, pull, per_wound, restores, per-rank effects
#   stat_range   what its user's stats add to its reach: radius_mod, radius_stat
#   stat_impact  what its user's stats add to what it does: a tier's stat, heal_mods, turns_mod, an
#                effect's per_mod (passives) or by_mod (put on)

const CHANNELS: Array[StringName] = [&"rank_range", &"rank_impact", &"stat_range", &"stat_impact"]

# The user's damage intensities (low, moderate low, moderate, high, extreme) on Difficulty.MAGNITUDE.
const INTENSITY := {&"low": &"faint", &"moderate_low": &"mild", &"moderate": &"moderate", &"high": &"strong", &"extreme": &"severe"}
# A tier's average damage at rank I (no mod) -> its intensity, for skills that don't name one.
const BANDS := [[3.0, &"faint"], [4.5, &"mild"], [6.0, &"moderate"], [8.0, &"strong"], [10.0, &"intense"], [14.0, &"severe"]]
const IMPACTS: Array[StringName] = [&"tame", &"impactful"]
const PENALTIES: Array[StringName] = [&"minor", &"major", &"severe"]

var skill: Skill
var channels := {}  # channel -> Array[String] of what scales so
var intensity := &""  # a Difficulty.MAGNITUDE word, or "" for no damage
var damage := false  # deals damage
var check := false  # has a check: an attack roll, a save, a contest, a check it imposes
var conditions := false  # puts effects on
var ground := false  # aimed at a tile
var impact := &""  # its unique effect beyond damage: "", tame, impactful
var penalty := &""  # "", minor, major, severe
var hit_per_rank := 0.0  # + to hit per rank
var damage_per_rank := 0.0  # + damage per rank (a behaviour's +rank damage)
var contingencies: Array = []  # [what (String), share, beneficial] - a requirement or an above_hp effect

static var _cache := {}


static func of(s: Skill) -> SkillTerms:
	if s not in _cache:
		_cache[s] = SkillTerms.new(s)
	return _cache[s]


# Forgets what it read (tests that change a skill's fields).
static func forget(s: Skill = null) -> void:
	if s:
		_cache.erase(s)
	else:
		_cache.clear()


func _init(s: Skill) -> void:
	skill = s
	for c in CHANNELS:
		channels[c] = [] as Array[String]
	if s.radius_per_rank:
		add(&"rank_range", "radius_per_rank")
	if s.reach_scale:
		add(&"rank_range", "reach_scale")
	if s.blast > 0.0:
		add(&"rank_range", "blast")
	if _tiers_grow():
		add(&"rank_impact", "tiers")
	for f in ["roll_per_rank", "dice_per_rank", "dice_scale", "turns_per_rank", "push", "pull", "per_wound", "restores"]:
		if s.get(f):
			add(&"rank_impact", f)
	if s.effects.any(func(e: Effect): return e.per_rank):
		add(&"rank_impact", "effects")
	if s.radius_mod:
		add(&"stat_range", "radius_mod")
	if s.radius_stat:
		add(&"stat_range", "radius_stat")
	if s.tiers.any(func(t: Tier): return t.stat != &""):
		add(&"stat_impact", "tier stat")
	if not s.heal_mods.is_empty():
		add(&"stat_impact", "heal_mods")
	if s.turns_mod:
		add(&"stat_impact", "turns_mod")
	if s.effects.any(func(e: Effect): return (e.per_mod != &"" and s.passive) or e.by_mod != &""):
		add(&"stat_impact", "effects")
	hit_per_rank = s.roll_per_rank
	damage = not s.tiers.is_empty()
	check = s.attacks() or s.contests() or s.evadable
	conditions = not s.effects.is_empty() or s.grants != null
	ground = s.on_tile()
	intensity = s.intensity if s.intensity else _derived_intensity()
	impact = s.impact if s.impact else _derived_impact()
	penalty = s.penalty if s.penalty else _derived_penalty()
	for e in s.effects:
		if e.above_hp > 0.0:
			contingencies.append(["above %d%% HP" % roundi(e.above_hp * 100.0), 1.0 - e.above_hp, e.helps() > 0])
	if s.requires:
		contingencies.append([s.requires.said(1, s.requires.share), s.requires.share, s.requires.beneficial()])
	for b in s.behaviours:
		if b:
			b.terms(self)


# Notes that `what` scales by channel c (a behaviour's own: Kick's push).
func add(c: StringName, what: String) -> void:
	assert(c in CHANNELS, "no channel %s" % c)
	if what not in channels[c]:
		channels[c].append(what)


func has(c: StringName) -> bool:
	return not channels[c].is_empty()


# A contingency lambda can act on: one that helps.
func beneficial_contingency() -> bool:
	return contingencies.any(func(x: Array): return x[2])


# Rank or stat scaling of any kind.
func scales() -> bool:
	return CHANNELS.any(func(c): return has(c))


func _tiers_grow() -> bool:
	if skill.tiers.size() < 2:
		return false
	var first := skill.tier(1)
	return skill.tiers.any(func(t: Tier): return t != first and average(t) != average(first))


# A tier's average damage, no mod.
static func average(t: Tier) -> float:
	return 0.0 if t == null else t.power + t.dice.x * (t.dice.y + 1) / 2.0


func _derived_intensity() -> StringName:
	if skill.tiers.is_empty():
		return &""
	var lowest: Tier = skill.tiers[0]
	for t in skill.tiers:
		if t.rank < lowest.rank:
			lowest = t
	var avg := average(lowest)
	for b in BANDS:
		if avg <= b[0]:
			return b[1]
	return &"overwhelming"


func _derived_impact() -> StringName:
	var s := skill
	if s.disables or s.kills or s.levels_down or s.binds or s.shapes or s.rifts or s.exits or s.humbles or s.drags_to or s.engulfs:
		return &"impactful"
	if conditions or s.holds() or not s.behaviours.is_empty() or s.push or s.pull or s.heals() or s.boost_pool or s.zone or s.lays or s.flamewall:
		return &"tame"
	return &""


func _derived_penalty() -> StringName:
	var s := skill
	if s.requires and not s.requires.beneficial():
		return &"minor" if s.requires.share >= 0.5 else &"major"
	if s.disadvantage or s.roll_bonus <= -3:
		return &"major"
	if s.roll_bonus < 0:
		return &"minor"
	return &""

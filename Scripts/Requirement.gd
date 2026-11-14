class_name Requirement
extends Resource

# A contingency on a skill (Skill.requires): a test of the moment it's used in, and what it gives while
# that test is met (its payoff). Its share is how permissive it is - the slice of its range that meets it
# (below half HP: 0.5; at least 80% Energy: 0.2) - so lambda modifiers can tighten or loosen it
# (Modifiers.share()) and the cost calculator can taper what it pays for (Pricing). A payoff below 0 is a
# penalty contingency (from concealment, or at disadvantage): lambda leaves those alone.
# docs/plans/skill-modifiers.md.

# test -> how its share reads: "below" a share of max, "above" (1 - share) of max, "tiles" share x SPAN
# tiles (x rank when per_rank), "flag" a yes/no the share only prices.
const TESTS := {
	&"hp_below": "below", &"hp_above": "above", &"energy_above": "above", &"energy_below": "below",
	&"target_hp_below": "below", &"target_hp_above": "above", &"ally_within": "tiles", &"concealed": "flag",
}
const SPAN := 12.0  # tiles a tile requirement's share is taken over, so lambda can work on it as a share

@export var test := &"hp_below"
@export var share := 0.5  # how permissive: the slice of the range that meets it
@export var per_rank := false  # tiles: share x SPAN x rank (within rank tiles of an ally: share 1 / 12)
@export var hit := 0  # met: + to its attack roll
@export var damage := 0  # met: + to its damage
@export var edge := 0  # met: advantage (1) or disadvantage (-1) on its attack roll


# The test's measure in tiles at rank r, for a share p (tile tests).
func tiles(p: float, r: int) -> float:
	return p * SPAN * (r if per_rank else 1)


# Helps rather than hinders: what lambda modifiers act on.
func beneficial() -> bool:
	return hit + damage + edge > 0


# Whether it's met for caster on target at rank r, with permissive share p (Modifiers.share(share)).
# `allies`: the caster's living allies (Battle passes them); `concealed`: the caster's concealment.
func met(caster: Unit, target: Unit, r: int, p: float, allies: Array = [], concealed := 0) -> bool:
	match test:
		&"hp_below":
			return caster.hp <= p * caster.max_hp
		&"hp_above":
			return caster.hp >= (1.0 - p) * caster.max_hp
		&"energy_above":
			return caster.energy >= (1.0 - p) * caster.max_energy - 0.0001
		&"energy_below":
			return caster.energy <= p * caster.max_energy
		&"target_hp_below":
			return target != null and target.hp <= p * target.max_hp
		&"target_hp_above":
			return target != null and target.hp >= (1.0 - p) * target.max_hp
		&"ally_within":
			var reach := tiles(p, r)
			var at: Vector2i = target.cell if target else caster.cell
			return allies.any(func(a: Unit): return a != caster and a.is_alive() and Command.tiles(a.cell, at) <= reach + 0.0001)
		&"concealed":
			return concealed > 0
	return false


# "below half HP", "at least 80% Energy", "within 2 tiles of an ally": the test at rank r, share p.
func said(r: int, p: float) -> String:
	var pct := func(x: float) -> String: return "%d%%" % roundi(x * 100.0)
	match test:
		&"hp_below":
			return "at or below %s HP" % pct.call(p)
		&"hp_above":
			return "at or above %s HP" % pct.call(1.0 - p)
		&"energy_above":
			return "with at least %s Energy" % pct.call(1.0 - p)
		&"energy_below":
			return "with at most %s Energy" % pct.call(p)
		&"target_hp_below":
			return "on a foe at or below %s HP" % pct.call(p)
		&"target_hp_above":
			return "on a foe at or above %s HP" % pct.call(1.0 - p)
		&"ally_within":
			return "within %s tiles of an ally" % Skill.num(snappedf(tiles(p, r), 0.1))
		&"concealed":
			return "from concealment"
	return String(test)

class_name Displace
extends Behaviour

# Forced movement: landing, it moves the target - drawn toward the caster (Sing) or driven straight away
# from it, a tile at a time and stopping at what's in the way, or teleported away to the furthest free
# tile on that line (Send Off). Battle.displace() does the moving: no movement spent, the ground passed
# over does nothing, and nobody turns (docs/plans/facing.md). Any skill, item skill or reaction can
# carry one: knock-back and draw-in are this, not a flag.

@export var toward := false  # draws the target toward the caster, else drives it away
@export var teleport := false  # puts it straight there (Battle.place()): the furthest free tile on the line, so many tiles out or nearer
@export var tiles := 1  # how far, x rank: rank impact for a walk, rank range for a teleport (its reach)
@export var stat := &""  # + the caster's mod in this, through its stat range (Send Off: charisma)
@export var foes_only := true  # moves only a foe (Sing's draw; a push); false: allies too (Send Off)


# The first Displace on s that draws its target in (Sing; the AI sings with it), or null.
static func draws(s: Skill) -> Displace:
	for b in s.behaviours:
		if b is Displace and b.toward:
			return b
	return null


# How far it moves c's target: tiles x its rank, + the caster's mod in stat (and Impassioned Fighter's
# zeal beside it, as on the skill's own mod).
func reach(c: Cast) -> int:
	var n := tiles * (c.range_rank() if teleport else c.impact_rank())
	if stat:
		n += maxi(c.stat_mod(c.caster.mod(stat, c.caster.skill_tags(c.skill)), &"stat_range"), 0) + Battle.passion(c.caster, c.target)
	return n


func apply(c: Cast) -> void:
	if (foes_only and not c.foe) or not c.target.is_alive() or c.target == c.caster:
		return
	var check := c.skill.check
	if check and check.suspicion and not c.battle.lured(c.caster, c.skill, c.target):
		return  # its song moves only one it enraptures (Sing)
	c.battle.displace(c.target, c.caster.cell, -1 if toward else 1, reach(c), teleport)


# Teleporting, it isn't a unique effect beyond its numbers (Send Off); a push or a draw is tame.
func impact() -> StringName:
	return &"" if teleport else &"tame"


func _label() -> String:
	return "pull" if toward else ("sends" if teleport else "push")


# How far it goes is rank impact (a walk) or rank range (a teleport), and stat range for its mod.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_range" if teleport else &"rank_impact", _label())
	if stat:
		t.add(&"stat_range", _label())


func describe(rank: int) -> String:
	var c := Cast.new()
	c.rank = rank
	return describe_as(c)


func describe_as(c: Cast) -> String:
	var dual := c.skill != null and c.skill.dual
	var m: Modifiers = c.mods if c.mods else Modifiers.NONE
	if teleport:
		var mod := (" %s +" % Skill._mod(stat, &"stat_range", m)) if stat else ""
		return "Teleports it%s {r:%d} tiles straight %s the caster, to the furthest free tile on that line" % [mod, tiles * c.range_rank(), "toward" if toward else "away from"]
	var n := tiles * c.impact_rank()
	var s := "" if n == 1 else "s"
	if toward:
		return "%s it up to {r:%d} tile%s toward the caster" % ["On a foe: draws" if dual and foes_only else "Draws", n, s]
	return "%sDrives it up to {r:%d} tile%s straight away from the caster, stopping at what's in the way" % ["On a foe: " if dual and foes_only else "", n, s]

class_name Boost
extends Behaviour

# On an ally, AP at once for this use (Igna: skill AP; Aetha, Prestidigitation: movement): the caster's
# mod in `mod` (stat impact) + rank (rank impact) + its contingency's payoff, and that is the whole of it.
# On a foe it does nothing.

@export var pool := &""  # the AP it gives: &"skill", &"move" (AP.gd)
@export var mod := &""  # the caster's mod in this adds to it


func whole(c: Cast) -> bool:
	return not c.foe


func apply(c: Cast) -> void:
	if c.foe:
		return
	var b := c.battle
	var n := c.stat_mod(c.caster.mod(mod, c.caster.skill_tags(c.skill))) + c.impact_rank() + int(b.requirement(c.caster, c.skill, c.target, c.rank)[1])
	c.target.ap.append(AP.new(maxf(n, 0.0), pool))


func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "boost_pool")
	if mod:
		t.add(&"stat_impact", "boost_mod")


func describe(rank: int) -> String:
	var c := Cast.new()
	c.rank = rank
	return describe_as(c)


func describe_as(c: Cast) -> String:
	return "On an ally: it gains %s + {r:%d} %s AP at once" % [Skill._mod(mod, &"stat_impact", c.mods if c.mods else Modifiers.NONE), c.impact_rank(), pool]

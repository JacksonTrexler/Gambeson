extends Behaviour

# Clairvoyance: channeled on the caster. Foes its side can't see within its wisdom score + its rank for
# the channel in tiles, walls or not, are pinged where they stand (Battle.ping(): location only, a
# stack of the caster's suspicion of each tile). As each of its side's turns ends while it holds, the
# pings move to where the foes are now, then its rank for the channel rises by 1. Used again while it
# channels: it stops, free. Its reach is rank and stat range, read through its caster's modifiers (Density cuts it); each ping's stacks are rank impact.


# How far u's channel of it reaches now: wisdom score + the channel's rank, through u's modifiers.
func reach(u: Unit) -> int:
	if u.channel == null or self not in u.channel.skill.behaviours:
		return 0
	var m := u.mods(u.channel.skill)
	var r := m.statf(u.stat(&"wisdom"), &"stat_range") + m.rank(u.channel.rank, &"rank_range")
	return roundi(maxf(r * m.reach, 1.5 if r >= 1.5 else 1.0) if m.reach != 1.0 else r)  # Density's cut (Modifiers.reach), as Skill.span()


# The stacks of suspicion each ping of it adds: its learned rank (not the channel's rising one), rank impact.
func stacks(u: Unit) -> int:
	var s := u.channel.skill
	return u.mods(s).irank(maxi(u.rank(s), 1), &"rank_impact")


func apply(c: Cast) -> void:
	var b := c.battle
	var u := c.caster
	b.end_channel(u)
	u.channel = Unit.Channel.new(c.skill, u.cell)
	u.channel.rank = c.rank
	b.ping(u, reach(u), stacks(u))
	b.channeled.emit(u, c.skill, u.cell)


func held(b: Battle, holder: Unit) -> void:
	b.ping(holder, reach(holder), stacks(holder))  # the pings move to where the foes are now...
	holder.channel.rank += 1  # ...then it ranks up


func recast_stops() -> bool:
	return true


func senses() -> bool:
	return true


# Its reach: rank (the channel's, rising) and wisdom score, both range; the stacks each ping adds, its rank
# (impact); a tame effect.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_range", "ping reach")
	t.add(&"rank_impact", "stacks")
	t.add(&"stat_range", "ping reach")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var k: float = c.mods.k[&"stat_range"] if c.mods else 1.0
	return "%s on the caster: foes its side can't see within its wisdom%s + {r:%d} tiles, walls or not, show where they are as black shapes, and nothing more (%s). Each adds {r:%d} stack%s of %s of its tile. As each of its turns ends while it holds, they move to where the foes are now, and the rank rises by 1 for the channel. Cast again to stop" % [
			Glossary.term(&"channeled", "Channeled"), "" if k == 1.0 else " x %s" % Skill.num(snappedf(k, 0.01)), c.range_rank(), Glossary.term(&"pinged", "pinged"), c.impact_rank(), "" if c.impact_rank() == 1 else "s", Glossary.term(&"suspicion", "suspicion")]

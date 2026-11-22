extends Behaviour

# Summon, cast on a tile: `per_rank` x rank units of `scene` rise on the caster's side, each on the free
# tile nearest the one aimed at (Battle.summon(); fewer if the map has no room). They are ordinary units
# of the caster's side - its allies to command or leave to the AI, hurt and killed like any other - and
# arrive with their turn's AP spent but for a few they keep (keeps()): rank + the cast's stat mod + what the
# summoner's passives add (Behaviour.summon_ap(): Wake and Rake), at most what they had. Permanent: nothing ends
# them but a death. Skeleton is its first user; any later summon sets another `scene` and `per_rank`.
# Its rank is rank impact (the count), so a modifier that raises it raises the host.

@export var scene: PackedScene
@export var per_rank := 2


# How many it raises: per_rank x its rank impact.
func count(c: Cast) -> int:
	return per_rank * c.impact_rank()


func bodies(c: Cast) -> int:
	return count(c)


func apply_at(c: Cast, cell: Vector2i) -> void:
	for i in count(c):
		var u := c.battle.summon(scene, c.caster.faction, cell)
		if u == null:
			break  # no room anywhere: the rest don't come
		var keep := float(keeps(c, u))
		for p in u.ap:  # risen this turn: all spent but what they keep, the first pools first
			var held := minf(p.amount, keep)
			keep -= held
			p.amount = held


# The AP a summoned unit keeps: its cast's rank + stat mod, plus each passive its summoner has that adds
# (Behaviour.summon_ap(): any, by the unit's tags, not by name), never below 0.
func keeps(c: Cast, who: Unit) -> int:
	var n := c.impact_rank() + c.stat_mod(c.caster.mod(c.skill.stat(), c.caster.skill_tags(c.skill)))
	for x in c.caster.slots:
		if x.rank > 0 and x.skill.passive and c.caster.equipped(x.skill):
			for h in x.skill.behaviours:
				n += h.summon_ap(c.caster, x.rank, who)
	return maxi(n, 0)


func tile_target() -> StringName:
	return &"tile"


# Its count is rank impact; raising units is a thing of its own (impactful).
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "summon")
	if t.impact == &"":
		t.impact = &"impactful"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var n := count(c)
	var who: String = scene.get_state().get_node_name(0) if scene else "unit"
	return "Raises {r:%d} %s%s on the free tiles nearest a tile, on the caster's side: ordinary units that keep %s AP on arriving and act in full from next turn" % [n, who, "" if n == 1 else "s", "{r:%d} + %s" % [c.impact_rank(), c.mod_text(c.skill.stat() if c.skill else &"intelligence")]]

class_name Skill
extends Resource

@export var name := ""
@export var passive := false  # works while its slot is on; costs nothing, can't be cast
@export var toggle := false  # passive: its holder switches it on and off (from the hotbar)
@export var inherent := false  # part of what its holder is (Starkind): it can't be disabled or removed, and takes no slot
@export var min_tier := 0  # its tier is at least this (Synergy: 2), wherever it's offered (Unit.tier())
@export var hybrid := false  # passive with an active part: using it costs its AP (Personify: adjusting its persona; Battle.personify())
@export var tags: Array[StringName] = []  # e.g. physical, dark, magical, str, wis; martial, magical, specialist: its category
@export var effects: Array[Effect] = []  # passives: on the holder; actives: put on the target
@export var max_rank := 0  # the highest rank it can be raised to; 0: no cap
@export var glyph := ""  # up to 2 characters standing for it on skill trees, its placeholder icon; empty: its initials
@export var studies := ""  # a Wizard's expanded study (Dabblings): what it lets its holder pick, up to its rank (TreeChoice.by: "religious domains")
@export var ai := false  # designed by an AI, a placeholder open for the user's design: its name shows with ?? after it (title())
@export var classes: Array[StringName] = []  # a class feature: only units of these classes learn it (Paladin: Smite), tagged with them; anyone else meeting it on a tree it borrows (a Cleric's or Wizard's Eros) sees it locked (Unit.missing())
@export var rank_cost := 0  # skill points for rank II, times rank_growth for each rank after (Clever Disguise: 4, 8, 16...); 0: the usual 1 + r^2
@export var rank_growth := 2.0
@export var downed: Downed  # passive: on its last life, its holder lingers Downed at 0 HP rather than dying, by this rule x rank (Tenacity, Grudge; Scripts/Downed.gd)
@export var behaviours: Array[Behaviour] = []  # what it does beyond these flags, each saying so itself: run in order as it lands (Kick; Scripts/Behaviour.gd, Behaviours/)

@export_group("Active")
@export var ap := 0.0
@export var cost := 0  # paid in Energy, or a reserve that can pay for this skill's tags
@export var cost_per_rank := false  # cost x rank (starter spells)
@export var ap_with: Dictionary[Reserve, float] = {}  # AP factor when fully paid with a reserve (Hex: mana 0.5)
@export var needs: Reserve  # it can only be paid with this reserve (a Warlock's higher-tier skills: a Sweet Nothing)
@export var cost_with: Dictionary[Reserve, float] = {}  # cost factor paid with a reserve, once the caster has opened it up to this skill's tier (starter spells: mana 0.5, opened by Mana)
@export var radius := 0.0  # range before reach and size
@export var radius_stat := &""  # plus the caster's score in this stat itself, not its mod (Gasp: charisma)
@export var radius_mod := &""  # plus the caster's mod in this stat, reaching an adjacent unit at least (starter spells: intelligence)
@export var hostile := true  # targets enemies (false: allies)
@export var dual := false  # usable on allies and foes alike: allies get its effects, foes its damage (starter spells)
@export var either := false  # usable on allies and foes alike, its effects on both (wauaw)
@export var rolls := true  # used on a foe: rolls d20 + attack mod against its Defense first (Battle.cast())
@export var advantage := false  # that roll is the better of two d20s (Gasp)
@export var roll_per_rank := 0  # ...plus this x rank (Gasp: rank)
@export var roll_bonus := 0  # ...plus this (Jugular: -1, with roll_per_rank 1: rank - 1)
@export var disadvantage := false  # that roll is the worse of two d20s (Jugular)
@export var sure_crit := false  # a hit is a critical (Jugular)
@export var recast_on_crit := false  # a natural 20 on its roll recasts it at once on the same foe, free (Jugular; Battle.cast())
@export var decays := 0.0  # its effects' strength falls this share a tile past the first between caster and target, set as they're put on; none paid wholly with mana (Rejuvinate: 0.05)
@export var engulfs := false  # used on a foe: a contest in its stat; won, the caster moves into the foe's tile, sharing it (Coalescing; Battle.engulf())
@export var mist_only := false  # only while its caster is a mist (Vaporize), and the only kind of skill a mist can use (Coalescing)
@export var rifts := false  # aimed at a tile in sight within range (over walls from rank III): opens a door to a domain, kept open while its caster channels it (or not: Alt-click), its count starting once it stops; used again, the channel stops (Rift; Battle.open_rift())
@export var grapples := false  # its effects hold the foe (grappled) until it breaks free by moving away (Drown; Battle._break_free())
@export var drowns := Vector2i.ZERO  # each turn the foe it holds ends submerged (Battle.submerged()), these dice + the caster's mod in its stat (Drown: 1d12)
@export var links := false  # on itself: links it with its teammates within its cha mod in tiles (at least 1) and its leader, to pool what they make out (Coordinate; Battle._link())
@export var prays := false  # prays to the caster's god, an effect by god (Pray; Battle.pray())
@export var auto := false  # used at once, landing on the nearest units in range - allies and foes alike - no more than its rank (Sing; Battle.auto_targets())
@export var check: SkillCheck  # used on a foe: the check it makes in place of the attack roll - a save (Haluca: wisdom), a contest (Drown's drag) - or beside it (Sing's on the suspicious); lost, it misses (Scripts/SkillCheck.gd, Battle.skill_opts())
@export var disables := false  # a curse: with its save, the caster's luck-rounded sqrt(rank) of the foe's skill slots are switched off, right to left, for its turns; the foe adds the ranks of the skills in them to its save (Brainfog; Unit.disable_order())
@export var tiers: Array[Tier] = []  # damage by rank; none: no damage (tagged energy: it drains Energy first - Unit.drain())
@export var weapon_tag := false  # its damage takes its wielder's weapon's damage tag, or blunt bare-handed (Strike; Item.damage_tag, Battle.hit_tags())
@export var levels_down := false  # rank rolls of d20 + the caster's mod in its stat, each beating the higher of the foe's average stat mod + level and its last stand; each that does takes a level off it for rank - misses turns (Level Down; Battle._level_down())
@export var opening := false  # only as its holder's turn opens: before it moves or spends AP (Flamedance)
@export var renames := ""  # learned, Strike goes by this name (Decisive Strike; Unit.skill_name())
@export var exclusive := &""  # only one skill of this group can be learned (the low-tier Strike upgrades: strike_form)
@export var waives := &""  # opens a general tree's skills up to its rank in tier without their usual needs - general (Generalist), martial (Martialist), magical (Thaumaturgist); a tree its class doesn't have, it shows, one tier lower (Unit.missing())
@export var kills := false  # the foe's last stand, cut by how hurt it is (execute), against d20 + the caster's mod in its stat: failing, it takes 1 true damage and dies (Death; Battle._death())
@export var god_tag := false  # its damage takes the tag of its caster's god as well (Smite; God.tag): Urlo's energy drains Energy first
@export var carry := 0.0  # energy damage: this x (rank - 1) of what's left once the target's Energy is gone goes on to HP (Smite: 0.2)
@export var hits_per_rank := false  # Strike III hits three times
@export var chain := false  # each hit rolls on its own: a miss ends it, and each hit in a row is -1 to hit and damage (Strike; Battle._chain())
@export var grants: Skill  # also puts this skill's effects on the target (Stonegift: Stoneskin)
@export var binds: Item  # on a hit, bound onto the target in place of its trinket at the skill's rank - its weight the rank - the trinket stowed till it comes off (Judgement: Shackles; Battle._bind())
@export var turns := 0  # how many of the target's turns put-on effects last (zones: the caster's)
@export var turns_per_rank := 0  # ...plus this many per rank (Sola: rank turns)
@export var turns_mod := &""  # ...plus the caster's mod in this (Haluca: charisma)
@export var fades := false  # ...after which they lose a rank a turn, rather than ending (Clever Disguise)
@export var until_move := false  # they last until the target moves rather than standing still - with no turns set, with no limit (Hide)
@export var self_only := false  # used on its user alone (Hide)
@export var pays_with := &""  # the AP it draws on first, then general AP: move - paid with movement and AP (Meditate); "" skill AP
@export var respecs := false  # its user may then move up to its rank in points between its core stats, down one for each up - as far as it knew itself before (Meditate; Battle.respec())
@export var investigated := false  # the target rolls once (d20 + stat mod + rank), and enemies that can see it investigate against that; those who meet it aren't fooled by it (Battle.investigate())

@export_group("Channel")  # cast on a tile, it channels; cast again for strike_ap and strike_cost to strike (Metea; Battle._detonate())
@export var channel := false
@export var strike_ap := 0.0
@export var strike_cost := 0
@export var blast := 0.0  # the explosion's radius, per rank
@export var dice_per_rank := false  # its tier's dice rolled once per rank (Metea II: 2d12)

@export_group("Heal")  # used on an ally (Battle.mend())
@export var heal_mods: Array[StringName] = []  # heals the caster's mods in these, added up (First Aid: dexterity, wisdom; Renew: wisdom)...
@export var heal_split := 1  # ...divided by this (First Aid: 2; luck rounds)...
@export var heal_bonus := 0  # ...plus this (First Aid: 1), at least 1 HP
@export var squared := false  # clears wounds up to rank x rank, not its rank (Renew)
@export var restores := 0.0  # the recipient gets this x rank AP back (Renew)
@export var per_wound := 0  # this x rank more HP for each wound it clears (First Aid: 1)

@export_group("Area")  # cast on a cell rather than a unit: what it does there is a behaviour's (Behaviour.apply_at(): Darkstone's zone, Wildfire's cone), these its numbers
@export var difficulty := &""  # the difficulty (Difficulty.LADDER) of the check it imposes, at its rank: dodging it (Wildfire: difficult; Behaviours/cone.gd)
@export var reach_scale := &""  # its reach runs this magnitude of its rank in tiles (Difficulty.MAGNITUDE; Wildfire's cone: intense, 2.5 x rank)
@export var dice_scale := &""  # its damage dice come this magnitude of its rank, times its tier's count (Wildfire: severe, 3 x rank)
@export var bane := &""  # units carrying this tag - from what they are, wear or know (Unit.has_tag()) - dodge at impossible and are hit as a crit (Wildfire: earth)
@export var radius_per_rank := 0.0  # range grows with rank (Darkstone: 1 + rank; Embellish, cast on a unit: rank - 1)

@export_group("Trap")  # cast on a cell, lays a trap there (Snare; Battle.lay())
@export var lays: Terrain  # the trap: its concealment and dice multiplier are per rank

@export_group("Stand-in")  # passive: one stat stands in for others on skills sharing a tag with it
@export var stand_in := &""  # Arcanist Perspective: intelligence
@export var replaces: Array[StringName] = []  # wisdom, charisma

@export_group("Energy")  # passive: what its holder's Energy counts as
@export var energy_as: Array[StringName] = []  # Energy paid for skills with these tags gets the bonuses their own resources give (Working Knowledge: magical - Hex at half AP, as with Mana)
@export var reserve: Reserve  # passive: gives its holder this reserve, its max the holder's mod in reserve_mod plus the reserve's base (at least 0) x rank (Sweet Nothings; Stamina)
@export var reserve_mod := &""
@export var opens: Reserve  # skills up to its rank in tier get their cost_with savings for this reserve (Mana: mana)

@export_group("Look")  # a persona it puts forward on whoever has it (Alluring; Unit._take_looks()), cutting their dissonance penalty by its rank
@export var stance := ""
@export var shows_vibe: Array[String] = []
@export var shows_tags: Array[StringName] = []
@export var shows_adjectives: Array[String] = []
@export var shows_nouns: Dictionary[String, String] = {}
@export_multiline var lore := ""  # a story behind it, shown after what it does (the Bracing passives: Jimhe Deyn's gangs)
@export_group("Terms")  # what it does and how it scales, for the cost calculator and modifiers (SkillTerms, Pricing, Modifiers); empty: derived from its fields
@export var intensity := &""  # its damage, a Difficulty.MAGNITUDE word (the user's low faint, moderate low mild, moderate, high strong, extreme severe); empty: from its tier
@export var impact := &""  # its unique effect beyond damage: tame or impactful; empty: from its fields
@export var penalty := &""  # what it costs its user to use: minor, major or severe; empty: from its fields (disadvantage, roll_bonus)
@export var requires: Requirement  # a contingency: a test of the moment and what it gives while met (Scripts/Requirement.gd)
@export var priced := false  # its AP and cost come from the cost calculator (Pricing), not ap and cost
@export_group("Stub")  # a skill that isn't built yet: shown on skill trees, but it can't be learned
@export var stub := ""  # the open question(s) in todo.md it waits on: "?3", "?2 ?11"
@export_multiline var plan := ""  # what it's meant to do, until it's built

var terms_read: RefCounted  # its SkillTerms, read on first ask (SkillTerms.of())

const STAT_TAGS := {&"str": &"strength", &"dex": &"dexterity", &"con": &"constitution",
		&"int": &"intelligence", &"wis": &"wisdom", &"cha": &"charisma"}
const CATEGORIES := {&"magical": "Magic", &"martial": "Martial", &"specialist": "Specialist"}
const ICONS := "res://Icons/Skills/"  # <skill file>.png each: icon()

static var _icons := {}  # skill file -> its icon, or null
static var _kinds := {}  # skill -> the broad kinds its trees give it (kinds()), found on first ask
static var _kinds_found := false


# Its broad kinds, from the trees it sits on, so they can't drift from the .tres files: each class root's
# tag (a Cleric's Sol: magical), each general tree's category, &"general" for the base General tree
# (Strike, though tagged martial). On roots of two kinds (Snare: specialist, and a Druid's magical
# Sylvan), both. On no tree (Hex, listed outright; a monster's Sing): its own category tags.
# How a with_energy reserve comes back, in a description: as Energy does, and its resting bonus.
static func _comes_back(r: Reserve, rank: int) -> String:
	var bonus := r.rest_rank * rank
	return "It comes back as Energy does, {r:%s} more on a turn it rests%s" % [num(bonus), (", {r:%s} on any other" % num(bonus * r.steady)) if r.steady > 0.0 else ""]


func kinds() -> Array[StringName]:
	if not _kinds_found:
		_kinds_found = true
		_find_kinds()
	var out: Array[StringName] = []
	if _kinds.has(self):
		out.assign(_kinds[self])
	else:
		for t in tags:
			if t in CATEGORIES:
				out.append(t)
	return out


# Whether it carries t as a tag or as a kind its trees give it: what reserves (Reserve.only), Energy
# standing in for them (energy_as) and exhaustion (Exhaustion.alike()) ask.
func tagged(t: StringName) -> bool:
	return t in tags or t in kinds()


# A general skill: on the base General tree (Strike). Its uses wear a little on every skill.
func general() -> bool:
	return &"general" in kinds()


# Duck-typed: naming SkillTab, SkillRoot or Role here would load them, and Unit's general trees, with Skill.gd.
static func _find_kinds() -> void:
	var note := func(s: Skill, k: StringName) -> void:
		if s == null or k == &"":
			return
		if not _kinds.has(s):
			_kinds[s] = [] as Array[StringName]
		if k not in _kinds[s]:
			_kinds[s].append(k)
	for f in ResourceLoader.list_directory("res://Trees/"):
		var t = load("res://Trees/" + f) if f.ends_with(".tres") else null
		if t and t.has_method(&"general") and t.general():  # a general tree (SkillTab)
			var k: StringName = t.category if t.category else &"general"
			for s in ([t.center] if t.center else []) + t.core:
				note.call(s, k)
			for r in t.roots:
				for s in r.skills() if r else []:
					note.call(s, k)
		elif t and t.has_method(&"branch"):  # a class root shared by classes (SkillRoot)
			for s in t.skills():
				note.call(s, t.tag)
	for f in ResourceLoader.list_directory("res://Roles/"):
		var role = load("res://Roles/" + f) if f.ends_with(".tres") else null
		if role and role.has_method(&"all_roots"):
			for r in role.all_roots():
				for s in r.skills():
					note.call(s, r.tag)


func tier(rank: int) -> Tier:
	var best: Tier = null
	for t in tiers:
		if t.rank <= rank and (best == null or t.rank > best.rank):
			best = t
	return best


# Goes on the hotbar to work: everything but an inherent skill (Starkind), which takes no slot. Actives
# and toggles are worked by hand from it; an always-on passive just sits there, working (Unit.equipped()).
func fits_bar() -> bool:
	return not inherent


# Its holder's build stands on it (Powerful): it's the easiest to disable, and one going takes every
# pillar skill with it (Unit.disable()).
# Whether its effects hold the foe until it breaks free: it grapples or drowns.
func holds() -> bool:
	return grapples or drowns != Vector2i.ZERO


func pillar() -> bool:
	return &"pillar" in Tags.expand(tags)


# A Pillar that sits rank / 2 slots in from the right for disabling (Generalist): harder to reach.
func foundation() -> bool:
	return &"foundation" in tags


# Aimed at a tile rather than a unit: area skills and trap skills.
func on_tile() -> bool:
	return lays != null or channel or rifts or behaviours.any(func(b: Behaviour): return b and b.tile_target() != &"")


# The tiles it would cover, cast on `cell` by `caster` (its behaviours' footprint()): who stands there
# glows as it's aimed. Empty for a skill with no area.
func footprint(b: Battle, caster: Unit, cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not on_tile():
		return out
	var c := b.cast_of(caster, self, null, caster.rank(self), hostile)
	for h in behaviours:
		for at in h.footprint(c, cell) if h else []:
			if at not in out:
				out.append(at)
	return out


# Its behaviour from Behaviours/<file>.gd (&"guard": Shields Up!), or null: what a reader asks when it
# acts on one kind (AI._search(): an Observe).
func behaviour(file: StringName) -> Behaviour:
	for b in behaviours:
		if b and b.get_script().resource_path.get_file().get_basename() == file:
			return b
	return null


# Whether it can serve a posture when a unit reaches for its default move (HUD default orders, and the
# context tags in docs/plan-composability.md): &"offensive" an attack on a foe, &"supportive" help for
# an ally, &"defensive" protecting oneself. A skill can serve more than one (a dual spell attacks and
# supports); a passive serves none - it's not a move to order. A posture tag on it decides outright.
# Given the unit that would use it, "supportive" also counts any skill a behaviour of which restores
# something to that unit (Behaviour.restores(): Heal, Energize, Resuscitate), as heals() does for the
# skills whose fields heal - so Affinity and a HELP order see them alike; without one it can't ask.
func serves(posture: StringName, u: Unit = null) -> bool:
	if passive:
		return false
	if tags.any(func(t: StringName): return t in Unit.POSTURES):  # tagged with its posture outright (Frenzy: offensive)
		return posture in tags
	match posture:
		&"offensive":
			return for_foes() and (attacks() or contests() or not tiers.is_empty() or Displace.draws(self) != null or disables)
		&"supportive":
			return for_allies() and (restoring(u) or not self_only and (heals() or grants != null or behaviour(&"boost") != null or behaviour(&"aura") != null or not effects.is_empty()))
		&"defensive":
			return self_only
	return false


# Whether one of its behaviours would give u something back used by u on itself (Behaviour.restores(),
# whatever the pool, however little: only that it is a restorer). False with no unit to ask.
func restoring(u: Unit) -> bool:
	if u == null or behaviours.is_empty():
		return false
	var c := Behaviour.Cast.new()
	c.caster = u
	c.target = u
	c.skill = self
	c.rank = 1  # not u.rank(): a unit's rank reads its Affinity, which asks serves()
	c.foe = false
	return behaviours.any(func(x: Behaviour): return x != null and not x.restores(c).is_empty())


# Can be used on foes: hostile skills, and dual ones.
func for_foes() -> bool:
	return hostile or dual or either


# Can be used on allies: support skills, and dual ones.
func for_allies() -> bool:
	return not hostile or dual or either


# Rolls to hit a foe before it does anything to it.
func attacks() -> bool:
	return for_foes() and rolls and not on_tile() and not contests()


# Heals (or restores AP): mends allies it's used on.
func heals() -> bool:
	return not heal_mods.is_empty() or heal_bonus > 0 or restores > 0.0


# Carries a look its holder puts forward (Alluring).
func has_look() -> bool:
	return stance != "" or not (shows_vibe.is_empty() and shows_tags.is_empty() and shows_adjectives.is_empty() and shows_nouns.is_empty())


# The highest rank of wound it clears at a rank: its rank, or rank x rank (Renew).
func clears(rank: int) -> int:
	return rank * rank if squared else rank


# HP it heals, cast by u (at least 1).
func healing(u: Unit) -> int:
	var sum := 0
	for s in heal_mods:
		sum += u.mod(s, tags)
	return maxi(u.rounded(u.mods(self).statf(sum, &"stat_impact") / float(heal_split)) + heal_bonus, 1)


# Its cost at a rank (starter spells: cost x rank).
func price(rank: int) -> int:
	return cost * (maxi(rank, 1) if cost_per_rank else 1)


# How many of the target's turns the effects it puts on last, at a rank.
# Through u's modifiers (Unit.mods()): its rank_impact rank, its stat_impact mod.
func lasts(rank: int, u: Unit = null) -> int:
	var m := u.mods(self) if u else Modifiers.NONE
	return turns + turns_per_rank * m.irank(rank, &"rank_impact") + (m.stat(maxi(u.mod(turns_mod), 0), &"stat_impact") if u and turns_mod else 0)


# Contests a foe in place of an attack roll: a save, a drag, Level Down, Death.
func contests() -> bool:
	return (check != null and not check.suspicion) or levels_down or kills


# The ground tag its check drags a foe to (Drown: water), or none.
func drags() -> StringName:
	return check.drags_to if check else &""


# Used on its user alone: self_only, except a prayer to Drael (Pray), which is on a unit within rank tiles.
func on_self(u: Unit) -> bool:
	return self_only and not (prays and u and u.deity() == &"drael")


# Its range for a caster, before reach and size: a magnitude of its rank (reach_scale), or radius (+
# radius_per_rank x rank: Embellish), plus
# its mod in radius_mod - at least 1, so it reaches an adjacent unit - plus what its range effects add
# (a Staff, a Broadsword: Unit.skill_stat()).
# Rank and stats go through u's modifiers (Unit.mods(): rank_range, stat_range).
func span(u: Unit) -> float:
	var m := u.mods(self)
	if reach_scale:  # a magnitude of its rank (Wildfire's cone)
		return maxi(ceili(m.rank(maxi(u.rank(self), 1), &"rank_range") * Difficulty.MAGNITUDE[reach_scale]), 1) + (u.skill_stat(&"range", self) if not self_only else 0.0)
	var r := radius + radius_per_rank * m.rank(u.rank(self), &"rank_range") + (m.statf(u.stat(radius_stat), &"stat_range") if radius_stat else 0.0)
	if radius_mod:
		r = maxf(r + m.stat(u.mod(radius_mod, tags), &"stat_range"), 1.0)
	return r + (u.skill_stat(&"range", self) if not self_only else 0.0)


# The tags it's asked about by for its attributes (Unit.skill_stat()): its own, plus damage for a skill
# that deals any.
func query() -> Array[StringName]:
	var out: Array[StringName] = tags.duplicate()
	if not tiers.is_empty():
		out.append(&"damage")
	return out


# Its name as the skills screen and hotbar show it: an AI's placeholder design ends with ?? (ai).
func title() -> String:
	return name + " ??" if ai else name


# Its icon: Icons/Skills/<its file>.png, white on clear so the skills screen tints it by state. Until
# art replaces the file it's a placeholder of its mark (Util/icon.py draws one); null: none, the mark's
# drawn as text instead.
func icon() -> Texture2D:
	var id := resource_path.get_file().get_basename()
	if id not in _icons:
		var p := ICONS + id + ".png"
		_icons[id] = load(p) if id and ResourceLoader.exists(p) else null
	return _icons[id]


# Up to 2 characters for it on skill trees, its placeholder icon: its glyph, or its initials (a stub's
# dashed edge says it isn't built).
func mark() -> String:
	if glyph:
		return glyph
	var words := name.split(" ", false)
	if words.size() > 1:
		return words[0].left(1) + words[1].left(1)
	return name.left(2)


# "Waits on open question 3", "...questions 2 and 11".
func waits() -> String:
	if not stub.begins_with("?"):
		return "Waits on " + stub  # a system, not a question: "Waits on Reactions (docs/todo/systems.md)"
	var ids := Array(stub.replace("?", "").split(" ", false))
	if ids.size() == 1:
		return "Waits on open question %s (todo.md)" % ids[0]
	return "Waits on open questions %s and %s (todo.md)" % [", ".join(ids.slice(0, -1)), ids[-1]]


# The stat it's used with, for its attack roll: the one its tags name (str, wis...), else the one its
# damage scales on, else strength.
func stat() -> StringName:
	for t in tags:
		if t in STAT_TAGS:
			return STAT_TAGS[t]
	for t in tiers:
		if t.stat:
			return t.stat
	return &"strength"


static func roman(n: int) -> String:
	var out := ""
	for pair in [[50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while n >= pair[0]:
			out += pair[1]
			n -= pair[0]
	return out


# What it's used on (a Glossary target term): self, nearest, area, tile, ally_or_foe, foe or ally.
func target() -> StringName:
	if self_only:
		return &"self"
	if auto:
		return &"nearest"
	if channel or behaviours.any(func(b: Behaviour): return b and b.tile_target() == &"area"):
		return &"area"
	if on_tile():
		return &"tile"
	if dual or either:
		return &"ally_or_foe"
	return &"foe" if hostile else &"ally"


# Its range as it scales, in Glossary markup: the set part first, then what grows with rank (gold),
# then its user's stat (orange): "2 + {o:int mod}", "{r:rank} + {o:cha mod}", "{r:rank} - 1". Under
# modifiers m (its holder's: Unit.mods()), rank and stats as they read them: "{r:1.75 x rank}", a
# nullified rank as rank I (folded into the set part), "{o:0 x int mod}".
func reach_markup(m: Modifiers = Modifiers.NONE) -> String:
	var kr: float = m.k[&"rank_range"]
	if reach_scale:
		var mag: float = Difficulty.MAGNITUDE[reach_scale]
		return "{r:%s x rank}" % num(snappedf(mag * kr, 0.01)) if kr != 0.0 else str(maxi(ceili(mag), 1))
	var parts: PackedStringArray = []
	var base := radius
	if radius_per_rank and kr == 0.0:
		base += radius_per_rank  # as at rank I
	elif radius_per_rank:
		var per := radius_per_rank * kr
		parts.append("{r:rank}" if per == 1.0 else "{r:%s x rank}" % num(snappedf(per, 0.01)))
	if radius_stat:
		var ks: float = m.k[&"stat_range"]
		parts.append("{o:%s score}" % String(radius_stat).left(3) if ks == 1.0 else "{o:%s x %s score}" % [num(snappedf(ks, 0.01)), String(radius_stat).left(3)])
	if radius_mod:
		parts.append(_mod(radius_mod, &"stat_range", m))
	var grows := " + ".join(parts)
	if not grows:
		return num(base)
	if base > 0.0:
		return "%s + %s" % [num(base), grows]
	if base < 0.0:
		return "%s - %s" % [grows, num(-base)]
	return grows


# Its user's mod in x as channel c of m reads it, in Glossary markup: "{o:int mod}", "{o:1.75 x int
# mod}", "{o:0 x int mod}" (Modifiers.stat()).
static func _mod(x: StringName, c: StringName, m: Modifiers) -> String:
	var k: float = m.k[c]
	return Glossary.mod(x) if k == 1.0 else "{o:%s x %s mod}" % [num(snappedf(k, 0.01)), String(x).left(3)]


# What using it takes, in the same order on every skill: [label, Glossary markup] - its target, its
# range (none on itself), AP, cost. A passive: just how it runs. Given its holder u, at a rank: its
# range under u's modifiers, and the AP and cost u pays at that rank (Pricing.ap_at(), cost_at(): its
# modifiers, and how much it has used it lately - Exhaustion). Without one: its base, the AP and cost
# as set (a priced skill's at rank I) - the skills screen's, with nobody's modifiers.
func spec(u: Unit = null, rank := 1) -> Array:
	if stub:
		return [["", "Not built yet"]]
	if passive:
		var how := [["", "Passive"], ["", "Toggle" if toggle else ("Inherent" if inherent else "Always on")]]
		if hybrid:  # its active part costs AP (Personify: adjusting its persona)
			how.append(["AP", num(Pricing.ap_at(u, self, rank) if u else ap)])
		return how
	var out := [["", Glossary.term(target())]]
	if not self_only or prays:  # a prayer to Drael lands on a unit in range
		out.append(["range", reach_markup(u.mods(self) if u else Modifiers.NONE)])
	if u:
		var rate := u.exhaustion.rate(self) if u.exhaustion else 1.0
		out.append(["AP", num(Pricing.ap_at(u, self, rank) * rate)])
		var e := ceili(Pricing.cost_at(u, self, rank) * rate - 0.0001)
		if e:
			out.append(["cost", str(e)])
		return out
	if priced:  # the cost calculator's, at rank I (Pricing)
		out.append(["AP", num(Pricing.ap(self, 1))])
		if Pricing.energy(self, 1):
			out.append(["cost", str(Pricing.energy(self, 1))])
		return out
	out.append(["AP", num(ap)])
	if cost:
		out.append(["cost", "{r:%d x rank}" % cost if cost_per_rank else str(cost)])
	return out


# Its spec as one line of markup: "{k:foe} · range 2 + {o:int mod} · 3 AP · 2 cost" (as u holds it at
# a rank, given u: spec()).
func spec_line(u: Unit = null, rank := 1) -> String:
	return " · ".join(spec(u, rank).map(spec_part))


# A part of its spec, read: "{k:foe}", "range 2 + {o:int mod}", "3 AP", "2 cost".
static func spec_part(p: Array) -> String:
	return p[1] if not p[0] else ("range " + p[1] if p[0] == "range" else "%s %s" % [p[1], p[0]])


# One line for lists: its spec, plain.
func summary() -> String:
	return Glossary.plain(spec_line())


# Lines for a static view of s (the skills screen) that shows its base values: that u's modifiers change
# them, and that u has used it lately and pays more now (Exhaustion.note()); "" when neither.
static func base_note(u: Unit, s: Skill) -> String:
	if not u:
		return ""
	var note := ""
	if not u.mods(s).empty():
		note = "\nBase values: %s changes them (the spellbook and hotbar show them as %s has it)" % [u.mods(s).label(), u.name]
	var worn := u.exhaustion.note(s) if u.exhaustion and not s.passive else ""
	if worn:
		note += "\nCosts more now: " + worn
	return note


# Everything it does at this rank, as plain text (as u holds it, given u: markup()).
func describe(rank := 1, u: Unit = null) -> String:
	return Glossary.plain(markup(rank, true, u))


# The same in Glossary markup, for the skills screen and rich tooltips; with_spec: leading with its
# spec line (the skills screen shows that apart).
# Given its holder u: as u has it - every number rank or a stat adds read through u's modifiers
# (Unit.mods(): what Battle.cast() reads too), its price what u pays. Without one, its base.
func markup(rank := 1, with_spec := true, u: Unit = null) -> String:

	var lines: PackedStringArray = []
	if stub:
		lines.append("Not built yet. " + waits())
		if plan:
			lines.append(plan)
		return "\n".join(lines)
	var foe := "On a foe: " if dual else ""
	var ally := "On an ally: " if dual else ""
	var me := Glossary.mod(stat())
	var me_short := String(stat()).left(3)
	var m := u.mods(self) if u else Modifiers.NONE  # its holder's modifiers: rank and stats as cast() reads them
	var ri := m.irank(rank, &"rank_impact")  # rank for what it does
	var rr := m.irank(rank, &"rank_range")  # rank for how far it reaches
	if with_spec:
		lines.append(spec_line(u, rank) if not passive or not inherent else "Inherent: can't be removed or disabled, and takes no slot")
	if requires:
		lines.append(requires.markup(rank, m))
	if not passive:
		for r: Reserve in ap_with:
			lines.append("%s AP paid with %s" % [share(ap_with[r]), r.name])
		for r: Reserve in cost_with:  # the skill opening a reserve goes by its name (Mana)
			lines.append("%s cost paid with %s, once the caster's %s rank reaches its tier" % [share(cost_with[r]), r.name, r.name])
		if attacks():
			var extra := roll_per_rank * ri + roll_bonus
			lines.append("%s%s (%s%s)" % [foe, Glossary.term(&"attack") + (" with " + Glossary.term(&"advantage") if advantage else "") + (" with " + Glossary.term(&"disadvantage") if disadvantage else ""),
					me, (" + {r:%d}" % extra if extra > 0 else (" - {r:%d}" % -extra if extra < 0 else "")) if roll_per_rank or roll_bonus else ""])
			if sure_crit:
				lines.append("A hit is a %s" % Glossary.term(&"critical"))
			if recast_on_crit:
				lines.append("A natural 20 casts it again at once on the same foe, free")
		if decays > 0.0:
			lines.append("Its strength falls %s%% a tile past the first between caster and target, set as it's cast; none paid wholly with mana" % num(decays * 100.0))
		if prays:
			var n := ri
			var s := "" if n == 1 else "s"
			lines.append("Prays to the caster's god:")
			lines.append("Ramut: its side waits {r:%d} turn%s less for Ramut's Ire" % [n, s])
			lines.append("Eros: up to {r:%d} unit%s within {r:%d} tile%s that can see it lose a stack of %s of it" % [n, s, n, s, Glossary.term(&"suspicion", "suspicion")])
			lines.append("Sol: darkness within {r:%d} tile%s is gone" % [n, s])
			lines.append("Urlo: enchants {r:%d} unenchanted item%s of allies within {r:%d} tile%s, weapons first (+1)" % [n, s, n, s])
			lines.append("Luun: the ground within {r:%d} tile%s falls into %s for {t:%d turn%s}, concealing its side a level" % [n, s, Glossary.term(&"darkness", "darkness"), n, s])
			lines.append("Drael: takes {r:%d} rank%s of debuffs off an ally within {r:%d} tile%s, the highest first" % [n, s, n, s])
			lines.append("Vetruvis: the ground within {r:%d} tile%s becomes %s for {t:%d turn%s}, costing its enemies 50%% more to enter" % [n, s, Glossary.term(&"disturbed_earth", "disturbed earth"), n, s])
		if check and check.save:
			lines.append("%s (%s%s) vs %s%s" % [Glossary.term(&"save"), Glossary.mod(check.theirs(self), true),
					" + the ranks of the skills it would lose" if disables else "", Glossary.mod(check.mine(self)), " + {r:%d}" % ri if check.ranked else ""])
		if levels_down:
			lines.append("{r:%d} %s (%s), each against the higher of the foe's {d:average stat mod} + level and its %s. Each that wins takes a level off it, for {t:%d turn%s} less one a miss"
					% [ri, Glossary.term(&"check", "check" if ri == 1 else "checks"), me, Glossary.term(&"last_stand"), ri, "" if ri == 1 else "s"])
		if kills:
			lines.append("Its %s x (its HP left / {r:%d}) vs a %s (%s): failing, it takes 1 %s damage and dies"
					% [Glossary.term(&"last_stand"), ri, Glossary.term(&"check", "check"), me, Glossary.term(&"true", "true")])
		if disables:
			var n := floori(sqrt(ri))
			var up := ceili(sqrt(ri))
			lines.append("Failing, {r:%s} of its skill slots are %s, from the right%s; its pillar skills go first, all as one slot"
					% [str(n) if n == up else "%d (%d while lucky)" % [n, up], Glossary.term(&"disabled", "disabled"), _lasting(rank, u)])
		if lays:
			var bonus := " + %s" % Glossary.mod(lays.bonus_stat) if lays.bonus_stat else ""
			lines.append("Sets a %s: %s {r:%d}, %dd%d x {r:%d}%s %s" % [Glossary.term(&"trap", lays.name.to_lower()), Glossary.term(&"concealment", "concealment"), lays.concealment * ri,
					lays.dice.x, lays.dice.y, lays.times * ri, bonus, " ".join(lays.damage_tags.filter(func(t): return t != &"trap").map(func(t): return "{x:%s}" % t))])
			if &"trap" in tags:
				lines.append("Allies within its %s in tiles learn where it is" % Glossary.mod(&"cha"))
		var t := tier(ri)
		if channel:
			lines.append("%s on a tile. Cast again for %s AP and %d cost to strike: a tile within (its side's turns since) tiles of it explodes, hitting everyone within {r:%s} tiles but the caster"
					% [Glossary.term(&"channeled", "Channels"), num(strike_ap), strike_cost, num(snappedf(blast * m.rank(rank, &"rank_range"), 0.01))])
		if god_tag:
			var n := ri
			lines.append("Its damage takes its caster's god's tag, and on a hit its god adds:")
			lines.append("Eros ({x:love}): used on an ally, it heals what it would deal, overhealing at {r:%d%%}" % (20 * n))
			lines.append("Luun ({x:dark}): a foe left at {r:%d%%} of its max HP or less dies" % (5 * n))
			lines.append("Sol ({x:fire}): it burns again for {r:%d%%} of the damage, pure fire, as its turn ends" % (20 * n))
			lines.append("Urlo ({x:energy}): %s Energy (or Power) first%s; takes {r:%d} enchantment%s off, enchanting the caster's items with the rest"
					% [Glossary.term(&"drain", "drains"), ", then {r:%d%%} of the rest goes on to HP" % roundi(carry * (n - 1) * 100) if carry * (n - 1) > 0 else "", n, "" if n == 1 else "s"])
			lines.append("Drael ({x:water}): takes {r:%d} rank%s of its buffs off" % [n, "" if n == 1 else "s"])
			lines.append("Vetruvis ({x:earth}): radiates to everyone within {r:%d} tile%s, the damage / (tiles away + 1)" % [n, "" if n == 1 else "s"])
			lines.append("Ramut ({x:physical}): nothing more")
		if t:
			var dmg := _damage(t, m)
			if dice_per_rank and ri > 1:
				dmg = dmg.replace("%dd%d" % [t.dice.x, t.dice.y], "{r:%dd%d}" % [t.dice.x * ri, t.dice.y])
			if dice_scale:
				dmg = dmg.replace("%dd%d" % [t.dice.x, t.dice.y], "{r:%dd%d}" % [t.dice.x * Difficulty.scaled(dice_scale, ri), t.dice.y])
			if hits_per_rank and ri > 1:
				dmg = "{r:%d} hits of %s" % [ri, dmg]
			lines.append(foe + ("deals " if dual else "Deals ") + dmg)
			if &"energy" in tags:
				lines.append("%s: Energy (or Power) first%s" % [Glossary.term(&"drain"), ", then {r:%d%%} of the rest goes on to HP" % roundi(carry * (ri - 1) * 100) if carry * (ri - 1) > 0 else ""])
		if grants:
			lines.append("Gives %s for {t:%d turn%s}" % [grants.name, lasts(rank, u), "" if lasts(rank, u) == 1 else "s"])
		if binds:
			lines.append("On a hit: %s, weight {r:%d}, take the place of its trinket. Taking them off once unlocked takes {r:%d} AP; locked, they're lockpicked (%s, DC {r:%d}) or pried apart (%s, DC {r:%d})"
					% [binds.name, ri, ri, Glossary.term(binds.picks), Difficulty.dc(binds.picks, ri), Glossary.term(binds.prised), Difficulty.dc(binds.prised, ri)])
		if chain:
			lines.append("Attacks cease on a miss. -1 to hit and damage for each hit in a row")
		if opening:
			lines.append("Only as its turn opens, before it moves or spends AP")
		if pays_with == &"move":
			lines.append("Paid with movement and AP: its AP comes from movement first")
		if respecs:
			lines.append("Then move up to {r:%d} point%s from its core stats into others, a point down for each point up - no more than it already knew itself (%s)" % [ri, "" if ri == 1 else "s", Glossary.term(&"self_knowledge", "self-knowledge")])
		if bane:
			lines.append("Units carrying {x:%s} - from what they are, wear or know - dodge it at %s and are hit as a %s" % [bane, Glossary.term(&"impossible", "impossible"), Glossary.term(&"critical", "critical")])
		if heals():
			var mods := " + ".join(heal_mods.map(func(x): return _mod(x, &"stat_impact", m)))
			if heal_split > 1:
				mods = "(%s) / %d" % [mods, heal_split]
			lines.append("Heals %s%s HP, at least 1" % [mods, (" + %d" % heal_bonus if mods else str(heal_bonus)) if heal_bonus else ""])
			lines.append("Clears %s up to rank {r:%d}%s" % [Glossary.term(&"wound", "wounds"), clears(ri), " (rank x rank)" if squared else ""])
			if per_wound:
				lines.append("+{r:%d} HP for each wound it clears" % (per_wound * ri))
			if restores > 0.0:
				lines.append("Gives back {r:%s} AP" % num(restores * ri))
		if drags():
			lines.append("%s (%s vs %s) in place of an attack, -%d a tile it must drag the foe%s. Won: drags it to the nearest %s the caster could walk to, and both go in"
					% [Glossary.term(&"contest"), me, Glossary.mod(check.theirs(self), true), check.range_penalty, " (less {r:%d})" % (ri - 1) if ri > 1 else "", drags()])
		if engulfs:
			lines.append("%s (%s vs %s) in place of an attack. Won: moves into its tile, sharing it" % [Glossary.term(&"contest"), me, Glossary.mod(stat(), true)])
		if holds():
			lines.append("%s it: moving away first takes 1 + %s tiles of movement and a %s" % [Glossary.term(&"held", "Holds"), me, Glossary.term(&"contest", "contest")])
		if drowns != Vector2i.ZERO:
			lines.append("%s: each turn it ends held and %s, it takes %dd%d + %s" % [Glossary.term(&"drowning", "Drowns it"), Glossary.term(&"submerged", "submerged"), drowns.x, drowns.y, me])
		if check and check.suspicion:
			lines.append("%s%s comes. On a suspicious one, a %s (%s vs %s) takes a stack of %s off"
					% [foe, ("only one " if dual else "Only one ") + Glossary.term(&"enraptured", "enraptured"), Glossary.term(&"contest", "contest"),
					me, Glossary.mod(check.theirs(self), true), Glossary.term(&"suspicion", "suspicion")])
		if links:
			lines.append("Its effects go on its teammates within its %s in tiles (at least 1), and on its leader, too" % _mod(&"charisma", &"stat_range", m))
		if auto:
			lines.append("Used at once: lands on the nearest {r:%d} unit%s in range, allies and foes alike" % [rr, "" if rr == 1 else "s"])
	for e in effects:
		lines.append(ally + e.markup(ri if e.per_rank else rank) + ("" if passive else _lasting(rank, u)))
	if downed:
		lines.append(downed.markup(rank))
	var as_cast := Behaviour.Cast.new()  # what its behaviours are told: the holder, rank and modifiers, no battle
	as_cast.caster = u
	as_cast.skill = self
	as_cast.rank = rank
	as_cast.mods = m
	for bh in behaviours:
		var said := bh.describe_as(as_cast)
		if said:
			lines.append(said)
	if has_look():
		var look := ([stance] if stance else []) + [", ".join(shows_vibe)] + [", ".join(shows_tags)]
		lines.append("Puts forward a look: %s. Its holder's {k:dissonance|dissonance} counts {r:%d} less against its own checks"
				% ["; ".join(look.filter(func(x: String): return x != "")), ri])
		if not (shows_adjectives.is_empty() and shows_nouns.is_empty()):  # what it may go by (Unit.alias: the persona panel)
			var names: PackedStringArray = []
			if not shows_adjectives.is_empty():
				names.append(", ".join(shows_adjectives))
			if not shows_nouns.is_empty():
				names.append(", ".join(PackedStringArray(shows_nouns.keys())))
			lines.append("It may go by %s" % "; ".join(names))
	if investigated:
		lines.append("A %s as it's used (%s + {r:%d}): enemies that can see it %s against that at once, with %s within their %s - {r:%d} tiles. Those who meet it aren't fooled by it"
				% [Glossary.term(&"check", "check"), me, ri, Glossary.term(&"investigate", "investigate"), Glossary.term(&"advantage", "advantage"), Glossary.mod(&"wis", true), ri])
	if not energy_as.is_empty():
		lines.append("Energy paid for %s skills counts as their own resources, with the bonuses those give" %
				" or ".join(energy_as.map(func(t): return CATEGORIES.get(t, String(t)).to_lower())))
	if reserve and passive:  # Stamina: (con mod + 2) x rank
		var per := (Glossary.mod(reserve_mod) if reserve_mod else "1") + (" + %d" % reserve.base if reserve.base else "")
		lines.append("Gives its holder %s: (%s) x {r:%d} at most, %s as each battle starts" % [reserve.name, per, rank, "empty" if reserve.empty else "full"])
		if reserve.only and reserve.whole == 0:
			lines.append("%s pays before Energy for %s skills" % [reserve.name, ", ".join(reserve.only)])
		if reserve.with_energy:
			lines.append(_comes_back(reserve, rank))
		if reserve.builds > 0.0:
			lines.append("It builds %d%% of its max back on each turn it rests - no AP spent, no move - and only then (not while holding a %s)" % [roundi(reserve.builds * 100), Glossary.term(&"channeled", "channel")])
		if reserve.aims:
			lines.append("%s pays first for a ranged %s; for anything else only once Energy can't" % [reserve.name, Glossary.term(&"attack", "attack")])
	if waives:
		lines.append("Opens the %s tree's skills up to {r:T%d} without their usual needs (one tier lower where your class doesn't have the tree, which it then shows). Skills learned that way stop working without it"
				% ["General" if waives == &"general" else ("Caster" if waives == &"magical" else String(waives).capitalize()), rank])
	if exclusive:
		lines.append("Only one %s can be learned" % ("Strike upgrade" if exclusive == &"strike_form" else String(exclusive)))
	if renames:
		lines.append("Strike becomes %s" % renames)
	if mist_only:
		lines.append("Only as a mist (Vaporize)")
	if rifts:
		lines.append("Opens a rift on a tile in sight (over walls from {r:III}): a door both ways to a domain, an 8x8 diamond of grass with demons of its own (difficulty by rank, the caster's level). %s, it stays open while the caster keeps channeling (shown as infinite); used again, the channel stops. Its {t:%d turns} start once the channel stops, or at once if it's cast unchanneled (Alt-click); then the caster's side comes back and the domain goes" % [Glossary.term(&"channeled", "Channeled"), Battle.rift_turns(ri)])
	if studies:
		lines.append("Dabblings: pick up to {r:%d} of the %s on your tree" % [rank, studies])
	if opens:
		lines.append("Cheaper casting with %s: skills up to {r:T%d} get the savings they list for it" % [opens.name, rank])
	var stands: Reserve = reserve if reserve and reserve.replaces else (opens if opens and opens.replaces else null)
	if stands and toggle and passive:  # Mana, Stamina: what its holder runs on (Unit.runs_on())
		if opens == stands:
			lines.append("%s pays only for %s skills" % [stands.name, ", ".join(stands.only)])
			if stands.with_energy:
				lines.append(_comes_back(stands, rank))
		lines.append("On as it's learned: its holder runs on %s, its own Energy emptied and not coming back; Energy it gets some other way still pays%s"
				% [stands.name, (", but nothing pays for a %s skill that costs anything" % " or ".join(stands.bars)) if stands.bars else ""])
		lines.append("Switching it on or off is %s: of what it leaves, it keeps {r:%d}%% of that one's max a turn held, into what it runs on next; the rest is lost. Switch again to finish early"
				% [Glossary.term(&"channeled", "channeled"), 10 * rank])
	if stand_in:
		lines.append("%s stands in for %s on %s skills" % [stand_in.capitalize(),
				", ".join(replaces.map(func(x): return String(x).capitalize())), ", ".join(tags)])
	if rank_cost:
		lines.append("Ranks cost more: II takes %d points, then x%s each rank" % [rank_cost, num(rank_growth)])
	if (not tags.is_empty() and not stand_in) or not classes.is_empty():
		lines.append("Tags: " + ", ".join(classes.map(func(c): return String(c).capitalize()) + ([] if stand_in else tags.map(func(t): return "{x:%s}" % t))))
	if lore:
		lines.append(lore.replace("{", "(").replace("}", ")"))
	return "\n".join(lines)


# How long its put-on effects last at a rank: " for 2 turns", " until it moves", " for 2 turns,
# then a level less each turn".
# Given its holder u: its turns as u has it (lasts(): its modifiers) - with turns_mod, the part rank adds.
func _lasting(rank: int, u: Unit = null) -> String:
	var n := lasts(rank, u)
	var text := " for {t:%d turn%s}" % [n, "" if n == 1 else "s"] if n else ""
	if turns_mod:
		var m := u.mods(self) if u else Modifiers.NONE
		n = turns + turns_per_rank * m.irank(rank, &"rank_impact")
		text = " for %s + {t:%d turns}" % [_mod(turns_mod, &"stat_impact", m), n]
	if until_move:
		text += (", or" if n else "") + " until it moves"
	if fades and n:
		text += ", then a level less each turn"
	return text


func _damage(t: Tier, m: Modifiers = Modifiers.NONE) -> String:
	var parts: PackedStringArray = []
	if t.power:
		parts.append(str(t.power))
	if t.dice != Vector2i.ZERO:
		parts.append("%dd%d" % [t.dice.x, t.dice.y])
	if t.stat:
		parts.append(_mod(t.stat, &"stat_impact", m))

	return " + ".join(parts) + (", " + Glossary.term(&"unblockable", "unblockable") if t.direct else "")


# "Half", "A quarter", "x0.75": a cost or AP factor.
static func share(f: float) -> String:
	if is_equal_approx(f, 0.5):
		return "Half"
	if is_equal_approx(f, 0.25):
		return "A quarter"
	return "x" + num(f)


static func num(x: float) -> String:
	return str(roundi(x)) if is_equal_approx(x, roundf(x)) else String.num(x, 2)

class_name Skill
extends Resource

@export var name := ""
@export var passive := false  # works while its slot is on; costs nothing, can't be cast
@export var toggle := false  # passive: its holder switches it on and off (from the hotbar)
@export var hybrid := false  # passive with an active part: using it costs its AP (Personify: adjusting its persona; Battle.personify())
@export var tags: Array[StringName] = []  # e.g. physical, dark, magical, str, wis; martial, magical, specialist: its category
@export var effects: Array[Effect] = []  # passives: on the holder; actives: put on the target
@export var max_rank := 0  # the highest rank it can be raised to; 0: no cap
@export var glyph := ""  # up to 2 characters standing for it on skill trees; empty: its initials
@export var rank_cost := 0  # skill points for rank II, times rank_growth for each rank after (Clever Disguise: 4, 8, 16...); 0: the usual 1 + r^2
@export var rank_growth := 2.0

@export_group("Active")
@export var ap := 0.0
@export var cost := 0  # paid in Energy, or a reserve that can pay for this skill's tags
@export var cost_per_rank := false  # cost x rank (starter spells)
@export var ap_with: Dictionary[Reserve, float] = {}  # AP factor when fully paid with a reserve (Hex: mana 0.5)
@export var needs: Reserve  # it can only be paid with this reserve (a Warlock's higher-tier skills: a Sweet Nothing)
@export var cost_with: Dictionary[Reserve, float] = {}  # cost factor paid with a reserve, once the caster has opened it up to this skill's tier (starter spells: mana 0.5, opened by Mana)
@export var radius := 0.0  # range before reach and size
@export var radius_mod := &""  # plus the caster's mod in this stat, reaching an adjacent unit at least (starter spells: intelligence)
@export var hostile := true  # targets enemies (false: allies)
@export var dual := false  # usable on allies and foes alike: allies get its effects, foes its damage (starter spells)
@export var either := false  # usable on allies and foes alike, its effects on both (wauaw)
@export var rolls := true  # used on a foe: rolls d20 + attack mod against its Defense first (Battle.cast())
@export var pull := 0  # used on a foe: draws it this many tiles x rank toward the caster (Sing; Battle.pull())
@export var drags_to := &""  # used on a foe: a contest in its stat in place of the attack roll; won, it drags the foe to the nearest ground with this tag the caster could walk to, and both into it (Drown: water; Battle.drag_spot())
@export var grip := Vector2i.ZERO  # its effects hold the foe (grappled) until it breaks free by moving away: each turn it ends held, these dice + the caster's mod in its stat (Drown: 1d12; Battle._break_free(), Battle._grip())
@export var links := false  # on itself: links it with its teammates within its cha mod in tiles (at least 1) and its leader, to pool what they make out (Coordinate; Battle._link())
@export var prays := false  # prays to the caster's god, an effect by god (Pray; Battle.pray())
@export var observes := false  # cast on a tile: the caster inspects every tile around it as if it had rested rank turns (Observe; Battle.observe())
@export var auto := false  # used at once, landing on the nearest units in range - allies and foes alike - no more than its rank (Sing; Battle.auto_targets())
@export var save := &""  # used on a foe: in place of the attack roll, it saves - d20 + its mod in this beating d20 + the caster's mod in the skill's stat + rank; failing, it takes the effects, and that roll is what seeing through them must beat (Haluca: wisdom)
@export var disables := false  # a curse: with its save, the caster's luck-rounded sqrt(rank) of the foe's skill slots are switched off, right to left, for its turns; the foe adds the ranks of the skills in them to its save (Brainfog; Unit.disable_order())
@export var resisted := &""  # it pulls only foes enraptured by the caster (fooled, with no suspicion of it); on a suspicious one, d20 + the caster's mod in the skill's stat against d20 + its mod in this takes a stack of suspicion off (Sing: wisdom; Battle._lured())
@export var tiers: Array[Tier] = []  # damage by rank; none: no damage (tagged energy: it drains Energy first - Unit.drain())
@export var carry := 0.0  # energy damage: this x (rank - 1) of what's left once the target's Energy is gone goes on to HP (Smite: 0.2)
@export var hits_per_rank := false  # Strike III hits three times
@export var grants: Skill  # also puts this skill's effects on the target (Stonegift: Stoneskin)
@export var turns := 0  # how many of the target's turns put-on effects last (zones: the caster's)
@export var turns_per_rank := 0  # ...plus this many per rank (Sola: rank turns)
@export var turns_mod := &""  # ...plus the caster's mod in this (Haluca: charisma)
@export var fades := false  # ...after which they lose a rank a turn, rather than ending (Clever Disguise)
@export var until_move := false  # they last until the target moves rather than standing still - with no turns set, with no limit (Hide)
@export var self_only := false  # used on its user alone (Hide)
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

@export_group("Area")  # cast on a cell rather than a unit (Darkstone)
@export var zone := &""  # concealment kind laid on tiles: rank - distance from the centre levels
@export var radius_per_rank := 0.0  # range grows with rank (Darkstone: 1 + rank; Embellish, cast on a unit: rank - 1)

@export_group("Trap")  # cast on a cell, lays a trap there (Snare; Battle.lay())
@export var lays: Terrain  # the trap: its concealment and dice multiplier are per rank

@export_group("Stand-in")  # passive: one stat stands in for others on skills sharing a tag with it
@export var stand_in := &""  # Arcanist Perspective: intelligence
@export var replaces: Array[StringName] = []  # wisdom, charisma

@export_group("Energy")  # passive: what its holder's Energy counts as
@export var energy_as: Array[StringName] = []  # Energy paid for skills with these tags gets the bonuses their own resources give (Working Knowledge: magical - Hex at half AP, as with Mana)
@export var reserve: Reserve  # passive: gives its holder this reserve, its max the holder's mod in reserve_mod (at least 0) x rank (Sweet Nothings)
@export var reserve_mod := &""
@export var opens: Reserve  # skills up to its rank in tier get their cost_with savings for this reserve (Mana: mana)

@export_group("Look")  # a persona it puts forward on whoever has it (Alluring; Unit._take_looks()), cutting their dissonance penalty by its rank
@export var stance := ""
@export var shows_vibe: Array[String] = []
@export var shows_tags: Array[StringName] = []
@export var shows_adjectives: Array[String] = []
@export var shows_nouns: Dictionary[String, String] = {}
@export_group("Stub")  # a skill that isn't built yet: shown on skill trees, but it can't be learned
@export var stub := ""  # the open question(s) in todo.md it waits on: "?3", "?2 ?11"
@export_multiline var plan := ""  # what it's meant to do, until it's built

const STAT_TAGS := {&"str": &"strength", &"dex": &"dexterity", &"con": &"constitution",
		&"int": &"intelligence", &"wis": &"wisdom", &"cha": &"charisma"}
const CATEGORIES := {&"magical": "Magic", &"martial": "Martial", &"specialist": "Specialist"}


func tier(rank: int) -> Tier:
	var best: Tier = null
	for t in tiers:
		if t.rank <= rank and (best == null or t.rank > best.rank):
			best = t
	return best


# Has a part its holder works by hand - it's cast, or switched on and off - so it goes on the hotbar.
func fits_bar() -> bool:
	return not passive or toggle


# Its holder's build stands on it (Powerful): it's the easiest to disable, and one going takes every
# pillar skill with it (Unit.disable()).
func pillar() -> bool:
	return &"pillar" in tags


# Aimed at a tile rather than a unit: area skills and trap skills.
func on_tile() -> bool:
	return zone != &"" or lays != null or observes or channel


# Can be used on foes: hostile skills, and dual ones.
func for_foes() -> bool:
	return hostile or dual or either


# Can be used on allies: support skills, and dual ones.
func for_allies() -> bool:
	return not hostile or dual or either


# Rolls to hit a foe before it does anything to it.
func attacks() -> bool:
	return for_foes() and rolls and not on_tile() and not drags_to and not save


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
	return maxi(u.rounded(sum / float(heal_split)) + heal_bonus, 1)


# Its cost at a rank (starter spells: cost x rank).
func price(rank: int) -> int:
	return cost * (maxi(rank, 1) if cost_per_rank else 1)


# How many of the target's turns the effects it puts on last, at a rank.
func lasts(rank: int, u: Unit = null) -> int:
	return turns + turns_per_rank * rank + (maxi(u.mod(turns_mod), 0) if u and turns_mod else 0)


# Used on its user alone: self_only, except a prayer to Drael (Pray), which is on a unit within rank tiles.
func on_self(u: Unit) -> bool:
	return self_only and not (prays and u and u.deity() == &"drael")


# Its range for a caster, before reach and size: radius (+ radius_per_rank x rank: Embellish), plus
# its mod in radius_mod - at least 1, so it reaches an adjacent unit.
func span(u: Unit) -> float:
	var r := radius + radius_per_rank * u.rank(self)
	if not radius_mod:
		return r
	return maxf(r + u.mod(radius_mod, tags), 1.0)


# Up to 2 characters for it on skill trees: a stub's question ("?3"), its glyph, or its initials.
func mark() -> String:
	if stub:
		return stub.split(" ")[0]
	if glyph:
		return glyph
	var words := name.split(" ", false)
	if words.size() > 1:
		return words[0].left(1) + words[1].left(1)
	return name.left(2)


# "Waits on open question 3", "...questions 2 and 11".
func waits() -> String:
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


# One line for lists: what using it takes, or how a passive works.
func summary() -> String:
	if stub:
		return "Not built yet"
	if passive:
		return "Toggle" if toggle else "Always on"
	var parts := ["%s AP" % num(ap)]
	if cost:
		parts.append("%d cost%s" % [cost, " x rank" if cost_per_rank else ""])
	if zone:
		parts.append("area %s" % num(radius))
	elif self_only:
		parts.append("on itself")
	elif radius_mod and radius_per_rank:
		parts.append("range rank + %s mod" % String(radius_mod).left(3))
	elif radius_mod:
		parts.append("range %s%s mod" % [num(radius) + " + " if radius else "", String(radius_mod).left(3)])
	elif radius_per_rank:
		parts.append("range %srank%s" % ["" if radius_per_rank == 1 else num(radius_per_rank) + " x ",
				" %s %s" % ["+" if radius > 0 else "-", num(absf(radius))] if radius else ""])
	else:
		parts.append("range %s" % num(radius))
	return " · ".join(parts)


# Everything it does at this rank, for tooltips and the spellbook.
func describe(rank := 1) -> String:
	var lines: PackedStringArray = []
	if stub:
		lines.append("Not built yet. " + waits())
		if plan:
			lines.append(plan)
		return "\n".join(lines)
	var foe := "On a foe: " if dual else ""
	var ally := "On an ally: " if dual else ""
	if passive:
		lines.append("Passive" + (", switched on and off" if toggle else ", always on"))
	else:
		var kind := "Channel" if channel else "Area" if zone else ("Self" if self_only else ("Ally or foe" if dual or either else ("Attack" if hostile else ("Heal" if heals() else "Support"))))
		lines.append("%s · %s" % [kind, summary()])
		for r: Reserve in ap_with:
			lines.append("%s AP paid with %s" % [share(ap_with[r]), r.name])
		for r: Reserve in cost_with:  # the skill opening a reserve goes by its name (Mana)
			lines.append("%s cost paid with %s, once the caster's %s rank reaches its tier" % [share(cost_with[r]), r.name, r.name])
		if attacks():
			lines.append("%s%s d20 + %s mod against Defense; a natural 20 doubles damage" % [foe, "rolls" if dual else "Rolls", String(stat()).left(3)])
		if zone:
			lines.append("Lays %s concealment around a tile for %d turns" % [zone, turns])
		if observes:
			lines.append("Inspects around a tile as if it had rested %d turn%s: every tile within wis mod (at least 1) + %d tiles of it, at +%d, -1 a tile from it"
					% [rank, "" if rank == 1 else "s", rank, rank])
		if prays:
			var n := rank
			var s := "" if n == 1 else "s"
			lines.append("Prays to the caster's god:")
			lines.append("Ramut: its side waits %d turn%s less for Ramut's Ire" % [n, s])
			lines.append("Eros: up to %d unit%s within %d tile%s that can see it lose a stack of suspicion of it" % [n, s, n, s])
			lines.append("Sol: darkness within %d tile%s is gone" % [n, s])
			lines.append("Urlo: enchants %d unenchanted item%s of allies within %d tile%s, weapons first (+1)" % [n, s, n, s])
			lines.append("Luun: the ground within %d tile%s falls into darkness for %d turn%s, concealing its side a level" % [n, s, n, s])
			lines.append("Drael: takes %d rank%s of debuffs off an ally within %d tile%s, the highest first" % [n, s, n, s])
			lines.append("Vetruvis: the ground within %d tile%s becomes disturbed earth for %d turn%s, costing its enemies 50%% more to enter" % [n, s, n, s])
		if save:
			lines.append("The foe saves: d20 + %s mod%s against d20 + %s mod + %d" % [String(save).left(3),
					" + the ranks of the skills it would lose" if disables else "", String(stat()).left(3), rank])
		if disables:
			var n := floori(sqrt(rank))
			var up := ceili(sqrt(rank))
			lines.append("Failing, %s of its skill slots are disabled, from the right%s; its pillar skills go first, all as one slot"
					% [str(n) if n == up else "%d (%d while lucky)" % [n, up], _lasting(rank)])
		if lays:
			var bonus := " + %s" % String(lays.bonus_stat).left(3) if lays.bonus_stat else ""
			lines.append("Sets a %s: concealment %d, %dd%d x %d%s %s" % [lays.name.to_lower(), lays.concealment * rank,
					lays.dice.x, lays.dice.y, lays.times * rank, bonus, " ".join(lays.damage_tags.filter(func(t): return t != &"trap"))])
			if &"trap" in tags:
				lines.append("Allies within its charisma mod in tiles learn where it is")
		var t := tier(rank)
		if channel:
			lines.append("Channels on a tile. Cast again for %s AP and %d cost to strike: a tile within (its side's turns since) tiles of it explodes, hitting everyone within %s tiles but the caster"
					% [num(strike_ap), strike_cost, num(blast * rank)])
		if t:
			var dmg := _damage(t)
			if dice_per_rank and rank > 1:
				dmg = dmg.replace("%dd%d" % [t.dice.x, t.dice.y], "%dd%d" % [t.dice.x * rank, t.dice.y])
			if hits_per_rank and rank > 1:
				dmg = "%d hits of %s" % [rank, dmg]
			lines.append(foe + ("deals " if dual else "Deals ") + dmg)
			if &"energy" in tags:
				lines.append("Energy damage: it drains Energy (or Power) first" + (", then %d%% of the rest goes on to HP" % roundi(carry * (rank - 1) * 100) if carry * (rank - 1) > 0 else ""))
		if grants:
			lines.append("Gives %s for %d turns" % [grants.name, lasts(rank)])
		if heals():
			var mods := " + ".join(heal_mods.map(func(x): return String(x).left(3) + " mod"))
			if heal_split > 1:
				mods = "(%s) / %d" % [mods, heal_split]
			lines.append("Heals %s%s HP, at least 1" % [mods, (" + %d" % heal_bonus if mods else str(heal_bonus)) if heal_bonus else ""])
			lines.append("Clears wounds up to rank %d%s" % [clears(rank), " (rank x rank)" if squared else ""])
			if per_wound:
				lines.append("+%d HP for each wound it clears" % (per_wound * rank))
			if restores > 0.0:
				lines.append("Gives back %s AP" % num(restores * rank))
		if drags_to:
			lines.append("%s contest in place of an attack roll, -1 a tile it must drag the foe%s. Won: drags it to the nearest %s the caster could walk to, and both go in"
					% [String(stat()).left(3).capitalize(), " (less %d)" % (rank - 1) if rank > 1 else "", drags_to])
		if grip != Vector2i.ZERO:
			lines.append("Holds it: moving away first takes 1 + the caster's %s mod tiles of movement and a %s contest. Each turn it ends held, it takes %dd%d + %s mod"
					% [String(stat()).left(3), String(stat()).left(3), grip.x, grip.y, String(stat()).left(3)])
		if pull:
			lines.append("%s%s it up to %d tile%s toward the caster" % [foe, "draws" if dual else "Draws", pull * rank, "" if pull * rank == 1 else "s"])
		if resisted:
			lines.append("%s%s enraptured (fooled by the caster, with no suspicion of it) comes. On a suspicious one, %s mod against its %s mod takes a stack of suspicion off"
					% [foe, "only one" if dual else "Only one", String(stat()).left(3), String(resisted).left(3)])
		if auto:
			lines.append("Used at once: lands on the nearest %d unit%s in range, allies and foes alike" % [rank, "" if rank == 1 else "s"])
	for e in effects:
		lines.append(ally + e.describe(rank) + ("" if passive else _lasting(rank)))
	if has_look():
		var look := ([stance] if stance else []) + [", ".join(shows_vibe)] + [", ".join(shows_tags)]
		lines.append("Puts forward a look: %s. Its holder's dissonance counts %d less against its own rolls"
				% ["; ".join(look.filter(func(x: String): return x != "")), rank])
	if investigated:
		lines.append("Rolls once as it's used: d20 + %s mod + %d. Enemies that can see it investigate at once, d20 + wis mod (the better of two within wis mod - %d tiles) against that roll. Those who meet it aren't fooled by it"
				% [String(stat()).left(3), rank, rank])
	if not energy_as.is_empty():
		lines.append("Energy paid for %s skills counts as their own resources, with the bonuses those give" %
				" or ".join(energy_as.map(func(t): return CATEGORIES.get(t, String(t)).to_lower())))
	if opens:
		lines.append("Cheaper casting with %s: skills up to tier %d get the savings they list for it" % [opens.name, rank])
	if stand_in:
		lines.append("%s stands in for %s on %s skills" % [stand_in.capitalize(),
				", ".join(replaces.map(func(x): return String(x).capitalize())), ", ".join(tags)])
	if rank_cost:
		lines.append("Ranks cost more: II takes %d points, then x%s each rank" % [rank_cost, num(rank_growth)])
	if not tags.is_empty() and not stand_in:
		lines.append("Tags: " + ", ".join(tags))
	return "\n".join(lines)


# How long its put-on effects last at a rank: " for 2 turns", " until it moves", " for 2 turns,
# then a level less each turn".
func _lasting(rank: int) -> String:
	var n := lasts(rank)
	var text := " for %d turn%s" % [n, "" if n == 1 else "s"] if n else ""
	if turns_mod:
		text = " for %s mod + %d turns" % [String(turns_mod).left(3), n]
	if until_move:
		text += (", or" if n else "") + " until it moves"
	if fades and n:
		text += ", then a level less each turn"
	return text


func _damage(t: Tier) -> String:
	var parts: PackedStringArray = []
	if t.power:
		parts.append(str(t.power))
	if t.dice != Vector2i.ZERO:
		parts.append("%dd%d" % [t.dice.x, t.dice.y])
	if t.stat:
		parts.append(String(t.stat).left(3))
	return " + ".join(parts) + (", unblockable" if t.direct else "")


# "Half", "A quarter", "x0.75": a cost or AP factor.
static func share(f: float) -> String:
	if is_equal_approx(f, 0.5):
		return "Half"
	if is_equal_approx(f, 0.25):
		return "A quarter"
	return "x" + num(f)


static func num(x: float) -> String:
	return str(roundi(x)) if is_equal_approx(x, roundf(x)) else String.num(x, 2)

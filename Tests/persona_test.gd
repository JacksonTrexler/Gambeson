extends Test

# Persona beyond the Siren's lies: Personify, Embellish and Brood on the Adventurer's, Bard's and
# Rogue's trees; fronting, which fools allies that aren't insightful without trickery
# (Perception.fronts_to()); Embellish (cast on itself or an ally) and Brood making stats seem higher
# or lower to those they fool (Perception._seem()); dissonance: what an insightful observer reads of
# how true a presentation is (Perception.insight()), tallied from what its persona puts forward
# (Unit.dissonance()), and a penalty to its own deceiving rolls; and the Astral Princess's Physical
# Intelligence.

var personify: Skill = load("res://Skills/persona.tres")
var embellish: Skill = load("res://Skills/embellish.tres")
var brood: Skill = load("res://Skills/brood.tres")
var clever: Skill = load("res://Skills/clever_disguise.tres")


func siren() -> Unit:
	return b.get_node("Units/Siren")


# Puts nothing forward through its persona: no vibe, tags, stance, claimed level or name.
func bare(u: Unit) -> void:
	u.shows_vibe.clear()
	u.shows_tags.clear()
	u.stance = ""
	u.shows_level = 0
	u.alias = ""
	u.alias_noun = ""


func test_trees() -> void:
	for path in ["res://Roles/adventurer.tres", "res://Roles/bard.tres"]:
		var role: Role = load(path)
		ok(role.tier(personify) == 1 and role.tier(embellish) == 2 and role.tier(brood) == 2 and role.root_of(embellish).tag == &"specialist",
				"%s: Personify (tier 1), then Embellish and Brood (tier 2)" % role.name)
	var rogue: Role = load("res://Roles/rogue.tres")
	ok(rogue.tier(brood) == 2 and rogue.tier(personify) == -1, "the Rogue: Brood after Meander (tier 2), no Personify")
	ok(personify.name == "Personify" and "Persona: +2" in personify.describe(2), "Personify: +rank persona (%s)" % personify.describe(2))


func test_insight() -> void:
	var s := siren()
	ok(v(1).insightful() and not v(1).wisdom < 12, "wis 12: insightful")
	v(1).afflict(effect("recon", 1), 9)
	var fooled := b.read(v(1), s)
	ok(fooled.deceived and fooled.insight == "%s is as they appear; they make no attempt to appear otherwise." % s.alias,
			"fooled: it seems to make no attempt (%s)" % fooled.insight)
	v(1).afflict(effect("recon", 3), 9)
	ok(s.dissonance() == 4 + 1 + 1 + 1, "its dissonance, tallied from what it puts forward: 4 vibe words, a tag, a stance, a name (%d)" % s.dissonance())
	ok(s.dissonance_penalty() == 7 - 4, "a practised lie: Alluring IV takes 4 off it against its own rolls")
	var noun := s.alias_noun
	bare(s)
	ok(b.read(v(1), s).insight == "Siren is as they appear; they make no attempt to appear otherwise.", "seen through, putting nothing forward: as it appears")
	s.stance = "Friendly"
	ok(s.dissonance() == 1 and b.read(v(1), s).insight == "Siren is pretending to be something they aren't.", "one thing (a stance): pretending")
	s.set_alias("Radiant", noun)
	var words := ", ".join(s.shows_adjectives.slice(0, -1)).to_lower() + " or " + s.shows_adjectives[-1].to_lower()
	ok(s.dissonance() == 2 and b.read(v(1), s).insight == "Siren isn't as %s, or %s-like as they would have others believe." % [words, s.alias_noun.to_lower()],
			"two (and a name): what it isn't (%s)" % b.read(v(1), s).insight)
	v(2).afflict(effect("persona", 1), 9)
	v(2).shows_vibe.assign(["Kind", "Gentle"])
	v(2).shows_tags.assign([&"holy"])
	v(2).stance = "Friendly"
	ok(v(2).dissonance() == 2, "only what its persona rank puts forward counts: at I, its vibe")
	v(2).extra_dissonance = 3
	ok(v(2).dissonance() == 5, "plus any set on it")
	ok(b.read(v(3), s).deceived and b.read(v(3), s).insight.ends_with(" is as they appear; they make no attempt to appear otherwise."),
			"its own side, fooled by its trickery, reads it as it appears")
	v(1).wisdom = 10
	ok(not v(1).insightful() and b.read(v(1), s).insight == "", "wis mod 0: not insightful")
	v(1).afflict(effect("insight", 1), 9)
	ok(v(1).insightful() and b.read(v(1), s).insight != "", "a bonus to reading others makes it insightful")
	var honest := b.read(v(1), v(3))
	ok(honest.insight == "Villager3 is as they appear; they make no attempt to appear otherwise." or honest.net < 0, "an honest villager is as it appears")


func test_embellish() -> void:
	var s := siren()
	stage(nemes, {s: Vector2i(8, 6), v(3): Vector2i(8, 5), v(4): Vector2i(7, 5), v(1): Vector2i(1, 1)})
	s.learned.append(slot(embellish, 1))
	s.refresh()
	ok(embellish.summary() == "Ally · range rank - 1 · 2 AP · 2 cost" and not b.cast(s, embellish, v(3)), "Embellish I: on itself only (%s)" % embellish.summary())
	s.learned[-1].rank = 2
	ok(b.cast(s, embellish, s) and b.cast(s, embellish, v(3)), "Embellish II: itself, or an adjacent ally")
	ok(s.timed[embellish.effects[0]].turns == 4 and roundi(v(3).stat(&"embellish")) == 2, "3 turns (after this one), at rank 2")
	ok(Perception.embellish(s) == {&"charisma": 1.2, &"strength": 1.2}, "its two highest (cha 18, then str 12 before its equals)")
	v(1).afflict(effect("recon", 1), 9)
	var r := b.read(v(1), s)
	ok(r.deceived and r.stats[&"charisma"] == 22.0 and r.stats[&"strength"] == 14.0 and r.stats[&"dexterity"] == 12.0,
			"to those it fools, they seem 20% higher (cha 22, str 14)")
	ok(not b.read(v(1), v(3)).deceived and b.read(v(1), v(3)).stats.is_empty() or b.read(v(1), v(3)).stats[&"wisdom"] == 12.0,
			"no trickery: an embellished villager doesn't fool its enemies")
	v(4).wisdom = 10
	v(3).charisma = 10  # cha 8 would make it hard for v(4) to read
	v(4).afflict(effect("recon", 1), 9)
	var friend := b.read(v(4), v(3))
	var puffed := Perception.embellish(v(3))
	ok(friend.deceived and friend.twist == 0.0 and puffed.size() == 2 and puffed.keys().all(func(x): return friend.stats[x] == roundf(v(3).stat(x) * 1.2)),
			"but it fools an ally that isn't insightful, nothing twisted")
	v(4).wisdom = 12
	ok(not b.read(v(4), v(3)).deceived, "an insightful ally isn't fooled by fronting alone")
	v(1).afflict(effect("recon", 3), 9)
	var true_read := b.read(v(1), s)
	ok(not true_read.deceived and true_read.stats[&"charisma"] == 18.0, "untricked: the truth")
	bare(s)
	ok(s.dissonance() == 1 and b.read(v(1), s).insight == "Siren is trying to look strong.", "embellishing alone: trying to look strong")
	s.extra_dissonance = 1
	ok("charming, or " not in b.read(v(1), s).insight and "harmless, charming or strong" in b.read(v(1), s).insight,
			"dissonance 2: the stats it inflates join its adjectives (%s)" % b.read(v(1), s).insight)
	s.timed[embellish.effects[0]].rank = 7
	ok(Perception.embellish(s)[&"charisma"] == 1.4 and Perception.embellish(s).size() == 6, "past six: back to the highest (x1.4)")


func test_brood() -> void:
	var s := siren()
	stage(nemes, {s: Vector2i(8, 6), v(3): Vector2i(8, 5), v(4): Vector2i(5, 5), v(1): Vector2i(1, 1)})
	s.learned.append(slot(brood, 1))
	s.refresh()
	v(1).afflict(effect("recon", 1), 9)
	var r := b.read(v(1), s)
	ok(r.stats[&"charisma"] == 14.0 and r.stats[&"strength"] == 9.0, "Brood I: 25% lower to those it fools (cha 18 seems 14, str 12 seems 9)")
	ok(b.read(v(1), s).insight.ends_with(" is as they appear; they make no attempt to appear otherwise."), "fooled, it seems to make no attempt")
	v(1).afflict(effect("recon", 3), 9)
	ok(b.read(v(1), s).stats[&"charisma"] == 18.0, "untricked: the truth")
	bare(s)
	ok(b.read(v(1), s).insight == "Siren is trying to look weak.", "brooding alone: trying to look weak")
	v(1).timed.clear()
	v(1).afflict(effect("recon", 1), 9)
	s.learned[-1].rank = 4
	ok(b.read(v(1), s).stats.values().slice(0, 6).all(func(x): return x == 1.0), "Brood IV: every stat seems 1, no lower")
	var plain := b.read(v(1), v(3)).stats.duplicate()
	s.learned[-1].rank = 5
	var near := b.read(v(1), v(3))
	ok(Unit.CORE.slice(0, 6).all(func(x): return near.stats[x] == maxf(roundf(plain[x] * 0.9), 1.0)), "Brood V: an adjacent ally seems 10% lower too")
	ok(b.read(v(1), v(4)).stats[&"wisdom"] == 12.0, "one further off doesn't")
	v(1).afflict(effect("recon", 5), 9)
	ok(b.read(v(1), v(3)).stats[&"wisdom"] == 12.0, "nor to one the brooder doesn't fool")


func test_physical_intelligence() -> void:
	var pi: Skill = load("res://Skills/physical_intelligence.tres")
	var u := v(1)
	u.strength = 18
	u.intelligence = 8
	u.learned.append(slot(pi, 5))
	u.refresh()
	ok(u.mod(&"intelligence", [&"magical"]) == 4 and u.mod(&"intelligence") == -1, "rank V: str mod (+4) for int on magical skills only")
	u.learned[-1].rank = 1
	ok(u.mod(&"intelligence", [&"magical"]) == 0, "rank I: capped at int / 80% (10)")
	ok(&"pillar" in pi.tags, "a pillar")


func test_dissonance_investigation() -> void:
	stage(nemes, {siren(): Vector2i(8, 6), v(1): Vector2i(7, 6)})
	siren().learned.append(slot(clever, 1))
	siren().refresh()
	siren().extra_dissonance = 50
	var looks := []
	b.investigated.connect(func(by: Unit, _of: Unit, _s: Skill, total: int, against: int, _c: bool): looks.append([by, total, against]))
	ok(b.cast(siren(), clever, siren()), "the Siren disguises itself")
	ok(looks.size() == 1 and looks[0][2] <= 20 + siren().mod(&"charisma") + 1 - 50 and looks[0][1] >= looks[0][2],
			"its dissonance comes off its own roll: a less believable lie (%d vs %d)" % [looks[0][1], looks[0][2]])
	ok(v(1) in siren().timed[clever.effects[0]].known_to, "so it's seen through")


# Alluring carries the look a persona puts forward: any unit with it shows it, on top of its own.
func test_alluring_look() -> void:
	var alluring: Skill = load("res://Skills/alluring.tres")
	ok(alluring.has_look() and siren().stance == "Friendly" and "Serene" in siren().shows_vibe and siren().shows_tags == [&"holy"]
			and siren().shows_nouns.has("Songstress"), "the Siren's serene, safe look is Alluring's")
	ok("Puts forward a look: Friendly; Harmless, Beautiful, Serene, Safe; holy. Its holder's dissonance counts 4 less against its own checks" in alluring.describe(4),
			"described (%s)" % alluring.describe(4))
	var u := v(2)
	bare(u)
	u.shows_vibe.assign(["Kind"])
	u.learned.append(slot(alluring, 2))
	u._take_looks()
	ok(u.stance == "Friendly" and u.shows_vibe == ["Kind", "Harmless", "Beautiful", "Serene", "Safe"] and u.shows_tags == [&"holy"],
			"a villager with it puts the look forward too, on top of its own vibe")
	ok(u.dissonance() == 5 + 1 and u.dissonance_penalty() == 6 - 2, "Alluring II: 2 off its dissonance penalty (%d)" % u.dissonance_penalty())
	u.learned[-1].rank = 9
	ok(u.dissonance_penalty() == 0, "never below 0")

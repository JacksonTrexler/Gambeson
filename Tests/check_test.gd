extends Test

const STUN := preload("res://Behaviours/stun.gd")
const HITCH := preload("res://Behaviours/hitch.gd")
const SLAM_JAM := preload("res://Behaviours/slam_jam.gd")

# The Check resolver (Check, Battle.resolve): the one definition of a d20 roll - attack vs Defense, a
# natural 20, advantage, and a forced-sure hit (docs/plan-composability.md, seam 1).

func test_roll_invariants() -> void:
	for n in 300:
		var r := b.resolve(Check.attack(5, 12))
		ok(r.total == r.d20 + 5 and r.target == 12 and r.margin() == r.total - 12, "total is d20 + bonus; margin is total - target")
		ok(r.crit == (r.d20 == 20), "a natural 20 is a crit")
		ok(r.hit == (r.crit or r.total >= 12), "a hit meets Defense, or crits")
		ok(r.d20 >= 1 and r.d20 <= 20, "the face is a d20")


func test_crit_and_sure() -> void:
	ok(not b.resolve(Check.check(-50, 10)).hit, "a plain check far below its DC misses (no crit to save it)")
	ok(b.resolve(Check.attack(-50, 10).sure()).hit, "a sure() attack hits however the die falls")
	var nat := 0
	var hopeless_hits := 0
	for n in 400:
		var r := b.resolve(Check.attack(-50, 10))  # only a natural 20 can land this
		if r.hit:
			hopeless_hits += 1
			ok(r.glance and not r.crit, "the only way a hopeless attack lands is a glance (a miss in crit range)")
		if r.d20 == 20:
			nat += 1
	ok(hopeless_hits == nat and nat > 0, "a natural 20 always lands, even far below Defense: as a glance (%d)" % nat)
	ok(Check.outcome(Check.attack(5, 10), 20, 20, 10) == Check.CRIT, "a natural 20 that would hit anyway is a critical")


func test_advantage() -> void:
	var single := 0
	var better := 0
	for n in 400:
		single += b.resolve(Check.check(0, 0)).d20
		better += b.resolve(Check.check(0, 0).edge(1)).d20
	ok(better > single, "the better of two d20s averages higher (%.1f vs %.1f)" % [better / 400.0, single / 400.0])


func test_beats() -> void:
	var ties := 0
	for n in 400:
		var vs := b.beats(Check.side(3), Check.side(3))
		ok(vs.mine.total == vs.mine.d20 + 3 and vs.theirs.total == vs.theirs.d20 + 3, "each side rolls d20 + its bonus")
		ok(vs.won == (vs.mine.total >= vs.theirs.total), "the one acting wins ties")
		var held := b.beats(Check.side(3), Check.side(3), false)
		ok(held.won == (held.mine.total > held.theirs.total), "unless it must beat the other outright (breaking free)")
		if vs.mine.total == vs.theirs.total:
			ties += 1
	ok(ties > 0, "ties happen, and go to the one acting (%d)" % ties)
	ok(not b.beats(Check.side(-40), Check.side(40)).won and b.beats(Check.side(40), Check.side(-40)).won, "a lopsided contest goes the way of the bonus")


func test_no_inline_d20() -> void:
	var src := FileAccess.get_file_as_string("res://Scripts/Battle.gd")
	ok(src.count("randi_range(1, 20)") == 2, "every d20 in Battle goes through resolve() (its own two rolls: one die, the edge's second)")


func test_cut() -> void:
	for n in 100:
		var r := b.resolve(Check.check(10, 0).cut(0.5))
		ok(r.total == floori((r.d20 + 10) * 0.5), "only half its total counts, rounded down")


# An execute (a skill tagged execute) cuts a foe's defensive check by how hurt it is: HP left / max HP
# / rank, as Death does a last stand (Battle.executed()).
func test_execute() -> void:
	v(3).max_hp = 100
	v(3).hp = 25
	var death: Skill = load("res://Skills/death.tres")
	ok(is_equal_approx(Battle.executed(v(3), death, 1), 0.25) and is_equal_approx(Battle.executed(v(3), death, 2), 0.125), "a quarter left: x0.25 at rank I, x0.125 at II")
	ok(Battle.executed(v(3), strike, 1) == 1.0, "nothing to cut against what isn't an execute")
	var grip: Skill = load("res://Skills/interdict.tres").duplicate()
	grip.tags.append(&"execute")
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).learned.append(slot(grip))
	v(3).strength = 40  # str mod 15: unhurt, it would nearly always win
	v(3).hp = 1
	var theirs := []
	b.contested.connect(func(_c, _t, _mine, against): theirs.append(against))
	for n in 20:
		v(1).refresh()
		v(1).energy = v(1).max_energy
		b.cast(v(1), grip, v(3))
	ok(theirs.size() == 20 and theirs.all(func(t): return t == 0), "1 HP of 100: its saves count for nothing (%s)" % [theirs])


# The one check helper (Battle.check(), odds(), sides(); docs/plans/checks.md): ties, kinds, the better
# of several stats, a range penalty, a cut, and odds that match what it rolls.
func test_check_helper() -> void:
	ok(is_equal_approx(Check.odds(Check.side(0), Check.side(0)), 0.525), "even sides: the actor wins ties, 21/40 (%s)" % Check.odds(Check.side(0), Check.side(0)))
	ok(is_equal_approx(Check.odds(Check.side(0), Check.side(0), false), 0.475), "...and loses them with ties false")
	ok(is_equal_approx(Check.odds(Check.side(-50), Check.side(0)), 0.0) and is_equal_approx(Check.odds(Check.side(50), Check.side(0)), 1.0), "hopeless and certain")
	ok(Check.odds(Check.side(0).edge(1), Check.side(0)) > 0.65 and Check.odds(Check.side(0).edge(-1), Check.side(0)) < 0.4, "advantage and disadvantage weigh in")
	var a := v(1)
	var t := v(3)
	var s := Battle.sides(a, &"strength", t, [&"strength", &"dexterity"], {bonus = 2, penalty = 1, tiles = 3, cut = 0.5})
	ok(s[0].bonus == a.check_mod(&"strength", &"offensive") + 2 - 3, "a's side: its check mod + bonus - penalty x tiles (%d)" % s[0].bonus)
	ok(s[1].bonus == maxi(t.check_mod(&"strength", &"defensive"), t.check_mod(&"dexterity", &"defensive")) and is_equal_approx(s[1].share, 0.5), "b's: the better stat, defensive, cut")
	ok(Battle.sides(a, &"", t, &"", {bonus = 4, their_bonus = 1})[0].bonus == 4, "a stat &\"\": its bonus alone")
	var won := 0
	for n in 2000:
		if b.check(a, &"strength", t, &"strength", {bonus = 3}).won:
			won += 1
	var p := Battle.odds(a, &"strength", t, &"strength", {bonus = 3})
	ok(absf(won / 2000.0 - p) < 0.05, "odds() matches what check() rolls (%.3f vs %.3f)" % [won / 2000.0, p])


# A check against a number rolled earlier (Battle.check() given a total: investigating, a last-stand fall,
# Level Down's bar): that side spends no die, ties and a cut work as on any side, and odds() weighs it.
func test_check_against_a_total() -> void:
	b.rng.seed = 5
	var before := b.rng.state
	var c := b.check(null, &"", null, 15, {bonus = 5})
	ok(c.theirs.total == 15 and c.mine.total == c.mine.d20 + 5 and c.won == (c.mine.total >= 15), "it meets the total with a d20 + its bonus (%d vs %d)" % [c.mine.total, c.theirs.total])
	b.rng.seed = 5
	b.check(null, &"", null, 15, {bonus = 5})
	var one_die := b.rng.state
	b.rng.state = before
	b.rng.randi_range(1, 20)
	ok(one_die == b.rng.state, "only its own die rolls")
	ok(is_equal_approx(Battle.odds(null, &"", null, 15, {bonus = 5}), 0.55) and is_equal_approx(Battle.odds(null, &"", null, 15, {bonus = 5, ties = false}), 0.5), "d20 + 5 meets 15 on 11 faces of 20, 10 with ties lost")
	ok(is_equal_approx(Battle.odds(null, &"", null, 15, {bonus = 5, edge = 1}), 1.0 - 0.45 * 0.45), "advantage on its die")
	ok(is_equal_approx(Battle.odds(null, &"", null, 15, {bonus = 5, their_bonus = 3}), 0.4), "their_bonus adds to the total (18)")
	ok(is_equal_approx(Battle.odds(null, &"", null, 20, {bonus = 5, cut = 0.5}), 0.8), "a cut halves it (10): d20 + 5 meets it on 16 faces")
	var won := 0
	for n in 2000:
		if b.check(null, &"", null, 15, {bonus = 5}).won:
			won += 1
	ok(absf(won / 2000.0 - 0.55) < 0.05, "odds() matches what it rolls (%.3f)" % (won / 2000.0))


# Rolls against a fixed DC (a dodge, Stun's save, Recovery Endurance's, Bandwagon's) and the checks after a hit (Hitch's
# grapple, Slam Jam's contest) are the helper's, so its odds forecast them: Stun, Hitch and Slam Jam say what a
# hit would bring (Behaviour.foresee()) from the odds of the very roll apply() makes; an evade rolls as odds say.
func test_dc_and_rider_forecasts() -> void:
	for f in ["Battle.gd", "RecoveryEndurance.gd"]:  # (Battle's: the initiative d20, and the two last stands)
		var src := FileAccess.get_file_as_string("res://Scripts/" + f)
		ok(src.count("Check.check(") == (3 if f == "Battle.gd" else 0), "%s: no DC roll builds its own Check" % f)
	for f in DirAccess.get_files_at("res://Behaviours"):
		ok("Check.check(" not in FileAccess.get_file_as_string("res://Behaviours/" + f), "%s: nor a behaviour's" % f)
	stage(nemes, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var braced := effect("check", 6.0)
	braced.kind = &"defensive"
	v(3).afflict(braced, 9)  # a defensive check bonus only: a dodge is a defensive roll
	var dex := Battle.odds(v(3), &"dexterity", null, 12, {role = &"defensive"})
	var got := 0
	for n in 1500:
		got += 1 if b.evade(v(3), 12) == 0.0 else 0
	ok(dex > 0.2 and dex < 0.9 and absf(got / 1500.0 - dex) < 0.04, "a dodge passes as often as its odds say (%.3f vs %.3f)" % [got / 1500.0, dex])
	for pair in [["stun", "Stuns it"], ["hitch", "Holds it"], ["slam_jam", "Interrupts it, Jammed"]]:
		var s: Skill = load("res://Skills/%s.tres" % pair[0])
		v(1).learned.append(slot(s, 2))
		v(1).refresh()
		var more := b.foresee(v(1), s, v(3))
		var note: String = more.get("notes", [""])[0]
		var c := b.cast_of(v(1), s, v(3), 2, true)
		var p := Battle.odds(v(3), &"constitution", null, STUN.dc(c), STUN.save_opts(c))
		match pair[0]:
			"stun": p = 1.0 - p
			"hitch": p = Battle.odds(v(1), &"strength", v(3), HITCH.FOE_STATS, HITCH.grapple(c))
			"slam_jam": p = Battle.odds(v(1), &"strength", v(3), &"constitution", SLAM_JAM.contest(c))
		ok(note == "%s (%d%%)" % [pair[1], roundi(p * 100.0)] and more.riders == 0.0 and more.afflicts > 0.0 and more.afflicts <= p and p > 0.0 and p < 1.0, "%s: \"%s\" is the odds of its roll" % [pair[0], note])
	var s: Skill = load("res://Skills/stun.tres")
	var c := b.cast_of(v(1), s, v(3), 2, true)
	var held := 0
	for n in 600:
		v(3).timed.clear()
		b.interrupt(v(3))
		c.bag.clear()
		s.behaviours[0].apply(c)
		held += 1 if c.bag.get(&"stunned", false) else 0
	var p := 1.0 - Battle.odds(v(3), &"constitution", null, STUN.dc(c), STUN.save_opts(c))
	ok(absf(held / 600.0 - p) < 0.06, "Stun lands as often as it said (%.3f vs %.3f)" % [held / 600.0, p])


	# Hitch's apply() rolls the same options foresee() weighs: it holds as often as grapple()'s odds say.
	var hs: Skill = load("res://Skills/hitch.tres")
	var hc := b.cast_of(v(1), hs, v(3), 4, true)
	v(1).strength = 14
	v(3).strength = 10
	v(3).dexterity = 14
	v(1).refresh()
	v(3).refresh()
	var hp := Battle.odds(v(1), &"strength", v(3), HITCH.FOE_STATS, HITCH.grapple(hc))
	var hheld := 0
	for n in 2000:
		hc.bag.clear()
		v(3).timed.clear()
		hs.behaviours[0].apply(hc)
		hheld += 1 if hc.bag.get(&"hitched", false) else 0
	ok(hp > 0.2 and hp < 0.8 and absf(hheld / 2000.0 - hp) < 0.035, "Hitch holds as often as its options say (%.3f vs %.3f)" % [hheld / 2000.0, hp])

	# Level Down's branch of hit_chance() alone: a foe gets level_odds() at its rank impact, an ally the plain 1.0.
	var ld: Skill = load("res://Skills/level_down.tres")
	v(1).learned.append(slot(ld, 3))
	v(1).refresh()
	var lp := Battle.hit_chance(v(1), ld, v(3), b)
	var want := Battle.level_odds(v(1), ld, v(3), v(1).mods(ld).irank(v(1).rank(ld), &"rank_impact"), b)
	ok(is_equal_approx(lp, want) and lp > 0.0 and lp < 1.0, "Level Down's chance is level_odds at its rank (%.3f vs %.3f)" % [lp, want])
	ok(is_equal_approx(Battle.hit_chance(v(1), ld, v(2), b), 1.0), "an ally is not rolled against")

# A declared check (Skill.check) as the helper reads it: + rank when ranked, its edge, a range penalty a
# tile past the first (1 less a rank past I), its own check tags beside the skill's.
func test_declared_check() -> void:
	var s: Skill = load("res://Skills/haluca.tres").duplicate()
	s.check = s.check.duplicate()
	s.check.range_penalty = 2
	s.check.edge = -1
	s.check.tags = [&"taps"] as Array[StringName]
	v(1).learned.append(slot(s, 1))
	v(1).refresh()
	stage(nemes, {v(1): Vector2i(1, 1), v(3): Vector2i(5, 1)})
	var o := Battle.skill_opts(v(1), s, v(3))
	ok(o.penalty == 2 and o.tiles == 3 and o.edge == -1 and o.kind == Check.Kind.SAVE, "rank I: -2 a tile, 3 tiles past the first, disadvantage, a save (%s)" % o)
	ok(&"taps" in o.tags and &"magical" in o.tags and &"taps" not in s.tags, "its check tags join the skill's (which keep their own)")
	ok(Battle.sides(v(1), &"charisma", v(3), &"wisdom", o)[0].bonus == v(1).check_mod(&"charisma", &"offensive", o.tags) + 1 - 6, "+ rank 1, - 2 x 3")
	ok(s.check.penalty(3, 3) == 0 and s.check.penalty(2, 3) == 3, "the penalty falls 1 a rank past I")


# A Glance (the user's word): a face in crit range that would miss lands anyway, a hit for half
# (Check.outcome(), the one place an attack's outcome is decided); glancing, at disadvantage, a miss whose
# better die would land glances too (Glancing Strike). Check.outcomes() is the same, unrolled.
func test_glance_outcomes() -> void:
	var c := Check.attack(0, 30)
	ok(Check.outcome(c, 20, 20, 30) == Check.GLANCE, "a natural 20 that would miss glances")
	c.keen(2)
	ok(Check.outcome(c, 18, 18, 30) == Check.GLANCE and Check.outcome(c, 17, 17, 30) == Check.MISS, "crit range 18 and up: 18 glances, 17 misses")
	ok(Check.outcome(Check.attack(15, 10).keen(2), 18, 18, 10) == Check.CRIT, "in range and hitting: a critical")
	var d := Check.attack(0, 15).edge(-1)
	ok(Check.outcome(d, 3, 16, 15) == Check.MISS, "at disadvantage the worse die counts")
	d.glancing = true
	ok(Check.outcome(d, 3, 16, 15) == Check.GLANCE and Check.outcome(d, 3, 14, 15) == Check.MISS, "glancing: the better die would hit, a glance; both miss, a miss")
	var o := Check.outcomes(Check.attack(0, 100).keen(3))
	ok(is_equal_approx(o[0], 0.2) and is_equal_approx(o[2], 0.2) and o[1] == 0.0, "hopeless, crit range 17 and up: 4 faces in 20 land, all glances (%s)" % [o])
	o = Check.outcomes(d)
	ok(is_equal_approx(o[0], 0.51) and is_equal_approx(o[2], 0.42) and is_equal_approx(o[1], 1.0 / 400.0), "glancing vs 15 at +0: lands when the better die reaches it, 51%%, 42%% as a glance (%s)" % [o])


# The crit range hook (Effect stat crit_range: Backstab) on a real cast: faces in range that miss land as
# glances for half damage (Battle.as_rolled()), and the forecast (hit_chance(), attack_odds()) says so.
func test_crit_range_glances() -> void:
	var s: Skill = strike.duplicate()
	s.chain = false
	s.hits_per_rank = false
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	v(1).learned.append(slot(s, 1))
	v(1).strength = 28  # mod 9: a hit deals 1 + 9
	v(1).weapon = null
	v(3).afflict(effect("defense", 200), 99)  # nothing reaches it
	soak(v(3), 100000)
	ok(is_equal_approx(Battle.hit_chance(v(1), s, v(3), b), 0.05), "only a natural 20 lands (%s)" % Battle.hit_chance(v(1), s, v(3), b))
	v(1).learned.append(slot(sk("backstab"), 4))
	ok(Battle.crit_range(v(1)) == 4, "Backstab IV: crit range 4 faces wider (%d)" % Battle.crit_range(v(1)))
	var odds := Battle.attack_odds(v(1), s, v(3), b)
	ok(is_equal_approx(odds[0], 0.25) and is_equal_approx(odds[2], 0.25), "16 and up land, all as glances (%s)" % [odds])
	var seen: Array[Check.Roll] = []
	b.attack_rolled.connect(func(_c, _t, r: Check.Roll): seen.append(r))
	var dealt := []
	v(3).hp_changed.connect(func(was: int, now: int): dealt.append(was - now))
	for i in 80:
		v(1).refresh()
		b.cast(v(1), s, v(3))
	var glances := seen.filter(func(r: Check.Roll): return r.glance)
	ok(seen.size() == 80 and seen.all(func(r: Check.Roll): return r.hit == (r.d20 >= 16) and not r.crit), "16 and up land, never a critical against it")
	ok(glances.size() > 0 and dealt.size() == glances.size() and dealt.all(func(n: int): return n == 5), "each glance deals half of 10: %s" % [dealt])
	var uses := {}
	for r in seen:
		uses[r.use] = true
	ok(uses.size() == 80 and not uses.has(0) and v(1).rolls_made == 1, "each cast its own skill use, its roll counted in it (%d uses, %d)" % [uses.size(), v(1).rolls_made])


# Glancing Strike's two stats as attack_check() reads them, only on a Strike skill's attacks (its effects ask for
# the strike tag, on the attack's tags: hit_tags()): at disadvantage and glancing, any other attack as it was (no
# edge, no glance, no opening bonus, even a non-chain one); + rank to its first rank attack rolls of each skill use
# (Unit.rolls_made, zeroed as a use opens: a real Strike III makes three rolls in one use, the next starts again).
# Friction (Unit.friction, Battle.loops()) on any attack: at disadvantage, - that.
func test_glancing_and_opening() -> void:
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	var plain: Skill = strike.duplicate()
	plain.chain = false
	plain.tags = [&"physical", &"str", &"martial"] as Array[StringName]
	var lone: Skill = strike.duplicate()  # a Strike skill that isn't a chain (Silent Strike, Waterstrike)
	lone.chain = false
	var hit := Battle.hit_tags(v(1), strike)
	v(1).learned.append(slot(sk("glancing_strike"), 2))
	ok(&"strike" in hit and &"strike" in Battle.hit_tags(v(1), sk("waterstrike")) and &"strike" in Battle.hit_tags(v(1), sk("silent_strike")), "Strike, Waterstrike and Silent Strike attack as Strike skills (%s)" % [hit])
	var c := Battle.attack_check(v(1), strike, 3, 15, 0, hit)
	ok(c.advantage == -1 and c.glancing, "a Strike: at disadvantage, glancing")
	ok(Battle.attack_check(v(1), lone, 3, 15, 0, Battle.hit_tags(v(1), lone)).advantage == -1, "any Strike skill, chain or not")
	var other := Battle.attack_check(v(1), plain, 3, 15, 0, Battle.hit_tags(v(1), plain))
	ok(other.advantage == 0 and not other.glancing and other.bonus == 3, "another attack: no edge, no glance, no opening bonus (%d)" % other.bonus)
	ok(Battle.attack_check(v(1), strike, 3, 15, 1, hit).advantage == 0, "advantage from elsewhere cancels it")
	ok(c.bonus == 3 + 2, "+ rank on its first rolls (%d)" % c.bonus)
	v(1).rolls_made = 1
	ok(Battle.attack_check(v(1), strike, 3, 15, 0, hit).bonus == 5, "the second of rank 2's")
	v(1).rolls_made = 2
	ok(Battle.attack_check(v(1), strike, 3, 15, 0, hit).bonus == 3, "then no more")
	v(1).friction = 2
	var f := Battle.attack_check(v(1), plain, 3, 15, 1, Battle.hit_tags(v(1), plain))
	ok(f.advantage == 0 and f.bonus == 1, "friction 2: a step of disadvantage (cancelling advantage) and -2 (%d, %d)" % [f.advantage, f.bonus])
	v(1).friction = 0
	v(1).learned.append(slot(strike, 3))
	v(1).strength = 30  # (str mod 10 at Defense 2: every hit lands)
	v(1).weapon = null
	soak(v(3), 5000)
	var counts := []
	b.attack_rolled.connect(func(_c, _t, r: Check.Roll): counts.append([r.use, v(1).rolls_made]))
	for i in 2:
		v(1).refresh()
		b.cast(v(1), strike, v(3))
	var ids := counts.map(func(x: Array): return x[0])
	ok(counts.size() == 6 and counts.map(func(x: Array): return x[1]) == [1, 2, 3, 1, 2, 3] and ids[0] == ids[2] and ids[3] == ids[5] and ids[0] != ids[3],
			"a Strike's three rolls are one use, counted 1-3; the next Strike a new use (%s)" % [counts])

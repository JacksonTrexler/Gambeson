class_name Downed
extends Resource

# Downed (down but not out): what a passive makes of its holder's death (Skill.downed). On its last
# life, a unit with such a skill taken to 0 HP doesn't fall: it lingers, Downed (Unit.dbno), for
# `rounds` x rank of its side's turns. Meanwhile its HP runs below 0, as far as `limit` x rank of its
# max HP: past that it dies at once. Healed above 0 it's saved (Battle.rescued()); still at 0 or below
# as its last round ends, it dies. Unless it `acts`, it's helpless (Unit.helpless()): it can't act,
# move or take orders. One that acts (Grudge) may be held to `actions` x rank skill uses in all - one
# more, and it dies once that's done - and to a `melee` attack every round: a round ending without
# one, it dies.
# Not the hearts' going down (Unit.downed, Unit.reviving, Battle.fallen): hearts are spent first.

@export var rounds := 1  # x rank: how many of its side's turns it lingers
@export var limit := 0.2  # x rank: the share of its max HP its HP may run below 0
@export var acts := false  # it goes on acting as if it weren't down (Grudge); otherwise it's helpless (Tenacity)
@export var actions := 0  # x rank: the skill uses it may pay for while down, one more killing it; 0: no limit
@export var melee := false  # each round it must make a melee attack: a round ending without one, it dies


# A unit's time Downed (Unit.dbno): its rule and the rank it went down at, fixed as it does.
class State:
	var rule: Downed
	var rank := 1
	var left := 0  # rounds left: its side's turns still to end before it dies of it
	var limit := 0  # how far below 0 its HP may run
	var acted := 0  # skill uses it has paid for since (Unit.pay_for(), Unit.pay_strike())
	var meleed := false  # it has made a melee attack this round
	var fresh := false  # it went down in its own side's turn: that turn's end doesn't count as a round

	# Skill uses it may still pay for without dying of it; -1: as many as it likes.
	func spare() -> int:
		return maxi(rule.actions * rank - acted, 0) if rule.actions > 0 else -1


# u's Downed skill, as a slot: of the passives it has on, the one it has the highest rank in (the
# first listed on a tie). Null if it has none.
static func slot_of(u: Unit) -> Slot:
	var best: Slot = null
	var most := 0
	for x in u.on_passives:
		if x.skill.downed and u.rank(x.skill) > most:
			best = x
			most = u.rank(x.skill)
	return best


# The lowest u's HP can be set: 0, or while Downed one past its limit - what kills it.
static func floor_hp(u: Unit) -> int:
	return -(u.dbno.limit + 1) if u.dbno else 0


# u's HP went from `was` to `now` (Unit.hp's setter): whether Downed has dealt with it. On its last
# life with a Downed skill, reaching 0 puts it down instead of killing it; Downed, rising above 0
# saves it, and falling past its limit kills it.
static func takes(u: Unit, was: int, now: int) -> bool:
	var s: State = u.dbno
	if s:
		if now > 0:
			u.dbno = null
			u.dbno_changed.emit(u, &"saved")
		elif now < -s.limit:
			succumb(u, &"limit")
		return true
	if was < 0:
		return true  # one that died below 0: nothing more comes of its HP settling
	if now != 0 or u.reviving or u.lives_left() > 0:
		return false  # hearts first
	var x := slot_of(u)
	if x == null:
		return false
	s = State.new()
	s.rule = x.skill.downed
	s.rank = u.rank(x.skill)
	s.left = maxi(s.rule.rounds * s.rank, 1)
	s.limit = maxi(roundi(s.rule.limit * s.rank * u.max_hp), 0)
	u.dbno = s
	u.healed_by = null
	u.dbno_changed.emit(u, &"down")
	return true


# u, Downed, dies of it. why: &"limit" (its HP past its limit), &"rounds" (its last round over),
# &"actions" (more skill uses than its rule allows), &"melee" (a round without a melee attack),
# &"slain" (an execute). Its HP stays where it was.
static func succumb(u: Unit, why: StringName) -> void:
	if u.dbno == null:
		return
	u.dbno = null
	u.dbno_changed.emit(u, why)
	u.died.emit(u)


# An execute lands on u (Death, Luun's Smite): one already Downed dies of it. False if it wasn't - it
# is taken to 0 HP as usual, which may put it down.
static func finish(u: Unit) -> bool:
	if u.dbno == null:
		return false
	succumb(u, &"slain")
	return true


# b tells of a change in u's Downed state (Battle._on_dbno()). Going down, it notes whether its own
# side's turn is on (that turn doesn't count as a round), and a helpless one lets go of what it was
# channeling. Saved, whoever healed it last brought it back (Battle.rescued()).
static func changed(b: Battle, u: Unit, how: StringName) -> void:
	match how:
		&"down":
			u.dbno.fresh = u.faction == b.turn
			if u.stopped():
				b.end_channel(u)
		&"saved":
			b.rescued(u, u.healed_by)


# A skill use is done (Battle.used). A Downed caster's attack on a foe touching it is the melee attack
# its round asks for, hit or miss; one use past its allowance, and it dies now that it's done.
static func acted(caster: Unit, skill: Skill, at: Variant) -> void:
	var s: State = caster.dbno if caster else null
	if s == null:
		return
	if at is Unit and at != caster and skill.attacks() and not Faction.friends(caster.faction, at.faction) and Battle.next_to(caster.cell, at.cell):
		s.meleed = true
	if s.rule.actions > 0 and s.acted > s.rule.actions * s.rank:
		succumb(caster, &"actions")


# A side's turn ends (Battle.end_turn()): a round passes for each of its Downed units, but one that
# went down this very turn. One owing a melee attack that made none dies; so does one whose last
# round this was.
static func end_round(side: Array[Unit]) -> void:
	for u in side:
		var s: State = u.dbno
		if s == null:
			continue
		if s.fresh:
			s.fresh = false
			continue
		if s.rule.actions > 0 and s.acted > s.rule.actions * s.rank:
			succumb(u, &"actions")
		elif s.rule.melee and not s.meleed:
			succumb(u, &"melee")
		else:
			s.meleed = false
			s.left -= 1
			if s.left <= 0:
				succumb(u, &"rounds")


# What a skill carrying this rule does, for its description at a rank (Skill.markup()).
func markup(rank: int) -> String:
	var n := rounds * rank
	var lines: PackedStringArray = []
	lines.append("On its last life, at 0 HP it is %s instead of dying, for {t:%d round%s}: %s" % [Glossary.term(&"downed"), n, "" if n == 1 else "s",
			"it goes on acting as if it weren't" if acts else "helpless, it can't act or move"])
	lines.append("Its HP runs below 0, as far as {r:%d%%} of its max HP: past that, it dies at once" % roundi(limit * rank * 100.0))
	if actions > 0:
		lines.append("Using more than {r:%d} skill%s while down, it dies once that's done" % [actions * rank, "" if actions * rank == 1 else "s"])
	if melee:
		lines.append("A round ending without a melee attack from it, it dies")
	lines.append("Healed above 0 HP it is saved; still down as its last round ends, it dies")
	return "\n".join(lines)

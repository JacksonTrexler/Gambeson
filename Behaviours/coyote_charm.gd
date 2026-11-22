extends Behaviour

# Coyote Charm (lent by the Coyote Charm, an epic trinket): its holder's skills about to be disabled, it gets the
# Coyote Charm buff for rank turns - disablings wait, not counting down, until it ends (the postpone stat) - and
# the Curse of the Coyote at the same rank, rightmost: a curse that must be overcome before any cleansing or heal
# reaches it (the overcome stat), not counting down meanwhile either. A buff already up isn't renewed. Its
# enchanted effect (an enchanted Coyote Charm, owned: not ranked up): an instant death (it dies with HP left:
# Unit.slay()) on its last life puts it on Borrowed Time for rank rounds instead (Unit.defer()). Its rank is
# rank impact, through its holder's modifiers.

const BUFF: Effect = preload("res://Effects/coyote_charm.tres")
const CURSE: Effect = preload("res://Effects/curse_of_the_coyote.tres")


# Puts the Coyote Charm and its curse on u at rank r for r of its turns, unless the buff is already up
# (a disabling lands and waits: Coyote Scepter lends them too). One more turn in its own side's turn,
# whose end doesn't count.
static func lend(b: Battle, u: Unit, r: int) -> void:
	if r < 1 or u.postponing():
		return
	var turns := r + (1 if u.faction == b.turn else 0)
	u.afflict(BUFF, turns, r)
	u.afflict(CURSE, turns, r)


func disabling(b: Battle, holder: Unit, rank: int, u: Unit, _d: Dictionary) -> void:
	if holder == u:
		lend(b, u, holder_rank(holder, rank))


func slain(_b: Battle, holder: Unit, rank: int, d: Dictionary) -> void:
	if holder.lives_left() <= 0 and holder.dbno == null and _enchanted(holder):
		d.defer = maxi(int(d.defer), holder_rank(holder, rank))


# One of its items lending this is enchanted.
func _enchanted(holder: Unit) -> bool:
	return holder.items().any(func(it: Item): return it.enchanted() and it.skills.any(func(s: Skill): return s and self in s.behaviours))


func owns_enchant() -> bool:
	return true


# Its terms: the turns, the curse's rank and the rounds put off are all rank impact; a tame effect.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "turns, curse, borrowed time")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var rank := c.impact_rank()
	return "Its skills about to be %s: %s for %d turns (they wait, and its curses with them), and %s %s, rightmost - cleansing and heals must overcome it first. Enchanted: an instant death on its last life puts it on Borrowed Time for %d rounds instead" % [
			Glossary.term(&"disabled", "disabled"), BUFF.name, rank, CURSE.name, Skill.roman(rank), rank]

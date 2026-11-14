extends Behaviour

# Bludgeon: a blunt blow, heavier from one already bludgeoning - wielding a weapon that deals blunt, or
# bare-handed (Strike's rule: Battle.hit_tags()): + 1d4 a hit. Landing, it leaves the foe Winded: it
# loses rank AP, at once if it's acting, else as its next turn opens (the winded stat: Unit.winded()).

const WINDED: Effect = preload("res://Effects/winded.tres")
const BLUNT_DIE := Vector2i(1, 4)


# Whether u's blows are blunt already: a blunt weapon, or none.
static func bludgeoning(u: Unit) -> bool:
	return (u.weapon.damage_tag if u.weapon else &"blunt") == &"blunt"


func bonus(c: Cast) -> int:
	return c.battle.roll(BLUNT_DIE) if c.foe and bludgeoning(c.caster) else 0


func apply(c: Cast) -> void:
	if not c.foe or not c.target.is_alive():
		return
	if c.target.faction == c.battle.turn:
		c.target.pay(minf(c.rank, c.target.ap_for(&"")), &"")  # acting: at once
	else:
		c.put(WINDED, 1)


func describe(rank: int) -> String:
	return "Wielding blunt (or bare-handed): + 1d4 damage. A hit leaves it %s: it loses {r:%d} AP, at once if it's acting, else as its next turn opens" % [
			WINDED.name, rank]

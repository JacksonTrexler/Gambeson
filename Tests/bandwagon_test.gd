extends Test

# Bandwagon (Skills/bandwagon.tres, Behaviours/bandwagon.gd): a foe that grows suspicious of its holder
# must pass a cha check (standard DC at its rank + the holder's cha mod) to tell each ally, while no
# more than rank + 1 foes suspect it. Blinthe has it at III.

const BANDWAGON := preload("res://Behaviours/bandwagon.gd")
var bandwagon: Skill = load("res://Skills/bandwagon.tres")


func blinthe(more := {}) -> Unit:
	var bl: Unit = b.summon(load("res://Scenes/blinthe.tscn"), load("res://Factions/unaligned.tres"), Vector2i(8, 1))
	var near := {v(1): Vector2i(4, 3), v(2): Vector2i(4, 4)}
	near.merge(more)
	stage(lancin, near)
	b.move(bl, Vector2i(8, 1))
	return bl


func test_blocks_word() -> void:
	var bl := blinthe()
	ok(BANDWAGON.dc(bl, 3) == Difficulty.dc(&"standard", 3) + bl.mod(&"charisma"), "the DC: standard at rank III, + his cha mod (%d)" % BANDWAGON.dc(bl, 3))
	var heard := []
	b.told.connect(func(_by: Unit, to: Unit, _of: Unit, got: bool): heard.append([to, got]))
	v(1).charisma = 1  # d20 - 5 never reaches 16
	b.suspect(v(1), bl)
	ok(v(2).suspects(bl) == 0 and heard == [[v(2), false]], "a poor talker can't get the word out: %s" % [heard])
	v(1).suspicion.clear()
	v(1).charisma = 60
	b.suspect(v(1), bl)
	ok(v(2).suspects(bl) == 1, "a silver tongue can")


func test_past_rank_plus_one() -> void:
	var others: Array[Unit] = [v(3), v(4), b.get_node("Units/Icor"), b.get_node("Units/Alabaster")]
	var bl := blinthe({others[0]: Vector2i(1, 7), others[1]: Vector2i(2, 7), others[2]: Vector2i(3, 7), others[3]: Vector2i(4, 7)})
	for u in others:
		u.suspicion[bl] = 1
	v(1).charisma = 1
	b.suspect(v(1), bl)  # 5 foes suspect him now: past III + 1
	ok(BANDWAGON.doubters(b, bl) == 6 and v(2).suspects(bl) == 1, "past rank + 1 suspicious foes, the word's out: no check - v(2) makes 6 (%d doubt him; v(2) %d)" % [BANDWAGON.doubters(b, bl), v(2).suspects(bl)])


func test_wiring() -> void:
	ok(load("res://Roles/bard.tres").all_tabs().any(func(t: SkillTab): return t.offers(bandwagon)), "on the Bard's tree")
	ok(bandwagon.passive and not bandwagon.ai and bandwagon.describe(3).contains("12"), "a passive; says its DC: %s" % bandwagon.describe(3))

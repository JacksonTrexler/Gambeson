extends Test

# Word to the Wise (Skills/word_to_the_wise.tres, Behaviours/word_to_the_wise.gd): the leader commands
# by its wis mod in place of its cha mod, no higher than the lower of the two units' wis mods + rank.

var word_to_the_wise: Skill = load("res://Skills/word_to_the_wise.tres")


func test_word_to_the_wise() -> void:
	stage(lancin, {v(1): Vector2i(3, 3), v(2): Vector2i(4, 3)})
	var c := Command.new(b, v(1))
	v(1).charisma = 8  # -1
	v(1).wisdom = 18  # +4
	v(2).wisdom = 10  # +0
	v(1).learned.append(slot(word_to_the_wise, 2))
	ok(c.cha_for(v(2)) == 2 and c.slots(v(2)) == 2, "wis +4 for cha -1, but the ally's wis +0 + rank II bounds it: +2")
	v(2).wisdom = 16  # +3
	ok(c.cha_for(v(2)) == 4, "a wiser ally (+3 + 2): the leader's whole wis +4")
	v(1).charisma = 20  # +5
	ok(c.cha_for(v(2)) == 5, "charisma higher still: it goes by charisma")
	v(1).charisma = 8
	v(1).wisdom = 6  # -2
	ok(c.cha_for(v(2)) == -1, "a foolish leader: charisma -1 is the better")
	ok(word_to_the_wise.describe(2).contains("wis mod + 2"), word_to_the_wise.describe(2))

# Equip follow-ups (z-equipfu)

## Readings
Already built by equipping (docs/plans/equipping.md): the Save hooks (`_equipped_out/_in`, saved on equipping), the
Settings auto-equip toggle, losing slots with an unequipped granting skill, the Specialist tab scrolled to its
lowest filled tier. Left: the four items below.

## Calls
1. Lent ring: drawn on the numeral's baseline, just left of the rank numeral (it was lower right, under the pip).
   The toggle dot and name shift left to make room.
2. The on/off dot shows only for toggles (`SkillSlot.shows_switch()`); always-on passives have none.
3. Unequipped learned skill (wheel and grid): dashed rim and a darker fill, beside the dulled numeral. Dashes are
   the stub look too; stubs are a muted grey and aren't learned, so the two don't meet.
4. Skill Slot +1 (?3): NOT built. The recorded design (skill_slot.tres plan, docs/todo/classes.md:12) is
   unresolved: an untyped slot "slightly darker", "locked until current slots are filled", and asks "the hotbar's
   center or the tree's?". No answer is recorded (only "kept as built"). Building it needs that choice; the
   slot-granting path (`slots` Effect, `Unit._grants`) already makes an untyped slot once it's decided.

## As built
SkillSlot.gd, SkillWheel.gd, SkillGrid.gd; test `equip_test.test_slot_switch_dot`.
Mutation spot-check: inverting `shows_switch` fails 2 checks. Dashed rim and ring position checked by frames
(shot_z-equipfu/d frame 100 the bar; frame 118 of the first run the wheel with Sola dashed), no unit test.

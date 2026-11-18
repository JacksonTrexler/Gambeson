# Traits declared, Skill Slot +1, no on/off on always-on passives (w3-traits, 2026-11-18)

The user's words (docs/agents/answers-2026-11-18b.md): 4 "Traits are best explicitly specified by builder skill / script
tooling, this will likely come up during testing when unit mechanics simply stop working when disabled"; 5 "skill slot +1
adds it to the unit's *hotbar*, and it sits on the far right. skill slot +1 is a *trait* when learned: otherwise it'd just
occupy a slot and create a slot. it still costs points to learn for the first time: skill slot +1 is used to reward mastery.
If it's applied as an *item*, it can be disabled the same way other equipment effects can be disabled."; 6 "always on
passives should have no indication they are 'on' or 'off' whatsoever".

Baseline suite: 9756 checks, 0 failed (936 tests).

## Readings

1. **Nothing was inferred at run time.** A trait is the `trait` tag (w2-traits call 1) and `Skill.is_trait()` reads it. What
   was loose was the authoring: the tag was hand-edited, no tool offered it, and nothing checked how a unit holds one
   (Siren's Alluring sat among its *learned* skills, so it also looked like one of its slotted skills). So "replace the
   inference with the explicit declaration" became: one declaration (the tag), written only by tools, and checks on both
   ends (the skill, and the unit that holds it).
2. **Skill Slot +1 was a stub** on the Adventurer's centre (`Role.center`), waiting on ?3 ("hotbar's centre or the tree's?").
   Answered: the hotbar, far right, as a trait. The slot machinery (`slots` Effect, `Unit._grants`, `bar_size`) was done
   for Basic Magic / Martial / Specialist Skill Slot +1 and the Burning Bag; an untyped slot is the same Effect with no tag.
3. **"Disabled the same way other equipment effects can be disabled (`Unit.equipped`)"**: an item lends skills
   (`Item.skills`, `Unit.granted()`), and every lent skill is gated by `equipped()`; a lent trait by `traits_suppressed()`.
   So the item version is an item that lends Skill Slot +1, and the slot goes when the trait is suppressed or the item taken off.
4. **(c) was half done in ?165** (the green dot only for toggles). What remained: `SkillSlot` dimmed an always-on passive
   whenever its unit "couldn't use" it (another unit's turn, no orders), which reads as off.

## Calls

1. **The declaration is the tag, written by tools, checked.** `skill.py new --trait` (implies `--passive`, adds the tag,
   needs no tree or role: a unit's innate trait goes to `unit.py trait`), `skill.py trait <id> [--off]` (edit path; refuses
   a non-passive, toggle or hybrid). `unit.py trait <unit> <skill>[:rank] [--off]` puts a skill into a unit scene's `innate`
   (moving it off `learned`) and refuses one not declared a trait; `unit.py new --trait id[:rank]` does it at creation, and
   `--skill` naming a trait now dies pointing at `--trait`. No Skill.gd field, no per-unit flag (CLAUDE.md).
2. **Checks** (`skill.py check_traits`): a trait must be a plain always-on passive (was already) and not a pillar or
   foundation (a pillar sits on the hotbar for a curse to reach); a unit scene lists a trait under `learned`: fails, with
   the `unit.py trait` command. The reverse ("a skill that behaves as a trait but is undeclared") has nothing to find:
   a skill takes no slot and works only by being a trait (`equipped()`), and a slotted skill over the room already fails
   `unit.py check` ("set extra_slots"). Not made: "an innate always-on passive must be a trait", since Powerful and
   Starsap on Starmote / Starman are innate and deliberately slotted (w2-traits call 4).
3. **Migration**: Siren's Alluring moved from `learned` to `innate` (rank 4 kept): behaviour unchanged (`slots` is both lists).
4. **Skill Slot +1**: `Skills/skill_slot.tres` is now a trait with one `slots` Effect, untyped, not per rank, `max_rank = 1`;
   stub and plan text gone. Still on the Adventurer's centre, tier 1, and unlocked like any skill (1 point: unlock cost has no
   other price, `rank_cost` only prices rank II+). So "costs points to learn the first time" holds, and the mastery
   gating ("used to reward mastery") is left to where it is offered: only the centre now, learnable at once. Say if it should
   wait on something (a prereq on the centre needs machinery that doesn't exist).
5. **Item version**: an item lists it in `Item.skills` (a lent trait). No new item written: the test builds one. A real item is
   `item.py new ... --skills skill_slot`.
6. **One generic read**: `Unit.bar_size()` (sure slots + granted + clover) is the hotbar's size; Cram, caster bonus slots
   and items add to `_grants()` and nothing else reads. Left the two `slot_count() + granted_slots().size()` sums
   (`clover()`, `burning_slots()`): they mean "before the clover", not the size.
7. **(c)**: `SkillSlot.brightness()` (lifted from `_draw` so it can be tested): an always-on passive is bright whatever its unit
   can do now; only a disabling or sealing (or no luck, for a clover slot) dims it. A toggle still dims when off or unusable,
   an active when unusable, a trait while suppressed (a status, shown on purpose). The "Always on" spec word in the tooltip
   is a description of kind, left.

## As built

Files: `Util/skill.py` (new --trait, trait, check_traits), `Util/unit.py` (trait, new --trait, --skill guard),
`Skills/skill_slot.tres`, `Scenes/siren.tscn`, `Scripts/SkillSlot.gd`, `Tests/equip_test.gd` (new `test_skill_slot`; trait
inventory gains skill_slot; `test_slot_switch_dot` gains brightness), `Tests/adventurer_test.gd` and `Tests/hud_test.gd`
(Skill Slot +1 is offered and shows first on the wheel, no longer a stub), this file. `.claude/skills/new-skill` and
`new-unit` should mention `--trait` / `unit.py trait` (not edited: `.claude/` is out of bounds for builders).

Tests changed to the new rule: `adventurer_test.test_starting_skills`, `test_tree_unlocks`, `test_stubs`;
`hud_test.test_adventurer_skills_screen`. Mutation spot-checks (fail, then reverted): `brightness()` ignoring always-on;
Skill Slot +1's Effect amount 0 (fails the lent and returns checks); a trait in a scene's `learned` fails skill.py check
(Siren, before migration).

Undone: the todo's "slightly darker" look for an untyped granted slot (docs/todo/ui.md); it needs a slot kind, and Cram's
caster bonus slots will want the same, so left for that card. Visual: `scratchpad/shot_w3t` (Adventurer with Skill Slot +1:
a trait row after the hotbar, a fifth empty slot, always-on passives bright and dot-free).

Final suite: 9769 checks, 0 failed (937 tests).

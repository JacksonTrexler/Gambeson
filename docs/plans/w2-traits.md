# Traits (w2-traits, 2026-11-18; ?163)

The user's words: "yes active skills must be in hotbar to work. Traits are special, they're always in hotbar, and
don't count against slotted skills. Keep them to the furthest right of the skill hotbar. traits can't be disabled
the same way skills can be, they don't make it easier or harder to disable other skills by taking up space on
hotbar, and they don't interfere with hotbar ordering (e.g. enchant rank leftmost skills, disable rank skills on
unit hotbar right to left etc.) keep ability to suppress traits open of course e.g. "disable unit traits for rank
rounds" but I'm guessing doing so would break monsters / species mechanics: it'd likely be for utility reasons".
And: "Yup any active or passive skill does nothing unless it is equipped (and if relevant, toggled), either
automatically on learn when there is space or manually if the hotbar is full."

Baseline suite: 8663 checks, 0 failed (927 tests).

## Readings

1. **Most of it was already built, as `Skill.inherent`.** The equipping card (docs/plans/equipping.md) added a bool
   `inherent` ("takes no slot and is always equipped", Starkind and Reckless Abandon): `Unit.equipped()` returned
   true for it, `fits_bar()` kept it off the hotbar (so `hotbar` holds none: `disable_order()`, the Sigil's
   leftmost-eligible, `bar_place`, the curse on the leftmost slot and Command's slot count never see it), and
   `Unit.disable()` ignored it. What was missing: the word `trait`, any way to suppress, anywhere to see one in the
   HUD (none was shown at all), and a set of skills beyond those two.
2. **Active or passive, unequipped does nothing** already held (equipping card: `on_passives`, `actives`, `hooks()`,
   `stat()`, the AI through `kit`). Audit of every other reader of `slots` found one leak: `Unit.skill_name()`
   (Strike renamed Brutal Strike / Decisive Strike for a learned but unequipped upgrade, which does nothing).
   Fixed. The rest read learning state on purpose (`missing`, `exclusive`, `magic_learned`, rank and raise) or are
   toggle bookkeeping (`is_on`, `toggle`, `_one_replacer`, Battle's unshape clearing mist).
3. **Auto-equip and manual equip** already exist (`Unit._sync_new`, Settings "Auto-equip new skills", drag to the bar
   when full). Left as built.

## Calls

1. **`trait` is a tag, replacing the `inherent` flag** (CLAUDE.md: no new Skill.gd flag; one mechanism, not a flag
   and a tag). `Skill.inherent` is gone; `Skill.is_trait()` reads the tag; the two skills that carried the flag now
   carry the tag. Nothing outside the repo's own code read `inherent`. `trait` was made with
   `mechanic.py tag trait --human` (the user's word, no ??), kind `target` (never a modifier), colour `#d6c8a0`
   (a pale parchment, near no element), and is in `Tags.PLAIN` so it never marks a stripe or trims an item.
2. **Traits are always-on passives**, never actives or toggles: nothing on the hotbar to press, and the HUD does
   not make them selectable. `skill.py check` now fails a trait that isn't `passive` or is a `toggle`
   (`check_traits`).
3. **Suppression** is one Effect stat `no_traits` (above 0: traits are off), read by the one helper
   `Unit.traits_suppressed()`, which `Unit.equipped()` asks for a trait. A status file `Effects/traits_suppressed.tres`
   ("Traits Suppressed ??", HARMFUL) is the reusable status; unused by any skill. Calls inside it:
   - read from the unit's **timed statuses only**, as `shackled()` does, never `stat()`: `stat()` gathers passives,
     which ask `equipped()`, which would ask `stat()`. So an item or passive can't suppress traits, only a status
     (a tile's effect, a skill's `afflict`); that is what "for N rounds" asks.
   - suppressed means "as if unequipped" (the same inert state the equipping rule already gives a passive): effects,
     hooks, reactions, tags (`has_tag`), looks all stop; it returns when the status ends. The stat name has no
     ?? (it is an id the player never sees); the shown status name has.
4. **Which skills are traits** (clearly innate, held by a kind of unit rather than learned off a tree):
   - **Starkind**: Starmote's astral nature (max HP is its Power; fades off the star lattice). Was `inherent` already.
     It is also on the Astral tree: a player can learn it, and it is then a trait too (no slot, as before).
   - **Reckless Abandon**: the Berserker's own ("A Berserker's trait", its lore, and the test already says "an
     inherent trait"). Was `inherent` already.
   - **Alluring**: the Siren's allure, on no tree or role, carried by the Siren alone (its `shows_*` look and the
     persona effect). Was an ordinary passive that needed an `extra_slots` point to work (the equipping card gave
     Siren 2 for Tonefoolery, Well Up and Alluring). Now takes no slot, so the Siren's `extra_slots` goes 2 -> 1 (one less than
     the room it would have left empty); `command_test.test_default_bar` updated to the bar that gives.
   Left alone, on purpose: **Powerful** and **Physical Intelligence** (pillars: a build's foundation that the curse
   reaches first, so they must stay disable-able and on the bar), **Oceanic**, **Regeneration Pulse**, **Stoneskin**,
   **Hardy** and **Starsap** (also on player trees: a monster's use of them isn't what they are), and the Druid's
   FORMS traits (`Battle.FORMS`: haste, aquatic...), which are data of a shape taken, not skills. "Aquatic" is a
   Property (Properties/aquatic.tres) and a form word, not a skill; no skill to tag. Species options
   (`Race.options`: Relay, Synergy) are choices the player makes, not innates.
5. **Items' emblems**: scopes `insignia` (every skill) and `badge` (every passive) still reach a trait, since they
   don't order the hotbar. Only the Sigil walks the bar, and it can't see a trait. Left as built; say if a trait
   should be out of reach of those too.
6. **HUD**: a read-only `Traits` column under the hotbar (`%Traits`; the hotbar is a vertical column here, so "far
   right" is its far end, after the last slot): one `SkillSlot` per trait with `trait_slot` set: a diamond where
   the number would be, the trait colour's frame and tint, no drag, no drop, no right-click clear, no key, dimmed
   with "Suppressed" in the tooltip while `traits_suppressed()`. Not in `bar`, so `_slot_key`, `use_slot`, keep-slot
   and Command's slot lock never count it. The skills screen already refuses to drag a trait (`fits_bar()`).
7. **Spec text**: a trait's spec line reads "Trait" (was "Inherent") and its description "Trait: always equipped at the
   far right of the hotbar, takes no slot, and can't be disabled".

## As built

Files: `Scripts/Skill.gd` (is_trait, fits_bar), `Scripts/Unit.gd` (equipped, disable, disable_order, equip_skill,
traits(), traits_suppressed(), skill_name), `Scripts/Effect.gd` (no_traits: doc, enum, name, HARMFUL, describe),
`Scripts/Tags.gd`, `Scripts/Glossary.gd` (the tag), `Scripts/SkillSlot.gd`, `Scripts/HUD.gd`,
`Scripts/SkillDetail.gd`, `Scenes/UI/hud.tscn` (Traits column), `Effects/traits_suppressed.tres`,
`Skills/{starkind,reckless_abandon,alluring}.tres`, `Scenes/siren.tscn` (extra_slots 1), `Util/skill.py` (check_traits), `Util/unit.py` (slot room reads
the tag).

Tests: `equip_test.test_traits` (new: no slot used, bar and free slot unchanged, can't be placed, not disabled, not
in `disable_order`, suppression status and its expiry, the real set of traits and that each is an always-on passive,
the HUD column and its read-only slots); `equip_test.test_equip_unequip` gains the renamed-Strike check. Updated to
the tag: `command_test.test_default_bar` (Siren's bar: Alluring off it), `berserker_test.test_reckless_abandon` (`inherent` -> `is_trait()`), `sweep_test.test_passives` (same).
No test encoded "an unequipped passive works".

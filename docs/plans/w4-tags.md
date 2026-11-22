# Tag and parameterize the rest (branch w4-tags, 2026-11-19)

The user's words: `docs/agents/answers-2026-11-19.md`, last line: "*do* aggressively tag and parameterize skills to make them
easier to scale and tweak in the long run". Built on w2-param.md (the 22 left concrete), w4-density.md (35 ineligible),
w4-knobs.md. Baseline suite: 10103 checks, 0 failed (958 tests). `Skill.gd` gained no field: FLAG_CEILING stays 105.

## Readings and calls (for the coordinator to number)

1. **What "cheap" meant:** a skill whose number can read rank (impact or range) through a channel with rank I exactly as it was,
   by an existing mechanism (`per_rank`, `dice_per_rank`, `Cast.impact_rank()`, `holder_rank()`) and one `terms()` line. Rank II+
   is new scaling, as in w2-param / w4-density ("the channel is the point"); no AP, cost or price edited. A one-entry `terms()`
   label per behaviour (a comma list, not several entries) so `Pricing`'s per-term rank cost doesn't move for priced skills.
2. **Parameterized, 9 skills (Density-ineligible 37 -> 29):**
   - **Mage Armor, Manifest, Relay**: `per_rank = true` on the effect (data only). Defense / luck / relay share x rank. Manifest
     was already stat-parameterized; Mage Armor and Relay had no rank impact.
   - **Peel**: its steps a turn are rank impact, the foe's distance from the ally rank range (was raw rank: both read through the
     holder's modifiers now; the ally reach was already range).
   - **Solar**: its fire damage is a d20 per rank impact (`1d20` at I, `2d20` at II): same move as the seven blows given
     `dice_per_rank` in w4-density. Its width stays rank range.
   - **Drown, Coalescing**: `dice_per_rank` on the skill now also means a grip's `drowns` dice (`Battle._grip()` multiplies the
     count by the holder's rank impact; rank I is 1d12). No new field. Drown's drowning at II is 2d12 a turn; untuned, tune by
     the knob or a later d tag. Coalescing was ineligible, Drown already eligible.
   - **Coyote Charm, Coyote Scepter**: the turns, the lent Charm's rank and Borrowed Time's rounds read `holder_rank()`.
     Item-lent, so no slot of the holder carries the behaviour and `mods_on()` is `NONE` today; the read is there for when a
     tree teaches them (and the test learns the Charm into a slot). They were ineligible "no rank impact".
   - **Energy Transfer**: the Overcharge kept and its turns read the cast's rank impact (declared `terms()`).
   - **Kick**: Soaked and Blinded's rank and turns read rank impact (they were raw rank beside a push that already read impact).
   - **Slam Jam**: the AP/cost rebate `1 / (rank + 2)` reads rank impact; **Hitch**: its text and **Bludgeon** now through
     `Cast.put()`, which gives a per-rank effect the cast's rank impact (as `Battle` does for a skill's own effects).
     Rank I is unchanged in each.
3. **`Cast.put()`**: per-rank effects at `impact_rank()` instead of raw rank, the one generic edit behind Kick / Hitch / Bludgeon
   / Stun (Stun already passed impact as turns, its effect rank is unchanged at I).
4. **Still concrete (29 declare `no_density`), with the reason kept as in w4-density:** the build gates, switches and selectors,
   traits, drawbacks (Oceanic, Reckless Abandon, Vaporize), Armor. Of the "fewer is better" four left: **Clairvoyance** (rank is
   only reach; the channel's rank rising each turn already grows it), **Send Off** (a teleport: rank is only reach), **Stoneskin**
   (a fixed share above a fixed HP: `per_rank` would double 40% to 80% at II, which is a rebalance, not a read; needs tiers),
   and **Elemental Mastery** (scales through Strike's own `element` term).
5. **Tags added (existing words, `mechanic.py carry`; no new words, so no ` ??`), 15 skills:** `entrance` on Sing (its displace
   draws, and passes that tag to the unit); `evadable` on Wildfire (an evadable cone); `aura` on Flamecharm, Flamedance (the aura
   behaviour); `concealment` on Blur, Hide, Invisibility, Nadira, Vanishing Act (they lay concealment); `held` on Coalescing,
   Drown (a grapple); `disabled` on Brainfog; `channeled` on Clairvoyance; `wound` on Snare. All inert today (no rule reads a
   skill's condition tag): they join the Tags line, the modifiers' words and any rule a later item or skill reads.
6. **cc / shove / strike / friction were audited and left as they are:** `forced_test.test_cc_and_shove_are_tagged` already pins
   which skills carry `cc` and `shove` by what they do (Gale's and Judgement's untagged state is correct by its definition:
   Gale is a stub with no displace; Judgement's shackles hold movement, not action); `strike` (Strike, Waterstrike, Silent
   Strike) and `friction` (Chaser, Jugular) follow w4-friction's loop audit. Discipline / role tags (offensive, martial...)
   were not touched: the AI reads `offensive` and friends as intent (`intent_skill`), so adding them changes behaviour.
7. **Damage tags**: every skill with a tier either names its element or `weapon_tag`s; only Astera, Hydera, Smite and Judgement have
   none and are not damage-tagged on purpose (a divine one; the others deal none). No change.

## As built

- Skills (data): mage_armor, manifest, relay (`per_rank`), drown, coalescing (`dice_per_rank`); `no_density` dropped from
  mage_armor, manifest, relay, coalescing, peel, solar, coyote_charm, coyote_scepter; the tags above.
- Scripts: `Scripts/Battle.gd` (`_grip()` dice), `Scripts/Behaviour.gd` (`Cast.put()`), `Scripts/Skill.gd` (Drown's text, a comment).
  Behaviours: peel, cone, energy_transfer, coyote_charm, coyote_scepter, kick, slam_jam, hitch.
- Tests (no new files): `param_test`: three rows in `test_concrete_scaled`'s table (Mage Armor, Manifest, Relay) and a new
  `test_impact_reads` (Peel, Energy Transfer, Coyote Charm, Kick's riders and `Cast.put`, Solar's and Drown's dice, each at I
  against I under Density); `water_test.test_drowning_dice_per_rank` (the rule lives in `_grip`); updated to the new state:
  `modifiers_test.test_terms` (Kick's term label), `route_test` (Solar's no longer a doctored copy).
- Mutation spot-checks (each failed its test, reverted): Peel's steps on raw rank; Energy Transfer on raw rank; Solar one die;
  `_grip()` ignoring `dice_per_rank`; Coyote Charm on raw rank; `Cast.put()` on raw rank; Relay without `per_rank`.
- `skill.py check`, `mechanic.py check`, `item.py check`, `unit.py check`: ok. Suite: 10189 checks, 0 failed (960 tests).

## Not done

- Clairvoyance, Send Off, Stoneskin, Elemental Mastery stay on their reasons above.
- No HUD screenshot: only text and numbers changed (tests read `describe`).

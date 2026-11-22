# Deathlust (branch r-deathlust)

The user's words: "new eros / slayer / vanguard / fighter martial passive: Deathlust: Units dying in rank range remove a small amount of exhaustion. Prevents specific skill exhaustion on skills used to kill (not down) a unit." The name is theirs (`--human`, no ??).

## Readings

- "Fighter martial" read as `Trees/general_martial.tres` (the General Martial tree the Fighter's martial branch draws on), as the brief said. Placed on four trees: `eros`, `slayer`, `vanguard`, `general_martial`.
- The `neutralized` signal (`Battle.neutralize(u, how)`) says how: `&"downed"` (a heart spent), `&"down"` (went Downed), `&"killed"`. "Killed (not down)" is `&"killed"` only.
- Exhaustion is gained at payment (`Unit.pay_for()` -> `Exhaustion.used()`), before the cast resolves, so the kill comes after the gain. A hook at the gain cannot know; so the use is held open and settled once the outermost cast is over.

## The generic pieces (nothing Deathlust-only in Unit, Battle or Skill.gd)

- `Exhaustion.relieve(n, skill = null)`: takes n uses off one skill's count or all of them. `recover()` (turn end) now calls it: one way counts come off.
- `Exhaustion.Wear`: one use as paid (`skill`, `caster`, `target`, `gain`, mutable `uses`, `felled` {Unit: how}, `killed()`).
- `Unit.paid(u, s, wear)` signal from `pay_for()`; `Battle._on_paid` holds it open while a cast is under way (`_wears`, `_aims` for the cast's target); `Battle._settle_wear()` at the outermost cast's end (`_done_casting`) runs every holder's `Behaviour.wearing(b, holder, rank, wear)` hooks, then relieves `gain - uses` from that skill. A passive may cancel or lower what a use adds.
- `Battle.neutralize()` marks each open `Wear` whose caster struck the unit (or was aiming at it) in `felled`, and tells every other standing unit's passives `Behaviour.neutralized(b, holder, rank, u, by, how)`.
- `Util/skill.py` `HOOKS` gets `neutralized` and `wearing`, so `check` accepts a passive that uses only them.

## Deathlust (`Behaviours/deathlust.gd`, apply-less: hooks plus describe)

- `neutralized`: how = killed, the dying unit within `2 x rank` tiles (`rank_range`, through modifiers) of the holder: every skill's count falls by `0.25 x rank` uses (`rank_impact`).
- `wearing`: a use that killed a unit (`wear.killed()`) keeps no gain.

## Calls made (for the designer)

1. Either side counts, and the holder's own kills: any unit killed in reach, ally, foe or the holder's victim. (A grim cheer: allies dying also help; a dead holder gets nothing; the unit itself dying is not felt.) Downed (`&"downed"`, `&"down"`) never does; nor unshaping.
2. Reach: 2 tiles a rank (2 / 4 / 6 at ranks 1-3); `rank_range` so range modifiers scale it. "Rank range" read as "rank tiles" is too tight (1 tile at rank I).
3. "Small amount": 0.25 of a use a rank (0.25 / 0.5 / 0.75), off every skill's count. A turn's end takes 1, so this is a quarter to three quarters of a free turn per death; several deaths stack.
4. The kill skill: its own use gains nothing, flat at every rank (the brief's "prevents"); other skills' share (half of its kind, a quarter of Strike's) is derived from its count, so it falls with it.
5. "Used to kill": the unit's last hit came from the caster during that cast, or the cast was aimed at it (so executes, which set no `last_hit_by`, count). A cast that kills one and downs another is a kill skill. A kill outside any cast (a bleed ticking) is no skill's kill. A channeled skill's later strike (Metea) is not: the channel's use was paid when it began, and no `Wear` is open at the strike.
6. A use and its kill settle at the outermost cast's end, so a reaction's casts inside it are settled too (each unit's own passives).
7. Placement: Slayer, Vanguard and General Martial at their roots with no prerequisite (General Martial tier 5, with the bracings; Slayer and Vanguard open from the start); Eros after Impassioned Fighter (the fighting skill there; free at the root it showed up as a first skill of a Paladin's, changing `progress_test.test_unlock`). Tags `martial` only.
8. No HUD float or log line when it eases; the state shows on the exhaustion tooltips.

## Tests

`Tests/deathlust_test.gd` (2 tests, 11 checks): `test_deaths_in_range` (the seam: in range reduces, out of range doesn't, downed/Downed don't, ally counts, own death doesn't, rank widens and eases more, every skill's count and none below nothing) and `test_kill_skips_exhaustion` (a killing Strike gains no use; a downing Strike does). The stub test file was replaced by it. The sweep covers `describe`.

Mutation spot-checks (each failed the tests, reverted): drop the cancel; let downed count; ignore reach; cancel on any felled unit; flat 0.25 whatever the rank.

No existing test changed.

## As built / not done

- Built as above; full suite green.
- Not done: no AI knowledge of it (it does not seek kills for the discount); no HUD feedback; Metea-style channel strikes don't count; an area skill's kills count only through `last_hit_by`.

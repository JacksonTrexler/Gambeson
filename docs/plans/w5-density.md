# Density: fewer ineligible skills (branch w5-density, 2026-11-19)

The user (?203): as few skills as possible should be ineligible for Density / Diluted. Built on w4-density.md and
w2-param.md. Baseline suite: 10225 checks, 0 failed (966 tests).

## Readings

1. **Most of the card was already built.** Commit e05a3c1 (before this branch) gave Mage Armor, Manifest and Relay
   `per_rank`, Solar a d20 a rank, Peel its steps a turn (rank impact), Coalescing and Drown `dice_per_rank`, and
   dropped their `no_density` reasons; `param_test` holds a row each (`test_concrete_scaled`, `test_impact_reads`).
   `skill.py density` on this tip listed **29**, not the 35 of w4-density.md. What was left of the card: Clairvoyance,
   Send Off, Stoneskin.
2. **Rank I unchanged** for each, rank II+ is new scaling (not a balance pass).

## Calls (for the coordinator to number)

1. **Clairvoyance: the stacks of suspicion each ping adds are rank impact.** A ping already adds one stack
   (`Battle.ping()`), each seeing through a rank of trickery and concealment (`Unit.suspicion`); now `stacks` =
   its *learned* rank's impact (1 at I; 2 under Density), not the channel's rising rank (that stays reach, or the
   stacks, already added every turn, would grow quadratically). `Battle.ping(u, reach, stacks := 1)`. Reach stays rank
   and stat range, and now also takes Density's cut (`Modifiers.reach`, as `Skill.span()`): `Clairvoyance.reach()` has
   its own range, so the cut had no effect there. (The brief said "reach only" and "Clairvoyance and Peel (reach only)";
   Peel was already done.)
2. **Send Off: a ward on whoever it sends, from rank II, for rank turns.** The brief said "Send Off's turns", but it had
   no timed effect to give turns to, so one is added: `mitigate` 5% x rank (per_rank), `min_rank = 2`,
   `turns_per_rank = 1`, so rank I does nothing new (no status is put on) and II is 10% for 2 of the target's turns.
   `either`, so it lands on a foe sent away too: the cost of a trade, as Density's slot is easier to disable. Call: the
   ward is thematic ("out of harm's way"); if a foe getting it is wrong, make it a Displace `allies only` rider later.
3. **Battle.cast() skips an effect whose `min_rank` the cast rank (impact rank for a per_rank one) doesn't reach.** Before,
   a tiered effect was put on inert and shown as a status; the stat read already gated it (`Unit._gather_effects()`).
   One line, generic; it also keeps Stonegift (`grants` Stoneskin) from putting a rank-II tier on at rank I.
4. **Stoneskin: a tier, `mitigate` 5% x rank from rank II above 85% HP** (II 50%, III 55%; I stays 40%), its own Effect
   after the two it had, so Stonegift's `effects[0]` and the dex halving are untouched. A grant takes the
   *granting* skill's rank (`ri if e.per_rank`): a Stonegift III grants the III tier. Small; left.
5. **`param_test`'s "ineligible" examples were Clairvoyance**: three places (`test_move`, `test_density`'s end,
   `test_knobs`' knob_problems) now use Powerful (a switch, still ineligible); `test_clairvoyance` now says Density fits
   and cuts its reach ((wisdom + rank) / 1.75) and Diluted fits.

## Still ineligible: 26 (was 29 at the start of this branch, 35 under w4-density.md)

| Skills | Reason, kept |
|---|---|
| alluring, starkind, skill_slot | a trait: nothing to trade (no slot a foe can disable, range, check or cost) |
| arcanist, physical_intelligence, everyman, field_experience, working_knowledge, decisive_strike, decisive_mastery, powerful, synergy, striking_intellect, elemental_mastery | a switch / selector / gate |
| generalist, journeyman, martialist, thaumaturgist, divinity, mastery, symphony, witchery | a build gate |
| armor | Defense by the item, not ranked |
| oceanic, reckless_abandon, vaporize | a drawback only / an inherent trait / a toggled form |

## As built

- `Skills/clairvoyance.tres`, `send_off.tres`, `stoneskin.tres` (reasons dropped; Send Off's ward, Stoneskin's tier).
- `Behaviours/clairvoyance.gd` (`stacks()`, Density's cut on `reach()`, a `rank_impact` term, text);
  `Scripts/Battle.gd`: `ping(..., stacks)`, `min_rank` gate in `_cast()`.
- Tests: new `param_test.test_density_tiers` (all three eligible both ways; Clairvoyance's stacks at I and dense;
  Stoneskin I/II/III and dense; Send Off's ward absent at I, there at II and dense I). Updated: `param_test`
  (see call 5). No new file.
- Mutation spot-checks (each failed `test_density_tiers`, reverted): Stoneskin's tier ungated (`min_rank` 0); stacks
  fixed at 1; the `_cast()` min_rank gate off. `skill.py check`: ok.

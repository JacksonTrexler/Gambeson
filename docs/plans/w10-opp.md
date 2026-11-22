# w10-opp: Opportunist (the Siren's reaction), ?237

Goal: Siren's Opportunist (4fe2c05: first active on enemies that run into it) via a new reaction trigger + Behaviour.react. Detective, Ambush stay unbuilt.

## Calls
1. Trigger `&"beside"` (Battle.travel(): a walk that ends next to another unit; subject = by = the walker). Pre-gated by `_beside()` (8 neighbours) so a walk in the open costs nothing. Only travel() fires it: push/pull/lure through move() don't (no one's walk). Generic: any passive's react may read it (Ambush later); behaviours check hostility/adjacency themselves.
2. "Ran into" read as "ended its walk beside", not blocked-by (4fe2c05's bump) nor passing by mid-path: matches the card's "moved beside it".
3. The use is an aimed interrupt: `grant_interrupt(..., aim)` (5th arg): opens the usual interrupt (free AP, Energy still paid, `allowed` = that skill, "acts out of turn" log), no one picks, casts at `aim` at once, ends. A failed cast (out of reach, can't pay) just ends it. No new Skill field.
4. "First active" = `holder.actives[0]` (4fe2c05's), must be hostile and in reach; else nothing.
5. Opportunist is a `trait` skill (always on, no slot, tags reaction+trait), innate on the Siren (unit.py trait), `--human` (user's name from 4fe2c05, no ??). Rank-less: no_density note.
6. Unlimited per mover (4fe2c05 had none); the skill's Energy cost limits it. A foe in melee range of a Siren still walks into it: the AI doesn't weigh Opportunist (as reactions.md "not done").
7. Hostility = faction, not read: a mover fooled by Alluring (reads the Siren as ally) is still struck: the Siren's trick (Rake doubles on the trusting).

## As built
- Battle.gd: `grant_interrupt(..., aim)`, `_open_interrupt` aimed branch, `_first_active()`, `_beside()`, travel() fires `react(&"beside")` then opens a queued interrupt (as `_on_falling`).
- Behaviours/opportunist.gd, Skills/opportunist.tres (+icon), Scenes/siren.tscn innate.
- Tests: reaction_test.test_beside (the seam), test_opportunist (behaviour on the Siren). Stub opportunist_test deleted.

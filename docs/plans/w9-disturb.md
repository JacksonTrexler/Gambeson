# w9-disturb: Disturbance (Warlock) + Disturbed (cc status)

## Goal
User card: Warlock mid-level skill Disturbance: chosen unit in rank range; imposes a check (very difficult: non-leader | easy: leader); afflicted become Disturbed for rank rounds: can't be commanded or issue commands; act by behaviour (AI) only. Player control stripped via cognitive disruption. Card 3 (undead / Restless Dead) will read `Unit.disturbed()`.

## Readings / decisions
- Existing seam: `Unit.uncontrolled` (export, Astral shades): Command.could_order/can_join refuse; Command.idle() hands them to AI at turn end (HUD._act_alone -> AI.act, which reads u.behaviour). Disturbed reuses that: orderable-ness via `Unit.disturbed()`.
- "Leader" = `Battle.leads(u)`: the player, or a unit someone `follows` (party leader). No other leader model exists.
- Check: target's wisdom (cognitive) check vs DC `Difficulty.dc(unfair|easy, impact rank)` (card: "very difficult" = unfair rung), like Evade's `Battle.check(u, stat, null, dc, {role=defensive})`.
- Status Effects/disturbed.tres, stat `disturbed`, bears `cc`; trait use = holding the effect permanently (no duration).
- Duration = skill rank rounds (turns_per_rank, via Cast.put).

- Skill: Elmon tree (the mind patron: Brainfog, Haluca), after Brainfog (tier 3, "mid"); hostile (foes only; a Warlock can't disturb its own side - card says "unit": left foe-only, `dual` would open the AI to using it on allies); range = rank tiles (radius_per_rank 1, no stat mod); cost "high ap, high sweet nothings, flat rank" (Sweet Nothings preferred, not only); tags warlock, magical, cha, curse, cc. Behaviour `whole()`: no attack roll, the wisdom check is the whole save. Duration = rank impact (no Skill.turns_per_rank: test_flags_described wants a flag to change the markup).
- Check = wisdom check (cognitive), DC unfair (very difficult) non-leader, easy leader; Modifiers.check shifts DC (Density) as Wildfire's dodge does. Emitted as `contested` (total=DC, against=roll+1, so the HUD's "hit" = target failed).
- `fits`: not self, not already Disturbed.
- Disturbed on the player's leader: HUD.autopilot() true (side plays itself via _act_alone, as when the leader is down); log line says "Your mind is Disturbed".
- Command: could_order / can_join refuse a Disturbed unit or Disturbed leader; hears() false either way (Harmony etc. read it); idle() always lists a Disturbed ally (acts at turn end even if ordered/held).
- Glossary tag `disturbed` (--human, no ??; condition, #b58fd6); stat `disturbed`; Effect text + HARMFUL entry. No names made up by me except none: Disturbance, Disturbed are the user's.
- Query for card 3: `Unit.disturbed()` (reads stat `disturbed`, so any status/item/trait lends it); status resource `Effects/disturbed.tres`.
- Sweep fix: `_pose` sets endurance 9 (a recovery-endurance con roll burned Wildfire's pool after my skill shifted the rng).
- forced_test: added disturbed stat and disturbance skill to the cc tables (rule extended, not weakened).

## Done
stat/effect/tag, Unit.disturbed, Command+HUD wiring, skill+behaviour, Tests/disturbed_test.gd (4 tests, 19 checks), commit bb2b4db.
Mutation spot-checks (each fails the test, reverted): swap easy/unfair; +1 turn; drop could_order disturbed; drop idle disturbed; drop leader-disturbed in could_order; drop hears; drop HUD autopilot disturbed.

## Next
full suite, tool checks, launch check, todo notes are the keeper's (not edited).

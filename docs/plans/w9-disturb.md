# w9-disturb: Disturbance (Warlock) + Disturbed (cc status)

## Goal
User card: Warlock mid-level skill Disturbance: chosen unit in rank range; imposes a check (very difficult: non-leader | easy: leader); afflicted become Disturbed for rank rounds: can't be commanded or issue commands; act by behaviour (AI) only. Player control stripped via cognitive disruption. Card 3 (undead / Restless Dead) will read `Unit.disturbed()`.

## Readings / decisions
- Existing seam: `Unit.uncontrolled` (export, Astral shades): Command.could_order/can_join refuse; Command.idle() hands them to AI at turn end (HUD._act_alone -> AI.act, which reads u.behaviour). Disturbed reuses that: orderable-ness via `Unit.disturbed()`.
- "Leader" = `Battle.leads(u)`: the player, or a unit someone `follows` (party leader). No other leader model exists.
- Check: target's wisdom (cognitive) check vs DC `Difficulty.dc(unfair|easy, impact rank)` (card: "very difficult" = unfair rung), like Evade's `Battle.check(u, stat, null, dc, {role=defensive})`.
- Status Effects/disturbed.tres, stat `disturbed`, bears `cc`; trait use = holding the effect permanently (no duration).
- Duration = skill rank rounds (turns_per_rank, via Cast.put).

## Done
(none)

## Next
stat -> effect -> Unit.disturbed() -> Command/HUD/AI wiring -> skill -> behaviour -> test

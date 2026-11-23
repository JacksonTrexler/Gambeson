# w21-foresight
Goal (user): weigh heals/energizing by "would the next hit kill it" and "skills ineligible for lack of Energy"; wise units (wis mod > 0) project auto combat wis-mod turns ahead; a heal/energize that raises turns survived / turns of skill use -> heal or energize itself, ask for it (plea), or, as a skilled leader, command its healers. Projections carry an error margin from what it knows and its int.
Files: Scripts/AI.gd (own section at the end: "Foresight"), Tests/ai_tactics_test.gd.

## Readings
- No existing "request" mechanism in AI/Command: the closest are want() (healer's pick), Command.skilled()/hears() (w16 skilled leader), _replenish (self Energize at <= half, after blows), _switch (starved of every paid skill).
- _threat() = a foe's best read blow x hit chance (else BLOW + stat mod), clamped to u.hp. Busy units recover no Energy (Unit.recover()).
- Energize is self_only; Energy Transfer is a hostile siphon. No skill restores an ally's Energy yet: answering an energy plea is generic and fires for none today.

## Calls
- Horizon = wis mod, 0..FORESIGHT_CAP 4. Wis mod <= 0: no foresight at all (identical turns). The two user signals are the horizon-1 case: "next hit kills" = projected blows reaching it on the foes' next turn >= HP; "ineligible for lack of Energy" = can't pay its cheapest paid skill (blow or heal) from what it runs on.
- Projection (cheap, no sim): each foe it has located and reads as a foe reaches it on turn ceil((tiles - reach) / movement)+1 (reach: its read hostile skills' reach, else MELEE 1.5; movement: the stat), then deals _blow() (= _threat unclamped) every turn after. Turns survived = first turn cumulative blows >= HP; else horizon + 1. Stopped/cc'd foes are not discounted.
- Energy projection: turns (of horizon) it can pay its cheapest paid "worth" skill (for_foes or mends, as _switch), nothing coming back (busy): min(h, floor(store / cost)). Cheapest, not dearest: a dear rarely-used skill shouldn't pull an Energize ahead of every strike.
- Margin: m = clamp(0.3 - 0.1 x int mod, 0.05, 0.6) + 0.3 x share of projected foes whose blows it guesses (no hostile skill read). Error e uniform in [-m, m] from a local RNG seeded hash(battle rng seed, unit name, unit.rounds): deterministic, never draws on b.rng. Projected damage x (1 + e). Energy projection carries no error (it knows its own bar).
- Act: a heal raises turns survived (HP gain capped at max) -> it heals itself first if it can (best self heal by HP); else, if an ally's known heal (allies share kits, any ally whose movement x h + skill reach covers the distance) would, it pleads: meta `plea` {pool: unit.rounds}, lasting through its side's next turn (t.rounds <= stamp + 1), cleared on its next foresight. Same for Energy/its reserve with a self restore (Energize) or an ally's.
- Answering: want() + PLEA 2.0 for a pleading ally; + ORDER 2.0 more when the pleader is its skilled leader (Command.skilled) whose orders reach it (Command.hears) - the "command healers". A plea also lets a healer that reads the ally unhurt (no HP read) heal it. Non-HP pleas answered by `_answer()` (any non-hostile, non-self_only skill restoring that pool) after _heal in _full and _drill: dormant today.
- Foresight runs on a self-directed full turn only (posture ""), after the switch check, before the heal phase. Drill/herd/prowl turns skip it (calm/far: not in danger by definition).
- No HUD sign (sibling branch owns HUD; a "Plea" sign needs a ?? name): log lines only ("X foresees ... and heals itself", "X asks for HP").

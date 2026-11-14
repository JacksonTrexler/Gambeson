# Reactions and interrupts

Branch `s-react`, Phase 3 item 9 of `docs/plan.md`. Baseline suite: 45524 checks, 0 failed (761 tests).

## Readings

- `docs/plan.md` 9: collect reactions before `cast()` resolves a hit; each may swap the target or act, in a
  fixed order, at most once per trigger; Final Act needs an interrupt turn (`_acting()` letting a unit act
  outside its side's turn). Unlocks Interject, Gallantry, Final Act, Snapping Turtle.
- `docs/todo/classes.md`: the four stubs. ?12 (does Final Act's unit die after its action?) and ?13
  (Interject: who and how often) were answered "kept as built unless you say otherwise": nothing was built,
  so the calls below are mine, open for review.
- Already built and reused: `Unit.reacts()` (not Jammed, not stopped) gates every reaction; Jam's
  `jammed` already "takes reactions"; Behaviour hooks on the Cast (`aim`, `edge`, `guard`, `felled`...);
  `Battle.neutralize()` / `neutralized`; Borrowed Time's deferred death (`Unit._landed()`), the model for
  holding a unit up at 0 HP; Mindless Fury's permit (a helpless unit with a permit still `reacts()`).
- Skill tags `offensive` and `defensive` already exist (Tags.gd, on 33 and 34 skills). The context kinds
  (`Check` offensive/defensive) are built too, but Snapping Turtle reads a *skill's* kind, so it uses skill
  tags (through `Unit.skill_tags()`, so a modifier's tags count).

## Calls

1. **One hook, one seam.** `Behaviour.react(r: Reaction, holder, rank) -> bool` beside the other passive
   hooks; `Battle.react(trigger, subject, by, cast)` asks every switched-on passive with behaviours on the
   field. No Skill.gd flag. A throwaway passive joins by implementing `react` (`reaction_test.test_joins`).
2. **Triggers** (`Reaction.trigger`): `&"attacked"` (a hostile skill aimed at a foe, after paying and
   `aim()`, before any roll or save), `&"hit"` (it landed - past the roll, save or contest - before damage;
   in a Strike chain, each blow), `&"fallen"` (reaching 0 HP, `Unit.falling`), `&"snap"` (Snapping Turtle).
   Self-targeted and ally-targeted skills don't trigger. Area skills cast on a tile (`cast_at`) don't
   either: they have no target to swap.
3. **Order:** who brought it about first, then whom it happens to, then the rest by distance from that
   one (ties in the field's order); within a unit, its passives top to bottom of its hotbar, then the rest.
   Each (holder, passive) at most once per moment (`Reaction.done`). The attacker first is what lets
   Snapping Turtle lock its attack before the target's side reacts.
4. **Gating:** `holder.reacts()`, nothing else. Whom it happens to is asked even at 0 HP (Final Act).
   A Jam hit puts Jammed on as it lands, before its damage: so Jam takes Final Act too (tests pin it).
5. **What a reaction can do** (fields on the payload): `retarget(to)` swaps the cast's target unless
   `locked`; `locked` stays on the Cast for the later moments of the same cast; `guard` adds Defense to the
   new target against the roll already made; `stay` holds a falling subject at 0 HP; and
   `Battle.grant_interrupt()` gives an action. A swap after the roll re-checks the same roll against the
   new target's Defense (+ guard); a natural 20 still hits. A swap ignores reach: it steps into the blow.
6. **The tag** `reaction` (`--human`: the word is the user's, plan.md "Reactions"; kind check, colour
   #e0a75e, via `mechanic.py tag`). On all four skills. Composable: a reaction's check carries its skill's
   tags, so an effect tagged reaction (a `check` effect, say) counts on reaction checks and nothing else
   (`reaction_test.test_keyed`). `skill.py check` now fails a skill whose behaviour reacts without the tag.
7. **Reaction checks:** a contest, the reactor's mod (a defensive check, with its skill's tags) against
   the other's (offensive), reactor winning ties (`Reaction.contest()`). So Turtle Tactics helps them.
8. **Interrupt turn.** `grant_interrupt(u, n)` queues; it opens once no `cast()`/`cast_at()`/`react()` is
   under way (at once if none). While open, `_acting()` allows only the interrupter; it gets a free AP pool
   (99, skill uses only, drawn first, taken back after): **a free action is one skill use, any AP cost, no
   walking**; Energy and other costs are still paid. Its n-th skill use (cast, cast_at, or a miss on thin
   air) ends it; `end_interrupt()` passes. Then the next queued opens, else the turn resumes. `end_turn()`
   passes one still open.
9. **Who picks:** the HUD lets the player pick for the leader and party (`command.ours`), with a log line
   and a prompt; End turn passes. Every other interrupter's AI picks (`AI.interrupt()`): its best blow in
   reach (`_strike`), else the heal it wants most (`_heal`, itself among them), else it passes. During an AI
   side's turn the HUD loop waits the interrupt out, then lets the interrupted unit carry on (`AI.act` again).
   Battle doesn't call the AI: headless code drives `AI.interrupt()` itself.
10. **Interject** (?13): allies **beside it** (8 neighbours), **every hit** (no per-round limit; the dex
    contest and the Jam/helpless gate limit it). "A hit not aimed at it" = the cast under way was meant
    for another (`Cast.meant`), whoever swapped it (Gallantry's swaps count). Rank V+: +25% x rank of its
    Defense (against the cast's tags) as `guard`. Snapped: its contest against the target; passing, the
    attack is locked (the target's side can't turn it aside).
11. **Gallantry:** adjacent ally, on `attacked`, before the roll; cha contest against the attacker.
    "That ally can't be retargeted" read as: the attack locks on the Paladin, so no later reaction (an
    Interject, another Gallantry) turns it back or elsewhere. Rank adds nothing yet.
12. **Final Act** (?12): it holds at 0 HP (`Unit.staying`: alive, can't lose more HP), interrupts, takes one
    free action, then **falls as it would have** (a heart, Downed, or death, through `Unit.fall()`),
    **unless the action got it back above 0 HP** (healing itself: it lives). Once a battle
    (`Battle.times_reacted()`). It comes before Borrowed Time, Downed and hearts. The fall resumed isn't a
    new moment to react to. While it holds, the attacker gets no kill until it falls.
13. **Snapping Turtle:** on its holder's `attacked` with an offensive-tagged skill, it asks up to rank of
    its other `defensive` passives with behaviours, top to bottom, with the moment as `&"snap"`; each decides
    what it does snapped. Rank counts those that react (a failed check doesn't use one up). Defensive
    passives without behaviours (Turtle Tactics) are always on: nothing to snap. Gallantry and Final Act
    have no snapped form.
14. **Log and float text:** one line per reaction, "<unit> <Skill> (14 vs 9)" (the roll only when there
    was one), the skill's name floated over the unit in gold; "<unit> acts out of turn" as an interrupt
    opens; failed reactions say nothing.

## As built

- **Behaviour.gd:** `Behaviour.Reaction` (trigger, subject, by, cast, skill, locked, guard, stay, done,
  rolled; `retarget()`, `contest()`, `reacted()`), the hook `react(r, holder, rank)`; `Cast.meant`,
  `Cast.locked`.
- **Battle.gd:** `react()`, `react_with()`, `reactors()`, `reactions_of()`, `times_reacted()`,
  `resolving()`; `grant_interrupt()`, `end_interrupt()`, `interrupter`, `free_ap()`; signals `reacted`,
  `interrupt_began`, `interrupt_ended`. `cast()` and `cast_at()` count calls under way (`_casting`; the
  body of `cast_at` moved to `_cast_at`); `_acting()` lets only the interrupter act; `travel()` refuses it;
  `attempt()`'s miss counts as its action; `end_turn()` passes an open one. In `_cast()`: every hostile
  cast on a foe now gets a Cast (it had one only with behaviours), the `attacked` and `hit` moments, and
  the re-check of a roll after a swap; `_chain()` asks `hit` per blow. `_on_falling()` / `_settle()`.
- **Unit.gd:** signal `falling(u, hold)`, `staying`, `_held_up()`; `is_alive()` counts `staying`.
- **AI.gd:** `AI.interrupt(b, u)`.
- **HUD.gd:** log line and gold float per reaction; `_on_interrupt()` (prompt, or the AI); `my_turn()` is
  the player's while its own unit interrupts; End turn passes it; the AI turn loop waits interrupts out
  (`_interrupted()`) and lets the interrupted unit carry on; the AP row leaves out the free pool.
- **Mechanic:** tag `reaction` (Glossary, Tags colour). **Skills** (stubs removed and rewritten through
  `skill.py new --human`, same places): Interject (Protector, after Shields Up!), Snapping Turtle (after
  Turtle Tactics), Final Act and Gallantry (Chivalry, after Coordinate), with behaviours of the same names.
- **Util/skill.py:** `react` joins HOOKS; `check` fails a skill whose behaviour reacts without the tag.
- **Tests:** new `reaction_test` (hook joining, order, once, gating, Jam, keyed effects, interrupt, queue,
  AI), `interject_test`, `gallantry_test`, `final_act_test`, `snapping_turtle_test`. Changed to the new
  rule: `paladin_test.test_tree` (Final Act and Gallantry built, tier 2), `fighter_test.test_tree` (the
  "stub can't be learned" check now uses Sundering; Interject is learnable).
- **Visual check:** `S/shot_s-react/` (driver `S/driver_react.gd`): a foe's Final Act floats and logs, its
  AI takes the action; the player's own interrupt on the foe's turn prompts, acts, and the turn resumes.

## Not done

- Snapped forms for Gallantry and Final Act (none designed); Turtle Tactics and other always-on defensive
  passives have nothing to snap.
- Reactions to area skills on tiles (`cast_at`: cones, zones) and to damage outside casts (flames, traps):
  no `attacked`/`hit` moment there; `fallen` does fire for them.
- The AI doesn't weigh enemies' reactions when picking targets (a Gallantry Paladin beside its mark), nor
  hold a Final Act unit back.
- Battle doesn't run the AI for interrupts: headless simulations must call `AI.interrupt()` themselves.

# w4-friction: Strike-only Strike rules, Chaser rank chases a chain, the friction tag

The user's words: `docs/agents/answers-2026-11-19.md`, first block (Heavy Strike and any skill named "strike"
apply only to Strike skills, even a Strike chained in as a combo, and only to the strike component; Chaser
procs rank times; rolls past the first rank in a use at disadvantage with a building -1, utility tag
`friction`, "to tamp down infinites"). Prior: `docs/plans/w3-strike.md` (skill uses, Volley, Chaser).

## Readings and calls (for review)

1. **How a skill is known to be a Strike**: before, only `Skill.chain` (Strike alone) - Glancing Strike's
   disadvantage asked `s.chain`, Heavy Strike pooled any skill. Now one generic read, a tag: **`strike`**
   (the user's word, `--human`, no ??; Glossary kind target), via `mechanic.py tag` / `carry`, on the actives
   named for striking: **Strike, Waterstrike, Silent Strike**. It rides on the attack's tags (`hit_tags()`),
   so a modifier or item that adds `strike` to another skill makes it a Strike for these rules. Spellstrike
   (a passive, data only) and the strike-named passives don't carry it: they're rules, not Strikes.
   `strike` and `friction` are in `Tags.PLAIN` (a damage floater passes over them).
2. **Glancing Strike**: its two effects (`glancing`, `opening_rolls`) now carry `tags = [strike]`, so
   `Unit.stat()`'s existing tag filter limits them to Strike skills' attacks; `attack_check()` lost its
   `s.chain` test. **Changed**: a non-Strike attack at disadvantage no longer glances, and gets no opening
   bonus. Opening rolls still count within a use (`rolls_made`): a chase is its own use, so its Strike's first
   rolls get the bonus.
3. **Heavy Strike**: pools only hits whose tags carry `strike` (`striking()` at `hit`); any other skill's hits
   land as they would. The user's case (Jam crits, Chaser follows up with Strike) pools only the Strike's
   rolls: the chase is a separate use, so Heavy Strike's per-use pool already keeps them apart.
4. **The other strike-named passives** (Brutal, Decisive, Elemental, Strike Out, Strike!, Record Striker)
   already act only inside `_chain()`, which only Strike runs: unchanged. Extending them to Waterstrike or
   Silent Strike (non-chain) would need those to be chains: not done.
5. **Use chain (Chaser's scope, (b))**: a new `Behaviour.Volley.chain` dictionary, shared by a use and the uses
   it sets off. `grant_interrupt(u, actions, only, chain)` gains an optional chain; the interrupter's uses join
   it (`_begin_use`). Only Chaser passes one (Final Act's interrupt starts fresh chains).
   **Chaser procs rank times per use chain** (the critting use + its chases), still once per use. The old
   "a use made in an interrupt sets off no chase" is gone: a chase's crit may chase again until the chain has
   chased rank times. A crit in Final Act's interrupt now may chase (its own fresh chain).
6. **Friction ((c))**: tag **`friction`** (the user's word, no ??; Glossary kind check). One generic rule,
   `Battle.loops(caster, skill, rank)`: called where a skill loops a use (a chase, a recast); does nothing
   unless the skill carries `friction`. From then, across the use chain, each attack roll past the first `rank`
   (the looping skill's rank through its holder's modifiers) is at disadvantage (one step of edge, summed with
   others and held to one as any edge, so advantage from elsewhere cancels it) and -1, -2, -3... (the first past
   them is -1). Through `Unit.friction` (the steps on its next roll), read by `attack_check()`, so the HUD's
   forecast and the AI see it too. Calls:
   - Counting starts where the loop begins (Chaser: just after the critting roll, so the rest of that use's
     rolls count; Jugular: at its first recast), not from the use's first roll: a plain Strike's own rolls
     never meet friction.
   - The first friction skill to loop a chain sets its free rolls; a second doesn't add to them or reset.
   - Every attack roll in the chain counts, Heavy Strike's last roll included.
7. **Loop audit** (tagged friction: can loop unboundedly):
   - **Chaser** - tagged: a chase's crit chases again (now capped at rank, plus friction).
   - **Jugular** - tagged: a crit (in crit range, so Backstab widens it) recasts "without limit", guarded
     only by `RECAST_LIMIT` 20; `loops()` called before each recast.
   - Not tagged: **Strike!** (restrikes bounded at three: `depth < 3`), **Strike** (its rank's rolls, ends on a
     miss), **Reckless Abandon** (affinity stats only, nothing repeats), **Final Act** (once, on falling),
     **Snapping Turtle** (snaps up to rank reactions, no attack rolls), **Interject / Gallantry** (a check,
     no attack loop), multi-hit and auto skills (bounded by rank and targets).
8. Not balanced; the user asked friction be reused for future infinites: any new looping skill gets the tag
   and one `loops()` call where it loops.

## As built

- `Scripts/Battle.gd`: `attack_check()` (glancing by tag, friction), `roll_attack()` (counts friction),
  `_begin_use()` (joins the interrupt's chain, sets friction), `loops()`, `_friction_next()`, `FRICTION`,
  `_end_use()` (friction off), `grant_interrupt(..., chain)`, `_interrupt_chain`, Jugular's recast calls `loops()`.
- `Scripts/Behaviour.gd` (`Volley.chain`), `Scripts/Unit.gd` (`friction`), `Scripts/Effect.gd` (glancing text),
  `Scripts/Glossary.gd`, `Scripts/Tags.gd` (two tags, PLAIN).
- `Behaviours/chaser.gd` (rank chases a chain, loops), `Behaviours/heavy_strike.gd` (strike tag only).
- `Skills/strike.tres`, `waterstrike.tres`, `silent_strike.tres` (strike), `chaser.tres`, `jugular.tres`
  (friction), `glancing_strike.tres` (effects tagged strike).
- Tests: `check_test.test_glancing_and_opening` (Strike skills only, chain or not; another attack no edge, glance
  or opening bonus; friction's edge and -N), `heavy_strike_test.test_any_use` -> `test_strike_skills_only`
  (a non-chain Strike skill pooled, another attack not), `test_last_roll` (Volley carries strike tags),
  `chaser_test.test_chase` (Chaser I: once a chain), `test_reach_and_ai` (rank II chases twice),
  new `test_chain_friction_and_heavy_strike` (the user's Jam -> Strike case: Jam's hits land one by one, each
  Strike chase one pooled blow; friction 1, 2, ... past two rolls; no third chase),
  `fighter_test.test_jugular_recasts` (recasts past the first at disadvantage).
- Mutation spot-checks (each failed, reverted): Heavy Strike without the strike gate; `loops()` a no-op; no chase
  cap; chase not joining the chain; Glancing Strike's effects untagged; friction without disadvantage.
- Not done: HUD not visually checked (friction shows only through the forecast's odds); no HUD line naming
  friction on a roll.

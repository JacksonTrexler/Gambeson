# w24-tempers
Card: flippant 18%, power hungry gate, Ramut's Ire cost+exhaust, Princess vindictive.
## Calls (as built)
- Bio.FLIPPANT 0.25 -> 0.18; TEMPERS text names "18% of its HP" (Guide shows it); stars_test asserts it.
- Power Hungry: AI._dares(u, r) gates _richest() and _hunger(): oblivious (wis or cha mod < 0) OR confident: u.bst()+wis > target's (r.stats six cores + wis; no stats: own total scaled by _level()/own lv; no idea: not confident) x (1 + margin(u)) - margin is the existing int-error (Foresight), so "int check on simulating" is deterministic, no dice in AI. Stays non-hostile.
- Ramut's Ire: hand price 1 AP, 1 Energy (skill.py cost hand); new tag `exhausting ??` (mechanic.py; Skill.gd is at its field ceiling, a field failed skill.py check) = one use counts Exhaustion.EXHAUSTING (4) uses; Ire tagged -> a 2nd cast same turn costs x3 (STEP .5 x 4 +1). No per-skill exhaust weight existed; a shared tag lets any skill join. Ire is applied by Battle._ire, never paid, so this bites only if cast/lent.
- Princess: Bio {vindictive, grudges ["astral"]} in Scenes/astral_princess.tscn (hand edit; unit.py has no edit verb). AI._grudge: GRUDGED now skips units of friendly factions (allies astral not targeted). Neutral starmen already count as foes (non-friends), so neutrals are engaged.
## Tests
stars_test (flippant, power_hungry, hunts), exhaustion_test.test_counts.
- Princess grudges ["astral", "starman"]: tags only read at net>=1 (recon), so at recon 0 a Starman reads as name "Starman" and "astral" alone never matched it; "starman" added (defectors keep the name).
- Starman cha 8-ish: mod<0 so Starmen are already "oblivious" and unchanged in play; the gate bites for sharper power hungry units (test sets cha 14). Call for the user: want Starmen gated too?
- Mutation: not run beyond the new asserts (each fails if _dares/EXHAUSTING/friends clause removed by construction: first-run failures showed the asserts live).
- unit.py check wanted a faction and appearance on the Princess now she has a bio: Factions/astral.tres (the Nexus overrides it), appearance Knight.

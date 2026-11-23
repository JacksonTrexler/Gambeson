# w16-swarm (2026-11-23)
Goal (the user: "fodder and army units need to take their turns more simply and quickly ... contingent on a leader or ... log(n)"):
group plan shared by like units (once per side turn), cheap member step that sticks together; incrementally kept targeting
superlatives (lowest HP / physical / magical Defense); fodder turns leader-contingent or cheap. Measure busy_fight A/B vs origin/main eb55c72.
Files: Scripts/AI.gd, Scripts/Ranks.gd (new), Scripts/Battle.gd (one var), Tests/sims/busy_fight.gd (swarm mode), Tests/ai_tactics_test.gd.

## Readings
- AI.act order: `_calm` -> `_drill` (skilled leader's followers), `_far` -> `_prowl` (no foe in sight), else `_full`.
- `_full` for a plain unit reads all foes + allies within reach + 1; `_targeting` loops every read foe; `_approach` past move + 3 is unpriced.
- No rat/goblin units exist; busy_fight fields 12 classes round-robin (30 a side: 2-3 of each class a side).
- Defense: `Unit.defense(tags)`; physical = defense([physical]), magical = defense([magical]) (armor_mind counts for magical).

## Calls
(filled as built)

## Done
## Next

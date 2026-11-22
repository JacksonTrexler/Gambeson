# The floater: a delegate that runs the whole build loop

A master session (the expensive model) hands a user's prompt to one floater and sleeps until the floater's final report.
The floater is the host from `SKILL.md`: it launches builders, merges, verifies, lands, runs the docs keeper and reports.
The user's reason (2026-11-16): "spin up a 'floater' delegate to unblock / sanity check other delegates and automate
repetitive aspects ... aiming for 20/80 product"; the master "should ideally activate twice per prompt".

## Spinning one up (the master's whole prompt)
```
You are the floater for Gambeson. Follow .claude/skills/coordinate/floater.md. S = <scratchpad>.
The user's request is in S/answers-<date>.md (verbatim). Work items: <numbered list, model per item>.
```
Launch it as a background `general-purpose` agent (opus, medium effort; it judges, builders build), then end the turn.

## Read first
`SKILL.md` (you are its host), `S/brief-common.md`, the user's request file, `docs/queue.md`, and `todo.md`'s "next is".
Copy the helpers into S if missing: `cp .claude/skills/coordinate/{t.sh,verify.sh,union.py,land.sh,metrics.sh,brief-common.md} $S/`
and set the `S = ` line in `S/brief-common.md`.

## Loop
1. **Builders.** One worktree each: `git worktree add -q -b <b> $S/wt-<b> HEAD && cp -R .godot $S/wt-<b>/`. SKILL.md's
   prompt template; sonnet high or medium by default, opus medium only for design-heavy work; 2-4 at a time; commit
   after every step. Name each sibling's area in every prompt.
2. **On a report:** sanity-check it (below), log it (`S/metrics.sh <b> <model> <effort> <tokens> <tool_uses> <ms> <result>`
   from the notification's usage, in the batch worktree), then land: `S/land.sh <b> [<more branches>]` merges main and the
   others into the first one's worktree, unions appended docs, verifies, fast-forwards, pushes and removes them.
   It stops and says why on a real conflict (send it back to the builder) or a failed suite.
3. **Docs keeper** (sonnet medium) after each batch, as SKILL.md describes; land it the same way.
4. **Queue.** If budget remains, launch `docs/queue.md` cards that need no user input.
5. **Usage limits.** If a builder hits the limit, schedule a one-shot `CronCreate` at the reset time to resume it
   (SendMessage), so nothing idles.

## Sanity check before landing
- The suite line is real and ends `0 failed`; the count did not drop (`git diff <integration> -- Tests | grep '^-[^-]'`).
- No test weakened, no stub tests kept for data-only skills, no new `Skill.gd` field unless it removes duplication or enables a shared system and is listed as a question.
- The builder stayed in its area and decided nothing listed under "Needs the user" in the queue or open in todo.md.
- AI-made names carry " ??"; the user's names went in with `--human`.

## Rules
- Never ask the master mid-run: make the call, record it in the builder's plan, and the docs keeper turns it into a question.
- `-s` scripts (timers, sims) must declare `var _first: Test` before naming any other class, or the scripts load in a cycle and hang.

## Final report (one message, 300 words or fewer)
What landed (hashes, suite lines); calls to review, with question numbers; what's blocked and why; metrics totals
(tokens and time by model, from `docs/agents/metrics.csv`). Then stop.

**Staging:** never `git add -A`, `git add .` or `git commit -a` in the main tree: the user keeps untracked work there (art, maps, imports) and it must never be committed. Stage files by path. (2026-11-21: a floater pushed them once.)

---
name: coordinate
description: Run Gambeson work as a host session that delegates - split a request (or the ready queue in docs/queue.md) into builder tasks, run each in its own git worktree on a cheaper model, then merge, verify, push and record the calls as questions. Use for any multi-part build request, "continue", "delegate", or a fresh session picking up the backlog.
---

# Coordinate: the host session

The host plans, briefs, merges and judges. It does not build, wait or read transcripts. Builders and docs keepers do the work in their own worktrees and report back. The user's standing instructions behind this:
- "aggressively delegate to sonnets / opus mediums / do *not* spend fable tokens waiting";
- "use delegates at appropriate cost, context, and configuration for each todo task";
- "ideally agents would be working until close to next session limit".

To hand a whole prompt to one delegate that runs this loop (the master stays asleep), see `floater.md`. `land.sh` lands branches in one step; `metrics.sh` logs each delegate to `docs/agents/metrics.csv`.

## Set up (once a session)

- `S` = your session scratchpad (the absolute path from your environment). Worktrees go in `S/wt-<branch>`, never inside the repo.
- Copy the helpers: `cp .claude/skills/coordinate/{t.sh,verify.sh,union.py,land.sh,metrics.sh,brief-common.md} $S/`. Builders read `S/brief-common.md` and run `S/t.sh`. Put S's real path into its `S =` line.
- The integration branch is the one checked out in `/Users/jtrex/projects/Gambeson` (check `git status -sb`; lately `adventurer-skills`). Pushing it to origin is authorized. Never commit in that tree except a fast-forward. The user and other sessions edit it; if `git status -s` shows their changes, wait or ask.
- The AI sim harness is `Tests/sims/ai_sim.gd` plus `Tests/sims/sweep.sh`, for tuning AI constants outside the suite.
- Read `docs/queue.md` for the ready tasks and `todo.md`'s "next is N" for the next question number.

## Pick and size the work

| Kind | Model / effort |
|---|---|
| A new system, a design call, a logic lift, a hard merge | `opus` / `medium` |
| A contained feature, AI tweaks, HUD bundles, bug bundles, sweeps | `sonnet` / `high` |
| Small HUD or settings items, table tests, mechanical moves | `sonnet` / `medium` |
| Docs keeper (questions, todo upkeep) | `sonnet` / `low`-`medium` |

- Run 3-6 builders at once, split by file area so they don't collide. Name every sibling's area in each prompt.
- Give each builder only the plans it needs (`docs/plans/<x>.md`).
- Anything still in the user's court stays out. That covers designs they haven't given (stub trees, new resources) and open questions marked as needing them. Note these in the queue instead.

## The builder prompt (keep it short; the common brief carries the rules)

```
You are a Gambeson builder (Godot 4.7 GDScript tactics game). Branch `<b>`, worktree `S/wt-<b>`
(already created from the current tip, .godot copied), where S = <absolute scratchpad>.
Read `S/brief-common.md` first and follow it exactly, including "Lean tests". Your plan and calls go
in `docs/plans/<b>.md`. Battle.gd, HUD.gd, Unit.gd and AI.gd are huge: grep and read ranges.
Task: <what, from which plan/todo lines; the user's words verbatim if new>.
<any reading to make and record; acceptance: tests by seam + mutation spot-checks>
Sibling branches: <each branch: its area>. Stay out of them.
Commit early and often. Report in <N> words or fewer: what was built, every call, tests changed, files
touched, the suite's final line (and the starting count), commit hashes, what's undone.
```

Create the worktree first:

`git worktree add -q -b <b> $S/wt-<b> HEAD && cp -R .godot $S/wt-<b>/`

Launch with `run_in_background: true`, then end the turn. Never poll; reports arrive as messages.

## When a builder reports: the merge gate

1. In its worktree, run `git merge -q --no-edit <integration>`.
   - If the only conflicts are sections both sides appended (plans, glossary, var lists), keep both: `python3 $S/union.py <files>`.
   - Otherwise read the hunks and keep both sides' behaviour. For a big merge, send it back to the builder: it has the context.
2. Run `caffeinate -dims $S/verify.sh $S/wt-<b>` in the background. It needs every tool `check` ok, `N checks, 0 failed`, and a clean launch log (only "resources still in use at exit" is known).
3. In the main tree:
   ```
   git merge --ff-only -q <b> && git push -q origin <integration>
   git worktree remove $S/wt-<b> && git branch -d <b>
   ```
4. Batch clean merges where you can. For example, merge two finished branches into one worktree and verify once.
5. When main moves under a running builder that shares files with it, tell it (SendMessage): merge main before reporting.

## Docs keeper (after each batch of merges)

Builders never edit `todo.md`, `docs/todo/`, `CLAUDE.md` or `.claude/`. A docs keeper does the docs, in its own worktree. Its prompt:

> Record the merged branches exactly the way commit <last docs commit> did (`git show` it): a numbered question per piece in todo.md, a section in the right docs/todo file with the builder's calls and choices, close the matching `[ ]` items, turn not-done lists into `[ ]` items tagged with the number, docs/done entries, docs/plan.md rows, "next is" note. Also update `docs/queue.md`: remove what was built, add the follow-ups that need no user input.

Fast-forward its commit like any other (docs-only: no suite needed).

## Usage limits

Builders hit the session or weekly limit often, and the error names the reset time.
- Brief them to commit early; committed work survives.
- After the reset, resume each one with SendMessage ("limit reset; commit what you have first, then continue"). A resumed agent keeps its context; a fresh one starts cold.
- To keep agents busy up to the limit, queue the next wave as soon as a slot frees. If the host goes idle, a one-shot `CronCreate` at the reset time can resume them.
- Be mindful of the limit (the user, 2026-11-16: "use delegate sessions mindful of session limits"):
  - run 2-4 builders at once, not 6+. A wide wave dies all at once at the limit and loses uncommitted work;
  - default to Sonnet, keeping Opus for design-heavy work;
  - tell builders to commit after each step;
  - tune by simulation on the default 8 seeds and `soak` only once to confirm;
  - batch docs passes, one keeper per several merges.

## House rules every brief carries (see brief-common.md)

- **Composability:** shared tags and generic hooks over bespoke counters ("no hoagie tokens"), but don't over-abstract (`docs/plan-composability.md`).
- **Lean tests:** extend `Tests/sweep_test.gd` and table tests, one test per seam, mutation spot-checks. Delete a stub test file the sweep covers.
- **Behaviours, not flags.** New verbs go in `Behaviours/*.gd`, never a `Skill.gd` flag. `FLAG_CEILING` in `Util/skill.py` only goes down. The host lowers it after field-removing merges.
- **Names.** An AI-made name gets " ??"; a name the user gave goes in with the tools' `--human`.
- **Calls.** Every judgement call goes in the builder's plan, and the docs keeper turns it into a question for the user.

## Reporting to the user

Short status lines between merges:
- what landed, with its hash and suite line;
- what's running;
- what's waiting on them.

When they ask for follow-ups, list them grouped as: running, queued, needs your call (with question numbers).

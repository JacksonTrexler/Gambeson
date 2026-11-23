# w18-skillpy
Cause: `new --intensity X` wrote intensity = &"faint"; SkillTerms derives the same word from the rank I tier `new` writes, so field was redundant -> skills_test.flags_described "unsaid".
Fix: skill.py writes intensity only with explicit --tier. New check_declared in `check`: .tres field not declared on Skill.gd fails. Found+removed stray `description` in Skills/undead.tres.
Mutation: added `bogus = 1` to undead.tres -> check failed; reverted. Probe skill via new: no intensity line, flags_described passed.
Not done: default-valued fields check (many skills set passive=false etc, harmless: skipped).

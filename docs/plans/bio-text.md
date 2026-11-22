# Bio text on the sheet and the Guide (y-bio)

Calls
- `Bio.line(unit, read)` builds the line; the sheet's `open(u, editable, r = null)` takes the viewer's Read (null: own, whole bio). HUD.gd not touched: the sheet opens only for own units today, so the foe path is for a later caller (shift-click look-over).
- Minimal words: "Brave · Injured Knight · Rotting", tags coloured with {x:}. No sentences, no new Glossary terms.
- Foe: name unknown (r.name empty) shows nothing. Fooled by a persona: persona's adjectives and noun only, no temper or properties (the Read would leak properties at persona III). Else temper (insightful viewers, Read.temper), real adjectives and kind noun, properties as read.
- Guide: a Bio paragraph on the character page; `Bio.TEMPERS` gives each temper a few words, keyed by BEHAVIOURS (test checks sizes match).

Tests: bio_test.test_sheet_line (own, disguised, unknown). Mutations: dropping the deceived guard and the unknown guard each failed it.

As built: screenshots in scratchpad shot_y-bio/run5 (sheet line 'Brave · Injured Knight · Rotting'). RichTextLabel autowrap off, else the panel balloons. Suite start 8105 checks (844 tests) with the new tests.

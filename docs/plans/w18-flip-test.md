# w18-flip-test
Goal: sim that Floaty ranks 1-3 (move 2.5/1.67/1.25, Jump x2-x4) + _leap() never stall a starman.
Done: stars_test.test_floaty_no_stall: 6 starmen (ranks 1,2,3 x2) v 4 villagers (both AI.act), 14 rounds; stall = 3 turns running with no move/hp change/log/Energy change while a free tile takes it further from every villager. 66 checks.
Findings: no stall in _leap()/fractional move. Two non-bugs: (1) a villager's death ended the battle (Phase.OVER, _acting false, all travel no-ops): test resets phase each turn. (2) a Flippant starman cornered at the map edge with every tile unsafe holds still 3-4 turns (_away returns its own cell); judged hold, not stall (turns aggressive once struck). No AI.gd change.
Calls: kept in stars_test (suite cost see report), cornered holding exempt in the test.

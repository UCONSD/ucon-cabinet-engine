# Commit chronicle — August 2026

Moved out of `claude/repo-state.md` on 2026-08-27. That file is read FIRST by
every session and had grown to 561 lines, most of it history; a first-read
document that takes ten minutes to read is one nobody finishes. The history is
not deleted — it is here, verbatim, and `repo-state.md` points at it.

**Shas other than HEAD are deliberately not transcribed** where the original
tables omitted them: `tail .git/logs/HEAD` is the source, and a copied sha is a
number that can go wrong in exactly one place.

---

### 2026-08-24 commits, newest first

| sha | what |
|---|---|
| `27ede4c` | chore: probe reports are measurements, not data |
| `e9229d0` | fix(placement): a row is aligned at the FRONT, so a shallow neighbour stops being invisible (0.77.2) |
| `467699b` | tools: read-only probes that write their reports into the repo |
| `a6991bf` | fix(placement): a turned element takes the RUN's depth, so a shallow filler lands on the front line (0.77.1) |
| `6f31f7d` | placement: a run turns at a corner's wasted end, back to the wall and shoulder to the 8x8 (0.77.0) |
| `28091f3` | placement: both sides taken builds anyway, and the rule covers fillers (0.76.1) |
| `c2d3475` | docs(repo-state): 422 checks, and the side rule with its untried half |
| `b111343` | placement: the next element takes the free side, and refuses when both are taken (0.76.0) |
| `e555f2f` | registry(fillers): the front-only strip is 22 deep and nine of twelve rows are held (0.75.0) |
| `6458a0d` | registry: the hung capacity is a property of the fixing pair, and the count 2/4 leaves the code comment |
| `8e211f1` | registry: tall units H.210 for base unit H.78, printed p.116 - and a split front that must not leak to its family (0.74.0) |
| `cb80117` | registry(fillers): a note copied from H.78 claimed a front height three families do not have *(the same message as `ec3d8fb` below - the first commit went in without the new findings note, which needed `git add`)* |
| `ec3d8fb` | registry(fillers): a note copied from H.78 claimed a front height three families do not have |
| `7f1a3d8` | docs(repo-state): 405 checks |
| `26753c7` | docs(repo-state): the Project holds session instructions, not repo documents |
| `3168d35` | docs: the reverted corner seating reaches the teardown and the manifest |
| `53afd00` | docs(repo-state): rewrite at 13e7754 - the numbers, the corner correction, and the owed list |
| `13e7754` | generator: the dishwasher panel gets a drawn plinth, and DRAWN stops meaning ORDERED (0.73.0) |
| `3652298` | fix(corner): the 8x8 is 77 x 80, and the node seats raw again (0.72.0) |
| `ab492dc` | docs(elda): estimate 30831 teardown, and what the factory confirms and contradicts |
| `30bbca1` | docs(repo-state): the day's four commits, and extraction paused by the real kitchen *(this file, written at `14158a5` — and the row below is what it therefore got backwards for three commits)* |
| `8aee002` | chore: drop the corner probe |
| `14158a5` | fix(corner): seat the node one front gap off the perpendicular wall (0.71.0) *(the seating was the wrong body — superseded by `3652298` the same day, and left in history: rule 9)* |
| `848f10f` | fix(harness): the suite runs on the Ruby macOS ships (2.6) again |
| `42288dc` | registry: the printed p.19 pictogram sweep, and an absent reading that is now a bug (0.70.0) |
| `e0893dd` | registry: base and sink units H. 58.5, and a door version that may belong to the article (0.69.0) |
| `6e06bbc` | chore(gitignore): keep rendered catalog pages out of git |
| `2f54abf` | docs: repo-state records the move, what stayed behind, and where the next session starts |
| `a775846` | docs: move the working notes out of the claude.ai Project and into the repo |
| `0d31813` | registry: base units H.48 p.28, and a catalog cache the suite had outgrown (0.68.0) |
| — | registry: base H.39 p.25, and two pages stopped on a height the page will not name (0.67.0) |
| — | registry: base units H.39 p.24, and the base prefix that was never a family letter (0.66.0) |
| — | registry: the plain tall column, five families that agree on everything but hanging (0.65.0) |

*(shas other than HEAD are deliberately not copied here — `tail .git/logs/HEAD`
is the source, and a transcribed sha is a number that can go wrong in exactly
one place.)*

### 2026-08-23 commits, newest first

| sha | what |
|---|---|
| `2c312c6` | registry: tall H.138 p.90, and six codes we were offering wall-hung that the catalog does not (0.64.0) |
| `f50a3d6` | registry: the three integrated-dishwasher doors of p.48, held on the axis p.38 found (0.63.0) |
| `7843727` | registry: base units H.78 p.37-38, and the legend on p.19 nobody had read (0.62.0) |
| `09c15e9` | registry: wall units H.120, and two things the pages did not actually say (0.61.0) |
| `217153d` | registry: wall units H.96, dish-drainers H.96, and the sentence that derives nothing (0.60.0) |
| `719eba7` | registry: wall units H.84 and dish-drainers H.84 (0.59.0) |
| `0e3b421` | registry: wall units H.72 and dish-drainers H.72 |
| `a8e75b9` | registry: wall H.60 compounds |
| `3325f5c` | fix: the wall-hung checkbox reads the choice, not the result |
| `0bc849f` | registry: dish-drainer units H.36 / H.48 / H.60 |
| `52bb422` | registry: wall units H.48 |
| `00115de` | palette: a filler grid is rows by depth, buttons by height (0.55.2) |
| `21383ba` | fix: a rebuild must see the ordered width, not re-read a row that has none (0.55.1) |
| `86bd15f` | palette: ask for the width a filler is ordered at (0.55.0) |
| `27eab90` | registry: a filler's width is an order axis, not a catalog fact |

### 2026-08-22 commits, newest first

| sha | what |
|---|---|
| `bc546b2` | registry: two files may not disagree about one family fact |
| `f2bf2db` | wall-hung: the panel offers it, and the rebuild asks the object |
| `f5f671a` | wall-hung: the rules, and the first companion a person has to choose |
| `a3b9927` | plinth: record what the 5 mm foot's range means, so zero reads as a decision |
| `094a409` | plinth: say what the 5 mm foot actually is *(superseded by `a3b9927`)* |
| `6a9ff1b` | plinth: the height is a family fact, and zero is one of its values |
| `4f641ae` | export: count the handles — one per opening front |
| `4d860ef` | contract v2.1 + gola profiles as order lines |
| `cc34376` | export: walk the model |
| `23230f7` | export: order rows level 1 |

**`094a409` states the shim range wrongly.** `a3b9927` replaces it. Left in
history rather than rebased away: rule 9 applies to the log as much as to a
document.

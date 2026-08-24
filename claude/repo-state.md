# Repo state — the volatile numbers, in ONE place

**This file is the single source of truth for where the repository stands.**
`claude/ucon-cabinet-engine-status.md` points here and does not repeat any of
it: a number copied into two documents goes stale in one of them, and rule 13
was learned the expensive way. **`claude/extraction-plan-2026-08-23.md`
deliberately carries no progress numbers either** — it is a dated estimate of
the work, and how much of it is done belongs here. The measured debt is
`claude/debt-2026-08-24.md`, which is a dated measurement and is superseded by
a new note rather than edited.

It is deliberately tiny. The day's narrative lives in
`claude/findings-2026-08-23.md`, `claude/findings-2026-08-23-tall.md` and
`claude/findings-2026-08-24-base-column.md`.

**How to keep it true (rule 13):** read it from the repo, never from memory,
**and re-read it before every report** — Andriy commits in his own terminal.
Through the device bridge the safe reads are `git show -s --oneline HEAD`,
`tail .git/logs/HEAD`, `cat .git/refs/heads/main`,
`cat .git/refs/remotes/origin/main`, and `git show HEAD:<file> | diff - <file>`
for what is uncommitted. **Never `git status` through the bridge** — it takes
`.git/index.lock` and the mount cannot delete the lock afterwards.

---

## As of 2026-08-24

| | |
|---|---|
| **HEAD** | **`2f54abf`** — *docs: repo-state records the move, what stayed behind, and where the next session starts* |
| **Pushed** | **yes** — `origin/main` == `refs/heads/main` == `2f54abf` |
| **Working tree** | **DIRTY — the whole H.58.5 extraction is uncommitted.** Two new registry files (`base_h58_5.json`, `sink_base_h58_5.json`), `_manifest.json`, `tools/test_contract.rb`, `core/00_version.rb`, `docs/Elda_Open_Questions_v0.1.md`, `claude/findings-2026-08-24-h58_5.md`, `claude/README.md` and this file. Andriy commits in his own terminal. |
| **Core version** | **0.69.0**, shell 0.6.0 |
| **Headless suite** | **394 checks, 0 failures** — green on the bridge (Ruby 3.0.2) |
| **Object Contract** | **v2.1** — unchanged, with **two named gaps** |
| **Registry** | **692 codes** in **36 section files** carrying **27 catalog sections**; `catalog_map` holds **67 sections** |
| **`_to_delete/`** | **two files, still waiting on Andriy** — `probe_tmp.rb` and `00_version.rb.bak.2026-08-23`. The bridge cannot delete. |

### The Project is retired

`claude/` was moved out of the claude.ai Project on 2026-08-24 and pushed as
`a775846`. **Twenty of the twenty-one originals were then deleted from the
Project; the repository is canonical.**

**One was deliberately kept there: `elda-mini-order-2026-08-20.md`.** The
scheduled Elda follow-up fires at 07:00 UTC and writes the sent/unsent state
into that document from a fresh session, at an hour when Andriy's computer is
asleep and this repository is unreachable. It updates the Project copy and
reports that the repo copy needs the same edit. **After that firing, the two
copies disagree until somebody commits the repo one — and then the Project copy
can go.**

---

## The extraction, group by group

Plan: `claude/extraction-plan-2026-08-23.md` §5 — **but read the manifest
first.** Three times in two days the plan has described work already done or
already blocked; it estimates volume from an index and knows nothing about
blockers. Measured debt: `claude/debt-2026-08-24.md`.

| group | state |
|---|---|
| **Group 1 — the wall column** | **DONE.** All thirteen non-hood wall sections held. |
| **Group 0 — the clean remainder** | **CLOSED as far as reading can take it.** p.37, p.38, p.48 done; p.112 and p.115 blocked on modules. |
| **Group 2 — the plain tall column** | **DONE as far as reading can take it.** All five families' clean first pages held, 72 codes. |
| **Group 3 — the base column** | **OPEN, part done.** H.39 (p.24-25) and H.48 (p.28) held. **H.58.5 (p.32-35) DONE — the section taken whole, 77 codes, 2026-08-24.** **Next: H.84, printed p.49-56** (letters `BK`/`BL`/`BM` swept, **depth mapping not read**). |
| Groups 4-5 | not started. |

### Where the next session starts

**Base H.84 — printed p.49-56**, which DOES need discovery: `BK` / `BL` /
`BM` were swept out of the filler table and **which letter is which depth has
not been read**. H.48 and now H.58.5 are the warning — `BC` / `BQ` / `BD` and
`B3` / `B6` / `B4` are both out of depth order — so nothing about H.84 can be
assumed from the alphabet. Its plinth is 60, not 100.

**Before it, one page is still owed:** the printed p.19 pictogram sweep over
the **148 non-wall codes** transcribed before the legend was found. Their
silence about the hung and hob glyphs means *unread*, not *absent* —
`claude/debt-2026-08-24.md` §3. H.58.5 is the argument for doing it: on
printed p.32 the hob glyph sits on d.62 of two positions and NOT on d.62 of the
position directly above them, so the mark is per (position x depth) and no
sweep can be shortcut by a rule.

### Sections held

| section | printed | held | left |
|---|---|---:|---|
| Base units H. 39 | 24-27 | 48 | p.26 and p.27 **stopped** — a height the page will not name |
| Base units H. 48 | 28-31 | 30 | p.29-31 |
| **Base units H. 58.5** | **32-34** | **53** | **none — the section is whole** |
| **Sink base units H. 58.5** | **35** | **24** | **none — the section is whole** |
| Base units H. 78 | 36-43 | 131 | p.41 (grammar unread), p.42-43, p.46 (corners, Q7b) |
| Base H. 78 \| appliances | 47-48 | 9 | the induction-hob protection |
| Sink base units H. 78 | 44-46 | 20 | |
| Tall units H. 138 | 90-96 | 16 | mechanisms, corners, appliance housings |
| Tall units H. 198 | 97-101 | 14 | same |
| Tall units H. 210 | 111-115 | 14 | same |
| Tall units H. 222 | 132-136 | 14 | same |
| Tall units H. 234 | 151-155 | 14 | same |
| USA \| tall H. 210 | 418 | 8 | |
| Closing strips and fillers | 434-435 | 6 | |
| the thirteen wall sections | 211-254 | 291 | one unread page (p.212) and twelve corners |

**Held and NOT buildable, registry-wide: 23.** Two fillers with no printed
depth, thirteen base units, six appliance panels, and **two compact-oven
housings on printed p.34** whose front height the appliance decides. **Nineteen
still wait on ONE decision** — `door_versions` is a family key — and a check
requires all nineteen to name that reason in the same words, so the backlog is
one grep.

**Twenty-two codes refuse the hung version:** 2 base (p.37), **2 base (p.34)**,
2 tall H.138, 6 tall H.210, and all 10 of H.222 + H.234. **Four of the
twenty-two refuse in WORDS** — p.34 and p.37 — and the other eighteen only by a
missing glyph and a missing margin line. An absence has to be re-read; a
sentence does not, and that difference is now its own check.

---

### 2026-08-24 commits, newest first

| sha | what |
|---|---|
| — | **UNCOMMITTED: registry: base and sink units H. 58.5, and a door version that may belong to the article (0.69.0)** |
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

---

## The shape of every finding so far

**A rule derived from pages that happened to agree, and a later page that did
not.** Two corollaries worth keeping separately:

> **A reading that stays in a note is a reading the engine does not have.**
> `catalog_map` recorded correctly on 2026-08-22 that only one type on printed
> p.111 offers a wall-hung version. It never became data, so the registry was
> wrong for a day and a half while the note beside it was right.

> **A check can only fail on what it looks at.** The old rack check went green
> while the note beside it was false, because it read a proxy instead of the
> recorded fact. The five-family tall check, by contrast, caught a suffix note
> written an hour earlier — because it looked at the codes.

And, from the base column:

> **A page stopped for a reason must say so in BOTH places** — the section file
> and `catalog_map`. A plan written from a map that says *not_extracted* where
> the manifest says *blocked* schedules a day of work that cannot be done.

And, from H.58.5:

> **A door version can be an ARTICLE fact.** printed p.32 draws ONE elevation
> over its pull-out door and two over every other position on the page, where
> the same position at H.78 draws two. `door_versions` is a family key, so the
> panel offers a 55,5 the page has never printed. Elda **Q8**, and the same
> axis the 19 not-buildable H.78 codes wait on — one answer settles both.

Full accounts: **`claude/findings-2026-08-23.md`** (H.96, H.120, base p.37-38,
p.48, Group 0), **`claude/findings-2026-08-23-tall.md`** (the five plain tall
families), **`claude/findings-2026-08-24-base-column.md`** (the base prefix) and
**`claude/findings-2026-08-24-h58_5.md`** (H.58.5, whole).

---

## The earlier work

`claude/fillers-recon-2026-08-23.md` — the filler chapter and the order-axis
width. `claude/warehouse-architecture-2026-08-22.md` §8 — how a filler reaches
the order as погонаж. `claude/options-architecture-2026-08-20.md` — the kit that
is chosen against the hinge that is implied.

**Rule 18, learned 2026-08-23:** *when a check fails for a reason its title does
not mention, the title is the bug.* Applied seven times since.

---

## The 5 mm foot — settled, in four passes

KS printed p.548 prices *"Floor-standing base and tall units with adjustable
feet **H. 5 mm**"* (`989053`, 22 points).

| # | reading | whose | verdict |
|---|---|---|---|
| 1 | 50 mm — a cm/mm slip | Claude | wrong |
| 2 | ±5 mm of adjustment travel | Andriy | right about *travel*, wrong as "±" |
| 3 | a foot 5 mm tall | Claude | right about the part, wrong about the datum |
| 4 | **range 0…5, and the 5 is travel for floor unevenness** | Andriy | **the spec** |

**LIN printed p.214** sells the same foot for floor-standing panels as `990408`,
*"Adjustable foot H. 0.5 cm"*, noting *"0.5-cm **high** feet will be mounted"*.
The book keeps two grammars — `H. <n>` for a height, *"adjustable in height by /
up to <n>"* for travel. What settled it was a fitting drawing: M6×22 stud, Ø18
disc 5 mm thick, insert M6×13 — **the stud screws into an insert sunk in the
bottom panel and disappears.**

**The specification, and it is OURS:** minimum design height **0 mm**, panel flat
on the floor; maximum **5 mm**, and that 5 is **travel**. The drawing shows
**zero — no gap.** *(Rule 4: a UCON decision.)* In the model, `plinth_h_mm = 0`.
**The number 5 is stored nowhere.**

---

## Two commands that did NOT run, 2026-08-22 — the evidence for rule 16

**1. `git pushcd ~/dev/ucon-cabinet-engine`** — a line-join typo. Git rejected
`pushcd` and three commits sat unpushed until the two refs were compared.

**2. A `printf ... >> session-logs/... && git add -A && git commit && git push`
chain.** The redirect failed — **`session-logs/` does not exist here** — and
because the chain is `&&`-joined, *nothing after it ran*. The text it was
appending was a **BA discovery rule**:

> ## Discovery rule (BA, applies to all remaining discovery)
> If a new crack is an instance of a previously found systemic pattern, do NOT
> create a new concept — mark it as re-confirmation of the existing one. Goal:
> the minimal set of stable business primitives and governance rules, not the
> largest possible data model.

**Recorded here so it is not lost, and NOT filed into this repository**, which
has no `session-logs/`, no "cracks" and no "business primitives" — the command
looks meant for a different project's terminal. **Andriy has to say where it
goes.**

Applied repeatedly since: the plinth-height finding was another instance of the
**composition-axis** pattern; the wall-hung and filler rebuild bugs were the
third and fourth instances of **"a pure layer being right proves nothing about
its caller"**, the wall-hung checkbox the fifth, and the unreachable `wall_hung`
key the sixth. The whole wall chapter and now the whole tall chapter have been
one long instance of **the letter is a lookup, read the row** — and the base
prefix turned out to be a lookup for a *slot*, not a family, which is the same
pattern a level deeper.

**A third failure of the same family, and it was Claude's:** a list of files in
`_to_delete/` was formatted as a fenced code block, so it read as commands and
was pasted into the shell. Four `command not found` lines. **Format a listing as
a listing; a fenced block is an instruction to run something.**

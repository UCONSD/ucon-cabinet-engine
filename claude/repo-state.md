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

## As of 2026-08-26, evening — the end-panel chapter, and modifications parked

| | |
|---|---|
| **HEAD** | **THIS CELL DOES NOT CARRY THE HASH, AND THAT IS THE FIX (2026-08-26).** A file that names its own commit is wrong the moment it is committed: writing the hash here changes HEAD. It was wrong three times on 2026-08-26 alone, and every time somebody noticed it was because they read the ref instead. **Read it, it is one command:** `git show -s --oneline HEAD`, or `cat .git/refs/heads/main`. What this row CAN say is what landed last and is stable: the 0.83.0 work — the appliance housing on the floor, the span above it as an order line, the east fridge in the model, `FRONT_REVEAL_MM` deleted — and the doc commit that follows any of it. |
| **Pushed** | **READ THE TWO REFS. It is two `cat`s** and it is the only answer that is ever current: `cat .git/refs/heads/main` and `cat .git/refs/remotes/origin/main`. Equal means nothing is waiting; **equal does NOT mean up to date** — that is how the laptop looked while eleven commits behind. This cell said YES on 2026-08-26 while `063c373` sat unpushed, and the commit whose own message announced the push was the one that had not gone. |
| **Working tree** | **READ IT FROM `git`, NEVER FROM THIS CELL.** At the close of 2026-08-27 it held **twenty-two files and an entire day** - HEAD was still `85aea5b` (0.92.0) while the tree was at 0.99.0. One `sh build/go.sh` commits and pushes the lot; until it has run, none of it exists anywhere but that one disk. Earlier, and kept for its lesson: the 0.86.0 glass repaint AND the 0.87.0 end-panel work were both in `60_generator.rb` at once. They are separated by `build/commit-panels.sh`, which stages the glass hunks into the INDEX with `git apply --cached` and leaves the working tree alone - two commits out of one edited file, in the right order. If that script has not been run, the two concerns are still tangled. |
| **Core version** | **Read `git show -s --oneline HEAD`.** In flight at the close of 2026-08-27: **0.99.0**, and it is ONE uncommitted batch covering the whole day - the Shelves chapter and `object_class: shelf` (contract v2.2), the shelf fixings as order-only lines, worktops, C92640's derived door, the lit shelf through four rounds of not being visible, the `label` key (contract v2.3), the facing controls, and the colour-temperature setting. If `build/go.sh` has not run, ALL of it is local to the office Mac. Shell **0.6.0**. **Appliances 0.2.0 - still untouched, and no `.rbz` rebuilt.** |
| **Headless suite** | `tools/test_contract.rb` **569, 0** · `tools/test_appliances.rb` **84, 0** · `tools/test_appliance_seam.rb` **46, 0**, all three green under `/usr/bin/ruby` 2.6 on 2026-08-29. **The filler's door version added eight more on 2026-08-29**, and FOUR of the eight pin refusals rather than the happy path - a filler gets no `opening_method` (gola is not a way of opening for a thing that does not open), no mounting decision (the checkbox is hidden for it, so reading its `false` would put a wall filler on the floor - this bug's mirror image), the grip recess is taken AWAY again at 78, and a family that declares no versions refuses a 75 by name. The fifth is a SOURCE check on the dialog's JavaScript, because a fieldset and a radio cannot be pressed headlessly. **Retag added eight on 2026-08-29** and the shape of them is the point: ONE is a ratchet - every `object_class` in the contract must have a tag in `Retag::TAGS`, so the enum cannot widen without the tag map learning the new class - and THREE pin refusals rather than the happy path (a body already on a UCON tag is not moved, a body with no `CabinetEngine` dictionary is not touched, an unknown class is named and not guessed). One is a SOURCE check on the palette, for the same reason the picker grid has one: the button is HTML and nothing headless can press it. **A ninth check failed on first run and was right to** - three inline comments in `66_retag.rb` numbered their own refusals `rule 1..3`, and `rule N` is a citation into `claude/rules.md`; they are `refusal N` now. Before that: **533, 0**. The ceramic tops added **five** on 2026-08-28, and four of the five pin a REFUSAL rather than the happy path - a top with no depth is not buildable, 660 is not rounded to a band, 650,5 is not a band, and a length off the 3140 sheet is refused. The fifth walks the CATALOG as well as the lookup, because adding a key to one and not the other is the `wall_hung` bug of 2026-08-22 and this section adds four such keys. **Seven checks failed the moment the section loaded**, all seven correctly: two code counts, the section census, the class census, the two-books check, the picker label, and the unlabelled-type ratchet firing on its first new chapter exactly as its own comment said it would. Earlier: `tools/test_contract.rb` **517, 0**. The Volume 3 panel chapter added **eight** on 2026-08-27 - two books and no code citing the wrong one, 44 codes in ten blocks none of which claims to be buildable, a sheet having neither width nor height and both refusals naming the order, 880 ordered rather than MODIFIED, a panel bigger than its sheet refused, a sheet's width not being a thickness where an end panel's still is, the minimum and the non-monotone prices held as printed, and the fixing kit priced per BASE UNIT rather than per panel. **Three of those eight failed when first run and found a real bug**: `height_range_mm` was written correctly in the section file and `Registry.lookup` did not carry it, so a cut sheet was being recorded as a height REDUCTION - the same shape as the `wall_hung` key that could not be reached for a day and a half. Before that: the end-panel work added **16**, and the 2026-08-27 tidy four more — a bare `rule N` anywhere in `src/`, `tools/` or `registry/`; the two rule lists still being the length `claude/rules.md` claims; every working note named in `claude/README.md`; every Elda question in the status table with a Status line of its own. Before: the three collections and their code count, contract validity, height-from-the-row, the depth label the catalog contradicts itself about, no front, the width refusal, the one misprinted height, the refusal to draw on a guessed ground, the 1,8 cm surcharge that must never become an article, a picker label for every class in the registry AND in the map, and - added after the first lookup against the real kitchen contradicted a note - that THE TWO PAGES OF A COLLECTION NEVER PRICE THE SAME DEPTH GROUP, that the picker grid has something to put ON the button, and - a SOURCE check, because the grid is JavaScript and nothing headless could see it - that a selected code reaches the Build button whatever else the article still needs asked. **Run under the Ruby macOS ships (2.6) by the commit script, which will not proceed otherwise.** |
| **The Avenida Primavera model** | **THE EAST FRIDGE IS BUILT AND THE ENGINE CANNOT REBUILD IT.** `CL4850SD/S/T` named, its opening drawn at the published 1206 x 2127 x 610, three UCON overlay panels placed at a MEASURED datum off the Sub-Zero guide, and `UCON-BESP-001` — a custom cabinet with one upward-opening door — closing the 313 above. All of it drawn by ARMED probe runs (`build/42`, `build/44`) and verified by a read-only one (`build/43`), because no command in the engine can produce any of it. Account: `claude/findings-2026-08-26-east-fridge.md`. **AND THE 2026-08-25 READING BELOW IS NOW OVERTAKEN, kept rather than deleted (rule 9): FOUR objects on the east wall now carry NO article** — the three UCON panels and `UCON-BESP-001` — and each of them says why on itself and reaches the order as *CUSTOM SIZE - NO ARTICLE, to be quoted*. That is the honest state of a kitchen whose appliance side is ahead of its catalog side, not a regression. What follows was true on 2026-08-25: ~~**NO OBJECT ON EITHER WALL IS WITHOUT AN ARTICLE**~~ as of 2026-08-25 late evening. The seven CUSTOM boxes became `SD0631` x6 (four at 610x600, two at 610x720 - width and height INCREASE, unprinted, Q11) and `SD0930` x1 cut to 770 (width REDUCTION, printed, 989370). Read back from the model, not from the list of what was built. The walls: SOUTH is the range, EAST is the fridge niche - and a verification probe called the east run WEST for one run because it mapped a `+x` back vector to the wrong side. The model's own names were right. |
| **Extensions** | **TWO, one repository**, and **both now RUN** (2026-08-25, SketchUp 2026, first time for the appliance one). `src/ucon_cabinet_engine.rb` + tree, `src/ucon_appliances.rb` + tree. Neither requires the other. **The engine is NOT copied into Plugins**: a one-line dev loader there requires the repository, so Extension Manager has nothing of it to uninstall — which is exactly how the copy was lost on 2026-08-25. Appliances stay an `.rbz` copy from `tools/build_rbz.rb`. One shared `UCON` submenu via `UCON.extensions_menu`. Design VENDORED from `design/panel_kit.css` by `tools/build_panel_kit.rb`; a hand-edited copy fails its own suite. Account: `claude/findings-2026-08-25-first-run.md`. |
| **Object Contract** | **v2.1**, one of the two named gaps closed (the `remainder`; see `docs/Reserved_Void_Spec_v0.1.md`), and **two rules that were confirmed and unwired are now wired**: a WIDTH REDUCTION reaches the object as a variant (Elda 2026-08-24, Q3 closed for width), and §4.2 rule 4's *never a silent deletion* is finally true of the exporter. **printed p.414's gap - a front whose WIDTH comes from the opening - is NOT closed**, and Q11 is its live twin: 610 has no article because nothing above it can be cut down. **Q11's disposition was corrected the same evening**: the engine DRAWS 610 rather than refusing it, because the LayOut sheet is how the question gets asked - the catalog prints reduction only, and the object says so in its own variant instead of the registry inventing an article. |
| **Worktops** | **THE ENGINE DOES NOT DRAW THEM. Andriy draws the stone; the engine STAMPS the article onto it** — decided 2026-08-28 after three refusals in a row came out of the model rather than out of the suite. The reason is this project's own discipline turned on itself: every rule that generated a worktop shape would have been **inferred from one kitchen**, and the rules would never have ended — mitres, scribes, 45° returns, angled walls, a notch round a column. **Do not re-add a generator without re-opening this.** `core/62_top_stamp.rb` is pure and holds all of it: the thickness is the smallest of the three dimensions (no axis convention to remember, survives 45°), the band Andriy chose decides which of the other two is the depth (sorting would call a 300×650 return piece '650 long'), three refusals — a thickness that is not the article's, a piece over 3140, a piece deeper than its band — and one remark, for stone cut down from a wider band, which is what a 644,5 run buys because no 620 band exists. Tolerance **1 mm everywhere**: hand geometry lands on fractions and a refusal at 0,3 would be about SketchUp. **The one assumption is Elda Q28** and it is written onto every object it touches: a mitred piece has no single length, so the order figure is the piece's BOUNDING RECTANGLE, the sheet it is cut from. **What was lost, and it is owed back:** a stamped top does not know the run beneath it, so nothing checks the stone covers the cabinets — `build_worktop` knew, because it measured them. It keeps its code and its checks and **lost its button**; two ways to make a worktop are two ways to be wrong. **The sink is two facts** (`core/64_sink_mark.rb`): the ORDER fact is a variant on the top (p.110 prices a bowl each, no code of its own), the DRAWING fact is a dashed rectangle 1 mm above the stone that cuts nothing — position is not in the order, which is what lets them come apart. And it **refuses where there is no stamped top**, which is the only covering check the model has left. |
| **The door version** | **A CONTROL THAT WAS SHOWN AND COULD NOT ACT, 0.95.0 to 1.6.0.** `Panel.attributes_patch` opened with `unless opens?(unit) -> return led_patch`, and `opens?` asks for `unit['opening']`, which a FILLER does not have - so the door-height choice never reached the model. No error, no change, and the radio stayed where it was put because it is HTML. The dialog showed it because the JavaScript asked only `st.door_versions`, a FAMILY fact, and B70151 is family H.78 which does declare 78/75. **Found in the model, not in the dialog:** every base cabinet at front 750 and both H.78 fillers at 780, a 30 mm step in the elevation - which `fillers_h78.json` had warned about in writing. **The fix is one predicate becoming two**: `front?` (front_layout kind present and not `none`) earns the door version and the grip recess; `opens?` earns the method, the handle and the hinge. **A filler in the 75 version orders its own length of profile** - Andriy, 2026-08-29 - which fell out of resolving companions from the door VERSION rather than the opening METHOD; `GOL001`, um ML, `qty` nil, exactly as incomplete as every cabinet's profile line and a separate open question. **A `door_version` contract key was written and taken back the same hour** (learned rule 9): §1.2 makes a key outside the list a violation, so storing it is a REVISION, and `front_height_mm` plus the family's `gola_mm` already determine the version - `door_version_of` derives it in one pure place, the shape `wall_hung_chosen` has had all along. **The family scoping was already right** and is now pinned: BE0151, C00151 and PF0151 are fillers whose families declare nothing, and they are refused by name. Account: `claude/findings-2026-08-29-the-filler-has-a-front.md`. **STILL OWED: the two fillers in the model are still at 780** until the armed pass runs. |
| **Drawing / tags** | **THE MODEL HAD EIGHT SCENES AND NOTHING TO SWITCH, 2026-08-29.** 56 of 59 UCON bodies sat on `Layer0`, so every scene faithfully saved a tag state that did not exist - one drawing of everything and no way to make a second. All eight cameras were PERSPECTIVE and seven of the eight were the SAME perspective, saved under four wall names and four island names; section planes zero. **The symbols were fine all along** - 205 entities on Opening (front), 450 on (plan), 338 on (door), 309 on Lighting - simply switched off. `core/66_retag.rb` (1.5.0) fills in `Layer0` from `object_class`, ten classes to ten tags taken from the contract's own enum, and refuses three things: a body that is not ours, a body already carrying a UCON tag (`Placeholder (not ours)` is a statement of OWNERSHIP, not of class, and re-tagging it would put a client's fridge on a sheet as if we sold it), and an unknown class. **The generator does NOT tag at build - Andriy, 2026-08-29** - because that decision would land in twenty call sites. **The tag GROUPING and the SCENES are deliberately not the engine's**: grouping differs per sheet and SketchUp has folders for it; the scenes get one elevation built by hand first, same reasoning as the worktops. Account: `claude/findings-2026-08-29-layout-prep.md`. **OPEN, and it bites LayOut specifically:** the model is open out of the Trimble Connect cache (`.../SketchUp 2025/SketchUp/.tc/<uuid>/cache/...`), and a LayOut document holds a PATH to its .skp. Where LayOut takes the model from is not decided. **IT RAN, 2026-08-30, and the model is now controlled by tags.** 57 bodies onto five tags - Cabinets 35, Panels 11, Fillers 7, Shelves 3, Appliance fronts 1 - with the two tags the generator had already set left alone and the nine bodies that are not ours untouched on `Layer0`, which is both refusals doing their job. A second run over the result reports 0 moves and 60 kept, so the pass is idempotent in the model and not only in the suite. **AND WITHIN THE HOUR THREE BODIES WERE BACK ON `Layer0`** - a `DZ731Q` side panel, an `MNS022038` shelf and a rebuilt `PF0151`, all built after the pass. Retag is a pass over the model, not a rule about it: learned rule 19, and `core/66_retag.rb` carries the same note beside its own design argument. **Re-run it as the last act before any sheet.** |
| **The first stone** | **THREE PIECES DRAWN 2026-08-29, NONE STAMPED, and Elda Q28 finally has a price.** All 40 thick at z 880..920, so `TOPDR008040`. `Group#3` 874,3 x 645 - a true rectangle, band **650**, 5 mm of the band paid for and not drawn: orderable as drawn. `Group#2` 2444 x 663 - also a true rectangle, but **650 REFUSES** (663 > 650 + 1) and the smallest band that takes it is 700, at 37 mm unused; the 663 is an 18,5 mm BACK overhang on the island against 0,5 at the front, and there is no band between 650 and 700, so that edge decides the order. `Group#4` - **an L**: bounding rectangle 1903 x 3786,8 = **7,206 m2**, real surface **3,012 m2**, six vertices. **THE BOUNDING-RECTANGLE ORDER COSTS 4,195 m2 HERE - 58% of the sheet** - where on both straight pieces it cost nothing, measured to three decimals. That is the Q28 question with a number on it. It is refused anyway at 3787 against the 3140 sheet, and cutting it into rectangles at the corner fixes both at once; the joint is Q27. **THE COVERING PASS MUST MEASURE THE CARCASS, NOT THE INSTANCE BOX** - the first one read four covered island units as 53% because an instance box carries the PLAN SYMBOLS and a drawer's travel runs ~549 mm out in front (Drawing_Spec puts it on the floor). Measured on carcasses the whole model comes down to one line: `B70150` at 87%, a **15,2 mm** strip against the wall. That requirement belongs to the covering report `62_top_stamp.rb` still owes. Tool: `tools/probe_top_measure.rb`. Account: `claude/findings-2026-08-29-the-first-stone.md`. |
| **Registry** | **939 codes**, **84 sections in the manifest**. **+2 on 2026-08-28: Linear Elements printed p.110, the 4 and 6 cm CERAMIC TOPS** - `registry/cesar/tops_ceramic_linear_elements.json`, the first `object_class: worktop` this engine has ever held, extracted on demand because 545 Avenida Primavera needs worktops. **They bring a grammar nothing here had**: one code spans FIVE finish groups and EIGHT depth bands, so **the code does not determine the price** - the group is an order axis under domain rule 6, carried in `points_per_lm_by_group_and_band`, named for both axes so nobody reads it as one. And the DEPTH comes from the order like the sheets' width and height, except that it is a **closed list, not a range**: `Registry.with_ordered_depth` refuses 660 rather than rounding it to 650, because a band is an overhang and a price. The bands sit 30 mm above this book's carcass depths and the section says out loud that this is an observation, not a printed rule. Thickness is on `height_mm` - a top is thin on Z where a sheet panel is thin on Y. Recorded and NOT resolved: the price table says max length 314 cm, the same page's text says 319 for MDi Inalco; **3140 held**. Only p.110 is extracted - p.104 (1,2) and p.107 (2,2) are the same grammar at other thicknesses and their headings are identical, so THICKNESS is what tells the three pages apart. Before that: **924 codes** in **57 section files** carrying **37 catalog sections**, and **for the first time they are not all one book**. **+44 on 2026-08-27: Linear Elements printed p.215-220, panels priced BY THE SQUARE METRE**, minimum 0,5 m2, ten blocks, `registry/cesar/panels_linear_elements.json` - held not buildable and **RELEASED THE SAME DAY at 0.90.0** - the ten blocks carried one refusal in one wording precisely so a single edit would clear all of them, and it did. **And the picker can order one as of 0.91.0**: an H field beside the W, three arguments to `sketchup.build`, and a `sheetGrid` whose columns are thicknesses and whose buttons carry the price group and the faced sides - a sheet has no width, no height and a depth that is a thickness, so nothing else tells its codes apart. **Untried in the dialog**: HtmlDialogs bake their HTML at open, so the palette has to be closed and reopened, and nothing headless can press a button. `source_pdf` is a PER-SECTION fact as of the same commit (owed 14, closed): the manifest's value is now only the default, and a check walks all 924 rows to prove no code cites the wrong volume. Earlier: **880 codes** in **53 section files** carrying **36 catalog sections**. **+124 on 2026-08-26 evening: the adjoining end side panel, 2.2 cm thick, in all three collections** - Maxima-Intarsio (printed p.440-441, 76), N_Elle (p.444-445, 24) and N_Elle with framed door (p.446-447, 24). Taken all three at once ON PURPOSE: which collection this kitchen is remains an Elda question, and holding the files makes the answer a picker choice instead of a day of extraction. Earlier the same day: +3 glass wall H.96, +1 wall filler H.96. |
| **`_to_delete/`** | **GONE, and the correction is the point.** It was TRACKED, not untracked: two files lived in `HEAD` and their deletion sat unstaged while an earlier version of this cell said the directory was 'not part of the repository's state at all'. It was. `a105069` committed the deletion. The wrong sentence is recorded here rather than removed, because it is why the working-tree cell is now read from `git` and not from prose. |

| **The probe bridge** | **NEW 2026-08-25, `tools/probe_bridge.rb`, dev tool only** - nothing in `src/` requires it and it is never in an `.rbz`. It polls `tools/probe_inbox/`, runs what appears there, and writes `tools/probe_outbox.txt` and `tools/probe_log.txt`, so a question about the open model can be asked and answered without Andriy typing a `load` line for each one. **ITS ROLLBACK IS NOT A GUARANTEE AND THE FILE NOW SAYS SO**: a probe that calls `Generator.build` commits an operation of its own, that commit closes the bridge's outer one, and everything the probe does afterwards sticks. Measured, not reasoned about - `07_wall_h222_build.rb` applied in full while unarmed on 2026-08-25. The detector was fixed at the same time: it compared `model.modified?`, which is already true in any model anybody has worked in, and now compares entity count, definition count and summed instance origin. |

### The Project is retired

`claude/` was moved out of the claude.ai Project on 2026-08-24 and pushed as
`a775846`. **Twenty of the twenty-one originals were then deleted from the
Project; the repository is canonical.**

**What is in the Project now is not repository material, and moving it in
would be a mistake.** Corrected 2026-08-24 evening by Andriy, after a session
proposed exactly that move. Two of the documents there —
`handoff-<date>-<machine>.md` and `spec-<date>-<subject>.md` — are **the
instructions a Cowork session is started with**: they are addressed to Claude,
they are rewritten as the work moves, and they are read BEFORE the repository is
reachable. The repository is where findings and decisions live; the Project is
where the next session is told what to do. **Do not copy them into `claude/`.**

**One repository document was deliberately kept there too:
`elda-mini-order-2026-08-20.md`.** The
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

**EXTRACTION IS PAUSED, and that is a decision, not a gap.** On 2026-08-24
Andriy opened the real Avenida Primavera kitchen and said: only what this
project needs. That is the demand-driven discipline CLAUDE.md describes, working
as intended - the roadmap is a MENU, and the kitchen picks from it. The first
thing it picked was the corner, and the corner took two commits: `14158a5` was
wrong and `3652298` reversed it. **Do not resume the extraction queue below
without asking.**

Four things the real kitchen has asked for so far; three are built and the fourth
is built headless and untried in the model:

1. **DONE, and the first answer was wrong — the corner front gap.** The fronts
   of two runs missed each other at an inside corner by `FRONT_GAP_MM`.
   `14158a5` moved the SEATING and was wrong. `3652298` moved the FILLER, which
   is the body that had to move: **the printed 8x8 is a NOMINAL, and the leg
   that runs along the width is drawn at `FILLER_MM - FRONT_GAP_MM` = 77,
   because it meets a front and not a carcass; the return leg meets nothing and
   keeps its 80.** The node seats **raw** at `nominal - carcass` again, which is
   what Cesar's own SketchUp export of estimate 2026/30831 does. Account, dated
   and added rather than edited: `docs/Drawing_Spec_v0.1.md` → *"CORRECTED THE
   SAME DAY"*. **The front gap therefore lives in the filler leg
   (`60_generator.rb`), NOT in `Placement.corner_origin`** — any note that says
   otherwise was written before the correction.
2. **DONE, with the order side deliberately left open — the dishwasher plinth**
   (`13e7754`). The panel now carries a **drawn** plinth box and its phantom
   housing starts on top of it, so the plinth LINE runs unbroken across a LayOut
   elevation. That is a *representation*: the real plinth in front of a machine
   is cut away, and what the warehouse must be asked for is a plinth **with a
   cutout**. **Deferred, not decided.** Mechanically this is why
   `plinth_continues` and `appliance_niche` are now read from the **unit type**
   first and the family only as a fallback — family H.78 is three merged files
   and 131 base units, so there was no way to say it about one object.
3. **DONE, and half of it is still untried - placement infers its direction**
   (2026-08-24). `Placement.side_beside` is pure and carries eight checks:
   both sides free grows RIGHT as it always did; attached on the right grows
   LEFT; attached on the left grows right; **both attached refuses** with a
   sentence for the person holding the mouse. Attached means TOUCHING, at
   `SNAP_MM` - the same distance at which the place tool closes a joint, so the
   two rules can never disagree about what "next to" means. A corner on the
   right occupies its NODE, wasted space and all. **It applies to fillers
   exactly as to cabinets**: `with_ordered_width` turns the catalog range into
   a number before anything is drawn, so a 50 mm strip reaches the placement
   with a width like any other element.
   **Both sides taken does NOT refuse** (Andriy, 2026-08-24, after trying it):
   the rule still reports `:blocked` because that is a fact, and the generator
   builds on the right anyway - a unit in the wrong place can be dragged, a unit
   that was never built has to be asked for twice. Rule states, caller decides.
   **THE TURN AT A CORNER IS BUILT** (2026-08-24, same evening, after Andriy
   tried the straight version and said "rotate 90 counter-clockwise and it goes
   up against the 8x8"). A corner's two ends are not alike: the 8x8 end is where
   the run continues STRAIGHT - its width leg is drawn at 77 precisely to meet
   the next front - and the WASTED end faces the perpendicular wall, so the run
   turns there. `Placement.corner_turn_seat` puts the new element back to that
   wall and shoulder to the 8x8, at +90.
   **It is measured, not derived.** His own kitchen already held the turn,
   placed by hand: `AU110D` at (620, 250) turned 90, `B80501` at (1153, 620)
   turned 180 - offset (370, -533) and a further +90 in the corner's frame. Both
   halves mean something and a check holds both: `span_low + run_depth` puts the
   FRONT on the run's front line, `-(new_width + 83)` puts the near end on the
   8x8's outer face, 83 being `FILLER_MM + FRONT_GAP_MM`.
   **CORRECTED THE SAME EVENING (rule 9, and it is the day's second instance of
   the same shape).** The first version used the NEW element's depth, so a
   cabinet turned correctly and a filler was pushed back onto the wall - "along
   the wall, not along the front". `B80501` had hidden it: at 620 it is exactly
   as deep as the corner, so both readings gave 370 and the wrong one fitted.
   **One measurement, two readings — the same trap as the 8x8 on 2026-08-24
   morning.** A unit is drawn from its origin FORWARDS, so the origin is the
   front edge whatever the depth; the run's depth is what belongs there.
   `B70501` at d.350 standing in the 620 run with its back 270 off the wall is
   the independent witness, and a check holds that number.
   **THE MIRROR IS NOT MEASURED.** A left-execution corner wastes its high end
   and turns at -90; no hand-placed example exists. A check proves it reflects
   rather than guesses. Measure one before trusting it.
   **The SketchUp half has now been RUN, not merely read** (2026-08-24 evening,
   in the model, by Andriy): the side rule, the filler, and the turn at the
   corner all behave. `Generator.placement_side` still carries no headless
   check - it needs SketchUp - so a future change to it is unguarded and has to
   be tried in the model again. What has NOT been tried is a rotated run: left
   and right are the SELECTED unit's, not the world's, and nothing has proved
   that on a wall drawn at an angle. Avenida Primavera has two of those.
   Stepping LEFT steps back by the NEW element's own width, which is why
   `placement_transform` now takes it; without it the run continues right, as
   before.

4. **BUILT HEADLESS, UNTRIED IN SKETCHUP — B6, the run gap** (2026-08-25 late
   evening). A range stands BETWEEN two runs, not inside an opening, so its page
   prints a width and nothing else; `place_set` skipped it and 1219 mm of the
   south run was marked by nothing. Now: the appliance layer answers with the
   printed width (`Appliances.run_gap`, pure, and it REFUSES rather than
   defaulting when the caller states no run depth — 610, 620 and 635 are all
   live here), the engine asks through the existing seam
   (`ApplianceCheck.run_gap`), and the ENGINE draws
   (`Generator.build_run_gap`), because a reservation nobody can see is worse
   than an empty gap and only this tree may write this contract. §11's arrow is
   untouched: the engine asks, the appliance module answers, and nothing in that
   tree calls this one. Decisions: `claude/appliance-rules-decided.md` §12; the
   alternatives that were rejected: `claude/plan-2026-08-25-b6-run-gap.md`.
   **The depth and the top are MEASURED off the unit beside the gap** — the
   command refuses without a selection instead of choosing a number.
   **The export prints reservations BESIDE the order, not in it** — a factory
   must not receive a line nobody can make, and a person must see the hole.
   That is decided against `docs/Reserved_Void_Spec_v0.1.md` §3, whose sentence
   is left standing because it is the half of the argument the new block keeps.
   **IT HAS NOW RUN IN SKETCHUP, and the run corrected it twice** (2026-08-25, late
   evening, the south run of Avenida Primavera):

   - **the package was 0.1.1 and the engine was current.** `undefined method
     'run_gap?'` — the engine is loaded from the repository by a dev loader and
     `Reload core` updates it in a second, while the appliance package is an
     installed `.rbz` copy that moves only when somebody rebuilds it. The seam now
     answers that with a sentence naming `tools/build_rbz.rb`, because an installed
     package that is too old is a STATE, like an absent one, and not a Ruby error.
   - **the height was the carcass and should have been the finished run.** The
     reservation stopped at 880 — the top of the neighbour's body, honestly measured.
     A gap in the run is a gap in the FINISHED run: **920 = 880 measured + 40 stated
     for the worktop**, and the range's own 928,4 stands 8,4 proud of it. The worktop
     is not drawn in this model — no `object_class: worktop` anywhere, every base unit
     tops out at 880 — so it CANNOT be measured, and it is now a project number kept
     on the model (`core/08_project.rb`), stated once in the palette. The object says
     which of its numbers was measured and which was declared.
   - and `selected_top_mm` stopped measuring the INSTANCE, which carries the opening
     symbols too, and now measures the `CARCASS` box.

   Three readings of the drawn reservation — attributes, seat, world bounds — agree to
   the millimetre, and it sits where `48 WOLF` stands (x 1903,0…3122,2 measured against
   1904,0…3123,0 drawn; the guide prints 1219 and the gap is 1219,2).

   **And a second thing fell out of the first check** — `EC3050TE/S`, a coffee
   system that IS built in, publishes a width and a depth off p.86 and no
   height, so "width and no height" alone called it a run gap. The rule now also
   requires NO DEPTH, and the coffee system, which used to reach the housing
   builder and come out **a box zero millimetres high**, is refused by name.
   Recorded as **B7**.

### Owed — carried in from the 2026-08-24 handoff

0. **HORIZONTAL THIN IS HELD AND NOT DRAWN, and it is the first object that
   envelope-only geometry cannot represent.** Four codes, printed p.459, in the
   registry and out of the drawing. A framed open module has no volume: the
   generator gave it one and Andriy called it what it was - *"мы сделали
   параллелепипед, это никак не полка"*. **The first time domain rule 4's own
   exception fires** - the source states the interior and the drawing needs it.
   Two ways forward and **the choice is Andriy's**: read p.458's three views and
   generate, or take a SketchUp body he builds by hand as the spec and write the
   script from that. It also wants a fourth `geometry_kind` and two materials on
   one object. Everything already read off the page is in
   `claude/findings-2026-08-27-horizontal-thin-is-not-a-box.md` so nobody renders
   it twice.

Not numbers, but the things a next session would otherwise re-derive. A line
leaves this list when it is done, not when it is mentioned.

1. **The warehouse side of the plinth** — a request for a plinth with a cutout.
   Deferred by Andriy, who is informed.
2. **`"cutout for plinth 40"`, printed p.47 and p.48 — still unread.** A
   plausible home has been found (40 mm out of the plinth in front of the
   machine) and plausible is not printed: rule 1. Elda question, not urgent by
   Andriy's decision.
3. **Corner handedness — Elda Q7, and the data still says the old thing.**
   `base_corner` carries `handed: true` and its disposition still describes two
   independent axes, but the door hand is derived from the D/S execution letter.
   Touches `50_registry.rb`, `60_generator.rb`, `80_panel.rb`.
4. **Layer 3 of the Elda work** — FRN fronts as their own order lines,
   composition-scoped companions, and the wine-cooler door being `FRN…` rather
   than `CR96xx`.
5. ~~**The Elda draft email is written and unsent**~~ — Gmail thread
   `1a0252a76b71d5d0`, draft `r-9182472239550867935`. **PARKED ON PURPOSE
   2026-08-27, and it stops being a pending job.** Andriy's plan: finish the
   kitchen, produce the drawing, send THAT, and diff our extraction against the
   Metron estimate that comes back. A priced line names an article, a quantity
   and a surcharge for a thing we also drew, and this project has been corrected
   by such a line twice already - 2026/30831 named `DZAK22` and `DZAC00` while
   this repository was calling them codes with no article behind them. The
   questions do not expire and will be sharper for having a real order beside
   them. **Which ones the estimate can and cannot reach is written out** in
   `docs/Elda_Open_Questions_v0.1.md` -> *How these get answered*, including the
   three it lost today: Q20-Q22 are about Volume 2's end panel, and this kitchen
   stopped ordering one the moment the island's ends became Volume 3 sheets.
6. **The wording of the FIRST `contradicts` line in `_manifest.json` — the
   corner filler measured from the carcass plane, our 703 against the factory's
   700.** It still ends `NOT YET FIXED`, which was true when it was written and
   now reads as a pending job. `docs/Drawing_Spec_v0.1.md` and the teardown
   both settle it the other way: **it is a recorded divergence, deliberately not
   fixed** — two defensible readings of an 8x8 panel differing by exactly the
   gap, and it does not affect whether the fronts meet. Left as it stands
   because a `contradicts` line is factory-confirmed data and rewording it is a
   content decision, not a stale number. **Andriy's call.**

7. **`wall_hung` is recorded per TYPE, and the catalog prints the glyph per
   DEPTH BAND.** Nothing is wrong today: on printed p.111 the first position
   carries the symbol beside both d.35 and d.62, re-verified on a 175-dpi
   render 2026-08-24, and every held code agrees with its type. But the schema
   cannot say *"hung at d.35, refused at d.62"*, and this catalog has already
   proved twice that it states availability per POSITION rather than per family
   — the pictogram sweep, and `tall_two_doors` hung at H.138 and refused at
   H.210 on facing pages. The day a page splits the answer between depths, a
   boolean on the type will silently pick one of them. **Not urgent — no held
   code needs it, and no page read so far splits it.** Found while answering
   whether `CR0631` (600 × 2100 × 620) may be hung. It may: the limit the book
   prints is not a size but the fixings — 240 kg per pair, `989410` two for a
   base, `989411` four for a tall — and the weight of a loaded cabinet and the
   wall behind it are site questions the catalog never answers.

8. ~~**Four things the appliance seam found in what the engine DRAWS today, all
   four undecided.**~~ **CLOSED 2026-08-26** — three decisions and one Elda
   question (Q18). Account: `claude/findings-2026-08-26-seam-findings-closed.md`;
   the decisions are `claude/appliance-rules-decided.md` §13. The original text
   is kept below rather than deleted, learned rule 9. Account: `claude/findings-2026-08-25-appliance-seam.md`.
   (a) `usa_tall_h210` draws its housing from the **plinth top** to 2133.6, so
   the top is the right 84 in from the floor and the OPENING is 100 short;
   (b) `NICHE_DEFAULT_DEPTH_MM` 620 is shallower than a Designer column's 635;
   (c) `niche_attributes_for` takes `width_mm` from the **Cesar door code**, and
   for built-in refrigeration the required cutout is 13 NARROWER than nominal in
   a standard install and 51 WIDER flush — one number cannot be right for both;
   (d) nothing is drawn in the 66-73 left above a housing in a 2200 run, where
   the rules call for a filler or an open shelf, set back 55.
   **No geometry was moved.** Each is a drawing decision, not a typo — (a)
   reverses a deliberate 2026-08-22 choice, and (b)/(c) would mean a Cesar unit
   cannot be drawn until a machine has been named. The seam reports; Andriy
   decides.

9. **THE MODEL IS NOT RECOMPUTED WHEN THE ENGINE CHANGES**, and on 2026-08-26
   that cost two corrections in one day — six `SD0631` kept fronts of the old
   size, and the east fridge panels were built by a probe the engine cannot
   reproduce. **Both were spotted by Andriy looking at a sheet, not by a check.**
   Nothing in the suite can see a stale model. Until something can, a change to
   the generator means the affected objects must be rebuilt by hand.
9b. **THE HOOD HAS A RESERVATION AND IT IS UNTRIED IN THE MODEL** (2026-08-28,
    core 1.1.0, contract v2.4). `Generator.build_wall_reservation` + a palette
    button; the appliance module answers with the envelope off Wolf printed
    p.141 and REFUSES on the mounting height, which p.144 prints as a RANGE
    (762-914 above the countertop). Headless-green and never drawn - the same
    place B6 stood before its first run, and for the same reason: **the
    installed package is 0.2.0** and the seam correctly refuses against it.
    Order: install `ucon-appliances-0.3.0.rbz`, restart SketchUp, `Reload core`,
    select the range's run-gap reservation, reserve the hood. Account:
    `claude/findings-2026-08-28-appliance-placement.md`.
    **AND THE 48_Core LIST IS NOW CHECKED AGAINST THE MODEL** (probe run 62):
    fridge drawn, range reserved, **dishwasher drawn and its machine never
    named** - `V80630`'s niche still says "client-supplied" - and the hood
    absent. The dishwasher's `plinth_top` datum is NOT a missed call site: it is
    the 2026-08-24 drawn-plinth decision, and `usa_tall_h210`'s `floor` is the
    2026-08-26 fix, and from inside the seam the two are indistinguishable.
    **Andriy: not touched.**

10. **The engine cannot rebuild the east fridge bay.** Its panel table lives in
    a probe (`build/45`), and it belongs in `appliances.json` behind the seam —
    which means the first `.rbz` rebuild since 0.2.0.
    **THE REBUILD HAS NOW HAPPENED for other reasons - 0.3.0, 2026-08-28** (the
    three ADA openings and the hood envelope), so the cost this line warned
    about is paid and the east fridge panels are no longer behind it. What
    remains owed here is the panel table itself.
11. **`48 WOLF` is a mute body**: a component in the model carrying no contract
    at all, so every walk skips it and every audit under-reports.
12. **The LayOut sheet that carries Q11-Q23 to Elda** is not drawn. Two of those
    questions are marked *blocks a live drawing*.
13. ~~**The island is not drawn.**~~ **ITS BACK AND ENDS ARE, 2026-08-27** -
    six `DZAK22` measured by probe run 56, and **both `YU0028` deleted**: the
    island is finished ENTIRELY from Volume 3, because the Kitchen System prices
    an end panel by cabinet height and has no 880 at d.645 in any collection.
    Still back-to-back-free, so the paired depth groups still serve nothing.
    **CLOSED 2026-08-28: THE ISLAND IS WOOD.** Run 71 applied and run 83 verified
    it by reading the model - zero DZAK22, four DZ731Q backs and two DV731Q ends,
    group A First (the oak group), drawn thickness agreeing with the attribute on
    all six, and the ends at 663 flush with the backs' outer face because the back
    went 22 -> 18. The finish NAME is still unchosen and is an order field.
    Account: `claude/findings-2026-08-28-panels-the-letter-is-a-lookup.md`.
    Original, kept (learned rule 9): the material is undecided and the code in the
    model is lacquer where it will be wood (a different page, a different
    thickness, and the grain direction IS the code); **the breakfast top at 30
    inches is not drawn** - there is no `object_class: worktop` anywhere, so the
    surface the whole slot is built around exists only as a gap; and the panels
    were dragged into their courses by hand, which no placement rule reproduces.
    Account: `claude/findings-2026-08-27-island-back-built.md`. Original:
13. **The island is not drawn.** Probe run 48 measured it: nothing in the model
    stands back to back, so the back-to-back end panels have nothing to serve
    yet.
14. ~~**Volume 3 cannot be extracted until `source_pdf` is a per-section fact.**~~
    **CLOSED 2026-08-27**, and by the work it was blocking rather than ahead of it:
    the island's back panels needed the chapter, so `source_pdf` moved onto the
    section, `Registry.lookup` and `Registry.catalog` both name the book, and a
    check walks every one of the 924 rows. The original text is kept below
    (learned rule 9).
    **AND IT LEFT A NEW ONE. A companion whose quantity comes from the RUN has
    no expression in Contract v2 §4.2.** printed p.214 prices the panel fixing
    kit PER BASE UNIT WIDTH - four 600 units behind TWO 1200 panels take four
    kits - so it cannot hang off the panel as a `companion_ref`, which would
    count two. Held in `_manifest.json` under
    `hardware.linear_element_panel_fixings` and visible rather than invented.
    **AND A SECOND, FOUND BY THE ISLAND'S OWN ORDER: the lacquered sheet is
    recorded width <= 1200, height <= 3000, straight off the drawing's 120 x
    300.** For VENEER that fixing is right, because the grain direction is in the
    code and the board has an orientation. For lacquer it almost certainly is
    not - a 2400 x 116 board would be cut along the three-metre axis and no
    printed sentence forbids it. So the engine would refuse a panel the factory
    can make. Elda question or UCON decision; not fixed silently.
    **Original:**
14. **Volume 3 cannot be extracted until `source_pdf` is a per-section fact.**
    `Registry.lookup` reads it once from `_manifest.json` for the whole
    registry, so the first Linear Elements code held today would cite the
    Kitchen System as its source. Small change, real one.

*(The item that stood here — moving the Project's handoff and spec into
`claude/` — was wrong and was removed the same evening. Those two are session
instructions, not repository documents; see "The Project is retired" above.)*

### When the extraction resumes

**Base H.84 — printed p.49-56**, which DOES need discovery: `BK` / `BL` /
`BM` were swept out of the filler table and **which letter is which depth has
not been read**. H.48 and now H.58.5 are the warning — `BC` / `BQ` / `BD` and
`B3` / `B6` / `B4` are both out of depth order — so nothing about H.84 can be
assumed from the alphabet. Its plinth is 60, not 100.

**Nothing is owed before it.** The printed p.19 pictogram sweep — the oldest
debt in the registry, `claude/debt-2026-08-24.md` §3 — **was done on
2026-08-24**: ten pages, 146 held codes, no availability changed, six positions
gained the hob mark, and every non-wall cabinet type now states `wall_hung`
explicitly so that an absent reading is a failing check rather than a shrug.
Account: `claude/findings-2026-08-24-pictogram-sweep.md`.

### Sections held

| section | printed | held | left |
|---|---|---:|---|
| Base units H. 39 | 24-27 | 48 | p.26 and p.27 **stopped** — a height the page will not name |
| Base units H. 48 | 28-31 | 30 | p.29-31 |
| **Base units H. 58.5** | **32-34** | **53** | **none — the section is whole** |
| **Sink base units H. 58.5** | **35** | **24** | **none — the section is whole** |
| Base units H. 78 | 36-43 | 131 | p.41 (grammar unread), p.42-43, p.46 (corners, Q7b) |
| **Tall H. 210 \| for base unit H. 78** | **116-125** | **12** | **p.117-125 — and p.121-123 + p.125 are the appliance columns Avenida Primavera needs** |
| **Fillers, first position** | **434** | **9 of 12** | **BE0151 (H.60 — no such base section in the printed index), BK0151 (H.84, family unextracted), CH9151 (H.278, no family anywhere)** |
| Base H. 78 \| appliances | 47-48 | 9 | the induction-hob protection |
| Sink base units H. 78 | 44-46 | 20 | |
| Tall units H. 138 | 90-96 | 16 | mechanisms, corners, appliance housings |
| Tall units H. 198 | 97-101 | 14 | same |
| Tall units H. 210 | 111-115 | 14 | same |
| Tall units H. 222 | 132-136 | 14 | same |
| Tall units H. 234 | 151-155 | 14 | same |
| USA \| tall H. 210 | 418 | 8 | |
| Closing strips and fillers | 434-435 | 6 | |
| **End elements for Maxima-Intarsio** | **436-441** | **76** | **p.436-439 - the L-shaped end panel and its three grip-recess variants, which need an L profile in `30_geometry`** |
| **Adjoining end side panel for N_Elle** | **444-445** | **24** | **none - both pages whole** |
| **… for N_Elle with framed door** | **446-447** | **24** | **none - both pages whole** |
| the thirteen wall sections | 211-254 | 291 | one unread page (p.212) and twelve corners |

**Held and NOT buildable, registry-wide: 23.** Two fillers with no printed
depth, thirteen base units, six appliance panels, and **two compact-oven
housings on printed p.34** whose front height the appliance decides. **Nineteen
still wait on ONE decision** — `door_versions` is a family key — and a check
requires all nineteen to name that reason in the same words, so the backlog is
one grep.

**Fifty-two codes refuse the hung version: 4 base and 48 tall** (46 until
printed p.116 arrived on 2026-08-24 and brought six more, none of them a flip —
the check's comment carries the arithmetic) — and the
figure is now COUNTED BY A CHECK, not by hand. It read *twenty-two* here this
morning, which had counted the tall families by position instead of by code.
**Four of the forty-six refuse in WORDS** — printed p.34 and p.37 — and the
other forty-two only by a missing glyph and a missing margin line. An absence
has to be re-read; a sentence does not.

---

### The commit chronicle has moved

**`claude/commit-chronicle-2026-08.md`** holds the day-by-day tables for
2026-08-22, 23 and 24, verbatim. They were eighty lines of history in the file
that every session reads first. For anything newer, `git log` is the source and
this file never transcribes a sha.

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

And, from the pictogram sweep:

> **A positive reading has to be recorded as a positive reading.** For six days
> a type with no `wall_hung` key meant EITHER 'the catalog offers it' OR
> 'nobody looked', and that ambiguity had already shipped six H.210 codes with
> a version the catalog does not sell. The sweep changed no value and fixed
> that: 54 types now state the reading, and a check makes silence a failure.

And, from H.58.5:

> **A door version can be an ARTICLE fact.** printed p.32 draws ONE elevation
> over its pull-out door and two over every other position on the page, where
> the same position at H.78 draws two. `door_versions` is a family key, so the
> panel offers a 55,5 the page has never printed. Elda **Q8**, and the same
> axis the 19 not-buildable H.78 codes wait on — one answer settles both.

And, from the corner at Avenida Primavera:

> **A symptom can point at two bodies, and the easier one to see is not
> necessarily the one that moved.** The fronts missed by exactly
> `FRONT_GAP_MM` — a constant that appears in BOTH the seating and the filler
> leg, so the symptom could not name which was wrong. The first fix moved the
> seating. The measurement that settled it, the factory's own SketchUp export,
> had been in hand for an hour before anyone opened it. **When a constant lives
> in two places, only a measurement says which one is the bug.**

And, from the dishwasher panel:

> **DRAWN and ORDERED are two facts, and a drawing must never be allowed to
> imply an order.** The panel draws a plinth so the elevation line runs
> unbroken; the warehouse must still be asked for a plinth with a cutout. The
> engine now says so **on the object itself**, because a raised housing that
> stays silent gets read as a measurement.

Full accounts: **`claude/findings-2026-08-23.md`** (H.96, H.120, base p.37-38,
p.48, Group 0), **`claude/findings-2026-08-23-tall.md`** (the five plain tall
families), **`claude/findings-2026-08-24-base-column.md`** (the base prefix) and
**`claude/findings-2026-08-24-h58_5.md`** (H.58.5, whole) and
**`claude/findings-2026-08-24-pictogram-sweep.md`** (the glyph debt, closed).
The second half of 2026-08-24 — the corner and the dishwasher plinth — is
narrated in **`docs/Drawing_Spec_v0.1.md`**, not in a findings note.

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

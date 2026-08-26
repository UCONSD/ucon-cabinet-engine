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

## As of 2026-08-26, late afternoon — owed 10, and the east fridge in the model

| | |
|---|---|
| **HEAD** | **`f79f18c`** — *a reveal nobody drew is deleted, and the fridge bay is drawn with no gaps at all (0.83.0)*, read after the push. Under it **`c05e90d`** — *the housing stands on the floor and the span above it gets a body — the seam's four findings become three decisions and one question (0.82.0)*, read 2026-08-26 late afternoon from `refs/heads/main`. Under it `063c373` (docs) and `da758d9` (0.81.0). **Read the ref; this cell is a reading and not a promise** — two versions of it were wrong within an hour on 2026-08-26. |
| **Pushed** | **YES.** `refs/heads/main` and `refs/remotes/origin/main` are both **`f79f18c`**, read 2026-08-26 late afternoon; the stranded `063c373` went out with it. Earlier the same day this cell said YES while a commit sat unpushed — **rule 16 caught its own author, so read the two refs, it is two `cat`s.** |
| **Working tree** | **ONE MODIFIED FILE**: `claude/findings-2026-08-26-east-fridge.md`, closing the last 2 mm. Everything else is in `f79f18c`. **Read it from `git`, never from this cell** — through the device mount `git status` can lag a write by a second. |
| **Core version** | **0.83.0, COMMITTED at `f79f18c`** — it deletes `FRONT_REVEAL_MM`, a locked standard that nothing ever drew. 0.82.0 at `c05e90d`: It moved a DATUM and drew a new body: the USA appliance housing starts on the floor instead of the plinth, and the remainder above it gets a filler that is an order line rather than a face. Shell **0.6.0**. **Appliances 0.2.0 — still untouched, and no `.rbz` has been rebuilt in any of this.** That is now a debt rather than a saving: see the east fridge row. |
| **Headless suite** | `tools/test_contract.rb` **464, 0** · `tools/test_appliances.rb` **68, 0** · `tools/test_appliance_seam.rb` **30, 0**. **All three ran under Ruby 2.6 before the commit and the commit script would not have proceeded otherwise** — `ruby 2.6.10 (universal.arm64e-darwin25)`, output in `build/run26-*.out`, which `.gitignore:29` (`build/`) ignores. So 2.6 is green at **`c05e90d`**, measured rather than assumed. |
| **The Avenida Primavera model** | **THE EAST FRIDGE IS BUILT AND THE ENGINE CANNOT REBUILD IT.** `CL4850SD/S/T` named, its opening drawn at the published 1206 x 2127 x 610, three UCON overlay panels placed at a MEASURED datum off the Sub-Zero guide, and `UCON-BESP-001` — a custom cabinet with one upward-opening door — closing the 313 above. All of it drawn by ARMED probe runs (`build/42`, `build/44`) and verified by a read-only one (`build/43`), because no command in the engine can produce any of it. Account: `claude/findings-2026-08-26-east-fridge.md`. **AND THE 2026-08-25 READING BELOW IS NOW OVERTAKEN, kept rather than deleted (rule 9): FOUR objects on the east wall now carry NO article** — the three UCON panels and `UCON-BESP-001` — and each of them says why on itself and reaches the order as *CUSTOM SIZE - NO ARTICLE, to be quoted*. That is the honest state of a kitchen whose appliance side is ahead of its catalog side, not a regression. What follows was true on 2026-08-25: ~~**NO OBJECT ON EITHER WALL IS WITHOUT AN ARTICLE**~~ as of 2026-08-25 late evening. The seven CUSTOM boxes became `SD0631` x6 (four at 610x600, two at 610x720 - width and height INCREASE, unprinted, Q11) and `SD0930` x1 cut to 770 (width REDUCTION, printed, 989370). Read back from the model, not from the list of what was built. The walls: SOUTH is the range, EAST is the fridge niche - and a verification probe called the east run WEST for one run because it mapped a `+x` back vector to the wrong side. The model's own names were right. |
| **Extensions** | **TWO, one repository**, and **both now RUN** (2026-08-25, SketchUp 2026, first time for the appliance one). `src/ucon_cabinet_engine.rb` + tree, `src/ucon_appliances.rb` + tree. Neither requires the other. **The engine is NOT copied into Plugins**: a one-line dev loader there requires the repository, so Extension Manager has nothing of it to uninstall — which is exactly how the copy was lost on 2026-08-25. Appliances stay an `.rbz` copy from `tools/build_rbz.rb`. One shared `UCON` submenu via `UCON.extensions_menu`. Design VENDORED from `design/panel_kit.css` by `tools/build_panel_kit.rb`; a hand-edited copy fails its own suite. Account: `claude/findings-2026-08-25-first-run.md`. |
| **Object Contract** | **v2.1**, one of the two named gaps closed (the `remainder`; see `docs/Reserved_Void_Spec_v0.1.md`), and **two rules that were confirmed and unwired are now wired**: a WIDTH REDUCTION reaches the object as a variant (Elda 2026-08-24, Q3 closed for width), and §4.2 rule 4's *never a silent deletion* is finally true of the exporter. **printed p.414's gap - a front whose WIDTH comes from the opening - is NOT closed**, and Q11 is its live twin: 610 has no article because nothing above it can be cut down. **Q11's disposition was corrected the same evening**: the engine DRAWS 610 rather than refusing it, because the LayOut sheet is how the question gets asked - the catalog prints reduction only, and the object says so in its own variant instead of the registry inventing an article. |
| **Registry** | **752 codes** in **50 section files** carrying **33 catalog sections** (711 at the start of the evening). Added in one sitting, all demand-driven: printed p.121-125 (+13), p.170 and p.173 (+10), p.143 (+4), p.172 (+9), p.162 (+4), and `BE0151` (+1). |
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
5. **The Elda draft email is written and unsent** — Gmail thread
   `1a0252a76b71d5d0`, draft `r-9182472239550867935`.
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

8. **Four things the appliance seam found in what the engine DRAWS today, all
   four undecided.** Account: `claude/findings-2026-08-25-appliance-seam.md`.
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

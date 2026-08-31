# UCON Cabinet Engine — status

Working context for future sessions on the SketchUp extension project.
**Read this first, then `claude/repo-state.md`, then `CLAUDE.md` in the repo.**

> ## MOVED INTO THE REPOSITORY 2026-08-24
>
> These notes lived in the claude.ai Project until 2026-08-24 and now live in
> `claude/` inside the repository, so that knowledge and code are versioned
> together. Cross-references of the form `claude/<name>.md` still resolve — the
> directory name did not change.
>
> ## WHAT CHANGED AFTER THIS DOCUMENT WAS LAST REVISED (2026-08-23 morning)
>
> The body below is kept as written (rule 9). These are the parts it no longer
> describes; the numbers live in `claude/repo-state.md`, as always.
>
> - **The registry went from 7 section files to 34, and from ~185 codes to 615.**
>   The whole wall chapter, all five plain tall families, base H.39 and H.48,
>   base p.37-38 and p.48 were extracted on 2026-08-23/24.
> - **Three new notes:** `claude/findings-2026-08-23.md`,
>   `claude/findings-2026-08-23-tall.md`,
>   `claude/findings-2026-08-24-base-column.md`, plus the measured
>   `claude/debt-2026-08-24.md` and the grouped
>   `claude/extraction-plan-2026-08-23.md`.
> - **Rule 18 has been applied seven times**, and two more rules earned their
>   place beside it — see the findings notes: *a reading that stays in a note is
>   a reading the engine does not have*, and *a check can only fail on what it
>   looks at*.
> - **printed p.19 carries a legend for two pictograms nobody had read.** The
>   "Hung version" glyph is a printed statement of a fact the engine derives,
>   and twenty codes now refuse the wall-hung option on that evidence — which
>   makes the "three types print not available wall hung" paragraph below an
>   undercount of the real rule.
> - **`Registry.catalog` is memoised** as of 0.68.0; it was rebuilt on every
>   call and the suite had outgrown it.

> ## Where the repository stands: **`claude/repo-state.md`**, and nowhere else.
>
> HEAD, core version, check count, whether the tree is clean, what is unpushed
> — all of it lives in that one small file, because those numbers change on
> every commit and this document does not. **Do not copy them here.** Same
> discipline as the Elda email state, and for the same reason: rule 13.
>
> **Email to Elda: state lives in `claude/elda-mini-order-2026-08-20.md`**, in
> its STATE block, and nowhere else. One line: positions 1–12 sent 08-21, the
> follow-up sends itself Monday 08-24 09:00 Italian time unless she replies
> first.
>
> Detail, newest first:
> **`claude/debt-2026-08-24.md`**,
> **`claude/findings-2026-08-24-base-column.md`**,
> **`claude/findings-2026-08-23-tall.md`**,
> **`claude/findings-2026-08-23.md`**,
> **`claude/extraction-plan-2026-08-23.md`**,
> **`claude/fillers-recon-2026-08-23.md`**,
> **`claude/plinth-and-wall-hung-2026-08-22.md`**,
> **`claude/finishes-and-price-bands-2026-08-22.md`**,
> **`claude/warehouse-architecture-2026-08-22.md`** (§8 added 08-23),
> `claude/contract-v16-companions-2026-08-22.md` (the SPEC is in the repo at
> `docs/UCON_Object_Contract_v2.md`),
> `claude/tall-units-recon-2026-08-22.md`,
> `claude/wine-cooler-aperture-2026-08-22.md`,
> `claude/usa-elements-recon-2026-08-20.md`,
> `claude/options-architecture-2026-08-20.md`,
> `claude/wall-units-recon-2026-08-18.md`,
> `claude/placement-tool-design-2026-08-19.md`,
> `claude/corner-units-m22-brief-2026-08-20.md`,
> `claude/picker-ui-backlog-2026-08-20.md`.

## What this is
Parametric SketchUp extension generating preliminary, catalog-coded placeholder
cabinetry from Cesar catalog data. Repo: `~/dev/ucon-cabinet-engine` (GitHub
UCONSD/ucon-cabinet-engine, private). Core hot-reloads (palette → Reload core);
the shell (menu, toolbar) needs a SketchUp restart; dialogs need close/reopen to
pick up new buttons or registry sections.

## The founding principle — why the drawings look simple

**The product is a printed drawing in CAD Drawings Style, for installers and
architects.** Cabinets are placeholders on purpose. **A handle is shown
schematically. A plinth is shown schematically.** Nobody draws every handle.

**But a simplified drawing does not mean a simplified ORDER.** They are two
outputs of one model:

- **Not drawn, still ordered.** The bespoke gola handle and its accessories are
  never embedded in the cabinet. They are collected aside — a hidden tag/scene,
  a small **warehouse** — and reach the order from there.
- **Drawer inserts are OPTIONS, not geometry.**
- **The plinth is the exception: its geometry STAYS VISIBLE.** Being drawn does
  not remove it from the warehouse; the two questions are independent.
- **And some things must be ANNOTATED, not merely stored.** The order forms say
  a per-element finish may be specified *"on the drawing"* — see the finishes
  note. The sheet is a consumer of project data, not only a picture.

## THE WAREHOUSE — recorded, piece half counted

Full account: **`claude/warehouse-architecture-2026-08-22.md`**. Two article
types, in Andriy's words: **штучные и погонные**.

- **By the piece — LANDED.** 8 cabinets → 8 handles. Implemented as **one
  handle per OPENING FRONT**, read off the registry's `front_layout`, which
  reproduces 8→8 and also gives `CR1230` two and `B80653` three.
- **By the metre — BLOCKED on Elda L1.** A running length must become *bars
  plus offcuts*, and no page prints a bar length.

**A correction worth keeping:** the first draft of that note claimed `um`
discriminates the two types. It does not — the estimate files the plinth under
**PZ**, sold by the piece and derived from a length. The note now carries two
crossing axes plus a third (ours to order vs Metron's to generate).

**§8, added 2026-08-23: a run element contributes a LENGTH, not a count.** The
filler is the first element that is almost entirely warehouse. Andriy's rule: the
plinth runs *under* it and the gola recess runs *above* it, **both are drawn, and
both enter the warehouse as погонаж whose length is the filler's ordered width**.
Neither is ever a piece — a filler must never put `qty 1` against a plinth or a
profile. Two consequences: `plinth_continues` for a base filler is **yes** and
the engine already draws it; and the filler's `GOL001` line is right as it
stands, because the exporter's null already says *"the running length of the run,
not of this unit"*. **The test worth writing first: if a filler needs a special
case in the aggregation walk, the walk is wrong.**

**Not built:** the aggregation itself. The per-object numbers exist; nothing
sums them. And **no unit carries a plinth companion line at all** — the plinth is
drawing-only today, and giving it an order line runs straight into Elda L2.

## THE ORDERED WIDTH — the third axis outside the code (0.55.x)

Full account: **`claude/fillers-recon-2026-08-23.md`**.

Printed p.434 prices **fillers and closing strips by HEIGHT alone**. One article
covers every width from **2,3 to 15 cm**, and the code never names one — so the
width is stated when the thing is ordered. **`order_axes_outside_code` now has
three entries**: `door_version`, `hinge_side` and **`filler_width_mm`**, and the
third is the first that is a **DIMENSION** rather than a choice from a list.

- The range is a catalog fact and lives on the row as **`width_range_mm`**; the
  row carries **no `width_mm` at all**.
- **`Registry.with_ordered_width(unit, width_mm)`** turns the range into a
  number. It **raises rather than defaulting** — a filler silently built at the
  bottom of its range would be a drawing nobody could tell was wrong.
- **`Generator::INSTANCE_KEYS` was NOT widened.** That guard says an object may
  not out-vote the registry about what article it is, and it must keep saying
  so. A filler's width out-votes nothing, because the catalog never stated it.
  A sentinel test refuses a width offered to `B80601`: 600 is final, and a
  narrower one is a *modification with a surcharge*, not a number typed into a
  dialog.
- **`Generator.effective` restores it on every REBUILD.** `Panel.apply` looks
  the code up afresh, and a filler row has no width — so the first filler to
  meet the properties panel collapsed its front. The restore is the mirror of
  `INSTANCE_KEYS` and must be read as one pair: **that overrides what the
  catalog said, this restores what the catalog never said**, and only where the
  row gives a range. Validated on the way in, so an edited object cannot smuggle
  a width the article is not made at.
- **The ORDER says so.** `unit_row` carries *"width is an ORDER choice, not a
  catalog size"* on any article whose registry row gives a range — asked of the
  registry, never trusted from the object.
- **The contract needed no change.** It validates the OBJECT, and a built filler
  has a real `width_mm`: the one the person typed.

**`filler` is a CLASS of its own in the picker and in `catalog_map`, and that is
OURS, not the catalog's.** printed p.434 spreads 31 codes over twelve heights
and over base, wall and tall alike — **the first page in this book that is not a
page of one family.** The rows keep their families, so a wall filler still hangs
and a base filler still stands on the H.78 plinth. **A filler may not be
extracted before its family**, or it silently inherits `Standards::PLINTH_H_MM`
instead of its own ground.

**Five of the 31 codes are held**: `B70150` (H.78), `PB0151` (Wall H.36),
`PD0151` (Wall H.60) — buildable; `B70151` and `CQ0151` — **held and NOT
buildable**, because the page prints no depth for a front-only strip and 2,2 cm
would be a guess (rule 8). They are the first unbuildable rows this registry has
ever held. *(2026-08-24: no longer the only ones — nineteen more joined them,
all waiting on the door-version axis.)*

**In the picker a ranged article is not a size grid.** Rows are depths and the
buttons carry the **height** — `PB0151` and `PD0151` are both d.35 and differ
only in height, so one row per code read as two identical rows. The width is
typed, with **5 / 10 / 15 cm** presets beside the box (5 cm because printed p.11
asks for a closing strip of at least that), and Build stays hidden until the
number is inside the range.

## THE EXPORTER — level 1, and the one null left

`85_export.rb` is pure (columns, the orderable rule, the hand as a variant
line, the handle count, the ordered-width note); `86_export_run.rb` is the
SketchUp walk. The palette button is `export_order` — **`export` is a JS
reserved word**.

The first real run was the most useful artefact of the day: **every companion
line shipped with an empty qty**, for two unequal reasons.

| line | why | state |
|---|---|---|
| `GOL001` gola profile | *"the running length of the run, not of this unit"* | **open** — waits on **M2.1a**; no single object can see a run |
| handles | *"one per front; not derived here"* | **CLOSED** — the count was readable all along |

Rule 7 held: unknown went out as `nil` with the reason beside it. **The honest
failure was also the to-do list.** *(And on 2026-08-23 the gola null turned out
to have been saying exactly the right thing about fillers too — see the
warehouse section.)*

It also caught a fake article: the panel had been emitting `GOL001+GOL002`, a
string that looks like a code. A sentinel test now fails if any joined
pseudo-code reaches an object or an order.

**Handle count scope (rule 4):** *ours*, not Cesar's. Every such row says so and
names estimate position 14 as what could confirm it; a test pins the note.

## THE PLINTH — a family fact, and zero is one of its values

`Standards::PLINTH_H_MM` is now only a **fallback**. The family states its own
`plinth_h_mm`: H.78 stands on 100, H.84 on 60 (Project Guidelines printed p.73,
p.82, p.90; N_Elle repeats both), so it follows the **height family**, not the
collection. `Generator.plinth_h_mm` asks the object; a test allows the constant
to be read in exactly one place.

*(2026-08-24: H.39, H.48 and H.58.5 all read 100, from the modularity diagram on
Project Guidelines printed p.68, render-verified. And every plain tall family
declares 100 as well.)*

**Zero is a real value, not a missing one** — the carcass on the floor, nothing
drawn. That is how the 5 mm shim foot is modelled: minimum design height 0,
maximum 5, and the 5 is **travel** for floor unevenness, spent on site. The
drawing shows zero, no gap. A UCON decision, not a Cesar statement; the number
5 is stored nowhere. Full account, including the four readings it took to get
there: `claude/repo-state.md`.

Declared in **one file per family** — `plinth_h_mm` is only in `base_h78.json`
though three files name H.78 — with a test reading it back through a code out
of each. **The filler files declare no family-level key at all**, and a test
enforces that too: a second copy would not raise while it happened to agree.

**The plinth runs under a filler**, at the family's own height, and its length
is the filler's ordered width. Drawn today; its ORDER line waits on Elda L2.

## WALL-HUNG — the first companion a person has to choose

Printed p.548 sells the wall-hung version of a base or tall unit as a surcharge
with fixings: **`989410`** base (2 fixings), **`989411`** tall (4), 240 kg per
pair. Nearly every base and tall price table points at it, so it is a standing
option.

**It is the first `origin: chosen` companion this engine can produce.** The same
article code is ordered whether the unit stands or hangs — the difference
travels as a separate line, so no rule can rederive it. The sweep asserting that
`attributes_for` never emits a chosen line **by itself** stays green and must.

Two defects had to be fixed to make it honest:

- **`mount_bottom_mm` ignored its argument** and always answered 1400, which
  would have hung a base unit at wall-cabinet height. It is two questions: a
  wall unit hangs by nature and how high is a project decision; a base unit
  chosen to hang shares its neighbours' worktop, so its bottom sits where its
  plinth would have — and the gap that opens is the plinth height, which is
  what the option is bought for. `Registry.lookup` now reports
  `mounting_default` beside `mounting` so the two stay distinguishable.
- **`Panel.apply` asked the catalog, not the object.** It looks the code up
  afresh, so a stored choice was invisible to the rebuild — a hung unit would
  have been redrawn on its plinth. `Generator.effective(unit, attrs)` overlays
  the instance's choices, and **only keys a person can set**: an object may not
  out-vote the registry about what article it is.

**A wall-hung base is NOT "without feet"** (Project Guidelines p.39): it carries
a stabilising foot at the bottom rear, bearing against the **wall**, which sets
the tilt. No floor contact, no plinth, but a foot exists and occupies clearance.

**Three types print "not available wall hung"** (printed p.34, p.37). **None is
in this registry** and those pages are not extracted, so the restriction is
recorded and NOT enforced — the flag is read anyway and proved on a synthetic
unit, so extracting the pages later is a data change.

> **SUPERSEDED 2026-08-23 (rule 9).** Two of those three are now extracted and
> carry `wall_hung: false`. More importantly the prose count was never the whole
> rule: printed p.19 names a per-depth-row pictogram, "Hung version", and its
> ABSENCE refuses the option without a word of prose. **Twenty codes now refuse
> it**, eighteen of them on the glyph alone. And the guard could not be reached
> from any data until 2026-08-23 — `Registry.lookup` never carried `wall_hung`
> out of the section file. See `claude/findings-2026-08-23-tall.md`.

**A filler is never offered it.** `wall_hung_available?` already refuses anything
that is not a cabinet; the filler is the first `object_class` to exercise that
arm, and a test says so.

## OBJECT CONTRACT v2 / v2.1

Authority: **`docs/UCON_Object_Contract_v2.md`**. v1 kept unedited with a
SUPERSEDED banner.

`companion_refs` is a **list of order lines**, one level deep; `variants` is a
new key. A line carries `code` (nullable), `qty`, `um`, `origin`
(`implied` | `chosen`) and optionally its own `variants`.

**Why v2 and not the "v1.6" it was designed as:** the contract's own §0 makes a
change to a key's allowed values a major version. A rule that is inconvenient
does not get reinterpreted quietly.

**v2.1 loosened `qty` to accept `nil`** — rule 7 landing in the schema.

**Migration:** `Contract.read` is the boundary and returns v2 shape whatever
wrote the object. The test that matters is *an old object stays editable*.
**Two traps, both pinned:** `JSON.parse('995626')` returns an Integer, so the
lift keys off the leading bracket; and presence must be decided on the logical
value before encoding, or `[]` persists as the String `"[]"`.

**`object_class` `filler` and `panel` were legal from the start and unused until
2026-08-23.** printed p.434 gave `filler` its first data and needed no schema
change to do it — worth remembering the next time a new kind of thing looks like
it needs a contract revision.

> **TWO GAPS FOUND 2026-08-24, and they are the contract's, not the pages'.**
> (1) `front_layout` has no NESTED kind, so a drawer band above two doors cannot
> be expressed and `Export.fronts_in` would count two fronts where the page
> prints three. (2) `door_versions` is a FAMILY key, so nothing can say that an
> article exists at 75 and not at 78 — nineteen held codes wait on it. Both are
> recorded on the articles and refused rather than guessed. See
> `claude/findings-2026-08-23.md`.

### Its prerequisite: the contract can erase (0.44.0)

`write!` used to skip keys whose value had become empty; every caller is
read-merge-write, so `hardware_ref` survived on a client-hardware object. It now
**reconciles**. This is what lets the wall-hung option be taken back: a unit
returned to the floor gets `mount_bottom_mm` deleted, not left behind.

## THE PANEL

**`Panel.selection_state(unit, attrs)` is pure; `push_selection` is glue.** A
grep test fails if `Sketchup`/`UI`/`@dialog` appears in the pure method.

It exists because of a live defect found off a screenshot: `push_selection`
called `gola_options` with **no unit**, so a gola drawer unit was offered one
profile instead of the PAIR — and the order silently lost the profile that
pairing exists to keep. The suite was green: its check called the helper
directly.

**Handle restrictions are data, not prose.** Lume `M00014` read *"with straight
grip recess system only"* inside its display name. It moved into `requires` with
`gola_system: "straight"`, the verbatim sentence and its page. **No filter was
built, and that is the finding** — the restriction is COMPOSITION-scoped and
waits on M1.6; a sentinel test says so.

**The plinth now has ONE writer.** `Generator.draw_plinth` returns nil when
there is no plinth, so `rebuild_plinth` can erase and redraw unconditionally. A
test counts the builders.

**A DEFAULT IS NOT A SOURCE.** `effective_slabs` and `gola_options` both turn a
missing `front_layout` into `single`, which silently invented a front for the
first object that legitimately had none stated. Every filler now states its
layout explicitly — one front, no `hinge_axis`, because a filler does not open —
the same way a US appliance panel states a front it never swings.

## RULES LEARNED THE HARD WAY — all enforced by tests

**Cite these as `learned rule N`**, never as a bare number: `domain rule 4` and
`learned rule 4` are different rules, and until 2026-08-27 a dozen notes cited a
bare four for a third thing that was in neither list. `claude/rules.md` is the
index; a check fails on a bare citation in `src/`, `tools/` or `registry/`.

**1. A section in `catalog_map` is one the printed index prints.** *(Scope, from
printed p.433: the index is a SUFFICIENT condition, not a necessary one. That
chapter's index lists nine entries where the pages head thirteen. A page the
index forgot is mapped as a PAGE of the section whose range contains it, which
keeps the rule intact and loses nothing. **Second instance 2026-08-23:** the
wall chapter index names no dish-drainer section at H.120, though printed p.254
is headed one. Two chapters, one shape.)*

**2. Run the suite on BOTH machines, and read the Ruby line first.** macOS ships
**2.6.10**. **Write to the lowest Ruby in play.**

**3. Silent applies to the GESTURE, never to the RECORD.** *(`GOL001+GOL002`
was not even a code, and it took a real export run to see it. Second instance:
an ordered filler width is OUR number in the L column, so the schedule says so.)*

**4. A rule that generalises past its evidence is a future bug with a date on
it.** Record the SCOPE. *(Instances: the Lume restriction; `um` as a piece/metre
discriminator; "8 cabinets → 8 handles" being true of eight SINGLE-FRONT
cabinets; the filler suffix `0151`, which means a front-only strip on a `B`/`C`
prefix and a wall filler with a one-piece bottom on a `P` prefix. **And the whole
of 2026-08-23**: the widest-unit rack sentence, "a compound never carries the
width restriction", the microwave niche at section height minus 360, the tall
suffix, and the base prefix as a family letter — five rules derived from pages
that happened to agree, and five later pages that did not.)*

**5. Ask, don't recompute.** *(Also why the handle count and the plinth height
ask the registry instead of keeping a copy.)*

**6. A constant chosen when there was one case is a bug waiting for the second.**

**7. Unknown is `nil`, never zero.** **A null that turns out to be readable is
still worth having been null** — the handle count closed in one commit *because*
the gap was labelled instead of filled with 1. *(And the gola null was still
saying the true thing a week later, about an element that did not exist when it
was written.)*

**8. A number no source gives us is not written down.** *(Second instance: the
front-only fillers have no depth on printed p.434, so they are held and NOT
buildable rather than given the 2,2 cm every other front carries. **Third:**
printed p.26 draws one elevation carrying 36,5 and 39 and does not say what
either is, so the page is STOPPED rather than half-read.)*

**9. A correction is DATED AND ADDED, never an edit that erases the mistake.**
*(Applies to the git log too: `094a409` states the shim range wrongly and was
superseded rather than rebased away.)*

**10. AN ABSENCE — OR A PRESENCE — IN EXTRACTED TEXT IS NOT ONE ON THE PAGE.**
`pdftotext` dropped digits on p.82 and glued two columns on p.90 into a plinth
height that does not exist. Render the page. *(2026-08-23, the sharpest case:
the N_Elle heights are in the PDF's text layer at 7,5 pt and render as blank
paper at 600 dpi. **The text layer can claim something the page does not say.**)*

**11. THE DICTIONARY IS THE OBJECT.** **Corollary: a pure layer being right
proves nothing about the thing that calls it.** *(Third instance: `Panel.apply`
reading the catalog instead of the object. **Fourth: the same method losing a
filler's ordered width — inside `Generator.effective`, which was written to
settle the third.** Fifth: the wall-hung checkbox in HTML. **Sixth: a guard is
not a rule until some data can reach it** — `wall_hung` was never carried out of
the section file. Both were found in SketchUp while the suite was green, and
both were reproducible headlessly all along.)*

**12. A GUARD MUST PROVE ITSELF BEFORE IT IS TRUSTED.** *(The registry
collision guard caught its author's own duplicate key the day it was written,
and its fixture then caught a wrong filename in its own error message. The
filler regression sweep was run with the fix removed and failed on `w_mm=>nil`
before it was trusted.)*

**13. A RECORD OF AN OUTSIDE ACTION IS ONLY TRUE IF SOMETHING CHECKS IT.**
Before touching an outgoing message, search `in:sent`. **Outside-world state is
written in ONE place.** **And re-read it before every report** — Andriy commits
in his own terminal, which happened three times mid-task on 2026-08-22.

**14. A RULE WRITTEN IN PROSE IS A RULE NO CODE CAN READ.** Move it to data,
with its page — **and record its SCOPE.** *(2026-08-23 gave this its own
corollary: **a reading that stays in a note is a reading the engine does not
have.** `catalog_map` recorded correctly that only one type on printed p.111
offers a wall-hung version, and the registry was wrong for a day and a half
while the note beside it was right.)*

**15. A SUCCESSFUL WRITE IS NOT A CORRECT WRITE — CHECK THE IDENTITY FIELDS
AFTER IT.** Gmail's `update_draft` returned success and silently re-threaded a
client email onto a new thread. **After any write through someone else's API,
read back the field that says WHAT the thing is, not just whether the call
worked.**

**16. A COMMAND THAT DID NOT RUN LEAVES NO TRACE, AND THAT IS THE DANGER.**
`git pushcd` was rejected and three commits sat unpushed. An `&&` chain whose
first link failed ran nothing at all. Compare `origin/main` with
`refs/heads/main`; it costs nothing.

**17. FORMAT A LISTING AS A LISTING.** A list of files in a fenced code block
was pasted into a shell and produced four `command not found` lines. A fenced
block is an instruction to run something.

**18. A SUITE CAN ASSERT AN INVARIANT SIDEWAYS, AND YOU FIND OUT WHEN IT
BREAKS.** *"Every corner article is still buildable"* opened by demanding that
**nothing at all** in the registry be unbuildable — true only because nothing
unbuildable had yet been held. The first front-only filler ended that. **When a
check fails for a reason its own title does not mention, the title is the bug.**
*(Applied seven times by 2026-08-24. Its companion, learned the same week: **a
check can only fail on what it looks at** — the rack check went green while the
note beside it was false, because it read a proxy instead of the recorded fact.)*

**19. A PASS OVER THE MODEL IS NOT A RULE ABOUT THE MODEL. WHATEVER IS BUILT
AFTERWARDS IS UNTAGGED.** `Retag` ran on 2026-08-30 and moved 57 bodies onto
five tags; the verification an hour later found THREE on `Layer0` again -
`DZ731Q`, `MNS022038` and a rebuilt `PF0151`, all made after the pass. Nothing
was wrong with the pass: `core/66_retag.rb` is a command precisely so that the
decision does not land in twenty call sites, and the price of that choice is
this. **Re-run Retag as the LAST act before any sheet, and after any build. A
green tag census is a fact about a moment, not about the model.**

**20. A DETECTOR THAT WATCHES THE MODEL CANNOT TELL YOUR WRITE FROM A PERSON'S
EDIT IN THE SAME WINDOW.** The probe bridge's structural fingerprint reported
*"THIS RUN APPLIED, THE ROLLBACK DID NOT HOLD"* for run 115 on 2026-08-30 - a
script with no write in it at all - because Andriy was building in the model
during the two seconds between the two snapshots. It had never fired on an
unarmed run before, and its message names a cause (*the script committed an
operation of its own*) that was not the cause. **The fingerprint is still worth
having; what it proves is that SOMETHING changed, never WHO changed it. Before
believing it, run a second read-only probe: a real escape repeats, a shared
model does not.**

## Environment
- Laptop (home): SketchUp **2025**, system Ruby **2.6.10**. Office Mac:
  SketchUp **2026**. Each SketchUp version has its own Plugins folder.
- Installation = TWO symlinks into
  `~/Library/Application Support/SketchUp <VERSION>/SketchUp/Plugins/`:
  the folder `src/ucon_cabinet_engine` AND the registrar `src/ucon_cabinet_engine.rb`.
- **A missing menu is not always a broken install.** `load '<repo>/src/ucon_cabinet_engine/main.rb'`
  in the Ruby Console brings it back. Extension Manager → Settings → Loading
  Policy must be *Unrestricted*.
- **`main.rb` calls `load_core` BEFORE registering the menu**, so any exception
  in `core/` removes the whole submenu rather than reporting itself.
- **A palette button that does not appear usually means core was not reloaded.**
  **A dialog that looks unchanged after a reload needs closing and reopening** —
  hot-reload does not redraw HTML that is already on screen.
- A fresh clone has NO catalog: `sources/**/*.pdf` is git-ignored (~438 MB), and
  `sources/**/*.png` too, which is where page renders go.
- **NEVER run git through the device bridge — not even `git status`.** It needs
  `.git/index.lock` and the mount cannot delete files. **AND `sh build/go.sh` IS
  GIT** — obvious afterwards, and broken anyway on 2026-08-28 by running the
  commit script through the bridge to *check that it worked*. It reached
  `git add`, left a zero-byte `.git/index.lock` and an unlinkable
  `.git/objects/**/tmp_obj_*`. `sh -n build/go.sh` checks the syntax and touches
  nothing; the suite lines can be run on their own; the git half is Andriy's
  terminal and only his. **Clearing a stuck lock: `mv` it aside**
  (`mv .git/index.lock .git/index.lock.stale-$(date +%H%M%S)`) — the mount
  cannot unlink but it can rename, which is cheaper than the delete-permission
  prompt. **Safe:**
  `git show HEAD:<path>`, `git show -s HEAD`, and reading `.git/logs/HEAD`,
  `.git/refs/heads/main`, `.git/refs/remotes/origin/main`.
  `git show HEAD:<f> | diff - <f>` shows what is uncommitted.
- **The bridge cannot delete anything.** Move unwanted files into `_to_delete/`
  and tell Andriy. *(It was emptied and removed 2026-08-22, and refilled
  2026-08-23.)*
- **The bridge VM runs Ruby 3.0.2 and mounts the repo.** Andriy's terminal is
  the authority. **The bridge can drop mid-session.**
- **ONE DIRECTORY, TWO NAMES, AND A SCRIPT MUST KNOW NEITHER.** The bridge sees
  the repository at `~/mnt/ucon-cabinet-engine`; Andriy's own terminal sees the
  same directory at `~/dev/ucon-cabinet-engine`. On 2026-08-28 `build/go.sh` was
  written with the bridge's path baked into a `cd` and died on its third line in
  his terminal — *No such file or directory* — after the suites had passed here.
  **Anything Andriy runs derives its own location: `cd "$(dirname "$0")/.."`.**
  **And the line handed to him carries the cd in front of it**, every time -
  `cd ~/dev/ucon-cabinet-engine && sh build/go.sh` - because he often runs it in
  a fresh terminal window, where the working directory is his home.
  The same trap is waiting in any path written into a file for him rather than
  for this session.
- **A bridge call is capped at about 45 seconds and each one runs in its own
  process namespace**, so a background job does not survive the call that
  started it. Discovered 2026-08-24 when the suite outgrew the cap; the real fix
  was making the suite faster, not working around the cap.
- **Never reformat a hand-written JSON file.** Edit registry JSON as TEXT;
  validate with `json.load` afterwards. A duplicated key is what `json.load`
  will NOT tell you. Recovery: `git show HEAD:<path> > <path>`.
- **The five factory PDFs live in `sources/factory/`.** Search ALL of them, not
  the one that raised the question — the 5 mm foot was settled 380 pages away
  in another volume, under a different code, because the same part is sold
  twice for two elements. **Cross-book search before asking the factory.**

## How we work (demand-driven)
Development is driven by building a REAL kitchen. When modelling hits a missing
element, THAT is the next task. The roadmap is a MENU of unlocks, not a queue.
Discipline: catalog fact → registry (source-verified); one-off → that unit's
attributes; never harden a project-specific choice into a global standard.
**Git runs in Andriy's terminal** — Claude prepares commands. Commits small, one
concern each. Say what we're going to do before doing it. **Don't scatter.**
**All code, commands and commit messages in English.**

**Probe before building.** Throwaway scripts outside the repo; only the residue
goes into `core/`.

**Investigate before proposing.** "Сначала выясняем, потом вырабатываем вариант."
*(The handle count is the cheap version: the answer was already in
`front_layout` and the work was reading it, not designing it. The fillers are
the other shape: the reading said the extraction could not land without a code
change, and saying so before writing anything was the whole value of the pass.)*

**Read the whole chapter before extracting one page of it.**

**Build it in SketchUp before believing it.** The filler suite was green through
two defects that a single placed object exposed in seconds. Both were pure-layer
bugs the suite could have caught — so the lesson is not that headless testing is
weak, it is that **the first real placement is a test nobody wrote yet**, and
whatever it finds belongs in the suite the same hour.

**Andriy's discovery rule (2026-08-22):** if a new crack is an instance of a
pattern already found, mark it a **re-confirmation** rather than inventing a new
concept. The goal is the minimal set of stable primitives, not the largest data
model. *(Its own provenance is odd — see `claude/repo-state.md`; the command
that would have filed it never ran, and it may belong to a different project.)*

## Architecture
- `main.rb` — thin frozen shell: menu, one toolbar button, icons.
- `core/` — 00 version, 10 standards, **20 contract (v2.1 validator; `write!`
  RECONCILES; `STRUCTURED_KEYS` are JSON at the boundary; `read` is the v1→v2
  migration boundary)**, 22 placement (pure), 30 geometry, 40 B80601 delegate,
  **50 registry (family-key collisions RAISE; `with_ordered_width`; `catalog`
  memoised on the parsed registry's identity since 0.68.0)**,
  **60 generator (`plinth_h_mm`, `plinth?`, `draw_plinth`, `effective` — which
  also RESTORES an ordered width, `wall_hung_available?`, `wall_hung_ref`;
  `build` takes `width_mm:`)**, 70 symbols, 75 place tool (glue only),
  **80 panel (`selection_state` pure, `push_selection` and `apply` glue)**,
  **85 export (pure order rows, the handle count, the ordered-width note)**,
  **86 export run**, 90 palette (`widthList` for a ranged article).
  Only 30/60/70/75/80/86/90 touch SketchUp.
- `registry/cesar/` — `_manifest.json` + one file per PRINTED section.
  *(The list that stood here named seven files and is superseded: there are 34
  as of 2026-08-24, and the count belongs in `claude/repo-state.md` anyway.)*
  The shape has not changed: **one file per printed section, merged by family
  name, and only ONE file per family may declare family-level keys.**
- `docs/UCON_Object_Contract_v2.md` — the authority the code implements, and a
  test fails if the code stops citing it.

## Key domain rules
- Trust: SOURCE < CONTROL < PLANNING < CONFIRMED. **Factory output beats the
  source PDF; the source PDF beats invention.**
- Page numbers: always **PRINTED** (PDF = printed + 2).
- **A price table outranks a visual index.**
- `hinge_side` per-order, never guessed. **The family letter is a lookup** — in
  the tall chapter a PAIR, d.35 then d.62. **In the base chapter it is not a
  family letter at all but a (family × depth × geometry) SLOT key.**
- **A family letter can be page-scoped, like a depth letter.** `CH` is H.222
  d.62 in the tall chapter and H.278 on printed p.434.
- **The USA elements chapter has no family letters of its own.**
- **A depth letter can be page-scoped.**
- **Millimetres are the truth; inches are a way of READING a size.**
- **The door-version axis (78/75) is FAMILY-SCOPED** — and nineteen articles now
  need it to be narrower than that.
- **A FILLER'S WIDTH IS AN ORDER AXIS, not a catalog fact** — the row gives
  `width_range_mm` and the person gives the number. The third such axis, and the
  first that is a dimension.
- **A filler inherits its FAMILY's ground** — height, mounting and plinth. So it
  may not be extracted before its family exists.
- **A RUN ELEMENT CONTRIBUTES A LENGTH, NOT A COUNT.** The plinth under it and
  the grip recess above it are drawn AND enter the warehouse as погонаж, and for
  a filler both lengths are its ordered width. Never `qty 1`.
- **A US appliance panel has no hand in the ORDER but the DRAWING carries it.**
- **A plan symbol rides with its ROW.**
- **A symbol we cannot justify is not drawn.**
- **A drawn thing may still be ordered, and an ordered thing need not be drawn.**
- **`front_layout` is an ORDER fact as well as a drawing fact** — it counts the
  handles. Adding a type without it costs a quantity, and leaving it ABSENT lets
  a default invent one.
- **A finish, a foot type and a grip system are COMPOSITION axes** wearing
  per-unit coats. They belong to M1.6.
- **THE CATALOG STATES THINGS IN PRINT-ART, NOT ONLY IN WORDS.** printed p.19
  gives two per-depth-row pictograms their names: "Hung version" and "Provisions
  for hob". `pdftotext` cannot see either. Whether an article can be hung is a
  printed fact, and its ABSENCE is the statement.
- Envelope-only; front flush; **the 1.5 mm reveal is recorded, never drawn**.
- NOT Dynamic Components.

## NEXT — in priority order

*(2026-08-24: items 6 and 7 are done — the tall and wall chapters were read.
The list is otherwise current; the extraction queue itself lives in
`claude/debt-2026-08-24.md`.)*

1. **Elda round one is in flight.** Five questions ride on her: W1–W3 (cutout,
   thickness, protection) and **L1 (bar length) + L2 (plinth ours or
   Metron's)**. Q7b gates the corner units in **five** chapters now. **Two more
   are waiting for round two** — the filler width quantisation, and the 2,3 vs
   5 cm contradiction on printed p.435. **A third: is `BJ0150`/`BJ0151` really
   the H.58,5 base filler, when the H.58,5 base units are B3/B6/B4 and BJ is the
   H.39 d.47 letter?**
2. **The warehouse aggregation** (M1.13) — the hidden tag/scene. Per-object
   numbers exist; **nothing sums them.** Piece half can be summed today, and the
   filler gives the metre half its first concrete case:
   `claude/warehouse-architecture-2026-08-22.md` §8.5.
3. **Exporter level 1 to 100 %** (M1.10). One null left and it is **M2.1a**.
4. **`registry/cesar/options/`** — p.568 + p.569. Read the accessories chapter
   index first (rule 1). `origin: chosen` now has a working precedent.
   **Five positions in five chapters point at p.569** — the most referenced
   unread page in the registry.
5. **The panel's second job** — a chosen companion that rebuilds nothing.
   `Panel.apply` is still one geometry pipeline. *(`effective` was the other
   half of this and is done.)*
6. ~~The next tall page~~ — **done 2026-08-23**: all five plain tall families.
7. ~~The third wall family~~ — **done 2026-08-23**: the whole wall chapter.
8. **Stamp tool** — point-and-place from the catalog.
9. **M1.6 project defaults** — takes over `WALL_MOUNT_BOTTOM_MM`, the Lume
   filter, the grip SYSTEM, **the foot type**, and **finishes**. See
   `claude/finishes-and-price-bands-2026-08-22.md` before designing it: no
   integer `price_band`, no band hung off a colour, and **a per-object finish
   override must be visible on the sheet.** **The corner-filler minimum is a
   fourth grip-scoped axis** — 7,5×7,5 default, 6×6 Frame, 5×5 push-pull or
   grip recess.
10. **The appliance module.** Four things wait on it — and ~285 codes.
11. **The mechanisms chapter — printed p.559-567.**
12. **`restrictions` has nowhere to be written** — the list keeps growing: *"DO
    NOT fit against the wall"*, *"cannot be modified in width"*, *"35 cm deep
    tall units must be fixed to the wall"*, the types that may not hang, the
    asterisked widths that restrict finishes, **the hob provisions**, and the
    five closing-strip and corner-filler rules of printed p.10-11.
13. **printed p.612 "Additional handles"** — resolves `M00015`/`M00016`.
14. **USA elements (p.409-432)** — next page p.414, waits on M1.11.
15. **The baked z0.**
16. **Properties panel does not expose `mount_bottom_mm`.**
17. **The 5 cm closing strip rule** — `PD0131/0531/0631`. **The article it asks
    for now exists: `PD0151`**, and 50 mm is inside its range. What is left is
    the WARNING, not the part. Policy unchanged: warn, never auto-insert.
18. **Corner units, wall and tall** — Q7b gates them in five chapters.
19. ~~Registry loader hardening~~ — **done 2026-08-22** (`bc546b2`).
20. Placement performance unmeasured on a real kitchen.
21. **Tall unit top elements (p.170-173)** — a stacking relationship. *(And the
    low base families turn out to be the other end of the same idea: Project
    Guidelines p.68 dimensions H.39 + H.39 = H.78.)*
22. ~~Does a filler carry the run's plinth across?~~ — **YES, answered
    2026-08-23.**
23. **The rest of printed p.433-456** — end elements and adjoining side panels
    (p.436-449), which are the **area-derived (`MQ`) half the warehouse has been
    waiting for**, and open units (p.450-456), which bring a **second
    continuous-width axis**.
24. UI backlog (own file).
25. **The pictogram sweep owed** — 148 non-wall codes were transcribed before
    printed p.19's legend was found. Their silence about the hung and hob glyphs
    means *unread*, not *absent*.

## Milestone menu
M1.6 project defaults (now also finishes + foot type) · M1.7a registry
thumbnails · M1.8 appearance layer · **M1.9 Elda round one (in flight)** ·
**M1.10 exporter (level 1 landed; one null left, and it is M2.1a)** ·
M1.11 modifications · M1.12 bespoke · **M1.13 warehouse (piece half counted,
aggregation not built, metre half on Elda L1)** · M2.1a batch row builder →
M2.1b worktop → **M2.2 corner placement DONE** → **M2.3 interactive tool (grab
half landed, stamp half open)** · M3 multi-manufacturer (Pianca is SPREADS —
`printed_left = 2 × PDF − 4`).

## North star
Presentation CAD sheets in LayOut: wireframe, four views. Real target output =
a "Custom Elements" sheet like Alta Vista 7/9.

## Practical notes
- Current model: `545_Avenida_Primavera_Kitchen_Preliminary_Model_v0.1_1.skp`.
- `pdftotext -f N -l N -layout` reads a page; `pdftoppm -r 300 -f N -l N -png`
  renders one and `-x -y -W -H` crops it. **For exact geometry off a drawing use
  `pdftocairo -svg`.** **And `pdftotext -bbox` gives the coordinates of a piece
  of text, which is how you render exactly the box a claim rests on.**
- **To sweep a whole chapter cheaply**, dump it once with `pdftotext -layout`,
  split on `\f`, and pull per page. **Cheap for structure; see rule 10 before
  trusting it for anything decisive.** *(200 dpi is enough to verify a dense
  price table — p.434 has four tables and 31 codes and read cleanly.)*
- DWG cannot be opened in Claude's sandbox. **DXF can** — `ezdxf` reads it.
- US vs EU: real US sheets use 19 mm (3/4″) fronts, not 22 mm EU — see W2.
- **`export` is a reserved word in JS.** The palette callback is `export_order`.

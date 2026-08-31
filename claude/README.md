# `claude/` — the working notes

**What this is.** The reasoning behind the code. Recon of catalog chapters
before they were extracted, architecture decisions and the arguments for them,
findings that corrected something already committed, and the open questions for
Elda. Written during Cowork sessions, kept because the *why* of a registry file
is not in the registry file.

**Moved here on 2026-08-24** from the claude.ai Project that had held them since
2026-08-18, in commit `a775846`; **a second batch — the appliance notes — followed
on 2026-08-25**, listed under "Appliances" below. The move does three things: the knowledge travels with the code, the
history of a note lands in git beside the history of the corrections it
explains, and a future move between tools becomes a `cd` rather than a
migration. **Nothing was deleted from the Project until the first push of this
directory succeeded.** It did, and twenty of the twenty-one originals are gone;
`elda-mini-order-2026-08-20.md` was kept there on purpose, because a scheduled
task writes into it from a session that cannot reach this repository. See
`repo-state.md`.

**After the 2026-08-25 housekeeping the Project holds exactly two files:** the
current `handoff-<date>-<machine>.md` and `elda-mini-order-2026-08-20.md`.
Anything else appearing there is a note that has not been moved yet.

**Faithfully copied.** Every file is the Project text. Where a document said
something that later reading falsified, a **dated correction block was ADDED at
the top or beside the claim — never an edit that erases the mistake** (rule 9,
the same rule the commit log follows). Six documents carry such a block; each
one names the date and what superseded it.

---

## Where to start

| read this | when |
|---|---|
| **`rules.md`** | before writing `rule N` anywhere. FOUR numbering schemes, three of them starting at 1 — this says which is which, and a check fails on a bare citation in `src/`, `tools/` or `registry/`. |
| **`repo-state.md`** | first, always. HEAD, version, check count, registry size, what is uncommitted, what is next. The only file allowed to carry volatile numbers. |
| **`ucon-cabinet-engine-status.md`** | the long-form status: the rules, the environment, the architecture, the NEXT list. Points at `repo-state.md` for numbers and does not repeat them. |
| **`debt-2026-08-24.md`** | how much of the catalog is held, measured rather than remembered. Superseded by a newer dated note, never edited. |
| **`commit-chronicle-2026-08.md`** | only when you need the history. The day-by-day commit tables for 22-24 August, moved out of `repo-state.md` on 2026-08-27 so that the first-read file stays short. |
| **`extraction-plan-2026-08-23.md`** | the groups and the reasoning for their order. Its §1-2 numbers are stale by design; §4-7 are the useful part. |

## The rest, by kind

**Findings — a page, a model or a check said something we had assumed.** In
date order; a finding is never edited to hide what it corrected.

- 08-23: `findings-2026-08-23.md` (H.96, H.120, base p.37-38, p.48),
  `findings-2026-08-23-tall.md` (the five plain tall families).
- 08-24: `findings-2026-08-24-base-column.md` (the base prefix),
  `findings-2026-08-24-h58_5.md` (H.58.5 whole),
  `findings-2026-08-24-pictogram-sweep.md` (the glyph debt, closed),
  `findings-2026-08-24-filler-note.md`.
- 08-25: `findings-2026-08-25-first-run.md` (both extensions running, in
  SketchUp, for the first time),
  `findings-2026-08-25-appliance-seam.md` (four things the seam found in what
  the engine draws), `findings-2026-08-25-tall-h210-appliance-columns.md`,
  `findings-2026-08-25-top-elements-and-the-ceiling.md`.
- 08-26: `findings-2026-08-26-seam-findings-closed.md` (three of the four
  decided), `findings-2026-08-26-east-fridge.md` (the fridge bay built by
  probe, and the engine unable to rebuild it),
  `findings-2026-08-26-gap-audit.md` (56 joints at 0,0 and one deliberate gap),
  `findings-2026-08-26-filler-rounding.md` (a filler rounds UP),
  `findings-2026-08-26-custom-fronts.md` (a model is not recomputed when the
  engine changes), `findings-2026-08-26-glass-row.md` (the west wall's glass,
  and a frame the catalog does not print),
  **`findings-2026-08-26-panels-recon.md`** (the panel chapter, the first object
  with no ground of its own, and the third volume),
  **`findings-2026-08-27-vol3-panels-read.md`** (Volume 3 printed p.214-220 read
  from the renders: 44 panel codes priced per m2, the fixing kits and the foot,
  three corrections to the note above, and — section 6 — the extraction that
  followed the same day, source_pdf becoming a per-section fact, and the loader
  bug three new checks caught on their first run),
  **`findings-2026-08-27-island-back-built.md`** (the six panels measured in the
  model, the breakfast top at exactly 30 inches that explains the slot, the
  material fork still open, and a lacquer refusal that would have been wrong),
  **`findings-2026-08-27-c92640-the-door-nobody-printed.md`** (the custom-sized
  door the page declines to dimension, derived as the remainder and confirmed
  against the render, and the census check that went red first),
  **`findings-2026-08-27-horizontal-thin-is-not-a-box.md`** (why the open module
  came out a solid, the first time domain rule 4's exception fires, the p.458
  dimensions already read, and the two ways forward),
  **`findings-2026-08-27-shelves-38-44-search.md`** (all five volumes searched
  for a 38-44 mm horizontal shelf: the Shelves chapter prints 2,2 and 6,0 only,
  and the 40 mm board is a breakfast bar / Living top with concealed wall
  supports that name the thickness — **corrected the same hour, see the next
  note**),
  **`findings-2026-08-27-shelf-fixings-rules.md`** (printed p.223 carries a 4 cm
  block the search note missed, the MNS code grammar, the fixings as order-only
  lines, and the three spacing rules with their table),
  **`findings-2026-08-27-lit-shelves.md`** (three shapes a lit shelf takes, the
  power adapter never included, the luminous glass shelf's 110V exclusion, and -
  appended the same day - the FOURTH instance of learned rule 11: the light was
  written onto the object and `Generator.effective` never handed it to the
  drawing, plus why reloading the core cannot fix an open HtmlDialog, plus the
  third round where it was drawn correctly and was five pixels tall),
  **`findings-2026-08-27-colour-temperature.md`** (the whole Lighting chapter
  read: every Cesar lamp is dual-colour and adjusted on site, so no order states
  a temperature and none can arrive wrong - the real risk is ordering a lamp with
  nothing to adjust it with; the lamp and transformer codes; and the catalog's own
  cross-reference to p.526, which is a page about waste bins),
  **`findings-2026-08-27-facing.md`** (the label was inside the wall: a shelf
  inherits the facing of whatever it was built off, there was NO WAY AT ALL to
  turn an object round, and a shelf should never have been placed beside
  anything - Andriy's wall rule, and the turn buttons; **superseded in part
  2026-08-28**, when the facing question was deleted instead of answered),
  **`findings-2026-08-28-a-copy-is-not-a-copy.md`** (a hand-copied shelf shared
  its definition, so taking the light off one took it off the other - the order
  was never wrong, only the editing; and the guard already existed in the
  generator and had never been generalised to the panel),
  **`findings-2026-08-28-appliance-placement.md`** (48_Core read against the
  model: the dishwasher was drawn before anybody named its machine, the datum
  that looks like a missed call site is a decision in one file and a defect in
  the other, and the gola rule substituted three machines that had a PRICE and
  no OPENING - so the geometry review silently stopped at the moment the front
  system changed the machine; then the three manufacturer guides were found in
  ~/Downloads, the three ADA openings and the hood's envelope and mounting range
  were read off their pages, and the appliance package went 0.2.0 -> 0.3.0; and the hood turned out to be
  BUILT IN, which made the cabinets over the range the hood rather than an
  obstruction to it),
  **`findings-2026-08-28-panels-the-letter-is-a-lookup.md`** (every panel code
  carried a price-group letter and nothing said what the letter meant, so the
  held island probe was ordering an unnamed species list - and on the two-sided
  veneer pages the same letter B is Trama at 1,8 and Prime at 2,2),
  **`findings-2026-08-28-the-first-worktop.md`** (Linear Elements printed p.110,
  the ceramic tops: the first `object_class: worktop`, the first section where
  THE CODE DOES NOT DETERMINE THE PRICE - five finish groups x eight depth bands
  under one code - and the first dimension that comes from the order as a CLOSED
  LIST rather than a range, so 660 is refused instead of rounded to 650; and the
  seven suite checks that failed the moment it loaded, all seven correctly).

  **`findings-2026-08-29-layout-prep.md`** (the drawing side asked its first
  question: eight scenes over a model whose 56 of 59 bodies were on Layer0, all
  eight cameras a perspective and seven of them the SAME perspective, zero
  section planes - and the symbols themselves drawn correctly all along and
  simply switched off; plus core/66_retag.rb and why the generator does not tag).

  **`findings-2026-08-29-the-filler-has-a-front.md`** (the Door height control on
  B70151 was shown and could not act: attributes_patch returned early on anything
  that does not OPEN, and a filler has a front and does not open - found in the
  model, where the base run stood at front 750 and both H.78 fillers at 780; one
  predicate split into two, a contract key written and taken back, and the
  mounting block guarded so the mirror-image bug did not ship with the fix).

  **`findings-2026-08-29-the-first-stone.md`** (the first three countertops, and the
  day Elda Q28 got a price: the bounding-rectangle order costs nothing on a straight
  run - measured, twice, to three decimals - and 4,195 m2, 58%% of the sheet, on an L;
  plus the band with nothing between 650 and 700, and the covering pass that read
  four covered units as 53%% because an instance box carries the drawer symbols).

  **`decisions-2026-08-29-finishes.md`** (thirteen finish decisions taken in one
  sitting off the order form itself: Maxima 2.2 at band 6, RR09 Rovere Nordico with
  LX19 Nero, one black metal through recess, plinth, wall edging and glass frames,
  Dekton Marmorio at 650 with no edge profile - plus the four printed routes out of
  band 6, the contract having no finish key at all, and the morning claim about zero
  GOL lines corrected from the estimate teardown).

  **`findings-2026-08-30-the-oak-black-split.md`** (the last of the thirteen finish
  questions, and the catalog had already answered half of it: six panels are price
  group A, First wood veneers, which printed p.218 and p.220 print as exactly seven
  Rovere with no lacquer in it at all - so both island ends, the island's whole back
  and the tall run's end were oak before the question was asked, and the split was
  only ever which of those two masses also gets oak fronts; the answer is both,
  43 fronts assigned with none left over, and the three shared definitions all want
  one finish each so it can be painted; plus the order form carrying the finish
  FAMILY and never the colour, which is what makes the drawing the only record).

  **`findings-2026-08-30-the-stone-stamped.md`** (six pieces of stone carry an
  article at last, and the sink mark came with them because it refuses over an
  unstamped top; the cut of the west run was chosen at option A because it was
  already drawn and the three schemes are one per cent apart; the island pays
  band 700 knowingly; and FOUR PIECES CARRY A VISIBLE SIDE EDGE THE RULE SAYS
  THEY SHOULD NOT - parked rather than fixed, because the stamp asks one edge
  count of a whole selection while an edge belongs to one end of one piece).

  **`findings-2026-08-31-the-plinth-nobody-owned.md`** (whether the worktop is
  ordered on this project AT ALL is undecided, which two documents said
  otherwise until this date; the edge procedure designed and agreed but not
  built, and the live defect it uncovered - the stone stamp rebuilds `variants`
  from scratch and would delete the sink bowl on a second stamp, where the sink
  itself merges; the fridge plinth that was never missing, only unpainted and
  untagged, because a body with NO CONTRACT is invisible to every pass that
  walks the model; and the eight scenes that remembered a tag created after they
  were saved - learned rule 19 wearing different clothes, and a candidate rule
  21 that has not been added).

**Handoffs:** `handoff-2026-08-28-appliances.md`,
**`handoff-2026-08-28-worktops.md`** (the evening one, and the one to read first
after this date: the engine stopped DRAWING worktops and started STAMPING them,
what that keeps, what it costs, and the covering report it owes).

  **`order-form-maxima22-recon-2026-08-31.md`** (the Maxima 2.2 order form read
  field by field off the RENDER - printed p.65-66, and the text layer says 64
  because that is the previous page's footer; it cannot be filled
  programmatically, it is one of the four documents Cesar says a new order is,
  and every field is marked engine-knows / engine-could-know / ask-a-person. It
  confirms Elda Q11 from a second direction and raises four questions nobody
  knew they had, the sharpest being that one Depth field cannot hold three
  worktop depths).

**Chapter recon — read before extracting:**
`wall-units-recon-2026-08-18.md`, `tall-units-recon-2026-08-22.md`,
`fillers-recon-2026-08-23.md`, `usa-elements-recon-2026-08-20.md`,
`corner-units-m22-brief-2026-08-20.md`, `wine-cooler-aperture-2026-08-22.md`,
`kits-availability-p568-2026-08-25.md`.

**Appliances** — a SEPARATE extension (`UCON::Appliances`, own namespace, own
dictionary, own JSON files, own suite); `core/88_appliance_check.rb` is the only
seam and it only asks questions. **The package moved into this repository on
2026-08-25** — `src/ucon_appliances/`, its own extension target beside
`src/ucon_cabinet_engine/`, its own version, its own suite
(`tools/test_appliances.rb`). `appliance-rules-decided.md` is the prose behind
its `data/rules.json`:
`appliance-rules-decided.md`, `findings-2026-08-25-appliance-seam.md`,
`appliance-housing-datum-2026-08-25.md`, `appliance-filler-plane-2026-08-25.md`,
`appliance-flush-vs-standard-2026-08-25.md`,
`appliance-openings-recon-2026-08-25.md` with its raw table
`appliance-openings-106-configs-2026-08-25.csv`.

**Architecture and decisions:**
`warehouse-architecture-2026-08-22.md`, `options-architecture-2026-08-20.md`,
`placement-tool-design-2026-08-19.md`, `plinth-and-wall-hung-2026-08-22.md`,
`finishes-and-price-bands-2026-08-22.md`, `contract-v16-companions-2026-08-22.md`,
`picker-ui-backlog-2026-08-20.md`, `price-trust-2026-08-25.md` (what a fetched
number is worth), `plan-2026-08-25-b6-run-gap.md` (the alternatives that were
rejected before the run gap was built).

**For Elda:** `elda-mini-order-2026-08-20.md` — and the numbered questions
themselves live in `docs/Elda_Open_Questions_v0.1.md`.

---

## How to keep these honest

1. **Rule 9 — a correction is dated and ADDED.** Never rewrite a claim so the
   mistake disappears; the mistake is why the check exists.
2. **One document owns each volatile number.** `repo-state.md` owns the repo's;
   a dated debt note owns the catalog's. A number copied into two files goes
   stale in one of them.
3. **A reading that stays in a note is a reading the engine does not have.** If
   a note records a catalog fact, the same session should put it in
   `registry/cesar/` and pin it with a check in `tools/test_contract.rb`.
4. **Page numbers here are always PRINTED page numbers.** PDF page = printed
   + 2, in **all five** factory books — `docs/Cesar_Volumes_Index.md` says which
   book holds what. **Before recording that Cesar does not print something, name
   which volume was searched**; on 2026-08-26 three facts were called missing
   that were simply in another one.
5. **This index is checked.** A file in `claude/` that is not named here fails
   the suite. An index nobody maintains is worse than none, because it reads as
   a complete list.

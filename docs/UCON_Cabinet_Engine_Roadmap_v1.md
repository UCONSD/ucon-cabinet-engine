# UCON Cabinet Engine — Roadmap v1

**Org:** UCONSD · **Document role:** Two-phase build plan and milestone register
**Version:** v1 (status update 2026-08-16) · **Status:** Active planning document

This roadmap is a planning document, not a contract. It is expected to be reworked as we
learn. The foundation it points to (`UCON_Object_Contract_v1.md`) is the stable part;
everything scheduled below is deliberately allowed to change.

---

## 1. Goal

Generate architectural placeholder cabinetry that matches Cesar catalog dimensions and
carries the correct catalog article code, on demand, inside SketchUp — so a designer
never has to search a thousand-item catalog by hand. Correctness is defined by the source
PDF; the engine's job is to reproduce it, not to reinterpret it.

## 2. Scope boundary (fixed)

In scope: **Concept/Preliminary Design → Design Development → Elda/Giorgio Confirmation
(Level 4)**.

Out of scope, in a separate project: quote, pricing, order, production, delivery,
install. The roadmap below never crosses L4. Any milestone that would require pricing,
availability commitments, or production release is out of bounds by definition.

## 3. The four-level trust model

The engine tracks how trustworthy each fact is, via the `status` attribute:

| Level | Name | Meaning | Authority |
|------:|------|---------|-----------|
| 1 | Source | Read directly from a manufacturer catalog / price list PDF | Dimensions, module structure, technical rules, article codes |
| 2 | Control | Captured into a controlled register with provenance to a PDF section | Planning data, priority (P1/P2/P3) |
| 3 | SketchUp Planning | Instantiated as a preliminary placeholder component | Layout / review only |
| 4 | Elda Confirmation | Confirmed in writing by Cesar / DzineElements | Feasibility, U.S. applicability, availability — **last stage in scope** |

Codes and dimensions stay **PRELIMINARY** until Level 4. The source PDF always wins over
any register, workbook, or generated model.

---

## 4. Two-phase plan

### Phase 1 — Solo / script-based

One operator, plain Ruby scripts run against SketchUp, data in flat files
(`registry/*.json`, the source-extract layer). No install story, no UI beyond the script
console. The point of Phase 1 is to prove the contract and the generation/verification
loop on real Cesar data, cheaply and reversibly.

**Exit criteria for Phase 1:** the Object Contract is locked; the Cesar registry drives a
forward generator and a reverse decoder; a verify tool checks generated codes against the
source PDF; an exporter walks a model and emits a factory-code schedule. All of it
reproducible from the command line.

### Phase 2 — Plugin

Package the proven Phase 1 core as a SketchUp extension: a real UI, in-model dialogs,
component browser, and the exporter available as a menu action. Phase 2 does not begin
until Phase 1's core is stable, because the plugin is a wrapper around it. Everything
shared between phases lives in the same core modules (contract + registry + generator +
exporter); the plugin only adds the shell.

---

## 5. Milestones

> **Correction from earlier notes.** Earlier planning treated the Object Contract,
> `cesar.json`, and the H.78 tools as already built, and framed Milestone 1.1 as "write
> the exporter and make the generator read from `cesar.json`." Those files do not yet
> exist. Milestone 1.1 is therefore re-sequenced to build the foundation first; the
> exporter/registry-reader work moves to Milestone 1.4, where its prerequisites exist.

### Phase 1

- **M1.0 — Repo & orientation** *(in progress)*
  Repo structure, README, this roadmap. Establishes the frame the rest hangs on.

- **M1.1 — Object Contract v1** *(next)*
  Author `UCON_Object_Contract_v1.md`: attribute schema, component structure,
  rules-registry format, and the `status` vocabulary. Formalizes the existing source
  hierarchy and P1/P2/P3 tagging into the four-level model. Load-bearing; changes only via
  versioned migration afterward.

- **M1.2 — Data Levels v1**
  Author `UCON_Data_Levels_v1.md`: the four-level trust model in full, mapped onto
  `status`, with rules for how a fact moves up a level and what evidence each move
  requires.

- **M1.3 — Cesar registry (H.78)**
  Author `registry/cesar.json`: Cesar H.78 rules as data, in the Contract's format,
  verified against the source PDF (Kitchen System, incl. the H.78 reference page).
  Catalog facts confirmed against the PDF before they enter the registry — never assumed.
  Must encode the opening-method axis added in Object Contract v1.1: `opening_method`
  (`handle`/`push_to_open`/`gola`), derived `front_height_mm` (`gola` = family door − 30),
  and separately-ordered hardware (`GOL`/`M`/push-pull, or client-provided) — none of which
  is carried in the article code. Order-notation detail for the door version is pending Elda
  (see `docs/Elda_Open_Questions_v0.1.md`, Q1).

- **M1.4 — Generator + decoder + verify + exporter** *(first synchronization loop)*
  The H.78 forward generator (params → coded component) and reverse decoder (code →
  params), both reading rules from `registry/cesar.json` rather than hard-coding them; a
  verify tool that checks output against the source; and the class-agnostic exporter that
  walks a model, reads the UCON attribute namespace off any object, and emits a
  factory-code schedule. This closes the first source ↔ model synchronization loop and
  becomes the first shared-core module.

- **M1.5 — Catalog-extraction SKILL**
  Package the extraction workflow (already exercised manually to build the source-extract
  layer) as a reusable SKILL scaffold under `skills/catalog-extraction/`.

### Phase 2 (loose, revisited after Phase 1)

- **M2.0** — Wrap the Phase 1 core as a SketchUp extension (packaging, load path, menu).
- **M2.1** — In-model generation dialog and component browser.
- **M2.2** — Exporter as a menu action producing the factory-code schedule from the UI.

Phase 2 milestones are intentionally under-specified; they will be detailed once Phase 1
is stable.

---

## 6. Working principles

Foundation stable, tools fluid. Concrete on the near step, loose on the far ones. Verify
against the source PDF and never override it. Codes stay PRELIMINARY until human
confirmation. Ask before assuming catalog facts. Keep changes small and committable.

---

## 7. Status update — 2026-08-16

**Settled architecture decision (do not revisit without cause):** NOT built on
Dynamic Components. DC can deliver live Component-Options editing (SG Kitchen
Pro does), but only with generic parametric geometry and no article-code
binding — incompatible with "every unit is an existing catalog code." We
generate from the registry and rebuild instead. Full reasoning:
`docs/Competitive_Notes_v0.1.md`.

**Where reality diverged from the plan, and why it was the right call:** the
Phase 2 shell (extension registrar, menu, floating palette) was built early,
in v0.1, because the shell/core split with hot reload turned out to be the
cheapest way to iterate on Phase 1 itself. The shell is ~100 lines and frozen;
everything fluid lives in core/ and reloads without restarting SketchUp.

**Done (beyond the original M1.x scope):**

- Object Contract implemented and enforced in code (v1.2: + hinge_side);
  67+ headless checks run without SketchUp.
- Registry: 74 codes across five H.78 unit types, verified against printed
  p.36/39/40; stored one-file-per-catalog-section (registry/cesar/) with an
  mtime-cached merging loader. Code grammar corrected from source (depth digit
  family-specific; width field is a lookup; suffix not globally unique).
- Generator (M1.4 forward path): code -> envelope unit with contract
  attributes; floor snap; build-next-to-selected continues a run.
- Reverse lookup (M1.4 decoder in practice): Registry.lookup(code).
- Unit Properties panel: door 78/75, gola with mandatory profile lines
  (undercounter single for doors, pairs for drawer stacks), handle
  factory/client, push-to-open (device code pending Elda), hinge side.
- Opening symbols on two hideable dashed tags (elevation V / diagonals;
  plan swing arcs / pull-out with real travel), gray, view switcher.
- Cascading catalog picker: class > section > type > size grid + search.
- Hardware at CONTROL level: 4 gola profiles, 8 handles (Tratto excluded per
  source restriction, conflicting M-codes held back), Blum runner table as
  clearly-marked external spec.

**Not done from M1.x:** UCON_Data_Levels_v1.md (M1.2) — the trust vocabulary
lives in the Contract §3 and has not needed a separate document yet.
Verify tool and exporter (rest of M1.4) — deliberately deferred: nothing to
export until real layouts exist. Catalog-extraction SKILL (M1.5) — the
extraction workflow is being exercised page by page instead.

**Development strategy: demand-driven (2026-08-16).** Work is driven by
building a real kitchen. When modelling hits a missing element, that element is
the next task. The list below is therefore a MENU of unlocks, not a fixed
queue — pick what the current kitchen needs. Order shown is a reasonable
default, not a mandate. (Full rationale: the "How we work" section of
CLAUDE.md.)

**Milestone menu:**

- **M1.6 — Project defaults.** Per-model defaults dialog (depth, door
  version, gola system, handle, finishes); new units inherit; panel becomes
  the exception editor.
- **M1.7 — Sink base H.78 section — DONE for printed p.44 (2026-08-17).**
  `registry/cesar/sink_base_h78.json`: 20 codes in four unit types (door 4,
  doors 6, jumbo drawer 2, jumbo drawers 8). The proof held — the picker
  unfolded the new section with ZERO changes in core/; the only code touched
  was the test suite (77 -> 84 checks). Registry now 94 codes.
  Page numbers corrected: the sink section is printed p.44-46 / PDF 46-48,
  not "printed p.46-48" — earlier notes cited PDF numbers as printed ones
  (same slip for the corner pages, which are printed p.42-43).
  Still open on this section: printed p.45 (fixed front + jumbo drawer)
  carries paired codes 90/91 with identical dimensions and prices, differing
  only in the gola front split — 165+555 vs 195+555. Reads as "where the
  30 mm recess is taken", consistent with our gola-zone model, but the source
  never says so: Elda Q4, not a guess. Printed p.46 (corner sink bases,
  AU/AW/A81171) waits for M2.2.
- **M1.7a — Registry-drawn picker thumbnails** (paired with M1.7, from the
  EasySketch review 2026-08-16). Inline SVG mini-elevations generated in the
  picker from front_layout data - our own drawing convention (dashed V /
  diagonals), real proportions: type tiles get a schematic, the result card
  gets the actual code's W:H. NO static image assets ever - thumbnails derive
  from the registry, so every new section draws its own. Corner types will
  render a plan-view schematic (geometry_kind=corner); appliance/sink
  pictogram hints become an optional registry field when those sections are
  extracted. Cost: ~60-80 lines JS in picker_html + front_layout passthrough
  DECISION 2026-08-16: iso direction, catalog-like; TYPE-level iso uses PDF-extracted placeholders with a generative fallback via an optional `thumbnail` field (generative is the default); the result card uses the generated front schematic per code; flame pictogram ignored. Drawing rules are authored in docs/Drawing_Spec_v0.1.md (procedural graphics; spec is the authority, renderer implements it). Also adopted from that review, unscheduled: Smart
  Right Click (context menu on a unit: panel / flip hinge / door version)
  and saved unit variants (code + options preset, extends M1.6 defaults).
  Rejected from it: static asset libraries, door animations (a wireframe
  LayOut sheet needs symbols, not motion). EasySketch's model (generic
  free-sized cabinets, pretty pictures, manual translation to a factory
  order) is the opposite of ours (article-coded, source-verified,
  order-ready) - UX patterns borrowed, data model deliberately not.
- **Catalog section map + picker gaps — DONE 2026-08-17.**
  `_manifest.json` → `catalog_map` records what the printed index says exists
  (sections from printed p.19, unit types only for pages we have opened), and
  `Registry.gaps` turns the difference against the registry into inert grey
  rows in the picker. Readable copy: `docs/Catalog_Section_Map_H78.md`.
  Held: 94 of 231 codes in the H.78 block. Rule established: a placeholder may
  only be shown at a level we have actually read in the source.
- **Dishwasher placeholder + both dishwasher doors — ONE task, and it is a KIT.**
  The door exists in two executions: fully-integrated on printed p.47
  (V80530 W45, V80630 W60, V80730 W75) and a second on printed p.48
  (V88559…V88669, W45 and W60 only). The machine is the client's; the Cesar
  order line is the DOOR. Build the appliance placeholder
  (`object_class=appliance_front`, sixth tier of the spectrum in
  `docs/Bespoke_Elements_Design_Spec_v0.1.md`) together with both extractions.

  **Choosing a dishwasher door must emit companion order lines, not just the
  door.** This is the gola pattern again — door 75 already forces its `GOL`
  profile lines — so the concept is not new, only its second instance. Name it
  once here and reuse it: a catalog choice may MANDATE companion codes, and the
  exporter emits them whether or not they are drawn.

  Composition, all source-verified on printed p.47-48:
  - **Filler profile between the dishwasher and the top** — `995945` (W45),
    `995946` (W60). Only two widths exist. It is a strip, not a box: recorded
    as an order line, not drawn, exactly like a `GOL` profile.
  - **The door** itself, at the chosen width.
  - **`GBBF01`** — stainless steel cabinet W15 with the door-bearing mechanism,
    required ONLY by the 75 cm version: the appliance is 60 wide, the door is
    75, and 60 + 15 = 75. Unlike the filler this is a real box and occupies
    space in the run, so it is GENERATED as an object, not merely listed.
  - Therefore: door 45 → 2 codes (door + filler 995945). Door 60 → 2 codes
    (door + filler 995946). **Door 75 → 3 codes** (door V80730 + filler 995946,
    because the machine behind it is 60 wide + GBBF01).
  - Open: which side GBBF01 goes on — Elda Q5. Per-order axis with no default
    until answered, same discipline as `hinge_side`.

  Also on printed p.48, not part of this kit but noted while reading it:
  "Protection under induction hob" (`996466` W60 … `996462` W120). A 99xxxx
  accessory family, extract when a hob needs it.
- **Printed p.47 — three positions excluded by decision (2026-08-17).** Fridge/
  freezer housing (V80601, V90601), built-in fridge-freezer unit (V80611,
  V90611) and the washing-machine door (V80640) are not extracted because no
  current project orders them; the dishwasher door on the same page is KEPT and
  planned. Decisions live per position, not per page — that is why map types
  may carry their own status. PLANNING trust, reversible on demand.
- **Printed p.41 needs its grammar read from scratch** before extraction: its
  codes (B78566, B88566, B98566 …) do not decode with the p.36 width lookup and
  its elevation sums to 750, not 780. Flagged in the map; do not extract by
  inertia.
- **Registry loader hardening — small, do before the next section lands
  (found 2026-08-17 while adding the sink section).** `core/50_registry.rb`
  merges every non-`unit_types` key from a section file into its FAMILY, last
  file wins, files sorted by name. `sink_base_h78.json` sorts after
  `base_h78.json`, so a `depths_mm` in the sink file would have silently
  overwritten the base family's `[350, 620, 670]`. Worked around by keeping
  only `height_mm` in the sink section, but the next section will meet it
  again. Fix: raise on conflicting family-level values instead of overwriting
  silently; the tests should carry a check for it.
- **M1.8 — Appearance layer.** registry/ucon_appearance.json working palette
  + UCONAppearance dictionary on units (outside the Contract namespace);
  front/carcass finish from the panel.
- **M1.9 — Elda round one.** Send Q1+Q2 (docs/Elda_Email_Draft_v0.2.md);
  on written answers move affected registry entries toward CONFIRMED.
- **M1.10 — Exporter — PRIORITY RAISED** — TARGET OUTPUT FORMAT is a real
  deliverable: the "Custom Elements" sheet (iso views + dimensions + structured
  machine-generated names), e.g. Bobby_410_Alta_Vista sheet 7/9. Emits catalog
  order codes for standard/modified units and generated structured names
  (see docs/Naming_Convention_Spec_v0.1.md) for non-catalog elements. (competitive review 2026-08-16:
  one-click cut list / order schedule is an expected baseline in peer tools,
  not a final flourish; and it feeds the order-ready goal directly). Walk a
  model, read the CabinetEngine dictionary off every unit, emit the factory
  ORDER schedule (CSV first): code, door version (78/75), gola profile lines,
  hardware, hinge side, W/H/D, status. NOT a joinery cut list — Cesar order
  lines. Can run against the current single-unit models; does not truly need
  a full layout first. Consider pulling ahead of M1.8/M1.9 once M1.7 lands.
- **M1.11 — Modified elements** (spec ready:
  `docs/Modifications_Design_Spec_v0.1.md`; registry `modifications` section +
  Elda Q3 already recorded). Build ONLY when a real project needs a modified
  unit. Base code immutable; modification codes (989xxx) attached additively;
  auto-marked on dimension divergence; contract invariant "diverged ⟺ has
  modification ⟺ PRELIMINARY"; validator enforces prohibited families + depth
  maxima; exporter emits the modification order lines. The anti-DC: additive
  data, no heavy editable object.
- **Naming convention** (spec: docs/Naming_Convention_Spec_v0.1.md) — the
  engine generates consistent structured names for non-catalog elements;
  this IS the identity the factory reads. Finalize token set with the factory.
- **Appliance placeholders** — client-appliance stand-ins (panel-ready), sixth
  tier of the non-standard spectrum; object_class=appliance_front already in
  the Contract. Build when a real project needs one.
- **US vs EU parameters** — the real sheet uses 19 mm (3/4") fronts, not the
  22 mm EU standard. Front thickness is market-dependent; fold into US Elements
  work and project defaults (M1.6).
- **Catalog edition stamp — PROACTIVE, do before first real delivery**
  (strategy: docs/Catalog_Update_Strategy_v0.1.md). Stamp `catalog_edition` on
  every built unit; cannot be retrofitted to models built without it. Cheap,
  additive (Contract v1.3); the exporter M1.10 needs it anyway. Catalog diff +
  model audit tools stay demand-driven (build when Cesar ships a new edition).
- **M1.12 — Bespoke elements** (spec ready:
  `docs/Bespoke_Elements_Design_Spec_v0.1.md`). Made-to-measure, no catalog
  code — the simplest object (a named box), the LAST resort after catalog
  fillers and modifications. Never a fake Cesar code (UCON-internal ref only);
  exporter emits the full made-to-measure spec; PRELIMINARY until factory
  feasibility. Build only when a real project needs one.
- **M3 — Multi-manufacturer** (strategy:
  `docs/Multi_Manufacturer_Strategy_v0.1.md`). Foundation ready (manufacturer
  is a Contract field; registry is per-manufacturer). Seams: standards move
  from core/10_standards.rb into per-manufacturer data; domain concepts
  (gola axis) become declared capabilities; picker gains a manufacturer level;
  exporter groups the order by manufacturer. Build when a real second factory
  is onboarded. Scenarios A-D in the strategy doc (incl. mixed brands in one
  kitchen, and UCON's own shop as a codeless manufacturer).
- **Later:** corner/waste/appliance H.78 pages; wall + tall sections; .rbz
  packaging (build step copies registry/ into the payload).

### 7.05 Will demand-driven growth break the foundation? (2026-08-16)

Honest layered assessment, so future work knows what is safe to touch.

**Load-bearing (redo almost never):** Object Contract, trust model,
CabinetEngine dictionary, code grammar, registry/code separation. Designed to
extend, not rewrite — already went v1.0 → v1.1 → v1.2 (added hinge_side and
order axes) with ZERO existing units broken. It knows nothing about specific
cabinet types, so new types cannot break it. Small on purpose: the less the
foundation promises, the less can be wrong in it.

**Data (cannot break by construction):** a new catalog section is a new file;
the loader merges it; existing sections are untouched. Safest layer, and the
one touched most often under the demand-driven plan.

**Tools — fluid, expect rework, that is their job:** generator, panel, symbols,
picker. "Foundation stable, tools fluid." Reworking a tool is a local swap in
core/ (minutes, tests stay green, foundation untouched) — e.g. the opening
symbols were rewritten ~4 times in one session with no ripple. This is what
"redo" costs here: a part swap, not a rebuild.

**Genuine rework risks (named so nobody is surprised later):**
1. **Corners / arrangement.** Placement today is a single-axis (X) shift.
   Corners need rotation and may force revisiting how a unit's position in a
   run is stored. `geometry_kind=corner` is already in the Contract, but this
   logic cannot be truly validated until a real corner exists — a placement
   refactor is plausible there (M2.2). NOT a foundation change.
2. **First genuinely new object class.** Everything so far is a rectangular
   floor cabinet. A sink with a bowl, a carousel corner, a shaped worktop may
   show a current geometry simplification was too narrow — that grows
   `30_geometry.rb` by one case, not a rebuild.

**What actually protects against "redo everything":** 77 headless tests (break
the foundation, know in seconds); physical layer boundaries (a tool rework
cannot reach data or contract); git + small commits (every change reversible).

**The one thing that could force a big redo:** discovering the Contract failed
to anticipate something fundamental (an object no `geometry_kind` describes).
Mitigated by keeping the Contract small and source-verified; no cracks in 2
days / 74 codes so far. If it ever happens: versioned migration, not rewrite.

### 7.1 Auto-arrangement track (added 2026-08-16)

Source: `docs/Autoarrangement_Note_v0.1.md` (project note). Status against it:
the foundation it demands — catalog as data, separate from code — is DONE
(registry/cesar/, JSON sections; its open question "catalog.rb vs catalog.json"
is resolved by reality). A seed of the straight run also exists:
build-next-to-selected chains units flush along X, inheriting the run's
orientation and snapping to the floor.

Milestones, in the note's own order (straight run before corner, corner
before interactive):

- **M2.1a — Batch row builder.** Dialog takes an ordered list (codes +
  quantities) + start point; builds the whole run in one operation. Covers
  the real workflow: kitchen composition is known from the spec. Includes
  the shared-plinth decision (one continuous plinth strip per run vs butted
  per-unit plinths - note leans continuous; hidden plinth ends already make
  butted read as one).
- **M2.1b — Worktop.** One slab over the run (open question in the note:
  part of arrangement or separate step - decide at M2.1a review).
  **Sink bowl decision (2026-08-17, settled while modelling 545 Avenida
  Primavera).** The bowl belongs to the worktop layer, not to the unit: in
  the catalog it lives in Linear Elements (integrated bowls TOPDR/TOPMO/TOPSH,
  block sink LAVBL), so the worktop module draws it. It is drawn as a SYMBOL
  on the existing hideable plan/front tags, not as a solid - the deliverable
  is a wireframe sheet, and the "carcass top shows through the bowl" problem
  only exists in shaded 3D. Two options were rejected: building the sink
  carcass without its top face (breaks the envelope-is-one-volume invariant
  and puts a sink exception into 30_geometry.rb), and having the worktop
  boolean-cut the unit (mutates geometry, so the object stops matching its
  code and cannot be rebuilt from it - the heavy editable object we rejected
  with Dynamic Components). If a solid bowl is ever needed for a render, it
  is a separate display-only copy; the unit is never mutated.
  Bowl configuration by unit width - single on narrow, symmetric double on
  wide, asymmetric double (one small bowl, one standard) in between - is a
  UCON drafting convention at PLANNING trust, NOT a Cesar fact: it only
  chooses the default symbol, never an order line, and its width thresholds
  live in data, not in code. The bowl's article code comes from Linear
  Elements, source-verified, when the order needs it.
  Identification note: a sink base is externally indistinguishable from a
  plain base (sink B81087 and plain B81057 are both 1050 wide, d.62, and both
  split 390/390), so until this symbol
  exists the Outliner instance name is how a sink is recognised in a model.
- **M2.2 — Corner as hinge.** Requires the corner pages first (corner base
  units printed p.42-43 / PDF 44-45, corner sink bases printed p.46 / PDF 48;
  AU/AW/A81171 codes; geometry_kind=corner already in the Contract).
  The corner unit comes FROM THE CATALOG - its record defines how run B
  turns 90 degrees off run A. Open: per-corner-type joining rules
  (diagonal / L / carousel), Y inheritance through the turn.
- **M2.3 — Interactive placement tool** (SketchUp Tool API, onMouseMove
  drag-out) - last, once geometry is settled. Batch covers the drawing
  workflow until then.

North star from the note, worth keeping verbatim: the goal is presentation
CAD sheets in LayOut (wireframe, four views: front / plan / side / iso) -
data quality and correct run geometry over 3D richness. The engine's
envelope-only + symbols-on-tags representation is already aimed there.

---

## 7.2 Status update — 2026-08-17 (session close)

Core **v0.23.0**, **136 headless checks**, registry **126 codes** in three
sections of family H.78.

**Shipped this session, in the order the model demanded it:**

- **M1.7 completed for printed p.44** — `sink_base_h78.json`, 20 codes in four
  unit types. The thesis held: a new section file unfolded new picker levels
  with ZERO changes in `core/`.
- **Catalog map + picker gaps.** `_manifest.json` → `catalog_map` records what
  the printed index says exists, at per-PAGE and per-POSITION granularity
  (`extracted | partial | not_extracted | planned | excluded`), and the picker
  renders it as inert grey rows. A gap is now never mistaken for an oversight.
  Human companion: `docs/Catalog_Section_Map_H78.md`.
- **Printed p.36 completed**, plus pull-out door and laundry basket units.
- **Appliances (printed p.47).** Contract **v1.3** added `companion_refs` (a
  catalog choice can mandate companion order lines); **v1.4** added
  `object_class: appliance`. An appliance is TWO objects: the Cesar panel
  (`appliance_front`, ordered and drawn) and the machine's niche (`appliance`,
  `manufacturer=client`, drawn and never ordered).
- **Trash & Recycle** (P-One and XL / Envi Space) with their bin kits as
  companions.
- **Corner base units (printed p.42) — DECODED AND BUILDABLE.** 9 sizes x 2
  executions = 18 real articles; no template can reach an order. The letter is
  the EXECUTION, the door's LH/RH is the ordinary per-order `hinge_side`; the W
  notation is the corner NODE (depth + 80 across, nominal length along the
  wall) and nominal minus carcass is WASTED SPACE, drawn as edges only on its
  own tag. Corner PLACEMENT is still M2.2 — a corner unit builds, a run does
  not yet turn.
- **Drawing conventions settled:** surfaces mean ownership (Cesar objects have
  faces, stand-ins for what is not ours are edges only); the opening symbol's
  base sits on the hinge axis and its apex on the opening edge (so bottom-hung
  reads as an inverted V); plan symbols are drawn at the FLOOR for every unit.
- **Printed p.1-17 read** (technical and dimensional information). It confirmed
  the corner model independently — p.10's RH plan diagram IS our D execution,
  and the geometry matched with no change — and produced
  `docs/Clearance_Rules_H78_v0.1.md` (5 cm closing strips, corner filler
  minimums, modification limits), a d.57 corner gap, and Elda **Q7**.

**Open questions now Q1-Q7** (`docs/Elda_Open_Questions_v0.1.md`). Q7: does
"1 rh or lh door" name the door's hinge or the cabinet's execution, given the
code already carries D/S and p.10/p.11 draw RH while p.42 draws LH.

**Next session: WALL CABINETS.** Scouted, not extracted. The wall-unit chapter
has its own contents index at printed p.205 and a visual D x W index at printed
p.206-210; the sections themselves run **printed p.211-256** (PDF = printed + 2,
verified against the footers: printed 211 = PDF 213):

| printed | section |
|---|---|
| 211 | Wall units H. 36 |
| 213 | Dish-drainer units H. 36 |
| 214 | Wall units H. 48 |
| 217 | Dish-drainer units H. 48 |
| 219 | Wall units H. 48 with Virgola hood |
| 221 | Wall units H. 60 |
| 224 | Dish-drainer units H. 60 |
| 226 | Wall units H. 60 with Virgola hood |
| 227 | Wall units H. 60 with Virgola No Drop hood |
| 228 | Wall units H. 72 |
| 232 | Dish-drainer units H. 72 |
| 234 | Wall units H. 72 with Virgola hood |
| 236 | Wall units H. 72 with Virgola No Drop hood |
| 238 | Wall units H. 84 |
| 241 | Dish-drainer units H. 84 |
| 243 | Wall units H. 84 with Virgola hood |
| 244 | Wall units H. 84 with Virgola No Drop hood |
| 245 | Wall units H. 96 |
| 248 | Dish-drainer units H. 96 |
| 250 | Wall units H. 96 with Virgola hood |
| 251 | Wall units H. 96 with Virgola No Drop hood |
| 252 | Wall units H. 120 |
| 255 | Wall units H. 120 with Virgola hood |
| 256 | Wall units H. 120 with Virgola No Drop hood |

Seven height families (H.36 / 48 / 60 / 72 / 84 / 96 / 120), depth D.35 on the
index pages, and unit types already visible in the index text: wall unit with
door, with doors, with glass door(s) ("Cannot be reduced"), with top-hung
doors. The page notice reads "The handles are not included in the price".

What wall units will demand that base units did not, and should be decided
BEFORE extracting:

1. **Z placement.** A wall unit hangs; it has no plinth and no floor snap. The
   engine's floor snap and build-next-to-selected assume a base run. A hanging
   height is a project default (M1.6), not a catalog fact — the catalog gives
   the unit's height, not where it goes on the wall.
2. **Top-hung and glass doors** are new opening kinds for `70_symbols.rb`. The
   hinge-axis rule already covers them (base on the hinge axis, apex on the
   opening edge), so a top-hung door is the mirror of the bottom-hung Λ we
   built for the dishwasher and the laundry unit — reuse, do not reinvent.
3. **The 5 cm closing strip rule** (`docs/Clearance_Rules_H78_v0.1.md` §1) is
   written ABOUT wall units. It is the first rule where `hinge_side` changes
   the plan, not just the symbol. Still PLANNING — do not implement it as an
   auto-insert.
4. **A new height-family grammar.** H.78's depth digit (7/8/9 = d.35/62/67) is
   family-specific by rule; wall codes must be decoded from explicit registry
   rows, never by analogy.
5. **Hood variants (Virgola / Virgola No Drop) are probably out of scope** for
   the first pass — decide per position, as we did on printed p.47, rather than
   taking or skipping whole pages.

First concrete step next session: add the wall sections to `catalog_map` as
`not_extracted` so the picker shows the whole chapter as grey rows, then
extract ONE page (printed p.211, Wall units H. 36) and let the demand of the
real kitchen choose the next.

---

## 7.3 Status update — 2026-08-26 (modifications parked, panels started)

### M1.11 — Modified elements: the design questions, answered but NOT built

Andriy proposed the UI: a **Modification** button on the palette → select an
object → a floating menu with width / height / depth and a comment field; the
same for a panel. Discussed 2026-08-26, **deliberately parked** in favour of
panels. What the discussion settled, so it is not re-litigated later:

1. **A button must not be what makes something a modification.** The spec's own
   rule (`docs/Modifications_Design_Spec_v0.1.md`) is that *divergence itself*
   is the trigger — a dimension that differs from the catalog standard attaches
   its `989xxx` code and drops the unit to PRELIMINARY, with no mode switch and
   no "make modifiable" click, precisely so it cannot be forgotten. The floating
   dialog is a fine way to TYPE the numbers. It must not be the thing that
   decides they count.
2. **The dialog must rebuild through the registry, never scale geometry.** The
   fault found the same morning in six `SD0631` — a unit changed and its fronts
   stayed the old size — is exactly what stretching a group produces, and it
   would also lie about shelves, plinth and cutout rails. The dialog calls
   `Generator.build` with a modified unit hash.
3. **The comment field needs a home that survives a rebuild.** Contract v2 §1.1
   is a closed key list, so a human comment is a contract amendment, not a free
   attribute — and it must be excluded from anything that regenerates geometry.
   A comment eaten by the next rebuild is worse than no comment field.
4. **Correction to an earlier claim in this repo's conversation:** depth was
   said to have no modification path. It does. Reduction is coded
   (989350 base/wall 92 pts, 989360 tall 143 pts) with limits D.350 → −20,
   D.620 → −90, D.670 → −40; increase exists for a side panel only, 62→67→72→77
   at 41 pts a step (printed p.549). What is missing is the wiring, not the
   path.

Unchanged from the original M1.11 entry: base code immutable, `989xxx`
additive, the invariant "diverged ⟺ has modification ⟺ PRELIMINARY", the
validator enforcing prohibited families and depth maxima, the exporter emitting
the modification order lines.

### M1.13 — Panels (NEW, in progress) — driven by the island

Recon: `claude/findings-2026-08-26-panels-recon.md`. The chapter is
"Fillers – End elements", printed p.436–449, plus the 1,8 surcharge at p.551–553
and the depth-increase surcharge at p.549.

The recon's load-bearing finding: **"a panel" is three different things**, and
only one is an object.

- **2,2 cm adjoining end side panel** — real article codes, a separate ordered
  piece, joined at 45° to the door. *This* is what the module generates. Its
  back-to-back depth groups (35+35 → d.75, 62+35 → d.102, 62+62 → d.129) are
  what an island needs.
- **1,8 cm finishing side panel** — printed p.553 is titled "Replacing standard
  side panel". No code; a surcharge by height × depth × price band. Under rule 4
  it draws NOTHING new, because the carcass already occupies that volume. It
  belongs to the properties panel as a flag + order line, not to a generator.
- **Custom panel per m²** — `DZAK22` / `DZAC00`, which are Metron *estimate*
  codes and do not appear in the price list. The last resort, and the honest
  label for what we drew beside the fridge.

Consequences already accepted:

- `object_class: 'panel'` has existed in the Contract since v2 and nothing has
  ever built one; the fridge-bay panels were a hard-coded table inside a probe.
  Getting them out of the probe and into the registry is part of this milestone.
- ~~A panel is handed and it is joined to a specific door. Printed p.440 (hinges
  on the 45° side) and p.441 (hinges opposite) are **different articles**, so
  the hand is a choice, never a guess.~~ **WRONG, corrected the same evening by
  the first lookup against the real kitchen.** The two pages of a collection
  price **disjoint** depth groups, so there is never a choice between them; and
  which groups fall on which page **changes between collections**, so the banner
  does not mean "back-to-back" either. What the second page's banner means is
  **Elda Q22**. The depth group picks the code. Account:
  `claude/findings-2026-08-26-panels-recon.md` §9.1.
- Code grammar is per depth group with drifting suffixes (`0030` / `0130` /
  `0077` / `0087` / `0097` / `0107`). Explicit registry rows only.

New Elda questions: **Q20** (p.436 labels d.102 and d.107 both "62+35"; codes
and arithmetic say d.107 is 67+35), **Q21** (whether the printed `d.` is the
overall assembly depth including door faces, which is what everything drawn
depends on) and **Q22** (what the second page's banner means, given that the two
pages never price the same depth group).

And one question the model itself raised: an **unprinted height increase orphans
its end panel**. Two `SD0631` at H.720 and `UCON-BESP-001` at H.313 have no
finishing panel at any depth, because the catalog prices none at a height it does
not print. Q11's consequence, and it needs its own answer.

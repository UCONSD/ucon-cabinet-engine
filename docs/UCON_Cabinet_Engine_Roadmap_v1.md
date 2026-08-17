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
- **M1.7 — Sink base H.78 section** (printed p.46-48): first proof that a new
  section file unfolds new picker levels with zero code changes. P1 units.
- **M1.7a — Registry-drawn picker thumbnails** (paired with M1.7, from the
  EasySketch review 2026-08-16). Inline SVG mini-elevations generated in the
  picker from front_layout data - our own drawing convention (dashed V /
  diagonals), real proportions: type tiles get a schematic, the result card
  gets the actual code's W:H. NO static image assets ever - thumbnails derive
  from the registry, so every new section draws its own. Corner types will
  render a plan-view schematic (geometry_kind=corner); appliance/sink
  pictogram hints become an optional registry field when those sections are
  extracted. Cost: ~60-80 lines JS in picker_html + front_layout passthrough
  in Registry.catalog. Also adopted from that review, unscheduled: Smart
  Right Click (context menu on a unit: panel / flip hinge / door version)
  and saved unit variants (code + options preset, extends M1.6 defaults).
  Rejected from it: static asset libraries, door animations (a wireframe
  LayOut sheet needs symbols, not motion). EasySketch's model (generic
  free-sized cabinets, pretty pictures, manual translation to a factory
  order) is the opposite of ours (article-coded, source-verified,
  order-ready) - UX patterns borrowed, data model deliberately not.
- **M1.8 — Appearance layer.** registry/ucon_appearance.json working palette
  + UCONAppearance dictionary on units (outside the Contract namespace);
  front/carcass finish from the panel.
- **M1.9 — Elda round one.** Send Q1+Q2 (docs/Elda_Email_Draft_v0.2.md);
  on written answers move affected registry entries toward CONFIRMED.
- **M1.10 — Exporter — PRIORITY RAISED** (competitive review 2026-08-16:
  one-click cut list / order schedule is an expected baseline in peer tools,
  not a final flourish; and it feeds the order-ready goal directly). Walk a
  model, read the CabinetEngine dictionary off every unit, emit the factory
  ORDER schedule (CSV first): code, door version (78/75), gola profile lines,
  hardware, hinge side, W/H/D, status. NOT a joinery cut list — Cesar order
  lines. Can run against the current single-unit models; does not truly need
  a full layout first. Consider pulling ahead of M1.8/M1.9 once M1.7 lands.
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
- **M2.2 — Corner as hinge.** Requires the corner pages first (printed
  p.44-45, AU/AW codes; geometry_kind=corner already in the Contract).
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

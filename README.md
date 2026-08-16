# UCON Cabinet Engine

**Org:** UCONSD · **Status:** Foundation build (pre-1.0) · **Updated:** 2026-07-29

A parametric SketchUp toolset that generates architectural placeholder cabinetry
matching manufacturer catalog dimensions (starting with **Cesar**), with automatic
catalog article-code assignment. It replaces *"search a thousand-item catalog"* with
*"generate the coded model on demand."*

This is a research/build project, moving one step at a time. The foundation is built to
be stable; the tools on top of it are expected to be reworked as we learn, so rework
stays cheap.

---

## What this is (and is not)

**Is:** a controlled, source-based system for producing preliminary, coded cabinet
models and the schedules that go with them — for layout, technical planning, and
preparing questions for factory confirmation.

**Is not:** a pricing system, an ordering system, a production-release system, or a
confirmation of current product availability. Codes it produces stay **PRELIMINARY**
until a human confirms them.

## Scope boundary

The larger kitchen lifecycle runs: Concept/Preliminary Design → Design Development →
Elda/Giorgio Confirmation → quote → pricing → order → production → delivery → install.

**The Cabinet Engine covers only the first three stages** — Concept/Preliminary Design,
Design Development, and Elda/Giorgio Confirmation (Level 4). Everything after L4 (quote,
pricing, order, production, delivery, install) lives in a **separate project** and is
deliberately out of scope here.

## The four-level trust model

Every fact the system holds carries a trust level, expressed through the `status`
attribute (defined in the Object Contract):

1. **Source** — read from a manufacturer catalog / price list PDF. Primary authority for
   dimensions, module structure, technical rules, and article codes.
2. **Control** — captured into a controlled register (the source-extract layer) with
   provenance back to a source PDF section.
3. **SketchUp Planning** — instantiated as a placeholder component in a model; still
   preliminary.
4. **Elda Confirmation** — reviewed and confirmed in writing by Cesar / DzineElements
   (Elda / Giorgio). This is the last stage inside scope.

The source of truth is always the manufacturer PDF. A register row, a workbook, or a
generated model **never overrides** a restriction, note, or dimension in the source. When
they disagree, the PDF wins and the discrepancy is logged.

---

## Current state (honest snapshot)

**Built — the source-control layer:**

- A source hierarchy (five levels of authority) and priority tagging (P1/P2/P3) for
  register rows.
- Ten Cesar catalog source-extracts (Base Units, USA Elements, Tall Units, Wall Units,
  Fillers/End Elements, Plinths/Handles/Grip Recesses, Modifications/Customisations,
  Interior Accessories/Mechanisms, Lighting, Linear Elements) as paired `.md` + `.xlsx`
  registers.
- An Elda / DzineElements questions register and first-pass confirmation package.
- SketchUp component scope + schedule drafts, and pilot-extraction scope docs.

This material currently sits outside the repo (in `raw_dump/`) and will be staged into
`sources/` as read-only reference once curated (duplicates dropped, versions pinned).

**To be built — the engine core (this repo's near-term work):**

- `docs/UCON_Object_Contract_v1.md` — attribute schema, component structure,
  rules-registry format, `status` vocabulary. Load-bearing.
- `docs/UCON_Data_Levels_v1.md` — the four-level trust model formalized and mapped to
  `status` (subsuming the existing source hierarchy + P1/P2/P3).
- `registry/cesar.json` — Cesar rules as data, in the format the Contract defines,
  verified against the source PDFs.
- `src/` + `tools/` — the H.78 generator, reverse code decoder, class-agnostic exporter,
  and a verify tool.
- `skills/catalog-extraction/` — the catalog-extraction SKILL.

> Earlier project notes described some of these as already done. They are **not yet
> present as files** — this repo is where they get authored, foundation first.

---

## Repository structure

```
ucon-cabinet-engine/
├── README.md                     # this file
├── docs/                         # foundation documents (load-bearing)
│   ├── UCON_Object_Contract_v1.md
│   ├── UCON_Data_Levels_v1.md
│   └── UCON_Cabinet_Engine_Roadmap_v1.md
├── registry/                     # manufacturer rules as data
│   └── cesar.json
├── src/                          # Phase 1 Ruby tools (script-based)
│   ├── generator/                #   forward: params -> coded component
│   ├── decoder/                  #   reverse: code -> params
│   └── exporter/                 #   class-agnostic factory-code schedule
├── tools/
│   └── verify/                   # check generated codes against source
├── skills/
│   └── catalog-extraction/       # catalog-extraction SKILL scaffold
└── sources/                      # existing source-control layer (read-only ref)
```

## How we work

- **Foundation stable, tools fluid.** The Object Contract changes only via a versioned
  migration; the tooling above it is free to be reworked.
- **Concrete on the near step, loose on the far ones.** One committable change at a time.
- **Verify against the source PDF; never override it.**
- **Codes stay PRELIMINARY until human confirmation** (Level 4).
- **Ask before assuming catalog facts.**

## Roadmap

See [`docs/UCON_Cabinet_Engine_Roadmap_v1.md`](docs/UCON_Cabinet_Engine_Roadmap_v1.md)
for the two-phase plan (Phase 1: solo / script-based; Phase 2: plugin) and current
milestones.

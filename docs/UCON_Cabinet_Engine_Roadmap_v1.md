# UCON Cabinet Engine — Roadmap v1

**Org:** UCONSD · **Document role:** Two-phase build plan and milestone register
**Version:** v1 · **Date:** 2026-07-29 · **Status:** Active planning document

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

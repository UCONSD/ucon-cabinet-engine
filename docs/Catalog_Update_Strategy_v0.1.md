# Catalog update strategy v0.1 — 2026-08-16

What we do when the factory (Cesar) releases an updated catalog edition. NOT
YET IMPLEMENTED (tooling is demand-driven); one small proactive item flagged.

## Core principle

A new catalog is a DATA event, not a code event. The catalog is versioned
data, separate from the engine; `_manifest.json` carries `catalog_edition`.
A new edition = new/updated section files, re-verified against the new PDF.
The generator, panel, picker and symbols do not change. This is the payoff of
"foundation stable, data fluid" — a catalog change is an update, not a
rewrite. Object Contract §4 already anticipates in-place code updates.

## The real risk: existing models

The danger is not the engine — it is already-saved .skp files. A model built
today embeds `CabinetEngine` attributes ("B80601, verified against 2021
catalog") that were TRUE against the catalog they were built with. The harm is
re-exporting / ordering an OLD-catalog model against a NEW catalog where a code
changed dimensions or was discontinued. A model must never silently become
wrong.

## Actions when a new edition drops (demand-driven, section by section)

1. **Re-extract and verify against the new PDF — only the sections in use.**
   Same "never assume" discipline: a new catalog is a re-extraction job, page
   by page, not "trust that the old data still applies."
2. **Diff old vs new**, never blind-replace: discontinued codes, changed
   dimensions, new units, changed modification/hardware rules. This diff tells
   you which existing models need review.
3. **Confirmations reset.** Units CONFIRMED against the old edition drop to
   PRELIMINARY until re-checked — the trust model applied to editions.
4. **Audit existing models: flag, do not rewrite.** A tool walks a model,
   reads each unit's catalog edition, flags units whose code changed or
   vanished. The designer decides per unit. The engine never silently
   rewrites an approved/ordered model.

## The one proactive item (cannot be retrofitted)

Stamp `catalog_edition` on every unit at build time. A model built without it
cannot later be audited by edition — provenance does not retrofit. Cheap,
additive (future Contract v1.3). NOT urgent now (all current models are test
builds, nothing to lose), but **must be in place before the first real
delivered model.** The exporter (M1.10) needs it anyway — natural place to add
it. Everything else here (diff tool, audit tool) waits for a real new edition.

## Tooling (build when a real new edition arrives)

- **Catalog diff** (edition A vs B): discontinued / changed-dims / new /
  changed-rules.
- **Model audit**: walk a model, flag units whose edition != current or whose
  code changed/vanished; human decides per unit.

## Contract note

`schema_version` versions the CONTRACT, not the catalog — a separate axis.
Add `catalog_edition` per unit (additive, v1.3, alongside modifications and
bespoke). §4 already handles individual Elda code corrections in place; a
whole-edition change is the bigger case this strategy covers.

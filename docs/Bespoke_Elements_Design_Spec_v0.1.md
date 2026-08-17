# Bespoke elements design spec v0.1 — 2026-08-16

Design for made-to-measure elements with NO catalog code. NOT YET IMPLEMENTED
— build only when a real project needs a bespoke element (demand-driven).
Companion to docs/Modifications_Design_Spec_v0.1.md.

## The counterintuitive point

A bespoke element is the SIMPLEST object in the system, not the hardest. A
catalog cabinet carries doors, gola, hinges, drawer stacks, source
verification. A bespoke element is a named box: W×H×D, material, done. No door
logic, no profiles, no article code. The generator already builds boxes.
Discipline: it is a box and stays a box — do not grow it into a cabinet-scale
subsystem.

## Buildability ladder (the real purpose — 2026-08-16, from a real sheet)

Custom elements are NOT a production spec — they are a COMMUNICATION to the
factory, which re-models them (Metron, then production software). The goal is
"do not complicate the factory's life." When an element is custom, the
decision ladder is:

1. **Factory builds it** — if they understand the drawing and can make it.
2. **Change the plan** — avoid needing the custom element at all.
3. **Simplify the element** — make it factory-friendly.
4. **Order extra sheet material and fabricate it ourselves (UCON)** — backstop.

Consequence for design: model the MINIMAL, factory-communicable description,
not the maximal one. Complexity in a bespoke element is a smell — it usually
means option 1 is at risk, so prefer 2/3, or accept 4. The engine's job is a
clear, consistently-named, dimensioned box — not a production-accurate model.

## What defines it

No catalog article code. That is the whole distinction from a modification.
A modification starts from a catalog cabinet (base_code + 989xxx) and stays a
catalog product with sanctioned changes. A bespoke element starts from
nothing — UCON/the designer defines it, the catalog does not.

## The non-standard spectrum (bespoke is last)

1. European standard code — as-is (a catalog section).
2. US Elements — a catalog section (extract exists; not yet a registry section).
3. Catalog filler / end / open units — Cesar has this section (printed p.457);
   simple infill panels often EXIST here with codes. Reach here FIRST.
4. Modified standard — base code + 989xxx (M1.11, spec ready).
5. **Bespoke / made-to-measure — no code, UCON-defined.** The simplest object,
   used when nothing catalog-traceable fits (subject to the buildability
   ladder above).
6. **Appliance placeholder — a stand-in for the client's own appliance**
   (e.g. DACOR_42_FOUR_DOOR_PANEL_READY_PLACEHOLDER), not cabinetry. Panel-ready
   so panels plan around it. object_class=appliance_front / geometry_kind=non_dim
   (already in the Contract). No Cesar code; brand+model in the name.

## Two safety rules (mirror of the modification danger)

Modification danger was "factory makes standard." Bespoke dangers:

1. **Never a fake Cesar code.** A bespoke element carries at most a
   UCON-internal reference (e.g. `UCON-BESP-001`), never a catalog article
   code — so it is never confused with a catalog product.
2. **Exporter must emit the full spec.** There is no code to look up, so the
   order line is descriptive: name, W×H×D, material, made-to-measure, clearly
   separated from catalog code lines.

## Contract treatment (honest — a real gap)

The trust model (SOURCE < CONTROL < PLANNING < CONFIRMED) is catalog-centric:
it verifies against the source PDF. A bespoke element has NO catalog source.
Its authority is "designer-defined + factory feasibility", a different axis.
So a bespoke element is PRELIMINARY by definition until the factory confirms
it can be made (same "check feasibility with Cesar" master rule as
modifications). Needed rule (future Contract v1.3, with modifications): an
object with no catalog code cannot claim a catalog CONFIRMED; its status means
"design intent", not "catalog trust".

The Contract is already half-ready: `object_class` includes `filler`,
`panel`, `accessory`; `code` is optional; `geometry_kind` includes `non_dim`.

## Design (keep it minimal)

- `object_class`: `panel` / `filler` / `cabinet` (bespoke), as fits.
- `code`: empty, or a UCON-internal ref — never a Cesar code.
- New flag/status marking BESPOKE; PRELIMINARY until factory feasibility.
- Dimensions from the user; material from the appearance layer (M1.8).
- Panel gets a "New bespoke element" flow: name, W×H×D, material, optional
  simple front. No door/gola/drawer logic.
- Visible on-screen marker so bespoke reads as bespoke.
- Exporter: descriptive made-to-measure order line.

## Scope

Simple boxes/panels only ("usually simple"). Anything with real cabinet
complexity should be a catalog unit or a modification, not bespoke. If a
bespoke element starts wanting doors/drawers, that is a signal to look for a
catalog match instead.

## Roadmap

M1.12 — build only when a real project needs a bespoke element. Menu item,
not a queued step.

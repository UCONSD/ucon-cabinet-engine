# Pianca (Armadi / Cabine) — source-verified reconnaissance (2026-08-18)

Third companion doc, alongside `claude/ucon-cabinet-engine-status.md` and
`claude/wall-units-recon-2026-08-18.md`. Everything below is READ FROM THE
SOURCE PDF `2023_TECHNICAL-BOOK_Armadi-Cabine-Pianca-LR.pdf` (Adobe InDesign
18.3, created 2023-06-07, 134 PDF pages, 41 MB, text layer present).
Trust level: SOURCE.

**Landed in the repo: NOTHING.** No registry directory, no `catalog_map` rows,
no core change, no version bump. This document is the whole deliverable of the
session. See §"Why nothing landed" for the reason.

## Page numbering — DIFFERENT FROM CESAR

The Cesar Kitchen System PDF is one printed page per PDF page (PDF = printed
+ 2). **This book is spreads: two printed pages per PDF page.**

```
printed_left = 2 × PDF − 4          printed_right = printed_left + 1
```

Verified on footers: PDF 96 carries printed 188 / 189. PDF 116 carries
printed 228 / 229. Cite PRINTED, as always, but do not reuse the Cesar offset.

`pdftotext -f N -l N -layout` works (text layer is real); on the technical
pages the overlaid diagram labels interleave badly, so
`pdftoppm -jpeg -r 110 -f N -l N` and reading the image is the reliable way
to check a technical spread.

## Chapter map (printed p.2-3 index, verbatim structure)

| printed | chapter |
|---|---|
| 4 | Introduzione |
| 6 | **Armadi / Wardrobes** |
| 8 / 16 / 24 / 32 / 40 / 48 | Amalfi · Cornice · Crea · Icona · Manhattan · Milano |
| 56 / 64 / 72 / 88 / 96 / 104 | Murano · Nastro · Plana · Raggio · Tratto · Verona |
| 112 / 118 | Anta TV · Home Office |
| 126 | **Cabine e complementi / Walk-in closets** |
| 128 / 140 / 152 | Anteprima · Sipario · Teatro |
| 164 / 172 / 180 | Teatro con anta Murano · Vista · Island up |
| 188 | **Info tecniche / Technical info** |

The pages before 188 are photography and finish plates. **All dimensional data
lives in the technical section, printed 188 onward.**

### Technical section, page by page (verified by direct read)

| printed | content |
|---|---|
| 188-189 | Amalfi |
| 190 / 191 | Cornice / Crea |
| 192 / 193 | Icona / Manhattan |
| 194 / 195 | Milano / Murano |
| 196 / 197 | Nastro / Plana |
| 198 / 199 | Raggio / Tratto |
| 200 / 201 | Verona (by Calvi Brambilla) / Anta TV |
| 202-203 | Internal finishes (Base, Top, Shelves, Internal sides, Backs, Partitions) |
| 204-221 | Internal accessories: shelves, partitions, drawer units, hangers, shoe shelves, pull-out frames, mirrors, LED, interior configurations |
| 222-227 | **Moduli speciali / Special modules** (19 items) |
| 228+ | Walk-in closets: Sipario, Anteprima, Teatro |

**Home Office has no located technical page.** Index lists it at printed 118
(photography). Not read — do not assume it shares Amalfi's table.

Every program but Verona is credited `by CRS Pianca`; **Verona is
`by Calvi Brambilla`.** If designer attribution ever matters for ordering, it
is per-program, not per-brand.

## THE LOAD-BEARING FACT: there are no article codes

Direct test across the whole extracted text layer:

- zero tokens matching `[A-Z]{1,3}[0-9]{3,6}` (the shape of every Cesar code)
- zero occurrences of `codice`, `code`, `listino`, `price list`

A Pianca item is identified by a **configuration tuple**, not a code:

```
program        Amalfi | Cornice | Crea | Icona | Manhattan | Milano |
               Murano | Nastro | Plana | Raggio | Tratto | Verona | Anta TV
opening        battente | cardine | scorrevole | complanare | soluzione angolare
L              discrete list, per program AND per opening
H              238,5 | 257,7 | 289,7 cm
P              RANGE 42,3 – 59 cm
```

and every position on every technical page is stamped **`Su misura / Made to
measure`** (36 occurrences). Depth is a continuum, not a family fact — the
opposite of H.78's d.35/62/67 lookup.

**This is also not a price list.** It is a Technical Book: no ordering data of
any kind. Whatever Pianca's order identity is, it is not in this document.
Getting the Pianca *listino* is a precondition for any exporter work, and
should be asked for before anything else is invested.

## printed p.189 — Amalfi, read visually (the reference table)

Five opening types. Widths are DOOR widths, not carcass widths.

| opening | P | H | L |
|---|---|---|---|
| Battente / hinged | 42,3-59 | 238,5 / 257,7 / 289,7 | 47,8 · 57,8 · 67,8 · 97,8 · 117,8 · 137,8 · **46,1 (Anta TV)** |
| Cardine / cardine hinged (180°) | 42,3-59 | 238,5 / 257,7 | 47,8 · 57,8 · 67,8 · 97,8 · 117,8 · 137,8 |
| Scorrevole / sliding | 42,3-59 | 238,5 / 257,7 / 289,7 | 67,8 · 97,8 · 117,8 · 137,8 · 147,8 |
| Complanare / flush-sliding | **59 only** | 238,5 / 257,7 | 206 · 246 · 286 · 306 |
| Soluzioni angolari | 42,3-59 | 238,5 / 257,7 / 289,7 | battente · cardine · **opposto (external opening)** |

Footnote exclusions are per-position, exactly the granularity `catalog_map`
already models:

- battente L 137,8 — not available at depth 42,3
- scorrevole L 137,8 / 147,8 — not available at H 289,7; door divided in 2 panels
- complanare L 286 / 306 — door divided in 2 panels
- angolari — `*` no depth 42,3 · `**` no height 289,7

Widths 96,4 / 116,4 / 136,4 appear once each elsewhere in the book — a second
width series exists somewhere and has not been traced. Do not treat the 47,8
series as complete.

Anta TV also carries square formats **110,7×110,7** and **94×94** (printed 201).

## What fits the engine and what does not — three tiers

### Tier 1 — Wardrobes (printed 188-201). Fits, better than expected.

Printed 189 is, literally, a sheet of plan symbols with dashed opening arcs —
the same drawing convention `70_symbols.rb` already produces. Envelope +
fronts + opening symbol covers it.

Two genuinely new things:

- **`complanare` (flush-sliding) and `scorrevole` (sliding) are not hinged
  doors.** The hinge-axis rule (base on the hinge axis, apex on the opening
  edge) does not describe a sliding leaf. This is the SAME open question
  already recorded for Cesar's push-up wall doors — one convention should
  settle both. Do not improvise one per manufacturer.
- **`cardine` opens 180°.** The swing arc is a half-circle, not a quarter. The
  symbol must read the opening ANGLE, which today is implicit.

`Soluzioni angolari` with `Opposto / External opening` is a corner-execution
distinction, conceptually the same shape as the H.78 corner base: the choice
names the execution, not the door's hand.

### Tier 2 — Walk-in closets (printed 228+). Does NOT fit. Exclude.

Anteprima / Sipario / Teatro / Vista / Island up are not cabinets. They are
component systems assembled from montanti (uprights), schienali (back panels),
cornici ad L / lineari / ad angolo, ripiani, pedane and cassettiere. You do not
place a box; you build a frame.

Anteprima's own dimension block (printed 232-235) gives L 50 / 70 / 90 / 110,
H 238,5 / 257,7 / 289,7, frames from 5 to 21 cm and 10×10 — i.e. the frame is
dimensioned, not the unit.

Teatro (printed 242-243) carries **composition rules**, paraphrased: modules
must sit between two open partitions; a terminal module may have open or closed
sides; each module needs at least one shelf; a composition in the middle of the
room needs modules with glass or wooden back and end side, and at least two
shelves each. Exact wording is on printed 242-243.

That is a constraint solver, not a picker. **`excluded`, reason: "component
system, not unit-based; composition rules require a solver".**

### Tier 3 — Internal fittings and special modules (printed 202-227). Deferred.

Internal finishes apply to Base, Top, Shelves, Internal sides, Backs and
Partitions (printed 202). Then 18 pages of hangers, drawer units, shoe shelves,
pull-out frames, mirrors, LED.

The 19 **Moduli speciali** (printed 222-227) are the ones worth naming, because
several have direct H.78 analogues and will eventually be asked for:

```
1  modulo stagionale          11  cabina angolare a soffietto
2  modulo per elettrodomestici 12  cabina terminale
3  modulo cassettiera esterna  13  modulo terminale a giorno
4  modulo con vano             14  modulo terminale a giorno con asta
5  modulo a ponte              15  modulo terminale
6  modulo Home office          16  angolo battente
7  modulo TV                   17  modulo sovraporta
8  anta TV scorrevole          18  pannelli per modulo centrostanza
9  angolo battente             19  modulo estraibile
10 angolo scorrevole
```

`modulo per elettrodomestici` is the appliance-niche problem again — Contract
v1.4's `object_class: appliance` split (Pianca panel ordered and drawn, machine
niche drawn and never ordered) should transfer unchanged.

## Why nothing landed

Wall units were a new CLASS inside an existing manufacturer. Pianca is a new
MANUFACTURER, and there is no manufacturer level anywhere in the stack:

- `50_registry.rb` loads `registry/cesar/` and merges non-`unit_types` keys into
  the FAMILY, last file wins by filename sort. A second manifest with its own
  `grammar` and `hardware` would silently overwrite. **The loader-hardening task
  already carried over in the status doc is now a hard blocker, not a nicety.**
- `90_palette.rb`'s `classes()` merges registry classes with map classes — all
  within one brand. Manufacturer would have to become the picker's zeroth level.
- Object Contract v1.4 keys identity on a code. Pianca has none.

Writing a `registry/pianca/` directory today would either be dead data that no
code reads, or live data that corrupts the Cesar family merge. Neither is worth
doing before the contract question is answered.

## Decisions taken this session

1. **No fork.** Pianca does not justify a second program or a second panel. A
   Pianca wardrobe and a Cesar tall unit can appear in one model; two panels
   would force the user to remember which panel placed what.
2. **Walk-in closets are out**, and should go into `catalog_map` as `excluded`
   the moment a `pianca` map exists — same treatment as the Virgola hoods.
3. **Pianca is not the next task.** Under demand-driven discipline it waits for
   a real project. The natural moment is *after* M1.10 (exporter), which forces
   the identity representation to be touched anyway.

## Open, not yet decided

- **Contract v2.0 shape.** Proposal to argue later, not now:
  `identity = { manufacturer, code }` for Cesar and
  `identity = { manufacturer, program, opening, L, H, D }` for Pianca, with a
  code understood as a factory-supplied shorthand for a tuple. Plus
  `dimension_mode: catalog | made_to_measure`, so a `su misura` range is
  validated as a range and never silently rounded.
- **Sliding / flush-sliding / push-up symbol convention.** One convention, three
  claimants (Pianca scorrevole, Pianca complanare, Cesar push-up).
- **Opening angle** as an explicit symbol property (cardine 180°).
- **The second width series** (96,4 / 116,4 / 136,4) — where it comes from.
- **Home Office** technical page — not located.
- **Pianca listino** — does not exist in this document. Ask Andriy's source.

## Practical notes

- The book is bilingual IT/EN and dual-unit: every dimension is given in cm AND
  inches (H 238,5 = 93.90"). Relevant to the US-vs-EU note in the status doc —
  Pianca already publishes an imperial face.
- `-LR` in the filename = low resolution. If a drawing ever needs to be measured
  rather than read, get the HR original.
- Heights 238,5 / 257,7 / 289,7 do not form an obvious module (deltas 19,2 and
  32,0). Do not derive; look them up.

# Catalog Section Map — Base units (Maxima / Intarsio)

Version 0.1 — 2026-08-17. Companion to `registry/cesar/_manifest.json` →
`catalog_map`, which is the machine-readable authority; this file is the same
information for human eyes. Page numbers are PRINTED pages (PDF = printed + 2).

## Why this exists

The registry holds what we have EXTRACTED. The catalog's printed index holds
what EXISTS. Until now the difference between the two lived nowhere, so a gap
was indistinguishable from an oversight. The map records the difference as
data: the picker greys out what is missing, and every future session can see
what is left without leafing through the PDF again.

## The catalog's own hierarchy

Six levels, and our picker deliberately mirrors the lower five:

| # | Catalog | Example | Engine |
|---|---------|---------|--------|
| 1 | Collection / door system | Maxima e Intarsio (p.19), Tangram (57), Unit (257), N_Elle (321), USA elements (409) | not modelled yet — the M3 seam |
| 2 | Element class | Base units; later Wall, Tall | `class` |
| 3 | Height family | H.39, H.48, H.58.5, H.78, H.84 | `family` |
| 4 | Family variant | plain / Sink / for household appliances | `section` |
| 5 | Unit type | "Base unit with doors", "Corner base unit" | `unit_type` |
| 6 | Depth × width | D.62 × W.45, 60, 75… | code rows |

**Rule that follows from this:** a placeholder may only be shown at a level we
have actually read in the source. Sections come from the printed index, so all
of them may be shown. Unit types come only from pages we have opened, so type
placeholders exist for H.78 and nowhere else. Showing H.84's types today would
mean inventing a structure we have not seen.

A second gift from the index: the visual D×W tables on printed p.20-22 list the
available depths and widths per type. That is a source-side completeness check
for any section we extract — a good future test, not yet written.

## Base units, section level (printed index p.19)

| Printed | Section | Status |
|---|---|---|
| 24-27 | Base units H. 39 | not extracted |
| 28-31 | Base units H. 48 | not extracted |
| 32-34 | Base units H. 58.5 | not extracted |
| 35 | Sink base units H. 58.5 | not extracted |
| 36-43 | **Base units H. 78** | partial |
| 44-46 | **Sink base units H. 78** | partial |
| 47-48 | Base units H. 78 \| for household appliances | p.47 mixed (3 excluded, dishwasher door planned), p.48 planned |
| 49-52 | Base units H. 84 | not extracted |
| 53-54 | Sink base units H. 84 | not extracted |
| 55-56 | Base units H. 84 \| for household appliances | not extracted |

H.84 is a separate `family`: its depth-digit grammar must be verified from its
own pages. H.58.5 already proves the point — there 6 = d.47 and 4 = d.62, not
the H.78 mapping.

## H.78 block, page level (printed p.36-48)

| Printed | Unit types on the page | Codes | Status |
|---|---|---|---|
| 36 | pull-out door · laundry basket · **door** · **doors** | 26 | partial (20 held) |
| 37 | door for interior drawer + jumbo kit · w/door and pull-out table ×2 · drawer and door | 12 | not extracted |
| 38 | drawer and doors · drawer and door · jumbo drawer and interior drawers | 16 | not extracted |
| 39 | jumbo drawer for P-One waste · pull-out XL waste · **drawers and jumbo drawer** | 23 | partial (18 held) |
| 40 | **jumbo drawers** · **drawer and jumbo drawer** | 36 | extracted |
| 41 | drawer and jumbo drawer (B7856x series) · built-in oven H.60 | 28 | not extracted — see caution |
| 42 | built-in oven H.60 · corner base unit · corner with Magicorner | 16 | not extracted (M2.2) |
| 43 | corner with Slidecorner · corner base unit rh+lh | 6 | not extracted (M2.2) |
| 44 | **sink: door · doors · w/jumbo drawer · w/jumbo drawers** | 20 | extracted |
| 45 | sink with fixed front + jumbo · corner sink with fixed front | 24 | not extracted — Elda Q4 |
| 46 | corner sink ×3 variants | 10 | not extracted (M2.2) |
| 47 | fridge/freezer housings · dishwasher door · washing machine door | 8 | 3 positions **excluded**, dishwasher door **planned** |
| 48 | door for integrated dishwasher | 6 | **planned** |

Held: 94 of 231 codes in this block.

### Caution — printed p.41

The codes there (`B78566`, `B88566`, `B98566`, …) do NOT decode with the p.36
width lookup, and the elevation reads 19,5 + 55,5 = 750 rather than 780. The
page's grammar has to be read from scratch before anything is extracted from
it. This is the manifest's warning made concrete: the config suffix and width
field are not globally uniform, and explicit rows are the only authority.

### Decisions are per POSITION, not per page (2026-08-17)

The first version of this map put status on the page, which meant a decision
could only ever exclude a whole spread. That was wrong: what gets excluded is a
type. A type in `catalog_map` may therefore be written either as a bare string
(meaning "same status as its page") or as an object carrying its own status and
reason. Printed p.47 is the case that forced it:

| Position on p.47 | Codes | Status |
|---|---|---|
| Floor-standing housing for fridge or freezer | V80601, V90601 | excluded |
| Base unit for built-in fridge-freezer | V80611, V90611 | excluded |
| Door for fully-integrated dishwasher | V80530, V80630, V80730 (+ GBBF01) | **planned** |
| Door for fully-integrated washing machine | V80640 | excluded |

Exclusions are UCON decisions at PLANNING trust — no current project orders
Cesar fridge housings or a washing-machine door — and are reversible the moment
a real kitchen asks. They are recorded so a future session reads a decision,
not an oversight.

### The dishwasher door is a KIT, not a single code

Choosing a dishwasher door mandates companion order lines. Same shape as the
gola rule (door 75 forces its `GOL` profile lines), second instance of the same
concept:

| Chosen door | Codes emitted |
|---|---|
| W45 | door + filler profile `995945` |
| W60 | door + filler profile `995946` |
| **W75** (p.47, V80730) | door + filler `995946` + **`GBBF01`** |

The filler profile ("between the dishwasher and the top", printed p.48) exists
only in W45 and W60 — a 75 door takes the W60 filler because the appliance
behind it is 60 wide. It is a strip: recorded, not drawn. `GBBF01` is the
opposite — a real 15 cm stainless steel box with the door-bearing mechanism, so
it is generated into the run (60 + 15 = 75). Which side it goes on is Elda Q5.

### Planned — the dishwasher door spans BOTH pages

The dishwasher door exists in two executions: fully-integrated on printed p.47
(V80530 / V80630 / V80730, plus `GBBF01`, a stainless steel cabinet with
door-bearing mechanism that the 75 cm version requires) and a second execution
on printed p.48 (V88559 … V88669). Both belong to one task together with the
dishwasher appliance placeholder, because they are one deliverable: the Cesar
order line is the DOOR, while the machine itself is the client's.
`object_class=appliance_front` already exists in the Contract; the placeholder
is the sixth tier of the non-standard spectrum in
`docs/Bespoke_Elements_Design_Spec_v0.1.md`.

Note also `GBBF01` — a code shape we have not met before (GB prefix, an
accessory sold with a door). One more reason not to assume the B-grammar
generalises.

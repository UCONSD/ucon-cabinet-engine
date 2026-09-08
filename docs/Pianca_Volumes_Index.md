# The Pianca shelf — which book holds what (2026-09-07)

Second manufacturer, second shelf. Fourteen files came off the dealer package
Troels Ostergaard sent on 2026-08-17 and now live in
`sources/factory/pianca/`, which is **git-ignored** like the Cesar volumes —
cloning gets the code, not the catalog. Copy them in by hand on a new machine,
and `ls -la sources/factory/pianca/` at the start of a session rather than
assuming the shelf.

## THE LOAD-BEARING CORRECTION: PIANCA HAS ARTICLE CODES

`docs/Pianca_Recon_v0.1.md` (2026-08-18) records, correctly, that the technical
book contains **zero** article codes and concludes that a Pianca item is
identified by a configuration tuple rather than a code. **The observation was
right and the conclusion was wrong, and the reason is which document was
searched.** The technical book is a technical book. The codes are in the PRICE
LIST, which was not on the shelf that day.

`PIANCA - 1 Night Systems 2023` alone carries **553 distinct codes** of the
shape `[A-Z]{2,4}[0-9]{2,6}`. This is the same lesson Cesar taught on
2026-08-26 in the opposite direction — *a code absent from the book you have is
not a code absent from the book* — and it has now happened once per
manufacturer.

**Consequence for the Object Contract: none.** The proposed v3 with
`identity = { manufacturer, program, opening, L, H, D }` existed only because
Pianca appeared to have no codes. It does. v2 keys identity on `code` and holds
unchanged.

## PAGE OFFSET — AND THERE ARE TWO OF THEM FOR ONE MANUFACTURER

**In the price lists: printed = PDF − 2**, the same as every Cesar volume.
Verified on the footers of PDF 10, 41, 50 and 100 of Night Systems, which print
`8_SIPARIO`, `SIPARIO_39`, `48_SIPARIO` and `98_SIPARIO`.

**In the technical book it is different**: that book is set as SPREADS, two
printed pages per PDF page, `printed_left = 2 × PDF − 4`
(`docs/Pianca_Recon_v0.1.md`). **Do not carry one rule across to the other
document.** Cite PRINTED pages, and name the file.

## The shelf

| | file | pages | what it is |
|---|---|---:|---|
| 0 | `PIANCA - 0 Technical Book Armadi-Cabine 2023 (LR).pdf` | 134 | **The technical book.** Wardrobes and walk-in closets: plan symbols, per-program dimension tables, internal accessories, special modules. **Spreads, not single pages — see the offset section** |
| 1 | `PIANCA - 1 Night Systems 2023 (+10%).pdf` | 375 | **WARDROBES AND WALK-IN CLOSETS.** Price list 03.09.2023. The one that matters |
| 2 | `PIANCA - 2 Night Collection 2023 (+10%).pdf` | 178 | Beds, wall panels, casegoods, desks |
| 3 | `PIANCA - 3 Day Systems 2023 (+10%).pdf` | 403 | Unless, Spazioteca, Spazio, People — living-room systems |
| 4 | `PIANCA - 4 Day Collection 2023 (+10%).pdf` | 236 | Chairs, coffee tables, tables, sideboards, sofas |
| 5 | `PIANCA - 5 Progetti di Design 09 price (+6%).pdf` | 80 | Price list 03.05.2025 — Clelia, Elide, Enea Up, Onda, Soffio Up, Mambo, Norma Up, Siviglia |
| 6 | `PIANCA - 6 Progetti di Design 08 price (+6%).pdf` | 28 | Earlier design-projects price list |
| 7 | `PIANCA - 7 Progetti di Design 06-07 price (+6%).pdf` | 52 | " |
| 8 | `PIANCA - 8 Price Chart Notte 01-02.pdf` | 4 | Finish update insert, night, from 01.09.2025 |
| 9 | `PIANCA - 9 Price Chart Giorno 01-02.pdf` | 4 | Finish update insert, day, from 01.09.2025 |
| 10 | `PIANCA - 10 Progetti di Design 09 catalogue.pdf` | 79 | Photography catalogue |
| 11 | `PIANCA - 11 Progetti di Design 09 presentation.pdf` | 25 | Presentation |
| 12 | `PIANCA - 12 Progetti di Design 09 text.doc` | — | Descriptive text, Word |
| 13 | `PIANCA - 13 Spazi Feb 2026.pdf` | 80 | February 2026 |
| 14 | `PIANCA - 14 Outdoor Collection.pdf` | 44 | Outdoor |

The `+10%` and `+6%` in the names are **price adjustments carried in the
original filenames**, kept so a figure read here is never mistaken for the
factory's own list price. Every file has a real text layer — `pdftotext` works;
all were produced by Adobe InDesign, most re-saved through iLovePDF.

**Editions do not agree, and that is a fact about the shelf**: the four 2023
price lists are 03.09.2023, the design-projects list is 03.05.2025, and the two
Price Chart inserts take effect 01.09.2025 and amend the 2023 lists. Whatever
becomes `catalog_edition` for Pianca is a stack, not a date.

## Volume 1 — Night Systems, the only one in scope today

Printed table of contents, verbatim structure:

| printed | chapter |
|---|---|
| 5 | SIPARIO structure and doors |
| 39 | Hinged door wardrobe modules |
| 54 | Hinged door wardrobe compositions |
| 76 / 82 | Cardine hinged door modules / compositions |
| 88 | Home Office |
| 101 / 116 | Sliding door modules / compositions |
| 138 | Sliding door wardrobes with TV door |
| 150 | Flush-sliding door compositions |
| 161-209 | **SPECIAL MODULES** — folding dressing closet, over-door and bridge, household appliances, seasonal, open elements, external drawer units, opposite corners, L-shaped and open end, pull-out with shelves |
| 213 | Internal accessories |
| **245** | **MADE TO MEASURE SOLUTIONS** |
| 257-363 | Walk-in closets: Sipario, Anteprima, Teatro, Island Up, Snake, Vista |
| 364 / 368 / 369 | Accessories / Ottone Anticato surcharge / General conditions |

It answers, page for page, the chapters the technical book draws. **Home Office
has a page here (88) and none located in the technical book.**

### The code grammar, as far as ONE page proves it

Read off the hinged-door compositions pages, and **the scope is that page**
(learned rule 4). Not verified across the book, and not to be generalised until
it is.

- **The first letter is the DEPTH.** The table prints two code columns headed
  `CODES D 59` and `CODES D 42.3`: `BA715` is the 59, `TA715` the 42,3. Same
  position, two codes, and the depth is not a suffix but the first character.
- **The letters after it name the program and type** — `A`, `VR`, `MF`, `MU`,
  `T`, `G`, `PA` appear as 26 distinct prefixes in this file.
- **The first digit is the HEIGHT family**: 7 = 238,5 · 8 = 257,7 · 9 = 289,7.
  `BA715 / BA815 / BA915` is one width at three heights.
- **The digits after it are a WIDTH lookup**, not a measurement: 15 → 153,8 ·
  18 → 183,8 · 20 → 203,8 · 21 → 213,8 · 24 → 243,8 · 25 → 253,8.
- **`D/S` is printed beside a code, not inside it** — `MVR73 D/S`. Whether that
  is the door's hand or the module's execution is **the same question as Cesar
  Q7b** (domain rule 7) and is NOT answered here.
- **A corner takes its own letter**: 110,7 × 110,7 → `MVR77A`.

Prices are in €, four columns wide by finish group, with surcharges printed
beside the table — handles C/L/W/Y +€38, Q +€115, push-pull +€42, electronic
lock +€300, Duna interior and marble back panel by module width. **None of that
enters the registry**: Contract v2 §1.2 forbids a price, a surcharge or a
coefficient on an object, and the surcharges are `variants` and
`companion_refs`, which is the shape they already have for Cesar.

## The technical book — ARRIVED 2026-09-07, and it checks out

It was missing from the dealer package and was downloaded separately the same
evening from the catalogue source Troels named. It is the file the 2026-08-18
recon was written from, and every identifying fact that recon states about it is
true of this copy: **Adobe InDesign 18.3 (Windows), created 2023-06-07, 134
pages, real text layer.**

**Its page formula is verified afresh, on four pages rather than the recon's
two.** `printed_left = 2 × PDF − 4`: PDF 60 carries printed 116/117, PDF 96
carries 188/189, PDF 116 carries 228/229, PDF 130 carries 256/257. The first
attempt at this check reported PDF 116 as a miss and the reason was the checking
regex, which matched no three-digit number above 199 — **a failing check is a
claim about the checker until you have looked at the checker.**

`-LR` in the filename is the factory's own mark for low resolution. It reads
fine and it is not a measuring instrument: for geometry taken off a drawing
rather than off a table, get the HR original.

## What is still NOT on this shelf

**No document we know the name of.** Troels said installation guides ship with
the product, so there is no planning manual to chase: the price lists and the
technical book together are the documentary base for wardrobes.

**What is missing is not a document but a person.** Cesar has Elda, and domain
rule 2 — everything is PRELIMINARY until the factory confirms in writing — needs
somebody at Pianca who can do the confirming. Today there is a sales director in
the USA and three names in Italy read off a 2023 thread where UCON was the
installer and not the customer. **Until that counterpart exists, no Pianca fact
in this repository can pass CONTROL**, and a registry built from these pages
would be a shelf of PRELIMINARY rows with nobody to ask.

## Why the codes are not the deliverable, and this changes the work

Troels, 2026-08-17, on how a Pianca dealer orders: *"we convert your drawings
into our systems and revert with a quotation and technical drawing — when you
become a large dealer we can share software."*

So there is no dealer configurator, and **the factory's input is OUR DRAWING**,
not a coded order line. For Cesar the exporter emits the order; for Pianca the
exporter's product is a sheet, and the codes in this price list are what we
**check the factory's returned quotation against** — the same reconciliation
already built against Elda's 30833. That moves registry extraction out of the
first rank of Pianca work and puts the drawing and the structured element name
(`docs/Naming_Convention_Spec_v0.1.md`) in front of it.

---

# ADDED 2026-09-07, evening — what Pianca's software is, and what a real UCON job looks like

Two findings of different kinds. The first is research and rests on public
sources; the second is measured off a drawing and is the one that changes the
work.

## The software is ADA, by Arcadia S.r.l.

Not 3CAD, not Metron — those belong to other factories. Two independent
sources, neither of them a vendor's word alone:

- **Pianca's own job advertisement** for the Ufficio Tecnico, *Sviluppo
  programma grafico*: *"sviluppo programma grafico **ADA** per manutenzione del
  catalogo, inserimento in ambiente 3D dei prodotti"*, with SQL and Access in the
  requirements. **They maintain the ADA catalogue in house.**
- **Arcadia's announcement of 2024-06-12**: Pianca chose **ADA BE** for the
  configurator on pianca.com, described as *"the natural continuation of the
  long-standing close collaboration with Pianca"* — the web configurator is a
  layer on a system that was already there.

The ADA platform, from Arcadia's own product pages:

| module | for | what it does |
|---|---|---|
| **ADA Catalog** | technical office | *"the electronic version of the technical price list"* — graphics and characteristics of every article, in ADA database tables |
| **ADA Robot** | manufacturer | the factory's 3D software, a superset of Designer; loads orders (wardrobes named explicitly) into production and *"generates processes that allow you to create production prints and technical documentation"* |
| **ADA GeDI** | across | Catalogues (import), **Orders (transfer to the management system)**, Production (printouts of graphics and data) |
| **ADA IDP** | production | splits an order into component operations — base units, side panels, shelves, tops — and generates CAM files |
| **ADA PostProcessor** | production | CAM into the language of a specific machine |
| **DraftUP / DraftUP CAM** | production | Arcadia's own 2D CAD and CNC management, DXF import |
| **ADA Designer** | **dealer** | 3D planning, quotation preparation, cloud catalogues updated in real time, photorealistic plan printing |
| **ADA BE** | end user | browser edition — the configurator on pianca.com |

**Three consequences.** The software Troels offers *"when you become a large
dealer"* has a name — **ADA Designer** — and can be asked for by it. Their
catalogue exists as DATA, so *"can you export the catalogue with codes"* is a
question with an addressee, the same question that was put to Elda about Metron.
And their designers work in **AutoCAD 2D and SketchUp** (their interior-designer
advert), while ADA imports DWG/DXF and exports to 3ds Max and SketchUp — our
sheet reaches them in their own idiom.

**NOT ESTABLISHED, and the line matters**: which producer modules Pianca
licenses. ADA BE is stated outright and ADA Catalog comes from their own advert;
Robot, GeDI, IDP and PostProcessor are inference from the module descriptions.
**"The printed assembly instructions come from ADA Robot" is a hypothesis**,
consistent with that module's stated job and not proven. Three ways to settle
it, cheapest first: the footer of a printed instruction sheet from a delivered
box; the PDF metadata of a drawing that came from the factory itself; or one
line to Troels asking which system prepares the drawings and quotations he
returns.

## What a real UCON Pianca job looks like — measured, not assumed

`sources/factory/pianca/_specimens/SPECIMEN 2024-12 La Canada closets (DNA
sheets).pdf` — eleven sheets, DNA Design Group, December 2024, the closets of
the La Canada project. **It carries no factory stamp**: it is a PowerPoint
compiled by the designer (`Author: millene shipley`,
`Creator: Microsoft PowerPoint`), so it proves nothing about software. What it
does carry is dimensions.

- **The thickness pair is 30 and 22.** Every sheet dimensions `30` at the ends of
  a run and `22` between elements — for example `30 | 819 | 22 | 819 | 30 =
  1720`. The price list says it in words: *"3 cm Th sides (standard)"*. So 30 is
  the standard Pianca side and 22 the intermediate panel.
  **`core/10_standards.rb` holds `PANEL_T_MM = 18`, which is Cesar's.** This is
  seam 1 of `docs/Multi_Manufacturer_Strategy_v0.1.md` — *standards move from
  code into data* — no longer an argument but a measurement.
- **The widths are not catalogue widths.** 819, 822, 923, 478, 504, 670, 759,
  1150, 678, 998, 2364: none belongs to the 47,8 / 57,8 / 67,8 / 97,8 / 117,8 /
  137,8 series. **The job is made to measure.**
- **The heights are mixed.** The hall closet is **2897**, exactly the catalogue
  H 289,7; 2845, 2885, 2410 and 1950 are not. Standard and made-to-measure sit
  in one project.
- **The depths include 590**, the catalogue's D 59 and the top of the 42,3-59
  range, with 627 and 324 elsewhere.
- **Three views per element** — plan, textured elevation, line-only elevation —
  which is the engine's own north star for Cesar.

**This is what reconciles the two halves of the day.** The price list has 553
codes and they matter for checking what the factory quotes back; but the work
UCON actually sells lives largely in *Made to measure solutions* (printed 245),
where identity is a dimension and not a code. **A thin tracer that can only
place catalogue widths would not draw a single one of these eight closets.**

It is also a ready acceptance test: reproduce one of these closets — 30 at the
ends, 22 between, the dimension chain in millimetres — and compare with the DNA
sheet.

---

# ADDED 2026-09-07, evening — a dealer's own sheet set, and the metric catalogue read off an imperial drawing

`sources/factory/pianca/_specimens/SPECIMEN 2026-03 Loevner master closet (ECDS
sheets).pdf` — eight A3 sheets, **European Cabinets & Design Studios**, 864 San
Antonio Rd, Palo Alto; drawn by Lena Pekker; issued 2026-03-26, signed by the
client through Docusign on 2026-04-07. Title block fields: CLIENT · PROJECT ·
**MANUFACTURER: PIANCA** · DRAWN BY · ISSUE. Programme **MILANO**, glass doors.
It reached UCON inside the client's installation package, not from the factory.

**Made in `LayOut in SketchUp Pro 2025`** — read off the PDF metadata. That is
the whole point of the specimen: **an active Pianca dealer produces the signed,
final drawing set in SketchUp and LayOut, not in the factory's own software.**
ADA is not a precondition for selling Pianca; it is a convenience the factory
offers. The engine's north star — wireframe sheets out of LayOut — is already
the market's standard deliverable for this manufacturer.

## The sheet set, as a pattern worth copying

Three shaded render sheets (doors closed, doors open, interior) carrying a spec
block in words — *MODEL: MILANO · GLASS DOOR: reflective bronze in canna de
fucile frame · INTERIOR FINISH: Lavagna matte · DRAWERS: Lavagna matte glass ·
shoe pullout, trouser pullout · LED: horizontal top shelf* — then **A.01** plan,
**A.02** door elevation, **A.03** interior elevation with every rail, drawer and
pullout dimensioned, **A.04** and **A.05** shaded elevations.

**The identity on the sheet is not a code.** It is a programme name plus
finishes and options in words, exactly as this repository concluded on 2026-09-07
from the dealer process: the factory takes the drawing and returns the
quotation. Trade coordination lives on the sheet too — a blue note giving the
2-gang 110 V box position (*13" from the left finished wall, 17" AFF*), LED LV
runs and sensors marked in red.

**The part vocabulary is ours already**: END SIDE PANEL, SIDE END PANEL,
PARTITION PANEL, FILLER, DOUBLE FILLER, GLASS DWR, TROUSER PULLOUT, SHOE
PULLOUT, LED LV, SENSOR — `panel`, `filler`, `accessory` and a variant with a
label, with no contract key missing.

## THE MEASUREMENT: the metric catalogue is under the inches

The sheet is dimensioned in **inches and sixteenths**, because the client and the
installer read inches. Converted, the catalogue is intact underneath:

| on the sheet | mm | what it is |
|---|---:|---|
| `22-3/4"` opening | 577,9 | catalogue **L 57,8** |
| `46-3/8"` opening | 1177,9 | catalogue **L 117,8** |
| `54-1/4"` opening | 1377,9 | catalogue **L 137,8** |
| `93-7/8"` height | 2384,4 | catalogue **H 238,5** |
| `23-1/4"` depth | 590,5 | catalogue **D 59**, the top of the 42,3-59 range |
| `96"` | 2438,4 | the finished ceiling — module plus a top filler |

**And the door is not the opening.** Three doors, three openings, one difference:

```
47-1/16" − 46-3/8"  = 17,5 mm
23-7/16" − 22-3/4"  = 17,5 mm
54-15/16" − 54-1/4" = 17,5 mm
```

**The door leaf is the opening plus 17,5 mm, every time** — it laps the partition
by about 8,7 mm a side. Three independent instances on one sheet; the scope is
this programme and this door type (Milano, hinged glass), and it is not to be
generalised further until a second programme says the same (learned rule 4).

**This refines the 2026-08-18 recon, which recorded the technical book's width
series as DOOR widths.** On this sheet the catalogue series is the OPENING and
the door is wider. One of the two readings is wrong, or the two documents
measure different things — and that is now a question with an owner, not a
guess: it is the first thing to put to the factory's technical counterpart when
one exists.

## What it means for the first Pianca task

Yesterday's specimen (La Canada, DNA) was made to measure end to end. This one is
built from catalogue modules under a 96" ceiling. **Both are real, and a tracer
that can only do one of them is half a tool.** The engine needs the catalogue
width series AND a free dimension from the start — which is `width_range_mm`
plus a depth range, not a new contract.

> **Both sections above are dated 2026-09-07 and were first written with
> tomorrow's date on them.** The session ran past midnight UTC while the
> working day in San Diego was still the 7th, and the headings took the
> container's clock rather than the repository's. Corrected the same
> evening, before anyone read them; recorded here because a section dated a
> day ahead of the commit that carries it reads, later, as work from a
> different session. **Dates in this repository are the local working day.**

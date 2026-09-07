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

## What is NOT on this shelf

**The technical book.** `2023_TECHNICAL-BOOK_Armadi-Cabine-Pianca-LR.pdf` — the
source of the 2026-08-18 recon, the plan symbols and the per-program dimension
tables — is not in the dealer package and not on this machine. Troels named
`pianca.com/en/catalogues/` as the catalogue source. **Until it is here, every
geometric fact in `Pianca_Recon_v0.1.md` rests on a document nobody can re-open**,
and `-LR` means the copy that was read was low resolution.

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

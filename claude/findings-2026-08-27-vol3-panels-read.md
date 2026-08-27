# The Volume 3 panel chapter, READ — printed p.214-220 (2026-08-27)

**Volume searched: `CESAR - 3 Linear Elements.pdf`, October 2021 / update 05|26,
244 printed pages, offset +2.** Named because that is now the rule
(`docs/Cesar_Volumes_Index.md`): a code absent from the book you have is not a
code absent from the book.

Read from 150-dpi renders of PDF 216-222, not from the text layer
(learned rule 10). The renders are kept beside the volume as
`sources/factory/lin-p<printed>-<pdf>-*.png`, git-ignored like everything else
in `sources/`.

**Why now.** Andriy, 2026-08-27, on the island: *"Я ищу панели шириной 600, а
высотой примерно 700, 720, 730, 740."* A 600-wide sheet cut to a height nobody
prints is not the Volume 2 article at all — it is this chapter. The demand came
from the kitchen, which is how work is supposed to arrive here.

---

## 1. What the chapter is

Six pages of panels, priced **per m², minimum invoicing quantity 0,5 m²** —
printed at the head of every one of the six. **No height and no width in any
article**: the sheet is cut, and the only dimensional fact the page states is
the MAXIMUM sheet, drawn beside each block.

**44 panel codes** across six pages, plus **8 companion articles** on p.214.

## 2. printed p.214 — the notes page, and it draws an island

The page carries no panel code. It carries the two sentences that decide how a
panel meets the floor, and a drawing that is this project's case exactly:

> *"If it is used as a floor-standing panel behind a base unit or as a
> floor-standing end side panel, 0.5-cm high feet will be mounted that must be
> calculated separately."*

> *"If the panel is used behind a base unit, a kit to attach it to the rear of
> the base units will be supplied. This kit must be calculated separately."*

> *"The panel must be used with the doors."*
> *"The panel must be attached before placing the top on the base units."*

The illustration, *"Example of floor-standing panels with adjustable feet"*,
labels three things: **panel used as a floor-standing end side panel with
adjustable feet**; **panel used behind base units with adjustable feet and
fixing kit**; and **back of the arrangement with kit to fix the panel behind the
base unit**. It is drawn as an island — two base units, a top, an end panel and
a back panel.

**The companions, per piece:**

| what | code | points |
|---|---|---:|
| Kit to fix panel behind base unit — 30 cm | `990483` | 48 |
| … 45 cm | `990485` | 51 |
| … 60 cm | `990486` | 69 |
| … 75 cm | `990487` | 70 |
| … 90 cm | `990489` | 72 |
| … 105 cm | `990490` | 72 |
| … 120 cm | `990492` | 72 |
| Adjustable foot H. 0,5 cm, each | `990408` | 6 |

**The kit is priced per BASE UNIT WIDTH, not per panel.** A 2400 run of four
600-wide units takes four `990486` whatever the panels behind it are cut to.
That is a companion whose quantity comes from the RUN and not from the article
it rides on, and nothing in `companion_refs` does that today.

## 3. The panels, page by page

Every block on every page carries the same three surcharges, each per piece:
**cutout for electrical socket 32 · out-of-square reduction 27 · inner or outer
reduction 65.**

| printed | block | max sheet (cm) | codes |
|---|---|---|---|
| 215 | melamine 2 sides, 1,2, ABS edge | **205 x 278** | `DZAD12` 118 |
| 215 | melamine 2 sides, 1,8, ABS edge | **180 x 278** | `DZAC00` 129 |
| 215 | melamine 2 sides, 1,8/2,2, ABS edge | **205 x 278** | `DZAD00` 118 · `DZAD22` 129 |
| 216 | Technomat 2 sides, ABS edge | **120 x 278** | `DZDT00` 155 · `DZDT22` 155 |
| 216 | laminate 2 sides, ABS edge | **126 x 418** | A `DZBZ00` 206 · B `DZDY00` 670 · A `DZBZ22` 206 · B `DZDY22` 670 |
| 217 | lacquered 1,2 / 1,8 / 2,2 | **120 x 300** | sixteen, four groups — below |
| 218 | veneer 1 side, 1,8, melamine reverse — horizontal grain | **300 x 120** | A `DZ061Q` 343 · B `DZ065Q` 358 · C `DZ062Q` 508 · D `DZ063Q` 809 |
| 218 | … vertical grain | **300 x 120** | A `DZ731Q` 343 · B `DZ735Q` 358 · C `DZ732Q` 508 · D `DZ733Q` 809 |
| 219 | veneer 2 sides, 1,8 and 2,2 — horizontal grain | **300 x 120** | B 1,8 `DZ075Q` 579 · A `DV061Q` 549 · B `DV065Q` 579 · C `DV062Q` 1038 · D `DV063Q` 1002 |
| 220 | … vertical grain | **300 x 120** | B 1,8 `DZ745Q` 579 · A `DV731Q` 549 · B `DV735Q` 579 · C `DV732Q` 1038 · D `DV733Q` 1002 |

**printed p.217, the lacquered sixteen** — four finish groups (A silk-effect,
B gloss, C structured, D metallic) x four executions:

| | 1,2 two sides | 1,8 ONE side | 1,8 two sides | 2,2 two sides |
|---|---|---|---|---|
| A | `DZAI12` 307 | `DZAH00` 171 | `DZAI00` 263 | `DZAI22` 274 |
| B | `DZAK12` 382 | `DZAJ00` 252 | `DZAK00` 389 | **`DZAK22` 405** |
| C | `DZCP12` 345 | `DZCO00` 250 | `DZCP00` 362 | `DZCP22` 339 |
| D | `DZDX12` 572 | `DZDW00` 474 | `DZDX00` 670 | `DZDX22` 670 |

`DZAK22` is the code Metron estimate 2026/30831 quotes, at the points the page
prints. `DZAC00` on p.215 is the other one. Both confirmed against the render.

**Two things the page prints that a tidy reader would be tempted to fix, and
must not.** Group C costs MORE than group D on both veneer 2-side pages —
1038 against 1002 — and group C costs less than B in the lacquer table for the
2,2 (339 against 405). The catalog's own order is not monotone. And p.219/220
carry a warning triangle: *"Trama finishes: 1 side with trama, 1 side polished
and Trama edge."*

## 4. CORRECTIONS to `findings-2026-08-26-panels-recon.md` §10.6

Dated and added, not edited (learned rule 9). §10.6 was written from the text
layer and from an older raw_dump extract; the renders narrow it.

1. **The maximum sheet sizes were mis-attributed.** §10.6 says *"205 x 278 for
   melamine, 180 x 278 for the 1,8, 120 and 126 for Technomat and laminate, 300
   for the wood veneers."* The melamine halves are right. But **120 x 300 is
   LACQUER**, not a veneer; **Technomat is 120 x 278**; **laminate is 126 x 418**,
   and the 418 appears nowhere in §10.6; and the veneers are **300 x 120** — the
   300 is their WIDTH, not their height.
2. **So the H.278 hypothesis is narrowed rather than confirmed.** §10.6 offers
   *"that is almost certainly why Volume 2's adjoining end side panel tops out
   at H.278: it is the sheet, not a cabinet."* Melamine and Technomat do stop at
   278 and support it. Laminate reaches 418 and lacquer 300, so 278 is not a
   universal sheet limit and cannot be the whole reason. It was written as a
   hypothesis and it stays one, now with its counter-examples beside it.
3. **The `DV…` series is enumerated**, where §10.6 had only *"and the `DV…` 2,2
   series"*: eight codes, 549 / 579 / 1038 / 1002 twice.

## 5. What this does NOT settle

- ~~**Which height Andriy's back panels are.**~~ **ANSWERED THE SAME DAY, and
  the answer was already in this registry with a source on it.** He settled the
  width first — two panels of 120 rather than four of 60 — and asked for the
  height. It is **880**, and it is not a UCON decision: `base_h78.json` → family
  H.78 `plinth_note` cites **Volume 1 printed p.73 and p.82**, where the
  dimension chain reads *78 H. Cesar door* over *10 Plinth H.*, and states
  **780 + 100 = 880 to the worktop underside**. p.214's own rule — feet 0,5 cm,
  attached before the top goes on — puts the panel from the floor to exactly
  that line. The 700–740 band corresponds to nothing measured in this kitchen.
  **Where the answer lived is the lesson.** Volume 1 — the book nobody has opened
  yet, and the one holding the collection question — quoted second-hand in a
  registry note written for a different reason. Section 5 of this document called
  the height open three hours before anyone read the file that answers it.
  *A reading that stays in a note is a reading the engine does not have; a
  reading that stays in ONE note is a reading the next question cannot find.*
- **Elda Q23 is untouched.** Whether a Volume 2 adjoining end side panel may be
  ordered floor-standing, or whether floor-standing always means this chapter,
  is still open. This reading makes the second more plausible and does not
  settle it.
- **Nothing is in the registry yet**, and it cannot be until `source_pdf` is a
  per-section fact — `50_registry.rb:232` builds `source_ref` from the single
  manifest value and every code here would cite the Kitchen System. That is
  owed 14 and §10.8, and it is now on the critical path rather than beside it.
- **The shape of the article is new to this registry.** Both dimensions come
  from the order and the page states only a maximum. `width_range_mm` +
  `with_ordered_width` is exactly half of that mechanism already; the height
  half does not exist, and `with_ordered_height` would record a cut sheet as a
  MODIFICATION of a printed height that was never printed.

---

## 6. And then it was extracted, the same day (core 0.89.0)

Andriy: *"Ты можешь сделать extraction? их панелей ставить на нашей модели?"* — so
the chapter went in. `registry/cesar/panels_linear_elements.json`: **44 codes in
ten blocks**, family `Panels (Linear Elements)`, class `panel_sheet`.

**All 44 are `buildable: false`, and the reason is one sentence repeated
verbatim** — the backlog is one grep, the same shape the nineteen `door_versions`
codes use. A sheet is not an end panel turned sideways: an end panel carries its
thickness on **x** and its front edge in the plane of the doors, a panel behind a
run carries its thickness on **y** and has no front edge at all. Until the
generator has that orientation and a placement against the BACK of a selected
run, drawing one would put a board in the wrong plane and call it an order.

### What had to change under it

- **`source_pdf` is a per-section fact** (owed 14, closed). The manifest's value
  is the default; a section may declare its own; `Registry.lookup` **and**
  `Registry.catalog` both name the book. A check walks all 924 rows.
- **`with_ordered_height` gained the range path** `with_ordered_width` has had
  since the fillers. Without it, 880 was recorded as a height REDUCTION from a
  height the page never printed — a surcharge code on an order line the catalog
  does not charge.
- **`width_is_a_thickness?` was narrowed** from "any panel" to "a panel with no
  width range". Learned rule 6, one day later: it was written when there was one
  kind of panel, and it would have refused all 44 sheets the one dimension that
  is genuinely theirs.
- **`class` is `panel_sheet`, not `end_panel`.** Two articles, two classes, two
  picker headings.

### The bug the new checks found, which is why they exist

Three of the eight new checks **failed on their first run.** `height_range_mm`
was written correctly in the section file and `Registry.lookup` did not carry it
into the flat hash — so `with_ordered_height` fell straight past its new range
path into the modification path, and a cut sheet came out recorded as a
reduction. **This is exactly the `wall_hung` bug of 2026-08-22**: data written
right, loader silent, and the escape hatch unreachable from any code. That one
cost a day and a half because the note beside it was correct. This one cost
four minutes, because a check was looking at the thing rather than at a proxy.

> **A guard must prove itself before it is trusted** — learned rule 12, and the
> proof arrived by itself.

### Still owed, and new

**A companion whose quantity comes from the RUN has no expression in Contract v2
§4.2.** The fixing kit is priced per BASE UNIT width: four 600 units behind
**two** 1200 panels take **four** kits. Hung off the panel as a `companion_ref`
it would count two. Held in `_manifest.json` →
`hardware.linear_element_panel_fixings`, visible rather than invented, with the
foot beside it and the note that **how many feet per panel is not printed.**

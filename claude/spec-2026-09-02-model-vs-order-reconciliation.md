# Reconciling the model against order 30833 — method, fixture, and the session's plan

Spec, 2026-09-02. **Nothing here is built.** Written so the session that does the
work opens one file and starts, instead of re-deriving this.

**Add to `claude/README.md` in the same commit — `go.sh` refuses otherwise.**

Companion: `claude/three-level-validation-2026-09-02.md` (the three levels, and
why the factory wins some disagreements and we win others). This document is
**L2 applied to one project, once.**

---

## 0. The rule that governs the whole exercise

**We change OUR MODEL. We do not change the ORDER.**

Andriy, 2026-09-02: nothing goes back to Elda until the client approves the
budget and the design retainer is in hand. That rule is about the ORDER. It does
not touch our own model, and reconciling the model against what the factory has
already sent costs nothing, disturbs nobody, and is exactly the learning these
first jobs are for. Model now; order after the retainer.

---

## 1. What arrived from Elda, and what it is NOT

2026-09-02 16:26, WeTransfer, two files for estimate `2026_C2X01_AG157_T_30833`:

| file | size | what it actually contains |
|---|---|---|
| `2026_C2X01_AG157_T_30833.dxf` | 270 MB | **1199 `3DSOLID` entities. Three blocks, all of them the standard `*Model_Space` / `*Paper_Space` pair. ONE layer, `Furniture`. ZERO `TEXT`, `MTEXT` or `ATTRIB` entities.** |
| `2026_C2X01_AG157_T_30833.skp` | 204 MB | SketchUp format `{18.0.1}`. **75 top-level groups named `Group`, `Group1` … `Group74`. One layer, `Layer0`. Materials named `Color_5`, `img7_6` — auto-generated. No component definition names, no finish names.** |

Verified by reading the files directly — the DXF parsed for blocks, layers, entity
types and text; the SKP read for its UTF-16 name table. Neither file was opened
in an application.

### The finding, and it closes a question that has been open since 2026-08-20

`elda-mini-order-2026-08-20.md` §3.2 asked whether anything Metron exports
carries the ARTICLE CODES as data — IFC, or DXF with block names, or a parts
list. Elda answered "no export" on 2026-09-01 about Excel and text.

**The 3D files answer the rest of it, and the answer is also no.** The DXF has no
blocks and no text, so there is nothing for a code to be written on. The SKP's
groups are numbered, not named. Neither file knows what a `PD0799` is.

**Do not ask her again.** It is not a setting she failed to tick; the export has
no place to put a code.

### What this forces, and it is not a loss

The SKP and the DXF are a **geometry check, not a data source.** That was always
the more valuable of the two things they could have been — the codes we can read
off the estimate PDF, which extracts cleanly, while nothing but the factory's own
solid tells us where the factory actually put it.

---

## 2. The join: by geometry, and now there is no choice

**Join her rows to our bodies on SIZE AND POSITION. Compare on CODE.** Joining on
code makes a code error invisible: the rows simply fail to meet and it reads as a
missing position rather than a wrong one. This was the right method anyway; the
unnamed export makes it the only one.

### And it is mechanical, because the counts nearly agree

**75 groups in the SKP against 69 rows in the estimate.** Close enough that the
correspondence is roughly one group per ordered position, with a handful of rows
splitting or merging. Every row of the estimate carries `L`, `H` and `P` in its
own columns; every group in the SKP has a bounding box.

**The algorithm for the session:**

1. A read-only probe over the imported model reads each top-level group's
   bounding box: `w`, `h`, `d`, and the origin of its `bounds.min`.
2. Match each box against the `L / H / P` triple of the 69 rows, 1 mm tolerance
   (hand geometry lands on fractions — a refusal at 0,3 would be about SketchUp,
   the same reasoning as the worktop stamp's tolerance).
3. Unique triples land immediately. Repeats — `PD0799` four times at 610×600×620,
   `C90635` four times, `SD0631` five times — resolve by position along the run.
4. Anything unmatched in either direction is the finding, and it is the point:
   a group with no row is something the factory drew that no line pays for; a row
   with no group is something we are paying for that is not in the picture.

**The probe reads. It does not write, and it must not** — `apply!` commits an
operation of its own and escapes the bridge's rollback. `probe_bridge.rb` says so
in its own header.

---

## 3. The one mapping already known, before the session starts

`repo-state.md` records our seven custom upper-tier boxes as `SD0631` ×6 — four at
610×600, two at 610×720 — plus `SD0930` cut to 770. Those are **tall-unit top
element** codes. Estimate 30833 says they are not:

| ours | hers | rows |
|---|---|---|
| `SD0930` reduced to 770 | `PD0999` 770×600×620 | 5 |
| `SD0631` ×4 @ 610×600 | `PD0799` ×4 @ 610×600×620 | 7, 9, 44, 45 |
| `SD0631` ×2 @ 610×720 | `PE1299` ×1 @ 1220×720×620 — **two of our bodies, one of her rows** | 8 |

Seven of our boxes, six of her rows, and the widths agree one for one. Her email
gives the reason: a standard wall unit exists only at d.350, so everything at
d.620 is a custom `ELEMENTO A DISEGNO` with a +138 surcharge — not a column top
element.

**And it is not a rename.** Her custom rows carry the front and the shelf as their
own sub-lines (`FRN`, `RPN`); our `SD0631` has no such structure. The composition
of the position changes, not only its code.

**`SD0631` is not wrong everywhere.** Five of them in her order are genuine top
elements sitting on the `C90635` / `C92640` columns of the east wall. The code is
wrong only where we used it to close a wall.

---

## 4. Five verdicts, and every row gets exactly one

| verdict | meaning | action |
|---|---|---|
| **MATCH** | code, size and position agree | nothing |
| **MODEL WRONG** | the factory is authoritative here — code, article content, how a variant is expressed | change the model |
| **HERS WRONG** | we are authoritative — measured dimension, clearance, installation access | record; raise only after the retainer |
| **OPEN** | neither is authoritative; she guessed, or it is waiting on an answer | record, change nothing |
| **NO BODY** | a row with nothing in our model, or a group with no row | investigate — this is the category that finds omissions |

A row may not be left unclassified. An unclassified row is the state this whole
exercise exists to remove.

---

## 5. What the session must NOT touch

- **Row 43 `PB1299`** — the custom box above the range, quoted in Rovere Nordico
  where our schedule says both boxes over the range are `LX19` Nero. **OPEN**, not
  MODEL WRONG. It is a question for Elda and it is unsent.
- **The panels** — we specified `DZ731Q`, one side veneered; she quoted `DV731Q` /
  `DV061Q`, two sides. **OPEN.** It is also the only open item that moves the
  number the client will approve.
- **Prices, and the shape of her custom sub-lines.** A price is not a model fact,
  and how Metron splits a custom position into `FRN` and `RPN` rows is its
  business. See the companion note: our side of the diff is codes, dimensions and
  composition, never sums.
- **The 8 mm ceiling gap.** Settled our way 2026-09-02 — nothing restricts access
  on that wall and we manage it at installation. Recorded as an accepted
  divergence, not a defect.

---

## 6. Order of work

1. **`get_device_info`**, then request `~/dev/ucon-cabinet-engine` and
   `~/dev/_claude`. Read `repo-state.md` and `rules.md`.
2. **Check the model is saved.** As of 2026-09-01 it was last written 2026-08-31
   12:47 and everything after that lived in an open window. A read-only probe
   answers it: `model.modified?`.
3. **Emit our element list** from the model.
4. **Import her SKP** into a scratch model — not into 545 — and run the bounding-box
   probe over its 75 groups.
5. **Join, then classify all 69 rows.** The table in §8 is the fixture; fill the
   verdict column.
6. **Apply MODEL WRONG only.** Start with the `SD` → `PD0x99` block in §3, which is
   the largest known error and is already mapped.
7. **Write the divergence register** — every HERS WRONG and every accepted
   difference, with its reason and its date. Without it the next comparison
   re-reports the same lines and nobody can tell a decision from a defect.

---

## 7. What this session should produce

- The filled table: 69 rows, one verdict each.
- The divergence register.
- A short list of questions for Elda, held until the retainer.
- If the bounding-box join works: the probe kept as a tool, because this is the
  first instance of the L2 diff and it should not be written twice.

---

## 8. The fixture — estimate 2026/30833, all 69 rows

`Listino 9`, coefficient 1,34, **band 6 confirmed**. `fin` is the `Furnishing`
heading the row sits under. `L / H / P` are Metron's own columns in mm and are
the join key.

| # | code | L | H | P | fin | what it is |
|---|---|---|---|---|---|---|
| 1 | `C00151` | 49 | 2340 | 620 | RR09 | TALL UNIT FILLER |
| 2 | `PD0151` | 49 | 600 | 350 | RR09 | FILLER FOR WALL UNIT WITH ONE-PIECE BOTTOM |
| 3 | `B70151` | 104 | 780 | 620 | LX19 | FILLER IN DOOR FINISH |
| 4 | `PD0151` | 104 | 600 | 350 | RR09 | FILLER FOR WALL UNIT WITH ONE-PIECE BOTTOM |
| 5 | `PD0999` | 770 | 600 | 620 | RR09 | ELEMENTO A DISEGNO |
| 6 | `B80753` | 750 | 780 | 620 | LX19 | BASE UNIT 2 DRAWERS, 1 JUMBO DRAWER |
| 7 | `PD0799` | 610 | 600 | 620 | RR09 | ELEMENTO A DISEGNO |
| 8 | `PE1299` | 1200 | 720 | 620 | LX19 | ELEMENTO A DISEGNO |
| 9 | `PD0799` | 610 | 600 | 620 | RR09 | ELEMENTO A DISEGNO |
| 10 | `B80753` | 750 | 780 | 620 | LX19 | BASE UNIT 2 DRAWERS, 1 JUMBO DRAWER |
| 11 | `PD0699` | 600 | 600 | 620 | RR09 | ELEMENTO A DISEGNO |
| 12 | `TF0641` | 600 | 960 | 350 | RR09 | GLASS DOOR WALL UNIT |
| 13 | `PD0699` | 600 | 600 | 620 | RR09 | ELEMENTO A DISEGNO |
| 14 | `TF0641` | 600 | 960 | 350 | RR09 | GLASS DOOR WALL UNIT |
| 15 | `B80501` | 450 | 780 | 620 | LX19 | BASE UNIT WITH DOOR |
| 16 | `PD0699` | 600 | 600 | 620 | RR09 | ELEMENTO A DISEGNO |
| 17 | `TF0641` | 600 | 960 | 350 | RR09 | GLASS DOOR WALL UNIT |
| 18 | `PF0151` | 80 | 960 | 350 | RR09 | FILLER FOR WALL UNIT WITH ONE-PIECE BOTTOM |
| 19 | `PD0151` | 80 | 600 | 350 | RR09 | FILLER FOR WALL UNIT WITH ONE-PIECE BOTTOM |
| 20 | `AU110D` | 900 | 780 | 620 | LX19 | RH CORNER BASE UNIT WITH LH DOOR |
| 21 | `B80565` | 450 | 780 | 620 | LX19 | WASTE BIN BASE UNIT WITH PULL-OUT DOOR |
| 22 | `B81087` | 1050 | 780 | 620 | LX19 | 2 JUMBO DRAWERS SINK BASE UNIT |
| 23 | `V80630` | 600 | 780 | 620 | LX19 | FULLY-INTEGRATED DISHWASHER DOOR |
| 24 | `B70501` | 450 | 780 | 350 | LX19 | BASE UNIT WITH DOOR |
| 25 | `B70150` | 102 | 780 | 350 | LX19 | BASE UNIT FILLER |
| 26 | `B80653` | 600 | 780 | 620 | RR09 | BASE UNIT 2 DRAWERS, 1 JUMBO DRAWER |
| 27 | `B80653` | 600 | 780 | 620 | RR09 | BASE UNIT 2 DRAWERS, 1 JUMBO DRAWER |
| 28 | `FRN007170747` | 607 | 717 | 22 | LX19 | FRONT H.717 W.747 |
| 29 | `B80653` | 600 | 780 | 620 | RR09 | BASE UNIT 2 DRAWERS, 1 JUMBO DRAWER |
| 30 | `B80653` | 600 | 780 | 620 | RR09 | BASE UNIT 2 DRAWERS, 1 JUMBO DRAWER |
| 31 | `FRN019770747` | 734 | 1807 | 22 | RR09 | FRONT H.1977 W.747 |
| 32 | `FRN019770597` | 480 | 1807 | 22 | RR09 | FRONT H.1977 W.597 |
| 33 | `C90635` | 600 | 2340 | 620 | RR09 | TALL UNIT WITH DOOR FOR DRAWER AND JUMBO |
| 34 | `SD0631` | 600 | 600 | 620 | RR09 | TALL UNIT TOP ELEMENT WITH DOOR |
| 35 | `C90635` | 600 | 2340 | 620 | RR09 | TALL UNIT WITH DOOR FOR DRAWER AND JUMBO |
| 36 | `SD0631` | 600 | 600 | 620 | RR09 | TALL UNIT TOP ELEMENT WITH DOOR |
| 37 | `C90635` | 600 | 2340 | 620 | RR09 | TALL UNIT WITH DOOR FOR DRAWER AND JUMBO |
| 38 | `SD0631` | 600 | 600 | 620 | RR09 | TALL UNIT TOP ELEMENT WITH DOOR |
| 39 | `C90635` | 600 | 2340 | 620 | RR09 | TALL UNIT WITH DOOR FOR DRAWER AND JUMBO |
| 40 | `SD0631` | 600 | 600 | 620 | RR09 | TALL UNIT TOP ELEMENT WITH DOOR |
| 41 | `C92640` | 600 | 2340 | 620 | RR09 | TALL UNIT FOR BUILT-IN OVEN AND MICROWAVE |
| 42 | `SD0631` | 600 | 600 | 620 | RR09 | TALL UNIT TOP ELEMENT WITH DOOR |
| 43 | `PB1299` | 1200 | 333 | 620 | RR09 | ELEMENTO A DISEGNO |
| 44 | `PD0799` | 610 | 600 | 620 | RR09 | ELEMENTO A DISEGNO |
| 45 | `PD0799` | 610 | 600 | 620 | RR09 | ELEMENTO A DISEGNO |
| 46 | `DV061Q` | 2438 | 650 | 22 | RR09 | 2.2 CM TH. PANEL VENEERED ON 2 SIDES HORIZ. |
| 47 | `DV731Q` | 650 | 600 | 22 | RR09 | 2.2 CM TH. PANEL VENEERED ON 2 SIDES VERT. |
| 48 | `ZOCC011` | 1820 | 100 | - | RR09 | FRONT PLINTH H.10 PER LM |
| 49 | `ZOCC011` | 2400 | 100 | - | RR09 | FRONT PLINTH H.10 PER LM |
| 50 | `MNS022000` | 874 | 22 | 645 | RR09 | 2.2 CM TH. SHELF |
| 51 | `MNS022000` | 874 | 22 | 645 | RR09 | 2.2 CM TH. SHELF |
| 52 | `DV061Q` | 874 | 645 | 22 | RR09 | 2.2 CM TH. PANEL VENEERED ON 2 SIDES HORIZ. |
| 53 | `DV061Q` | 1880 | 375 | 22 | RR09 | 2.2 CM TH. PANEL VENEERED ON 2 SIDES HORIZ. |
| 54 | `GOL001` | 3179 | 57 | 27 | RR09 | L-SHAPED UNDERCOUNTER GRIP RECESS TO LM. |
| 55 | `GOL002` | 1046 | 73 | 27 | RR09 | INTERMEDIATE L-SHAPED GRIP RECESS TO LM. |
| 56 | `ZOCC011` | 3304 | 100 | - | RR09 | FRONT PLINTH H.10 PER LM |
| 57 | `DV731Q` | 672 | 878 | 22 | RR09 | 2.2 CM TH. PANEL VENEERED ON 2 SIDES VERT. |
| 58 | `DV731Q` | 1200 | 880 | 22 | RR09 | 2.2 CM TH. PANEL VENEERED ON 2 SIDES VERT. |
| 59 | `ZOCC011` | 2400 | 100 | - | RR09 | FRONT PLINTH H.10 PER LM |
| 60 | `ZOCC011` | 1348 | 100 | - | RR09 | FRONT PLINTH H.10 PER LM |
| 61 | `GOL002` | 746 | 73 | 27 | RR09 | INTERMEDIATE L-SHAPED GRIP RECESS TO LM. |
| 62 | `GOL001` | 1277 | 57 | 27 | RR09 | L-SHAPED UNDERCOUNTER GRIP RECESS TO LM. |
| 63 | `DV731Q` | 1200 | 880 | 22 | RR09 | 2.2 CM TH. PANEL VENEERED ON 2 SIDES VERT. |
| 64 | `ZOCC011` | 1220 | 100 | - | RR09 | FRONT PLINTH H.10 PER LM |
| 65 | `GOL002` | 748 | 73 | 27 | RR09 | INTERMEDIATE L-SHAPED GRIP RECESS TO LM. |
| 66 | `GOL001` | 850 | 57 | 27 | RR09 | L-SHAPED UNDERCOUNTER GRIP RECESS TO LM. |
| 67 | `ZOCC011` | 854 | 100 | - | RR09 | FRONT PLINTH H.10 PER LM |
| 68 | `DV731Q` | 672 | 878 | 22 | RR09 | 2.2 CM TH. PANEL VENEERED ON 2 SIDES VERT. |
| 69 | `DV731Q` | 1217 | 194 | 22 | RR09 | 2.2 CM TH. PANEL VENEERED ON 2 SIDES VERT. |

**Verdict column deliberately absent — it is filled in the session, not here.**

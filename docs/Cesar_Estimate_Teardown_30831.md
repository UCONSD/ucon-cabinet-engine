# Teardown — Cesar estimate 2026/30831, the test composition

**Source:** `ESTIMATE 2026 / 30831`, ref `2026_C2X01_AG157_T_30831`, Cesar order
system v2.66, printed 2026-08-24 15:53, via Elda Chiara Lesca (DzineElements),
with the Metron SketchUp and DXF exports of the same composition.
**Trust: CONFIRMED** — factory output. Recorded in
`registry/cesar/_manifest.json` → `factory_confirmations`.

**What it is.** Fifteen positions we described in PLAIN WORDS, deliberately not
as codes, so that Metron would choose the articles and we could read its
choices. It is not a buildable kitchen and nothing will be ordered from it. The
companion teardown of the first estimate is
`docs/Cesar_Estimate_Teardown_v0.1.md` (2026/30829, the Dadvar composition).

Listino 9, coefficient 1,34, EUR. Total 16.256,88 €. MC 5,46 · KG 753,72.

---

## The composition header

Every finish and every default lives here, and everything placed in the scene
inherits it. Kept identical to 30829 on purpose, so the two sheets compare.

| | |
|---|---|
| MODELLO | MAXIMA 2.2 |
| FRONT FINISH | Lacc. Lucido Magnolia |
| GRIP RECESS TYPE / ORIENTATION / FINISH | "L-Shaped" Grip · Horizontal · Matt Aluminium |
| HANDLE TYPE | 90 Gradi |
| CARCASS FINISH | Cenere |
| DRAWER STRUCTURE / FINISH / SIDE | Legrabox · Legrabox Cenere · Legrabox R |
| ELEMENT TYPE | Normal |
| FOOT TYPE | H.100 Mm |
| POWER SUPPLY | Usa |

## What we asked for, and what Metron chose

| # | asked, in words | our guess | Metron |
|---|---|---|---|
| 1 | corner base H.78, 115x70, d.62, left-handed | AU110S | **AU110S** |
| 2 | the same, right-handed | AU110D | **AU110D** |
| 3 | base H.78, one door, d.62, W.600 | B80601 | **B80601** |
| 4 | the same, reduced to 560 | — | **B80601** + WIDTH REDUCTION, +138 |
| 5 | the same, reduced to 400 | — | **B80501** + WIDTH REDUCTION, +138 |
| 6 | wall H.60 W.60 top-hung, Servo Drive | PD0600 | **PD0600** + FRN005970597 |
| 7 | wall H.60 W.60 push-up, Servo Drive | PD0610 | **PD0610** + FRN005970597 |
| 8 | wall H.60 W.60, one door hinged left | PD0631 | **PD0631** |
| 9 | straight corner wall H.60, 100x40, left | PD094S | **PD094S** |
| 10 | dishwasher door 75 with its panel | V80730 | **V80730** + GBBF01 |
| 11 | USA base for built-in oven, W.76.2, d.62 | B87699 | **B87699** + FRN003870897 + KCAS01 |
| 12 | tall H.198, one door, W.60, d.35 | CE0631 | **CE0631** |
| 13 | USA wine cooler door, W.61, for tall H.210 | CR9601 | **FRN020970687** — not a CR code |
| 14 | tall H.210 W.60 d.62 with the p.569 kit | CR0635 + kit | **CR0635** + **996OL6** |
| 15 | the same with stainless kit fronts | — | CR0635 + 996OL6, DRAWER FINISH Legrabox Inox, **+387 added by hand** |

Twelve of fifteen guesses were right. The three that were not are the three
findings below.

---

## 1. A front is its own order line, and its code is its size

Three fronts appear as their own rows:

| code | reads as | on |
|---|---|---|
| `FRN005970597` | H.597 W.597 | the two wall units |
| `FRN020970687` | H.2097 W.687 | the wine cooler |
| `FRN003870897` | H.387 W.897 | the USA oven base |

**`FRN` + five digits of height + four of width, in millimetres.** All three
decode without exception.

And the mechanisms hang on the FRONT, not on the carcass: *Top-Hung Door + With
Servodrive Mechanism*, *With Servodrive Mechanism + Oblique Push-Up Door*,
*OPENING TYPE: Autoportante*, *GRIP RECESS TYPE: Without Handle*, *CUTOUT
WORKMANSHIP + FRONT FINISH: Pred. Cantinetta A*.

**Our Object Contract draws fronts and does not order them.** Closing that is a
versioned contract revision and belongs with the exporter (M1.10), not to a
patch.

## 2. The wine cooler door is not a CR article

Position 13 came back as `FRN020970687` — an ordinary autoportante front with
the variant *Pred. Cantinetta A*, which is the cutout workmanship. There is no
`CR9601` row anywhere on the sheet.

`registry/cesar/usa_tall_h210.json` holds `CR9401 / CR9601 / CR9701 / CR9901`
as wine-cooler doors read off printed p.418. The page prints them; Metron does
not order them that way. **Both readings are recorded and neither is deleted**
until we understand whether the page and the order system disagree or whether
the CR row is something else.

## 3. A width reduction keeps the code of the module above

560 is a reduced 600 and stays `B80601`. 400 is a reduced **450** and becomes
`B80501`. Both carry *WIDTH REDUCTION: Yes* and a flat **+138 points**.

Elda adds that starting from a 600 to reach 400 is possible and dearer. So the
rule is *nearest module above by default, wider on request*. The width our tool
puts on an object and the width that reaches an order are therefore two
different things — the second is a variant on a standard code.

## 4. The corner, in the factory's own words

Both corner rows print the same note:

> `BASE ANGOLO: INGOMBRO Xtot 1150mm Ztot 700, SCATOLATO X 365 mm Z 80 mm`

and the wall corner:

> `BASE ANGOLO: INGOMBRO Xtot 1000mm Ztot 400, SCATOLATO X 350 mm Z 50 mm`

**INGOMBRO is our `corner_geometry`, and it matches what we already held** —
1150x700 and 1000x400. **`Z` is the filler**: 80 for the base corner, 50 for
the wall corner, confirming the 8x8 and the 5x5 from the factory rather than
from a page. **`SCATOLATO X` — 365 and 350 — is a quantity we do not model.**
It is not `nominal - carcass`, which is 250 here. Recorded, not derived.

And the descriptions settle the letter: **`AU110D` = RH CORNER BASE UNIT WITH
LH DOOR**, **`AU110S` = LH CORNER BASE UNIT WITH RH DOOR**. Elda Q7 and Q7b,
closed. See `docs/Elda_Open_Questions_v0.1.md`.

## 5. What the SketchUp export measures

Read with a probe on the factory file. Every straight unit is drawn at
**depth + 25**:

| item | depth | drawn |
|---|---|---|
| base `B80601` | 620 | **645** |
| tall `CE0631` | 350 | **375** |
| wall `PD06xx` | 350 | **375** |

620 + 3 + 22 = 645. **`FRONT_GAP_MM` 3 and `FRONT_T_MM` 22 are confirmed by the
factory's own geometry**, not by a letter. Heights likewise: 880 = 780 + 100,
2080 = 1980 + 100, 2200 = 2100 + 100.

### And two things it contradicts

**The corner filler is measured from the CARCASS plane.** The base corner is
drawn 900 x 700 — 620 + 80 exactly — and the wall corner 1000 x 400 = 350 + 50.
`core/60_generator.rb` sets `out_y = back_y - FILLER_MM`, where `back_y` already
carries the gap, and draws **703**. One gap too deep.

**The corner is seated on the printed node, with no gap.** The corner carcass
ends at exactly `nominal - carcass` = 250 mm from the perpendicular wall.
Commit `14158a5`, made earlier the same day, added one `FRONT_GAP_MM` to that
seating. It makes our own two legs agree with each other, and it does not match
the factory: the right correction was the other leg.

**Neither is fixed as this document is written.** Both are recorded in
`_manifest.json` → `factory_confirmations` → `contradicts`.

**Added 2026-08-24, hours later — the paragraphs above stand as written
(rule 9).** The seating was reverted in `3652298`: the corner now sits on
the printed node raw again, and the correction went into the filler's width leg,
drawn at
`FILLER_MM - FRONT_GAP_MM` = 77. The depth divergence — our 703 against the
factory's 700 — was **not** fixed, and it has stopped being a pending fix: both
are defensible readings of an 8x8 panel, they differ by exactly the gap, and it
does not affect whether the fronts meet. It is a **recorded divergence**. See
`docs/Drawing_Spec_v0.1.md` → *"CORRECTED THE SAME DAY"*.

## 6. What the exports do not carry

**No article codes, in either format.** The SketchUp groups are `Group1`,
`Group2`… with internal item numbers such as `2367`, `2368`, `2715`. The DXF —
254 MB of it — has no user blocks at all, only `*Model_Space` and
`*Paper_Space`, and a whole-file search for article codes returns nothing.

Both files are geometry. Asked back the same day: whether Metron can export the
position list as Excel or CSV, and whether the internal item number can be tied
to the article code. Without that, every estimate is read by eye.

## 7. Companions the sheet proves

| article | pulls | scope |
|---|---|---|
| `V80730` dishwasher door 75 | `GBBF01` steel unit | per article |
| `CR0635` with interior kit | `996OL6` kit tipo L | per article |
| any Servo Drive | `996811` transformer USA + `996805` distribution extension | **per COMPOSITION** |

The last row is new: `companion_refs` has no composition scope. The two power
lines appear once, qty 1, for the whole kitchen.

## 8. What an order actually needs

Printed on the sheet:

> Orders must be sent accompanied by the **floor plan, final measurements,
> parts list, and appliance datasheets**.

The exporter's target is that package, not a list of rows.

---

## What this estimate could not answer

Which side `GBBF01` stands on. What the `O` option of the interior drawer kit
gives, against the `L` that was chosen — Elda picked L and had to add the
stainless upcharge by hand, which suggests Metron does not price it from the
drawer finish. Q1, Q2, Q4, Q6, Q8 and Q9 contain nothing this composition
touches.

## The plinth and the grip profile are absent, and that is the answer

Neither appears anywhere on the sheet. The header fixes the plinth height and
the grip finish, but the profiles themselves are added as separate positions
after the cabinets are placed, and snap to them. Our exporter should behave the
same way rather than inventing a second method.

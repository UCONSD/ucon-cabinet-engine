# Cesar factory estimate — teardown (Dadvar Residence, 2026-08-07)

Source: two PDFs produced by **Cesar's own order system**, version 2.66, printed
07/08/2026, sent by Elda Chiara Lesca (DzineElements) in reply to the manual
preliminary package `Bobby_410_Alta_Vista_Preliminary_Layout_v0_2.pdf`.

- `ESTIMATE 2026 / 30829` — DADVAR RESIDENCE, **89 numbered rows**, 8 price
  pages + 9 drawing pages, total **68.113,12 €**
- `ESTIMATE 2026 / 30830` — same composition NO COUNTERTOPS, **76 numbered
  rows**, total **34.504,18 €**

Trust level: **CONFIRMED.** This is not a catalog reading and not our
hypothesis — it is factory output. Where this document contradicts anything in
`registry/cesar/` or in the Object Contract, this document wins.

The two estimates differ only by the countertop/cladding block, which makes the
pair a natural A/B: everything present in both is furniture, everything only in
30829 is surface.

## Header — the composition-level axes

Above the first row, once per estimate:

```
Codice cliente  235450        Listino 9      Coefficiente 1,34     Valuta EUR
MODELLO: MAXIMA 2.2
FRONT FINISH            Lacc. Lucido Magnolia
GRIP RECESS TYPE        "L-Shaped" Grip
GRIP RECESS ORIENTATION Horizontal
GRIP RECESS FINISH      Matt Aluminium
HANDLE TYPE             90 Gradi
CARCASS FINISH          Cenere
DRAWER STRUCTURE        Legrabox
DRAWER FINISH           Legrabox Cenere
DRAWER SIDE TYPE        Legrabox R
ELEMENT TYPE            Normal
FOOT TYPE               H.100 Mm
PLINTH FINISH           Matt Aluminium
```

**This is a whole layer the engine does not model.** These are not per-unit
attributes and not per-row variants — they are properties of the COMPOSITION.
M1.6 project defaults is the right home for them; today the engine has no place
to put "the whole kitchen is Maxima 2.2 in Lacc. Lucido Magnolia with an L-shaped
horizontal gola in matt aluminium".

`Listino 9` + `Coefficiente 1,34` is the points→euro conversion. Prices are
quoted in **Punti**; euros are derived. Elda's note: the coefficient is expected
to rise by 0,03 on 1 October 2026.

## Row anatomy

```
Riga | Code | Description / Variants | L | H | P | UM | Qty | Punti | Magg. | Amount (€)
```

**A row is a TREE, not a record.** Below a numbered row sit:

1. **variant lines** — `KEY: Value`, some carrying their own surcharge into the
   `Magg.` column;
2. **child component rows** — a real article code with no `Riga` number, which
   may itself carry variant lines and its own price.

89 numbered rows in 30829 carry **29 child component rows** beneath them.
The flat 8-column table in the manual package cannot express this.

**`UM` is an axis we do not have.** Three values in use:

| UM | meaning | used by |
|---|---|---|
| PZ | piece | units, fronts, tops, plinth |
| ML | linear metre | `GOL001`, `GOL002` gola profiles |
| MQ | square metre | `DZAK22`, `DZAC00` panels |

A quantity of 1 means one piece, one linear metre's worth, or one square
metre's worth depending on the row. An exporter that assumes "1 = one thing"
is wrong on 40 % of this sheet.

**`Note:: 06` appears on nearly every furniture row** — the price band. This
confirms the `Price_Column = 6` guess in the manual package. Per Elda: band 6
covers glossy lacquer AND first-category wood veneer, so the choice between
them is finish-only and price-neutral.

## ANSWERS TO OPEN QUESTIONS

### Q6 — CLOSED, and the premise was wrong

The gola profile is **not** ordered by any unit — not by an appliance panel,
not by a base unit. It is its own row, priced **per linear metre**:

- `GOL001` L-SHAPED UNDERCOUNTER GRIP RECESS — L 3000 / 1800 / 1198 / 1198
- `GOL002` INTERMEDIATE L-SHAPED GRIP RECESS — L 1200 / 1200 / 1198 / 1198

Eight rows total. **Profile is a property of the RUN, computed from running
length**, not a `companion_ref` on a cabinet. The question "does an appliance
panel order its own GOL profile" does not apply — nothing orders a GOL profile.

End conditions are variants on the profile row, not separate articles:
`RIGHT END ELEMENT TYPE+GRIP RECESS FINISH: Flush–Fitted E` (+25 / +24),
`RIGHT END ELEMENT TYPE: Without`.

### Q7 — CLOSED for wall units. NOT closed for corners.

```
PG0631  1 DOOR WALL UNIT  600 840 350   OPENING DIRECTION: Left     (rows 14,17,24,26)
PD0631  1 DOOR WALL UNIT  600 600 350   OPENING DIRECTION: Left     (rows 15,25)
PD0631  1 DOOR WALL UNIT  600 600 350   OPENING DIRECTION: Right    (rows 18,27)
```

One code, both hands. **"1 rh or lh door" names the DOOR'S HINGE, and the hand
is an order variant, not part of the code.** The registry must not carry two
codes for the two hands of a `..31` wall unit.

**The corner swap is not refuted — but its footing has narrowed.** The rule
that S and D are different corner ARTICLES came from the corner pages, and no
corner unit appears in this composition. What is now dead is the general
principle "the hand is read from the code letter": for `..31` wall units it
demonstrably is not. `corner-units-m22-brief` should be amended from a general
rule to a corner-page-specific one, and Q7 kept open in the narrower form:
*does the corner execution letter behave differently from the wall-unit hand?*

### Q1 — CLOSED, and the answer is that the axis does not exist here

**The 78/75 door-version axis appears nowhere in the order.** Every base unit is
H 780. Gola is expressed entirely through the composition header
(`GRIP RECESS TYPE / ORIENTATION / FINISH`) plus per-row `HANDLE TYPE`.

Handle is a per-row variant with a small vocabulary:
`Push-Pull`, `Profilo Alluminio`, `90 Gradi` (header default), plus
`GRIP RECESS TYPE: With Handle` / `Without Handle` on front rows.

### Q2 — PARTIALLY ANSWERED

Legrabox is a header choice (`STRUCTURE / FINISH / SIDE TYPE: Legrabox R`).
Runner length is baked into the interior-drawer article rather than ordered
separately: `996MB6 INTERIOR DRAWER H.10 LEGRABOX DEPTH 50 CM.60` — depth 50,
for width 60. Four occurrences, always as a child of `B80657`.

### Q5 — SIDESTEPPED, still open

The dishwasher here is `V80630` FULLY-INTEGRATED DISHWASHER DOOR at 600, not
750, and no `GBBF01` appears. What does appear is a plinth cutout:
`ZOCC011 … SPECIAL WORKMANSHIP: Scanso Per Lavastoviglie` (+40,00), twice.

Elda's note: integrated dishwashers usually need no filler panel; most models
work with a continuous 100 mm plinth. **Q5 stands for the 75 cm case.**

### Q3, Q4, Q8 — UNTOUCHED

No modification via 989346, no p.45 sinks, no lift-up wall doors, therefore no
Servo Drive. All three remain open.

## NEW GRAMMAR — confirmed from the order

### Wall-unit family letters

| letter | H | evidence |
|---|---|---|
| PB | 36 | `PB1299` 1067 × **360** × 620 |
| PD | 60 | `PD0631` 600 × **600** × 350 |
| PE | 72 | catalog printed p.228 |
| PG | 84 | `PG0631` 600 × **840** × 350 |

Still unread: H.48, H.96, H.120. The observed set B / D / E / G against
36 / 60 / 72 / 84 is **not** a sequence over the height list — if it were, G
would be H.96. **The family letter is a lookup, exactly like the width index.**

### Suffix `99` = customisable carcass, priced for reduction

```
PB1299  COSTUMIZABLE CARCASS FOR WALL UNITS  1067 360 620   WIDTH REDUCTION: Yes  +138,00
PD0699  ELEMENTO A DISEGNO                    534 600 620   WIDTH REDUCTION: Yes  +138,00
```

`PB12` is the W.120 wall carcass cut down to 1067. This is the mechanism behind
M1.11 (modifications): a `..99` article plus a `WIDTH REDUCTION` variant, flat
+138,00. Note both are **depth 620**, not 350 — these are the deep hood-surround
boxes, so wall depth is not fixed per family.

### `ELEMENTO A DISEGNO` — special order keeps the article

```
row  9   C42601  TALL UNIT FOR BUILT-IN OVEN …   862,00
row 11   C42601  ELEMENTO A DISEGNO            1.065,00
```

Same code, description replaced, price re-pointed. **A special is not a new
article — it is an existing article flagged and re-priced.** That is M1.12
(bespoke) already solved by the factory, and it means bespoke items still carry
a real code, which the exporter can emit.

### The component layer — codes the registry has never seen

| prefix | meaning | example |
|---|---|---|
| `FRN` | front panel | `FRN009570597` FRONT H.957 W.597 |
| `RPN` | shelf | `RPN105630490` SHELF |
| `DVN` | divider | `DVN105630515` DIVIDER |
| `FND` | bottom panel with profile | `FND205630329` |
| `SCSE` | tall appliance housing carcass | `SCSE035H4` W600 H2220 D620 |
| `ZOCC` | plinth, per linear metre | `ZOCC011` FRONT PLINTH H.10 |
| `GOL` | gola profile, per linear metre | `GOL001`, `GOL002` |
| `DZAK` / `DZAC` | finished / carcass panel, per m² | `DZAK22` (2,2 cm), `DZAC00` (1,8 cm) |
| `TOPDR` / `SPLDR` / `SCH` | top, side panel, splashback | `TOPDR008040` |
| `KCAS` | drawer kit | `KCAS01` |

**`FRN` grammar is clean and verified on six distinct codes:**

```
FRN + HHHHH + WWWW      heights and widths in mm, zero-padded
FRN 00137 0597  →  H.137  W.597
FRN 00597 0597  →  H.597  W.597
FRN 00777 0597  →  H.777  W.597
FRN 00837 0597  →  H.837  W.597
FRN 00957 0597  →  H.957  W.597
FRN 01317 0747  →  H.1317 W.747
FRN 01437 0597  →  H.1437 W.597
```

**But the code does not equal the piece.** Where an `FRN` appears as a numbered
row, the L/H/P columns disagree with the code:

| code | code says | L/H/P columns |
|---|---|---|
| `FRN007770597` | H.777 W.597 | 531 × 777 × 22 |
| `FRN014370597` | H.1437 W.597 | 531 × 1437 × 22 |
| `FRN013170747` | H.1317 W.747 | 607 × 1300 × 22 |

Width is always smaller than the code (−66, −66, −140); height matches in two
of three. The deltas are not constant. Reading: **the code is a SIZE BIN, the
columns are the actual cut piece.** An exporter must emit both. → new question.

### Wall units DO carry a companion

Every `PG0631` (four rows) is followed by
`FND205630329 BOTTOM PANEL W/PROFILE — Matt Aluminium+Bottom Panel With Opening
Profiles +19,00`. Not Servo Drive, but a mandatory companion position in exactly
the shape `companion_refs` was designed for.

### Workmanship — an orthogonal surcharge axis

`Smontato` (unassembled, +22 on the unit / +39 on the carcass) ·
`Scanso Per Lavastoviglie` (+40) · `Foro Per Presa Luce` (+32) ·
`Pair Of Feet` (+18) · `Sink Hole Above The Top` (+127) · `Tap Hole` (+51) ·
`WIDTH REDUCTION` (+138).

Elda flags that "unassembled" may or may not be what the office understands as
flat-packed — to be confirmed.

## HARD VALIDATION RULES from Elda's note

1. **A front panel is max 1200 mm wide.** She changed the hood-cabinet front for
   this reason, substituting two hinged doors. This is a checkable rule that
   should fire before an order is emitted.
2. **The floor-to-ceiling swing/cladding door is max L 850 × H 2780 mm.**
3. The island countertop overhang is deeper than usual; the technical department
   may require custom supports. Not a rule yet — a flag.

## WHY THIS DOCUMENT MATTERS MORE THAN THE ESTIMATE

We now hold a matched **input → output pair on a real project**:

- input: the manual preliminary package, 28 cabinet rows, hand-assembled
- output: the factory estimate, 89 numbered rows + 29 child rows = **118 order
  lines**

The gap — roughly 90 lines of profile, plinth, panels, fronts, shelves,
dividers, companions and workmanship — is precisely what a human has to know and
add by hand today, and precisely what M1.10 exists to generate.

**This pair is the exporter's test fixture.** M1.10 is no longer specified by a
guess about what a Cesar order looks like; it is specified by a target it can be
measured against.

## New questions raised by this document

- **E1** — `FRN` codes name a size bin while L/H/P give the cut piece. What is
  the rule, and which of the two does the factory treat as authoritative?
- **E2** — is `Note:: 06` on every row the price band, and is it per-row or
  inherited from the composition?
- **E3** — does `Smontato` mean flat-packed? (Elda has already flagged it.)
- **E4** — `PB1299` and `PD0699` are wall carcasses at depth 620. Is wall depth
  free per order, or does the `..99` article carry its own depth set?
- **E5** — how is running length for `GOL001` / `GOL002` computed? The values
  1198 vs 1200 suggest an end condition eats 2 mm, but that is inference.

## What must change in the repo (not done in this session)

- Composition-level axes (`MODELLO`, finishes, gola, Legrabox, foot type) have
  no home. M1.6.
- `UM` (PZ / ML / MQ) is absent from the contract.
- Order rows are a tree; nothing in the contract expresses a child component row.
- Price is in **points**, with a dated coefficient. Neither exists in the model.
- The `..31` wall hand must be a variant, never a second code.
- `corner-units-m22-brief` overstates its rule and should be narrowed.

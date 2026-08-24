# The wine cooler front — the aperture, the glass, and the thickness

Settled 2026-08-22. Core **0.41.0** (the hole) and **0.42.0** (the glass),
**235 headless checks**. The short version: **Cesar never dimensions this hole,
the appliance makers do, two of their three numbers agree across brands and one
does not — and the same specifications opened a second question about
thickness.**

---

## 1. The catalog was searched, not skimmed

`cut-out|cutout|wine cooler` across all five books.

- **One sentence, six times.** Printed p.418, 420, 421, 423, 425, 426 all carry
  the identical line — *"Use with melamine, Technomat, Unicolor and Fenix,
  including cutout on front"* — and it sits **inside the finish sentence**, not
  among the dimensions. Not a number anywhere.
- **No technical page.** Unlike push-up, which had the mechanisms chapter at
  printed p.560–561, there is nothing. "Wine cooler" appears nowhere in Project
  Guidelines.
- **No article for the cutout.** Modifications (p.548 general; p.554–556
  replacement fronts by H×W) lists width/height/depth reductions, feet,
  wall-hung, matt carcass — no machining line for a front.
- **But the mechanism for "we send dimensions, the factory cuts" exists and is
  priced:** printed p.541, `989394` / 108 points, *"Feasibility study regarding
  cutouts and positioning"*, and a 323-point study that says Cesar will supply a
  technical project *"including any modifications for appliances"*.

### The price is the strongest piece of evidence

The wine cooler front is **exactly ×1.5 the plain door, in every width and
every finish column.**

| | col 3 | col 4 | col 5 | col 7 | col 10 |
|---|---|---|---|---|---|
| CR9700 (30″, plain) | 200 | 323 | 528 | 665 | 1.333 |
| CR9701 (30″, wine) | 300 | 484 | 791 | 999 | 2.001 |
| ratio | 1,500 | 1,499 | 1,498 | 1,502 | 1,501 |

Same on CR9400/9401, CH9700/9701, CH4640/4651. Columns 1 and 2 are blank for
every wine cooler code — those are the two prohibited finishes (Maxima 2.2
framed, Metal).

**A multiplier that ignores the size of the hole is a price for the VARIANT,
not for the machining.** That is the catalog's own admission that it holds no
geometry for it.

### The drawing is not a drawing

The p.418 elevation was pulled apart with `pdftocairo -svg` and compared
vector-by-vector against the plain door above it. **Same artwork, differing by
exactly two line segments.** Frame proportions on it: 12–15 % of width at the
sides, 5–6 % of height top and bottom — but the panel is drawn at 1 : 2,83
while the real widths run 1 : 2,30 to 1 : 3,44. Not to scale, and the left view
labelled "210" is a side view with no aperture at all.

---

## 2. The appliance makers do dimension it

Three specifications, supplied 2026-08-22.

| | Miele KWT 6722 iS | Thermador T18IW100SP | Thermador T24IW100SP |
|---|---|---|---|
| niche | 560 (EU 60) | 457 (18″) | 610 (24″) |
| **panel W × H** | 551 × 1762 | 451 × 2029 | 603 × 2029 |
| side rail | **84** | **79** (range 74–82) | **79** (74–82) |
| top rail | **155** | **158** | **158** |
| bottom rail | **111** | **243** | **243** |
| aperture (derived) | 383 × 1496 | 293 × 1628 | 445 × 1628 |
| panel thickness | 16–22 | 19 | 19 |

### Five things that fall out of it

**1. Nobody stores an aperture. Everybody stores rails.** Width follows:
`panel − 2 × side`. Rails are what stay constant when the width changes, so
storing the aperture instead would need a row per width and would contradict
itself the first time a width was added. The registry follows the makers.

**2. Two rails converge across unrelated brands** — 79/79/84 and 155/158/158 —
and they converge as **absolute millimetres, not proportions**: 84/551 = 15,2 %,
79/451 = 17,5 %, 79/603 = 13,1 %.

**3. One rail does not.** 111 against 243, a factor of 2,2. That is where the
machine compartment and the presenter drawer live, and it is genuinely
per-appliance.

**4. Which inverts the obvious datum.** An aperture is dimensioned from the
bottom edge by habit — and the bottom rail is the unstable one, so anchoring
there moves the whole hole when the guess is wrong. Anchoring at the top and the
sides leaves only the aperture's lower edge undetermined.

**5. It is a window, not a point.** Thermador allows the lateral rail anywhere
in 74–82; Miele prints its aperture width as "383 max". Being a few millimetres
out is inside the makers' own latitude — which is the reason an indicative
rectangle is worth drawing at all.

### And one cross-check that confirms an older decision

Thermador's 24″ panel is **603** wide; Cesar's `CR9601` is **610**. The 18″ pair
is 451 against 457. That 6–7 mm is the reveal we decided not to draw. So the
Cesar width is the **niche**, and drawing the nominal is confirmed from the
appliance side.

---

## 3. THE SECOND FINDING — 22 mm against 19 mm

Raised by Andriy off the drawing: **a thicker door swings wider, and the leaf
can foul its neighbour.**

- **Cesar: 2.2 cm.** `Standards::FRONT_T_MM = 22`, `elda_confirmed`. Unchanged.
- **Thermador: 19, flat.** *"The drawing is based on a door panel thickness of
  3/4″ (19 mm)"*, and its maximum panel dimensions are computed from a 1/8″
  (3 mm) clearance. No alternative is offered.
- **Miele: 16–22 allowed — and it answers the swing question directly.** A
  table of minimum gap X to the **adjoining housing unit door**, by panel
  thickness and by the front's edge radius B:

| panel thickness | R0 | R1.2 | R2 | R3 |
|---|---|---|---|---|
| 16–19 mm | 3 | 3 | 3 | 3 |
| 20–21 mm | 5–5,5 | 4–5 | 4–4,5 | 3,5–4 |
| **22 mm** | **6,5** | **6** | **5,5** | **4** |

So a 22 mm Cesar front is **not forbidden — it costs gap**, 6,5 mm instead of 3,
and an edge radius buys most of that back. Thermador does not offer the choice
at all, which is the real risk: its clearances are planned around 19.

**Nothing was changed on a suspicion.** `FRONT_T_MM` stays 22 and the open leaf
is still drawn at 22 — `70_symbols` already carries the note that a 19 mm US
front would be one change in one place. It became **question W2 to Elda**,
first in the list.

---

## 4. What was built

**0.41.0 — the hole.** Variant **B** (draw it, mark it clearly), chosen with
the eyes open: the default is a default. Better founded than when the option was
first put, because it rests on three specifications instead of none, and only
one of its three numbers is a guess.

- **`Geometry.framed_slab`** — a front with a hole through its THICKNESS. `box`
  extrudes a footprint upward, so its hole would run top to bottom; this builds
  the front face in the x–z plane, drops an inner loop out of it, and extrudes
  the ring. A nil inner face raises rather than quietly leaving a solid slab
  with a rectangle drawn on it.
- **`Generator.draw_front_slab`** — the one place a slab becomes geometry. That
  loop stood written out **three times** (twice in `build`, once in the
  properties panel), which is exactly the shape that would have shipped a wine
  cooler front that came back solid the first time somebody re-applied a handle.
  Same lesson as `front_y_mm`, learned the same way.
- **`Generator.cutout_rails`** — reads the registry, computes nothing. Returns
  nil for a split slab: no aperture in this catalog crosses a joint.
- **`CUTOUT_LABEL = '(cutout: INDICATIVE)'`** — spelled once, reaching both the
  outliner (the group name) and the contract notes.

**0.42.0 — the glass.** Andriy: *draw the glass, do not leave a hole* — a void
reads as a missing part on an elevation. Opaque, CAD style.

- **The pane is GEOMETRY, in the front.** `FRONT_GLASS`, full front thickness,
  flush both faces, its own flat grey `UCON_Glass_Gray`. Full thickness because
  a thinner pane would need a number no source gives us, and the one thickness
  in play is already in dispute — inventing a third is how that argument gets
  lost.
- **The hatch is a SYMBOL, on the elevation tag.** `Symbols.glass_hatch` is
  pure: a 45° line is `v = u + c` in pane coordinates, so it is choosing `c` and
  clipping `u` — no trigonometry, no SketchUp, and testable headless. Diagonals
  come in **pairs**; at the corners a pair where one member clips away entirely
  is dropped, because a lone diagonal reads as a section cut.
- **That split is the three-tag philosophy applied again:** the thing that is
  really there is modelled and stays visible; the convention that describes it
  comes and goes with the Elevation button.

**Where the numbers live.** The measured table is in
`_manifest.json → external_specs.wine_cooler_panel_apertures`, beside the
LEGRABOX table and for the same reason: not a Cesar fact, outside the four-level
trust model. `usa_tall_h210.json` takes a default from it and points at it — a
test fails if the table is ever copied into the section file.

**Defaults: side 80, top 156, bottom 243.** A test proves none was invented:
side and top must fall inside the observed range, and the bottom — which does
not converge — must be *one of the measured values*, never an average. 243 is
taken because these are US widths meeting US appliances; the Miele figure
belongs to a 60 cm European column that never carries a 2100 front.

---

## 5. Still open, deliberately

- **Three questions to Elda, first in the queue** —
  `claude/elda-mini-order-2026-08-20.md`, Part 1: who supplies the cutout
  dimensions (W1), 19 or 22 and what edge radius (W2), the uncoded 234-point
  stainless steel protection (W3). Plus one estimate position, `CR9601`.
- **The bottom rail** — comes from the machine, when appliances are modelled.
- **Where the appliance's panel sits inside ours.** Panel heights are 1762 and
  2029; a `CR94xx` front is 2100. Nothing yet says how they line up. Parked
  beside the fridge-door swing projection, in the same appliance module.

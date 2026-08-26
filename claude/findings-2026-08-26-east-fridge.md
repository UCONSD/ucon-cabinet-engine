# 2026-08-26 — the east fridge is named, and its panels are blocked on one number

**Nothing was built into the model.** This file is what was decided and what was measured
before the build stopped, and why it stopped.

## The machine is named — CL4850SD/S/T

**Andriy, 2026-08-26.** The east 1220 reservation holds a **48 in Sub-Zero Classic
side-by-side with dispenser**, `CL4850SD/S/T`.

That closes the half of owed 5 that said *"the east reservation is still the probe's …
unassigned"*, and it gives B3 its first named object. It does NOT close the tag
contradiction in the same item — `36_void_report.rb` against `38_void_tags.rb` — which is a
separate reading and still owed.

The reservation's own note asked for exactly this: *"RESERVED — 1220 mm for ONE 48 in
appliance. Height is the run top and NOT a published opening: no appliance has been named.
**Replace both when it is.**"*

### The opening it actually needs

`subzero-design-guide.pdf` rev 4/2026 p.10, **`trust: fetched`** — read by a machine
through a web fetch, not by Andriy off a printed page:

| | |
|---|---|
| opening width | **1206** (47 1/2 in) |
| opening height | **2127** (83 3/4 in) |
| opening depth | **610** (24 in) |

**Measured against the drawing:** the reservation is 1220 wide, 2440 tall, 620 deep.
So the machine leaves **14 mm across** and **313 mm above** it, and the run is 10 deeper
than the machine needs.

**313 is over the appliance rules' 120 threshold**, so what goes above this machine is not
the filler case at all — `rules.json` offers `open_shelf_cabinet` or `filler` there, and
that is a decision nobody has made.

### Flush inset is excluded by arithmetic, not by taste

The flush variant of this machine (`CL4850SD/O`) publishes an opening of **1270** and a
grille panel of **1245**. Neither fits 1220. **In this niche only the overlay installation
is possible**, and that is a reading of the drawing rather than a preference.

## The panels — three of them, and the sizes are known

`subzero-design-guide.pdf` p.19 (overlay) and p.23 (flush inset), **`trust: fetched`**:

| panel | overlay | flush inset |
|---|---|---|
| refrigerator door | 730 × 1810 | 743 × 1810 |
| freezer door | 483 × 1810 | 495 × 1810 |
| grille | 1219 × 197 | 1245 × 197 |

**Three panels, not one.** The door height is the same in both installations; only the
widths move. Sub-Zero's own panel thickness is 19; **UCON makes 22** (§8), which in overlay
costs nothing — the 90° door stop is a flush-inset consequence. **The dispenser model needs
the refrigerator panel routed in the dispenser area** (§8), which is an order note, not a
drawing one.

## WHY NOTHING WAS BUILT — the vertical placement is not published

The guide gives the panel SIZES and not their POSITION. Inside a 2127 opening,
1810 + 197 = 2007, and **120 mm are unaccounted for**.

Four sources were tried, all through web fetch, none of them answered it:

- the design guide itself, twice, with different questions — p.19 and pp.49-51;
- `classic_series_ig.pdf`, the Classic installation guide — it defers to the design guide;
- `built-in-refrigeration-qr-sheet-cl4850sds-st.pdf`, the spec sheet for this exact model —
  front view, opening only;
- a mirrored copy of an older revision.

Sub-Zero's own documents point at the **full-scale templates** (the guide's pp.32-33) and
at customer care for the stacking heights.

### And the fetch channel disqualified itself, which is the more useful finding

**Two machine reads of the SAME table disagreed with each other.** One returned the door
panels as *730 wide × 1810 high*; another returned *"Refrigerator door panel height: 730,
Freezer door panel height: 483"* and then computed a stack from them. A third produced a
list of vertical dimensions — 1911, 606, 665, 67 — that does not reconcile with anything
else on the page.

> **A source that gives a different answer to the same question is not a source yet.**
> It is good enough to name a machine and to say what is roughly known. It is not good
> enough for a number that will be cut.

That is why `trust: fetched` sits a notch below a page Andriy has in front of him, and why
none of these numbers is in the registry or in `appliances.json`.

### The one derivation worth recording, marked as a derivation

```
   120  ?
+ 1810  door panels
+  197  grille
------
  2127  = the published opening, EXACTLY
```

A **120 mm base under the doors with the grille on top** closes the opening to the
millimetre — the same kind of exact closure that corroborated the Designer stack
(102 + 2029 + 3 = 2134). The grille being at the top is the one thing every read agreed on.

**But 120 was obtained by subtraction, not read off anything**, and the numbers subtracted
came from the channel disqualified above. It is recorded here as a candidate and used for
nothing.

## What unblocks the build

1. **The vertical stack, from a page a human has read** — the full-scale template, guide
   pp.32-33, or the number from Sub-Zero directly. Then: does the 120 sit under the doors
   as a base, or between the doors and the grille as a gap?
2. Then the panels can be drawn at published size and placed at a MEASURED datum instead of
   a declared one — and if the number never arrives, the fallback is the worktop's pattern:
   declare it once, keep it on the model, and let every object say that its position is
   declared rather than measured.

## What is decided and waiting, so the next session does not re-open it

- the machine: **`CL4850SD/S/T`**, overlay, in the east 1220;
- the reservation is to be **redrawn to 1206 × 2127 × 610**, and its role is to stop being
  `run_gap` — a run gap is a span for a FREESTANDING machine, and this one is built in;
- **313 above and 14 across** become visible the moment it is redrawn, and both need an
  answer;
- the panels are **UCON faces at 22 mm** (§8), three of them, and the article question is
  the same one Q18 asks about the strip above a housing: nothing printed names them yet.

---

## THE NUMBER WAS FOUND, AND IT WAS NOT THE ONE I DERIVED

Andriy supplied `subzero-design-guide.pdf` itself. Read properly this time —
`pdftotext -layout` for the tables and the rendered page enlarged for the drawings —
**not** through the summarising fetch that disqualified itself above.

### p.9, Overall Dimensions, CL4850S(ID) / CL4850SD

| printed | what it measures |
|---|---|
| **84" (2134)** | floor to the top of the grille |
| **75 1/4" (1911)** | floor to the BOTTOM of the grille = the top of the doors |
| **4" (102)** | floor to the BOTTOM of the doors — a VERTICAL dimension, read off the arrows |
| note on the drawing | **HEIGHT DIMENSIONS ± 1/2" (13)** — the legs adjust |

102 + 1810 = 1912 against the printed 1911. So the doors run **102 → 1912** and the grille
zone is **1911 → 2134**, 223 mm of it.

> ### The 120 was wrong, and the way it was wrong is the lesson
>
> The earlier derivation — *120 + 1810 + 197 = 2127 exactly* — closed to the millimetre and
> was **false**. The base is 102, not 120. Nothing about the arithmetic was mistaken; the
> numbers going into it were, and an exact sum made them look confirmed.
>
> **Arithmetic that closes exactly is not evidence. It is a coincidence that has passed one
> test.** The Designer stack (102 + 2029 + 3 = 2134) closed the same way and happened to be
> right, which is precisely why the pattern is dangerous: it does not distinguish itself.
>
> This is the day's shape again at a third level. The morning had two bodies and only a
> measurement said which moved; the afternoon had a panel and a filler claiming one band;
> and here two candidate stacks both closed and only the page said which.

### p.19, Overlay Panel Dimensions — read from the PDF, not paraphrased

| CL4850S(ID), CL4850SD | W | H |
|---|---|---|
| Refrigerator, overlay | 28 3/4" (730) | 71 1/4" (1810) |
| Freezer, overlay | 19" (483) | 71 1/4" (1810) |
| Grille, overlay | 48" (1219) | 7 3/4" (197)* |

\* *"Panel height may be increased by 7/16" (11) to hide upper main frame"* — a panel that
grows upward is one anchored at its BOTTOM, which is how it was placed.

Spacer and backer panels are printed too and are **not ours**: the Sub-Zero mounting kit
removes both (§8), and UCON makes the 22 mm face alone.

### p.17 and the figure on p.18 — the dispenser

- *"For models CL4250SD and CL4850SD, the refrigerator door panel must include a cutout…
  Panels thicker than 3/4" (19) must be routed… in the dispenser area."*
- Cutout **162 × 330**; **A = 54** from the refrigerator panel's LEFT edge, **B = 832** from
  its BOTTOM edge — read off the p.18 figure, where A is horizontal and B runs from the
  panel bottom to the bottom of the cutout.
- The figure also settles the arrangement: **narrow door (freezer) LEFT, wide door
  (refrigerator) RIGHT, dispenser on the refrigerator panel.**

## What was built, and what the model says back

Built by `build/42_east_fridge_build.rb` through the probe bridge, **armed** — the one mode
that commits. Verified afterwards by `build/43_east_verify.rb`, which reads the model rather
than trusting the builder's own report.

```
appliance  Appliance opening 1206x2127 — CL4850SD/S/T   x 5612,5..6222,5  y  702,3..1908,3  z    0,0..2127,0
panel      UCON panel — refrigerator 730x1810 (disp.)   x 5587,5..5609,5  y  695,8..1425,8  z  102,0..1912,0
panel      UCON panel — freezer 483x1810                x 5587,5..5609,5  y 1431,8..1914,8  z  102,0..1912,0
panel      UCON panel — grille 1219x197                 x 5587,5..5609,5  y  695,8..1914,8  z 1912,0..2109,0
cabinet    Open shelf above the fridge — 313 mm         x 5612,5..6232,5  y  695,3..1915,3  z 2127,0..2440,0
```

Joints, measured back out of the model: **door joint 6,0** (1219 − 483 − 730); **doors meet
the grille with a 0,0 gap**; grille top **2109**, under both the opening 2127 and the unit
2134; the shelf sits on the opening with **0,0**; the panel plane is **5587,5…5609,5**,
which is the plane of the neighbouring Cesar fronts.

**The old reservation is gone** — its own note had asked for exactly that — and the only
reservation left in the model is the south range gap.

### The 1 mm that was not drawn

The first dry run overlapped the grille onto the doors by 1 mm: the guide PRINTS 1911 for
that line and 102 + 1810 makes 1912. It is rounding — 4" is 101,6 and 71 1/4" is 1809,75, so
the true line is 1911,35. **The two bodies were joined to each other rather than to either
printed number**, and the grille panel says so on itself.

### What is READ and what is DECLARED, on every object

Read: all panel sizes, the opening, the base 102, the door top, the grille height, the
dispenser cutout. Declared, and only these three:

1. **the panel plane** — the guide fixes the panel to the DOOR, not to our cabinets, so its
   outer face was put in the plane of the neighbouring Cesar fronts;
2. **the 14 mm** the 1206 opening leaves inside the 1220 run, split 7 / 7;
3. **22 mm thickness** instead of the guide's typical 19, because UCON makes the face (§8).

### Four order lines, none with an article

The three panels and the open shelf all reach the order as
*"CUSTOM SIZE - NO ARTICLE, to be quoted"*. That is honest and it is not finished: nothing
printed names a UCON appliance panel yet (§9 says it is an ordinary front line), and no
Cesar article is held for an open shelf 313 tall.

## Now owed by this

1. **The dispenser cutout is recorded and not drawn.** 162 × 330 at A 54 / B 832, plus the
   routing requirement at 22 mm. A cutout drawn from a number nobody has checked in the
   model is worse than one named in words — but it has to be drawn eventually.
2. **The engine cannot regenerate any of this.** It was drawn by a probe. The panel table
   belongs in `appliances.json` with the guide as its source, and drawing it belongs behind
   the seam like everything else — and filing it there means a `.rbz` rebuild, which nothing
   in this change has needed so far.
3. **The article question, twice**: the UCON panel line, and the open shelf at 313.

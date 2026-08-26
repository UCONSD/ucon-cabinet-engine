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

---

## THE OPEN SHELF BECAME A CUSTOM CABINET — and why that is a Sub-Zero problem

**Andriy, 2026-08-26, on seeing it in the model.** The box above the fridge had no finish face
at all — a bare carcass — which is fine as far as it goes and is not what the kitchen wants
there. **It becomes a custom cabinet with ONE DOOR THAT OPENS UPWARD.**

His framing is the one that matters, and it is why this project started with Sub-Zero at all:

> **These are the hardest machines to integrate into a European kitchen, and none of this is
> obvious — not to a session and not to an ordinary designer.** So the approach is: we draw
> what we need, send it to Elda, and she tries to make it. If she cannot, the plan changes.

That is `docs/Bespoke_Elements_Design_Spec_v0.1.md`'s buildability ladder stated by the person
who wrote it: **1. factory builds it → 2. change the plan → 3. simplify → 4. UCON fabricates.**

### The catalog was searched FIRST, because the spec demands it

The same spec says a bespoke element that starts wanting doors is **a signal to go and look for
a catalog match instead**. The signal was followed, and the search has an answer worth keeping:

**`PB1210` — Wall unit with push-up door, 1 push-up door, H.36 W.120 d.35, printed p.211.**
Push-up positions print at **H.36 / H.48 / H.60**, widths **600 / 750 / 900 / 1050 / 1200**, and
**depth 350 only** — p.211, p.214, p.221.

| | printed | needed | delta |
|---|---|---|---|
| width | 1200 | 1220 | **+20** — above the widest printed module, the Q11 shape |
| height | 360 | 313 | **−47** — and 360 is the SMALLEST printed push-up height |
| depth | 350 | 620 | **+270** — no push-up position prints any other depth |

**313 is forced, not chosen:** the appliance opening ends at 2127 and the row at 2440. A printed
H.36 would reach 2487 and break the run.

So there is no catalog match, and now that is a *finding* rather than an assumption — and it
gave the letter three precise deltas against a named article instead of "we want something
custom". **Elda Q19.**

### What was built

```
UCON-BESP-001 — custom cabinet above the fridge, 1 door opening UPWARD
  x 5587,5..6232,5   y 695,3..1915,3   z 2127,0..2440,0
  carcass 1220 x 620 x 313, front 22 on the same plane as the run
  order line: CUSTOM SIZE - NO ARTICLE, to be quoted
```

- **`opening: "push-up"`** — the CATALOG'S word for a door that opens upward, used for exactly
  that reason. Which mechanism actually carries a front 1220 wide and 313 high is the part no
  page answers, and it is question 5 of Q19.
- **`UCON-BESP-001` lives in the NAME, never in `code`.** The spec's first safety rule is never
  a fake Cesar code; keeping the internal reference out of the code field means no exporter path
  can promote it into one.
- **The neighbours open in different directions on purpose.** Q11 records that the H.60 top
  elements over this niche must NOT open upward. That is the row at 2440–3040. This one is the
  band below it, and the object says so on itself so that a later session does not "fix" the
  disagreement.

### What this does not settle

The mechanism, the three deltas, and whether Cesar will build it at all — Q19. And the same
structural gap as everything else in this file: **the engine cannot regenerate this object.**
It was drawn by `build/44_above_fridge_custom.rb` through an armed probe run.

---

## REDRAWN WITHOUT GAPS — the plinth's rule, applied to an appliance panel

**Andriy, 2026-08-26**, on seeing the panels in the model:

> We redraw with no gaps at all. This is not for the order, it is for LayOut, and gaps read
> as dirt on a sheet. The factory gap between these doors is 3 mm. On our models we draw
> without gaps. We do it the way we do the plinth: the doors are drawn with no gaps, and the
> panels that go to the warehouse are the ones in the Sub-Zero spec.

So the **DRAWN / ORDERED** split that 2026-08-24 settled for the plinth now governs appliance
panels too, and **the attributes disagree with the geometry on purpose**:

| | DRAWN (LayOut) | ORDERED (warehouse, p.19) |
|---|---|---|
| freezer | **486,5** × 1810 | 483 × 1810 |
| refrigerator | **733,5** × 1810 | 730 × 1810 |
| grille | **1220 × 215** | 1219 × 197 |

Joints measured back out of the model: doors **0,0**, doors to grille **0,0**, grille to the
cabinet above **0,0**, and the assembly spans **1220,0 of the 1220,0 run**.

**The joint line was not invented.** The real assembly is 1219 inside a 1220 run — freezer
0,5…483,5, a 6 mm gap, fridge 489,5…1219,5 — and the centreline of that gap is **486,5**. The
drawn faces meet there, so the line an elevation shows sits where the real joint is and only
the gap around it disappears. The grille was drawn up to **2127** for the same reason: at 2109
it left an 18 mm band between itself and the cabinet above.

**Why this is safe to do at all:** the order reads the attributes and the drawing does not.
`width_mm` and `height_mm` still carry Sub-Zero's published panel, so the row that reaches the
warehouse is the real one. Every panel says both numbers in its notes, because a reader who
measures the model and reads the attribute will otherwise think they have found a bug.

## The plinth line runs across the bay

**Andriy, same conversation:** *"yes, draw the standard plinth. The order that goes to the
warehouse is a plinth WITH A CUTOUT."*

Drawn 1220 × 18 × **100**, set back 45 — and **the height was asked, not assumed**: it comes
from the neighbouring tall unit `C92640` through `Generator.plinth_h_mm`, so if that family
ever states 60 this line follows it instead of drifting.

**It carries no contract attributes, deliberately.** Everywhere else in this engine a plinth is
GEOMETRY belonging to the unit in front of it, never an object; giving it attributes here would
have put a plinth row in the order, and **Elda L2 is unanswered** — *no plinth article enters
the registry and none enters the warehouse* until it is. Verified: the model still has exactly
**four** no-article order rows, the three panels and `UCON-BESP-001`, and no plinth among them.

The sentence that must survive lives on the appliance opening instead, which is the object this
bay already has: the plinth box is a representation, the plinth ORDERED there has a cutout, and
the machine's own base is 102 while the drawn line is the run's 100.

### The 2 mm that is left

The plinth tops out at **100** and the doors start at **102**, so a 2 mm strip of the machine's
own base shows between them. It is the last gap in the bay and it is the same question one
level down: draw the doors from 100 and let the drawn height exceed the ordered 1810 by 2, as
the widths already exceed theirs — or leave the machine's real base visible. **Not decided.**

# Elda / DzineElements — Open Questions (Cabinet Engine)

**Org:** UCONSD · **Document role:** Living register of open factory-confirmation questions
raised by the Cabinet Engine · **Version:** v0.1 · **Date:** 2026-07-29 · **Status:** Working

These are questions the source PDF alone cannot resolve. Each stays open until a written
Cesar / DzineElements (Elda / Giorgio) confirmation is linked. Nothing here advances past
`CONTROL` / becomes `CONFIRMED` until answered.

---

## Q1 — Order notation for the door-version choice (opening method)

**Status:** open

**Context / what is already settled.** For a base unit, the article code is the **same**
for the "with handle / push-pull" version (full door, e.g. 78) and the "with grip recess"
version (short door −30 mm with top cutout, e.g. 75). This is confirmed: the Kitchen System
pages (printed p.36 / PDF 38) show both door-height elevations over a single code table,
and the grip-recess (gola) profile is ordered separately as a `GOL` line item. The opening
method is modeled as a separate axis (`opening_method`, see Object Contract §4.1), not part
of the code.

**What is still unclear (the actual question).** Since the article code does not carry the
door version:

1. How should the choice be specified in an order — a free modification flag
   ("with grip recess" / "with handle" / "push-pull"), or something else?
2. Does the grip-recess version of the **cabinet** carry its own modification code or
   surcharge in the current price list, separate from the `GOL` grip-recess profile that we
   already order as its own line?

**Affected families:** Maxima / Intarsio / Tangram base units with paired door-height
elevations — H.39, H.48, H.58.5, H.78, H.84.

**Disposition until answered:** model the full-height (`handle`) front by default; treat the
`gola` (−30 mm) front and its `GOL` profile as a separate, non-default option; keep all such
items `PRELIMINARY` and `P3` where the notation affects orderability.

**Draft text to send (EN):**

> On the base-unit pages, each unit is drawn with two door-height elevations 30 mm apart
> (for example H.78 shows "78" and "75"), but only one article code. The taller front is the
> "door with handle / push-pull" version and the shorter (−30 mm) is the "with grip recess"
> version, where the horizontal grip-recess (gola) profile takes the top 30 mm. Since the
> single article code does not distinguish the two: how should we specify the chosen door
> version in an order? Is it a free modification flag ("with grip recess" / "with handle"),
> or does the grip-recess version of the cabinet carry its own modification code or surcharge
> in the current price list (separate from the `GOL` grip-recess profile, which we already
> order as its own line)?

---

## Q2 — Full-extension drawer travel dimension (plan-view symbol)

**Status:** open · added 2026-08-16

**Context.** UCON preliminary plans need to show fully extended drawers
(dashed) in plan view. The Kitchen System catalog describes LEGRABOX runners
only qualitatively ("soft-close full-extension runners", capacities 40/70 kg;
interior pull-outs 10/30/120 kg). The technical page (printed p.14) gives
drawer-box internal depth only as ranges: 30–40 cm (d.35 carcasses) and
50–60 cm (d.62/d.67). No travel/extension dimension in mm appears anywhere in
the catalog or in the mechanisms extract.

**Question.** For H.78 base units at d.62 and d.67: what is the actual drawer
travel (front face displacement) at full extension, per drawer/jumbo type?
Alternatively: which Blum LEGRABOX nominal length (NL) is fitted per carcass
depth, from which travel follows?

**Disposition until answered:** interim data in use — a Blum LEGRABOX runner
table provided by Andriy (2026-08-16) sits in the registry as
`external_specs`, clearly marked as outside the Cesar source system. The
engine selects the largest NL fitting the carcass internal depth (d.35→300,
d.62→550, d.67→600) and draws plan travel = NL as a stated assumption. The
question stays open until Cesar confirms actual fitted runner lengths.

---

## Q3 — Modification limits and the drawer-width-reduction ambiguity

**Status:** open · added 2026-08-16

**Context.** The Modifications/Customisations section confirms modification
codes (989370 width/height base-wall, 989380 tall, 989350/989360 depth) added
as separate order lines to the unmodified base code, with width modification
prohibited for appliance / interior-drawer / jumbo-drawer / pull-out /
mechanism / framed-glass units, and depth-reduction maxima for drawer units
(D.350 −20, D.620 −90, D.670 −40).

**Questions.**
1. What is the minimum resulting width and height after reduction? The source
   lists reduction as "available" (989370) but states no lower limit.
2. Code 989346 (drawer/jumbo-drawer width reduction, 69 pts) appears on the
   same page that prohibits reducing interior/jumbo drawers. What is the
   distinction — a drawer box / custom-sized drawer vs an interior-drawer
   configuration? When does 989346 apply?

**Disposition until answered:** the engine will refuse width modification for
the prohibited families and enforce the known depth maxima; width/height
reduction minimums stay unbounded-but-flagged until confirmed. 989346 is not
offered until clarified.

---

## Q4 — Sink base units: what distinguishes codes 90 from 91?

**Status:** open · added 2026-08-17

**Context.** Printed p.45 (PDF 47) lists the sink base unit with fixed front
and jumbo drawer twice, as two code series with **identical widths, depths and
prices**: B80790/B80990/B81090/B81290 (and d.67 B90790…) against
B80791/B80991/B81091/B81291 (and B90791…). The corner sink units on the same
page repeat the pattern: AU925/AU935 against AU945/AU955.

The only visible difference is in the front-height annotations. The first
series reads 19,5 + 58,5 in the handle version and 16,5 + 55,5 in the grip-
recess version (sum 720 — two 30 mm recesses). The second reads 19,5 + 58,5
and 19,5 + 55,5 (sum 750 — one recess). Read against our gola model that looks
like "where the 30 mm recess is taken": whether the fixed front also loses 30
under the worktop, or stays full height because it never opens.

**Question.** What distinguishes the two code series? If it is the grip-recess
arrangement, which one is ordered when the kitchen has a continuous gola line
across the run?

**Disposition until answered:** printed p.45 is NOT extracted. The four types
on printed p.44 are in the registry; p.45 waits for this answer rather than a
guess.

---

## Q5 — 75 cm dishwasher door: which side does GBBF01 go?

**Status:** open · added 2026-08-17

**Context.** Printed p.47 states that for the 75 cm wide dishwasher door
(V80730) "a stainless steel cabinet is installed adjacent to the 60 cm wide
appliance", ordered as `GBBF01` (W15), and that "an automatic opening and
closing mechanism is installed on the right-hand side panel". 60 + 15 = 75, so
the geometry is unambiguous; the position is not.

**Question.** Is the stainless steel cabinet always on one side (and if so,
which), or is the side chosen per order? Does the sentence about the
right-hand side panel fix the cabinet's position, or only describe where the
mechanism sits within it?

**Disposition until answered:** the engine will treat the side as a per-order
axis with no default, the same discipline as `hinge_side` — asked, never
guessed. Nothing is generated until the dishwasher placeholder task is built.


---

## Q6 — Does an appliance panel in a gola kitchen order its own grip-recess profile?

**Status:** open · added 2026-08-17

**Context.** The dishwasher door (printed p.47, V80530/V80630/V80730) is drawn
with the same two door-version elevations as any front: 78 and 75. In the 75
version a cabinet front loses 30 mm and the `GOL` grip-recess profile is
ordered as its own line (§4.1 of the Object Contract, Q1). The panel, however,
is not a cabinet front: it bolts onto the appliance, and the profile above it
runs along the worktop as part of the adjacent units' order.

**Question.** In a gola kitchen, does the dishwasher panel carry a `GOL`
profile line of its own, or is the profile above it already covered by the
run? If it does, is it the same undercounter profile as the neighbouring
units?

**Disposition until answered:** the engine shortens the panel to 750 in the 75
version (the elevation is printed, so the height is a source fact) but does
NOT require or invent a profile line for it. A profile may still be recorded
by hand if the order needs one.

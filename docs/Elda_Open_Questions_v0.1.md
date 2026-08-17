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

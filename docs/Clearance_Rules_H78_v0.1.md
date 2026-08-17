# Clearance rules v0.1 — 2026-08-17

Source-backed clearances: the minimum gaps the catalog requires between a unit
and whatever stands next to it. Read from printed p.10, p.11 and p.14
("Technical and dimensional information", `sources/factory/CESAR - 2 Kitchen
System.pdf`, PDF = printed + 2).

These are CATALOG FACTS, quoted verbatim below. Nothing here is implemented
yet: the engine builds single units and continues a run, it does not validate
neighbours. This document exists so that when placement lands (roadmap M2.1a /
M2.2) the rules are already written down and sourced, instead of being
reinvented from memory.

Trust: SOURCE. Nothing on this page has been confirmed by Elda.

---

## 1. Hinged door against a wall or a tall unit — 5 cm closing strip

Printed p.11, "overall dimensions of adjacent tall and wall units", verbatim:

> If a rh or lh wall unit with a "D" handle is installed adjacent to a tall
> unit or a wall, it is advisable to fit a closing strip of at least 5 cm so
> that the wall unit can be fully opened. Alternatively, use wall units with
> top–hung, push–up or horizontally–folding doors.

And, on the same page:

> Add a minimum 5–cm wide closing strip between the tall fridge unit and the
> wall so that the doors can be opened fully and any drawers inside the fridge
> can be pulled out.

The accompanying diagrams draw the strip as a 5 cm band between the wall and
the unit, with the door's swing arc shown dashed over it.

**Why it is a left/right rule.** The strip is needed on the side the door
swings from — the hinge side. The same article with the opposite `hinge_side`
needs the strip on the opposite side, or no strip at all if that side is open.
This is the first rule we hold where `hinge_side` changes the PLAN, not just
the symbol.

**Engine consequence (PLANNING, not implemented).** At placement time: if a
unit whose opening is a hinged door has its hinge side facing a wall or a tall
unit, either insert a filler of at least 50 mm on that side, or flag it. The
catalog says "advisable", not "required", and it names an alternative (a
top-hung / push-up / folding door), so this should surface as a WARNING with
the alternative offered — never as a silent auto-insert.

**Scope caution.** The quoted sentence is written about WALL units, which we do
not hold yet (our registry is base units H.78). The fridge sentence is about
tall units. Whether the same 5 cm applies to a base unit with a "D" handle is
not stated on p.11 — do not extend it there without asking.

## 2. Corner tall unit next to a base or tall unit — 5 cm closing strip

Printed p.11, "overall dimensions of corner tall units", verbatim:

> To prevent "D" handles from colliding with each other, we suggest you fit a
> minimum 5–cm wide closing strip between the corner tall unit and the adjacent
> base or tall unit.

Same page, the depth pairing for corner tall units:

> Base units with 62–cm side panels, tall unit with 70–cm fixed door. Base
> units with 67–cm side panels, tall unit with 75–cm fixed door.

Both diagrams on the page are drawn RH — see §5.

## 3. Corner fillers — which size, and when the 8x8 is mandatory

Printed p.10, "overall dimensions of corner base units", verbatim:

> Fit corner base units with 8x8–cm fillers adjacent to drawer units, jumbo
> drawers and dishwashers (or custom–sized corner base units).

Printed p.10, "Overall dimensions of Magicorner base units", verbatim:

> Min. dimensions of corner filler for push-pull device or grip recess = 5x5
> cm; for Frame grip edgings = 6x6 cm; for handles the filler's minimum size
> depends on the model and its relative position.

Printed p.11 repeats the 5x5 / handles clause for Slidecorner and Slidecorner
Planero (it omits the 6x6 Frame grip line).

**Reading.** Our `base_corner` rows carry the 8x8 unconditionally, because the
p.42 price-list description of the article itself says "8x8 fixed corner front
panel" — the 8x8 is part of what is ordered. The p.10 sentence is a PLACEMENT
instruction about the neighbour (drawer unit, jumbo drawer, dishwasher), and
the 5x5 / 6x6 minimums belong to Magicorner and Slidecorner, which we do not
hold. Do not use the 5x5 number on an ordinary corner base unit.

## 4. Modification limits (feeds Elda Q3)

Printed p.10, on both corner families:

> Out of square modifications are not available for glass and ceramic doors.
> Doors cannot be reduced in size.
> Off–square glass and ceramic doors are not available.

Printed p.14, beside the LEGRABOX / jumbo drawer diagrams:

> It's not possible to reduce the width of a drawer structure designed to
> accommodate a sink.

The last one is a hard constraint on the sink bases we DO hold
(`sink_base_h78.json`): a jumbo-drawer sink base may not be narrowed.

## 5. RH / LH on the drawings — do not read the hand off a picture

Printed p.10 (corner base units) and printed p.11 (corner tall units) both
label the plan diagram **RH**. Printed p.42, the price list for the same
articles, labels its iso **LH**. The code itself carries neither: it carries
**D / S** (destra / sinistra).

What p.10's RH diagram actually shows: the corner at the LEFT, the door at the
RIGHT end of the run, the 8x8 filler immediately left of the door, and the
blind wasted zone further left behind the returning run. That is our `D`
execution — so, on these pages, **RH = D = door at the right end**, and our
geometry matched the drawing with no change.

But the two pages disagree in which hand they illustrate, so:

**Rule: the hand is read from the code letter, never from a drawing.**

Whether Cesar treats "rh/lh" in the article description as the door's hinge or
as the cabinet's execution is Elda Q7.

## 6. Depths the catalog recognises (printed p.17)

The measurement conversion table lists depths 35, 57, 62, 67, 72 and 77 cm.
We hold 35, 62 and 67 in H.78. Note d.57: printed p.10 prices corner nodes at
95x65 / 110x65 / 125x65, i.e. a d.57 corner base (65 = 57 + 80) that does not
appear on p.42. Recorded as a gap in `_manifest.json`; its own page has not
been located.

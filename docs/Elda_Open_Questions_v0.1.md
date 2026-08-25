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

**Status:** ANSWERED FOR WIDTH 2026-08-24 by estimate 2026/30831, otherwise open · added 2026-08-16 — see the dated block at the foot of this file

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

**Status:** open · added 2026-08-17 — the COMPANION is now confirmed by estimate 2026/30831; the SIDE is still not stated, so the question stands

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


---

## Q7 — "rh or lh" in the corner base description: the door's hinge, or the cabinet's execution?

**Status:** ANSWERED 2026-08-24 · added 2026-08-17 — see the dated block at the foot of this file. THE ENGINE DOES NOT YET FOLLOW THE ANSWER.

**Context.** A corner base unit is ordered as `AU110D` or `AU110S` — the letter
is Destra / Sinistra. The carcass is not symmetric (one end carries the door
and the 8x8 fixed corner front panel, the other is blind), so the mirror is a
genuinely different article and a U-shaped kitchen needs both. Separately, the
door itself has a hinge side, which for every other unit we order is a free
per-order choice that does not change the code.

The catalog uses "rh / lh" for both senses without defining either:

- printed p.42, in the article description: "– 1 rh or lh door";
- printed p.42, beside the iso of the article: **LH**;
- printed p.10 ("overall dimensions of corner base units") and printed p.11
  ("overall dimensions of corner tall units"), inside the plan diagram of the
  same product: **RH**.

So the two dimension pages illustrate the opposite hand from the price-list
page, and neither picture is tied to a D or an S. Reading p.10's diagram
literally — corner on the left, door at the right end, 8x8 immediately left of
the door — makes RH correspond to D.

**Questions.**

1. In "1 rh or lh door", does rh/lh name the DOOR's hinge side (a free choice
   inside one article), or the CABINET's execution (already fixed by the D/S
   letter)?
2. If it names the door: on a `...D` unit, may either hinge side be ordered,
   and how is that stated on the order?
3. Is the RH on printed p.10 / p.11 the same axis as the LH on printed p.42,
   or are the two pages labelling different things?

**Why it matters.** Our exporter must emit exactly one article code plus, where
it is a real choice, the hinge side. If rh/lh IS the execution, then "hinge
side" on a corner unit is not an order field at all and must not be emitted;
if it is the door, then it is, and the D/S letter alone does not determine how
the door opens.

**Disposition until answered:** the engine keeps them as two independent axes —
the code letter drives the geometry (which end carries the door, the 8x8 and
the wasted space), `hinge_side` drives only the opening symbol. The hand is
read from the code letter and NEVER from a drawing; see
`docs/Clearance_Rules_H78_v0.1.md` §5.

---

## Q10 — What is the thickness of the front-only closing strip?

**Status:** open · added 2026-08-24 · **we have acted, and this is the
confirmation, not the blocker**

Printed p.434, first position, *"Fillers in door finishes from 2,3 to 15 cm —
front in door finishes"* — `B00151` … `CH9151`. The table prices the article by
height and **prints no depth beside it**, where the two positions below it both
print `d. 35`.

**We have recorded 22 mm and drawn it**, on three grounds: the section detail of
that position shows a single layer in the front plane bracketed to the
neighbouring carcass, with no box behind it; the position directly beneath it on
the same page dimensions the identical *"front in door finishes"* as
**35 / 0,3 / 2,2** — box, gap, front; and Cesar's own SketchUp export of estimate
2026/30831 measures the front at 22.

**Questions.**

1. Is the front-only closing strip 22 mm thick, like a door front?
2. Does it ever come in another thickness — for a framed door, or in Groove,
   where the page already says the minimum width changes to 5 cm?
3. Is it supplied with the fixing bracket the drawing shows, or is that the
   fitter's?

---

## Q8 — Is the door-version choice offered by the FAMILY or by the ARTICLE?

**Status:** open · added 2026-08-24

**Context.** Every base page prints two elevations over its code tables — the
full door height and the same height less 30 mm, where the top of the front
goes into the gola profile. We have read that as a FAMILY fact: 78 / 75 at
H.78, 48 / 45 at H.48, 39 / 36 at H.39, 58,5 / 55,5 at H.58.5. The registry
stores it once per family and the properties panel offers the choice on every
article in that family.

**Printed p.32 contradicts that.** The first position on the page, *Base unit
with pull-out door* (`B30100`, `B40100`, `B40300`), prints **one** elevation:
58,5, and nothing beside it. The two positions below it on the same page, both
positions on printed p.33 and all four on printed p.35 print **both**. And the
same position one family up — *Base unit with pull-out door* on printed p.36 —
prints **78 / 75**.

So at H.78 the pull-out door has a gola version and at H.58.5 the page does not
draw one.

**Questions.**

1. Are `B30100`, `B40100` and `B40300` available in the gola (55,5) execution?
2. If they are, why does printed p.32 print one elevation where printed p.36
   prints two — is the second elevation informational rather than an
   availability statement?
3. If they are not: is the door version an ARTICLE property in general, and are
   there other positions whose single elevation we have read as a family fact?

**Added 2026-08-24, the same day, from the other end of the catalog — and this
half is not a doubt, it is a printed contradiction inside one family.**

Family **Tall H.210** now holds two sections at once:

| section | printed | what the elevation prints |
|---|---|---|
| `Tall units H. 210` | p.111 | **one** dimension: `210` |
| `Tall units H. 210 \| for base unit H. 78` | p.116 | **two**: `132 + 78` and `132 + 75` |

Same height, same plinth, same two depths, different letter pair (CQ/CR against
C5/C6). So within one family one section states a gola execution and the other
states nothing at all. `door_versions` is stored per family and merges per
family, so it cannot hold both answers: declaring the pair would offer a plain
full-height door a 2070 front the catalog has never printed, and that is Q8's
own failure mode, arriving from the opposite direction.

The registry's answer for now is to record the split **per unit type**, in
`front_layout.gola_stack_top_to_bottom`, and to leave `door_versions`
undeclared — exact, and it cannot leak. The cost is that the properties dialog
offers these units no 78/75 switch, because `80_panel` reads the family key.

**Question 4.** Is the door version scoped to the SECTION rather than to the
family or to the article? If yes, `50_registry.rb` and `80_panel.rb` need it
section-scoped, and Q8's first three questions may have the same answer.

**Why it matters.** This is the same axis the 19 held-and-not-buildable H.78
codes wait on, approached from the other side. There, two codes print a gola
elevation that does not sum to the handle height and we cannot say *this
article exists at 75 and not at 78*. Here, one position prints no gola
elevation at all and we cannot say *this article exists at 58,5 and not at
55,5*. One answer settles both.

**Disposition until answered:** `door_versions` stays a family key, the panel
keeps offering 55,5 on all three codes, and the absence is recorded in
`registry/cesar/base_h58_5.json` → `base_pull_out_door.door_version_note` and
pinned by a check that fails the day the axis narrows.

---

## Q9 — H.58.5 at d.67: the modularity page offers it, the price pages do not

**Status:** open · added 2026-08-24

**Context.** *CESAR - 1 Project Guidelines*, printed p.68 (*Modularity of base
units H. 78*), gives every base family a depth list. H.58.5 reads
**35 / 47 / 62 / 67**, plus 72\* and 77\* on request.

The price pages for the family — printed p.32-34 for the base units and printed
p.35 for the sink bases — print **d.35, d.47 and d.62 only**. There is no d.67
row anywhere in the family, and the code grammar has no fourth prefix for one:
H.58.5 is `B3` / `B6` / `B4` and H.78's d.67 prefix `B9` belongs to H.78.

**Questions.**

1. Is a d.67 H.58.5 unit orderable, and under what code?
2. If it is a made-to-order depth like the 72 and 77 marked with an asterisk,
   should the modularity page's list be read as *available* or as *the depths
   this height can be built at*?

**Why it matters.** Small, and worth asking while the page is open: the picker
offers depths from the registry, so a depth that exists and is not held is a
gap a planner will hit and read as our oversight.

**Disposition until answered:** `depths_mm` for H.58.5 records what the PRICE
pages print — 350 / 470 / 620 — and the discrepancy is written into
`registry/cesar/base_h58_5.json` → `page_observations`.

---

## Q11 — Can a top element be supplied at 610 mm, where the widest side-hinged one printed is 600?

**Status:** open · added 2026-08-25 · **blocks a live project, not a hypothesis**

**The project.** 545 Avenida Primavera, east wall. Tall units **H.234** on a 100 plinth with
**H.60 top elements**, d.62 throughout, under a 3048 (10 ft) ceiling — 100 + 2340 + 600 = 3040,
so the run finishes 8 mm short of the slab. In the middle of the run there is a **1220 mm
(48 in) niche for one appliance**. Above that niche the client wants **two cabinets of 610 mm
each**, so that the top row reads as two halves over one appliance rather than as one wide box.

**Why the catalog does not answer it.** The doors above must open to the **side**, not upward.
printed p.172 sells three top-element positions at H.60, and the side-hinged **single**-door one —
*Top element with door – 1 rh or lh door – 1 shelf* — is printed at **W.45 (`SD0531`) and
W.60 (`SD0631`) and nothing wider**. Above W.60 the only door that does not open upward is the
**two**-door position, `SD0930` (W.90) and `SD1230` (W.120).

**And Q3's answer does not reach this case.** Elda, 2026-08-24: a reduced unit keeps the code of
the module it was cut from, and Metron takes *the nearest module above*. For 610 in this position
**there is no module above** — 600 is the largest printed. This is the first width the project has
needed that sits ABOVE a position's widest printed article rather than between two of them, and it
is a different question from Q3, which is about cutting down.

**Questions.**

1. **Can `SD0631` be supplied at 610 mm?** That is 10 mm *more* than the printed width, and the
   Modifications chapter prices reduction (989370 / 989380) and no increase we have found.
2. If not — **is a width INCREASE available at all**, on any article, at a surcharge? Or does
   "the nearest module above" mean an article is simply unavailable above its largest printed
   width, full stop?
3. If an increase is impossible — **can 610 be cut from `SD0930`**, the W.90 two-door top element?
   That would give a 610 box with two doors rather than one. Is it supplied, does it keep
   `SD0930`'s code with `WIDTH REDUCTION: Yes` as the base units do, and is a ~300 mm door leaf
   inside the maker's limits?

**Disposition until answered.** The engine builds **`SD1230`** (W.120, two doors) over the niche.
It is 20 mm narrower than the 1220 it sits above, and that 20 mm is absorbed by the corner filler
at the end of the run rather than left as a gap — see
`claude/findings-2026-08-25-top-elements-and-the-ceiling.md` §7. **Nothing is invented:** no 610
article is written into the registry, and the two-cabinet arrangement the client asked for is not
drawn until this is answered.

**Disposition CORRECTED 2026-08-25, late evening — the engine now DRAWS the 610.** The paragraph
above is kept because the reasoning in it is still right about the catalog; the verdict it drew
from that reasoning was wrong about the workflow. Andriy: *"в жизни делают. Но проблема в том, что
я с этой фабрикой ещё не работал. Поэтому мы делаем чертёж просто в Layout и отправляем Elda, а
потом она руками вводит это всё дело в Metron, и мы сравниваем результаты."* The LayOut sheet is
not an order — it is **the form this question is asked in**. Refusing to draw 610 would have
prevented the ask, and substituting `SD1230` would have sent a sheet that does not show what the
client wants. So `50_registry.rb` now accepts a width ABOVE the printed one, keeps the module's
code, and records `width_increased_from_mm`; `60_generator.rb` marks the object with the variant

    WIDTH INCREASE = "REQUESTED, from 600 mm - NOT PRINTED"

whose `source_ref` says no code and no surcharge exists in anything read and names this question,
and adds the note *THE CATALOG DOES NOT PRINT THIS … feasibility must be confirmed with Cesar.*
**The registry is unchanged: no 610 article exists.** The increase lives on the object, which is
where a request belongs, and the catalog prohibitions (jumbo drawers, mechanisms, appliance
housings) refuse an increase exactly as they refuse a cut. Sentinel:
*a width change keeps the CODE; only the DIRECTION is printed or not*, `tools/test_contract.rb`.

4. **And the same question for HEIGHT.** Under the 610-wide pair over the range the project needs
   **610 × 720**, where the position's printed height is 600. The Modifications chapter prints
   height REDUCTION only, so this is a second unprinted increase, asked the same way. Is a taller
   carcass in a printed position available at a surcharge — and if not, is the answer p.550's
   assembled tall unit (a standard carcass plus a standard top element under one continuous door),
   applied here?

### Ready to send

> On a current project we have a 1220 mm (48 in) niche for a single appliance, flanked by H.234
> tall units, with H.60 top elements above at d.62. Above the niche we would like **two top
> elements of 610 mm each** rather than one of 1200, and the doors must open to the side rather
> than upward.
>
> On p.172 the side-hinged single-door top element is printed only at W.45 and W.60. Can `SD0631`
> be supplied at **610 mm** — that is, 10 mm wider than the printed module? If a width increase is
> not possible, is 610 available by reducing `SD0930` (the W.90 two-door element), and would that
> keep the `SD0930` code with a width-reduction line as the base units do?
>
> We are asking because your note of 24 August explained that a reduced unit takes the nearest
> module **above**; here there is no module above 610 in this position, so we would rather ask than
> assume.

---

## Q12 — `C68654` / `C68754`: one elevation where every other position prints two

**Status:** open · added 2026-08-25

**What the page shows.** printed p.121 position 3 is *Tall unit for oven H. 60*, and its
elevation is a **single** stick — `72 / [oven] / 19,5 / ⌐ / 55,5` — where position 2 immediately
above it prints the usual pair: `72 / 19,5 / 58,5` with handles and `72 / ⌐16,5 / ⌐55,5` with the
grip recess. In position 3 the 19,5 drawer keeps its full height and has **no recess above it**,
while the 55,5 below is recessed. One recess in the whole column, and it closes: 720 + 195 + 30 +
555 + 600 = 2100.

**Why it matters.** The prices are **identical to `C62650` / `C62750` in all eleven bands**, and
the printed descriptions differ only in the capitalisation of *"no Push-pull device"*. So this is
neither the handle version nor the gola version of the position above — it is a third thing with a
mixed stack, and our registry has no shape for it. `front_layout` carries one stack for the handle
execution and one for the gola execution; declaring `C68654` as either would draw a front 30 mm
wrong.

**Questions.**
1. What is `C68654` / `C68754`? A third front programme — the page's side tab names
   *Maxima – Intarsio – **Tangram*** while the header block names only Maxima and Intarsio — or an
   article whose stack simply is what it is?
2. If it is a programme, does the same programme appear elsewhere in the chapter under codes we
   have read as ordinary?

**Disposition.** Not held. printed p.121 positions 1 and 2 are extracted and position 3 is
recorded as read-and-not-held, with its reason, in `registry/cesar/tall_h210_base78.json`.

---

## Q13 — The fridge unit carries the hung pictogram and no hung surcharge

**Status:** open · added 2026-08-25 · **second instance of a disagreement first seen on printed p.42**

printed p.125's single position (`C64601` W.60 / `C64701` W.75) prints the **cabinet-in-a-bracket
pictogram** beside `d. 62` — verified at 600 dpi against printed p.123 position 3's, the same glyph
— while its margin carries only *side panel D. p.549* and *feet H. 5 mm p.548*, and **no
*Surch. for wall-hung version on page 548***.

Everywhere else in this catalog the two signals agree: a position that refuses the hung version
drops both. The printed p.19 pictogram sweep found one exception, the *Corner base unit with
Magicorner* on printed p.42, which carries **the margin line and no glyph** — the mirror image of
this one. **Two instances is a pattern worth asking about.**

**Question.** Is the wall-hung version offered on these two positions? If it is, why is it not
priced; if it is not, why is the glyph printed?

**Disposition.** Both are held as `wall_hung: false`, because the priced offer is the one a person
can actually order. Recorded in `registry/cesar/tall_h210_base78.json` and in
`claude/findings-2026-08-24-pictogram-sweep.md` §4.

---

## Q14 — The chapter sells top elements at H.36 and H.72 and no closing strip to finish them

**Status:** open · added 2026-08-25

printed p.434's first position — the front-only filler, the strip every tall run is closed with —
prints **39 · 48 · 58,5 · 60 · 78 · 84 · 138 · 198 · 210 · 222 · 234 · 278**. It prints **no 36 and
no 72**. The tall-unit top-element chapter sells four heights: **H.36, H.48, H.60, H.72**. Two of
them have no strip of their own.

The only H.72 filler printed anywhere in the catalog is **`PE0151`**, in the third position:
*Wall unit filler … with one-piece bottom*, **d.35** — right height, and drawn for wall units,
which are d.35, against a top-element run at d.62.

**Questions.**
1. Is the front-only closing strip available at **H.36 and H.72**, unprinted?
2. If not, what closes a top-element run at those heights against a wall — `PE0151` at its d.35,
   a side panel from p.549 cut to size, or something else?

**Disposition.** The Avenida Primavera wall was built at **H.60**, where the strip *is* printed
(`BE0151`), so this does not block that kitchen — it was chosen for the door hinge and it happened
to solve this too. The question stays open because the next wall may not have that luxury.

---

## Q15 — What is the maximum load on ONE wall-hung element?

**Status:** open · added 2026-08-25 at Andriy's request · **blocks a live project**

**What is printed.** printed p.548: *"Wall-hung base and tall units — with fixings, 240 Kg capacity
per pair."* The registry records the rest of it: a base unit takes **2** fixings, a tall unit takes
**4**, and `CESAR - 1 Project Guidelines.pdf` printed p.39 adds that a wall-hung base unit is *not*
"without feet" — *"Wall-hung base units are always provided with fixings and a foot to stabilise
them and determine their inclination"*, the foot bearing against the WALL at the bottom rear and
never touching the floor.

**Why "per pair" is not enough to design with.**

1. **Is 240 kg the capacity of a PAIR OF FIXINGS, or of an ELEMENT?** If it is the fixings, a tall
   unit with four of them would carry 480 kg. If it is the element, the extra pair is about
   stability and moment, not load, and 240 is the ceiling however many fixings are used.
2. **What does the 240 include?** The carcass, the fronts and the contents, presumably — but does
   it also cover **anything resting ON TOP of the hung unit**?
3. **And the foot.** It bears against the wall rather than the floor, so it takes moment and not
   weight. Is that right, and does it change the number?

**The concrete case, which is why point 2 matters.** 545 Avenida Primavera, south wall. A row of
tall-unit top elements (`SD` series, H.60, d.62) is to STAND ON a row of hung cabinets beneath it,
because the top-element chapter is titled *"without fixings"* throughout and carries no wall-hung
surcharge on any of its four pages — see Q16. The lower row would therefore carry its own weight
and contents **plus the whole row above and everything in it**, on one set of fixings. Whether that
is inside 240 kg, inside 480, or outside both, is not something the catalog answers and not
something we will guess.

**Question, in one line.** For one wall-hung element: what is the maximum permitted load, does it
scale with the number of fixings, and does it include what is stacked on top of it?

---

## Q16 — Is there a top element WITH fixings?

**Status:** open · added 2026-08-25

All four pages of the top-element chapter — printed p.170, p.171, p.172, p.173 — are headed
**"without fixings"**, and none of them prints *"Surch. for wall-hung version on page 548"* in its
margin, where almost every base and tall price table in the book does. printed p.123 position 3 is
a *"Wall-hung tall unit **with fixings** H. 132"*, so **"with fixings" is this catalog's phrase for
wall-hung**, and its absence here is a refusal in the catalog's own words rather than a gap in our
reading. The registry holds all nineteen top elements as `wall_hung: false` for exactly that reason.

**Questions.**
1. Is a top element available in a wall-hung version, ordered against p.548 or otherwise?
2. If not — is it structurally acceptable to hang one anyway with the p.548 fixings, or must a top
   element always be carried by the cabinet beneath it?

**Why it is being asked.** On the south wall of 545 Avenida Primavera a row of `SD` top elements
sits 1840 mm above the floor with a hood beneath it, so nothing but the wall is available to it
across the range opening. See Q15 for the load half of the same problem.

---

# ANSWERED 2026-08-24 — estimate 2026/30831 and Elda's letter of the same day

Rule 9: this block is ADDED and dated. The questions above keep their text;
only their Status lines point here. Full teardown of the estimate:
`docs/Cesar_Estimate_Teardown_30831.md`.

## Q7 — CLOSED. The letter is the cabinet; the door follows.

Metron printed the two corner rows as **`AU110D` — RH CORNER BASE UNIT WITH
LH DOOR** and **`AU110S` — LH CORNER BASE UNIT WITH RH DOOR**. Elda, the same
day, in words:

> Corner units are differentiated with S or SX for Left-hand and D or DX for
> Right-hand. The door on Left-hand units opens to the right and vice versa.

So the letter names the CABINET's execution, and the door's hand is DERIVED
from it — not a free per-order choice. Note also that orders may carry **SX
and DX** as well as S and D; our grammar knows only S and D.

**This closes Q7b, the corner execution letter, which gated 21 held corner
codes across five chapters.**

**The engine does not yet follow this.** `base_corner` still carries
`handed: true` and the disposition above still describes two independent
axes. Correcting that is a data and behaviour change and belongs with the
corner geometry work, not with this note.

## Q3 — CLOSED for width reduction. Still open for the rest.

A reduced unit **keeps the code of the module it was cut from** and carries a
variant plus a flat surcharge:

| asked for | Metron priced | variant | surcharge |
|---|---|---|---|
| 560 mm | `B80601` (the 600 module) | WIDTH REDUCTION: Yes | +138 points |
| 400 mm | `B80501` (the 450 module) | WIDTH REDUCTION: Yes | +138 points |

Elda: *the 560mm base unit is a 600mm module reduced, while the 400mm is a
450mm module reduced. You can technically start from a 600mm module and get a
custom 400mm cabinet but obviously the starting price will be slightly
higher.* So Metron takes the nearest module **above**, and a wider start is
possible at a price. The `989346` ambiguity and the minimum-width limits are
NOT answered.

## Q5 — half closed.

`V80730` came with **`GBBF01` STEEL UNIT FOR DISHWASHER 75** as its own line,
exactly as this registry already emits it. Which SIDE it stands on is still
not stated anywhere, so the question stays open.

## Answered without ever being numbered

**The wine cooler aperture.** We do not dimension it and there is no separate
article. Elda: *anything that includes appliances will be tailored to the
specific models you pick… the front panel for the wine cooler includes the
workmanship for the finished cutout, which costs the same regardless of the
exact size. This information is usually in the technical sheet of each
appliance, and that's enough for the technical department.* Same for the oven
housing: *the height of the bottom drawer will be customised depending on the
oven height* — which is why the compact-oven housing of printed p.34 prints
only a minimum and is held not-buildable here.

**`989394` on printed p.541 is NOT that route** — it is for the Across system
on a countertop Cesar did not supply.

**Cutouts that are NOT for an appliance** — sockets, switches, vents — DO
need a drawing from us, with exact size and position.

**Front thickness: 22 mm only.** 19 mm is not offered. The edge radius is
minimal. Clearance against panel-ready appliances is solved per layout by
widening gaps or recessing side panels.

**The stainless steel protection printed on every wine cooler door (234
points, no code) is finish-conditional, not compulsory** — it is a frame
inside the cutout, needed where the cutout is made post-production and
exposes the inner layers. On lacquered panels the inner edge is finished
anyway.

**Goods sold by the metre: about 4 m maximum, 3.8 m for wood veneer**, cut to
order with an allowance for site trimming. This is the number joint planning
in a long run has been missing.

**The plinth and the grip profile are NOT generated by the composition
header.** The header fixes finishes and plinth height; the profiles are added
as separate positions after the cabinets and snap to them. Estimate 30831
contains none, which is why.

**A Servo Drive pulls two lines per COMPOSITION**, not per unit: `996811`
TRASFORMATORE PER SERVO DRIVE VERSIONE USA and `996805` PROLUNGA DI
DISTRIBUZIONE.

**Neither export carries article codes.** The SketchUp file names its groups
`Group1`, `Group2`… with internal item numbers such as `2367` and `2715`; the
DXF has no user blocks at all, only `*Model_Space` and `*Paper_Space`. Both
are geometry. Asked back on 2026-08-24: whether Metron can export the
position list as Excel or CSV, and whether the internal item number can be
tied to the article code.

## Q17 — The exclusion list on printed p.548 is headed for WIDTH. Does it govern height too?

**Status:** open · added 2026-08-25

printed p.548 prints three width rows and then a fourth headed **"Units that cannot be modified in
width"** — appliance units, units with interior or jumbo drawers, pull-out units, units with
mechanisms, and tall or wall units with framed glass doors. Immediately below it the same page
prints **height reduction** for base, wall and tall units, code **989370**, 138 points — and prints
**no exclusion list of its own**.

**Questions.**

1. Does the width exclusion list also govern **height** reduction, or is height reduction available
   on families where width reduction is not?
2. The width table charges a tall unit **989380 / 227 points** and a base or wall unit **989370 /
   138**. The height table charges **989370 / 138 for all three classes**, tall included. Is that
   right, or is the tall height row a repeat of the base row in the printed table?
3. **Is a height INCREASE available at all?** See Q11 question 4 — the project needs 610 × 720 where
   the position prints 600 × 600, and nothing read prints an increase in any dimension except a side
   panel's depth.

**What the engine does until this is answered.** `Registry.with_ordered_height` refuses **one**
family and borrows nothing: an **appliance housing**, because its opening height is the appliance's
and not the carcass's — a fact this registry already holds and draws, not a prohibition read off
this page. Every other height change is drawn, and the object carries the note *NO EXCLUSION LIST IS
PRINTED FOR HEIGHT* together with the master rule, so whoever reads the order sees exactly how far
the page goes. Copying the width list across would have been inventing catalog.

---

## Still open after all this

Q1, Q2, Q4, Q6, Q8, Q9 — untouched. Q11 to Q17 are the Avenida Primavera batch and go out with the LayOut sheet. Q5's side. And one new one, asked but not
yet numbered: **what the `O` option of the interior drawer kit gives**, where
Elda chose `L` and had to add the stainless-steel upcharge by hand.

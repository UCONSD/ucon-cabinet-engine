# 2026-08-28 — finishing the panels: a price group is not a finish

**Andriy set the direction:** appliances are paused, the project has to be
finished and given to Elda to price, and appliances do not affect that. Next is
the Counter-Top — **but the panels come first.**

The panels are the island's six. Probe run 78 confirms they are the only Cesar
panels in the model: six `DZAK22`, plus three UCON fridge panels carrying no
article and two `MNS040038` shelves. **And no `object_class: worktop` exists
anywhere**, which is the Counter-Top task confirming it is genuinely unstarted.

---

## 1. What "finish the panels" turned out to mean

`repo-state.md` owed 13 says the island's material is undecided and *"the code in
the model is lacquer where it will be wood"*. `tools/probe_inbox_hold_71.rb` — the
armed probe, written and deliberately held — already had wood codes in it:
`DZ731Q` for the backs and `DV731Q` for the ends, both **price group A**.

**That group was never confirmed by anybody.** It was chosen while the probe was
written and has been sitting inside a held script ever since, and the registry
could not have caught it, because until today **every code in this chapter
carried a price-group LETTER and nothing said what the letter meant.** Ordering
"group A" was ordering an unnamed species list.

## 2. So the letters were given their names, off the pages

Volume 1 printed p.269 indexes the finishes and p.293 holds WOOD VENEERS — but
that page's header is *Breakfast bar and Living top finishes* and its two
categories (First, Prime) do not match the panels' four. **The authority for a
panel is the panel's own page**, and Volume 3 prints the groups beside the codes:

| | printed p.217 — lacquer | printed p.218/220 — veneer |
|---|---|---|
| A | Silk-effect lacquers | **First wood veneers** (7 Rovere) |
| B | Gloss lacquers | **Prime wood veneers** |
| C | Structured lacquers | **Special wood veneers** (Palissandro Santos, Ebano Macassar) |
| D | Metallic effect lacquers | **High-gloss wood veneers** (Acacia, Noce Desaturato, Sicomoro) |

`finish_family` is now recorded on all **38** coded rows. The lacquer rows carry
the family NAME and say that their finish lists are on p.217 and unread — an
absence stated rather than left to look like an oversight.

## 3. THE SAME LETTER, THE SAME PAGE, TWO LISTS

Read off a **200-dpi render** of printed p.220, because `pdftotext` interleaves
the two columns and would have let either reading through (learned rule 10):

> **"Available finishes Th. 1.8:"** offers only **B — Trama wood veneers**.
> **"Available finishes Th. 2.2:"** offers **A First, B Prime, C Special, D High-gloss**.

So on one page, `B` at 1,8 is **Trama** and `B` at 2,2 is **Prime**. printed
p.219 prints the identical structure for horizontal grain. The registry had both
as a bare `"price_group": "B"`, which is true and useless.

`finish_family` is therefore recorded **per code and never per group**, and a
check pins the 1,8 two-sided code to Trama in both grain blocks — proved by
setting it to Prime, the plausible wrong reading, and watching it fail.

A warning triangle on the same page adds the detail that makes it matter:
*"Trama finishes: 1 side with trama, 1 side polished and Trama edge."* **A
two-sided Trama panel is not trama on both sides.**

## 4. Andriy chose B — Prime. Which moved the codes.

|  | was (assumed) | is (decided) | points/m² |
|---|---|---|---|
| backs, 1,8, one side | `DZ731Q` (A First) | **`DZ735Q`** (B Prime) | 343 → **358** |
| ends, 2,2, two sides | `DV731Q` (A First) | **`DV735Q`** (B Prime) | 549 → **579** |

The probe is corrected, and a check refuses it if the group-A codes ever come
back — proved against exactly that edit. **The 663 is untouched**: it is 667 less
the 4 the back loses going from 22 to 18, and `DZ735Q` is 18 like `DZ731Q` was.
The check pins that number to the back's thickness so the arithmetic cannot drift
silently.

### And a constraint the codes cannot express

**Within Prime, the one-sided back offers NINE finishes and the two-sided end
offers SIXTEEN** — the same nine, plus the seven Trama. printed p.218 against
printed p.220.

> So this island can only be finished in the nine both can be: **Rovere
> Termocotto, Castagno Sbiancato, Castagno Grigio, Castagno Toscano, Noce
> Desaturato, Noce Sgubbiato, Eucalipto, Abete Nero, Rovere Rigatino Sbiancato.**
> **A Trama finish cannot be matched across it** — the ends could have it and the
> backs could not.

**Nothing in the codes says this.** Both are *group B, Prime wood veneers*, and
the finish name is an order field that changes no article — which is precisely
why it is a check and not a comment. The finish itself is still to be chosen and
does not block the rebuild.

## 5. What is now true, and what is owed

- The registry says what every price group is, per code.
- The armed probe carries the decided group and is guarded against reverting.
- **The model still holds six `DZAK22`.** Nothing has been rebuilt: probe 71
  calls `Generator.build`, which commits an operation of its own, so the bridge's
  rollback does not apply to any part of it. It runs when Andriy says so.
- **The finish NAME within Prime is unchosen**, and must come from the nine.
- The lacquer finish lists on printed p.217 remain unread — harmless now that the
  island is leaving lacquer, and recorded rather than assumed away.

---

# PART TWO — the east wall ends in the open

**Andriy:** *"the wall with high cabinets ends with nothing. One high, the second
ordinary. 235 and 60 high."*

Probe 79 asked and got a useless answer, because it sorted every run by **X** and
the east wall runs along **Y** — X is that wall's depth axis, so its "ends" were
two faces of the same cabinets. Probe 80 re-asked on the right axis. **Third time
this week that a measurement had to be re-taken because it was taken along the
wrong axis**, after the hood's X-only collision test and the run gap's own
depth/width confusion.

| | |
|---|---|
| the run | y 646,1 → 4915,3 |
| the LOW end | already closed — `C00151` filler 50 × 2340 and `BE0151` 50 × 600 |
| the HIGH end | **nothing** — `C90635` 600 × 620 × 2340 (z 100→2440) and `SD0631` 600 × 620 × 600 (z 2440→3040) |

Exactly what Andriy said: two exposed sides, 2340 and 600.

## 6. The catalog had an answer, and the answer was a collection question

Maxima-Intarsio prints **both** heights at the depth group for a 62-cm carcass
(printed p.440): `F90030` at 2340 and `XF0030` at 600, d.645, 2,2 thick, held and
buildable. **N_Elle prints neither** — its end panels stop at 368 / 780 / 840, in
both the plain and framed versions. So whether a catalog end panel exists here at
all depends on the collection question that `repo-state` has been carrying.

**Q22 does not bite here, and that is worth recording**: the second end-panel
page's depth groups are all back-to-back sums — 750, 1020, 1070, 1290 — while
this is a single 620 run, so only the first page offers a 645 at all. Whatever
Q22 turns out to mean, the article for this end is on page one.

**Andriy chose the Volume 3 sheet, as the island was closed** — which bypasses
the collection question entirely, the same way the island did.

## 7. And then the sheet limits bit

### The end is 3040 and no sheet in the chapter exceeds 3000

Floor to the top of the upper box is 3040. Every veneer block is `width ≤ 3000,
height ≤ 1200`; lacquer is `1200 × 3000`; the tallest anything in the chapter
reaches is laminate's 4180. **One board was never possible.** Andriy: two sheets,
joint at 2440 — where the real joint between the two carcasses already is, which
is how the island's back was split at the breakfast top.

### The grain glyph, read off 300-dpi renders

Both veneer blocks draw the **same** 300 × 120 sheet. The only difference is the
grain glyph, and at text level the two pages are identical — this had to be seen:

| block | glyph runs along | grain limited to |
|---|---|---|
| horizontal grain | the **300** axis | **3000 mm** |
| vertical grain | the **120** axis | **1200 mm** |

**So the island worked and this end cannot, in the same article.** The island's
ends are 663 × 880 on `DV735Q`, vertical grain, 880 of grain inside the 1200.
This end needs **2440 of grain running up the board**, and no vertical-grain
article can carry it.

### The engine refused it in as many words, which is the check working

```
645 x 2440  -> REFUSED: DV065Q is cut from a sheet 1200 mm on that axis;
               2440 does not come out of it. That is a second panel or a
               different material, not a height nobody prints.
2440 x 645  -> ok
```

So the board is ordered **2440 wide × 645 high from the HORIZONTAL-grain block**
and stood on its side. The grain then runs up the finished panel, and every
printed limit is respected. **`DV065Q`** — 2,2, two sides, group B Prime — 2,2 and
two-sided to match the island's ends, B because Andriy chose Prime today.

**Whether that is a legitimate order is Elda Q26**, added today: does
"horizontal / vertical grain" describe the SHEET or the INSTALLED panel? A wrong
reading orders a board whose grain runs across a 2,4-metre end, which is the one
mistake nobody can hide.

## 8. The seat, measured — and it produced the catalog's own number

Probe 81, off the bodies:

```
C90635  CARCASS  x 5612,5..6232,5   y 4315,3..4915,3   z  100..2440
SD0631  CARCASS  x 5612,5..6232,5   y 4315,3..4915,3   z 2440..3040
FRONT (door face)  x 5587,5..5609,5
```

So the finished end spans **x 5587,5 → 6232,5 = 645**: carcass 620 + door 22 +
the 2,5 front gap. **That is exactly the `d. 64,5` Volume 2 prints** for a 62-cm
carcass — arrived at from our own drawn model, not copied from the page.

> It is corroboration for **Q21** and it is not proof. Q21 asks whether the
> printed `d.` is the panel or the whole assembly, and a number our drawing
> happens to reproduce is evidence about our drawing. *Arithmetic that closes
> exactly is not evidence* — the 120 mm fridge base closed exactly and was false.
> Recorded as corroboration, and Q21 stays open.

## 9. `tools/probe_inbox_hold_82.rb` — written, armed, not run

The engine seats a sheet **behind** a run — `sheet_ground` and
`placement_transform` — and has **no rule for finishing an end**. That is the same
gap probe 71 works around for the island, and one kitchen is still not enough to
invent the rule from.

**And this seat is a rotation nothing else in this project has needed.**
`60_generator.rb:642` boxes a panel as `(0, front_y, z0)` by `(w, d, h)` — width
along its own X, thickness along Y, height along Z — so a 2440 × 645 board is
drawn **lying down**. Standing it up is **−90° about the Y axis**, not a yaw.
Every other seat here has been a yaw, which is why this one is written out in the
probe rather than copied from a sibling.

The probe **builds the lower board, measures it, and refuses to build the second
if it did not land within 0,5 mm** of what probe 81 measured. `Generator.build`
commits its own operation, so nothing in it can be rolled back; the most it can
do is stop after one wrong object instead of two, and say that one must be
deleted by hand.

---

## 10. THE GROUP MOVED TWICE IN ONE DAY, AND THE SECOND MOVE IS THE INTERESTING ONE

Both are kept (learned rule 9), because the second is only legible against the
first.

1. Probe 71 was written assuming **A**, and nobody had ever confirmed it.
2. The letters were given their names off printed p.217–220, and Andriy chose
   **B — Prime**, reasonably: it is the larger and dearer list.
3. Then the designer's render arrived. **The kitchen is oak.**

At that point the groups stop being a price ladder and become a species list:

| group | family | oak on BOTH back and end | back/end pts |
|---|---|---|---|
| **A** | First wood veneers | **all seven** — Sbiancato, Nordico, Mediterraneo, Fossile, Dark, Corvino, Cortado | 343 / 549 |
| B | Prime wood veneers | only two — Termocotto, Rigatino Sbiancato | 358 / 579 |
| C | Special | none | 508 / 1038 |
| D | High-gloss | none | 809 / 1002 |

**Group A is the oak group**, and it is also the one where the one-sided back and
the two-sided end offer *the same seven*, so any choice matches across the island.
B's other seven oaks are all Trama and exist on the end only — the constraint §4
found, now with teeth: in B a designer can pick an oak that **cannot be carried
onto the backs at all**.

So the codes go back to what the held probe had before I touched it: `DZ731Q`,
`DV731Q`, and `DV061Q` for the east end.

> **The original codes were right for the wrong reason, and are right again for
> the right one.** They were a guess when written and are a decision now, and the
> difference is not visible in the file — only in this note and in what the check
> asserts.

### So the check stopped pinning a letter

It pinned `DZ735Q`/`DV735Q` for about an hour, which would have made this
correction *fail the suite* — a guard defending a decision instead of a property.
It now pins **the property the decision was made on**: every code the armed
scripts name must have `finish_family: First wood veneers` and offer **only**
Rovere finishes. A letter that stops meaning oak fails here rather than in an
order. Proved by putting the group B codes back and watching it fail.

**What is still not chosen is the finish NAME**, and it will not be chosen from a
render: colour in a JPEG is not a finish sample, and one of the seven is a
decision for Andriy and the client in front of real veneer.

---

## 11. "The one with the least points" — and why that is not a finish

**Andriy asked for the cheapest.** Within a group there isn't one: **points are
per CODE, and the code is group + thickness + faced sides.** All seven Rovere in
group A carry the same 343 for a one-sided back and 549 for a two-sided end. The
finish name has no price at all.

And group A is already the cheapest veneer group — 343/549 against B's 358/579,
C's 508/1038 and D's 809/1002. **So the least-points decision was taken when the
kitchen turned out to be oak**, and the finish name is free: it is chosen on looks
and nothing else.

### The real lever was faced sides, and it was declined on purpose

Every one of these panels has its inner face against a carcass where nobody sees
it, so all of them *could* be the one-sided 1,8 article:

| | points |
|---|---:|
| as planned — one-sided backs, **two-sided 2,2 ends** | **2716,5** |
| all one-sided 1,8, melamine reverse matching the carcass | 2048,9 |
| **difference** | **667,6 — 25%** |

**Andriy, 2026-08-28: the ends stay 2,2 and two-sided.** 2,2 is Cesar's own
convention for an end — every adjoining end side panel in Volume 2 is 2,2 — the
exposed EDGE is thinner at 1,8, and **Q24 is open on what finishes that edge at
all.** A quarter of the panel cost is a real number and it was looked at, which is
the point of writing it down: the next session finds a decision with its price
beside it instead of an unexamined default.

### And 0,97 m² of what is invoiced is air

The chapter's minimum is 0,5 m² per piece, and three of the eight pieces are
under it:

| piece | actual | invoiced |
|---|---:|---:|
| island back upper, left | 0,139 | 0,500 |
| island back upper, right | 0,139 | 0,500 |
| east end upper | 0,387 | 0,500 |

**That is the price of putting the seams where the real joints are** — the
breakfast top on the island, the carcass joint at 2440 on the east wall. Moving
the east seam to 2264 would clear the minimum and save 0,11 m², and would draw a
line across the middle of a tall door. Recorded so the figure is not a surprise on
Elda's estimate, and deliberately not optimised.

### Where the panels stand

Nothing about the finish name blocks either probe: it is an order field and
changes no code. Both are written, armed and unrun, and both now carry group A:

- **`probe_inbox_hold_71.rb`** — the island's six: four `DZ731Q` backs, two
  `DV731Q` ends, at the seats run 56 measured.
- **`probe_inbox_hold_82.rb`** — the east wall's open end: two `DV061Q` boards,
  seated by a −90° rotation about Y, the lower one checked before the upper is
  built.

---

# PART THREE — what the picker showed once it was reopened

## 12. The panels were there all along; the palette was not

*"Не вижу панелей в пикере. Не вижу панелей на проекте."*

**The project half was mine**: Andriy armed the bridge, I asked which probe to
drop, and the oak question intervened. Nothing was ever dropped — the inbox was
empty and the last run was 81. No panels because none were built.

**The picker half was the two clocks again.** The data was never in doubt —
checked headlessly before saying anything: `DZ731Q` sits in `Registry.catalog`
under class `panel_sheet`, labelled *"Panels cut to size (per m²)"*, 44 codes,
carrying the `height_range_mm` that triggers the sheet grid. Closing and
reopening the palette showed all ten types immediately.

**And the screenshot proved the staleness before the picker did.** The bridge
button answered with a MESSAGEBOX, and the current code answers on the status bar
— `announce`, added an hour earlier precisely because a modal blocks the timer.
A dialog bakes its callbacks at open, so that button was still running the
pre-16:17 closure. `Reload core` cannot reach it; only closing the panel can.

> The version dialog was honest throughout: `core v1.1.0, deployed 09:17:44,
> 18 files`, and the newest core file on disk is exactly 16:17:44 UTC = 09:17:44
> PDT, 18 of them. **The engine was current and the window was not**, and only
> one of those two says so on itself.

## 13. AND PRESSING THE BRIDGE BUTTON DISARMS THE BRIDGE

`reload!` loads `probe_bridge.rb`, whose last line calls `start`, and `start`
does `@armed = false` on its fifth line. So the arm Andriy had set was silently
cleared by the convenience I built to save him typing.

**The run counter survives and the arm does not** — `@runs ||= 0` against
`@armed = false` — which is why the dialog could truthfully say *"ON, 7 runs"*
while being disarmed.

That is not a bug in the bridge: a freshly started bridge SHOULD be unarmed.
It is a trap in the pairing, and the worse half is what would have happened next:
probe 71 calls `Generator.build`, which commits its own operation, so **it would
have applied anyway** while the bridge's own accounting said it had not.
Armed-vs-not is honesty, not safety, and here the two would have disagreed.

**The order is therefore: reload the bridge FIRST, arm SECOND.** The button's own
comment says it never arms; it now has to say it also un-arms.

## 14. 74 of 100 picker types show a raw key, and it is not a panels defect

The panels' cards head themselves `panel_veneer_2sides_vertical`. `TYPE_LABELS`
falls back to the key for an unmapped type and says so in its own comment — but
it was written early and **no chapter since has added to it**:

| | |
|---|---|
| type keys in the catalog | 100 |
| with a label | 26 |
| **showing a raw key** | **74** |

Across base, wall, tall, dish-drainer, USA and Linear Elements alike —
`tall_oven_h60_two_jumbo`, `dish_drainer_top_hung_doors_stacked`,
`base_compound_2_compartments_bottom_hung`. **The panels only made it visible.**

**Nothing is wrong**: each card carries the catalog's own description underneath,
which is accurate and readable. It is legibility, and it touches neither the
order nor the drawing.

**Andriy, 2026-08-28: later — panels and the Counter-Top first.** So what went in
is a **ratchet, not a fix**: a check that refuses to let the number GROW. Failing
on all 74 would fail the suite for a week and teach nobody anything; refusing the
75th means the next chapter either labels its types or says in a commit that it
chose not to. It also fails if the number reaches zero, so it gets deleted rather
than left passing vacuously. Proved by inventing a type and watching it report
*"the picker shows 75 raw type keys, was 74"*.

### And the fix made its own guard fire, correctly

`status_line` now ends: *"Starting it CLEARED any arm: type
`UCON::ProbeBridge.arm!` again if you meant to."* — and the check written
yesterday, *"the bridge button never arms"*, failed at once, because it greps the
non-comment body for `arm!`.

**It was right to fire and it was asking the wrong question.** The invariant is
*no one-click arm*, not *the word never appears* — and a message that NAMES the
method is the opposite of a hazard. It now asks three sharper questions instead:
`main.rb` must not mention it at all; the `reload_bridge` callback must not call
it; and in `DevBridge` every occurrence must sit inside a quoted string — something
the tool SAYS, never something it does. Proved by adding a real
`::UCON::ProbeBridge.arm!` after the `load` and watching it report
*"DevBridge calls arm! rather than naming it"*.

> A guard that forbids a WORD stops the thing it was aimed at and also stops you
> explaining it. The fix was to name the behaviour instead of the token.

---

# PART FOUR — the island is wood

**Run 71 applied**, and the bridge said so in its own words rather than pretending
otherwise:

> *WARNING: THIS RUN APPLIED. THE ROLLBACK DID NOT HOLD.
> entities 63 → 63, definitions 779 → 791, positions 348053 → 346763.*

Exactly as the probe's header promised: `Generator.build` commits an operation of
its own and that commit closes the bridge's outer one. Entities unchanged because
six were erased and six built.

## 15. Verified by reading the model, not the builder's report

Run 83, read-only — the same discipline run 43 applied to the east fridge:

| | |
|---|---|
| `DZAK22` remaining | **0** |
| `DZ731Q` backs | **4** |
| `DV731Q` ends | **2** |

**The drawn thickness agrees with the attribute on all six** — 18 on every back,
22 on both ends. That is the check that would have caught a wrong article, because
a `DV731Q` drawn 18 thick would mean the generator had taken its depth from
somewhere other than the code.

### And the 4 mm landed

The whole reason this was a rebuild and not an attribute edit:

```
back OUTER face at y : 2350.9
end (left)  far edge : 2350.9   FLUSH
end (right) far edge : 2350.9   FLUSH
end LENGTH along y   : 663.0    (was 667 when the back was 22)
```

The back went 22 → 18, so the end that wraps its edge went 667 → 663, and both
ends finish exactly on the backs' outer face. **Measured out of the model, not
computed from the plan.**

### The order side

Both codes reach the order as `manufacturer: cesar`, `status: PLANNING`, citing
`CESAR - 3 Linear Elements.pdf` printed p.218 for the one-sided backs and p.220
for the two-sided ends — the right page for each, which matters because those two
pages are where the grain and the finish family differ.

**What is still owed on the island:** the finish NAME, one of the seven First
oaks, chosen in front of real veneer and not from a render. It is an order field
and changes no code.

---

# PART FIVE — the east wall's end is closed

**Run 82 applied**, and both boards landed with **worst error 0.00** against what
run 81 measured. The first-board check never had to fire.

## 16. The rotation was right, and the model says so in the shape of the numbers

```
заказан 2440 x 645   нарисован 645.0 x 22.0 x 2440.0
заказан  600 x 645   нарисован 645.0 x 22.0 x  600.0
```

**The ordered WIDTH became the drawn HEIGHT.** That is the −90° about Y doing
exactly what it was derived to do — and it is also Q26 made visible: the article
is ordered 2440 wide because its height range stops at 1200, and it stands up
2440 tall in the kitchen. The order and the drawing describe the same board with
their axes swapped, on purpose, and the object's own note says so.

| | |
|---|---|
| `DV061Q` in the model | **2** |
| thickness drawn vs attribute | **22 = 22**, both |
| seam between the boards | 2440 to 2440, gap **−0.0** — встык |
| panel's near face vs the cabinet's end | 4915.3 vs 4915.3 — **вплотную** |
| span across the end | **5587.5 → 6232.5 = 645** |

645 is the door face to the wall: carcass 620 + door 22 + the 2,5 front gap —
the number Volume 2 prints as `d. 64,5`, reached again from the drawn model.

**And the source citation is the right page**: `printed p.219`, the
horizontal-grain two-sided block — not p.220, which is where the island's ends
came from. Two ends of one kitchen, two different pages, because one needed 880
of grain and the other 2440.

Objects with the contract: **59** (57 + 2).

## 17. What the panels leave behind

**Done:** the island in oak, the east wall's open end closed, every price group
named, the Trama trap pinned, the oak property pinned.

**Owed:**
1. **The finish NAME** — one of the seven First oaks. An order field; changes no code.
2. **Elda Q26** — whether ordering a horizontal-grain board and standing it up is
   legitimate. **Two boards in the model now depend on the answer**, and they say
   so on themselves.
3. **Elda Q21** — the printed `d.` corroborated twice now by our own geometry, and
   still not proof.
4. **Elda Q24** — what finishes the edge of a veneered panel.
5. **74 raw type keys in the picker** — ratcheted, not fixed.

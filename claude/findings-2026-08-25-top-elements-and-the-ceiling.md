# Findings — top elements, and why 148 cannot happen

**Date:** 2026-08-25 · **Session:** Cowork, office Mac, device bridge + the probe bridge
**Source:** printed p.170 / PDF 172 and printed p.173 / PDF 175, read at 150 and 600 dpi
**Model:** `545_Avenida_Primavera_Kitchen_Preliminary_Model_v0.1_1.skp`, measured through
`tools/probe_bridge.rb`

---

## 1. THE LATTICE — the answer to a question that was asked as a number

Andriy: *"148 до потолка действительно важно."* **148 is not reachable.**

Both ladders in this catalog step by **120 mm**. Tall units on a base H.78 plinth go
1980 / 2100 / 2220 / 2340; top elements go 360 / 480 / 600 / 720. The plinth is 100 and
the ceiling is 3048 — **10 feet exactly, confirmed by Andriy and by the model bounds.**

So the leftover under the ceiling can only take the values

> **8 · 128 · 248 · 368 · 488 · 608** — every one of them ≡ 8 (mod 120)

| tall | floor → top | +H.36 | +H.48 | +H.60 | +H.72 |
|---|---|---|---|---|---|
| H.198 | 2080 | 608 | 488 | 368 | 248 |
| **H.210** *(built)* | 2200 | 488 | 368 | 248 | **128** |
| H.222 | 2320 | 368 | 248 | **128** | **8** |
| H.234 | 2440 | 248 | **128** | **8** | −112 ✗ |

Two combinations reach the ceiling and both leave 8: **H.222 + H.72** and **H.234 + H.60**.
The wall is built at H.210 today, so either means replacing six `CR0635` columns.

**148 therefore comes from something that is not cabinetry** — a beam, a soffit, a dropped
ceiling over that wall, or a gap somebody intends to leave. `tools/probe_inbox/`
`04_ceiling_over_east_wall.rb` measures what is actually overhead instead of asking again.

**This is worth keeping as a rule rather than as an arithmetic.** A height that is not
≡ 8 (mod 120) cannot be produced by stacking this catalog under this ceiling, so a number
outside the lattice is always a report about the ROOM.

---

## 2. What was held, and what was not

**printed p.173, WHOLE.** One position, `SE0500` / `SE0600` / `SE0700` / `SE0900` /
`SE1200`, d.62, W.45–120. *Top element with top-hung door — 1 top-hung door — 1 shelf.*

**printed p.170, the straight position only.** `SB0500`…`SB1200`, d.62, same widths.
*Top element with top-hung door — 1 top-hung door.* **No shelf, and the difference from
H.72 is printed**, not an omission — a check holds both.

**The two corner positions of printed p.170 are read and NOT held.** They carry the D/S
execution letter, a panel ordered at its own W.70/75/85, and an **ordered width that is not
the carcass width** — W.115 with a 70 panel on a 90 carcass. Corner geometry, Elda Q7b.
The reading is kept in `tall_top_h36.json` → `data.corner_positions_not_held` so it never
has to be done twice.

**printed p.171 (SC, H.48) and p.172 (SD, H.60) are deliberately not read.** Their headings
and prefixes are confirmed on the render, and both carry **a second straight position the
other two pages do not** — *Top element with door — 1 rh or lh door — 1 shelf*. So the four
pages of this chapter are **not one page at four heights**. Reading a page for a height
nobody has chosen is the extraction queue coming back in through the side door.

Registry **724 → 734**. `tools/test_contract.rb` **440 → 443, 0 failures.**

---

## 3. The first codes that refuse the hung version IN WORDS

All ten refuse, and not by a missing pictogram: the section title is **"without fixings"**.
That is the catalog's own sentence, the same kind printed p.37 gives with *"not available
wall hung"*, and it is the strongest form of the reading this chapter offers.

**And "with fixings" is this catalog's phrase for wall-hung** — printed p.123 position 3 is
a *"Wall-hung tall unit with fixings H. 132"*. So the title is not a manufacturing note, it
is an availability statement. The top-element page for the WITH-fixings version has not been
found and is not guessed at.

**No `mounting` value is recorded, and the absence is a reading.** A top element rests on
the tall unit beneath it. It meets neither the floor nor the wall, which are the only two
values Object Contract v2.1 allows, and writing `floor` would be a number nobody can honour
— the same objection §1.3 makes to a hanging height on a floor unit.

---

## 4. THE TEXT LAYER LIES AGAIN — second chapter

`pdftotext` reports `N– Elle` and a second height at H + 2,2 on every page of this chapter —
38,2 against 36, 74,2 against 72. **Rendered at 600 dpi at exactly those coordinates: blank
paper.** White text, or a hidden layer for the N_Elle edition — in the file, not in the book.

`wall_h36.json`'s `n_elle_note` recorded this on 2026-08-23 and ended *"it will not be the
last."* It was not. The numbers are kept as **document leads below source trust** — used for
nothing, drawn by nothing, never quoted to Elda as something the catalog prints — and a
check now enforces that any file keeping one keeps the warning with it.

**Rule 10 says the render is the page.** Two chapters have now shown the text layer claiming
what the page does not, in the mirror image of the pictogram problem, where the art said
what the text layer could not see. **Neither direction is trustworthy alone.**

---

## 5. What the model turned out to hold — measured, not eyeballed

`tools/probe_bridge.rb` was built this evening and these came out of its first two runs.

**The 1219,2 mm gap in the south base run is occupied by a component named `48 WOLF`** —
x 1903,0…3122,2, y 0…742,6, **z 0…928,4**. 1219,2 is 48 inches exactly. It carries no
`CabinetEngine` dictionary, so `audit` cannot see it, the export cannot see it, and no check
can. **That is worse than an empty gap: emptiness is visible, and a foreign component looks
like a settled question.**

Andriy, asked whether that is the range or the fridge: *"оба есть, я путаю места."* **It
does not need resolving to proceed** — that is the whole point of the concept. A reservation
owns the span without owning a body, so both gaps can be marked now and the drawing can ask
the question instead of a person answering it from memory.

The second gap: **619,2 mm at the start of the east wall**, y 696,1…1315,3, in the TALL run,
empty of everything.

**The placeholder convention already exists in this model, hand-made:** a component named
*"Appliance niche 600 — client-supplied machine"* on tag *"UCON — Placeholder (not ours)"*,
z 100…880. Exactly the void idea, drawn by a person because the engine could not.

**And the range's top is at 928,4 against a worktop at 880.** So the run-gap rule proposed
in `docs/Reserved_Void_Spec_v0.1.md` §5 — *floor to worktop* — **is wrong**, and the
correction is that a run gap's height comes from the appliance, and from the section top
only where the appliance publishes none.

---

## 6. The island stood 100 low

Four `B80653` sat at z −100 where every other base unit sits at 0 with its front from 100 to
880. Their worktop was 100 below the wall runs'. **Andriy, 2026-08-25: not intended, and not
noticed.** `tools/probe_inbox/03_island_lift.rb` lifts them; the bridge rolls every run back
by default, so its first run is a dry run of itself.

---

## 7. THE 150 LATTICE, and a filler the catalog does not print

**Added the same evening, after the east wall was built at H.222 + H.72.**

Top-element widths are **450 / 600 / 750 / 900 / 1200** — every one a multiple of **150**,
so **every sum of them is a multiple of 150**. The east wall's clear span is **4378,5**, and
4378,5 − 29×150 = **28,5**. So a top row that reaches both walls **must carry at least 28,5 mm
of filler**, however it is arranged. That is not a layout preference; it is the span.

**And the fridge niche cannot be covered exactly, ever.** It is **1219,2 — 48,00 inches** —
and no multiple of 150 reaches it. The minimum leftover is **19,2**, and **the narrowest
filler Cesar sells is 23**. So the 19,2 falls *below the smallest closing strip in the
catalog* and cannot be closed where it falls.

**What was done instead: move it to the corner.** The row is

| | y | |
|---|---|---|
| *(open, 69,2)* | 646,1 … 715,3 | absorbs the 19,2 |
| `SE1200` | 715,3 … **1915,3** | right edge exactly on the column joint below |
| `SE0600` ×5 | 1915,3 … 4915,3 | one per column |
| *(open, 109,3)* | 4915,3 … 5024,6 | |

178,5 mm of filler is spent where 28,5 would do, and what it buys is that **every visible
joint in the top row sits on a joint in the row beneath it**. The 19,2 disappears into the
corner strip, which is the one place on a wall where a width nobody chose is invisible.

### The article does not exist at this height

printed p.434 position 1 — the front-only strip, the one every tall run uses — prints
**39 · 48 · 58,5 · 60 · 78 · 84 · 138 · 198 · 210 · 222 · 234 · 278**.
**No 36 and no 72.** Two of the four top-element heights have no strip of their own.

The only H.72 filler printed anywhere in this catalog is **`PE0151`**, position 3:
*Wall unit filler … with one-piece bottom*, **d.35**. Right height, **wrong depth** — 350
against a 620 row, because it was drawn for wall units, which are d.35.

**So the two corner gaps are left open, and that is a decision.** Andriy, 2026-08-25: put the
cabinets in, settle the fillers later. Inventing a depth for a printed article is precisely
what the source rule forbids, and *"is the front-only strip available at H.36 and H.72"* is
now an Elda question — the catalog sells the top elements and does not sell a strip to close
them.

### The first run_gap void in a real model

The fridge niche is now **drawn**: `object_class: void`, `void_role: run_gap`, 1219,2 × 620 ×
2320, red, named *"UCON void — run gap 1219.2 mm (fridge, unassigned)"*. Its **height is the
section top and not a published opening**, because no fridge has been chosen — which is the
rule as corrected in `docs/Reserved_Void_Spec_v0.1.md` §3 the same evening. When an appliance
is named, both the height and the note are replaced.

**`place_set` still does not do this** — the void above was placed by a probe. B6 is decided,
demonstrated, and not yet built.

### The bridge's own correction, proved

Run 9 printed **"THIS RUN APPLIED. THE ROLLBACK DID NOT HOLD"** with entities 33 → 35,
definitions 457 → 465 and summed positions 171939 → 188096. The detector this replaced
compared `model.modified?` and had stayed silent through run 7, which applied a whole wall.
**A guard is worth what it catches, and this one has now caught something.**

---

## 8. BOUNDS ARE NOT THE OBJECT — four listings, one mistake

**Added 2026-08-25 evening, while surveying the south wall.** Not a catalog finding; a
method one, and it cost four runs.

Every probe that walks the model has to decide which objects belong to the wall it is
reading. Four of them in a row got it wrong, and all four for the same reason: they
selected on `entity.bounds`.

| run | test | what it lost or gained |
|---|---|---|
| 25 | `min.y < 900` | swept in the **whole east wall** — its units begin at y 646 |
| 26 | `min.y < 2` | lost **every object not 620 deep**, including the two fillers it had just placed |
| 27 | `max.y < 820` | lost **every object with a door-swing symbol**, which pushes the box to y 1194 |
| 28 | origin `y == 620` | lost the **d.350 glass row**, whose front line is y 375, not 645 |

**A bounding box is the object PLUS every symbol drawn on it, and the symbols are exactly
what varies.** A hidden door swing adds 574 mm of nothing. A 22 mm filler strip and a
620 mm cabinet standing in the same run have bounding boxes that share no y value at all.

**The transformation does not vary.** A unit is drawn from its origin backwards, so the
origin sits on the FRONT LINE of its run whatever its depth — and that is the test:
`origin.y == front_line`, plus the back vector to say which wall it faces. Run 28 used it
and finally listed the base run correctly, corner unit included.

**And run 28's own miss was the useful one.** It found no glass cabinets because they are
not on that front line: `PF0631` is d.350 and its origin sits at **y 350**, front face
**375**, while everything 620 deep has its origin at **y 620**, front face **645**. So the
south wall has **two front lines 270 mm apart**, which is the step the render shows and
Andriy confirmed is what the client asked for. A filter that assumed one line could not
have found that; a filter that asked the geometry did.

> **The rule: select by the transformation, report by the bounds.** The origin says what an
> object IS and where it sits; the box says how much room it takes up once its symbols are
> drawn. Reading the second as if it were the first is what happened four times.

---

## 9. Seven boxes with no code became seven articles — and the direction is the whole answer

Late the same evening the drawing stopped being able to answer the question it existed to ask.
Seven objects on two walls carried no article: five on the south wall over the range, two on the
east wall over the fridge niche. They were drawn as `CUSTOM` because the catalog's side-hinged
single top-element door stops at **W.60** and the Modifications chapter prices **reduction only** —
so 610 had nothing above it to be cut from, and the engine refused to invent an article.

**The refusal was right about the catalog and wrong about the workflow.** Andriy, on being asked
whether the code allows widening a unit:

> *«Да, в жизни делают. Но проблема в том, что я с этой фабрикой ещё не работал. Поэтому мы делаем
> чертёж просто в Layout и отправляем Elda, а потом она руками вводит это всё дело в Metron, и мы
> сравниваем результаты.»*

The LayOut sheet is not an order. It is **the form the question is asked in**, and Metron's answer
is the confirmation — which is exactly how width REDUCTION came to be known at all, from estimate
2026/30831. A box with no code cannot be keyed into Metron, so refusing to draw 610 did not protect
the drawing; it removed the only way to find out.

### What the source actually prints, in one table

| | printed? | code | points | where |
|---|---|---|---|---|
| Width reduction, base/wall | yes | `989370` | 138 | printed p.548 |
| Width reduction, tall | yes | `989380` | **227** | printed p.548 |
| **Height reduction, base/wall/tall** | yes | `989370` | **138 for all three** | printed p.548 |
| Width increase | **no** | — | — | nowhere in anything read |
| Height increase | **no** | — | — | nowhere; p.550's combined tall unit is a different article |
| Side-panel DEPTH increase | yes | none | 41 a step | 620 → 670 → 720 → 770 |

Two facts fall out of it that are easy to blur and must not be. **A tall unit is charged more for
width and the same as a base unit for height** — so the height row is not the width row repeated.
And the exclusion list, which the page heads *"Units that cannot be modified in **width**"*, has
**no height counterpart printed at all**.

### What the engine does now

`Registry.with_ordered_width` and the new `Registry.with_ordered_height` both accept either
direction, keep the module's code, demand whole millimetres, and record which way it went
(`width_increased_from_mm` / `height_reduced_from_mm`, and their two mirrors). The generator turns
those into variants that reach the order schedule as their own rows:

```
SD0631   610 x 720 x 620      <- the carcass, under its own code
  WIDTH INCREASE:  REQUESTED, from 600 mm - NOT PRINTED
  HEIGHT INCREASE: REQUESTED, from 600 mm - NOT PRINTED
```

**No code is invented and no surcharge is guessed.** `NOT PRINTED` is in the value, the `source_ref`
says what was read and names Elda Q11, and the note carries *THE CATALOG DOES NOT PRINT THIS* beside
the chapter's own master rule about Cesar. A reduction reads differently on purpose — `Yes, from
900 mm`, with `989370` in the source_ref — because one of the two is something Elda can key in and
the other is something she has to answer.

**The exclusion list is not borrowed for height.** Reusing the width prohibitions would have been
inventing catalog. One height refusal stands and it is ours rather than the page's: an **appliance
housing** takes its opening height from the appliance — the 600 oven niche this registry recovered
from three different family totals — so changing the carcass without changing what it houses breaks
the stack arithmetic one step later with a worse message. Elda Q17 asks about the rest.

### The seven, after the swap

| was | is | direction |
|---|---|---|
| 610 × 600 × 620 ×4 | `SD0631` | WIDTH INCREASE 600 → 610 — not printed |
| 610 × 720 × 620 ×2 | `SD0631` | WIDTH **and** HEIGHT INCREASE — not printed |
| 770 × 600 × 620 ×1 | `SD0930` | **WIDTH REDUCTION** 900 → 770 — printed, `989370` |

The seventh is the one worth looking at twice: the 770 filler-substitute over the right of the hood
was never a custom at all. It is a **W.90 two-door top element cut down**, which is a modification
the catalog sells and prices — the same span, one legal and one not, decided by which side of 600 it
falls on.

> **Cabinets in the model with no article: 0.** Read back from the model after the swap, not from
> the list of what was built.

**Both transformations were COPIED off the boxes they replaced**, never recomputed from a neighbour.
The two walls have different rotations, and §8 above is four bugs' worth of reason not to compute a
seat when an exact one is already sitting in the model.

### And a fifth listing bug, of exactly the §8 family

The verification probe reported the fridge-niche run as the **WEST** wall while every instance name
on it said EAST. The model was right. The probe classified by the back vector — correctly, that part
is the rule from §8 — and then mapped `+x` to WEST. A cabinet's back points **into** its wall, so a
back of `+x` means the wall stands on the `+x` side, and with `NorthAngle 0.0` that is EAST. Reading
the model's own named walls settled it in one run.

> **The rule, extended: the transformation says which wall, and the SIGN says which side of it.**
> Getting the first right and the second backwards produces a report that is confidently mirrored.

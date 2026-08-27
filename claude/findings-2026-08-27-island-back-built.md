# The island's back, built — and a breakfast top at 30 inches (2026-08-27)

Measured, not reported: probe run 56, core 0.91.0, read-only. Six panels, all
`DZAK22`, all on the floor. **Both `YU0028` are gone from the model.**

## 1. What is standing

| | article | x | y | z | m² |
|---|---|---|---|---|---:|
| end, left | 667 × 880 × 22 | 1711,8…1733,8 | 1687,9…2354,9 | 0…880 | 0,587 |
| back lower | 1200 × 722 × 22 | 1733,8…2933,8 | 2332,9…2354,9 | 0…722 | 0,866 |
| back upper | 1200 × 116 × 22 | 1733,8…2933,8 | 2332,9…2354,9 | 764…880 | 0,139 |
| back lower | 1200 × 722 × 22 | 2933,8…4133,8 | " | 0…722 | 0,866 |
| back upper | 1200 × 116 × 22 | 2933,8…4133,8 | " | 764…880 | 0,139 |
| end, right | 667 × 880 × 22 | 4133,8…4155,8 | 1687,9…2354,9 | 0…880 | 0,587 |

Both back courses sit with their face **exactly on the run's back, y 2332,9** —
the number probe 53 measured off the bodies, not one anybody typed.

## 2. THE ISLAND IS FINISHED ENTIRELY FROM VOLUME 3, and that is the answer to
this morning's dead end

The adjoining end side panel of the Kitchen System is priced by CABINET height.
At d.645 it prints **780 or 840** and this island needs **880** — so in all three
collections there is no article for its ends. Andriy deleted both `YU0028` and
cut the ends from the same per-m² sheet as the back: **667 × 880**.

**667 = 645 + 22.** The end wraps the edge of the back panel rather than butting
against it. A joinery decision, and it means the end's width is a function of the
back panel's THICKNESS — change the material to an 18 and the end becomes 663.

## 3. THE SLOT IS A BREAKFAST TOP AT EXACTLY 30 INCHES

The two back courses leave 722…764. Andriy, asked rather than guessed:

> *"2 мм — это люфт на вставку столешницы. The breakfast top должен быть на 30
> дюймов от пола. А кухня примерно 36 дюймов от пола."*

The arithmetic closes to the millimetre:

    722 + 40 (the worktop stated on this model) = 762,0 = 30,000 inches
    + 2 of play for getting it in                = 764  = the upper course's foot

So **the drawn slot is 42 and the ordered top is 40**, and the 2 is a fitting
allowance. Same distinction as the plinth and the scribed filler: *the attributes
are the order and the geometry is the sheet.* `worktop_t_mm = 40` stands.

The upper strip, 764…880, is therefore the band between the breakfast surface and
the underside of the kitchen counter — 116 of visible carcass side.

**The kitchen counter is the other level.** Carcass measured 880 + 40 stated =
920, which is 36,22 in. Andriy said *approximately* 36; recorded as what it is
rather than rounded to what it nearly is.

**AND THE BREAKFAST TOP IS NOT DRAWN.** There is no `object_class: worktop`
anywhere in this model — the 30-inch surface the whole slot is built around
exists only as a gap between two boards. That is the same shape as B6: a
reservation nobody can see is worse than an empty span. **Owed.**

## 4. The material is not decided, and the code in the model is the wrong kind

Everything above is built as `DZAK22` — **lacquered, gloss group B, 2,2 cm, two
sides, 405 pt/m²**. Andriy: *"это будет дерево, и там имеет значение направление
волокон."* Wood is a different set of pages and a real fork:

| | page | thickness | sides | group A | note |
|---|---|---|---|---:|---|
| veneer, one side, melamine reverse matching the carcass | 218 | **1,8** | 1 | `DZ061Q` / `DZ731Q` **343** | the reverse is the carcass finish — right for a face nobody sees |
| veneer, two sides | 219 / 220 | **2,2** | 2 | `DV061Q` / `DV731Q` **549** | |

The first code of each pair is **horizontal** grain, the second **vertical**:
**the direction is IN THE CODE**, which is exactly why two boards of 1200 and not
one of 2400. It is not a sheet limit — the veneer sheet is 3000 × 1200 and a 2400
board fits it easily — it is the figure.

**Choosing 1,8 moves geometry**, per §2: the ends go from 667 to 663.

**Open, for Andriy:** one side or two; group; and whether the 116 band wants the
grain running along its length (horizontal) while the 722 course runs vertical,
or all four the same.

## 5. What the minimum costs here

Actual 3,184 m²; **invoiced 3,906 m²**, because both 116-high strips are 0,139
and the chapter's minimum is 0,5. That is 0,722 m² of air — **292 points at
DZAK22's 405**, or 248 at the one-side veneer's 343. About the price of the four
`990486` fixing kits (69 each, 276) that the run takes regardless.

One 2400 strip instead of two would pay one minimum rather than two. Andriy's
answer is that the grain decides it, and the grain is worth more than 200 points.
**Recorded so the trade is on the record, not so it gets taken.**

## 6. A refusal I would have made wrongly, found by this order

`panels_linear_elements.json` records the lacquered sheet as **width ≤ 1200,
height ≤ 3000**, straight off the drawing's *120 × 300*. For **veneer** that
fixing is right — the grain direction is in the code, so the board has an
orientation. For **lacquer** it almost certainly is not: a 2400 × 116 board would
be cut along the three-metre axis and the page says nothing that forbids it.

So the engine would today refuse a lacquer panel the factory can make. Not fixed
silently: it is either an Elda question or a UCON decision, and the evidence for
each is a sentence the page does not print. **Owed.**

## 7. Drawn by hand after it was built

Andriy moved the panels after generating them. The heights — 722 and 116 — were
typed into the picker; the positions were dragged. **Owed 9 again**: the engine
cannot reproduce this arrangement, because the placement rule seats a sheet at a
selected unit's origin and steps back by that unit's depth, and it knows nothing
about two courses or a slot. A rule for *"the second course of a back, above a
breakfast top"* does not exist and should not be invented from one example.

---

## 8. The material, decided — and the arrangement written down before it moves

Andriy, 2026-08-27: the cheapest wood; 2,2 two sides for the ends *"куда денешься"*;
one side for the backs if it exists; **all vertical grain**.

It does exist, and only at **1,8** — there is no 2,2 one-side veneer anywhere in
the chapter. So:

| | article | code | thickness | sides | pt/m² |
|---|---|---|---|---|---:|
| ends | veneer 2 sides, vertical grain, group A | **`DV731Q`** | 2,2 | 2 | 549 |
| backs, all four | veneer 1 side, melamine reverse matching the carcass, vertical grain, group A | **`DZ731Q`** | 1,8 | 1 | 343 |

**The ends go from 667 to 663**, because they wrap the edge of a back that is now
18 and not 22. That four millimetres is why this is a rebuild and not an
attribute edit.

**It costs what it already cost: 1 578 points against the lacquer's 1 582.** The
cheaper backs pay for the dearer ends almost exactly. All-2,2-two-sides
everywhere would have been 2 145. Invoiced area is unchanged at 3,90 m² against
3,18 actual — both 116 strips still fall under the 0,5 minimum.

**The edge is Q24**, open. The chapter prints *"with ABS edge"* on melamine,
Technomat and laminate and prints nothing on any of the three veneer blocks. That
difference is too deliberate to fill in, and on this island the edges facing into
the breakfast slot are seen at sitting height.

### THE ARRANGEMENT, so it survives `build/` being git-ignored

`build/71_island_recode_ARMED.rb` rebuilds the six. It is a probe, and `build/`
does not travel — the east fridge is already one debt of exactly that shape. So
the seats are written **here**, where they are tracked:

| code | W × H | origin (x, y, z) | rot |
|---|---|---|---:|
| `DZ731Q` | 1200 × 722 | 1733,8 · 2332,9 · 0 | 0 |
| `DZ731Q` | 1200 × 722 | 2933,8 · 2332,9 · 0 | 0 |
| `DZ731Q` | 1200 × 116 | 1733,8 · 2332,9 · **764** | 0 |
| `DZ731Q` | 1200 × 116 | 2933,8 · 2332,9 · **764** | 0 |
| `DV731Q` | 663 × 880 | 1733,8 · 1687,9 · 0 | **+90** |
| `DV731Q` | 663 × 880 | 4155,8 · 1687,9 · 0 | **+90** |

The geometry and the attributes come from `Generator.build`; only the SEAT is
set from these numbers, which probe run 56 measured off the boards Andriy had
already placed. Nothing is invented and nothing moves.

### The two rules that do not exist, named rather than invented

1. **A SECOND COURSE.** `placement_transform` seats a sheet on the FLOOR at a
   selected unit's origin. A board whose ground is the breakfast top is a
   different rule, and one kitchen is not enough to write it from.
2. **A TURNED BOARD.** The ends are the same sheet rotated 90° to finish a run.
   The rule places behind, never beside-and-turned.

### And a third word `mounting` does not have

A strip standing at 764 is neither `floor` nor `wall_hung`, and those are the
only two the contract knows. Rather than force it into an enum with no room, each
strip carries the fact in `notes` — the datum, where the 764 comes from (762 =
30 in, plus 2 of play), and that it was declared and not measured. Same idiom as
the run gap: *the object says which of its numbers was measured and which was
stated.* Whether `mounting` needs a third word, or whether a second course is
better expressed some other way, is a contract question and not a probe's to
answer.

# The first worktop, and a dimension that is a list

2026-08-28, after the panels. 545 Avenida Primavera needs worktops; the engine
held no `object_class: worktop` at all, and `Generator.build_worktop` had been
drawing a grey slab that says, in its own `source_ref`, *"no article chosen"*.

Andriy chose **ceramic**, then — off 200-dpi renders of the swatch pages —
**Dekton Marmorio**, which is **group D**. So one page was extracted:
**Linear Elements printed p.110 / PDF 112**, the 4 and 6 cm tops, two codes:
`TOPDR008040` and `TOPDR008060`.

## What the page does that no page here had done

**The code does not determine the price.** Every section in this registry so far
has had the article code decide the number, or a single price band decide it.
Here one code spans **five finish groups × eight depth bands = forty prices**,
and the code names neither axis. That is domain rule 6 — per-order axes live
outside the article code, like door version 78/75 and hinge side — arriving in
the *price* for the first time. The group has to be carried on the order line
beside the code, and the key is named `points_per_lm_by_group_and_band` for both
axes so that nobody reads it as one.

**And the depth comes from the order.** Width has meant "ask the order" since
the fillers; height since the sheets on 2026-08-27. A top's **depth** is the
third such dimension — and the first that is a **closed list rather than a
range**. A sheet is cut anywhere between two numbers. A top is not: the page
prints eight columns and there is no ninth.

So `Registry.with_ordered_depth` **refuses** anything off the list instead of
clamping to it, and it does not round 660 down to 650. Rounding would choose an
overhang and a price on somebody's behalf. Same reason `with_ordered_height`
gives for not rounding a sheet: nothing here is scribed against a wall.

**The bands are not derived from the carcass, either.** They happen to sit 30 mm
above the depths this book sells — 35→38, 62→65, 67→70 — and the section says out
loud that this is an *observation about this catalog*, not a printed rule
(learned rule 4: record the scope). Computing one from the other would quietly
turn it into a rule, and a deeper band is a legitimate design choice.

**Thickness is on `height_mm`, because a top is thin on Z.** A sheet panel is
thin on Y and carries its thickness on `depth_mm`. Same word, different axis,
different object — and getting it backwards draws a 650 mm thick worktop.

## What is recorded and NOT resolved

The price table prints **max length 314 cm** for all eight bands. The TOP
SPECIFICATIONS block **on the same page** says *"Maximum length of MDi Inalco
tops: 319 cm"*. **3140 is held**, because it is the number in the price table and
it applies to every finish, while the 319 sentence names MDi Inalco only —
groups A and B, and this kitchen is D. If a run ever needs between 3140 and 3190
in an Inalco finish, this has to be asked first.

Only p.110 is extracted. Printed p.104 (1,2 cm) and p.107 (2,2 cm) are the same
grammar at other thicknesses, and **their headings are identical** — thickness is
the only thing that tells the three pages apart, which is worth writing down
because a reader looking for "the ceramic tops page" will find three.

The cutouts for a hob or an undercounter sink are **not** on this page. It points
at a separate *table of workmanships on tops*, printed p.172, which is unread.
Any cutout this kitchen needs is therefore not yet priced.

## The seven checks that failed, and all seven were right

Adding the section broke the suite in seven places, and not one of them was
noise: two code counts (937 → 939), the section census, the class census, the
two-books check (`volume_three` was `%w[panel_sheet shelf]` and its own comment
said a third had to be added *here, on purpose*), the picker label for the new
class, and **the unlabelled-type ratchet firing on its first new chapter exactly
as its own comment predicted it would**. The ratchet stayed at 74 rather than
moving to 75, because the chapter labelled its type.

Five new checks were added, and four of the five pin a **refusal** rather than
the happy path — a top with no depth is not buildable, 660 is not rounded to a
band, 650,5 is not a band, and a length off the 3140 sheet is refused. The fifth
walks the **catalog** as well as the lookup: this section adds four keys, and
adding a key to `lookup` and not to `build_catalog` is the `wall_hung` bug of
2026-08-22.

## The order this kitchen is heading for

`TOPDR008040` — 4 cm — group **D**, Dekton **Marmorio**, in two depth bands:

- **band 650** for the 620-deep runs and the island. The finished front is 644,5
  (620 carcass + 22 door + 2,5 gap), so 650 overhangs the door face by 5,5.
  **806 points/lm.**
- **band 380** for the breakfast counter, which Andriy set at **depth 350** and
  then, when the bands were put to him, at **380 — the stone is 380**, not cut
  down. Nothing is cut, so nothing has to be asked of the factory.
  **618 points/lm.**

The counter is the same material and the same thickness as the worktop; that was
Andriy's instruction, and it is why it shares the code rather than getting one.

## And then the picker found the hole, the same afternoon

Andriy pressed the **Worktops** button that appeared in the picker the moment
the chapter loaded, and SketchUp said:

> Non-positive dimension for CARCASS: w=847 d= h=40

The right refusal in the wrong voice, three layers below the question. Two
defects behind it.

**`Generator.build` ordered a width and a height and never a depth.** Three
dimensions can come from the order as of that morning; that one line knew about
two. It now calls `with_ordered_depth`, so the refusal is the sentence that
names the eight bands.

**And the real one: a top must not be built from the picker at all.** Every
other article here is a thing you choose and then place. A worktop is the
opposite — it has no length, no position and no height of its own; it is as long
as the run it covers, it starts on top of that run, and its depth is a band
chosen against it. All three come off a **selection**, and a list of codes has
none. So it refuses with the run in the message, *before* the depth refusal can
answer a question nobody asked. The same shape as an end panel without a ground
— and found the same way, in the model.

**Why the suite missed it.** The whole-registry sweep *orders* a width, a height
and now a depth before validating, because "valid once ordered" is the honest
claim, and it stayed true. Nothing asked the opposite question — whether an
**un**ordered one could still reach the geometry. It could. That check now
exists for all three dimensions, so the fourth is covered before it is invented.

## What a worktop is now

`Generator.build_worktop` takes an article and writes a real order line:

- **thickness from the code** — 40 or 60, not stated any more. If the project
  already states a different number, it refuses: both numbers are in the model
  (every run gap and hood reservation was drawn to the stated one), so one of
  them is wrong and nothing may choose which.
- **depth from a chosen band**, seated against the carcass **back**, so the
  difference falls at the **front** as an overhang past the door face. A wall
  cannot absorb 5,5 mm; a front edge can, and that is what an overhang is.
- **length measured off the run and then ordered** through
  `with_ordered_width`, so 3140 refuses by itself.
- **the finish group on `pricing_group_ref`** — the one key Contract §1.2 allows
  near a price list, and it holds the reference and never a number.

Without an article it still draws the old placeholder slab, unchanged, because a
kitchen whose top nobody has chosen still needs a surface in the elevation. The
two paths say different things on the object and in the outliner.

The palette's Worktop button asks the article, the band and the group, and
**pre-chooses neither of the last two**: a SketchUp inputbox selects its first
dropdown entry, so anything real put first is what somebody gets by pressing OK
without reading — and both of these are decisions with a price behind them. Both
lists open on a sentinel and the build refuses if it comes back. The article,
group and finish are kept on the model, because a kitchen has one top material;
the **band** is asked every time, because it is genuinely per-run.

## Two questions the model raised, and their answers

**A filler is part of the run.** *"Над кабинетом рисует, а над филлером нет."* The
selection filter named `cabinet` and `corner_unit` and left `filler` out. The
refusal was the loud half; the quiet half was a filler in the **middle** of a
selection contributing nothing to the length, so the top came out short by the
width of the strip and looked right. A filler now counts toward the **length**
and not toward the **datum** — a closing strip takes its depth and its height
from the run it closes — and fillers alone are refused rather than drawn to a
depth of zero. That split is ours; printed p.548 says nothing about what a top
covers.

**And the way to cover one is to draw the run again, not to patch beside it.**
Andriy's call when both were put to him: stone under 3140 is one piece and no
fabricator puts a seam beside a 50 mm strip. So `build_worktop` refuses a slab
that overlaps one already drawn, names what is in the way, and deletes nothing.

**"Глубина по фасаду, до стены" changed nothing, and that is worth writing
down.** It could have meant the stone has to reach a wall standing behind the
carcass — which would have made the back edge a **measurement** and 650 the
wrong band. It does not: at 545 Avenida Primavera the carcass stands against the
wall, so *to the wall* and *to the carcass back* are the same plane. Asked
rather than assumed, because this engine has no notion of a wall at all, and
inventing one to measure would have been a day's work built on a guess.

## And then the approach itself changed

Late on 2026-08-28, after the third refusal in a row came out of the model rather
than out of the suite, Andriy stopped it: *"То, что мы сделали, сейчас ставим на
паузу… я их рисую вручную. А ты делаешь мне интерфейс, чтобы я делал как штамп…
Потому что у нас сложные стены: угловые, подрезанные, под 45°. Мы просто
замучаемся писать правила."*

He is right, and the reason is the project's own discipline turned on itself.
Every rule that generated a worktop shape would have been **inferred from one
kitchen** — the thing this engine refuses to do everywhere else, and the reason
the registry is trustworthy. A generator for tops would have been a rulebook
written from a single sample, and the rules would never have ended: mitres,
scribes, 45° returns, angled walls, notches around a column.

So the division of labour moved. **He draws the stone. The engine names it.**

What that keeps is everything the chapter was worth: the article, the two price
axes, the eight bands, the 3140 sheet, and every refusal — enforced at the stamp
now instead of at the generator. `Generator.build_worktop` keeps its code and its
checks and loses its button, because two ways to make a worktop are two ways to
be wrong.

What it costs is one real thing, and it is written into `core/62_top_stamp.rb`
at the top: **a stamped top does not know the run beneath it**, so nothing checks
that the stone covers the cabinets. `build_worktop` knew, because it measured
them. That has to come back one day as a report over the model — *carcasses with
no stone above them* — and until then, covering the run is Andriy's eye.

**The one assumption is Elda Q28.** A top is priced per linear metre at a band; a
mitred piece has no single length; so the order figure is the piece's **bounding
rectangle**, the sheet it is cut from, and everything the shape does inside that
rectangle is a workmanship. The catalog does not say this. It is written onto
every object the stamp touches, so that if she answers otherwise the numbers move
and nothing else does.

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

**Not done, and named so it is not mistaken for done:**
`Generator.build_worktop` still writes `code: nil` / `manufacturer: 'client'`,
and takes its depth off the carcass under it. With a chapter in hand, both of
those are now wrong in a way they were not wrong yesterday — the article exists,
and the depth is a band that overhangs rather than a measurement. Nothing has
been drawn from this chapter yet.

# Horizontal Thin is not a box — a stub, and what the next session needs

**Status: HELD, NOT BUILDABLE.** Four codes are in the registry, findable and
orderable. Nothing is drawn. Decided 2026-08-27 by Andriy, looking at the result:

> *"Тот случай, когда нужно было смотреть глазами. Мы сделали параллелепипед,
> это никак не полка."*

He is right, and the failure is worth naming precisely, because it is the first
of its kind here.

## Why the box is wrong, and it is not a bug

Envelope-only geometry — **domain rule 4** — draws a carcass as ONE VOLUME. That
has been correct for 924 codes because every one of them IS essentially a box
with a front on it. A Horizontal Thin has **no volume to draw**: a top rail, a
back, two sides, and a shelf floating between them, with air where the box would
be. The solid the generator produced is not a poor drawing of this article. It is
a drawing of a different article.

**This is the first object where domain rule 4's own exception fires:** *"no
interior modelled unless the source states it AND a drawing needs it."* Both
halves are true here for the first time. printed p.458 states it — front, side
and top views with every member dimensioned. And a LayOut elevation needs it,
because the whole point of this element is the gap.

## What printed p.458 already gives, so nobody re-renders it

Read at 170 dpi, 2026-08-27. All in cm as the page prints them.

**Front view** — width **180 / 240**, height **36 / 39**; top rail **1,8**;
bottom rail **1,4**; the shelf reads **80 / 110** across the opening.

**Side view** — overall depth **29,2**; a **10** return at the top; the shelf at
**14,2**. The optional MINI NOOR led is called out on this view, under the shelf.

**Top view** — depth **35**; shelf **87,4 / 117,4**; back **1,2**.

**Note the two depths and do not average them.** The price table sells **d. 35**
and the top view agrees; the side view's **29,2** is a different member. Which of
them is the carcass and which is the shelf's reach has NOT been settled — it is
the first thing to establish, and it is on the page.

**The materials are named, and they differ:** *"Shelf in matt black lacquered
metal"*; *"Side panel in the same finish as the top or door"*. So this object
wants at least two materials, where every other object here wants one.

## The two ways forward — Andriy's, and his choice governs

1. **Read the graphics and generate it.** Everything needed is on p.458 above;
   what is missing is the member-by-member assignment of those numbers and a
   geometry kind that is not `linear`.
2. **Andriy builds one by hand in a separate SketchUp file**, the way he wants it
   to look, and that file becomes the spec — the script is written from a body
   that already satisfies him rather than from a reading of a line drawing.

**Option 2 is the one with precedent.** The corner turn was measured off a
placement he had made by hand, and the 8x8 filler was settled by the factory's
own export after a reading had already been wrong once. *When a constant lives in
two places, only a measurement says which one is the bug.*

## What is owed, exactly

- The geometry, by whichever path.
- **A second `geometry_kind`.** `linear`, `corner` and `non_dim` are the three,
  and a framed open module is none of them.
- **Two materials on one object.** `Geometry.box` takes one.
- p.458's two other obligations, still unwired and recorded in the section file:
  the **mandatory top** above it, and the **finished side panel** on any carcass
  it stands next to. `companion_refs` cannot say *"the run above you must exist"*.

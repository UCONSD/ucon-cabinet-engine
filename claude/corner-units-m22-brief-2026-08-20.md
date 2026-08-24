# M2.2 — corner placement: DONE 2026-08-20 (commit `54e4e74`, core 0.34.0)

Started and finished the same day. Probes `step7_find_corner.rb` and
`step8_seat_corner.rb` in `~/dev/_archive/` settled the behaviour; the rules
then went into `core/22_placement.rb` and the glue into `core/75_place_tool.rb`.
The probes are disposable and can be deleted.

## What a corner unit does now

Select one, run the placement tool, point at either wall of a room corner: the
node seats in the angle with the wasted space in it, and **the article changes
by itself** if the letter you happened to build does not fit that wall.

## The rules that make it work (all headless-tested)

**A corner is two crossing vertical planes, and it must lie ON the wall.**
`Placement.corner_point` solves the 2×2 in plan; parallel planes return nil
(one wall seen twice is not a corner). `Placement.wall_run` then rejects a
crossing that falls outside the wall's own extent — planes cross wherever they
like, including far past the end of a face, and a unit seated there would hang
off the end of the wall. Tolerance 50 mm.

**The wall picks the article, and the door has nothing to do with it.**
`Placement.execution_for` reads the DOMINANT direction the wall runs from the
corner. A wall overhangs its corner slightly on the far side, so a merely
non-zero run is not enough. Wall runs +x → right execution; −x → left.

**The wasted end goes in the angle**, whichever execution — `corner_origin`,
with a check asserting the invariant for both letters.

**One measure of what a unit occupies.** `Placement.span_mm` returns `[low,
high]` along the unit's own x: a straight unit is `[0, width]`, a corner is its
NODE (`[0, nominal]` left, `[−wasted, carcass]` right). The high end continues a
run; both ends feed the neighbour snap, so a corner's wasted space now counts as
occupied and the next unit starts past it. `run_extent_mm` is just the high end.

**The sibling article is looked up, never spelled.**
`Registry.sibling_execution_code` matches node, door and depth and requires the
other execution. A test walks all 18 corner articles and fails if any size lacks
its twin — a U-shaped kitchen needs both letters, so a hole there would be an
order error.

## The swap, and the safeguard that makes it safe

Andriy's call: substitute silently, do not ask. `Generator.swap_corner_execution!`

- makes the definition unique if more than one instance shares it — attributes
  live on the definition, so editing in place would re-article the copies too;
- redraws through the same `draw_corner` the ordinary build uses (a second copy
  of that code would be a second chance to update only one);
- rewrites `code`, renames the instance, and appends to `notes` that the
  execution was chosen by placement from the wall.

**Silent applies to the GESTURE, never to the RECORD.** Nothing reaches an order
that the model does not state plainly. The whole thing sits inside the tool's
single `start_operation`, so one Cmd+Z undoes seating and swap together.

## The picker simplified by itself

Removing the letter from the choice collapsed `cornerList`'s inner loop:
**9 size buttons instead of 18**, captioned "the wall picks the hand". No new
section, no special case — which is why the earlier attempt to carve corners
into their own catalog section was the wrong fix and was reverted (`79d2454`).

## Still open, and one of them is a real risk

- **Elda Q7 can invalidate the swap.** "1 rh or lh door" — does it name the
  door's hinge or the cabinet's execution? The whole rule rests on the second
  reading. The swap is reversible (attributes rewritten, geometry rebuilt), but
  if Q7 comes back the other way this is the piece that has to change.
  *(Update 2026-08-20: Q7a is CLOSED — factory estimate 2026/30829 orders PD0631
  with both opening directions, so for a wall unit the hand is an order variant
  and is not in the code. Q7b, the corner execution letter, stays open.)*
- **The d.57 corner gap** (printed p.10 lists 95×65 / 110×65 / 125×65, i.e.
  d.57, which p.42 does not price). Recorded in `catalog_map`, not invented.
- **Corner sink bases** (printed p.46) and **Magicorner / Slidecorner** pull-outs
  (p.42-43) are not extracted at all.
- Corner-to-corner: two corner units in the same corner, and a corner unit whose
  return wall already carries a run, are untried.
- Performance: the wall scan walks the model to depth 4 on the first mouse move
  and caches; unmeasured on a real kitchen.

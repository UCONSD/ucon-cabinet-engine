# 2026-08-30 — the stone is stamped, and the edges are parked on purpose

Six pieces of stone carry an article. The kitchen's tops are, for the first
time, an order rather than a drawing. What follows is what was decided, what was
measured, and the one question that was deliberately NOT answered.

Companion to `claude/findings-2026-08-29-the-first-stone.md`, whose own dated
correction — the angled wall, the window, and the island's back cladding — was
written the same day and belongs beside this.

## What is stamped

All six are `TOPDR008040`, group **D**, finish **Marmorio**, `code_status`
PRELIMINARY. Every length below was MEASURED off the geometry by the stamp, not
typed into the dialog, and re-stamping re-measures.

| piece | plan | length | band | why that band |
|---|---|---|---|---|
| west run | x 0…645 · y 620…3700 | 3080 | 650 | 5 mm paid, not drawn. 3080 < 3140 sheet |
| south leg | x 0…1903 · y 0…645 | 1903 | 650 | 5 mm paid. Mitred into the west run |
| south, east of the range | x 3123…3997,3 · y 0…645 | 874,3 | 650 | 5 mm paid |
| wedge at the angled wall | x 493,2…645 · y 3700…3802 | 102 | 650 | measures 152 deep; 498 mm of band paid, not drawn |
| island | x 1711,8…4155,8 · y 1687,9…2350,9 | 2444 | **700** | 663 deep and 650 refuses. **88 points, and Andriy chose to pay them** |
| ledge behind the island | x 1734,8…4132,8 · y 2332,7…2712,9 · z 723 | 2398 | **380** | 380,1 deep — the band fits with nothing paid for. The only piece in the kitchen that does |

**The sink came with the stamp.** `SinkMark` refuses where the piece above the
unit is unstamped, so it had been unavailable all week. It is now placed —
`Integrated bowl 70×40×19 over B81087`, x 110…510 · y 1775…2475 — and recorded
as a VARIANT on the west run's own object, not as a separate line, which is
where a surcharge on a top belongs.

## THE CUT: option A, and it was Andriy's drawing that decided it

The west run is 3182 mm from the corner joint to the angled wall and the sheet
is 3140. It cannot be one piece. Three schemes were costed:

| | pieces | joints | points, west + south |
|---|---|---|---|
| **A — as drawn** | 3 | 2 | 4139 |
| B — corner joint moved to y 680 | 2 | 1 | 4118 |
| C — second joint at the dishwasher | 3 | 2 | 4099 |

**Forty points apart on four thousand — one per cent.** So the scheme is not a
price decision and was not made as one. Andriy took **A, because it is what he
had already drawn**, and the drawing already carried the corner detail: the
joint runs along y 620 (the line of the west run's carcass front) and turns 45°
out to (645, 645) to meet the front slab. The south leg was drawn to the
matching mitre.

The cost of A is the wedge: a 102 × 152 piece as its own order line at band 650,
82 points, with its own joint and its own installation.

## THE EDGES ARE PARKED, AND THAT IS A DECISION

Four pieces carry `visible_side_edge = 1` — the west run, the south leg, the
piece east of the range, and the wedge. **The rule Andriy stated says all four
should be 0**, and it is a good rule: *an end is finished where a finished front
runs along it; the range side has no finished front, so that end is ordinary;
the island is finished all round, so its ends are.*

Under that rule the four ones are 569 points that nothing asks for, against a
stone of roughly 10 580 including the bowl — 5,4 %.

**They were left in the model anyway, on purpose, and recorded here as PARKED
rather than as decided.** Re-stamping to fix them means re-opening the dialog,
and the dialog is the actual problem:

> **The stamp asks for ONE edge count and applies it to the WHOLE SELECTION,
> but an edge belongs to ONE END of ONE PIECE.** Four pieces stamped together
> can only be given one number, however different their four pairs of ends are.

So the next session gets the design question, not the typo: **a separate stamp
for edges, or a rule simple enough to survive a shared dialog.** Fixing the four
numbers before that is fixing the symptom, and it would have to be done again
the next time four pieces are stamped together.

## What p.172 owes this kitchen, and it is now two things

`registry/cesar/tops_ceramic_linear_elements.json` already records that the
cutouts for a hob or an undercounter sink are NOT on printed p.110 — p.172
points at a separate *table of workmanships on tops* which is UNREAD.

Add the second: **the ledge behind the island is finished on three sides.**
Andriy, 2026-08-30: *visible on three sides; the side that adjoins the island
stays unfinished.* Two of those three are its ends and the stamp records them.
The third is its long outer edge, 2398 mm, and **p.110 prices no such thing** —
`visible_side_edge` is per END, capped at two per piece, each as long as the
band is deep.

So one unread page holds two priced facts this kitchen needs: the sink cutout
and a finished long edge. Andriy's call for now: *Elda will sort it out.* That is
a decision about the ORDER, not about the extraction — the page is still owed.

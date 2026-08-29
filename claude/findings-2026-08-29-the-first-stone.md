# 2026-08-29 — the first stone, and the day Elda Q28 got a price

Andriy drew the first countertops of 545 Avenida Primavera and asked what to do
with them. Three read-only probe runs answered it, and one of the answers is a
number this project has been carrying as a worry for two days.

## What is in the model

Three groups, all on `Layer0`, none stamped, all 40 mm thick, all sitting
z 880…920 — the carcass tops are at 880, so the finished worktop height is 920.
Thickness 40 picks `TOPDR008040`; `TOPDR008060` refuses everywhere, correctly.

| piece | plan bbox | real top surface | verdict |
|---|---|---|---|
| `Group#3` | 874,3 × 645 | **0,564 m² — identical** | a rectangle. Band **650**, remark: 5 mm of the band paid for and not drawn. **Orderable as drawn.** |
| `Group#2` | 2444 × 663 | **1,620 m² — identical** | a rectangle, but **band 650 REFUSES**: 663 > 650 + 1 mm. Smallest band that accepts it is 700, at 37 mm paid for and not drawn. |
| `Group#4` | 1903 × 3786,8 = **7,206 m²** | **3,012 m², outline 6 vertices** | **an L.** Refused twice: 3787 mm long against a 3140 sheet, and 58 % of the ordered sheet is not drawn. |

## THE NUMBER: Elda Q28 costs 4,195 m²

`62_top_stamp.rb` has carried this assumption in writing since 2026-08-28: a
mitred or angled piece has no single length, so the order figure is the piece's
**bounding rectangle — the sheet it is cut from**. The catalog does not say it;
it is our reading, it is written onto every object it touches, and it is Elda
Q28.

Today it was measured on real geometry for the first time, and it behaves
exactly as the two halves of that sentence predict:

- **On a straight run it costs nothing.** Both rectangles came back with real
  surface identical to bounding box, to three decimal places. The assumption is
  free where it was believed to be free — and that is now a measurement rather
  than a belief.
- **On an inside corner it costs the corner.** `Group#4` orders **7,206 m²** of
  ceramic and draws **3,012**. **4,195 m² — 58 % of the sheet — is ordered and
  thrown away.**

That is the question to put to Elda, and it is a much better question with the
number attached.

**And the practical answer does not wait for her:** cutting the L into two
rectangles at the corner makes the cost zero *and* is how the piece gets under
the 3140 sheet length. The stamp's own refusal already says so and names the
joint as Elda Q27, a line somebody prices. Where the joint falls is a real
decision and worth making on purpose.

## The band, and the 18,5 nobody chose

`Group#2` is 663 deep because it overhangs the island **0,5 mm at the front and
18,5 at the back** — the island carcasses run y 1138,9…2332,9 with the finished
front at 1688,4, and the stone runs 1687,9…2350,9.

The bands are 380 · 650 · 700 · 750 · 800 · 1030 · 1080 · 1300 and there is
nothing between 650 and 700. So the back overhang decides the order: **keep 18,5
and pay for band 700 (37 mm of width unused), or bring it back to ~5,5 and land
on 650.** Not the engine's decision — but it is a decision, and until today it
was being made by an edge nobody had looked at.

## THE MEASUREMENT MISTAKE, AND WHY IT MATTERS BEYOND TODAY

The first covering pass reported **four island units at 53 % and two more at
54–68 %**. All of them were fully covered.

**An instance's bounding box contains the PLAN SYMBOLS.** `Drawing_Spec` puts a
drawer's travel on the floor in front of the unit — about 549 mm — so a 600-wide
base unit measures 600 × 1194 as an instance and 600 × 644,5 as a cabinet. The
pass was measuring the drawer symbol.

Measured on the **carcass**, found by name inside the definition, the answer
collapses to one line: **`B70150` at 87 %** — the stone ends at y 3786,8 and the
filler's back is at 3802, a **15,2 mm strip of uncovered carcass** against the
wall. Worth Andriy's eye; it is either the drawing or the room.

**This is a requirement for the covering report `62_top_stamp.rb` still owes.**
Whatever form it eventually takes, it must measure the carcass and not the
instance box, or every unit with drawers is permanently and wrongly "not
covered" — a check that cries wolf on the majority of a kitchen would be worse
than no check at all.

Two smaller measuring errors are recorded for the same reason (learned rule 9):
`BoundingBox#width/height/depth` are X/Y/Z, so `width × depth` is an elevation
and not a plan; and a face search comparing a WORLD z against DEFINITION
coordinates finds nothing and reports "no top face" on a perfectly good slab.

## What is now a tool

`tools/probe_top_measure.rb` — dev only, writes nothing, never in an `.rbz`. It
finds the stone (the selection, or every thin high body that is not ours),
warns when a group's own axes differ from the world's (the stamp measures the
piece in its OWN axes, and 90_palette.rb warns about the same trap), prints real
surface against bounding rectangle in m², runs every band of every held article
through `TopStamp.verify` so the refusals are visible before the dialog, and
measures the covering on carcasses.

## What is still open, stated rather than decided

- **Where `Group#4` is cut.** Elda Q27, and a design decision.
- **Band 700 or a 5,5 back overhang** on `Group#2`.
- **The 15,2 mm at `B70150`.**
- **The sink.** `B81087` is under the stone and `Sink marks` holds zero
  entities, because the sink mark refuses where there is no stamped top. It
  becomes available the moment the piece over it is stamped.
- **The covering check is still a probe, not a rule.** One kitchen is enough to
  look and not enough to decide what it should REFUSE.

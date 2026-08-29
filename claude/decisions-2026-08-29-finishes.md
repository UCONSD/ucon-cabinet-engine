# 2026-08-29 — the finishes of 545 Avenida Primavera, decided

Andriy answered thirteen questions in one sitting. This is the record. Every
option offered came off a printed page and every page is cited; nothing here was
inferred from another kitchen.

**The list of questions is not ours.** It is the Cesar order form itself —
Volume 1 printed p.65–66, "Maxima 2.2 order form". Intarsio (p.49), N_Elle
(p.198) and Unit (p.158) carry the same blocks.

## The decisions

| | decision | source |
|---|---|---|
| Collection | **Maxima 2.2** | p.65 |
| Price band | **6** — and both fronts land on it independently, F6 and F6 | p.12–13 |
| Front 1 | **RR09 Rovere Nordico** — First-category wood veneer, F6 | p.58 |
| Front 2 | **LX19 Nero** — structured lacquer, F6 | p.57 |
| Grip recess system | **L-shaped** — `GOL001` undercounter + `GOL002` intermediate | p.66 |
| Grip recess finish | **Aluminium Black** | p.66 |
| Carcass | **Grigio Fumo** | p.65 |
| Drawer structures | **Legrabox Cenere** | p.65 |
| Grip edging on door | **None** — possible only because the recess is L-shaped | p.66 |
| Wall unit edging | **Black** | p.66 |
| Plinth | **Aluminium Black, H.10** | p.66 |
| Jumbo drawers open by | **`GOL002`, the intermediate profile** | p.66 |
| Glass doors `TF0641` ×3 | **Black frame, black silk-screen printing, transparent glass** | p.65 |
| Worktop | **`TOPDR008040`** ceramic 40 mm, group **D — Dekton**, **Marmorio**, band 650, **no edge profile** | Vol.3 p.110, p.39 |
| Appliances | **All the client's, sink and mixer tap included.** Cesar supplies the dishwasher FRONT and no machine | p.66 |

**One black metal runs through the kitchen** — recess, wall-unit edging, plinth,
glass frames — and the second front colour is the same black in structured
lacquer. Two materials, one line.

## Four things that could still move the band, and none of them is settled

**1. THE MIXED-ARRANGEMENT FOOTNOTE, and it is the live one.** Printed p.13:

> *If an arrangement has First wood veneered fronts, with or without an Inside
> grip edging, the whole arrangement must be considered as if it belongs to the
> Prime wood veneer price band.*

Prime in Maxima is **7**. This kitchen has First veneer fronts AND a second
finish, which is exactly the shape the sentence describes.

**Against it stands Elda's own answer**, recorded in
`docs/Cesar_Estimate_Teardown_v0.1.md`: *"band 6 covers glossy lacquer AND
first-category wood veneer, so the choice between them is finish-only and price
-neutral."* Her sentence is about choosing **between** them, and the estimate
she was describing is single-finish (`FRONT FINISH  Lacc. Lucido Magnolia`).
Neither she nor that estimate speaks to a kitchen that has both.

**So this is not a contradiction — it is an unasked question**, and it is now
sharp enough to send: page, wording, and our exact configuration.

**2. Continuous grain match.** Printed p.58, on the First-category block:
*"continuous grain match available on request with switch to Prime category."*
A long oak run is exactly where somebody asks for it, and asking for it is a
second route to band 7. Not requested; recorded so it is a decision rather than
a surprise.

**3. Inside grip edging.** First veneer's inside-grip row is **7\***, not 6.
Choosing `GOL002` for the jumbo drawers is what keeps the kitchen at 6 — that
answer was load-bearing and did not look it.

**4. Step edging does not exist for First veneer.** The row is absent from
p.13. It would have split the two fronts onto different treatments. Not chosen.

## What the model cannot yet hold, and it matters for exactly this

**The contract has 31 keys and not one of them is about a finish.** Read off the
model, 2026-08-29: `collection` and `pricing_group_ref` are both present as keys
and **empty on all 58 objects**, and there is nowhere at all to write "this door
is RR09 and that one is LX19".

That is not an abstract gap. Every finish block of the order form carries the
same sentence: *"if the kitchen has various finishes they must be specified for
each single element in the list **or on the drawing**"*. **Our deliverable is
the drawing.** Two front colours is the first decision that the drawing is
obliged to show and currently cannot.

The cheapest honest version is two distinct front materials in SketchUp, so the
split reads on an elevation. Today every front carries one placeholder,
`UCON_Front_White` — the engine paints nine `UCON_*` materials and all of them
say what KIND of body it is, never what it will be finished in.

**AND THE SPLIT ITSELF IS NOT DECIDED.** Which units are oak and which are black
was not part of these thirteen answers. It is the next question and it is a
drawing question.

## A correction to something said earlier today

The morning's reading of the model — *"zero GOL lines on the order, a gola
kitchen with no profile ordered"* — **was wrong**, and the answer was already in
the repository. `docs/Cesar_Estimate_Teardown_v0.1.md`, Q6 CLOSED:

> *The gola profile is **not** ordered by any unit — not by an appliance panel,
> not by a base unit. It is its own row, priced per linear metre.*

`GOL001 L 3000 / 1800 / 1198 / 1198` on the factory's own estimate.

So the profile was never meant to hang off a unit. **The engine has the wrong
shape**: `Panel.attributes_patch` writes `GOL001` as a per-unit companion with
`qty: nil`, and this morning that shape was widened to fillers as well. What the
order needs is linear metres at composition level, from a run the engine can
measure. **Owed, and it should be settled before any order leaves.**

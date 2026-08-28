# Shelves p.223-224 and their fixings — the rules for spacing (2026-08-27)

## 0. A CORRECTION TO THE SEARCH NOTE, MADE THE SAME HOUR

`claude/findings-2026-08-27-shelves-38-44-search.md` §2 says the Shelves chapter
prints **2,2 and 6,0 and nothing else**, and concludes the 40 mm board must be a
breakfast bar. **That is wrong, and the render says so.**

printed p.223 carries **two blocks, not one**: *2.2 cm thick shelves* at the top
and **_4 cm thick shelves_** below it. `MNS040038`, `MNS040060`, `MNS040000`.
The 40 mm shelf Andriy asked for is a SHELF, in the shelves chapter, with its own
codes.

The search was done on the text layer and the page-level scan DID report a `4`
on printed 223 — it is in the note's own distribution table. I read the first
line of the page, called the page "2,2", and did not open it. **Learned rule 10,
and it is the second time this week: an absence in extracted text is not an
absence on the page. Look at the render.** The earlier note is kept, dated and
corrected here rather than edited (learned rule 9); the breakfast-bar reading in
it is still true and is now an ALTERNATIVE rather than the answer.

## 1. What the two pages actually sell

**Code grammar, decoded and now certain:** `MNS` + **thickness × 10**, three
digits + **depth in cm**, three digits. `000` in the depth field means the row is
sold **per m²** at D.120 instead of per linear metre.

| printed | thickness | code | sold | D. | max. L. |
|---|---:|---|---|---:|---:|
| 223 | 2,2 | `MNS022038` | per lm | 38 | 300 |
| 223 | 2,2 | `MNS022060` | per lm | 60 | 300 |
| 223 | 2,2 | `MNS022000` | per m² | 120 | 300 |
| **223** | **4,0** | **`MNS040038`** | per lm | 38 | 300 |
| **223** | **4,0** | **`MNS040060`** | per lm | 60 | 300 |
| **223** | **4,0** | **`MNS040000`** | per m² | 120 | 300 |
| 224 | 6,0 | `MNS060038` | per lm | 38 | 300 |
| 224 | 6,0 | `MNS060060` | per lm | 60 | 300 |
| 224 | 6,0 | `MNS060000` | per m² | 120 | 300 |

**Three maximum lengths are printed and they disagree.** The chapter heading says
*(Melamine, Unicolor and Fenix max. L. 418)*; the 2,2 block adds *L. max 278*;
every table row says **300**. Recorded as three facts, not reconciled. Elda.

**The finish lists are complementary, which is easy to misread.** Band 1 for the
2,2 is everything EXCEPT Bianco, Cenere and Grigio Fumo; band 1 for the 4,0 is
**only** Bianco, Cenere and Grigio Fumo.

**Surcharges, printed once for the chapter:** out-of-square reduction **83**,
internal or external cutout **56**, shaping of hood chimney **137**, angled or
rounded front edge **83** (feasibility check and a quotation for Fenix, Unicolor
and stainless steel).

## 2. The fixings — printed p.228, and NOT DRAWN

**Andriy, 2026-08-27: the fixings are not drawn in the model; they go to the
warehouse.** So they are ORDER LINES and never geometry — the same split the
plinth-with-a-cutout and the gola profile already live on. *Being drawn is a
separate question from being ordered.*

| fixing | code | pts | thickness it takes | depth window | fixes to |
|---|---|---:|---|---|---|
| Concealed shelf support for walls | `990316` | 16 | **4 / 6 cm** | min 18, max 35 cm | a wall |
| " | `990315` | 16 | 2,2 cm | min 18, max 35 cm | a wall |
| " into plasterboard | `990317` | 16 | 4 / 6 | (same) | 4/6 thick plaster |
| Concealed support for back panel | `990307` | 23 | **2,2 only** | max 35 cm | a back panel |
| L-shaped bracket for breakfast bar | `990331` | 61 | — | **max 38 cm** | a **4-6 cm partition** |

**Two things fall straight out of that table and both matter:**

1. **There is no back-panel support for a 4 cm shelf.** `990307` is 2,2 only.
2. **`MNS040038` is 380 deep and the wall supports are recommended to 350.** The
   catalog sells a shelf 30 mm deeper than the fixing it recommends for it. Only
   the L-bracket reaches 380 — and that one needs a vertical partition to bolt
   to, not a wall. **Named, not resolved.**

## 3. THE THREE RULES

### Rule 1 — the COUNT is the catalog's, and only the count

All three fixing families print the same sentence: *"2 … needed every 100 cm."*
That is a density, 2 per metre, and it is the only placement fact on the page.

    n = max(2, ceil(L / 500))

**It rounds UP and never down**, for the same reason a filler width does: up is
the direction a fitter can correct. One support too many is a stiff shelf; one
too few is a sag that costs a redrill through a finished board.

### Rule 2 — the POSITIONS are OURS: equal load

The catalog prints no position at all. **UCON decision:** every support carries
the same length of shelf.

    pitch p = L / n          outermost supports at p/2 from each end

Two consequences worth stating because they are what makes the rule safe: the
pitch **can never exceed 500**, and the end overhang **can never exceed 250** —
so the catalog's density is satisfied automatically, by construction, rather than
checked afterwards.

*Scope, learned rule 4: this is a UCON convention for drawing and ordering. It is
not structural engineering and it is not the catalog's. It is the rule we apply
when nobody has said otherwise.*

### Rule 3 — the FIXING is chosen by two facts, and each has its own window

Thickness **and** what it fixes to, together, pick the code — §2's table is the
whole lookup. And a shelf outside a fixing's depth window has **no fixing in the
book**: refuse and say so, do not substitute a neighbour. Specifically:

- a **4 cm** shelf on a **wall** → `990316`, and only within 180…350 deep;
- a **4 cm** shelf on a **back panel** → **nothing is printed**;
- a shelf **380 deep** → only `990331`, and only onto a 4-6 cm partition;
- **2,2** has the widest choice: `990315` on a wall, `990307` on a back panel.

## 4. The table

L is the ordered shelf length in mm. Points are the fixings only.

| L, mm | supports | pitch, mm | from each end, mm | concealed, pts | L-brackets, pts |
|---:|---:|---:|---:|---:|---:|
| 600 | 2 | 300.0 | 150.0 | 32 | 122 |
| 800 | 2 | 400.0 | 200.0 | 32 | 122 |
| 1000 | 2 | 500.0 | 250.0 | 32 | 122 |
| 1200 | 3 | 400.0 | 200.0 | 48 | 183 |
| 1400 | 3 | 466.7 | 233.3 | 48 | 183 |
| 1500 | 3 | 500.0 | 250.0 | 48 | 183 |
| 1600 | 4 | 400.0 | 200.0 | 64 | 244 |
| 1800 | 4 | 450.0 | 225.0 | 64 | 244 |
| 2000 | 4 | 500.0 | 250.0 | 64 | 244 |
| 2400 | 5 | 480.0 | 240.0 | 80 | 305 |
| 2780 | 6 | 463.3 | 231.7 | 96 | 366 |
| 3000 | 6 | 500.0 | 250.0 | 96 | 366 |

**Read the two point columns as alternatives, not a sum.** A shelf is fixed one
way or the other.

## 5. Next

Extraction of printed p.223-224 and the p.228 accessories, on Andriy's word. The
fixings enter as ORDER LINES only — no geometry, per §2.

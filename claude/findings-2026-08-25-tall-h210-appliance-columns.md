# Findings — the appliance columns of Tall H.210 / base H.78, printed p.121-125

**Date:** 2026-08-25 · **Session:** Cowork, office Mac, device bridge · **HEAD at read:** `e01f2ef`
**Source:** `sources/factory/CESAR - 2 Kitchen System.pdf`, printed p.121-125 = **PDF 123-127**
(offset +2, confirmed by the printed folio on each sheet).

Read demand-driven: the Avenida Primavera east wall needs these columns and nothing
else on the sheet. **Every position was read on a 600-dpi render, not only through
`pdftotext`** (rule 10) — and this is the page where that mattered, because the whole
section turns on a symbol `pdftotext` cannot see.

**Nothing is extracted into `registry/` by this note.** It is a measurement. What it
found needs one decision first, and that decision is in §6.

---

## 1. The invariant that makes the section readable

Every position on these five sheets satisfies, **in both executions**:

> **Σ printed fronts + Σ 30 mm recesses + Σ appliance openings = 2100**

That is not printed anywhere. It is measured, and it holds on 16 of 16 codes with no
exception and no rounding. Its value is that **it recovers the numbers the catalog
does not print**, and it recovers them without a hypothesis.

**The oven niche for "oven H. 60" is 600 mm.** Not printed — derived, five independent
times, from five different front stacks that all leave exactly the same hole:

| position | handle fronts | Σ | 2100 − Σ |
|---|---|---|---|
| p.121 pos 2 · `C62650` | 72 + 19,5 + 58,5 | 1500 | **600** |
| p.121 pos 3 · `C68654` | 72 + 19,5 + 55,5 + one 30 recess | 1500 | **600** |
| p.122 pos 1 · `C62653` | 72 + 19,5 + 19,5 + 39 | 1500 | **600** |
| p.122 pos 2 · `C62657` | 72 + 39 + 39 | 1500 | **600** |
| p.122 pos 3 · `C62651` | 72 + 78 | 1500 | **600** |
| p.123 pos 3 · `C62691` (H.132) | 72 | 720 | **600** of 1320 |

Six stacks, three different front counts, two different totals, one answer. **This is a
measurement, not a reading** — and per rule 9 it is written down as such, so that when
Elda contradicts it, it is the derivation that is on trial and not somebody's memory.

**Consequence for the seam.** `NICHE_DEFAULT_DEPTH_MM` and the housing datum are open
questions (`claude/findings-2026-08-25-appliance-seam.md`, findings 1-4); the HEIGHT of
an H.60 oven niche in a Cesar H.210 column is now not one of them.

---

## 2. The gola rule needs one correction: the recess is taken from the GROUP, not the front

`tall_h210_base78.json` already records *"the lower front gives its 30 mm to the recess"*.
p.122 pos 1 shows that sentence is too narrow.

`C62653`, handle: **19,5 / 19,5 / 39**. Gola: **⌐ 18 / 18 · ⌐ 36**.

On the 900-dpi crop the recess hooks are unambiguous: **one above the first 18, none
between the two 18s, one above the 36.** Two recesses, three fronts. The pair of drawers
gives **30 mm between them** — 1,5 cm each — and the jumbo gives its own 30.

> **A recess is subtracted from the front group beneath it. When the group is two fronts,
> they split the 30 equally.**

Every other position on these sheets is a group of one and therefore agrees with the old
sentence, which is why it survived this long. Check: 720 + 30 + 180 + 180 + 30 + 360 = 1500.

---

## 3. `C68654` / `C68754` — an article, not an execution

p.121 position 3 prints **ONE elevation, not a handle/gola pair**: `72 / [600] / 19,5 / ⌐ 55,5`.

The 19,5 keeps its full handle height and has **no recess above it**; the 55,5 below is
recessed. One recess in the whole column. 720 + 195 + 30 + 555 = 1500.

Its prices are **identical to `C62650`/`C62750` in all eleven bands**, and its printed
description differs from position 2 only in the capitalisation of *"no Push-pull device"*.

So this is neither the handle version nor the gola version of position 2 — it is a third
article with a mixed stack, and the registry has no shape for that today. `front_layout`
carries `heights_mm_top_to_bottom` for the handle execution and `gola_stack_top_to_bottom`
for the other; **`C68654` is a stack that is neither, and declaring it as either would
draw a front that is 30 mm wrong.**

**Not a guess to be made here.** Two readings are possible — a third execution (the side
tab says *Maxima – Intarsio – Tangram* while the header block says only *Maxima /
Intarsio*), or an article whose stack simply is what it is. **Elda question.**

---

## 4. Two things printed here that belong somewhere else

**`C62691` is not an H.210 unit.** p.123 position 3 is *"Wall-hung tall unit with fixings
H. 132 for oven H. 60"* — 1320 tall, no feet, fixed front, one 72 door over a 600 niche.
It is printed inside the section *Tall units H. 210 | for base unit H. 78* and it is a
different family. The section heading is not the family: the same trap
`tall_h210_base78.json` already records for printed p.116's two identically-titled
positions, now on the height axis. There is `tall_h138.json`; **132 is not 138**, and no
H.132 section file exists.

**The fridge unit carries the hung glyph and no hung surcharge.** p.125's single position
(`C64601` W60 / `C64701` W75) has the cabinet-in-a-bracket pictogram beside `d. 62` —
verified at 600 dpi against `C62691`'s, which is the same glyph pixel for pixel — while
its margin prints only *side panel D. p.549* and *feet H. 5 mm p.548*. **No
*Surch. for wall-hung version on page 548*.**

This is the **second** instance of the contradiction `claude/findings-2026-08-24-pictogram-sweep.md`
§4 recorded for the Magicorner corner on printed p.42, and it is **mirrored**: there the
margin line stood without the glyph, here the glyph stands without the margin line.
Everywhere else the two signals agree. **Two instances is a pattern worth asking about.**
Neither is held, so nothing depends on it yet. **Elda question, alongside the corner one.**

---

## 5. THE BLOCKER — a front whose height is the remainder

Three of the sixteen codes print **`1 rh or lh custom-sized door`**, and on the 600-dpi
render that front is drawn as a bar **with no dimension beside it**, in both executions.

| code | printed fronts (handle) | printed fronts (gola) | what is left | holds |
|---|---|---|---|---|
| `C62610` p.121 pos 1 | 19,5 + 78 | ⌐16,5 + ⌐75 | **1125** | custom door **+ oven H.46 niche** |
| `C63640` p.123 pos 1 | 39 | ⌐36 | **1710** | custom door **+ oven + microwave** |
| `C63659` p.123 pos 2 | 58,5 | ⌐55,5 | **1515** | custom door **+ oven + microwave** |

**The remainder is execution-independent.** 195 + 780 = 975 and 30 + 165 + 30 + 750 = 975;
390 and 30 + 360 = 390; 585 and 30 + 555 = 585. Handle and gola leave the *same* hole, to
the millimetre, in all three. That is the property that makes the remainder a real number
rather than an artefact.

**And that is exactly why the door is custom.** In the H.60 positions there is no custom
door and the niche is a constant 600. Here the door exists *because the niche is not a
constant* — the appliance decides the split, and the catalog can only state the sum.

> **The catalog prints a REMAINDER, and the appliance decides how it divides.**

Object Contract v2.1 cannot express that. §4.1 derives `front_height_mm` from the family
and `opening_method`; `front_layout.heights_mm_top_to_bottom` is a list of constants.
Neither can hold *"this front is 1125 minus whatever the oven takes"*.

**This is the same gap as printed p.414, on the other axis.** `_manifest.json` records
p.414 as deferred because *"p.414's four types are all custom-sized and the contract
cannot yet express a front whose WIDTH comes from the opening"*. Here it is the HEIGHT.
**Two named gaps, one shape.**

**And it is the same shape as В6.** `claude/findings-2026-08-25-first-run.md` §5: a range
stands in a GAP IN THE RUN and `place_set` reserves nothing for it, so 1219 mm of run is
marked by nothing at all. Here 1125 mm of COLUMN would be marked by nothing at all. Both
are a **reserved emptiness** — a span the drawing must own without owning a body. В6 is
that concept in plan; this is that concept in elevation. **They should be decided once,
not twice.**

---

## 6. What is owed before anything is extracted

**13 of the 16 codes are expressible under v2.1 today** — every H.60 oven column
(`C62650` `C62750` `C62653` `C62753` `C62657` `C62757` `C62651` `C62751`, and
`C68654` `C68754` if §3 resolves), the fridge unit (`C64601` `C64701`), and `C62691` once
it has a home. **3 are not**: `C62610`, `C63640`, `C63659`.

**The one the wall actually needs is among the three.** Printed p.123 is the oven-and-
microwave column on the designer's render.

The decision is Andriy's and is not made here:

1. **Extract the 13 now, record the 3 in `catalog_map` as blocked** — the wall gets its
   fridge unit and its oven columns, and the column on the render still cannot be drawn.
2. **Close the remainder concept first (with В6), then take the section whole** — one
   contract revision, three gaps shut, nothing extracted twice.

**Do not extract the 3 by assuming a niche height.** A 460 mm niche would make `C62610`'s
door exactly 665 and the arithmetic would close — and it would be an invention, in the one
place where the catalog has gone out of its way to say the number is not fixed.

---

## 7. ANSWERED THE SAME EVENING — added, not edited (rule 9)

**Andriy chose option 2: close the concept first, then take the section.** Both were done
in the same session.

`docs/Reserved_Void_Spec_v0.1.md` names the shape and `Object Contract v2.1` gained
`object_class: void` and the key `void_role`. **The remainder is an entry in the front
stack**, beside `front` and `zone`, and a fourth kind — `appliance_opening` — was added
with it, because §1's measured 600 is a span that is neither a front nor a recess nor a
remainder: **its division is decided, and the appliance is what decides it.**

**So 13 of the 16 codes are held, not 13 of 13.** All three custom-door articles came in
with the others — `C62610`, `C63640` and `C63659` — because a remainder is now something
the registry can say. The two that stayed out stayed out for reasons that have nothing to
do with the contract: `C68654`/`C68754` (§3, Elda) and `C62691` (§4, wrong family).

**One thing this note got wrong and the code corrected.** §6 above said the fronts inside
a remainder could not be counted. They can: printed p.121 says *"1 rh or lh custom-sized
door"* **in words**, so HOW MANY is printed and only HOW TALL is not. `C62610` exports
three fronts and three handles. The remainder entry carries `fronts_within` and
`Export.fronts_in` adds it. **A number that is printed must not be thrown away to protect
one that is not.**

**Still true, still not invented:** no oven H.46 niche height, anywhere.

**NOT YET TRIED IN SKETCHUP.** Everything above is 440 headless checks. The void band, its
red, and the missing drawer diagonal need the model — like everything that draws.

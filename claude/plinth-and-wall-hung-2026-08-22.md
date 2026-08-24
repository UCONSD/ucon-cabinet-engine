# Plinth height and the wall-hung base unit — what the factory documents say

Read 2026-08-22 from `sources/factory/CESAR - 1 Project Guidelines.pdf` (PG),
`sources/factory/CESAR - 2 Kitchen System.pdf` (KS, the price list) and
`CESAR - 3 Linear Elements.pdf` (LIN). Page numbers are PRINTED, as always.
Nothing was built from this yet — the instruction was *"сначала смотрим, потом
делаем, и думаем"*.

Three renders were taken because the decisive numbers sit in two-column
drawings whose text layer interleaves the columns (rule 10, and it earned its
keep again — see §1.2):
`sources/factory/pg-p73-h78-plinth.png`, `pg-p90-h84-plinth.png`,
`pg-p39-wallhung.png`.

---

## 1. Plinth height

### 1.1 The pairing is real, and it is a property of the HEIGHT FAMILY

Every "Sizes of base units" drawing prints the same two-line dimension chain:
the door height, then `Plinth H.` Across all four base families:

| family | drawing says | plinth | worktop underside | PG printed page |
|---|---|---|---|---|
| Maxima/Intarsio **H.78**, handles | `78 H. Cesar door` + `10 Plinth H.` | **100** | 880 | p.73 |
| Maxima/Intarsio **H.78**, grip recess | `75 H. Cesar door` + `10 Plinth H.` | **100** | 880 | p.82 |
| Maxima/Intarsio **H.84** | `84 H. Cesar door` + `6 Plinth H.` | **60** | 900 | p.90 |
| **N_Elle H.78** / framed H.78 | `10 Plinth H.` | **100** | 880 | p.175 / p.193 |
| **N_Elle H.84** / framed H.84 | `6 Plinth H.` | **60** | 900 | p.186 / p.197 |

So it tracks the **height family**, not the collection — N_Elle H.84 gets 60
just as Maxima H.84 does. Andriy's statement is confirmed exactly.

> **2026-08-24 — the low families join the table, read from the same source.**
> PG printed p.68, "Modularity of base units H. 78", draws H.39, H.48 and
> H.58.5 each as a worktop line at 78, the unit height, then **0 / 10** at the
> floor. All three stand on **100**. Render-verified at 200 dpi. The same
> diagram shows why they exist: 78 − 39 = 39, 78 − 48 = 30, 78 − 58,5 = 19,5 —
> they are the lower half of a column, not short base units.

### 1.2 A trap the render caught

`pdftotext` renders PG p.90 as `9 / 6  Plinth H.`, which reads as two plinth
options. **It is not.** The render shows the `9` is a separate dimension on the
DISHWASHER drawing only — the gap from the bottom of the appliance door to the
floor — sitting directly above the `6` that labels the plinth. The facing
drawing, DISHWASHER WITH TALL DOOR, prints `6` alone. **One plinth height per
family.** Rule 10: an absence — or a presence — in extracted text is not one on
the page.

### 1.3 The catalog sells exactly two heights, and the HEIGHT IS IN THE CODE

KS printed p.625, *"Front plinth – (including accessories) – per lm."*:

| item | H.6 | H.10 |
|---|---|---|
| Front plinth | `ZOCC001` | `ZOCC011` |
| Side plinth, base D.35 | `ZOCC002` | `ZOCC012` |
| Side plinth, base D.62 | `ZOCC005` | `ZOCC015` |
| Side plinth, base D.67 | `ZOCC006` | `ZOCC016` |
| 90° end element | `ZOCA001` | `ZOCA011` |

KS p.624 adds the material axis: **"Plinths in aluminium h. 6, h. 10"** and
**"PVC plinth h. 10"** (Matt aluminium / White only) — so PVC exists at 100
alone. The A–E columns on p.625 are price bands, not dimensions.

**Nothing on either page ties a height to a base family.** The two heights are
simply two articles. So "it must be possible to change it" is not a special
request at all — it is ordering the other code. **`PLINTH_H_ALT_MM = 60`, whose
comment in `10_standards.rb` reads *"alternate plinth height, special request
only"*, is mislabelled: 60 is the H.84 DEFAULT.** (Rule 9 — correct by adding a
dated note, do not erase the old line.)

Two more facts worth keeping:

- **"(including accessories)"** — the plinth's own accessories are inside its
  price. That shrinks the "десяток сопроводительных позиций" worry for the
  plinth. It says nothing about the gola profile, which is a separate family.
- PG p.38, the **Blink** magnetic fastener, gives a countable rule in plain
  words: *"2 Blink fasteners are required for plinth lengths up to 2 metres; 1
  Blink fastener will be added for each additional metre… This rule will also
  apply to side plinths."* That is a real linear-goods accessory formula, and
  it is the first one the catalog states outright — even if, being included,
  it never needs to reach an order.

### 1.4 But it is a COMPOSITION axis, not a per-unit one — and that mostly answers Elda L2

The estimate header carries **`FOOT TYPE  H.100 Mm`** and **`PLINTH FINISH
Matt Aluminium`**, and `ZOCC011 FRONT PLINTH H.10` appears in the estimate's
**component layer**, alongside `FRN` / `RPN` / `DVN` — the parts Metron
generates from our article rather than parts we order. The chain is therefore:

> `FOOT TYPE` (composition header) → plinth height → the `ZOCC` article Metron
> emits.

That is the same shape as the gola SYSTEM and the Lume restriction: **a
composition-level fact wearing a per-unit coat.** It belongs to **M1.6**, not
to the unit properties panel.

It also largely answers **Elda L2** from our own data — the plinth looks like
Metron's to generate, not ours to specify. **Keep the question anyway.** The
component layer is strong evidence, not a statement, and the plinth is
simultaneously a real priced article with its own code. Her one sentence
settles what our inference only suggests.

*(Per Andriy's own discovery rule: this is a **re-confirmation of the existing
composition-axis pattern**, not a new concept. No new primitive is created for
it.)*

---

## 2. The wall-hung base unit

### 2.1 It is a catalogued option with a code

KS printed p.548, under *Modifications*:

> **Wall–hung base and tall units** — with fixings, 240 Kg capacity per pair
>
> | | Code | Points |
> |---|---|---|
> | base units with 2 fixings | **`989410`** | 42 |
> | tall units with 4 fixings | **`989411`** | 84 |

And **almost every base and tall price table in the book** prints
*"Surch. for wall-hung version on page 548"* in its margin — Maxima, Intarsio,
N_Elle, Unit, the glass display cabinets, all of them. This is a standing
option, not an exception.

> **CORRECTION 2026-08-23 — "almost every" is doing real work in that sentence.**
> The margin line's ABSENCE is a statement, and printed p.19 names the matching
> pictogram: "Hung version". Twenty codes are now refused on that evidence —
> two base units on printed p.37 that also say so in words, and eighteen tall
> ones that say it only by leaving the glyph off, including the whole of H.222
> and H.234. See `claude/findings-2026-08-23-tall.md`.

### 2.2 A wall-hung base unit is NOT "without feet" — it has one

PG printed p.39, verbatim:

> **Wall-hung base unit fixings.** Wall-hung base units are always provided
> with fixings and a foot to stabilise them and determine their inclination.
> Fixings have a maximum capacity of 240 kg.

The rendered drawing (`pg-p39-wallhung.png`) shows what that means: the fixing
bracket at the **top rear**, and at the **bottom rear** a stabilising foot
bearing **against the wall** — the grey hatch in the drawing is the wall, not
the floor. Its job is to set the tilt. Captioned *"Bottom stabilising foot also
used to adjust the inclination"*.

So the accurate wording is **no floor contact and no plinth, but a foot is
still there.** Our vocabulary must not say "without feet"; it invites someone
to model a cabinet with nothing at the bottom rear and to forget the wall
clearance that foot occupies.

### 2.3 Not every unit may hang, and the catalog says which

Three occurrences of *"not available wall hung"* in 634 pages, all base units:

| printed page | type |
|---|---|
| p.34 | appliance base with 1 oven niche — *bottom panel lined with sheet metal* |
| p.37 | two grip-recess types — *no Push-pull device on top front, no intermediate grip recess* |

This is a fourth tenant for **`restrictions`**, the contract key that still has
nowhere to be written — and the first one that a UI could actually enforce
rather than merely warn about: do not offer the wall-hung option on these
types.

> **2026-08-23: the p.37 pair is extracted and carries `wall_hung: false`.** And
> the guard that reads it could not be reached from any data until that day —
> `Registry.lookup` never carried the key out of the section file. Fixed in
> `50_registry.rb`. A guard is not a rule until some data can reach it.

### 2.4 What the engine has, and what it lacks

`Contract` already carries `mounting` (`floor` | `wall_hung`) and
`mount_bottom_mm`, and `Generator.base_z_mm` already branches on them. **What
is missing is that `mounting` is read from the FAMILY** —
`family['mounting'] || 'floor'` in `Registry.lookup` — so a base unit can never
be made to hang. It is not a choice anywhere in the tree.
*(Built 2026-08-22, commits `f5f671a` and `f2bf2db`.)*

---

## 3. THE 5 mm FOOT — SETTLED, and both first guesses were wrong

Added 2026-08-22, after §3.3 below had already listed this as a question for
Elda. **It is no longer a question**, and the paragraph is kept rather than
rewritten (rule 9).

KS p.548 prices *"Floor-standing base and tall units with adjustable feet
**H. 5 mm**"* (`989053`, 22 points). Three readings were on the table:

1. **50 mm, a cm/mm slip** — mine, on the grounds that the same book writes
   H.6 and H.10 everywhere else. **Wrong.**
2. **±5 mm of adjustment travel** — Andriy's, and the more natural engineering
   reading of a number that small. **Wrong.**
3. **A foot 5 mm tall.** **Correct.**

The evidence is the same article written out in centimetres in another book.
**LIN printed p.214**, in the floor-standing panel section:

> *Notes:* "If it is used as a floor-standing panel behind a base unit or as a
> floor-standing end side panel, **0.5-cm high feet** will be mounted that must
> be calculated separately."
>
> **Adjustable foot H. 0.5 cm — each — `990408` — 6 points**

*"0.5-cm **high** feet"* is explicit, and `H. 0.5 cm` = `H. 5 mm`. Same object,
different book, different article code because it is sold for a different
element.

**And the book has two distinct grammars, which is what makes this safe:**

| construction | means | examples |
|---|---|---|
| **`H. <n>`** | the foot's **height** | `H. 5 mm` (KS p.548), `H. 0.5 cm` (LIN p.214), `H. 2.7 cm foot` (HOME p.98) |
| **`adjustable in height by / up to <n>`** | the **travel** | *"Foot adjustable in height by 1.5 cm"* (PG p.136, BATH p.70), *"foot adjustable in height up to 1 cm"* (HOME p.160) |

p.548 uses the first construction. Had Cesar meant travel it had a phrase for
that and used it three times elsewhere. **The word "adjustable" is doing
different work in the two constructions, and that is exactly what made the
guess tempting.**

*(Fourth pass, 2026-08-22 evening, Andriy: the range is 0…5 and the 5 is travel
for floor unevenness. The drawing shows zero — no gap. `plinth_h_mm = 0`, and
the number 5 is stored nowhere. See `claude/repo-state.md`.)*

**A consequence worth carrying forward:** a base unit on 5 mm feet stands
essentially on the floor and has no room for a plinth. That is a **third base
datum**, alongside floor-on-plinth (`z0 = plinth height`) and wall-hung
(`z0 = mount_bottom_mm`). `base_z_mm` currently knows two.

**Method note.** This was settled by searching all five factory books at once
rather than one. The answer was never on the page that asked the question —
it was 380 pages away in a different volume, under a different code, because
the same physical part is sold twice for two different elements. *Cross-book
search before asking the factory.*

---

## 4. What this suggests, in order — nothing built yet

**4.1 Plinth height stops being a global constant.**
`Standards::PLINTH_H_MM = 100` is used in five places in `60_generator.rb`. It
is really a **family fact with a project override**: the registry family states
it, M1.6 may override it for the whole composition, and `Standards` keeps 100
only as the fallback for a family that does not say. Small, self-contained, and
it kills a rule-6 constant (chosen when there was one case) before the H.84
chapter arrives and makes it wrong. The `PLINTH_H_ALT_MM` comment gets its
dated correction at the same time. *(Built 2026-08-22, commit `6a9ff1b`.)*

**4.2 Wall-hung becomes a per-object choice — and it is the first CHOSEN
companion the generator could actually emit.**
Today `origin: chosen` exists in Contract v2 and *nothing in the tree produces
one* (a check over all 180 codes proves it). A wall-hung base unit is exactly
that: a decision nobody can infer from the code, carrying article `989410` as a
companion line with `origin: chosen`, and switching the geometry from
plinth-standing to hanging — which `base_z_mm` already knows how to do. It also
gives `restrictions` its first enforceable tenant. *(Built 2026-08-22.)*

**4.3 Two things to ask Elda, if they are cheap enough to add.**
- ~~The feet article on p.548 reads *"Floor-standing base and tall units with
  adjustable feet H. 5 mm"* (`989053`, 22 points; already in our manifest).
  Whether **H. 5 mm** means 50 mm — a cm/mm slip, consistent with the H.6 /
  H.10 the same book uses everywhere else — or a genuine 5 mm foot, the page
  does not say, and no plinth article exists at H.5 to corroborate either
  reading. **Rule 8: not written down.**~~ **WITHDRAWN — settled from the
  source, see §3.**
- A wall-hung base unit takes no plinth. Does the run's plinth then simply stop
  at it, the way it stops at a dishwasher, or is a side plinth expected at the
  break? This is the plinth-continuity question we already answer per-article
  with `plinth_continues`, asked for a case the registry has never met.
  **Still open.**

# USA elements — reconnaissance (printed p.409-432)

Read 2026-08-20. Pages **414** and **418** read in full; the other 22 read at
the level of headings, codes and width columns. Nothing extracted. Landed in
the repo: 16 section rows in `catalog_map`, a `code_grammar.usa_elements`
block, and `nominal_widths_in`.

The chapter exists because **American appliances do**. It is not a metric
catalog converted for export — it is a set of extra articles sized to fit a
30″ range, a 36″ fridge, a 24″ dishwasher.

---

## 1. The finding that settles the units question

**printed p.418 prints inches. In their own column. First.**

```
      W.     Code
18"  45.7   CR9400
24"   61    CR9600
30"  76.2   CR9700
36"  91.4   CR9900
```

This is the only place in 634 pages where the book states an inch size, and it
states it as **data beside the centimetres**, not as a note. So the nominal
inch size of a US width is a catalog fact, not a conversion we perform.

`42″` and `48″` come from the width column on printed p.414 (106.7 and 121.9).

**Six nominal widths, and the rule that comes with them:**

| mm | inches | why it must be looked up |
|---|---|---|
| 457 | 18″ | 18″ = 457,2 |
| 610 | 24″ | 24″ = 609,6 — the catalog rounded UP to the centimetre |
| 762 | 30″ | exact |
| 914 | 36″ | 36″ = 914,4 — rounded DOWN |
| 1067 | 42″ | 42″ = 1066,8 |
| 1219 | 48″ | 48″ = 1219,2 |

Dividing 610 by 25,4 gives **24 1/16″**, which is not a size anybody ordered.
Same rule as the width index and the family letter: **a lookup, never
arithmetic.** `Registry.nominal_in` reads the table; a test fails if `25.4`
ever appears in it.

**No metric width in this catalog collides with any of the six** (metric runs
150 / 300 / 450 / 600 / 750 / 900 / 1050 / 1200 / 1500 / 1800 / 2400), so the
width alone resolves the nominal and no per-row field is needed. A test checks
that non-collision on every row and will fail the day it stops being true.

---

## 2. The width field is not decodable here — demonstrated, not suspected

The wall chapter carries a *caution* that the width field is a lookup. This
chapter carries the **proof**. W. 91,4 appears as three different fields:

| code | page | field | width |
|---|---|---|---|
| `B89657` | 414 | `96` | 91,4 |
| `B89150` | 414 | `91` | 91,4 |
| `CR9900` | 418 | `99` | 91,4 |

Two of those are **on the same page, under different types**. And on that same
page 106,7 is `21` and 121,9 is `22`, which resemble nothing.

Conclusion recorded in the manifest: **read the row.** No grammar was invented
to cover it.

## 3. New family letters, read but not extracted

| letters | where |
|---|---|
| `B8` / `B9` | USA base H.78, d.62 / d.67 — the SAME depth digits as metric H.78 |
| `BL` / `BM` | USA base H.84, d.62 / d.67 |
| `Y4` / `Y7` | USA Unit base H.66 |
| `C8` | USA tall H.198 |
| `CR` | Doors for USA fridge, tall H.210 |

`BL` and `BM` are the first two-letter family prefixes in the registry's
experience, and they break the "one letter after B" reading that has held so
far. Recorded, not extrapolated.

> **2026-08-24.** That reading is now dead for the whole base class, not just
> here: the base prefix is a **(family × depth) slot key**, not a family letter.
> printed p.24 prices H.39 as `B0` / `BJ` / `B1`, and printed p.42's corners use
> `AU` and `AW` at the same depths the plain units call `B8` and `B9`. See
> `claude/findings-2026-08-24-base-column.md`.

## 4. Character of the chapter

Most types are **custom-sized**: *"1 custom–sized fixed front"*, *"2
custom–sized doors"*, *"1 custom–sized jumbo drawer"*. Several carry **suffix
`99`** — the customisable carcass the factory estimate showed being priced with
a `WIDTH REDUCTION: Yes` variant line. So the US chapter leans on the
modification mechanism (M1.11) rather than on a fixed size grid.

**Depths stay metric.** A US-width unit at d.62 is normal and correct — Cesar
makes imperial only what meets an American appliance. This is visible in the
picker the moment inches are on: `762 · 30 in` beside `620 · ≈24 7/16 in` on
one card. Not a defect of the display; the truth about the object.

What the chapter is mostly made of: **oven housings, hob bases, fridge doors,
wine-cooler doors**. Ordinary door and drawer units are not duplicated here —
for those the metric grid still applies.

## 5. What is in the repo now

- `catalog_map`: **16 section rows**, class `base`/`tall`, all tagged
  `collection: "USA elements"`. It is a COLLECTION, not a class — the printed
  general index lists it beside *Maxima e Intarsio* — but each section keeps
  its real class so the picker files it where a person would look.
- Page detail for **p.414** (four types, every code and width) and **p.418**
  (two types, the inch column).
- `code_grammar.usa_elements` with the three counter-examples.
- `nominal_widths_in` with its source page.

Not in the repo: **a single US article**. The chapter is 100 % gap.
*(Superseded 2026-08-21: printed p.418 was extracted — 8 codes, the fridge and
wine-cooler doors, held as `usa_tall_h210.json`.)*

## 6. When to extract, and what first

Demand-driven says: when a real kitchen needs one. When that day comes the
first page is **printed p.414**, because it is the one already read in full and
because oven housing + hob base + fridge doors is what a US kitchen actually
starts from.

Two things to settle before extracting:

1. **How a custom-sized front is modelled.** Half this chapter is
   custom-sized, and the contract has no way to say "this front's width comes
   from the opening, not from the code". That is M1.11 territory and it blocks
   a faithful extraction more than the codes do.
2. **Whether `nominal_in` should also cover heights and depths.** Today the
   lookup is widths only. Nothing in the chapter suggests a nominal height —
   H.78 and H.84 are metric throughout — but the question should be asked once
   rather than discovered later.

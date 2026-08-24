# Finishes and price bands — where they live, and what would break

Andriy's question, 2026-08-22, explicitly **not urgent**: *"Мне лично это сейчас
не горит. Я боюсь, что в будущем это может нам чего-нибудь сломать либо
осложнить жизнь."* So this is a decision recorded, not work started.

He offered three ways to configure it:

1. pick a **colour**, the band is substituted;
2. pick a **band**, see what finishes are inside it;
3. pick a **band 1–11**, then the finish, with a **search box** over finishes —
   plus the ability to change the band for the **whole project** or for
   **groups** (island as one group, base units as another).

---

## 1. They are not three architectures. They are two readings of one table

**The band is not a choice and not a property of a colour. It is a LOOKUP**, and
the factory prints the whole lookup on two pages.

**CESAR - 1 Project Guidelines, printed p.12–13, "Price bands"** is a matrix:

- **rows** — the finish FAMILY (Melamine, Technomat, Fenix NTM, Fenix NTA,
  Unicolor HPL, Silk-effect lacquers, Gloss lacquers, First / Prime / Prime
  Trama / Special / High-gloss / Tabu wood veneers…), each with sub-rows for the
  **door treatment**: frame grip edging, 30° grip edging, step, inside grip
  edging, Shaker door, Groove door;
- **columns** — the **collection**: Unit, Maxima 2.2, Tangram, Intarsio, N_Elle;
- **cells** — the band, `1`…`11`; blank means *not offered in that collection*,
  and some cells say *"See Volume 2"*.

So the band is a function of **(finish family × door treatment × collection)**.
Read one way it answers "what does this finish cost me"; read the other way,
"what may I have inside band 6". **Same table. The direction is a UI decision,
not an architectural one** — which is the answer to the question as asked:
store the relation, and let the picker traverse it both ways. Committing the
data model to one direction is the only way to get this wrong.

The individual colours live on the Finishes pages (PG printed p.44–61, 127–132,
162–166) with their own codes, e.g. `LL91` / `LS91` = Magnolia in gloss and in
silk-effect.

---

## 2. Where it lives: a COMPOSITION axis, with group and object overrides

The estimate settles this. Its header carries, for the whole composition:

```
MODELLO: MAXIMA 2.2
FRONT FINISH        Lacc. Lucido Magnolia
GRIP RECESS FINISH  Matt Aluminium
CARCASS FINISH      Cenere
DRAWER FINISH       Legrabox Cenere
PLINTH FINISH       Matt Aluminium
```

That is the same shape as `FOOT TYPE`, the gola system and the Lume
restriction: **a composition-level fact wearing a per-unit coat.** It belongs to
**M1.6 project defaults**.

**And overrides below it are real, not hypothetical.** The same estimate carries
a per-row `RIGHT END ELEMENT TYPE+GRIP RECESS FINISH: Flush-Fitted E` — the
factory's own document overrides a finish on one line. So the three levels
Andriy is asking for already exist in Metron:

| level | what it is | evidence |
|---|---|---|
| **composition** | the project default | estimate header |
| **group** | Andriy's island vs the base run | *not yet seen in factory output* — but a group is needed anyway for M2.1a runs |
| **object** | one line differs | estimate per-row override, **and the order form's own instruction — see §6** |

The middle level is the one with no factory evidence behind it yet. It is a
reasonable UCON construct — but per rule 4 it must be recorded as ours, and it
should reuse whatever grouping M2.1a invents for runs rather than growing a
second notion of "group".

---

## 3. What would actually break us — four traps, all avoidable now

**3.1 Storing the band on the object.** If every object carries its band, then
changing the project finish means rewriting sixty objects, and the one that is
missed is silently wrong on the order. **The band is derivable from (collection,
finish, treatment), so derive it and never store it** — exactly the rule already
applied to `front_layout` (which counts handles) and `plinth_h_mm`. Contract
§1.2 already leans this way: `pricing_group_ref` is *"reference only, never a
price"*, and it is *conditional*, not required.

**3.2 Assuming one band scale.** There is not one.

| article family | band scale | source |
|---|---|---|
| cabinets, fronts | **1 … 11** | every price table prints `W. Code 1 2 3 4 5 6 7 8 9 10 11` |
| plinths | **A … E** | printed p.625, five columns |
| grip recesses | **A … D** | printed p.616, four columns |

A single integer `price_band` field is wrong on day one. Whatever holds the band
must be a **string scoped to its article family**, and a kitchen is at band `6`
for its doors and at some *letter* for its plinth at the same time. The two are
related only through the finish, never through the number.

**3.3 Assuming the band belongs to the colour.** It does not. Magnolia is
band 5 in silk-effect and 6 in gloss — same colour, two finishes. The same
finish family is band 8 in Intarsio and 6 in N_Elle. **The key is the triple,
never the colour name.**

**3.4 Three notations for one value.** The estimate writes `Note:: 06`; the
finish pages write `F5` / `F6`; the master matrix writes a bare `6`. Normalise
at the boundary — the same job `Contract.read` does for schema versions — or
they will be compared as strings somewhere and silently fail to match.

**A fifth, smaller:** the manifest already records *"asterisked widths restrict
door finishes"* on two deferred pages. So per-unit finish restrictions exist and
are another tenant for the still-empty `restrictions` key.

> **2026-08-24: twenty of them are now held, not two.** Every compound base and
> wall position extracted since carries a `finish_restrictions` block, recorded
> with its page and read by nothing. The band work has more data waiting for it
> than this note assumed.

---

## 4. Is the band even ours to carry? Yes — and this is why

It looks like commercial data, which §1.2 forbids. It is not, and the
distinction is worth stating once so nobody re-opens it:

- **Forbidden:** the price, the points, the coefficient, the surcharge.
- **Allowed:** the band, because it is a **classification the factory itself
  prints on the order** — `Note:: 06` appears on nearly every furniture row of
  estimate 2026/30829, and Elda confirmed it means band 6.

It is factory output, not our arithmetic. `pricing_group_ref` was put in the
contract for exactly this, and its documented example is already `1-11`.

---

## 5. Recommendation

**Data.** A flat finish table — one row per finish, carrying its code, its
name, its family, its treatment, and the band **per collection**. Flat is what
makes Andriy's search box free; nesting finishes under bands is what would make
it expensive. Home: `registry/cesar/finishes/`, one file per printed section,
same discipline as the unit sections.

**Configuration.** A finish is chosen at composition level (M1.6), may be
overridden per group, may be overridden per object. The band is **shown, never
entered** — and when the user wants to work the other way, the same table
filters the finish list to a chosen band. Both directions, one table.

**On the object.** The finish, if anything. Not the band.

**What is worth doing NOW, given it is not urgent:** nothing but this note —
and one line of insurance when M1.6 is designed, so that nobody adds an integer
`price_band` field or hangs the band off a colour. Those are the two mistakes
that would be expensive to undo; everything else here is cheap whenever it is
picked up.

---

# 6. The CARCASS palette — read 2026-08-22, and it is a different shape

Added after Andriy's follow-up: *"есть разные цвета каркаса-материала… основных
цветов должны быть дополнительные."* He remembered it correctly, and reading it
changed one thing more important than the palette itself (§6.3).

## 6.1 Three standard colours and one paid escape, and it is NOT collection-scoped

Every order form in the Project Guidelines prints the same block under
`CARCASS:` — Maxima 2.2 (printed p.65), Unit (p.158), N_Elle (p.198), Intarsio
(p.49):

| | |
|---|---|
| **Cenere** | standard |
| **Grigio Fumo** | standard |
| **Rovere Bruno** | standard |
| **Silk-effect lacquers w/surcharge** | the paid escape |

**The same four in all four collections.** That is the opposite of the door
price bands, which are collection-scoped through and through — so the carcass
palette is its own small flat table, not a cell in the big matrix. The estimate
agrees: `CARCASS FINISH  Cenere`.

**The surcharge article is probably `989400` / `989401` / `989402`** on printed
p.548 — *"Cabinets with carcasses matt lacquered in all parts (top panel,
bottom panel, shelves, side panels, back panel)"*, 172 / 120 / 417 points for
base / wall / tall. **"Probably" is deliberate (rule 4):** the order form says
*silk-effect*, the price list says *matt lacquered*, and equating them is OUR
reading. In Cesar's vocabulary silk-effect is the matt lacquer as opposed to
gloss — the finish pages code them `LS…` against `LL…` — and p.548 lists no
other carcass-finish article, so the identification is very likely right. It is
still an identification, not a printed fact.

## 6.2 The same shape appears again on the drawer structures

`LEGRABOX DRAWER/DEEP DRAWER STRUCTURES:` on the same forms —
**Cenere · Bruno · Stainless steel w/surcharge**. The estimate carries
`Legrabox Cenere R`.

So the pattern repeats: **a short standard palette plus one "w/surcharge"
option.** That is exactly the shape of the wall-hung option built on
2026-08-22 — a decision nobody can infer from the article code, travelling as a
separate surcharge line. **The mechanism already exists** (`origin: chosen`
companion lines); these axes will need data, not new machinery. Per Andriy's
discovery rule: a re-confirmation of an existing pattern, not a new concept.

## 6.3 The line above the block matters more than the block

Every finish section of every order form — PLAIN DOOR, SHAKER DOOR, GROOVE
DOOR, FRAMED DOOR **and CARCASS** — carries the same sentence:

> *"if the kitchen has various finishes they must be specified for each single
> element in the list **or on the drawing**"*

Three things follow, and the third is the one that changes our plans.

**Mixed finishes in one kitchen are normal.** The factory explains up front how
to submit them. So the group level Andriy asked about is a standard scenario,
not a convenience he invented.

**The burden of saying which element gets which is OURS**, not Metron's.

**And the DRAWING is an accepted vehicle for it.** *"…or on the drawing."*

That last clause is worth more to this project than the whole band discussion.
**Our deliverable is the drawing.** If a per-element finish may travel on it,
then a finish override is not a picker convenience that ends up in an order —
it is **drawing content**, and sooner or later an elevation has to annotate it.
That does not change where the finish is stored; it changes **who has to show
it**, and it adds a consumer nobody had counted: the sheet.

## 6.4 What this adds to the recommendation

- The carcass palette is a **flat four-row table, not per collection**. Do not
  model it as part of the door-band matrix.
- Drawer structures are a second such table with the same shape.
- **A per-object finish override must be visible on the sheet.** Decide that
  when M1.6 is designed, not after: building the override without the
  annotation would produce exactly what the factory asks us to show, and fail
  to show it.
- Still nothing to build today.

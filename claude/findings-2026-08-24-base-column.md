# The base column, first page — the prefix was never a family letter

> ## MOVED INTO THE REPOSITORY 2026-08-24
> Copied verbatim from the claude.ai Project. See `claude/README.md`.
>
> **DATED CORRECTION — one row of §1's table is no longer "not read yet".**
> Rule 9: added, not merged.
>
> This note was written after printed p.24. Since then **printed p.25 was
> extracted into `base_h39.json` (48 codes total) and printed p.28 into
> `base_h48.json` (30 codes)**, so the H.48 row of the table in §1 now reads:
>
> | family | d.35 | d.47 | d.62 |
> |---|---|---|---|
> | **H.48** | **BC** | **BQ** | **BD** |
>
> **And it confirms §1's finding rather than softening it: the three letters
> are not in alphabetical order of depth.** `BC` → `BQ` → `BD` as the box gets
> deeper. Whatever a base prefix is, it is not a sequence — it is a slot key,
> exactly as §1 says. **H.84 (`BK` / `BL` / `BM`) is still not read**, and its
> row of the table stands as written.
>
> Printed **p.26 and p.27 were opened and stopped**, and the stop is recorded in
> both the section file and `catalog_map` (see the last section of this note for
> the rule that requires both places).

Group 3, printed p.24 (Base units H. 39). 24 codes, and three findings that
reach backwards into work already done.

---

## 1. A base prefix names a (family, DEPTH) slot

Printed p.24 prices one type at three depths and gives each depth its own
prefix: **B0** = d.35, **BJ** = d.47, **B1** = d.62.

**The wall chapter got lucky.** A wall family has one depth, so its two-letter
prefix could be treated as a family name — `PB` = H.36, `PC` = H.48 and so on —
and the filler table on printed p.434 could be used to learn one before the
section was opened. That worked seven times and felt like a rule.

A base family has two or three depths and a prefix for each. Swept across the
low families the same day:

| family | d.35 | d.47 | d.62 | d.67 |
|---|---|---|---|---|
| H.39 | B0 | BJ | B1 | — |
| H.48 | BC / BD / BQ — which is which is **not read yet** | | | |
| H.58.5 | B3 | B6 | B4 | — |
| H.78 | B7 | — | B8 | B9 |
| H.84 | BK / BL / BM — **not read yet** | | | |

No rule across families, none across depths. **d.47 is a depth this registry
had never held.**

---

## 2. The filler table does not use the same key, and BJ proves it

Printed p.434 prices base-unit fillers **one per height, with no depth axis at
all**: `B0` (39), `BC` (48), **`BJ` (58,5)**, `BE` (60), `BI` (72), `B7` (78),
`BK` (84).

Four of those match the d.35 member of the unit family. **`BJ` does not.** The
H.58,5 base units are `B3` / `B6` / `B4`, and `BJ` is H.39 at **d.47** on
printed p.24. Two characters, two different slots. The codes never collide —
`BJ0150`/`BJ0151` against `BJ0525` and up — but **the letter cannot be used to
find a family**.

The filler recon's reading — *"printed p.434 names the height letters and the
unit page confirms them; two pages in two chapters agreeing is as close to
confirmation as this catalog gets"* — was **true for the wall chapter and does
not generalise**. It is now recorded as such in `code_grammar.base_units`.

**Open for Elda:** is `BJ0150`/`BJ0151` really the H.58,5 base filler, when the
H.58,5 base units are `B3`/`B6`/`B4` and `BJ` is the H.39 d.47 letter? (The same
table also prints `PJ0150` at H.120 — a *wall* prefix inside the base-unit
filler table — flagged when p.434 was first read and still unexplained.)

---

## 3. And a corner has its own prefixes at the same depths

Written as a check — *tie every base code to the grammar table* — it failed
immediately on `AU090S`.

Printed p.42 prices the H.78 corner base units as **B7** at d.35, shared with
the plain units, then **AU** at d.62 and **AW** at d.67, where the plain units
read `B8` and `B9`. So the slot a prefix names is **(family, depth, geometry)**,
and two of the three H.78 corner prefixes were in no table at all.

That is what the check was for, and it found it on the first run.

---

## 4. The plinth, printed at last — for three families at once

`CESAR - 1 Project Guidelines.pdf` printed p.68 draws a **modularity** diagram
for each low base family: a worktop line at **78**, the unit height below it,
then **0** and **10** at the floor.

- H.39 → 78 / 39 / **0 / 10**
- H.48 → 78 / 48 + 48 / **0 / 10**
- H.58.5 → 78 / 58,5 and 19,5 + 39 / **0 / 10**

**The plinth is 100 for all three**, read for these families rather than
inherited from H.78 — and **render-verified at 200 dpi** before being written
down, which is the habit the N_Elle figures bought.

### And the same diagram says what these families are for

78 − 39 = 39. 78 − 48 = 30. 78 − 58,5 = **19,5** — exactly the drawer front that
printed p.37 and p.38 stack above a door.

**These are not short base units. They are the lower half of a column.** That is
the stacking concept Group 4 of the extraction plan is about, arriving three
groups early. Recorded, not implemented: nothing in the engine stacks anything,
and a 390-tall unit on a 100 plinth is a correct object on its own.

---

## What else printed p.24 gave

- **The first compound in the registry with no printed module split.** Every
  compound wall unit prints *"2 modules 60+45"* beside its row; this page prints
  nothing, though the drawing shows an internal divider. `modules_mm` is
  **absent** rather than guessed, and the check that compounds add up simply
  does not see these rows — correctly, since it can only check what is stated.
- **The suffix does not mark the compound either.** Both positions are `25`.
- **Every row carries the hung glyph**, all three depths, both positions. After
  two whole tall families that refuse it, which pages say *yes* is worth writing
  down too.
- **No hob glyph anywhere** — which is what a 390-tall undercounter unit should
  say.
- **The width set agrees across two chapters**: the guidelines list 45…240 for
  H.39 and printed p.24 prices exactly those.

---

## Added 2026-08-24 — a page stopped for a dimension we cannot name says so in BOTH places

**Printed p.26 and p.27 were opened and not extracted.** The stop itself is the
finding, and so is where it had to be written.

A page abandoned mid-read leaves two records that can drift: the **section
file**, which is what an extractor opens next time, and **`catalog_map`**, which
is what a plan is written from. `claude/extraction-plan-2026-08-23.md` was
written from the map alone and was wrong about its own Group 0 twice, for
exactly this reason — the map said *not_extracted* where the manifest note said
*blocked*.

So the rule is now enforced rather than remembered: **a page recorded as stopped
in one place must be recorded as stopped in the other, in words that name the
same reason.** A check asserts it. The cost of getting this wrong is not a lost
page; it is a plan that schedules a day of work that cannot be done.

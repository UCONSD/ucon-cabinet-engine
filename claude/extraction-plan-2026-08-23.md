# The extraction debt, and a plan in groups — 2026-08-23

> ## MOVED INTO THE REPOSITORY 2026-08-24
> Copied verbatim from the claude.ai Project. See `claude/README.md`.
>
> **DATED CORRECTION — §1 and §2 are SUPERSEDED, §4 to §7 are not.** Rule 9:
> added, never merged into the body.
>
> - **§1's "we hold 185" and every `held` figure in §2 were true on
>   2026-08-23 and are not true now.** The measured replacement is
>   `claude/debt-2026-08-24.md`, which counts **615 held** and re-measures the
>   whole book: ~1 230 mapped and not held, 135 excluded, 2 271 never mapped,
>   ~4 240 total. **Read the debt note for numbers; read this one for the
>   plan.**
> - **Group 0 is CLOSED** (p.37, p.38, p.48 extracted; p.112 and p.115 proved
>   blocked, not merely unread — see `claude/findings-2026-08-23.md`).
> - **Group 1 is CLOSED** — the whole wall column, H.36 through H.120 with all
>   five dish-drainer sections.
> - **Group 2 is CLOSED** — the five plain tall families, H.138 / H.198 /
>   H.210 / H.222 / H.234. See `claude/findings-2026-08-23-tall.md`.
> - **Group 3 is OPEN and part done** — base H.39 and H.48 extracted; H.58.5
>   (p.32-35) and H.84 (p.49-56) remain. See
>   `claude/findings-2026-08-24-base-column.md`.
> - **Group 4 and Group 5 are untouched.**
> - **§4's grouping principle survived contact and is the most useful part of
>   this document.** The prediction that the wall and tall columns would be
>   cheap because their grammar was already recorded held: both columns went
>   through in one session each. The prediction that the base column would need
>   discovery per family also held — see the base-column findings, where the
>   prefix turned out to name a (family, depth) SLOT rather than a family.

What is actually left to extract from `CESAR - 2 Kitchen System.pdf`, measured
rather than remembered, and a proposed order of work.

> **How the counts were made, and how far to trust them.** Every printed page was
> dumped with `pdftotext -layout` and scanned for six-character article codes
> (`[A-Z]{1,4}[0-9]{2,5}[A-Z]?`). **This is OUR estimate, not a source-verified
> count** — rule 4. It is calibrated against two numbers we already trust:
> printed p.434 gives **31**, which is exactly what the filler recon counted by
> hand, and printed p.36-48 gives **235** against the 231 recorded in
> `docs/Catalog_Section_Map_H78.md` — about **1,5 % high**. Treat every figure
> below as ±2 %, good enough to size work and not good enough to extract from.
>
> **One correction already made in the making:** the first regex allowed at most
> three leading letters and reported Hide & Seek as 1 code and Trilli as 0. Both
> were wrong — `CFMS21` has four. Anything that reads as "this chapter is empty"
> deserves one page opened before it is believed.

---

## 1. The debt in one line

**~3 800 unit codes are printed in this book. We hold 185.**

| | codes | |
|---|---:|---|
| held today | **185** | eleven registry files, eight sections |
| in `catalog_map`, not extracted | **~1 680** | the Maxima core + USA elements |
| excluded by decision | ~133 | the eleven Virgola-hood sections |
| **not in `catalog_map` at all** | **~2 115** | see §3 — and this is the half that is not "more of the same" |

The middle row is the debt everybody means when they say "debt". **The bottom
row is bigger, and most of it sits behind an axis the engine does not have.**

---

## 2. What the map holds, section by section

Non-excluded sections only. `codes~` is the estimate; `held` is the intersection
with the registry.

| class | printed | status | codes~ | held | section |
|---|---|---|---:|---:|---|
| base | 24-27 | not_extracted | 96 | 0 | Base units H. 39 |
| base | 28-31 | not_extracted | 120 | 0 | Base units H. 48 |
| base | 32-34 | not_extracted | 53 | 0 | Base units H. 58.5 |
| base | 35 | not_extracted | 24 | 0 | Sink base units H. 58.5 |
| base | 36-43 | **partial** | 166 | 94 | Base units H. 78 |
| base | 44-46 | **partial** | 54 | 20 | Sink base units H. 78 |
| base | 47-48 | **partial** | 14 | 3 | Base units H. 78 \| household appliances |
| base | 49-52 | not_extracted | 92 | 0 | Base units H. 84 |
| base | 53-54 | not_extracted | 34 | 0 | Sink base units H. 84 |
| base | 55-56 | not_extracted | 8 | 0 | Base units H. 84 \| household appliances |
| tall | 90-96 | not_extracted | 56 | 0 | Tall units H. 138 |
| tall | 97-101 | not_extracted | 44 | 0 | Tall units H. 198 |
| tall | 102-110 | not_extracted | 70 | 0 | Tall units H. 198 \| for base unit H. 78 |
| tall | 111-115 | **partial** | 44 | 14 | Tall units H. 210 |
| tall | 116-125 | not_extracted | 72 | 0 | Tall units H. 210 \| for base unit H. 78 |
| tall | 126-131 | not_extracted | 50 | 0 | Tall units H. 210 \| for base unit H. 84 |
| tall | 132-136 | not_extracted | 44 | 0 | Tall units H. 222 |
| tall | 137-145 | not_extracted | 68 | 0 | Tall units H. 222 \| for base unit H. 78 |
| tall | 146-150 | not_extracted | 48 | 0 | Tall units H. 222 \| for base unit H. 84 |
| tall | 151-155 | not_extracted | 44 | 0 | Tall units H. 234 |
| tall | 156-164 | not_extracted | 68 | 0 | Tall units H. 234 \| for base unit H. 78 |
| tall | 165-169 | not_extracted | 48 | 0 | Tall units H. 234 \| for base unit H. 84 |
| tall | 170-173 | not_extracted | 40 | 0 | Tall unit top elements H. 36 / 48 / 60 / 72 |
| wall | 211-212 | **partial** | 30 | 17 | Wall units H. 36 |
| wall | 213 | not_extracted | 16 | 0 | Dish-drainer units H. 36 |
| wall | 214-216 | not_extracted | 35 | 0 | Wall units H. 48 |
| wall | 217-218 | not_extracted | 20 | 0 | Dish-drainer units H. 48 |
| wall | 221-223 | **partial** | 33 | 15 | Wall units H. 60 |
| wall | 224-225 | not_extracted | 22 | 0 | Dish-drainer units H. 60 |
| wall | 228-231 | not_extracted | 31 | 0 | Wall units H. 72 |
| wall | 232-233 | not_extracted | 22 | 0 | Dish-drainer units H. 72 |
| wall | 238-240 | not_extracted | 28 | 0 | Wall units H. 84 |
| wall | 241-242 | not_extracted | 17 | 0 | Dish-drainer units H. 84 |
| wall | 245-247 | not_extracted | 27 | 0 | Wall units H. 96 |
| wall | 248-249 | not_extracted | 17 | 0 | Dish-drainer units H. 96 |
| wall | 252-254 | not_extracted | 27 | 0 | Wall units H. 120 |
| base/tall | 414-432 | 1 of 17 | 116 | 8 | USA elements, seventeen small sections |
| filler | 434-435 | **partial** | 37 | 5 | Closing strips and fillers |

---

## 3. What the map does NOT see — and it is the larger half

`catalog_map` covers the **Maxima core** (base 24-56, tall 90-173, wall 211-256)
plus USA elements and the fillers. A header sweep of all 635 pages shows what it
has never named:

| printed | block | codes~ | what it is |
|---|---|---:|---|
| 57-62 | **Tangram** | 7 | a door system of its own |
| 63-78 | **Block base units** | 88 | H.58.5 / H.64.5 / H.66 *"to align with base units H.78 / H.84"* — **a stacking relationship** |
| 175-194 | **Revego** receding door | 21 | **the Code column is EMPTY** — priced by configuration, not by article |
| 195-204 | **Hide & Seek** | 51 | its own system; codes are four letters + two digits (`CFMS21`) |
| 257-304 | **Unit** | 331 | a collection: base H.66 / H.72, tall H.138 / H.198, Compart |
| 305-319 | Glass display + **Comb** | 63 | glass doors, and the Comb drawer system |
| 321-395 | **N_Elle** | 670 | a whole collection, base and tall, H.36.8 / 78 / 84 / 210 / 222 / 234 |
| 397-408 | **N_Elle with framed door** | 188 | a second programme inside N_Elle, with its own price bands |
| 436-449 | End elements, adjoining side panels | 177 | **the area-derived (`MQ`) half the warehouse waits for** |
| 450-456 | Open end units, open units | 87 | **a second continuous-width axis**, 150-450 and 450-900 |
| 457-468 | **Thin** | 36 | a system |
| 469-482 | **Trilli** | 396 | a system, and far bigger than it looks |

**~1 189 of those codes — Unit, N_Elle and N_Elle framed — are one collection
axis away.** Everything the engine holds today is Maxima/Intarsio. That is the
M3 seam in `Catalog_Section_Map_H78.md`'s six-level hierarchy, level 1, and it
has never been modelled. Extracting N_Elle before it exists would mean either a
second registry that cannot say what makes it N_Elle, or a `family` key quietly
carrying two different things.

---

## 4. The grouping principle: cost is GRAMMAR, not codes

A section whose family letters, width index and suffix meanings are already
recorded is transcription with a render check. A section that needs its own
grammar read from scratch is a day. Printed p.41 is the standing proof: its
codes do not decode with the p.36 lookup and its elevation reads 750, so it has
sat unextracted inside an otherwise-finished section since 2026-08-17.

**Three things make a block cheap:**

1. **the family letters are already in `code_grammar`** — the tall chapter was
   read at section level on 2026-08-22 and its full pair map recorded, so no
   tall section needs discovery;
2. **the family already exists in the registry**, so height, mounting and plinth
   are settled — and a filler cannot be extracted until this is true;
3. **no new relationship** — nothing that stacks, spans, or is measured rather
   than counted.

---

## 5. The groups, in the order I would do them

### Group 0 — the clean remainder of what we are standing in · ~60 codes

Printed **p.37, p.38** (base H.78: drawer-and-door types, 28 codes), **p.48**
(the second dishwasher-door execution, 6 codes, already *planned* in the map),
**p.112 and p.115** (tall H.210, the pages the 14 held codes did not cover).

No new family, no new grammar, no new concept. **This is the warm-up that proves
the current pipeline still works end to end** before anything larger goes in.

**Blocked and deliberately left inside this group's pages:** p.41 (grammar reads
750, must be read from scratch), p.42-43 and p.46 and p.113-114 and p.223
(corner units, gated on **Elda Q7b**), p.45 (sink with fixed front, **Elda Q4**).

### Group 1 — the wall column · ~224 codes · printed 213-254

Wall H.48, H.72, H.84, H.96, H.120 and the five dish-drainer sections.

**The cheapest large block in the book, and the reason is a gift from the filler
work:** printed p.434 prints the wall height letters independently —
`PB`=36, `PC`=48, `PD`=60, `PE`=72, `PG`=84, `PF`=96, `PJ`=120. Two pages in two
different chapters agreeing is as close to confirmation as this catalog gets.
Every unit here hangs, and `mounting` / `mount_bottom_mm` are proven machinery.

**It also retires five orphan fillers** — `PC0151`, `PE0151`, `PG0151`,
`PF0151`, `PJ0151` — because a filler may not be extracted before its family.

**Test:** one unit of each height built in a row, each hanging at the project's
bottom line; then a `PD0151` at 50 mm beside a `PD` wall unit, which is the
printed p.11 closing-strip rule made real.

### Group 2 — the plain tall column · ~232 codes · printed 90-101, 132-136, 151-155

Tall H.138, H.198, H.222, H.234 — the sections that are NOT "for base unit".

`code_grammar.tall_units` already holds every pair: `C1/C2`, `CE/CF`, `CG/CH`,
`C0/C9`, first member d.35 and second d.62. Nothing to discover.

**Retires five more orphan fillers** — `C10151`, `CE0151`, `CG0151`, `C00151`
and the base filler `C10150`.

**Test:** one of each height, the d.35/d.62 pair resolving correctly, and the
plinth right — H.78 stands on 100 and H.84 on 60, and **no tall family has yet
declared its own `plinth_h_mm`**, which this group has to answer.

### Group 3 — the base column · ~427 codes · printed 24-35, 49-56

Base H.39, H.48, H.58.5 (+ its sink section), H.84 (+ sink, + appliances).

**The most expensive of the four columns, and the only one that needs discovery
per family.** H.58.5 already proved the point: there `6` = d.47 and `4` = d.62,
not the H.78 mapping. Each family's depth digits, width index and suffixes must
be read from its own pages before a single row is written.

**Retires the largest number of orphan fillers** — `B00150`/`B00151` (H.39),
`BC0150`/`BC0151` (H.48), `BJ0150`/`BJ0151` (H.58.5), `BE0150`/`BE0151` (H.60 —
**and there is no base H.60 section in this book**, which is its own question),
`BK0150`/`BK0151` (H.84).

**One loose end to answer here:** `BA0150` is a *base unit* filler at **H.36**,
and the book prints no base units at H.36 at all. Which family does it inherit?

**Test:** the plinth per family — H.84 must come up 60, not 100 — and the depth
letters verified against each family's own page rather than assumed.

### Group 4 — everything that STACKS · ~464 codes · printed 102-110, 116-131, 137-150, 156-173

The "for base unit H. 78 / H. 84" tall sections, plus the four top-element
sections.

**These are not 2 100-tall units.** Printed p.116 shows the elevation as
**132 + 78 = 210** (and 132 + 75 + the 30 mm grip zone for the gola version), so
the article is an **H.132 upper element that completes a column over a base
unit**. *(OUR reading of one elevation, to be verified on the page when the group
is extracted — but the family letters `C5/C6` are already recorded for exactly
this section, which supports it.)*

The top elements (H.36/48/60/72, letters `SB/SC/SD/SE`) are the same concept at
the other end of the column.

**One new relationship, ~464 codes behind it.** That ratio is why this group is
worth doing as a group and not page by page: the concept is paid for once.

**Test:** a stack built as a stack — an upper element over an H.78 base — with
the fronts meeting at 210 in both door versions, and the plinth appearing only
under the base.

### Group 5 — USA elements · ~108 codes left · printed 414-432

Seventeen small sections, one extracted. **Blocked on M1.11 and the appliance
module**, and four of the seventeen are N_Elle sections that are blocked again on
the collection axis. Not scheduled here.

---

## 6. The second horizon — do not start it without a decision

| | codes~ | what has to exist first |
|---|---:|---|
| End elements + adjoining side panels (436-449) | 177 | the warehouse's **area (`MQ`)** derivation |
| Open end units + open units (450-456) | 87 | a **second continuous-width axis** (150-450, 450-900) |
| Block base units (63-78) | 88 | the stacking concept of Group 4 |
| Glass display + Comb (305-319) | 63 | glass fronts as a finish/áxis question |
| Hide & Seek (195-204) | 51 | its own system |
| Revego (175-194) | 21 | **priced without article codes** — a different ordering model entirely |
| Thin (457-468) + Trilli (469-482) | 432 | their own systems |
| **Unit + N_Elle + N_Elle framed (257-408)** | **~1 189** | **the COLLECTION axis — M3** |
| Tangram (57-62) | 7 | the collection axis |

**The collection axis is the single biggest unlock in the book** and the one
thing on this page that is architecture rather than transcription. It is also
what `claude/finishes-and-price-bands-2026-08-22.md` already needs: price bands
are collection-scoped, and the filler pages proved it a third time.

---

## 7. What this plan does not change

- **Demand still beats order.** This is a menu, not a queue. If 545 Avenida needs
  an H.84 wall unit tomorrow, Group 1 moves to the front of Group 1.
- **One printed page is still one commit**, and every page still gets a render
  check before its rows are believed (rule 10).
- **A section is still what the printed index prints** — with the p.433 scope
  note: the index is sufficient, not necessary, and a page it forgot is mapped
  as a page of the section whose range contains it.
- **Nothing here is extracted by an estimate.** The counts above size the work.
  The rows come from the page.

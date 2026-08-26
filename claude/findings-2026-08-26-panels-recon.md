# Panels — chapter recon (2026-08-26)

Read for the island. Source: `CESAR - 2 Kitchen System.pdf`, printed pages
cited (PDF = printed + 2). Nothing here is in the registry yet.

## 1. The first thing the recon changed

"A panel, 22 mm by default" is not one object with a thickness field. The
catalog prints **three different things**, and only one of them is an object:

| | what it is | has a code? | is it geometry? |
|---|---|---|---|
| **2,2 cm adjoining end side panel** | a separate piece joined to the door | **yes**, per height x depth-group | **yes** — a real object |
| **1,8 cm finishing side panel** | *replaces* the carcass's own side panel | **no** — a surcharge by H x D x band | **no** — the carcass already occupies that volume |
| **custom panel per m²** | `DZAK22` / `DZAC00` in the Metron estimate | estimate code, **not** a price-list article | depends |

Printed p.553 is explicit: *"Surcharge for finishing side panels, 1.8 cm thick
| Replacing standard side panel"*. It is a property of a cabinet, not a part
next to it. Under rule 4 (envelope-only geometry) it draws nothing new.

So the module builds the 2,2 family. The 1,8 family is a flag + a companion
order line on an existing unit, and belongs to the properties panel, not to a
panel generator.

The 1,8 surcharge table also states what gets finished:
- 2 visible sides — melamine, Technomat, Fenix NTA, Fenix NTM, Unicolor;
- 1 visible side, reverse in carcass colour — silk-effect / gloss / structured
  / metallic-effect lacquers, first / prime / special / Intarsio wood veneers.

Depths in that table: **D. 35 / 62 / 67 / 72**. Heights 36…234 (D.35 starts at
36; the deeper three start at 39).

## 2. What the chapter contains (printed p.433 index)

```
434  Closing strips and fillers for Maxima and Intarsio     [EXTRACTED]
435  Closing strips and fillers for N_Elle …                [partial]
436  End elements for Maxima-Intarsio — L-shaped end side panel, 7.5 cm wide
437  … L-shaped with intermediate shaped grip recess (35,7 / 44,7)
438  … L-shaped with intermediate shaped grip recess (16,2 / 55,2)
439  … L-shaped with intermediate shaped grip recess (19,2 / 55,2)
440  Adjoining end side panel, 2.2 cm thick — 45° vertical edge
441  … same, for units whose hinges are on the side OPPOSITE the 45° edge
442  Adjoining end side panel for Maxima Groove
443  Adjoining end side panel for lacquered Intarsio
444  Adjoining end side panel for N_Elle | 45° vertical edge
446  Adjoining end side panel for N_Elle with framed door | 45°
448  2.2 cm thick end side panels | Finishes and price bands
450  2.2 cm thick open end units
455  Open base/wall/tall units 15–45 cm wide, 2.2 thick
456  Open base/wall/tall units 45–90 cm wide, 2.2 thick
457+ Thin, Trilli (open-unit systems — a different animal)
```

The running head on all of it is **"Fillers – End elements"**, i.e. the same
chapter the fillers we already hold came from.

## 3. The depth grammar — DERIVED, and it closes on all seven groups

The catalog labels each group by the CARCASS depth(s) it serves and prints a
drawn depth `d.` beside it. Those two numbers differ, and the catalog never
says why. They close as: **d = sum of the carcass depths + 2,2 per door face,
rounded UP** (to the next 0,5 for a single panel, to the next whole number for
a back-to-back).

| label | carcass | + doors | printed d. |
|---|---|---|---|
| 35 | 35 | 37,2 | **37,5** |
| 62 | 62 | 64,2 | **64,5** |
| 67 | 67 | 69,2 | **69,5** |
| 35+35 | 70 | 74,4 | **75** |
| 62+35 | 97 | 101,4 | **102** |
| 67+35 | 102 | 106,4 | **107** |
| 62+62 | 124 | 128,4 | **129** |

This is derived arithmetic, not a printed rule. It is recorded here because it
explains the numbers; the registry still carries the printed `d.` verbatim.
(2026-08-26 discipline: arithmetic that closes exactly is not evidence — but
seven independent groups closing the same way is worth writing down.)

**A misprint it exposes.** Printed p.436 labels BOTH the d.102 and the d.107
group "for 62+35–cm deep side panel". The arithmetic says d.107 = 67+35, and
the codes agree: the d.102 rows carry the X-prefixes that mean 62 everywhere
else (`X40097`, `X80097`, `XL0097`), the d.107 rows carry the B-prefixes that
mean 67 (`B60097`, `B90097`, `BM0097`). Two independent witnesses against one
label. The registry follows the codes and records the printed label as a note.

**The back-to-back groups are the island.** 35+35 → d.75, 62+35 → d.102,
62+62 → d.129. An island whose two rows meet back to back takes ONE panel
across both, not two.

## 4. Code grammar

The letter pair is the HEIGHT, and it is different in every depth group —
`PB`=36 and `B0`=39 in the d.37,5 group, `X1`=39 in d.64,5, `B2`=39 in d.69,5.
The four trailing digits carry the depth group AND which page the row came
from: `0030` (p.440, 45° edge), `0130` (p.441, opposite hinge), `0077` (p.436,
L-shaped), `0087` / `0097` / `0107` (its back-to-back groups). Suffixes also
drift inside one table — the 278-high row is `0031` where its neighbours are
`0030`.

Rule 5 applies with no exception: **explicit registry rows only, never decoded
by analogy.**

Heights on the 45° adjoining panel (d.37,5 group): 36, 39, 48, 58,5, 60, 72,
78, 84, 96, 120, 138, 198, 210, 222, 234, 278. The deeper groups drop 36, 72,
96 and 120. The L-shaped panel is much shorter: 39, 48, 58,5, 78, 84 only.

Price bands 1–11 as everywhere else; **bands 9 and 11 are "–" on every panel
row in the chapter** — the finish families at those bands are not made in
panels.

## 5. Charges that ride along

- **Vertical edge of door, each**: 48 pts up to H.72, 65 pts H.75–140, 86 pts
  above H.141. Printed on every 45° page.
- **Height reduction of side panel for side grip recess, if an adjoined end
  side panel is present**: 84 pts.
- **Groove / lacquered Intarsio edges** (printed p.442, p.443) are priced as
  *workmanship per m²*, not per piece: Groove 438 / 516 / 682 / 884 by finish
  family; Intarsio 454 / 500 / 720. And the constraint that matters for
  drawing: **"The Groove end side panel cannot be joined at 45° with the
  door."**
- **Side panel depth increase** (printed p.549): 62→67, 67→72, 72→77, **41 pts
  per step per side panel**, listed per height family. This is the depth
  INCREASE path — the one I wrongly said did not exist.
- Melamine, Technomat, Unicolor and Fenix L-shaped panels ship with an ABS
  edge; *"Requests for different edgings will not be accepted."*
- Not available on the L-shaped panel: the Inside and Frame shaped grip
  edgings; no Intarsio with trama; no Noce Sgubbiato / Fenix NTA at D.129.

## 6. What this means for the module

1. `object_class: 'panel'` already exists in Contract v2 and **nothing has ever
   built one.** The fridge-bay panels were a hard-coded table inside probe 45.
2. The generator's first panel family should be the **2,2 adjoining end side
   panel** — it is the one with codes, and its back-to-back rows are exactly
   what an island needs.
3. The 1,8 finishing side panel is NOT this module's job. It is a surcharge
   line on a cabinet that already exists — closer to `companion_refs` than to
   geometry.
4. A panel is handed and it is joined at 45° to a specific door, which means it
   needs the same treatment `hinge_side` gets: never guessed, only chosen. The
   two pages p.440 / p.441 are that choice, and they are DIFFERENT ARTICLES.
5. Nothing here reaches the ISLAND until we know which of the seven depth
   groups the island's two runs make. That is a fact about the model, not
   about the catalog.

## 7. Open questions this recon raises

- **Q20** — printed p.436 labels the d.102 and d.107 groups identically
  ("62+35"). Codes and arithmetic both say d.107 is 67+35. Confirm.
- **Q21** — the printed `d.` is the drawn depth including door faces. Is the
  panel's own board still 2,2 thick, i.e. is `d.` the OVERALL depth of the
  assembly rather than of the panel? Everything we draw depends on it.

---

## 8. What was then built (same evening)

**The tables were PARSED, not transcribed.** All 124 rows came out of
`pdftotext -layout` through a throwaway parser that split each page on its
"for N-cm deep" labels and matched `H. + six-character code` — so a
mistyped code is not one of the ways this can be wrong. The two places it
COULD be wrong are the two recorded above: a page that misprints a height,
and a page that labels two groups the same. Both were checked against a
rendered image at 100 dpi, which is why one is corrected and the other is
an Elda question rather than a correction.


124 codes in three section files, and four changes in `core/`.

**`Registry.lookup` now reads height from the ROW, family second.** Every
section extracted before today is one height family per file — H.78 is 780 for
all 262 of its codes — so the family said it once. printed p.440 prices `PB0030`
at H.36 and `C00030` at H.234 in the same table, and the height is what the code
IS. The same precedence `scoped` already used for `plinth_continues`. A file that
says nothing per row is untouched, and a check holds both halves.

**`front_slabs` gained `when 'none' then []`.** The `else` branch hands anything
it does not recognise a full-face slab, which for a 22 mm board beside a run
would have drawn a door on the end of the kitchen. Stated, not reached by
absence — the same reason the fillers state `kind: 'single'`.

**`Generator.panel_ground` — and this is the interesting one.** An end panel is
the first object in this registry with no ground of its own. Everything else
knows where its bottom sits because its family does: a base unit stands on the
H.78 plinth, a wall unit hangs. printed p.440 prices sixteen heights in one
table and states where none of them begins, because the honest answer is
"wherever the run it joins begins." So the panel reads its mounting and plinth
off the unit it is placed beside — **through that unit's code and the registry,
not off its geometry**, so the answer is the one the neighbour was built from
rather than a measurement of whatever has since been dragged. With no
neighbour selected it **refuses and draws nothing**. `Standards::PLINTH_H_MM`
would have been right for the island and wrong for every wall-height panel in
the same table: the kind of default that survives until it reaches a sheet.

**A width refusal that is NOT one of the catalog's.** `WIDTH_MOD_FORBIDDEN` is
the book's own list, pinned against `_manifest.json`; a panel's `width_mm` is
its 2,2 cm thickness and cutting it is a category error the book never had to
name. So `Registry.width_is_a_thickness?` runs BEFORE the list and outside it.

### Three things the census caught on the way

> **A word is not a sentence — the second instance in this file.** Sixty of the
> 124 panels landed in the `units with jumbo drawers` bucket, because printed
> p.441's own title is *"for base units with drawers/jumbo drawers … hinges on
> the side opposite the 45° edge"*: the description names the units the panel is
> FOR. `50_registry.rb` already carries the first instance, where matching
> `push-pull` refused 133 codes for saying they had none. The other sixty-four
> answered *yes, cut me* — the silent kind of wrong the census check warns about
> in its own comment.

> **A prefix is not a chapter.** The USA-elements check tested every code in the
> registry for the prefixes `BL`/`BM`/`C8`/`Y4`/`Y7`, on the assumption that a
> prefix names a family. printed p.440 prices `BM0030` and p.444 prices
> `Y40028`, three hundred pages from the USA elements. The check is now scoped
> to the USA sections; what it is for survives intact. This is rule 5 arriving
> from the other side — a code is a lookup, and so is its first two letters.

> **A correction that erases what was printed is a second source.** `Y00129` is
> printed at H.84 on p.445 and is recorded at H.36,8, on two witnesses: the
> parallel framed-door page prints the identical group as 36,8/78/84, and
> `Y0`/`Y3`/`Y6` is that triple everywhere else in the collection. Verified
> against a rendered image, so it is the catalog's misprint and not a
> text-extraction artifact. The printed value stays on the row as
> `printed_height_cm`, and a check requires both.

### What is NOT built

- No panel has been drawn in SketchUp yet. The ground rule needs a neighbour, so
  it must be tried on the island rather than on an empty model.
- The L-shaped end panel (printed p.436-439) needs an L profile in
  `30_geometry`, and its three grip-recess variants belong to the gola axis.
- The 1,8 cm finishing side panel is held in `catalog_map` as a surcharge and
  **must never become an article**. Wiring it is properties-panel work: a chosen
  option on an existing unit plus an order line by H × D × band.
- The surcharges are recorded and unread: the vertical door edge (48/65/86), the
  45° lip (205 in N_Elle, 84/168 stone and 134/267 ceramic in the framed
  collection), the grip-recess height reduction (84), and the depth increase of
  printed p.549 (41 a step).

---

## 9. The first lookup against the real kitchen, and what it corrected (same evening)

Probe run 48 (`build/66_island_ends.rb`, read-only) walked the Avenida Primavera
model, found every cabinet end with nothing against it, and asked the new
registry which panel would finish each. Five things came back.

### 9.1 THE CORRECTION — the two pages are not what §2 and the commit said

The registry note read: *"THIS IS A DIFFERENT ARTICLE, NOT A VARIANT. The two
pages price the same heights and the same depth groups under different codes."*
**That is false, and the first real lookup showed it.** Within a collection the
two pages price **disjoint** depth groups, so no comparison between them is
possible and nothing is ever a choice. Worse for the reading: **which page a
group falls on changes between collections** — Maxima puts 35+35 on the banner
page, N_Elle and N_Elle framed put it on the 45° page — so the banner does not
mean "back-to-back" either. The drawings on both pages are the same drawing.

The claim survived the extraction because nothing in it was tested against a
question. It died the moment a real end at d.620 asked *which code* — and the
answer came back from one page with no rival on the other.

Now: the two type keys record **which printed page a code came from**, which is
a fact; what the banner MEANS is **Elda Q22**; the depth group picks the code;
and the picker labels the two levels with the printed page headings and calls
neither a choice. The wrong note is kept beside the correction in all three
files (`choice_note` / `choice_note_corrected_2026_08_26`), and a check now pins
the disjointness *and* the fact that the partition moves between collections.

> **A reading nothing has asked a question of is not yet knowledge.** Four
> documents, a commit message and a set of green checks all repeated it, because
> every one of them was written from the same reading of the same two pages.

### 9.2 The model has NO island yet

*"none — every run has its back to something that is not a cabinet."* Nothing in
545 Avenida Primavera stands back to back today, so every free end is a
single-depth panel and the back-to-back groups (d.75 / 102 / 107 / 112 / 129)
have nothing to serve. The island is still to be drawn; the panels for it come
after its units, not before.

### 9.3 A deep panel stops at H.84 and resumes at H.138

The chapter prints **no H.72, H.96 or H.120 at d.62 or d.67** — those heights
exist only in the d.35 group. So a 620-deep unit at wall height has no adjoining
end panel in the book at all. Not a gap in the extraction: it is what the pages
print, and it is consistent (a 620-deep box 720 high is not a thing Cesar sells).

### 9.4 AN UNPRINTED HEIGHT INCREASE ORPHANS ITS END PANEL

Two `SD0631` in this kitchen were increased to **H.720** — the increase Q11 is
about, printed nowhere. The probe asked for their end panels and got nothing at
any depth. The same is true of `UCON-BESP-001` at H.313. This is a consequence
worth stating plainly: **a dimension the catalog does not print cannot be
finished with a catalog part.** Whatever Elda answers about the height increase,
the end of that run needs an answer of its own.

### 9.5 A hint about the collection question, from the kitchen's own tall run

`C90635` is **H.2340** at d.620, and only **Maxima** prices a panel that tall —
`F90030`. N_Elle and N_Elle framed stop at H.84. So if this kitchen is N_Elle,
its tall run cannot have a finished end from the panel chapter at all. Combined
with the estimate header (MAXIMA 2.2, 2026/30829) against the glass page's
N_Elle mark, that is worth putting in front of Elda alongside the glass
question — it is the first place where the collection answer changes what CAN be
ordered rather than only which code.

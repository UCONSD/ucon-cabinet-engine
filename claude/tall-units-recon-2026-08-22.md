# Tall units — reconnaissance and first extraction (2026-08-22)

Companion to `claude/ucon-cabinet-engine-status.md`. Everything below is READ
FROM THE SOURCE PDF (`CESAR - 2 Kitchen System.pdf`), page numbers **printed**
(PDF = printed + 2). Trust level: SOURCE.

**Landed in the repo:** 16 section rows in `catalog_map`, a
`code_grammar.tall_units` block, a correction to `code_grammar.usa_elements`,
and `registry/cesar/tall_h210.json` — **printed p.111 extracted whole, three
types, 14 codes**. Suite: **245 checks, 0 failures** on the bridge VM
(`ruby 3.0.2 (aarch64-linux-gnu)`). Core version unchanged at 0.42.0 — no
Ruby in `core/` was touched.

This is the registry's **first metric tall family** and its **first
floor-standing full-height cabinet**. Until today the `tall` class held only
the eight USA fridge and wine-cooler door panels from printed p.418.

## Section pages (printed p.79 index, verbatim)

| printed | section | letters (d.35 / d.62) |
|---|---|---|
| 90 | Tall units H. 138 | C1 / C2 |
| 97 | Tall units H. 198 | CE / CF |
| 102 | Tall units H. 198 \| for base unit H. 78 | C7 / C8 |
| **111** | **Tall units H. 210** | **CQ / CR** |
| 116 | Tall units H. 210 \| for base unit H. 78 | C5 / C6 |
| 126 | Tall units H. 210 \| for base unit H. 84 | CQ / CR |
| 132 | Tall units H. 222 | CG / CH |
| 137 | Tall units H. 222 \| for base unit H. 78 | C3 / C4 |
| 146 | Tall units H. 222 \| for base unit H. 84 | CI / CK |
| 151 | Tall units H. 234 | C0 / C9 |
| 156 | Tall units H. 234 \| for base unit H. 78 | C0 / C9 |
| 165 | Tall units H. 234 \| for base unit H. 84 | CW / CX |
| 170 | Tall unit top elements H. 36 \| without fixings | SB |
| 171 | Tall unit top elements H. 48 \| without fixings | SC |
| 172 | Tall unit top elements H. 60 \| without fixings | SD |
| 173 | Tall unit top elements H. 72 \| without fixings | SE |

**16 sections.** Chapter runs printed 90–173; printed 174 opens the next one.

Two notices are printed on the index page itself and belong to the whole
chapter: *"Tops, upstands, plinths, grip recesses and handles are not included
in the price"* and *"IMPORTANT: 35 cm deep tall units must be fixed to the
wall"*. The second one applies to every `CQ` code we now hold.

## Code grammar — the family letter is a PAIR, and the pair is a lookup

**Every tall section prints two two-character prefixes: the first is d.35, the
second is d.62.** That is the chapter's one clean rule, and it is worth having,
because everything else about the prefix is unpredictable.

**The pair is not one-to-one with a section.** `CQ/CR` serves both **H.210**
(printed p.111-115) and **H.210 for base unit H.84** (printed p.126-131).
`C0/C9` serves both **H.234** (p.151-155) and **H.234 for base unit H.78**
(p.156-164). Meanwhile H.198 and H.222 give their "for base unit" sections
letters of their own. There is no rule to learn. Read the section.

The codes do not collide, because the four-digit tail differs — p.111-115 uses
width indices `03/05/06/07/09/12`, p.126-131 uses `05/06/07/09/15/16/19/26/27/
29/36`. But **a loader that keyed on the prefix would silently merge two
sections the book keeps apart**, which is the registry-loader hardening item
arriving with a concrete case attached.

### The one alphabetical run in the catalog, and why it changes nothing

The four top-element sections are `SB` / `SC` / `SD` / `SE` against H.36 / H.48
/ H.60 / H.72 — the first genuine alphabetical sequence of family letters
anywhere in this book. Recorded as an **observation**, not promoted to a rule.
The wall letters (B/D/E/G against 36/60/72/84) and the tall pairs above are both
standing proof that a sequence in one chapter predicts nothing in another.

## The finding that reaches back into the USA chapter

`claude/usa-elements-recon-2026-08-20.md` §3 lists `BL`/`BM`, `Y4`/`Y7`, `C8`
and `CR` as **new family letters**. They are not new.

| USA letter | where the USA recon found it | what it actually is |
|---|---|---|
| `B8` / `B9` | p.414, USA base H.78 | metric base H.78 depth digits — already in the registry |
| `BL` / `BM` | p.415, USA base H.84 | **metric base H.84**, printed p.49-52 |
| `C8` | p.417, USA tall H.198 | **metric H.198 for base unit H.78**, printed p.102-110 |
| `CR` | p.418, USA fridge doors | **metric tall H.210**, printed p.111-115 |

**The USA elements chapter has no grammar of its own. It is the same family
letters carrying USA width indices** — `94/96/97/99` where the metric grid uses
`03/05/06/07/09/12`. That is the whole reason no USA code collides with a metric
one, and it is a much simpler story than "a chapter of new prefixes".

`Y4`/`Y7` is the one claim not yet checked against its own chapter: it belongs
to the Unit collection (printed p.257), which is still entirely unmapped.

Recorded as `code_grammar.usa_elements.family_letters_are_not_new`, written as a
**correction dated today** rather than by editing the original note away. A test
fails if the correction is removed.

## printed p.111 — the extraction

Three types, 14 codes, both depths. `registry/cesar/tall_h210.json`, family
`Tall H.210` (namespaced, same reason as `Wall H.36` and `USA Tall H.210`).

| type | codes | W | d |
|---|---|---|---|
| Tall unit with door — 1 rh or lh door, 4 shelves, 1 divider | CQ0331/0531/0631/0731, CR0331/0531/0631/0731 | 30/45/60/75 | 35 and 62 |
| Tall unit with doors — 2 doors, 4 shelves, 1 divider | CQ0930, CQ1230, CR0930, CR1230 | 90/120 | 35 and 62 |
| Tall unit with door, kit-ready in the bottom section — 1 rh or lh door with 155° hinges, 2 shelves, 1 divider | CR0535, CR0635 | 45/60 | **62 only** |

Height 2100, standing on the 100 plinth, so the front runs z=100 → z=2200.

### Three things the page says that a code table would not

**1. The price table prints a width the visual index does not — and the check
mattered more than the finding.** The D × W index on printed p.82 lists the
one-door type as *"D. 35 W. 30, 45, 60 / D. 62 W. 30, 45, 60"*. The price table
on printed p.111 prints `CQ0731` and `CR0731` at **W.75** with a full price row.

Before recording that as a discrepancy it was checked, because **an absence in
extracted text is not an absence on the page**. `pdftotext -bbox-layout` on
p.82 came back with several captions in that very block reduced to a bare
`D. | W.` — the digits were silently dropped. So the page was rendered instead
(`pdftoppm -r 300`, cropped to
`sources/factory/p82-084-tall-h210-caption.png`) and read as an image. The
caption really does stop at 60.

**The price table is the authority: it prints the article.** W.75 is extracted;
the index is a navigation aid. Same lesson as printed p.561 — when a reading
matters, leave the text layer.

**2. The wall-hung surcharge is per TYPE, not per page.** *"Surch. for wall-hung
version on page 548"* is printed in the margin of the one-door type and of both
fridge units on p.115, and is **absent** from the two-door type and the
kit-ready type. Recorded verbatim; nothing is modelled as `wall_hung` and
`mounting` stays floor for the family.

> **CORRECTION 2026-08-23 (rule 9 — added, not erased).** That observation was
> correct and **was never turned into data**, so for a day and a half the engine
> offered all fourteen codes wall-hung. printed p.19's "Hung version" pictogram
> is the printed carrier of the same fact. `tall_two_doors` and
> `tall_door_kit_ready` now set `wall_hung: false`. **A reading that stays in a
> note is a reading the engine does not have.** See
> `claude/findings-2026-08-23-tall.md`.

**3. Suffix 35 exists only at d.62.** A d.35 tall unit cannot take the
bottom-section kit — there is no `CQ` counterpart at all.

Width index on this page happens to match the wall lookup exactly (30=03, 45=05,
60=06, 75=07, 90=09, 120=12). **Coincidence of two chapters.** The corner units
two pages later break it past repair: `CQ152D/S` is W.115, `CQ180D/S` is W.120,
`CQ157D/S` is W.130. Same for the suffix: 31 = one door and 30 = two doors here
*and* at wall H.60, while at wall H.72 the same 30 is a pull-out door.

## The kit-ready type is the live options case

`claude/options-architecture-2026-08-20.md` took its worked example from printed
p.97 — the H.198 twin of this type — because one printed row carries **an option
that is CHOSEN and an option that is IMPLIED at the same time**:

- *"See kit on page 569"* — the drawer and jumbo drawer kit, ordered or not.
- *"1 rh or lh door with 155° hinges"* — comes with the article whether anyone
  asks or not.

`companion_refs` is a comma-joined string and can express neither, so **neither
is recorded**. Half an answer written into a string is worse than a recorded
gap. Both wait on Contract v1.6 and `registry/cesar/options/`. The two shelves
against the other types' four are what makes room for the kit; the code is the
same article either way.

That makes **two** live cases now queued behind v1.6 — this one and the wine
cooler cutout, whose data source is not even Cesar.

*(2026-08-24: the contract half landed as v2.1 on 2026-08-22. The catalog half
did not, and the queue is now FIVE positions in five chapters, all printing
"See kit on page 569".)*

## printed p.112-115 — recorded, not taken, with reasons

- **p.112** — pull-out door (`CR0350/0550/0650`), "Dispensa" (`CR0385/0585`),
  "Tandem" (`CR0586/0686`). Every type is *defined by* an interior mechanism the
  page names but does not code: Arena Style Plus doors and trays, an ETOUCH
  electrical opening with a power adapter priced in the margin with **no
  article**. The envelope is a box with one front and could be drawn today —
  but extracting the carcass while dropping the thing the article *is* would
  misrepresent it.
- **p.113** — "Convoy" (`CR0688`), broom cupboard (`CR1512/1612`), and the first
  **corner tall units**. The broom cupboard alone is extractable; held back only
  so the page is taken whole when it is taken.
- **p.114** — corner tall units W.120 and both Slidecorner sizes.
- **p.115** — `CR4611` and `CR4712`, the fridge units. Appliance module
  territory. Both carry Servo Flex and a Power adapter priced without article
  codes; `CR4611` adds a Kamat fixed-hinge surcharge. One takes fixed hinges,
  the other *explicitly does not* — a fact that needs somewhere to live before
  the codes are useful.

### The corner tall unit is not the base corner made taller

This is the **third chapter** in which the `D/S` execution letter appears —
after the base corners (printed p.42) and the straight corner wall unit
(printed p.223). That is more direct evidence for **Elda Q7b**, which is still
the only open question with shipped code depending on it.

And the geometry is genuinely new: a corner tall unit carries a **panel W.
70/75/85**, and its overall W (115/120/130, or 130/135/145 for the W.120
carcass) is the carcass *plus* that panel. The base corner's 8×8 filler
arithmetic does not describe it.

A test fails if any `CQ`/`CR` code ending in `D/S` ever reaches the registry.

## Tests added (235 → 245)

1. The tall chapter is in the map: 16 sections, first `Tall units H. 138` at
   printed 90-96, last at 173 — and the USA rows, also class `tall`, are not
   swept in.
2. printed p.111 holds three types and 14 codes, all 2100 tall, depths {350, 620}.
3. **The prefix is the depth**: every `CQ` is d.35, every `CR` in this section is
   d.62 — plus the two shared pairs are pinned, so tidying them apart fails.
4. `CR` spans three printed sections and no code collides; the metric and USA
   width-index sets are disjoint.
5. Nothing from p.112-115 has leaked in, and no `D/S` tall corner code exists.
6. A tall unit stands on the floor at `PLINTH_H_MM` and carries no
   `mount_bottom_mm`.
7. The 2100 front is one slab; the two-door unit is two equal ones.
8. This family declares **no** `door_versions` — and H.78 still does, so the
   absence is a fact rather than a hole.
9. The kit-ready type records neither its chosen kit nor its implied hinges,
   and is d.62 only.
10. The USA family-letter correction is recorded and names the metric section it
    came from.

Plus the two counts updated: 166 → **180** codes, in `Registry.codes` and
`Registry.catalog`.

## Method note — how the chapter was swept

84 pages were read in three commands, not 84 page reads: dump once with
`pdftotext -f A -l B -layout <pdf> /tmp/chapter.txt`, split on `\f`, then pull
per page the running header, any line **followed by an `–` bullet** (that is a
type title), and the code rows with the nearest `d. NN` marker above them. The
depth-pair grammar and both shared letter pairs fell out of that sweep. They
would not have fallen out of reading p.111 alone.

The counterpart caution is §1 above: the same text layer that made the sweep
cheap also drops digits without saying so. Cheap for structure, not trusted for
an absence.

## Open, not decided

- **Which tall section is next.** printed p.116 (H.210 for base unit H.78,
  `C5/C6`) is the natural neighbour — it is the section whose front splits align
  with an adjacent base unit, which is what a real run wants. p.113's broom
  cupboard is the cheapest single article left in the section we already hold.
- **`restrictions` has nowhere to be written.** *"35 cm deep tall units must be
  fixed to the wall"* is a real installation fact, cited in the section file,
  and nothing writes it onto the object. The contract has the key.
- **Top elements (p.170-173)** sit on top of a tall unit and are a stacking
  relationship the engine has never modelled. Not a code problem.
- **Whether a corner tall unit's panel is geometry or a companion.** It is
  priced inside the article and it changes the footprint, so probably geometry —
  but that is a guess and it is written here as one.

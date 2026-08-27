# The Cesar shelf — which book holds what (2026-08-26)

Until this evening this repository had **one** of five books, and three separate
mistakes today came from grepping it as if it were all of them. This file says
what is on the shelf so that never repeats.

All five live in `sources/factory/`, which is **git-ignored** (`.gitignore:13`,
`sources/**/*.pdf`) — cloning gets the code, not the catalog. Copy them in by
hand on a new machine.

**Page offset is +2 in every volume**: PDF page = printed page + 2. Verified on
the footers of PDF 60 / 120 / 180 in each. Always cite PRINTED pages.

| | file | pages | edition |
|---|---|---:|---|
| 1 | `CESAR - 1 Project Guidelines.pdf` | 300 | October 2021, update 05\|26 |
| 2 | `CESAR - 2 Kitchen System.pdf` | 634 | " |
| 3 | `CESAR - 3 Linear Elements.pdf` | 244 | " |
| 4 | `CESAR - 4 Home Elements.pdf` | 176 | " |
| 5 | `CESAR - 5 Bathroom Collection.pdf` | 202 | **April 2026** — a separate price list, not part of "BOOK 1/2/3/4" |

---

## Volume 1 — Project Guidelines

The rules and the finishes. **Everything the engine calls "appearance" is here**,
and so is the collection question.

| printed | section |
|---|---|
| 4 | General conditions of sale |
| 10 | Order management and execution flowchart |
| **12** | **PRICE BANDS** |
| **16** | **DOOR FINISHES AND MATERIALS** |
| 41 | Collections — index |
| 42 | Intarsio |
| **50** | **Maxima 2.2** |
| 67 | Planning with Maxima and Intarsio |
| 105 | Tangram, and Tangram with L-shaped grip edging |
| 125 | Unit |
| 135 | Planning with Unit |
| **160** | **N_Elle** |
| 167 | Planning with N_Elle |
| **200** | **Glass display cabinet** |
| 225 | Grip recesses, plinths — index |
| 226 | Grip recess |
| **230** | **PLINTHS** |
| 233 | Home elements |
| 269 | Finishes and materials of linear elements |

**Open questions this volume plausibly answers, none of them read yet:**

- **The collection question** (`glass_wall_h96.json` → `collection_note`, and
  Q22's cousin): the project header says MAXIMA 2.2 while the glass page carries
  an N_Elle mark. Printed p.50 and p.160 are the two collections themselves,
  and p.67 / p.167 are their planning chapters.
- **The glass frame** — printed p.200 is a whole Glass display cabinet chapter.
  On 2026-08-26 we set the frame to 25 mm as a UCON declaration after failing to
  find a section anywhere in Volume 2. This page was never looked at.
- **The plinth** — printed p.230. The plinth-with-a-cutout question (owed 1) and
  Q23's "does an end panel stand on the plinth or on the floor" both live here.
- **Finishes and price bands** — M1.8 has no source today; p.12 and p.16 are it.

## Volume 2 — Kitchen System

The book everything so far was extracted from: base, wall and tall units, sink
bases, appliances, fillers, end panels, open units, fronts, modifications.
`registry/cesar/` is entirely this volume, and `_manifest.json` → `catalog_map`
is its map. Chapter notes live in `docs/Catalog_Section_Map_H78.md` and the
`claude/findings-*` series.

## Volume 3 — Linear Elements

Tops, splashbacks, breakfast bars, shelves — and **panels priced by the square
metre**, printed p.214-220, which is where a floor-standing end side panel comes
from. Read on 2026-08-26:
`claude/findings-2026-08-26-panels-recon.md` §10. Nothing extracted.

| printed | section |
|---|---|
| 9 | Handling tops |
| 10 | Top finishes and features |
| 33 | Éclaire and Macaron edge profiles |
| 35 / 47 / 49 / 55 | Features of Maxima-Intarsio / Tangram / Unit / N_Elle tops |
| 65 | Features of splashbacks |
| 71 | Features of Living tops and breakfast bars |
| 92-133 | Side panels: Fenix, ceramic, engineered and natural stone |
| 148-177 | Side panels: Barazza and Foster stainless steel |
| **214-220** | **Panels — per m², minimum 0,5 m²; floor-standing feet and fixing kits on p.214** |
| 225-227 | Shelves with back panel |

## Volume 4 — Home Elements

Not kitchen. THE 50's wall system, Mobilis, Dressup, Gap, Williamsburg
workstations and sideboards, coffee tables, tables, chairs. Relevant only if a
project puts Cesar furniture beside the kitchen.

## Volume 5 — Bathroom Collection

A separate price list on its own edition (April 2026). Maxima/Intarsio, Unit and
Ondula base units, end elements and customisations, tops, washbasins, handles
and grip recesses, mirrors. **Its own price bands and delivery times** — do not
read a band number across from a kitchen page.

---

## The rule this file exists for

> **A code absent from the book you have is not a code absent from the book.**

Three times on 2026-08-26 a fact was called missing when it was only in another
volume: the glass door's frame section, and `DZAK22` / `DZAC00` twice. Before
recording that Cesar does not print something, **name which volume was
searched**, in the note itself, so a later reader can tell a real absence from an
absent book.

### And the sharper version, learned the next morning

**The book you do not have may be on your other desk.** `sources/factory/` is
git-ignored: the shelf does not travel with the code, and **the two machines can
hold different catalogs with nothing saying so.** Volume 3 was not missing from
the project — it was on the laptop, which is why an extract from it
(`sources/raw_dump/Linear_Elements_Source_Extract_v0.1.md`) had been in this
repository for nine days while the office Mac searched a book that could not
contain the answer.

**`ls -la sources/factory/` at the start of every session.** Do not assume the
shelf; look at it. If the two machines differ, say so out loud — which editions
each holds is a fact about the project, not a nuisance.

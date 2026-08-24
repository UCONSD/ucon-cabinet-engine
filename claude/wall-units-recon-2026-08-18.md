# Wall Units — source-verified reconnaissance (2026-08-18)

Companion to `claude/ucon-cabinet-engine-status.md` §"NEXT SESSION — Wall
Cabinets". Everything below is READ FROM THE SOURCE PDF
(`CESAR - 2 Kitchen System.pdf`), page numbers **printed** (PDF = printed + 2).
Trust level: SOURCE.

**Landed in the repo (core 0.24.0, 141 checks):** the whole chapter is in
`catalog_map` as 24 section rows, and the picker now shows a class it holds
nothing in. No wall unit is extracted or buildable yet.

## Section pages (printed p.205 index, verbatim)

| printed | section |
|---|---|
| 211 | Wall units H. 36 |
| 213 | Dish–drainer units H. 36 |
| 214 | Wall units H. 48 |
| 217 | Dish–drainer units H. 48 |
| 219 | Wall units H. 48 with Virgola hood |
| 221 | Wall units H. 60 |
| 224 | Dish–drainer units H. 60 |
| 226 | Wall units H. 60 with Virgola hood |
| 227 | Wall units H. 60 with Virgola No Drop hood |
| 228 | Wall units H. 72 |
| 232 | Dish–drainer units H. 72 |
| 234 | Wall units H. 72 with Virgola hood |
| 236 | Wall units H. 72 with Virgola No Drop hood |
| 238 | Wall units H. 84 |
| 241 | Dish–drainer units H. 84 |
| 243 | Wall units H. 84 with Virgola hood |
| 244 | Wall units H. 84 with Virgola No Drop hood |
| 245 | Wall units H. 96 |
| 248 | Dish–drainer units H. 96 |
| 250 | Wall units H. 96 with Virgola hood |
| 251 | Wall units H. 96 with Virgola No Drop hood |
| 252 | Wall units H. 120 |
| 255 | Wall units H. 120 with Virgola hood |
| 256 | Wall units H. 120 with Virgola No Drop hood |

**24 sections**, of which **11 are hood variants** (Virgola / Virgola No Drop).
Chapter ends at printed 256; printed 257 opens the "Unit" chapter.

## Code grammar — `P` + family letter + width index + type suffix

**Confirmed by direct read only:** `PB` = H.36 (p.211), `PE` = H.72 (p.228),
`PG` = H.84 (p.238). The letters for H.48 / H.60 / H.96 / H.120 are NOT read
yet — do not assume C/D/F/H.

**Width index is a LOOKUP, never arithmetic.** Observed rounding is irregular:

```
15→01  30→03  45→05  60→06  75→07  90→09  105→10  120→12  150→15  180→18  240→24
```

**Type suffix is not stable across families — this is the load-bearing fact.**

- `04` at H.36 = *compound wall unit, 2 modules side by side, 1 top-hung door*.
- `04` at H.72/H.84 = *2 stacked top-hung doors* (H.72 splits 36+36, H.84 splits
  36+48).
- `30` inside H.72 alone = *pull-out door* at W.15 (PE0130) but *2 doors* at
  W.60/W.90 (PE0630/PE0930).

So the suffix is not decodable even within one family. Registry rows only.

## printed p.211 — Wall units H. 36 (the first extraction target)

All d.35. Three opening kinds, 17 codes, no side-hinged door anywhere on the page.

- **Top-hung door** (`PB..00`) — W. 45/60/75/90/105/120 → PB0500 PB0600 PB0700
  PB0900 PB1000 PB1200
- **Push-up door** (`PB..10`) — W. 60/75/90/105/120 → PB0610 PB0710 PB0910
  PB1010 PB1210. Notes: *interior Valencia handle*, *no Push–pull device*.
- **Bottom-hung door** (`PB..25`) — W. 45/60/75/90/105/120 → PB0525 PB0625
  PB0725 PB0925 PB1025 PB1225

Surcharge lines on the page (companion-ref candidates): Servo Drive mechanism
554, Power adapter 224, Valencia handle 23.

## printed p.212 — H.36 compound (NOT in the first pass)

`04` 2 modules (45+45, 60+45, 60+60, 60+90, 90+90 → W.90…180);
`34` 3 compartments, never smaller than 30 cm, top-hung;
`44` same, push-up. Widths to 240. Asterisked widths restrict door finishes
(metal, Noce Sgubbiato, Fenix NTA, melamine W.240, Unicolor list). Compound
units carry INTERNAL PARTITIONS — new geometry, deliberately deferred.

## printed p.228 (H.72) and p.238 (H.84) — structurally identical

| type | H.72 | H.84 |
|---|---|---|
| pull-out door, W.15 | PE0130 | PG0130 |
| 1 rh or lh door | PE0131, W.15/30/45/60, 1 shelf | PG0131, W.15/30/45/60, 2 shelves |
| 2 doors | PE0630/PE0930, W.60/90, 1 shelf | PG0630/PG0930, W.60/90, 2 shelves |
| 2 top-hung doors | PE..04, W.45–120, split 36+36 | PG..04, W.45–120, split 36+48 |

Surcharges: Servo Drive lower 554, Servo Drive upper 1.107, Power adapter 224.
On compound pages the Servo Drive line is split ≤120 = 554 / >120 = 1.107.

## Overall height with N_Elle: H + 2,2

Every wall page carries a second annotated elevation labelled `N– Elle` with an
overall height of **H + 2,2 cm** — 38,2 at H.36; 74,2 at H.72; 86,2 at H.84.
`N_Elle` is its OWN chapter (printed p.321; framed-door variant p.397), i.e. a
front programme, not a handle accessory. The wall pages themselves are headed
Maxima / Intarsio. RECORDED, NOT IMPLEMENTED — the +22 mm must not be baked
into the wall-unit height until the N_Elle chapter is read.

> **CORRECTION 2026-08-23 (rule 9 — added, not erased).** The N_Elle figures are
> NOT PRINTED ON THE PAGE. `pdftotext -bbox` puts them at 7,5 pt over the
> perspective drawing on every wall page; rendering exactly that box at 400 and
> 600 dpi shows blank paper. They are white text or a hidden layer in the PDF —
> in the file, not in the book. See `claude/findings-2026-08-23.md`.

## The 5 cm closing strip rule — narrower than remembered

Verbatim, printed p.11 ("overall dimensions of adjacent tall and wall units"):

> If a rh or lh wall unit with a "D" handle is installed adjacent to a tall unit
> or a wall, it is advisable to fit a closing strip of at least 5 cm so that the
> wall unit can be fully opened. Alternatively, use wall units with top–hung,
> push–up or horizontally–folding doors.

Two consequences:

1. The rule bites only on **rh/lh doors with a "D" handle** — not on every wall
   unit. It is conditional on the handle, which is an order axis outside the
   code.
2. **printed p.211 is entirely the rule's own escape hatch** (top-hung, push-up,
   bottom-hung). So the first page extracted needs no plan-changing rule at all.
   The rule first bites at H.72/H.84, where `..31` / `..30` rh-lh doors appear.

## Other observations

- Electrical diagram (printed p.16) puts the led-bar/socket height for wall
  units at **132 cm**. A hint about hanging height, not a rule.
- Height conversion table (printed p.17) lists the catalog's height family set:
  6, 10, 36, 39, 48, 58,5, 60, 66, 72, 78, 84, 96, 120, 138, 198, 210, 222, 234.

## Decisions taken this session

1. **Z placement** — a wall unit is placed by its **bottom edge at an
   above-finished-floor value**, a project default (M1.6), overridable per unit.
   Not a catalog fact. Proposed default 1400 mm (corroborated loosely by the
   132 cm led-bar height); PLANNING until the real kitchen confirms.
   NOT IMPLEMENTED YET — the generator still floor-snaps.
2. **Hood variants (Virgola / Virgola No Drop)** — all 11 sections are in
   `catalog_map` as **`excluded`**, dated 2026-08-18, reason: "a hood is chosen
   per POSITION, not per page" (same treatment as printed p.47).
3. **First extraction** — printed **p.211** (H.36), then one of the tall
   families. Recommendation: **printed p.238 (H.84)**; the flip condition is
   whether 545 Avenida Primavera has a soffit or H.198 tall units, which would
   favour H.72 (printed p.228).

## Open, not yet decided

- **Push-up symbol.** Top-hung and bottom-hung are covered by the existing
  hinge-axis rule (base on the hinge axis, apex on the opening edge) — top-hung
  is the exact mirror of the dishwasher Λ. **Push-up is not a hinged door** and
  the existing rule does not describe it. Needs its own convention; do not
  improvise one during extraction.
- **Family letters** for H.48 / H.60 / H.96 / H.120. *(All read by 2026-08-23:
  PC / PD / PF / PJ.)*
- Whether `Servo Drive mechanism` / `Power adapter` become `companion_refs`
  (contract v1.3) or stay order-axis surcharges.

## Repo change log for this session

- `core 0.23.0 → 0.24.0`.
- `90_palette.rb` — the picker's class level is no longer derived from the
  registry alone. `classes()` merges the classes we hold with the classes the
  map names, `autoAdvance` counts both, and a class we hold nothing in is a
  navigable button badged *catalog only*. Without this the wall chapter was
  literally unreachable: with one extracted class the picker auto-advanced past
  the class level and the grey rows never rendered.
- `registry/cesar/_manifest.json` — 24 wall sections, the grammar caution on
  H.36, "family letter not read" on H.48/H.60/H.96/H.120, page detail for the
  four pages actually opened (211, 212, 228, 238), 11 hood sections excluded.
- `tools/test_contract.rb` — 5 new checks (136 → 141).

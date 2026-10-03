# [7612-S4] Open end units W.20 into the registry and the picker

**Status:** ready for session
**Epic:** Open units in the picker (7612 Hillside Dr pantry) - S4 of S4..S7, run in order
**Date:** 2026-10-03

---

## 1. Intent

The 7612 pantry recon (Project doc `claude/recon-2026-10-03-7612-pantry-open-units.md`) needs every Cesar
open element findable in the picker, so Andriy can choose the pantry layout from the catalog instead of from
memory. Printed p.450-452 of the Kitchen System ("2.2 cm thick open end units") are mapped in `catalog_map`
as `not_extracted`. This story takes them whole: a 20 cm wide open end unit for every base and tall height,
three single depths and four combined depths. Catalog fact, not a one-off: it goes in the registry, verified
against the page (domain rule 1). Demand: the end of the pantry run beside the door casing.

---

## 2. Input/Output matrix

| # | Input | Expected output |
|---|---|---|
| 1 | Picker: chapter "Fillers, end elements and open units" | A new level for the end units, grouped by height family; the grey "not extracted" row for p.450-452 is gone |
| 2 | Base H.39 / H.60 / H.78 / H.84 rows (printed p.450-451) | Every printed code present: d.37,5 / 64,5 / 69,5 and, where printed, the combined 75 / 102 / 107 / 129 |
| 3 | Tall H.138 / 198 / 210 / 222 / 234 rows (printed p.452) | Three codes each (d.37,5 / 64,5 / 69,5), every one as printed - including the irregular ones (`F20250`, `C20251`, `F90205`): copied, never "corrected" |
| 4 | Build any single-depth code | Open box W 200, depth and height from the row/family, front `none`, joins its height family like `open_tall_*.json` |
| 5 | A combined-depth code (75 / 102 / 107 / 129) | In the picker and orderable; built or held not-buildable - the session decides and writes why on the row |
| 6 | Price column 3, 9, 11 | "-" kept as absent, not 0 |
| 7 | The "* No Fenix NTA for D. 129" footnote and the Unicolor list beside it | Kept as a note on the d.129 rows |
| 8 | Same code printed on two pages | Loader refuses or the check catches it - no silent overwrite |

---

## 3. Acceptance criteria

- AC-1 - `catalog_map` entry for p.450-452 is `extracted`, dated, the count of codes stated.
- AC-2 - The three suites green under `/usr/bin/ruby` 2.6 via `build/go.sh`; the census checks (code count, section count) are updated, not loosened.
- AC-3 - `claude/repo-state.md` registry row and the 7612 card get one dated line each.

---

## 4. NOT-list

- DO NOT touch the 7612 model or run an ARMED probe; checking the picker is a read-only probe at most.
- DO NOT change `open_*` files of printed p.455-456 or their codes.
- DO NOT invent geometry for the combined depths that the page does not print.
- DO NOT change the contract (`20_contract.rb`), `main.rb` or the palette layout beyond what a new section needs.
- DO NOT extract any other page "while there".

---

## 5. Non-functional

_none_

---

## 6. Files to read first

| Path | What to look at | Why |
|---|---|---|
| `sources/factory/CESAR - 2 Kitchen System.pdf` | PDF 452-454 (printed 450-452); render, then text layer | The source |
| `registry/cesar/open_tall_222.json` | whole file | Shape of an open unit joining its family |
| `registry/cesar/_manifest.json` | `catalog_map` entry "2.2 cm thick open end units" | To flip and date |
| `src/ucon_cabinet_engine/core/90_palette.rb` | ~322-351, ~640-730 | How the chapter tree and class labels pick up a section |
| `claude/rules.md` | domain rules 1, 4, 5 | Code grammar is per family |

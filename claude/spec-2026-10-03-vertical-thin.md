# [7612-S6] Vertical Thin and its bottle racks into the registry

**Status:** ready for session
**Epic:** Open units in the picker (7612 Hillside Dr pantry) - S6 of S4..S7
**Date:** 2026-10-03

---

## 1. Intent

Kitchen System printed p.464-470: Vertical Thin, an open niche 24 or 30 wide, d.35, fitted BETWEEN two tall
units of the same height, plus two bottle racks (`900280` W.24 10 spaces, `900281` W.30 15 spaces). Two
groups by base height: "for 78 cm high base units" (H.198 `C7`, H.210 `C5`, H.222 `CI`, H.234 `C0`) and "for
84 cm high" (H.210 `CQ`, H.222 `C4`, H.234 `CW`); each with a bottle-rack variant (…0260 / …0360) and a
two-shelf variant (…0261 / …0361). Only bands 5, 6, 8 are priced; RR oak is band 8 here (printed p.457).
The `catalog_map` row for Thin says p.461-468 not extracted. Wanted in the picker as a possible wine niche.

---

## 2. Input/Output matrix

| # | Input | Expected output |
|---|---|---|
| 1 | Picker, open units chapter | Vertical Thin level, grouped by height and by base 78 / 84 |
| 2 | Every code on printed p.466-469 | Present with W, d.35, height, its variant (bottle-rack space or 2 shelves), bands 5/6/8, "surcharge for lights" as printed |
| 3 | Bottle racks `900280` / `900281` (p.470) | Held as accessories; offered with the …0260 / …0360 codes, never forced |
| 4 | Mini Noor lights `991M10/11/20/21` (p.463) and the L-profile (p.465) | Recorded as printed; if no code is printed for the L-profile, said so - not invented |
| 5 | Printed rules (p.464): between two talls only, same height, never an end unit, never stacked | Written on the type as rules; refusals implemented only where the engine can check them today, the rest recorded as owed |
| 6 | Build | Open envelope W x 350 x H, front `none` |
| 7 | Prefix shared with other tall sections (`C0`, `CQ`) | Codes decode only via their explicit rows (domain rule 5); a collision fails a check, it does not overwrite |

---

## 3. Acceptance criteria

- AC-1 - `catalog_map` Thin entry updated: which pages are now extracted, dated; p.457 / 460-461 status unchanged.
- AC-2 - Suites green; census checks updated.

---

## 4. NOT-list

- DO NOT change Horizontal Thin (`thin_horizontal_*.json`).
- DO NOT build placement logic that finds "the two talls"; recording the rule is enough.
- DO NOT touch the 7612 model.

---

## 5. Non-functional

_none_

---

## 6. Files to read first

| Path | What to look at | Why |
|---|---|---|
| `sources/factory/CESAR - 2 Kitchen System.pdf` | PDF 459, 465-472 (printed 457, 463-470) | The source |
| `registry/cesar/thin_horizontal_h39_base78.json` | whole | The Thin precedent, its notes and `stands_on` |
| `registry/cesar/_manifest.json` | `catalog_map` "Thin" entries | To update |

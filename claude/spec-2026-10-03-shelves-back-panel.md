# [7612-S5] Shelves with back panel + concealed supports into the registry

**Status:** ready for session
**Epic:** Open units in the picker (7612 Hillside Dr pantry) - S5 of S4..S7
**Date:** 2026-10-03

---

## 1. Intent

Linear Elements printed p.225-228 sell a pantry-wall system we do not hold: a 1,8 back panel by the square
metre (`MNSSCH018`, max L 240 per the table, "Maximum length: 200 cm" per the text) and a 2,2 shelf d.38 by
the linear metre (`MNS022038`, max 200) that fits a concealed support INTO the back panel. Printed p.228
prices the supports: `990307` for the back panel, and `990315` / `990316` / `990317` for walls, plus the
breakfast-bar bracket `990331`. This closes the old finding "MNS022038 has no fixing"
(`findings-2026-08-27-shelf-fixings-rules.md`) - with a contradiction to record, not resolve: the shelf is
sold at d.38, the supports are "recommended max. 35 cm". That contradiction becomes Elda Q51.

---

## 2. Input/Output matrix

| # | Input | Expected output |
|---|---|---|
| 1 | Picker: Linear Elements / Shelves | `MNSSCH018` present as a sheet ordered by W and H (same grammar as `panels_linear_elements.json`) |
| 2 | `MNS022038` already in `shelves_linear_elements.json` | NOT duplicated; the back-panel use is recorded on it (note or companion), the session picks which and says why |
| 3 | Supports `990307`, `990315-317`, `990331` | Held as order-only articles with points and "2 per 100 cm" as printed; `990315` already present stays as is |
| 4 | Max length: table says 240, text says 200 | Both recorded; the smaller one is the one the engine enforces; the conflict is named in the note |
| 5 | Shelf d.38 on `990307` | Allowed, with a remark naming "recommended max. 35 cm" (p.228) and Q51; never refused, never silent |
| 6 | Price bands for this chapter (p.225-226) | As printed: RR veneers in band 6, Trama in band 8 |

---

## 3. Acceptance criteria

- AC-1 - `catalog_map` gets an entry for printed p.225-228 of Volume 3, `extracted`, dated; `source_pdf` per section is Linear Elements.
- AC-2 - The findings note of 2026-08-27 gets a dated ADDED correction (rule 9), not an edit.
- AC-3 - `docs/Elda_Open_Questions_v0.1.md` gets Q51 (unsent). Suites green.

---

## 4. NOT-list

- DO NOT change existing shelf codes, their prices or their fixing rules.
- DO NOT draw supports; they are order lines only.
- DO NOT touch the 7612 model.
- DO NOT extract Dressup Line (p.229-231).

---

## 5. Non-functional

_none_

---

## 6. Files to read first

| Path | What to look at | Why |
|---|---|---|
| `sources/factory/CESAR - 3 Linear Elements.pdf` | PDF 227-230 (printed 225-228) | The source |
| `registry/cesar/shelves_linear_elements.json` | whole | Where `MNS022038` and `990315` already live |
| `registry/cesar/panels_linear_elements.json` | grammar + one block | Sheet ordered by W x H |
| `claude/findings-2026-08-27-shelf-fixings-rules.md` | the "no fixing for 38" claim | To correct by addition |

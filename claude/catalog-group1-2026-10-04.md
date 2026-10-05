# Catalog recon, group 1 — what was generated with confidence (2026-10-04, core 1.9.27)

Andriy asked for a recon of what is not yet extracted and not in the picker, split into
(1) safe to generate, (2) needs looking at and modelling, (3) not now — and then to
generate group 1. The recon itself lives in the claude.ai Project
(`claude/recon-2026-10-04-catalog-gaps.md`); this note is what landed in the registry.

## Landed: 230 codes, 1332 -> 1562

| batch | section | printed | codes | file |
|---|---|---|---:|---|
| 1 | Tall H.198 for base unit H.78 | 102-109 | 39 | `tall_h198_base78.json` (new, joins family Tall H.198) |
| 1 | Tall H.210 for base unit H.78 | 117-118 | 14 | `tall_h210_base78.json` |
| 1 | Tall H.222 for base unit H.78 | 137-142 | 34 | `tall_h222_base78.json` |
| 1 | Tall H.234 for base unit H.78 | 156-161 | 34 | `tall_h234_base78.json` |
| 2 | Base units H.48 | 29 | 30 | `base_h48.json` |
| 2 | Top elements H.48 | 171 | 9 | `tall_top_h48.json` (new) |
| 2 | Glass wall H.60 / H.120 | 313 / 315 | 6 | `glass_wall_h60.json`, `glass_wall_h120.json` (new) |
| 3 | Hide & Seek H.198 / H.210 / H.234 | 200 / 201 / 203 | 51 | `hide_seek_h198/h210/h234.json` (new), lookup only |
| 4 | Wall units H.36, compounds | 212 | 13 | `wall_h36.json` — the section is now whole |

How: every code, width and depth checked by script against the text layer (scripts in
`~/dev/_claude/g1/`, not in the repo); elevations and glyphs spot-checked on renders
(p.29, p.106, p.117, p.137, p.171 N_Elle crop, p.201 / p.203 door codes, p.212). Every
tall stack sums to its family height in both executions; a probe-free Ruby check built
attributes and the front stack for all 121 tall codes with zero errors. Picker labels
added for the two new type keys (`tall_door_drawer_jumbo`, `tall_doors_drawer_jumbo`).

## Read and deliberately NOT held

- **Single-elevation 19,5 / 55,5 positions** on every tall-for-H.78 page (C57/C67,
  C37/C47, C07/C97, C77/C87 xx64, C48655, C98655, C88654): one profile, no gola column,
  fronts that do not sum to the column — the printed p.41 / C68654 shape.
- **printed p.109 position 2 (C83659)**: at H.198 the custom door is TOP-HUNG, where the
  H.210-234 twins print an rh or lh door.
- Corner tall units (Elda Q7b), the wall-hung H.132 units (C61691, C81691).
- **Hide & Seek door codes copied as printed and flagged**: `CRM550` (H.210) and `C9H550`
  (H.234) break the page pattern (CHHS50 / CFMS50 elsewhere). 200-dpi crops confirm the
  print. Possible misprints — ask Elda before ordering, as with Q37.

## Moved from group 1 to group 2 after reading the registry's own notes

The recon's first draft overclaimed. These were already stopped, with reasons, and stay so:
printed p.26-27 and p.30-31 (low base, D-prefix, the unnamed 36,5 / 45,5 profile),
p.41 (grammar does not decode, 19,5 + 55,5 = 750), p.45 (suffixes 90/91, Q4), p.49
BK0100 (pull-out mechanism), USA p.424-426 (fixed filler, three-front fridge doors),
glass tall and glass top elements p.308-312 (new families; the glass tops are HUNG where
plain tops are 'without fixings' — a question, not a twin).

## Census moves (all dated in `tools/test_contract.rb`)

1332 -> 1562 codes; no-hung 315 -> 488; cuttable 717 -> 830; jumbo refusals 274 -> 381;
interior-drawer 28 -> 32; framed glass 9 -> 15; finish blocks 22 -> 26; compound rows
57 -> 70; top elements 19 -> 28 (side-hinged now at H.48 and H.60).

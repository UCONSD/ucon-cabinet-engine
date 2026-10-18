# Drawing standard for wall-panel sets (AP Capital) - audit and decisions, 2026-10-17

Andriy 2026-10-17: "three sets look like seven different people made them". This file is the audit of the three issued
sets and the standard they move to. One writer + one style file; every room = data.

## Executive summary
- Three sets, three writers: REC-LAU v1.1 (`wall_drawing_set.rb` / `ap_drawing_set.rb`, 16 sheets), Main Kitchen v1.0
  (`mk_drawing_set.rb`, 40 sheets), ML Foyer v1.0 (`foyer_drawing_set.rb`, 23 sheets). Same title block and template
  (`ucon_sheet_template.rb`), everything else drifts: sheet list and names, key plan, detail pages, colours, legend, texts.
- Decisions (Andriy 2026-10-17): detail sheets = SECTIONS FROM THE MODEL with dimensions; A-100 key plan ALWAYS, FROM THE
  MODEL (a schematic of the walls from the survey when the model has no plan; the architect's plan only as a reference
  image); REISSUE Main Kitchen and Foyer in the standard (v1.1), REC-LAU at its next revision.
- Target: `tools/layout/room_drawing_set.rb` (UCON::RoomSet) + `tools/layout/drawing_style.json`. FoyerSet is the base
  (snapshot-driven, `{{tokens}}`, section detail pages); MKSet's kitchen parts (windows, single-leaf doors, niche,
  vector key plan) come back as data-driven options.

## Audit
| Item | REC-LAU v1.1 | Main Kitchen v1.0 | ML Foyer v1.0 | STANDARD |
|---|---|---|---|---|
| Writer / data | WallSet: one wall JSON, generators | MKSet: snapshot read from the model | FoyerSet: snapshot from the generators (RoomSnapshot) | RoomSet: snapshot (RoomSnapshot; MK snapshot until the kitchen walls are generator JSONs) |
| Sheets | 16 | 40 | 23 | by rule, below |
| Cover status line | "For factory review - Rev 1.1" | "For review - Rev 1.0" | "For review - Rev 1.0" | from tags.Status: "For review - Rev X" |
| G-001 | LEGEND & GENERAL NOTES | LEGEND, NOTES & SHEET INDEX | same as MK | LEGEND, NOTES & SHEET INDEX |
| A-100 key plan | none | vector plan from the model | architect plan image | always; from the model, else wall schematic from the survey; architect image = reference only |
| A-10x existing | elevation + plan cut at 1200 | elevation, several short walls per sheet | elevation | elevation; plan cut where the model has a plan |
| A-20x frames | "SUBFRAME LAYOUT", outlines, no fill | "SUBFRAME + CLIPS - <wall>", wood fill, frame bubbles | same as MK | MK / Foyer |
| Clips | inside A-202 "CLIP LAYOUT & DETAIL" | A-210 CLIP DETAIL & ORDER | A-210 | A-210 |
| A-30x panels | white panels, plan cut below | light fill, coloured openings, window liners | + stone, L-liner, TM cabinet outline | Foyer |
| Door A-50x | DOOR D01 1:20 / 1:10 | DK1, DK2 1:20 / 1:10 | OB2 1:30 / 1:20 (double) | same layout, scale picked by door size |
| Details A-51x | none | hand-drawn images + iso | model sections 1:5 + dims (+ table) | model sections + dims; optional small iso from the model |
| 3D A-601 | one view | finished + frames | finished + frames | two views |
| Schedules | A-701, A-702 | A-701, A-702, A-703 cut list & sheets | same as MK | with A-703 |
| Drilling | "PANEL DRILLING n", 1:15 | "DRILLING P01…P11 (n)", 1:20 | same as MK | MK / Foyer |
| Colours | none | PAN_FILL, WOOD, STONE, GLASS, DOORF, NICHEF, CLADF in the writer | + LINERF | one palette in drawing_style.json |
| Legend | fixed list | fixed list | fixed list | built from what the set draws (an entry per element type present) |
| Numbers in texts | some `{jamb}` fills | typed in the JSON | `{{expr}}` tokens from the snapshot | tokens only; a typed number in a text = defect |
| Questions | red number + bubble | same | same | same (unchanged) |
| Liner at openings | - | flange 35.2 + strips B / A, joints show the wall | flange 56 to the frame, no strips | Foyer (variant 2) - kitchen to be rebuilt |

## Sheet list rule (STANDARD)
G-000 cover · G-001 legend, notes, index · G-002 questions · A-100 key plan · A-10x existing walls · A-20x frames + clips
per wall · A-210 clip detail & order · A-30x panel layout per wall · A-50x door + door details per door · A-51x details
(sections) · A-601 3D · A-701 panels · A-702 frames · A-703 cut list & sheets · D-xx drilling (BACK VIEW). Codes and titles
from the style file; a page exists only if the room has its content.

## Plan
1. RoomSet + drawing_style.json from FoyerSet; Foyer rebuilt with it = the same pages as v1.0 (page-by-page compare).
2. MK through RoomSet from its snapshot: windows, single doors, niche, vector key plan as options; compare with MK v1.0.
3. Kitchen: section scenes for the details (ARMED in the kitchen model), liners widened to variant 2 (frames / liners in
   the kitchen model - the kitchen is not generator-based yet), questions re-tokenised.
4. Reissue MK v1.1 and ML v1.1 (Documents, no overwrite). REC-LAU at its next revision. Retire MKSet / FoyerSet / WallSet.

## Status 2026-10-17 (evening)
- Steps 1-4 done for Main Kitchen and ML Foyer: both released as v1.1 from UCON::RoomSet (probes 800 / 801), see
  handoff-2026-10-17-ap-mk-v1.1-standard.md. The kitchen is generator-based now (six wall JSONs), liners widened.
- Left: REC-LAU at its next revision; retire MKSet / FoyerSet / WallSet after it.
- 2026-10-17 later: REC-LAU in the standard too (v1.2); all three sets reissued as v1.2 with the door swing per the
  European convention (base on the hinges, apex at the handle) - the same rule as the cabinet engine's Drawing_Spec.
  MKSet / FoyerSet / WallSet are no longer used by any AP Capital set.

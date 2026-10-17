# Handoff 2026-10-16/17 — AP Capital, ML FOYER: panels, frames, clips, door, liners, stone, closets, LayOut v1.0

## Executive summary
- RELEASED v1.0 FOR REVIEW (2026-10-17, probe 784): `~/Documents/AP_ML_Drawings_v1.0.layout` / `.pdf` (23 sheets),
  `~/Documents/AP_ML_drilling_panels_TM_v1.0.csv` (factory, 147 recesses), `~/Documents/AP_ML_drilling_frames_CNC_S_v1.0_UCON-only.csv`
  (UCON CNC - NOT to the factory). Snapshot, cut list, key plan: `~/dev/_claude/ap/ml/release_v1.0/`.
- Model `~/Documents/AP_ML_Foyer_v1.skp` (saved 14:18:37 PDT after ARMED 779): walls B + A (UCON survey), 18 panels, 28 frames,
  147 clips, drilling, Office double door, L-liners, stone plinth, TM closet cabinets (envelopes), section planes + scenes
  FOY-05..FOY-11. Model = generators, 0 differences.
- Open: Q1–Q9 on G-002 (TM: long panels, liners, P56 210, door, back-view drilling, cabinet heights; Site: FFL, stone).
- Not committed (Andriy): list at the end.

## Decisions (Andriy)
- 10-16: keep only the walls; survey = UCON; z 0 = subfloor, FFL +57.15 (as Main Kitchen); long panels one piece (Q1);
  numbering as TM 252502 rev 4 (B P47–P55, A P56–P64); A-100 = Passione plan crop (reference).
- 10-16: Office double door built as Main Kitchen DK1 ("to the joint"): 2 claddings 1049, joint 10, panels over the frame rebated 10.
- 10-16: openings OA1 / OA2 / OB1 get an L-liner as the kitchen windows, leg against the reveal.
- 10-16: stone plinth by others as Main Kitchen (20 thick, top 260.35 = FFL + 203.2, notch 10); panels and frames stand on it.
- 10-17: walls are fixed, panels follow. The two TM shoe cabinets DIFFER IN HEIGHT: each fits its niche (head - 3, sides 3):
  NB 634 x 3046.85 FFL, NA 642 x 3039.85 FFL (TM drawing 3049 / 3046 - NA 3.15 too high). The panel over a closet starts
  cabinet top + 10 (P52 3114, P61 3107). Shown on A-301 / A-302 / A-513 and asked in Q9.
- 10-17: NO RAW WALL IN ANY PANEL JOINT. Band cut at every vertical panel joint (6" stile behind each joint); plywood LINTEL
  over the closets and the door; pier frames run to the closet / door jambs (jamb_setback 0). Liners: variant 2 - flange
  widened 35.2 -> 56 = to the frame, corners mitred, NO strips B / A. Build check: `panels.no_wall_in_joints` +
  `WallPanels.joint_gaps` (empty on both walls).
- 10-17: TM is slow with answers - cabinet points go as red notes on the sheets, the question list stays short.
- 10-17: from now on: one ARMED + Save per draft / release, not per decision (changes verified offline first: tests,
  joint check, clash check, dry).

## Code (all pure Ruby 2.6-safe except the SketchUp builders)
- `tools/wallpanels/wall_panels.rb`: band layout (R1 solid strip, R2 band cut at every panel joint, R3 per-jamb setback),
  LINTEL over no-liner openings, closet panel = cabinet top + joint (`cab_top`: fit_niche or TM height), `joint_gaps`
  check, frame first_id, narrow-panel clip column, grouped rails, raised bottom clip row onto a frame above.
- `tools/wallpanels/room_snapshot.rb` (new): room + wall JSONs -> snapshot, factory CSV, UCON CNC CSV, cut list. Sheet
  texts carry their numbers as `{{expr}}` tokens resolved against the snapshot (helpers in RoomSnapshot::Ctx); a failing
  token stops the build - no number typed by hand.
- `tools/wallpanels/room_extras.rb` (new): door (DK1 profile, double), liners (wide flange, mitred head), strips (only if
  liner.strips), stone (levels.stone), cabinets as boxes; `build` for ARMED.
- `tools/wallpanels/walls/AP_ML_Foyer.json` (room: sheets, questions Q1–Q9, notes, details A-511..A-513 with dims),
  `AP_ML_Foyer_B.json`, `AP_ML_Foyer_A.json` (B frames S01–S14, A S15–S28).
- `tools/layout/foyer_drawing_set.rb` (UCON::FoyerSet, copy of MKSet): liners / stone / cabinets on the elevations, double
  door pages at 1:30 / 1:20, 'sections' detail pages (two scene crops 1:5 + dims + optional table). DEBT: MKSet / FoyerSet /
  bath writer share most code - see "Drawing standard" below.
- `tools/test_wallpanels.rb`: foyer checks incl. no raw wall in joints and flange = frame setback. Linux ruby 3.0:
  wallpanels 421/0, contract 711/0, mep 73/0. macOS 2.6: to run (commands below).

## Learned (bridge)
- An ARMED run COMMITS even when it raises - every STOP check before the first change.
- Erasing scenes can leave objects hidden (753); check `hidden?` after any ARMED that touches scenes.
- `model.modified?` is true inside any probe; "saved after the last ARMED" = .skp mtime vs the last ARMED `at` in probe_log.txt.
- Section planes are top-level entities named FOY-05..; a rebuild erases only groups / components named `FOY-A` / `FOY-B` (775+).
- Backing frames are ComponentInstances, not Groups (772 failed on that).

## FUTURE - widen the liners everywhere (Andriy 2026-10-17)
- Do the same as the foyer EVERYWHERE, the Main Kitchen windows included (there: flange 35.2 + strips B 6 x 34 / A 6 x 17,
  frame 46 behind the panel edge - joints crossing the 35.2..56 zone show the wall). Needs the kitchen wall JSONs, a rebuild
  of the kitchen model and a reissue of the kitchen set (A-511, Q8). Run `joint_gaps` on every room.

## Drawing standard (Andriy 2026-10-17: three sets look like different people made them)
- Proposal: one data-driven writer + one style file (colours, line weights, legend entries, sheet list rules, detail
  page types), every room = data. Then reissue Main Kitchen, Foyer (and the next rooms) from it. See summary-2026-10-17.

## Commit (Andriy, office or laptop - the repo is ~/dev/ucon-cabinet-engine)
- Files: tools/wallpanels/wall_panels.rb, room_snapshot.rb, room_extras.rb, walls/AP_ML_Foyer.json, AP_ML_Foyer_A.json,
  AP_ML_Foyer_B.json, tools/test_wallpanels.rb, tools/layout/foyer_drawing_set.rb, this handoff.
- NOT claude/README.md: it also holds another session's lines (sinks); its line for this handoff goes with that commit.
- Message: ~/dev/_claude/commit_msg_ml_foyer.txt

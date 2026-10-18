# Handoff 2026-10-17 - AP Capital: Main Kitchen on the generator, MK v1.1 + ML v1.1 in the drawing standard

## Executive summary
- RELEASED FOR REVIEW (probes 800 / 801), ~/Documents, nothing overwritten:
  - Main Kitchen v1.1: AP_MK_Drawings_v1.1.layout / .pdf (40 sheets), AP_MK_drilling_panels_TM_v1.1.csv (factory, 266
    recesses), AP_MK_drilling_frames_CNC_S_v1.1_UCON-only.csv (UCON CNC - NOT to the factory). Data: ~/dev/_claude/ap/mk_release_v1.1/.
  - ML Foyer v1.1: AP_ML_Drawings_v1.1.layout / .pdf (23 sheets), AP_ML_drilling_panels_TM_v1.1.csv (147),
    AP_ML_drilling_frames_CNC_S_v1.1_UCON-only.csv. Data: ~/dev/_claude/ap/ml/release_v1.1/. Content = v1.0, new writer.
- Both sets come from ONE writer (UCON::RoomSet, tools/layout/room_drawing_set.rb + drawing_style.json) and ONE data path
  (room JSON + wall JSONs -> RoomSnapshot). MKSet / FoyerSet are no longer used for these rooms.
- Kitchen model ~/Documents/AP_MF_Main Kitchen_Breakfast.skp rebuilt by ARMED 795 (frames, clips, holes, liners from the
  generator) and 797 (section scenes MK-09, MK-10); saved after 797. Walls NOT touched (Andriy: "только стены не трогай").

## Decisions (Andriy 2026-10-17)
- Kitchen moved onto the generator; walls untouched; liners widened as in the foyer (variant 2: flange to the frame, no strips).
- Detail sheets = sections from the model with dims; A-100 always, vector, from the data.
- Architect plan screenshot: optional reference inset on A-100 only when the room JSON names files.key_plan (foyer: yes;
  kitchen: none yet; REC-LAU at its next revision).
- MK draft3 accepted ("выглядит хорошо") -> released.

## Kitchen data (new, tools/wallpanels/walls/)
- AP_MF_Kitchen.json - the room (sheets, Q1-Q11, notes, A-511..513 'sections' with dims, Rev 1.1 tags).
- AP_MF_Kitchen_W1 / W2 / A / B / C / D.json - panels GIVEN as issued v1.0 (panels.explicit), P09 / P30 glued (no
  clips), clips.fixed = the 266 issued recesses (xb / zb / xf kept to the digit), openings with liners, doors DK1 / DK2
  (jamb_y, hinge, leaf, rebate), niche, band frames local mode, first_id W1 1, W2 9, A 39, B 50, C 58, D 60 (S01-S61).
- AP_MF_Main_Kitchen.json stays as the v1.0 snapshot read from the model (history).
- Checks: panels / rebates / 266 recesses identical to v1.0; joint_gaps empty on all 6 walls; clash check clean.

## Code
- wall_panels.rb: explicit / glued panels, clips.fixed, adjacency vseams, ceil_at + ceiling steps, window SILL frames,
  band_bottom 'local', seam rails, rail packing (push, merge to 6"), short frame -> solid, pier cut at internal joints,
  LINTEL per piece, joint_gaps with the sill flange, frame-joint exemptions at LINTEL edges and ceiling steps.
- room_snapshot.rb: more {{token}} helpers, plan_wf, wall name from spec, window / niche kinds, wf-based door export,
  stone_runs.
- room_extras.rb: generalized liner (leg [la, lb], jamb / head / sill legs and flanges), strips only if liner.strips,
  levels.stone, leaf.joint, cab_top via WallPanels.
- room_drawing_set.rb: liner drawing with leg / sill; section cams / targets coerced to Float (tokens resolve to
  strings); A-703 sheet scale 1:40 -> 1:50 / 1:60 / 1:80 until the sheets fit.
- probe_bridge.rb: resolve also counts Sketchup.active_model (documents opened after the bridge start were missed).
- test_wallpanels.rb: kitchen section (452 checks, 0 failures on Linux ruby 3.0).

## Learned
- A string that is one {{token}} stays a STRING after resolve - numeric consumers must Float() it.
- After a SketchUp restart: palette "Reload probe bridge (dev)" before the first probe.
- The bridge only sees OPEN documents: the foyer probes refuse while only the kitchen is open.

## Open / next
- Q1-Q11 (kitchen) and Q1-Q9 (foyer) wait for TM / site.
- A-513 repeats the DK1 jamb plan of A-512 (accepted); Q11 bubble touches the P41 title on D-08 (as in v1.0).
- REC-LAU into the standard at its next revision. Retire MKSet / FoyerSet / WallSet after that.
- Kitchen key plan reference image: add files.key_plan if a crop of the Passione Main Level plan is wanted.

## Commit (Andriy; repo ~/dev/ucon-cabinet-engine)
- Files: tools/wallpanels/wall_panels.rb, room_snapshot.rb, room_extras.rb, walls/AP_ML_Foyer.json,
  walls/AP_MF_Kitchen.json, walls/AP_MF_Kitchen_W1.json, _W2, _A, _B, _C, _D .json, tools/layout/room_drawing_set.rb,
  tools/probe_bridge.rb, tools/test_wallpanels.rb, claude/spec-2026-10-17-drawing-standard.md, this handoff.
- NOT: claude/README.md and the other modified files (another session: sinks, MEP, core).
- Message: ~/dev/_claude/commit_msg_mk_v11.txt

## Later the same day - v1.2 of all three sets (REC-LAU, Main Kitchen, ML Foyer)
- RELEASED v1.2 FOR REVIEW into ~/Documents (probes 809 / 810 / 811b), nothing overwritten:
  AP_REC-LAU_Drawings_v1.2 (18 sheets), AP_MK_Drawings_v1.2 (40), AP_ML_Drawings_v1.2 (23), each with
  *_drilling_panels_TM_v1.2.csv (factory) and *_drilling_frames_CNC_S_v1.2_UCON-only.csv (NOT to the factory).
- DOOR SWING ON ELEVATIONS (Andriy 2026-10-17): one rule with the cabinet engine (docs/Drawing_Spec_v0.1.md, the
  European reading TM / Cesar use): BASE of the dashed V on the hinge edge, APEX at the handle edge, "HINGES" written at
  the hinge edge. v1.0 / v1.1 of the wall-panel sets drew it the US way (apex at the hinges) - superseded by v1.2.
  Doors checked: DK1 hinges right / DK2 left (from the kitchen), D01 right (from Recreation), OB2 double (outer edges).
- REC-LAU in the standard: room AP_BF_REC_LAU.json (sheet texts with tokens, Q1-Q10 as v1.1), wall JSON got name / wf /
  levels (ffl 0: Z from the FINISHED floor) / D01 scenes. Frames floor_gap 25 -> 10 (Andriy: "до уровня панелей, 10 мм
  от пола") - no raw wall in a joint; panels, clips, drilling = v1.1 (test). Model: ARMED 804e (frames S01-S15 rebuilt),
  scene "07 3D Frames" (left by the rolled-back 804b, kept). The wall JSON's own 'sheets' block = v1.1 history.
- Writer: qref per room may be null (no bubble); drilling note cites qref('drill') (MK has no drilling question - MK
  v1.1 wrongly cited Q5 = levels; fixed in v1.2); Z reference from levels.ffl (0 = finished floor); wall_t_note;
  single-panel D-title.
- Bridge lesson: a scene created in a rolled-back (non-ARMED) run is NOT rolled back and survives a Save; SketchUp
  crashed once after such a run (804b). Release / draft probes now check the last ARMED of THEIR model (807b+).
- Commit: claude/README.md is NOT in it (other session's lines) - its line for this handoff is added locally; the contract
  test passes only with it.

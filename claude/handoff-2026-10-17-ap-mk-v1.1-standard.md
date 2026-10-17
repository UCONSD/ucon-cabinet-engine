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

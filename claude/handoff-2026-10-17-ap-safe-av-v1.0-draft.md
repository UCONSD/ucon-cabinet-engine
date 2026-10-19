# Handoff 2026-10-17 - AP Capital: Garage wall to SAFE / AV rooms (SAFE-AV), v1.0 DRAFT 2 ready for Andriy's review

## Executive summary
- SAFE-AV is on the generator and in the drawing standard: wall JSON tools/wallpanels/walls/AP_BF_Safe_AV.json, room
  AP_BF_SAV_Room.json, model ~/Documents/AP_BF_Safe_AV.skp built by ARMED 813b (saved 19:35:11 after the run 19:35:06).
- Draft 2 (19 sheets) in ~/dev/_claude/ap/sav_v10_draft2/ (probe 816b). NOT released into ~/Documents - waits for Andriy.
- Release = copy probe *809* / *811b* pattern with room AP_BF_SAV_Room.json, out ~/Documents, AP_SAFE-AV_Drawings_v1.0.

## Decisions (Andriy 2026-10-17)
- Our survey governs (model 8026 x 2847, D02 Safe 946..2169, D03 AV 4185..5189, h 2542; wall 362 / 171.5).
  From TM (order 252260, GARAGE WALL TO SAFE AND AV ROOM REV3 - DISEGNO PORTE, DWG 2026-10-12) only the door profile.
- Safe opening runs to the ceiling today; lowered to the AV head 2542 by others (Q6).
- Jambs to our survey, the frame made deeper / shallower: D02 384.3, D03 193.8 (front 4 behind our panel face 44.3).
- Free spans split equally; TM leaves centred in our openings (1138 / 919 x 2494); panels 3 from the leaves; joints 10.
- Doors D02 / D03, panels P01-P14 = TM cut list numbers 1-14. Red circles on the TM PDF (2814 / 2512) ignored.
- Leaf as TM drew it (variant 1): 50 = face 38 + back step 12 x 12, veneered, no cladding, flush with the panels.
  The other AP doors (D01, DK1/DK2, OB2: leaf 43 + 3 + cladding 12) open AWAY from the panels; Safe / AV open INTO the
  Garage (toward the panels) - Daniel's list 2026-01-12 "Opens Outside", TM "A TIRARE".

## Code (commit)
- room_extras.rb: door profile 'tm_pull' (jamb body 47 + front lip 35 x 34, leaf + back step, no stops / casings /
  cladding); 'clad_inset' replaces the hard-coded 55.5 (default 55.5 - other rooms unchanged).
- room_snapshot.rb: clad_inset in clad / clad_x; doors export profile, leaf_t, leaf_step.
- layout/room_drawing_set.rb: tm_pull wording on the door sheet ("LEAF (TM)", leaf note) and in the legend.
- test_wallpanels.rb: section 11 SAFE-AV. 472 checks, 0 failures (Linux ruby 3.0).

## Learned
- THE MAC DISK IGNORES CASE: a room file AP_BF_SAFE_AV.json IS the wall file AP_BF_Safe_AV.json - it overwrote it once
  (regenerated; probe 815: model vs JSON 0 differences). Room file renamed AP_BF_SAV_Room.json.
- Read-only and dry probes run by themselves (bridge polls every 2 s); only an ARMED run needs Andriy's click + Save.
  Andriy 2026-10-17: no more "press Apply" for read-only probes.
- The model's top level holds 25 loose survey edges / faces (reveals) besides the wall group (probe 814).
- TM DWGs parse with @mlightcad/libredwg-web (npm, wasm) in the cloud container; DWGs of kitchen rev 5, REC-LAU rev.3,
  foyer rev 4 in ~/dev/_claude/ap/tm_dwg/. "door to mudroom rev 4.dwg" NOT downloaded (2 tries, not confirmed).

## Open
- Q1-Q9 (sheet G-002) to TM / site. Andriy's review of draft 2, then release v1.0 FOR REVIEW into ~/Documents.
- claude/README.md line for this handoff (README is modified by another session - add locally if the contract test asks).

## Later the same evening - draft 3 (Andriy's review of draft 2)
- Andriy: joints 10 between the panels and the door leaf (also on top); the panel rebate as on all our AP walls (rear 10,
  not TM's BATTENTE 38 x 18); the door profile moved accordingly. Cause: every other AP door opens AWAY from the panels,
  Safe / AV open INTO the Garage. Foyer OB2 checked: opens into the Office (Passione plan; the TM foyer DWG plan shows no
  swing), profile = kitchen / REC-LAU (58 / 55 / 35 / 37 / 12).
- Now: panels 968.5 / 2 x 1035.5 / 3 x 946.5 (= the 2026-10-08 draft), rows 10..2499 / 2509..2837 (joint along the leaf
  top), rebate inset 2.5 / head_inset 2.5 / depth 10, frame front -32.3 (12 behind the face, as DK1), lip depth 26,
  jambs 376.3 / 185.8. 474 checks, 0 failures. Model: dry 817, ARMED 817b (20:05:00, saved 20:05:12), 0 differences.
- Draft 3: ~/dev/_claude/ap/sav_v10_draft3/ (probe 816c). Draft 2 superseded.
- Not yet parsed: "20260701 252260 garage pannelling and doors (2).dwg" and "door to mudroom rev 4.dwg" (Gmail button
  downloads did not land; Andriy to save them).
- Draft 5 (816e): swing on the door plan sections (Andriy: "не вижу траектории открытия"). room_drawing_set.rb page_door:
  for profile tm_pull the plan view is centred to fit the swing toward the panels; dashed open leaf at 90 degrees from
  the hinge edge of the leaf face + dashed arc from the latch edge, "SWING"; the door bubble sits inside the swing.
  Other profiles unchanged (no swing on their plans yet). ~/dev/_claude/ap/sav_v10_draft5/ supersedes draft 3 / 4.

## RELEASED v1.0 FOR REVIEW (probe 818, 2026-10-17 20:29, Andriy "OK" on draft 5)
- ~/Documents: AP_SAFE-AV_Drawings_v1.0.layout / .pdf (19 sheets, = draft 5), AP_SAFE-AV_drilling_panels_TM_v1.0.csv
  (factory, 138 recesses), AP_SAFE-AV_drilling_frames_CNC_S_v1.0_UCON-only.csv (UCON CNC - NOT to the factory).
  Data: ~/dev/_claude/ap/sav_release_v1.0/. Nothing overwritten.
- Next: send the PDF + factory CSV to Daniel with Q1-Q9 (G-002); parse "garage pannelling and doors" and
  "door to mudroom rev 4" DWGs when saved.

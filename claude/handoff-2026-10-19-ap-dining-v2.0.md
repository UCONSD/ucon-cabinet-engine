# Handoff 2026-10-19 - AP Capital: DINING AREA (TM 252234) wall panels, v2.0 FOR REVIEW released

## Executive summary
- RELEASED v2.0 FOR REVIEW (probe 858, 2026-10-19 12:12), ~/Documents, nothing overwritten, v1.0 kept beside it
  (Andriy: "we release the next version, not a replacement"):
  AP_DIN_Drawings_v2.0.layout (3 675 783 b) / .pdf (2 193 948 b, 31 sheets), AP_DIN_drilling_panels_TM_v2.0.csv
  (29 847 b, factory, 388 recesses), AP_DIN_drilling_frames_CNC_S_v2.0_UCON-only.csv (24 533 b, NOT to the factory).
  Data: ~/dev/_claude/ap/din_release_v2.0/. Listing checked by probe 859 (У2).
- Model ~/Documents/AP_MF_Dining_Room.skp rebuilt by ARMED 849b, 854b, 856b (last 11:57, saved). Walls, window
  profile, scenes, section planes untouched.
- v1.0 handoff: claude/handoff-2026-10-19-ap-dining-v1.0.md (decisions there still hold unless changed below).

## Changes v1.0 -> v2.0 (Andriy 2026-10-19)
1. Walls B / C 4830 as surveyed ("the walls in the file are my survey"); the A / D panels stand in front of their ends:
   subframe.ends_setback [44.3, 44.3] - frames stop 44.3 from the wall ends, panels from 54.3 (10 to the A / D face).
   v1.0 had shifted the B / C origin instead (length 4741.4) - geometry was the same, the frame of reference not.
2. Liner fixing ("no liner fixing to the panels - look at the kitchen"): the kitchen today (v1.1 / v1.2) has none
   either (probe 847); Main Kitchen v1.0 had the slot strips. Chosen: the slot -
   strips B 6 x 34 (8.7..42.7) + A 6 x 17 (25.7..42.7 behind the panel edge) glued to the panel back by the factory,
   flange 35.2 in the slot (B: leg 14 + 21.2 from the jamb; C: 35.2 from the jamb), frame 46 behind the panel edge
   (B frame_setback 33 -> 42, C stays 56). 14 panels carry strips (D-sheets draw them, sheet note gives the sizes).
3. Joint blocks: with the slot, ~20 mm between the flange end and the frame showed the wall in 12 joints. Chosen:
   JOINT BLOCK MDF 6 glued to the wall by UCON (wall .. 6, strip B is 10.3 off the wall), 20 past the joint, from 20
   under the flange to the frame edge. Tag "07 Liners - joint blocks MDF 6 (UCON)". joint_gaps counts them.
4. Solid plywood pieces ("these frames are better made of solid plywood - write the rules"): subframe.solid_below 150 -
   S1 stiles under 150 apart, or S2 every gap between rails under 150 -> one solid piece, if S3 it nests two across a
   4 x 8 sheet (short side <= 606, long <= 2438). S3 added after draft 4: the 1252 x 660 A / D bands took a sheet each
   (16 sheets). Result: 16 solids (S01-S09, S23, S25-S30), 212 parts, 12 sheets (v1.0 frames: 269 parts, 11 sheets).
   Clip columns no longer snap onto a solid piece -> the panels at the window / opening are on the edge-75 grid
   (recess coordinates differ from v1.0 there; the factory has not drilled).
5. Q11 (G-002): liner fixing - strips vs separate liner pieces fixed on site by UCON; Andriy: keep the strips, ask.
- Revision 2.0 "Reissued for review" 10.19.26; Rev1 1.0 kept in the block.

## Code (commit - Andriy)
- wallpanels/wall_panels.rb: subframe.ends_setback; joint_blocks + joint_gaps(blocks:); solidify (S1 / S2 / S3);
  clip columns ignore solid pieces; cut list: a solid piece = a strip of its short side.
- wallpanels/room_extras.rb: strips generalised (panel_overlap, head_gap or window head, liner.z0); joint blocks boxes;
  tag / colour 'blocks'.
- wallpanels/room_snapshot.rb: panels[].strips, blocks per wall.
- layout/room_drawing_set.rb: D-sheets draw strips B / A on the back view + "strips B / A" label + sheet note.
- walls/AP_MF_Dining_A / B / C / D.json, walls/AP_MF_Dining.json (written by ~/dining_work/mk_walls.py / mk_room.py,
  copies in ~/dev/_claude/ap/dining/).
- test_wallpanels.rb: section 12 extended - strips, flange in the slot, joint blocks, solids (511 checks, 0 failures).

## Learned
- The strips variant reopens raw wall in joints between the flange end and the frame - check joint_gaps after any
  liner / frame change; the joint blocks close it without touching the panels.
- Solid pieces must be judged on the sheet (A-703), not only on the frame: a wide solid can cost a sheet each.
- A clip column snapping onto a solid's centre merges two columns - snap only to real stiles.

## Open
- Q1-Q11 (G-002) to TM / site. Send PDF v2.0 + factory CSV v2.0 to Daniel (not v1.0).
- 3D ISO (DIN-07) shows wall D from the back (one section plane per scene).
- P20 / P24 carry a 31 mm strip piece (P01 / P05 99 mm) - candidate to drop (overlap < 50) if TM objects.
- Rule solid_below is Dining-only; MK / ML / REC-LAU would get it on their next revision.
- claude/README.md: line for this handoff to add (README also changed by another session - Andriy decides).

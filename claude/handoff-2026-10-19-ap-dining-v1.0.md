# Handoff 2026-10-19 - AP Capital: DINING AREA (TM 252234) wall panels, v1.0 FOR REVIEW released

## Executive summary
- RELEASED v1.0 FOR REVIEW (probe 843, 2026-10-19 10:09), ~/Documents, nothing overwritten:
  AP_DIN_Drawings_v1.0.layout / .pdf (31 sheets), AP_DIN_drilling_panels_TM_v1.0.csv (factory, 388 recesses),
  AP_DIN_drilling_frames_CNC_S_v1.0_UCON-only.csv (UCON CNC - NOT to the factory). Data: ~/dev/_claude/ap/din_release_v1.0/.
- Same pipeline / writer as REC-LAU, MK, ML, SAFE-AV: wall JSONs -> RoomSnapshot -> UCON::RoomSet + drawing_style.json.
- Model ~/Documents/AP_MF_Dining_Room.skp (Andriy: Save As from the Trimble Connect copy). Walls untouched.
- Notes, decisions, probe by probe: ~/dev/_claude/ap/dining/dining_razvedka_2026-10-19.md (+ mk_walls.py / mk_room.py
  that write the JSONs).

## Decisions (Andriy 2026-10-19)
- Survey = the model (walls group: A / D 7524, B / C 4830, ceiling 3354; window B 4233 x 3112 to the floor, opening C
  3684.6 x 3044 to the floor). Old TM panels, plywood pilot, plywood groups erased (allowed); walls, trim stay.
- DWG REV 3 governs (Gmail 2026-09-30, downloaded У2: REV 3 1 132 431 b, REV 2 1 422 981 b). Prefix AP_MF_ / files AP_DIN_.
- "As the kitchen": heights from the subfloor, panels on the stone 260.35 (FFL 57.15), 10 to the ceiling, joints 10 open.
- Inside corners as Main Kitchen D ("panels 10 short"): A / D run through, B / C between the A / D panel faces
  (B / C wall-local x 0 = the A / D panel face, length 4741.4).
- Panel height (option A): wide panels no taller than TM drew them -> lower 2755 on every wall, ONE joint 3015.35 /
  3025.35 all round, upper 318.65; window / opening piers cut at that joint; bands over them 236 (B) / 290 (C).
- Window B as Main Kitchen W2-WIN: L-liner 6, leg on the 2nd trim step (14..20 into the opening, 62 deep), flange to
  the frame (frame_setback 33), panels 4 into the opening, legs down to the stone (liner.z0), nothing at the floor.
  Window trim profile (Andriy's) swept on both jambs + head (ARMED 834b), nothing along the floor.
- Opening C as ML Foyer (liner against the reveal, depth 64, flange 56, panel_overlap -10, head_gap 10).
- Numbers P01-P38 = TM elevations 1-4 (B, A, C, D); frames S01-S42.

## Code (commit)
- wallpanels/wall_panels.rb: clip columns snap to frame stiles before a solid strip; band piece lift only by the clip
  rows of panels whose clip columns are in that piece; subframe.seam_overrun_at (turn one band cut).
- wallpanels/room_extras.rb: liner.z0 (where window liner legs start).
- wallpanels/wall_model.rb: build_panels draws a mitred panel (long point on the face) - unused by Dining (inside corners).
- walls/AP_MF_Dining_A / B / C / D.json, walls/AP_MF_Dining.json (room, Q1-Q10, details A-511..513).
- test_wallpanels.rb section 12 (496 checks, 0 failures).

## Learned
- Inside vs outside corners: Main Kitchen mitres only OUTSIDE corners; an inside corner = "panels 10 short".
- TM wide panels max 2755 (REV 3) / 2765 (REV 2); only narrow verticals go to 2844.
- A scene's style can lose DisplaySectionCuts: drafts 3 / 4 printed sections uncut. Fix (841b): set cuts on the
  shared style (selected + update_selected_style) AND page.use_rendering_options = true + page.update. Check by
  re-selecting the scene in the same probe (837b only looked right, it did not hold).
- One section plane per scene: the ISO uses a cut removing wall C; wall D is seen from the back.
- The Mac SketchUp is "the Mac where the model is open" - do not name office / laptop.

## Open
- Q1-Q10 (G-002) to TM / site. Send PDF + factory CSV to Daniel.
- A-100 labels walls B / C 4741.4 (between the A / D panel faces), not 4830 - writer change if wanted.
- Model: old scenes Wall A..D / Scene 5 and old section planes kept; tag "00 Survey dims (old)" holds the 4 old dims.

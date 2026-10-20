# Handoff 2026-10-20 - AP Capital: MASTER BEDROOM (TM 260326) wall panels, v1.0 FOR REVIEW released

## Executive summary
- RELEASED v1.0 FOR REVIEW (probe 944, 2026-10-20 16:0x), ~/Documents, nothing overwritten:
  AP_MB_Drawings_v1.0.layout (3 065 174 b) / .pdf (2 334 527 b, 35 sheets), AP_MB_drilling_panels_TM_v1.0.csv (21 708 b,
  factory, 282 recesses), AP_MB_drilling_frames_CNC_S_v1.0_UCON-only.csv (17 375 b, NOT to the factory). Data + mk_walls.py /
  mk_room.py: ~/dev/_claude/ap/mb/release_v1.0/. Checked on disk (У2): names, sizes, 282 rows + header each, 35 pages.
- Same pipeline / writer as the other AP rooms (wall JSON -> RoomSnapshot -> UCON::RoomSet + drawing_style.json).
- Model ~/Documents/AP_SF_Master_Bedroom_V0.1.skp (Andriy's survey, loose faces on Layer0, probe 930): room 8790 x 7888,
  ceiling 3152. Built by ARMED 932 / 933 / 937 / 942 (saved); scenes MB-05..MB-13. The survey geometry is untouched.
- Sources: TM DWG "260326 Master bedroom-20260708 rev 2" (Gmail "DWG file" 2026-10-12, attached by Andriy, 1 946 428 b, copy in
  ~/dev/_claude/ap/mb/) = the PDF rev 3 / rev 4 WITHOUT Andriy's red survey marks (no newer DWG on Gmail / Drive / Downloads);
  Passione sheet 25 (Master Suite: bed wall = marble slab / wood, fireplace wall onyx, 8" stone base).

## Room = 11 wall JSONs (walls/AP_SF_MB_*.json, written by ~/dev/_claude/ap/mb/mk_walls.py) + AP_SF_MB_Room.json (mk_room.py)
- W1 bed wall (x 8790): stone by others with P01 / P02 1200 at the TM places; door D01 (her bath); stone zones = full-height
  'openings' (no frames behind the stone); marble slabs as tm boxes tag 'stonewall'; at D01 the stone passes 45.5 over the
  frame, joint 10 to the cladding (as the panels at D02).
- W2: left 3 x 1078.7 / right 2 x 1278.5 (P13 10 short of the built-in cabinets 700, TM); entrance piers A / B wrapped on
  three faces, outside corners mitred 45 (kind niche_side, mitres 'out'); ALL pier frames on 2 mm shims (build_up face 46.3,
  recess -2) -> fronts P07 / P10 4 wider (Andriy: room to adjust on a not-straight pier); reveals 650 (pier B assumed, Q6).
- W3 fireplace wall: cabinets 0..2314 and fireplace 2314..5559 as full-height openings; P14 | D02 (his bath) | P15.
- W4 window wall, runs through both corners: P16 / P21, band P17-P20 1695 / 1665 / 1665 / 1727 x 615 (Andriy's mullion survey
  1688 / 1665 / 1665 / 1720, 7 + 7 onto the ends); L-liner as Dining C (reveal not surveyed - Q8 CHECK ON SITE).
- Stone baseboard 260.35 everywhere, ONE piece per run (levels.stone.continuous).
- Doors D01 / D02 as Bedroom 3 D01, openings to the ceiling (no lintel), wall 350 (TM section, Q11); fillers P22 / P23 71 high
  over the claddings (glued). Q15 DOOR HEAD (red frames on A-301 / A-304 / A-501 / A-503): A) door to the ceiling without a head
  (hidden door, designer's intent) - feasible? B) lower door + head panel. UCON recommends A, to discuss with the client.

## G-002 (15 questions) Q1 heights / stone (TM) · Q2 stone + FFL (Site) · Q3 sizes vs DWG rev 2 (TM) · Q4 W1 stone slabs / panels
(TM / Site) · Q5 piers, mitres, shims (TM) · Q6 pier B reveal (Site) · Q7 window liner (TM) · Q8 CHECK window junction (Site) ·
Q9 doors (TM / Client) · Q10 D02 pocket door per Passione? (Client / TM) · Q11 wall 350 (Site) · Q12 cabinets 700 (TM) ·
Q13 clips · Q14 drilling from the back · Q15 door head (TM / Client).

## Code (commit - Andriy)
- wallpanels/wall_panels.rb: a band piece with no height (opening to the ceiling) is skipped.
- wallpanels/room_extras.rb: levels.stone.continuous (stone per stone_runs, cut at doors); tag 'stonewall' (stone cladding ref).
- wallpanels/room_snapshot.rb: doors on walls NOT along +x -> door-local coordinates + doors[].tf.
- layout/room_drawing_set.rb: P() maps door-local points through @dtf on the door pages; a door with stone (no panel) beside
  it - nearest neighbour panel / stone; G-002 rows fit the sheet (adaptive row height), TO column 0.65 and wraps; red
  RECTANGLE marks: sheets.bubbles entry [label, s0, z0, s1, z1] (A-1/2/3:<wall> and A-5:<door>).
- walls/AP_SF_MB_*.json (11 walls + room). test_wallpanels.rb: 511 checks, 0 failures (no Master Bedroom section yet).

## Learned
- A parallel session edited mk_walls.py at the same time (pier shims) - Andriy chose one session; check mtimes before editing.
- m.modified? is always true inside a probe (the bridge opens an operation) - check the file mtime instead.
- Pages selected inside a probe do not switch the view (pictures of scenes from a probe are useless).

## Open
- Send PDF v1.0 + factory CSV to Daniel (TM) with the package; Q15 to discuss with the client.
- Garage -> Mudroom fire-rated door (Door Schedule #1) - scope question still open.

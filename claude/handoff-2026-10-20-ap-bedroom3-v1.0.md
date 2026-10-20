# Handoff 2026-10-20 - AP Capital: BEDROOM 3 (TM 252258) wall panels, v1.0 FOR REVIEW released

## Executive summary
- RELEASED v1.0 FOR REVIEW (probe 922, 2026-10-20 12:27), ~/Documents, nothing overwritten:
  AP_BR3_Drawings_v1.0.layout (1 611 598 b) / .pdf (1 428 250 b, 18 sheets), AP_BR3_drilling_panels_TM_v1.0.csv
  (6 723 b, factory, 87 recesses), AP_BR3_drilling_frames_CNC_S_v1.0_UCON-only.csv (5 537 b, NOT to the factory).
  Data: ~/dev/_claude/ap/br3/release_v1.0/. Checked on disk (У2): names, sizes, 87 rows + header each, 18 pages.
- Same pipeline / writer as REC-LAU, MK, ML, SAFE-AV, Dining, Office: wall JSON -> RoomSnapshot -> UCON::RoomSet +
  drawing_style.json. Office handoff / journal and the start file of this session were not on the office Mac
  (laptop) - the session ran from the Dining v2.0 handoff + the drawing standard.
- Model ~/Documents/AP_SF_Bedroom _V0.1.skp (Andriy's survey: wall 5783 x 3215, door opening 4082..5077 x 2475,
  safe niche 210..1177 x 292..2090, 663 deep - probes 910b / 910c). Built by ARMED 912 / 914 / 915 / 918, scenes
  912 / 919 (saved). The survey group is untouched.
- Sources: TM DWG 252258 REV 1 (Gmail "DWG file" 2026-10-12, attached by Andriy, 428 836 b, copy in
  ~/dev/_claude/ap/br3/), TM PDF REV 2 (Drive), Passione sheet 34 "Bed 3", sheet "AP Capital - Drawings vs Estimate".

## Decisions (Andriy 2026-10-20)
- Our survey governs; TM / factory numbers only to compare, every difference = a G-002 question.
- One wall only. TM layout "1-8" of the DWG, full-height panels ("if the DWG has the size, the factory can make it").
- STONE BASEBOARD as MK / ML / Dining (walls prepared for it on site; TM drew none -> Q1): stone top 260.35 from the
  subfloor (FFL 57.15 + 8"), panels on the stone, 10 to the ceiling: P01 193, P02 961 x 1095 (one piece over the safe),
  P03 977, P04 973.5, P05 973, P06 884 x 811 (over the door), P07 741.5; full height 2944.65.
- SAFE: TM two-door technical cabinet WITHOUT a back, two back rails for transport (as for an oven); carcass = niche
  less 3 every side (961 x 1792 from 295); doors 22 flush with the panels, FFL + 10 .. 2100; no stone under them.
  DO NOT ORDER before the safe spec / dimensions (Q5). Junction details A-511 (plan) / A-512 (section).
- Door D01 as REC-LAU D01 (same TM concealed frame, wall 170): one stop = hinge insert on the hinge side (right),
  leaf 3 from the bare latch jamb; back casings = TM U PROFILE; swing drawn on the plan section. Opening 995 x 2475
  from the subfloor = 2417.85 above FFL - TM frame 2476 / leaf 2390 do not fit (Q6).
- Wall thickness 170 from the TM door section, not surveyed (Q7): drawn as a reference body (tag
  "00 Wall body - reference (not surveyed)") so the plan / jamb sections show the wall.
- Frames from the stone top; tier 2522.1 = the 4" rail centred on the clip row 2571.1 of the full-height panels
  (at the door head 2475 the rail crossed that row); lintels over the door and the niche; no frame under the niche.

## G-002 (9 questions)
Q1 baseboard / panel heights (TM) · Q2 stone + FFL (Site) · Q3 layout 1-8 and sizes (TM) · Q4 safe cabinet build,
hinges, hardware (TM) · Q5 safe spec before ordering (Client) · Q6 door D01 sizes (TM) · Q7 wall 170 (Site) ·
Q8 clips (TM) · Q9 drilling from the back (TM).

## Code (commit - Andriy)
- wallpanels/room_extras.rb: TM U-profile back casing (casing_u, REC-LAU DWG rev.3 / probe 511) instead of the 69.5 x
  18.2 block - every DK1 door gets it at its next rebuild; opening.stops = 'hinge' (one stop on the hinge side);
  :xy pieces (plan polygon extruded in z); tag 'wallref'.
- wallpanels/room_snapshot.rb: doors[].stops.
- layout/room_drawing_set.rb: A-502 on a wall without a row seam (cladding top + leaf joint); swing on the plan
  section A-501 also for doors opening AWAY from the panels (MK / ML / REC-LAU get it at their next revision).
- walls/AP_SF_Bedroom3.json (wall), walls/AP_SF_BR3_Room.json (room, G-002, details A-511 / A-512).
- test_wallpanels.rb: 511 checks, 0 failures (no Bedroom 3 section yet).

## Learned
- r1 rounds to 0.1: sill_setback 31.65 gave a 0.05 SILL frame (A-703 crashed) - keep setbacks clear of the stone.
- A full-height panel wall has no row seam; writers that read the seam need a fallback.
- Pages / scenes selected inside a probe do not switch the view (no animation in the operation): for checks set
  active_section_plane + camera directly (918dry2).
- ~/Documents is shared with the laptop; ~/dev/_claude is not - the AP journals of 10-16..10-19 are on the laptop.

## Open
- Send PDF v1.0 + factory CSV to Daniel (TM). Safe cabinet: not ordered before Q5.
- test_wallpanels: add a Bedroom 3 section (stone + full height, stops 'hinge', U casing, safe cabinet boxes).
- MK / ML / REC-LAU: U casing + swing on A-501 arrive at their next revision.

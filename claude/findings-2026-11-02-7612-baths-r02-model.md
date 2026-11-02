# Findings 2026-11-02 — 7612 baths R02: the model brought to the designer's selection, exported to Metron

Level: PLANNING (designer's selection as we read it; Elda questions of 2026-11-02 open). Master Bath NOT touched.
Source: Project docs `handoff-2026-11-02-7612-baths-r02-sketchup-first.md`, `draft-2026-11-02-7612-baths-designer-elda.md`,
`recon-2026-11-02-7612-baths-designer-catalog.md`.

## What changed in `~/Documents/7612_Hillside_Dr_Bathrooms_v0.1.skp` (office Mac mini, SketchUp 2026)

- ARMED run 41 (`build/r02/7612_baths_r02_model.rb`, dry runs 38 / 40 first), Powder, Guest, Bath 2, Bath 3:
  vanities and side panels -90 (bottom 243 -> 153, `mount_bottom_mm` 153 on their definitions); the integrated MDi 22
  top is the SAME group, rebuilt as a Dekton 20 slab at 738..758 (so the stone top is 758, not 760: 828 - 90 + 20);
  a new countertop basin group per room (Minima 58x37 h130, LVB019.003), centred on the sink unit, 250 from the wall;
  the deck faucet group rebuilt as a wall faucet (spout 950..990, 180 out); mirrors at the same height.
- Bath 2 mirrored: BA60957 to 18..918 (UCON_METRON fronts=fixed), BA61287 to 918..2118; the mirror moved with the basin.
- Guest: tall unit C91230, filler C00151 and the two tall panels 22 not moved. The closing front 22 lying along the
  wall is kind=skip - Metron has accepted panels across the wall only.
- UCON_METRON now on all four room groups (R02; Powder T_00015, Guest T_00016, Bath 2 T_00018, Bath 3 T_00019),
  with `master` and `finishes`; on panels, tops, basins, mirrors, Guest MAX2.2 units.
- ARMED run 44: per-scene visibility. **The scenes isolate a room by per-object hidden state, so a body created after
  the scenes is visible in EVERY scene** — Andriy saw "one basin too many". Fixed for the 4 basins and for the 2 Bath 3
  panels made by stage 2 on 2026-10-29, which had the same defect (visible in Master's scenes too). Any probe that
  ADDS a body to this model must set its page visibility in the same run.
- Saved 10:06:52 local.

## Exporter (core 1.9.34)

`core/87_metron.rb`: room `master` + `finishes` passed through; unit `LAVABO` + `article` (refused without it; never
'under' the top; sorted after the cabinets); unit `master`; unit `fronts` (only `fixed`); panel / top `finish`;
top `th`, checked against the body. Absent keys are not emitted - the BA2 / BA3 fixtures are unchanged.
`room_from_skp.py` carries the new keys and `master` / `finishes` into the room JSON; `rit_build.py` does not use
them yet. `tools/test_metron.rb` 11 -> 18 checks.

## Exports (run 46) and the laptop check

`metron/export/7612/7612_{PWD,BA1,BA2,BA3}.export.json`: 7 / 10 / 7 / 8 items, `not_exported` none.
`room_from_skp.py` refuses all four for one reason only: `LAVABO: no sample` - expected, the handoff says to place
one basin by hand in Metron and SUSPEND. With the basin left out, all four resolve. `--prev` does not keep the R01
ids of the moved units (their y changed 243 -> 153), so ids fall back to the samples.

## Open

- Guest in R01 was INTBA; R02 says MAXBA + MAX2.2. The laptop must change the estimate's collection, not copy R01.
- `rit_build.py`: write finishes, LAVABO block, FOG1.SP, th 20 / CE26, panel finishes, fixed-fronts note.
- 758 vs 760, the Bath 2 mirror, the Guest closing front: defaults taken, listed for Andriy.

## Added the same day — R02b, Andriy's answers (ARMED 48, saved 10:16:46)

- 758 vs 760: "millimetres do not matter" - 758 stands.
- Bath 2: the BASIN moves right, the MIRROR DOES NOT - there is a window on the right, and the left of the toilet is
  blocked. Run 41 had moved the mirror with the basin; run 48 put it back at 18..1218. The default of run 41 was wrong.
- Guest closing front 22 along the wall: "do it in Metron as it comes out". Now kind panel PAN022 LM51 with
  `orient: along`; the exporter emits it only when marked (pos [x0, z0, 0, 0], X length, Y height, th, from_wall);
  an unmarked along-the-wall panel is still refused.
- NEW: a 10 cm backsplash on the BACK wall only, the top's stone (Dekton CE26 20): one group per room, the top's
  length, 20 thick, 758..858; UCON_METRON kind `upstand`, code `ALZATINA` - **no Cesar bathroom code is known**. The
  kitchen snapshot has only ceramic ALZ008012 (12 mm, h max 60) and SCH008012 (back panel 12 mm, h 50..1400, CE26
  priced) - CONTROL, not checked against a printed page; question for Elda. Visible only in its own room's scenes.
- Exports (run 49): 8 / 12 / 8 / 9 items. room_from_skp.py carries `upstand` (no src, `top` mapped to the top's id)
  and the along-panel keys; without the LAVABO sample all four resolve. test_metron 18 -> 20.

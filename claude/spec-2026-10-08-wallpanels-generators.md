# Wall-panel generators — REC -> LAU made general (2026-10-08)

AP Capital, 29 Waves End. The Recreation -> Laundry wall was built by hand on 2026-10-07/08 in probes 538-598:
panel grid, backing frames S, Fastmount clips, clip drilling, a 16-sheet LayOut set. This note records how
those one-wall scripts became generators that take any wall as data, and what proved they reproduce REC -> LAU.

## What is where

| File | What |
|---|---|
| `tools/wallpanels/wall_panels.rb` | `UCON::WallPanels` - pure Ruby (2.6-safe, no SketchUp): grid, frames, clips, holes, both CSVs, cut list, strips, sheets, checks |
| `tools/wallpanels/walls/<model>.json` | one wall: dimensions, openings, door, build-up, rule parameters, sheet texts. REC -> LAU: `AP_BF_Recreation_Laundry.json` |
| `tools/wallpanels/wall_model.rb` | `UCON::WallModel` - SketchUp side: `read` a built wall, `compare` it with the generators, `build_all` (panels, frames, clips, drill cylinders) for an ARMED probe |
| `tools/layout/wall_drawing_set.rb` | `UCON::WallSet` - the LayOut set for any wall; every number from the generators or the JSON. `ap_drawing_set.rb` (APSet) stays as the writer of issued v1.1 |
| `tools/test_wallpanels.rb` | the suite: REC -> LAU regenerated from its JSON against the model export (568), the applied data (566/570), the issued CSVs and A-702 |
| `tools/wallpanels/fixtures/` | those references, frozen |

## The rules (as decided by Andriy, now code)

- Panels: joints 10, 10 to floor / ceiling / ends. A door is a grid column (cladding width), the horizontal joint
  runs along its top. Over a plain opening the panels run `panel_overlap` into it (REC -> LAU: 55, Q9).
  Free segments split into equal columns no wider than `max_width`, widths cut to 0.1, the last takes the rest.
- Rebate: rear 10 removed where a panel passes in front of the door frame (`x0+2.5 .. x1-2.5`, below the head).
- Frames: tiers `floor_gap..tier_joint`, `tier_joint..ceiling`, over an opening `opening top..ceiling`. A panel
  joint inside a span gets a frame joint `seam_overrun` (20) past its centre, on a 6" stile - unless it is
  within a 6" strip of the span end, then that end stile is 6" and there is no joint. Any edge member with a
  panel joint within 152 of it is 6", others 98. Rails: one per edge, one centred on each clip row the edge
  rails do not carry.
- Clips: 75 from edges, rows <= 600 (min 2), a centre column above 900 wide; a column over a stile moves to the
  stile centre, never closer than 40 to the edge; an unsupported bottom row goes onto the rail above.
- Holes: numbered per panel from the back (x right-to-left on the face, then bottom-up).

## Parameters that are NOT recorded decisions (flagged in the JSON)

- `max_width` 1220 - assumed (one MDF sheet). REC -> LAU comes out the same for 1061..1266. Columns can be fixed
  per segment with `columns`.
- `clips.row_over_opening` 2555.8 - LEGACY: the centre of the OLD frames' rail (562). Kept so REC -> LAU
  regenerates its issued drilling. Without it the rule puts the row on the new rail centre, 2554.
- `tier_joint` 2380 and `floor_gap` 25 - per wall numbers from the proposal, not derived.

## Proof (2026-10-08, office Mac)

1. `tools/test_wallpanels.rb`: 399 checks, 0 failures - panels, 78 frame members, 103 clips, 103 holes, both
   CSVs text for text, cut list, strips 23 / 7, 3 sheets; plus a second run with no numbering, no column counts
   and no legacy row (auto rules) that passes its own checks.
2. Probe 599c (dry, rolled back): model vs generators 0 differences; the writers drew the same wall under the
   prefix WPDRY599C, read back 0 differences vs generators and vs the hand-built wall, box by box
   (15 panels, 78 members, 103 clips, 206 cylinders).
3. Probe 600 (read only): the set rebuilt by `WallSet` into `~/dev/_claude/ap/regen/`: 16 pages, 117 dimensions
   (v1.1: 117), frames CSV byte-identical, PDF text identical on 15 of 16 pages, renders identical within
   anti-aliasing. The one difference is intended - next section.

## The one difference: A-702 sheet text

v1.1 says `2 mixed (4 x 6" + 6 x 4") + 1 of 12 x 4"`. Across the 48" sheet that mixed pattern is
4 x 152 + 6 x 98 = 1196 plus 9 kerfs x 3.2 = 1224.8 mm, 5.6 mm wider than 1219.2. The generator packs
`1 of 7 x 6" + 1 x 4", 1 of 12 x 4", 1 of 10 x 4"` (1184.4 / 1211.2 / 1009.6 mm). Still 3 sheets.
Not reissued - Andriy decides.

## Not generated yet

- Scenes and section planes (01-06) - still per wall, by ARMED probe (scene and style changes are not rolled back).
- The door D01 itself (frame, leaf, swing) - built by hand in 502-530; `WallSet` reads it through scenes 05 / 06.
- More than one door on a wall: `WallSet` refuses.
- A wall not on the model's x axis: writers take `origin:`, the reader and the LayOut views assume x along the wall.

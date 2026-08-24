# Placement tool — what the cursor settled (2026-08-19/20)

Probed live in SketchUp 2025, not argued on paper. Six throwaway scripts in
`~/dev/_archive/` (`step1_follow.rb` … `step6_neighbour.rb`) — deliberately
OUTSIDE the repo, not committed, disposable. Nothing in `core/` was touched.
This doc is the residue worth keeping; the scripts are not.

Related: roadmap M2.3 (interactive tool), pulled forward by demand. M2.1a/M2.1b
(batch row, worktop) will now sit on top of this, which is a conscious trade.

**Status: the grab half is proven end to end** — a unit follows the cursor,
recognises a wall, seats its back on it at any wall angle, and butts flush
against its neighbour. Not in the engine yet.

## Settled by experiment

**A wall is a geometric fact, not a name.** A face whose normal is horizontal
(tolerance ~5°, measured as `|normal.z|`). The wall belongs to the client's
model and carries no attribute of ours, so tag names and group names are not
available to read — and must not be. The floor is the same test with a vertical
normal. Confirmed in a real model: side face → `(1.00, 0.00, 0.00)`, another
wall → `(0.00, -1.00, 0.00)`, top → `(0.00, 0.00, 1.00)`.

**The back plane mates to the wall, not the bounding box.** Cabinet local axes:
x across the face, y depth (front at 0, back at +depth), z up. So the unit's
depth axis points INTO the wall and the origin steps forward off the wall by
exactly the carcass depth. The front slab keeps hanging forward at negative y,
which is correct — it is a front, it is supposed to stand proud.

**Rotation is `back normal = −wall normal`**, which works at any wall angle,
not just orthogonal ones. Right-handed frame: `yv = −n`, `zv = Z_AXIS`,
`xv = yv × zv`. Local +x lands on the viewer's right when facing the unit.

**The thing being placed hides the thing it is placed on.** This is not a bug,
it is inherent: the unit sits under the cursor and occludes the wall behind it.
`pick_helper` only ever reports the front-most entity, so it is the wrong tool
here. Solution that kept the real unit visible (no wireframe stand-in): fire
`Sketchup::Model#raytest` and WALK the ray — every hit whose path includes the
unit is stepped past by 1 mm and the ray is fired again, up to 8 times, until it
meets somebody else's face.

**The cursor holds ONE fixed corner: right / top / far.** Same for base and wall
units. Two earlier attempts were worse:

- *left edge* (step 3) — "left" is derived from the wall normal, so the unit
  jumped to the other side of the cursor when you crossed to another wall;
- *grab wherever you touched* (step 4) — flexible and forgettable; the same drag
  felt different depending on where you happened to click.

A fixed corner is a promise: the hand always holds the same point, so the unit
lands where you expect on the first try. Andriy's call, and it reads better in
use than either alternative. The corner is marked with three short arms drawn
along the three edges meeting at it — an invisible promise is not a promise.

**Top comes from `definition.bounds.max.z`, not from a standard.** That is
correct for a base unit on its plinth and a wall unit hanging at 1400 alike,
with no assumption about either.

**The vertical is latched.** The held corner follows the cursor ALONG the wall,
not up and down it. A run is level by construction; height changes by a separate
gesture or a typed number. Decided 2026-08-19.

**Two tools, not one.** Stamp (point and place) for inserting from the catalog;
grab for moving something that already exists. Decided 2026-08-19; only the grab
half has been probed.

**Snaps are split across axes so they cannot fight** (step 6, proven):

| decides | rotation | depth | position along the wall | height |
|---|---|---|---|---|
| wall | ✓ | ✓ | — | — |
| neighbour | — | — | ✓ | — |
| latched default | — | — | — | ✓ |

**A neighbour must qualify, not merely be nearby.** Three tests, all required:
it carries our contract `code`; it has the same `mounting` (a wall unit does not
butt against a base unit — different rows); it faces the same way (`dot ≥ 0.95`
on the depth axis) and its back sits on the same wall plane (within 30 mm).
Either end can catch — our left onto their right, or our right onto their left —
and the smallest correction wins, so the nearest joint is the one that takes.
Pull-in distance 120 mm. Feedback: the held-corner marker turns green.

## Traps found along the way (all cost real time)

- **`load` REOPENS a class, it does not replace it.** A method defined by an
  earlier version of a probe file survives into the next one and gets called
  with the wrong arguments — the symptom is `ArgumentError: wrong number of
  arguments` pointing at a line that looks fine. Every probe file now begins by
  wiping its own namespace with `remove_const`.
- **SketchUp swallows exceptions raised inside tool callbacks.** The tool simply
  stops responding and says nothing at all. Anything running on every mouse move
  needs its own `rescue` that prints once.
- **Neither the status bar nor the tooltip is a usable readout on macOS.**
  SketchUp repaints both on its own schedule and the string is gone before it is
  read — a value set on click survived only because nothing repainted in
  between. Draw the text into the viewport with `view.draw_text` and force
  `view.invalidate`.
- **A missing menu is not always a broken install.** Both symlinks were correct
  and the code was clean, yet the submenu was absent — SketchUp had not started
  the extension. `load '<repo>/src/ucon_cabinet_engine/main.rb'` in the Ruby
  Console brought it back with no restart.
- Downloading a `.rb` through the desktop app failed ("Unable to open file").
  Writing straight into `~/dev/_archive/` over the device bridge worked and is
  now the way these scripts are delivered.

## Still open

1. **Stamp tool** — the other half of the two-tool decision. Untouched.
2. **Two rows of different depth on the same wall.** Both backs sit on the same
   plane, so the coplanar test passes and a d.35 unit will butt against a d.62
   one. Not yet judged right or wrong in use.
3. **Wall unit aligned to a base unit's end.** Currently forbidden by the
   `mounting` test. That may be over-strict — lining a wall unit up with the
   base below it is a real move — but a shared end is an alignment, not a butt
   joint, and probably wants its own weaker snap.
4. **The baked z0.** The mounting height is modelled INTO the definition (the
   carcass starts at z = 1400) while the instance origin sits at floor level.
   Visible in the model as a bounding box running from the floor to the top of a
   hanging unit. Latched vertical hides the problem; the moment height becomes
   editable, one definition can no longer serve two heights and
   `mount_bottom_mm` stops describing reality. Decide then: bake, or hand the
   height to the instance transform.
5. **`mount_bottom_mm` must be written by placement, not by the default.** Today
   the generator writes `Standards::WALL_MOUNT_BOTTOM_MM`. Once a unit can be
   re-hung, the attribute has to record where it actually ended up, or the
   exporter will quote 1400 for a cabinet hanging at 1520.
6. **Corner units** — footprint is not the box and two walls are needed at once.
   Out of scope; already tracked as M2.2.
7. **Undo.** The probes mutate the transformation directly with no
   `start_operation` wrapper. The real tool needs one, plus a clean abort.
8. **Performance.** Every mouse move fires up to 8 `raytest` calls and scans all
   top-level instances for neighbours. Fine on a test model; unmeasured on a
   real kitchen with a full run.

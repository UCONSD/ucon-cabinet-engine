# UI backlog

Small, non-load-bearing notes about how the extension LOOKS. Kept apart from the
status file so that stays about the engine. Nothing here changes data or rules;
if an item turns out to need either, it does not belong in this file.

## 1. Corner units should use the same three-column grid as every other type

**Noticed 2026-08-20, right after the corner list dropped from 18 buttons to 9.**

Removing the execution letter fixed what to look at but left the layout wrong:
nine stacked headers, each followed by one full-width button. It reads as a long
list of nearly identical rows.

Every other unit type already solves this in `sizeGrid` (`core/90_palette.rb`):
one `.drow` per DEPTH, a `.dlab` on the left (`d. 35`), then the size buttons as
`.wbtn` with `flex:1` filling the row. Three depths → three rows.

Corner sizes fall into exactly that shape:

| | | | |
|---|---|---|---|
| **d. 35** | 1000×430 | 1150×430 | 1300×430 |
| **d. 62** | 1000×700 | 1150×700 | 1300×700 |
| **d. 67** | 1050×750 | 1200×750 | 1350×750 |

So `cornerList` should stop being its own layout and become `sizeGrid` with the
node in place of the width: group by `depth_mm`, label the row `d. NN`, put the
node on the button. The door width and carcass length repeated in every header
are already shown by `showCard` for the selected code; in the list they are nine
near-identical lines of noise. The caption "the wall picks the hand" then
belongs once, above the grid.

**Cost:** small, contained in one JS function. **Risk:** none to data.

## 2. Toolbar icon — DONE 2026-08-20, drawn by Andriy

An isometric extruded **U** with three visible faces — white cap, pale front,
blue side — under one dark outline. 24×24 and 32×32, RGBA with real alpha, glyph
16×20 inside the 24 canvas so it floats rather than fills. Sits correctly beside
the native icons on the toolbar. Accepted.

Only observation left, not a defect: **the outline lightens in the downsample**,
so the mark reads softer than the near-black native set. That is the one place
to add weight if it ever wants more presence.

### Why five of Claude's attempts failed first — worth keeping

1. *A cabinet silhouette* — five or six strokes average into a grey smudge at
   24 px, and it said "cabinet" where the button means "UCON".
2. *SketchUp-rendered line art, white faces, thin grey edges* — invisible on a
   light toolbar. **At 24 px contrast comes from the LINE, not the fill.**
3. *Bolder silhouette via `ProfileWidth` / `DrawSilhouettes`* — **the active
   style overrides rendering options**, exactly as it had already done to
   `DisplayAxes`. Line weight cannot be negotiated with SketchUp.
4. *Extrusion outlined front AND back* — two parallel dark lines merge at 24 px
   into one smear ("why is it doubled"). **Depth must be a MASS in a different
   tone under a SINGLE outline** — how SketchUp's own `3D Text` icon does it,
   and the reference that finally named the problem.
5. *Fully saturated orange* — too heavy; one step of desaturation read calmer,
   but the whole line of attack was still weaker than what a designer produced
   in one pass.

Three conclusions that outlive this icon:

- **The 24 px size overrules the style guide.** The house idiom says "an object
  in perspective"; the size says depth only survives as mass, never as a second
  contour.
- **SketchUp settles the FORM, not the artwork.** `~/dev/_archive/icon_u.rb`
  builds the U as real geometry and photographs it — useful for judging
  proportion. Final pixels have to be drawn where stroke width is controlled.
- **Three faces beat two.** The accepted icon shows cap, front and side; every
  Claude attempt showed only front and side, which reads as a shadow rather
  than a body. That single structural difference is why it works at 24 px.

### Drop-in spec, if it is ever replaced again

- `src/ucon_cabinet_engine/icons/ucon_24.png` and `ucon_32.png` — exactly these
  names; the shell looks them up by name.
- PNG with alpha, exactly 24×24 and 32×32.
- **Both files must exist**: SketchUp drops the whole button, silently, if one
  is missing.
- **`toolbar.restore` must be called** or the toolbar never appears at all.
- Both live in `main.rb`, the frozen shell: a change needs a full SketchUp
  restart, not `Reload core`.
- `tools/test_contract.rb` asserts both files exist and start with the PNG magic
  bytes. **A merely ugly icon passes — the eye is the only test here.**

## 3. The properties dialog still uses `'78'` / `'75'` as internal JS tokens

Labels are data-driven since the door-version axis became family-scoped, so
nothing visible lies. But a token with a number in its name will read oddly the
day a family with different door heights appears. `full` / `gola` are the honest
names. Cosmetic; no behaviour depends on it.

*(2026-08-24: that day is close. printed p.38 and p.48 hold nineteen articles
that exist only in the gola execution, and `door_versions` is still a family
key. When the axis narrows to an article, these tokens go with it.)*

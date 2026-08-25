# 2026-08-25 — the appliance seam, and the four things it found on day one

Core 0.78.0. New file `src/ucon_cabinet_engine/core/88_appliance_check.rb`,
new suite `tools/test_appliance_seam.rb` (16 checks). The engine's own suite is
unchanged at 429.

## What was built

One seam, one direction, optional.

The appliances live in a **separate extension** — `UCON::Appliances`, its own
namespace, its own `UCON_APPLIANCE` dictionary, its own four JSON files, its own
48-check suite. That separation is not housekeeping: Object Contract v2 §1.2
forbids commercial data in the `CabinetEngine` dictionary and §1.1 closes the
key list, and an appliance record carries a manufacturer's price and a dozen
keys the contract has never heard of.

`88_appliance_check.rb` is the only place the two touch, and it **only asks
questions**:

- nothing in `core/` requires the appliance module. `ApplianceCheck.available?`
  is a real question, asked at call time (so installing the extension and
  reloading core is enough — no SketchUp restart), and every entry point
  returns `'checked' => false` with a reason rather than raising;
- it writes no attribute, draws nothing, orders nothing. It builds the niche
  the generator **would draw** and hands it to the appliance module to judge;
- the appliance module never calls back.

Three of the sixteen checks exist purely to prove the dependency is optional —
they run and pass with the appliance package absent.

**The niche it checks is built from `Generator.niche_bottom_mm` /
`niche_top_mm` / `niche_height_mm`, never from the registry row.** The row
states a fragment (`bottom: plinth_top`, sometimes a `top_mm`); the rule that
turns the fragment into a box lives in `60_generator.rb`. Read the row instead
and the seam would be checking a niche nobody draws.

## What it found, on real codes, the first time it ran

```
CR9700 vs DEC3050R/L: DISAGREES
  ! drawn housing height 2033.6 vs required opening height 2134
  ! niche depth 620 is shallower than the required 635
  ! niche bottom is plinth_top, but an appliance housing is measured from the floor
  > 66 left above the housing: filler, carcass, set back 55 from the front plane

CR9900 vs CL3650UID/S/T/R: DISAGREES
  ! niche top 2133.6 vs published opening height 2127
  ! drawn housing height 2033.6 vs required opening height 2127
  ! niche width 914 vs published opening width 902
  ! niche bottom is plinth_top, but an appliance housing is measured from the floor
  > 73 left above the housing: filler, carcass, set back 55 from the front plane
```

Four defects, none of them invented for the occasion.

### 1. The housing is 100 mm short, and its TOP is right

`usa_tall_h210` draws the housing from the **top of the plinth** to 2133.6.
2133.6 is exactly the 84 in the appliance makers require — **from the finished
floor**. So the top is correct and the opening is 2033.6 tall, a hundred
millimetres short of what the machine needs.

This is why `matches_niche?` gained a **height** comparison on the same day.
Comparing tops alone called this a match. The top and the height are two
questions, and a housing that starts on a plinth answers the first correctly
while failing the second. A check now holds exactly that case, and a second one
holds that the top must NOT be reported — otherwise the title would be lying
about which comparison caught it (rule 18).

The `bottom: plinth_top` in `usa_tall_h210.json` was a deliberate 2026-08-22
decision, off the model, because the phantom was coming out from under the
plinth. It is right about the DRAWING and wrong about the MACHINE, exactly as
the dishwasher plinth is — and the dishwasher's row says so in
`bottom_is_representation`. **The USA tall row does not carry that flag.**

### 2. The default depth is shallower than a Designer column needs

`NICHE_DEFAULT_DEPTH_MM` is 620 (d.62, the run). A Designer column publishes a
635 cutout, a Classic 610. So the default is too deep for one and too shallow
for the other, and neither number is ours to choose.

### 3. The niche width is the DOOR's width, not the cutout's

`niche_attributes_for` writes `'width_mm' => unit['width_mm']` — the width in
the Cesar door code. That is right for a dishwasher, where a 600 machine stands
behind a 600 or a 750 front. It is **wrong for built-in refrigeration**, and
wrong in a way that changes sign with the installation type:

| 36 in Classic | opening | vs the CR9900 door at 914 |
|---|---|---|
| standard | 902 (nominal − 13) | the opening is **12 narrower** than the door |
| flush inset | 953 (nominal + 51) | the opening is **39 wider** than the door |

This is the same trap that produced the Classic/flush correction: the frame
overlaps the cabinetry in a standard install and sits inside it flush. A single
`width_mm` copied from the door code cannot be right for both.

### 4. Nothing is drawn above the housing

66 mm above a Designer column, 73 above a Classic, in a 2200 run. The appliance
rules always name something to offer — below 120 a filler, above it a filler or
an Open Custom Shelf Cabinet — and both sit **55 mm back from the cabinet front
plane**, because the Sub-Zero hinge draws the panel inward. The engine draws
none of it today.

## What was NOT changed, and why

**No geometry moved.** Every one of the four is a decision, not a typo:

- fixing (1) means the drawn housing stops matching the plinth line that
  2026-08-22 deliberately made it match, and that is a drawing decision;
- fixing (2) and (3) means the niche's width and depth stop coming from the
  Cesar code and start coming from the specified appliance — which means a
  Cesar unit can no longer be drawn until somebody has named a machine, or
  needs two states;
- (4) is new geometry with a new object class behind it.

The seam exists so these are visible before they are argued about. It reports;
Andriy decides. **Rule 1's shape, applied to our own drawing: a plausible fix
is not a decided one.**

## How to run it

```
ruby tools/test_appliance_seam.rb
UCON_APPLIANCES=/path/to/ucon-appliances ruby tools/test_appliance_seam.rb
```

Without the package it runs the three optional-dependency checks, prints
SKIPPED, and exits 0. A skip is honest; a green tick for checks that never ran
is not. It looks for `$UCON_APPLIANCES`, then `../ucon-appliances` beside the
repo, then `~/Downloads/ucon-appliances`, then `~/dev/ucon-appliances`.

**CORRECTED 2026-08-25 evening (rule 9 — added, not erased). Both paragraphs
above are now wrong, and the second one was reversed by decision the same day.**

The search list gained `src/ucon_appliances` at the FRONT, and the lib file it
looks for is `lib/appliances.rb` as well as the older `lib/ucon_appliances.rb`.
While both trees existed the old list silently preferred the stale Downloads
copy — a suite that finds the wrong tree does not fail, it gets quieter, which
is worse than failing.

And the package IS in this repository now, at `src/ucon_appliances/`, beside
`src/ucon_cabinet_engine/`. **Two extensions, one repository** — see §11 of
`claude/appliance-rules-decided.md`. The separation that matters is at RUNTIME,
and it is unchanged: neither extension requires the other, the engine's suite
passes with the appliance tree deleted, and the three optional-dependency
checks still prove it. What changed is only where the files are kept. The
original claim follows, and it was right about the runtime and wrong about the
repository:

> The appliance package is **not in this repository** and should not be: it is a
> separate extension, currently `ucon-appliances-0.1.1.rbz`.

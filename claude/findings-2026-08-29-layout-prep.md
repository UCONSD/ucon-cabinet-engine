# 2026-08-29 — the drawing was never there: eight scenes over an untagged model

**545 Avenida Primavera, laptop, SketchUp 2025, core 1.4.0 in memory.**
Two read-only probe runs, before any theory. What they found is not a bug in
the engine — the engine had done its part — but the drawing side of this
project had never been asked a single question.

## What the model held

| | |
|---|---|
| Scenes | **8** — `K-E01…K-E04` the four walls, `K-E05…K-E08` the island's four faces. Every one saves camera, tags, hidden geometry, style, section and shadows. |
| Cameras | **All eight are PERSPECTIVE, fov 35**, and **seven of the eight share one direction, `(-0.42, -0.62, -0.66)`** — the same three-quarter view saved eight times under eight elevation names. Only `K-E05_ISLAND_NORTH` looks anywhere else. |
| Section planes | **Zero.** Not at top level, not nested. |
| Per-scene tag state | **Every scene hides nothing.** `Page#layers` is empty on all eight. |
| Tags | 8 exist. The three opening tags are **globally invisible**. |
| Bodies | **56 of 59 UCON objects on `Layer0`.** Tagged: 2 appliances (Placeholder), 1 void (Reserved). |
| Symbol geometry | It **exists**: 205 entities on Opening (front), 450 on (plan), 338 on (door), 309 on Lighting. |
| `object_class: worktop` | **None in the model.** And `Sink marks` holds 0 entities although `B81087`, a sink base, is built — the sink mark refuses where there is no stamped top, so one fact explains the other. |
| Style | one, `[Construction Documentation Style]` — the brackets are SketchUp saying it is modified and unsaved. |

## The three things this actually means

**1. Eight scenes saved a tag state that does not exist.** A LayOut sheet is
controlled by tags and by nothing else. With 56 bodies on Layer0 there is one
drawing of everything in this model and no way to make a second — no plan
without the elevation symbols on it, no elevation without the plan symbols, no
sheet with the client's fridge switched off.

**2. The eight elevations are not elevations.** A perspective has no scale, so
no dimension on it is true. Seven of them are additionally the same picture. The
names were written first and the cameras were never aimed.

**3. The symbols were drawn and then switched off.** This is the one cheerful
line in the report: 1302 entities of symbol geometry are sitting in the model
correctly made. Nothing needs rebuilding — it needs a tag state per sheet, which
is exactly what nothing has ever set.

## What was done about it, and what was deliberately not

**Done: `core/66_retag.rb`, core 1.5.0.** One pass, re-runnable, that fills in
`Layer0` from `object_class`. Eight checks in `tools/test_contract.rb`.

**Andriy's call, 2026-08-29: the GENERATOR does not tag at build time.** The
same decision would have landed in twenty call sites — every `build*`, every
probe that draws, every hand copy — and this project already knows what that
costs: the shared-definition guard sat in the generator for weeks and never
reached the panel (2026-08-28). One place does the thing.

**The three refusals are the design, and two of them are about not being
clever:**

- **It never touches a body that is not ours.** No `CabinetEngine` dictionary,
  no tag. The walls, the floor and the imported furniture stay where Andriy put
  them.
- **It never moves a body that already carries a UCON tag.** `Placeholder (not
  ours)` is a statement of OWNERSHIP, not of class — Drawing_Spec's *a stand-in
  for something that is not ours has no surfaces*. Re-tagging an appliance by
  its class would delete that statement and put a client's fridge on a
  presentation sheet as though we had quoted it. Only the ABSENCE of a decision
  is filled in.
- **An unknown `object_class` is refused and named.** The ratchet is in the
  suite: a class in the contract with no tag here fails a check, so the enum
  cannot widen without this file learning the new class.

**Not done, on purpose: the tag GROUPING.** Whether `Corner units` deserves its
own switch or folds into cabinets is a decision that differs per sheet, and
SketchUp has tag folders for it. Inferring that from one kitchen is the error
this project refuses everywhere else. The map is mechanical, out of the
contract's own enum, ten classes and ten names.

**Not done, on purpose: the scenes.** Andriy's call the same day — **one
elevation built by hand first**, and only then a conversation about what, if
anything, should be automated. Same reasoning as the worktops: a camera rule
inferred from one kitchen would never have ended (angled walls, an island seen
from four sides, a run that turns a corner mid-elevation).

## One thing found on the side, and it will bite LayOut specifically

The model is open **out of the Trimble Connect cache**:

    ~/Library/Application Support/SketchUp 2025/SketchUp/.tc/<uuid>/cache/northAmerica/<id>/545_….skp

That is how it reached the laptop, and it is fine for modelling. A LayOut
document, however, holds a PATH to its .skp and re-imports through it. A path
containing a session uuid is not a promise. **Where LayOut takes the model from
has to be decided before the first sheet, not after it.** Not decided here.

## What this cost, and what it is worth

Two read-only probes, about ten minutes, and they answered a question that three
days of reasoning about the drawing side had not been asked. Recording it under
rule "the probe is faster than the theory": the complaint was going to be *"the
sheets look wrong"*, and the model said why before anyone theorised.

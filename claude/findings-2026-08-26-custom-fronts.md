# 2026-08-26 — a custom carcass with a printed front

**Andriy, looking at the model:** the fronts of custom-sized cabinets do not stretch to the
custom size. Two top elements at 610 from a 600 module, and the same over the fridge.

## What was actually wrong — the engine was right and the bodies were old

**Proved headless before anything was touched.** `Registry.with_ordered_width(SD0631, 610)`
then `with_ordered_height(…, 720)` gives `front_slabs` → **one slab 610 × 720**. The increase
path reaches the front today.

Measured in the model, group by group inside each definition:

| body | carcass | front | short by |
|---|---|---|---|
| `SD0631` 610×600, east ×2 | 610 wide | **600** | 10 wide |
| `SD0631` 610×600, south ×2 | 610 wide | **600** | 10 wide |
| `SD0631` 610×720, south ×2 | 610 wide, top 2440 | **600 wide, top 2320** | 10 wide, **120 high** |

The two over the range are the bad ones: **120 mm of carcass with no front on it at all** —
not a front that is slightly narrow, a band with nothing there.

They were built on 2026-08-25, before the increase path reached `front_slabs`, and **nothing
had re-drawn them since.** A model is not recomputed when the engine changes; it holds
whatever it was given.

## The half that makes it a finding rather than a bug report

**REDUCTION WAS NEVER WRONG.** `SD0930` cut to 770 drew **385 + 385** — in the same model, on
the same day, through the same method. One direction of one rule worked and the other did not.

> **Reading the code proves nothing about the past.** The code is right now; six bodies say it
> was not right when they were made. Only the model remembers that, and only a measurement
> reads the model.

## What was done

- **A check**, so it cannot go quiet again: *"A MODIFIED UNIT GETS A MODIFIED FRONT, in both
  axes"* — the slabs must sum to the modified width, must reach the modified height, and must
  **not** be allowed to come back as the printed 600. The reduction case is pinned in the same
  check, because that is the half that was already fine and would otherwise be the thing a
  later refactor breaks.
- **Six bodies redrawn** from the registry on their own seats, through the engine's own methods
  rather than a copy of the builder. Verified afterwards: carcass 610, front 610, and the
  720-tall pair reaching 2440. Their symbols regenerated with them — the door symbol moved
  from 74,21 to 75,08, which is what a symbol scaled to a real width looks like.
- Each redrawn object says on itself why it was redrawn.

## The detector over-reported, and the guard is what saved it

The probe that found these flagged **18** bodies by comparing the carcass width to the sum of
the front widths. Twelve were false:

- **drawer stacks** — three fronts one above another, so summing their WIDTHS is meaningless
  (750 carcass, "2250" of front);
- **`AU110D`**, a corner unit: one 450 door on a 900 carcass, by design;
- **`C92640`**, whose front stops at 490 with a `VOID_REMAINDER` above it — the remainder
  concept working exactly as intended;
- **base units** at front 750 on carcass 780, which is the printed H.78 / door-version-75 pair.

**Nothing without a WIDTH or HEIGHT variant was touched**, which is why a crude detector was
safe to use. The lesson is not "write a better detector" — it is that a destructive pass needs
a narrow gate that does not depend on the detector being right.

## Still open

Whether anything else in the model predates a rule it should now follow. This one was found by
Andriy looking at a sheet, not by a check — and the same is true of every geometry fault found
today.

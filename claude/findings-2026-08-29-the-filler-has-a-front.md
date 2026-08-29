# 2026-08-29 — a filler has a front and does not open, and one predicate stood for both

**The complaint, in Andriy's words:** the Door height control on `B70151` does
not work, and for a filler that choice belongs to base cabinets only.

Both halves were right. The second half was already true and nobody had checked;
the first half was a **silent no-op that had been shipping since 0.95.0**.

## The mechanism, in one line

`Panel.attributes_patch` opened with

    unless opens?(unit)
      return led_patch(unit, payload)
    end

and `opens?` asks `unit['opening']`, which a filler does not have. So **the
method returned before it ever reached the door-version code.** Pick "75 —
gola", press Apply: no error, no change, and the radio still reads 75 afterwards
because the radio is HTML and nothing had told it otherwise.

The dialog showed the control because the JavaScript asked only
`st.door_versions` — a FAMILY fact, and `B70151` is family H.78, which does
declare 78/75. **A control was shown on an object whose Apply path could not
reach it.**

## What made it visible, and it was not the dialog

Probe run 92, over every object in 545 Avenida Primavera:

| | front_height_mm | opening_method |
|---|---|---|
| every base cabinet in the run | **750** | gola |
| `B70150`, `B70151` — the two H.78 fillers | **780** | handle |

**The filler fronts stand 30 mm proud of every front beside them** — a step in
the elevation, on the wall Andriy was about to draw. `fillers_h78.json` had
written the warning down in advance, in the note explaining why the filler
states `front_layout kind: single` at all: *a filler's front line must meet its
neighbours' or the drawing breaks.*

## The fix: one predicate becomes two

- **`front?(unit)`** — `front_layout.kind` present and not `none`. A filler
  passes; a shelf and a Linear-Elements panel state `none` and do not.
- **`opens?(unit)`** — unchanged, and now used only for what genuinely needs an
  opening: the method, the handle, the hinge.

The door version, and the grip recess that comes with it, moved to the FRONT
question. The 0.95.0 change that caused this was right about what it aimed at —
a shelf must not be offered a handle — and swept the door version along with the
handle because one predicate stood for two facts.

**`opening_method` is not set on a filler at all.** `gola` is not a way of
opening for a thing that does not open. The front is short; nothing about it
opens; nothing pretends otherwise.

**A filler in the 75 version orders its own length of profile** — Andriy's call
the same day. The run's grip recess stops at the filler, so the piece over it is
nobody else's order line. Mechanically this fell out of resolving the companions
from the door VERSION instead of the opening METHOD: `GOL001`, um ML, and its
`qty` is nil — exactly as incomplete as every cabinet's profile line, which is a
separate open question and not a regression.

## Two things deliberately refused

**A `door_version` contract key was written and taken back the same hour.** It
failed five contract checks correctly — §1.2 makes a key outside the list a
violation, so storing it is a contract REVISION, and that is a poor price for a
fact already in the model. `front_height_mm` and the family's declared `gola_mm`
determine the version exactly, so `door_version_of` derives it in one pure
place. **That is the shape `wall_hung_chosen` has had all along**, forty lines
below, and the lesson is the same one that file already states: the checkbox
records a CHOICE, `mounting` records the RESULT, and reading one for the other is
how a control stops working. Recorded rather than erased — learned rule 9.

**The mounting block is now guarded by `opens`.** Fillers reached this method for
the first time that day, and the mounting checkbox is hidden for them — so an
unguarded pass would have read a `false` nobody set and written `mounting: floor`
onto a wall filler. That is this bug's mirror image: a control acting where it
was never shown. What the generator built stands until somebody is actually
asked.

## And the half that was already right

The 78/75 choice is scoped by FAMILY, not by class, and that is what makes it
"base only": `B70150` and `B70151` are family H.78 and get it; `BE0151` (Top
elements H.60), `C00151` (Tall H.234) and `PF0151` (Wall H.96) are fillers too
and declare no `door_versions`, so they get nothing. A check now pins it,
including the refusal by name when a 75 is asked of a family that has none.

## What this cost

Eight checks, of which **four pin refusals rather than the happy path**: no
opening method on a filler, no mounting decision, the profile taken away again at
78, and the family scoping refusing by name. And one SOURCE check on the HTML,
because the fieldset and the radio are JavaScript and nothing headless can press
them.

**The lesson, and it is a new one for this project's list:** a predicate that is
right about the case it was written for can be wrong about the case it was
reused for. `opens?` was correct in every line that asked it in 0.95.0. It became
a bug the moment it was made to answer a question about fronts.

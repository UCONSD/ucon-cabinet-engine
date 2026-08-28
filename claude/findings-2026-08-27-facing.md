# The label was inside the wall — 2026-08-27

> Я понял, в чем была проблема. [Полка] была сгенерирована жопой к стенке. И
> надпись уходила вовнутрь стены. […] я даже не могу её развернуть, потому что не
> дают мне такой опции развернуть.

Andriy found it, and he found it by looking for the label the previous round had
just added. The mark was never the problem; the object was turned round.

## Read out of the model, not reasoned about

A probe over all 50 UCON objects, reporting each one's yaw — the direction of its
own `+y`, which is the axis a unit's depth runs along, so `+y` is *backwards,
into the wall*:

```
  yaw  -180 : 18  {"cabinet"=>14, "filler"=>4}      the north run
  yaw   -90 :  6  {"cabinet"=>4, "filler"=>1, ...}  the west return
  yaw     0 :  9  {"cabinet"=>4, "panel"=>4, "shelf"=>1}
  yaw    90 : 17  {"cabinet"=>13, "filler"=>2, ...} the east run
```

The shelf is the single `shelf` in that third row: **`MNS040038` at yaw 0**, sitting
at `x 2931, y −488` — up against the north wall, where every one of the eighteen
neighbours is at **yaw −180**. Its front, and therefore its light and its label,
pointed into the plaster.

It came out that way honestly: it was built with an **island** unit selected, the
island runs at yaw 0, and a new object inherits the facing of whatever the run it
continues is facing. Then he dragged it to the north wall, which faces the other
way. Nothing was wrong at the moment it was created.

## Two things were missing, and one of them was a bug

### 1. There was no way to turn anything round

Every other placement decision in this engine can be corrected by dragging.
Facing could not be corrected **at all** — no rotate, no flip, nothing. That is
not a missing nicety; it is a state the engine can put an object into and cannot
get it out of.

`Panel.turn(degrees)` and three buttons: 90°, 180°, 270°.

* **About the middle of the object's own plan, not about its origin.** A unit is
  drawn from its origin forwards and backwards, so rotating about the origin
  swings the box somewhere else and the person has to re-place it. About the
  footprint centre it stays exactly where it is and only turns round — which is
  what a person means by "turn it".
* **Relative, not absolute.** There is no stored facing to set: the
  transformation *is* the facing, the same as it is for every object he has moved
  by hand. So the buttons say "quarter turn", never "face north".
* One `start_operation`, so one Ctrl-Z undoes it.
* It takes effect at once. It is not part of Apply, because it changes the
  INSTANCE and Apply rebuilds the DEFINITION — two different things, and putting
  a transform inside a geometry rebuild is how they get confused later.

The panel also now shows the facing it reads off the instance: `front faces −Y
(0°)`. **In model axes and not in compass points**, because this engine holds no
compass — the scene tabs are called north and east by a person, nothing in the
code knows which way north is, and a readout that guessed would be wrong in some
other kitchen. Anything not square to the axes says so rather than rounding into
a lie.

### 2. A shelf should never have been placed beside anything

Andriy's rule, and it is the right one:

> Я выделяю кабинет. Полка генерируется по задней стене, к которой этот кабинет
> приторочен.

A shelf is **not a run element**. It butts against nothing, it is cut to any
length, and it hangs wherever a person wants it — so "which side of the selected
unit" is the wrong question, exactly as it was for the sheet panel back on
2026-08-27 morning. What a shelf needs from the selection is **the wall**: the
plane that cabinet's back is against, and the direction it faces.

So `placement_transform` gains a third pre-run branch, before `placement_side`:

```
y = back - (new_unit['depth_mm'] || 0).to_f
```

The shelf's back lands on the selected unit's back — which is where the wall is —
and its own depth comes forward from there into the room. `x` stays zero for the
sheet panel's reason: the person places it, and the catalog prices a length
without an opinion about where it starts. No depth on the selected unit means a
refusal that names the reason, not a guess.

This also makes the facing right by construction rather than by luck: the shelf
inherits the transformation of the cabinet whose wall it is on, and it is on that
wall because that is what was selected.

## The shape of this, for next time

**Three rounds of "I don't see the light", three different causes, and none of
them was the one before it.** The variant never reached the drawing; then the
symbol was five pixels tall; then the object was back-to-front. Each fix was
necessary and none was sufficient, and the third was only findable *because* the
first two were done — you cannot notice that a label is inside a wall until
there is a label.

And the probe found the facing in one run, again. The model can be asked. It is
now twice in one day that a question put to the model beat a theory about it.

## Owed

* `turn` has no counterpart in the picker: a new object still cannot be given a
  facing at build time other than by inheriting one. That is right for a run
  element and probably right for a shelf now, but a free-standing object with
  nothing selected still lands at the origin facing −Y.
* Nothing checks that an object's facing agrees with its neighbours'. The probe
  did it by eye in one table; the engine could, and a warning on the panel would
  have caught this the moment it happened.
* This engine holds **no compass**. `claude/` has a `10_10_compass.rb` probe from
  an earlier day and the scene tabs carry wall names; none of it is in code.


---

## SUPERSEDED IN PART, 2026-08-28 — the buttons are gone

Kept rather than deleted (learned rule 9), because the reasoning above is worth
reading and the conclusion is worth knowing was wrong.

**§2.1 above — "There was no way to turn anything round" — described a real
defect, and the control it produced was still the wrong answer.** Andriy removed
the requirement the next morning:

> Уже не будет значения, где лицо, где не лицо. […] Я просто его разверну руками
> обычными инструментами со скетчапом. Потому что стены могут быть под разными
> углами.

The light now hangs under the **middle of the board's depth** (`Symbols#led_y_mm`
returns `depth/2`), so no symbol asserts a front and nothing in the drawing
depends on facing. With the requirement gone, `Panel#turn` and its three
quarter-turn buttons went too — they never served a wall at 37° anyway, and
SketchUp's own rotate tool serves every angle.

**§2.2 stands unchanged and is the half that mattered**: a shelf seats on the
wall the selected cabinet is against, in that cabinet's own frame. Right by
construction, no button required.

The full account is at the end of `findings-2026-08-27-lit-shelves.md`.

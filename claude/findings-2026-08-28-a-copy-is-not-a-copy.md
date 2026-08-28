# A hand copy was one object wearing two positions — 2026-08-28

> Когда я добавляю дополнительный элемент, клонирую полку — не становится
> уникальной. Если я убираю Light на одной полке, убирается и на второй.

Confirmed, and the diagnosis is exactly what he described.

## What was happening

Copy a component in SketchUp and you get **a second INSTANCE of one
DEFINITION**. That is normal and it is not a SketchUp defect — it is how a
component library works.

But **every fact this engine keeps lives on the definition**: the code, the
status, the mounting, the hinge side, the variants, the light. `Contract.write!`
writes to the definition. `rebuild_fronts`, `rebuild_plinth` and `Symbols.draw`
all rebuild the definition's contents. So `Apply` on either copy rewrote both,
and there was no indication that it had.

**SketchUp is not wrong to share. This engine was wrong to let it.** A unit here
is an **order line**. Two lines that cannot differ in hinge side, mounting or
light are not two lines — they are one line and a mistake waiting to be
delivered.

## What was NOT happening, and it is worth knowing

**The order was never wrong.** `86_export_run.collect` walks *instances* and
reads each one's definition, pushing one `attrs` per instance — so two instances
sharing a definition already produced **two rows** on the schedule.

That is the far worse version of this bug and it does not exist: a copied shelf
was always counted. Only the *editing* was shared. A check now pins the line in
`collect` that makes this true, because nothing else was guarding it.

## The fix

`Panel#apply` now calls `make_instance_unique!(inst)` before it touches
anything. Three details, and each of them is a way to get this wrong:

1. **Inside the operation.** So one Ctrl-Z puts the split back with everything
   else, rather than leaving a stray definition behind.
2. **Before `defn` is read.** `make_unique` replaces the definition the instance
   points at. `defn = inst.definition` used to happen at the top of `apply`;
   read there, the write would still land on the *shared* definition — the
   original bug wearing a fix. `defn` is now read after the split, and a check
   holds the ordering `start_operation → make_unique → read defn → write`.
3. **Renamed in this engine's convention**, `CESAR_<code>_<timestamp>`, rather
   than SketchUp's `…#1`, so the outliner stays readable.

A no-op when the instance is already alone — every unit the generator builds
gets its own timestamped definition, so sharing only ever arises from a hand
copy.

## THE ENGINE ALREADY KNEW THIS

`Generator#swap_corner_execution!` has carried the guard, and the reasoning, for
weeks:

```ruby
# Attributes live on the DEFINITION. If two instances share it, editing
# in place would silently re-article the other one too.
instance.make_unique if instance.definition.count_instances > 1
```

The panel never inherited it. **A rule discovered at one call site is not a
rule** — it is a local fix that happens to be right, and the next place that
needs it will not have it. A check now names both sites together so they cannot
drift apart again.

That is the same shape as learned rule 11 (a key written correctly that the
thing needing it is never given), one level up: **a precaution taken correctly
in one place and never generalised.** Worth watching for — the codebase is old
enough now that "somewhere else already solved this" is often true, and being
true is not the same as being applied.

## For the model as it stands

Copies made **before** this fix are still sharing definitions. They separate the
first time `Apply` runs on either one — which is the right moment, but it means
any pair Andriy has already made is still linked until he touches it. Nothing
needs cleaning up by hand; it resolves itself on first edit.

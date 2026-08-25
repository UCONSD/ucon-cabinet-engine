# Reserved Void — design spec v0.1

**Date:** 2026-08-25 · **Status:** ACCEPTED by Andriy the same evening. **The engine half is
built and green on 440 headless checks and UNTRIED IN SKETCHUP; the appliance half — В6, the
run gap — is NOT built.** · **HEAD at authoring:** `e01f2ef`
**Closes:** В6 (`claude/appliance-rules-decided.md`), the custom-sized front on printed
p.121/p.123 (`claude/findings-2026-08-25-tall-h210-appliance-columns.md` §5), and it names
the shape that printed p.414 is deferred on.

---

## 1. One shape, found three times

| where | the span | its extent | what divides it | drawn today |
|---|---|---|---|---|
| **above a housing** | vertical, housing top → row top | `section_top − opening_h` | filler, or an Open Shelf | **YES** — `VOID_ABOVE_*` |
| **В6 — a gap in the run** | horizontal, cabinet → cabinet | printed width, e.g. **1219** | the freestanding appliance | **no** |
| **the remainder in a column** | vertical, between fixed fronts | measured, e.g. **1125** | custom-sized front + appliance opening | **no** |

All three are the same object: **a span whose extent is known and whose internal division
is not yet decided.** Not a body. Not an absence either — an absence is what the drawing
already has, and it is exactly what gets built over.

> **A void is a reservation: the drawing owns the span without owning a body.**

**This is not a new idea in this repository — it is an existing one that was never
named.** `src/ucon_appliances/main.rb` `draw_void` already draws the first row: a
translucent box on `UCON_APPLIANCE_VOID`, carrying `VOID_H_MM`, `FILL_OPTIONS`,
`FILL_MATERIAL`, `SETBACK_MM` and the note *"TO BE FILLED — N mm"*, with the fill offer
resolved from `rules.json → void`. **The spec below generalises that; it invents nothing
about how a void looks or behaves.**

---

## 2. Ownership — and why §11 is not crossed

§11 of `appliance-rules-decided.md`: *observation is free in both directions; action flows
one way only, core → appliances.* A void could have broken that, and does not:

> **Whoever knows the extent draws the void.**

| void | extent comes from | owner |
|---|---|---|
| above a housing | the appliance's published opening | **appliances** (already) |
| a gap in the run | the appliance's published **width** | **appliances** |
| the remainder in a column | the **catalog page** — a registry fact | **engine** |

Neither module ever asks the other. The run gap needs the run's depth and the worktop
height, and the appliance module takes both **as parameters**, exactly as `place` already
takes `section_top_mm:` from its caller. The remainder needs no appliance at all until
somebody resolves it — until then the engine draws the whole span as one void.

**And the seam keeps doing what it already does.** `88_appliance_check.rb` compares a
drawn niche against a published opening, by observation. A resolved void is just another
niche to check. **No new direction of call is introduced by this spec.**

---

## 3. Contract — `object_class: 'void'`, and one new key

**Recommended, and each half is a separate decision:**

1. **`object_class` gains `void`.** It sits beside `appliance` and `appliance_front`,
   which are also things that are not cabinetry. A void's geometry is a box, so
   **`geometry_kind` stays `linear` and gains nothing** — `w`/`d`/`h` describe it exactly.
2. **`KEYS` gains `void_role`**, enum `above_housing · run_gap · front_remainder`.

`void_role` earns a key under §4.2 rule 6 — *a variant earns its own contract key only
when geometry reads it* — because **the role decides the datum and the fill offer**, and
both are read while drawing:

| role | datum | fill offer resolved from |
|---|---|---|
| `above_housing` | top of the opening | `rules.json → void` (threshold 120) |
| `run_gap` | floor | the appliance itself; nothing if it is never placed |
| `front_remainder` | top of the fixed front below | custom-sized front + the opening(s) |

Everything else a void needs is already in the key set: `code` is `null`,
`code_status` `PRELIMINARY`, `status` **`PLANNING`**, the extent in `width_mm` /
`depth_mm` / `height_mm`, the offer in `notes`, the reason in `source_ref`.

**A void is exported.** `85_export.rb` emits it as a line with no code and a visible
warning. An unmarked 1219 mm of run is a change order with a date on it; a line that says
*"1219 mm reserved, unassigned"* is a question somebody answers before the install.
**This is the whole point of the concept and it is the half most worth arguing about.**

---

## 4. Registry — a remainder is an entry in the stack, not a new field

`front_layout` already carries `gola_stack_top_to_bottom`, whose entries are
`{kind: 'front'|'zone', h_mm, role}`. **Promote that stack to the general form and allow a
third kind.** No new top-level field, no second way to say the same thing.

```json
"front_layout": {
  "kind": "horizontal",
  "stack_top_to_bottom": [
    { "kind": "remainder", "h_mm": 1125,
      "holds": ["custom_sized_front", "appliance_opening"],
      "appliance_class": "oven_h46" },
    { "kind": "front", "h_mm": 195 },
    { "kind": "front", "h_mm": 780 }
  ],
  "gola_stack_top_to_bottom": [
    { "kind": "remainder", "h_mm": 1125,
      "holds": ["custom_sized_front", "appliance_opening"],
      "appliance_class": "oven_h46" },
    { "kind": "zone", "h_mm": 30, "role": "intermediate recess" },
    { "kind": "front", "h_mm": 165 },
    { "kind": "zone", "h_mm": 30, "role": "intermediate recess" },
    { "kind": "front", "h_mm": 750 }
  ]
}
```

`heights_mm_top_to_bottom` stays exactly as it is — the shorthand for a stack with no
remainder, which is 708 of the 711 codes. **A type with a remainder declares the full
stack in both executions and no shorthand**, so a reader can never get a partial list and
believe it is complete.

**The remainder is execution-independent, and that is a check, not a comment.** 1125 in
both stacks above; 390 and 585 on printed p.123. Handle and gola leave the same hole to
the millimetre in all three articles, which is what makes the number real.

**`Export.fronts_in` needs no change** — it selects `kind == 'front'`, so an unresolved
remainder contributes no handle and no front line. That is correct: nobody can order a
front whose height nobody knows.

**The generator's sum check gets stronger, not weaker.** `60_generator.rb:540` today
raises when the heights do not sum to `h`. It becomes the invariant measured on printed
p.121-125:

> **Σ fronts + Σ zones + Σ remainders = height_mm**

Sixteen of sixteen codes on those five sheets satisfy it. A section that does not is a
misreading, and the raise is where it surfaces.

---

## 5. What changes, file by file

**Engine (core 0.79.0 — it changes what is DRAWN):**

| file | change |
|---|---|
| `20_contract.rb` | `object_class` += `void`; `KEYS` += `void_role`; `ENUMS['void_role']` |
| `50_registry.rb` | pass `stack_top_to_bottom` through, as `gola_stack_top_to_bottom` already is |
| `60_generator.rb` | the sum check admits `remainder`; a remainder entry draws a void box instead of a front |
| `70_symbols.rb` | a remainder band draws as an outline with no diagonal — it is not a front |
| `80_panel.rb` | the elevation preview shows the remainder as an empty band, labelled |
| `85_export.rb` | a void emits a warning line, no code |

**Appliances (0.2.0):**

| file | change |
|---|---|
| `main.rb` | `draw_void` takes a `role`; `place_set` gains `run_depth_mm:` and `worktop_h_mm:` and, for an item with a printed width and no full opening, draws a `run_gap` instead of skipping it |
| `rules.json` | `void` gains the `run_gap` offer; **`decided` date moves, the file's own clock** |
| `lib/appliances.rb` | `void` learns the second role; **no engine call is added** |

**`place_set` stops silently skipping.** It keeps listing what it did not place — that
report is right and stays — but an item with a printed width now leaves a marked span
rather than nothing.

---

## 6. Checks that must exist before this is believed

1. `test_contract.rb` — **a remainder stack sums to `height_mm`.** Run over every type
   in the registry, so a future section cannot forget.
2. `test_contract.rb` — **a remainder is execution-independent**: the handle stack and
   the gola stack leave the same remainder, per type.
3. `test_contract.rb` — **an unresolved remainder is never counted as a front**:
   `Export.fronts_in` returns the fixed fronts only.
4. `test_contract.rb` — **`object_class: 'void'` validates with `code: null`** and fails
   without `void_role`.
5. `test_appliances.rb` — **a run gap is drawn for an item with a printed width and no
   opening**, `DF48650C/S/P` being the case that opened В6.
6. `test_appliance_seam.rb` — **unchanged, and still 3-with-exit-0 when the package is
   absent.** If this spec makes the seam suite need both trees, the spec is wrong.

---

## 7. What this spec does NOT decide

- **The oven H.46 niche height.** Unknown, and deliberately so — the whole point of the
  remainder is that the catalog refuses to fix it. Nothing here invents 460.
- **printed p.414.** Same shape on the WIDTH axis. This spec does not extend the
  remainder sideways; it only stops pretending the shape is unique to one page.
- **`C68654` / `C68754`** — the one-recess article of printed p.121 pos 3. Elda question,
  independent of this.
- **Whether a void is selectable, snappable, or hidden by default in SketchUp.** A
  drawing question, to be answered in the model.

## 8. What was BUILT on 2026-08-25, and what was not

**Built and green (440 checks, 0 failures):** §3 in full, §4 in full plus a fourth stack
kind `appliance_opening` the spec did not foresee — a span whose division IS decided —
§5's engine column, and §6 checks 1-4. `Export.fronts_in` counts a remainder's
`fronts_within`, which §4 got wrong: how many fronts is PRINTED even where how tall is not.

**NOT built:** §5's appliance column in full — `place_set` still skips an item with a
printed width and no opening, so **В6 is decided and not yet closed**. §3's export line for
a void. §6 checks 5-6.

**NOT tried in SketchUp:** every line that draws.

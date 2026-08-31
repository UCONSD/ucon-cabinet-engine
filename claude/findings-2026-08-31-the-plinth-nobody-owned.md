# 2026-08-31 — the stone is not an order, the edges got a design, and one body
# in the kitchen belonged to nobody

## 0. THE CORRECTION FIRST, because two documents currently say otherwise

**Andriy, 2026-08-31: whether the worktop is ordered on this project AT ALL is
not decided.** The stone work is parked — not "later today", but stopped until
that decision exists.

Both `claude/handoff-2026-08-30-laptop.md` and the worktop row of
`claude/repo-state.md` say, in so many words, that the tops of 545 Avenida
Primavera **are an ORDER**. That was true of yesterday's intent and it is not
true today. Dated and added rather than erased (learned rule 9): the stamping,
the six pieces, the cut, the sink and the four parked edges all still happened
and are all still recorded correctly. What changed is one level up — whether any
of it becomes a purchase.

The practical consequence, and it is the reason this is not a footnote: **the
four `visible_side_edge = 1` cost nothing while the stone is not being bought.**
Debt 1 was blocking because 569 points were about to be paid; they are not.

## 1. THE EDGES: designed, agreed, and NOT built

The design question from the handoff was answered before the stop. Recording it
so it survives, because the reasoning cost more than the code will.

**Andriy's choices, 2026-08-31:**

- the edge count is asked **per END, two questions per piece**, not per piece and
  not per selection
- the edge question leaves the stone stamp **entirely** — article, band, group and
  finish are facts about a whole selection; an end is not
- the ledge's long finished edge (2398 mm) is **not recorded** until printed p.172
  is read

**And a defect found by reading, which the design depends on and which is live
right now.** `TopStamp.attributes_for` builds `variants` from scratch and
`Contract.write!` deletes any key the new attributes lack. `SinkMark` merges —
`variants_with` keeps foreign variants and rewrites only its own. The stone stamp
does not. **So re-stamping the west run today would silently delete
`sink_integrated_bowl_70x40x19`, the bowl that placed itself on 2026-08-30.**

Nobody has done it, so nothing is broken in the model. But the agreed design
makes the stone stamp run a SECOND time over pieces that already carry edges,
which turns a latent defect into a certain one. The rule to write is the one the
sink already follows: **every stamp rewrites its own key and leaves foreign
variants alone.** Prove it against the defect before trusting it (learned rule
12) — set a bowl, re-stamp, watch it vanish, then fix.

## 2. THE PLINTH NOBODY OWNED, and it is one cause with two symptoms

Andriy, 2026-08-31: *"пропал цоколь под холодильником"*. It had not.

Read, in three read-only drops (49, 51, 52), because the first two answers were
both wrong in an instructive way:

- 49 said the light was correctly tagged, so the code was not the problem
- 51 said the plinth group held **0 faces** — which was a defect in the PROBE, not
  in the model: `Geometry.box` puts the box in a NESTED group and the reader
  looked one level up. **The same shape as the 2026-08-30 lesson about reading
  the definition and not the instance: a reader that stops one level short is
  confidently wrong.**
- 52 descended and answered it in one line:

| | faces | material |
|---|---|---|
| plinth under `B80653` | 6 | `UCON_Finish_Aluminium_Black` |
| plinth under the fridge | 6 | **none** |

Not hidden, not on a hidden tag, `Layer0` shown in all eight scenes. **Unpainted.**
An unpainted white box under the fridge, in a kitchen whose plinth line is black
all the way along, reads exactly like a gap in the line.

**And the cause is not the paint.** That plinth is a `Plinth (REPRESENTATION)`
drawn as a top-level group with **no contract attributes at all**. `Retag` moves
only entities that answer `object_class_of`, so it skipped it; the painting pass
skipped it for the same reason. **One object, two passes, one root: a body with
no contract is invisible to every pass that walks the model.** It sat on `Layer0`
— the only cabinet-ish body in the kitchen that did — and it sat unpainted, and
both facts have the same sentence behind them.

Fixed in the model (run 53, ARMED): six faces painted, outer group moved to
`UCON — Cabinets`, inner box left on `Layer0` exactly as every working plinth
sits inside a tagged parent. **The CAUSE is not fixed.** The representation
plinth must carry its tag and its material at draw time, and the passes must be
able to pick up a body that carries no contract. Until then the next kitchen
repeats it.

## 3. THE SCENES DID NOT KNOW ABOUT THE NEW TAGS — and this is rule 19 again

Andriy: *"подсветка на лайтах почему-то всегда активная"*.

`Symbols.show_mode` was correct: it sets `led.visible = front.visible`, so Off
turns the light off. The model agreed — at the moment of reading, all three
opening tags were hidden. And `UCON — Lighting` was **visible**.

Probe 50 found why, and it is not in the code at all. **All eight scenes
remembered `Lighting` as SHOWN**, including ISLAND_Clear, ISO and HERO where the
three opening tags are remembered hidden. `TAG_LED` was created after those
scenes were saved, and SketchUp adds an unknown tag to an existing page as
visible. So: press Off, the light goes out; click any scene, the scene restores
its own snapshot and the light comes back. `UCON — Sink marks` had exactly the
same history — eight scenes out of eight.

**This is learned rule 19 wearing different clothes.** Rule 19 says a pass over
the model is not a rule about the model. This says: **a new TAG is not a rule
about the scenes that already exist.** A scene is a saved snapshot of tag
visibility, so every scene predating a tag holds an opinion about it that nobody
formed. Candidate learned rule 21 — NOT added, because adding a rule means
editing `claude/rules.md` and the status document and that is Andriy's call.

Fixed in run 53: each page now remembers `Lighting` the way it remembers
`Opening (front)`, and `Sink marks` the way it remembers `Opening (plan)`. Read
off each page's own state rather than typed in, so a page whose opening tags move
later will need the same pass again — which is the honest shape of the problem,
not a workaround for it.

**Still owed in code:** `show_mode` does not know about `SinkMark::MARK_TAG` at
all. Until it does, every Off leaves the sink mark on, and the scene fix above
will be undone by hand the next time somebody re-saves a scene.

## 4. THE GOLA IS NOT A PART OF A CABINET

Andriy, 2026-08-31, and it settles a question this file opened badly:
*"голая ручка, она длинная, идет хлыстом, и она просто идет как мост через все
транзитом."*

The symptom was that the recess does not read over the dishwasher door. Measured:
a base unit's fronts stop at z 850 with the unit top at 880, leaving the empty
30 mm gola zone; `V80630` also stops at 850. **The zone is there.** What is not
there is anything behind it — the dishwasher door has `FRONT`, `PLINTH` and its
symbols and **no `CARCASS`**, correctly, because it is a door and not a cabinet.
On its neighbours the carcass behind the empty 30 mm is what makes the recess
read at all.

So the drawing fix is not a back panel for the dishwasher. **The profile is one
continuous run-length element that bridges over the dishwasher**, which is also
exactly what the ORDER has said all along: `GOL001` is written with `qty: nil`
and the note *"qty = running length of the run, not of this unit"*. The drawing
and the order want the same object, and the engine currently draws neither —
it draws an absence per cabinet.

Not built. It needs the run, which is M2.1a, and it is the same unfinished thing
as owed item 7 in the handoff (gola by the linear metre).

## 5. WHAT WAS ACTUALLY WRITTEN TODAY

One armed run, 53, and nothing else. Everything before it was read-only, and
probe 50 doubled as the second read-only drop that learned rule 20 asks for:
49's numbers did not repeat, so nothing had escaped a rollback.

- fridge plinth painted `UCON_Finish_Aluminium_Black`, 6 faces
- fridge plinth outer group `Layer0` -> `UCON — Cabinets`
- eight scenes taught `Lighting` and `Sink marks`

All three read back and verified in the same run (learned rule 15).

## 6. AND A DELIVERABLE THAT IS NOT IN THIS REPOSITORY

A LayOut-ready cabinet schedule was built from
`545_Avenida_Primavera_Kitchen_Preliminary_Model_v0_1_1_order.csv` — 59
positions, the engine's provenance columns dropped, hand as a column instead of a
row, gola and handles moved to a summary sheet. It is a paste-into-LayOut
artefact and deliberately not committed here; the export it came from is the
record.

The finishes note to Elda went out the same day, as a reference and not as
questions, per the handoff's rule that Elda questions wait for the drawing. It
names the worktop as NOT confirmed, which §0 above is the reason for.

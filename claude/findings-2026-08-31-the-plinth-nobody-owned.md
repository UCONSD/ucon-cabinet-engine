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

---

# Later the same day — the report exists, and the order form was found

## 7. A CORRECTION TO §2, AND IT IS MINE

§2 above and the commit message of `4cdbf04` say the fridge plinth is "drawn as
a top-level group with no contract attributes". Literally true, and it reads as
though THE ENGINE draws it. It does not. `Plinth (REPRESENTATION)` appears
nowhere in `src/` — the string does not exist in the engine at all. The object
is a ComponentInstance on `Layer0`, sitting among `48 WOLF` and `Group#1…#7`,
which is to say it was made by hand, with wording copied from the generator's
own note text.

So there is no draw-time fix, because there is no draw time. **And the cause is
one size larger than §2 says: not "the representation plinth is outside the
passes" but "anything drawn by hand is outside every rule the engine has."**
Retag will not move it, the painting pass will not paint it, and a contrast pass
would not reach it either.

Dated and added (learned rule 9). §2 stands as the record of what was believed
when it was written.

## 8. THE REPORT, AND ITS FIRST RUN

`core/68_report.rb`, and a button on the palette. Three buckets — ours, declared
not ours, unowned — the outermost unowned body as one row, wrappers descended
into, empty containers counted and not listed. The rules are pure and decided in
the suite; only the survey and the window have heard of a model.

First run on 545 Avenida Primavera: **unowned 4, ours 68, declared not ours 0,
empty groups 1.**

| | size | tag | faces |
|---|---|---|---|
| `48 WOLF` | 1219,2 × 928,4 × 742,6 | Layer0 | 0 |
| `Plinth (REPRESENTATION)` | 18 × 100 × 1220 | UCON — Cabinets | 0 |
| `Group#1` | 6503,8 × 3048 × 5981,1 | Layer0 | 41 |
| `Group#5` | 6503,8 × 0 × 5981,1 | Layer0 | 1 |

**The plinth is still on the list, and that is the sentinel working.** It was
tagged and painted by hand this morning, which fixed how it looks and made no
rule responsible for it. A report that went quiet at that point would go quiet
exactly when the problem was papered over.

**DECLARED IS EMPTY, and that is the finding.** Two of the four — the client's
range and the room — plainly belong in it. Nothing in this model has ever been
declared not-ours by a person: the only bodies on the placeholder and reserved
tags are the engine's own, and those carry a class, so they count as ours. The
bucket that keeps the list short has never been used, and until the second
action exists it cannot be. That is what to build next, before the stamp.

**AND A SECOND READER DISAGREED WITH THE RULES, twelve hours after the lesson.**
Probe 54's own dump asked `declared?` before `owned?`, and so printed the
appliance niche and the run gap as declared, while `counts` — asking `owned?`
first, as the rules do — counted them as ours. The shipped rules were right and
the throwaway reader was wrong. Nothing was broken, and it is written down
because it is the same shape as the definition-versus-instance lesson of
2026-08-30: **a second reader that re-implements a precedence instead of asking
for it is wrong on the day the precedence matters.**

## 9. THE ORDER FORM EXISTS, AND THE ENGINE ALREADY MAKES HALF THE ORDER

Asked for, researched, NOT BUILT.

**`Maxima 2.2 order form`, printed p.64-65 / PDF 67-68 of
`CESAR - 1 Project Guidelines.pdf`.** There is one per collection — Intarsio,
Unit and N_Elle have their own — so the form is COLLECTION-SCOPED and a single
generic form would be a rule generalising past its evidence (learned rule 4).

**It cannot be filled programmatically.** The file declares an AcroForm and
holds **zero fields and zero widget annotations across all 300 pages**: the
checkboxes are drawn artwork. So the engine mirrors the form, field for field;
it does not fill Cesar's file.

**And the reason this is not a convenience.** The book's own order flowchart
says a new order is FOUR documents: *order form, list of elements, dimensional
drawing, technical data sheets of appliances.* The engine already produces the
second (the CSV export) and the third (LayOut). The order form is the missing
quarter, and Cesar is the one who defines the set. Beside it: confirmation takes
5-10 days *"based on completeness and clarity of order information"*, and a
modification after confirmation costs 150 euro / 300 points.

**What would fill itself today**, from the decisions of 2026-08-29 and 08-30:
carcass Grigio Fumo (the form prints exactly three, and it is one of them);
Legrabox Cenere; L-shaped grip recess in Aluminium Black with no grip edging on
the door; wall unit edging Black; plinth Aluminium H.10; the door as First wood
veneer AND structured lacquer at once; the framed glass door with oak fabric,
which the form prints as its own line; every appliance in the CUSTOMER'S column.
The modularity lists — base 39/48/58,5/78/84, tall 138/198/210/222/234, wall
36/48/60/72/84/96/120 and their depths — are the same numbers the engine already
validates against.

**One line answers §0 whether we like it or not.** Under WORKTOP: *"this field
must be filled in even if the top is not provided by Cesar."* Thickness and
depth are owed to the order whether or not the stone is bought from them.

**And one sentence repeats six times:** *"if the kitchen has various finishes
they must be specified for each single element in the list or on the drawing."*
A mixed-finish kitchen is handled by the element list and the drawing — the two
documents the engine already makes — and not by the form. Which is also the
shape of the unsent Elda question about the mixed arrangement.

Next step is a MAP, not a panel: every field of the form marked as one of three
— the engine knows it, the engine could know it, ask a person. The panel waits
on Elda's reply and on the worktop decision.

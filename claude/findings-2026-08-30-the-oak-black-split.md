# 2026-08-30 — the oak / black split, and the four panels that had already decided half of it

**Laptop, `macbook-pro-4-local`, core 1.6.0, HEAD `3cd3e63` at the start.**
Three read-only probe runs (105, 106, 107 unarmed) and four printed pages.

The last of the thirteen finish questions. `claude/decisions-2026-08-29-finishes.md`
ends by naming it: *"AND THE SPLIT ITSELF IS NOT DECIDED. Which units are oak and
which are black was not part of these thirteen answers. It is the next question
and it is a drawing question."*

---

## 0. The question was smaller than it looked, and the catalog is why

Before any taste enters: **six panels in this model can only ever be oak, and
they were ordered that way days ago.**

`DZ731Q` ×4 (the island's whole back), `DV731Q` ×2 (both island ends) and
`DV061Q` ×2 (the east run's end, and its top band's end) are **price group A —
First wood veneers**. printed p.218 and printed p.220 print that group as exactly
seven Rovere: Sbiancato, **Nordico**, Mediterraneo, Fossile, Dark, Corvino,
Cortado. There is no lacquer in group A at all. `tools/test_contract.rb:8394`
already refuses any other family, in as many words: *"a letter that stops meaning
oak must fail here rather than in an order."*

So both visible ends of the island, the island's entire seating side, and the
end of the tall wall were oak before the question was asked. **The split was
never "which units are oak" — it was "which of the two masses these panels
already belong to also gets oak fronts."** Put that way it has three answers
instead of dozens, and Andriy took it in one pass.

**This is the second time on this project that the catalog answered a question
recorded as open.** The +30 top overhang was the first.

---

## 1. The decision

**Andriy, 2026-08-30: both masses. The east wall floor to 3040, and the island.**

Asked separately and answered separately: the seven `SD0631` in the band at 2440
above the tall run are **oak too** — the east wall is one plane, and its top
band's own end panel `DV061Q` is group A and could not have been black anyway.

| | | m² of front |
|---|---|---:|
| **OAK — `RR09 Rovere Nordico`**, First veneer, F6 | east wall floor to 3040: `C00151`, `C92640`, 4× `C90635`, `BE0151`, 7× `SD0631`, `UCON-BESP-001`; island: 4× `B80653` | ≈ 9,3 |
| **BLACK — `LX19 Nero`**, structured lacquer, F6 | west run: `AU110D`, `B80565`, `B81087`, `V80630`, `B70501`, `B70150`; south base: `B80501`, 2× `B80753`, `B70151`; south uppers: `PF0151`, 2× `BE0151`, 9× `SD0631`, `SD0930` | ≈ 7,3 |
| **neither** | 3× `TF0641` — black frame, black silk-screen, transparent glass, decided 2026-08-29. Not a door finish. | — |

**43 objects carry a front and all 43 are assigned.** Probe 106 proved it against
the model rather than against this table: every one of the 43 plan lines matched
exactly one object, nothing with a front was left over, and nothing without a
front was planned.

Also painted oak, and not a choice made here: the six Cesar veneer panels above,
and the three Sub-Zero overlay panels, which carry no article, are ours, and
stand in the east wall.

---

## 2. The guard that mattered, and it was asked of the model

**A hand copy shares its definition until `Apply` splits it.** `SD0631` falls on
BOTH sides of this split — seven oak on the east wall, nine black on the south.
If those instances shared one definition, painting the `FRONT` group inside it
would paint both sides and the split could not be drawn at all.

Probe 106 asked. **Three definitions in the whole model are shared, and each is
wanted in one finish only:** `B80653` ×4 (all oak), `B80753` ×2 (both black),
`SD0631` ×2 (both black). Every other object has its own definition. No conflict,
nothing needs making unique.

**Asking cost one read-only run. Assuming would have cost a repaint of the wrong
wall**, and the assumption that felt safe — "the SD0631s are copies of each
other" — is the one that was false.

---

## 3. Where the split can live, and it is not the data

**The Object Contract has 31 keys and not one of them is a finish.** Confirmed
again on 2026-08-30, probe 105: `finish keys = []`. There is nowhere in the model
to write that this door is RR09 and that one is LX19.

And **the printed order form does not carry the colour either.** printed p.65,
the PLAIN DOOR block, offers only the FAMILY — `Structured` under lacquer,
`First` under wood veneer — and both may be ticked at once, so a mixed kitchen is
a shape the form expects. What it never asks for is which element is which. Every
finish block on that page repeats the same sentence:

> *"if the kitchen has various finishes they must be specified for each single
> element in the list or on the drawing"*

**So the drawing is not one of two ways to record this split. With no contract key
and no field on the form, the drawing and the element list are the only two, and
the drawing is ours.** That is what makes two SketchUp materials the deliverable
and not a nicety.

`tools/probe_inbox_hold_107.rb` paints them: `UCON_Finish_RR09_Rovere_Nordico`
and `UCON_Finish_LX19_Nero`. **They are named for the finish, not for the kind of
body.** All nine existing `UCON_*` materials say *this is a front* or *this is a
carcass*; these two say *this is what was ordered*, which is the first time the
model has recorded an order fact in a material.

Unarmed rehearsal, run 18: 19 oak fronts, 21 black fronts, 11 bodies, 3 `TF0641`
untouched. Rolled back, as designed.

---

## 4. Owed, and named rather than quietly carried

- **The paint does not survive a rebuild.** The generator writes
  `UCON_Front_White` at build time — `60_generator.rb:387` and `:577`,
  `80_panel.rb:708`. Anything rebuilt comes back white. This is the standing
  *"the model is not recomputed when the engine changes"* debt acquiring a second
  victim, and it is now cheap to argue that the contract should carry a finish
  key after all — a v2.5 revision, not a patch, and Andriy's call.
- **The two `MNS040038` shelves have no finish.** They sit at x 3123…3997 in the
  black zone, but they are Linear Elements sold per linear metre, not doors, and
  no finish block on printed p.65 covers them. Unassigned on purpose; asking is
  cheaper than guessing.
- **The mixed-arrangement footnote is now maximally sharp.** printed p.13 puts
  any arrangement with First veneered fronts onto the Prime band — 7 in Maxima.
  This split puts ≈ 9,3 m² of First veneer on the two biggest masses in the
  kitchen. It does not change the question, but it removes any chance of the
  answer being academic.

---

## 5. What this cost, and one mistake worth keeping

**A file dropped into `tools/probe_inbox/` is executed within seconds.** Probe 106
went in carrying a syntax error and the bridge ran it, failed it, and filed it in
`done/` before it could be checked. No harm — a `SyntaxError` paints nothing —
but the habit is wrong. **Syntax-check outside the inbox, then move the file in.**
The inbox is hot; it is not a place to keep a draft.

And the day's real lesson, which is section 4 of
`claude/findings-2026-08-28-panels-the-letter-is-a-lookup.md` and now carries a
dated correction there:

**A document that describes a guard is not the guard.** That file states that a
check refuses the group-A codes. The check that exists refuses group B — the
exact opposite — and the two drifted apart inside a single day, on the same
subject, in the same commit's work. The model, the held probe, the registry and
the suite all agreed with each other and only the prose disagreed. **Four
artefacts against one sentence, and the sentence was the one a next session would
have read first.**

---

## 6. Later the same day — the split moved, and two catalog questions were answered

### The upper tier is oak, all of it

Andriy, after looking at the painted model: **the whole upper tier is oak.**
Black survives only on the base runs and on the CUSTOM boxes over the range,
which is where the hood goes. That moves nine objects from the table in section
1: `PF0151`, both `BE0151`, the five `SD0631` at 2440 (103, 703, 1303, 1903,
2513 — the first two share one definition) and `SD0930`.

**The model already holds the new scheme**, painted by hand before it was
written down. Probe 110 reads it back: those nine carry `RR09` on their faces.
Three objects also picked up an oak material on the INSTANCE while their faces
stayed black — `AU110D`, `B80501` and the lower `MNS040038` — which is the
invisible-paint case in reverse and needs clearing when the plan is rewritten.

### Painting inside the group is the right gesture, and the corner proved the probe wrong

Andriy painted by hand to test it, and the test found a real defect. Every
material in this model sits at **depth 2** — on the faces inside a group, not on
the group. `UCON_Front_White` is now on zero faces.

**`AU110D` is the case worth keeping.** 20 faces with no material, 6 black. The
six are the door. The **8×8 fixed corner front panel** — which the code's own
description names — is among the twenty, because run 107 matched sub-groups whose
name contains FRONT, DOOR or DRAWER, found the door, and reported the object as
painted. **A per-object "something was painted" is not a check.** The 518 faces
still carrying no material at all are the carcasses, which nothing has ever
painted, and they are most of what reads as white in the viewport.

### Panels: a black panel is orderable, and it is a different family

printed p.217, Volume 3 — **lacquered** panels, a separate chapter from the
veneered ones on p.218/220. Group **C — Structured lacquers** lists **Nero**, so
a black side panel lands inside the `LX19 Nero` decision rather than adding a
third finish.

| | code | points/m² | the oak equivalent |
|---|---|---:|---|
| 1,8 lacquered ONE side | `DZCO00` | **250** | `DZ731Q` 343 |
| 1,8 lacquered two sides | `DZCP00` | 362 | — |
| 2,2 lacquered two sides | `DZCP22` | **339** | `DV731Q` 549 |
| 1,2 lacquered two sides | `DZCP12` | 345 | — |

Three things this page settles:

- **Black is cheaper than oak here**, and not marginally: 250 against 343 on the
  one-sided, 339 against 549 on the two-sided 2,2.
- **A lacquered panel has no grain**, so it has no grain-direction article. The
  veneered ones do, and that is why the east run's end had to be `DV061Q` —
  vertical grain caps at 1200 and that end is 2440. **That trap does not exist on
  a lacquer panel.**
- **The two-sided 2,2 (339) is cheaper than the two-sided 1,8 (362).** Printed,
  and counter-intuitive enough to be worth writing down before someone "corrects"
  it.

**And the custom boxes over the range have no side panels at all.** Nothing of
`object_class: panel` exists between x 1903 and 3123. This is not a repaint, it
is two new order lines.

### The glass cabinets: decided, and it dodges a second oak

printed p.314 — `TF0641`, 60 wide, d.35, **2 glass shelves**, and *"cannot be
reduced in width, height or depth"*. Three independent axes: the door (the closed
15-row list on printed p.65), the shelves (Bronze +15, Fumè +15), and the
interior, which is the CARCASS block and may be specified per element.

The interior was the problem. The carcass block offers only one wood —
**`Rovere Bruno`** — which is not `RR09 Rovere Nordico`. Dressing the inside of
the vitrines in oak would have introduced a SECOND oak, one shade off the fronts,
which reads as a mistake rather than a choice.

**Andriy, 2026-08-30: `Black frame with black silk-screen printing / transparent
glass WITH OAK FABRIC`,** printed p.65, **+95 per 60 cm door, +285 for the
three.** The black frame decision of 2026-08-29 survives untouched, oak enters
the upper tier, and the interior stops being a question because the fabric closes
it. `Grigio Fumo` stays the carcass everywhere.

### A false alarm, recorded so it is not raised again

`TF0641` is drawn 375 deep against a catalog `d.35`. Reported as a possible
error; **it is not one.** Andriy: the catalog depth is always the CARCASS, and
the drawn body is the carcass plus the front. The engine already knows it —
`Standards::FRONT_T_MM = 22` plus `FRONT_GAP_MM = 3` — so 350 + 25 = 375 exactly
as 620 + 25 = 645 on every base unit in this kitchen. Both constants carry
provenance: the thickness `:elda_confirmed`, the gap `:derived_from_elda_dimensions`.

**The lesson is small and cheap: a catalog dimension and a drawn dimension are
different measurements, and the difference is a constant this repository already
holds.** Before calling a drawn number wrong, subtract the ones the engine adds.

---

## 7. And then the whole drawing got its finishes, because only fronts had ever had one

Run 112, armed, verified by run 113 asking the model afterwards. **836 of the
model's 848 faces now carry a finish. The other 12 are the two appliance
openings, and a niche is drawn and never ordered — domain rule 8.**

### What was actually wrong: the engine only ever painted fronts

Sixteen sub-group names exist inside UCON objects. Six of them carried no
material at all, and **five of those six had a finish decided on 2026-08-29 that
had simply never been drawn**:

| body | count | faces | was | is |
|---|---:|---:|---|---|
| `CARCASS` | 52 | 312 | nothing | **Grigio Fumo** |
| `PLINTH` | 20 | 120 | nothing | **Aluminium Black** (H.10) |
| `FRONT (frame: DECLARED)` | 3 | 30 | nothing | **Aluminium Black** |
| `FRONT_GLASS` | 3 | 18 | nothing | **Oak fabric** |
| `FILLER_8X8` | 1 | 8 | nothing | the corner's own finish, **black** |
| `PANEL` | 3 | 18 | instance only | **oak** |
| `APPLIANCE_OPENING_600` | 2 | 12 | nothing | **nothing, correctly** |

So "the model looks unpainted" was never a bug in the split. **Fifty-two white
carcasses and twenty white plinths were what Andriy was looking at**, and the
finishes for both had been chosen a day earlier.

The rules are keyed on the sub-group NAME, not on a list of objects, so a unit
built tomorrow gets its carcass and plinth painted without anybody editing a
plan. Only the front finish is per-object, because only the front finish is a
choice.

### The corner, and why the old report was green

`AU110D`'s fixed 8×8 corner panel is called `FILLER_8X8`. Run 107 matched
sub-groups whose name contains FRONT, DOOR or DRAWER, found the door, painted it,
and reported the object done. **A per-object "something was painted" is not a
check.** The check now asserts that no FRONT-family body — `FILLER_8X8` and
`PANEL` included — belongs to an object without a finish, and refuses before
painting anything.

### The one that would have shipped, caught by adding up

The first rehearsal printed `CARCASS -> Grigio Fumo, 312 faces` and looked right.
312 is 52 objects, and only six objects in this model have no `CARCASS`. So the
veneer panels have one too: **the generator names every solid body `CARCASS`,
and for `DV731Q`, `DZ731Q`, `DV061Q` and the two `MNS040038` shelves that group
IS the visible object** — both island ends, the island's entire back, the tall
run's end. A blanket carcass rule turns the oak half of the split grey and
reports a clean 312 while doing it.

`object_class` is what separates them: a panel and a shelf have no carcass, so
their `CARCASS` group takes the object's own finish. The exception is pinned by a
check, because removing it is silent.

**Three times in one session a count looked correct and hid a defect** — "an
object was painted", "the group carries the material", "312 faces". Each was
caught by a different means and none by the count itself. The verification is now
`tools/probe_verify_finishes.rb`: fifteen named assertions about named bodies at
named positions, and not one total.

### Decided in passing, and still assumed

- **The two `MNS040038` shelves are painted oak, and nobody has decided that.**
  They are Linear Elements sold per linear metre, no block on printed p.65 covers
  them, and oak matches the tier they hang in — Andriy painted the lower one that
  way by hand while testing. **One line in the plan to change.**
- The vitrine glass is **opaque** in the drawing, on Andriy's instruction: a
  see-through pane would show the inside, and the inside is the thing the Oak
  fabric exists to close.
- `Aluminium Black` is deliberately a different value from `LX19 Nero`. One is
  anodised metal and the other a lacquered front, and on an elevation they should
  be tellable apart.

### Still owed, unchanged by any of this

The paint does not survive a rebuild — the generator writes `UCON_Front_White`
at build time. Everything above is now riding on that, not just the split, which
strengthens the case for a finish key in the contract rather than weakening it.

**And the black side panels for the custom boxes are not drawn.** Nothing of
`object_class: panel` exists between x 1903 and 3123. Two new order lines,
`DZCO00` (250/m², one side) or `DZCP22` (339/m², two sides) in structured
lacquer Nero — not the DZ7/DV7 veneer chapter, which holds no lacquer at all.
Next job.

---

## 8. The black sides of the hood block: a surcharge, not a panel, and the catalog says it in Andriy's words

Asked for "black side panels for the customs", the obvious answer was the
Linear Elements chapter — an applied panel, `DZCO00` at 250/m². **That was the
wrong chapter**, and Andriy said so before it was ordered: *"это не просто
панель, это боковина, которая заменена. Вместо каркаса идёт лакированный
материал."*

**printed p.553, Volume 2 — "Surcharge for finishing side panels, 1.8 cm thick |
REPLACING STANDARD SIDE PANEL."** Read off a 160-dpi render, not off
`pdftotext`, and the numbers agree between the two.

Two mechanisms exist and they are not interchangeable:

| | applied panel | finishing side panel |
|---|---|---|
| where | Volume 3, Linear Elements, printed p.217–220 | Volume 2, printed p.553 |
| what it does | added ON TOP of the carcass side | **replaces** the carcass side |
| priced | per m², minimum 0.5 m² | **surcharge by height × depth × band** |
| dimension | adds 18 mm to the outside | **changes nothing** |

For a cabinet side that is merely visible, the surcharge is the right mechanism.
The applied panel is for a return that is not a cabinet's side — which is exactly
what the island's ends and back are, and why `DV731Q` / `DZ731Q` were correct
there.

### The page confirms the instinct, and removes a choice

> *2 visible sides* — Melamine, Technomat, Fenix NTA, Fenix NTM, Unicolor.
> *1 visible side and reverse side in carcass colour* — Silk-effect, Gloss,
> **Structured lacquer**, Metallic-effect, and all four veneer categories.

`LX19 Nero` is a structured lacquer, so it falls in the second line and **cannot
be two-sided at all**: the reverse comes in the carcass colour, Grigio Fumo.
There was never a decision to make. Andriy's *"нет смысла делать в другой
цвет"* is what the catalog already enforces.

### And it saves the hood match, which the applied panel would have broken

The black block over the range is x 1903…3123 — **1220 wide, and `PW482418` is
1219**, 48 inches. A replacing side is 18 mm where 18 mm already was, so the
block stays 1220. An applied `DZCO00` on each cheek would have made it 1256 and
quietly lost the match.

### Where it does not reach, and the decision taken

Depths run D.35 / D.62 / D.67 / D.72 / D.77. **At every depth from 62 up the
heights jump 60 → 78; H.72 exists only at D.35.** The two custom boxes are
610 × 720 at a 620 carcass — `UCON_SD0631_REDRAWN_3` and `_4` — so **D.62 H.72
is not a row in this table.** The rest of the kitchen fits: an ordinary `SD0631`
is D.62 H.60, band 6, **87** each.

**Andriy, 2026-08-30: the cabinet is custom, Elda decides.** Not forced into the
grid, not re-dimensioned to reach H.78 (113 at band 6), not guessed. *"У неё есть
Metron и она делает новые модификации. Не будем изобретать."* **It goes into the
material specification as a NOTE**, with the geometry stated and the mechanism
named, and she prices the modification.

That is the right call for a reason worth writing down: **the unit is already
outside the catalog, so its side is outside the catalog by the same amount.**
Solving the side inside the grid while the box it belongs to sits outside it
would have produced a confident number for the wrong object.

### Consequences, one for the order and one for the drawing

**Nothing new is built.** A replacing side changes no geometry, so there are no
new objects and no new `object_class: panel` bodies. The earlier note in section
7 — "two new order lines between x 1903 and 3123" — is **superseded**: it is one
note to Elda, not two panels.

**But two faces are now the wrong colour.** The outer cheeks of the block — the
left face at x 1903 and the right face at x 3123 — carry a finishing side in
`LX19 Nero`, while run 112 paints the whole `CARCASS` group Grigio Fumo. The
block projects 265 mm past both neighbours (`TF0641` at 375 deep, the shelves at
380), which is the entire reason the sides are finished at all, so those two
faces are seen. **Owed: paint them black, per face rather than per group.**

### Owed, and argued rather than just listed

**This table is not in the registry, and it should be.** Five depths × fourteen
heights × eleven bands, and an exposed carcass side anywhere in this kitchen now
has a printed price that nothing in the engine can look up. Learned rule 14 — a
rule written in prose is a rule no code can read — and this one has just been
written in prose. Andriy's call when.

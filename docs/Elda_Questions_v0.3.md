# Questions for Elda — v0.3 (2026-08-20)

Supersedes the Q1–Q8 list in `ucon-cabinet-engine-status.md` and the unsent
draft letter v0.2. Rebuilt after `Cesar_Estimate_Teardown_v0.1.md` (estimate
30829/30830, CONFIRMED) and `Reconciliation_Round1_v0.1.md`.

**The main change is not the list — it is what to ask for.**

Seven of the open items no longer need Elda's judgment. They need another
estimate. Every Metron output is a CONFIRMED source, and one more estimate
answers more than five emails would. **The primary ask should be two or three
past estimate PDFs from unrelated projects, not a questionnaire.**

Preference for what those projects contain, in order of value: a corner run · a
75 cm dishwasher · a lift-up or push-up wall door · a sink from printed p.45 ·
a modified-width unit.

---

## CLOSED — do not ask

| was | answer | source |
|---|---|---|
| **Q1** door-version (78/75) notation in orders | The axis does not appear in an order at all. Every base is H 780. Gola is expressed by composition-level `GRIP RECESS TYPE / ORIENTATION / FINISH` plus per-row `HANDLE TYPE`. | estimate header + all base rows |
| **Q6** does an appliance panel in a gola kitchen order its own GOL profile | Premise wrong. **Nothing** orders a GOL profile. `GOL001` / `GOL002` are their own rows priced per linear metre — a property of the RUN. | rows 39, 40, 43, 45, 62, 63, 74, 75 |
| **Q7a** "1 rh or lh door" for WALL units | The door's hinge, and the hand is an order variant. One code serves both. `PD0631` appears with `OPENING DIRECTION: Left` and with `Right`. | rows 15, 18, 25, 27 |

---

## ANSWERABLE FROM MORE FACTORY OUTPUT — ask for estimates, not answers

- **Q4** — sinks, printed p.45, codes 90 vs 91. Needs an estimate containing a
  p.45 sink.
- **Q8** — the wall pages price *Servo Drive mechanism* and *Power adapter* but
  give no article code. Needs an estimate with a lift-up or push-up wall door.
  (Note: the wall units in 30829 are all side-hinged, so this composition could
  never have shown it.)
- **E1** — `FRN` codes name a size bin while the L/H/P columns give a different
  actual piece (`FRN007770597` → 531 × 777; `FRN013170747` → 607 × 1300). The
  deltas are not constant. More `FRN` rows across projects would establish the
  rule without asking.
- **E5** — how is running length for `GOL001` / `GOL002` computed? Values of
  1198 against a 1200 module suggest an end condition consumes 2 mm, but that is
  inference from one project.
- **R1** — we used `995626` for the waste unit; the factory ordered `B80665
  WASTE BIN BASE UNIT WITH PULL-OUT DOOR`. Hypothesis: `99…` codes are
  accessories/components (cf. `996MB6` interior drawer, `9837350` Miele filler),
  so we put an accessory code where a unit code belongs. Confirmable from any
  estimate with a waste unit.
- **R4** — `SD0631 TALL UNIT TOP ELEMENT WITH DOOR` sits above each tall unit.
  Is a top element a separate article by rule whenever a tall unit runs to
  ceiling, or was it a composition choice? Two more tall runs would settle it.
- **Q2 (remainder)** — LEGRABOX runner length is a header choice plus baked into
  the interior-drawer article (`996MB6` = H.10, depth 50, for W.60). What remains
  is whether runner length is ever ordered as its own line. Visible in any
  estimate with a different drawer depth.

---

## GENUINELY NEEDS ELDA — ranked

### Load-bearing

**1. (was Q7b) The corner execution letter.**
For wall units the hand turned out to be an order variant, not part of the code.
Does the same hold for CORNER units, or are S and D genuinely different
articles? Our corner placement ships behaviour that rests on the second reading:
pointing at a wall silently substitutes the sibling article. **If the corner
behaves like the wall unit, shipped code is wrong.**

**2. (was Q3) Modification limits.**
We now know the mechanism — a `..99` carcass plus `WIDTH REDUCTION: Yes`,
flat +138,00 (`PB1299` 1067 from a W.120; `PD0699` 534). What is not known:
- the minimum width and height a modification can go to
- whether reduction is priced flat regardless of how much is removed
- the ambiguity in position 989346

**3. (was Q5) The 75 cm dishwasher.**
Which side does `GBBF01` go on? Elda's note — integrated dishwashers usually
need no filler, most models work with a continuous 100 mm plinth — is about the
60 cm case in this project. The 75 cm case is unresolved.

**4. Front panel maximum width.**
Elda changed the hood-cabinet front because fronts are max 1200 mm wide. Is 1200
a hard fabrication limit for every front, or specific to that panel type? This
becomes a validation rule that fires before we export, so its scope matters.

### Housekeeping

**5. (was E3) `Smontato`.**
Elda already flagged this: is "unassembled" the same as flat-packed, and does it
apply per unit or per composition? It carries a surcharge (+22 on the unit, +39
on the carcass) so it is priced, not cosmetic.

**6. (was E2) `Note:: 06`.**
Confirm this is the price band, and that it is inherited from the composition
rather than chosen per row. Elda has already said band 6 covers both glossy
lacquer and first-category veneer.

**7. (was E4) Wall-unit depth.**
`PB1299` and `PD0699` are wall carcasses at depth **620**, not 350. Is depth free
per order on a `..99` article, or does it carry its own depth set?

---

## Not for Elda — our own work

- **R2** — `UI0657` vs `UI0658` was a distinction we invented; the factory used
  `B80657` for all eight. Check whether anything in `registry/cesar/` carries
  that split.
- **R3** — the reconciliation join by cumulative running length is untested
  across a corner, where `span_mm` counts a corner's wasted space as occupied
  and the factory may not.
- The invented prefixes `UI` / `UH` are exactly what the registry supplies
  (`B8` = d.62, `B7` = d.35). No question needed; the engine fixes this by
  construction.

---

## Framing note

The earlier plan was to send questions once the exporter produced a verified
order sheet. That plan is now partly obsolete: **the order sheet already
exists** — hers. What we hold that she does not is the reconciliation: a matched
input/output pair showing which 12 positions a competent human missed and which
13 codes came out wrong.

That is worth showing eventually. It is not worth showing yet — 45 % on codes is
not a demonstration of depth. The target before any such conversation is level 1
(carcasses and articles) at 100 %, which the current registry can already
deliver.

For now the correspondence should stay what it is: a designer asking a factory
representative practical questions, plus a small request for reference material.

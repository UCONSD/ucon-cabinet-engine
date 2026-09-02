# Three levels of validation, and what can actually be auto-filled

Andriy's structure, 2026-09-02, written down before it is built. Nothing here is
code yet. **Sections marked NEW are from this session; the rest restates what the
repository already settled, so this file can be read alone.**

**Add this file to `claude/README.md` in the same commit — `go.sh` refuses a
commit that leaves a new note out of the index.**

---

## The structure

A project is checked three times, and the three checks are not variants of each
other. They answer different questions, read different inputs, and fail in
different ways.

| | asks | reads | fails when | emits |
|---|---|---|---|---|
| **L1 — NKBA** | is this a correct American kitchen? | our model only | a distance is wrong | compliance report |
| **L2 — Factory** | will Cesar build this? | our article list + the catalog rules | a code or rule is wrong | the order package |
| **L3 — Installer** | can WE build and ship this? | our model + the article list | something is **missing** | pre-flight checklist |

**L1 and L2 catch errors. L3 catches omissions.** That difference decides how
each is built: a validator for the first two, a completeness pass for the third.

**And L3 is the one with cash impact.** A wrong dimension is caught on a drawing;
a forgotten touch-up kit is caught on site and costs a second freight from Italy.
By the decision order — cash first — L3 deserves to be built first even though it
is the least technical of the three.

---

## It is a loop, not a pipeline

L2 changes geometry. On 545 the factory took two H.720 wall units and returned
**one custom W.1220 hood cabinet** (estimate 30833, row 8, `PE1299`). That is a
different mass over the range, so the cooking-surface landing areas and the work
aisle are no longer the ones L1 approved.

**After any factory-driven change, L1 runs again.** Otherwise the project holds a
compliance report for a kitchen that no longer exists.

---

## Who wins a disagreement

Written down so the case Andriy named — *"либо с ней не соглашаемся"* — is
decided by a rule and not by mood.

- **Anything about the FACTORY** — which code is emitted, what an article
  contains, how a variant is expressed, price — **Metron wins, always.** It is
  their system; our model is a guess about it.
- **Anything about the OBJECT** — measured site dimensions, clearances, panels
  for the client's appliances, installation access — **we win.** The 8 mm
  ceiling gap is exactly this: Cesar's guidance says 25–30 mm, we install it and
  nothing restricts that wall, so the drawing stands.

**A divergence we accept is recorded, with its reason and its date.** Otherwise
the next comparison flags it again, and in three projects nobody can tell whether
it was a decision or a defect. Same failure the repository already knows from
`findings-2026-08-27-lit-shelves.md`: a fact written as a story instead of as
something a check can hold gets rediscovered the expensive way.

---

## L1 — NKBA · NEW

**31 kitchen guidelines**, every one carrying an Access Standard. The fifth
edition is aligned to **IRC 2024** and **CSA B652 (2023)**. The freely published
summary sheet is the 2022 one, i.e. **before** that revision — the fifth edition
has to be bought before any threshold is hard-coded.

**Do not copy their prose.** Cite by number — *NKBA Guideline 6* — and hold only
the number and the rule. Figures are not protectable; their wording is.

### About 23 of the 31 are computable from the model today

Everything geometric: doors and door interference (1, 2), work centres and the
triangle (3, 5), **work aisle 42″ / 48″** (6), walkways 36″ (8), seating and knee
space (7, 9), landing areas at sink, refrigerator, cooking surface, microwave and
oven (11, 16, 17, 22, 23) and their combination rule (24), preparation area (12),
dishwasher within 36″ of the sink (13), auxiliary sink (14), countertop frontage
158″ (25), storage totals (27, 28), a functional corner unit (29).

**Eight need data that is not in the model:** ventilation 150 cfm (19) and
cooking-surface safety (20) come from the appliance datasheets; GFCI within 6′
(30) from MEP; 8% glazing (31) from the architecture; countertop edge treatment
(26) from the stone spec. Guideline 15 (two waste receptacles) is half-answered
by the model — `B80565` is in the order — and half by the client's habits.

### Two severities, not one

Some of these are **code** (IRC / NEC) and cannot be waived. The rest are **NKBA
recommendation** and can be waived with a recorded reason. A report that grades
them the same becomes noise and stops being read. Same shape as the scope work:
a waiver is a decision with an author and a date, not a suppressed line.

### The unit trap

NKBA is imperial, Cesar is metric, the engine is metric. **Hold the thresholds in
inches as canonical and convert at comparison time.** 42″ written down as "1050"
fails a legal kitchen by 17 mm, silently, forever.

---

## L2 — the factory, and what can be auto-filled

### An order is four documents, not one

From the book's own flowchart: **the order form + the list of elements + the
dimensional drawing + the appliance datasheets.** The engine already makes the
middle two. So L2's output is a package, and the form is one quarter of it.

### Cesar's PDF cannot be filled. This is settled.

`order-form-maxima22-recon-2026-08-31.md`: the file **declares an AcroForm and
contains zero fields across 300 pages.** There is nothing to write into.

Coordinate stamping — drawing text at fixed positions over their pages — is
technically possible and is **rejected**: no anchors to align to, 300 pages to
calibrate, and Cesar revises the book, at which point every coordinate is wrong
and nothing says so. It is also their document.

**The engine mirrors the form and never writes into Cesar's file.**

### What the mirror can fill by itself — most of it

The whole settings block is decided and lives in the model: MODELLO, FRONT
FINISH, GRIP RECESS TYPE / ORIENTATION / FINISH, HANDLE TYPE, CARCASS FINISH,
DRAWER STRUCTURE / FINISH / SIDE TYPE, ELEMENT TYPE, FOOT TYPE, PLINTH FINISH.
Thirteen finishes, settled 2026-08-29. Pure lookup, no judgement.

The element list is already emitted. The appliance datasheets are assembled by
fetching the specific model on request, which is the existing practice.

### What the mirror cannot fill, in three different kinds

**1. The form's shape does not hold this kitchen.** Three worktop depths — 650,
700, 380 — and one printed Depth field. No engine solves this; it is a question
for Elda, already question 3 on the unsent list.

**2. Blocked on a fact that has not arrived.** The mixed-arrangement band (see
below), which glass sits behind the oak fabric, whether the INSIDE GRIP EDGING
FOR JUMBO DRAWERS block applies to a handleless kitchen, which column the sink
belongs in, and whether the worktop is bought on this project at all.

**3. Never automatable, by nature.** Anything `undecided` on scope — who installs
the client's appliances — and anything that is the customer's choice, such as kit
type L or O.

**Rule: the mirror prints what it does not know.** A blank field is a question
nobody answered; a field the engine silently omitted is a question nobody knows
exists. Same rule, from the other side, as blocking a sheet on `undecided`.

### NEW — the estimate PDF is machine-readable, and that closes the export gap

Elda confirmed on 2026-09-01 that Metron cannot produce an Excel or text export.
**It does not need to.** Estimate 30833 was extracted whole with `pdftotext
-layout`: row number, code, description, L / H / P, unit, quantity, points,
surcharge, amount — plus the variant sub-lines (`OPENING DIRECTION`, `WIDTH
REDUCTION`, `GRAIN DIRECTION`) and the component sub-lines (`FRN`, `RPN`, `FNC`,
kit codes). Nothing was lost. The file is machine-generated by Metron and stamps
its own template version (`Version : 2.70`), so a parser is written once.

**Structure a parser must respect:** `Furnishing` headings split the estimate by
finish, but **row numbers are global across the whole composition** — 30833 runs
1 to 69 with no gaps, interleaved between the oak block and the black block. The
row number is the position key; the finish comes from the nearest heading above.

**This is what makes L2 mechanical.** Our mirror is what we send; her parsed
estimate is what came back; L2 is the diff of the two. The mirror's real purpose
is not to be a document — it is to be the left-hand side of that comparison.

### NEW — the band question is CLOSED: band 6

The p.13 mixed-arrangement footnote puts any arrangement carrying First veneered
fronts onto the Prime band — **7** in Maxima — and this kitchen is the mixed case,
with ≈ 9,3 m² of First veneer on its two biggest masses. **It does not bite.**

All 17 catalogue codes in estimate 30833 were checked against the band columns of
`sources/factory/CESAR - 2 Kitchen System.pdf` (October 2021, **Update 05|26**).

**Exact on band 6, nine codes:** `AU110D` 560 · `B70151` 127 · `B70501` 257 ·
`B80501` 276 · `B80565` 1075 · `B81087` 882 · `C00151` 330 · `PF0151` 174 ·
`V80630` 214.

**Within 6 points of band 6, four more:** `B70150` 159 / 160 · `B80653` 719 / 720 ·
`B80753` 798 / 797 · `C92640` 876 / 870.

**Band 7 fits nothing** — `B80501` band 7 is 317 against 276 printed; `B80653`
band 7 is 802 against 719. The question is closed and needs no email.

`TF0641` is not an anomaly: glass-door fronts are priced on a five-column table,
not the eleven-band one, and 449 is its first column.

### NEW — and the limit this exposes: we cannot compute the price

Three codes reconcile to **no** band column:

| code | estimate | band 6 | note |
|---|---|---|---|
| `C90635` | 1.504 | 965 | kit `996OL6` prints 584 in the book and 584 in the estimate; 965 + 584 = 1.549, not 1.504 |
| `PD0151` | 275 | 146 | +129, nearly double |
| `SD0631` | 321 | 304 | band 7 is 338 — it lands **between two bands** |

Plus the four off-by-one-to-six above. The differences are far too small to be a
band and far too varied to be one cause: either Metron runs a later update than
our 05|26, or it folds some surcharges into the `Punti` column instead of
printing them in `Magg.`

**So the boundary is here, and it should be written into the design before anyone
starts a calculator: our extracted prices validate a BAND, they do not reproduce
Metron's arithmetic.** The price stays the factory's. Our side of the L2 diff is
**codes, dimensions and composition — not sums.** A sum that differs by four
points is not a finding; a code that differs is.

Reconciliation script: `~/rec.py` on the laptop, outside the repository. Runs
against any estimate in about a second.

---

## L3 — the installer, and the invisible order

The parts that never appear in the design and are never missed until they are
absent. **They must be derived from the model, not remembered from a list.**

| what | derived from |
|---|---|
| finished side panel | every carcass side exposed in the model (`FNC`, `DV` in 30833) |
| edging | every exposed shelf and panel edge, in the front finish |
| extra feet | run length ÷ foot spacing, plus every unsupported panel corner |
| touch-up kit | one per finish used in the order — 545 has two |
| gola end caps and corners | every termination and every direction change of the profile — `GOL030`, `GOL031`, `GOL032`, `GOL034` |
| plinth joints and corners | same, on the plinth run |
| profile and plinth joints | run length ÷ **bar length** — blocked, see below |

### L1 (bar length) blocks this level

We have been holding the bar-length question as a warehouse problem. It is not.
Without it there is no way to count joints, connectors, or the true number of
linear metres, and **L3 cannot close.** It is the most expensive unanswered
question we have, and it is already with Elda.

### The by-others schedule belongs here

Named in the 2026-09-01 handoff and unscoped: the schedule for the GC, emitted
from the same lookup that prints the sheet notes so the two cannot disagree. It
is coordination, not production — L3, not L2.

---

## Order of work, proposed

1. **The estimate parser.** L2 has no left-hand side without it, and the test
   file already exists. Independent of whether 545 goes ahead.
2. ~~The band lookup~~ — **done 2026-09-02, band 6, see above.** What it left
   behind is a reconciliation question, not a budget one.
3. **L3 completeness pass.** Highest cash impact; partially blocked on L1 (bar
   length) but most of the table above is derivable today.
4. **L1 NKBA.** Needs the fifth edition bought first. Build the ~23 geometric
   checks; leave the eight data-dependent ones as declared gaps rather than
   silent passes.
5. **The mirror.** Last, because two of its blocks are still waiting on Elda, and
   because by then the parser will have taught us what the factory's own
   vocabulary actually looks like.

---

## Open, and blocking

- **L1 bar length** (profile and plinth) — blocks L3 joint counting. With Elda.
- **Three worktop depths, one Depth field** — blocks the mirror's worktop block.
  Unsent.
- ~~Mixed-arrangement band~~ — **closed 2026-09-02: band 6.**
- **Three codes reconcile to no band** (`C90635`, `PD0151`, `SD0631`) — a
  reconciliation question against the book edition, not a pricing question.
- **Is the worktop bought at all** — one level above the engine. Andriy's.
- **Who installs the client's appliances** — blocks a sheet by design.
- **NKBA fifth edition** — not yet purchased.

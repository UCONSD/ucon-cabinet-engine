# The divergence register — 545 Avenida Primavera against estimate 2026/30833

Opened 2026-09-02, companion to `claude/recon-2026-09-02-model-vs-30833.md`.

**Why it exists, in one sentence from the spec:** without it the next comparison
re-reports the same lines and nobody can tell a decision from a defect.

**Two kinds of entry and they are not alike.** An **ACCEPTED** divergence is a
difference we have decided to keep; the next diff should stay quiet about it. An
**OPEN** one is a difference nobody has decided; the next diff should keep
raising it. **Nothing here goes to Elda** — the order does not change until the
client approves the budget and the design retainer is in hand.

Every entry carries the date it was decided and by whom, per learned rule 9: a
correction is dated and added, never an edit that erases the reading.

---

## A. Accepted — we keep our reading, and the diff should stop reporting it

| id | what | ours | hers | why accepted | date / by |
|---|---|---|---|---|---|
| **D1** | The `P` column of a filler, a front or a panel | the piece's own thickness — 22, 18 | the **depth of the run** it belongs to — 620, 350 | Two correct answers to two different questions. Metron's column says where the piece lives; ours says what it is. The join drops the third dimension for anything whose smallest dimension is a thickness | 2026-09-02, this session |
| **D2** | The 8 mm ceiling gap | 8 mm | Cesar guidance 25-30 | Nothing restricts access on that wall and we manage it at installation. Settled our way before this diff | 2026-09-02, spec §5 |
| **D3** | The vitrine run's end | one `DZ731Q` 375×960 end panel | three `FNC109600350` side panels, one per `TF0641` | Two ways to finish the same run. Both close. It is 18 of the 23 mm of D4 | 2026-09-02, this session — **but the finish question itself is Elda Q4 and unsent** |
| **D4** | The south-west upper run's length | **1903** = 85 filler + 3×600 + 18 panel | **1880** = 80 filler + 3×600 | Arithmetic on both sides, and the whole difference is her narrower filler plus our end panel. We measured 1903 and the range reservation starts there | 2026-09-02, this session |
| **D5** | The run gap over the range | a `void` reservation, 1220×920×620, printed beside the order | no row at all | A factory must not receive a line nobody can make. Decided 2026-08-25, `appliance-rules-decided.md` §12 | 2026-08-25, Andriy |
| **D6** | A corner unit's width | `width_mm` is **nil** on `AU110D` | 900 | Unknown is `nil`, never a number we did not take from a source; a corner's width belongs to the node. Measured 900 in the model, and it agrees | learned rule 7 |

---

## B. Hers wrong — we are authoritative, recorded, raised only after the retainer

| id | row | what | ours | hers | the argument | date |
|---|---:|---|---|---|---|---|
| **H1** | 3 | `B70151`, the filler closing the south base run at its east end | **124** | 104 | **Her order disagrees with itself.** Her `PD0999` above is 770 and her `B80753` below is 750, so her upper filler at 104 closes the tier at 3997 and her lower one at 104 closes at 3977. Ours are 105 and 124 and both close at 3997/3998. The 20 mm is the width difference between the two units, and the lower filler has to absorb it | 2026-09-02 |
| **H2** | 50 | `MNS022000` shelf, east of the range | `MNS040038`, **40 thick, 380 deep** | `MNS022000`, 22 thick, 645 deep | Shelf thickness and depth are a design decision of ours, and the model holds the drawn body. **Her depth is the run's, not the shelf's** — the same reflex as D1 | 2026-09-02 |
| **H3** | 51 | the second shelf of the pair | as H1 | as H1 | as H2 | 2026-09-02 |

**And a caution attached to H2/H3, not a fourth entry:** `repo-state.md` owed 10
says the finish of these two `MNS040038` is **an assumption, still flagged** —
painted oak. So the shelves are ours on the dimension and unsettled on the
finish, and the second half is not this register's to close.

---

## C. The 20 mm family — one shape, four appearances, not yet one explanation

Kept together because a single cause would close all four at once, and because
three of the four are the same sign.

| where | ours | hers | note |
|---|---|---|---|
| the two boxes over the range → her `PE1299`, row 8 | 610 + 610 = **1220** | 1200 | 1220 is the width of the range reservation |
| the box above the fridge → her `PB1299`, row 43 | **1220** × 313 | 1200 × 333 | row 43 is untouched by instruction; the geometry is recorded, nothing is acted on |
| the south run's closing filler, row 3 | **124** | 104 | H1 |
| her own two fillers at that end, rows 3 and 4 | — | 104 and 104 | they cannot both be right against her own 770 and 750 |

**Not resolved, and deliberately not guessed.** Her SKP was not read this
session; a solid either stands at 1220 or it does not, and that is the one
measurement that would settle the whole column.

---

## D. Still open, and the diff must keep raising them

| id | rows | what | who decides |
|---|---|---|---|
| **O1** | 46, 47, 52, 53, 57, 58, 63, 68, 69 | panels: we specified `DZ731Q`, one side veneered; she quoted `DV731Q` / `DV061Q`, two sides | Elda Q1 — **unsent**, and the only open item that moves the number the client approves |
| **O2** | 43 | `PB1299` quoted in `RR09` where our schedule makes both boxes over the range `LX19`. **And the geometry says it is not a box over the range at all** — 1200×333×620 against our fridge-top box at 1220×313×620 | Elda Q2 — unsent. If the geometry is right the finish contradiction may dissolve on its own, because the east wall is oak |
| **O3** | 2, 4, 18, 19 | fillers at d.350 in a d.620 run | Elda Q3 — unsent |
| **O4** | 12, 14, 17 | `TF0641` frame finish not printed, and each carries an `FNC109600350` side panel that is not in our schedule | Elda Q4 — unsent. Also D3 |
| **O5** | 31, 32 | the appliance fronts: her code says H.1977 W.747, her printed size is 734×1807, our panel is 730×1810 | Elda Q6 — unsent. The **code** is hers and is applied; the size stays ours |
| **O6** | 47, 69 | the 0,5 m² panel minimum — both billed at it, row 69 being only 1217×194 | Elda Q7 — unsent |
| **O7** | 28 | a front 607×717 in `LX19` positioned inside the oak island, with nothing in our model at that size | **nobody yet.** Her SKP, then the estimate PDF's sub-line structure |
| **O8** | 5, 7-9, 11, 13, 16, 43-45 | which custom rows still need Cesar's feasibility sign-off — 9 766,60 € of 45 745,53 € is `ELEMENTO A DISEGNO` | Elda Q8 — unsent |

---

## E. What is NOT in this register, on purpose

**Prices.** Three codes reconcile to no band column and the reason is unknown;
`three-level-validation-2026-09-02.md` settles that our extracted prices validate
a **band** and do not reproduce Metron's arithmetic. A price difference is
therefore not a divergence we are entitled to record.

**The shape of her `FRN` / `RPN` sub-lines.** How Metron splits a custom position
into component rows is its business. It becomes ours only where it changes what
our model must contain — which is `recon-2026-09-02-model-vs-30833.md` §6.3, and
that is stopped for an estimate rather than improvised.

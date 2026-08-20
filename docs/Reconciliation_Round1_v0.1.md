# Reconciliation — manual package vs. factory estimate (Dadvar Residence)

First run of the loop that M1.10 exists to serve:

```
we draw  →  Elda reads the drawings  →  she builds the order in Metron
         →  her estimate comes back  →  we compare
```

**The exporter is not the order.** The order is whatever leaves Metron. Our line
list will never reach production. It therefore does not need to reproduce
Cesar's format and does not need to be complete — it needs to be
**reconcilable**: same granularity, same codes, so that a difference means
something.

Sides compared:
- `Bobby_410_Alta_Vista_Preliminary_Layout_v0_2.pdf` sheet 2/9 — **26 legend rows**, hand-assembled
- `ESTIMATE 2026 / 30829` — **36 numbered furniture rows + 29 child rows = 65 furniture lines** (plus 53 surface/profile rows, out of scope for this comparison)

## The join key works

The two sides share no identifier: ours are `B-01`, `W-05`; hers are `Riga 1…89`
tied to her own composition. The join has to be geometric.

**It holds.** Both documents state the same run totals:

| run | manual sheet 3/9 | factory elevation |
|---|---|---|
| wall run | 5979 mm | 5979 (1) |
| island | 4880 mm | 4880 (600×6 + 1200 + 40 + 40) |

Within a run, the width sequence matches position by position — the island reads
600 · 600 · 600 · 1200 · 600 · 600 · 600 on both sides. **Join by run + cumulative
length along the run, then by order within the run.** No other key is needed and
no manual sorting was required to produce the table below.

This is the one thing that had to be proven before writing any exporter code,
and it is now proven on a real project.

## Result

| | count |
|---|---|
| manual rows | 26 |
| positionally matched | **24** |
| — of which the code was exact | **11 (45 %)** |
| — of which the code was wrong | 13 |
| present in the factory order, absent from ours | **12** |
| present in ours, dropped by the factory | 2 |

## Class A — wrong code (13 rows), and the failure mode is narrow

| ours | factory | occurrences |
|---|---|---|
| `UI0657` | `B80657` | 5 |
| `UI0658` | `B80657` | 3 |
| `UH1200` | `B71200` | 4 |
| `995626` | `B80665` | 1 |

**Nine of the thirteen had the correct numeric tail.** `UI0657` → `B80657` and
`UH1200` → `B71200` differ only in the invented prefix `UI` / `UH`.

And the correct prefixes confirm the grammar already recorded in the status doc:

```
B8 0657   600 × 780 × 620      second digit 8 = d.62
B7 1200  1200 × 780 × 350      second digit 7 = d.35
```

**The depth digit 7/8/9 = d.35/62/67 is now verified against a real order**, not
just read from the catalog.

This is the cheapest possible class to eliminate. The registry supplies exactly
the thing that was invented here. Every one of these 13 rows would have been
correct by construction.

Two sub-cases that are not prefix errors:

- `UI0657` and `UI0658` were treated as two different articles; the factory used
  `B80657` for all eight. A distinction we believed in does not exist.
- `995626` for the waste unit is not a base-unit code at all. The factory ordered
  `B80665 WASTE BIN BASE UNIT WITH PULL-OUT DOOR`. Worth checking against the
  registry's waste rows — this may be an accessory code used where a unit code
  belongs.

## Class B — missed positions (12)

| factory | what it is | why it was missed |
|---|---|---|
| `V80630` ×1 | fully-integrated dishwasher door | treated as appliance `A-06` only; the Cesar-ordered door was never listed |
| `SD0631` ×2 | tall unit top element with door | drawn in elevation (2320–2920 band), absent from the legend |
| `PB1299` ×1, `PD0699` ×2 | hood surround carcasses | present on sheet 7/9 as custom elements, absent from the legend |
| `FRN…` ×6 | fronts as standalone rows | no concept of a front as an orderable line |

**The dishwasher case is the important one.** An appliance was recorded, its
Cesar companion was not. That is precisely the `companion_refs` shape, and it is
the class of error that costs a return trip to the factory.

**The hood case is a different failure and a worse one.** Those items WERE on
sheet 7/9 — `Custom Hood Incert`, `CESAR_CUSTOM_UPPER_W1067_H600_D620…` — but
never reached the legend table. The drawing and the schedule disagreed with each
other. A generated schedule cannot disagree with the model it was generated
from; this class disappears by construction rather than by knowing more.

Also missed, beneath the matched rows: `996MB6` interior drawer ×4,
`FND205630329` bottom panel with profile ×4 (mandatory companion of every
`PG0631`), `SCSE035H4` ×2, `RPN`/`DVN`/`KCAS01`.

## Class C — real constraints (1 substitution)

Elda changed the hood-cabinet front because **a front panel is max 1200 mm
wide**, substituting two hinged doors. Not our error — a fabrication limit we
had no way to know. It becomes a validation rule that fires before export.

Same class, not yet triggered: the floor-to-ceiling swing door max
L 850 × H 2780, and the flag on the island overhang possibly needing custom
supports.

## Class D — factory errors (0)

None found in this round. Recording the class anyway: it is the only one for
which showing her our line list has any value, and its being empty is itself
worth knowing.

## Dropped by the factory (2)

`B-15` (`B41200`, H.58.5) and `B-16` (`Custom 42"`) do not appear. Not an error —
the pantry side is explicitly out of scope in Elda's note, pending measurements.
**Scope exclusions must be visible in the reconciliation, not silent**, or they
will be re-reported as missing on every subsequent run.

## What this fixes about the exporter's specification

**Compare in levels, and declare what is not compared.** Rows 37–89 are plinth
running metres, gola running metres, square-metre panels, tops and splashbacks.
The engine does not produce them and should not pretend to. A flat 26-vs-118
comparison reports ~90 differences that are not differences.

Proposed levels:

1. **Carcasses and articles** — comparable today. This round: 24 matched, 11
   codes correct.
2. **Companions** — `V80630`, `FND205630329`, `996MB6`, `SCSE035H4`. Comparable
   as soon as `companion_refs` are emitted.
3. **Fronts** — the `FRN` layer. Needs the size-bin question (E1) answered first.
4. **Not compared** — running metres, square metres, workmanship surcharges,
   points and pricing. Declared explicitly in the output.

**Target for the next round: level 1 at 100 % on codes.** That is achievable with
the registry as it stands, because every Class A error was an invented prefix
where the registry holds the real one.

## Open, from this reconciliation

- **R1** — `995626`: is it an accessory code that we used where a unit code
  belongs? Check the registry's waste rows against `B80665`.
- **R2** — `UI0657` vs `UI0658` was a distinction we invented. Where did it come
  from, and is anything else in the registry carrying it?
- **R3** — the join by cumulative length worked on two straight runs. It is
  untested across a corner, where our `span_mm` counts a corner's wasted space as
  occupied and the factory may not.
- **R4** — `SD0631` top elements sit above the tall units. Is a tall-unit top
  element a separate article by rule, or was it a choice she made?

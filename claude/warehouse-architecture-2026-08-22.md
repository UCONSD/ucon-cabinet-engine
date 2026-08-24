# The warehouse — where an order becomes a number

Design note, 2026-08-22, from Andriy's account of what the project is for.
**Nothing here is implemented.** Recorded now, built on demand — the same
discipline as `claude/options-architecture-2026-08-20.md`.

> **Revised the same day.** The first version of this note said the two kinds of
> warehouse item are told apart by `um` — piece goods PZ, linear goods ML. That
> is wrong, and §2 now says why: the plinth is sold by the PIECE and its
> quantity is derived from a LENGTH. One example (the gola profile, where both
> answers happen to be "linear") was generalised into a rule. Rule 4, caught by
> reading the estimate teardown instead of trusting the note.

> **Extended 2026-08-23 — see §8.** The first element that is *nothing but*
> warehouse contribution arrived: a filler. It settles how a non-opening element
> enters the warehouse, and it closes two questions §7 left open.

## 0. The principle it comes from

The project exists to produce **printed drawings an installer and an architect
can work from**, in CAD Drawings Style. That is why a cabinet is an envelope,
why a handle is not drawn, why an opening is a symbol rather than a leaf.

**But a schematic drawing is not a reduced order.** We still order the handle,
the grip recess, the plinth, the drawer inserts. They simply have no business
being modelled into the cabinet: nobody needs eight handles drawn on eight
cabinets to read a sheet.

So there are **three kinds of object**, not two:

| | drawn | ordered | example |
|---|:--:|:--:|---|
| the furniture | ✓ | ✓ | carcass, front |
| **the warehouse** | ✗ | ✓ | handle, grip recess, drawer insert, bin kit |
| the placeholder | ✓ | ✗ | appliance niche — the client's machine |

Half of this already works. The niche is drawn and never ordered, and the
exporter skips it with no special case at all: it has no `code`, and orderable
means *carries a code*. The warehouse is the mirror half, and it has been
missing.

**The plinth sits in both rows and that is correct.** Its schematic geometry
**stays visible** — confirmed by Andriy — because the plinth line is how an
installer reads where the base sits. What it lacks is its order side.

## 1. What the warehouse is

A **hidden tag, its own scene, parked away from the kitchen** — conditionally
on the floor, off to the side. It holds the things that are bought but not
drawn, so the drawing stays clean and the order stays complete.

**It is GENERATED from the units, never typed by hand.** A cabinet already
records what it needs; the warehouse is that record laid out in space. Which
means it can be deleted and rebuilt at any moment and can never drift from the
model. A hand-filled warehouse would be a second place where the truth lives,
and this project has spent one day watching what that costs.

## 2. TWO AXES, not one kind of split

This is the load-bearing part, and it is where the first draft was wrong.

### Axis 1 — how the article is SOLD (`um`, a catalog fact)

`PZ` piece · `ML` linear metre · `MQ` square metre. Printed: p.616 and p.621
say `– per lm.` beside `GOL001` and `GOL002` in the catalog's own words. The
estimate's UM table says the same and adds `MQ` for panels.

### Axis 2 — how the QUANTITY is DERIVED (ours, and this is the warehouse's job)

| derivation | means | example |
|---|---|---|
| **per host** | count the things that need it | a handle per front, a bin kit per waste unit |
| **from a length** | measure along the RUN, across joints | grip recess, plinth, grip edging |
| **from an area** | measure a surface | a finished panel (`DZAK22`) |
| **by a printed rule** | the catalog states the calculation | Servo Drive kits, printed p.566 |

### The axes CROSS, and the plinth is the proof

| article | sold | derived | so the warehouse must |
|---|---|---|---|
| handle `M00001` | PZ | per host | put one object per piece — 8 cabinets, 8 handles |
| grip recess `GOL001` | **ML** | from a length | total the run, express it in metres |
| **plinth** | **PZ** | **from a length** | total the run, then work out **how many pieces** that is |
| panel `DZAK22` | MQ | from an area | total the area |

The plinth is the case a single "piece or linear" split cannot express: **sold
by the piece, counted from a length.** Turning its length into a number of
pieces needs the length of one piece and an offcut allowance — which is exactly
the *"ограничение по метражу"* Andriy named, and it is not a property of any
cabinet.

**So `um` says how to WRITE the quantity; the derivation says how to COMPUTE
it.** Conflating them is what produced the wrong first draft.

### Why this settles a question we left open this morning

The exporter emits `qty` as **null** for a linear line, noting that the quantity
is measured along the run. That was right, and for a bigger reason than we knew:
**the answer may not even be a length — for a plinth it is a piece count.** No
object can hold it, because it depends on the whole run, the article, and a
cutting decision.

**The warehouse is where a composition-level quantity becomes a number.** That
is the real reason the order should be read from it: not because the warehouse
is a second copy, but because it is the only place the question can be answered
at all.

```
units  ──►  companion lines (per object, resolved from the registry)
                   │
                   ▼
        WAREHOUSE BUILDER  (sees the whole model)
                   │
     per host   from a length   from an area   by a printed rule
                   │
                   ▼   expressed in the article's own um
     warehouse: hidden tag, own scene, parked aside
                   ▼
                 ORDER
```

## 3. AXIS 3, and it decides what may be in the warehouse at all

**Whose line is it — ours to order, or the factory's to generate?**

`docs/Cesar_Estimate_Teardown_v0.1.md` lists a **component layer**: codes the
registry has never seen, which Metron explodes out of our article — `FRN`
fronts, `RPN` shelves, `DVN` dividers, `FND` bottom panels, `SCSE` housings,
`KCAS` drawer kits. The options note already closed that: *we do not order
them.*

**`ZOCC` — the plinth — is in that component list**, described as *"plinth, per
linear metre"*, with `ZOCC011 FRONT PLINTH H.10` as the example, and the
estimate header carries `PLINTH FINISH: Matt Aluminium` and `FOOT TYPE: H.100
Mm` as composition axes.

**And the same document contradicts itself**: its UM table (line 71) files the
plinth under `PZ` with units, fronts and tops, while its component table (line
201) calls `ZOCC` per linear metre. Both statements are ours, not the factory's,
and the estimate PDF is not in the repo to settle which reading is right.

That matters more than the wording, because it decides whether the plinth
belongs in the warehouse **at all**: a warehouse holding something Metron
generates from the composition header would order it twice.

**Nothing is built on either reading.** It became a question for Elda.

## 4. Deferred by decision, not overlooked: the accessories

A grip recess does not travel alone. Printed p.616 prices, beside the profile:

| code | what |
|---|---|
| `GOL031` / `GOL032` | flush-fitted end cap for the undercounter recess, RH / LH |
| `GOL030` | flush-fitted end cap for the intermediate recess |
| `GOL034` | inner corner element for the undercounter recess |

Andriy: *"Ручка идёт с разными переходниками, заглушками, креплениями, там
где-то десяток сопроводительных позиций. Сегодня нам это не нужно."*

They are real coded articles and will eventually be counted automatically — an
end cap where a recess meets a side panel, a corner element where a run turns.
**Not today.** Recorded so the page is known when the day comes.

## 5. Where linear goods live in our data today

**In exactly one place**: `hardware.gola_profiles`, four rows, given their `um`
on 2026-08-22. Everything else linear is unmapped:

| printed | section | in our data |
|---|---|---|
| 608 | Grip Edgings — FRAME, STEP, 30° | no |
| 609 | Grip edging — INSIDE | no |
| 613 | Grip edge for wall units | no |
| 615-616 | L-shaped grip recess (`GOL001` `GOL002` + caps) | profiles only |
| 620-621 | Straight grip recess (`GOL005` `GOL006` + caps) | profiles only |
| 624+ | Plinths | **no** — p.624 is finishes and price bands |
| 527-546 | Lighting | no |

The accessories chapter has never been mapped either (rule 1: a section is one
the printed index prints), which is the same prerequisite `registry/cesar/
options/` already waits on.

## 6. What this changes in what exists

**Nothing already built turns out wrong.**

- The gola profile became a companion **order line** rather than geometry hours
  before this principle was stated. That is exactly this rule.
- Envelope-only geometry already covers drawer inserts: they are options, not
  shapes.
- `um` went into the registry this morning for the exporter, and turns out to be
  axis 1 of three.
- `orderable? = carries a code` is what will let the exporter read the warehouse
  and skip everything else.

Two small corrections the source read turned up:

- `GOL001` / `GOL002` carry `source_ref` **printed p.615**, the cross-section
  page. They are **priced on p.616**, which is also where `– per lm.` appears.
  The reference should point at the page that states the fact.
- The registry's `um_note` calls ML *"CONFIRMED from the estimate"*. It is now
  **also printed in the catalog** — a stronger, independent source.

## 7. Open

- **The length of one piece / one bar.** Not on p.616 or p.621. Andriy: it
  depends on the maker, and the factory often sources these outside. → Elda.
- **Is the plinth ours to order, or Metron's to generate?** → Elda. Until
  answered, no plinth article enters the registry and none enters the warehouse.
- **The offcut policy** is a DECISION, not a catalog fact. Recorded as ours, at
  PLANNING, and marked in the model — never averaged into a number that looks
  sourced.
- ~~**How many handles per cabinet.**~~ **Closed 2026-08-22** — one per OPENING
  FRONT, read off `front_layout`. Still OUR reading; every row says so.
- **Where the warehouse parks**, and whether one scene is enough.

---

# 8. A FILLER IS ALMOST ENTIRELY WAREHOUSE — Andriy, 2026-08-23

The fillers of printed p.434 landed the same day
(`claude/fillers-recon-2026-08-23.md`), and the first one placed in the 545
Avenida model produced the account below. It is worth its own section because a
filler is the **first element whose whole contribution to the run is linear** —
the piece itself is one small article, and everything else about it is length.

## 8.1 The rule, in Andriy's terms

> *"Стандартно строим виртуальный цоколь… считаем его отдельно в погонаж на
> складе. Теперь сверху ручка, у нас сверху вырез — чисто декоративная. Она тоже
> рисуется виртуально. А ширина этой гола добавляется в склад в погонаж."*

**A filler is not an exception.** It behaves like every other element of the run:

| | drawn | enters the warehouse as |
|---|:--:|---|
| the filler itself | ✓ | one piece, `PZ` — the article at its ordered width |
| **the plinth under it** | ✓ | **погонаж — its length is the filler's ordered width** |
| **the gola recess above it** | ✓ | **погонаж — same length again** |

Both are DRAWN and both are counted, and those remain the two independent
questions §0 already separated. What is new is that **for a filler the length in
both cases is the same number — the width the person typed.** Both the plinth
and the grip recess run *along* the run, so a 50 mm filler contributes exactly
50 mm to each.

**Neither is ever a piece.** A filler must never put `qty 1` against a plinth or
a profile. It contributes length, and the length becomes a number in the
warehouse and nowhere else.

## 8.2 The gola on a filler is DECORATIVE, and that changes nothing

A filler does not open and nobody grips it. The recess above it exists so the
line does not break where the run crosses the filler. **This does not make it
optional and does not make it free** — the profile still runs across those
50 mm, and those 50 mm are bought.

**This closes the question left open on 2026-08-23:** whether a filler should
carry its own `GOL001` companion line. It should, and the mechanism already in
the exporter is the right one —

```
,1,GOL001,,,,,,ML,,,,"implied · printed p.615 / PDF 617 ·
                       qty = running length of the run, not of this unit"
```

— because the contribution is a **length, not a count**. The null was already
saying the true thing. Nothing in the data changes; what is missing is the
aggregation that adds those 50 mm up.

## 8.3 The plinth under a filler carries on — and it is still blocked

**`plinth_continues` for a base filler is YES.** The engine already draws it:
`plinth? = true`, `plinth_h_mm = 100` inherited from H.78, carcass bottom at
100. Confirmed standing in the model. That closes the open question of the
filler recon's §10 and NEXT item 22.

**But its warehouse line cannot be built yet, and not for a filler-shaped
reason.** No unit in this registry carries a plinth companion line *at all* —
the plinth today is drawing only. Giving it one runs straight into **§3 / Elda
L2**: if Metron generates `ZOCC` from the composition header, a warehouse line
orders it twice. So:

- **the drawing half works today** — for fillers and for everything else;
- **the warehouse half waits on L2**, and then on L1 for the bar length, because
  §2 already established that for a plinth the answer is a **piece count**, not
  a length.

The gola half is not blocked by either: its line exists, its `um` is `ML`, and
it only wants summing.

## 8.4 The d.35 step is not a defect

A base filler is **d.35** where its H.78 neighbours are **d.62**, so the plinth
drawn under it steps back. Raised as a possible drawing fault; Andriy:

> *"Вопрос не актуальный. Работает хорошо. Заказывая другой глубины, мы просто
> немного экономим."*

**A shallower filler is a saving, not a compromise** — it is the only depth
p.434 makes, and there is nothing behind a filler that needs 62 cm. Recorded so
nobody re-opens it as a bug.

## 8.5 What M1.13 has to do with this

The aggregation now has a concrete first case, and it is small enough to build
against:

1. Walk the model. For every object, read its companion lines.
2. `ML` lines derived **from a length**: total the participating objects' widths
   along the run, across joints. A filler contributes exactly like a cabinet —
   **there is no filler branch to write.**
3. Express the total in the article's own `um`, and — when L1 answers — turn a
   plinth length into pieces plus an offcut allowance, marked as OURS.

**If a filler needs a special case anywhere in that walk, the walk is wrong.**
That is the test worth writing first.

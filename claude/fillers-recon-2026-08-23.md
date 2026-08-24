# Fillers and closing strips — recon, 2026-08-23

> ## MOVED INTO THE REPOSITORY 2026-08-24
> Copied verbatim from the claude.ai Project. See `claude/README.md`.
>
> **One dated correction, added not merged — rule 9. §5 counted the families
> the registry held on 2026-08-23: five of the 31 codes on printed p.434 had
> one.** The registry has since grown from 7 section files to 34 and from
> ~185 codes to 615, so that count is stale by construction. It is left
> standing because the CONSTRAINT it exists to state — *a filler cannot
> honestly be extracted before its family exists* — is unchanged, and the
> table is the worked example of it. **Do not read the five-row table as the
> current state; recount against `registry/cesar/` before extracting any
> filler.** The four filler files that exist today are still the only ones:
> `fillers_h78.json`, `fillers_wall_h36.json`, `fillers_wall_h60.json`,
> `fillers_tall_h210.json` — six codes, of which two are held-not-buildable.

Printed **p.433-456**, chapter *"Fillers, end elements and open units"*,
`CESAR - 2 Kitchen System.pdf`. Read at chapter level; **printed p.434 and
p.435 read in full and verified against 200-dpi renders** (rule 10). Scope
chosen with Andriy: the fillers and closing strips only — end elements
(p.436-449) and open units (p.450-456) were read at heading level and are
recorded here as the chapter map, nothing more.

Renders kept: `sources/factory/p434-436-fillers-maxima-436.png`,
`p435-437-fillers-nelle-437.png`.

> **§6 and §11 were written before the work was authorised and are now
> SUPERSEDED by §12, same day.** They are left standing unedited: the reading
> was true when it was made and the reason the extraction paused is worth
> keeping. Rule 9.
>
> **§13 is what the first placed filler taught**, after §12 shipped: two defects
> the suite had been green through, and Andriy's rule for how a filler reaches
> the order.

---

## 1. The chapter map, and the printed index under-prints it

Printed p.433 is the chapter's own index. It lists **nine** entries. The pages
themselves carry **thirteen** headings. Four page-groups are headed on the page
and absent from the index:

| printed | page header | in the chapter index? |
|---|---|---|
| 434 | Closing strips and fillers for **Maxima and Intarsio** | yes |
| **435** | **Closing strips and fillers for N_Elle and N_Elle with framed door** | **no** |
| 436-439 | End elements for Maxima-Intarsio | yes (436) |
| **440-441** | **Adjoining end side panel for Maxima \| with 45° vertical edge** | **no** |
| 442 | Adjoining end side panel for Maxima Groove | yes |
| 443 | Adjoining end side panel for lacquered Intarsio | yes |
| 444-445 | Adjoining end side panel for N_Elle \| with 45° vertical edge | yes (444) |
| 446-447 | Adjoining end side panel for N_Elle with framed door | yes (446) |
| **448-449** | **2.2 cm thick end side panels \| Finishes and price bands** | **no** |
| 450-452 | 2.2 cm thick open end units | yes (450) |
| **453-454** | **Open base, wall and tall units \| Finishes and price bands** | **no** |
| 455 | Open base, wall and tall units, from 15 to 45 cm wide | yes |
| 456 | Open base, wall and tall units, from 45 to 90 cm wide | yes |

**Rule 1 says a section in `catalog_map` is one the printed index prints.** This
chapter is the first place where that rule loses information rather than
protecting us: p.435 is an entire collection's fillers, and the index simply
does not mention it. The rule is still right about *invention* — but "the index
prints it" is a sufficient condition for a section, not a necessary one, and
this chapter is the evidence. **Not changed, recorded.** *(§12 shows the way
round it that costs nothing: p.435 is mapped as a PAGE of the section whose
range contains it, so the section still comes from the index.)*

---

## 2. What printed p.434 actually holds — four positions, 31 codes

Verified against the render. Bands **1-8 and 10** are priced throughout;
**9 and 11 are dashes** in every row of every table on the page.

### 2.1 *"Fillers in door finishes from 2,3 to 15 cm — front in door finishes"*

No depth printed. A front strip and nothing else.

| H. | code | H. | code |
|---|---|---|---|
| 39 | `B00151` | 138 | `C10151` |
| 48 | `BC0151` | 198 | `CE0151` |
| 58,5 | `BJ0151` | 210 | `CQ0151` |
| 60 | `BE0151` | 222 | `CG0151` |
| 78 | `B70151` | 234 | `C00151` |
| 84 | `BK0151` | **278** | **`CH9151`** |

### 2.2 *"Base unit filler … — front in door finishes — sides, bottom and top panel in melamine"* — **d. 35**

| H. | code | H. | code |
|---|---|---|---|
| 36 | `BA0150` | 72 | `BI0150` |
| 39 | `B00150` | 78 | `B70150` |
| 48 | `BC0150` | 84 | `BK0150` |
| 58,5 | `BJ0150` | **120** | **`PJ0150`** |
| 60 | `BE0150` | 138 | `C10150` |

### 2.3 *"Wall unit filler … — with one-piece bottom"* — **d. 35**

| H. | code | H. | code |
|---|---|---|---|
| 36 | `PB0151` | 84 | `PG0151` |
| 48 | `PC0151` | 96 | `PF0151` |
| 60 | `PD0151` | **120** | **`PJ0151`** |
| 72 | `PE0151` | | |

### 2.4 *"60°÷160° base unit corner panel"*

`A80150` (H.78) and `AL0150` (H.84). The drawing is labelled
*"Rear size w. 15x15"* — **a drawn example, not a rule**; the rule is in the
warning block (§7).

### The warning block, verbatim, carried by 2.1, 2.2 and 2.3 alike

> *"If the door is framed, the glass/ceramic will be applied to the panel and
> not to the aluminium support"*
> *"Minimum size available also for Groove: 5 cm."*
> *"Trama: 2 sides with trama, polished edge."*

---

## 3. Printed p.435 — N_Elle, and one contradiction on its own page

| position | d. | H. | code | bands |
|---|---|---|---|---|
| N_Elle base unit filler, **45° front edge**, 35 cm melamine sides/bottom/top | 35 | 36,8 / 78 / 84 | `Y00150` / `Y30150` / `Y60150` | **5-8, 10, 11** |
| N_Elle **framed door** base unit filler, *"from 5 to 15 cm"* | 35 | 36,8 / 78 / 84 | `YC0150` / `YO0150` / `YT0150` | **12, 13, 15** |
| 60°÷160° base unit corner panel | — | 78 / 84 | `A80150` / `AL0150` | 1-8, 10 |

**Three things worth keeping.**

**The corner panel is shared.** `A80150` / `AL0150` appear on p.434 and p.435
with the *same codes and the same prices in every band*. One article serving two
collections — not two articles that happen to agree.

**The band sets confirm `claude/finishes-and-price-bands-2026-08-22.md`.**
Maxima/Intarsio 1-8+10, N_Elle 5-8+10+11, N_Elle framed 12/13/15. Bands are
collection-scoped, and the framed-door programme has a band set of its own.
Re-confirmation of an existing pattern, per Andriy's discovery rule — not a new
concept.

**The page contradicts itself, and it is not a `pdftotext` artefact.** The first
position is headed *"from 2,3 to 15 cm"* while its own warning triangle reads
*"Minimum size available: 5 cm."* — with the words *"also for Groove"* dropped,
which on p.434 were what made that sentence a Groove exception. Both readings
are on the render. The second position's heading agrees with 5 (*"from 5 to
15 cm"*), which makes the first heading the likely copy from p.434 — **but that
is inference, so 2,3 vs 5 for N_Elle goes to Elda (§10).**

---

## 4. The finding: a filler's WIDTH is an order axis outside the code

Every article this engine has met names its width in the code table.
**A filler does not.** One code covers every width from 2,3 to 15 cm, and the
width is chosen when the thing is ordered.

`_manifest.json` already has the right shelf for this — `order_axes_outside_code`
— holding two entries: `door_version` and `hinge_side`. **A filler's width is
the third, and it is the first that is a DIMENSION rather than a choice from a
list.** Same shape as `hinge_side`: the catalog states one article and declines
to state this property, so it is per-order and never guessed.

**Landed 2026-08-23 as `order_axes_outside_code.filler_width_mm` — §12.**

---

## 5. The second finding: p.434 is the first page that is not a page of ONE family

The registry stores **one section file = one family**, and `Registry.lookup`
takes `height_mm`, `mounting` and `plinth_h_mm` from the family. Printed p.434
scatters across **twelve heights and three classes** — 36, 39, 48, 58,5, 60,
72, 78, 84, 96, 120, 138, 198, 210, 222, 234, 278 — base, wall and tall.

`catalog_map` has the same shape problem one level up: each section entry
carries exactly one `class`, and this section has three.

**The resolution is not a workaround, it is the correct semantics.** A filler
inherits its neighbours' ground: `B70150` at H.78 stands on the same 100 mm
plinth as the cabinets beside it, `PB0151` at H.36 hangs. Those are precisely
the family facts the loader already supplies. So a filler `unit_type` belongs
**inside the existing family**, contributed by a small file that names the
family and declares no family-level keys of its own — which
`merge_family_keys!` permits, since only a *disagreement* raises.

**The consequence is a real constraint, and it is worth more than the storage
question:** a filler cannot honestly be extracted before its family exists, or
it silently inherits `Standards::PLINTH_H_MM` instead of its own ground.

Of the 31 codes on p.434, **five have a family in the registry today**:

| code | family held | position |
|---|---|---|
| `B70151` | H.78 | front strip |
| `B70150` | H.78 | base unit filler, d.35 |
| `PB0151` | Wall H.36 | wall filler, d.35 |
| `PD0151` | Wall H.60 | wall filler, d.35 |
| `CQ0151` | Tall H.210 | front strip |

The other 26 wait on families we have not read. **The whole of p.435 waits on
the N_Elle chapter (printed p.321), which is not extracted at all.**

> **CORRECTION 2026-08-24 — the count above is stale, the constraint is not.**
> Between 2026-08-23 and 2026-08-24 the registry went from 7 section files to
> 34 and from ~185 codes to 615: Wall H.96 and H.120, five plain tall families
> (H.138, H.198, H.210, H.222, H.234), base H.39 and H.48. **Many more of the
> 31 codes on p.434 now have a family than five, and this note deliberately
> does not name the new number** — a count written into a document is stale the
> next session (see `claude/repo-state.md` for the rule). Recount against
> `registry/cesar/` at the moment of extracting. **No filler file was added in
> that time**, so the four listed in §12.5 are still the whole of it.

---

## 6. Why nothing landed in the registry today

> **SUPERSEDED the same day by §12** — Andriy authorised the code change and it
> is in the working tree. Kept unedited because the diagnosis is still what
> shaped the design, and because one of its four items turned out to be wrong
> (see §12.4).

The five rows above were ready to write. They were not written, for one
concrete reason found by reading the code rather than the catalog:

**`width_mm` is not optional downstream.**

- `20_contract.rb` line 135 — `require_keys!(a, %w[height_mm depth_mm width_mm], 'geometry_kind = linear')`. A linear object without a width does not validate.
- `90_palette.rb` `sizeGrid` labels every size button with `String(c.width_mm)` and sorts on it. Filler rows would render **buttons labelled `null`**, and `showCard` would print **`W null × H 780 × D null`**.
- `60_generator.rb` — `INSTANCE_KEYS = %w[mounting mount_bottom_mm]`, deliberately narrow, with the comment *"an object may not out-vote the registry about what article it is."* A chosen width cannot simply be written onto the object today.

That last guard is right and should stay. **A filler's width is not the object
out-voting the registry — it is the catalog declining to state it**, exactly as
it declines to state `hinge_side`. So the change is not to widen `INSTANCE_KEYS`
on a hunch; it is to give the width the same standing `hinge_side` has.

**Landing the data before that would have put five broken buttons in the picker
and a card reading `W null`.** Rule 7's spirit, one level up: the honest stop is
also the to-do list.

### What it needs, smallest first

1. `width_range_mm: [23, 150]` on the row, `width_mm` absent — data only.
2. A third entry in `order_axes_outside_code`, `filler_width_mm`, with its contract key.
3. `sizeGrid` must render a range as something other than a size button — the fillers of one family are **one button and a number to type**, not a grid.
4. The contract's linear-geometry requirement must accept a width that arrives from the order rather than the catalog.

**3 and 4 are the real work and neither is large. Nothing here is decided.**

---

## 7. The corner-panel minimums, reconciled with printed p.10

The warning block on p.434 and p.435 prints three minima **with no conditions
attached**, which is unreadable on its own:

> *"Minimum dimensions of the filler panel's rear side: 7.5x7.5 cm."*
> *"Minimum rear dimensions for the "Frame" grip edging: 6x6 cm."*
> *"Minimum rear dimensions: 5x5 cm."*
> *"Out-of-square modifications are not available for framed doors"*

**Printed p.10 supplies the conditions the price page omits:**

> *"Min. dimensions of corner filler for push-pull device or grip recess =
> 5x5 cm; for Frame grip edgings = 6x6 cm; for handles the filler's minimum
> size depends on the model and its relative position."*

Reading the two together: **7,5×7,5 is the default, 6×6 with Frame grip edging,
5×5 with a push-pull device or a grip recess.** *(OUR reconciliation of two
pages, not a printed statement — rule 4. It is also the fourth axis found to be
grip-system-scoped, which puts it with the Lume restriction in M1.6.)*

**And the handle case has no number anywhere.** p.10 says it depends on the
model and its position; the handle chapter agrees and still prints nothing —
printed p.599 (TITANIUM) *"a suitable filler strip is added to increase the
opening angle of the door"*, printed p.606 (TRATTO) *"Add a filler strip"*.
Rule 8: **a number no source gives us is not written down.**

---

## 8. Two sweeps that changed what the word means

### 8.1 "Filler" is at least six different things

Cross-book search of all five factory PDFs (the rule that settled the 5 mm
foot). Only the first is an article we would ever order from this chapter:

| # | what | where |
|---|---|---|
| 1 | **the ordered filler / closing strip** | printed 434-435, and every collection prints its own |
| 2 | **"Filler profile"** — the dishwasher companion `995945` / `995946` | printed 48, 56, 335, 346, 404, 408 — already in the registry |
| 3 | **"interior filler strip" / "fixed filler"** — part of a unit's own description | printed 96, 101, 131, 420, 425 |
| 4 | **"corner filler 5x5" / "10x5"** — inside wall corner unit descriptions | printed 216, 223, 230, 239, 246, 252 |
| 5 | **"spacer-filler 2.5 cm"** — Hallway module | printed 198 |
| 6 | **"a suitable filler strip is added"** — handle special cases | printed 599, 606 |

Plus *"2 x 5.6 cm fillers"* (Comb system, printed 317) and *"1 customised
filler"* (Unit tall, printed 297). **Three of these are components of an
article we already order and must never become order lines of their own** —
the same trap as the `FRN`/`RPN` component layer in the estimate teardown.

### 8.2 There are FIVE closing-strip rules, not one

`NEXT` item 17 records one of them. Printed p.10-11 carry all five, and they
are placement rules — the `restrictions` key that still has nowhere to be
written:

1. **p.10, Magicorner** — corner filler minimums by grip system (§7).
2. **p.10, corner base units** — *"Fit corner base units with 8x8–cm fillers adjacent to drawer units, jumbo drawers and dishwashers (or custom–sized corner base units)."*
3. **p.11, Slidecorner** — the same minimums **minus the 6×6 Frame line**, which p.10 has. Two pages, two lists, and we do not know whether the omission is meaningful.
4. **p.11, corner tall units** — *"To prevent "D" handles from colliding with each other, we suggest you fit a minimum 5–cm wide closing strip between the corner tall unit and the adjacent base or tall unit."*
5. **p.11, adjacent tall and wall units** — the known rh/lh + "D" handle rule, **and a second sentence beside it**: *"Add a minimum 5–cm wide closing strip between the tall fridge unit and the wall so that the doors can be opened fully and any drawers inside the fridge can be pulled out."*

**All five are conditional on things outside the code** — the grip system, the
handle model, what stands next to the unit. Policy stays what the wall-unit
recon set: **warn, never auto-insert.** `restrictions` now has **ten** facts
waiting on it, up from five.

---

## 9. Code grammar — one re-confirmation and one row that breaks two patterns

**The prefix is the height family letter, and it is the same lookup the unit
chapters use** — `B7` = H.78, `BK` = H.84, `PB` = H.36, `PD` = H.60, `PE` = 72,
`PG` = 84, `C1` = 138, `CE` = 198, `CQ` = 210, `CG` = 222, `C0` = 234. A
re-confirmation of the family-letter lookup, not a new grammar.

**`CH9151` at H.278 breaks two things at once.** `CH` is the H.222 **d.62**
member in the tall chapter's pair (`_manifest.json` → `code_grammar.tall_units`),
and here it is H.278. It is also the only code on the page whose suffix is not
`0150` or `0151`. Both confirmed on the render. **A family letter can be
page-scoped, exactly as a depth letter can** — and H.278 appears nowhere else in
anything we have read. Read the row; decode nothing.

**`PJ` appears in both tables** — `PJ0150` in the base-unit filler table at
H.120 and `PJ0151` in the wall filler table at H.120. So `0150`/`0151`
discriminates *within* a prefix, while **across prefixes `0151` means two
different articles**: a front-only strip on a `B`/`C` prefix, a wall filler
*with a one-piece bottom* on a `P` prefix. Rule 4 again, and worth stating
because the suffix looks decodable and is not.

**A geometry fact from the detail circle on p.434.** The base unit filler's
detail is dimensioned **35 / 0,3 / 2,2**. Read as a stack that is
350 + 3 + 22 = **375** — the D.375 finished depth the end-panel pages use
throughout. *(OUR reading of a drawing, not a printed equation.)*

---

## 10. Open questions

**For Elda** — neither is answerable from the book:

- **N_Elle minimum filler width: 2,3 or 5 cm?** The heading and the warning on printed p.435 disagree (§3).
- **Is the filler width continuous, or quantised?** One code covers 2,3-15 cm and no page says whether the factory takes any millimetre, or steps. The warehouse cannot express the position without knowing.

**Ours to decide, later:**

- **Is the 8×8 corner filler of printed p.10 the `A80150` article cut to size, or a modification?** It reads like a rule about a filler rather than a second article, but the modifications chapter (printed 547) has not been read.
- ~~**Does a filler carry the run's plinth across?**~~ **YES — answered
  2026-08-23, §13.2.** The engine already draws it. What remains is not the
  drawing but its WAREHOUSE line, and that is Elda L2, not a filler question.
- ~~**Where fillers belong in the picker.**~~ **Decided 2026-08-23 — §12.2.**

---

## 11. What was NOT done, deliberately

> **SUPERSEDED the same day by §12.** Kept unedited — rule 9.

- **No registry file written.** §6.
- **No code changed.** The four items in §6 are a proposal, not a decision.
- **`catalog_map` not touched.** Adding this chapter means answering §5's
  one-class-per-section question first, and that is Andriy's call, not a
  side-effect of an extraction.
- **End elements (p.436-449) and open units (p.450-456) read at heading level
  only.** They are the area-derived (`MQ`) half the warehouse note has been
  waiting for, and the open units bring a second continuous-width axis
  (150-450 and 450-900). Their own session.
- **The pre-repo extract `sources/raw_dump/Fillers_End_Elements_Source_Extract_v0.1.md`
  covers this chapter** and was read first. It is broadly right on structure and
  should not be trusted on detail: it files p.435 as *"Maxima / Intarsio"*,
  misses that the corner panel is one shared article, and states heights as a
  single flat list per position. **Superseded by this note for p.434-435, and
  left in place — rule 9.**

---

## 12. What landed, 2026-08-23 — core 0.55.0, 346 checks green

Authorised by Andriy after §6 was written. **Working tree only — the commits
are prepared and Andriy runs git himself.** Three concerns, in this order.

### 12.1 The third order axis

`_manifest.json` → `order_axes_outside_code.filler_width_mm`, beside
`door_version` and `hinge_side`, carrying the reasoning of §4 and Elda's open
quantisation question.

**`Registry.with_ordered_width(unit, width_mm)`** is where a range becomes a
number. Pure, and it **raises rather than defaulting** — a filler silently built
at the bottom of its range would be a drawing nobody could tell was wrong. It
refuses four things: a missing width on a ranged article, a width outside the
printed range, a fractional millimetre, and — the sentinel — **a width offered
to an article that names its own.** `B80601` is 600 wide and that is final; a
narrower one is a *modification* with a surcharge (Elda position 4), never a
number typed into a dialog. `Generator::INSTANCE_KEYS` was **not** widened.

`Generator.build` grew one keyword, `width_mm:`, defaulting to nil, so the
existing positional callers are untouched.

### 12.2 `filler` is a class of its own, and that was a decision

§5 left it open. Decided: the four section files and the `catalog_map` entry
carry **`class: "filler"`**, and the picker labels it *"Fillers and closing
strips"*.

**Why:** the catalog prints these as their own chapter after every collection,
a map entry carries exactly one class, and a person looking for a closing strip
is looking for one thing and not three. **What it does not change:** the ROWS
keep their families, so a wall filler still hangs and a base filler still stands
on the H.78 plinth — the ground comes from the family and always did.
**Reversible:** one field in four data files and one label.

`catalog_map` gained the section with per-position statuses, and **p.435 is
mapped as a PAGE of it** rather than a section of its own — so rule 1 stands
untouched while the page the index forgot is still recorded (§1).

### 12.3 The picker asks for the width

`sizeGrid` hands a ranged article to a new `widthList`: one button per article
showing its range, then a number box. **Build stays hidden until the number is
inside the range** — the same refusal `with_ordered_width` makes in Ruby, and
the dialog is a convenience, never the authority. The card no longer prints
`W null`: it says *"W 23–150 mm, stated per order"* and, for the front strips,
*"no depth printed"*.

*(Reworked the same day — see §13.3. Rows are depths and the buttons carry the
HEIGHT, and the width box gained 5 / 10 / 15 cm presets.)*

### 12.4 One item of §6 was wrong, and the export gained a line

**§6 item 4 was wrong.** The contract needed **no change at all**. It validates
the OBJECT, and a built filler has a real `width_mm` — the one the person typed.
The requirement was never the problem; the missing width was, and it is missing
only until the thing is ordered.

**What did need adding was in the export.** `unit_row` now carries a note on any
article whose registry row gives a range:

> *width is an ORDER choice, not a catalog size: this article is made from 23 to
> 150 mm (printed p.434)*

Nothing in the `l_mm` column says a width was chosen rather than quoted, and
**quoting a catalog size and specifying a cut are not the same request.** Asked
of the registry, never trusted from the object — the rule `front_layout_for`
already follows.

### 12.5 The five rows, and the two that will not build

`registry/cesar/fillers_h78.json`, `fillers_wall_h36.json`,
`fillers_wall_h60.json`, `fillers_tall_h210.json` — **four files for one page,
because the loader stores one family per file and this page has twelve.** None
declares a family-level key, and a test enforces that.

**`B70151` and `CQ0151` are held and NOT buildable.** The page prints no depth
for a front-only strip. 2,2 cm is stated all over this catalog and would be the
obvious guess, and a guess is what rule 8 forbids. They are findable and
orderable; a confirmed depth makes them a data change, not a code change.

**They are the first unbuildable rows this registry has ever held**, which broke
an invariant the suite had been asserting sideways — *"every corner article is
still buildable"* opened by demanding that **nothing at all** be unbuildable.
That was only ever true because nothing had yet been held that we cannot draw
honestly. The check was narrowed to what it was actually about, and a new one
demands that anything unbuildable say why.

### 12.6 What the suite now pins

346 checks, 0 failures, core **0.55.0**. Eleven are new. The ones worth naming:

- **A filler inherits its family ground** — `B70150` is 780 tall on a 100 mm plinth on the floor; `PB0151` hangs. This is §5's claim, and it is the reason a filler waits for its family.
- **No filler file declares a family-level key.** It would not raise while the two copies happened to agree, and would raise on the day somebody corrected one.
- **SENTINEL: a width may not be ordered for an article that names its own.**
- **The order says the width was chosen** — and an ordinary article carries no such note.
- **A filler is never offered the wall-hung surcharge.** Free, since `wall_hung_available?` already refuses anything that is not a cabinet — but the filler is the first `object_class` to exercise that arm.

### 12.7 Still not done

Everything in §11's last three bullets stands: **end elements, open units, the
corner panel, the 26 codes without a family, and the whole of p.435.** Plus one
new one — **the plinth question of §10 is now live**, because `B70150` is the
first filler in the model and nothing says whether the run's plinth carries on
under it. *(Answered within the hour — §13.2.)*

---

## 13. What the first PLACED filler taught — 0.55.1 and 0.55.2

§12 shipped green. Andriy then put a `B70150` at 50 mm on the end of the base
run in the 545 Avenida model, and the first two things he did with it both
failed or looked wrong. **Both were pure-layer bugs the headless suite could
have caught and did not.**

### 13.1 The rebuild lost the ordered width — rule 11, FOURTH instance

> *Apply failed: Non-positive dimension for FRONT: w= d=22 h=750*

`Panel.apply` does `Registry.lookup(attrs['code'])` afresh, and **a filler row
has no width**: the ordered width lives only on the object. `Generator.effective`
overlaid `INSTANCE_KEYS` and nothing else, so every rebuild re-read a nil.

**The third instance of rule 11 was `Panel.apply` reading the catalog instead of
the object. The fourth is the same method losing a different value — inside
`Generator.effective`, which was written to settle the third.**

The fix keeps the guard's meaning exactly, and the pair has to be read together:

| | does what |
|---|---|
| `INSTANCE_KEYS` | overrides what the catalog **said** |
| the new line | restores what the catalog **never said** |

— and only where the row gives a `width_range_mm`, validated on the way in, so
an edited object cannot smuggle a width the article is not made at.

**Two more things fell out of the same call.** `effective_slabs` was being handed
the bare registry row one argument later — the same mistake twice in one
statement. And the fillers had no `front_layout` at all, while `effective_slabs`
and `gola_options` both turn a missing layout into `single`: **a default is not a
source.** They now state it explicitly — one front, no `hinge_axis`, because a
filler does not open — exactly as a US appliance panel states a front it never
swings.

**The regression sweep was proved before it was trusted** (rule 12): with the fix
removed it fails on `w_mm=>nil`, which is the SketchUp error reproduced
headlessly.

### 13.2 How a filler reaches the ORDER — Andriy's rule

> *"Стандартно строим виртуальный цоколь… считаем его отдельно в погонаж на
> складе. Теперь сверху ручка, у нас сверху вырез — чисто декоративная. Она тоже
> рисуется виртуально. А ширина этой гола добавляется в склад в погонаж."*

**A filler is not an exception.** The plinth runs under it, the gola recess runs
above it, both are **drawn**, and both enter the warehouse as **погонаж whose
length is the filler's ordered width**. Neither is ever a piece — a filler must
never put `qty 1` against a plinth or a profile.

This closes two questions in one sentence:

- **`plinth_continues` for a base filler: YES**, and the engine already does it
  (`plinth? = true`, 100 mm from H.78, carcass bottom at 100). §10 struck.
- **The `GOL001` line is right as it stands.** The recess above a filler is
  decorative — nothing opens, nobody grips it — but the profile still crosses
  those 50 mm and those 50 mm are bought. The exporter's null already said the
  true thing: *"qty = running length of the run, not of this unit"*. **The
  contribution is a length, not a count**, so nothing in the data changes.

The full account, including what M1.13 has to do with it and why the plinth's
warehouse line is still blocked on Elda L2, is in
**`claude/warehouse-architecture-2026-08-22.md` §8**.

### 13.3 The picker grid was one dimension off

`widthList` gave one row per code with the depth as its label, so the wall
fillers rendered as **two identical rows both saying `d. 35`** — `PB0151` and
`PD0151` are both d.35 and differ only in height. Corrected to `sizeGrid`'s own
shape, one dimension over: **rows are depths, buttons carry the HEIGHT**, and the
code drops to the small line under it. The width box gained **5 / 10 / 15 cm**
presets — 5 cm is not chosen for tidiness, it is the size printed p.11 asks for
(*"a closing strip of at least 5 cm"*), so it is the one this article is reached
for most. A preset outside the article's range is not offered.

### 13.4 The d.35 step is not a defect

A base filler is d.35 where its H.78 neighbours are d.62, so the plinth drawn
under it steps back. Raised as a possible drawing fault; Andriy:

> *"Вопрос не актуальный. Работает хорошо. Заказывая другой глубины, мы просто
> немного экономим."*

**A shallower filler is a saving, not a compromise.** Recorded so nobody
re-opens it as a bug.

### 13.5 The lesson worth keeping

The suite was green through both defects in §13.1, and every layer involved —
`Generator.effective`, `front_slabs`, `Panel.effective_slabs` — is pure. So the
lesson is not that headless testing is weak. It is that **the first real
placement is a test nobody wrote yet**, and whatever it finds belongs in the
suite the same hour. Both do: 351 checks, core 0.55.2.

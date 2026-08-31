# The Maxima 2.2 order form, field by field — and which of them the engine
# already knows

**Printed p.65-66 / PDF 67-68 of `CESAR - 1 Project Guidelines.pdf`.**

READ FROM THE RENDER, NOT FROM THE TEXT LAYER, and it mattered on the first
line: the extracted text puts `64` immediately before the title, because that is
the PREVIOUS page's footer, and the pages themselves are numbered 65 and 66.
`claude/findings-2026-08-31-the-plinth-nobody-owned.md` §9 and commit 6994287
both say p.64-65 and are wrong by one. Dated and added here rather than edited
there (learned rule 9). Learned rule 10 earned its keep again.

**THE FORM IS COLLECTION-SCOPED.** Intarsio, Unit and N_Elle each have their
own. Anything built from this document is the MAXIMA 2.2 form and says so; a
generic order form would be a rule generalising past its evidence (learned rule
4).

**IT CANNOT BE FILLED PROGRAMMATICALLY.** The file declares an AcroForm and
holds zero fields and zero widget annotations across all 300 pages. The
checkboxes are drawn artwork. So the engine MIRRORS this form; it never writes
into Cesar's file.

**AND IT IS ONE QUARTER OF AN ORDER.** The book's own order flowchart: a new
order is *order form, list of elements, dimensional drawing, technical data
sheets of appliances*. The engine already produces the second and the third.

---

## How to read the three marks

| mark | meaning |
|---|---|
| **KNOWS** | the engine holds this today, as a decision or as a fact of the model |
| **COULD** | derivable from what the engine holds, but nothing derives it yet |
| **ASK** | no source in the engine. A person answers it, once per project |

---

## Header — printed on BOTH pages

| field | mark | note |
|---|---|---|
| Customer Code/Customer | ASK | project admin |
| Reference | ASK | |
| Requested delivery date | ASK | the book's own delivery tables decide what is possible |
| Place of delivery if different | ASK | |
| Seller | ASK | stable per dealer - DzineElements - rather than per project |

Five fields, none of them drawing facts. They are the argument for the panel
holding a small set of PROJECT constants that outlive one kitchen.

## PLAIN DOOR

The mixed kitchen ticks **two** boxes here, and the form says so itself, six
times over: *"if the kitchen has various finishes they must be specified for
each single element in the list or on the drawing."* The form carries the
palette; the element list and the drawing carry which element wears what — and
those are the two documents the engine already makes.

| field | mark | note |
|---|---|---|
| MELAMINE FINISH | — | **no checkboxes on the page at all**, a write-in blank. The text layer hides this |
| TECHNOMAT FINISH | — | same, write-in |
| LAMINATE: Fenix NTM / Fenix NTA / Unicolor HPL | — | not used |
| LACQUER: Silk-effect / Gloss / **Structured** / Metallic effect | **KNOWS** | `LX19 Nero` is a structured lacquer, decided 2026-08-29 |
| WOOD VENEER: **First** / Prime / Special / High-gloss / Tabu | **KNOWS** | `RR09 Rovere Nordico` is a First veneer, decided 2026-08-29 |
| METAL, FACED ON 6 SIDES | — | not used |

## SHAKER DOOR · MAXIMA GROOVE DOOR · FRAMED DOOR

Not used — but **which door MODEL this kitchen is, is nowhere in the engine.**
Every article code the registry holds is a carcass; the door style is a
programme-level choice that has never been written down as one. Mark **ASK**,
once per project, and it decides which of these four blocks is filled in at all.

## GLASS CABINET DOOR W/ FRAME — and a real question falls out

Fourteen printed combinations of frame, silk-screen, glass and fabric. The
kitchen has `TF0641` x3 with **oak-fabric glass** in Aluminium Black frames
(2026-08-29 / 08-30).

**Two printed lines carry a black frame with Oak fabric** — one over BRONZE
glass and one over TRANSPARENT glass — and nothing recorded says which. **ASK,
and it is a new question, not one we knew we had.** It carries a surcharge
either way.

## CARCASS and the modularity blocks

| field | mark | note |
|---|---|---|
| CARCASS: Cenere / **Grigio Fumo** / Rovere Bruno / silk-effect w-surcharge | **KNOWS** | decided 2026-08-29 |
| BASE UNITS CARCASS HEIGHT — 39 / 48 / 58,5 / **78** / 84 | **COULD** | every base in the model is 780 |
| BASE UNITS CARCASS DEPTH — **35** / 47 / **62** / 67 / 72 / 77 | **COULD** | both are present: the 620 runs and the 350 south leg |
| TALL UNIT CARCASS HEIGHT — 138 / 198 / 210 / 222 / **234** | **COULD** | `C90635` and `C92640` are 2340 |
| TALL UNIT CARCASS DEPTH — 35 / **62** / 67 / 72 / 77 | **COULD** | |
| TALL UNIT TOP CARCASS HEIGHT — 36 / 48 / **60** | **COULD**, and see below | |
| TALL UNIT TOP CARCASS DEPTH — **62** / 67 / 72 / 77 | **COULD** | |
| WALL UNITS CARCASS HEIGHT — 36 / 48 / 60 / 72 / 84 / **96** / 120 | **COULD** | `TF0641` is 960 |
| WALL UNITS CARCASS DEPTH — **35** | **COULD** | the form prints exactly one value |
| LEGRABOX — **Cenere** / Bruno / stainless w-surcharge | **KNOWS** | decided 2026-08-29 |

**AND THE FORM CONFIRMS ELDA Q11 FROM A SECOND DIRECTION.** Tall unit top
carcass height prints **36, 48 and 60 and nothing else**. Two `SD0631` in this
kitchen stand at **720**, recorded in the export as *HEIGHT INCREASE: REQUESTED,
from 600 mm - NOT PRINTED*. That reading came from the Modifications section
pricing reduction only; the order form has no box to tick for it either. Two
independent parts of the book agree, which is worth more than either alone.

## L-SHAPED GRIP RECESS · STRAIGHT GRIP RECESS

| field | mark | note |
|---|---|---|
| L-shaped, Aluminium: **Black** / White / Matt / Champagne / Bronze | **KNOWS** | decided 2026-08-29 |
| GRIP EDGING ON DOOR -> **Without grip edging**, *for L-shaped grip recess* | **KNOWS** | "no grip edging on the door", decided 2026-08-29 |
| Lume handle / Stelo handle / 30 deg / Step / Frame | — | not used |
| HANDLE block, FOR TRATTO HANDLE block | — | not used |

**A printed asymmetry worth keeping.** The L-shaped block is headed *optional
grip edging* and offers aluminium and lacquers. The straight block is headed
*mandatory grip edging* and additionally offers **wood veneer** and metallic
lacquer. So a wood-veneer recess exists only on the straight system. Nobody has
needed that yet; it is the kind of fact that becomes a defect the day somebody
assumes the two lists are the same.

## INSIDE GRIP EDGING FOR JUMBO DRAWERS

Four printed options: *from 30 cm horiz./vert.*, *crossover only horiz.
central*, *mid-door horiz. side/vert.*, and separately *Push-Pull*.

**ASK, and probably an Elda question.** What is recorded for this kitchen is
that the jumbo drawers open by `GOL002`, which is the intermediate gola profile
— a different fact from where the inside grip edging sits. Whether this block is
even filled in for a handleless kitchen is not something the page states.

## WALL UNIT EDGING

**KNOWS** — Black, decided 2026-08-29. The page adds a rule in its own
parenthesis: *for handleless opening, apart from on glass dish-drainer doors
where it is always matt.* This kitchen has no glass dish-drainer door, so the
exception does not bite — recorded because it is a rule the engine does not hold
anywhere.

## PLINTHS

Ten rows. **White PVC and Matt aluminium PVC print H. 10 ONLY**; the other eight
— aluminium and seven lacquer or veneer finishes — print H. 6, H. 10 and a
written finish.

**KNOWS**: Aluminium, H. 10, finish Black. Decided 2026-08-29, and it is what
was painted into the model.

## WORKTOP — the block that is owed whatever we decide

The page says it in print: **"this field must be filled in even if the top is
not provided by Cesar."**

| field | mark | note |
|---|---|---|
| Cesar / Customer's | **ASK** | this is the open decision of 2026-08-31 |
| Diamond top / Éclair edge profile / Macaron edge profile | ASK | none recorded |
| Finish | **KNOWS** if Cesar - Dekton Marmorio | |
| Thickness | **KNOWS** - 40 | |
| Depth | **AND HERE THE FORM AND THE KITCHEN DISAGREE** | |

**One Thickness field and one Depth field.** This kitchen has **three** worktop
depths — 650 over the base runs, 700 at the island, 380 at the ledge. The form
has no room to say that, which means either the extra depths travel on the
element list and the drawing like the finishes do, or the form is filled for the
principal depth and the rest is a note. **Nothing on the page decides it.** Elda
question, and a good one: it is the first time the form's shape, rather than its
content, has failed to hold this kitchen.

## HOUSEHOLD APPLIANCES

Twelve rows, two columns — CESAR or CUSTOMER'S. Fridge, Freezer, Dishwasher,
Washing machine, Oven, Microwave, Hob, Cover, Hood, Sink, Mixer tap,
Accessories.

**KNOWS, mostly**: *all appliances are the client's*, decided 2026-08-29. So
eleven rows tick CUSTOMER'S and Washing machine stays empty.

**Except the Sink, and it is not a quibble.** The integrated bowl is a
`70x40x19` cut into the Dekton top and priced by Cesar on printed p.110 — it is
a surcharge on THEIR worktop, not a machine the client brings. **ASK**: whether
that row is CESAR because the bowl is ordered from them, or CUSTOMER'S because
no sink appliance is being bought. The answer changes nothing about the price
and everything about whether the form reads as true.

---

## What this map says about the panel

**Fills itself today**: the two door finishes, the carcass, Legrabox, the
L-shaped recess and its Black aluminium, no grip edging on the door, the wall
unit edging, the plinth, and eleven of twelve appliance rows. All of it comes
from the decisions of 2026-08-29 and 08-30, and none of it needs a new reading
of the catalog.

**Fills itself from the MODEL, once something derives it**: nine modularity
values, every one of which the engine already validates against — which is why
they are COULD and not ASK. A panel that reads them off the model would also be
the first thing that notices when a kitchen quietly acquires a tenth.

**Never fills itself**: the five header fields, the door model, and whatever
Elda answers.

**And four questions came out of the reading**, none of which we knew we had:
which glass sits behind the oak fabric, whether the jumbo-drawer grip-edging
block applies at all, how three worktop depths go into one Depth field, and
which column the sink belongs in. The worktop one is the interesting one,
because it is the form's SHAPE failing rather than a missing decision.

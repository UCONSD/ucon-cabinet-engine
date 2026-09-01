# Declaring a body: three buckets, five reasons, and who installs it

**Agreed 2026-08-31 by Andriy.** The second action on the orphan report — owed
item 1 — specified before any of it is built. No code was written for this in
the session that produced this document, on purpose: the one part that is
expensive to change later is the list of reasons, because it lands as attributes
on bodies in live models, and that list is settled here first.

---

## 0. What changed while specifying it, and it changed the stakes

The declare action started as housekeeping — a way to stop the report opening
with the client's Wolf range and the room on every run. Andriy, 2026-08-31:

> *«Оно так и перекочует в layout by others. Типа counter top by others,
> appliances by others.»*

That moves it out of housekeeping entirely. A reason that prints as
**COUNTERTOP BY OTHERS** on a sheet a GC reads is a statement about SCOPE, and
scope statements are what gets argued about on site. So:

- the reasons are chosen as DRAWING vocabulary, not as debugging vocabulary;
- a wrong declaration now costs money instead of costing a tidy list;
- and the report's own doctrine — a tag is not ownership — gets an enforcement
  mechanism for free, because a wrong declaration turns up on a sheet where
  somebody argues with it.

---

## 1. Two buttons, not one

**Show** and **assign** are different tools with different risk, and they stay
apart. The same division as Retag: a pass that reads and a pass that writes are
never the same button.

- **Show** writes nothing, ever. No arm, no operation, no undo entry.
- **Assign** always writes, always inside one ordinary undoable operation. No
  arm either — an arm is for a probe that builds, and this builds nothing.

### And the window answers ONE question

Andriy's words were *«показать всё бесхозное, безымянное, неопределённое»* —
three words, and they are three DIFFERENT defects. One flat list of all three
would be long again, which is the exact thing this whole design exists to
prevent. So the window asks **what is not ready to print**, and shows three
sections with three counts of different weight:

| section | meaning | how it empties |
|---|---|---|
| **Unowned** (red) | I do not know what this is | by deciding — declare, or stamp |
| **Ours, no contract** | I know what this is, and I owe it | ONLY by stamping |
| **Declared not ours** | decided, and it goes on a sheet | it does not empty; it is the answer |

Nameless bodies — `Group#5` — used to be cosmetic. Now that names print, a
missing name is a defect and belongs in the first section's row as a flag.

---

## 2. The second bucket, because it is the one that gets confused

A body lands in **ours, no contract** when the answer to *whose is this* is
**ours** and the answer to *which rule owns it* is **none**.

The case that named it is the fridge plinth. We sell it. It is in the order. It
was drawn by hand, carries no `object_class`, and so Retag did not move it, the
painting pass did not paint it, and a future contrast pass would not have
touched it either. It read as MISSING for a day. It was not missing; nobody
asked it anything.

**Against the first bucket:** unowned means *I do not know what this is*.
This means *I know exactly what it is and it has no contract yet*.

**Against the third:** declared is final — the body leaves and prints on a
sheet. This is deferred — the body stays our debt and merely stops crowding the
list that has to be read.

**The exit is a stamp and nothing else.** This is the only count in the window
that a click cannot reduce. If it could, the declare button would become a way
to shorten the list at the expense of honest debts — the papering-over the
report was written to find, and the suite already has a sentinel against its
other form.

---

## 3. The five reasons

Closed list. The words were left OPEN when this was first written — Andriy,
2026-08-31, and he was right that they matter more than the structure, because a
GC reads them. **SETTLED THE SAME DAY; see section 3a.** The slugs below are what
lands on a body and never changes; what PRINTS is a separate lookup.

| reason | means | prints on a sheet |
|---|---|---|
| `owner_furnished` | the client's own item | yes |
| `by_others` | supplied by somebody else — INSTALL IS NOT PART OF THIS | yes |
| `existing` | existing, remains | yes |
| `building` | shell, floor, walls, openings | **no** — architecture is not scope |
| `drawing_aid` | setting-out, section aids | **never**, and hidden on every sheet |

Every declaration records the reason, the date and who made it. *Declared: 12*
with no breakdown is a number nothing can check, and learned rule 13 says a
record of an outside action is only true if something checks it.

### The second axis: who installs

`owner_furnished` and `by_others` collapse two different facts — who SUPPLIES
and who INSTALLS — and for appliances that difference is the thing that gets
argued about. Andriy, 2026-08-31: the axis exists from day one.

**Field: `installed_by`. Values: `ucon`, `not_ucon`, `undecided`. Default
`undecided`.**

**The two values are not symmetrical, on purpose.** We know reliably whether WE
install something. Who installs it instead of us is usually something nobody told
us, and learned rule 8 forbids writing down a fact no source gave us. So there is
no `owner` value and no `others` value: `not_ucon` is true whoever it turns out
to be, and `OFOI` — Owner Furnished / Owner Installed — is a claim this engine
must never make on its own.

Adding the field later would have meant migrating attributes across bodies in a
live model; adding it now costs nothing. What learned rule 6 forbids is
INVENTING VALUES on one case, not declaring a field.

---

## 3a. The words, settled 2026-08-31, and checked against real drawings

Checked against documents rather than remembered. A city permit set's
ABBREVIATIONS block lists `N.I.C. - NOT IN CONTRACT`, `E.T.R. - EXISTING TO
REMAIN`, `EXIST - EXISTING`, `V.I.F. - VERIFY IN FIELD`, `T.B.D. - TO BE
DETERMINED`; a public construction programme's acronym schedule gives
`OFCI - Owner Furnished / Contractor Installed`, `OFOI - Owner Furnished / Owner
Installed`, `CFCI - Contractor Furnished / Contractor Installed`. BY OTHERS and
BY OWNER appear in neither abbreviation list, which is itself the answer: they
are plain notes, not abbreviations.

### Three findings that changed the wording

**THE PARTY IS THE OWNER, NEVER THE CLIENT.** Every standard acronym is built on
Owner and none on Client. Client is a word for correspondence; Owner is the word
for contract documents.

**"BY OWNER" ALONE IS AS AMBIGUOUS AS "BY OTHERS".** It does not say whether the
owner only bought the thing or also sets it. On this kitchen every appliance is
the owner's and who sets them is live and costs money, so BY OWNER is the note
that starts the argument rather than the one that ends it. The trade closed that
seam long ago with the furnish / install split: FURNISH is to supply and deliver,
INSTALL is to set in place, PROVIDE is both.

**AND WE DO NOT NAME OURSELVES AT ALL.** The draft of this document said
`INSTALLED BY UCON`. Andriy, 2026-08-31: the installer may end up being somebody
else, so a company name on a drawing goes stale. He is right, and the fix is
not a better name for us - it is that a contract document describes SCOPE
RELATIVE TO THIS CONTRACT and not people. The proof is the existence of N.I.C.:
a note meaning *not in contract* is only needed because IN CONTRACT is the
default that goes unwritten. `OFCI` is also refused for a second reason - on a
sheet read by a GC, "Contractor Installed" reads as the GC, and to them we are a
subcontractor.

When a sheet ever must point at somebody else's scope it names a TRADE and never
a company - BY G.C., BY ELECTRICAL CONTRACTOR, BY STONE FABRICATOR. In our own
set that is never needed for our own work. *(That last paragraph is reasoned from
the convention rather than quoted from a source; the abbreviations above are
quoted.)*

### What prints

| reason + install | prints on the sheet |
|---|---|
| `owner_furnished` + `ucon` | **OWNER FURNISHED** |
| `owner_furnished` + `not_ucon` | **OWNER FURNISHED — INSTALLATION N.I.C.** |
| `by_others` + `ucon` | **FURNISHED BY OTHERS** |
| `by_others` + `not_ucon` | **BY OTHERS** |
| `existing` | **EXISTING TO REMAIN** |
| `building` | nothing |
| `drawing_aid` | nothing, and hidden on every sheet |
| anything `undecided` | nothing, **and it blocks the sheet** |

All caps, as the rest of a construction drawing. `installed_by: ucon` is
recorded on the body and does NOT print, because the default sentence in the
legend already says it.

**The slug is not the printed word, and they must never be the same string.**
The slug lands on a body and is stable; the phrase lives in one lookup. The
wording changed three times while this section was being written and not one
body would have had to be touched. Same argument as `Retag::TAGS` taking the
generator's constants rather than retyping them.

---

## 3b. The legend, and it is not optional

Andriy, 2026-08-31: the decoding has to come out somewhere in LayOut. It does,
and one line of it is load-bearing.

### The sentence the whole scheme rests on

> **Unless noted otherwise, all work shown is furnished and installed under this
> contract.**

Without it, *unmarked means ours* is an assumption we hold privately. With it, it
is a statement the sheet makes. It is the most consequential line on the drawing
and it is one sentence.

And it is only SAFE because of section 4: nothing undecided reaches a sheet. The
default rule and the sheet block are one rule seen from two sides, and neither
may be built without the other.

### The two blocks

**SCOPE** — the notes actually used on that sheet, spelled out:

- Unless noted otherwise, all work shown is furnished and installed under this
  contract.
- OWNER FURNISHED — supplied by the owner; installed under this contract.
- OWNER FURNISHED — INSTALLATION N.I.C. — supplied by the owner; installation is
  not in this contract.
- FURNISHED BY OTHERS — supplied by another party; installed under this contract.
- BY OTHERS — supplied and installed by another party; not in this contract.
- EXISTING TO REMAIN — in place before this work; not altered under this
  contract.

**ABBREVIATIONS** — this system contributes exactly ONE: `N.I.C. — NOT IN
CONTRACT`. V.I.F., T.B.D. and the rest come from other parts of the sheet, and we
do not print an abbreviation nothing on the sheet uses. Learned rule 8.

### It is DERIVED, like the elevation description

The legend lists the notations that actually occur on that sheet, and no others.
A legend that names BY OTHERS when nothing on the sheet is by others sends a
reader hunting; a note with no legend line is worse. This is the same failure as
an index nobody maintains, and this repository met that one on 2026-08-31 when
two new notes were not added to `claude/README.md` and the suite caught it.

**Honest about the mechanism, exactly as with the notes:** SketchUp cannot write
into a LayOut document. What the engine can do is EMIT the legend text - from the
same lookup that prints the notes, so the sheet and the by-others schedule cannot
disagree - and a person places it once. A placed block can then go stale, so the
emitted legend carries a generation stamp, and the pre-flight window reports the
lines the sheet needs so a person can compare. Learned rule 13: a record of an
outside action is only true if something checks it.

### Where it goes

**On every sheet, not once per set.** A GC often holds one sheet, and a scope
statement that lives only on the cover is a scope statement that particular
reader never saw. Repeating it costs nothing. Andriy's call if he wants it
otherwise.

---

## 4. UNDECIDED IS NOT "BY OTHERS"

Whether the worktop is bought on this project at all is undecided — handoff §2,
Andriy 2026-08-31. If a body with no decision defaults to printing BY OTHERS,
we have handed a competitor, in writing, work we have not decided about.

**Learned rule 7, verbatim: unknown is `nil`, never zero.** A body with no
decision prints NOTHING and sits in the second or first section until somebody
decides. There is no default reason, there is no fallback reason, and the
writer refuses rather than choosing.

**AND THE MIRROR OF IT, which is the reason this section is load-bearing rather
than tidy.** Section 3b's legend says that unmarked work is ours. So a body that
prints nothing does not merely stay silent - on a sheet it reads as OURS. The
undecided worktop printing nothing would therefore claim scope we have not
decided, which is the same error as BY OTHERS by default, inverted.

There is exactly one resolution and it is not a wording: **an undecided body
blocks the sheet.** It is not printed either way, it does not leave quietly, it
sits in the window's first section, and no sheet is issued while that section has
rows. That is what turns the window from a report into a PRE-FLIGHT, and it is
what makes the legend's default sentence safe to print.

---

## 5. The declaration is a fact on the BODY, not a tag

Written into the `CabinetEngine` dictionary, beside `object_class`, and read the
same way `Retag.object_class_of` reads: **instance first, then definition.** Any
other reading and ownership and declaration disagree on the first copy —
learned rule 11, the dictionary is the object.

> **CORRECTED 2026-09-01, DATED AND ADDED (learned rule 9). The sentence above is
> wrong about the DICTIONARY and right about everything else.** It cannot be the
> `CabinetEngine` dictionary, and the contract says so twice: §1.2 rejects any key
> outside the closed `KEYS` list, and `ALWAYS_REQUIRED` demands `object_class` on
> anything written there. **A declared body has no `object_class` — that is the
> entire definition of the thing being declared.** So a declaration in that
> dictionary would either violate the contract or force somebody to invent a
> class for a client's refrigerator. It lives in **`UCON_SCOPE`**, on the body,
> keys `reason` and `installed_by`, read instance-then-definition exactly as
> described. This is the same argument `core/08_project.rb` makes for
> `UCON_PROJECT`: a different dictionary on a different kind of fact — the
> contract describes the objects WE make, and a declaration describes one we do
> not. A suite check pins it so the two can never merge.

**Why not a tag, given the current code declares by tag:**

1. Moving a body onto `UCON — Placeholder (not ours)` changes which SHEET it
   prints on, and eight scenes already hold saved opinions about those tags.
   That is candidate learned rule 21 exactly — a scene older than a tag holds an
   opinion nobody formed. **Declaring must not cost a single sheet.**
2. The whole point of this report is that a tag is not ownership. Declaring by
   tag is the same category error from the other side.
3. It is nearly free to change, because the tag branch has never fired.
   Declared has always read 0: the only bodies on those two tags are the
   engine's own, they carry a class, and `owned?` is asked first. Learned rule
   18 — an invariant asserted sideways, discovered when it stops being vacuous.

### The lever that keeps the list short by itself

`orphans` already does `next if declared?(n)` **before** descending into
children. So **declaring a CONTAINER declares its whole subtree.** One group of
client appliances is declared once, and every appliance dropped into it
afterwards is born declared. Clicking bodies one at a time is O(n) forever;
this is the part that makes the list stay short without anybody maintaining it.

The same lever already pays before any code ships: the conditional floor
(`Group#5`) nests inside the room (`Group#1`) as a nested group — not exploded,
or SketchUp welds the faces and cuts the wall bottoms — and the report drops
from four rows to three, because the room owns nothing and is therefore reported
as one row and not descended into.

### Two refusals

- **A body carrying an `object_class` cannot be declared.** The window names the
  class and refuses. Otherwise somebody declares one of our cabinets in a month.
- **`owned?` is asked before `declared?`, everywhere, by everybody.** Probe 54's
  own dump asked them the other way and printed two engine objects as declared
  while the shipped `counts` was right. Twelve hours after the
  definition-versus-instance lesson, a throwaway reader made the same shape of
  mistake.

---

## 6. What gets removed, precisely

**One rule.** In `core/68_report.rb`, `declared?` stops meaning *sits on the
Placeholder or Reserved tag* and starts meaning *carries a recorded reason*.
That is `declared_tags`, two lines of `declared?`, and the suite check that
currently proves the bucket through tags.

**What is NOT touched, so that nobody reads this as a bigger change than it is:**

- the tags `UCON — Placeholder (not ours)` and `UCON — Reserved void` stay, and
  the generator keeps assigning them;
- `Retag::TAGS` keeps its `appliance` → Placeholder and `void` → Reserved rows;
- the engine's appliance niches and reserved voids stay out of the list exactly
  as before — **because they carry a class, not because they carry a tag**;
- Retag's refusal 2 — never move a body that already carries a UCON tag — stays,
  and matters more after this, not less.

**Measured, not assumed:** probe 54 found exactly two bodies on those two tags,
both the engine's own, both classed. **The list changes by zero rows.**

**The one live consequence:** a body put on the Placeholder tag by hand will no
longer go quiet. That is the design, the same doctrine as the sentinel. So the
report says so on the spot — a row on a declaring-looking tag with no recorded
reason is flagged **"on a Placeholder tag, not declared"** — and the surprise is
explained where it is felt instead of being reported as a bug.

---

## 7. And the tag gets its job back, from the other side

The declaration is the FACT. The tag is the DRAWING CONSEQUENCE of the fact, so
that by-others work can be greyed, dashed or switched off per sheet.

Applied by a PASS, like Retag, never by the button. The chain is:

> reason on the body → a pass puts it on a presentation tag → LayOut shows the
> tag → the legend sits beside it.

**Honest about the last step:** SketchUp cannot push a text note into LayOut.
What it can do is make the model self-describing so the legend is mechanical to
place, and EXPORT the by-others schedule as a list — the same shape as the
element list the engine already writes, except this one is not for Cesar. It is
for the GC. Not scoped, named here so it is not discovered by accident.

---

## 8. What the suite must prove

Learned rule 12: a guard proves itself against the defect it exists for.

1. Declaring a body that carries an `object_class` is refused, and the refusal
   names the class.
2. A declared CONTAINER removes its whole subtree from the list.
3. The per-reason counts and the list are derived from one tree and cannot
   disagree.
4. **The defect itself:** a tree of the Wolf range plus the fridge plinth, where
   the plinth is marked as a debt and NOT declared, and the plinth must stay
   visible in the second section. A declare button that can silence it fails
   here and its author reads this paragraph.
5. The existing sentinel — a tag never stands in for a contract — is untouched
   and still passes.
5a. The printed-word lookup is TOTAL: every reason paired with every
   `installed_by` value resolves to exactly one phrase or to an explicit
   nothing, and no pair falls through to a default. A fall-through here is a
   scope statement nobody wrote.
5b. The emitted legend names every notation the sheet uses and no notation it
   does not — checked against the same tree the notes come from, so the two
   cannot disagree.
5c. A model holding one `undecided` body reports the sheet as BLOCKED.
6. Nothing writes a tag on a declaration, and no scene changes: after the
   button runs, the eight scenes are byte-identical.

---

## 9. Not in scope

The stamp. The delta of *what is new since the last run*. Deleting from the
window. The by-others export. The install axis printing anything. The template
pass — one correct elevation by hand first, Andriy 2026-08-29, unchanged.

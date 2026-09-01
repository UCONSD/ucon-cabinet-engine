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

Closed list. **The words are OPEN and will be revisited** — Andriy, 2026-08-31,
and he is right that they matter more than the structure, because a GC reads
them. The structure below does not depend on which words win.

| reason | means | prints on a sheet |
|---|---|---|
| `owner_furnished` | the client's own item | yes |
| `by_others` | supplied AND installed by somebody else | yes |
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

**Field: `installed_by`. Values: `us`, `others`, `undecided`. Default
`undecided`.**

The field is written from the first day and **prints nothing yet.** Adding it
later would mean migrating attributes across bodies in a live model; adding it
now costs nothing. What learned rule 6 forbids is INVENTING VALUES on one case,
so the value list stays at three until a sheet asks for a fourth. When it does
start printing, that is a second scope statement and gets accepted as
deliberately as the first.

---

## 4. UNDECIDED IS NOT "BY OTHERS"

Whether the worktop is bought on this project at all is undecided — handoff §2,
Andriy 2026-08-31. If a body with no decision defaults to printing BY OTHERS,
we have handed a competitor, in writing, work we have not decided about.

**Learned rule 7, verbatim: unknown is `nil`, never zero.** A body with no
decision prints NOTHING and sits in the second or first section until somebody
decides. There is no default reason, there is no fallback reason, and the
writer refuses rather than choosing.

---

## 5. The declaration is a fact on the BODY, not a tag

Written into the `CabinetEngine` dictionary, beside `object_class`, and read the
same way `Retag.object_class_of` reads: **instance first, then definition.** Any
other reading and ownership and declaration disagree on the first copy —
learned rule 11, the dictionary is the object.

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
6. Nothing writes a tag on a declaration, and no scene changes: after the
   button runs, the eight scenes are byte-identical.

---

## 9. Not in scope

The stamp. The delta of *what is new since the last run*. Deleting from the
window. The by-others export. The install axis printing anything. The template
pass — one correct elevation by hand first, Andriy 2026-08-29, unchanged.

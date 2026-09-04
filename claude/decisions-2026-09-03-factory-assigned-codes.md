# A code the catalog does not print: the round trip, and who decides what

**Andriy's rule, 2026-09-03.** Written down the day the first instance was
worked through in full — estimate 2026/30833 row 8, `PE1299`, the cabinet over a
48-inch range.

---

## The rule

**When an element is not in the catalog, we draw it the way we want, and we send
it to Elda.** She does with it whatever she judges right inside Metron. She
sends back an order. **We read the code off that order, we compare HER geometry
with OURS, we decide whether her solution suits us — and then we assign her code
to our object.**

Even though the code is in no catalog and in no registry file we hold.

**The comparison is the part that is not optional.** The code is hers; the
geometry is the check. Taking the code without reading the geometry would be
accepting a solution we have not looked at, and the whole point of sending a
drawing is that the answer comes back as a thing we can measure.

---

## Why this does not break the rules it looks like it breaks

**Domain rule 5** — *code grammar is family-specific; codes decode only via
explicit registry rows, never by analogy.* Untouched. Nothing here decodes a
code. `PE1299` is not deduced from `PE1204` by analogy; it is **read off a
document the factory sent us**. Decoding it afterwards, as we did, is a check on
the reading and not the source of it.

**Object Contract v2 §4.2 rule 2** — *companions are resolved from the registry,
never typed; a code that reached an object by being typed is a defect.* Also
untouched, and this is the important one. That rule exists to stop a code being
INVENTED at a keyboard. A factory-issued code is not invented; it is received.

**Domain rule 1** — *the source PDF wins; never invent a catalog fact.* This is
the rule the round trip actually sits under, widened by one word: **a priced
order from Metron is a SOURCE of the same kind as a printed page**, for a
position the printed pages do not carry. A made-to-drawing element is by
definition not printed, so the catalog cannot be the authority for it and
something has to be. The factory that will build it is the only candidate.

**And `three-level-validation-2026-09-02.md` already decided the split:**
anything about the FACTORY — which code is emitted, what an article contains,
how a variant is expressed — Metron wins. Anything about the OBJECT — measured
site dimensions, clearances, panels for the client's appliances — we win. This
rule is that split applied to a position that has no catalog row at all. **Her
code, our dimension.**

---

## What it does NOT license

- **Inventing a code.** Not a guessed suffix, not a width index reasoned out, not
  a code assembled from grammar. If it did not arrive on a document, it does not
  exist.
- **Reusing a code on a second object by analogy.** One code, one position, one
  named row of one named document. A second cabinet that looks similar gets its
  own round trip.
- **Skipping the geometry comparison.** A code accepted without reading her
  solution is a code accepted on trust, and the first instance below is exactly
  why that would have been wrong.
- **Writing it as CONFIRMED.** An estimate is a quotation. `code_status` stays
  `PRELIMINARY` until Elda or Giorgio confirm in writing (domain rule 2).

---

## What goes on the object

Everything needed to answer *where did this code come from* without leaving the
model:

- `code` — hers, verbatim.
- `code_status` — `PRELIMINARY`.
- `source_ref` — the document and the row, named: `Metron estimate 2026/30833
  row 8`. Not "the factory", not "Elda" — the document, because the next reader
  has to be able to open it.
- `notes` — what it replaced and why, in one sentence, so that a body whose code
  changed says so on itself.

**The registry gets nothing.** A project-scoped code is not a catalog fact and
must not enter `registry/`, which is the printed book and only the printed book.
That leaves such a code living on the object and nowhere else, which is
deliberate and is also an open question: **there is today no store for
"codes this project received from the factory"**, and the second project will
want one. Not built, not designed, named here so it is not discovered twice.

---

## The first instance, worked through — row 8, and the 48 inches

Kept because the rule reads as obvious and the instance shows why it is not.

**What we drew.** Two boxes over the range, `SD0631` each, 610 × 720 × 620, at
x 1903 and x 2513, together **1220** — which is the width of the range
reservation, `1220.0 mm (DF48650C/S/P, 0.8 breathing space)`. **1220 is 48
inches plus eight tenths.** The appliance is American and the number is the
appliance.

**What she sent back.** One row, not two: `PE1299`, L 1200 × H 720 × P 620,
`LX19`, **`ELEMENTO A DISEGNO`**. A body count change, not a rename.

**What the code decodes to**, by our own grammar in
`registry/cesar/_manifest.json → code_grammar.wall_units`: `P` wall unit, `E`
family H.72 (the letter is a lookup: B=36, C=48, D=60, E=72, F=96, G=84, J=120),
`12` width index → 1200, `99` type suffix. The slot is real and priced — printed
*Wall units H. 72*, row W. 120, holding `PE1204`, `PE1207`, `PE1210`, `PE1212`,
`PE1274`, `PE1276`, `PE1278`, `PE1279`, `PE1282`, `PE1284`, `PE1285`, `PE1286`,
`PE1289`, `PE1292`. **Suffix 99 is not among them**, and `PE1299` appears in none
of the four Cesar volumes.

**And now the comparison, which is the whole rule.** Her printed L is **1200**
and her own 3D draws the solid at **1200**. Ours is 1220.

**1200 does not cover a 48-inch range.** 48 in = 1219,2 mm. The catalog prices
121,9 cm only for BASE units, in the USA Elements chapter — `B82250`, `B92250`,
`BL2250`, `BM2250`, width field 22. **No wall unit and no top element is printed
at 121,9 anywhere in the book**; the wall chapters print no inch widths at all,
and the widest metric wall slot is W.120 = 1200, which is 19,2 mm short of the
appliance. `SE1200` — top element H.72, W.1200, d.620, which we already hold —
does not solve it either, being 1200 as well.

**So there is no printed article for this cabinet at any height, and that is
exactly why the position is `ELEMENTO A DISEGNO`.** The factory took the nearest
existing slot and marked it made-to-drawing, because the metric grid has nothing
to offer an American appliance.

**The decision, therefore: her code, our 1220.** Her 1200 is not a measurement
of anything — it is the label of the slot the code sits in. Had we taken the
code and not compared the geometry, we would have ordered a cabinet 19,2 mm
short of the range beneath it.

*(This corrects a reading made earlier the same day and is dated rather than
erased, learned rule 9: the session first wrote that "on row 8 she is right and
we are 20 mm over". She is right about the CODE and about the slot. She is not
right about the width, and the printed book is what says so.)*

---

## Candidate domain rule 10, and deliberately NOT added

*A position the catalog does not print takes its code from the factory's own
order, and its dimensions from us — and the code is only accepted after her
geometry has been compared with ours.*

`claude/rules.md` holds domain rules 1-9 and learned rules 1-20. Three learned
candidates are already waiting on Andriy and are not added either. This one is
recorded here in words, with its instance, which is the form this repository
trusts: **a citation that carries its own claim survives a collision; a bare
number does not.**

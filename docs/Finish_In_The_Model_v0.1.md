# Where a finish lives in the model — v0.1

**Date:** 2026-08-30 · **Status:** PROPOSAL, nothing implemented · **Decision:** Andriy's

This note exists because two things were decided this week that the model has
nowhere to put, and because the first answer proposed for them was wrong in a
way the contract itself catches.

---

## 1. The problem, stated once

Two facts about 545 Avenida Primavera are now settled, both are ORDER facts, and
neither can be written onto an object:

**The oak/black split.** Which units are `RR09 Rovere Nordico` and which are
`LX19 Nero`. The Object Contract has 31 keys and not one is about a finish —
`Contract::KEYS.select { |k| k =~ /finish/ }` returns `[]`, checked by probe 105.

**The finishing side panels.** The two custom boxes over the range carry a
finished side on their outer cheek only — printed p.553, Volume 2, a surcharge
that REPLACES the carcass side. Nothing on the object says which cheek, or that
there is one.

Both are currently carried by **paint on faces in the .skp and by nothing else**.
That is not nothing — the Maxima 2.2 order form says mixed finishes must be
specified *"for each single element in the list or on the drawing"* (printed
p.65), and the drawing is ours. But paint is erased by any rebuild: the generator
writes `UCON_Front_White` at build time (`60_generator.rb:387`, `:577`,
`80_panel.rb:708`). **A fact that a rebuild deletes is not recorded.**

---

## 2. The first answer, and why it is wrong

The obvious proposal — and the one made in conversation on 2026-08-30 — was a
**v2.5 revision adding two keys**, a finish and a `finished_sides`. Written down
and read against the contract, it does not survive §4.2 rule 6:

> **A variant earns its own contract key only when geometry reads it.**
> `hinge_side` and `opening_method` are first-class because the front builder and
> the symbol renderer read them. Everything else — `OPENING DIRECTION`,
> `WIDTH REDUCTION`, `Smontato`, **`FINISH: Stainless steel`** — lives in
> `variants`. Without this rule the key list grows one entry per surcharge and
> ends up with thirty.

**A finish is the rule's own example of what does NOT become a key.** And a
finished side is a surcharge, which is the exact growth the rule was written to
prevent. §0 closes the escape: *"If a rule here is inconvenient, the rule is not
what gets adjusted."*

So the proposal is withdrawn as stated. What survives is the observation that
prompted it, and it needs a different home.

---

## 3. What actually changed, and it is not the contract

Rule 6's test is **"geometry reads it"** — and until this week nothing did.
A finish was a thing written on an order and never a thing the model drew, so
`variants` was the right place and the rule was right.

**On 2026-08-30 that stopped being true.** The paint pass reads which finish an
object carries in order to colour its faces, and the elevation is the deliverable
that carries the split. The front builder reads `hinge_side` for exactly the same
kind of reason.

So the question is not "should the rule bend" but **"does a finish now pass the
test the rule already sets"** — and the honest answer is that it does, while the
cheaper answer is that it does not have to.

---

## 4. The cheaper answer, and the recommendation

**`variants` already has the right shape and needs no revision at all.**

It is a structured key (§1.4), a list one level deep, each line carrying
`key` · `value` · `label` · `source_ref`. A finish is exactly that: a key
(`front_finish`), a value (`RR09 Rovere Nordico`), a source (printed p.58), and
— since v2.3 — a `label` that exists *"for a symbol on a drawing"*, which is
precisely what an elevation needs.

```
variants: [
  { key: 'front_finish',   value: 'RR09 Rovere Nordico', label: 'RR09',  source_ref: 'V1 p.58' },
  { key: 'finished_side',  value: 'left, LX19 Nero',     label: 'fin.L', source_ref: 'V2 p.553' }
]
```

**What this buys, today, with no migration:**

- the split stops living only in paint, and survives a rebuild
- the exporter already emits variants, so it reaches the order without new code
- the paint pass reads variants instead of a hard-coded plan, and
  `tools/probe_inbox_hold_112.rb` — 53 hand-maintained plan lines — **goes away**
- rule 6 is satisfied rather than argued with

**What it costs:** reading a variant is more work than reading a scalar, and a
variant value is free text where a key could be enum-checked. Both are real and
both are smaller than a contract revision.

**Recommendation: do this, not the revision.** If, after living with it, the
paint pass and the exporter are both fighting the free-text value, that is the
evidence a key was needed — and it will be evidence rather than a prediction.

---

## 5. What this does NOT solve, said out loud

- **The p.553 surcharge table is still not in the registry.** Five depths ×
  fourteen heights × eleven bands. An exposed carcass side anywhere in this
  kitchen has a printed price nothing in the engine can look up. That is learned
  rule 14 and it is independent of everything above: it is a REGISTRY gap, not a
  contract one.
- **`D.62 H.72` is not a row in that table**, and the two custom boxes are
  exactly that. Andriy, 2026-08-30: the cabinet is custom, it goes to Elda as a
  note in the material specification, and she prices the modification against
  Metron. Not to be solved here.
- **The rebuild still repaints.** Recording the finish in `variants` means a
  rebuild can RESTORE the right colour instead of losing it — but only once the
  generator reads it. Until then the record is honest and the picture still needs
  a repaint.

---

## 6. The reason this note exists at all

The v2.5 proposal was made confidently, in conversation, from a correct
observation — and it took reading two paragraphs of the contract to find that the
contract had already considered the case and ruled the other way, naming a finish
as its example.

**Same shape as the day's other lesson, one level up.** Three times on 2026-08-30
a count looked right and hid a defect. This is a fourth: an argument looked right
and the document it was arguing about had already answered it.

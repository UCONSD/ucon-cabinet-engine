# 2026-08-30 — the oak / black split, and the four panels that had already decided half of it

**Laptop, `macbook-pro-4-local`, core 1.6.0, HEAD `3cd3e63` at the start.**
Three read-only probe runs (105, 106, 107 unarmed) and four printed pages.

The last of the thirteen finish questions. `claude/decisions-2026-08-29-finishes.md`
ends by naming it: *"AND THE SPLIT ITSELF IS NOT DECIDED. Which units are oak and
which are black was not part of these thirteen answers. It is the next question
and it is a drawing question."*

---

## 0. The question was smaller than it looked, and the catalog is why

Before any taste enters: **six panels in this model can only ever be oak, and
they were ordered that way days ago.**

`DZ731Q` ×4 (the island's whole back), `DV731Q` ×2 (both island ends) and
`DV061Q` ×2 (the east run's end, and its top band's end) are **price group A —
First wood veneers**. printed p.218 and printed p.220 print that group as exactly
seven Rovere: Sbiancato, **Nordico**, Mediterraneo, Fossile, Dark, Corvino,
Cortado. There is no lacquer in group A at all. `tools/test_contract.rb:8394`
already refuses any other family, in as many words: *"a letter that stops meaning
oak must fail here rather than in an order."*

So both visible ends of the island, the island's entire seating side, and the
end of the tall wall were oak before the question was asked. **The split was
never "which units are oak" — it was "which of the two masses these panels
already belong to also gets oak fronts."** Put that way it has three answers
instead of dozens, and Andriy took it in one pass.

**This is the second time on this project that the catalog answered a question
recorded as open.** The +30 top overhang was the first.

---

## 1. The decision

**Andriy, 2026-08-30: both masses. The east wall floor to 3040, and the island.**

Asked separately and answered separately: the seven `SD0631` in the band at 2440
above the tall run are **oak too** — the east wall is one plane, and its top
band's own end panel `DV061Q` is group A and could not have been black anyway.

| | | m² of front |
|---|---|---:|
| **OAK — `RR09 Rovere Nordico`**, First veneer, F6 | east wall floor to 3040: `C00151`, `C92640`, 4× `C90635`, `BE0151`, 7× `SD0631`, `UCON-BESP-001`; island: 4× `B80653` | ≈ 9,3 |
| **BLACK — `LX19 Nero`**, structured lacquer, F6 | west run: `AU110D`, `B80565`, `B81087`, `V80630`, `B70501`, `B70150`; south base: `B80501`, 2× `B80753`, `B70151`; south uppers: `PF0151`, 2× `BE0151`, 9× `SD0631`, `SD0930` | ≈ 7,3 |
| **neither** | 3× `TF0641` — black frame, black silk-screen, transparent glass, decided 2026-08-29. Not a door finish. | — |

**43 objects carry a front and all 43 are assigned.** Probe 106 proved it against
the model rather than against this table: every one of the 43 plan lines matched
exactly one object, nothing with a front was left over, and nothing without a
front was planned.

Also painted oak, and not a choice made here: the six Cesar veneer panels above,
and the three Sub-Zero overlay panels, which carry no article, are ours, and
stand in the east wall.

---

## 2. The guard that mattered, and it was asked of the model

**A hand copy shares its definition until `Apply` splits it.** `SD0631` falls on
BOTH sides of this split — seven oak on the east wall, nine black on the south.
If those instances shared one definition, painting the `FRONT` group inside it
would paint both sides and the split could not be drawn at all.

Probe 106 asked. **Three definitions in the whole model are shared, and each is
wanted in one finish only:** `B80653` ×4 (all oak), `B80753` ×2 (both black),
`SD0631` ×2 (both black). Every other object has its own definition. No conflict,
nothing needs making unique.

**Asking cost one read-only run. Assuming would have cost a repaint of the wrong
wall**, and the assumption that felt safe — "the SD0631s are copies of each
other" — is the one that was false.

---

## 3. Where the split can live, and it is not the data

**The Object Contract has 31 keys and not one of them is a finish.** Confirmed
again on 2026-08-30, probe 105: `finish keys = []`. There is nowhere in the model
to write that this door is RR09 and that one is LX19.

And **the printed order form does not carry the colour either.** printed p.65,
the PLAIN DOOR block, offers only the FAMILY — `Structured` under lacquer,
`First` under wood veneer — and both may be ticked at once, so a mixed kitchen is
a shape the form expects. What it never asks for is which element is which. Every
finish block on that page repeats the same sentence:

> *"if the kitchen has various finishes they must be specified for each single
> element in the list or on the drawing"*

**So the drawing is not one of two ways to record this split. With no contract key
and no field on the form, the drawing and the element list are the only two, and
the drawing is ours.** That is what makes two SketchUp materials the deliverable
and not a nicety.

`tools/probe_inbox_hold_107.rb` paints them: `UCON_Finish_RR09_Rovere_Nordico`
and `UCON_Finish_LX19_Nero`. **They are named for the finish, not for the kind of
body.** All nine existing `UCON_*` materials say *this is a front* or *this is a
carcass*; these two say *this is what was ordered*, which is the first time the
model has recorded an order fact in a material.

Unarmed rehearsal, run 18: 19 oak fronts, 21 black fronts, 11 bodies, 3 `TF0641`
untouched. Rolled back, as designed.

---

## 4. Owed, and named rather than quietly carried

- **The paint does not survive a rebuild.** The generator writes
  `UCON_Front_White` at build time — `60_generator.rb:387` and `:577`,
  `80_panel.rb:708`. Anything rebuilt comes back white. This is the standing
  *"the model is not recomputed when the engine changes"* debt acquiring a second
  victim, and it is now cheap to argue that the contract should carry a finish
  key after all — a v2.5 revision, not a patch, and Andriy's call.
- **The two `MNS040038` shelves have no finish.** They sit at x 3123…3997 in the
  black zone, but they are Linear Elements sold per linear metre, not doors, and
  no finish block on printed p.65 covers them. Unassigned on purpose; asking is
  cheaper than guessing.
- **The mixed-arrangement footnote is now maximally sharp.** printed p.13 puts
  any arrangement with First veneered fronts onto the Prime band — 7 in Maxima.
  This split puts ≈ 9,3 m² of First veneer on the two biggest masses in the
  kitchen. It does not change the question, but it removes any chance of the
  answer being academic.

---

## 5. What this cost, and one mistake worth keeping

**A file dropped into `tools/probe_inbox/` is executed within seconds.** Probe 106
went in carrying a syntax error and the bridge ran it, failed it, and filed it in
`done/` before it could be checked. No harm — a `SyntaxError` paints nothing —
but the habit is wrong. **Syntax-check outside the inbox, then move the file in.**
The inbox is hot; it is not a place to keep a draft.

And the day's real lesson, which is section 4 of
`claude/findings-2026-08-28-panels-the-letter-is-a-lookup.md` and now carries a
dated correction there:

**A document that describes a guard is not the guard.** That file states that a
check refuses the group-A codes. The check that exists refuses group B — the
exact opposite — and the two drifted apart inside a single day, on the same
subject, in the same commit's work. The model, the held probe, the registry and
the suite all agreed with each other and only the prose disagreed. **Four
artefacts against one sentence, and the sentence was the one a next session would
have read first.**

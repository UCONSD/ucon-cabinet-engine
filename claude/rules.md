# The rules, and which list a number belongs to

**Read this before writing `rule N` anywhere.** This repository cites rules by
bare number about ninety times, and until 2026-08-27 there was no file saying
which list a number came from. There are **four** numbering schemes, three of
them starting at 1, and at least eight citations were pointing at the wrong list.

Numbers are NOT being renumbered. Renumbering would silently change what every
historical note and commit message says, which is the one thing learned rule 9
forbids. Instead **every citation names its list**, and a check keeps new ones
honest.

## How to cite

| write | means |
|---|---|
| `domain rule 4` | CLAUDE.md → *Non-negotiable domain rules*, 1-9. What the CATALOG and the OBJECT require. |
| `learned rule 4` | `claude/ucon-cabinet-engine-status.md` → *RULES LEARNED THE HARD WAY*, 1-20. What went WRONG once and must not again. |
| `§4.2 rule 4` | `docs/UCON_Object_Contract_v2.md` → the numbered rules inside a section. Already unambiguous; leave these alone. |
| `Contract v2 §1.1` | a section reference, not a rule number. |

A bare `rule 4` is now a defect. `tools/test_contract.rb` fails on one in
`tools/`, `src/` or `registry/`.

---

## Domain rules — CLAUDE.md

What the catalog and the object require. Breaking one produces a wrong ORDER.

| | |
|---:|---|
| 1 | The source PDF wins. Never invent a catalog fact; unclear → an Elda question. |
| 2 | Everything is PRELIMINARY until Elda/Giorgio confirm in writing. |
| 3 | The Object Contract is load-bearing; changes only via a versioned revision. |
| 4 | Envelope-only geometry. Carcass = one volume, front flush, no interior unless the source states it AND a drawing needs it. |
| 5 | Code grammar is family-specific. Codes decode only via explicit registry rows, never by analogy. |
| 6 | Per-order axes live outside the article code — door version 78/75, hinge side. |
| 7 | A corner unit's hand is TWO things: the execution letter and the door's own hand. |
| 8 | An appliance is two objects: the Cesar panel (ordered and drawn) and the machine's niche (drawn, never ordered). |
| 9 | A choice can oblige or offer companion order lines; companions come from the registry, never typed by hand. |

## Learned rules — `claude/ucon-cabinet-engine-status.md`

What went wrong once. Breaking one produces a wrong BELIEF, which is worse,
because it looks like knowledge. Every one of these has at least one instance
behind it and most have several; the status document carries them.

| | |
|---:|---|
| 1 | A section in `catalog_map` is one the printed index prints. |
| 2 | Run the suite on BOTH machines; write to the lowest Ruby in play (macOS ships 2.6.10). |
| 3 | Silent applies to the GESTURE, never to the RECORD. |
| 4 | A rule that generalises past its evidence is a future bug with a date on it. **Record the SCOPE.** |
| 5 | Ask, don't recompute. |
| 6 | A constant chosen when there was one case is a bug waiting for the second. |
| 7 | Unknown is `nil`, never zero. |
| 8 | A number no source gives us is not written down. |
| 9 | A correction is DATED AND ADDED, never an edit that erases the mistake. |
| 10 | An absence — or a presence — in extracted text is not one on the page. Look at the render. |
| 11 | The dictionary is the object. *(Corollary: a pure layer being right proves nothing about its caller.)* |
| 12 | A guard must prove itself before it is trusted — run it against the defect it exists for. |
| 13 | A record of an outside action is only true if something checks it. |
| 14 | A rule written in prose is a rule no code can read. Move it to data. |
| 15 | A successful write is not a correct write — check the identity fields. |
| 16 | A command that did not run leaves no trace, and that is the danger. |
| 17 | Format a listing as a listing. A fenced code block reads as "run this". |
| 18 | A suite can assert an invariant sideways, and you find out when it stops being vacuous. |
| 19 | A pass over the model is not a rule about it — whatever is built afterwards is untagged. **Re-run Retag before any sheet.** |
| 20 | A detector that watches the model cannot tell your write from a person's edit in the same window. |

---

## The three collisions that made this file necessary

Found 2026-08-27, while tidying. All three were live in committed data.

**`rule 1` meant two things.** `registry/cesar/dish_drainer_h120.json` uses it
for *"a section is what the printed index prints"* (learned 1) and
`registry/cesar/appliance_h78.json` for *"the source wins"* (domain 1), four
files apart.

**`rule 4` meant three things.** Domain 4 is envelope-only geometry; learned 4
is *record the scope*; and a dozen registry notes and two source files cite
*"rule 4"* for **"this is a UCON decision, not the catalog's"** — which is in
NEITHER list. That phrase is a real and useful idea; it had simply attached
itself to a number that did not hold it. Those citations now read
`learned rule 4`, whose *record the SCOPE* is the half that actually applies,
and the UCON-decision half is said in words beside it.

**`rule 9` was the only one nobody ever got wrong**, in thirty-six citations,
because its text — *a correction is dated and added* — is quoted in almost every
one of them. **A citation that carries its own claim survives a collision; a
bare number does not.** That is the whole argument for this file.

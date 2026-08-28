# 2026-08-28 — finishing the panels: a price group is not a finish

**Andriy set the direction:** appliances are paused, the project has to be
finished and given to Elda to price, and appliances do not affect that. Next is
the Counter-Top — **but the panels come first.**

The panels are the island's six. Probe run 78 confirms they are the only Cesar
panels in the model: six `DZAK22`, plus three UCON fridge panels carrying no
article and two `MNS040038` shelves. **And no `object_class: worktop` exists
anywhere**, which is the Counter-Top task confirming it is genuinely unstarted.

---

## 1. What "finish the panels" turned out to mean

`repo-state.md` owed 13 says the island's material is undecided and *"the code in
the model is lacquer where it will be wood"*. `tools/probe_inbox_hold_71.rb` — the
armed probe, written and deliberately held — already had wood codes in it:
`DZ731Q` for the backs and `DV731Q` for the ends, both **price group A**.

**That group was never confirmed by anybody.** It was chosen while the probe was
written and has been sitting inside a held script ever since, and the registry
could not have caught it, because until today **every code in this chapter
carried a price-group LETTER and nothing said what the letter meant.** Ordering
"group A" was ordering an unnamed species list.

## 2. So the letters were given their names, off the pages

Volume 1 printed p.269 indexes the finishes and p.293 holds WOOD VENEERS — but
that page's header is *Breakfast bar and Living top finishes* and its two
categories (First, Prime) do not match the panels' four. **The authority for a
panel is the panel's own page**, and Volume 3 prints the groups beside the codes:

| | printed p.217 — lacquer | printed p.218/220 — veneer |
|---|---|---|
| A | Silk-effect lacquers | **First wood veneers** (7 Rovere) |
| B | Gloss lacquers | **Prime wood veneers** |
| C | Structured lacquers | **Special wood veneers** (Palissandro Santos, Ebano Macassar) |
| D | Metallic effect lacquers | **High-gloss wood veneers** (Acacia, Noce Desaturato, Sicomoro) |

`finish_family` is now recorded on all **38** coded rows. The lacquer rows carry
the family NAME and say that their finish lists are on p.217 and unread — an
absence stated rather than left to look like an oversight.

## 3. THE SAME LETTER, THE SAME PAGE, TWO LISTS

Read off a **200-dpi render** of printed p.220, because `pdftotext` interleaves
the two columns and would have let either reading through (learned rule 10):

> **"Available finishes Th. 1.8:"** offers only **B — Trama wood veneers**.
> **"Available finishes Th. 2.2:"** offers **A First, B Prime, C Special, D High-gloss**.

So on one page, `B` at 1,8 is **Trama** and `B` at 2,2 is **Prime**. printed
p.219 prints the identical structure for horizontal grain. The registry had both
as a bare `"price_group": "B"`, which is true and useless.

`finish_family` is therefore recorded **per code and never per group**, and a
check pins the 1,8 two-sided code to Trama in both grain blocks — proved by
setting it to Prime, the plausible wrong reading, and watching it fail.

A warning triangle on the same page adds the detail that makes it matter:
*"Trama finishes: 1 side with trama, 1 side polished and Trama edge."* **A
two-sided Trama panel is not trama on both sides.**

## 4. Andriy chose B — Prime. Which moved the codes.

|  | was (assumed) | is (decided) | points/m² |
|---|---|---|---|
| backs, 1,8, one side | `DZ731Q` (A First) | **`DZ735Q`** (B Prime) | 343 → **358** |
| ends, 2,2, two sides | `DV731Q` (A First) | **`DV735Q`** (B Prime) | 549 → **579** |

The probe is corrected, and a check refuses it if the group-A codes ever come
back — proved against exactly that edit. **The 663 is untouched**: it is 667 less
the 4 the back loses going from 22 to 18, and `DZ735Q` is 18 like `DZ731Q` was.
The check pins that number to the back's thickness so the arithmetic cannot drift
silently.

### And a constraint the codes cannot express

**Within Prime, the one-sided back offers NINE finishes and the two-sided end
offers SIXTEEN** — the same nine, plus the seven Trama. printed p.218 against
printed p.220.

> So this island can only be finished in the nine both can be: **Rovere
> Termocotto, Castagno Sbiancato, Castagno Grigio, Castagno Toscano, Noce
> Desaturato, Noce Sgubbiato, Eucalipto, Abete Nero, Rovere Rigatino Sbiancato.**
> **A Trama finish cannot be matched across it** — the ends could have it and the
> backs could not.

**Nothing in the codes says this.** Both are *group B, Prime wood veneers*, and
the finish name is an order field that changes no article — which is precisely
why it is a check and not a comment. The finish itself is still to be chosen and
does not block the rebuild.

## 5. What is now true, and what is owed

- The registry says what every price group is, per code.
- The armed probe carries the decided group and is guarded against reverting.
- **The model still holds six `DZAK22`.** Nothing has been rebuilt: probe 71
  calls `Generator.build`, which commits an operation of its own, so the bridge's
  rollback does not apply to any part of it. It runs when Andriy says so.
- **The finish NAME within Prime is unchosen**, and must come from the nine.
- The lacquer finish lists on printed p.217 remain unread — harmless now that the
  island is leaving lacquer, and recorded rather than assumed away.

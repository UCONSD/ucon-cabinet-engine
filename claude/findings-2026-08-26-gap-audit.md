# 2026-08-26 — every gap in the model, measured

The fridge bay was closed one joint at a time. This asks the same question of the whole
model, so the next conversation about gaps starts from a measurement instead of an
impression. `build/50_gap_audit_bodies.rb`, read-only.

## The method, and the mistake that produced it

Two bodies are NEIGHBOURS when their boxes overlap on two axes and are separated on the
third; the separation is the gap. Anything from a hairline to 60 mm is reported — beyond
that it is a design decision, not dirt.

**The first run of this audit was wrong, and it was wrong in the way the handoff warns about
in as many words:** *"the bounds of an INSTANCE are not the bounds of the body — a definition
carries the opening symbols too. Measure the CARCASS box."* Run 17 measured instance bounds
and reported two gaps of **57,00** and **55,71 mm** at the corner. Both were **symbols**: the
opening symbols are drawn well in front of the fronts and inflate the instance box, so units
that touch look separated and units that do not look adjacent.

Run 19 walks each definition, keeps only the groups whose name does not begin with `SYM_`,
transforms their corners by the instance's own transformation, and unions them. **Both large
gaps disappeared.** Nothing was wrong with the arithmetic; the wrong body was being measured
— the same sentence this project has now written three times in two days.

## The result — 49 bodies, 53 joints at 0,0, three gaps

| gap | axis | between |
|---|---|---|
| **0,800** | x | `48 WOLF` (no contract, hand-placed) and `B80753` base unit |
| **0,300** | y | `C90635` tall unit and `C00151` filler, east wall |
| **0,300** | y | `SD0631` top element and `BE0151` filler, east wall — directly above the one above |

### The two 0,300s are one error, repeated

The east run steps 600 from y 1915,312, so it ends at **4915,312**. Both fillers begin at
**4915,612**. Their origins are 5024,612 where a seat on the run would be 5024,312 — the same
0,300 in both, on two objects that sit one above the other. **That is one seating, repeated,
not two coincidences**, and nothing recorded says the 0,3 is deliberate.

At any sheet scale 0,3 mm is invisible. **The value is not the appearance, it is the
diagnosis:** a filler seated 0,3 off the run means something computed a position rather than
taking it from the neighbour.

### The 0,800 is the range, and it is a different animal

`48 WOLF` is a component with **no contract attributes and no instance name** — the client's
machine, placed by hand. It occupies x 1903,0…3122,2, so **1219,2 wide: 48 inches exactly.**
The reservation drawn for it is x 1904…3123, **1219 — the printed number, rounded.**

So the machine is 0,2 wider than the span reserved for it and sits 1 mm to one side. **Both
numbers are right and they are not the same number**: 48 in is 1219,2 and the guide prints
1219. The reservation took the printed value, as it should, and the machine is the real one.

This is the same shape as the 1 mm between the doors and the grille that was closed this
afternoon, and it wants the same answer: the bodies should meet each other, and the printed
number stays in the attributes where the order reads it.

## Where the 0,300 came from — it was a decision, and it was on the wrong side

Not an engine bug. `tools/probe_inbox/done/14_14_tall_end_filler.rb` says it in its own
header, on 2026-08-25:

> "4915,3 .. 5024,6 is 109,3, and a filler is ordered in WHOLE millimetres, so it is 109 and
> **0,3 is left to scribe against the wall.** That is stated rather than rounded away."

So the 0,3 is a declared scribe allowance. **But the probe seated the filler with its far edge
ON the wall**, so the allowance ended up between the filler and the CABINET — a hairline on a
joint an elevation shows — instead of at the wall, which is the edge that gets cut on site.

And the rounding went the other way from Andriy's own practice, which owed 2 records:
**fillers are ordered WIDER and scribed.** 109,3 by that rule is 110 with 0,7 to cut, not 109
with 0,3 left over. The engine refuses the fraction and names both roundings; the choice of
109 was made in the probe.

## Decided and applied, 2026-08-26

**The fillers keep their 109 and the allowance moves to the wall** (Andriy). Both were shifted
**−0,300** — the shift computed per filler from whatever body ends beneath it in the same z
band, not hard-coded — and both came out at exactly −0,300, which confirms the diagnosis: one
seating, repeated, not two coincidences. They now butt the cabinets at 4915,312 and the
allowance sits at the wall. **owed 2 stays open**: this moves the allowance, it does not settle
whether a filler rounds up or down.

**The range gap becomes the gap.** Measured from the two `B80753` that make it:
**1903,000 … 3123,000 = 1220,000**. The reservation had been drawn at the appliance's printed
1219 and so sat 1 mm to the side of the span it describes and 1 mm short of it. It is now
1220,000, and the 0,800 the machine leaves is **breathing space by decision** rather than a
leftover. See §12's narrowing in `claude/appliance-rules-decided.md`.

**Result, from an independent audit run afterwards: 55 joints at 0,0 and ONE gap in the whole
model** — the 0,800 that was kept on purpose.

## Still not decided

Whether `48 WOLF` should carry contract attributes at all. It is the client's machine, so it
is never ordered — but the appliance placeholder the engine draws for exactly this case
carries `object_class: appliance` and says what it stands for, and this one is a mute
component with no name and no attributes. It is the only body in the model that says nothing
about itself.

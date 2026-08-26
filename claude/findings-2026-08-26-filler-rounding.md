# 2026-08-26 — owed 2 closed: a filler rounds UP, and the object says by how much

**Andriy's practice becomes the engine's rule.** A filler is ordered in whole millimetres
and the rounding is **always UP**, because up is the only direction a fitter can correct:
ordered wider, the excess is scribed off against the wall; ordered narrower, there is a gap
and nothing to close it with.

## The three-day shape of it, kept because it is why the rule can be trusted

1. **Silence.** `Integer("49.2")` raises and `Integer(49.2)` **truncates**. The original guard
   caught a string and let a float through, so three fillers ordered at 49,2, 69,2 and 109,3
   on the Avenida Primavera run were built at **49, 69 and 109** — and the only evidence was a
   fraction of a millimetre against a wall.
2. **A refusal**, 2026-08-25 evening: a fractional width was refused and both roundings were
   named — *"49 leaves 0,20 to scribe, 50 is 0,80 too wide"*. That made the question visible
   and asked a human every time.
3. **A rule**, 2026-08-26. The refusal answered the question once per filler; the rule answers
   it once. **What it keeps from the refusal is the half that mattered: the allowance is said
   on the object.**

## Two widths, and they differ on purpose

| | |
|---|---|
| `width_mm` | what is **ORDERED** — a whole number, rounded up |
| `width_clear_mm` | what is **DRAWN** — the space the body actually fills |
| `scribe_mm` | the difference, cut off on site |

`Generator.drawn_width_mm` is the **one asker** of the second, and it has three readers —
`build`, `front_slabs` and `plinth_width_mm` — for the same reason `plinth_h_mm` has one:
three copies of a rule is three chances to update two.

**This is the third time in two days the same split has been the answer**: the plinth (drawn
continuous, ordered with a cutout), the Sub-Zero panels (drawn with no gaps, ordered at the
published size), and now the filler. **The attributes are the order and the geometry is the
sheet**, and every object that carries a disagreement says so in its own notes.

## The range still bites, and it bites on the ORDERED width

A clear space of 0,5 rounds up to 1, and no filler is made at 1. The refusal names the
printed range and sends the reader to **two fillers or a different article** — not to a width
nobody prints. Rounding up out of the top of the range (150) fails the same way.

## And a sentence outlived its number by one commit

`Generator.notes_for` wrote on **every object**: *"Front drawn flush; 1.5 mm reveal recorded,
not drawn."* `FRONT_REVEAL_MM` was deleted earlier the same day because nothing read it — and
this sentence went on telling every object about a 1,5 that no longer existed anywhere. It now
says the faces meet and no reveal is drawn or stored, and a check named *"the reveal sentence
died with the reveal"* holds it.

> **A deletion is not finished while something still says the number aloud.**

## Applied to the model the same afternoon — and the measurement was worth it

The fillers already in the model had been placed by probes at whole numbers, so nothing
changed retroactively. Applying the rule meant measuring each one's clear space again rather
than trusting the number a probe carried a day ago — **the room was walked for its vertical
faces, our own objects skipped, and the neighbour read on the other side.**

| filler | z | was | clear space, MEASURED | now |
|---|---|---|---|---|
| `C00151` | 0…2440 | 49 / 49 | **49,200** — wall face y 646,112 | order **50**, body 49,200 |
| `BE0151` | 2440…3040 | 49 / 49 | **49,200** | order **50**, body 49,200 |
| `C00151` | 0…2440 | 109 / 109 | **109,316** — see below | order **110**, body 109,316 |
| `BE0151` | 2440…3040 | 109 / 109 | **109,316** | order **110**, body 109,316 |
| `BE0151` | 2440…3040 | 104 / 104 | **104,325** — wall face x 3997,325 | order **105**, body 104,325 |
| `B70150` | 0…880 | 125 / 125 | **124,325** — same wall | order **125**, body 124,325 |

### `B70150` is the one that proves the rule

Its order was **already right**: `ceil(124,325)` is 125 and 125 is what somebody had written.
What was wrong was the BODY — drawn at 125, it **crossed the plane of the wall by 0,675**. The
old habit produced a correct order and a drawing that went through a wall; the rule produces
both, because the two numbers are now separate things.

### The 5024,628 end is NOT a wall, and the object says so

The probe that placed those two fillers in 2026-08-25 carried `WALL_Y1 = 5024.6` by hand.
There is no wall face there. **The east wall STOPS at y 5024,628** and a **~34° wall** begins —
one of the two the handoff warns about — and at this filler's depth that angled wall stands at
about **y 5980**, nearly a metre away.

So 109,316 is **the line where the run ends**, not a clear space to a surface. Andriy chose to
treat it as the clear line anyway: body to 109,316, order 110, and the 0,68 comes off against
the angled wall. **What matters is that the object now says which of the two it is** — the
notes name the end of the run and the angled wall by name, so nobody looks for a surface that
is not there.

### Two other fillers were left alone, on purpose

`BE0151` at x 0…103 meets the wall at x 0 with a clear space of **103,000 exactly** — nothing
to round. `B70150` at y 3700…3802 has **nothing within 80 mm** of its far end: it stops in open
room, and there is nothing to close.

### Afterwards

The gap audit was re-run: **55 joints at 0,0 and one gap** — the 0,800 of breathing space kept
for the range. Unchanged, which is the right answer: the six fillers closed gaps to WALLS, and
a body-to-body audit cannot see those. It is worth saying plainly, because "the number did not
move" is otherwise indistinguishable from "nothing happened".

## The old note, kept — what this did not do until it did

The fillers already in the Avenida Primavera model were placed by probes at whole numbers, so
**nothing changed retroactively**. Measured after the rule landed, every filler in the model
is drawn at exactly its ordered width — which is the old rule showing.

The east end pair is the clear case: the clear space is **109,3**, they are ordered **109** and
drawn **109**, and the 0,29 that is left now sits at the wall (moved there earlier today).
Under the new rule they would be ordered **110** and drawn **109,3**, reaching the wall with
0,7 to scribe.

**Applying the rule to the model is a separate step and it needs a measurement first** — each
filler's true clear space, which means reading the wall faces rather than trusting the number
a probe used a day ago.

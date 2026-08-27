# `C92640` — the door the page does not print (2026-08-27)

**Volume searched: `CESAR - 2 Kitchen System.pdf`, printed p.162 / PDF 164**,
read at 600 dpi. Andriy, building the east column: *"внизу выдвижной ящик…
потом два проёма с полкой между ними… потом сверху идёт дверь. Вот эту дверь ты
не нарисовал."*

He was right, and the engine was not wrong: **the door was never in the data.**

## 1. What the page actually prints

For *"Tall unit for oven and microwave oven"* at H.234, printed p.162 gives:

- the family height, **2340**;
- **one** front height in the elevation — **39** handle, **36** gola — the jumbo
  drawer;
- the contents: *"1 rh or lh **custom-sized door**, 1 jumbo drawer, 1 shelf,
  1 adjustable divider with stainless steel protection, 2 dividers"*.

**"Custom-sized" is the catalog saying, in its own vocabulary, that this door's
height is not an article dimension.** It prints the sum and refuses to divide it,
which is exactly how the registry recorded it: one `remainder` of **1950**,
holding a custom-sized front and two appliance openings, undivided.

That recording was right while nothing had asked. The kitchen asked.

## 2. The arithmetic, and where each number comes from

    2340  family height              PRINTED
    - 390  jumbo drawer front        PRINTED (39 handle / 36 gola + 30 recess)
    -  600  opening                  ESTABLISHED
    -  600  opening                  ESTABLISHED
    = 750  custom-sized door         DERIVED

**The 600 is not a guess.** It was recovered five times over from what front
stacks leave (`claude/findings-2026-08-25-tall-h210-appliance-columns.md` §1) —
and it is corroborated **on this very page** by the position directly above:
`C92657` prints **96 / 39 / 39**, and 960 + 390 + 390 = 1740, leaving exactly
**600** for its single oven opening. Same page, same family, printed numbers.

**Andriy reached 750 independently, by the same subtraction**, and added the
observation that 750 is a size this system already uses — so the factory is
fitting a standard front into a space it declines to name.

## 3. The reading that had to be excluded

The only competing division is a **450** microwave opening, which would leave a
**900** door. The 600-dpi render settles it: the drawing shows door, opening,
opening, drawer, and **the two openings measure the same** to within a few per
cent of each other. A 450 beside a 600 would be a third narrower and unmistakable
at that resolution. *Learned rule 10: look at the render.*

## 4. What was NOT decided, and deliberately

**Which machine goes in which opening.** The title says *oven and microwave
oven*; the drawing labels neither, and both are 600. So both openings carry the
geometry class `oven_h60` — a 600 opening — and which one takes the oven is a
per-order fact. Naming the upper one "microwave" would have been an invention
with a fifty per cent chance of being backwards, and nothing geometric turns on
it.

## 5. Scope

*Learned rule 4.* This is **one position on one page**. The twins `C63640` at
H.222 and `C42640` at H.210 carry the same undivided shape and were **not**
split — nothing has asked them. Their remainders are 1830 and 1710, and the same
subtraction would give them 630 and 510 doors. **That arithmetic has not been
checked against their renders and must not be assumed from this one.**

## 6. The check that went red first

`A REMAINDER IS EXECUTION-INDEPENDENT, or it is not a real number` pins the COUNT
of remainder codes *"so that a remainder appearing or vanishing is never
silent."* Dividing this one took the count from 7 to 6 and the check failed
before anything else noticed. That is the job, and the rung was kept rather than
deleted: **C92640's span is now the SUM of its parts**, 750 + 600 + 600 = 1950,
and it must still stand 120 above `C42640`'s 1830 — so a division that changed
the total would break the ladder instead of looking plausible. Four more
assertions were added beside it: both executions sum to 2340, the door is the
same 750 in each, and the door says on itself that it was derived.

## 7. Owed

**The model is not recomputed when the engine changes.** `C92640` stands in
545 Avenida Primavera drawn by a core that had no door in this stack. It has to
be rebuilt by hand — Reload core, then rebuild that unit — and until it is, the
east column on any sheet is missing a front that the registry now has.

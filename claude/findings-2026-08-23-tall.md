# The plain tall column — five families, one shape, no agreement

> **MOVED INTO THE REPOSITORY 2026-08-24.** Copied verbatim from the claude.ai
> Project. See `claude/README.md`. **No correction was needed.**

Continues `claude/findings-2026-08-23.md`. Same day, same shape as everything
else in it: **a rule derived from pages that happened to agree, and a page that
did not.**

By the end of the day all five plain tall families were held — H.138, H.198,
H.210, H.222, H.234 — one clean first page each, 72 codes.

---

## The wall-hung fact is per POSITION, and it is printed only as art

Printed p.19's **"Hung version"** pictogram — found on the base pages earlier
the same day — turns out to be the whole statement, on its own, with no prose
anywhere near it.

On **printed p.90** (H.138) the glyph sits beside both depth bands of *Tall unit
with door* and *Tall unit with doors*, and beside **neither** band of the
kit-ready door, whose margin also drops the *"Surch. for wall-hung version on
page 548"* line the two above it carry. There is no sentence to quote. **The
statement is a missing symbol.** Printed p.37 refused two base units *in words*;
here the same refusal is made only in print-art.

### And every family answers differently

| | door | two doors | kit-ready | door suffix |
|---|---|---|---|---|
| **H.138** (p.90) | hung | **hung** | no | **01** |
| **H.198** (p.97) | hung | no | no | 31 |
| **H.210** (p.111) | hung | no | no | 31 |
| **H.222** (p.132) | **no** | no | no | **02** |
| **H.234** (p.151) | **no** | no | no | **02** |

**H.222 and H.234 refuse every position** — the first whole families the
registry holds that cannot be hung at all, which for a 2220 and a 2340 column is
no surprise but is nowhere stated in words. **H.138 alone hangs its two-door
type.** And even the plain door — the position all five families otherwise print
identically — disagrees with itself.

A check now asserts all of that: at least one family hangs something and at
least one hangs nothing, and the plain door itself carries two different answers.
While that holds, nobody can re-derive the glyph from the type.

---

## Six codes we already held were wrong

`tall_h210.json` was extracted on **2026-08-22** with no wall-hung statement, so
`Generator.wall_hung_available?` offered all fourteen of its codes: the guard
derives the answer from `unit_class` and nothing in the row objected.
`CQ0930`, `CQ1230`, `CR0930`, `CR1230`, `CR0535`, `CR0635` should have refused.

**And the page had already been read correctly.** The `catalog_map` note written
that same day says, of *Tall unit with door*: *"The only type on the page whose
margin offers a wall-hung version."* The observation was made, written down, and
**never turned into data**.

> **A reading that stays in a note is a reading the engine does not have.**
> The note was right for a day and a half while the registry was wrong.

Ten codes now refuse the hung version, each naming the page it read — because a
fact that exists only as *absent* print-art is lost the next time someone opens
the page.

---

## The check caught a note written an hour earlier

The five-family check ends by asserting that the plain door's suffix is not
constant. It was written expecting **two** readings and found **three** — and
that third one was a mistake of mine, sitting in `tall_h138.json`, already
committed.

The note said *"Four widths at each depth, the same set H.210 prices, and the
same suffix 31."* `C10301` is prefix `C1`, width index `03`, suffix **01**. The
two-door note was wrong the same way: *"Suffix 30, as at H.210"* beside
`C10600`, which is **00**.

The codes themselves were right. **The suffix had been read off the neighbouring
family instead of off the row** — the exact failure this chapter has punished
five times, committed while looking at the correct digits. Both notes now carry
dated corrections (rule 9), and the check that found them stays.

H.138 sits a uniform thirty below H.198 and H.210 — `01/00/05` against
`31/30/35` — which looks like a rule for exactly as long as it takes to reach
H.222, where the door is `02` and the other two stay `30` and `35`.

---

## What else the five pages gave

- **One shape, five times.** Door / two doors / kit-ready door, in that order,
  d.35 and d.62, kit-ready always d.62-only. Everything structural agrees.
- **The interiors drift.** H.138 prints 3 shelves and no divider; the other four
  print 4 shelves and a divider. The kit-ready door prints no shelves at H.138,
  1 at H.198, 2 at H.210, H.222 and H.234.
- **The two-door width set is per family.** W.60 exists only at H.138; the other
  four start at W.90.
- **printed p.132 and printed p.151 are the same page twelve centimetres apart**
  — position for position, suffix for suffix.
- **Five positions in five chapters now point at printed p.569.** The kit
  catalog is the single most-referenced unread page in the registry.

---

## Group 2 is smaller than the plan said

Every plain tall section has the same three-part shape: **a clean first page**,
then **pages of interior mechanisms the catalog names and does not code** (Arena
Style Plus, ETOUCH with a power adapter priced in the margin with no article),
then **corners carrying the D/S execution letter**. Then oven, microwave and
fridge housings, which belong to the appliance module.

So Group 2's ~232 estimated codes are **72 codes of reading and the rest of
two standing blockers** — `registry/cesar/options/` and Elda Q7b.

And the plan's stated test for this group — *"no tall family has yet declared
its own `plinth_h_mm`"* — **was answered on 2026-08-22**, when `tall_h210.json`
declared 100 with its reason. Third time in two days the plan has described work
already done or already blocked. **The plan estimates volume from an index; the
manifest knows the content. Read the manifest first.**

# A copied note is a copied claim — the filler front_layout sentence, 2026-08-24

**Found while reading printed p.434 for the Avenida Primavera tall run**, after
Andriy settled on H.210 and asked for the tall filler. Nothing was broken in
the model and no check was failing: the defect was a sentence.

## What was wrong

`front_layout.note` was written once, for `fillers_h78.json`, and pasted
verbatim into every filler file that followed. It ends:

> …It also means the front shortens to **750** with the rest of the run when
> the door version is gola — a filler's front line must meet its neighbours' or
> the drawing breaks.

True for family H.78, whose `door_versions` are 780 full and 750 gola. Carried
into three other files it says nothing at all:

| file | family | height | `door_versions` |
|---|---|---|---|
| `fillers_wall_h36.json` | Wall H.36 | 360 | **null** |
| `fillers_wall_h60.json` | Wall H.60 | 600 | **null** |
| `fillers_tall_h210.json` | Tall H.210 | 2100 | **null** |

A family that declares no `door_versions` has no 78/75 choice, so nothing
about those fronts shortens with anything.

**The registry already knew.** `base_h78.json` says so in its own
`door_versions` note — *"FAMILY-SCOPED … a family that does not declare this
key has no such choice. Wall H.36 is 360 tall and 78/75 means nothing there."*
The registry contradicted itself in prose for a day and a half and the suite
was green throughout, because no check read prose.

## Why it mattered now and not later

Andriy chose **H.210** for the tall wall. The plain H.210 section really does
have no door-version axis — one 2100 front. But the section the design needs,
**`Tall units H. 210 | for base unit H. 78`** (printed p.116-125, letters
`C5` d.35 / `C6` d.62), *does* print 78 and 75 — as `132 + 78` and
`132 + 75` — for its **lower door only**. So the sentence was about to become
not merely meaningless but plausible, in a file where a full-height 2100 filler
stands beside a split front and **the catalog prints nothing about what it
does**. That is an open question, not a number to derive.

## What changed

- The three wrong notes are corrected **in place**, each naming what is
  actually true for its family, what the copied sentence claimed, that it came
  from `fillers_h78.json`, and the date. The mistake is quoted, not erased.
- `fillers_h78.json` keeps the sentence — it is true there — and now states
  that the number is **NOT PORTABLE** and why, so the next copy stops at the
  source.
- Three checks in `tools/test_contract.rb` (402 → 405):
  1. the reader proves itself on a fixture carrying the exact defect;
  2. no section file may quote a front height its own family does not declare;
  3. the three corrected files must still carry the date and the reason.

No code changed, no geometry changed, no article changed. `CORE_VERSION`
deliberately not bumped: nothing the engine *does* is different.

## The lesson, in the same shape as the others

> **A note is a claim, and a claim nobody checks is a claim that rots.** The
> guard against copied prose is not review, it is a check that reads the prose
> against the data in the same file. `front_layout.note` was the fourth thing
> in this registry to be right once and wrong by duplication — after the
> wall-hung glyph, the rack sentence and the plinth range.

Related: `claude/fillers-recon-2026-08-23.md` (the chapter), `registry/cesar/`
the four filler files, `docs/Clearance_Rules_H78_v0.1.md` §1 (why the strip is
5 cm).

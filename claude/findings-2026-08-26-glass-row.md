# 2026-08-26 — the west wall gets glass, and a frame nobody prints

**Andriy:** the three `PF0631` on the west wall should have glass doors — and what does the
Cesar source have at 600 × 960 × 350?

## The three, found and measured

All on the west wall, hung z 1480…2440, d 350, joints 0,0 between them:
x 103…703, 703…1303, 1303…1903. Plain-door units — `CARCASS`, `FRONT`, and the door symbol.
**No glass anywhere in them**, and none was ever intended: `PF0631` is *"Wall unit with door –
1 rh or lh door – 2 shelves"*, family Wall H.96, printed p.245.

## What the source has — a whole chapter nobody had opened

**The registry held no glass position at all.** The catalog holds a chapter:
**"Glass display cabinet elements", printed p.305–315.** Glass tall units H.138/198/210/222,
tall-unit top elements with glass doors H.36/H.48, and glass wall units at H.60, H.72, H.84,
**H.96**, H.120.

**Printed p.314, the H.96 block — extracted on demand:**

| position | W. | code |
|---|---|---|
| Wall unit with glass door – 1 rh or lh glass door – 2 glass shelves | 45 | `TF0541` |
| the same | **60** | **`TF0641`** ← the size this kitchen has |
| Wall unit with glass doors – 2 glass doors – 2 glass shelves | 90 | `TF0940` |

**It is a different ARTICLE, not a variant.** `PF` is the wall chapter at printed p.245; `TF`
is the glass chapter at p.314. Swapping to glass changes the code; it is not a modification of
the plain unit.

### The letter rule held a third time, read independently

`TD` = H.60, `TE` = H.72, **`TF` = H.96**, `TG` = H.84, `TJ` = H.120. **The F/G pair runs
BACKWARDS against height** — exactly as `PF`/`PG` do in the plain wall chapter, and exactly as
they do again in the filler table on printed p.434. Three chapters, three independent readings,
one rule: **a letter is a lookup and never a sequence.**

### "Cannot be reduced in width, height or depth"

Printed on every glass position.

- **WIDTH refused itself.** `WIDTH_MOD_FORBIDDEN`'s framed-glass rule, written from p.548 on
  2026-08-25, matched the new rows by their own description with **no new code**. The check
  that had been holding an empty bucket — *"NO framed-glass refusal fires today, and it is
  recorded as zero rather than left out: an empty bucket that later fills is a change somebody
  should see"* — **filled, 0 → 3, on the day the section arrived.** That is a check doing the
  job it was written for a day before it was needed.
- **HEIGHT was wired**, citing **p.314** rather than borrowing p.548, which excludes framed
  glass from WIDTH only. Borrowing a prohibition the page did not write is the one thing this
  registry may not do; here the page wrote it, next to the article.
- **DEPTH is prohibited by the same sentence and is NOT wired**, because the engine has no
  depth-modification path to refuse. Said out loud so the absence is a known gap.

## The frame is 25 mm and it is OURS

A framed glass door is a frame with a pane in it, and **the catalog prints no frame section**.
Checked, and then checked again by Andriy himself: the glass chapter (p.305–315), *Unit
structure* (p.260, p.282–283 — whose "aluminium frame" is the structural frame of an open
shelving unit, a different thing), the technical pages (p.10–11), the filler table (p.434).
`sources/factory/` holds one PDF and no brochures.

**Andriy, 2026-08-26: "we are not sending this to production — put 25 and draw it CAD-style."**

So the frame is drawn at 25 and the object says whose number that is. It wears
**`(frame: DECLARED)`** — deliberately **not** the appliance aperture's `(cutout: INDICATIVE)`:

> An aperture's rails come from a machine's published specification and are INDICATIVE of it.
> A glass door's frame is a number UCON declared because nothing prints one. **Two different
> claims must not wear one label**, and in an outliner the difference has to be visible at a
> glance.

The pane is opaque and flat at full front thickness — the convention this engine chose for
glass on 2026-08-22, because a transparent material would show the room through a cabinet in
every rendered view.

### And it caught something on the way past

`cutout_rails` waits for a slab **as wide as the whole unit** — right for an aperture, which
belongs to one machine behind one front. **A two-door glass unit would have had neither leaf
glazed.** A glass frame answers per leaf instead, and `TF0940` has a check of its own.

## The filler, and the page answering the question it was ordered for

The row starts at x 103,000 and the room's own face is at x 0,000 — a clear space of
**103,000 exactly**, no fraction, no scribe. `PF0151`, the **H.96 wall filler**, printed p.434,
extracted for it; the wall filler table runs H.36 `PB0151`, H.48 `PC0151`, H.60 `PD0151`,
H.72 `PE0151`, H.84 `PG0151`, **H.96 `PF0151`**, H.120 `PJ0151`, and only the H.96 row was taken.

**Andriy: order the filler in the colour of the glass door's frame.** Printed p.434 answers it
beside that very table:

> *"If the door is framed, the glass/ceramic will be applied to the panel and not to the
> aluminium support."*

So a filler in a framed-door finish is a front in that finish **on a panel**. The finish itself
is not modelled — there is no appearance layer — so the requirement rides on the object as a
note and reaches the order that way.

## Two rules picked up in passing, printed p.10–11

- *"Out of square modifications are not available for glass and ceramic doors."*
- *"Doors cannot be reduced in size."*

Neither was held before. Recorded here rather than wired, because neither has a caller yet.

## The state afterwards

Band, left to right: wall → `PF0151` 103 → three `TF0641` → `SD0631`, **every joint 0,0**.
Registry 756 codes. Suites 467 / 68 / 30. Core 0.85.0.

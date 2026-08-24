# Findings — the printed p.19 pictogram sweep, closed

**Date:** 2026-08-24 · **Session:** Cowork, device bridge · **Core:** 0.70.0

The oldest debt in the registry is paid. Ten pages re-read at 170 dpi for two
glyphs; **no code changed availability, six positions gained the hob mark, and
"absent" now means absent.**

Files touched: `registry/cesar/base_h78.json`, `sink_base_h78.json`,
`base_h39.json`, `base_h48.json`, `base_h58_5.json`, `sink_base_h58_5.json`,
`tall_h138.json`, `tall_h198.json`, `tall_h210.json`, `appliance_h78.json`,
`usa_tall_h210.json`, `_manifest.json`, `tools/test_contract.rb`.
**396 checks green. No new codes.**

---

## 1. What was owed, and why it was not bookkeeping

printed p.19 carries a legend for two pictograms that sit beside every depth
band in the base code tables: a cabinet-in-a-bracket for **Hung version** and a
flame for **Provisions for hob**. They are printed art. `pdftotext` cannot see
them, so five days of extraction went straight past them, and they were only
found on 2026-08-23 because printed p.37 prints a position that refuses the
hung version *in words*.

Everything transcribed before that date carried the marks **unread** — and the
registry had no way to say so. A type with no `wall_hung` key meant *either*
"the catalog offers it" *or* "nobody looked", and no reader, and no check,
could tell which.

**That ambiguity had already cost something.** On 2026-08-23 six H.210 codes
were found to be offered a wall-hung version the catalog does not sell; they
had been extracted the day before with no wall-hung statement, and
`Generator.wall_hung_available?` derived *yes* from the unit class. The
correction is in `tall_h210.json` under rule 9. The sweep is that correction's
general form.

---

## 2. What the ten pages say

| printed | held positions | hung glyph | flame |
|---|---|---|---|
| p.36 | 4 | all four | d.62 / d.67 of the two door types |
| p.37 | 4 | two yes, **two refuse in words** | d.62 / d.67 of the two that hang |
| p.38 | 4 | all four | d.62 / d.67 of all four |
| p.39 | 3 | all three | d.62 / d.67 of drawers-and-jumbo only |
| p.40 | 2 | both | d.62 / d.67 of both |
| p.42 | 1 (the corner) | yes | d.62 / d.67 |
| p.44 | 4 | all four | **none, at either depth** |
| p.47 | 1 | *no pictogram column at all* | — |
| p.48 | 3 | *no pictogram column at all* | — |
| p.111 | 3 | the plain door only | none — the tall chapter has no flame |
| p.418 | 2 | *no pictogram column, no margin line* | — |
| p.434 | 6 | *no pictogram column anywhere in the chapter* | — |

**Nothing moved.** Every position that was being offered the hung version does
carry the glyph and the margin line. The sweep's whole value is that sentence
being *checked* rather than *assumed*.

**Six positions gained the flame** on d.62 and d.67 — the two door types of
p.36, the drawers-and-jumbo of p.39, both drawer types of p.40 and the corner
of p.42 — **92 codes**. Eight base pages have now been read for it and they
agree without exception: **the flame is on the deep bands and never on d.35 or
d.47.** Still read by nothing in the engine; it waits with restrictions.

---

## 3. The change that matters is a schema habit, not a value

Every non-wall **cabinet** type now states `wall_hung` explicitly — **true as
well as false** — with a note saying where the reading came from. 54 types,
378 codes. A positive reading recorded as a positive reading is the only thing
that makes a later absence a bug rather than a shrug.

A check enforces it: *AFTER THE SWEEP, AN ABSENT HUNG READING IS A BUG*. A new
section that forgets fails there, which is the point. `wall_hung: true` behaves
exactly as absence did — `wall_hung_available?` special-cases only `false` — so
nothing in the engine changed.

**The wall chapter is exempt, by observation and not by assumption.** Its code
tables carry no pictogram column at all; that was seen on every wall render
already read and re-checked deliberately on printed p.238 for this note. A wall
unit hangs by nature, so the hung glyph would say nothing — but the flame would
have, and it is not there. The exemption is written into `_manifest.json` →
`page_symbols.sweep_done.wall_chapter`, and the check reads it.

---

## 4. Three things the pages said that were not being looked for

**An oven housing at H.78 can be hung; at H.58.5 it cannot.** printed p.42's
*Base unit for built-in oven H. 60* carries both glyphs and the margin line.
The compact-oven housing extracted yesterday from printed p.34 refuses in the
catalog's own words. Same appliance idea, two families, opposite answers. And
p.42's version prints **real front heights** — 9 + 9 around the niche in the
handle execution, 7 + 8 in the gola one, summing to 780 and 750 against a 600
niche — where p.34 prints only a minimum. When the appliance module arrives,
the H.78 position is readable and the H.58.5 one still is not.

**A page contradicting itself.** The *Corner base unit with Magicorner* at the
foot of printed p.42 carries the **flame and no hung glyph**, while its margin
still prints *Surch. for wall-hung version on page 548*. Everywhere else the
two signals agree: the four articles that refuse in words drop the margin line
too, and the tall positions that refuse by a missing glyph drop it as well.
This one does not. It is not held, so nothing depends on it — recorded in
`catalog_map` against the type, and it belongs in the corner questions when
they go to Elda.

**Two sink sections agree about the flame.** Neither printed p.44 nor printed
p.35 marks a sink base for hob provisions, at any depth. Two sections saying
the same thing is worth writing down; it is still not a rule, and the next sink
page gets read like every other.

---

## 5. What the checks learned

The old check was titled *the hob pictogram is recorded where it was read, and
NOWHERE else* and pinned the two pages that had been looked at. After the sweep
that question is the wrong one — every page has been looked at — so the check
was rewritten rather than extended: it now asserts the mark is only ever in the
base chapter, never on a band shallower than d.62, and that **`sweep_owed` is
gone from the manifest** rather than merely contradicted by a newer note.

Two new checks:

- *AFTER THE SWEEP, AN ABSENT HUNG READING IS A BUG* — every non-wall cabinet
  type states the reading, and every stated reading carries a note.
- *and the sweep moved nothing: 46 codes refuse, the same 46 as before* — 4
  base and 42 tall. A later edit that quietly flips a true to a false moves the
  count and fails with the reason in its title.

**And writing that check corrected a number written this morning.**
`repo-state.md` said *twenty-two codes refuse the hung version* — it had counted
the tall families by position rather than by code (H.198 and H.210 refuse two
positions each, six codes each, not one code each). The real figure is **46**,
and it is now counted by the check rather than by hand. A number that a check
computes is a number that cannot drift; that is the third time this week the
fix has been to move a count out of prose.

---

## 6. What is left

**Nothing in the sweep.** `debt-2026-08-24.md` §3 counted 148 codes owed; the
measured figure is 146 held codes across ten pages, and it is now zero. The
other four buckets of §3 — 21 not-buildable, 21 gated on Q7b, 76 on stopped
pages, and the door-version axis — are untouched by this and unchanged.

**Next is base H.84, printed p.49-56**, which needs discovery: `BK` / `BL` /
`BM` were swept out of the filler table and which letter is which depth has not
been read. Three families have now printed a prefix trio that is not in depth
order, so the alphabet says nothing. Its plinth is 60, not 100.

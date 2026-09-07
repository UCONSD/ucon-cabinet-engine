# The ten codes are in the model — and a shared definition cannot hold a per-body fact

2026-09-05, on the laptop. **The first writes this project has made into 545
since the reconciliation was drawn up.** The apply list is
`claude/recon-2026-09-02-model-vs-30833.md` §6, items 2 and 4; item 3 (the
sub-line question) and row 8 are untouched and remain owed.

**The counter moved: NO ARTICLE 4 -> 2. A DISEGNO 0 -> 10.** Sheet length is
unchanged at 130 rows.

---

## 0. What was confirmed before a single attribute was written

**ONE SketchUp, and it was proved rather than assumed.** `Process.pid` printed
from inside a probe and `Process.pid` typed into the Ruby Console of the 545
window both answered **623**. On 2026-09-03 the same test answered 1396 and
23013 and that is why it exists.

**The bridge refused first, and the refusal was correct.** At 12:59 the run was
turned away: *0 model(s) answer to '545_Avenida'*, with `active_model` naming
Elda's `2026_C2X01_AG157_T_30833`. 545 was not yet open in that Ruby. Two
minutes later it was, and the same probe ran. **The fix of 2026-09-02 did the
one job it exists for**, on its first real occasion.

**And the engine in memory was proved to be the repository.** `SHELL_ROOT` reads
`~/Library/Application Support/SketchUp 2025/SketchUp/Plugins/ucon_cabinet_engine`
and `File.realpath` resolves it to `~/dev/ucon-cabinet-engine/src/ucon_cabinet_engine`
— **the Plugins entry is a SYMLINK, not a copy.** `85_export.rb`, `20_contract.rb`,
`86_export_run.rb` and `00_version.rb` were MD5'd on both sides and are identical
byte for byte. `repo-state.md` says the engine is not copied into Plugins and
attributes that to a one-line dev loader; the mechanism is a symlink, which is
recorded in the dated section rather than edited into the old cell.

**`Reload core` was needed and its absence was visible.** Before it,
`Export::FLAG_NO_ARTICLE` raised `NameError` — the flag column of `30b8b7b` was
on disk and not in memory, so the session had no progress bar at all. After
`UCON::CabinetEngine.load_core` the constant is there and `COLUMNS` carries
`flag`.

---

## 1. THE FINDING: `Contract.write!` writes to the DEFINITION, and two bodies can share one

This is the part worth carrying forward, and it was nearly missed.

**Eight of our bodies are `SD0631` 600 x 600 x 620 under the same component
name.** Five of them are her rows 34-42 and MATCH; three are her rows 11, 13 and
16 and had to become `PD0699`. `Contract.write!` writes the dictionary onto the
`ComponentDefinition` (§2), not onto the instance. **If those eight had shared
one definition, a write meant for three would have landed on eight and the model
would have claimed `PD0699` on five bodies that were already right.**

So the pre-apply probe printed, for every target, its definition, that
definition's `entityID`, and **every instance of it in the model**, marking each
one target or not. The map came back safe: **ten targets on nine definitions**,
eight with a single instance, and one — `CESAR_SD0631_20260825_135925` — with
two, **both of them targets** (x 103 and x 703, both `PD0699`). The apply probe
re-reads that map itself and refuses the whole run if it has changed.

**But the pair still cost something, and the verification found it.** Those two
bodies are her rows **11 and 13**. One dictionary was therefore written twice,
and the second write's `source_ref` — *row 13* — stood where the first had put
*row 11*. Every check passed, because the CODE is `PD0699` either way; the
PROVENANCE named one row where the object covers two. **A successful write is
not a correct write** (learned rule 15), and the check that caught it was the
one reading `source_ref` rather than `code`.

**Corrected the same hour, in an armed run of its own:** that definition's
`source_ref` now reads `Metron estimate 2026/30833 rows 11 and 13`, and the
correction is APPENDED to `notes` with its date rather than replacing the
sentence already there (learned rule 9).

**The limit underneath is not a defect and has no fix that is free:** a shared
definition cannot carry a per-instance fact, because there is one dictionary and
two bodies. `make_unique` would give each its own row and would change the
model's definition count — a structural edit. **NOT DONE, and it is Andriy's to
decide.** Recorded as an open item.

**The candidate rule this suggests, deliberately not added to `claude/rules.md`:**
*a fact that belongs to one BODY may not be written through a definition that
serves two.* It has one instance behind it, which by learned rule 4 is not
enough to generalise; the scope is stated instead — provenance keys
(`source_ref`, and the row-specific half of `notes`) on any component with more
than one instance.

---

## 2. What was written, and what was deliberately not

Ten bodies. On each: `code`, `code_status` = `PRELIMINARY`, `source_ref` naming
the document and the row, and one dated sentence appended to `notes`.
**Dimensions, variants, status, class and mounting were not touched**, and the
registry received nothing — `decisions-2026-09-03-factory-assigned-codes.md`.

| body | was | now | her row | her L/H/P | ours |
|---|---|---|---:|---|---|
| #21 | `SD0930` | `PD0999` | 5 | 770 / 600 / 620 | same |
| #34 | `SD0631` | `PD0799` | 7 | 610 / 600 / 620 | same |
| #35 | `SD0631` | `PD0799` | 9 | 610 / 600 / 620 | same |
| #30 | `SD0631` | `PD0799` | 44 | 610 / 600 / 620 | same |
| #31 | `SD0631` | `PD0799` | 45 | 610 / 600 / 620 | same |
| #19 | `SD0631` | `PD0699` | 11 | 600 / 600 / 620 | same |
| #17 | `SD0631` | `PD0699` | 13 | 600 / 600 / 620 | same |
| #18 | `SD0631` | `PD0699` | 16 | 600 / 600 / 620 | same |
| #25 | *(none)* | `FRN019770747` | 31 | 734 / 1807 / 22 | **730 / 1810 / 22** |
| #24 | *(none)* | `FRN019770597` | 32 | 480 / 1807 / 22 | **483 / 1810 / 22** |

**The geometry comparison the rule makes mandatory was done on all ten.** On the
eight cabinets her printed L/H/P agree with our measured figures exactly, so
*her code, our dimension* costs nothing there. On the two panels she is 3-4 mm
away and **our size stands** — Elda Q6, unsent.

**Verification is a run of its own.** The apply printed what it wrote; a
separate read-only probe then re-read the model and checked fifteen things: the
ten codes, their `code_status`, their `source_ref`, their dimensions, and — the
half that matters most — **that the five east-wall `SD0631` still say `SD0631`.**
All fifteen pass. Definitions 318 before and after; entities 77 before and after.

---

## 3. And the counter cannot reach zero without opening something Andriy closed

`repo-state.md` calls the `NO ARTICLE` block the session's progress bar: when it
is empty, the model and the order agree. **It now holds two bodies, and both of
them are on the do-not-touch list.**

- **`UCON-BESP-001`**, the custom cabinet above the fridge, is her row 43
  `PB1299` — *untouched by instruction*.
- **The grille overlay panel** is her row 69 `DV731Q` — one of the nine panel
  rows held by the one-side-versus-two question, the only open item that moves
  the number the client approves.

**So the end state the goal describes is unreachable today, and that is a
finding rather than a shortfall.** Two of the four were ours to close and are
closed; the other two are closed by a decision, not by a probe.

---

## 4. A THIRD TOOLING TRAP, found at the end of the session

**`model.modified?` READ FROM INSIDE A PROBE CANNOT TELL YOU WHETHER THE MODEL
IS SAVED.** The bridge opens `start_operation` on the resolved model *before* it
loads the probe, and an open operation dirties the flag. So a probe asking
`modified?` about its own target always gets `true`, saved or not — and the
question the flag looks like it answers is exactly the one it cannot.

**Measured, not reasoned about.** Probe 155 resolved Elda's `30833` as its model
and reported 545 as `modified? = false` — reading it from the outside, with no
operation open on it. Probe 153, ten seconds later, resolved 545 and reported
`modified? = true`. Nothing had been written to 545 in between; the difference is
entirely which document the bridge had an operation open on.

**What to use instead, and it is one line either way:** the file's own `mtime`
and `size` on disk, read with `File.mtime(model.path)` and `File.size`. A save
moves both. At the close of this session the file read **26 643 507 bytes**, the
same size `repo-state.md` records for the 2026-09-02 save, with an `mtime` of
13:00:19 — which is when the document was OPENED, not when the ten codes were
written. **On that evidence the apply is in the window and not yet on disk**, and
the session ends by asking for the save rather than by claiming it.

*(This is the same shape as the two traps of 2026-09-03 — `BoundingBox` naming
its axes, and two SketchUps on one inbox: a reading that looks answered and is
about something else. The bridge already prints `active_model` beside the
resolved title for the same reason; `modified?` now needs the same treatment.)*

---

## ADDED 2026-09-07 — the save was not made, and this note asked the right question

The paragraph above ends by asking for the ⌘S rather than claiming it. **The
answer is no.** `Window -> Model Info -> File`, 2026-09-07, model open from
Trimble Connect: **26 643 507 bytes**, unchanged. The apply is not on disk and
the ten codes are not in the model; the re-run is owed and the probes are held
in `tools/probe_inbox/`.

**The note's own instrument is what settled it.** Had this file recorded
`modified?` as the evidence, there would be nothing to check today — the flag
does not survive a closed window and never described the file to begin with. The
size in bytes did, two days and one application restart later. **A test is worth
having when it can still be run by somebody who was not there.**

## ADDED 2026-09-07, EVENING — the addition above is half wrong, and the half matters

**"The apply is not on disk" was right. "The ten codes are not in the model" was
wrong.** SketchUp had not been closed: probe 153 answered from `Process.pid` 623,
the process that ran the apply, and the document still held all ten codes with
the progress bar at `NO ARTICLE 2 / A DISEGNO 10`. The re-run was ordered on the
strength of the wrong half and would have been refused by 157's own guard.

**The state is now saved**, to a new file rather than to the Connect cache that
another application had rewritten:
`~/Documents/545_Avenida_Primavera_RESCUE_2026-09-07.skp`, 26 676 235 bytes,
15:41:39. Probe 160 afterwards: fifteen checks, all pass. The account is in
`claude/repo-state.md` under *As of 2026-09-07, evening*.

**This note's own instrument is still the right one and was still read wrong.**
The size answered truthfully about the file; the file was not the question. Two
readings in three days have now failed the same way — `modified?` about a
document, `size` about a file — and both times the number was correct and the
subject was not.


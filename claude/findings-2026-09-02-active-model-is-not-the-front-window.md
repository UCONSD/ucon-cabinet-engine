# `Sketchup.active_model` is not the window in front, and the bridge trusts it

2026-09-02, laptop, found in the first ten minutes of the reconciliation session
while answering a completely different question.

---

## What happened

The session's first act was the read-only check the handoff asks for: is the 545
model saved. The probe printed `model.title`, `model.path`, `model.modified?` and
the mtime of the file on disk — and answered about **`T42IT100NP_TradeCAD`**, a
Sub-Zero trade CAD downloaded to `~/Downloads` at 10:36 that morning.

Andriy brought 545 to the front. The Window menu showed it with the checkmark
beside it, and **`T42IT100NP_TradeCAD` was not in that menu at all**. The probe
was dropped again and answered `T42IT100NP_TradeCAD` a second time, and a third.

`ObjectSpace.each_object(Sketchup::Model)` ended it. **Six live model objects:**

| | title | modified? | window |
|---|---|---|---|
| 1 | `545_Avenida_Primavera_Kitchen_Preliminary_Model_v0.1_1` | false | open, in front |
| 2 | `Elliana_cut_EXPLODED` | false | closed |
| 3 | `Elliana` (Trimble Connect cache) | false | closed |
| 4 | `Elliana` (`~/Documents`) | false | closed |
| 5 | `T42IT100NP_TradeCAD` | true | **closed** — and this is `active_model` |
| 6 | `PO301W-SketchUp-2025` | false | closed |

SketchUp 25.0.659, one process, one Ruby. **Four of the six are documents whose
windows are shut.** SketchUp keeps them alive and `Sketchup.active_model`
returned one of them for at least twenty minutes while another was in front.

## What it costs, and it is two different things

**FOR A READING PROBE it costs a wrong answer that looks like a right one.** The
first probe was well written — it printed the title, the path and the mtime, all
of them true — and every figure in it was about a file nobody had asked about.
Nothing warned. The probe could not have known.

**FOR A WRITING PROBE it costs the rollback, and that is the serious half.**
`tools/probe_bridge.rb#run_one` does:

    model = Sketchup.active_model
    ...
    model.start_operation("UCON probe #{name}", true)
    ... load path ...
    armed ? model.commit_operation : model.abort_operation

So the operation is opened, and aborted, **on whatever `active_model` names** —
today a closed Sub-Zero file. A probe that writes into 545 through that bridge is
wrapped in nothing. The structural fingerprint that exists to notice an escaped
write compares the **same wrong model**, so it would come back unchanged and the
run would report itself as rolled back.

This is the file's own documented hole reached from the other side. Its header
already says an inner `commit_operation` closes the outer one and that the
rollback is a mechanism rather than a promise. It assumed the outer operation was
at least on the right model.

## The fix, in two parts

**DONE — every probe resolves its own model by name.** Probes 147 and 148 take
the model from `ObjectSpace` and **refuse unless exactly one answers**, printing
what it found when it refuses. `tools/probe_recon_elements.rb` carries the
pattern and says why in its own header.

**OWED, AND IT BLOCKS THE APPLY STEP — `run_one` must be given the model.** The
bridge should resolve once and hand the probe the model it is to work in, so that
the operation, the fingerprint and the script all name the same one. Until that
is done, **nothing may be applied through the bridge**:
`claude/recon-2026-09-02-model-vs-30833.md` §0 and §6 both stop on it.

## DONE 2026-09-03 — the owed half, dated and added

`run_one` no longer asks `Sketchup.active_model`. It resolves the model **once,
before the operation opens**, out of `ObjectSpace` by title, and **refuses unless
exactly one model answers**: a refusal loads nothing, opens no operation, writes
the candidates it found into the outbox and moves the file to
`done/<n>_REFUSED_<name>.rb`. The resolved model is handed to the probe as
`UCON::ProbeBridge.model`, so the script, the operation and the fingerprint are
one object rather than three answers to one question.

**Which document, and why it is not one hard-wired name.** A probe says what it
wants with a line in its own first 4 KB —

    # UCON-MODEL: 30833

— and a probe that says nothing gets `DEFAULT_TARGET`, `545_Avenida`. The two
probes this finding was written about want two DIFFERENT documents: 147 reads
545 and 148 reads Elda's estimate model. A bridge that resolved 545 for both
would have re-created this bug for the second one, in the same shape, with the
fix in place.

**And the header of every run now prints both** — the resolved title, and what
`active_model` would have said, marked `NOT USED`. When those two lines disagree
the reader is looking at this finding happening again, and at a run that is
nevertheless correct.

**PROVEN AGAINST THE DEFECT BEFORE BEING TRUSTED (learned rule 12).** Headless,
with three stub models and `active_model` deliberately pointed at the closed
`T42IT100NP_TradeCAD`: an undirected probe resolved 545, a probe carrying
`# UCON-MODEL: 30833` resolved nothing and refused, a probe naming `Elliana`
resolved one, and the same probe against a second model whose title also
contains `Elli` refused with two candidates. The in-SketchUp proof is the
outbox header of the next run: `model` says 545 or 30833 while `active` says
whatever `active_model` is holding that day.

**Still true and NOT fixed by this**, because it is a different hole: an inner
`commit_operation` closes the outer one, and `Generator.build` has one. The
rollback remains a mechanism with one documented exception. It is now a mechanism
aimed at the right file.

---

## The rule this is an instance of

Learned rule 13 — *a record of an outside action is only true if something checks
it* — with a sharper edge on it: **an API that names a thing is not a check that
it named the right one.** `active_model` is not a lie the way a stale note is; it
is an answer to a question nobody meant to ask. The cheap defence is the one now
in the probes: say which model you want, and refuse if the answer is not unique.

Candidate learned rule 21, and **not added** — `claude/rules.md` still holds 1-20
and the two earlier candidates are still waiting on Andriy.

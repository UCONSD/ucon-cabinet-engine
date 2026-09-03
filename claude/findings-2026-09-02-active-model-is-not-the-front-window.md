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

## The rule this is an instance of

Learned rule 13 — *a record of an outside action is only true if something checks
it* — with a sharper edge on it: **an API that names a thing is not a check that
it named the right one.** `active_model` is not a lie the way a stale note is; it
is an answer to a question nobody meant to ask. The cheap defence is the one now
in the probes: say which model you want, and refuse if the answer is not unique.

Candidate learned rule 21, and **not added** — `claude/rules.md` still holds 1-20
and the two earlier candidates are still waiting on Andriy.

# `claude/` — the working notes

**What this is.** The reasoning behind the code. Recon of catalog chapters
before they were extracted, architecture decisions and the arguments for them,
findings that corrected something already committed, and the open questions for
Elda. Written during Cowork sessions, kept because the *why* of a registry file
is not in the registry file.

**Moved here on 2026-08-24** from the claude.ai Project that had held them since
2026-08-18, in commit `a775846`; **a second batch — the appliance notes — followed
on 2026-08-25**, listed under "Appliances" below. The move does three things: the knowledge travels with the code, the
history of a note lands in git beside the history of the corrections it
explains, and a future move between tools becomes a `cd` rather than a
migration. **Nothing was deleted from the Project until the first push of this
directory succeeded.** It did, and twenty of the twenty-one originals are gone;
`elda-mini-order-2026-08-20.md` was kept there on purpose, because a scheduled
task writes into it from a session that cannot reach this repository. See
`repo-state.md`.

**After the 2026-08-25 housekeeping the Project holds exactly two files:** the
current `handoff-<date>-<machine>.md` and `elda-mini-order-2026-08-20.md`.
Anything else appearing there is a note that has not been moved yet.

**Faithfully copied.** Every file is the Project text. Where a document said
something that later reading falsified, a **dated correction block was ADDED at
the top or beside the claim — never an edit that erases the mistake** (rule 9,
the same rule the commit log follows). Six documents carry such a block; each
one names the date and what superseded it.

---

## Where to start

| read this | when |
|---|---|
| **`repo-state.md`** | first, always. HEAD, version, check count, registry size, what is uncommitted, what is next. The only file allowed to carry volatile numbers. |
| **`ucon-cabinet-engine-status.md`** | the long-form status: the rules, the environment, the architecture, the NEXT list. Points at `repo-state.md` for numbers and does not repeat them. |
| **`debt-2026-08-24.md`** | how much of the catalog is held, measured rather than remembered. Superseded by a newer dated note, never edited. |
| **`extraction-plan-2026-08-23.md`** | the groups and the reasoning for their order. Its §1-2 numbers are stale by design; §4-7 are the useful part. |

## The rest, by kind

**Findings — a page said something we had assumed:**
`findings-2026-08-23.md`, `findings-2026-08-23-tall.md`,
`findings-2026-08-24-base-column.md`, `findings-2026-08-24-h58_5.md`,
`findings-2026-08-24-pictogram-sweep.md`.

**Chapter recon — read before extracting:**
`wall-units-recon-2026-08-18.md`, `tall-units-recon-2026-08-22.md`,
`fillers-recon-2026-08-23.md`, `usa-elements-recon-2026-08-20.md`,
`corner-units-m22-brief-2026-08-20.md`, `wine-cooler-aperture-2026-08-22.md`.

**Appliances** — a SEPARATE extension (`UCON::Appliances`, own namespace, own
dictionary, own four JSON files, own 48-check suite); `core/88_appliance_check.rb`
is the only seam and it only asks questions. **The package moved into this
repository on 2026-08-25** — `src/ucon_appliances/`, its own extension target
beside `src/ucon_cabinet_engine/`, its own version, its own suite
(`tools/test_appliances.rb`). `appliance-rules-decided.md` is the prose behind
its `data/rules.json`:
`appliance-rules-decided.md`, `findings-2026-08-25-appliance-seam.md`,
`appliance-housing-datum-2026-08-25.md`, `appliance-filler-plane-2026-08-25.md`,
`appliance-flush-vs-standard-2026-08-25.md`,
`appliance-openings-recon-2026-08-25.md` with its raw table
`appliance-openings-106-configs-2026-08-25.csv`.

**Architecture and decisions:**
`warehouse-architecture-2026-08-22.md`, `options-architecture-2026-08-20.md`,
`placement-tool-design-2026-08-19.md`, `plinth-and-wall-hung-2026-08-22.md`,
`finishes-and-price-bands-2026-08-22.md`, `contract-v16-companions-2026-08-22.md`,
`picker-ui-backlog-2026-08-20.md`.

**For Elda:** `elda-mini-order-2026-08-20.md` — the open questions, numbered,
the ones the book cannot answer.

---

## How to keep these honest

1. **Rule 9 — a correction is dated and ADDED.** Never rewrite a claim so the
   mistake disappears; the mistake is why the check exists.
2. **One document owns each volatile number.** `repo-state.md` owns the repo's;
   a dated debt note owns the catalog's. A number copied into two files goes
   stale in one of them.
3. **A reading that stays in a note is a reading the engine does not have.** If
   a note records a catalog fact, the same session should put it in
   `registry/cesar/` and pin it with a check in `tools/test_contract.rb`.
4. **Page numbers here are always PRINTED page numbers.** PDF page = printed
   + 2, in both factory books.

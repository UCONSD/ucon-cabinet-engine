# Handoff — 2026-08-28 evening, the worktops

Read `claude/rules.md`, `claude/repo-state.md` and `docs/Cesar_Volumes_Index.md`
first, as always. This file is only what changed today and what is owed.

**HEAD when this was written:** `6894bfc` plus one commit carrying this file.
Read the two refs, never this line.

---

## The one thing not to undo

**The engine does not draw worktops.** Andriy draws the stone; the engine stamps
the article onto it. That is `repo-state.md`'s Worktops cell, and the reason is
this project's own discipline turned on itself: every rule that generated a
worktop shape would have been **inferred from one kitchen**, and the rules would
never have ended — mitres, scribes, 45° returns, angled walls, a notch round a
column.

A session that finds a tops chapter in the registry and no generator will want to
build one. Re-open the decision before doing it, not after.

`Generator.build_worktop` keeps its code and all its checks and **lost its
button**. Two ways to make a worktop are two ways to be wrong.

---

## What exists now

**`registry/cesar/tops_ceramic_linear_elements.json`** — Linear Elements printed
p.110, the 4 and 6 cm ceramic tops. Two codes. It brought a grammar nothing else
here has: **the code does not determine the price** (five finish groups × eight
depth bands under one code — the group is an order axis, domain rule 6), and
**the depth comes from the order as a closed list, not a range**, so
`Registry.with_ordered_depth` refuses 660 rather than rounding it to 650.

**`core/62_top_stamp.rb`** — pure, no SketchUp. Measures a slab without an axis
convention (thickness is the smallest of three dimensions), lets the chosen band
decide which of the other two is the depth, refuses three things and remarks on
one, tolerance 1 mm everywhere.

**`core/64_sink_mark.rb`** — the sink is **two facts**: the order fact is a
variant on the top (p.110 prices a bowl each; it has no code of its own), the
drawing fact is a dashed rectangle 1 mm above the stone that cuts nothing.
Position is not in the order, which is what lets them come apart.

**Two palette buttons:** *Stamp article on drawn top…* and *Sink over selected
unit…*.

**Suite:** `test_contract` **552**, `test_appliances` **84**, `test_appliance_seam`
**46**, all zero.

---

## The kitchen, where it actually stands

545 Avenida Primavera is getting **Dekton Marmorio, group D, 4 cm**
(`TOPDR008040`). Band **650** over the 620 carcasses and the island — the
finished front is 644,5, so it stands 5,5 proud of the door face. Band **380**
for the breakfast counter, which Andriy set at depth 350 and then, when the bands
were put to him, at **380 — the stone is 380**, not cut down.

806 points/lm at band 650, 618 at band 380. The carcass stands against the wall,
so *to the wall* and *to the carcass back* are the same plane.

**One run is 3552 mm and a top is 3140 at most**, so that run is two pieces and a
joint. Nothing places the joint: build the run in two pieces and stamp each.

**Nothing has been stamped yet.** The tops were still being drawn when the
session closed.

---

## What is owed

**A covering report.** When `build_worktop` lost its button the model lost the
only thing that verified stone actually covers the cabinets — it knew because it
measured them. `Sink over selected unit…` refuses where there is no stamped top,
which is a check on **one** cabinet. What is owed is the one that walks the
kitchen: *carcasses with no stone above them*. This is the largest hole opened
today and it was opened knowingly.

**Elda Q27** — what a joint in a ceramic top costs and what it is called on an
order. This kitchen has one.

**Elda Q28** — is a shaped top ordered by its **bounding rectangle**? Every top
here is priced on that assumption. It is written onto every object the stamp
touches, so if she answers otherwise the numbers move and nothing else does.

**Elda Q21, Q24, Q26** are still open from before.

**The unread table at printed p.172** — *workmanships on tops*. It owes us the
joint, the hob cutout and the sink cutout. Three unpriced things in one kitchen
is the strongest reason yet to read it.

**The island's oak finish name** — one of seven First oaks. An order field,
blocks nothing.

**74 raw type keys in the picker** — ratcheted, not fixed.

**Appliances are paused** by Andriy's decision. The built-in hood liner and the
`wall_reservation` built for it are unused here.

---

## Working on the laptop

Andriy may work at home this weekend. The laptop is **SketchUp 2025, system Ruby
2.6.10**; the office Mac is SketchUp 2026. Each SketchUp version has its own
Plugins folder, and installation is **two symlinks** — the folder
`src/ucon_cabinet_engine` and the registrar `src/ucon_cabinet_engine.rb`.

**`build/go.sh` IS in the repository as of 2026-08-28** and travels with a pull.
It was not, until the laptop was opened: `.gitignore` said `build/` while the
reason printed above that line was only ever about `.rbz` archives — a rule wider
than its own stated reason, which is the shape this project catches everywhere
else and had missed in its own ignore file. It is now `build/*` with
`!build/go.sh`, the script stages itself and `.gitignore`, and a suite check
keeps it that way. The archives, the throwaway probe scripts and
`build/commit-msg.txt` stay out — that last one holds the NEXT message and would
sit one commit stale in history forever.

The script derives its own location (`cd "$(dirname "$0")/.."`), so it runs
wherever the repository sits — but the command handed to Andriy must carry the
repository's path on **that** machine, not the office one.

`sources/**/*.pdf` is git-ignored (~438 MB), so a fresh clone has **no catalog**.
Everything already extracted is in `registry/`; anything that needs a page read
needs the PDFs present.

The two suites run under the Ruby macOS ships, and `go.sh` will not proceed
otherwise — 2.6 on the laptop, so nothing newer than 2.6 syntax may enter
`src/` or `tools/`.

`_to_delete/` holds four scratch files from today. They are untracked; the bridge
cannot delete, so they are Andriy's to remove.

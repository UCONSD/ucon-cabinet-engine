# CLAUDE.md — UCON Cabinet Engine

Onboarding for any Claude surface (Claude Code, Cowork, chat) working in this
repo. Read this first; deeper context lives in `docs/`.

## What this is

Parametric SketchUp 2025 extension generating preliminary, catalog-coded
placeholder cabinetry from Cesar catalog data. The goal is presentation CAD
sheets in LayOut (wireframe, four views: front / plan / side / iso) — data
quality and correct run geometry over 3D richness.

The repo IS the installation — no .rbz, just symlinks into the SketchUp
Plugins folder. TWO of them are required: SketchUp discovers the registrar
`.rb` file at the top level, and that file points at the folder next to it.
Linking only the folder leaves the extension invisible with no error.

```
P="$HOME/Library/Application Support/SketchUp <VERSION>/SketchUp/Plugins"
ln -s ~/dev/ucon-cabinet-engine/src/ucon_cabinet_engine    "$P/ucon_cabinet_engine"
ln -s ~/dev/ucon-cabinet-engine/src/ucon_cabinet_engine.rb "$P/ucon_cabinet_engine.rb"
```

`<VERSION>` is per machine, and they differ: the laptop runs SketchUp 2025,
the office Mac runs 2026 (each version has its own Plugins folder, so linking
into the wrong one silently does nothing). Nothing in the engine is pinned to
a SketchUp version; if one ever behaves differently, the Ruby Console at
startup is where it shows. If the extension still does not appear, check
Window -> Extension Manager -> Manage -> Loading Policy: ours is unsigned and
needs "Unrestricted".

Cloning onto a new machine gets you the code but NOT the catalog: `sources/`
is git-ignored (factory/ alone is ~438 MB). Copy
`CESAR - 2 Kitchen System.pdf` into `sources/factory/` before extracting any
new section.

## How we work: demand-driven

Development is driven by building a REAL kitchen, not by completing the catalog
or the feature list up front. Andriy models an actual project; when he hits a
missing element, THAT becomes the next task — extract the catalog section,
add the module, or write the behaviour, verify it on the same kitchen that was
blocked, continue. The architecture is built for exactly this: catalog is
per-section JSON files (add one, the picker shows it, no code change), core
hot-reloads, picker and symbols derive from data.

Consequence for planning: the roadmap is a MENU of unlocks, not a fixed queue.
Pick the milestone the current kitchen needs (sink wall → M1.7; shared plinth
in a run → M2.1a; finishes → M1.8), not the next number.

Discipline (Control-doc failure signal): when a real kitchen needs something,
ask "catalog fact or one-off?" — a catalog fact goes in the registry (verified
against the source), a one-off goes on that unit's attributes. Never let a
project-specific choice harden into a global standard.

## Non-negotiable domain rules

1. **The source PDF wins.** Catalog facts enter the registry only after
   verification against `sources/factory/CESAR - 2 Kitchen System.pdf`
   (has a text layer; page offset: PDF page = printed page + 2).
   NEVER invent a catalog fact. Unclear → Elda question, not a guess.
2. **Everything is PRELIMINARY** until Cesar/DzineElements (Elda/Giorgio)
   confirms in writing. Trust order: SOURCE < CONTROL < PLANNING < CONFIRMED.
3. **Object Contract is load-bearing** (`docs/UCON_Object_Contract_v1.md`,
   currently v1.4). Attribute dictionary `CabinetEngine`, closed key list,
   enforced by `core/20_contract.rb`. Changes only via versioned revision.
4. **Envelope-only geometry.** Carcass = one volume; front drawn flush
   (the 1.5 mm reveal is recorded data, deliberately not drawn); no interior
   modelled unless the source states it AND a drawing needs it.
5. **Code grammar is family-specific.** H.78: depth digit 7=d.35, 8=d.62,
   9=d.67; width field is a lookup (45→05, 105→10); config suffix is NOT
   globally unique — codes decode only via explicit registry rows.
6. **Per-order axes live outside the article code**: door version 78/75
   (gola = −30 mm, requires GOL profile order lines) and hinge_side (rh/lh,
   never guessed).
7. **An appliance is two objects, not one.** The Cesar panel
   (`object_class=appliance_front`) is ordered and drawn; the machine's niche
   (`appliance`, `manufacturer=client`) is drawn and never ordered. Keep them
   separate — that separation is what lets the exporter emit one and skip the
   other.
8. **A choice can mandate companion codes** (Contract v1.3 §4.2,
   `companion_refs`): gola forces its `GOL` profile, a dishwasher door forces
   the filler profile and — at W75 — `GBBF01`. Companions are resolved from
   the registry, never typed by hand, and the exporter must emit them all.
   Being drawn is a separate question from being ordered.

## Layout

- `src/ucon_cabinet_engine/main.rb` — thin shell (menu). Registers UI once;
  effectively frozen. Changing it requires a SketchUp restart.
- `src/ucon_cabinet_engine/core/` — everything fluid, numbered load order
  (00 version, 10 standards, 20 contract, 30 geometry, 40 b80601 delegate,
  50 registry, 60 generator, 70 symbols, 80 panel, 90 palette).
  Hot-reloads in SketchUp via palette → Reload core. Only 30/60/70/80/90
  touch the SketchUp API; 00/10/20/50 must stay headless-loadable.
- `registry/cesar/` — the catalog AS DATA. `_manifest.json` (grammar,
  hardware, external specs) + one JSON file per catalog section
  (`base_h78.json`: 80 codes, 7 unit types; `sink_base_h78.json`: 20, 4;
  `appliance_h78.json`: 3, 1). One extracted catalog page =
  one section file = one commit. Loader merges + mtime-caches.
- `docs/` — Object Contract, Roadmap (see §7/§7.1 for current milestones),
  Elda open questions + email drafts, project notes.
- `sources/` — git-ignored PDFs (factory/) and the raw extract registers
  (raw_dump/, .md tracked / .xlsx ignored).
- `tools/test_contract.rb` — headless test suite.

## Workflow

- **Tests:** `ruby tools/test_contract.rb` — plain Ruby, no SketchUp,
  currently 113 checks. Run after every change; keep it green. New pure
  logic gets a check here. If a rule needs SketchUp to test, split the
  pure part out first.
- **Versioning:** bump `CORE_VERSION` in `core/00_version.rb` on meaningful
  change (plain assignment — no `defined?` guard, it would pin stale values
  across reloads). Deploy stamp is automatic from mtimes.
- **Commits:** small, one concern each; imperative subject with scope
  prefix (`feat(gola): …`, `fix(symbols): …`). Trailer:
  `Co-Authored-By: Claude <model> <noreply@anthropic.com>`.
- **In Cowork sessions** git runs in Andriy's terminal, never through the
  device bridge (it leaves `.git/index.lock`). In Claude Code, run git
  directly.
- **UI change rules:** menu items are permanent for a SketchUp session
  (no remove API) — shell stays minimal. HtmlDialogs bake their HTML and
  callbacks at open; close/reopen after changing them. Core logic reloads
  live.
- Session rituals: start by reading `docs/UCON_Cabinet_Engine_Roadmap_v1.md`
  §7 (status + next milestones); end by updating it if milestones moved.

## Current state (2026-08-17)

Core v0.17.0. Working: registry-driven generator (build by code, floor
snap, build-next-to-selected continues a run), cascading catalog picker
with search, unit properties panel (78/75, gola profile lines, handles,
hinge side), dashed opening symbols on two hideable tags, 113 green checks.

Registry: 103 codes in three sections of family H.78 — base units (80, printed
p.36 complete, p.39, p.40), sink bases (20, printed p.44) and the
fully-integrated dishwasher door (3, printed p.47). M1.7 proved the
intent: a new section file unfolded new picker levels with zero changes in
core/. What the catalog contains but we have not extracted is recorded in
`_manifest.json` → `catalog_map` and shown as grey rows in the picker, so a
gap is never mistaken for an oversight.

Next milestones (roadmap §7): M1.6 project defaults → M1.8 appearance layer
→ M1.9 Elda round one → M1.10 exporter.
Auto-arrangement track (§7.1): M2.1a batch row builder → M2.1b worktop →
M2.2 corner-as-hinge → M2.3 interactive tool.

Open questions pending Elda (docs/Elda_Open_Questions_v0.1.md): Q1 door
version order notation; Q2 fitted LEGRABOX runner lengths (interim Blum
table in registry external_specs, clearly marked non-Cesar); Q3 modification
minimum width/height + the 989346 ambiguity; Q4 sink bases printed p.45 —
codes 90 vs 91 (and corner AU925/945) are identical in dimensions and price
and differ only in the gola front split (165+555 vs 195+555); the source
never names the distinction.

Q5 which side GBBF01 stands on for a 75 cm dishwasher door; Q6 whether an
appliance panel in a gola kitchen orders its own GOL profile.

Page numbers: always cite PRINTED pages (PDF = printed + 2, verified against
the page footers). Notes written before 2026-08-17 sometimes cited PDF
numbers as if printed — if a page reference does not match its content,
suspect that slip.

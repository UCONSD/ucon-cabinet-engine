# CLAUDE.md — UCON Cabinet Engine

Onboarding for any Claude surface (Claude Code, Cowork, chat) working in this
repo. Read this first; deeper context lives in `docs/`.

## What this is

Parametric SketchUp 2025 extension generating preliminary, catalog-coded
placeholder cabinetry from Cesar catalog data. The goal is presentation CAD
sheets in LayOut (wireframe, four views: front / plan / side / iso) — data
quality and correct run geometry over 3D richness.

Repo is symlinked into SketchUp Plugins:
`~/Library/Application Support/SketchUp 2025/SketchUp/Plugins/ucon_cabinet_engine
 -> ~/dev/ucon-cabinet-engine/src/ucon_cabinet_engine`

## Non-negotiable domain rules

1. **The source PDF wins.** Catalog facts enter the registry only after
   verification against `sources/factory/CESAR - 2 Kitchen System.pdf`
   (has a text layer; page offset: PDF page = printed page + 2).
   NEVER invent a catalog fact. Unclear → Elda question, not a guess.
2. **Everything is PRELIMINARY** until Cesar/DzineElements (Elda/Giorgio)
   confirms in writing. Trust order: SOURCE < CONTROL < PLANNING < CONFIRMED.
3. **Object Contract is load-bearing** (`docs/UCON_Object_Contract_v1.md`,
   currently v1.2). Attribute dictionary `CabinetEngine`, closed key list,
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
  (`base_h78.json`: 74 codes, 5 unit types). One extracted catalog page =
  one section file = one commit. Loader merges + mtime-caches.
- `docs/` — Object Contract, Roadmap (see §7/§7.1 for current milestones),
  Elda open questions + email drafts, project notes.
- `sources/` — git-ignored PDFs (factory/) and the raw extract registers
  (raw_dump/, .md tracked / .xlsx ignored).
- `tools/test_contract.rb` — headless test suite.

## Workflow

- **Tests:** `ruby tools/test_contract.rb` — plain Ruby, no SketchUp,
  currently 77 checks. Run after every change; keep it green. New pure
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

## Current state (2026-08-16)

Core v0.14.0. Working: registry-driven generator (build by code, floor
snap, build-next-to-selected continues a run), cascading catalog picker
with search, unit properties panel (78/75, gola profile lines, handles,
hinge side), dashed opening symbols on two hideable tags, 77 green checks.

Next milestones (roadmap §7): M1.6 project defaults → M1.7 sink base H.78
section → M1.8 appearance layer → M1.9 Elda round one → M1.10 exporter.
Auto-arrangement track (§7.1): M2.1a batch row builder → M2.1b worktop →
M2.2 corner-as-hinge → M2.3 interactive tool.

Open questions pending Elda (docs/Elda_Open_Questions_v0.1.md): Q1 door
version order notation; Q2 fitted LEGRABOX runner lengths (interim Blum
table in registry external_specs, clearly marked non-Cesar).

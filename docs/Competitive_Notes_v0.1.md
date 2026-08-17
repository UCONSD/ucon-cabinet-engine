# Competitive notes v0.1 — 2026-08-16

Review of existing SketchUp kitchen extensions and what their models teach us.
Recorded per the "chats are disposable, decisions live in files" rule.

## The core distinction

Every universal kitchen extension we reviewed builds GENERIC, free-sized
cabinets and outputs a picture (or a joinery cut list) that a human later
translates into a factory order. The UCON engine is the opposite: a unit
exists only if its manufacturer article code exists, sizes are catalog sizes,
facts are verified against the source PDF, and the output is an ORDER-READY,
coded schedule. This is the reason the off-the-shelf tools did not fit — they
cannot know about B80601, gola profile pairs, or Elda confirmation. UX
patterns are worth borrowing; the data model is deliberately not.

## EasySketch (easysketch.co.uk, UK, subscription £29-49/mo)

Generic parametric cabinets, Visual Cabinet Chooser, finish slots
(frontals/carcasses/plinths/worktops/handles), brand material libraries,
Smart Corners, door animations, Content Manager + variant libraries (Studio).

- **Borrow:** visual chooser → our registry-drawn thumbnails (M1.7a); finish
  slots → M1.8 appearance layer; Smart Right Click context menu; saved
  variants (extends M1.6); "content separate from engine" (we already do via
  the registry).
- **Reject:** static image asset libraries (ours derive from data); door
  animations (a wireframe LayOut sheet needs symbols, not motion).

## SG Kitchen Pro (sketchupgurus.co.in, $49/yr or $169 lifetime)

Built on SketchUp Dynamic Components. 16 cabinet types via a toolbar; per-type
config dialog; live edit through native Component Options; Global Settings
push defaults to all cabinets; **Smart Snap** (drop a new cabinet flush
left/right of a selected one at correct Z); **one-click Cut List → CSV**
(part, qty, length, width, thickness). No 2D drawings / elevations / LayOut.

- **Confirms our direction:** Smart Snap == our build-next-to-selected
  (arrived at independently); Global Settings == our M1.6 project defaults
  (proves defaults are a real need); category catalog == our picker, but ours
  grows from data instead of 16 hardcoded toolbar buttons.
- **Where it leads us — act on these:**
  1. **One-click cut list / order schedule is an EXPECTED baseline, not a
     final flourish.** Raise exporter priority (see roadmap). Ours differs in
     kind: not joinery parts but Cesar order lines (code, door version, gola
     profiles, hardware) — because our goal is a factory order, not a cut.
  2. Their live-edit works because geometry is generic DC parametrics with no
     article-code binding. See DC note below.

## Why NOT Dynamic Components (settled, do not revisit without cause)

Day one, the original ~/dev/ucon-cabinet was DC-based; its DC formulas did
not work and we moved to registry-driven generation + rebuild. SG Kitchen Pro
proves DC CAN deliver live Component-Options editing — but only by making all
geometry generic and parametric, with NO binding to catalog article codes.
"Live-edit any dimension" and "every unit is an existing code" are
incompatible by design. For an order-ready, source-verified engine we chose
the correct side. Recorded so this isn't re-litigated later.

## What stays uniquely ours

2D presentation output (front / plan / side / iso, wireframe, LayOut) and
source-verified catalog fidelity with a trust model. Neither reviewed tool
targets either. That is the moat; keep aiming there.

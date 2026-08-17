# Multi-manufacturer strategy v0.1 — 2026-08-16

Onboarding a second factory with its own catalog. NOT YET IMPLEMENTED
(demand-driven — build when a real second factory is onboarded). The point of
this doc: the foundation already anticipates it, and the seams are known.

## Already in place (designed in, not luck)

- **`manufacturer` is a first-class Contract field** (§1: the CabinetEngine
  dictionary is "manufacturer- and class-agnostic"). Every unit already knows
  its factory.
- **The registry loader already takes a manufacturer argument**
  (`Registry.data('cesar')`). `registry/newfactory/` is the natural home — no
  loader rewrite.
- **The registry is already namespaced** (`registry/cesar/`, not `registry/`).

## Mental model: shared engine + swappable manufacturer data packs

- **Shared (does not fork):** Object Contract, trust model, geometry
  primitives, opening symbols, picker/exporter mechanics, shell + palette.
- **Per-manufacturer (data pack):** code grammar, construction standards,
  hardware catalog, unit types + front layouts, modification rules, catalog
  sections.

## Scenarios (not every second factory is the same)

**A. Another catalog manufacturer, same paradigm** (an Italian/German brand
with article codes, standard sizes, a price-list PDF). Easy case:
`registry/brandX/` with its own manifest, grammar, standards, sections. A new
data pack, not new code.

**B. A US / domestic manufacturer, different paradigm.** Nominal inch sizes,
face-frame vs frameless, maybe NO article codes (ordered by spec, not code).
Stretches the Contract more, but `code` is optional — it holds this.

**C. A pure fabricator / UCON's own shop as a "manufacturer".** No catalog at
all — everything made-to-measure. `manufacturer = ucon`, no codes, the bespoke
path scaled up to a whole supplier.

**D. Mixed manufacturers in one kitchen** (the real US-dealer case). Cesar
bases + another brand's specialty piece + UCON bespoke fillers. Per-unit
`manufacturer` earns its place: **the exporter groups the order by
manufacturer** — Cesar lines to Cesar, brand-X to brand-X, UCON sheets cut
in-house. One project, several order documents.

## Known seams (honest — real work, not just data)

1. **Standards move from code into data.** `core/10_standards.rb` holds
   Cesar's standards (18/22/gola) as constants — the one place Cesar
   specificity leaked into CODE rather than data. Another factory has its own
   construction. The main multi-manufacturer refactor: standards become a
   field in each manufacturer's data pack.
2. **Domain concepts become declared capabilities, not universal
   assumptions.** The 78/75 gola door axis is Cesar's; the panel currently
   assumes it always. With a second factory the panel must ask the data ("does
   this brand have a gola axis?") — real work in panel/generator, not just
   data.
3. **Picker gains manufacturer as its top cascade level** (auto-advanced today
   because there is one brand); exporter groups by manufacturer; a project
   default sets the primary brand.

## When

Demand-driven: build when a real second factory is onboarded, not now. The
foundation does not preclude it and the seams are known; today's Cesar data
pack is also the template for tomorrow's brandX.

## Meta

Lifecycle questions (catalog update, second manufacturer) keep resolving to
"the architecture anticipated this" — the payoff of a small, source-verified,
manufacturer-agnostic contract. Recorded so the multi-manufacturer refactor,
when it comes, starts from a known plan rather than a surprise.

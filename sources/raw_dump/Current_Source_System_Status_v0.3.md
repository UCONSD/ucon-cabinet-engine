# Current Source System Status v0.3

**Project:** Cesar Dealership / UCON Cabinet Supply System  
**Status date:** July 29, 2026  
**Document role:** Current source-control and planning-library status register

## 1. Project Purpose

The current system is a preliminary Cesar planning system for UCON / Andriy.

It is intended to provide a controlled, source-based planning library for:

- preliminary SketchUp layout development;
- technical planning and review;
- quote-request preparation;
- identification of missing confirmations before project commitments;
- evaluation of a future Cesar dealership / UCON cabinet-supply workflow.

The system is **not**:

- a production-ready ordering system;
- a final client pricing system;
- confirmation of current product availability;
- authorization to release products for production;
- a substitute for Cesar / DzineElements technical review.

## 2. Source Hierarchy

Use sources in the following order of authority:

1. **Manufacturer technical catalogs / price lists** — primary authority for dimensions, technical rules, module structures, restrictions, product definitions, and catalog references.
2. **Cesar / DzineElements written confirmations** — authority for current availability, U.S. applicability, commercial terms, technical feasibility, and order workflow.
3. **Project-specific drawings and appliance information** — authority for actual room geometry, appliance requirements, utilities, site conditions, and project constraints.
4. **UCON internal workflow assumptions** — permitted only when clearly labeled as internal planning assumptions.
5. **General industry knowledge** — permitted only when clearly marked as inference and never as a replacement for manufacturer confirmation.

## 3. Active Source PDFs

| Active source PDF | Current role | Status |
|---|---|---|
| `CESAR - 1 Project Guidelines(2).pdf` | General project guidelines, catalog governance, finishes, order framework, and supporting commercial references | Active source PDF |
| `CESAR - 2 Kitchen System(2).pdf` | Primary kitchen system source for cabinet units, technical elements, accessories, modifications, and lighting | Active source PDF |
| `CESAR - 3 Linear Elements(2).pdf` | Primary source for worktops, tops, panels, splashbacks, shelves, breakfast bars, and related linear elements | Active source PDF |
| `CESAR - 4 Home Elements(2).pdf` | Source for non-kitchen home systems and related elements | Active source PDF; extraction deferred |
| `CESAR - Bathroom Collection(2).pdf` | Source for bathroom and vanity systems | Active source PDF; extraction deferred |

**Control note:** Inclusion as an active source does not confirm that the price-list edition, product availability, finishes, lead times, or commercial terms are current.

## 4. Active Source-Control / Workflow Markdown Files

| File | Role | Current status |
|---|---|---|
| `Cesar_Source_Register_Initial_Map_v0.1.md` | Initial source classification and document-use map | Active source-control file |
| `Cesar_Kitchen_Quick_Start_v0.2.md` | Minimum source-based rules for preliminary kitchen planning | Active planning guide |
| `SketchUp_Component_Schedule_v0.1(2).md` | Restricted preliminary component schedule for SketchUp setup | Active workflow source; components remain preliminary |
| `Pilot_Extraction_Scope_Bobby_v0.1(1).md` | Controlled pilot extraction scope, exclusions, and sequence | Active pilot-control file |
| `Current_Source_System_Status_v0.2_clean.md` | Prior source-system status register | Superseded by this v0.3 file; retained as version history |

## 5. Active Excel Planning Library

All workbooks below are controlled planning registers. They are not order forms and are not final pricing authorities.

| Sequence | Workbook | Scope | Source PDF | Status | Use | Not Use |
|---:|---|---|---|---|---|---|
| 1 | `Base_Units_Source_Extract_v0.1.xlsx` | Base units and related source-based planning data | `CESAR - 2 Kitchen System(2).pdf` | Active v0.1 planning source | Preliminary SketchUp / planning / review | Production ordering / final pricing |
| 2 | `USA_Elements_Source_Extract_v0.1(1).xlsx` | USA Elements and source-based appliance-related cabinet planning data | `CESAR - 2 Kitchen System(2).pdf` | Active v0.1 planning source | Preliminary SketchUp / planning / review | Production ordering / final pricing |
| 3 | `Tall_Units_Source_Extract_v0.1.xlsx` | Tall units and tall appliance-unit planning data | `CESAR - 2 Kitchen System(2).pdf` | Active v0.1 planning source | Preliminary SketchUp / planning / review | Production ordering / final pricing |
| 4 | `Wall_Units_Source_Extract_v0.1.xlsx` | Wall units, wall cabinet configurations, and related planning data | `CESAR - 2 Kitchen System(2).pdf` | Active v0.1 planning source | Preliminary SketchUp / planning / review | Production ordering / final pricing |
| 5 | `Fillers_End_Elements_Source_Extract_v0.1.xlsx` | Fillers, end elements, open units, and related finishing elements | `CESAR - 2 Kitchen System(2).pdf` | Active v0.1 planning source | Preliminary SketchUp / planning / review | Production ordering / final pricing |
| 6 | `Plinths_Handles_Grip_Recess_Source_Extract_v0.1.xlsx` | Plinths, handles, grip recesses, and related interface elements | `CESAR - 2 Kitchen System(2).pdf` | Active v0.1 planning source | Preliminary SketchUp / planning / review | Production ordering / final pricing |
| 7 | `Modifications_Customisations_Source_Extract_v0.1.xlsx` | Modifications, customisations, dimensional changes, and special-workmanship references | `CESAR - 2 Kitchen System(2).pdf` | Active v0.1 planning source | Preliminary SketchUp / planning / review | Production ordering / final pricing |
| 8 | `Interior_Accessories_Mechanisms_Source_Extract_v0.1.xlsx` | Interior accessories, pull-outs, mechanisms, waste systems, and internal equipment | `CESAR - 2 Kitchen System(2).pdf` | Active v0.1 planning source | Preliminary SketchUp / planning / review | Production ordering / final pricing |
| 9 | `Lighting_Source_Extract_v0.1.xlsx` | Lighting, LED systems, transformers, switches, controls, and related electrical accessories | `CESAR - 2 Kitchen System(2).pdf` | Active v0.1 planning source | Preliminary SketchUp / planning / review | Production ordering / final pricing |
| 10 | `Linear_Elements_Source_Extract_v0.1.xlsx` | Worktops, tops, side panels, splashbacks, upstands, shelves, breakfast bars, back panels, finishing panels, and related linear elements | `CESAR - 3 Linear Elements(2).pdf` | Active v0.1 planning source | Preliminary SketchUp / planning / review | Production ordering / final pricing |

## 6. Completed Source Coverage

| Source PDF | Extracted sections | Current status | Remaining extraction need |
|---|---|---|---|
| `CESAR - 1 Project Guidelines(2).pdf` | Used as governance and supporting reference within the source system; no new section extraction recorded in the v0.1 Excel planning library | Active supporting source | No immediate broad extraction scheduled; use only when a defined planning or confirmation need requires it |
| `CESAR - 2 Kitchen System(2).pdf` | Base Units; USA Elements; Tall Units; Wall Units; Fillers / End Elements / Open Units; Plinths / Handles / Grip Recesses; Modifications / Customisations; Interior Accessories / Mechanisms; Lighting | Primary kitchen extraction scope completed as v0.1 planning workbooks | No additional broad extraction required for the current preliminary planning phase; unresolved items move to Elda / DzineElements confirmation |
| `CESAR - 3 Linear Elements(2).pdf` | Linear Elements | Linear Elements extraction completed as v0.1 planning workbook | Technical feasibility and U.S. applicability confirmation remain required; no additional broad extraction scheduled |
| `CESAR - 4 Home Elements(2).pdf` | None in the current Excel planning library | Active source; intentionally deferred | Extract only if a defined project or dealership workflow requires Home Elements |
| `CESAR - Bathroom Collection(2).pdf` | None in the current Excel planning library | Active source; intentionally deferred | Extract only if a defined bathroom / vanity project or dealership workflow requires it |

## 7. Not Yet Extracted / Intentionally Deferred

The following work is outside the completed v0.1 planning library and remains deferred:

- Home Elements;
- Bathroom Collection;
- full commercial pricing master;
- full SKU-by-SKU master database;
- final production ordering system;
- Bobby-specific appliance coordination matrix;
- final client pricing system.

Deferral is intentional. These items should not be developed until the current commercial, technical, and pilot-workflow constraints are resolved.

## 8. Known Limitations

- Source PDFs may contain older price-list data and require current Cesar / DzineElements confirmation.
- Excel files are planning registers, not order forms.
- Some rows are **P3 / do not use until Elda confirmation**.
- Points / price groups are references only.
- U.S. electrical compatibility for lighting remains subject to written confirmation.
- Linear Elements require technical review for cutouts, seams, support, material feasibility, and U.S. availability.
- SketchUp components must remain preliminary placeholders unless confirmed.
- Catalog presence does not confirm current production availability.
- A workbook row does not override restrictions, collection logic, or notes in the original source PDF.
- The v0.1 planning library does not establish freight, tariffs, tax, margin, lead time, responsibility split, or final commercial terms.

## 9. Elda / DzineElements Confirmation Categories

The consolidated confirmation register should cover:

- current availability;
- U.S. applicability;
- price-list coefficient / commercial terms;
- technical feasibility of modifications;
- appliance-unit compatibility;
- lighting transformers / U.S. electrical compatibility;
- Linear Elements feasibility: tops, panels, sink / hob cutouts, supports, seams;
- final order workflow;
- software / quoting workflow.

Written confirmation should be linked back to the applicable workbook row, source section, project assumption, or workflow decision.

## 10. Recommended Next Work Sequence

1. Create a consolidated Elda Questions Register.
2. Create SketchUp Component Library v0.1 from **P1-only** rows.
3. Create the Bobby / pilot quote-request package only after relevant assumptions are locked.
4. Do not create final pricing until commercial terms are confirmed.
5. Do not create production-ready order schedules until Cesar / DzineElements review.

## 11. Production-Status Warning

> **PRELIMINARY PLANNING ONLY**  
> This system is for preliminary planning only. It does not authorize ordering, production, final pricing, installation details, or client commitments without written confirmation from Cesar / DzineElements.

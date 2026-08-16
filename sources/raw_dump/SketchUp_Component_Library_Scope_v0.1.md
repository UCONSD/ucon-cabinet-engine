# SketchUp Component Library Scope v0.1

**Project:** Cesar Dealership / UCON Cabinet Supply System  
**Primary audience:** UCON internal design team  
**Role:** Scope, build standard, governance framework, and phased development plan  
**Status:** Preliminary planning only  
**Status date:** July 29, 2026

> **PRELIMINARY PLANNING ONLY** — This library is not a production-order system, final pricing system, confirmation of current availability, or substitute for Cesar / DzineElements technical review.

## 1. Executive Summary

Create a controlled internal SketchUp library for preliminary Cesar kitchen planning. The library must improve speed and consistency without becoming a universal Cesar catalog or implying production authority.

Approved uses:

- preliminary room-fit and cabinet-massing studies;
- base, wall, tall, appliance, filler, panel, plinth, grip-recess, and worktop coordination;
- clearance and conflict testing;
- internal technical review;
- assumption tracking;
- review and quote-request preparation.

Prohibited uses:

- final product selection or item-code assignment;
- final appliance integration or cutouts;
- production, fabrication, installation, or MEP drawings;
- final client pricing;
- order release;
- confirmation of current availability.

The v0.1 library is intentionally restricted to controlled preliminary components supported by current Project Sources.

## 2. Core Constraint

The real constraint is not SketchUp capacity. It is the absence of confirmed collection-specific, appliance-specific, U.S.-applicable, and commercially current manufacturer information.

The current sources support generic planning blocks but do not establish universal compatibility, exact appliance integration, current production availability, final codes, or commercial terms. Library development must stop at preliminary geometry until the applicable confirmation gates are passed.

## 3. Source Hierarchy

Use sources in this order:

1. Manufacturer technical catalogs / price lists.
2. Cesar / DzineElements written confirmations.
3. Project-specific drawings and appliance information.
4. UCON internal assumptions, clearly labeled.
5. General industry knowledge, clearly marked as inference.

Current controlling planning sources:

- `Current_Source_System_Status_v0.3.md`
- `Cesar_Kitchen_Quick_Start_v0.2.md`
- `SketchUp_Component_Schedule_v0.1(2).md`
- current v0.1 Excel source extracts;
- original manufacturer PDFs referenced by those extracts.

**Control rule:** A workbook row or SketchUp component never overrides the original manufacturer PDF.

## 4. Library Scope

### 4.1 Included Component Classes

#### Cabinet carcass blocks

- standard 780 mm base block;
- standard 840 mm base block;
- narrow base reference;
- shallow base reference;
- standard wall block, nominal D350;
- selected deep wall reference;
- standard tall block, nominal D620;
- shallow tall reference;
- tall top-element reference.

#### Interface and finishing components

- straight filler / closing strip;
- 50 mm closing-strip reference;
- corner filler references;
- base, wall, and tall end panels;
- front plinth references;
- side plinth return;
- horizontal and vertical grip-recess references;
- generic worktop reference.

#### Appliance placeholders

- 24-inch dishwasher;
- 30-inch oven;
- 30-inch and 36-inch ranges;
- 36-inch refrigerator;
- 18-inch and 24-inch undercounter appliances;
- 42-inch and 48-inch special-width references.

Appliance objects are nominal planning envelopes only. Exact model, cutout, utilities, ventilation, door swing, service access, panel method, and Cesar compatibility remain unconfirmed unless written evidence is linked.

### 4.2 Project-Only Objects

These may be created inside a project file but may not enter the controlled master library without review:

- sink and hood placeholders;
- countertop overhangs;
- appliance swing and service envelopes;
- seating and circulation envelopes;
- room-shell references;
- assumption and conflict markers.

### 4.3 Excluded from v0.1

- final Cesar item codes;
- full SKU-by-SKU library;
- complete door/drawer subdivision catalog;
- complete sink-base or hood-cabinet library;
- corner mechanisms;
- appliance-specific cabinet construction;
- final appliance housings;
- collection-specific shaped panels;
- production fillers, panels, plinths, or grip profiles;
- custom-modification geometry;
- detailed accessories, mechanisms, or lighting hardware;
- final worktop fabrication geometry, cutouts, seams, or supports;
- Home Elements and Bathroom Collection;
- pricing or production-order schedules.

## 5. Component Build Standards

### 5.1 Units and Geometry

- Primary units: millimeters.
- Imperial dimensions: secondary reference only where the source uses inches.
- Every asset must be a SketchUp component, not loose geometry.
- Raw geometry remains on `Untagged`.
- Axes and insertion points must follow one consistent standard.
- Components must remain editable without exploding.
- Geometry must be simplified for preliminary planning.

### 5.2 Separation Logic

Never fuse these into one object:

- carcass;
- opening/front reference;
- filler;
- end panel;
- plinth;
- grip recess;
- worktop;
- appliance placeholder;
- clearance envelope.

### 5.3 Height and Depth Logic

- Component height represents carcass height unless explicitly stated otherwise.
- Plinth, grip-recess zone, and worktop remain separate.
- Finished counter height must not be inferred from carcass height alone.
- The 780 mm and 840 mm base systems remain separate.
- Maintain separate values for `CARCASS_DEPTH_MM`, `VISIBLE_SIDE_PANEL_DEPTH_MM`, and `FINISHED_PROJECTION_MM`.

### 5.4 Adjustable Parameters

Where technically practical, control:

- width, height, and carcass depth;
- visible-panel depth and finished projection;
- base system;
- opening type and hinge side;
- front-division reference;
- appliance zone;
- filler reason;
- panel edge condition;
- plinth setback;
- grip-recess position.

An adjustable parameter does not confirm that every resulting combination is available.

### 5.5 Level of Detail

Include only geometry required to evaluate massing, interfaces, projections, appliance envelopes, swings, and clearance risk.

Exclude hardware detail, joinery, drilling, machining, detailed internal equipment, and decorative geometry that adds weight without improving planning decisions.

## 6. Naming and Metadata

### 6.1 Naming Pattern

Use uppercase names with underscores:

`[CLASS]_[FUNCTION]_[HEIGHT/DEPTH OR CONDITION]`

Examples:

- `BASE_STD_780_D620`
- `WALL_STD_D350`
- `TALL_STD_D620`
- `FILLER_STRAIGHT_GENERIC`
- `END_PANEL_TALL_GENERIC`
- `PLINTH_FRONT_H100`
- `USA_APPL_DW_24_PLACEHOLDER`

Do not use names that imply a confirmed code, collection, appliance match, or production approval.

### 6.2 Required Metadata

| Field | Requirement |
|---|---|
| `COMPONENT_CLASS` | Required |
| `COMPONENT_NAME` | Required |
| `WIDTH_MM` | Required where applicable |
| `HEIGHT_MM` | Required where applicable |
| `CARCASS_DEPTH_MM` | Required for cabinet blocks |
| `VISIBLE_SIDE_PANEL_DEPTH_MM` | Required where relevant |
| `FINISHED_PROJECTION_MM` | Required where relevant |
| `BASE_SYSTEM_780_840` | Required where applicable |
| `OPENING_TYPE` | Required; use `TBD` when unknown |
| `HINGE_SIDE` | Required when relevant |
| `APPLIANCE_MODEL` | Required for appliance placeholders; default `TBD` |
| `SOURCE_BASIS` | Required |
| `STATUS` | Required |
| `ASSUMPTION_NOTE` | Required when unsupported |
| `LAST_REVIEW_DATE` | Required |
| `REVIEWED_BY` | Required |

Controlled status values:

- `PRELIMINARY`
- `NEEDS_ELDA_CONFIRMATION`
- `CONFIRMED_BY_ELDA`
- `REJECTED_OR_REVISED`
- `ARCHIVED`

Filler reason codes:

- `WALL`
- `HANDLE`
- `FRIDGE_SWING`
- `CORNER`
- `DISHWASHER_ADJACENCY`
- `OUT_OF_SQUARE`
- `ALIGNMENT`

## 7. File and Visual Standards

Master file:

`Cesar_SketchUp_Component_Library_v0.1.skp`

Do not overwrite controlled revisions.

Recommended folders:

```text
Cesar_SketchUp_Library/
├── 00_Governance/
├── 01_Base_Units/
├── 02_Wall_Units/
├── 03_Tall_Units/
├── 04_Fillers_Closing_Strips/
├── 05_End_Panels/
├── 06_Plinths/
├── 07_Grip_Recesses/
├── 08_Appliance_Placeholders/
├── 09_Worktop_References/
├── 10_Clearance_Envelopes/
├── 90_Review_Pending/
└── 99_Archive/
```

Use neutral internal materials that distinguish component classes and unresolved status. Do not simulate final finishes.

Performance requirements:

- low polygon count;
- no unnecessary textures;
- no uncontrolled marketing models;
- no hidden heavy geometry;
- purge before release;
- test in a representative kitchen model.

## 8. Quality-Control Workflow

Every component must pass four gates.

### Gate 1 — Source Review

- source file and page/section identified;
- dimensions and restrictions checked;
- status and unresolved conditions recorded;
- preliminary-use eligibility confirmed.

### Gate 2 — Build Review

- units, axes, origin, and bounding box checked;
- geometry remains separated;
- parameters work as intended;
- metadata is complete;
- file size is reasonable.

### Gate 3 — Model Test

Test placement, run alignment, resizing, replacement, panel/filler separation, plinth continuity, grip alignment, appliance fit, exports, and schedule readability.

### Gate 4 — Release

The library owner approves movement from `90_Review_Pending` into the controlled library. No self-release by the component builder.

## 9. Roles and Responsibilities

| Role | Responsibility |
|---|---|
| Library owner | Scope, versions, releases, archive, and change approval |
| Technical source reviewer | Source verification, restrictions, and status |
| Component builder | Geometry and metadata |
| Project designer | Correct use and assumption logging |
| Technical reviewer | Project conflicts and quote-request readiness |
| Elda / DzineElements | Collection, availability, compatibility, and feasibility confirmation |

**Founder-dependency rule:** The system is not operational if approval or interpretation depends only on Andriy’s memory. Use written standards, named owners, checklists, status fields, and decision logs.

## 10. Elda / DzineElements Confirmation Gate

Before a generic block becomes a quote-request module, confirm:

1. Collection and door family.
2. Opening system.
3. Base-height system: 780 mm or 840 mm.
4. Plinth height and finish.
5. Exact appliance models.
6. Current USA Elements compatibility.
7. Current production availability.
8. Exact filler requirements.
9. End-panel thickness, depth, edge, and grip termination.
10. Tall-unit height and front alignment.
11. U.S. applicability.
12. Modification or linear-element feasibility where relevant.
13. Required quotation and order workflow.

Written confirmation must be linked to the applicable component or schedule row.

## 11. Development Phases

### Phase 0 — Governance Lock

Deliver scope, naming, metadata, folders, QC checklist, ownership, and version-control method.

**Exit gate:** Governance approved before more components are built.

### Phase 1 — P1 Preliminary Core Library

Build only the approved base, wall, tall, filler, panel, plinth, grip, appliance-placeholder, and worktop-reference components.

**Exit gate:** All assets pass source, geometry, metadata, and model-use review.

### Phase 2 — Bobby Pilot Validation

Test the library in the Bobby / 410 Alta Vista preliminary model. Record usability issues, missing classes, assumptions, and scope leakage.

**Exit gate:** Pilot works without unsupported production detail.

### Phase 3 — Elda Confirmation Update

Update selected components only after written confirmation of collection, opening system, base height, plinth, appliance compatibility, panel/filler rules, availability, and U.S. applicability.

### Phase 4 — Quote-Request Module Layer

Create a separate controlled layer for confirmed module references, source codes where verified, appliance mapping, and unresolved technical questions.

**Restriction:** This remains separate from production-order authority.

### Phase 5 — Production Workflow Assessment

Assess whether a production-support library is justified only after pilot economics, territory, margin, workflow, support, and responsibility split are clear.

## 12. Change Control

Every controlled revision must record:

- component and version;
- change description and reason;
- source basis;
- reviewer and approval date;
- affected project files;
- backward-compatibility impact.

Do not silently replace a component already used in project files.

## 13. Metrics

Track:

- planned, built, source-verified, and QC-approved components;
- components requiring Elda confirmation;
- rejected or revised components;
- average build time;
- pilot substitutions;
- project-specific custom components;
- model errors caused by library assets;
- percentage with complete metadata.

Initial success criteria:

- 100% source basis and status coverage;
- 100% naming compliance;
- 100% geometry and metadata QC;
- Bobby pilot can be modeled without unsupported production detail;
- assumptions remain visible and traceable;
- no component is mistaken for production authority.

## 14. Risk Register

| Risk | Exposure | Control |
|---|---|---|
| Generic block treated as confirmed product | High | Mandatory status and disclaimer |
| Unsupported combination created | High | Source review and Elda gate |
| Nominal appliance width treated as compatibility | High | Exact-model placeholder rule |
| Collections mixed | High | Source and collection control |
| Full-catalog digitization starts too early | High | Scope and phase gates |
| Workbook overrides original PDF | High | Original-PDF-first rule |
| Old assets remain in projects | Medium | Version and impact log |
| Model becomes too heavy | Medium | Low-detail standard and testing |
| Founder becomes approval bottleneck | High | Role clarity and documented QC |
| Library used for pricing or ordering | High | Prohibited-use policy |
| Project object contaminates master library | Medium | Review-pending separation |

## 15. Failure Signals

Stop and review if:

- unverified Cesar codes appear in component names;
- source basis is missing;
- generic assets are shown as confirmed modules;
- final appliance cutouts are modeled without exact-model review;
- 780 mm and 840 mm systems are mixed without control;
- fillers, panels, plinths, grips, or tops are fused into carcasses;
- project-specific objects enter the master library without review;
- duplicate names contain different geometry;
- changes occur without revision logs;
- Elda confirmation is replaced by internal assumptions;
- full-catalog digitization begins before the pilot workflow is proven.

## 16. Immediate Next Actions

1. Approve this document as the v0.1 control scope.
2. Assign the library owner and technical reviewer.
3. Create the folder structure and build checklist.
4. Convert the existing component schedule into a build queue.
5. Classify each component: build now, source review, Elda confirmation, excluded, or deferred.
6. Build only P1 preliminary components.
7. Validate them in the Bobby pilot.
8. Record defects and missing needs.
9. Update only through controlled revisions.
10. Do not start production-support development until pilot and dealership constraints are resolved.

## 17. Approval Gate

Proceed to controlled building only when:

- [ ] scope is approved;
- [ ] owner and reviewer are assigned;
- [ ] source hierarchy is accepted;
- [ ] naming and metadata standards are accepted;
- [ ] exclusions are accepted;
- [ ] QC and version-control methods are established;
- [ ] Elda confirmation gate is accepted;
- [ ] the internal team accepts that v0.1 is preliminary and not production-ready.

**Recommendation:** Proceed with the restricted P1 preliminary core library. Do not develop a universal Cesar component library or production-order system at this stage.

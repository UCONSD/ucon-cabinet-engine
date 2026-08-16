# Bobby SketchUp Modeling Checklist v0.1

**Project:** Bobby / 410 Alta Vista Cesar Pilot  
**Client / Owner:** Mr. Bobby Dadvar  
**Project address:** 410 Alta Vista Way, Laguna Beach, CA 92651  
**Purpose:** Practical step-by-step checklist for creating a controlled preliminary SketchUp kitchen concept.  
**Status:** Preliminary planning only. Not production-ready and not approved for ordering, fabrication, construction, appliance rough-in, installation, or pricing.

---

## Source Control

| Ref. | Source | Intended use |
|---|---|---|
| S1 | `Cocina Modificada.pdf`, PDF p. 1, sheet C-2, dated 03-18-2024 | Primary source for the latest visible kitchen arrangement, island position, appliance-zone locations, pantry relationship, and kitchen-specific written dimensional references |
| S2 | `410 ALTA VISTA-BUILDING DPT ARCHITECTURAL PLANS-12-5-23.pdf`, particularly PDF p. 5 / sheet A-3, elevations, sections, and main-level EMP plan | Governing architectural geometry, room relationships, openings, stairs, floor elevation, plate-height context, circulation, and permitted MEP reference |
| S3 | `Bobby_Project_Input_Register_v0.1` | Consolidated project facts, source precedence, conflicts, open questions, and confirmation gates |
| S4 | `Bobby_Preliminary_Design_Workflow_v0.1` | Governing preliminary modeling sequence, placeholder rules, assumption controls, review scenes, export requirements, and stop conditions |
| S5 | Current Cesar project sources | Later technical reference only. Do not use them to assign final modules, item codes, appliance housings, or production details during this checklist |

### Source-Use Rules

- [ ] Use written dimensions shown on the project drawings.
- [ ] Do not create missing dimensions by scaling the PDFs.
- [ ] Use `Cocina Modificada.pdf` as the primary source for the visible kitchen concept.
- [ ] Use the architectural set for building geometry, room relationships, elevations, sections, circulation, and permitted MEP references.
- [ ] Do not assume the modified kitchen plan has been incorporated into the permitted architectural or MEP set.
- [ ] Where sources conflict, record the conflict. Do not silently reconcile it.
- [ ] Label every unsupported dimension, position, or configuration as an assumption.
- [ ] Keep all appliance geometry as nominal placeholders until exact models and current installation manuals are received.
- [ ] Do not assign final Cesar modules, item codes, fillers, panels, plinths, front divisions, opening systems, or appliance housings.

---

# 1. File Setup

## 1.1 Create the Working File

- [ ] Create a new SketchUp file using a clean architectural template.
- [ ] Set the primary modeling units to **millimeters**.
- [ ] Set dimension precision appropriate for preliminary planning without implying field-verified accuracy.
- [ ] Keep imperial dimensions only as secondary references when they are explicitly shown on the source drawings or used for nominal appliance categories.
- [ ] Confirm that imported references are not being treated as dimensionally authoritative until checked against written dimensions.

## 1.2 File Naming

Use a controlled version name:

`Bobby_410_Alta_Vista_Preliminary_Kitchen_v0.1.skp`

For revisions:

`Bobby_410_Alta_Vista_Preliminary_Kitchen_v0.2.skp`  
`Bobby_410_Alta_Vista_Preliminary_Kitchen_v0.3.skp`

- [ ] Do not overwrite the previous controlled version.
- [ ] Record the revision date in Model Info, a model note, or the revision log.
- [ ] Record the source package used for each revision.

## 1.3 Scene Naming Standard

Create scenes using numbered names so they remain in review order:

1. `01_OVERALL_PLAN`
2. `02_KITCHEN_PLAN`
3. `03_ISLAND_VIEW`
4. `04_RANGE_WALL`
5. `05_TALL_APPLIANCE_REFRIGERATION_WALL`
6. `06_PANTRY_RELATIONSHIP`
7. `07_CLEARANCE_REVIEW`
8. `08_ASSUMPTIONS_OPEN_QUESTIONS`

## 1.4 Tag / Folder Setup

Create separate tags, groups, or component folders:

| Tag / folder | Contents |
|---|---|
| `00_SOURCE_REFERENCES` | Imported PDF/image references, alignment markers, written-dimension checks |
| `01_ROOM_SHELL` | Walls, openings, floor, ceiling, columns, stairs, architectural references |
| `02_ISLAND_ZONE` | Island body, countertop, overhang, sink, dishwasher, seating, clearance zones |
| `03_RANGE_ZONE` | Range placeholder, landing zones, adjacent cabinet masses, hood envelope |
| `04_REFRIGERATION_ZONE` | Refrigerator and freezer placeholders, provisional swings, fillers, side panels |
| `05_TALL_APPLIANCE_STACK` | Coffee machine, combi-steam oven, generic tall housing, service zones |
| `06_SINK_DISHWASHER_ZONE` | Sink, sink-base zone, dishwasher, waste-storage zone, work clearances |
| `07_PANTRY_ADJACENCY` | Pantry opening, surrounding walls, adjacent masses, access route |
| `08_CLEARANCE_ENVELOPES` | Aisles, appliance swings, drawer projections, seating, travel paths |
| `09_ASSUMPTIONS` | Assumption labels, provisional dimensions, unresolved alternatives |
| `10_MEP_PLACEHOLDERS` | Diagrammatic water, waste, electrical, gas, hood, duct, and ventilation references |
| `11_CESAR_CONCEPT_BLOCKS` | Generic base, wall, tall, filler, panel, plinth, and worktop reference blocks only |
| `12_REVIEW_NOTES` | Bobby questions, conflicts, comments, decisions, and revision markers |

## 1.5 Basic Model Controls

- [ ] Keep raw geometry on `Untagged`.
- [ ] Group or componentize every modeled object.
- [ ] Keep source references locked.
- [ ] Use section planes only for review clarity.
- [ ] Keep assumption labels visible in the dedicated review scene.
- [ ] Purge unused geometry before each controlled issue.

---

# 2. Source Setup

## 2.1 Import / Reference `Cocina Modificada.pdf`

- [ ] Import or reference PDF p. 1, sheet C-2.
- [ ] Place the source on `00_SOURCE_REFERENCES`.
- [ ] Lock the source reference after alignment.
- [ ] Use it for:
  - [ ] visible kitchen arrangement;
  - [ ] island position and orientation;
  - [ ] cooking-zone location;
  - [ ] visible refrigerator/freezer designations;
  - [ ] sink-like fixture position;
  - [ ] pantry relationship;
  - [ ] visible appliance letters;
  - [ ] visible written aisle dimensions.
- [ ] Do not assume that the visible `15 ft-7 1/2 in` dimension is the confirmed island cabinet-body length unless its endpoints are established.
- [ ] Do not use PDF scaling to create dimensions that are not written on the drawing.

## 2.2 Import / Reference Architectural Main-Level Plan

- [ ] Import or reference `410 ALTA VISTA-BUILDING DPT ARCHITECTURAL PLANS-12-5-23.pdf`, PDF p. 5 / sheet A-3.
- [ ] Place the architectural source on `00_SOURCE_REFERENCES`.
- [ ] Align the architectural plan independently from the modified kitchen plan.
- [ ] Lock the source reference after alignment.
- [ ] Use it for:
  - [ ] main-level architectural geometry;
  - [ ] Kitchen, Living, Dining, Pantry, and Office/Study relationships;
  - [ ] walls, openings, stairs, and circulation;
  - [ ] south-side island clearance shown as `3 ft-0 in`, where applicable;
  - [ ] main-level finished-floor reference;
  - [ ] plate-height and ceiling context from elevations and sections;
  - [ ] permitted MEP reference.

## 2.3 Record Geometry Control

Create a source-control note in the model:

| Geometry item | Controlling source | Status / note |
|---|---|---|
| Visible kitchen layout | S1 — Cocina Modificada | Kitchen-specific concept source |
| Main walls and room relationships | S2 — Architectural set | Governing architectural geometry |
| Island position and orientation | S1, checked against S2 | Preliminary; conflicts must be logged |
| Openings, stairs, and circulation context | S2 | Use written dimensions only |
| Appliance-zone positions | S1 | Preliminary category locations only |
| Ceiling / plate-height context | S2 elevations and sections | Verify exact finished condition later |
| MEP references | S2 EMP plan | Not confirmed as coordinated with S1 |

## 2.4 Conflict Marking

- [ ] Overlay or compare S1 and S2.
- [ ] Mark each conflict with a numbered review note.
- [ ] Record conflicts involving:
  - [ ] wall locations;
  - [ ] openings;
  - [ ] island location;
  - [ ] appliance locations;
  - [ ] pantry access;
  - [ ] circulation dimensions;
  - [ ] plumbing points;
  - [ ] gas and electrical points;
  - [ ] hood / duct references;
  - [ ] lighting or control locations.
- [ ] Assign each conflict to the assumption or question register.
- [ ] Do not choose a resolution unless supported by a written source or confirmed decision.

---

# 3. Room Shell

## 3.1 Walls

- [ ] Model the main kitchen walls using written source dimensions only.
- [ ] Model only the adjacent Living and Dining boundaries needed to understand circulation.
- [ ] Model wall returns, columns, and projections shown in the source set.
- [ ] Separate confirmed wall geometry from provisional wall geometry.
- [ ] Label any provisional wall length, thickness, or finished-face position.

## 3.2 Openings

- [ ] Model openings affecting the kitchen layout.
- [ ] Model the pantry opening and immediate wall returns.
- [ ] Model openings toward Living and Dining that affect circulation or views.
- [ ] Model exterior openings that may affect cabinetry, appliance placement, or hood conditions.
- [ ] Do not invent opening dimensions.

## 3.3 Floor

- [ ] Create the main-level floor plane.
- [ ] Record the documented main-level finished-floor reference where useful.
- [ ] Do not infer finish thicknesses or transitions that are not shown.

## 3.4 Ceiling / Plate-Height Reference

- [ ] Create a ceiling or plate-height reference plane using the documented architectural reference where appropriate.
- [ ] Keep the plane tagged separately so it can be hidden during plan review.
- [ ] Mark the finished ceiling condition as provisional until field verification.
- [ ] Add placeholders for soffits, beams, dropped conditions, or obstructions only where shown or required for conflict review.

## 3.5 Pantry Adjacency

- [ ] Model the pantry entry.
- [ ] Model enough pantry-side geometry to test access and adjacent tall-unit conflicts.
- [ ] Keep detailed pantry cabinetry out of the first pass unless Bobby confirms it is included in the pilot scope.

## 3.6 Office / Study Side Wall

- [ ] Model the wall relationship between the Kitchen and Office/Study side.
- [ ] Include only the amount of Office/Study context required to understand the kitchen boundary and circulation.
- [ ] Flag any source conflict affecting this wall.

## 3.7 Stairs / Circulation Context

- [ ] Model stairs and immediate circulation context shown on the main-level plan.
- [ ] Represent travel paths between Kitchen, Living, Dining, Pantry, and stairs.
- [ ] Keep circulation geometry simplified but dimensionally controlled where written dimensions are available.

### Room-Shell Gate

Do not proceed to cabinet massing until:

- [ ] source references are aligned;
- [ ] the architectural shell is grouped and tagged;
- [ ] all unsupported room geometry is labeled;
- [ ] major S1-versus-S2 conflicts are entered into the register.

---

# 4. Kitchen Zones

## 4.1 Island Zone

- [ ] Create a neutral island-body mass.
- [ ] Model the approximate position and orientation shown on S1.
- [ ] Keep the island body, countertop, overhang, end panels, sink zone, dishwasher zone, seating zone, and clearance envelope as separate objects.
- [ ] Label the overall island dimensions as provisional unless supported by verified written endpoints.
- [ ] Do not convert the visible `15 ft-7 1/2 in` dimension into a confirmed cabinet-body length without source clarification.

## 4.2 Range Zone

- [ ] Place the range zone on the east perimeter as shown in the modified concept.
- [ ] Add the nominal 48-inch range placeholder.
- [ ] Add neutral adjacent landing and cabinet zones.
- [ ] Add a preliminary hood / ventilation volume.
- [ ] Add a range operating zone and door / handle projection envelope.
- [ ] Do not model final gas, electrical, rear, side, combustible-material, duct, or makeup-air requirements.

## 4.3 Refrigeration Zone

- [ ] Place neutral refrigerator and freezer placeholder volumes at the visible R and F locations.
- [ ] Keep each visible refrigeration-designated location separate.
- [ ] Do not assume a combined unit, separate columns, panel-ready configuration, width, hinge direction, or ventilation requirement.
- [ ] Add provisional door-swing envelopes only as assumptions.

## 4.4 Tall Appliance Stack

- [ ] Create a provisional tall-zone mass.
- [ ] Add separate placeholders for the 24-inch plumbed coffee machine and 24-inch combi-steam oven.
- [ ] Test single-stack versus adjacent-stack massing only as concept alternatives.
- [ ] Review approximate user reach, visual height, landing-space relationship, door interference, and relationship to refrigeration.
- [ ] Do not establish final niche dimensions, shelf separation, ventilation, utilities, front divisions, or Cesar housing selection.

## 4.5 Sink / Dishwasher Zone

- [ ] Place the sink and dishwasher as separate placeholders in or adjacent to the island fixture zone.
- [ ] Add a generic sink-base zone.
- [ ] Add a dishwasher-door opening envelope.
- [ ] Add a loading / unloading standing zone.
- [ ] Add a possible trash / recycling mass only as a generic concept block.
- [ ] Do not assign the exact sink size, sink-base width, dishwasher side, appliance order, or plumbing centerline until confirmed.

## 4.6 Pantry Access

- [ ] Test pantry-door clearance.
- [ ] Test tall-unit projection near the pantry entry.
- [ ] Test grocery transfer between Pantry and Kitchen.
- [ ] Test circulation between Kitchen, Dining, and Pantry.
- [ ] Mark any required filler or wall-return condition as provisional.

## 4.7 Clearance Envelopes

Create visible envelopes for:

- [ ] east-side island aisle;
- [ ] south-side island clearance;
- [ ] pantry access;
- [ ] Kitchen-to-Dining circulation;
- [ ] Kitchen-to-Living circulation;
- [ ] range operating area;
- [ ] appliance door swings;
- [ ] cabinet drawers and pullouts;
- [ ] seating pullback, if seating is intended.

---

# 5. Appliance Placeholders

## 5.1 Naming Standard

Use function-based names that do not imply final product selection.

| Appliance category | Required placeholder component name | Modeling rule |
|---|---|---|
| 48-inch dual-fuel range | `APPLIANCE_PLACEHOLDER_RANGE_48IN_MODEL_TBD` | Nominal width category only; no final cutout, utilities, clearances, or model data |
| 24-inch plumbed coffee machine | `APPLIANCE_PLACEHOLDER_COFFEE_24IN_MODEL_TBD` | Nominal category only; no final niche, water, drain, electrical, ventilation, or service data |
| 24-inch combi-steam oven | `APPLIANCE_PLACEHOLDER_COMBISTEAM_24IN_MODEL_TBD` | Nominal category only; no final niche, water, drain, electrical, ventilation, or service data |
| Refrigerator | `APPLIANCE_PLACEHOLDER_REFRIGERATOR_MODEL_TBD` | Width, height, configuration, hinge, panel strategy, and ventilation remain TBD |
| Freezer | `APPLIANCE_PLACEHOLDER_FREEZER_MODEL_TBD` | Width, height, configuration, hinge, panel strategy, and ventilation remain TBD |
| Dishwasher | `APPLIANCE_PLACEHOLDER_DISHWASHER_MODEL_TBD` | Exact width, panel condition, utility requirements, and opening remain TBD |
| Sink | `FIXTURE_PLACEHOLDER_SINK_MODEL_TBD` | Exact size, mounting type, bowl configuration, and centerline remain TBD |
| Hood | `APPLIANCE_PLACEHOLDER_HOOD_MODEL_TBD` | Width, CFM, mounting, duct route, makeup air, and clearances remain TBD |

## 5.2 Required Placeholder Treatment

For every appliance placeholder:

- [ ] Keep the appliance as a separate component.
- [ ] Add a note stating that the exact model is not confirmed.
- [ ] Keep door swing or handle projection as a separate clearance component.
- [ ] Keep service-access space as a separate assumption envelope.
- [ ] Do not model manufacturer cutouts.
- [ ] Do not model utility points as final rough-in locations.
- [ ] Do not imply Cesar compatibility.

Use this note:

> **APPLIANCE PLACEHOLDER:** Nominal appliance category shown for preliminary planning only. Exact model, overall dimensions, cutout, clearances, utilities, ventilation, door swing, service access, panel requirements, and Cesar compatibility are not confirmed.

---

# 6. Cabinet Massing

## 6.1 Generic Base Blocks

- [ ] Use neutral base-cabinet masses only.
- [ ] Keep each block editable in width, height, and depth.
- [ ] Use dimensions only when supported by the current controlled source or clearly labeled as assumptions.
- [ ] Do not assign internal accessories, drawer divisions, fronts, or opening systems.

Suggested name format:

`BASE_BLOCK_GENERIC_WIDTH_TBD_HEIGHT_TBD_DEPTH_TBD`

## 6.2 Generic Tall Blocks

- [ ] Use neutral tall-cabinet masses only.
- [ ] Separate appliance placeholders from the surrounding tall mass.
- [ ] Keep tall-unit grouping provisional.
- [ ] Do not create final appliance housings.

Suggested name:

`TALL_BLOCK_GENERIC_WIDTH_TBD_HEIGHT_TBD_DEPTH_TBD`

## 6.3 Wall Blocks

- [ ] Add wall-cabinet masses only where required to understand the concept.
- [ ] Keep all wall-block dimensions provisional unless source-supported.
- [ ] Do not imply a final Cesar collection, door system, or front division.

Suggested name:

`WALL_BLOCK_GENERIC_WIDTH_TBD_HEIGHT_TBD_DEPTH_TBD`

## 6.4 Fillers

- [ ] Use fillers as provisional clearance zones, not final production pieces.
- [ ] Keep filler thickness and width as TBD unless source-supported.
- [ ] Add fillers where wall conditions, tall units, appliance doors, or adjacent panels may require clearance.

Suggested name:

`FILLER_PLACEHOLDER_VERIFY`

## 6.5 End Panels

- [ ] Model end panels as separate generic planes or masses.
- [ ] Keep thickness, projection, finish, and return condition unresolved.

Suggested name:

`END_PANEL_PLACEHOLDER`

## 6.6 Plinth Reference

- [ ] Model a separate conceptual plinth volume.
- [ ] Keep height, setback, finish, ventilation, and system unresolved.

Suggested name:

`PLINTH_PLACEHOLDER_HEIGHT_TBD`

## 6.7 Countertop Reference

- [ ] Create a separate worktop reference plane or mass.
- [ ] Keep material, thickness, edge, overhang, seam, support, and fabrication unresolved.

Suggested name:

`WORKTOP_REFERENCE_THICKNESS_TBD`

## 6.8 Prohibited Cabinet Information

- [ ] No Cesar item codes.
- [ ] No final module assignment.
- [ ] No final collection selection.
- [ ] No confirmed opening system.
- [ ] No production filler or panel dimensions.
- [ ] No final plinth or grip-recess geometry.
- [ ] No final appliance housing.
- [ ] No pricing.

---

# 7. Clearance and Conflict Testing

## 7.1 Island Aisles

- [ ] Show all island aisles as visible envelopes.
- [ ] Record written source dimensions where clearly established.
- [ ] Label any inferred or provisional aisle as an assumption.
- [ ] Test simultaneous use of opposing cabinet or appliance fronts.

## 7.2 Range Working Zone

- [ ] Show standing space in front of the range.
- [ ] Test range-door and handle projection.
- [ ] Test conflict with island circulation.
- [ ] Test adjacent landing zones conceptually.
- [ ] Do not claim compliance with manufacturer clearances before exact model review.

## 7.3 Refrigerator Door Swing

- [ ] Add provisional door-swing envelopes.
- [ ] Test conflict with walls, panels, island, pantry route, and adjacent tall units.
- [ ] Mark hinge direction as TBD unless confirmed.
- [ ] Do not assume internal drawer pullout or full-door opening requirements.

## 7.4 Dishwasher Door Swing

- [ ] Add a full open-door envelope as a preliminary test.
- [ ] Test conflict with opposing cabinetry, island circulation, sink user, and pantry route.
- [ ] Keep dishwasher side and exact position as TBD unless confirmed.

## 7.5 Oven / Combi-Steam Door Swing

- [ ] Add provisional door-opening envelopes.
- [ ] Test user standing space and adjacent landing area.
- [ ] Test conflict with refrigerator doors and pantry circulation.
- [ ] Keep exact installation height and handle projection as assumptions.

## 7.6 Seating Pullback

- [ ] Add seating pullback only if seating is shown or intended.
- [ ] Keep number of seats, overhang, stool size, and circulation behind seats provisional.
- [ ] Test conflict with Kitchen-to-Living and Kitchen-to-Dining travel paths.

## 7.7 Pantry Access

- [ ] Test pantry-door operation.
- [ ] Test circulation with appliance doors or drawers open.
- [ ] Test tall-unit and filler projection near the opening.
- [ ] Test grocery transfer path.

## 7.8 Conflict Log

For each conflict, record:

| Conflict ID | Location | Elements involved | Source basis | Current status | Required decision |
|---|---|---|---|---|---|
| C-001 |  |  |  | OPEN |  |
| C-002 |  |  |  | OPEN |  |
| C-003 |  |  |  | OPEN |  |

---

# 8. Assumption Labels

## 8.1 Label Format

Use:

`ASSUMPTION A-### — [DESCRIPTION] — REQUIRES [OWNER] CONFIRMATION`

Example:

`ASSUMPTION A-012 — SOUTH R/F ZONE REPRESENTED AS SEPARATE REFRIGERATOR AND FREEZER COLUMNS — REQUIRES BOBBY CONFIRMATION`

## 8.2 Assumption Register

| Assumption ID | Location | Description | Reason | Who must confirm | Status |
|---|---|---|---|---|---|
| A-001 |  |  | Missing or conflicting source information |  | OPEN |
| A-002 |  |  | Missing or conflicting source information |  | OPEN |
| A-003 |  |  | Missing or conflicting source information |  | OPEN |
| A-004 |  |  | Missing or conflicting source information |  | OPEN |
| A-005 |  |  | Missing or conflicting source information |  | OPEN |

## 8.3 Allowed Statuses

- `OPEN`
- `CONFIRMED BY BOBBY`
- `CONFIRMED BY DESIGNER`
- `FIELD VERIFIED`
- `REQUIRES APPLIANCE MODEL`
- `REQUIRES ELDA REVIEW`
- `REJECTED / REVISED`

## 8.4 Assumptions That Must Be Logged

### Geometry

- [ ] provisional wall length;
- [ ] provisional wall thickness;
- [ ] provisional finished-face location;
- [ ] assumed ceiling height;
- [ ] assumed column or projection depth;
- [ ] assumed island dimensions;
- [ ] assumed island overhang;
- [ ] assumed finished aisle dimension;
- [ ] assumed dimension endpoints.

### Layout

- [ ] intended range location;
- [ ] intended refrigeration configuration;
- [ ] intended coffee / combi-steam location;
- [ ] intended dishwasher side;
- [ ] intended sink centerline;
- [ ] intended seating side;
- [ ] intended pantry cabinet scope;
- [ ] intended tall-unit grouping.

### Appliances

- [ ] nominal appliance width;
- [ ] approximate appliance height;
- [ ] approximate door swing;
- [ ] approximate handle projection;
- [ ] approximate service zone;
- [ ] assumed panel-ready or exposed condition;
- [ ] assumed appliance orientation.

### Cabinet System

- [ ] generic base-unit height;
- [ ] generic tall-unit height;
- [ ] generic carcass depth;
- [ ] provisional plinth height;
- [ ] provisional countertop thickness;
- [ ] provisional filler;
- [ ] provisional end-panel thickness;
- [ ] provisional opening-system geometry.

---

# 9. Bobby Review Scenes

## 9.1 `01_OVERALL_PLAN`

Show:

- [ ] Kitchen in relation to Living, Dining, Pantry, Office/Study, and stairs;
- [ ] primary circulation paths;
- [ ] overall room-shell context;
- [ ] major source conflicts only.

## 9.2 `02_KITCHEN_PLAN`

Show:

- [ ] island massing;
- [ ] range zone;
- [ ] refrigeration zones;
- [ ] tall appliance stack;
- [ ] sink / dishwasher zone;
- [ ] generic cabinet massing;
- [ ] key written dimensions and labeled assumptions.

## 9.3 `03_ISLAND_VIEW`

Show:

- [ ] island body;
- [ ] worktop reference;
- [ ] sink and dishwasher placeholders;
- [ ] possible seating / overhang;
- [ ] aisle envelopes;
- [ ] unresolved island-dimension assumptions.

## 9.4 `04_RANGE_WALL`

Show:

- [ ] nominal 48-inch range placeholder;
- [ ] adjacent cabinet masses;
- [ ] hood envelope;
- [ ] landing zones;
- [ ] relationship to the island;
- [ ] unresolved utility and clearance notes.

## 9.5 `05_TALL_APPLIANCE_REFRIGERATION_WALL`

Show:

- [ ] refrigerator placeholder(s);
- [ ] freezer placeholder;
- [ ] coffee-machine placeholder;
- [ ] combi-steam placeholder;
- [ ] tall-unit massing alternatives;
- [ ] door swings and service zones;
- [ ] open configuration questions.

## 9.6 `06_PANTRY_RELATIONSHIP`

Show:

- [ ] pantry opening;
- [ ] adjacent tall units or panels;
- [ ] traffic route;
- [ ] door and drawer conflicts;
- [ ] pantry-scope question.

## 9.7 `07_CLEARANCE_REVIEW`

Show:

- [ ] island aisles;
- [ ] range working zone;
- [ ] refrigerator / freezer swings;
- [ ] dishwasher swing;
- [ ] oven / combi-steam swing;
- [ ] seating pullback, if applicable;
- [ ] pantry access;
- [ ] conflict IDs.

## 9.8 `08_ASSUMPTIONS_OPEN_QUESTIONS`

Show:

- [ ] all assumption IDs;
- [ ] all open conflict IDs;
- [ ] unresolved dimensions;
- [ ] source conflicts;
- [ ] decisions required from Bobby;
- [ ] questions requiring architect, appliance, field, or Elda confirmation.

---

# 10. Export Package

## 10.1 PDF Views

Export a controlled PDF containing:

1. Cover / project identity
2. Source-control note
3. Overall plan
4. Kitchen plan
5. Island view
6. Range wall
7. Tall appliance / refrigeration wall
8. Pantry relationship
9. Clearance review
10. Assumptions / open questions

For each page:

- [ ] include the project name;
- [ ] include the SketchUp file version;
- [ ] include the export date;
- [ ] include the scene name;
- [ ] include the preliminary-design footer disclaimer.

## 10.2 Screenshots

Export high-resolution screenshots of:

- [ ] overall kitchen concept;
- [ ] island relationship;
- [ ] range wall;
- [ ] tall appliance / refrigeration wall;
- [ ] pantry relationship;
- [ ] clearance-conflict view;
- [ ] assumption-label view.

## 10.3 Assumption List

Export the current assumption register with:

- [ ] assumption ID;
- [ ] location;
- [ ] description;
- [ ] reason;
- [ ] responsible confirmer;
- [ ] status.

## 10.4 Questions List

Prepare a separate questions list organized by responsible party:

### Bobby

- layout direction;
- island function and seating;
- refrigeration configuration;
- tall appliance location and stacking;
- sink and dishwasher arrangement;
- pantry scope;
- aesthetic direction;
- decision authority.

### Architect / Designer

- governing kitchen plan;
- dimensional conflicts;
- finished wall locations;
- openings and pantry access;
- ceiling, soffit, beam, and projection conditions;
- coordination of the modified plan with permitted documents.

### Appliance Supplier / Manufacturer

- exact model numbers;
- current specification sheets;
- installation manuals;
- overall and cutout dimensions;
- utilities;
- ventilation;
- door swings and handle projections;
- service-access requirements;
- panel-ready requirements.

### Field Verification

- finished wall-to-wall dimensions;
- wall straightness and squareness;
- finished wall build-ups;
- ceiling and obstruction dimensions;
- opening and wall-return dimensions;
- island location and size;
- finished aisle dimensions.

### Elda / DzineElements — Later Gate Only

- applicable Cesar system and USA elements;
- supported appliance housings;
- required fillers and finished panels;
- ventilation and service-access requirements;
- front alignment and opening-system constraints;
- special-order conditions;
- current availability.

## 10.5 Disclaimer

### Full Disclaimer

> **PRELIMINARY DESIGN — NOT FOR PRODUCTION OR CONSTRUCTION**
>
> This SketchUp model and associated views are prepared solely for preliminary space planning, design discussion, appliance-location review, and coordination with Bobby, UCON, and Cesar / DzineElements. The package is based on currently available project information, including the modified kitchen plan, architectural drawings, visible appliance positions, preliminary appliance categories, and clearly identified assumptions. The available information has not been established as a complete, coordinated, field-verified, or production-ready project record.
>
> The model does not constitute a final Cesar cabinet layout, confirmation of Cesar module availability, an approved appliance-integration design, final appliance housing or cutout information, a fabrication drawing, an installation drawing, a construction document, an MEP coordination drawing, an order, a quotation, final client pricing, or approval for field rough-in or procurement.
>
> Appliance geometry is represented by preliminary placeholders based on nominal appliance categories only. Exact manufacturer model numbers, installation manuals, clearances, utilities, ventilation, service access, panel requirements, and cutout dimensions must be obtained and reviewed before technical development.
>
> All dimensions must be field verified. Written project dimensions take precedence over scaled drawing measurements. Any dimensions, locations, or configurations identified as assumptions remain subject to client, designer, architect, appliance-manufacturer, UCON, Cesar, and DzineElements review as applicable.
>
> Final cabinet modules, fillers, end panels, plinths, grip recesses, front divisions, appliance housings, ventilation provisions, and installation conditions must be confirmed through applicable Cesar technical documentation and Elda / DzineElements technical review.
>
> No cabinet order, appliance rough-in, fabrication, construction, or installation work should proceed from this preliminary package.

### Drawing Footer

> **PRELIMINARY CONCEPT ONLY — NOT FOR ORDER, FABRICATION, CONSTRUCTION, MEP ROUGH-IN, OR INSTALLATION. DIMENSIONS AND APPLIANCE MODELS REQUIRE FIELD AND TECHNICAL VERIFICATION. SUBJECT TO CESAR / DZINEELEMENTS REVIEW.**

---

# 11. Stop Conditions

Stop modeling and request clarification when any of the following occurs.

## 11.1 Geometry Stop Conditions

- [ ] A required wall, opening, column, return, or projection cannot be located from a written dimension.
- [ ] S1 and S2 show materially different kitchen geometry.
- [ ] The island size or position cannot be tested without inventing dimension endpoints.
- [ ] Pantry access depends on an unresolved opening or door condition.
- [ ] Ceiling, soffit, beam, or obstruction geometry materially affects the concept but is not established.
- [ ] A modeled aisle depends on scaling rather than a written dimension.

## 11.2 Layout Stop Conditions

- [ ] The refrigeration configuration cannot be represented without choosing between unsupported alternatives.
- [ ] The coffee / combi-steam location is not identifiable from the sources or Bobby’s direction.
- [ ] The sink / dishwasher arrangement requires an invented sequence or centerline.
- [ ] The island function, seating, or overhang materially changes the circulation strategy and has not been confirmed.
- [ ] Pantry cabinetry scope changes the main kitchen layout and has not been confirmed.

## 11.3 Appliance Stop Conditions

- [ ] Exact appliance dimensions are required to determine whether the concept works.
- [ ] Door swing, handle projection, ventilation, service access, or utilities materially affect the layout.
- [ ] A final niche, cutout, housing, or panel condition would need to be modeled.
- [ ] The hood concept requires a confirmed model, duct route, or makeup-air strategy.
- [ ] The refrigerator / freezer arrangement requires final hinge direction or internal-pullout clearances.

## 11.4 MEP Stop Conditions

- [ ] The modified kitchen plan conflicts with the permitted MEP layout.
- [ ] Range gas or electrical location controls the range position.
- [ ] Coffee-machine or combi-steam water, drain, electrical, or ventilation requirements control the stack location.
- [ ] Hood duct routing or makeup air controls the range-wall design.
- [ ] Sink and dishwasher utilities control the island configuration.
- [ ] Island receptacles or lighting controls conflict with the proposed massing.

## 11.5 Cesar Technical Stop Conditions

- [ ] A decision requires a final Cesar module.
- [ ] A decision requires a Cesar item code.
- [ ] A decision requires confirmed current availability.
- [ ] A decision requires a final collection or opening system.
- [ ] A decision requires production fillers, panels, plinths, grip recesses, or front divisions.
- [ ] A decision requires a final appliance housing or ventilation solution.

## 11.6 Documentation Stop Conditions

- [ ] The model could be mistaken for a production drawing.
- [ ] Assumptions are not visible or traceable.
- [ ] The source controlling a geometry item is unclear.
- [ ] Conflicts are being resolved informally without a decision record.
- [ ] The export would omit the preliminary-design disclaimer.

---

# Completion Gate

The preliminary SketchUp modeling pass is complete only when:

- [ ] the room shell is modeled from controlled sources;
- [ ] the modified kitchen concept is overlaid without silent conflict resolution;
- [ ] all appliances are represented only by named placeholders;
- [ ] cabinet geometry remains generic massing;
- [ ] clearance envelopes are visible;
- [ ] every unsupported decision has an assumption ID;
- [ ] Bobby review scenes are complete;
- [ ] the PDF and screenshot package is exported;
- [ ] the assumption and questions lists are included;
- [ ] the disclaimer appears on the package;
- [ ] the model is clearly identified as preliminary and not production-ready.

**Current gate:** Approved for controlled preliminary SketchUp concept modeling only.  
**Not approved for:** Final Cesar module assignment, appliance integration, MEP rough-in, quotation, ordering, fabrication, construction, or installation.

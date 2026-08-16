# Cesar Kitchen Quick Start v0.2

## Purpose

This guide contains the minimum source-based rules needed to begin a **preliminary SketchUp block layout** for a Southern California Cesar kitchen pilot.

It is not a production specification, order guide, complete module library, or confirmation of current availability. The model must remain subject to Cesar / DzineElements technical review.

## Source hierarchy used

1. `CESAR - 2 Kitchen System(2).pdf` - primary dimensional and module source.
2. `CESAR - 1 Project Guidelines(2).pdf` - supporting source for collection, grip-recess, plinth, and order-governance logic.
3. `Cesar_Source_Register_Initial_Map_v0.1` - source-use framework.
4. `Pilot_Extraction_Scope_Bobby_v0.1` - pilot-scope and extraction-control framework.

## 1. Start with a controlled SketchUp component structure

Create separate component classes before placing cabinets:

- `BASE_CARCASS`
- `WALL_CARCASS`
- `TALL_CARCASS`
- `APPLIANCE_OPENING`
- `FILLER_CLOSING_STRIP`
- `END_PANEL`
- `PLINTH`
- `GRIP_RECESS`
- `WORKTOP_REFERENCE`

Do not model a cabinet as one fused object. Cesar treats carcasses, fillers, end elements, plinths, grip recesses, handles, and tops as separate planning and pricing elements. The catalog repeatedly states that tops, upstands, plinths, grip recesses, and handles are not included with the cabinet item.  
**Source:** `CESAR - 2 Kitchen System(2).pdf`, Maxima / Intarsio / Tangram base and tall unit overview sections, printed pp. 19 and 78-79; USA Elements introduction, printed p. 409.

---

## 2. Global height logic for the preliminary block model

### 2.1 Base-unit carcass heights

The Maxima / Intarsio / Tangram schedules identify the following base-unit height families:

| Base-unit family | Carcass height |
|---|---:|
| Low base | 39 cm |
| Low base | 48 cm |
| Intermediate base | 58.5 cm |
| Standard base | 78 cm |
| High base | 84 cm |

Sink bases and appliance bases appear as separate categories within these height families. Do not assume that every configuration exists at every height.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Maxima / Intarsio / Tangram, Base Units overview, printed pp. 19-22.

### 2.2 Wall-unit carcass heights

The Maxima / Intarsio / Tangram wall-unit schedules identify these principal wall-unit heights:

- 36 cm
- 48 cm
- 60 cm
- 72 cm
- 84 cm
- 96 cm
- 120 cm

Dish-drainer and hood wall units are listed separately. Do not treat the height list as confirmation that every opening type, width, or hood configuration is available at every height.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Maxima / Intarsio / Tangram, Wall Units overview and schedules, printed pp. 205-210.

### 2.3 Tall-unit carcass heights

The Maxima / Intarsio / Tangram schedules identify these principal tall-unit heights:

- 138 cm
- 198 cm
- 210 cm
- 222 cm
- 234 cm

The catalog also distinguishes tall units aligned with 78 cm and 84 cm base-unit systems. That alignment affects front divisions and appliance-opening composition; it is not merely a change in total cabinet height.

Top elements are separately listed at 36, 48, 60, and 72 cm and are noted as being supplied without fixings.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Maxima / Intarsio / Tangram, Tall Units overview, printed approximately pp. 78-80.

### SketchUp rule

Use the carcass height as the cabinet block height. Add plinth, grip-recess, and worktop geometry separately. Do not use a single assumed “finished counter height” until the opening system and plinth are selected.

---

## 3. Standard depth logic

### 3.1 Base units

The Maxima / Intarsio / Tangram schedules show base-unit depth families including:

- 35 cm
- 47 cm
- 62 cm
- 67 cm

Some schedules reference increased side-panel depths of 67, 72, and 77 cm as modifications. These are not automatically interchangeable with standard carcass depth.

For the preliminary pilot, use **62 cm as the first check for full-depth kitchen base units**, but do not apply it universally. Confirm the exact item schedule, especially for appliance, sink, corner, and increased-depth conditions.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Maxima / Intarsio / Tangram, Base Units schedules, printed pp. 20-22; Modifications and Customisations cross-reference shown in the schedules.

### 3.2 Wall units

The principal wall-unit schedule uses:

- 35 cm depth for most standard wall units.
- 57 cm depth for specific deeper wall-unit configurations.

Do not use 57 cm as a general wall-unit depth. It appears only on selected items.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Maxima / Intarsio / Tangram, Wall Units schedules, printed pp. 206-210.

### 3.3 Tall units

The principal tall-unit schedule shows:

- 35 cm depth for selected shallow tall units.
- 62 cm depth for standard full-depth tall units.

The catalog states that 35 cm deep tall units must be fixed to the wall.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Maxima / Intarsio / Tangram, Tall Units overview and schedules, printed approximately pp. 78-80.

### SketchUp rule

Keep three depth fields in each component:

1. `CARCASS_DEPTH`
2. `VISIBLE_SIDE_PANEL_DEPTH`
3. `FINISHED_PROJECTION`

The source does not support treating those three values as automatically identical.

---

## 4. Common module-width logic

### 4.1 Metric planning grid

The schedules repeatedly use a 15 cm planning rhythm. Common widths include:

- 15 cm
- 30 cm
- 45 cm
- 60 cm
- 75 cm
- 90 cm
- 105 cm
- 120 cm

Selected compound, horizontal, corner, and special units extend beyond this sequence, including widths such as 150, 180, and 240 cm. Those larger sizes are item-specific and must not be treated as generic single-carcass widths.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Maxima / Intarsio / Tangram base and wall unit schedules, printed pp. 20-22 and 206-210.

### 4.2 Do not create a universal width menu

Width availability depends on all of the following:

- collection;
- cabinet family;
- height;
- depth;
- opening type;
- drawer or door configuration;
- appliance condition;
- front material;
- corner geometry.

The correct SketchUp workflow is to create a **restricted component schedule for the selected pilot collection**, not a generic Cesar width dropdown.

### 4.3 Corner units are footprint modules

Corner units must be modeled by their complete footprint, not by door width alone. Examples in the technical section include different footprints for 30, 45, and 60 cm doors and for 62 or 67 cm depth systems.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Technical and Dimensional Information, printed pp. 10-11.

---

## 5. USA Elements - check this before laying out appliances

The USA Elements section must be reviewed before the standard European module schedule is used for any North American appliance.

### 5.1 First checks

For every appliance, check:

1. Does a matching item appear in USA Elements?
2. Is it tied to a 78 cm or 84 cm base system?
3. Is it tied to a specific tall-unit height?
4. Is the width metric-standard or an inch-derived USA width?
5. Is the item a complete cabinet, a front/door package, or an appliance-specific insert condition?
6. Are the fronts custom-sized?
7. Does the item require a specific depth, divider, shelf, metal bottom, drawer, or ventilation condition?

### 5.2 USA width signals found

The USA section includes inch-derived metric widths such as:

- 45.7 cm = 18 in
- 61 cm = 24 in
- 76.2 cm = 30 in
- 91.4 cm = 36 in

It also shows appliance-related widths including 106.7 cm and 121.9 cm for selected base-unit conditions.

These widths are not a replacement for the normal metric grid. They are appliance-specific USA elements.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, USA Elements summary and schedules, printed pp. 409-419.

### 5.3 Items visible in the USA section

The section includes, among other conditions:

- base units for built-in ovens;
- countertop-hob base units;
- fronts/doors for USA refrigerators;
- tall oven units;
- tall oven plus microwave/double-oven units;
- USA refrigerator and wine-cooler fronts.

The section does not by itself confirm compatibility with Bobby's actual appliances.

### Pilot rule

Do not draw a refrigerator, range, oven stack, dishwasher, or undercounter appliance from nominal market width alone. Obtain the exact appliance model and compare:

- Cesar USA element;
- appliance installation manual;
- door swing and pullout clearance;
- ventilation requirement;
- panel thickness and attachment method;
- required fillers and finished side panels.

**Appliance model list:** Not found in provided sources.

---

## 6. Fillers and end panels must be separate components

### 6.1 They perform different functions

A filler or closing strip controls:

- wall clearance;
- door and drawer opening angle;
- handle collision;
- pullout operation;
- refrigerator-door and internal-drawer access;
- corner mechanism clearance;
- out-of-square wall absorption.

An end panel controls:

- visible finished side condition;
- collection-specific edge treatment;
- depth build-out;
- grip-recess termination;
- appliance or island side composition.

They are not interchangeable.

### 6.2 Source-based clearance rules

The technical section states:

- Minimum corner filler for push-pull or grip recess: **5 x 5 cm**.
- Minimum corner filler for Frame grip edging: **6 x 6 cm**.
- Handle conditions depend on handle model and position.
- Corner base units adjacent to drawer units, jumbo drawers, or dishwashers require **8 x 8 cm fillers**, or a custom-sized corner base unit.
- A wall unit with a `D` handle adjacent to a tall unit or wall should have at least a **5 cm closing strip** for full opening.
- A tall refrigerator unit adjacent to a wall requires a minimum **5 cm closing strip** for full door opening and internal-drawer extraction.
- A corner tall unit with `D` handles should have a minimum **5 cm closing strip** between it and the adjacent base or tall unit.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Technical and Dimensional Information, printed pp. 10-12.

### 6.3 Filler product range

The Maxima / Intarsio filler section lists fillers in door finishes from **2.3 to 15 cm**, with a noted minimum of **5 cm for Groove**. Base-unit and wall-unit filler products are separately scheduled.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Fillers, End Elements and Open Units, printed pp. 433-435.

### SketchUp rule

Each filler must have its own:

- width;
- height;
- depth;
- finish class;
- location;
- reason code: `WALL`, `HANDLE`, `FRIDGE_SWING`, `CORNER`, `OUT_OF_SQUARE`, or `ALIGNMENT`.

Never stretch the adjacent cabinet to absorb a filler unless a specific custom-size rule is confirmed.

---

## 7. Plinth and grip-recess items affecting elevation height

### 7.1 Plinth heights found

The Kitchen System plinth schedule identifies:

- 6 cm aluminium plinth;
- 10 cm aluminium plinth;
- 10 cm PVC plinth.

Front and side plinths are separately scheduled by depth and height.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, Plinths, printed pp. 624-626.

### 7.2 Grip-recess geometry found

The catalog provides separate L-shaped and Straight grip-recess systems. The diagrams show distinct undercounter, intermediate horizontal, vertical end, and intermediate vertical profiles.

Planning dimensions shown in the cross-sections include:

- 3 cm grip-recess profile dimension;
- 5.7 cm undercounter grip-recess zone;
- 7.3 cm intermediate grip-recess zone;
- 4.8 cm vertical end condition;
- 6.6 cm intermediate vertical condition.

These dimensions describe the grip-recess assembly geometry and must not be interpreted as additional cabinet carcass height without reviewing the selected system and elevation stack.

**Source:** `CESAR - 2 Kitchen System(2).pdf`, L-shaped Grip Recess, printed p. 615; Straight Grip Recess, printed p. 620.

### 7.3 Elevation build-up rule

Build the preliminary vertical stack as separate parameters:

`FINISHED_BASE_ELEVATION = PLINTH + BASE_CARCASS + GRIP_RECESS / OPENING_ZONE + WORKTOP`

Do not combine these values into one fixed standard. The selected opening system determines whether an undercounter or intermediate grip-recess zone is present.

### 7.4 Height alignment warning

The catalog distinguishes cabinet configurations “for base unit H. 78” and “for base unit H. 84.” This affects tall-unit and appliance-front alignment. Therefore, the base system must be selected before finalizing tall-unit elevations.

---

## 8. Minimum preliminary SketchUp workflow

### Step 1 - Lock project geometry

Required before layout validation:

- field dimensions;
- finished wall locations;
- ceiling and soffit heights;
- door and window openings;
- plumbing, electrical, gas, and duct locations;
- exact appliance models.

**Status:** Not found in provided sources.

### Step 2 - Obtain collection decision

Do not mix Maxima, Intarsio, Tangram, Unit, N_Elle, or other system schedules.

### Step 3 - Select one base-height system

Use either the source-supported 78 cm or 84 cm base family unless the pilot specifically requires a lower system. Add the selected plinth and worktop separately.

### Step 4 - Place full-depth blocks

Start with source-supported cabinet blocks only. For a typical full-depth run, test 62 cm depth first, then verify each item and visible side-panel depth.

### Step 5 - Resolve USA appliance modules

Check the USA section before setting appliance bays.

### Step 6 - Add operational clearances

Add fillers and closing strips as explicit geometry. Test:

- door swing;
- drawer and pullout extraction;
- refrigerator internal drawers;
- corner mechanisms;
- dishwasher adjacency;
- handles and grip recesses.

### Step 7 - Build elevation stack

Add plinth, carcass, grip-recess/opening zones, and worktop separately.

### Step 8 - Prepare the review package

The review package should include:

- plan;
- principal elevations;
- module schedule;
- appliance schedule;
- filler schedule;
- end-panel schedule;
- assumptions list;
- unresolved questions;
- source page for each selected module.

---

## 9. Needs Elda confirmation

The following items must remain unresolved until Elda / DzineElements confirms them:

1. **Pilot collection and door family.**
2. **Opening system:** handle, push-pull, L-shaped grip recess, Straight grip recess, Frame, or another permitted system.
3. **Base-height system:** 78 cm, 84 cm, or another project-specific family.
4. **Selected plinth height and finish.**
5. **Exact appliance models and which require USA Elements.**
6. **Current production availability of every selected item.**
7. **Current validity of the catalog dimensions, codes, finishes, and restrictions.**
8. **Whether 62 cm or increased-depth 67 / 72 / 77 cm conditions are required.**
9. **Approved wall-unit height and top alignment.**
10. **Tall-unit height and alignment with the selected base system.**
11. **Required filler widths at walls, corners, appliances, and handle-conflict locations.**
12. **Finished end-panel type, thickness, depth, and edge condition.**
13. **Appliance-panel construction and attachment method.**
14. **Ventilation and service-clearance requirements not fully defined by the Cesar cabinet schedule.**
15. **Whether any custom-size or modification request is factory-feasible.**
16. **Whether the listed USA elements cover the complete Southern California appliance package.**
17. **Current commercial terms, pricing, freight, tariffs, tax, lead time, and responsibility split.**

---

## 10. Preliminary-model disclaimer

The SketchUp model created from this guide is for block planning, collision review, appliance coordination, and quote-request preparation only.

It is not production-ready order information. Final item codes, dimensions, fronts, fillers, end panels, grip recesses, plinths, appliance openings, ventilation, modifications, finishes, pricing, and availability require Cesar / DzineElements written technical confirmation.

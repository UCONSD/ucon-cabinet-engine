# Minimum SketchUp Component Schedule v0.1

**Purpose:** Restricted generic component library for preliminary Cesar kitchen block modeling before Elda confirms the collection.

**Status:** Preliminary planning only. Not production-ready order information. No final Cesar item codes are included. Every component remains subject to Cesar / DzineElements technical review.

This schedule is derived from Cesar_Kitchen_Quick_Start_v0.2.md and must be updated after Elda confirms the collection, appliance list, opening system, base height, and plinth.

**Operating guide:** `Cesar_Kitchen_Quick_Start_v0.2.md`

## Modeling rules

- Keep carcasses, fillers, end panels, plinths, grip-recess references, and appliance placeholders as separate components.
- Use carcass height as the cabinet block height. Add plinth, grip-recess zone, and worktop separately.
- Keep `CARCASS_DEPTH`, `VISIBLE_SIDE_PANEL_DEPTH`, and `FINISHED_PROJECTION` as separate parameters.
- The widths below are planning options, not confirmation that every width is available for every collection, height, opening type, front, or appliance condition.
- Component status tag: `PRELIMINARY - NEEDS ELDA CONFIRMATION`.

---

## Component schedule

| Component name | Type | W / H / D in mm | Adjustable parameters | Source basis | Status | Notes |
|---|---|---:|---|---|---|---|
| `BASE_STD_780_D620` | Base block | W: 300 / 450 / 600 / 750 / 900 / 1050 / 1200; H: 780; D: 620 | `WIDTH`, `CARCASS_DEPTH`, `VISIBLE_SIDE_PANEL_DEPTH`, `FINISHED_PROJECTION`, `OPENING_TYPE`, `FRONT_DIVISION` | Quick Start §§2.1, 3.1, 4.1; Kitchen System pp. 19-22 | Preliminary / needs Elda confirmation | Primary generic conventional base block. Width availability is not universal. |
| `BASE_STD_840_D620` | Base block | W: 300 / 450 / 600 / 750 / 900 / 1050 / 1200; H: 840; D: 620 | Same as above plus `BASE_SYSTEM=840` | Quick Start §§2.1, 3.1, 4.1; Kitchen System pp. 19-22 | Preliminary / needs Elda confirmation | Use only as a separate 840 mm vertical system; do not mix front alignment casually with 780 mm bases. |
| `BASE_NARROW_REFERENCE` | Base block | W: 150; H: 780 or 840; D: 620 | `HEIGHT`, `OPENING_TYPE`, `FUNCTION` | Quick Start §4.1; Kitchen System base schedules pp. 20-22 | Preliminary / needs Elda confirmation | Width appears in the planning rhythm, but configuration restrictions are significant. Do not assume pullout availability. |
| `BASE_SHALLOW_REFERENCE` | Base block | W: TBD by selected supported item; H: 780 or 840; D: 350 or 470 | `WIDTH`, `HEIGHT`, `DEPTH`, `WALL_FIXING_REQUIRED` | Quick Start §3.1; Kitchen System pp. 20-22 | Preliminary / needs Elda confirmation | Reference only for explicitly supported shallow conditions; not the default kitchen base. |
| `WALL_STD_D350` | Wall block | W: 300 / 450 / 600 / 750 / 900 / 1050 / 1200; H: 360 / 480 / 600 / 720 / 840 / 960 / 1200; D: 350 | `WIDTH`, `HEIGHT`, `OPENING_TYPE`, `HINGE_SIDE`, `FINISHED_PROJECTION` | Quick Start §§2.2, 3.2, 4.1; Kitchen System pp. 205-210 | Preliminary / needs Elda confirmation | Default wall-block reference. Actual width/height/opening combinations must be checked. |
| `WALL_DEEP_REFERENCE_D570` | Wall block | W: TBD by selected item; H: 360-1200; D: 570 | `WIDTH`, `HEIGHT`, `OPENING_TYPE`, `APPLICATION` | Quick Start §3.2; Kitchen System pp. 206-210 | Preliminary / needs Elda confirmation | Selected deeper wall-unit configurations only. Do not use as a general wall depth. |
| `TALL_STD_D620` | Tall block | W: 300 / 450 / 600 / 750 / 900 / 1050 / 1200; H: 1380 / 1980 / 2100 / 2220 / 2340; D: 620 | `WIDTH`, `HEIGHT`, `BASE_ALIGNMENT_780_840`, `OPENING_TYPE`, `APPLIANCE_ZONE`, `FRONT_DIVISION` | Quick Start §§2.3, 3.3, 4.1; Kitchen System pp. 78-80 | Preliminary / needs Elda confirmation | Generic full-depth tall mass. Front divisions and appliance openings depend on selected system. Use as massing placeholders only; actual tall-unit widths must be selected from the applicable tall-unit schedule after collection confirmation. |
| `TALL_SHALLOW_D350` | Tall block | W: TBD by supported item; H: 1380 / 1980 / 2100 / 2220 / 2340; D: 350 | `WIDTH`, `HEIGHT`, `WALL_FIXING`, `OPENING_TYPE` | Quick Start §3.3; Kitchen System pp. 78-80 | Preliminary / needs Elda confirmation | Shallow tall units must be fixed to the wall. |
| `TALL_TOP_ELEMENT_REFERENCE` | Tall/top block | W: match tall block; H: 360 / 480 / 600 / 720; D: match selected tall depth | `WIDTH`, `HEIGHT`, `DEPTH`, `FIXING_METHOD` | Quick Start §2.3; Kitchen System pp. 78-80 | Preliminary / needs Elda confirmation | Separate top element; catalog notes these are supplied without fixings. |
| `FILLER_STRAIGHT_GENERIC` | Filler / closing strip | W: 23-150; H: match adjacent block; D: match adjacent carcass or finished projection | `WIDTH`, `HEIGHT`, `DEPTH`, `FINISH_CLASS`, `LOCATION`, `REASON_CODE` | Quick Start §6.3; Kitchen System pp. 433-435 | Preliminary / needs Elda confirmation | Keep separate from cabinet. Groove conditions note a 50 mm minimum in specified cases. |
| `CLOSING_STRIP_50_REFERENCE` | Filler / closing strip | W: 50 minimum reference; H: match adjacent block; D: match adjacent condition | `WIDTH`, `HEIGHT`, `DEPTH`, `HINGE_SIDE`, `REASON_CODE` | Quick Start §6.2; Kitchen System pp. 10-12 | Preliminary / needs Elda confirmation | Reference for wall-unit/tall-unit adjacency, tall refrigerator at wall, and stated D-handle conflicts. Increase if required by actual hardware. |
| `CORNER_FILLER_GRIP_50x50` | Corner filler | W: 50; H: match run; D/return: 50 | `LEG_A`, `LEG_B`, `HEIGHT`, `OPENING_SYSTEM` | Quick Start §6.2; Kitchen System pp. 10-11 | Preliminary / needs Elda confirmation | Minimum reference for push-pull or grip-recess corner condition. |
| `CORNER_FILLER_FRAME_60x60` | Corner filler | W: 60; H: match run; D/return: 60 | `LEG_A`, `LEG_B`, `HEIGHT` | Quick Start §6.2; Kitchen System p. 10 | Preliminary / needs Elda confirmation | Minimum reference for Frame grip edging. |
| `CORNER_FILLER_ADJACENCY_80x80` | Corner filler | W: 80; H: match base run; D/return: 80 | `LEG_A`, `LEG_B`, `HEIGHT`, `ADJACENT_UNIT_TYPE` | Quick Start §6.2; Kitchen System p. 10 | Preliminary / needs Elda confirmation | Reference where corner base is adjacent to drawers, jumbo drawers, or dishwasher, unless a custom-size corner unit is approved. |
| `END_PANEL_BASE_GENERIC` | End panel | W/thickness: TBD; H: 780 or 840 plus selected vertical terminations as applicable; D: 620 / 670 / project-specific | `THICKNESS`, `HEIGHT`, `DEPTH`, `EDGE_CONDITION`, `GRIP_TERMINATION`, `PLINTH_RETURN` | Quick Start §§3.1, 6.1; Kitchen System pp. 436-449 | Preliminary / needs Elda confirmation | Panel thickness and collection-specific geometry are not confirmed. Do not assume carcass depth equals visible panel depth. |
| `END_PANEL_WALL_GENERIC` | End panel | W/thickness: TBD; H: match wall block; D: 350 or selected finished projection | `THICKNESS`, `HEIGHT`, `DEPTH`, `EDGE_CONDITION` | Quick Start §§3.2, 6.1; Kitchen System pp. 436-449 | Preliminary / needs Elda confirmation | Separate visible-side component. |
| `END_PANEL_TALL_GENERIC` | End panel | W/thickness: TBD; H: 1380 / 1980 / 2100 / 2220 / 2340; D: 620 / 670 / project-specific | `THICKNESS`, `HEIGHT`, `DEPTH`, `EDGE_CONDITION`, `APPLIANCE_SIDE_CONDITION` | Quick Start §§3.3, 6.1; Kitchen System pp. 436-449 | Preliminary / needs Elda confirmation | Use for exposed tall ends and appliance-side compositions. |
| `PLINTH_FRONT_H60` | Plinth block | W: adjustable by run; H: 60; D/thickness: TBD | `LENGTH`, `HEIGHT`, `SETBACK`, `THICKNESS`, `FINISH`, `VENTING` | Quick Start §7.1; Kitchen System pp. 624-626 | Preliminary / needs Elda confirmation | Aluminium plinth height found. Keep separate from carcass. |
| `PLINTH_FRONT_H100` | Plinth block | W: adjustable by run; H: 100; D/thickness: TBD | Same as above | Quick Start §7.1; Kitchen System pp. 624-626 | Preliminary / needs Elda confirmation | Aluminium and PVC 100 mm plinths are listed. Material/finish not confirmed. |
| `PLINTH_SIDE_RETURN` | Plinth block | W/length: match panel or cabinet depth; H: 60 or 100; D/thickness: TBD | `RETURN_LENGTH`, `HEIGHT`, `SETBACK`, `THICKNESS`, `FINISH` | Quick Start §7.1; Kitchen System pp. 624-626 | Preliminary / needs Elda confirmation | Side plinths are separately scheduled by depth and height. |
| `GRIP_UNDERCOUNTER_REF` | Grip recess reference | W: adjustable by run; H zone: 57; D/profile: 30 reference | `LENGTH`, `ZONE_HEIGHT`, `PROFILE_DEPTH`, `END_CONDITION`, `FINISH` | Quick Start §7.2; Kitchen System p. 615 | Preliminary / needs Elda confirmation | Reference geometry only. Do not automatically add 57 mm to every carcass stack. |
| `GRIP_INTERMEDIATE_REF` | Grip recess reference | W: adjustable by run; H zone: 73; D/profile: 30 reference | Same as above plus `VERTICAL_POSITION` | Quick Start §7.2; Kitchen System p. 615 | Preliminary / needs Elda confirmation | Intermediate horizontal grip-recess reference. |
| `GRIP_VERTICAL_END_REF` | Grip recess reference | W/profile zone: 48; H: adjustable by composition; D: project/system-specific | `HEIGHT`, `PROFILE_ZONE`, `HANDING`, `END_PANEL_INTERFACE` | Quick Start §7.2; Kitchen System p. 615 | Preliminary / needs Elda confirmation | Vertical end-condition reference, not a final profile specification. |
| `GRIP_VERTICAL_INTERMEDIATE_REF` | Grip recess reference | W/profile zone: 66; H: adjustable by composition; D: project/system-specific | `HEIGHT`, `PROFILE_ZONE`, `ADJACENT_COMPONENTS` | Quick Start §7.2; Kitchen System p. 615 | Preliminary / needs Elda confirmation | Intermediate vertical-condition reference. |
| `USA_APPL_DW_24_PLACEHOLDER` | USA appliance placeholder | W: 610; H: exact model envelope TBD; D: exact model envelope TBD | `MODEL`, `CUTOUT_W/H/D`, `DOOR_SWING`, `PANEL_THICKNESS`, `VENTILATION`, `SERVICE_CLEARANCE` | Quick Start §5.2-5.3; Kitchen System USA Elements pp. 409-419 | Preliminary / needs Elda confirmation | Nominal 24 in width signal only. Exact dishwasher model and Cesar integration condition are not found. |
| `USA_APPL_OVEN_30_PLACEHOLDER` | USA appliance placeholder | W: 762; H: exact model envelope TBD; D: exact model envelope TBD | `MODEL`, `CUTOUT_W/H/D`, `INSTALL_HEIGHT`, `VENTILATION`, `TRIM`, `ELECTRICAL_CLEARANCE` | Quick Start §5.2-5.3; Kitchen System USA Elements pp. 409-419 | Preliminary / needs Elda confirmation | Use only as an appliance-zone placeholder. Do not treat as a confirmed Cesar oven cabinet. |
| `USA_APPL_RANGE_30_PLACEHOLDER` | USA appliance placeholder | W: 762; H: exact model envelope TBD; D: exact model envelope TBD | `MODEL`, `BODY_W/H/D`, `DOOR_CLEARANCE`, `GAS_ELECTRICAL`, `BACKGUARD`, `VENTILATION` | Quick Start §5.2 plus pilot appliance rule | Preliminary / needs Elda confirmation | Nominal planning block only; exact range model not found in provided sources. |
| `USA_APPL_RANGE_36_PLACEHOLDER` | USA appliance placeholder | W: 914; H: exact model envelope TBD; D: exact model envelope TBD | Same as above | Quick Start §5.2 plus pilot appliance rule | Preliminary / needs Elda confirmation | Nominal 36 in planning block only. |
| `USA_APPL_REF_36_PLACEHOLDER` | USA appliance placeholder | W: 914; H: exact model envelope TBD; D: exact model envelope TBD | `MODEL`, `BODY_W/H/D`, `DOOR_SWING`, `HANDLE_PROJECTION`, `INTERNAL_DRAWER_CLEARANCE`, `VENTILATION`, `PANEL_METHOD` | Quick Start §§5.2-5.3, 6.2; Kitchen System pp. 409-419 and 10-12 | Preliminary / needs Elda confirmation | Reserve a separate closing strip at walls; 50 mm is the source-based minimum reference for stated refrigerator-wall conditions. |
| `USA_APPL_UNDERCOUNTER_18_PLACEHOLDER` | USA appliance placeholder | W: 457; H: exact model envelope TBD; D: exact model envelope TBD | `MODEL`, `CUTOUT_W/H/D`, `VENTILATION`, `DOOR_SWING`, `PANEL_METHOD` | Quick Start §5.2; Kitchen System USA Elements pp. 409-419 | Preliminary / needs Elda confirmation | Nominal 18 in width signal; may represent wine cooler or other undercounter condition only after model confirmation. |
| `USA_APPL_UNDERCOUNTER_24_PLACEHOLDER` | USA appliance placeholder | W: 610; H: exact model envelope TBD; D: exact model envelope TBD | Same as above | Quick Start §5.2; Kitchen System USA Elements pp. 409-419 | Preliminary / needs Elda confirmation | Nominal 24 in placeholder. |
| `USA_APPL_SPECIAL_42_REFERENCE` | USA appliance placeholder | W: 1067; H: exact model envelope TBD; D: exact model envelope TBD | `MODEL`, `APPLICATION`, `BODY_W/H/D`, `CLEARANCES` | Quick Start §5.2; Kitchen System USA Elements pp. 409-419 | Preliminary / needs Elda confirmation | Inch-derived special width appears in selected USA base-unit conditions; application must be verified. |
| `USA_APPL_SPECIAL_48_REFERENCE` | USA appliance placeholder | W: 1219; H: exact model envelope TBD; D: exact model envelope TBD | Same as above | Quick Start §5.2; Kitchen System USA Elements pp. 409-419 | Preliminary / needs Elda confirmation | Inch-derived special width appears in selected USA base-unit conditions; application must be verified. |

---

## Required component metadata

Every SketchUp component should carry these attributes:

- `COMPONENT_CLASS`
- `COMPONENT_NAME`
- `WIDTH_MM`
- `HEIGHT_MM`
- `CARCASS_DEPTH_MM`
- `VISIBLE_SIDE_PANEL_DEPTH_MM`
- `FINISHED_PROJECTION_MM`
- `BASE_SYSTEM_780_840`
- `OPENING_TYPE`
- `HINGE_SIDE`
- `APPLIANCE_MODEL`
- `SOURCE_BASIS`
- `STATUS`
- `ASSUMPTION_NOTE`

## Controlled dropdowns

### Status

- `PRELIMINARY`
- `NEEDS_ELDA_CONFIRMATION`
- `CONFIRMED_BY_ELDA`
- `REJECTED_OR_REVISED`

### Filler reason code

- `WALL`
- `HANDLE`
- `FRIDGE_SWING`
- `CORNER`
- `DISHWASHER_ADJACENCY`
- `OUT_OF_SQUARE`
- `ALIGNMENT`

## Excluded from v0.1

- Final Cesar item codes
- Full cabinet configuration library
- Drawer and door subdivision catalog
- Corner cabinet mechanisms
- Sink-base details
- Hood cabinets
- Appliance-specific cabinet construction
- Collection-specific panels and shaped ends
- Custom modifications
- Pricing and commercial terms

## Elda confirmation gate

Before converting any generic block into a quote-request module, confirm:

1. Collection and door family.
2. Opening system.
3. Base-height system: 780 mm or 840 mm.
4. Plinth height and finish.
5. Exact appliance manufacturer and model numbers.
6. Current USA Elements compatibility.
7. Current production availability.
8. Exact filler requirements.
9. End-panel thickness, depth, edge, and grip termination.
10. Tall-unit height and front alignment.


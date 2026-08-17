# Element naming convention spec v0.1 — 2026-08-16

Grounded in a real deliverable: `Bobby_410_Alta_Vista_Preliminary_Layout_v0.2`
sheet 7/9 "Custom Elements" (Dadvar Residence, Cabinetry Edit). NOT YET
IMPLEMENTED — this is the exporter's core job (M1.10) and the identity for
non-catalog elements.

## Why this matters

For a catalog unit the identity is the article code (B80601). For a
NON-catalog element (modified, bespoke, appliance placeholder, filler) there
is no code — the STRUCTURED NAME is the identity, and it is what the factory
reads to re-model the element (in Metron, then production software). The whole
"don't complicate the factory's life" goal depends on that name being
consistent and complete.

## The insight

On the real sheet the names are hand-typed and slightly inconsistent (W_H_D
vs W_D_H order, spaces vs underscores, varying param sets). THE ENGINE SHOULD
GENERATE THESE NAMES automatically from a unit's attributes — machine
consistency is exactly what removes the ambiguity a hand-typed name
introduces. A person forgets a param or reorders letters; the generator does
not.

## Observed grammar (from the real sheet)

```
CESAR_CUSTOM_UPPER_W1067_H600_D620_DOUBLE_DOOR   modified Cesar (non-std width)
OWU_W610_H186_D620_C18_B4_PRELIMINARY            open wall unit + carcass/back t + status
UCON_Single_Front_W1150_H969_T19                 UCON bespoke front + thickness
UCON_Cesar_Island_Back_W1200_D350_H780_2D        repurposed Cesar unit
DACOR_42_FOUR_DOOR_PANEL_READY_PLACEHOLDER       appliance placeholder (client fridge)
UCON Miele CVA 7845 Lower Filler 9837350         filler w/ code, for an appliance
```

## Proposed standardized convention (to converge on)

`<ORIGIN>_<TYPE>_W<w>_H<h>_D<d>[_T<t>][_config][_<STATUS>]`

- **ORIGIN** — CESAR (catalog/modified), UCON (bespoke/UCON-made), or an
  appliance brand (DACOR, MIELE…) for placeholders.
- **TYPE** — CUSTOM_UPPER, OWU (open wall unit), SINGLE_FRONT, ISLAND_BACK,
  FILLER, PLACEHOLDER, …
- **Wxxx Hxxx Dxxx** — always in that order, always mm (fixes the sheet's
  inconsistency). Txx = panel/front thickness when relevant.
- **config** — DOUBLE_DOOR, 2D, PANEL_READY, C18_B4 (carcass 18 / back 4)…
- **STATUS** — PRELIMINARY until factory feasibility confirmed.

Exact token set to be finalized WITH the factory (they read it) — likely an
Elda/Cabinetry-Edit conversation. Record as an option, not a locked format.

## Ties to

- Exporter (M1.10): emits this name per non-catalog element on the order /
  Custom Elements sheet.
- Bespoke (M1.12) and Modifications (M1.11): the generated name is their
  identity in place of a catalog code.
- Appliance placeholders (new — see spectrum).

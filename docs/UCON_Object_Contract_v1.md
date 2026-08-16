# UCON Object Contract — v1

**Org:** UCONSD · **Document role:** Load-bearing data foundation for the Cabinet Engine
**Version:** v1 (revision v1.1) · **Date:** 2026-07-29 · **Status:** Locked (change only via versioned migration)

This document defines the data foundation every other part of the Cabinet Engine depends
on: the attribute namespace written onto model objects, the component structure, the
rules-registry format, and the trust vocabulary. It is deliberately small and stable.

## 0. How this document changes

This contract is **load-bearing**. Tools, registries, and models are built against it, so
it does not change casually.

- Any change to attribute names, allowed values, or the `status` vocabulary requires a new
  version (`v2`, …) and a written migration note describing how existing model attributes
  and registries move from the old version to the new one.
- `schema_version` (below) is written onto every object so a tool can tell which contract
  version produced it.
- Additive, non-breaking clarifications may be recorded as `v1.x` revisions of this file;
  anything that would invalidate existing data is a major version.

---

## 1. The attribute namespace

Every Cabinet Engine object carries its data in a **single SketchUp attribute dictionary
named `CabinetEngine`**. The dictionary name is the namespace, so individual keys are
plain (no per-key prefix). The dictionary is manufacturer- and class-agnostic: one
exporter reads it off any object without knowing what the object is.

### 1.1 Attribute schema

| Key | Type | Required | Allowed / format | Meaning |
|-----|------|:--:|---|---|
| `schema_version` | string | yes | `"1"` | Contract version that produced this object |
| `object_class` | string | yes | `cabinet` · `worktop` · `panel` · `filler` · `accessory` · `appliance_front` · `corner_unit` | What kind of thing this is |
| `manufacturer` | string | yes | `cesar` (lowercase id) | Source manufacturer |
| `collection` | string | no | e.g. `Maxima`, `Intarsio`, `Tangram` | Product collection/system |
| `family` | string | no | e.g. `H.78`, `H.84`, `H.48` | Manufacturer family (for cabinets, the height family) |
| `unit_category` | string | no | free text from source (e.g. `Standard base unit`) | Source category |
| `unit_type` | string | no | free text from source (e.g. `Base unit with door`) | Source sub-type |
| `geometry_kind` | string | yes | `linear` · `corner` · `non_dim` | How the object is dimensioned |
| `height_mm` | number | cond. | integer mm | Required when `geometry_kind = linear`/`corner` |
| `depth_mm` | number | cond. | integer mm | Required when `geometry_kind = linear`/`corner` |
| `width_mm` | number | cond. | integer mm | The chosen width (required for `linear`) |
| `corner_geometry` | string | cond. | e.g. `1000x400`, `750x750` | Required when `geometry_kind = corner` (replaces a single width) |
| `opening` | string | no | e.g. `door` · `doors` · `top-hung` · `push-up` · `pull-out` · `bottom-hung` · `folding` | Front / opening configuration (door type) |
| `opening_method` | string | no | `handle` · `push_to_open` · `gola` | How the front is opened — a separate axis from `code` (see §4.1) |
| `front_height_mm` | number | no | integer mm | Visible front height; derived from family + `opening_method` (`gola` = family door − 30) |
| `hardware_ref` | string | no | e.g. `GOL001`, `M00001`, or empty | The separately-ordered opening hardware (see §4.1) |
| `hardware_source` | string | no | `factory` · `client` | Who supplies the opening hardware (empty `hardware_ref` + `client` = client-provided) |
| `code` | string | no | manufacturer article code as printed (e.g. `B30601`, `PB0500`) | The factory code — see §4 |
| `code_status` | string | yes | `PRELIMINARY` · `CONFIRMED` | Trust in the code — see §4 |
| `pricing_group_ref` | string | no | e.g. `1-11` | Reference only; never a price |
| `status` | string | yes | ordered enum, see §3 | Trust level of this object's data |
| `priority` | string | no | `P1` · `P2` · `P3` | Planning priority; `P3` = blocked until CONFIRMED |
| `source_ref` | string | cond. | `"<pdf> p.<printed>[ /PDF <n>]"` | Required for `status = SOURCE` or higher |
| `restrictions` | string | no | free text | Source restrictions/notes that constrain use |
| `notes` | string | no | free text | Working notes |

**Conditional-required** keys are required only in the situation named in the Meaning
column; otherwise they may be omitted.

### 1.2 Reserved / forbidden

- No key may carry a price, margin, coefficient, lead time, or availability guarantee.
  `pricing_group_ref` records only the visible group structure and nothing more.
- Keys not listed here must not be written into the `CabinetEngine` dictionary under v1.
  Extra project data belongs in a separate dictionary.

---

## 2. Component structure

- A cabinet (or other object) is a SketchUp **`ComponentDefinition`**. The `CabinetEngine`
  attribute dictionary is written on the definition; per-placement overrides (e.g. a chosen
  `width_mm`) may be written on the **instance**.
- Geometry is an **exterior envelope only** — `height_mm × depth_mm × width_mm` (or the
  `corner_geometry` footprint). Internal features (shelves, drawers, dividers, racks,
  hood cavities) are **not modeled** unless a source explicitly and legibly confirms them.
  Inventing internal counts is a contract violation.
- The exporter, decoder, and verify tools read **only** the `CabinetEngine` dictionary.
  They must not infer meaning from the component's name, layer, geometry, or nesting. This
  is what makes the exporter class-agnostic.

---

## 3. Trust vocabulary (`status`)

`status` records how far a fact has moved through the four-level trust model. Values are
**words**, and their canonical order is fixed here so tools sort by this order (not
alphabetically):

```
order: SOURCE < CONTROL < PLANNING < CONFIRMED
```

| `status` | Meaning | Evidence required to reach it |
|----------|---------|-------------------------------|
| `SOURCE` | The fact is visible in a manufacturer catalog / price-list PDF | `source_ref` points to the page; dimensions/config legible |
| `CONTROL` | Captured into a controlled register with provenance | Present in a source-extract register, `priority` assigned |
| `PLANNING` | Instantiated as a preliminary placeholder component in a model | A `ComponentDefinition` exists carrying this contract |
| `CONFIRMED` | Confirmed in writing by Cesar / DzineElements (Elda / Giorgio) | A written confirmation linked to the register row — **last level in scope** |

This vocabulary formalizes the existing source-control layer rather than replacing it.
The register fields already in use map on as follows:

| Existing extract field | Maps to |
|------------------------|---------|
| `extraction_status = confirmed from source` | qualifies an object for `SOURCE` |
| row present in a `*_Source_Extract` register (+ `priority`) | `CONTROL` |
| `sketchup_use = use` (placeholder created) | `PLANNING` |
| `extraction_status = unclear` / `needs Elda confirmation` | caps the object at `CONTROL`, forces `priority = P3` |
| written Elda/DzineElements confirmation | `CONFIRMED` |

### 3.1 `priority` (orthogonal to `status`)

| `priority` | Meaning |
|------------|---------|
| `P1` | Clear enough for a preliminary exterior-envelope component |
| `P2` | Family confirmed, but detail/relevance needs review |
| `P3` | **Blocked**: do not use before `CONFIRMED` (availability, geometry, or meaning materially unclear) |

`status` says how trusted the data is; `priority` says whether we may act on it yet. An
object may be `SOURCE`/`CONTROL` and still be `P3` (blocked).

---

## 4. Codes

- A single key, `code`, holds the manufacturer article code exactly as printed in the
  source (e.g. `B30601`, `PB0500`). No separate internal ID is introduced in v1.
- `code_status` is `PRELIMINARY` at `SOURCE`, `CONTROL`, and `PLANNING`, and becomes
  `CONFIRMED` only when `status = CONFIRMED`. A code being visible in the 2021 price list
  is never proof of current availability, so it stays `PRELIMINARY` until a human confirms
  it.
- If Elda later states that current codes differ, the `code` value is updated in place;
  because there is no parallel internal ID, no model-data migration is needed. Splitting
  `code` into `factory_code` + `internal_id` remains a future option if a real need
  appears (it would be an additive change).

### 4.1 Opening method, front height, and hardware (added v1.1)

The factory article code identifies the base unit (carcass + door module + configuration).
It does **not** encode how the front is opened. Verified against Cesar Kitchen System
(printed p.36 / PDF 38): each base-unit type is drawn with two door-height elevations
30 mm apart (e.g. `78` and `75`) over a **single code table** — one code covers both.

Opening method is therefore a separate axis carried in `opening_method`, with three values
from the catalog's "opening methods" (grip recess / push pull / door with handle):

| `opening_method` | Front height | Separately-ordered hardware (`hardware_ref`) |
|------------------|--------------|----------------------------------------------|
| `handle` | full (e.g. 780) | a factory handle `M00xxx` **or** client-provided (empty ref, `hardware_source = client`) |
| `push_to_open` | full (e.g. 780) | a factory push-pull device; no handle |
| `gola` | short, family − 30 mm (e.g. 750) | a factory `GOL` grip-recess profile; the door carries the top cutout |

Consequences the tools must respect:

- The **decoder cannot recover `opening_method` from `code`** — the axis lives outside the
  code, so it is stored explicitly and never inferred from the article number.
- `front_height_mm` is **derived**: full family door height for `handle`/`push_to_open`,
  minus 30 mm for `gola`.
- The opening hardware is **always a separate line item**, never folded into the cabinet
  `code`. Its source may be `factory` (a `GOL`/`M`/push-pull code) or `client` (no code).
- Switching a unit between `gola` and `handle` is, per Cesar's order workflow, a
  substantial modification — a change of `opening_method`, not of `code`.

Open confirmation (Elda): exactly how an order notates the chosen door version, and whether
the grip-recess version of the cabinet carries its own modification code / surcharge
(separate from the `GOL` profile). See the open-questions register.

---

## 5. Rules-registry format

Manufacturer rules live as **data**, not as code. Tools (generator, decoder, verify) read
these files and execute them; they do not hard-code catalog facts. Each manufacturer has
one registry file (e.g. `registry/cesar.json`). Skeleton:

```json
{
  "manufacturer": "cesar",
  "catalog_edition": "2021 price list (later update notation)",
  "source_pdf": "CESAR - 2 Kitchen System.pdf",
  "schema_version": "1",
  "families": {
    "H.78": {
      "height_mm": 780,
      "depths_mm": [350, 620, 670],
      "collections": ["Maxima", "Intarsio", "Tangram"],
      "width_options_mm": [150, 300, 450, 600, 750, 900, 1050, 1200],
      "categories": ["Standard base unit", "Drawer base unit", "Sink base unit", "..."],
      "source_ref": "CESAR - 2 Kitchen System.pdf p.36-43",
      "code_grammar": {
        "note": "Defines how a code is composed from depth, width, and configuration; filled at M1.3 after PDF verification",
        "prefix": "manufacturer/depth marker (e.g. B3=D350, B6=D470, B4=D620) — TO VERIFY",
        "width_field": "encodes nominal width — TO VERIFY",
        "config_suffix": "encodes opening/configuration — TO VERIFY",
        "collection_variants": "e.g. B0.. / BJ.. / B1.. — TO VERIFY"
      }
    }
  }
}
```

- Every value that becomes an authority (a dimension, a code component, a restriction) must
  carry or inherit a `source_ref`, and must be **verified against the source PDF before it
  enters the registry** (see §6). Fields marked `TO VERIFY` are placeholders until that
  check is done at Milestone 1.3.
- The `code_grammar` block is what lets the generator produce a `code` from parameters
  (forward) and the decoder recover parameters from a `code` (reverse).

---

## 6. Invariants

These hold across every tool and document:

1. **The source PDF wins.** No register row, workbook, registry entry, or generated model
   may override a dimension, restriction, or note in the source. On conflict, the PDF is
   authority and the discrepancy is logged.
2. **Envelope only until confirmed.** Model exterior dimensions only; never invent internal
   configuration.
3. **PRELIMINARY until human confirmation.** `code_status` stays `PRELIMINARY` until
   `status = CONFIRMED`.
4. **Ask before assuming catalog facts.** Unclear source content becomes an Elda question
   and caps the object at `CONTROL` / `P3`; it is not guessed.
5. **Class-agnostic reads.** Tools derive meaning only from the `CabinetEngine` dictionary.
6. **In scope only through CONFIRMED.** Nothing in this contract crosses Level 4 into quote,
   pricing, order, production, delivery, or install.

---

## 7. Change log

- **v1 (2026-07-29)** — Initial contract. Namespace `CabinetEngine` with plain keys;
  single `code` + `code_status`; `status` vocabulary `SOURCE/CONTROL/PLANNING/CONFIRMED`
  with fixed order; `priority` P1/P2/P3 (P3 blocks until CONFIRMED); registry-as-data
  format with `H.78` as the first worked family. Formalizes the existing source-control
  layer (source hierarchy, extraction status, priority) into the four-level model.
- **v1.1 (2026-07-29)** — Additive, non-breaking. Added `opening_method`
  (`handle`/`push_to_open`/`gola`), derived `front_height_mm`, and `hardware_ref` +
  `hardware_source` (`factory`/`client`); added §4.1 establishing that the factory code
  does not encode opening method (verified against Kitchen System p.36) and that opening
  hardware is always a separate line item. No existing keys or values changed.

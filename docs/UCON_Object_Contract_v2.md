# UCON Object Contract — v2

**Org:** UCONSD · **Document role:** Load-bearing data foundation for the Cabinet Engine
**Version:** v2 (revision v2.2) · **Date:** 2026-08-27 · **Status:** Locked (change only via versioned migration)
**Supersedes:** `docs/UCON_Object_Contract_v1.md` (revision v1.5), which is kept as the
historical record and must not be edited.

This document defines the data foundation every other part of the Cabinet Engine depends
on: the attribute namespace written onto model objects, the component structure, the
rules-registry format, and the trust vocabulary. It is deliberately small and stable.

## 0. How this document changes

This contract is **load-bearing**. Tools, registries, and models are built against it, so
it does not change casually.

- Any change to attribute names, allowed values, or the `status` vocabulary requires a new
  version (`v3`, …) and a written migration note describing how existing model attributes
  and registries move from the old version to the new one.
- `schema_version` (below) is written onto every object so a tool can tell which contract
  version produced it.
- Additive, non-breaking clarifications may be recorded as `v2.x` revisions of this file;
  anything that would invalidate existing data is a major version.

**Why v2 exists at all is worth stating, because it is this section working.** The change
that prompted it — `companion_refs` going from a comma-separated string to a list of order
lines — was designed and written up as a "v1.6". Read against the rules above it is not:
it changes the allowed values of an existing key, and an object written under v1.5 is no
longer conformant. Both bullets point the same way, so it is a major version with a
migration note (§7), not a revision. **If a rule here is inconvenient, the rule is not
what gets adjusted.**

---

## 1. The attribute namespace

Every Cabinet Engine object carries its data in a **single SketchUp attribute dictionary
named `CabinetEngine`**. The dictionary name is the namespace, so individual keys are
plain (no per-key prefix). The dictionary is manufacturer- and class-agnostic: one
exporter reads it off any object without knowing what the object is.

**The dictionary IS the object.** `Contract.write!` reconciles: keys present in the
validated attribute set are written, keys absent from it are DELETED. A write that cannot
erase is not a description, it is an accumulation — and an accumulation is how a factory
article code once survived on an object that said the client supplies the hardware.

### 1.1 Attribute schema

| Key | Type | Required | Allowed / format | Meaning |
|-----|------|:--:|---|---|
| `schema_version` | string | yes | `"2"` | Contract version that produced this object |
| `object_class` | string | yes | `cabinet` · `worktop` · **`shelf`** · `panel` · `filler` · `accessory` · `appliance` · `appliance_front` · `corner_unit` · `void` | What kind of thing this is |
| `manufacturer` | string | yes | `cesar` (lowercase id), or `client` | Source manufacturer |
| `collection` | string | no | e.g. `Maxima`, `Intarsio`, `Tangram` | Product collection/system |
| `family` | string | no | e.g. `H.78`, `Wall H.36`, `Tall H.210` | Manufacturer family (for cabinets, the height family) |
| `unit_category` | string | no | free text from source | Source category |
| `unit_type` | string | no | free text from source | Source sub-type |
| `geometry_kind` | string | yes | `linear` · `corner` · `non_dim` | How the object is dimensioned |
| `height_mm` | number | cond. | integer mm | Required when `geometry_kind = linear`/`corner` |
| `depth_mm` | number | cond. | integer mm | Required when `geometry_kind = linear`/`corner` |
| `width_mm` | number | cond. | integer mm | The chosen width (required for `linear`) |
| `corner_geometry` | string | cond. | e.g. `1000x400`, `750x750` | Required when `geometry_kind = corner` |
| `mounting` | string | no | `floor` · `wall_hung` | How the object meets the room — see §1.3 |
| `mount_bottom_mm` | number | cond. | integer mm above finished floor | Required when `mounting = wall_hung`; forbidden otherwise |
| `opening` | string | no | e.g. `door` · `doors` · `top-hung` · `push-up` · `pull-out` · `bottom-hung` | Front / opening configuration |
| `opening_method` | string | no | `handle` · `push_to_open` · `gola` | How the front is opened — see §4.1 |
| `front_height_mm` | number | no | integer mm | Visible front height; derived from family + `opening_method` |
| `hinge_side` | string | no | `rh` · `lh` | Hinge side for handed single-door fronts. Chosen per order; NOT encoded in the article code |
| `hardware_ref` | string | no | e.g. `GOL001`, `M00001` | The separately-ordered opening hardware (see §4.1) |
| `hardware_source` | string | no | `factory` · `client` | Who supplies the opening hardware |
| `companion_refs` | **list of line** | no | see §1.4 | Order lines the article obliges or the customer chose alongside it — see §4.2 |
| `variants` | **list of variant** | no | see §1.4 | `KEY: Value` order lines this object carries that have no article code of their own |
| `code` | string | no | manufacturer article code as printed | The factory code — see §4 |
| `code_status` | string | yes | `PRELIMINARY` · `CONFIRMED` | Trust in the code — see §4 |
| `pricing_group_ref` | string | no | e.g. `1-11` | Reference only; never a price |
| `status` | string | yes | ordered enum, see §3 | Trust level of this object's data |
| `priority` | string | no | `P1` · `P2` · `P3` | Planning priority; `P3` = blocked until CONFIRMED |
| `source_ref` | string | cond. | `"<pdf> p.<printed>[ /PDF <n>]"` | Required for `status = SOURCE` or higher |
| `restrictions` | string | no | free text | Source restrictions that constrain use |
| `notes` | string | no | free text | Working notes |

**Conditional-required** keys are required only in the situation named in the Meaning
column; otherwise they may be omitted.

### 1.2 Reserved / forbidden

- No key may carry a price, margin, coefficient, discount, surcharge, lead time, or
  availability guarantee. `pricing_group_ref` records only the visible group structure.
- **This applies inside the structured keys too.** A variant records *that* stainless
  steel was chosen; what the surcharge costs is not ours to carry. A `surcharge` field on
  a variant is a contract violation, not a convenience.
- Keys not listed here must not be written into the `CabinetEngine` dictionary under v2.
  Extra project data belongs in a separate dictionary.

### 1.3 Mounting (unchanged from v1.5)

A base unit's height above the floor is not information: it stands on its plinth, and the
plinth height is already a standard. A wall unit's is. Nothing in the catalog says how high
a wall unit hangs — Cesar prices the box — so the number comes from the project.

- `mounting = wall_hung` **requires** `mount_bottom_mm`, and it must be positive.
- `mounting = floor` **forbids** `mount_bottom_mm`.
- `mounting` itself is optional for backward compatibility, but the generator states it on
  every cabinet it builds — including `floor` — so an absent key means "nobody asked".

`mount_bottom_mm` is a PROJECT decision at trust level PLANNING, never a catalog fact.

### 1.4 Structured keys (new in v2)

Two keys hold structure rather than a scalar. Both are **lists**, and both are **one level
deep — a line may not contain lines.**

```
companion_refs : [ LINE ]
LINE           : { code, qty, um, origin, source_ref, variants? }
variants       : [ VARIANT ]
VARIANT        : { key, value, source_ref }
```

| Field | Type | Required | Allowed | Meaning |
|---|---|:--:|---|---|
| `code` | string | yes* | article code as printed | The companion article. *May be `null` — see the unresolvable case in §4.2 |
| `qty` | number | no | > 0, or **null** | How many. A resolved NUMBER, never a rule. **Null means the quantity is not determinable from this object** — a linear-metre profile is measured along the RUN, a handle count follows the fronts. Forcing a number there would make the model state something nobody knows (v2.1) |
| `um` | string | yes | `PZ` · `ML` · `MQ` | Unit of measure |
| `origin` | string | yes | `implied` · `chosen` | Whether the article obliges this line, or a person asked for it — see §4.2 |
| `source_ref` | string | no | page reference | Where the rule was read. **Optional on purpose**: a resolved code's provenance lives in the registry row that produced it, and a second copy is a second thing to keep true — the same argument that kept a `role` field out |
| `variants` | list | no | `[ VARIANT ]` | Variant lines carried by THIS companion |
| `key` / `value` | string | yes | free text as printed | e.g. `FINISH` / `Stainless steel` |
| `label` | string | no | short free text | **v2.3.** The same choice in three words, for a symbol on a drawing. `value` is written to be read in a properties panel and on an order sheet; an elevation has room for `LED 3000/4000K` and no more. Never a second opinion — a check holds it to being shorter than `value` |

**No recursion, and the reason is evidential, not aesthetic.** The catalog shows exactly
one level of nesting — printed p.569, where an interior drawer kit is a companion article
that itself carries an uncoded `Stainless steel` variant — and **zero** cases anywhere of a
companion carrying a companion (the dishwasher door's `GBBF01` and filler profile are
siblings, not a chain). A shape that generalises past its evidence is a future bug with a
date on it. If a second level ever appears, it appears with a page reference.

**Storage.** SketchUp attribute values must be `nil`, Boolean, Integer, Float, String,
Length, Time or Array; **Hash is not an accepted type**, so these two keys are stored as
JSON text. The encoding is the contract's own business and lives in one place:

- `validate!` always operates on the **logical** form (real lists and hashes).
- `write!` validates, then encodes the structured keys at the boundary.
- `read` decodes them at the boundary, and performs the v1 → v2 lift (§7).

**Presence is decided on the logical value, and encoding happens after.** `[]` means "no
companions" and the key is not written; `"[]"` is a non-empty String and would be
persisted as if it were data. Encode-then-test is the wrong order.

---

## 2. Component structure

- A cabinet (or other object) is a SketchUp **`ComponentDefinition`**. The `CabinetEngine`
  attribute dictionary is written on the definition; per-placement overrides may be written
  on the **instance**.
- Geometry is an **exterior envelope only** — `height_mm × depth_mm × width_mm` (or the
  `corner_geometry` footprint). Internal features (shelves, drawers, dividers, racks) are
  **not modeled** unless a source explicitly and legibly confirms them. Inventing internal
  counts is a contract violation.
- The exporter, decoder, and verify tools read **only** the `CabinetEngine` dictionary.
  They must not infer meaning from the component's name, layer, geometry, or nesting.

---

## 3. Trust vocabulary (`status`)

Unchanged from v1.

```
order: SOURCE < CONTROL < PLANNING < CONFIRMED
```

| `status` | Meaning | Evidence required to reach it |
|----------|---------|-------------------------------|
| `SOURCE` | The fact is visible in a manufacturer catalog / price-list PDF | `source_ref` points to the page |
| `CONTROL` | Captured into a controlled register with provenance | Present in a source-extract register, `priority` assigned |
| `PLANNING` | Instantiated as a preliminary placeholder component in a model | A `ComponentDefinition` exists carrying this contract |
| `CONFIRMED` | Confirmed in writing by Cesar / DzineElements | A written confirmation linked to the register row |

### 3.1 `priority` (orthogonal to `status`)

| `priority` | Meaning |
|------------|---------|
| `P1` | Clear enough for a preliminary exterior-envelope component |
| `P2` | Family confirmed, but detail/relevance needs review |
| `P3` | **Blocked**: do not use before `CONFIRMED` |

`status` says how trusted the data is; `priority` says whether we may act on it yet.

---

## 4. Codes

- A single key, `code`, holds the manufacturer article code exactly as printed.
- `code_status` is `PRELIMINARY` at `SOURCE`, `CONTROL`, and `PLANNING`, and becomes
  `CONFIRMED` only when `status = CONFIRMED`.
- If Elda later states that current codes differ, the `code` value is updated in place.

### 4.1 Opening method, front height, and hardware (unchanged from v1.1)

The factory article code identifies the base unit. It does **not** encode how the front is
opened; that axis lives in `opening_method`.

| `opening_method` | Front height | Separately-ordered hardware (`hardware_ref`) |
|------------------|--------------|----------------------------------------------|
| `handle` | full (e.g. 780) | a factory handle `M00xxx` **or** client-provided (empty ref, `hardware_source = client`) |
| `push_to_open` | full | a factory push-pull device; no handle |
| `gola` | family − 30 mm | a factory `GOL` grip-recess profile |

- The **decoder cannot recover `opening_method` from `code`**.
- `front_height_mm` is **derived**.
- The opening hardware is **always a separate line item**.
- Switching between `gola` and `handle` is a change of `opening_method`, not of `code`.

### 4.2 Companion lines and variants (rewritten in v2)

A catalog choice can oblige, or offer, other order lines. This is not an exception; it is a
recurring shape of the source:

- Door version 75 (gola) requires its `GOL` grip-recess profile (§4.1).
- A dishwasher door requires the filler profile between the appliance and the top, and at
  W75 additionally `GBBF01`.
- A waste unit carries its bin kit.
- A kit-ready tall unit (printed p.111, `CR0535`/`CR0635`) **may** be fitted with an
  interior drawer kit from printed p.569 — and that kit in turn may be ordered with
  stainless steel fronts, an uncoded variant line of its own.

`companion_refs` records those as **lines** (§1.4). Rules:

1. **Companions are order lines, not geometry.** Whether one is drawn is a separate
   question. A companion that is a real box may be generated as its own object, and then it
   carries its own attributes and its own code.
2. **Companions are resolved from the registry, never typed.** The registry states the rule
   (which code, at which width, how many); the generator resolves it. A code that reached
   an object by being typed is a defect.
3. **`origin` is behavioural, not descriptive.** `implied` lines are recomputed on every
   rebuild — nobody owns them. `chosen` lines survive a rebuild: a hinge-side change must
   not evaporate somebody's kit.
4. **When a chosen line stops resolving, say so.** If the unit changes such that the code
   is no longer right (W.600 → W.450), re-resolve, rewrite `code`, and append to `notes` —
   the same treatment a corner execution swap gets. If the new state has **no** valid
   option at all, `code` becomes `null` and the object carries a visible warning. Unknown
   is null, never a quietly kept stale article and never a silent deletion.
5. **The exporter must emit every companion**, or the order is incomplete.
6. **A variant earns its own contract key only when geometry reads it.** `hinge_side` and
   `opening_method` are first-class because the front builder and the symbol renderer read
   them. Everything else — `OPENING DIRECTION`, `WIDTH REDUCTION`, `Smontato`,
   `FINISH: Stainless steel` — lives in `variants`. Without this rule the key list grows
   one entry per surcharge and ends up with thirty.
7. `hardware_ref` stays what it is — the opening hardware of THIS object. Folding it into
   `companion_refs` remains a future option and is not done here.

**What the object does NOT record.** Not the kit type, not the kit depth, not the price.
The code carries type and depth; the options registry decodes it; the price is Metron's
business. Store the code, look the rest up.

---

## 5. Rules-registry format

Manufacturer rules live as **data**, not as code. Tools read these files and execute them;
they do not hard-code catalog facts. The registry is stored as one file per PRINTED catalog
section under `registry/<manufacturer>/`, plus a `_manifest.json` holding shared facts
(code grammar, hardware, external specs, the catalog map). The loader merges them.

```json
{
  "manufacturer": "cesar",
  "catalog_edition": "2021 price list (later update notation)",
  "source_pdf": "CESAR - 2 Kitchen System.pdf",
  "schema_version": "2",
  "families": {
    "H.78": {
      "height_mm": 780,
      "depths_mm": [350, 620, 670],
      "collections": ["Maxima", "Intarsio"],
      "source_ref": "CESAR - 2 Kitchen System.pdf p.36-43",
      "unit_types": { "...": {} }
    }
  }
}
```

- Every value that becomes an authority (a dimension, a code component, a restriction) must
  carry or inherit a `source_ref`, and must be **verified against the source PDF before it
  enters the registry**.
- **Option rules are keyed differently from units** — an interior kit by (type, depth,
  width), a bin kit by width, a Servo Drive count by a printed calculation rule — so they
  live in their own namespace (`registry/<manufacturer>/options/`) rather than being forced
  into `families → unit_types → codes`. An option row states separately what it can attach
  to, how its code is selected, how many, and whether geometry reads it. *(Namespace
  planned, not yet created.)*
- **A duplicated key, a duplicated code, or two section files claiming the same
  `unit_type` inside one family are all silent losses** — JSON keeps the last, `lookup`
  keeps the first, and the loader deletes. The suite guards all three.

---

## 6. Invariants

1. **The source PDF wins.** No register row, workbook, registry entry, or generated model
   may override a dimension, restriction, or note in the source. Factory output outranks
   the source PDF.
2. **Envelope only until confirmed.** Model exterior dimensions only.
3. **PRELIMINARY until human confirmation.**
4. **Ask before assuming catalog facts.** Unclear source content becomes an Elda question
   and caps the object at `CONTROL` / `P3`.
5. **Class-agnostic reads.** Tools derive meaning only from the `CabinetEngine` dictionary.
6. **In scope only through CONFIRMED.** Nothing crosses into quote, pricing, order,
   production, delivery, or install.
7. **The dictionary is the whole description.** After a write it holds exactly the validated
   set — nothing stale, nothing outside the key list.

---

## 7. Migration — v1.5 to v2

Required by §0. `Contract.read` is the migration boundary: it returns v2-shaped data
whatever version wrote the object, so a model built under v1 keeps opening, and self-heals
as objects are rebuilt.

| v1.5 on the entity | v2 as read |
|---|---|
| `schema_version: "1"` | normalised to `"2"`. `write!` then persists `"2"` |
| `companion_refs: "995946,GBBF01"` | `[{code: "995946", qty: 1, um: "PZ", origin: "implied"}, {code: "GBBF01", qty: 1, um: "PZ", origin: "implied"}]` |
| `companion_refs` absent | absent |
| every other key | unchanged |

**Nothing in that lift is a guess, and it is worth being precise about why.**

- `origin: "implied"` — under v1 the contract had no way to express a chosen companion, so
  every companion a v1 object can be carrying was implied by its unit type.
- `qty: 1`, `um: "PZ"` — these are what the v1 format could *express*: one code in the
  string meant one line, one piece. This is a statement about the old shape's expressive
  power, not a claim about the catalog.
- `source_ref` is simply absent, because v1 never recorded a per-line one and inventing a
  page reference would be worse than having none. It is optional (§1.4).

An implied line is re-resolved from the registry on the next rebuild anyway (§4.2 rule 3),
so the lift only has to be good enough to stay valid and readable until then.

No model file has to be opened and re-saved for this. An object never touched again keeps
its v1 attributes on disk and reads correctly forever.

## 8. Change log

- **v2.3 (2026-08-27)** — Additive, non-breaking. A variant may carry **`label`**:
  the short form of the same choice, for a drawing. Driven by the lit shelf. Its
  `value` is a full sentence — the lamp, the length, the arithmetic that produced
  it, the depth position and the book it is priced in — which is right for a
  panel and an order sheet and impossible on an elevation symbol 60 mm deep. The
  alternative was to have the drawing code compose its own short text from the
  variant, which puts the wording in Ruby instead of on the page; `label` keeps it
  where every other piece of catalog wording lives. Optional, so every variant
  written before today stays valid, and §0 makes it a revision.
- **v2.2 (2026-08-27)** — Additive, non-breaking. `object_class` gains **`shelf`**.
  Driven by Linear Elements printed p.223-224: a board that HANGS, is cut to
  length and is priced by the linear metre or the square metre. Neither existing
  word fits — a `panel` finishes something and its width is a thickness, a
  `worktop` rests on a run and in this project is drawn and NOT ordered, while a
  shelf is ordered and rests on nothing. Andriy chose the new word over
  stretching either. **This row also records that `void` was in the code and not
  in this table**, since v2 shipped with `void` in the enum; the table is now
  correct rather than being made correct silently. Widening an enum invalidates
  no existing object, so §0 makes it a revision.
- **v2.1 (2026-08-22)** — Additive, non-breaking. `qty` on a companion line may
  be **null**, meaning the quantity is not determinable from this object. Driven
  by the first real export run: gola grip-recess profiles are ordered by the
  linear metre along a RUN that crosses joints between units, so no single
  cabinet can state the number. Requiring a positive number there forced a
  choice between a lie and an unrepresentable fact. Loosening a constraint
  invalidates no existing data — every line written under v2 carries a qty and
  stays valid — so §0 makes this a revision rather than a major version.
- **v2 (2026-08-22)** — MAJOR. `companion_refs` changes from a comma-separated string to a
  list of order lines, and `variants` is added. Driven by printed p.111 + p.569: the first
  article the registry holds whose option is CHOSEN rather than implied, and whose chosen
  companion carries an uncoded variant of its own — three levels where the string could
  express one. Also states the reconciling `write!` (§1), the storage rule for structured
  keys (§1.4), and the `origin` behaviour (§4.2). Migration: §7. Prior versions and their
  reasoning are in `docs/UCON_Object_Contract_v1.md`, which is not edited.

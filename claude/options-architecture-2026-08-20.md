# Options and extras — what attaches to a unit, and what the engine must grow

Design note, 2026-08-20. Written **before** any code changed, deliberately: the
decision is recorded now and the code follows demand. Nothing here is
implemented.

Sources read for this: chapter indexes of the whole price list; printed p.42-43
(corner base units), p.97 and p.170 (tall units, top elements), p.221 (wall
units H.60), p.512 (pull-out mechanisms), p.559-567 (hinges, wall unit opening
mechanisms, restrictors, Servo Drive), p.483-526 (accessories and waste bins
index), p.577 (handles index). Plus `docs/Cesar_Estimate_Teardown_v0.1.md`,
which is CONFIRMED factory output and outranks every reading above.

NOT read: lighting (527-546), Thin and Trilli (457-482), cutlery trays
(486-511). They look like they fit the same taxonomy. That is a guess.

---

## 1. "Option" is five different things

The catalog and the estimate agree on this, and the five behave differently
enough that treating them as one concept would be the bug.

| | mechanism | example | in an order | engine today |
|---|---|---|---|---|
| **1** | **baked into the article** | Magicorner is `AU112D/S`, not a tick-box on `AU110D/S`. Push-up is `PD0610`, not an option on `PD0600` | one row, a different code | **done** — registry rows |
| **2** | **variant line** `KEY: Value`, sometimes with a surcharge | `OPENING DIRECTION: Left`, `WIDTH REDUCTION: Yes +138`, `Smontato +22`, `Scanso Per Lavastoviglie +40`, `Tap Hole +51` | child line under the row, **no code** | **nothing** |
| **3** | **companion article** | `FND205630329` under every `PG0631`; bin kit `995626`; push-up mechanism `994550`; restrictor `994A4A`; power adapter `996801`; hinge kit `983590` | child row **with a code** | **partial** — see §3 |
| **4** | **component row** — the factory explodes our unit into pieces | `FRN`, `RPN`, `DVN`, `KCAS`, `SCSE`, `FND` | child rows with cut sizes | **nothing**, and deliberately so |
| **5** | **composition axis** — set once for the whole kitchen | `MODELLO`, front finish, gola type/orientation/finish, `FOOT TYPE`, Legrabox | header above all rows | **nothing** — this is M1.6 |

**The user-facing model — "pick a unit, then add things to it" — is rows 2 and
3 only.** Row 1 is a different unit. Row 4 is the factory's business. Row 5 is a
property of the project.

### The same article reaches a unit by two different routes

printed p.97, tall units H.198, two types on one page:

- *"Tall unit with door that can be fitted with a drawer and jumbo drawer kit in
  the bottom section — **See kit on page 569**"* → the kit is **CHOSEN**.
- *"1 rh or lh door **with 155° hinges**"* → hinge kit `983591` is **IMPLIED by
  the type**.

Same catalog, same class, same page. Any model that can only express one of
these is wrong half the time. This is the single most important shape in this
document.

### The left margin is row 2, every time

Base, wall and tall pages all carry, beside the code table:
`Surch. for side panel D. on page 549` · `Surch. for wall-hung version on page
548` · `Surch. for feet H. 5 mm on page 548`. These are surcharges on the unit's
own line with no article of their own — exactly the `KEY: Value` lines the
estimate prints.

> **2026-08-23: the wall-hung line is more than a surcharge.** Its PRESENCE or
> ABSENCE states whether the article can be hung at all — printed p.19 gives the
> matching pictogram a name, "Hung version". Twenty codes are now refused on that
> evidence. See `claude/findings-2026-08-23-tall.md`.

---

## 2. Does the current architecture fit?

Partly. Of the five, one is complete, one is half-built, three are absent.

**What is already right, and must not be disturbed:**

- The registry is the only authority on codes. A companion is *resolved*, never
  typed.
- `unit['companions']` already carries a **selection RULE rather than an
  answer**: `by: 'width'` with a map, `applies_to_widths_mm`, or unconditional.
  That is the correct shape — it is simply in the wrong place and can express
  too little.
- `hinge_side` and `opening_method` already work as per-instance choices that
  do not change the code.

## 3. What breaks

**`companion_refs` is a comma-joined string.** No quantity, no role, no
`source_ref`, no distinction between mandatory and chosen. Invisible while a
waste unit has exactly one bin kit. A push-up wall unit wants mechanism
`994550` **and** restrictor `994A4A`, and `'994550,994A4A'` cannot answer "how
many, and why". This is the same flat-table failure the estimate already
exposed at a larger scale: the order is a tree and we are storing text.
*(Fixed in Contract v2.1, 2026-08-22: `companion_refs` is a list of lines, each
carrying `origin: implied | chosen`.)*

**Options are declared on the `unit_type`, so they can only be IMPLIED.** A
waste unit implying its bin kit is correct. But Servo Drive is a choice, the
hinge angle is a choice, a restrictor is a choice — and an instance has nowhere
to record "this one has Servo Drive".

**There is no option catalog at all.** Options are keyed differently from units:
wall mechanism by *(mechanism type, family, width)*; bin kit by *width*; hinge
by *nothing*; and the number of Servo Drive kits by a **printed calculation
rule** ("How to calculate the Servo Drive kits required", p.566). The registry
knows exactly one shape — `families → unit_types → codes`. Forcing options into
it would corrupt the thing that makes the registry trustworthy.

**Variant lines have no class.** `WIDTH REDUCTION`, `Smontato`,
`Scanso Per Lavastoviglie` carry a surcharge and no code. They are neither
companions nor units.

**Nothing marks which options touch geometry.** The push-up mechanism decides
whether the symbol is vertical or oblique (printed p.560 vs p.561). Servo Drive
on the same door changes nothing visible. Gola changes the front height 78→75 —
already modelled, but as a special case rather than as an instance of a rule.

---

## 4. Target shape

### A. `registry/cesar/options/` — a second namespace, same discipline

One file per PRINTED section, `source_ref` on every row, coverage recorded in
`catalog_map`. Chosen over extending the unit files because an option is keyed
differently from a unit, and because one hinge article would otherwise be
copied into every file that needs it.

An option row states **four things separately** — this is the part that matters,
not the file layout:

| field | question it answers | example |
|---|---|---|
| `applies_to` | what can it attach to | class/family/unit_type/width predicate |
| `select_by` | how the code is chosen | width lookup · family lookup · fixed |
| `quantity` | how many | 1 · per door · per drawer (printed rule) · per metre |
| `effect` | does geometry read it | `none` · `symbol` · `front_height` |

Plus `kind: mandatory | chosen`, and `um` (PZ/ML/MQ).

This is a generalisation of the `companions` shape that already exists — not a
new idea — and it has room for the catalog's printed calculation rules.

### B. Object Contract v1.6 — two changes

- **`companion_refs`: string → list** of `{code, qty, um, role, source_ref}`.
- **new key `variants`**: list of `{key, value, source_ref}` — the home for
  `KEY: Value` lines.

*(Both landed in v2.1 on 2026-08-22.)*

### C. The rule that stops the key list growing forever

> **A variant earns its own contract key only when geometry reads it.**

`hinge_side` and `opening_method` are read by the symbol renderer and the front
builder, so they stay first-class. Everything else lives in `variants`. Without
this line the contract grows a key per surcharge and ends up with thirty.

### D. `variants` is what makes Elda Q7b cheap

If the corner execution letter turns out to be a variant rather than a second
article, `Generator.swap_corner_execution!` stops rewriting `code` and starts
writing one entry in `variants`. One field instead of a rework. Worth knowing
before the answer arrives.

### E. Component rows (§1 row 4) are NOT modelled

`FRN` / `RPN` / `DVN` / `KCAS` are the factory's explosion of our unit. We do
not order them; Metron generates them. Exporter level 1 is carcasses and
articles. Recorded, closed.

### F. Composition axes (§1 row 5) stay M1.6

Unchanged by this note.

---

## 5. When

**Decided 2026-08-20: record now, build on demand.** Modelling is not blocked —
units build, place and snap. The **exporter** is what these changes unblock, so
the trigger is the first order line that needs more than a code. Expected order:

1. **Contract v1.6** when the first unit we hold needs two companions, or when
   the exporter starts. Whichever comes first. *(Done as v2.1, 2026-08-22.)*
2. **`options/`** when a real kitchen needs a chosen option — most likely the
   push-up mechanism, because it also unlocks the two symbols.
   *(2026-08-24: overtaken. FIVE positions in five chapters now print "See kit
   on page 569" and record the same gap — printed p.37 `B80505`, p.90 `C20505`,
   p.97 `CF0535`, p.111 `CR0535`, p.132 `CH0535`. It is the most referenced
   unread page in the registry.)*
3. **The picker/panel** last: it cannot offer options that have no catalog.

Do not do these in the other order. An option UI over an invented catalog would
be the same mistake as a symbol without a convention.

---

## 6. Open, and worth carrying to Elda

- The wall pages print `Servo Drive mechanism 554` over BOTH the top-hung and
  the push-up block on printed p.221, but the articles differ: oblique push-up
  H.60 W.60 is `994A50` at **554**, while top-hung H.60 is `993A94` at **504**.
  So the figure on the unit page is not the article's price. Resolve from an
  estimate, do not guess.
- `Smontato` — Elda already flagged that "unassembled" may not mean what the
  office thinks. It is a variant line either way.
- Whether a chosen option is ordered as its own row or as a child of the unit
  row. The estimate shows children; whether that is Metron's doing or the
  order's is unknown.

# Companions and variants — the design, and what it cost

> **LANDED 2026-08-22 as Object Contract v2**, commit `17c20dd`. The filename
> still says v1.6 because that is what this was called while it was being
> designed, and renaming it would hide the most useful thing in it — see §0.
>
> **The SPEC now lives in the repository: `docs/UCON_Object_Contract_v2.md`.**
> It is the authority; this note is the reasoning and the catalog evidence that
> produced it. The shape is deliberately not restated here, because a spec
> written in two places goes stale in one of them.

---

## 0. The governance finding — why "v1.6" is called v2

This was designed as a revision. It is not one.

The contract document is marked **Locked**, and its §0 says two things:

> Any change to attribute names, **allowed values**, or the `status` vocabulary
> requires a new version (`v2`, …) and a written migration note.
>
> Additive, non-breaking clarifications may be recorded as `v1.x` revisions;
> **anything that would invalidate existing data is a major version.**

Turning `companion_refs` from a string into a list of objects trips **both**
clauses. The key keeps its name, but its allowed values change, and an object
written under v1.5 stops being conformant — the read-side lift makes it
*readable*, not *valid*.

So it is a major version with a migration note, and `schema_version` goes
`"1"` → `"2"`. The cost turned out to be small: `Contract.read` became the
migration boundary and returns v2 shape whatever wrote the object, so a model
built under v1 keeps opening and self-heals as objects are rebuilt.

**The lesson is the general one.** A rule that is inconvenient does not get
reinterpreted quietly. v2 §0 now says so about itself.

---

## 1. The catalog evidence

### 1.1 The kit is a chosen companion with three axes and two restrictions

**printed p.568** — *"position of interior Legrabox drawers and jumbo drawers in
base and tall units with rh or lh doors"*. Read as a **rendered image**; the
text layer mangles this page (status doc, rule 10). It splits the kits by class:

- **BASE units** (H.66, H.78, H.84) → KIT-D, KIT-E, KIT-F
- **TALL units** (H.138, H.198, H.210, H.222, H.234) → **KIT-L, KIT-O only**

So the five types on p.569 are not five choices for our cabinet. For H.210 there
are **two**.

**printed p.569** — code = `996` + depth letter + type letter + width digit,
where `O` = d.50, `P` = d.60, `5` = W.45, `6` = W.60. Twenty codes, verified by
render on types D and L because the price tables interleave with the margin
surcharges in the text dump.

For **CR0635** (W.600, d.62) the candidates are exactly four:

| | d.50 | d.60 |
|---|---|---|
| KIT-L | `996OL6` | `996PL6` |
| KIT-O | `996OO6` | `996PO6` |

Printed on both pages: **"They CANNOT be modified in width"** and **"DO NOT fit
against the wall."**

Grammar caution, free of charge: on the facing page (printed p.570, Legrabox
structures) the *same* depths d.50 and d.60 are coded `M` and `N`. **The depth
letter is page-scoped.**

### 1.2 The kit carries a variant of its own — this is what broke the old shape

Each type on p.569 prints `Surcharges for LEGRABOX: Stainless steel` — KIT-L
387, KIT-O 430 — **with no article code**. So the catalog shows three levels:

```
unit          CR0635          (article)
 └─ companion 996PL6          (article, CHOSEN)
     └─ variant  Stainless steel   (KEY: Value, no article)
```

The 08-20 options note designed two. That is the whole reason this exists.

### 1.3 Geometry reads none of it

Interior drawers, behind one full-height 2100 door, with their own 2 mm fronts.
Envelope-only draws the cabinet identically with the kit and without it — so by
the rule the options note already set, *a variant earns its own contract key
only when geometry reads it*, the kit gets **no key of its own**.

---

## 2. What changed while it was being built

Three things, and each one is a decision worth keeping.

**`role` was dropped, and then `source_ref` followed it.** Both are derivable
from the registry row that produced the code. Store the code, look the rest up
— a second copy is a second thing to keep true. `source_ref` stays *allowed* on
a line, just never required.

**`origin: implied | chosen` earned its place where `role` did not**, because it
changes what the code *does*: implied lines are recomputed on every rebuild,
chosen ones survive one. That is the difference between a hinge-side change
leaving somebody's kit alone and silently eating it.

**The prerequisite nobody had noticed.** `Contract.write!` could not erase: it
skipped keys whose value had become empty instead of deleting them, so a
factory article code survived on an object whose `hardware_source` said
"client". A *chosen* companion is by definition removable, so v2 was
unbuildable until that was fixed. It shipped separately, as `1932f20`.

---

## 3. Two traps, recorded because they are not obvious

**`JSON.parse('995626')` returns the Integer 995626** in modern json. A naive
"try to parse it, and if it raises it must be legacy" would silently turn a
single v1 companion code into a number. The lift keys off the leading bracket
instead, and a test pins it.

**Presence must be decided on the logical value, before encoding.** `[]` means
no companions and the key is not written; `"[]"` is a perfectly non-empty
String and would be persisted as data.

---

## 4. Still open

- **The kit depth for a d.62 carcass.** p.569 prices every kit at both d.50 and
  d.60 and nothing pairs either to a carcass. Elda estimate position 14 settles
  it without our having to ask. **Do not borrow `legrabox_runners`**: the
  manifest marks it *"NOT a Cesar source fact"*, it is Elda Q2, and it is
  quantised differently (d.620 → NL 550, a value p.569 does not offer).
- **Nothing can produce a chosen companion yet**, and a test over all 180 codes
  proves the generator never does. It needs a catalog to resolve from
  (`registry/cesar/options/`, p.568-569) and a person to choose — the panel's
  second job, which records something that rebuilds nothing.
  *(2026-08-24: five positions in five chapters now wait on that catalog.)*
- **"DO NOT fit against the wall" is a placement restriction** — the first
  catalog rule that contradicts the place tool, which seats units against walls
  on purpose. It also explains the 155° hinges: the door has to clear the
  drawers. Policy should match the five-centimetre closing strip: **warn, never
  move the unit.**
- **`restrictions` still has nowhere to be written** — three facts now wait on
  that empty key. *(2026-08-24: more than three. The width restriction, the hob
  provisions and the wall-fixing notice all queue there too.)*
- **Where p.568-569 belongs in `catalog_map`.** The accessories chapter has its
  own printed index and we have never mapped it. Rule 1: a section is one the
  printed index prints.

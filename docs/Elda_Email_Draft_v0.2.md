# Elda Email Draft v0.2 — engine technical questions (Q1 + Q2)

**Project:** Cesar Dealership / UCON Cabinet Supply System
**Prepared by:** UCON Contemporary Interiors · 2026-08-16
**Supersedes:** Elda_First_Pass_Email_Draft_v0.1 (workflow-gate email, July)
**Source basis:** docs/Elda_Open_Questions_v0.1.md (Q1, Q2)

The July v0.1 draft asks the broad workflow-gate questions and stays valid as
the FIRST email. This v0.2 is the focused technical follow-up carrying the two
questions the Cabinet Engine cannot resolve from the catalog. It can also be
merged into the first email as a short technical annex if only one email is
preferred.

---

## Subject

**Cesar base units — two technical confirmations (door version notation, drawer runners)**

## Body

Hi Elda and Giorgio,

While building our preliminary SketchUp planning library from the Kitchen
System catalog, two questions came up that the catalog alone cannot answer.
Both are short.

**1. Order notation for the door version (handle / gola).**
On the base-unit pages each unit is drawn with two door-height elevations
30 mm apart (for example H.78 shows "78" and "75"), but only one article code.
The taller front is the door with handle / push-pull version and the shorter
(−30 mm) is the grip-recess (gola) version, where the horizontal gola profile
takes the top 30 mm and is ordered separately as a GOL line item. Since the
single article code does not distinguish the two versions: how should the
chosen door version be specified in an order? Is it a free modification flag
("with grip recess" / "with handle" / "push-pull"), or does the grip-recess
version of the cabinet carry its own modification code or surcharge in the
current price list (separate from the GOL profile line)?

**2. Drawer runner travel at full extension.**
For plan drawings we show fully extended drawers. The catalog describes
LEGRABOX runners qualitatively (soft-close, full extension, 40/70 kg) but does
not state the fitted runner length or travel. For H.78 base units at depths
62 and 67 (and 35 where applicable): which LEGRABOX nominal lengths are fitted
per carcass depth? We are provisionally assuming NL 550 at d.62 and NL 600 at
d.67 (travel ≈ NL − 2 mm) and would like to confirm or correct this.

Both answers go straight into our planning library so that everything we later
send in quote-request packages matches your ordering rules.

Best,

Andriy Demko
UCON Contemporary Interiors

---

## Internal notes

- Q1 status: engine models the full-height (handle) front by default; gola is
  an explicit per-unit choice with a mandatory GOL line (undercounter GOL001 or
  GOL005 for door units; pairs +GOL002/GOL006 for drawer stacks).
- Q2 status: interim Blum table (user-provided) drives plan symbols; marked
  external to the Cesar source system in the registry; answer replaces it.
- On answers received: registry entries move PRELIMINARY → CONFIRMED per the
  Object Contract; log the written confirmation against Q1/Q2.
- This draft does not authorize pricing, ordering, fabrication, or client
  commitments.

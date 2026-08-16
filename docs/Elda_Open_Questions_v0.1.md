# Elda / DzineElements — Open Questions (Cabinet Engine)

**Org:** UCONSD · **Document role:** Living register of open factory-confirmation questions
raised by the Cabinet Engine · **Version:** v0.1 · **Date:** 2026-07-29 · **Status:** Working

These are questions the source PDF alone cannot resolve. Each stays open until a written
Cesar / DzineElements (Elda / Giorgio) confirmation is linked. Nothing here advances past
`CONTROL` / becomes `CONFIRMED` until answered.

---

## Q1 — Order notation for the door-version choice (opening method)

**Status:** open

**Context / what is already settled.** For a base unit, the article code is the **same**
for the "with handle / push-pull" version (full door, e.g. 78) and the "with grip recess"
version (short door −30 mm with top cutout, e.g. 75). This is confirmed: the Kitchen System
pages (printed p.36 / PDF 38) show both door-height elevations over a single code table,
and the grip-recess (gola) profile is ordered separately as a `GOL` line item. The opening
method is modeled as a separate axis (`opening_method`, see Object Contract §4.1), not part
of the code.

**What is still unclear (the actual question).** Since the article code does not carry the
door version:

1. How should the choice be specified in an order — a free modification flag
   ("with grip recess" / "with handle" / "push-pull"), or something else?
2. Does the grip-recess version of the **cabinet** carry its own modification code or
   surcharge in the current price list, separate from the `GOL` grip-recess profile that we
   already order as its own line?

**Affected families:** Maxima / Intarsio / Tangram base units with paired door-height
elevations — H.39, H.48, H.58.5, H.78, H.84.

**Disposition until answered:** model the full-height (`handle`) front by default; treat the
`gola` (−30 mm) front and its `GOL` profile as a separate, non-default option; keep all such
items `PRELIMINARY` and `P3` where the notation affects orderability.

**Draft text to send (EN):**

> On the base-unit pages, each unit is drawn with two door-height elevations 30 mm apart
> (for example H.78 shows "78" and "75"), but only one article code. The taller front is the
> "door with handle / push-pull" version and the shorter (−30 mm) is the "with grip recess"
> version, where the horizontal grip-recess (gola) profile takes the top 30 mm. Since the
> single article code does not distinguish the two: how should we specify the chosen door
> version in an order? Is it a free modification flag ("with grip recess" / "with handle"),
> or does the grip-recess version of the cabinet carry its own modification code or surcharge
> in the current price list (separate from the `GOL` grip-recess profile, which we already
> order as its own line)?

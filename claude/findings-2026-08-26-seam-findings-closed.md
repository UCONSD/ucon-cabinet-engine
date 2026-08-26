# 2026-08-26 — the seam's four findings, answered

Core 0.82.0. The appliance package is **untouched** — `void`, `opening_h` and
`matches_niche?` all predate this and the installed 0.2.0 `.rbz` already has
them, so there is no rebuild in this change. Two clocks, and only one of them
moved (§11).

Suites: `test_contract` **463, 0** (460 before the new checks) ·
`test_appliances` **68, 0**, untouched · `test_appliance_seam` **30, 0** (25).

The findings themselves are `claude/findings-2026-08-25-appliance-seam.md`,
which recorded them and deliberately changed nothing: *a plausible fix is not a
decided one*. Andriy decided all four on 2026-08-26 and the decisions are
`claude/appliance-rules-decided.md` §13.

## 1. The housing now starts on the FLOOR

`usa_tall_h210.appliance_niche.bottom` was `plinth_top`; it is `floor`.

The 2026-08-22 decision that put it on the plinth was right about the elevation
and wrong about the machine, and the wrongness had a size: drawn from the plinth
top the opening came out **2033,6** where the column needs **2133,6**. The top
was correct the whole time, which is why comparing tops alone called it a match
and why `matches_niche?` grew a height comparison on the day it was found.

**The reversal is recorded, not erased** (rule 9): the old `bottom_note` stands
and `bottom_correction_2026_08_26` sits above it saying what changed and why.

**The plinth line still runs.** The family keeps `plinth_continues`, so the
plinth box is still drawn across the front — and the housing now says on itself
what that box is:

> The machine stands on the FINISHED FLOOR and the housing is drawn from it. The
> plinth box in front is a REPRESENTATION that keeps the plinth line unbroken on
> the sheet, and the plinth ORDERED there is one with a cutout.

That is the dishwasher's sentence read from the other end. There the BODY was
raised to keep the line; here the LINE is kept in front of a body that starts on
the floor. Both are representations and both have to admit it.

**Two checks changed subject rather than changing meaning.** *The housing behind
a panel starts at THIS family plinth* used CR9601 as its witness and began
reporting 0.0 for a rule that was never about CR9601 — the rule is that a
`plinth_top` datum reads the FAMILY's plinth and not a global 100. The dishwasher
still states `plinth_top`, deliberately, so it is the witness now. And *the
bottom must be named, not numbered* accepts either name: what it has always been
about is that the datum is a WORD, because a word cannot drift away from the
family that owns it.

## 2 and 3. Width and depth — two states, and the object says which

Decided the other way, on purpose.

The drawing keeps the Cesar door nominal for the width and the run's own depth,
**and the machine's published cutout is not copied onto the object.** A second
copy of a published number is a second thing to go stale; the seam asks the
appliance module live, every time.

What changed is that the niche now says all of this in its own notes: the width
is a NOMINAL and not a cutout; for built-in refrigeration the published opening
is NARROWER than the door at a standard install and WIDER at flush inset, from
one number; the depth is MEASURED when a neighbour was selected and DECLARED
otherwise.

**So the depth finding still prints, and that is the decision rather than a
regression.** The seam suite now carries a check called exactly that, so a later
session cannot mistake one for the other.

## 4. The remainder above the housing has a body

66 mm above a Designer column in a 2200 run, 73 above a Classic. The niche note
called that span "the closing panel inside the housing"; no closing panel
existed. **A span named in prose and drawn by nothing is the silent deletion
§4.2 rule 4 forbids, wearing a sentence as a disguise.**

`ApplianceCheck.above_housing` asks the same question `review` already asked and
returns it in millimetres instead of in prose — a generator cannot draw a body
from *"66 left above the housing: filler, carcass, set back 55…"*. The engine
draws `FILLER_ABOVE_HOUSING` from those numbers.

**Not one of the three numbers is ours.** The height is what is left over the
machine's published opening; the setback (55) is an appliance rule, because a
Sub-Zero hinge draws the panel inward as the door opens; the material is one
too. The engine owns only where the run's top is. **So nothing is drawn until a
machine is NAMED** — the same shape as B6's run gap, and for the same reason:
the number that fixes the body does not exist until somebody says which machine
stands there. A suite check asserts that `draw_above_housing` refuses without an
appliance, refuses without the seam, and **contains no 55**.

**The article is open and the object says so.** A filler is priced by HEIGHT and
printed p.434 prints no H.6,6 and no H.7,3, so the object carries no code, sits
at `PRELIMINARY`, and its notes name both offers the appliance rules make. The
exporter already prints such a row as *"CUSTOM SIZE - NO ARTICLE, to be quoted"*,
so it reaches the order as a question. It went to Elda as **Q18**.

**The palette asks one question, in one place.** Building an `appliance_front`
whose family states a housing offers the machines that publish an opening
height; `not decided yet` is the default and a real answer, because a run is
usually drawn before the appliance is chosen. Every other code is built exactly
as before and is never asked.

## What is still open

- **Q18** — the article for the strip. Until it is answered the row is quoted,
  not coded.
- **The depth and width disagreements**, by decision. They print.
- **Nothing was drawn in SketchUp.** Every number above is headless. The filler
  above the housing has never been seen in the model, and the first live run is
  where the front plane, the setback and the plinth overlap get measured rather
  than reasoned about — which is exactly how B6's 880 turned out to be 920.

---

## THE LIVE RUN, the same afternoon — and it found what live runs find

Probes `build/39_above_housing.rb` (run 1–2) and `build/40_front_vs_filler.rb` (run 3),
through `tools/probe_bridge.rb`, in the Avenida Primavera model. Both roll back; 39 also
erases what it drew, because it is the first thing that has ever drawn this body.

**The stale core answered for itself.** Run 1 stopped at a guard rather than at
`undefined method`: the core in memory was 0.81.0 and the repository 0.82.0. Run 2 called
`CabinetEngine.load_core` from inside the probe — the same thing the palette button does —
and went on. **A probe that can fix a stale core in one line is better than a round trip
that says "press the button".** The guard and the reload both stay in the file.

### What held

- **The installed appliance package needs no rebuild, MEASURED not assumed.** 0.2.0 in
  Plugins answers `void`, `opening_h`, `matches_niche?`, `run_gap?` and `all`; 20 machines
  publish an opening height. The two clocks did not bite this time, and now it is a reading
  rather than an expectation.
- **The housing measures 0 → 2133,6 for all three USA doors** — CR9700, CR9900, CR9601.
- **The remainder is what the headless suite said**: 66,0 over `DEC3050R/L`,
  73,0 over `CL3650UID/S/T/R`, offer `filler`, material `carcass`, setback 55.
- **The body lands where it was designed to.** Drawn at the origin: x 0..762, y 30..48,
  z 2134..2200. Front plane is y −25, so the strip is set back **exactly 55,0**; it is 30
  behind the carcass front; it tops out at 2200,0 with a gap of −0,0 to the front's top.

### What it found — THE FRONT AND THE FILLER CLAIM THE SAME BAND

The Cesar front is drawn from the plinth top to the top of the run: **z 100 → 2200**, y −25
→ −3. The filler is **z 2134 → 2200**, y 30 → 48, same x. **They share 66 mm of elevation**
(73 for the Classic), and the front stands 55 mm in front of it.

**So on a LayOut elevation the panel hides the new body completely.** Two bodies claim one
band, and the drawing shows only the front one — which is exactly the failure mode the
remainder was drawn to end. A span nobody can see is not much better than a span nobody
drew.

**Only a decision says which body is wrong**, and both readings are coherent:

- **the Cesar panel is too tall.** It is drawn 2100 NOMINAL, from the family height, and
  **nothing anyone has read says what height Sub-Zero specifies for a `DEC3050` door
  panel.** Our own appliance record publishes the OPENING (w 762, h 2134, d 635, from
  `subzero-design-guide.pdf` rev 4/2026 p.46) and says nothing at all about the panel. If
  the door panel is the machine's height, the front should stop near 2134 and the 66 mm
  above it is a VISIBLE face — which is also why the appliance rules set it back 55: so the
  door panel below can swing past it.
- **or the filler is behind the panel by design** and is a backing strip nobody sees, in
  which case the 55 setback is doing something else and the elevation is already right.

**The registry states the first reading as settled and it is not.**
`usa_tall_h210.representation_notes` says *"HEIGHT NEEDS NO CUSTOMISATION… 2200 is TALLER
than the appliance, so nothing is short and nothing has to be trimmed to fit. The door
extracted here serves as it stands."* That is an argument about FITTING, and the question
here is about what the panel IS. The note is not wrong; it answers a different question.

**Nothing was changed on the strength of it.** Rule 1: a plausible fix is not a decided one,
and this one needs a page read rather than an opinion — `subzero-design-guide.pdf` is not in
`sources/`, it is pulled on demand.

### And a 0,4 mm sliver, named because it is two numbers for one plane

The housing tops out at **2133,6** — 84 in converted exactly — and the filler starts at
**2134**, the millimetre Sub-Zero prints. Nothing is drawn between them. It is 0,4 mm and it
will never matter on a sheet, but it is the same shape as everything else in this file: our
conversion and the maker's printed number are two facts, and the drawing currently holds
both without saying so.

---

## THE PAGE WAS READ, and it says the panel is shorter than we draw it

Andriy, 2026-08-26: read the Sub-Zero page rather than decide the overlap. Done — the
guide is not in `sources/` (it is pulled on demand, and this session could only fetch
answers from it, not the file). **Read via WebFetch from
`subzero-design-guide.pdf` rev 4/2026, pages 49–51, by a machine and not off a printed
page — treat it as `trust: fetched`, one notch below a page Andriy has in front of him.**

### The typical Designer column panel

> "Typical panel dimensions are based on an **84" (2134) finished height** for column and
> tall models", with a **4" (102) toe kick** and **1/8" (3) reveals**. Panel height
> **79 7/8" (2029)**. Panel width: 18" model 17 3/4" (451) · 24" 23 3/4" (603) ·
> **30" 29 3/4" (756)** · **36" 35 3/4" (908)**. Minimum panel thickness 5/8" (16), p.49.

**The arithmetic closes exactly, which is the strongest thing about this reading:**

```
   102  toe kick
+ 2029  panel
+    3  reveal at the top
------
  2134  = 84 in, the published opening
```

### What that does to our drawing

| | Sub-Zero typical | what the engine draws | difference |
|---|---|---|---|
| panel bottom | 102 (4" toe kick) | 100 (Cesar plinth H.100) | **2 mm — we were right** |
| panel height | **2029** | 2100 (family nominal) | **71** |
| panel top | **2131** | 2200 | **69** |
| panel width, 30" | 756 | 762 (nominal) | 6 |
| panel width, 36" | 908 | 914 (nominal) | 6 |

**The bottom datum is confirmed and needs no change** — Cesar's 100 plinth and Sub-Zero's
4" toe kick are the same line to within 2 mm. Only the TOP is wrong, and it is wrong by
69, not by the 66 the seam reports: the seam measures to the opening top (2134) and the
panel stops 3 mm below it for the reveal.

### And this sharpens the real question, which is not about 66 mm at all

`usa_tall_h210.representation_notes` decided on 2026-08-21, with Andriy:

> "WIDTH IS DRAWN NOMINAL, NEVER NET. A 30-inch panel is drawn 762 wide, although the panel
> actually supplied is a little narrower — and how much narrower is set by the APPLIANCE'S
> OWN SPECIFICATION, not by Cesar."

**That rule is now measured and it holds beautifully in the width axis: 762 nominal against
756 supplied, 6 mm, three per side — a reveal, exactly as predicted, and nobody wants it
drawn.**

**In the HEIGHT axis the same rule produces 69 mm, and 69 mm is not a reveal. It is a span
big enough to need its own article** — which is the very body owed 10 finding 4 just built,
and which the nominal panel then hides.

> **A rule that is right in one axis is not automatically right in the other, and the test
> is not the rule's wording — it is the size of what it leaves over.** Three millimetres is
> a reveal. Sixty-nine is a part.

### What stands in the way of simply shortening the front

`Registry.height_modification_refusal` refuses a height change on `appliance` and
`appliance_front` OUTRIGHT, and the reason is ours rather than the page's: *an appliance
housing takes its opening height from the appliance, not from the carcass.* Written for the
housing, it now also refuses the panel in front of it. **Deciding that the panel is 2029
means deciding what that refusal is actually about.**

And the catalog half is unanswered: whether Cesar supplies a USA appliance front at 2029 at
all, and whether that is a printed height reduction or an unprinted request, is **Elda Q17**,
still open.

### A second number wearing one name — 45 against 55

The guide, p.51: *"A DECORATIVE VALANCE CANNOT EXTEND BEYOND THIS PLANE"*, at **1 3/4"
(45)**. Our appliance rules set the filler above a housing back **55** from the cabinet
front, `applies_to_brands: [Sub-Zero]`, reason *the hinge draws the panel inward*.

**Two setback numbers for the region above the same machine, and nothing yet says whether
they are the same rule read twice or two different rules.** Not reconciled here on purpose:
55 came from somewhere and this session did not find where, and 45 came from a fetched page.
Naming the collision is the finding; resolving it needs both sources open.

### DECIDED, same afternoon: the nominal rule keeps the height axis

**Andriy, 2026-08-26.** The front stays 2100. The 2026-08-21 rule — *width is drawn
nominal, never net* — was confirmed by measurement in its own axis (762 drawn, 756
supplied) and governs the height axis too.

**So the filler above the housing is an ORDER LINE and not a face.** Somebody must still
make it; the sheet will not show it. The object says exactly that in its notes —
`NOT VISIBLE ON AN ELEVATION` — together with the 2029 that makes it true, and
`test_contract` holds a check of the same name. An invisible body with nothing on it
saying why is how a later session comes to "fix" the front.

**What this deliberately does NOT do:** 2029, 102, 3, 756 and 908 stay OUT of the registry
and out of `appliances.json`. They were read by a machine from a PDF, not by Andriy off a
printed page — `trust: fetched` — and the decision does not use them for geometry. They are
recorded here, where their provenance is visible, and nowhere that a later reader would
mistake them for catalog.

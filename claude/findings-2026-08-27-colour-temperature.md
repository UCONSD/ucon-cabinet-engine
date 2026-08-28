# Colour temperature across the Cesar catalogs — 2026-08-27

> Совсем забыл. Посмотри, пожалуйста, в каталогах выбор температуры цвета. Ты
> даже не представляешь, сколько у меня было проблем с тем, что приезжала не та
> температура цвета.

Read the Lighting chapter of Volume 2 end to end (printed **p.527–546**) and
swept all five books for a Kelvin figure. **The answer is better than expected,
and the risk he has been burned by is not the risk this catalog carries.**

## 1. There is no colour temperature to specify, on any lamp in the book

Every lit product in the Kitchen System is **dual-colour and adjusted on site**.
Not "available in 3000K or 4000K" — one article that is both.

| printed | product | temperature |
|---:|---|---|
| 528 | **Sky-B** led light lamp | 3000K → 4000K, Emotion Dual Color device **provided** |
| 530 | Kiton | 3000K → 4000K |
| 531 | Bali | "Dualcolor lamp 3000k/4000k" |
| 532 | Oslo | 3000/4000°K |
| 533 | Mini noor | 3000K → 4000K |
| 535 | Easy Sunrise spotlight | 3000K → 4000K |
| 536 | Sunrise spotlight | 3000/4000°K |
| 537 | **Solaris back panel** | **2700K → 6500K** — the one outlier, warm to cold |
| 538 | Wall waiter | 3000/4000°K |
| 539 | Luminous glass shelf H.2,8 | 3000/4000°K — *not held: 110V only* |
| 540 | Vivara semi-recessed | 3000K → 4000K |
| 541–542 | Across | 3000/4000°K |

printed p.528, verbatim:

> Emotion Dual Color device provided to adjust the light from 3000K to 4000K.
> Available with remote control, sensor or integrated IR proximity switch to turn
> the light on and adjust its temperature.

**So no order line states a temperature, and therefore no delivery can carry the
wrong one.** Whatever went wrong on his past jobs cannot go wrong the same way
here — those were fixed-temperature strips ordered by SKU, and this is not that.

## 2. THE RISK THAT REPLACES IT, and it is a real one

The temperature is adjustable *by a control*, and the control is a separate
decision. A Sky-B ordered as the plain per-metre lamp with no switch, no sensor
and no remote is a lamp **nobody can re-temperature after it is installed** — it
comes up at whatever the device defaults to and stays there.

Four ways to get the adjustment, and one of them has to be on the order:

* the **with-switch** version of the lamp (a different code, +24 points/m);
* an **IR sensor** — printed p.529, `991I00` one sensor 32 pts, `991I01` two 65 pts;
* the **remote control**, which needs the distributor *with integrated antenna*
  (`991I0E`, 87 pts) rather than the plain one;
* the **IR DOOR TUBE** — printed p.544 — which adjusts colour "by shutting the
  door 3 consecutive times". Charming, and useless on an open shelf.

**On an open shelf the door tube is out**, so a lit shelf here is the with-switch
lamp, or a sensor, or the remote. That is a question for Andriy, not a default.

## 3. What a lit shelf actually costs in lines — printed p.529 and p.543

Read, and **not yet extracted as articles**. Codes recorded here so nothing gets
invented later; the letter in them is a capital **I**, not a one.

| what | code | points | note |
|---|---|---:|---|
| Sky-B, per lm, no switch | `991I50` | 96 | 10 W, **max 3,9 m** |
| Sky-B, per lm, with switch | `991I60` | 120 | 10 W, max 3,9 m |
| IR sensor | `991I00` | 32 | |
| IR sensor, 2 | `991I01` | 65 | |
| Power adapter EU | `991I0A` | 65 | 48 W |
| **Power adapter US** | `991I0B` | 65 | 48 W — **this is the one for this project** |
| Power distributor, USA version | `991I0F` | 127 | one serves **8 lamps** |
| Power distributor with antenna | `991I0E` | 87 | needed for the remote |

printed p.543: **"Transformer kit (mandatory for all lamps)"**, and the cable
provided goes 110V to 220V — "there is no longer any need for different
equipment", max 45 W. So a lit shelf is *never one line*: lamp + transformer +
whatever does the switching, and the distributor amortises across 8 lamps.

## 4. THE CATALOG'S OWN CROSS-REFERENCE IS WRONG, and we had copied it

Linear Elements printed p.224 says:

> The Sky-B light can be fitted on the shelves (see the Kitchen System price list
> on page 526.

Printed p.526 of the Kitchen System is **Waste bins | Monolith**. The Lighting
chapter opens on p.527 and the Sky-B is **p.528–529**. Off by two, and not the
+2 PDF offset — this is printed-to-printed.

Our own `led_rule` had `"printed p.526 - NOT extracted"` in it, because I wrote
down the cross-reference instead of following it. A wrong reference copied
faithfully is still a wrong reference, and it would have sent whoever extracts
this chapter to a page about bins. Both the correction and the catalog's error
are now in `led_rule`, the second one on purpose: `cross_reference_error`.

## 5. What went into the code

* `led_rule` gains `colour_temperature`, `colour_temperature_k`, `beam_angle_deg`
  (96), `illuminance_lux`, `lamp_max_length_mm` (3900), `transformer_note`,
  `label`, the corrected `lamp_source` and the `cross_reference_error`.
* **The temperature is now on the object and on the drawing.** The variant's
  sentence carries it, the properties panel says "adjustable on site, nothing to
  specify on the order", and the elevation symbol is labelled `LED 3000/4000K`.
  Three places, because the one fact he has been burned by should be hard to miss.
* Contract **v2.3**: a variant may carry a `label` — the same choice in three
  words, for a drawing.
* And a gap found by accident: **`points` was not in `COMMERCIAL_MARKERS`**. The
  unit this entire catalog is priced in, and §1.2's scope check did not name it —
  it was caught only by the unknown-key sweep, which reports a typo rather than a
  scope breach. Added.

## Owed

* **Extract the Lighting chapter?** printed p.527–546. Not started, and not
  started deliberately: it is a real chapter with per-metre pricing, a mandatory
  transformer, a US-versus-EU adapter choice, and a distributor whose quantity
  depends on how many lamps the whole kitchen ends up with. Half-extracting it is
  worse than the honest `NOT YET EXTRACTED` the object carries now. **Andriy's
  call**, and the Metron estimate will show what she counted.
* Which control the lit shelves get. Not a default — see §2.
* The `Solaris back panel` at 2700–6500K is the only product in the book with a
  different range, and nothing here holds it.

---

## Second pass — Andriy was right that there is a choice, and I was wrong about what it is

> Должна быть опция выбора температуры цвета. Смотри в каталогах.

I had answered "there is nothing to choose" and stopped. That was the wrong end
of the question. Looked again, across all five volumes, page by page:

**There is not one lamp sold at a fixed colour temperature anywhere in the five
books.** Every stated temperature is a range the Emotion Dual Color device
adjusts — 3000/4000K throughout the Kitchen System, 2700>6500K on the Solaris
back panel, 2700>6000K on the Bathroom mirrors. Nothing prints a single figure.
(The sweep found four candidate pages naming one temperature; all four were a
range split across a page break.)

So both halves are true at once, and I had only said the first:

* **The article cannot be wrong.** The same code is supplied whichever
  temperature is wanted, so no delivery carries the wrong one.
* **The setting can be wrong, and nothing was preventing it.** The device is
  adjusted on site. If nobody says which temperature, it is left wherever it
  powers up. **That is the failure he has been burned by** — not a wrong article,
  a missing instruction — and the engine had no place to put that instruction.

He asked for an option. He should have one. It is not an article option; it is a
**commissioning instruction**, and it is now recorded as one.

### What it does

* `led_rule.colour_temperature_options` — `["3000", "4000"]`, from the page. A
  lamp with a 2700–6500 range would offer that instead, with no code changing:
  the dialog builds the list from the rule.
* A **Colour temperature** select in the Light fieldset, shown while the light
  is on.
* **The unset case is a warning, not a blank.** Silence is the defect here, so an
  unchosen temperature says so on screen — *"the same article is supplied either
  way, so nothing can arrive wrong, but nothing tells the installer either"* —
  and on the object: `TEMPERATURE NOT SPECIFIED. The device adjusts 3000/4000K
  and will be left wherever it powers up unless somebody sets it.`
* Chosen, the object reads `SET TO 3000K on commissioning - a setting, not a
  code: the same article is supplied either way.` The phrase "not a code" is on
  the object on purpose: the next person to read it must not go looking for a
  second article number.
* The elevation label follows: `LED 3000K` when set, `LED 3000/4000K` when not.
* Anything the page does not offer is **refused in Ruby**, not only in the
  dialog — `2700K is not a temperature this lamp offers…` naming p.528. Same
  reason `gola_available?` is checked twice: a rule that lives only in HTML is
  not a rule.

A bug caught by its own check while writing it: the panel first read the chosen
temperature back out of the *label*, and the unset label is `LED 3000/4000K`,
which a naive four-digit match reads as **4000** — a decision nobody took,
appearing in the dropdown as though someone had. It now parses `SET TO ####K`
out of the instruction sentence instead, which only exists when a choice was
actually made.

### THE ONE LAMP WITH NO TEMPERATURE AT ALL

**Strip reel, printed p.534** — `991B50` per lm, `991B55` a 3-metre cable, 120°
beam, up to 5 m, cut to size. The page prints **no colour temperature anywhere**,
neither a figure nor a range. Read on the render, not the text layer.

Every other lamp in the book says what it adjusts between. This one says nothing,
and it is the only product where "the wrong temperature arrived" could mean the
factory rather than the installer. **An Elda question**, and the only one this
chapter generates.

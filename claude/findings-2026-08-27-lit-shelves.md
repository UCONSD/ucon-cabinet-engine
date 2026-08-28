# Shelves with light — three shapes, and one of them is blocked at 110V (2026-08-27)

A reading, on Andriy's word. **Nothing extracted.** Searched all five volumes for
light terms co-occurring with shelf terms; everything below is Kitchen System
unless said otherwise.

## The catalog uses three different shapes, and Andriy's "option / upgrade" idea is already two of them

### 1. The light IS the shelf — **printed p.539, Luminous glass shelf H. 2,8**

> *"In black aluminium with 4mm thick smoky grey tempered glass, for recessing
> inside the cabinet. 2.8 cm thick. Supplied with a 24V, 3000/4000°K led light
> lamp. Standard controls designed for a switch."*

- **Modularity 45 / 60 / 90 / 120.**
- **Load: 40 kg at 45, 54 kg at 60, 84 kg at 90-120.** The only shelf in this
  catalog that prints a load at all.
- Two families on the page: **for wall units, d.28**, and **for base and tall units**.
- *"the hole in the back panel to let the electric cable through must be drilled
  by the customer."*
- **NOT AN OPTION — it is its own article.** There is no unlit version of it.

### 2. The light is a SURCHARGE on the module — **printed p.459-460, Horizontal Thin**

*"Surcharge for lights"* — **274 / 303 / 331 / 360**, one per position, beside
each of the four codes. Same article, plus points. **This is exactly the upgrade
line Andriy described**, and the catalog already writes it that way.

### 3. The light is an ACCESSORY fitted to a shelf — **printed p.461 and p.541**

**MINI NOOR led light**, p.461:

| | W. | code | points |
|---|---:|---|---:|
| for shelf | 180 | `991M10` | 91 |
| for shelf | 240 | `991M11` | 120 |
| full-length for back panel | 180 | `991M20` | 183 |
| full-length for back panel | 240 | `991M21` | 240 |

**Across**, p.541 — an island worktop light: two 45 cm uprights and a rail with an
integrated led, touch controls, Emotional Dual Color, 3 m cable, black aluminium.
Modularity 45/90/120/150/180. **Minimum 8 cm from the hob. Cannot be installed on
a glass top.** And p.542, the same bar as an *interior cabinet light* fitted
under a shelf inside a unit.

## The pattern that runs through all three: THE POWER IS NEVER INCLUDED

- Luminous shelf: *"To be ordered separately: 50W power adapter kit, multisocket
  extension lead + cable with plugs"* — `997820` **83**, `997821` power adapter
  **+ IR** **219**.
- Horizontal Thin: *"Power adapter not included"*, printed beside all four
  positions.

**So a lit shelf is never one order line.** Whatever shape it takes, the light
carries a supply that is priced separately — which is the same companion problem
as the panel fixing kit: a quantity that comes from the INSTALLATION and not from
the article.

## TWO FLAGS FOR A US PROJECT, and the first one is hard

**`110V` appears exactly twice in the whole Kitchen System, and one of them is
this:**

- **printed p.539 — *"Not available version 110V."*** On the luminous glass
  shelf, and it is the only such exclusion printed anywhere in the book. If 545
  Avenida Primavera is 110V, **shape 1 is off the table** whatever it costs.
- printed p.543 — *"The cable provided can be used to go from 110V to 220V; there
  is no…"* (a different item). So the book does contemplate the change somewhere.

**Not resolved, and not guessable from the page**: whether the other two shapes —
the Thin surcharge and MINI NOOR — are 110V-capable. The book says nothing, which
is not the same as yes.

## And an ambiguity worth naming before anyone extracts

The Thin's **"Surcharge for lights" 274-360** and the **MINI NOOR codes 91-240**
are different numbers for what looks like the same lamp on the same module.
Whether the surcharge is the preparation and the accessory is the lamp, or the
two are alternatives, neither page says. **Do not extract either until that is
settled** — a wrong reading here doubles or halves a line.

---

## 2026-08-27, later — three complaints, and the second one was a real bug (core 0.96.1)

Andriy, after reloading the core to 0.96.0:

> В общем, не получилось ничего. Нам не нужны предустановленные опции. Это для
> филеров 3, 10, 15. Достаточно просто выбрать ширину. Второе. Я не вижу, чтобы
> лайт как-то изображался. И кор, я обновил. Ну и то же самое. Я выбираю Light,
> ставлю Check Box. Убираю выделение. Снова выделяю этот же объект. Light не вижу.

Three complaints, three different causes. They are worth keeping apart because
only one of them was a bug in the thing he was complaining about.

### 1. The width presets — a label problem, not a bug

50 / 100 / 150 are the FILLER widths. They were rendered for every article with
a width range, so a shelf offered them too, and a shelf is cut anywhere between
its own minimum and 3000. Gated on `c['class'] === 'filler'` in `90_palette.rb`.
Nothing else changed: the width box was always there and always worked.

### 2. THE LIGHT WAS WRITTEN AND NEVER DRAWN — `Generator.effective` dropped it

Everything in the chain was right except the join between two of the parts.

* `Panel#attributes_patch` → `led_patch` wrote the variant correctly.
* `Contract` encoded it to JSON, stored it, decoded it back correctly.
* `Symbols#draw_led` knew how to draw it.
* `Panel#apply` handed `Symbols.draw` a `chosen` object built by
  `Generator.effective(unit, attrs.merge(patch))` — **and `effective` carries
  only `INSTANCE_KEYS` (`mounting`, `mount_bottom_mm`) and the ordered width.**

So `chosen` had no `variants`, `draw_led` returned at its first line, silently,
every time. Verified headlessly before touching anything: the Ruby round trip
(offer → patch → encode → decode → `led_chosen`) came back `true` at every step,
which is what pointed at the merge rather than at the storage.

**This is the fourth instance of learned rule 11 this year** — a key written
correctly that the thing needing it is never given. `wall_hung` (2026-08-22),
`height_range_mm`, the shelf's `mounting`, and now `variants`. The first three
were `Registry.lookup` not lifting a key out of a section file; this one is
`Generator.effective` not lifting a key off the OBJECT. Same shape, other end of
the pipe. A check now pins it, and pins the negative too: an object nobody has
lit must not acquire a light from the merge.

### 3. …and it would have been in the wrong place anyway

Every symbol in `70_symbols.rb` is drawn 1 mm proud of the FRONT LINE, and the
front line is 25 mm clear of the carcass (`FRONT_GAP_MM + FRONT_T_MM`). A shelf
has no front. Drawn at that y, the light would have floated 26 mm out ahead of
the board with nothing between them.

`Symbols.led_y_mm(unit, y_face)` now answers −1 for anything whose
`front_layout.kind` is `none`, and the front line for everything else. Pure and
separate from the drawing so it can be checked headlessly — which is the only
reason it is a method and not two lines inside `draw_led`.

The light stays on `TAG_FRONT`, so the elevation button switches it off with the
door swings. That was the request.

### 4. The checkbox that would not stick — already fixed, and he could not have got it

`apply()` reached for `st.attrs`, and `st` is `render`'s parameter: a
ReferenceError in an HtmlDialog callback, where nothing is visible. Fixed in
0.96.0 with `STATE`. **He reloaded the core to 0.96.0 and saw no change, and
that is correct behaviour, not a second bug:** an HtmlDialog bakes its HTML *and
its callbacks* at open. Reloading the core replaces the Ruby; the open window
keeps running the 0.95 JavaScript. The panel has to be CLOSED AND REOPENED.

Since a person cannot be expected to know that, the dialog now says it itself:
the HTML bakes `BAKED` at open, `selection_state` sends the loaded
`core_version`, and `render` shows a yellow banner when the two differ.

`Panel.core_version` is guarded — `00_version.rb` is not in the headless suite's
load list, and 11 checks went down with `NameError` before it was.

### Still owed

* The light has no article. The Sky-B is priced in *2 Kitchen System* printed
  p.526, which this registry does not hold — so the choice travels as a Contract
  VARIANT with the page named on it, and becomes an order line the day that
  chapter is extracted.
* `MNS040038` is 380 deep where p.224 recommends wall supports only to 350.
* No back-panel support is printed for the 4 cm shelf.

---

## 2026-08-27, later still — the light WAS there, and was five pixels tall (0.96.2)

> Смотри, я когда ставлю чекбокс я вижу, что блок выделения увеличивается. Это
> значит, что что-то, но там рисует объект какой-то скрытый. Я не вижу
> обозначение lights своими глазами. Возможно, он в скрытом теге или скрытом слое.

The bounding box growing was the right thing to notice, and it ruled out the
whole class of cause he suspected: something was being drawn. A read-only probe
into the open model (`tools/probe_inbox/led_where_is_it.rb`) answered the rest
in one run, on the selected `MNS040038`:

```
UCON — Opening (front)       visible=true  line_style=Dash
CARCASS   layer=Layer0                  x 0.0..874.0  y 0.0..380.0  z 1400.0..1440.0
SYM_LED   layer=UCON — Opening (front)  x 1.5..872.5  y -1.0..-1.0  z 1387.0..1399.0
   11 edges, hidden=false, mat=UCON_Symbol_Gray
```

Not a hidden tag. Not a hidden layer. Not a hidden entity. Not the wrong
material, not the wrong place: right tag, visible, unhidden, gray, 1 mm in front
of the board and 1 mm under it, inset 1,5 at each end exactly as p.224 says.

**It was correct and it was invisible, and those are not the same thing.**

On the north-wall elevation as he had it, 874 mm of shelf spanned about 350
screen pixels — **0,4 px per mm**. So:

* the spine, drawn 1 mm under the board, landed **0,4 px** from the board's OWN
  bottom edge. On top of it, in other words.
* the ticks, 12 mm, were **5 px** long.
* and there were five of them across 874 mm, which at that size is not a symbol,
  it is dust.

Every number had been chosen for correctness against the page and none of them
had been chosen for legibility, because I never asked what the symbol would
measure on the drawing it exists for. The page decides the LAMP; the drawing
decides the MARK. Two different questions and I only answered one.

Fixed by sizing the mark in model units the way a plotted symbol is sized:

| | was | now | why |
|---|---|---|---|
| `LED_GAP_MM` | 1 | **6** | the spine has to clear the board's own edge line |
| `LED_TICK_MM` | 12 | **40** | long enough to survive a dashed line style |
| ray count | fixed 5 | **one per `LED_TICK_PITCH_MM` = 120**, min 3 | five rays is a comb on a 400 shelf and a dotted line on a 3000 one — and these shelves run to 3000 |

`Symbols.led_tick_count` is pure and separate for the same reason `led_y_mm` is:
so the suite holds it rather than a person re-checking it by eye. The check that
does is named *"the light is drawn to be SEEN, and the first one was 5 pixels
tall"*, and it holds the ratios — spine clear of the edge, rays longer than the
gap, count rising with length — not the exact numbers, which are a drawing
judgement and may want tuning once these elevations are plotted at scale.

### What this cost, and the general form of it

Two rounds of "I don't see the light" for two entirely different reasons: the
first was a real bug (the variant never reached the drawing), the second was a
symbol too small to see. The first round's fix is what made the second round
possible to diagnose at all.

**And the probe found in one run what two rounds of reasoning did not.** The
model can be asked. When the complaint is "I don't see it", ask the model where
it is before theorising about tags — the answer arrives with coordinates on it.

---

## 2026-08-28 — the cone turned over, and the facing question was DELETED rather than solved

Two notes from Andriy on the office Mac, and the second is the more interesting.

### The cone was a funnel

> Трапеция должна быть широкая внизу и усеченная вверху.

It was wide at the top and narrow at the foot. That is the shape of something
draining away, not of light. It had survived a round of review because I was
checking whether the mark *fitted* — the 25 mm clearance from yesterday — and
never asked what it *depicted*.

Both constraints hold at once when it is the right way up: the WIDE edge is the
foot, and the foot is what gets capped 25 mm short of each end, so *a symbol
never leaves the footprint of its object* is untouched. The truncated top is
narrower again by the same 25, about 22,6° from vertical at the standard drop.
On an 874 shelf: lamp 1,5→872,5, cone top 50→824, foot 25→849.

`led_cone_top_mm` **refuses** rather than inverting: a board too narrow for the
splay gets the lamp line and no cone. A cone drawn inside out is the exact
mistake being corrected, and it must not come back through the short-board door.

### The label is supposed to disappear

> Тоненькая, как можно тоньше. Еле-еле заметная, светло-серая.

`add_3d_text` with `filled: false` — outlines rather than solid glyphs, the
thinnest a letter can be drawn — and its own material, `UCON_Symbol_Pale` at 190
grey against the 128 every other symbol here uses. A note on a drawing, not a
heading: readable when looked for, invisible when not.

### AND THEN THE FACING QUESTION WAS TAKEN AWAY

> Уже не будет значения, где лицо, где не лицо. Буквы будут написаны наоборот.
> Я просто его разверну руками обычными инструментами со скетчапом. Потому что
> стены могут быть под разными углами.

This is the good one, and it undoes a feature I had shipped the day before.

**The chain of reasoning that produced the turn buttons was sound and the
conclusion was still wrong.** An object could be built back-to-front; there was
no way to correct it; therefore give the person a way to turn it. Every step
follows. What none of them questioned was why the drawing needed a facing at
all — and the answer is that it did not. The symbol sat 1 mm proud of the face,
so the symbol *asserted* a front, so the object needed a front to be right, so
the person needed a control to fix the front.

Move the light to **half the depth** and the whole chain evaporates. That is the
one position equally right from either side. The label reads backwards from one
of them, and Andriy accepted that explicitly rather than asking me to solve it —
which is the correct trade, because the alternative was an engine that has to
know which way a wall faces.

**And the buttons were the wrong tool even on their own terms.** 90/180/270 does
not serve a wall at 37°, and SketchUp's rotate tool serves every angle already.
*A control that handles the easy quarter of the cases while silently failing the
rest is worse than no control, because it looks like the answer.*

Removed: `Panel#turn`, `footprint_centre`, `instance_yaw`, `facing_word`, the
callback, the fieldset, the readout. A check now holds that all of it is gone —
a half-removed control is worse than either state, since a callback without
buttons is dead code and buttons without a callback do nothing.

**What survives is the better half of the original fix**: a shelf seats on the
wall the selected cabinet is against, in that cabinet's own frame. That made the
facing right *by construction*, and it never needed a button.

### The shape of it

Yesterday's lesson was *when someone with the scar tells you the choice exists,
look again*. Today's is its mirror: **when the fix is a control, ask first
whether the thing it controls needs to exist.** I built a way to answer a
question instead of noticing the question was optional. Andriy deleted the
question, and the feature with it.

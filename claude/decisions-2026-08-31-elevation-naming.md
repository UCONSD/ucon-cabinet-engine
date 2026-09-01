# How walls, elevations and runs are named

**Decided 2026-08-31 by Andriy, in the session that followed the order-form
read.** This replaces nothing and erases nothing: every earlier document that
says *west run*, *south base run*, *east wall floor to 3040* or *the north-west
wall is angled* stays exactly as written. Learned rule 9 — a correction is dated
and added, never an edit that erases the mistake — and here it is not even a
mistake, it is an older vocabulary. §6 below is the bridge between the two.

---

## 1. Why the compass loses

Andriy, 2026-08-31: *«мне не очень нравится, как мы называем стены: восточная,
южная, западная. У меня же нету компаса. Зато у нас есть elevations, и у нас
есть разрезы, которые показывают эти elevations.»*

The compass is a fact about the BUILDING. The letter is a fact about the
DRAWING SET. We sell the set, not the building, so the name has to come off the
sheet. Three consequences follow and all three are practical:

- **A compass bearing is not checkable in the room.** Nobody standing in a
  kitchen knows which wall is west, and the one person who does is holding a
  phone rather than a drawing.
- **A bearing does not survive the next project.** *West run* means a different
  thing in every house and nothing at all across a template. A letter means the
  same thing in every set we will ever issue.
- **There is nothing in the model to rename anyway.** `Group#1` is one shell of
  41 faces. There are no wall bodies. The name has never lived on geometry —
  it lives on the SECTION PLANE and the SCENE, which is exactly what Andriy
  said. SketchUp gives a section plane both a name and a symbol; that is what
  they are for.

And the letters already exist without anything behind them: the model holds
`ELEVATION A`, `ELEVATION B`, `ELEVATION C` today, all of them perspective at
fov 35, seven of the eight scenes sharing one camera, **zero section planes.**
This document is not a new convention. It is the one already named, finally
given a rule.

---

## 2. Three layers, and each has exactly one job

| layer | what it is | where it lives | changes when |
|---|---|---|---|
| **Letter** | the identity | section plane, scene name, sheet | never, for the life of the project |
| **Description** | what is on that elevation | the scene's DESCRIPTION field, generated | the design moves |
| **Compass** | which way the plan faces | one project fact, for the site plan only | never |

The letter is the name. The description is a subtitle. The compass is a
footnote that nothing but a site plan reads.

---

## 3. The letter

**Clockwise in plan: A, B, C, D.** Andriy, 2026-08-31.

**OPEN, and the only open thing in this document: which wall is A.** A letter
without a mechanical rule for assigning it is worse than a bearing — a bearing
is at least checkable with a phone, and an arbitrary letter is checkable with
nothing. Clockwise fixes the ORDER; it does not fix the START.

Recommended, not decided: **A is the wall to the left of the main entry into
the room.** It is checkable standing in the doorway with no drawing in hand, it
works in a room that is not a kitchen, and it needs no landmark to exist. The
alternative considered was *A = the wall with the primary sink*, which is
easier to say and fails on two sinks.

This gets settled with the first real elevation and dated here when it does.

**Runs inherit the letter of the elevation that shows them.** *West run*
becomes *Run C* — or whatever letter the mapping in §6 gives it — and from that
day new documents write the letter.

---

## 4. The description is GENERATED, never typed

Andriy's rule, 2026-08-31: the wall is spoken of by what stands on it — the
fridge wall, the range wall, the sink wall — and when two landmarks share a
wall, both are named.

So the description is derived from the model rather than remembered:

- **Landmarks, closed list:** refrigerator, range or cooktop, sink, dishwasher,
  hood, oven or tall appliance column.
- **Order: left to right as the elevation is seen on the sheet.** Mechanical,
  matches how a person reads the drawing, needs nobody's memory. *Refrigerator,
  sink* and *sink, refrigerator* are two different walls and the order says so.
- **No cap on how many are named.** A wall with four landmarks is a busy wall,
  and the long description is the honest one.
- **Nothing on it means no description.** We do not invent *wall units* to fill
  the line. Learned rule 8: a fact no source gives us is not written down.
- **English.** A GC reads it; we do not.

### Why the description does not go in the NAME

**LayOut references a scene BY NAME.** A name that changed every time the range
moved would break sheets that were already laid out. So the name carries the
letter, which is stable, and the description carries the content, which is not.

`ELEVATION A` — name.
`Refrigerator, sink` — description, regenerated.

### And therefore

**The description is never hand-edited.** The next generating pass overwrites
it, and an edit that a pass silently discards is the worst kind of edit —
learned rule 19 is this exact shape. Anyone who wants their own words on a
sheet writes them in LayOut, where nothing regenerates.

---

## 5. The island is the island

No letter. Andriy, 2026-08-31. It is not a wall, it is not in the clockwise
sequence, and its scenes stay named for what they are. If its faces ever need
separate identities they get NUMBERS, so that a letter and a number can never
be confused for one another in a filename or across a phone.

---

## 6. The bridge to everything written before this

**Nothing is renamed.** Every committed document keeps the words it was
committed with. What this table does is let those documents still be read.

It **cannot be filled today**: the letters cannot be assigned until the section
planes exist, and there are none. It gets filled with the first elevation —
owed item 3 — and is dated then.

| letter | compass name used until 2026-08-31 | what is on it |
|---|---|---|
| A | TBD | TBD |
| B | TBD | TBD |
| C | TBD | TBD |
| D | TBD | TBD |
| — | island | island |

Names waiting in the existing documents for a row here: *west run* (3080 @650,
black `LX19`), *south base run* / *south leg* (1903 @650, black), *east wall
floor to 3040* (oak `RR09`), *east of the range* (874,3 @650), *the angled
north-west wall* with the opening at z 914,4…2286,0, and the two CUSTOM boxes
over the range at 1720.

---

## 7. Where the compass goes

One project fact — the plan's rotation relative to north — on the model, in the
`UCON_PROJECT` dictionary beside `worktop_t_mm` and `worktop_code`. It belongs
to the kitchen, so it travels in the .skp and is answered once.

Read by the site plan and by nothing else. No cabinet, no run, no elevation and
no order line ever reads it.

---

## 8. What this does NOT decide

- **Which wall is A.** §3.
- **How many elevations this kitchen has.** The angled north-west wall does not
  lie down in any orthographic projection, and what happens to it is a drawing
  question to be answered on the first sheet, not here.
- **Whether the generated description is produced by its own pass or by the
  standard pass.** That belongs to the template conversation, which is
  deliberately not started — see the handoff, §7, and learned rule 6: a
  constant chosen when there was one case is a bug waiting for the second.
  One correct elevation by hand first. Andriy's call, 2026-08-29, unchanged.

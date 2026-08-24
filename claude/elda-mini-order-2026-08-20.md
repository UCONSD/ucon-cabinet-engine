# Ask for Elda — designed to answer, not to be answered

Replaces the Q1…Q8 questionnaire (`docs/Elda_Questions_v0.3.md`). Drafted
2026-08-20.

## STATE — read this before touching anything

**This block is the single source of truth for what has and has not been sent.
The status doc points here rather than repeating it, because the last time two
documents both described the email state, one of them went stale and nearly
caused a duplicate request to a client.**

> **PART 2 (positions 1–12) WAS SENT.** 2026-08-21, 09:32 PDT (16:32 UTC),
> thread `1a0252a76b71d5d0`, subject *"Small test estimate request — 12
> positions"*. **No reply as of 2026-08-22 night** — re-read from the thread,
> not from this line: it holds one message and it is ours.
>
> **The follow-up is written, unsent, and SCHEDULED.** Draft
> **`r5780256024551136473`** — a reply *inside* that thread, subject *"Re: Small
> test estimate request — 12 positions"*. It carries only what is new:
> positions 13–15, a revised short-list, the three wine cooler questions, and
> (added 2026-08-22) the two linear-goods questions in PART 4.
> **Positions 1–12 and their numbering are untouched**, which is the whole
> reason a follow-up works where a replacement email would not.
>
> **IT IS NOW THE ONLY DRAFT IN THE ACCOUNT.** Both older ones were trashed on
> 2026-08-22 (see below), so there is nothing left to confuse it with.
>
> **The draft id changed on 2026-08-22.** The follow-up first lived in
> `r8207129901567342645`. Editing it with `update_draft` **detached it from the
> thread** — Gmail gave the edited draft a new `threadId` equal to its own
> message id, so it would have gone out as a standalone message with a "Re:"
> subject and no `References` header. It was rebuilt with `create_draft` +
> `replyToMessageId`, which keeps the thread, and the detached copy was
> trashed. **Lesson: after any draft edit, check that `threadId` still equals
> the thread's id.** `update_draft` does not preserve threading;
> `create_draft` with `replyToMessageId` does — and it appends the quoted
> original itself, so do not paste a quote block in by hand.
>
> ### When it goes: **Monday 2026-08-24, 09:00 in ITALY** = **07:00 UTC**
>
> `trig_018T3SxDUwXztezE4BS9sers`, one-shot, `run_once_at 2026-08-24T07:00:00Z`.
>
> **The time is Elda's, not ours** — changed from 09:00 PDT on 2026-08-22 at
> Andriy's instruction: she is in Italy and the letter should land at the start
> of *her* working day. Italy is on CEST (UTC+2) in August, so 09:00 Rome is
> 07:00 UTC and **around midnight in California**. Two consequences worth
> knowing: Andriy is asleep when it fires and reads the report in his morning,
> and the completion push arrives at that hour unless the channel is changed.
> **If this is ever rescheduled outside CEST (late October to late March),
> Italy is UTC+1 and 09:00 Rome becomes 08:00 UTC.**
>
> It reads the thread first: **if Elda has replied over the weekend it does NOT
> send**, and reports instead — her answer may already settle part of what the
> follow-up asks. If there is no reply it sends **the draft's content as it
> stands at that moment**, so *editing the draft before Monday is how to change
> what goes out*. It then updates this block and trashes the leftover draft.
>
> **Do not also send it by hand.** That is now the live duplicate risk, and it
> is the mirror image of the one below.
>
> **Never send a fresh 15-position email.** Elda would receive a second request
> that silently supersedes the first, with no way to tell which is current, and
> possibly after she has already started.
>
> **Both orphaned drafts are gone, 2026-08-22 night.**
> `r5488559918061589506` held an exact copy of the *sent* text — composed at
> 16:30:29 and sent from a copy two minutes later, never cleaned up.
> `r8207129901567342645` was the detached follow-up. Both removed with
> `trash_message` on the draft's *message* id, which does work even though
> there is no delete-draft tool. **The copy was only deleted after reading the
> SENT message back in full and confirming the text matched** — a duplicate is
> safe to remove, an only copy is not, and nothing but the sent message itself
> can tell the two apart.
>
> **How this was nearly got wrong, and the lesson.** This document and the
> status doc both said *"a Gmail draft exists and is UNSENT"* for a full day
> after it had gone out. Acting on that record, the draft was rewritten into a
> 15-position replacement — one click from being sent. It was caught only
> because Andriy showed a screenshot of the Sent folder. **A record of what we
> sent is only true if something checks it.** Before touching an outgoing
> message, search `in:sent` first; the draft list is not evidence of anything.
>
> **Context on her pace, so silence is not misread:** the separate "Cesar Finish
> Samples" email went 2026-08-17 and is also unanswered. Five days of quiet is
> normal here, not a signal.

**The method.** Factory output is CONFIRMED; an opinion is not. Estimate
2026/30829 answered three open questions and closed two more from our own data
— more than a page of questions would have. So instead of asking, we ask for
one more estimate, with positions chosen to make it answer as much as possible.

**The one rule that makes it work: describe the position in words, give the
code only as a guess she may ignore.** If we write "order `AU110D` and
`AU110S`", Metron echoes them back and we learn nothing — the whole question is
whether those are two articles or one article with a variant. Write "corner
base unit 115×70 d.62, left-handed" and **whatever the system emits is the
answer.**

**The one place the method does not reach.** W1–W3 and L1–L2 are about what is
*possible* or how the factory *works*, not what something *costs*, and no
estimate can answer them. They are asked outright, and the follow-up says why —
otherwise direct questions under a letter that opened "rather than sending you
another list of questions" reads as carelessness.

---

# PART 1 — the wine cooler panel

In the follow-up draft. Three questions, and they matter because **shipped
geometry depends on all three**: the engine draws this panel with an aperture
and a glass pane, and every number in it came from appliance makers rather than
from Cesar.

### W1 — who supplies the cutout dimensions?

> When we order a wine cooler door (for example `CR9601`, W. 61), the front
> carries a cutout. The price list never dimensions it, and there is no
> separate article for it. **Does the factory need the aperture size and its
> position from us as a drawing, or does Cesar take them from the appliance
> model named in the order?** If it is from us: what does Cesar need — a
> dimensioned drawing, or the appliance make and model?

*Why it matters.* We found the mechanism by which such dimensions travel —
printed p.541, `989394`, 108 points, *"Feasibility study regarding cutouts and
positioning"*. The path exists; we do not know whether it is the path for this.
The email names that article, which turns a vague question into one she can
answer yes or no to. Until it is answered the aperture is drawn from appliance
data and labelled `(cutout: INDICATIVE)` in the model.

### W2 — 19 mm or 22 mm, and what edge radius?

> The price list gives the front thickness as 2.2 cm. **Can the USA appliance
> panels (`CR94xx` / `CR96xx` and their siblings) be supplied at 19 mm
> instead?** And if 2.2 cm is the only thickness — **what edge radius do those
> fronts carry?**

*Why it matters.* Thermador plans its panel-ready wine columns around a 3/4″
(19 mm) panel and computes clearances from a 1/8″ (3 mm) gap. Miele allows
16–22 mm but publishes what a thicker panel costs in space — minimum gap to the
**adjoining housing unit door**:

| panel thickness | R0 | R1.2 | R2 | R3 |
|---|---|---|---|---|
| 16–19 mm | 3 | 3 | 3 | 3 |
| 20–21 mm | 5–5,5 | 4–5 | 4–4,5 | 3,5–4 |
| **22 mm** | **6,5** | **6** | **5,5** | **4** |

A 22 mm Cesar front is not forbidden — it costs gap, and the edge radius buys
most of it back. **This is an installation risk, not a modelling one**, and the
email says so in those words.

### W3 — the stainless steel protection

> Every wine cooler door prints *"Stainless steel protection for wine cooler
> door — 234"* with **no article code**. Is it compulsory on this front or
> optional, and how does it appear on an order?

*Why it matters.* Same shape as Servo Drive on the wall pages — a number with
no code — and that one turned out to have real articles in the mechanisms
chapter. This one may too.

---

# PART 2 — the positions

**Header, as sent: copy estimate 30829 exactly** — MAXIMA 2.2, Lacc. Lucido
Magnolia, "L-Shaped" grip horizontal in Matt Aluminium, carcass Cenere,
Legrabox Cenere R, foot H.100mm, plinth Matt Aluminium. Same finishes means any
difference in the output is caused by the positions and nothing else. A
controlled experiment, not a second sample.

Positions 3–5 sit **in one continuous run**, so the gola running length can be
read across a joint. Positions **14 and 15 sit next to each other** — the same
unit twice, differing only in the kit finish.

**1–12 are already with her. 13–15 are in the follow-up.**

| # | What we want, in words | our guess (ignore) | what it settles |
|---|---|---|---|
| 1 | Corner base unit H.78, 115×70, d.62, **left-handed** | `AU110S` | **Q7b.** Two codes, or one code with a hand variant |
| 2 | The same corner, **right-handed** | `AU110D` | the other half of Q7b |
| 3 | Base unit H.78 with one door, d.62, **W.600, unmodified** | `B80601` | the control row |
| 4 | The same base unit **reduced to W.560** | `B80699` + width reduction | Q3 mechanism, the surcharge, and the `FRN` size-bin vs cut-piece question |
| 5 | The same base unit **reduced to W.400** | — | is the reduction surcharge flat? is there a minimum? *(a refusal here IS the answer)* |
| 6 | Wall unit H.60, W.60, d.35, **top-hung door, with Servo Drive** | `PD0600` | which Servo Drive article, and at what price |
| 7 | Wall unit H.60, W.60, d.35, **push-up door, with Servo Drive** | `PD0610` | the same — and whether the push-up mechanism is included in the unit or ordered beside it |
| 8 | Wall unit H.60, W.60, d.35, **one door hinged on the left** | `PD0631` | control: confirms the sheet still behaves as 30829 did |
| 9 | Straight corner **wall** unit H.60, 100×40, **left-handed** | `PD094S` | does the wall corner letter behave like the base corner letter |
| 10 | Fully-integrated **dishwasher door, 75 cm**, with the panel that goes with it | `V80730` | **Q5**, which side `GBBF01` goes on |
| 11 | **USA element**: base unit for built-in oven, W. 76.2, d.62 | `B87699` | how a **custom-sized front** is expressed in an order — and whether the sheet prints inches |
| 12 | Tall unit H.198 with one door, W.60, d.35 | `CE0631` | does a top element appear by rule, or only when asked |
| 13 | **USA wine cooler door**, W. 61, for tall unit H. 210 | `CR9601` | whether the order asks for an appliance model, whether the cutout appears as its own line, and whether the stainless protection is added automatically |
| 14 | **Tall unit H.210, one door, W.60, d.62, fitted with the interior drawer and jumbo drawer kit in the bottom section** (the Legrabox kit, printed p.569). If the system offers a choice, take the simpler one and say what it asked | `CR0635` + kit | which kit **depth** goes in a d.62 carcass; whether a chosen option is a **child line or its own row**; whether the 155° hinge kit is pulled as an article |
| 15 | **The same position, with the kit fronts in stainless steel** | the same + surcharge | how a variant **on a companion article** is expressed on an order |

**Short-list, as sent:** 1, 2, 4 and 11. **Revised in the follow-up:**
**1, 2, 11, 13 and 14** — Q7b (the only open question with shipped code
depending on it), the custom-sized US front, the wine cooler, and the first
chosen option.

---

# PART 3 — two asks that are not questions

Both went out with the first email and are recorded here because they lived
only in the message until 2026-08-22.

### 3.1 A SketchUp export of the same test composition

Elda has already sent one, for the Dadvar composition, and it worked. The
factory's own geometry for the same positions turns the estimate from a text
answer into a checkable one: our drawing against theirs, same articles, same
finishes. OBJ was established as not available.

### 3.2 Does anything export the CODES as data?

> Besides SketchUp, does Metron export any format that carries the article codes
> as data — IFC, or DXF with block names, or a parts list in Excel or CSV?

**Worth more to M1.10 than half the positions are.** The exporter's whole job is
to emit codes; a factory-side format that already carries them is either a
validation fixture or a target. And it costs her nothing — a yes/no with a list.

The DXF phrasing is deliberate: `ezdxf` reads DXF in our sandbox, DWG needs the
proprietary ODA converter and cannot be opened at all. **Ask for DXF, never
DWG.**

---

# PART 4 — the goods sold by the metre

Added to the follow-up 2026-08-22, when the warehouse architecture made them
blocking (`claude/warehouse-architecture-2026-08-22.md`). Both are about how
the factory *works*, so like W1–W3 they are asked outright.

### L1 — how long is one bar?

> The grip profiles (`GOL001`, `GOL002`) and the plinth are priced per linear
> metre, but they must arrive as bars of some finite length. **What length is
> one bar?** If there is no single answer — what maximum length can we count
> on, and does it change with the finish?

*Why it matters.* printed p.616 and p.621 print *"– per lm."* beside `GOL001`
and `GOL002`, which makes ML a **catalog fact**, not merely our reading of the
estimate. But neither page prints a bar length, and without it the warehouse
cannot turn a running length into a count of pieces plus offcuts. Andriy's
framing is in the question deliberately: **the limit depends on the actual
maker, and the factory does not always produce these in house** — so a range or
a "depends" is a usable answer, and pretending there is one number would not
be. A joint in the wrong place shows up on a drawing, which is why this is not
purely a purchasing detail.

### L2 — is the plinth ours to specify, or Metron's to generate?

> On the Dadvar estimate the plinth appears as `ZOCC011 FRONT PLINTH H.10`,
> while the composition header also carries `PLINTH FINISH` and `FOOT TYPE`.
> **Do we specify the plinth ourselves as an ordered position with a length, or
> does Metron generate it from the composition settings once the units are
> placed?** The same question applies to the grip profile.

*Why it matters.* This is the **third axis** of the warehouse note — ours to
order vs the factory system's to generate — and our own evidence contradicts
itself: `ZOCC` sits in the estimate's component layer, yet the header carries
the settings that would generate it. Until it is answered **no plinth article
enters the registry and none enters the warehouse**; the plinth *geometry*
stays visible either way, because the drawings need it.

**Narrowed 2026-08-22, after reading the plinth pages** — the question stands,
but our own answer is now much better informed and the reading is recorded in
`claude/plinth-and-wall-hung-2026-08-22.md`: printed p.625 sells the plinth by
height as an article (`ZOCC001` = H.6, `ZOCC011` = H.10, *"per lm."*,
*"including accessories"*), while the composition header's `FOOT TYPE` already
implies the height, since the plinth clips to the feet. So the chain looks like
**FOOT TYPE → plinth height → the `ZOCC` article Metron emits**, which would
make it Metron's to generate. Her one sentence turns that inference into a fact.

---

## Why these fifteen

**Q7b is the only one with shipped code depending on it.**
`Generator.swap_corner_execution!` rewrites the article `code` today. If the
hand turns out to be a variant, it must rewrite a variant field instead.
Positions 1–2 settle it; position 9 says whether the answer generalises from the
base pages to the wall pages — the same D/S letter appears on both (printed p.42
and p.223). The tall corners on printed p.113-114 make it a third chapter.

*(2026-08-23: five chapters now. The wall corners at H.48–H.120, the tall
corners at H.138 and H.198–H.234, and the base corners. Twelve wall pages are
partial for this one answer alone.)*

**Positions 4 and 5 unblock the most.** Half the USA chapter is custom-sized and
leans on suffix `99` plus a `WIDTH REDUCTION` line. The contract cannot yet say
"this front's width comes from the opening, not from the code".

**Positions 6 and 7 close a discrepancy we cannot resolve from the book.**
printed p.221 prints `Servo Drive mechanism 554` over both the top-hung and the
push-up block, but printed p.564-565 gives the oblique push-up H.60 W.60 as
`994A50` at **554** and the top-hung H.60 as `993A94` at **504**. Only an order
says which article is actually pulled.

**Position 11 is the highest-value single row.** First US article we would ever
hold; exercises the custom-sized front, the undecodable US width grammar, and
the inch question at once.

**Positions 14 and 15 are a controlled pair.** The same article twice, differing
only in the kit finish. `CR0635` — extracted 2026-08-22 — is the first article
we hold with a **chosen** option rather than an implied one, and printed p.569
shows what the engine cannot yet express: the kit is a companion article that
**carries a variant of its own** (*"Surcharges for LEGRABOX: Stainless steel"*,
387 for KIT-L, 430 for KIT-O, no article code). Three levels where Contract v1.6
was designed for two — see
`claude/contract-v16-companions-2026-08-22.md`.

Position 14 also answers, without asking, which kit **depth** belongs in a d.62
carcass: p.569 prices every kit at both d.50 and d.60 and nothing pairs either
to a carcass. (Do not borrow the `legrabox_runners` table — the manifest marks
it *"NOT a Cesar source fact"*, it is Elda Q2, and it is quantised differently:
d.620 → NL 550, a value p.569 does not offer.)

## What this does NOT cover, deliberately

- **Handle compositions.** One grip choice is set in the header; a handle order
  would be a second request.
- **The accessory family around the grip** — `GOL030`, `GOL031`, `GOL032`,
  `GOL034` (end caps, corner element) and their kin, roughly a dozen positions.
  Real, and the warehouse will eventually have to count them. **Not today**, by
  decision — L1 has to be answered before counting anything derived from it.
- **The 5 mm shim foot.** It was on the list on 2026-08-22 and was **withdrawn
  the same day**, settled from the source instead: printed p.548 `989053` is the
  same part as `990408` on printed p.214 of Linear Elements, *"Adjustable foot
  H. 0.5 cm"*. Cross-book search before asking the factory.
- **Hood variants, dish-drainers, Virgola.** Excluded from the registry by
  decision; asking would reopen a closed question.
- **Anything we can read from the book.** Q4, Q8 and E1 were closed by reading
  further, not by asking.
- **The fridge door swing projection.** Belongs to the machine, not to Cesar.
- **Which kit type, L or O.** printed p.568 says a tall unit takes only those
  two, and the difference is how many drawers you get — a customer's choice. The
  email gives her the page number and no code: a reference, not a lead.
- **The W.75 discrepancy on printed p.82.** The visual index omits a width the
  price table prices (`CQ0731`/`CR0731`). The price table prints the article, so
  it wins and the matter is settled on our side. Reporting a typo in her own
  catalog buys nothing and spends her attention.

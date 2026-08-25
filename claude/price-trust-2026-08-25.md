# What an estimate confirms, and what it does not — the totals are not evidence

**Decided:** 2026-08-25, from Elda Chiara Lesca's written answer ·
**Trust: PLANNING** — the quotation below is hers and is evidence; the rule we
draw from it is a UCON decision about our own trust levels, not a factory fact ·
**Status:** agreed, NOT yet applied to `factory_confirmations`.

---

## What she said

Asked why she had to add the stainless steel drawer upcharge to estimate
2026/30831 by hand, Elda answered on 2026-08-25 (Gmail message
`1a039256c06ac2a1`, thread `1a0252a76b71d5d0`):

> "I did select the stainless steel option in Metron, but noticed that it did not
> impact the price of the individual item or the column. That's why I manually
> added the upcharge and also a note explaining why it was added.
> All the upcharges are added automatically but the software isn't perfect, so
> it's good to check this kind of things. Each item has a detailed price
> breakdown which isn't entirely included in the printout, and this upcharge did
> not show up in there."

and, on the same point:

> "With all these variables, especially in bigger projects, it's impossible to
> get the exact total. We can usually get really close to the official
> quotations from Cesar."

## The rule

**A printed estimate confirms CODES, DIMENSIONS and LINE STRUCTURE. It does not
confirm the pricing mechanism, and a figure on it is not evidence that the
factory system produced that figure.**

Three separate reasons, all in her answer:

1. **A human can write on the sheet.** The `SOVRAPREZZO + 387,00` block on line 2
   of 2026/30831 is a hand entry with a free-text note, not Metron output. It
   looks exactly like a system-generated surcharge in the printout.
2. **The printout is not the whole record.** Each item carries a detailed price
   breakdown that is only partly printed. What is absent from the sheet is not
   absent from the order.
3. **She does not claim exactness.** "Impossible to get the exact total",
   "usually really close". A sheet whose own author scopes it as an
   approximation cannot raise anything to `CONFIRMED` on the strength of its
   arithmetic.

## What this changes in the data

- **No price, point value or surcharge from an estimate may be written as
  `CONFIRMED`.** Points and coefficients read off a sheet are `SOURCE` at best,
  and where a line is hand-entered they are not even that — mark them and say so.
- **Codes, dimensions, variant strings and parent/child structure keep their
  standing.** Those are what Metron emitted, and they are the reason we asked
  for an estimate in the first place. `AU110S` / `AU110D`, `B80501` as the donor
  module at W.400, the `FRN…` front carrying the servo surcharge as a variant,
  `996OL6` as a child article — all unaffected by this rule.
- **`factory_confirmations` entries sourced from a price figure need
  re-reading** against the distinction above. Entries sourced from a code or a
  printed dimension do not.

## Correction, dated — narrows a check made on 2026-08-24

On 2026-08-24 the arithmetic of 2026/30831 was verified line by line:
`Amount = (Punti + Magg.) × 1,34` holds on all seventeen rows and the seventeen
amounts reconcile to the printed total of 16 256,88 € to the cent.

**That verification stands, and its meaning is narrower than it looked.** It
proves the sheet is internally consistent — that the coefficient is applied as
stated and nothing is dropped between the rows and the total. It does **not**
prove that Metron computed the inputs. Line 2 reconciles precisely *because* the
387 was typed in by hand; the arithmetic could not have told us otherwise, and
was read at the time as stronger evidence than it was.

Keep the check. It is a good fixture for the coefficient. Do not let it stand as
evidence for anything upstream of the numbers it adds.

## Where it does not reach

This says nothing about whether the prices are *right*. They may well be — she
says the results land close to Cesar's official quotations. The point is only
that our registry cannot cite them as factory-confirmed, because the sheet does
not separate what the system produced from what a person added.

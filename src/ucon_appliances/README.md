# UCON Appliances

Appliance housings, service zones and budget sets, drawn from the manufacturer
design guides.

## Install

SketchUp → `Extensions` → `Extension Manager` → `Install Extension` →
`ucon-appliances-0.1.0.rbz` → restart SketchUp.

Manual install needs BOTH `ucon_appliances.rb` and the `ucon_appliances/`
folder in the Plugins folder of the version you actually run.

## Use

`Extensions → UCON → Appliances…`

Two controls at the top govern everything below them:

- **Front system** — `handle` or `gola`. With gola every undercounter appliance
  is placed as its ADA variant; where no ADA variant exists the panel says so
  and names what the Cesar catalogue offers instead.
- **Run top, mm from floor** — 2200 for plinth 100 + H210. It decides the void.

## What it draws

| | tag | colour |
|---|---|---|
| housing, floor to opening height | `UCON_APPLIANCE_OPENING` | neutral |
| void above it | `UCON_APPLIANCE_VOID` | **red** |
| service zones | `UCON_APPLIANCE_UTILITIES` | by service |

Red marks what still needs a decision. The housing is resolved; the void is not.

The housing is a **component**, not a group, so `UCON_Appliance_Register_v1`
sees it: the same `UCON_APPLIANCE` dictionary carries the register's own six
keys, and `LIST OF APPLIANCES` and its CSV export work unchanged.

## The rules it applies

- **Housing is measured from the floor.** The plinth is interrupted at every
  appliance; the opening height is never counted from the plinth top.
- **Installation type comes from the finish.** Flush inset is offered only where
  the guide prints a flush table, and only to overlay models. A panel-ready
  model with a flush table defaults to flush.
- **The void is never left raw.** At or below 120 mm a filler; above it a choice
  of filler or open shelf cabinet, carcass material.
- **Above a Sub-Zero housing, whatever fills the void sits back 55 mm** on the
  appliance carcass, because the hinge draws the panel inward as the door opens.

Everything above lives in `data/rules.json` and is applied by `lib/appliances.rb`,
which has no SketchUp in it and is covered by headless checks:

    ruby test_appliances.rb

## Brands and where the data lives

Four brands, in button order: **Thermador, Sub-Zero, Gaggenau, Miele**
(`data/brands.json`, decided 2026-09-24). Sub-Zero is the group: Sub-Zero for
refrigeration, Wolf for cooking and ventilation, Cove for dishwashers. The
brand is a filter on the list, not a lock on the kitchen — brands mix.

One catalogue file per brand family, `data/brands/<key>.json`. Gaggenau, Miele
and (until 7612 Hillside Dr) Thermador are empty on purpose: a catalogue grows
only when a real project needs a model. A brand file that is missing or broken
is reported and loads nothing; the other brands load regardless.

## Prices

Sub-Zero group only. Other brands carry no prices: prices are open and change,
codes matter more, and prices are checked when a proposal is made.

`data/prices.json` is a dated snapshot of US list MSRP. Appliances are **not
supplied by UCON** — the figure is a budget allowance and the dealer quotes.
Rebate figures follow Full Suite Savings 2026, read from the promo page and
brochure rather than from the full terms.

## Not covered yet

Door swing projection. PRO Series has no default installation until that is
decided. The brand filter in the panel (step 4 of
`claude/decisions-2026-09-24-appliance-brands.md`). Any model outside the
Sub-Zero group.

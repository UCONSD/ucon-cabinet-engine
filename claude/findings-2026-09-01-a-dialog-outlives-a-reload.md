# A dialog outlives a core reload, and the callbacks go with it

**2026-09-01.** The declare button was pressed for the first time and nothing
happened. Nothing failed either — no error, no message, no change. Two
screenshots taken either side of the press were identical.

---

## What it was

`Report.show` memoised its window:

    @window ||= UI::HtmlDialog.new(...)

and gated its callbacks:

    unless @wired
      @window.add_action_callback('orphan_pick') { ... }
      @wired = true
    end

The window had been open since the previous day. **Reload core** replaced the
Ruby — new `html`, new `assign`, a new `orphan_assign` callback — and then
`show` found `@window` already set and reused it, and found `@wired` already
true and registered nothing. So the page was redrawn with a button that calls
`orphan_assign` **into a dialog that had never heard of it**.

JavaScript calling a callback that does not exist is silent. That is the whole
bug: not that it broke, but that it could not say so.

## The repository already knew the fact

`claude/findings-2026-08-27-lit-shelves.md`, four days earlier:

> an HtmlDialog bakes its HTML *and its callbacks* at open. Reloading the core
> replaces the Ruby; the open window keeps the old ones.

That note was written about HTML — a control that was redrawn and did not
change. This is the same sentence with the second half doing the work. **The
fact was recorded, correctly, and still cost an hour**, because it was recorded
as a description of one incident rather than as something a check could hold.

## The fix, in two parts

**The window is dropped at LOAD time**, in the module body, so the two lines run
on every `load` — which is exactly what Reload core does:

    begin
      @window.close if defined?(@window) && @window
    rescue StandardError
      nil
    end
    @window = nil

The next `show` therefore builds a new dialog whose callbacks match the Ruby
that just arrived. **A memo that survives the thing it memoises is not a cache,
it is a lie with a fast path.**

**And `@wired` is gone.** The callbacks are registered on every `show`. The flag
was the second half of the same mistake: after a reload it said yes and the
dialog said who.

## And the second fix is the one that matters more

A press that changes something now **says so on the page** — how many bodies,
what scope, what it will print on a sheet, and that Ctrl-Z undoes it.

The silence was worse than the failure. A button that does nothing and reports
nothing teaches a person to distrust the whole window, and this particular
window is about to be the thing that decides what a GC reads.

## Held by a check, not by prose

`tools/test_contract.rb` fails if the callbacks are gated behind a memo again,
if the window stops being dropped at load, or if the confirmation line
disappears. That is the difference between this note and the one from 08-27:
learned rule 13 — a record of something outside the code is only true if
something checks it.

## Candidate learned rule, NOT added

*A memo that outlives what it memoises is a lie with a fast path.* It is close
to learned rule 20 — a detector cannot tell your write from a person's edit —
in that both are about state that survives longer than the thing it describes.
Whether it earns its own number is Andriy's call, and candidate 21 from
2026-08-31 is still waiting on the same call.

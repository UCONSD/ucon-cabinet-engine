# `build/go.sh` can see a push that FAILS and cannot see a push that ASKS

**The event is 2026-09-03; this note is written 2026-09-05, which is why it is
dated for the day it was written rather than the day it happened.** It was owed
by the 2026-09-03 handoff as *§1.6, not written, write it*, and it is the last
thing that session left uncommitted.

---

## What happened, twice in one evening

`sh build/go.sh` stopped dead at `===== 4. push, and then READ THE REFS BACK`
with **no output and no exit code**. Not an error, not a failure message, not a
non-zero status — nothing at all, and the terminal simply sat there.

The cause was outside the script. The GitHub credential in the keychain was
dead, so `git push` fell back to asking for a username on the terminal — and
that prompt was behind `cl`'s transcript, where nobody could see it. `git` was
waiting for an answer that could not be typed. Andriy replaced the token and
both repositories push normally again; the account of that half is in
`repo-state.md` under *2026-09-03, evening*.

## Why the script's own guard could not catch it

**Step 4 is a good guard and it never ran.** It reads both refs back after the
push and refuses if they differ:

    git push
    LOCAL=$(cat .git/refs/heads/main)
    REMOTE=$(cat .git/refs/remotes/origin/main)
    ...
    if [ "$LOCAL" != "$REMOTE" ]; then ... exit 1

That is exactly the check that catches a push which FAILED — and a push which
is still ASKING never reaches the next line. `set -e` cannot help either: it
acts on a command that has finished with a non-zero status, and this command
had not finished. **The guard is downstream of the hang, so the one failure
mode it cannot see is the one where `git` is still waiting.**

**And the commit had already been made.** Step 3 runs before step 4, so the
work was committed locally and not pushed — which is the state `repo-state.md`
warns about in its own *Pushed* cell: two refs that disagree, on a machine that
has been eleven commits behind before.

## The shape of it, and the rule it belongs under

Learned rule 16 — *a command that did not run leaves no trace, and that is the
danger* — is close but not exact. This is its neighbour: **a command that has
not FINISHED leaves no trace either, and looks the same from outside as one
that is merely slow.** A script can only check what has returned to it.

## The proposed change, NOT APPLIED

    GIT_TERMINAL_PROMPT=0 git push

`GIT_TERMINAL_PROMPT=0` tells `git` never to prompt on a terminal. The prompt
then becomes an immediate failure — *could not read Username for
'https://github.com': terminal prompts disabled* — with a non-zero status, and
that is a thing the script can see: `set -e` stops the run, `cl` records the
exit code, and step 4's ref comparison is never reached because the push
announced its own failure first.

**Nothing is lost by it.** A prompt that reaches nobody cannot be answered, so
turning it into an error removes no capability the environment actually has.
The credential still comes from `osxkeychain` exactly as today; only the
fallback to asking a human changes, and that fallback is what hung.

**Deliberately not applied, and this is a judgement rather than a hesitation:**
`build/go.sh` is the ONE command Andriy runs on both machines, and a change to
it takes effect on both the moment it is committed. It is his to approve.

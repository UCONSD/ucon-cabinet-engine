# frozen_string_literal: true
#
# UCON Cabinet Engine — core/95_dev_bridge.rb  ::  A DOOR TO A DEV TOOL THAT
# STAYS OPTIONAL.
#
# `tools/probe_bridge.rb` is a DEV TOOL. Its own first lines say so: nothing in
# src/ requires it, it carries no version, and it never goes into an .rbz. That
# property is worth keeping, and a button is exactly the kind of convenience
# that quietly destroys it — a `require` at the top of a palette file would make
# the engine refuse to load wherever tools/ is absent.
#
# So this file NEVER requires it, and never names ::UCON::ProbeBridge except
# behind a `defined?`. It asks two questions at CALL time and answers both
# without loading anything:
#
#   available?  is there a bridge on disk to load  (i.e. a dev checkout)
#   running?    is one loaded and actually ticking (i.e. a live timer)
#
# That is deliberately the same shape as ApplianceCheck.available? — asked at
# call time, never memoised, because a session can change the answer without
# restarting. Here the answer changes every time somebody presses Reload core.
#
# WHY A BUTTON EXISTS AT ALL. `Reload core` re-reads core/ in a second and, in
# doing so, KILLS THE BRIDGE'S TIMER. The bridge then has to be re-loaded by
# hand, which means typing an absolute path into the Ruby Console — the one
# piece of typing this whole tool exists to remove. So the pair belongs
# together: the button that breaks the bridge, and the button that puts it back.
#
# WHAT THIS DID NOT DO, ON PURPOSE, UNTIL 2026-10-07 (see below): it never armed. `ProbeBridge.arm!` makes the
# next run COMMIT instead of roll back, and that is a decision somebody types out
# in full, every time, with the model in front of them. A one-click arm is how a
# probe applies to a kitchen nobody meant to change.
#
# AND IT UN-ARMS, WHICH THE SENTENCE ABOVE DID NOT SAY UNTIL IT BIT — 2026-08-28.
# `reload!` loads probe_bridge.rb, whose last line calls `start`, and `start` sets
# `@armed = false` on its fifth line. So pressing this button silently clears an
# arm that was already set. The RUN COUNTER survives and the arm does not, which
# is why the panel could truthfully report "ON, 7 runs" while disarmed.
#
# That is correct of the bridge — a freshly started bridge SHOULD be unarmed — and
# it is a trap in this pairing, because the next probe would have been 71, which
# calls Generator.build and therefore APPLIES WHETHER ARMED OR NOT. The bridge's
# accounting would have said "rolled back" over a kitchen that had changed.
#
# So the answer now says so out loud. THE ORDER IS: reload the bridge, THEN arm.
#
# A CONFIRMED ARM, NOT A ONE-CLICK ARM — 2026-10-07, Andriy's decision.
# Typing `UCON::ProbeBridge.arm!` before every applying run had become the one
# piece of typing left, and it carried no information: the console line does not
# say WHICH file it arms. So the arm now goes through one named file and one
# question. The rules, each enforced by tools/test_contract.rb:
#
#   * Only a file named `NNN_..._ARMED.rb.hold` in tools/probe_inbox/ can be
#     applied. A .hold is never run by the bridge; it waits for a person.
#   * The palette shows WHICH file, WHICH model it names (UCON-MODEL) and the
#     file's own opening comment, and asks Yes/No. Nothing happens on No.
#   * Refused if the bridge is not ticking, if more than one .hold waits, or if
#     any plain .rb probe is already queued — an arm must never fall on a probe
#     nobody was shown.
#   * arm! is called in exactly one place, arm_and_release!, and only after the
#     checks; the file is renamed .hold -> .rb in the same breath, so the very
#     next run is the file that was shown.
#   * The question is asked BEFORE anything is armed or released, so the modal
#     box cannot hold up a run (see `announce` for why a modal and a timer do
#     not mix).

module UCON
  module CabinetEngine
    module DevBridge
      module_function

      # <repo>/tools/probe_bridge.rb, derived from where THIS FILE actually is
      # rather than from a constant somebody may have set for another purpose.
      # core/ lives at <repo>/src/ucon_cabinet_engine/core, so tools/ is three
      # levels up. If the engine is ever packaged into an .rbz — owed, and
      # Andriy's call when — this path stops existing, `available?` goes false,
      # and the button is simply not drawn. Nothing raises.
      def path
        File.expand_path(File.join('..', '..', '..', 'tools', 'probe_bridge.rb'), __dir__)
      end

      def available?
        File.file?(path)
      end

      # A LIVE TIMER, NOT A LOADED FILE. `defined?` alone would say yes forever
      # once the module has been loaded once, and the whole problem is that the
      # module OUTLIVES ITS TIMER: after Reload core the constant is still there
      # and the bridge is deaf. ProbeBridge.timer is nil when it is not ticking,
      # and that is the honest question.
      def running?
        return false unless defined?(::UCON::ProbeBridge)

        !::UCON::ProbeBridge.timer.nil?
      rescue StandardError
        false
      end

      # Loading the file restarts it: probe_bridge.rb ends with
      # `UCON::ProbeBridge.start`, and `start` calls `stop` first, so this is
      # idempotent — pressing it twice leaves one timer, not two. `load` and not
      # `require`, for the same reason load_core uses it: require caches by path
      # and would make the second press do nothing at all.
      def reload!
        unless available?
          raise ArgumentError,
                "There is no probe bridge to load.\n\n" \
                "Expected it at:\n#{path}\n\n" \
                'It is a dev tool that lives in the repository and never ships in an ' \
                'extension, so this button only means anything in a dev checkout.'
        end

        load path
        true
      end

      # ---- the confirmed arm (2026-10-07) -------------------------------------
      def inbox
        File.join(File.dirname(path), 'probe_inbox')
      end

      # Plain .rb probes already queued - the bridge would run them next.
      def queued_probes
        Dir.glob(File.join(inbox, '*.rb')).sort
      end

      def waiting_holds
        Dir.glob(File.join(inbox, '*_ARMED.rb.hold')).sort
      end

      # The ONE file that may be applied now, or an error that says why not.
      def waiting_probe
        raise ArgumentError, 'The probe bridge is not running. Press "Reload probe bridge (dev)" first.' unless running?
        q = queued_probes
        raise ArgumentError, "A probe is already queued and would take the arm:\n#{q.map { |f| File.basename(f) }.join("\n")}" unless q.empty?
        h = waiting_holds
        raise ArgumentError, 'Nothing is waiting: there is no *_ARMED.rb.hold in tools/probe_inbox/.' if h.empty?
        raise ArgumentError, "More than one probe is waiting - apply them one at a time:\n#{h.map { |f| File.basename(f) }.join("\n")}" if h.size > 1
        h.first
      end

      # What the person is shown before saying Yes: name, model, opening comment.
      def confirm_text(hold)
        head = File.open(hold, 'r') { |f| f.read(4096) }.to_s.lines
        model = head.join[/^[[:blank:]]*#[[:blank:]]*UCON-MODEL[[:blank:]]*:[[:blank:]]*(\S.*?)[[:blank:]]*$/, 1] || '(default model)'
        about = head.select { |l| l =~ /^\s*#/ && l !~ /UCON-MODEL/ }.first(8).map { |l| l.sub(/^\s*#\s?/, '').rstrip }
        "APPLY THIS PROBE TO THE MODEL?\n\n#{File.basename(hold)}\nmodel: #{model}\n\n#{about.join("\n")}\n\nYes = arm and run it once (it COMMITS). No = nothing happens."
      end

      # The only place arm! is called. Checks again (the inbox may have changed
      # while the question was open), arms, and releases the shown file.
      def arm_and_release!(hold)
        raise ArgumentError, 'not a waiting probe' unless File.basename(hold.to_s) =~ /_ARMED\.rb\.hold\z/ && File.file?(hold)
        raise ArgumentError, 'the inbox changed while the question was open' unless waiting_probe == hold
        ::UCON::ProbeBridge.arm!
        File.rename(hold, hold.sub(/\.hold\z/, ''))
        ::Sketchup.status_text = "Probe bridge ARMED for #{File.basename(hold, '.hold')} - it runs within a few seconds." if defined?(::Sketchup)
        true
      end

      # THE ANSWER GOES TO THE STATUS BAR, NOT TO A MESSAGEBOX, AND THAT IS THE
      # WHOLE POINT — found 2026-08-28, in the model, on the button's first use.
      #
      # UI.messagebox IS MODAL, AND A MODAL DIALOG BLOCKS SKETCHUP'S TIMER LOOP.
      # The bridge IS a timer. So the confirmation box sat there saying "Probe
      # bridge is ON — 0 run(s)" while PREVENTING the bridge from taking the
      # single run that was already queued in the inbox. It was telling the truth
      # and stopping it from staying true.
      #
      # A success here has nothing a person must acknowledge, and the bridge's own
      # start already writes both lines it needs — Sketchup.status_text and a
      # console line. So success is silent-but-visible, and only a FAILURE gets a
      # modal, because a failure is something you must not miss and there is no
      # timer left to block.
      def announce
        return unless defined?(::Sketchup)

        ::Sketchup.status_text = status_line
        puts status_line
      rescue StandardError
        nil
      end

      # The sentence a person reads after pressing it. It reports what is TRUE
      # AFTERWARDS rather than what was attempted — learned rule 13, a record of
      # an outside action is only true if something checks it.
      def status_line
        if running?
          runs = begin
            ::UCON::ProbeBridge.runs.to_i
          rescue StandardError
            0
          end
          "Probe bridge is ON — #{runs} run(s) so far, watching tools/probe_inbox/. " \
            'Starting it CLEARED any arm: type UCON::ProbeBridge.arm! again if you meant to.'
        else
          'Probe bridge is OFF.'
        end
      end
    end
  end
end

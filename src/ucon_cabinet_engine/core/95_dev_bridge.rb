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
# WHAT THIS DOES NOT DO, ON PURPOSE: it never arms. `ProbeBridge.arm!` makes the
# next run COMMIT instead of roll back, and that is a decision somebody types out
# in full, every time, with the model in front of them. A one-click arm is how a
# probe applies to a kitchen nobody meant to change.

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
          "Probe bridge is ON — #{runs} run(s) so far, watching tools/probe_inbox/."
        else
          'Probe bridge is OFF.'
        end
      end
    end
  end
end

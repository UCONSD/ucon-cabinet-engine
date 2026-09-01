# frozen_string_literal: true
#
# UCON Cabinet Engine — core/67_declare.rb  ::  WHAT A BODY'S SCOPE IS, AND THE
# WORDS THAT GO ON A SHEET.
#
# The second half of core/68_report.rb, specified in
# claude/spec-2026-08-31-declaring-a-body.md and built the day after the report
# shipped. The report asks WHAT IS HERE THAT NO RULE OWNS. This answers the only
# question that can retire a row from that list without lying: whose is it.
#
# ---- IT IS NOT IN THE CabinetEngine DICTIONARY, AND THAT IS FORCED ---------
#
# The spec said it would be, beside `object_class`. It cannot be, and the
# contract itself says so twice: §1.2 rejects any key outside the closed KEYS
# list, and ALWAYS_REQUIRED demands `object_class` on anything written there. A
# declared body has NO object_class - that is the entire definition of the thing
# being declared. Writing a declaration into that dictionary would either be a
# contract violation or would force us to invent a class for a client's
# refrigerator.
#
# So this is a DIFFERENT DICTIONARY ON A DIFFERENT KIND OF FACT, exactly the
# argument core/08_project.rb makes for UCON_PROJECT: the contract describes the
# objects WE make, and a declaration describes a body we do not. The two never
# meet on one entity, which is also the refusal below.
#
# ---- THE SLUG IS NOT THE PRINTED WORD -------------------------------------
#
# The slug lands on a body and never changes. The phrase lives in NOTES and is
# read at drawing time. While this was being specified the wording changed three
# times - owner furnished, by owner, and a version naming UCON out loud - and no
# body would have had to be touched for any of them. Same argument as
# Retag::TAGS taking the generator's constants instead of retyping them.
#
# ---- WHY NO COMPANY NAME APPEARS IN ANY PHRASE HERE ------------------------
#
# An earlier draft printed INSTALLED BY UCON. Andriy, 2026-08-31: the installer
# may turn out to be somebody else. He is right, and the fix is not a better name
# for us - a contract document states scope RELATIVE TO THIS CONTRACT, not
# people. The proof is N.I.C. itself: a note meaning `not in contract` is only
# needed because IN CONTRACT is the default nobody writes. OFCI is refused for a
# second reason: on a sheet a GC reads, `Contractor Installed` reads as the GC,
# and to them we are a subcontractor.
#
# ---- NO SKETCHUP IN THE RULES ----------------------------------------------
#
# Everything above `THE MODEL SIDE` is pure and is checked headless. The two
# readers below it are the only methods here that have ever heard of a model,
# and they read instance-then-definition exactly as Retag.object_class_of does,
# because a declaration that disagreed with ownership on the first copy would be
# learned rule 11 for the fifth time.

module UCON
  module CabinetEngine
    module Declare
      module_function

      # Not `CabinetEngine`. See the header - the contract forbids it.
      DICTIONARY  = 'UCON_SCOPE'
      REASON_KEY  = 'reason'
      INSTALL_KEY = 'installed_by'
      AT_KEY      = 'at'
      BY_KEY      = 'by'

      # The five that are a DECLARATION - the body is not ours and we say so.
      REASONS = %w[owner_furnished by_others existing building drawing_aid].freeze

      # NOT a declaration. Ours, drawn by hand, no contract yet - the fridge
      # plinth. It leaves the main list and lands in a count that only a STAMP
      # can reduce. A click must never be able to lower it, or this whole tool
      # becomes a way of shortening a list at the expense of honest debts.
      DEBT = 'ours_no_contract'

      ALL_REASONS = (REASONS + [DEBT]).freeze

      # WHO INSTALLS, AND THE VALUES ARE DELIBERATELY ASYMMETRIC. We know
      # reliably whether WE install a thing. Who installs it instead of us is
      # usually something nobody told us, and learned rule 8 forbids writing down
      # a fact no source gave us. So there is no `owner` and no `others` here,
      # and OFOI - Owner Furnished / Owner Installed - is a claim this engine
      # must never make on its own.
      INSTALLERS = %w[ucon not_ucon undecided].freeze
      UNDECIDED  = 'undecided'

      # AND THE AXIS IS ONLY ASKED WHERE SUPPLY AND INSTALL CAN DIFFER. Nobody
      # installs an existing wall, and the building is not installed at all. An
      # undecided installer on those is not an open question, it is a question
      # that was never put - so it must not block a sheet.
      INSTALL_ASKED = %w[owner_furnished by_others].freeze

      # ---- THE WORDS ------------------------------------------------------

      NOTES = {
        %w[owner_furnished ucon]     => 'OWNER FURNISHED',
        %w[owner_furnished not_ucon] => 'OWNER FURNISHED — INSTALLATION N.I.C.',
        %w[by_others       ucon]     => 'FURNISHED BY OTHERS',
        %w[by_others       not_ucon] => 'BY OTHERS'
      }.freeze

      # nil means NOTHING PRINTS, stated rather than defaulted. `building` is
      # architecture and architecture is not scope; `drawing_aid` never reaches a
      # sheet at all; the debt is ours, and the legend's default sentence already
      # says that unmarked work is ours.
      UNCONDITIONAL = {
        'existing'    => 'EXISTING TO REMAIN',
        'building'    => nil,
        'drawing_aid' => nil,
        DEBT          => nil
      }.freeze

      def reason?(value)
        ALL_REASONS.include?(value.to_s)
      end

      def declared_reason?(value)
        REASONS.include?(value.to_s)
      end

      def installer?(value)
        INSTALLERS.include?(value.to_s)
      end

      def install_asked?(reason)
        INSTALL_ASKED.include?(reason.to_s)
      end

      # THE LOOKUP IS TOTAL AND HAS NO DEFAULT. A pair that fell through to a
      # default would be a scope statement nobody wrote, on a drawing somebody
      # signs. Every unknown pair raises and names itself.
      def note(reason, installed_by = UNDECIDED)
        r = reason.to_s
        i = installed_by.to_s
        i = UNDECIDED if i.empty?

        unless reason?(r)
          raise ArgumentError, "not a scope reason: #{reason.inspect} - one of #{ALL_REASONS.join(', ')}"
        end
        unless installer?(i)
          raise ArgumentError, "not an installer: #{installed_by.inspect} - one of #{INSTALLERS.join(', ')}"
        end

        return UNCONDITIONAL.fetch(r) unless install_asked?(r)
        return nil if i == UNDECIDED

        NOTES.fetch([r, i]) do
          raise ArgumentError, "no printed note for #{r} + #{i} - the lookup is meant to be total"
        end
      end

      # ---- WHAT STOPS A SHEET ---------------------------------------------
      #
      # The legend says that unmarked work is ours. That sentence is only safe
      # while nothing of UNKNOWN SCOPE can reach a sheet: an undecided body
      # printing nothing would read as ours and claim work nobody decided. So the
      # rule is not a wording, it is a refusal - and the debt bucket does NOT
      # block, because its scope is known. It is ours; it is the contract that
      # is missing, not the answer.
      def blocks_sheet?(reason, installed_by = UNDECIDED)
        r = reason.to_s
        return true if r.empty?
        return true unless reason?(r)

        install_asked?(r) && installed_by.to_s != 'ucon' && installed_by.to_s != 'not_ucon'
      end

      # ---- THE LEGEND -----------------------------------------------------
      #
      # DERIVED, never typed. It names the notations that occur on THIS sheet and
      # no others: a legend naming BY OTHERS where nothing is by others sends a
      # reader hunting, and a note with no legend line is worse. Same failure as
      # an index nobody maintains - which this repository met on 2026-08-31, when
      # two new notes were missing from claude/README.md and the suite caught it.

      DEFAULT_SENTENCE =
        'UNLESS NOTED OTHERWISE, ALL WORK SHOWN IS FURNISHED AND INSTALLED ' \
        'UNDER THIS CONTRACT.'

      GLOSS = {
        'OWNER FURNISHED' =>
          'supplied by the owner; installed under this contract.',
        'OWNER FURNISHED — INSTALLATION N.I.C.' =>
          'supplied by the owner; installation is not in this contract.',
        'FURNISHED BY OTHERS' =>
          'supplied by another party; installed under this contract.',
        'BY OTHERS' =>
          'supplied and installed by another party; not in this contract.',
        'EXISTING TO REMAIN' =>
          'in place before this work; not altered under this contract.'
      }.freeze

      # Printed in this order wherever they occur, so two sheets of one set never
      # disagree about the order of their own legend.
      NOTE_ORDER = [
        'OWNER FURNISHED',
        'OWNER FURNISHED — INSTALLATION N.I.C.',
        'FURNISHED BY OTHERS',
        'BY OTHERS',
        'EXISTING TO REMAIN'
      ].freeze

      # This system contributes exactly ONE abbreviation. V.I.F., T.B.D. and the
      # rest belong to other parts of a sheet, and an abbreviation for something
      # the sheet does not say is a fact no source gave us - learned rule 8.
      ABBREVIATIONS = { 'N.I.C.' => 'NOT IN CONTRACT' }.freeze

      # pairs: [[reason, installed_by], ...] - whatever is actually declared on
      # the bodies this sheet shows.
      def legend(pairs)
        used = Array(pairs).map { |r, i| note(r, i) }.compact.uniq
        lines = [DEFAULT_SENTENCE]
        NOTE_ORDER.each do |n|
          next unless used.include?(n)

          lines << "#{n} — #{GLOSS.fetch(n)}"
        end
        lines
      end

      def abbreviations(pairs)
        used = Array(pairs).map { |r, i| note(r, i) }.compact
        return {} unless used.any? { |n| n.include?('N.I.C.') }

        ABBREVIATIONS
      end

      # ---- THE REFUSALS ---------------------------------------------------

      # OURS IS NOT DECLARABLE. A body carrying a class is owned by a rule, and
      # putting a scope word on it would let somebody retire one of our own
      # cabinets from the report in a month. The message names the class rather
      # than saying no, because a refusal that does not say what it saw is a
      # refusal somebody works around.
      def declarable!(object_class)
        oc = object_class.to_s
        return true if oc.empty?

        raise ArgumentError,
              "this body carries object_class #{oc.inspect} - it is OURS and a rule owns it. " \
              'A scope word cannot be put on it; change the rule or the contract instead.'
      end

      def validate!(reason:, installed_by: UNDECIDED, object_class: nil)
        declarable!(object_class)

        r = reason.to_s
        unless reason?(r)
          raise ArgumentError, "not a scope reason: #{reason.inspect} - one of #{ALL_REASONS.join(', ')}"
        end

        i = installed_by.to_s
        i = UNDECIDED if i.empty?
        unless installer?(i)
          raise ArgumentError, "not an installer: #{installed_by.inspect} - one of #{INSTALLERS.join(', ')}"
        end

        # Not asked is not the same as undecided, and storing an answer to a
        # question nobody put would make the report show an open item forever.
        i = UNDECIDED unless install_asked?(r)

        { REASON_KEY => r, INSTALL_KEY => i }
      end

      # ---- THE MODEL SIDE, and the only part that knows what SketchUp is ---

      def reason_of(entity)
        v = entity.get_attribute(DICTIONARY, REASON_KEY)
        return v.to_s unless v.nil?

        d = (entity.respond_to?(:definition) ? entity.definition : nil)
        v = d ? d.get_attribute(DICTIONARY, REASON_KEY) : nil
        v.nil? ? '' : v.to_s
      rescue StandardError
        ''
      end

      def installed_by_of(entity)
        v = entity.get_attribute(DICTIONARY, INSTALL_KEY)
        return v.to_s unless v.nil?

        d = (entity.respond_to?(:definition) ? entity.definition : nil)
        v = d ? d.get_attribute(DICTIONARY, INSTALL_KEY) : nil
        v.nil? ? UNDECIDED : v.to_s
      rescue StandardError
        UNDECIDED
      end
    end
  end
end

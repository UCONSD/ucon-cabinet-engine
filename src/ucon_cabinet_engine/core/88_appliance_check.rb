# frozen_string_literal: true
#
# UCON Cabinet Engine — core/88_appliance_check.rb  ::  THE ONE SEAM TO THE
# APPLIANCE MODULE, AND IT ONLY EVER ASKS QUESTIONS.
#
# The appliances live in a SEPARATE extension with a separate namespace, a
# separate attribute dictionary and separate data files. That is not tidiness,
# it is the Object Contract: §1.2 forbids commercial data in the CabinetEngine
# dictionary and §1.1 closes the key list, while an appliance record carries a
# manufacturer's price and a dozen keys this contract has never heard of.
#
# So the dependency runs ONE WAY and it is OPTIONAL:
#
#   * nothing in core/ requires the appliance module, and the engine builds,
#     draws and exports exactly as before when it is not installed;
#   * this file never writes an attribute, never draws, never orders. It reads
#     what the generator would draw and reports what disagrees with the
#     appliance maker's published opening;
#   * the appliance module never calls back into the engine.
#
# `available?` is therefore a real question with a useful answer, and every
# entry point below returns `'checked' => false` with a reason rather than
# raising when the answer is no. A missing optional extension is a state, not
# a fault.
#
# Pure Ruby, no SketchUp: the whole thing is reachable from
# tools/test_appliance_seam.rb.

module UCON
  module CabinetEngine
    module ApplianceCheck
      module_function

      # The appliance extension registers UCON::Appliances when it loads. It is
      # a sibling extension in the same Plugins folder, not a file of ours, so
      # this is asked at CALL time and never memoised: a session can install it
      # and reload core without restarting SketchUp.
      def available?
        defined?(::UCON::Appliances) ? true : false
      end

      def unavailable
        { 'checked' => false, 'agrees' => nil, 'findings' => [], 'offers' => [],
          'reason' => 'the UCON Appliances extension is not installed in this session' }
      end

      # WHAT THE ENGINE WOULD ACTUALLY DRAW, in the four numbers the appliance
      # layer knows how to judge. It is deliberately built from the generator's
      # own functions rather than from the registry row: the row states a
      # fragment (`bottom: plinth_top`, sometimes a `top_mm`) and the drawing
      # rule that turns the fragment into a box lives in 60_generator.rb. Read
      # the row instead and the seam would check a niche nobody draws.
      #
      # depth_mm is passed in because the generator takes it from the run when
      # a neighbour is selected and defaults to d.62 otherwise - it is a fact
      # about the placement, not about the unit.
      def drawn_niche(unit, depth_mm = nil)
        stated = unit['appliance_niche']
        {
          'bottom'    => (stated && stated['bottom']) || 'floor',
          'bottom_mm' => Generator.niche_bottom_mm(unit),
          'top_mm'    => Generator.niche_top_mm(unit),
          'height_mm' => Generator.niche_height_mm(unit),
          'width_mm'  => unit['width_mm'],
          'depth_mm'  => depth_mm || Generator::NICHE_DEFAULT_DEPTH_MM
        }
      end

      # THE REVIEW. `unit` is a Registry.lookup row, `model` is the appliance
      # somebody specified. Nothing here decides anything: it returns findings
      # (things that disagree) and offers (things the appliance rules propose),
      # and the caller - a person, at a palette - decides.
      #
      # opts:
      #   'installation'  standard | flush_inset. Absent means the appliance
      #                   module's own default for that model.
      #   'depth_mm'      the run's depth, when a neighbour was selected.
      #   'run_top_mm'    the top of the section the housing stands in, so the
      #                   void above it can be answered. Absent means do not ask.
      #   'front_system'  handle | gola. Absent means read the unit's
      #                   opening_method, which is where the engine keeps it.
      def review(unit, model, opts = {})
        return unavailable unless available?

        a = ::UCON::Appliances
        findings = []
        offers   = []

        # 1. THE GOLA RULE COMES FIRST, because it can CHANGE THE MODEL. A grip
        # recess takes the top of a base opening, so an undercounter machine
        # under one must be the ADA variant - and checking the geometry of a
        # model that is about to be substituted would judge the wrong machine.
        front = opts['front_system'] || unit['opening_method'] || 'handle'
        sub = a.for_front_system(model, front)
        unless sub['ok']
          findings << sub['error']
          (sub['remedies'] || []).each { |r| offers << r }
          return { 'checked' => true, 'agrees' => false, 'model' => model,
                   'findings' => findings, 'offers' => offers }
        end
        if sub['substituted']
          offers << "#{front} front: specify #{sub['model']} rather than #{sub['from']} - " \
                    'a grip recess takes the top of the opening and the ADA variant is the ' \
                    'one that fits under it'
          model = sub['model']
        end

        # 2. THE GEOMETRY. The appliance layer is the sole judge: it holds the
        # published openings and the page each was read from, and this file
        # holds no copy of either. Rule 1 applies on that side of the seam
        # exactly as it does on this one.
        niche = drawn_niche(unit, opts['depth_mm'])
        cmp = a.matches_niche?(niche, model, opts['installation'])
        return cmp.merge('model' => model, 'offers' => offers, 'niche' => niche) unless cmp['checked']

        findings.concat(cmp['findings'])

        # 3. THE VOID ABOVE, when the caller says how tall the section is. Not a
        # finding - an unfilled gap above a housing is not a mistake, it is a
        # decision nobody has made yet, and the appliance rules always name
        # something to offer.
        if opts['run_top_mm']
          v = a.void(opts['run_top_mm'], model, opts['installation'])
          if v['applies'] && v['error']
            findings << "#{v['error']}: #{opts['run_top_mm']} - the opening leaves #{v['h']}"
          elsif v['applies'] && v['h'].to_f > 0.5
            offers << "#{v['h'].round(1)} left above the housing: #{v['fill'].join(' or ')}, " \
                      "#{v['material']}, set back #{v['setback_mm']} from the front plane"
          end
        end

        { 'checked' => true, 'agrees' => findings.empty?, 'model' => model,
          'findings' => findings, 'offers' => offers, 'niche' => niche }
      end

      # ------------------------------------------------- the void above, in mm
      #
      # `review` already reports the remainder above a housing, and it reports
      # it as a SENTENCE: "66 left above the housing: filler, carcass, set back
      # 55 from the front plane". That is the right answer for a person and a
      # useless one for the generator, which cannot draw a body from prose.
      # This asks the same question and returns the numbers.
      #
      # It still decides nothing, and the three numbers are all the appliance
      # module's: the HEIGHT is what is left over its published opening, the
      # SETBACK is the appliance rule (a Sub-Zero hinge draws the panel inward),
      # the MATERIAL likewise. The engine owns only where the run's top is.
      #
      # So nothing is drawn until a machine is NAMED - the same shape as B6's
      # run gap, and for the same reason: the number that fixes the body does
      # not exist until somebody says which machine stands there.
      #
      # opts:
      #   'installation'     standard | flush_inset, as in review.
      #   'section_top_mm'   the top of the section the housing stands in.
      #                      Defaults to the unit's own front top.
      def above_housing(unit, model, opts = {})
        return unavailable unless available?

        a   = ::UCON::Appliances
        top = opts['section_top_mm'] ||
              (Generator.base_z_mm(unit) + unit['height_mm'].to_f)
        v = a.void(top, model, opts['installation'])

        unless v['applies']
          return { 'checked' => true, 'applies' => false, 'reason' => v['reason'] }
        end
        if v['error']
          return { 'checked' => true, 'applies' => true, 'error' => v['error'],
                   'h_mm' => v['h'] }
        end

        { 'checked' => true, 'applies' => true, 'model' => model,
          'h_mm' => v['h'], 'bottom_mm' => top - v['h'], 'top_mm' => top,
          'fill' => v['fill'], 'material' => v['material'],
          'setback_mm' => v['setback_mm'] }
      end

      # ------------------------------------------------------------ run gaps
      #
      # THE SECOND QUESTION, AND IT IS STILL ONLY A QUESTION. A run gap is a
      # span between two cabinets where a freestanding machine stands on the
      # floor - the guide prints its WIDTH and nothing else, because the machine
      # is not built into anything. B6.
      #
      # WHY THE ENGINE DRAWS IT AND THE APPLIANCE MODULE DOES NOT, decided
      # 2026-08-25: a reservation nobody can see is worse than an empty gap, so
      # the void must carry this contract - and only this tree may write it.
      # A run gap exists only inside a run, and a run is drawn here, so nothing
      # is lost: the appliance module reports the span it did not reserve and
      # names this command. §11's arrow is untouched, and this file still never
      # writes an attribute and never draws.
      #
      # WHAT THE ENGINE MUST STATE, because the guide cannot know it: the run's
      # own depth and the top of the section. Both are measured from the unit
      # beside the gap - never taken from a constant. 610, 620 and 635 are all
      # live depths in this project.
      # AN INSTALLED PACKAGE CAN STILL BE TOO OLD, and that is a state rather
      # than a fault, exactly as an absent one is. It happened on the FIRST run
      # of this in SketchUp: the engine is loaded from the repository by a
      # one-line dev loader, so `Reload core` brings it up to date in a second,
      # while the appliance package is an INSTALLED .rbz COPY that changes only
      # when somebody rebuilds and reinstalls it. Two extensions, two clocks -
      # §11, on purpose - and this is what that costs. Without this guard the
      # caller was handed `undefined method 'run_gap?'`, which reports what Ruby
      # noticed instead of what to do about it.
      def run_gaps_supported?
        available? && ::UCON::Appliances.respond_to?(:run_gap) &&
          ::UCON::Appliances.respond_to?(:run_gap?)
      end

      # nil when the question can be asked; otherwise the sentence a person
      # needs. One place, so the palette and the generator say the same thing.
      def run_gap_reason
        return 'the UCON Appliances extension is not installed in this session' unless available?
        return nil if run_gaps_supported?

        'the installed UCON Appliances package is older than this engine and knows ' \
        'nothing about a run gap. Rebuild it — ruby tools/build_rbz.rb — reinstall ' \
        'the .rbz through Extension Manager, and restart SketchUp.'
      end

      def run_gap(model, opts = {})
        return { 'checked' => false, 'applies' => false, 'reason' => run_gap_reason } unless run_gaps_supported?

        g = ::UCON::Appliances.run_gap(model, opts['installation'],
                                       run_depth_mm: opts['depth_mm'],
                                       section_top_mm: opts['section_top_mm'])
        g.merge('checked' => true, 'model' => model)
      end

      # Every model the appliance layer says stands in a run rather than in an
      # opening. Observation, and the palette's list: a person should not have
      # to type a model number the other tree already knows.
      def run_gap_models
        return [] unless run_gaps_supported?

        ::UCON::Appliances.all.map { |a| a['model'] }.select do |m|
          ::UCON::Appliances.run_gap?(m)
        end
      end

      # THE MIRROR OF run_gap_models. A run gap publishes a width and nothing
      # else; a housing publishes a HEIGHT, and only a machine with one can say
      # how much of our run it leaves over. Sorted, because a list a person
      # picks from must not reorder itself between two openings of the dialog.
      #
      # An old installed package is a STATE here too: `void` and `opening_h`
      # both predate the run-gap work, so this asks for them by name rather
      # than assuming the copy in Plugins is the one in this repository.
      def housing_models
        return [] unless available? &&
                         ::UCON::Appliances.respond_to?(:opening_h) &&
                         ::UCON::Appliances.respond_to?(:void)

        ::UCON::Appliances.all.map { |a| a['model'] }.select do |m|
          next false if ::UCON::Appliances.respond_to?(:run_gap?) &&
                        ::UCON::Appliances.run_gap?(m)

          !::UCON::Appliances.opening_h(m).nil?
        end.sort
      end

      # Every item of a preset that reserves a span instead of filling an
      # opening, in the order the set states them. A set with none returns [],
      # which is a fact and not a failure.
      def run_gaps_in_set(set_key, opts = {})
        unless run_gaps_supported?
          return { 'checked' => false, 'gaps' => [], 'reason' => run_gap_reason }
        end

        set = ::UCON::Appliances.set(set_key)
        unless set
          return { 'checked' => false, 'gaps' => [], 'reason' => "unknown set #{set_key}" }
        end

        gaps = []
        set['items'].each do |it|
          it['qty'].to_i.times do
            g = run_gap(it['model'], opts)
            gaps << g.merge('slot' => it['slot']) if g['applies']
          end
        end
        { 'checked' => true, 'gaps' => gaps }
      end

      # A SENTENCE FOR A HUMAN, because a hash of findings is not a report.
      # Deliberately not written onto the object: an appliance disagreement is
      # a fact about the SPECIFICATION, and the moment it is stamped into a
      # note it becomes a second copy that outlives the model somebody changed.
      def report(unit, model, opts = {})
        r = review(unit, model, opts)
        return "#{unit['code']}: not checked - #{r['reason']}" unless r['checked']

        head = "#{unit['code']} vs #{r['model']}: " +
               (r['agrees'] ? 'the drawn housing agrees with the published opening' : 'DISAGREES')
        lines = r['findings'].map { |f| "  ! #{f}" } + r['offers'].map { |o| "  > #{o}" }
        ([head] + lines).join("\n")
      end
    end
  end
end

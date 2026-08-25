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

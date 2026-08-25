# frozen_string_literal: true
#
# UCON — appliance openings. The pure layer.
#
# No SketchUp, no network, no state beyond a memoised read of four JSON files,
# so the whole rule set runs headlessly:  ruby test_appliances.rb
#
# WHY THIS IS NOT PART OF THE CABINET ENGINE'S CONTRACT
#
# Object Contract v2 §1.2 forbids commercial data in the CabinetEngine
# dictionary, and its key list is closed. An appliance record carries a price
# and half a dozen keys the contract has never heard of, so it lives in its own
# namespace and its own attribute dictionary, and the generator is never asked
# to store one. The single seam back is a COMPARISON: Appliances.matches_niche?
# tells the engine whether a Cesar unit's declared appliance_niche agrees with
# the machine somebody specified. It validates; it never builds.
#
# The four files have deliberately different lifecycles:
#   appliances.json  geometry and services, versioned by design-guide revision
#   rules.json       UCON's decisions, versioned by the day they were decided
#   prices.json      a dated MSRP snapshot, the only file that goes stale fast
#   sets.json        which models make up a preset; totals are never stored

require 'json'

module UCON
  module Appliances
    # The package's own version, and the ONLY place it is written. The
    # extension loader reads it from here; the panel shows it beside the
    # engine's core version. Two extensions, two clocks, on purpose - a shared
    # number would make "the engine runs without appliances" untestable.
    VERSION = '0.2.0'

    module_function

    DATA_DIR = File.expand_path('../data', __dir__)

    def load_file(name)
      @files ||= {}
      @files[name] ||= JSON.parse(File.read(File.join(DATA_DIR, "#{name}.json")))
    end

    def reset!
      @files = nil
      @index = nil
    end

    # Classic defs, not endless ones: the headless suite is run on the Ruby
    # macOS ships (2.6) as well as on 3.x, and an endless def is a syntax error
    # there. Same reason the engine's own harness was fixed in 848f10f.
    def rules
      load_file('rules')
    end

    def prices
      load_file('prices')
    end

    def sets
      load_file('sets')
    end

    def all
      load_file('appliances')['appliances']
    end

    def index
      @index ||= all.each_with_object({}) { |a, h| h[a['model']] = a }
    end

    def find(model)
      index[model.to_s]
    end

    def price(model)
      row = prices['prices'].find { |p| p['model'] == model.to_s }
      row && row['msrp_usd']
    end

    # ------------------------------------------------------------ installation
    #
    # The finish decides what is on offer, not the designer. Flush inset is
    # printed as available for overlay models only, so a stainless unit is
    # never shown the choice - it is absent, not refused.

    # WHAT IS ON OFFER IS WHAT THE GUIDE PRINTS, not what the finish suggests.
    # An earlier version handed every panel-ready model a flush inset option and
    # so offered one to the whole Designer series, which has a single opening
    # table and no flush inset at all. The data answers; the finish only gates
    # whether a printed flush table may be shown.
    def installations_for(model)
      a = find(model) or return []
      keys = a['installations'].keys
      return keys if a['finish'] == 'panel_ready'

      keys - ['flush_inset']
    end

    def default_installation(model)
      a = find(model) or return nil
      offered = installations_for(model)
      return nil if offered.empty?
      return nil if a['series'] == 'PRO' # no default until Andriy decides

      offered.include?('flush_inset') ? 'flush_inset' : 'standard'
    end

    # The opening, in mm from the floor. Returns nil for anything with no
    # opening at all - a wall hood is not a gap in the cabinetry.
    def opening(model, installation = nil)
      a = find(model) or return nil
      inst = installation || default_installation(model) || 'standard'
      a['installations'][inst] || a['installations']['standard']
    end

    def opening_h(model, installation = nil)
      o = opening(model, installation)
      o && o['h']
    end

    # ------------------------------------------------------------------- void
    #
    # The remainder above a housing in a run. Never left raw: the caller always
    # gets something to offer. Below the threshold a filler, above it a choice.

    def void(section_top_mm, model, installation = nil)
      h = opening_h(model, installation)
      # 'fill' is present on every return, empty where the question does not
      # apply, so a caller never has to test for nil before asking what to offer.
      unless h
        return { 'applies' => false, 'fill' => [],
                 'reason' => 'no published opening height for this appliance' }
      end

      v = section_top_mm - h
      if v.negative?
        return { 'applies' => true, 'h' => v, 'fill' => [],
                 'error' => 'section is shorter than the opening' }
      end

      threshold = rules['void']['threshold_mm']
      fill = v <= threshold ? [rules['void']['at_or_below']] : rules['void']['above']
      { 'applies' => true, 'h' => v, 'fill' => fill,
        'material' => rules['void']['material'],
        'setback_mm' => setback_for(model) }
    end

    # The filler plane. A Sub-Zero hinge draws the panel inward, so anything
    # above the housing sits back on the appliance carcass.
    def setback_for(model)
      a = find(model) or return 0
      rules['filler']['applies_to_brands'].include?(a['brand']) ? rules['filler']['setback_from_cabinet_front_mm'] : 0
    end

    def fits?(section_top_mm, model, installation = nil)
      h = opening_h(model, installation)
      h.nil? ? true : section_top_mm >= h
    end

    # --------------------------------------------------------------- run gap
    #
    # THE OTHER SHAPE, and B6. A void above a housing is what a published
    # opening does not fill. A RUN GAP is what the guide does not publish at
    # all: a pro range stands on the floor BETWEEN two runs rather than inside
    # an opening, so its page prints a width and nothing else. Until this was
    # built, place_set skipped such an item entirely and 1219 mm of run was
    # marked by nothing - which is worse than an empty gap, because a foreign
    # component standing in it looks like a settled question.
    #
    # THE DATA RULE WAS NEVER THE PROBLEM. "A value reaches the file only if it
    # is printed" stands untouched; what was missing was a concept.
    #
    # READ FROM THE DATA, NOT FROM THE CLASS: an opening exists, it has a width,
    # and it has NEITHER a height NOR a depth. `install_class ==
    # 'freestanding_run'` sits on the same models and is the cross-check - a
    # check fails if the two ever disagree, because then one of them is a typo.
    #
    # THE DEPTH IS PART OF THE TEST AND THAT WAS LEARNED THE SAME HOUR. Width
    # and no height alone also catches EC3050TE/S, a coffee system that IS built
    # into a cabinet: it publishes a width and a depth off p.86 and no height.
    # A machine that stands in a run publishes ONE number, because nothing about
    # it is an opening; a slot with two numbers and a missing third is a page
    # somebody has not finished reading. See height_missing? below.
    def run_gap?(model, installation = nil)
      o = opening(model, installation)
      return false unless o

      !o['w'].nil? && o['h'].nil? && o['d'].nil?
    end

    # THE OTHER WAY A HEIGHT CAN BE ABSENT, and it is not a concept but a hole.
    # It must never be drawn: until this was caught, such a model reached the
    # housing builder and came out as a box zero millimetres high - present in
    # the model, invisible on the screen, and countable by the schedule.
    #
    # Documented absence is a fact - every range says in its own notes why its
    # height is not printed. Silent absence is a page to re-read.
    def height_missing?(model, installation = nil)
      o = opening(model, installation)
      return false unless o

      o['h'].nil? && !run_gap?(model, installation)
    end

    # The height rule, on its own so both of its branches can be checked:
    # THE HEIGHT COMES FROM THE APPLIANCE WHERE IT PUBLISHES ONE, and from the
    # section top only where it does not (Reserved_Void_Spec v0.1 §3, corrected
    # 2026-08-25 against the model - a pro range's top stands ABOVE the worktop,
    # so "floor to worktop" was wrong as a rule even where it is right as a
    # number). No freestanding range publishes a height today, so the fallback
    # is the branch that runs; the other exists because the guide may print one
    # tomorrow and the rule must not have to be rewritten when it does.
    def run_gap_height(published_h, section_top_mm)
      published_h || section_top_mm
    end

    # The reservation, as numbers. PURE - it draws nothing, and the two facts
    # the guide cannot know are the caller's to state: how deep the run is and
    # where its top is. A caller that states neither gets a REFUSAL, not a
    # default: 610, 620 and 635 are all live depths in this project, and a
    # silent choice between them is a wrong drawing that looks right.
    def run_gap(model, installation = nil, run_depth_mm: nil, section_top_mm: nil)
      o = opening(model, installation)
      unless o && run_gap?(model, installation)
        return { 'applies' => false,
                 'reason' => 'this model publishes a full opening, or no width at all' }
      end
      if run_depth_mm.to_f <= 0
        return { 'applies' => false,
                 'reason' => 'the run depth is not stated - measure it from the unit beside the gap' }
      end

      h = run_gap_height(o['h'], section_top_mm)
      if h.to_f <= 0
        return { 'applies' => false,
                 'reason' => 'neither the appliance nor the caller states a height' }
      end

      { 'applies' => true, 'model' => model, 'role' => 'run_gap',
        'w' => o['w'], 'd' => run_depth_mm, 'h' => h,
        'height_from' => o['h'] ? 'the published opening' : 'the section top',
        'datum' => rules['datum']['value'],
        'holds' => rules['void']['run_gap']['holds'],
        'source' => o['source'],
        'note' => run_gap_note(model, o, h) }
    end

    # The words that go on the drawn box. They live in rules.json, not here:
    # what a reservation says to whoever opens the model is a decision, and
    # decisions have a date and an author.
    def run_gap_note(model, opening_row, h)
      r = rules['void']['run_gap']
      a = find(model)
      name = a && a['product_name'] ? " (#{a['product_name']})" : ''
      [format('%s - %s mm of run, floor to %s mm', r['when_unassigned'], opening_row['w'], h.round),
       "Holds: #{r['holds']} - #{model}#{name}",
       opening_row['h'] ? nil : r['top_note'],
       r['proud_note'],
       "Source: #{opening_row['source']}"].compact.join(' | ')
    end

    # ------------------------------------------------------------------- gola
    #
    # A grip recess takes the top of the base opening, so every undercounter
    # appliance under it must be the ADA variant. Where no ADA variant exists
    # this is an error at specification time, and the remedies are Cesar's.

    def for_front_system(model, front_system)
      a = find(model) or return { 'ok' => false, 'error' => "unknown model #{model}" }
      return { 'ok' => true, 'model' => model } unless front_system.to_s == 'gola'
      return { 'ok' => true, 'model' => model } unless a['install_class'] == 'undercounter'

      if a['ada_variant']
        { 'ok' => true, 'model' => a['ada_variant'], 'substituted' => true, 'from' => model }
      else
        { 'ok' => false, 'model' => model,
          'error' => "#{model} has no ADA variant and cannot sit under a grip recess",
          'remedies' => rules['gola']['remedies'] }
      end
    end

    # ------------------------------------------------------------------- sets

    def set(key)
      sets['sets'].find { |s| s['key'] == key.to_s }
    end

    # Totals are computed, never stored: a price file dated one day and a total
    # dated another is two facts that can disagree.
    def set_total(key)
      s = set(key) or return nil
      core = %w[fridge fridge2 cooking hood dw]
      excluded = prices['programme']['excluded_addons']
      total = 0
      addons = 0
      lines = s['items'].map do |it|
        p = price(it['model']).to_f
        total += p * it['qty']
        addons += it['qty'] unless core.include?(it['slot']) || excluded.include?(it['model'].split('/').first)
        { 'model' => it['model'], 'qty' => it['qty'], 'line_usd' => p * it['qty'] }
      end
      pr = prices['programme']
      rebate = [pr['cap'], pr['base'] + pr['per_addon'] * addons].min
      { 'key' => s['key'], 'lines' => lines, 'total_usd' => total,
        'addons' => addons, 'rebate_usd' => rebate, 'net_usd' => total - rebate }
    end

    # Consistency, checked when a set is built rather than when a drawing fails.
    def set_problems(key)
      s = set(key) or return ["unknown set #{key}"]
      problems = []
      cooking = s['items'].find { |i| i['slot'] == 'cooking' }
      hood    = s['items'].find { |i| i['slot'] == 'hood' }
      if cooking && hood
        cw = find(cooking['model'])&.fetch('nominal_w_in', nil)
        hw = find(hood['model'])&.fetch('nominal_w_in', nil)
        problems << "hood #{hw}in is narrower than cooking #{cw}in" if cw && hw && hw < cw
      end
      s['items'].each do |i|
        problems << "#{i['model']} is not in appliances.json" unless find(i['model'])
        problems << "#{i['model']} has no price" if price(i['model']).nil?
      end
      problems
    end

    # ------------------------------------------------------- seam to the engine
    #
    # The ONLY call the cabinet engine makes. It compares the niche a Cesar unit
    # type declares against the machine that was actually specified, and says
    # what disagrees. It returns findings; it does not decide, draw or store.
    def matches_niche?(niche, model, installation = nil)
      o = opening(model, installation)
      return { 'checked' => false, 'reason' => 'no published opening for this model' } unless o

      found = []
      if niche['top_mm'] && o['h'] && (niche['top_mm'].to_f - o['h']).abs > 1
        found << "niche top #{niche['top_mm']} vs published opening height #{o['h']}"
      end
      # THE TOP AND THE HEIGHT ARE TWO QUESTIONS, and a housing that starts on
      # a plinth answers the first one correctly while failing the second. The
      # engine's USA tall niche tops out at 2133.6 - which IS the required 84in
      # from the floor - and begins at the plinth top, so the opening it draws
      # is only 2033.6 tall. Comparing tops alone would have called that a
      # match, so the drawn height is compared too when the caller states it.
      if niche['height_mm'] && o['h'] && (niche['height_mm'].to_f - o['h']).abs > 1
        found << "drawn housing height #{niche['height_mm']} vs required opening height #{o['h']}"
      end
      if niche['depth_mm'] && o['d'] && niche['depth_mm'].to_f < o['d'] - 1
        found << "niche depth #{niche['depth_mm']} is shallower than the required #{o['d']}"
      end
      if niche['width_mm'] && o['w'] && (niche['width_mm'].to_f - o['w']).abs > 1
        found << "niche width #{niche['width_mm']} vs published opening width #{o['w']}"
      end
      if niche['bottom'] != 'floor' && niche['bottom_mm'].to_f > 1
        found << "niche bottom is #{niche['bottom'] || niche['bottom_mm']}, " \
                 'but an appliance housing is measured from the floor'
      end
      { 'checked' => true, 'agrees' => found.empty?, 'findings' => found }
    end
  end
end

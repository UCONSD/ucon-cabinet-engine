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
    VERSION = '0.1.1'

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

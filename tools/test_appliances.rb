# frozen_string_literal: true
#
# UCON — appliance openings, headless suite.
#
#   ruby test_appliances.rb
#
# Plain Ruby, no SketchUp, no network. Runs on the Ruby macOS ships as well as
# on 3.x, for the same reason the cabinet engine's own harness does.
#
# Rule 18 from the engine's notes applies here too: when a check fails for a
# reason its title does not mention, the title is the bug.

require 'digest'
require_relative '../src/ucon_appliances/lib/appliances'
require_relative '../src/ucon_appliances/panel_kit'

A = UCON::Appliances

$checks = 0
$fails  = []

def check(title)
  $checks += 1
  ok = yield
  $fails << title unless ok
rescue StandardError => e
  $fails << "#{title} — raised #{e.class}: #{e.message}"
end

# ---------------------------------------------------------------- the files

check('every appliance carries a model, a brand and an install class') do
  A.all.all? { |a| a['model'] && a['brand'] && a['install_class'] }
end

check('every published opening names the page it was read from') do
  A.all.all? do |a|
    a['installations'].values.all? { |i| i['source'].to_s.match?(/p\.\d+/) }
  end
end

check('no two appliances share a model number') do
  models = A.all.map { |a| a['model'] }
  models.uniq.size == models.size
end

check('every service zone names a datum for x and, when it has geometry, for y') do
  A.all.all? do |a|
    a['services'].all? do |s|
      s['datum_x'] == 'none' || (s['datum_x'] && s['datum_y'] == 'floor')
    end
  end
end

check('a zone with a width also has a height, and vice versa') do
  A.all.all? do |a|
    a['services'].all? do |s|
      next true if s['datum_x'] == 'none'

      !s['h'].nil?
    end
  end
end

# ------------------------------------------------------------ the datum rule

check('every opening height is measured from the floor, so none is under 100') do
  A.all.all? do |a|
    a['installations'].values.all? { |i| i['h'].nil? || i['h'] > 100 }
  end
end

check('an undercounter opening is 876 or 826 and nothing else') do
  A.all.select { |a| a['install_class'] == 'undercounter' }.all? do |a|
    a['installations'].values.all? { |i| [876, 826].include?(i['h']) }
  end
end

check('a tall opening is 2127, 2134 or 2137') do
  A.all.select { |a| a['install_class'] == 'tall_opening' }.all? do |a|
    a['installations'].values.all? { |i| [2127, 2134, 2137].include?(i['h']) }
  end
end

check('a wall-mounted appliance publishes no opening at all') do
  A.all.select { |a| a['install_class'] == 'wall_mounted' }.all? { |a| a['installations'].empty? }
end

# ------------------------------------------------------- installation choice

check('a stainless model is never offered flush inset') do
  A.all.reject { |a| a['finish'] == 'panel_ready' }.all? do |a|
    !A.installations_for(a['model']).include?('flush_inset')
  end
end

check('flush inset is offered only where the guide prints a flush table') do
  A.all.all? do |a|
    offered = A.installations_for(a['model'])
    !offered.include?('flush_inset') || a['installations'].key?('flush_inset')
  end
end

check('a panel-ready model with a flush table defaults to flush') do
  A.all.select { |a| a['finish'] == 'panel_ready' && a['installations'].key?('flush_inset') }
   .all? { |a| A.default_installation(a['model']) == 'flush_inset' }
end

check('a Designer column is offered one installation only') do
  A.all.select { |a| a['series'] == 'Designer' && a['install_class'] == 'tall_opening' }
   .all? { |a| A.installations_for(a['model']) == ['standard'] }
end

check('Classic flush inset is wider than Classic standard, by 51 or by 63') do
  A.all.select { |a| a['installations'].key?('flush_inset') }.all? do |a|
    d = a['installations']['flush_inset']['w'] - a['installations']['standard']['w']
    [51, 63, 64].include?(d)
  end
end

# ------------------------------------------------------------------ the void

check('a void is never left without something to offer') do
  [2200, 2250, 2400].all? do |top|
    A.all.reject { |a| a['installations'].empty? }.all? do |a|
      v = A.void(top, a['model'])
      # Not applicable and an error are both answers. What is forbidden is a
      # void that applies, fits, and offers nothing.
      !v['applies'] || v['error'] || !v['fill'].empty?
    end
  end
end

# The threshold is read from rules.json, never written here. A number that
# lives in two files goes stale in one of them, and these checks exist to
# catch that class of thing rather than to join it.
check('a void at or below the threshold offers a filler and nothing else') do
  t = A.rules['void']['threshold_mm']
  A.all.reject { |a| a['installations'].empty? }.all? do |a|
    h = A.opening_h(a['model'])
    next true if h.nil?

    A.void(h + t, a['model'])['fill'] == ['filler']
  end
end

check('a void one millimetre above the threshold offers the open shelf as well') do
  t = A.rules['void']['threshold_mm']
  A.all.reject { |a| a['installations'].empty? }.all? do |a|
    h = A.opening_h(a['model'])
    next true if h.nil?

    A.void(h + t + 1, a['model'])['fill'].include?('open_shelf_cabinet')
  end
end

# The reason the threshold moved from 70 to 120 on 2026-08-25: at 70 the
# Classic standard opening left 73 and the tool offered a 73 mm open shelf.
check('a tall Sub-Zero housing in a 2200 run is always a filler, never a shelf') do
  %w[CL3650UID/S/T/R CL4250SD/S/T CL4850SD/S/T DEC3050R/L DEC3650R/L DEC2450W/L].all? do |m|
    A.installations_for(m).all? { |i| A.void(2200, m, i)['fill'] == ['filler'] }
  end
end

check('a section shorter than the opening is an error, not a negative void') do
  v = A.void(2000, 'DEC3050R/L')
  v['error'] && v['h'].negative?
end

check('the filler setback is 55 for Sub-Zero and zero for everyone else') do
  A.all.all? do |a|
    expected = a['brand'] == 'Sub-Zero' ? 55 : 0
    A.setback_for(a['model']) == expected
  end
end

check('H210 on a 100 plinth takes every published tall opening') do
  A.all.select { |a| a['install_class'] == 'tall_opening' }.all? do |a|
    A.installations_for(a['model']).all? { |i| A.fits?(2200, a['model'], i) }
  end
end

check('a 2000 carcass on a 100 plinth takes none of them') do
  A.all.select { |a| a['install_class'] == 'tall_opening' }.none? do |a|
    A.fits?(2100, a['model'], 'standard')
  end
end

# --------------------------------------------------------------- the run gap
#
# B6. A void above a housing is what an opening does not fill; a run gap is
# what the guide does not publish at all.

check('a run gap is read from the data - a width, no height AND no depth') do
  from_data = A.all.map { |a| a['model'] }.select do |m|
    o = A.opening(m)
    o && !o['w'].nil? && o['h'].nil? && o['d'].nil?
  end
  by_rule = A.all.map { |a| a['model'] }.select { |m| A.run_gap?(m) }
  !by_rule.empty? && by_rule.sort == from_data.sort
end

# THE CHECK ABOVE FAILED ON ITS FIRST RUN and the failure is why the depth is in
# the rule. EC3050TE/S publishes a width and a depth off p.86 and no height, and
# it IS built into a cabinet. Kept as two checks rather than corrected into one,
# because the second one is now the only thing standing between that model and a
# housing drawn zero millimetres high.

check('a missing height that is not a run gap is a hole in the data, and is named') do
  A.height_missing?('EC3050TE/S') && !A.run_gap?('EC3050TE/S') &&
    A.all.select { |a| A.height_missing?(a['model']) }.map { |a| a['model'] } == ['EC3050TE/S']
end

check('no model is both a run gap and a hole') do
  A.all.none? { |a| A.run_gap?(a['model']) && A.height_missing?(a['model']) }
end

check('every run gap says in its own notes why its height is absent') do
  A.all.select { |a| A.run_gap?(a['model']) }.all? do |a|
    a['notes'].any? { |n| n.downcase.include?('not published') }
  end
end

check('the data and install_class never disagree about which models stand in a run') do
  A.all.all? { |a| A.run_gap?(a['model']) == (a['install_class'] == 'freestanding_run') }
end

check('a wall-mounted hood is not a run gap, because it has no opening at all') do
  A.opening('PW482418').nil? && A.run_gap?('PW482418') == false
end

check('a fridge with a full published opening is not a run gap') do
  A.run_gap?('CL4850SD/S/T') == false &&
    A.run_gap?('CL4850SD/S/T', 'standard') == false
end

check('the height rule prefers the appliance and falls back to the section top') do
  A.run_gap_height(928, 880) == 928 && A.run_gap_height(nil, 880) == 880
end

check('a run gap refuses to be drawn when the caller states no run depth') do
  r = A.run_gap('DF48650C/S/P', nil, section_top_mm: 880)
  r['applies'] == false && r['reason'].include?('run depth')
end

check('a run gap refuses to be drawn when nobody states a height') do
  r = A.run_gap('DF48650C/S/P', nil, run_depth_mm: 620)
  r['applies'] == false && r['reason'].include?('height')
end

check('the 48in range reserves its printed width, floor to the section top') do
  r = A.run_gap('DF48650C/S/P', nil, run_depth_mm: 620, section_top_mm: 880)
  r['applies'] && r['w'] == 1219 && r['d'] == 620 && r['h'] == 880 &&
    r['role'] == 'run_gap' && r['datum'] == 'floor' &&
    r['height_from'] == 'the section top'
end

check('a run gap names the page it was read from and invents no dimension') do
  r = A.run_gap('DF48650C/S/P', nil, run_depth_mm: 620, section_top_mm: 880)
  n = r['note']
  n.include?('p.97') && n.include?('1219') && n.include?('880') &&
    !n.include?('610') && !n.include?('928')
end

check('a run gap says it is unassigned, and says what would fill it') do
  r = A.run_gap('DF48650C/S/P', nil, run_depth_mm: 620, section_top_mm: 880)
  r['note'].include?('RESERVED') && r['holds'].to_s.include?('appliance itself')
end

check('every model that is a run gap is asked for by name in at least one set') do
  gaps = A.all.map { |a| a['model'] }.select { |m| A.run_gap?(m) }
  in_sets = A.sets['sets'].flat_map { |s| s['items'].map { |i| i['model'] } }.uniq
  gaps.all? { |m| in_sets.include?(m) }
end

# ------------------------------------------------------------------- gola

check('gola substitutes the ADA variant where one exists') do
  r = A.for_front_system('DW2451', 'gola')
  r['ok'] && r['model'] == 'DW2451/ADA' && r['substituted']
end

check('gola refuses a 15in undercounter, because no ADA version exists') do
  %w[DEU1550W/L DEU1550I/L].all? do |m|
    r = A.for_front_system(m, 'gola')
    !r['ok'] && r['error'].include?('no ADA variant')
  end
end

check('a refusal carries the remedies rather than only the complaint') do
  A.for_front_system('DEU1550I/L', 'gola')['remedies'].size >= 2
end

check('gola leaves a tall appliance alone') do
  r = A.for_front_system('DEC3050R/L', 'gola')
  r['ok'] && r['model'] == 'DEC3050R/L' && r['substituted'].nil?
end

check('a handled front changes nothing anywhere') do
  A.all.all? do |a|
    r = A.for_front_system(a['model'], 'handle')
    r['ok'] && r['model'] == a['model']
  end
end

check('every named ADA variant has a price') do
  A.all.map { |a| a['ada_variant'] }.compact.all? { |m| !A.price(m).nil? }
end

# ------------------------------------------------------------------- sets

check('all nine sets exist') do
  A.sets['sets'].size == 9 &&
    %w[36 48 60].all? { |w| %w[Core Plus Full].all? { |l| A.set("#{w}_#{l}") } }
end

check('no set has a hood narrower than its cooking width') do
  A.sets['sets'].all? { |s| A.set_problems(s['key']).none? { |p| p.include?('hood') } }
end

check('every model in every set has a price') do
  A.sets['sets'].all? { |s| A.set_problems(s['key']).none? { |p| p.include?('no price') } }
end

check('a set total is the sum of its lines') do
  A.sets['sets'].all? do |s|
    t = A.set_total(s['key'])
    (t['lines'].sum { |l| l['line_usd'] } - t['total_usd']).abs < 0.01
  end
end

check('the rebate never exceeds the programme cap') do
  A.sets['sets'].all? { |s| A.set_total(s['key'])['rebate_usd'] <= A.prices['programme']['cap'] }
end

check('a Core set earns the base rebate and no add-ons') do
  %w[36_Core 48_Core 60_Core].all? do |k|
    t = A.set_total(k)
    t['addons'].zero? && t['rebate_usd'] == A.prices['programme']['base']
  end
end

check('totals rise with the level, at every cooking width') do
  %w[36 48 60].all? do |w|
    c = A.set_total("#{w}_Core")['total_usd']
    p = A.set_total("#{w}_Plus")['total_usd']
    f = A.set_total("#{w}_Full")['total_usd']
    c < p && p < f
  end
end

check('totals rise with the cooking width, at every level') do
  %w[Core Plus Full].all? do |l|
    A.set_total("36_#{l}")['total_usd'] < A.set_total("48_#{l}")['total_usd']
  end
end

check('a price file that goes stale says when it was taken') do
  A.prices['snapshot'].to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
end

check('the price file says the appliances are not ours to sell') do
  A.prices['disclaimer'].to_s.include?('not supplied by UCON')
end

# ------------------------------------------------------- seam to the engine

check('a niche that agrees with the published opening reports no findings') do
  r = A.matches_niche?({ 'top_mm' => 2127, 'width_mm' => 902, 'bottom' => 'floor' },
                       'CL3650UID/S/T/R', 'standard')
  r['checked'] && r['agrees']
end

check('a niche measured from the plinth top is reported, not silently accepted') do
  r = A.matches_niche?({ 'top_mm' => 2127, 'bottom' => 'plinth_top', 'bottom_mm' => 100 },
                       'CL3650UID/S/T/R', 'standard')
  r['findings'].any? { |f| f.include?('measured from the floor') }
end

check('a niche of the wrong height is reported with both numbers') do
  r = A.matches_niche?({ 'top_mm' => 2000, 'bottom' => 'floor' }, 'DEC3050R/L')
  r['findings'].any? { |f| f.include?('2000') && f.include?('2134') }
end

check('the seam declines to judge a model with no published opening') do
  A.matches_niche?({ 'top_mm' => 900 }, 'PW482418')['checked'] == false
end

# The case the cabinet engine actually produces: usa_tall_h210 draws its
# housing from the top of the plinth to 2133.6, so the TOP is right and the
# OPENING IS 100 SHORT. A seam that compared tops alone would pass it.
check('a housing with the right top and the wrong height is caught by the height') do
  r = A.matches_niche?({ 'top_mm' => 2133.6, 'height_mm' => 2033.6,
                         'bottom' => 'plinth_top', 'bottom_mm' => 100 },
                       'DEC3050R/L')
  r['findings'].any? { |f| f.include?('2033.6') && f.include?('2134') } &&
    r['findings'].any? { |f| f.include?('measured from the floor') } &&
    r['findings'].none? { |f| f.start_with?('niche top') }
end

check('a niche shallower than the published depth is reported') do
  r = A.matches_niche?({ 'top_mm' => 2134, 'height_mm' => 2134, 'depth_mm' => 620,
                         'bottom' => 'floor' }, 'DEC3050R/L')
  r['findings'].any? { |f| f.include?('shallower') && f.include?('635') }
end

check('a housing drawn from the floor to the published opening agrees on all four') do
  o = A.opening('DEC3050R/L')
  r = A.matches_niche?({ 'top_mm' => o['h'], 'height_mm' => o['h'], 'width_mm' => o['w'],
                         'depth_mm' => o['d'], 'bottom' => 'floor' }, 'DEC3050R/L')
  r['agrees']
end

# ------------------------------------------------------------------ rules

check('the decided rules are all present and none is nil') do
  r = A.rules
  r['datum']['value'] == 'floor' &&
    r['filler']['setback_from_cabinet_front_mm'] == 55 &&
    r['void']['threshold_mm'] == 120 &&
    r['panels']['face_thickness_mm'] == 22
end

check('the sections agree with the plinth heights the cabinet registry states') do
  s = A.rules['sections']
  s['base_h78']['plinth_mm'] == 100 && s['base_h84']['plinth_mm'] == 60 &&
    s['base_h78']['top_mm'] == 880 && s['base_h84']['top_mm'] == 900 &&
    s['tall']['top_mm'] == 2200
end

check('UCON supplies the face panel only, and the kit replaces the other two') do
  p = A.rules['panels']
  p['ucon_supplies'] == ['face'] &&
    p['mounting_kit']['eliminates'].sort == %w[backer spacer]
end

# ------------------------------------------------------------------ report


# ----------------------------------------------------------------- panel kit
#
# The other half of the same pair of checks in tools/test_contract.rb. The kit
# is copied into both trees rather than shared, because neither extension may
# require the other; these checks are the price of that, and they are cheaper
# than a design that drifts in one panel and not the other.

KIT_EXPECTED_VERSION = 1

check('the vendored panel kit is the version this suite expects') do
  UCON::Appliances::PanelKit::KIT_VERSION == KIT_EXPECTED_VERSION
end

check('the vendored panel kit still hashes to what the generator stamped') do
  k = UCON::Appliances::PanelKit
  Digest::SHA256.hexdigest(k::CSS)[0, 16] == k::KIT_SHA
end

check('the kit carries the trust encoding both panels depend on') do
  css = UCON::Appliances::PanelKit::CSS
  %w[--ok --amber --red .trust-printed .trust-assumed .trust-decide .flag .peer].all? do |t|
    css.include?(t)
  end
end

check('the kit defines the shared submenu root without requiring the engine') do
  UCON.respond_to?(:extensions_menu)
end

check('the panel observes the engine but never calls into it') do
  panel = File.read(File.expand_path('../src/ucon_appliances/ui_panel.rb', __dir__))
  # defined? and a version read are observation. Anything that makes the engine
  # DO something is the direction the seam exists to forbid.
  forbidden = ['CabinetEngine.load_core', 'CabinetEngine::Generator', 'CabinetEngine::Units']
  forbidden.none? { |f| panel.include?(f) } && panel.include?('def core_state')
end

check('the package states its own version, in exactly one place') do
  loader = File.read(File.expand_path('../src/ucon_appliances.rb', __dir__))
  lib    = File.read(File.expand_path('../src/ucon_appliances/lib/appliances.rb', __dir__))
  UCON::Appliances::VERSION =~ /\A\d+\.\d+\.\d+\z/ &&
    loader.include?('UCON::Appliances::VERSION') &&
    lib.scan(/VERSION = '/).size == 1
end

puts "#{$checks} checks, #{$fails.size} failures"
unless $fails.empty?
  puts
  $fails.each { |f| puts "  FAIL  #{f}" }
  exit 1
end

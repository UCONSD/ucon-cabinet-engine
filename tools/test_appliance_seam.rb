# frozen_string_literal: true
#
# Headless check of the ONE seam between the cabinet engine and the appliance
# module — core/88_appliance_check.rb.
#
#   ruby tools/test_appliance_seam.rb
#   UCON_APPLIANCES=/path/to/ucon-appliances ruby tools/test_appliance_seam.rb
#
# It is a SEPARATE suite from tools/test_contract.rb on purpose. The engine's
# own suite must keep passing on a machine where the appliance extension was
# never installed — that is what "optional dependency" means, and a suite that
# needs both trees to be green cannot prove it.
#
# When the appliance package is not found this file SKIPS and says so, with
# exit 0. A skip is honest; a green tick for checks that never ran is not.

require_relative '../src/ucon_cabinet_engine/core/10_standards'
require_relative '../src/ucon_cabinet_engine/core/20_contract'
require_relative '../src/ucon_cabinet_engine/core/50_registry'
require_relative '../src/ucon_cabinet_engine/core/85_export'
require_relative '../src/ucon_cabinet_engine/core/60_generator'
require_relative '../src/ucon_cabinet_engine/core/88_appliance_check'

Registry = UCON::CabinetEngine::Registry
Check    = UCON::CabinetEngine::ApplianceCheck

puts "ruby #{RUBY_VERSION} (#{RUBY_PLATFORM})"

$failures = 0
$checks   = 0

def check(description)
  $checks += 1
  yield
  puts "  ok    #{description}"
rescue StandardError => e
  $failures += 1
  puts "  FAIL  #{description}"
  puts "        #{e.class}: #{e.message}"
end

# ---------------------------------------------------------------------------
# The engine half, which is checked WHETHER OR NOT the appliance module is
# there. These are the checks that prove the dependency is optional.

puts "\nthe seam with no appliance module"

check('the engine loads and works with no appliance module in sight') do
  raise 'registry did not load' if Registry.catalog.empty?
end

check('a review with no appliance module reports not-checked, and does not raise') do
  unless Check.available?
    r = Check.review({ 'code' => 'CR9700' }, 'DEC3050R/L')
    raise r.inspect if r['checked']
    raise 'no reason given' unless r['reason'].to_s.include?('not installed')
  end
end

check('the drawn niche is built from the generator, not from the registry row') do
  u = Registry.lookup('CR9700')
  n = Check.drawn_niche(u)
  # The row states only a datum NAME and a top. The BOX is the generator's, and
  # neither of these numbers exists anywhere in the JSON.
  #
  # 2026-08-26: the datum moved from `plinth_top` to `floor` (owed 10 finding
  # 1), so the two numbers this check reads changed with it - 100 -> 0 and
  # 2033,6 -> 2133,6. What it proves did not change at all: the height is still
  # nowhere in the row, and the generator is still the only thing that knows it.
  raise n.inspect unless n['bottom_mm'].abs < 0.001
  raise n.inspect unless (n['height_mm'] - 2133.6).abs < 0.1
end

# ---------------------------------------------------------------------------

def appliance_lib
  # MOVED 2026-08-25: the package lives IN THIS REPOSITORY now, at
  # src/ucon_appliances, and its lib file is lib/appliances.rb. The old loose
  # copy under ~/Downloads had lib/ucon_appliances.rb, and while both existed
  # this list quietly preferred the stale one - a suite that finds the wrong
  # tree does not fail, it just gets quieter, which is worse.
  candidates = [ENV['UCON_APPLIANCES'],
                File.expand_path('../src/ucon_appliances', __dir__),
                File.expand_path('../../ucon-appliances', __dir__),
                File.expand_path('~/Downloads/ucon-appliances'),
                File.expand_path('~/dev/ucon-appliances')].compact
  candidates.each do |d|
    %w[appliances.rb ucon_appliances.rb].each do |base|
      f = File.join(d, 'lib', base)
      return f if File.file?(f)
    end
  end
  nil
end

lib = appliance_lib
unless lib
  puts "\nSKIPPED: the appliance package was not found."
  puts '         Set UCON_APPLIANCES=/path/to/ucon-appliances and run again.'
  puts "\n#{$checks} checks, #{$failures} failure(s)"
  exit($failures.zero? ? 0 : 1)
end

require lib
puts "\nthe seam against #{File.dirname(File.dirname(lib))}"

check('the appliance module is now visible to the seam') do
  raise 'still not available' unless Check.available?
end

# CR9700 is the 30in USA fridge door, printed p.418. DEC3050R/L is the 30in
# Sub-Zero Designer column that stands behind it. This pair is the reason the
# seam exists, and all three findings below are REAL: they describe the model
# the engine draws today.
puts "\nCR9700 (USA fridge door, 762) vs DEC3050R/L (Designer 30in column)"

# TWO CHECKS INVERTED 2026-08-26, and inverted is the right word: they were
# right on 2026-08-25 and the thing they described has been FIXED (owed 10
# finding 1, Andriy). The housing is drawn from the floor now, so the seam must
# no longer be able to say either sentence. A check that once proved a defect
# exists is the natural place to prove it is gone.
check('the housing the engine draws is no longer 100 short') do
  r = Check.review(Registry.lookup('CR9700'), 'DEC3050R/L')
  raise r['findings'].inspect if r['findings'].any? { |f| f.include?('2033.6') }
  raise r['findings'].inspect if r['findings'].any? { |f| f.start_with?('drawn housing height') }
end

check('and the datum finding is gone with it: the housing starts on the floor') do
  r = Check.review(Registry.lookup('CR9700'), 'DEC3050R/L')
  raise r['findings'].inspect if r['findings'].any? { |f| f.include?('measured from the floor') }
end

# AND THE DEPTH SURVIVES ON PURPOSE. Findings 2 and 3 were decided the other
# way the same day: the drawing keeps the Cesar door width and the run's depth,
# the machine's published cutout is NOT copied onto the object, and this seam
# stays the live judge of the difference. So the pair below is not a regression
# - it is the decision, and it has a check so that a later session cannot
# mistake it for one.
check('the depth disagreement is still reported, because it was decided to stay') do
  r = Check.review(Registry.lookup('CR9700'), 'DEC3050R/L')
  raise r.inspect if r['agrees']
  raise r['findings'].inspect unless r['findings'].any? { |f| f.include?('shallower') }
end

check('the TOP is right, so a seam comparing tops alone would have passed it') do
  r = Check.review(Registry.lookup('CR9700'), 'DEC3050R/L')
  raise r['findings'].inspect if r['findings'].any? { |f| f.start_with?('niche top') }
end

check('the d.62 default is shallower than the 635 the column needs') do
  r = Check.review(Registry.lookup('CR9700'), 'DEC3050R/L')
  raise r['findings'].inspect unless r['findings'].any? { |f| f.include?('shallower') }
end

check('the width agrees: 30in is 762 on both sides of the seam') do
  r = Check.review(Registry.lookup('CR9700'), 'DEC3050R/L')
  raise r['findings'].inspect if r['findings'].any? { |f| f.start_with?('niche width') }
end

check('a 24in door in front of a 30in column is a width disagreement') do
  r = Check.review(Registry.lookup('CR9600'), 'DEC3050R/L')
  raise r['findings'].inspect unless r['findings'].any? { |f| f.start_with?('niche width') }
end

check('the seam never mutates the unit it was handed') do
  u = Registry.lookup('CR9700')
  before = Marshal.dump(u)
  Check.review(u, 'DEC3050R/L', 'run_top_mm' => 2200)
  raise 'the unit changed' unless Marshal.dump(u) == before
end

check('a section top produces an offer, not a finding') do
  r = Check.review(Registry.lookup('CR9700'), 'DEC3050R/L', 'run_top_mm' => 2200)
  raise r['offers'].inspect unless r['offers'].any? { |o| o.include?('filler') && o.include?('55') }
  raise r['findings'].inspect if r['findings'].any? { |f| f.include?('left above') }
end

puts "\nthe gola rule, which can change the model before anything is measured"

check('a grip-recess unit substitutes the ADA dishwasher and says why') do
  u = Registry.lookup('CR9700').merge('opening_method' => 'gola')
  r = Check.review(u, 'DW2451')
  raise r['model'] unless r['model'] == 'DW2451/ADA'
  raise r['offers'].inspect unless r['offers'].any? { |o| o.include?('DW2451/ADA') }
end

check('a 15in undercounter under a grip recess is refused, with remedies') do
  u = Registry.lookup('CR9700').merge('opening_method' => 'gola')
  r = Check.review(u, 'DEU1550I/L')
  raise r.inspect if r['agrees']
  raise r['findings'].inspect unless r['findings'].any? { |f| f.include?('no ADA variant') }
  raise 'refused without a way out' if r['offers'].empty?
end

check('a handled front changes no model anywhere') do
  u = Registry.lookup('CR9700').merge('opening_method' => 'handle')
  raise 'model moved' unless Check.review(u, 'DW2451')['model'] == 'DW2451'
end

# THE HOLE THESE TWO CHECKS LEFT, found 2026-08-28 and closed the same day.
#
# The two checks above assert that the substitution HAPPENED and that the offer
# names the ADA model. Neither of them asks the seam to measure anything
# afterwards - and until today it could not: DW2451/ADA was named as a
# substitution target by appliances.json and was not a row in it, so
# matches_niche? answered 'no published opening for this model' and the geometry
# review SILENTLY STOPPED, at precisely the moment the front system changed which
# machine was being judged. Both checks stayed green throughout.
#
# A check can only fail on what it looks at. So this one looks at the thing the
# other two could not see: that a review AFTER a substitution still measures.

check('after a gola substitution the geometry is still measured, not skipped') do
  u = Registry.lookup('V80630').merge('opening_method' => 'gola')
  r = Check.review(u, 'DW2451', 'depth_mm' => 610)
  raise r.inspect unless r['checked']
  raise r['model'] unless r['model'] == 'DW2451/ADA'
  raise 'the substituted model was never measured' if r['niche'].nil?
  # and it must judge against the ADA opening, 826, not the parent's 876
  raise r['findings'].inspect unless r['findings'].any? { |f| f.include?('826') }
  raise r['findings'].inspect if r['findings'].any? { |f| f.include?('876') }
end

check('a model that is already ADA is not refused under a grip recess') do
  u = Registry.lookup('V80630').merge('opening_method' => 'gola')
  r = Check.review(u, 'DW2451/ADA', 'depth_mm' => 610)
  raise r.inspect unless r['checked']
  raise r['model'] unless r['model'] == 'DW2451/ADA'
  raise 'a swap was offered for a machine that needed none' if
    r['offers'].any? { |o| o.include?('rather than') }
  # AND IT MUST NOT PASS BY BEING UNKNOWN. Written after this check went green
  # against the very defect it exists for: with the row absent, the gola branch
  # refuses with "unknown model", the review still returns checked, no swap is
  # offered, and all three assertions above hold - for the wrong reason. That is
  # learned rule 18's cousin, an invariant asserted sideways, and it is caught here
  # because the guard was run against the defect (learned rule 12).
  raise r['findings'].inspect if r['findings'].any? { |f| f.include?('unknown model') }
  raise 'the machine was never measured' if r['niche'].nil?
end

check('every substitution target the appliance data names can be measured') do
  # The one-line version of the whole finding: a target that cannot be found is
  # a review that cannot happen, and nothing else in either suite says so.
  a = ::UCON::Appliances
  missing = a.all.map { |x| x['ada_variant'] }.compact.reject { |m| a.find(m) }
  raise "unmeasurable substitution targets: #{missing.inspect}" unless missing.empty?
end

puts "\nthe run gap — B6, and the engine states what the guide cannot know"

check('a run gap comes back with the printed width and the depth the engine states') do
  g = Check.run_gap('DF48650C/S/P', 'depth_mm' => 620, 'section_top_mm' => 880)
  raise g.inspect unless g['checked'] && g['applies']
  raise g.inspect unless g['w'] == 1219 && g['d'] == 620 && g['h'] == 880
  raise g.inspect unless g['role'] == 'run_gap' && g['datum'] == 'floor'
end

check('an installed package that is TOO OLD is a state, not a Ruby error') do
  # THE FIRST RUN IN SKETCHUP FAILED EXACTLY HERE. The engine comes from the
  # repository through a one-line dev loader and `Reload core` updates it in a
  # second; the appliance package is an installed .rbz copy and does not move
  # until somebody rebuilds it. So the pair CAN be mismatched, and the seam must
  # answer that with a sentence rather than `undefined method`.
  raise 'the tree in this repo must support run gaps' unless Check.run_gaps_supported?
  raise 'a supported package must give no reason' unless Check.run_gap_reason.nil?
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/88_appliance_check.rb', __dir__))
  code = src.gsub(/^\s*#.*$/, '')
  raise 'every run-gap entry point must ask' unless code.scan('run_gaps_supported?').size >= 4
  raise 'the rebuild instruction must be in the sentence' unless
    Check.method(:run_gap_reason).owner && src.include?('tools/build_rbz.rb')
end

check('the seam lists the machines that stand in a run, and only those') do
  models = Check.run_gap_models
  raise models.inspect unless models.include?('DF48650C/S/P')
  raise 'a wall hood is not a run gap' if models.include?('PW482418')
  raise 'a column is not a run gap' if models.include?('DEC3050R/L')
  raise models.inspect unless models.size == 3
end

check('the seam refuses a run gap when the engine states no depth') do
  g = Check.run_gap('DF48650C/S/P', 'section_top_mm' => 880)
  raise g.inspect if g['applies']
  raise g.inspect unless g['reason'].include?('run depth')
end

check('a fridge asked for as a run gap is refused, not quietly reshaped') do
  g = Check.run_gap('DEC3050R/L', 'depth_mm' => 620, 'section_top_mm' => 2200)
  raise g.inspect if g['applies']
end

check('the 48in Core set carries exactly one run gap, and it is the range') do
  r = Check.run_gaps_in_set('48_Core', 'depth_mm' => 620, 'section_top_mm' => 880)
  raise r.inspect unless r['checked'] && r['gaps'].size == 1
  g = r['gaps'].first
  raise g.inspect unless g['model'] == 'DF48650C/S/P' && g['slot'] == 'cooking' && g['w'] == 1219
end

check('the wall hood is in that set and is not one of its gaps') do
  r = Check.run_gaps_in_set('48_Core', 'depth_mm' => 620, 'section_top_mm' => 880)
  raise r.inspect if r['gaps'].any? { |g| g['model'] == 'PW482418' }
end

check('an unknown set is answered, not raised') do
  r = Check.run_gaps_in_set('no_such_set', 'depth_mm' => 620, 'section_top_mm' => 880)
  raise r.inspect if r['checked']
  raise r.inspect unless r['gaps'] == [] && r['reason'].include?('no_such_set')
end

puts "\nthe wall reservation - the hood, and Contract v2.4"

check('the seam supports wall reservations, and a supported package gives no reason') do
  raise 'the tree in this repo must support them' unless Check.wall_reservations_supported?
  raise 'a supported package must give no reason' unless Check.wall_reservation_reason.nil?
end

check('an installed package too old for a HOOD is a state, not a Ruby error') do
  # The run gap learned this in SketchUp as `undefined method run_gap?`. This one
  # was guarded from its first line, and on 2026-08-28 a probe found the installed
  # package really was 0.2.0 - so the guard was true before the feature shipped.
  src  = File.read(File.expand_path('../src/ucon_cabinet_engine/core/88_appliance_check.rb', __dir__))
  code = src.gsub(/^\s*#.*$/, '')
  raise 'every wall-reservation entry point must ask' unless
    code.scan('wall_reservations_supported?').size >= 3
  raise 'the rebuild instruction must be in the sentence' unless src.include?('tools/build_rbz.rb')
end

check('the seam lists the machines that hang on a wall, and only those') do
  m = Check.wall_reservation_models
  raise m.inspect unless m == %w[PW362418 PW482418 PW602418]
  raise 'a range is not a wall reservation' if m.include?('DF48650C/S/P')
  raise 'a column is not a wall reservation' if m.include?('DEC3050R/L')
end

check('the three reservation kinds are three different lists, with nothing in two of them') do
  hang = Check.wall_reservation_models
  run  = Check.run_gap_models
  hous = Check.housing_models
  raise 'a model is in two lists' unless (hang & run).empty? && (hang & hous).empty? && (run & hous).empty?
end

check('a hood refuses without a countertop, and the engine is told whose job that is') do
  r = Check.wall_reservation('PW482418')
  raise r.inspect if r['applies']
  raise r['reason'] unless r['reason'].include?('countertop')
end

check('a hood refuses without a mounting height, and the refusal names the RANGE') do
  r = Check.wall_reservation('PW482418', 'countertop_mm' => 920)
  raise r.inspect if r['applies']
  raise r['reason'] unless r['reason'].include?('RANGE') &&
                           r['reason'].include?('762') && r['reason'].include?('914')
end

check('a height outside the printed range is refused at both ends') do
  lo = Check.wall_reservation('PW482418', 'countertop_mm' => 920, 'bottom_above_top_mm' => 761)
  hi = Check.wall_reservation('PW482418', 'countertop_mm' => 920, 'bottom_above_top_mm' => 915)
  raise 'the low end was accepted'  if lo['applies']
  raise 'the high end was accepted' if hi['applies']
end

check('a stated height inside the range answers with the envelope and both edges') do
  r = Check.wall_reservation('PW482418', 'countertop_mm' => 920, 'bottom_above_top_mm' => 800)
  raise r.inspect unless r['applies'] && r['checked']
  raise r.inspect unless r['w'] == 1219 && r['d'] == 610 && r['h'] == 457
  raise r.inspect unless r['bottom_mm'] == 1720.0 && r['top_mm'] == 2177.0
  raise r.inspect unless r['datum'] == 'countertop'
end

check('the attributes the generator would write pass Contract v2.4') do
  r = Check.wall_reservation('PW482418', 'countertop_mm' => 920, 'bottom_above_top_mm' => 800)
  a = UCON::CabinetEngine::Generator.wall_reservation_attributes(
    'PW482418', width_mm: r['w'], depth_mm: r['d'], height_mm: r['h'],
    bottom_mm: r['bottom_mm'], countertop_mm: 920, bottom_above_top_mm: 800,
    source_ref: r['source'], note: r['note'], countertop_note: '920 MEASURED off the reservation below'
  )
  UCON::CabinetEngine::Contract.validate!(a)
  raise a.inspect unless a['void_role'] == 'wall_reservation'
  # A HOOD IS WALL-HUNG AND THE CONTRACT ALREADY SAID SO. The first draft wrote
  # mount_bottom_mm without mounting and validate! refused it - the invariant
  # doing its job, and the reason v2.4 had to add only the void_role.
  raise a.inspect unless a['mounting'] == 'wall_hung' && a['mount_bottom_mm'] == 1720.0
  raise a.inspect unless a['code'].nil? && a['manufacturer'] == 'client'
end

check('the object says which number was measured and which was stated') do
  r = Check.wall_reservation('PW482418', 'countertop_mm' => 920, 'bottom_above_top_mm' => 800)
  a = UCON::CabinetEngine::Generator.wall_reservation_attributes(
    'PW482418', width_mm: r['w'], depth_mm: r['d'], height_mm: r['h'],
    bottom_mm: r['bottom_mm'], countertop_mm: 920, bottom_above_top_mm: 800,
    source_ref: r['source'], note: r['note'], countertop_note: '920 MEASURED off the reservation below'
  )
  raise a['notes'] unless a['notes'].include?('MEASURED') && a['notes'].include?('STATED')
  raise a['notes'] unless a['notes'].include?('NEVER ORDERED')
  raise a['notes'] unless a['source_ref'].to_s.match?(/p\.\d+/)
end

check('the pure attributes refuse a hood at or below the countertop') do
  begin
    UCON::CabinetEngine::Generator.wall_reservation_attributes(
      'PW482418', width_mm: 1219, depth_mm: 610, height_mm: 457,
      bottom_mm: 900, countertop_mm: 920, bottom_above_top_mm: -20,
      source_ref: 'p.141'
    )
    raise 'a hood below the countertop was accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('cannot hang')
  end
end

check('this file still writes nothing and draws nothing') do
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/88_appliance_check.rb', __dir__))
  forbidden = ['set_attribute', 'add_group', 'add_instance', 'start_operation']
  raise 'the seam has grown a hand' if forbidden.any? { |f| src.include?(f) }
end

puts "\nthe remainder above the housing, as numbers - owed 10 finding 4"

# `review` reports it in prose and always did. The generator cannot draw a body
# from a sentence, so the same question is asked again for its three numbers -
# and every one of them belongs to the appliance module.

check('the void above comes back in millimetres, not in a sentence') do
  i = Check.above_housing(Registry.lookup('CR9700'), 'DEC3050R/L')
  raise i.inspect unless i['checked'] && i['applies']
  raise i.inspect unless (i['h_mm'] - 66).abs < 1
  raise i.inspect unless (i['top_mm'] - 2200).abs < 0.001
  raise i.inspect unless (i['bottom_mm'] - 2134).abs < 1
  raise i.inspect unless i['material'] == 'carcass'
  raise i.inspect unless i['setback_mm'] == 55
  raise i.inspect unless Array(i['fill']).include?('filler')
end

check('a Classic column leaves a different remainder, and the seam says so') do
  d = Check.above_housing(Registry.lookup('CR9700'), 'DEC3050R/L')['h_mm']
  c = Check.above_housing(Registry.lookup('CR9900'), 'CL3650UID/S/T/R')['h_mm']
  raise "#{d} vs #{c}" unless (d - c).abs > 1
  # 73 is why the void threshold moved from 70 to 120 on 2026-08-25: an open
  # shelf 73 mm tall is not a shelf.
  raise c.to_s unless (c - 73).abs < 1
end

check('the numbers and the sentence are the same answer, asked twice') do
  r = Check.review(Registry.lookup('CR9700'), 'DEC3050R/L', 'run_top_mm' => 2200)
  i = Check.above_housing(Registry.lookup('CR9700'), 'DEC3050R/L')
  offer = r['offers'].find { |o| o.include?('left above the housing') } or raise r.inspect
  # Compared as a NUMBER, not as a string. The prose rounds an Integer 66 to
  # "66" and this rounds a Float 66.0 to "66.0" - the same millimetre wearing
  # two spellings, and a string match would have called that a disagreement.
  spoken = offer[/\A[\d.]+/].to_f
  raise offer unless (spoken - i['h_mm'].to_f).abs < 0.1
  raise offer unless offer.include?(i['setback_mm'].to_s)
end

check('and it is still only a question: no model, no machine, no answer') do
  # A section shorter than the opening is an ERROR, not a body to draw.
  i = Check.above_housing(Registry.lookup('CR9700'), 'DEC3050R/L',
                          'section_top_mm' => 1800)
  raise i.inspect unless i['error']
end

puts "\nthe report a person reads"

check('the report names the code, the model and every finding') do
  t = Check.report(Registry.lookup('CR9700'), 'DEC3050R/L', 'run_top_mm' => 2200)
  raise t unless t.include?('CR9700') && t.include?('DEC3050R/L') && t.include?('DISAGREES')
  # WAS >= 4 until 2026-08-26. Two of the four findings were fixed that morning,
  # so the report is shorter by exactly the two that were closed. The floor is
  # what a report must always have: a title, a finding and an offer.
  raise t unless t.lines.size >= 3
end

puts "\n#{$checks} checks, #{$failures} failure(s)"
exit($failures.zero? ? 0 : 1)

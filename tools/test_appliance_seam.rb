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
  # The row states only `bottom: plinth_top` and a top. The BOX is the
  # generator's, and these two numbers exist nowhere in the JSON.
  raise n.inspect unless (n['bottom_mm'] - 100).abs < 0.001
  raise n.inspect unless (n['height_mm'] - 2033.6).abs < 0.1
end

# ---------------------------------------------------------------------------

def appliance_lib
  candidates = [ENV['UCON_APPLIANCES'],
                File.expand_path('../../ucon-appliances', __dir__),
                File.expand_path('~/Downloads/ucon-appliances'),
                File.expand_path('~/dev/ucon-appliances')].compact
  candidates.map { |d| File.join(d, 'lib', 'ucon_appliances.rb') }.find { |f| File.file?(f) }
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

check('the housing the engine draws is 100 short, and the seam says so') do
  r = Check.review(Registry.lookup('CR9700'), 'DEC3050R/L')
  raise r.inspect if r['agrees']
  raise r['findings'].inspect unless r['findings'].any? { |f| f.include?('2033.6') && f.include?('2134') }
end

check('and it names the reason: the housing is drawn from the plinth top') do
  r = Check.review(Registry.lookup('CR9700'), 'DEC3050R/L')
  raise r['findings'].inspect unless r['findings'].any? { |f| f.include?('measured from the floor') }
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

puts "\nthe report a person reads"

check('the report names the code, the model and every finding') do
  t = Check.report(Registry.lookup('CR9700'), 'DEC3050R/L', 'run_top_mm' => 2200)
  raise t unless t.include?('CR9700') && t.include?('DEC3050R/L') && t.include?('DISAGREES')
  raise t unless t.lines.size >= 4
end

puts "\n#{$checks} checks, #{$failures} failure(s)"
exit($failures.zero? ? 0 : 1)

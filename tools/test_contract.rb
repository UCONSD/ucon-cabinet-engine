# frozen_string_literal: true
#
# Headless check of the Object Contract implementation.
#
#   cd ~/dev/ucon-cabinet-engine && ruby tools/test_contract.rb
#
# SketchUp is NOT required and must not be. If this file ever needs SketchUp to
# run, something SketchUp-flavoured has leaked into core/20_contract.rb and the
# leak is the bug — not this test.

require_relative '../src/ucon_cabinet_engine/core/10_standards'
require_relative '../src/ucon_cabinet_engine/core/20_contract'
# 22_placement is the placement RULE SET and has no SketchUp in it at all -
# that is the whole point of splitting it away from 75_place_tool.
require_relative '../src/ucon_cabinet_engine/core/22_placement'
# 40_unit_b80601 touches the SketchUp API only inside build, so the unit's
# metadata and derived dimensions are reachable from here. 30_geometry is the
# one core file that genuinely needs SketchUp and is deliberately not loaded.
require_relative '../src/ucon_cabinet_engine/core/40_unit_b80601'
require_relative '../src/ucon_cabinet_engine/core/50_registry'
# 85_export is the order schedule and is PURE - no SketchUp at all, which is
# what lets it be checked against a real factory estimate headlessly.
require_relative '../src/ucon_cabinet_engine/core/85_export'
require_relative '../src/ucon_cabinet_engine/core/60_generator'
# 70_symbols touches the SketchUp API only when drawing; the geometry rules
# themselves are pure and are checked here.
require_relative '../src/ucon_cabinet_engine/core/70_symbols' rescue nil
require_relative '../src/ucon_cabinet_engine/core/80_panel' rescue nil
# 90_palette touches the SketchUp API only inside show/show_picker; the HTML
# builders are pure string work and are checked here.
require_relative '../src/ucon_cabinet_engine/core/90_palette' rescue nil

Contract  = UCON::CabinetEngine::Contract
Standards = UCON::CabinetEngine::Standards
B80601    = UCON::CabinetEngine::Units::B80601

# The interpreter is part of the result. macOS still ships Ruby 2.6, the Linux
# side of the device bridge had 3.0, and SketchUp 2025 runs 3.2 - so the same
# suite can pass on one machine and fail on another for reasons that have
# nothing to do with the engine. Printing the version means a divergence names
# itself the first time two people paste different numbers.
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

def accepts(description, attrs)
  check(description) { Contract.validate!(attrs) }
end

def rejects(description, attrs, expected_fragment)
  check(description) do
    begin
      Contract.validate!(attrs)
    rescue ArgumentError => e
      unless e.message.include?(expected_fragment)
        raise "rejected for the wrong reason: #{e.message.inspect} " \
              "did not contain #{expected_fragment.inspect}"
      end
      next
    end
    raise 'expected ArgumentError, but the attributes were accepted'
  end
end

VALID = {
  'schema_version' => '2',
  'object_class'   => 'cabinet',
  'manufacturer'   => 'cesar',
  'geometry_kind'  => 'linear',
  'height_mm'      => 780,
  'depth_mm'       => 620,
  'width_mm'       => 600,
  'code'           => 'B80601',
  'code_status'    => 'PRELIMINARY',
  'status'         => 'PLANNING',
  'source_ref'     => 'CESAR - 2 Kitchen System.pdf p.36 / PDF 38'
}.freeze

def without(key)
  VALID.reject { |k, _| k == key }
end

def with(overrides)
  VALID.merge(overrides)
end

puts "\nObject Contract v1.1 — headless checks\n\n"

puts 'accepted shapes'
accepts('a complete linear cabinet', VALID)
accepts('symbol keys normalize to strings',
        VALID.each_with_object({}) { |(k, v), h| h[k.to_sym] = v })
accepts('a corner unit with corner_geometry instead of width_mm',
        with('geometry_kind' => 'corner', 'corner_geometry' => '1000x400').reject { |k, _| k == 'width_mm' })
accepts('a non_dim accessory needing no dimensions',
        { 'schema_version' => '2', 'object_class' => 'accessory', 'manufacturer' => 'cesar',
          'geometry_kind' => 'non_dim', 'code_status' => 'PRELIMINARY', 'status' => 'SOURCE',
          'source_ref' => 'CESAR - 2 Kitchen System.pdf p.201' })
accepts('a fully confirmed object may carry a confirmed code',
        with('status' => 'CONFIRMED', 'code_status' => 'CONFIRMED'))

puts "\nrejected shapes"
rejects('an unknown key', with('cabinet_width' => 600), 'outside Object Contract')
rejects('a price key', with('price_group_eur' => 120), 'Commercial data is forbidden')
rejects('a missing required key', without('manufacturer'), 'Missing required keys')
rejects('a missing source_ref', without('source_ref'), 'source_ref is required')
rejects('a bad status value', with('status' => 'DRAFT'), 'is not one of')
rejects('a bad object_class', with('object_class' => 'kitchen'), 'is not one of')
# v1 is now the WRONG version to write. Reading one is a different matter:
# Contract.read migrates it (v2 §7), and that is checked in the v2 section.
rejects('the wrong schema_version', with('schema_version' => '1'), 'schema_version must be')
rejects('linear geometry without width_mm', without('width_mm'), 'geometry_kind = linear requires')
rejects('corner geometry without corner_geometry',
        with('geometry_kind' => 'corner'), 'geometry_kind = corner requires')
rejects('a confirmed code on an unconfirmed object',
        with('code_status' => 'CONFIRMED'), 'requires status = CONFIRMED')
rejects('a blocked P3 object claiming PLANNING',
        with('priority' => 'P3'), 'blocked at CONTROL')

puts "\nhinge side (contract v1.2)"
accepts('a handed door unit may record hinge_side', with('hinge_side' => 'lh'))
rejects('an invalid hinge_side', with('hinge_side' => 'left'), 'is not one of')

puts "\nstatus ordering (§3 — must not be alphabetical)"
check('SOURCE < CONTROL < PLANNING < CONFIRMED') do
  ranks = %w[SOURCE CONTROL PLANNING CONFIRMED].map { |s| Contract.status_rank(s) }
  raise "got #{ranks.inspect}" unless ranks == ranks.sort && ranks == [0, 1, 2, 3]
end
check('an unknown status ranks below everything') do
  raise 'expected -1' unless Contract.status_rank('WHATEVER') == -1
end

puts "\nlocked standards (transcription check against the control document)"
{
  PANEL_T_MM: 18, BACK_T_MM: 4, BACK_INSET_MM: 20, FRONT_T_MM: 22,
  FRONT_GAP_MM: 3, FRONT_REVEAL_MM: 1.5, PLINTH_H_MM: 100,
  PLINTH_H_ALT_MM: 60, PLINTH_T_MM: 18, PLINTH_SETBACK_MM: 45
}.each do |const, expected|
  check("#{const} == #{expected}") do
    actual = Standards.const_get(const)
    raise "got #{actual}" unless actual == expected
  end
end

check('every standard records where its authority comes from') do
  documented = Standards::STATUS.keys.map(&:to_s).sort
  defined_consts = Standards.constants.map(&:to_s).select { |c| c.end_with?('_MM') }.sort
  raise "undocumented: #{(defined_consts - documented).inspect}" unless (defined_consts - documented).empty?
end

puts "\nB80601 — catalog dimensions (frozen baseline is the authority)"
{
  'width_mm'  => [B80601::WIDTH_MM,  600],
  'height_mm' => [B80601::HEIGHT_MM, 780],
  'depth_mm'  => [B80601::DEPTH_MM,  620]
}.each do |name, (actual, expected)|
  check("#{name} == #{expected}") do
    raise "got #{actual}" unless actual == expected
  end
end

puts "\nB80601 — derived dimensions"
# The front is drawn flush (600 x 780) — the 1.5 mm reveal is a recorded
# standard, not drawn geometry — so there are no derived front dimensions to
# check; the reveal value itself is covered by the locked-standards block.
{
  'overall height (carcass + plinth)' => [B80601.overall_height_mm, 880],
  'overall depth  (carcass + gap + front)' => [B80601.overall_depth_mm, 645]
}.each do |name, (actual, expected)|
  check("#{name} == #{expected}") do
    raise "got #{actual}" unless actual == expected
  end
end

puts "\nB80601 — contract attributes (integration: the unit satisfies the contract)"
check('B80601 attributes validate against Object Contract v1.1') do
  Contract.validate!(B80601.contract_attributes)
end
check('front_height_mm derives to the full family door for opening_method = handle') do
  a = B80601.contract_attributes
  raise "opening_method is #{a['opening_method']}" unless a['opening_method'] == 'handle'
  raise "got #{a['front_height_mm']}" unless a['front_height_mm'] == 780
end
check('the code stays PRELIMINARY while status is PLANNING') do
  a = B80601.contract_attributes
  raise "got #{a['code_status']}" unless a['code_status'] == 'PRELIMINARY'
  raise "got #{a['status']}" unless a['status'] == 'PLANNING'
end
check('no hardware is invented') do
  a = B80601.contract_attributes
  raise 'hardware_ref was guessed' if a.key?('hardware_ref')
  raise 'hardware_source was guessed' if a.key?('hardware_source')
end
check('notes record the envelope-only representation') do
  raise 'envelope not mentioned' unless B80601.notes.downcase.include?('envelope')
end

# A SketchUp entity's attribute dictionary, headless. Defined here rather than
# beside the contract checks that first needed it, because a round trip through
# a real write! is the only honest way to prove that a key was ERASED and not
# merely skipped - and by 0.52 three separate sections want to prove exactly
# that. A helper used in three places belongs above all three.
class StubEntity
  def initialize; @d = {}; end
  def set_attribute(dict, key, value); (@d[dict] ||= {})[key] = value; true; end
  def get_attribute(dict, key); (@d[dict] || {})[key]; end
  def delete_attribute(dict, key); (@d[dict] || {}).delete(key); true; end
  def stored; (@d[Contract::DICTIONARY] || {}); end
end

puts "\nregistry + generator (M1.4 integration)"
Registry  = UCON::CabinetEngine::Registry
Export    = UCON::CabinetEngine::Export
Generator = UCON::CabinetEngine::Generator

check('registry loads and holds 704 codes (262 base + 44 sink + 9 appliance + 291 wall + 8 USA tall + 84 tall + 6 fillers)') do
  n = Registry.codes.length
  raise "got #{n}" unless n == 704
end
check('B80601 resolves to the frozen-baseline dimensions') do
  u = Registry.lookup('B80601')
  raise u.inspect unless u['width_mm'] == 600 && u['depth_mm'] == 620 &&
                         u['height_mm'] == 780 && u['unit_type'] == 'base_door' &&
                         u['handed'] == true
end
check('an unknown code raises with the known-code list') do
  begin
    Registry.lookup('B99999')
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('not in the registry')
  end
end
check('EVERY BUILDABLE registry code yields contract-valid attributes') do
  Registry.codes.each do |code|
    u = Registry.lookup(code)
    # An article the catalog prices by height alone has no width until it is
    # ordered (printed p.434). The sweep ORDERS one rather than inventing a
    # column, because the honest claim is "valid once ordered".
    u = Registry.with_ordered_width(u, u['width_range_mm'][0]) if u['width_range_mm']
    # And one that is not buildable is not required to be dimensionable: the
    # front-only fillers have no depth on the page, which is exactly why they
    # carry buildable false and a reason. Checked on its own below.
    next unless u.fetch('buildable', true)

    Contract.validate!(Generator.attributes_for(u))
  end
end
check('and every code that is NOT buildable says why, in the registry') do
  unbuildable = Registry.catalog.reject { |c| c['buildable'] }
  raise 'nothing is unbuildable - this check has lost its subject' if unbuildable.empty?
  bad = unbuildable.reject { |c| c['not_buildable_reason'].to_s.length > 40 }
  raise bad.map { |c| c['code'] }.inspect unless bad.empty?
end
check('the generator never guesses hinge_side') do
  attrs = Generator.attributes_for(Registry.lookup('B80601'))
  raise 'hinge_side was set' if attrs.key?('hinge_side')
end
check('front slabs: single door -> one full slab') do
  slabs = Generator.front_slabs(Registry.lookup('B80601'))
  raise slabs.inspect unless slabs.length == 1 &&
                             slabs[0][:w_mm] == 600 && slabs[0][:h_mm] == 780
end
check('front slabs: two-door unit -> two equal slabs') do
  slabs = Generator.front_slabs(Registry.lookup('B70900'))
  raise slabs.inspect unless slabs.length == 2 &&
                             slabs.all? { |sl| sl[:w_mm] == 450.0 && sl[:h_mm] == 780 } &&
                             slabs[1][:x_mm] == 450.0
end
check('front slabs: drawer unit -> 195/195/390 top to bottom, jumbo at the bottom') do
  slabs = Generator.front_slabs(Registry.lookup('B81253'))
  hs = slabs.map { |sl| sl[:h_mm] }
  zs = slabs.map { |sl| sl[:z_mm] }
  raise slabs.inspect unless hs == [390.0, 195.0, 195.0] && zs == [0.0, 390.0, 585.0]
end
check('front slab heights that do not sum to the door height raise') do
  bad = Registry.lookup('B81253').merge(
    'front_layout' => { 'kind' => 'horizontal', 'heights_mm_top_to_bottom' => [200, 200, 200] }
  )
  begin
    Generator.front_slabs(bad)
    raise 'accepted'
  rescue RuntimeError => e
    raise e.message unless e.message.include?('do not sum')
  end
end
check('interior confirmed by source is recorded in notes, not drawn') do
  attrs = Generator.attributes_for(Registry.lookup('B80601'))
  raise attrs['notes'] unless attrs['notes'].include?('1 shelf')
end

puts "\npanel logic (door version / opening / hardware rules)"
Panel = UCON::CabinetEngine::Panel
U = Registry.lookup('B80601')

check('door 75 -> gola, front 750, and the profile is an ORDER LINE') do
  # 0.49.0: the profile stopped being a hardware_ref string. One string cannot
  # hold the two profiles a drawer stack needs, and joining them into
  # "GOL001+GOL002" put an article that does not exist into a real export.
  p = Panel.attributes_patch(U, { 'door_version' => '75', 'gola_system' => 'L-shaped' })
  raise p.inspect unless p['opening_method'] == 'gola' && p['front_height_mm'] == 750
  raise 'the profile is no longer opening hardware' if p['hardware_ref']
  line = p['companion_refs'].find { |l| l['code'] == 'GOL001' }
  raise p['companion_refs'].inspect unless line
  raise line.inspect unless line['um'] == 'ML' && line['origin'] == 'implied'
  # Bought by the metre along a run that crosses joints - no cabinet knows it.
  raise 'an ML quantity must stay open' unless line['qty'].nil?
end
check('door 75 without a GOL profile is refused') do
  begin
    Panel.attributes_patch(U, { 'door_version' => '75', 'gola_system' => '' })
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('SYSTEM')
  end
end
check('door 78 + factory handle -> M-code recorded') do
  p = Panel.attributes_patch(U, { 'door_version' => '78', 'opening_method' => 'handle',
                                  'hardware_mode' => 'factory', 'hardware_ref' => 'M00001' })
  raise p.inspect unless p['front_height_mm'] == 780 && p['hardware_ref'] == 'M00001'
end
check('door 78 + client handle -> empty ref, source=client') do
  p = Panel.attributes_patch(U, { 'door_version' => '78', 'opening_method' => 'handle',
                                  'hardware_mode' => 'client' })
  raise p.inspect unless p['hardware_ref'] == '' && p['hardware_source'] == 'client'
end
check('push_to_open -> empty ref (device code pending Elda)') do
  p = Panel.attributes_patch(U, { 'door_version' => '78', 'opening_method' => 'push_to_open' })
  raise p.inspect unless p['hardware_ref'] == '' && p['hardware_source'] == 'factory'
end
check('hinge_side accepted on handed unit, refused on two-door') do
  p = Panel.attributes_patch(U, { 'door_version' => '78', 'opening_method' => 'push_to_open',
                                  'hinge_side' => 'lh' })
  raise p.inspect unless p['hinge_side'] == 'lh'
  begin
    Panel.attributes_patch(Registry.lookup('B80900'),
                           { 'door_version' => '78', 'opening_method' => 'push_to_open',
                             'hinge_side' => 'lh' })
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('handed')
  end
end
check('every patched attribute set stays contract-valid') do
  base = Generator.attributes_for(U)
  [
    { 'door_version' => '75', 'gola_system' => 'L-shaped' },
    { 'door_version' => '78', 'opening_method' => 'handle', 'hardware_mode' => 'client', 'hinge_side' => 'rh' },
    { 'door_version' => '78', 'opening_method' => 'push_to_open' }
  ].each do |payload|
    Contract.validate!(base.merge(Panel.attributes_patch(U, payload)))
  end
end
check('gola shortens door slabs by 30') do
  slabs = Panel.effective_slabs(U, true)
  raise slabs.inspect unless slabs[0][:h_mm] == 750
end
check('registry hardware: 4 gola profiles, 8 handles, Tratto excluded') do
  hw = Registry.data['hardware']
  raise 'gola' unless hw['gola_profiles'].length == 4
  raise 'handles' unless hw['handles'].length == 8
  raise 'tratto' unless hw['handles_excluded'].any? { |x| x['code'] == 'M00010' }
end

puts "\nLEGRABOX NL selection (user-provided Blum table, overlay column)"
check('d.350 -> NL 300, d.620 -> NL 550, d.670 -> NL 600') do
  got = [350, 620, 670].map { |d| Generator.runner_nl_for(d)['nl_mm'] }
  raise got.inspect unless got == [300, 550, 600]
end
check('travel comes from the table: 298 / 548 / 598 (NL - 2)') do
  got = [350, 620, 670].map { |d| Generator.runner_travel_for(d) }
  raise got.inspect unless got == [298, 548, 598]
end
check('a depth too shallow for any runner -> nil, nothing drawn') do
  raise 'expected nil' unless Generator.runner_nl_for(200).nil? && Generator.runner_travel_for(200).nil?
end
check('internal depth math uses UCON standards (620 - 20 - 4 = 596 < 603)') do
  row = Generator.runner_nl_for(620)
  raise 'NL600 must NOT fit d.62' if row['nl_mm'] == 600
end

puts "\ngola profile filtering (base unit front = undercounter only)"
check('the panel offers SYSTEMS, and names the profiles each one orders') do
  opts = Panel.gola_options
  raise opts.inspect unless opts.map { |r| r['value'] }.sort == ['L-shaped', 'straight']
  # No option value may look like an article code, because it is not one.
  raise 'an option value must not be a code' if opts.any? { |r| r['value'] =~ /^GOL/ }
  raise 'the person choosing must still see what gets ordered' unless
    opts.all? { |r| r['name'] =~ /GOL\d+/ }
end
check('registry rows carry position and system') do
  rows = Registry.data['hardware']['gola_profiles']
  raise 'missing keys' unless rows.all? { |r| r['position'] && r['system'] }
end

check('gola profile body recorded in registry: 30 / 57 / 27') do
  b = Registry.data['hardware']['gola_profile_body']
  raise b.inspect unless b['upper_dim_mm'] == 30 && b['zone_height_mm'] == 57 &&
                         b['profile_depth_mm'] == 27
end

check('registry catalog: 704 rows, each with code/dims/description/source') do
  cat = Registry.catalog
  raise cat.length.to_s unless cat.length == 704
  # THREE ways to be dimensioned, not one. A corner row carries corner_geometry
  # instead of a width; a filler carries the RANGE the catalog prints instead
  # of the width it never prints. A depth is required of anything we offer to
  # build - the front-only fillers have none and do not claim to be buildable.
  raise 'incomplete row' unless cat.all? { |c|
    c['code'] && c['height_mm'] &&
    (c['depth_mm'] || !c['buildable']) &&
    (c['width_mm'] || c['corner_geometry'] || c['width_range_mm']) &&
    c['description'] && c['source_ref'] && c['type_key']
  }
end

puts "\ngola drawer stack (verified from p.39 elevation)"
check('gola slabs: 360 at 0, 180 at 390, 180 at 570 (zones 30 above jumbo-joint and under worktop)') do
  slabs = Panel.effective_slabs(Registry.lookup('B81253'), true)
  got = slabs.map { |sl| [sl[:h_mm], sl[:z_mm]] }
  raise got.inspect unless got == [[360.0, 0.0], [180.0, 390.0], [180.0, 570.0]]
end
check('a drawer stack names TWO profiles per system, a door names one') do
  drawer = Panel.gola_options(Registry.lookup('B81253'))
  raise drawer.inspect unless drawer.map { |o| o['name'] }.sort ==
    ['L-shaped system (GOL001 + GOL002)', 'straight system (GOL005 + GOL006)']
  door = Panel.gola_options(Registry.lookup('B80601'))
  raise door.inspect unless door.map { |o| o['name'] }.sort ==
    ['L-shaped system (GOL001)', 'straight system (GOL005)']
end

check('and the ORDER gets the same two, as real codes') do
  # This is what the joined pseudo-code used to hide.
  p = Panel.attributes_patch(Registry.lookup('B81253'),
                             { 'door_version' => '75', 'gola_system' => 'L-shaped' })
  codes = p['companion_refs'].map { |l| l['code'] }
  raise codes.inspect unless codes == %w[GOL001 GOL002]
  raise 'no composite may survive anywhere' if codes.any? { |c| c.include?('+') }
end
check('a broken stack that does not sum to 780 raises') do
  u = Registry.lookup('B81253')
  bad = u.merge('front_layout' => u['front_layout'].merge(
    'gola_stack_top_to_bottom' => [{ 'kind' => 'front', 'h_mm' => 700 }]))
  begin
    Panel.effective_slabs(bad, true)
    raise 'accepted'
  rescue RuntimeError => e
    raise e.message unless e.message.include?('does not sum')
  end
end

puts "\np.40 unit types (B..57 jumbo drawers, B..50 drawer+jumbo)"
check('B71257: 1200x780x350, 2 jumbo drawers, slabs 390/390') do
  u = Registry.lookup('B71257')
  raise u.inspect unless u['width_mm'] == 1200 && u['depth_mm'] == 350 &&
                         u['unit_type'] == 'base_jumbo_drawers'
  hs = Generator.front_slabs(u).map { |x| x[:h_mm] }
  raise hs.inspect unless hs == [390.0, 390.0]
end
check('B71257 gola stack: 360 at 0? no - 360 at 0 and 360 at 390') do
  slabs = Panel.effective_slabs(Registry.lookup('B71257'), true)
  got = slabs.map { |sl| [sl[:h_mm], sl[:z_mm]] }
  raise got.inspect unless got == [[360.0, 0.0], [360.0, 390.0]]
end
check('B80650 drawer+jumbo: slabs 585 bottom / 195 top; gola 555/165') do
  u = Registry.lookup('B80650')
  hs = Generator.front_slabs(u).map { |x| [x[:h_mm], x[:z_mm]] }
  raise hs.inspect unless hs == [[585.0, 0.0], [195.0, 585.0]]
  gs = Panel.effective_slabs(u, true).map { |x| [x[:h_mm], x[:z_mm]] }
  raise gs.inspect unless gs == [[555.0, 0.0], [165.0, 585.0]]
end
check('every new code yields contract-valid attributes') do
  (Registry.codes.select { |c| c.end_with?('57', '50') } - ['B80553']).each do |code|
    u = Registry.lookup(code)
    # B70150 is the first code this filter has caught that has no width of its
    # own. Order one, for the reason given in the whole-registry sweep.
    u = Registry.with_ordered_width(u, u['width_range_mm'][0]) if u['width_range_mm']
    Contract.validate!(Generator.attributes_for(u))
  end
end

check('split storage: every catalog row is stamped with its section and class') do
  cat = Registry.catalog
  bad = cat.reject { |c| c['section'].to_s != '' && c['class'].to_s != '' }
  raise "missing stamps: #{bad.map { |c| c['code'] }.inspect}" unless bad.empty?

  sections = cat.map { |c| c['section'] }.uniq.sort
  raise sections.inspect unless sections == ['Base units H. 39',
                                             'Base units H. 48',
                                             'Base units H. 58.5',
                                             'Base units H. 78',
                                             'Base units H. 78 | for household appliances',
                                             'Closing strips and fillers for Maxima and Intarsio',
                                             'Dish-drainer units H. 36',
                                             'Dish-drainer units H. 48',
                                             'Dish-drainer units H. 60',
                                             'Dish-drainer units H. 72',
                                             'Dish-drainer units H. 84',
                                             'Dish-drainer units H. 96',
                                             'Sink base units H. 58.5',
                                             'Sink base units H. 78',
                                             'Tall units H. 138',
                                             'Tall units H. 198',
                                             'Tall units H. 210',
                                             'Tall units H. 210 | for base unit H. 78',
                                             'Tall units H. 222',
                                             'Tall units H. 234',
                                             'USA elements | for tall units H. 210',
                                             'Wall units H. 120',
                                             'Wall units H. 36',
                                             'Wall units H. 48',
                                             'Wall units H. 60',
                                             'Wall units H. 72',
                                             'Wall units H. 84',
                                             'Wall units H. 96']
  # tall arrived 2026-08-21 with printed p.418 - the first non base/wall class.
  # 'filler' arrived 2026-08-23 with printed p.434 and is the first class that
  # is OURS rather than the catalog's - one chapter whose rows are base, wall
  # and tall at once. catalog_map carries the reasoning.
  raise cat.map { |c| c['class'] }.uniq.sort.inspect unless
    cat.map { |c| c['class'] }.uniq.sort == %w[base filler tall wall]
end

puts "\nsink base units H. 78 (printed p.44 / PDF 46)"
check('the section adds 20 codes across four unit types') do
  rows = Registry.catalog.select { |c| c['section'] == 'Sink base units H. 78' }
  raise rows.length.to_s unless rows.length == 20

  types = rows.group_by { |r| r['type_key'] }.transform_values(&:length)
  expected = { 'sink_base_door' => 4, 'sink_base_doors' => 6,
               'sink_base_jumbo_drawer' => 2, 'sink_base_jumbo_drawers' => 8 }
  raise types.inspect unless types == expected
end
check('EVERY sink code yields contract-valid attributes') do
  Registry.catalog.select { |c| c['section'] == 'Sink base units H. 78' }.each do |row|
    Contract.validate!(Generator.attributes_for(Registry.lookup(row['code'])))
  end
end
check('sink codes obey the H.78 grammar: depth digit and width lookup') do
  depth = { '8' => 620, '9' => 670 }
  width = { '05' => 450, '06' => 600, '07' => 750, '09' => 900, '10' => 1050, '12' => 1200 }
  Registry.catalog.select { |c| c['section'] == 'Sink base units H. 78' }.each do |row|
    code = row['code']
    raise code unless depth[code[1]] == row['depth_mm']
    raise code unless width[code[2, 2]] == row['width_mm']
  end
end
check('B81087 sink w/jumbo drawers: 1050x780x620, slabs 390/390, gola 360/360') do
  u = Registry.lookup('B81087')
  raise u.inspect unless [u['width_mm'], u['height_mm'], u['depth_mm']] == [1050, 780, 620]
  raise u['unit_type'] unless u['unit_type'] == 'sink_base_jumbo_drawers'
  hs = Generator.front_slabs(u).map { |x| [x[:h_mm], x[:z_mm]] }
  raise hs.inspect unless hs == [[390.0, 0.0], [390.0, 390.0]]
  gs = Panel.effective_slabs(u, true).map { |x| [x[:h_mm], x[:z_mm]] }
  raise gs.inspect unless gs == [[360.0, 0.0], [360.0, 390.0]]
end
check('B80681 sink w/jumbo drawer: one full-height front, gola 750') do
  u = Registry.lookup('B80681')
  hs = Generator.front_slabs(u).map { |x| [x[:h_mm], x[:z_mm]] }
  raise hs.inspect unless hs == [[780.0, 0.0]]
  gs = Panel.effective_slabs(u, true).map { |x| [x[:h_mm], x[:z_mm]] }
  raise gs.inspect unless gs == [[750.0, 0.0]]
end
check('B80603 sink w/door is handed; B80602 two-door is not') do
  raise 'B80603' unless Registry.lookup('B80603')['handed'] == true
  raise 'B80602' unless Registry.lookup('B80602')['handed'] == false
end
check('the aluminium tray is recorded as interior, never drawn') do
  u = Registry.lookup('B81087')
  raise u['interior_confirmed'].inspect unless u['interior_confirmed'].include?('1 aluminium tray')
  attrs = Generator.attributes_for(u)
  raise attrs['notes'].to_s unless attrs['notes'].to_s.include?('aluminium tray')
end

puts "\nprinted p.36 completed (pull-out door + laundry basket)"
check('the two remaining p.36 types are in: 4 pull-out door codes, 2 laundry') do
  # SCOPED TO THE SECTION, and it was not until 2026-08-24. A type KEY is
  # unique inside a family and nowhere else: H.58.5 opened with a
  # base_pull_out_door of its own on printed p.32 and this check, which counts
  # keys across the whole catalog, failed with 7 for a page that still prices
  # exactly 4. The title says p.36; the count must say p.36 too. Rule 18.
  by_type = Registry.catalog
                    .select { |c| c['section'] == 'Base units H. 78' }
                    .group_by { |c| c['type_key'] }.transform_values(&:length)
  raise by_type.inspect unless by_type['base_pull_out_door'] == 4 && by_type['base_laundry_basket'] == 2
end
check('EVERY p.36 code yields contract-valid attributes') do
  %w[B70100 B80100 B80300 B80400 B80614 B90614].each do |code|
    Contract.validate!(Generator.attributes_for(Registry.lookup(code)))
  end
end
check('B80300 and B80400 are the same size and differ only by content') do
  a = Registry.lookup('B80300')
  b = Registry.lookup('B80400')
  raise [a, b].inspect unless [a['width_mm'], a['depth_mm']] == [b['width_mm'], b['depth_mm']]
  raise 'both must be 300 wide at d.62' unless [a['width_mm'], a['depth_mm']] == [300, 620]
  # The width field lies here: B80400 reads as "04" yet measures 300. This is
  # the manifest's warning made concrete - explicit rows are the authority.
  raise 'the bread-bag variant must be recorded' unless
    Registry.data['families']['H.78']['unit_types']['base_pull_out_door']['notes'].include?('bread bag')
end
check('the laundry unit records a bottom hinge axis and is not handed') do
  u = Registry.lookup('B80614')
  raise u.inspect unless u['handed'] == false
  raise u['front_layout'].inspect unless u['front_layout']['hinge_axis'] == 'bottom'
end
check('neither new type would draw a swing symbol: no hinge_side is ever offered') do
  # 70_symbols draws a single leaf only when a hinge_side is given, and the
  # panel never offers one for an unhanded unit - so an unimplemented rule
  # draws nothing rather than something wrong.
  %w[B80400 B80614].each do |code|
    u = Registry.lookup(code)
    raise code unless u['handed'] == false
    raise code unless u['front_layout']['kind'] == 'single'
  end
end
check('the pull-out door is marked as a mechanism, not a swinging leaf') do
  u = Registry.lookup('B80300')
  raise u['front_layout'].inspect unless u['front_layout']['mechanism'] == 'pull_out_door'
end

puts "\ncorner base units (printed p.42) - data now, geometry at M2.2"
check('nine sizes x two executions = eighteen corner articles') do
  rows = Registry.catalog.select { |c| c['type_key'] == 'base_corner' }
  raise rows.length.to_s unless rows.length == 18
  by_exec = rows.group_by { |r| r['execution'] }.transform_values(&:length)
  raise by_exec.inspect unless by_exec == { 'left' => 9, 'right' => 9 }
  # The template must never survive into the data: an order line carries a
  # letter, not "D/S".
  raise 'a D/S template reached the catalog' if rows.any? { |r| r['code'].include?('/') }
  rows.group_by { |r| r['corner_geometry'] }.each_value do |pair|
    letters = pair.map { |r| r['code'][-1] }.sort
    raise letters.inspect unless letters == %w[D S]
  end
  raise 'a corner row must not carry a single width' if rows.any? { |r| r['width_mm'] }
  raise 'every corner row needs its corner geometry' unless rows.all? { |r| r['corner_geometry'] }
end
check('EVERY corner code yields contract-valid attributes') do
  Registry.catalog.select { |c| c['type_key'] == 'base_corner' }.each do |row|
    a = Generator.attributes_for(Registry.lookup(row['code']))
    raise a.inspect unless a['geometry_kind'] == 'corner'
    raise 'width must be absent on a corner' if a.key?('width_mm')
    Contract.validate!(a)
  end
end
check('the second W number is always depth + 80 (the 8x8 corner panel)') do
  Registry.catalog.select { |c| c['type_key'] == 'base_corner' }.each do |row|
    u = Registry.lookup(row['code'])
    second = u['corner_geometry'].split('x').last.to_i
    raise "#{row['code']}: #{second} vs #{u['depth_mm']}" unless second == u['depth_mm'] + 80
  end
end
check('the hand is the article and the hinge is not — both rules recorded') do
  notes = Registry.data['families']['H.78']['unit_types']['base_corner']['notes']
  raise 'the execution rule must be recorded' unless notes.include?('THE HAND IS PART OF THE CODE')
  raise 'the hinge distinction must be recorded' unless notes.include?("DOOR's hand")
end
check('S puts the door at the left end, D mirrors it') do
  l = Generator.corner_parts(Registry.lookup('AU110S'))
  r = Generator.corner_parts(Registry.lookup('AU110D'))
  raise l.inspect unless l[:door_x].zero?                    # door at the left end
  raise r.inspect unless r[:door_x] == 900 - 450             # door at the right end
  # The wasted space always sits on the corner side, so it mirrors too.
  raise l[:wasted_x].to_s unless l[:wasted_x] == 900
  raise r[:wasted_x].to_s unless r[:wasted_x] == -250
end
check('the 8x8 filler is an L of 77 x 80 - and the missing 3 mm has a name') do
  # THE PRINTED 8x8 IS THE NOMINAL. The leg that runs along the WIDTH is the
  # one the neighbouring run meets, and that run's front stands FRONT_GAP_MM
  # proud of its own carcass - so a leg of a full 80 overshoots the front it is
  # supposed to meet by exactly one gap. Measured in Avenida Primavera on
  # 2026-08-24. The RETURN leg meets nothing and keeps its 80.
  #
  # Both numbers are computed from the constants: a literal 77 would go stale
  # in silence on the day the front gap changes.
  along = Generator::FILLER_MM - Standards::FRONT_GAP_MM
  %w[AU110S AU110D].each do |code|
    pl = Generator.corner_parts(Registry.lookup(code))[:filler_plan]
    xs = pl.map(&:first)
    ys = pl.map(&:last)
    raise "#{code}: #{pl.inspect}" unless (xs.max - xs.min) == along
    raise "#{code}: the return leg must keep 80" unless
      (ys.max - ys.min) == Generator::FILLER_MM
    raise "#{code}: #{ys.min}" unless ys.min == -83
    raise "#{code}: #{ys.max}" unless ys.max == -3
  end
end
check('wasted space is nominal minus carcass, for every corner article') do
  Registry.catalog.select { |c| c['type_key'] == 'base_corner' }.each do |row|
    u = Registry.lookup(row['code'])
    p = Generator.corner_parts(u)
    nominal = u['corner_geometry'].split('x').first.to_i
    raise row['code'] unless p[:wasted] == nominal - u['carcass_length_mm']
  end
end
check('door 75 shortens the door AND the 8x8 together') do
  p78 = Generator.corner_parts(Registry.lookup('AU110S'))
  p75 = Generator.corner_parts(Registry.lookup('AU110S'), 750)
  raise p78[:front_h].to_s unless p78[:front_h] == 780
  raise p75[:front_h].to_s unless p75[:front_h] == 750
end
check('the corner symbol follows hinge_side, not the execution letter') do
  u = Registry.lookup('AU110S')
  p = Generator.corner_parts(u)
  lh = UCON::CabinetEngine::Symbols.corner_door_marks(p[:door_x], p[:door], 100, p[:front_h], -26, 'lh')
  rh = UCON::CabinetEngine::Symbols.corner_door_marks(p[:door_x], p[:door], 100, p[:front_h], -26, 'rh')
  # Same cabinet, same door, opposite hinge: the V flips.
  raise lh.inspect unless lh[:front][0][0][0].zero?          # hinged on the left edge
  raise rh.inspect unless rh[:front][0][0][0] == 450.0       # hinged on the right edge
end
check('printed p.10 confirms the corner model, and RH there means D') do
  notes = Registry.data['families']['H.78']['unit_types']['base_corner']['notes']
  raise 'the p.10 confirmation must be recorded' unless notes.include?('printed p.10')
  raise 'the RH = D mapping must be recorded' unless notes.include?('RH (as drawn on p.10 and p.11) = D')
  # The two pages disagree on which hand they draw, so on THIS page the hand
  # cannot be read off a picture. The GENERAL form of that rule died on
  # 2026-08-20 against the factory estimate (see the estimate section at the
  # end); what must travel with the data is the page-scoped caution, not a law.
  raise 'the drawing caution must be recorded' unless
    notes.include?('p.10/p.11 draw the node RH while p.42 draws the same article LH')
  raise 'the caution must be scoped to this page' unless notes.include?('on THIS page')
end
check('the d.57 corner depth is recorded as a gap, not invented') do
  sec = Registry.map_sections.find { |s| s['family'] == 'H.78' && s['section'] == 'Base units H. 78' }
  page = sec['pages'].find { |p| p['printed'].to_s.include?('42') }
  ct = page['types'].find { |t| t['title'] == 'Corner base unit' }
  raise ct.inspect unless ct && ct['note'].include?('d.57')
  raise 'the gap must say where it came from' unless ct['note'].include?('printed p.10')
  # d.57 has no digit in the H.78 depth grammar, which is why it cannot be a
  # phantom section row: 7 = d.35, 8 = d.62, 9 = d.67.
  depths = Registry.data['families']['H.78']['code_grammar']['depth_digit'] rescue nil
  raise 'd.57 must not have leaked into the H.78 grammar' if depths && depths.values.include?(570)
  raise 'no corner article may claim d.57' if
    Registry.catalog.select { |c| c['type_key'] == 'base_corner' }
            .any? { |c| Registry.lookup(c['code'])['depth_mm'] == 570 }
end
check('REGRESSION: a corner front slab has a real width at BOTH door versions') do
  # The bug: front_slabs read unit['width_mm'], which a corner does not have,
  # so changing the door version in the properties panel produced
  #   "Non-positive dimension for FRONT: w= d=22 h=780".
  %w[AU110S AU110D].each do |code|
    u = Registry.lookup(code)
    [780, 750].each do |h|
      slabs = Generator.front_slabs(u.merge('height_mm' => h))
      raise "#{code}@#{h}: #{slabs.inspect}" unless slabs.length == 1
      s = slabs.first
      raise "#{code}@#{h}: #{s.inspect}" unless s[:name] == 'FRONT'
      raise "#{code}@#{h}: w=#{s[:w_mm].inspect}" unless s[:w_mm].to_f > 0
      raise "#{code}@#{h}: h=#{s[:h_mm].inspect}" unless s[:h_mm] == h
      raise "#{code}@#{h}: x=#{s[:x_mm].inspect}" unless s[:x_mm] == Generator.corner_parts(u)[:door_x]
    end
  end
end
if defined?(UCON::CabinetEngine::Panel)
  check('REGRESSION: the panel shortens a corner door for gola, and the 8x8 follows') do
    panel = UCON::CabinetEngine::Panel
    u = Registry.lookup('AU110S')
    full = panel.effective_slabs(u, false)
    gola = panel.effective_slabs(u, true)
    raise full.inspect unless full.length == 1 && full.first[:h_mm] == 780
    raise gola.inspect unless gola.length == 1 && gola.first[:h_mm] == 750
    raise gola.inspect unless gola.first[:w_mm] == full.first[:w_mm]
    # rebuild_fronts drives the filler off the rebuilt door height: the 8x8
    # must end up exactly as tall as the door it stands next to.
    raise 'filler height must follow the door' unless
      Generator.corner_parts(u, gola.first[:h_mm])[:front_h] == 750
  end
end
check('every corner article is still buildable and contract-valid') do
  # This used to assert that NOTHING in the registry was unbuildable, which was
  # true only because nothing had yet been held that we cannot draw honestly.
  # printed p.434 ended that: a front-only filler has no depth on the page. The
  # invariant that matters here was always about corners.
  #
  # AND THE REPLACEMENT WAS STILL A ROLL-CALL - %w[B70151 CQ0151] lasted until
  # printed p.37 and p.38 added thirteen more (rule 18, seventh instance). What
  # is actually claimed: HOLDING SOMETHING WE CANNOT DRAW IS ALLOWED, SAYING
  # NOTHING ABOUT WHY IS NOT. Every unbuildable row names its reason, and the
  # reason is written where the row is, not in a list somebody has to retype.
  not_buildable = Registry.catalog.reject { |c| c['buildable'] }
  raise 'the unbuildable articles have vanished' if not_buildable.empty?
  silent = not_buildable.reject { |c|
    Registry.lookup(c['code'])['not_buildable_reason'].to_s.length > 40
  }
  raise "unbuildable without a reason: #{silent.map { |c| c['code'] }.inspect}" unless
    silent.empty?
  # AND A LAYOUT WE CANNOT EXPRESS MUST NEVER BE OFFERED. front_layout v2.1 has
  # no nested kind, so a drawer band above two doors is recorded with its
  # heights and marked incomplete - Export.fronts_in would say two where the
  # page prints three. The two flags may not drift apart.
  # Read from the FILES, not through Registry.lookup: the loader has no reason
  # to carry a bookkeeping flag into the engine, and a flag the engine cannot
  # see is a flag the engine cannot act on by accident.
  # NOTE the Dir glob rather than registry_files: that helper is defined further
  # down this file and Ruby has not reached it yet when this check runs.
  files = Dir[File.expand_path('../registry/cesar/*.json', __dir__)]
          .reject { |f| File.basename(f).start_with?('_') }
  incomplete = files.flat_map { |file|
    JSON.parse(File.read(file))['data']['unit_types']
        .select { |_, ty| ty['front_layout_incomplete'] }
        .map { |k, ty| [k, ty] }
  }
  raise 'the nested-front gap has vanished' if incomplete.empty?
  drawable = incomplete.reject { |_, ty| ty['buildable'] == false }
  raise "incomplete layout offered for building: #{drawable.map(&:first).inspect}" unless
    drawable.empty?
  Registry.catalog.select { |c| c['type_key'] == 'base_corner' }.each do |row|
    a = Generator.attributes_for(Registry.lookup(row['code']))
    raise a.inspect unless a['geometry_kind'] == 'corner'
    Contract.validate!(a)
  end
end

puts "\nbase units H. 78, printed p.37-38 - the pages that were never read"
check('NOT EVERY UNIT CAN BE HUNG, and sometimes the page says so only in art') do
  # Generator.wall_hung_available? DERIVES the answer: every base or tall
  # cabinet can be hung unless a row says otherwise. printed p.37 prints two
  # positions whose last line is 'not available wall hung', and whose left
  # margin drops the 'Surch. for wall-hung version on page 548' that every
  # other base position carries. They are the first articles to use the escape
  # hatch, and until 2026-08-23 nothing did - so the derivation had never been
  # tested against a page that disagreed with it.
  # An appliance front is refused for a different and older reason - it is not
  # a cabinet at all - so only real cabinets are asked here.
  refused = Registry.catalog.reject { |c|
    u = Registry.lookup(c['code'])
    (u['object_class'] || 'cabinet') != 'cabinet' ||
      Generator.wall_hung_available?(u)
  }
  raise 'the printed refusal has vanished' if refused.empty?
  # EVERY REFUSAL NAMES ITS EVIDENCE, and the evidence is not always a sentence.
  # printed p.37 refuses two base units in words. printed p.90 and printed p.111
  # refuse three tall positions with NO prose at all - the statement is the
  # missing 'Hung version' glyph and the missing margin surcharge, and a fact
  # that exists only as absent print-art has to be written down or it is lost
  # the next time somebody reads the page. So the row carries a wall_hung_note
  # even where the description is silent.
  files = Dir[File.expand_path('../registry/cesar/*.json', __dir__)]
          .reject { |f| File.basename(f).start_with?('_') }
  noted = files.flat_map { |f|
    JSON.parse(File.read(f))['data']['unit_types']
        .select { |_, ty| ty['wall_hung'] == false }
        .map { |k, ty| [k, ty] }
  }
  raise 'nothing refuses the hung version any more' if noted.empty?
  noted.each do |key, ty|
    raise "#{key} refuses without saying why" unless
      ty['wall_hung_note'].to_s.length > 60
    raise "#{key} must cite the page it read" unless
      ty['wall_hung_note'].to_s.include?('printed p.')
  end
  raise 'the refusal must span more than one class' unless
    refused.map { |c| c['class'] }.uniq.length > 1

  # AND THE ANSWER IS PER POSITION, NOT PER TYPE. The same type_key is hung in
  # one family and refused in another - tall_two_doors is offered at H.138 and
  # not at H.210, on facing pages of one chapter. Nothing may derive this from
  # the type, and while these two disagree nothing can.
  by_key = Hash.new { |h, k| h[k] = [] }
  Registry.catalog.each do |c|
    u = Registry.lookup(c['code'])
    next unless (u['object_class'] || 'cabinet') == 'cabinet'

    by_key[c['type_key']] << Generator.wall_hung_available?(u)
  end
  split = by_key.select { |_, answers| answers.uniq.length > 1 }
  raise 'no type_key disagrees with itself: re-read before deriving the glyph' if
    split.empty?
  # And the ordinary case still works, or the flag would be meaningless.
  raise 'a plain base unit must still be hangable' unless
    Generator.wall_hung_available?(Registry.lookup('B80601'))
  # A refused unit must not be handed a surcharge line either.
  raise 'a refused unit was offered the fixing kit' unless
    Generator.wall_hung_ref(Registry.lookup(refused.first['code'])).nil?
end

check('THE DOOR-VERSION GAP HAS ONE NAME, and everything waiting on it says so') do
  # Two pages found the same missing axis on the same day. printed p.38 prints
  # base units whose only elevation is 19,5/55,5 - 750, the gola door height -
  # and printed p.48 prints dishwasher panels at 36/36 and 16,5/55,5. A handle
  # execution must sum to 780. So these articles exist at 75 or 72 and not at
  # 78, and door_versions is a FAMILY key: full_mm and gola_mm are stated once
  # for H.78 and every article in the family inherits both.
  #
  # The point of this check is not the count. It is that a backlog waiting on
  # ONE decision must not accumulate five different explanations of itself -
  # when the axis is finally narrowed to an article, whoever does it needs to
  # find every row in one grep. Rule 18's lesson pointed the other way for
  # inventories; this one is about a reason, and a reason that drifts is a
  # reason nobody can act on.
  waiting = Registry.catalog.reject { |c| c['buildable'] }.select { |c|
    Registry.lookup(c['code'])['not_buildable_reason'].to_s.include?('door_versions is a FAMILY key')
  }
  raise 'the door-version backlog has vanished' if waiting.empty?
  raise 'it must span more than one section, or it is not an axis problem' unless
    waiting.map { |c| c['section'] }.uniq.length > 1
  waiting.each do |row|
    reason = Registry.lookup(row['code'])['not_buildable_reason']
    raise "#{row['code']} does not say what it printed" unless reason.match?(/\d+ \+ \d+ = \d+/)
    raise "#{row['code']} must own the inference" unless reason.include?('rule 4')
  end
end

check('tall H.138: printed p.90 whole, 16 codes, and the kit-ready door is d.62 only') do
  rows = Registry.catalog.select { |c| c['section'] == 'Tall units H. 138' }
  raise rows.length.to_s unless rows.length == 16
  raise rows.map { |c| c['type_key'] }.uniq.length.to_s unless
    rows.map { |c| c['type_key'] }.uniq.length == 3
  raise 'C1 is d.35 and C2 is d.62, and nothing else is on this page' unless
    rows.all? { |c| c['code'].start_with?('C1', 'C2') }
  rows.each do |c|
    expected = c['code'].start_with?('C1') ? 350 : 620
    raise "#{c['code']}: #{c['depth_mm']} against #{expected}" unless
      c['depth_mm'] == expected
  end
  # THE KIT-READY DOOR HAS NO SHALLOW EXECUTION, in either tall family that
  # prints one. Two pages agreeing, recorded as what they price.
  kit = Registry.catalog.select { |c| c['type_key'] == 'tall_door_kit_ready' }
  raise 'the kit-ready doors have vanished' if kit.empty?
  raise kit.map { |c| c['depth_mm'] }.uniq.inspect unless
    kit.map { |c| c['depth_mm'] }.uniq == [620]
  raise 'they must come from more than one family' unless
    kit.map { |c| c['section'] }.uniq.length > 1
end

check('FIVE PLAIN TALL FAMILIES, ONE SHAPE, AND NO AGREEMENT ABOUT HANGING') do
  # printed p.90, p.97, p.111, p.132 and p.151 print the SAME three positions in
  # the same order: a door, a pair of doors, and a door that can take the
  # bottom-section kit. Everything structural about them agrees. Who can be hung
  # does not, and neither does the door's suffix.
  #
  #            door        two doors    kit-ready   door suffix
  #   H.138    hung        HUNG         no          01
  #   H.198    hung        no           no          31
  #   H.210    hung        no           no          31
  #   H.222    NO          no           no          02
  #   H.234    NO          no           no          02
  #
  # H.222 and H.234 refuse every position - the first whole families the
  # registry holds that cannot be hung at all - and they are also the two that
  # renumbered the door. That is a correlation across two families, recorded as
  # an observation in their files and used for nothing.
  plain = Registry.catalog.select { |c| c['section'].match?(/\ATall units H\. \d+\z/) }
  families = plain.map { |c| c['section'] }.uniq
  raise families.inspect unless families.length == 5
  families.each do |section|
    rows = plain.select { |c| c['section'] == section }
    raise "#{section}: #{rows.length}" unless [14, 16].include?(rows.length)
    keys = rows.map { |c| c['type_key'] }.uniq.sort
    raise "#{section}: #{keys.inspect}" unless
      keys == %w[tall_door tall_door_kit_ready tall_two_doors]
    kit = rows.select { |c| c['type_key'] == 'tall_door_kit_ready' }
    raise "#{section}: the kit-ready door must be d.62 only" unless
      kit.map { |c| c['depth_mm'] }.uniq == [620]
  end

  # THE DISAGREEMENT, BOTH WAYS ROUND. At least one family hangs something and
  # at least one hangs nothing; and the plain door - the position most nearly
  # constant across the chapter - is itself refused somewhere.
  hangs = families.to_h { |section|
    [section, plain.select { |c| c['section'] == section }
                   .any? { |c| Generator.wall_hung_available?(Registry.lookup(c['code'])) }]
  }
  raise hangs.inspect unless hangs.values.include?(true) && hangs.values.include?(false)
  doors = plain.select { |c| c['type_key'] == 'tall_door' }
  answers = doors.map { |c| Generator.wall_hung_available?(Registry.lookup(c['code'])) }.uniq
  raise 'even the plain door must disagree with itself across families' unless
    answers.length == 2

  # AND THE SUFFIX MOVES WITH NOTHING. THREE readings for one position: 01 at
  # H.138, 31 at H.198 and H.210, 02 at H.222 and H.234. This line was written
  # expecting two and found three, which is how it caught a note in
  # tall_h138.json claiming 'the same suffix 31' beside codes reading 01.
  suffixes = doors.map { |c| c['code'][-2..] }.uniq.sort
  raise suffixes.inspect unless suffixes.length == 3
end

check('THE CATALOG CACHE IS A CACHE, NOT A SECOND SOURCE') do
  # Registry.catalog is a pure function of Registry.data and was rebuilt on
  # every call. At 692 codes that is 0,38 s a time, and this suite calls it a
  # few hundred times: forty seconds became over ninety and the run stopped
  # fitting in one go. It is memoised now, keyed on the IDENTITY of the parsed
  # registry - so the moment data() re-reads an edited file the key misses.
  #
  # A CACHE THAT CAN DISAGREE WITH ITS SOURCE IS A SECOND SOURCE, which is the
  # thing this project keeps refusing to have. So: the cached array must be the
  # same object twice running, and it must equal what a fresh build produces
  # from the same data.
  first  = Registry.catalog
  second = Registry.catalog
  raise 'the cache is not caching' unless first.equal?(second)
  fresh = Registry.send(:build_catalog, Registry.data, 'cesar')
  raise 'the cache has drifted from its source' unless fresh == first
  raise 'a rebuild must be a NEW array, or the comparison proves nothing' if
    fresh.equal?(first)
end

check('A BASE PREFIX NAMES A (FAMILY, DEPTH) SLOT - and the grammar is checked against the codes') do
  # THE WALL CHAPTER GOT LUCKY. A wall family has one depth, so its two-letter
  # prefix could be treated as a family name and the filler table on printed
  # p.434 could be used to learn one. A BASE family has two or three depths and
  # a prefix for each: printed p.24 prices H.39 as B0 (d.35), BJ (d.47) and B1
  # (d.62). The prefix names a SLOT, not a family.
  #
  # And printed p.434 does not key the same way - it prices one filler per
  # HEIGHT with no depth axis, and its BJ sits at H.58,5 while the H.58,5 base
  # units are B3 / B6 / B4. Two characters, two different slots. The warning
  # lives in code_grammar.base_units and this check keeps it there, because a
  # warning nobody can delete silently is the only kind worth writing.
  grammar = Registry.data['code_grammar']['base_units']
  raise 'the base grammar block is gone' unless grammar
  raise 'it must say the prefix is not a family letter' unless
    grammar['shape'].to_s.include?('NOT A FAMILY LETTER')
  raise 'the filler collision must stay recorded' unless
    grammar['filler_letter_collision'].to_s.include?('BJ')
  raise 'the corner prefixes must stay recorded' unless
    grammar['corner_letters'].to_s.include?('AU')

  # AND THE CODES MUST AGREE WITH THE MAP. Where the grammar states a depth per
  # prefix, every held code of that family must sit in the slot its own prefix
  # names - which is what turns the map from prose into something that fails.
  map = grammar['family_depth_letter']
  checked = 0
  Registry.catalog.select { |c| c['class'] == 'base' }.each do |row|
    u = Registry.lookup(row['code'])
    # An appliance panel is not a base unit - it is a front for somebody else's
    # machine, and its V-prefix belongs to that grammar, not this one.
    next unless (u['object_class'] || 'cabinet') == 'cabinet'
    # AND A CORNER HAS ITS OWN PREFIXES AT THE SAME DEPTHS. printed p.42 prices
    # the H.78 corners as B7 at d.35 - shared with the plain units - and then
    # AU at d.62 and AW at d.67, where the plain units read B8 and B9. So the
    # slot is (family, depth, GEOMETRY), and the corner half is recorded in the
    # grammar's corner_letters rather than forced into the same table.
    next unless (row['geometry_kind'] || 'linear') == 'linear'

    slots = map[u['family'].to_s]
    next unless slots.is_a?(Hash)

    depths = slots.reject { |k, _| k == 'letters' || k == 'note' }
    next if depths.empty?

    prefix = row['code'][0, 2]
    expected = depths.key(prefix)
    raise "#{row['code']}: prefix #{prefix} is in no slot of #{row['section']}" if expected.nil?
    raise "#{row['code']}: #{prefix} names d.#{expected} and the row says #{row['depth_mm']}" unless
      expected.to_i == row['depth_mm']

    checked += 1
  end
  raise 'no base code was checked against the grammar' if checked < 100
end

check('A PAGE STOPPED FOR A DIMENSION WE CANNOT NAME SAYS SO IN BOTH PLACES') do
  # printed p.41 has been stopped since 2026-08-17 because its codes do not
  # decode with the p.36 lookup and its elevation reads 750. printed p.26 and
  # p.27 joined it on 2026-08-23: a LOW base unit with a prefix family of its
  # own and ONE elevation carrying TWO dimensions, 36,5 and 39, where every
  # other base page draws two profiles for the two door versions.
  #
  # UNREAD AND STOPPED ARE DIFFERENT STATES and the map does not distinguish
  # them - both are not_extracted. What distinguishes them is that a stopped
  # page carries its reason, in the map AND in the section file, so that the
  # next person to open it learns what beat us before they repeat it.
  stopped = Registry.gaps.select { |g|
    g['level'] == 'type' && g['note'].to_s.match?(/STOPPED|do NOT decode/i)
  }
  raise 'the stopped pages have vanished' if stopped.empty?
  stopped.each do |g|
    raise "#{g['printed']} is stopped without saying what beat us" unless
      g['note'].to_s.length > 120
  end
  # And the section file says it too, in a key a grep will find.
  files = Dir[File.expand_path('../registry/cesar/*.json', __dir__)]
          .reject { |f| File.basename(f).start_with?('_') }
  notes = files.map { |f| JSON.parse(File.read(f)).find { |k, _| k.end_with?('_stop_note') } }.compact
  raise 'no section file records a stop' if notes.empty?
  notes.each do |key, text|
    raise "#{key} must cite the page it stopped on" unless text.include?('printed p.')
    raise "#{key} must say a number could not be named" unless
      text.match?(/cannot name|we do not write down|does not say what it is/i)
  end
end

check('A PRINTED DESCRIPTION DOES NOT IDENTIFY AN ARTICLE') do
  # printed p.38 prints 'Base unit with drawer and doors' TWICE, as suffix 40
  # and as suffix 46, at the same widths, the same depths and the same price in
  # every band. 'Base unit with drawer and door' is 41 on printed p.37 and 47
  # on printed p.38. The words are identical; the ELEVATIONS are not. Anything
  # that keyed a position by its description would merge articles the factory
  # sells apart - which is why type_key is ours and the description is theirs.
  by_desc = Hash.new { |h, k| h[k] = [] }
  Registry.catalog.each do |c|
    u = Registry.lookup(c['code'])
    by_desc[[u['description'], c['section']]] << c['type_key']
  end
  shared = by_desc.select { |_, keys| keys.uniq.length > 1 }
  raise 'the twin descriptions have vanished' if shared.empty?
  # And where two type keys share a description, their FRONTS must differ -
  # otherwise they really are one article and the split is ours, not the page's.
  # ONE index, not a Registry.catalog.find per key: catalog is cached now but
  # it is still a 600-row array, and a find inside a loop is how a suite grows
  # a minute it does not need.
  first_of = {}
  Registry.catalog.each { |c| first_of[c['type_key']] ||= c['code'] }
  shared.each do |(desc, _section), keys|
    layouts = keys.uniq.map { |k| Registry.lookup(first_of[k])['front_layout'] }
    raise "#{desc}: two type keys, one front" unless layouts.uniq.length == layouts.length
  end
end

check('the hob pictogram is recorded where it was read - and the sweep is DONE') do
  # printed p.19 gives the legend for two glyphs that sit beside every base
  # code table: a cabinet-in-bracket is 'Hung version', a flame is 'Provisions
  # for hob'. Neither had been transcribed until 2026-08-23, and the pages read
  # before that date carried the marks unread - which is why THIS CHECK USED TO
  # SAY 'and NOWHERE else' and pin the two pages that had been looked at.
  #
  # The sweep ran on 2026-08-24. Every non-wall page carrying held codes has
  # now been read for both glyphs, so the question this check answers changed:
  # not 'was it recorded only where we looked', but 'is the record consistent
  # with what the pages print'. The hob mark is still read by nothing.
  files = Dir[File.expand_path('../registry/cesar/*.json', __dir__)]
          .reject { |f| File.basename(f).start_with?('_') }
  marked = files.flat_map { |file|
    JSON.parse(File.read(file))['data']['unit_types']
        .select { |_, ty| ty['hob_provisions_depths_mm'] }
        .map { |k, ty| [k, ty] }
  }
  raise 'the hob marks have vanished' if marked.empty?
  marked.each do |key, ty|
    # NEVER on d.35 or d.47. Eight base pages now agree on this and none of
    # them derives it - each was read.
    raise "#{key}: a hob mark on a shallow row" unless
      ty['hob_provisions_depths_mm'].all? { |d| d >= 620 }
    # And only ever in the base chapter, on a page we have actually opened.
    raise "#{key}: recorded without its page" unless
      ty['source_ref'].to_s.match?(/printed p\.(3[2456789]|4[02])\b/)
  end
  ruby = Dir[File.expand_path('../src/ucon_cabinet_engine/core/*.rb', __dir__)]
  raise 'nothing may read the hob mark yet' if
    ruby.any? { |f| File.read(f).include?('hob_provisions') }

  # THE OWED SWEEP MUST BE RECORDED AS DONE, in the one place that owed it.
  man = JSON.parse(File.read(File.expand_path('../registry/cesar/_manifest.json', __dir__)))
  sym = man['page_symbols']
  raise 'sweep_owed must be gone, not merely contradicted' if sym['sweep_owed']
  raise 'the sweep must record its date and its pages' unless
    sym.dig('sweep_done', 'date') == '2026-08-24' &&
    sym.dig('sweep_done', 'pages').is_a?(Hash) &&
    sym['sweep_done']['pages'].length >= 10
  obs = JSON.parse(File.read(File.expand_path('../registry/cesar/base_h78.json', __dir__)))
            .dig('data', 'page_observations').to_s
  raise 'the sweep result must be written down' unless obs.include?('THE SWEEP, 2026-08-24')
end

check('AFTER THE SWEEP, AN ABSENT HUNG READING IS A BUG') do
  # The point of the sweep, and the only thing that makes its negative result
  # worth four page reads. Before it, a type with no wall_hung key meant
  # EITHER 'the catalog offers it' OR 'nobody looked', and no reader could tell
  # which - the H.210 correction of 2026-08-23 was exactly that ambiguity
  # cashing out as six codes offered a version the catalog does not sell.
  #
  # Every non-wall CABINET type now states the reading, true as well as false.
  # A new section that forgets to fails here, which is the whole idea.
  #
  # The wall chapter is exempt BY OBSERVATION, not by assumption: its code
  # tables carry no pictogram column at all - re-checked on printed p.238 on
  # 2026-08-24 - and a wall unit hangs by nature, so the glyph would say
  # nothing. That exemption is recorded in _manifest.json page_symbols.
  silent = []
  files = Dir[File.expand_path('../registry/cesar/*.json', __dir__)]
          .reject { |f| File.basename(f).start_with?('_') }.sort
  files.each do |file|
    sec = JSON.parse(File.read(file))
    next if sec['class'] == 'wall'

    sec['data']['unit_types'].each do |key, ty|
      next unless (ty['object_class'] || 'cabinet') == 'cabinet'
      next if sec['class'] == 'filler'

      silent << "#{File.basename(file)}:#{key}" unless ty.key?('wall_hung')
      raise "#{key}: a hung reading with no note" if
        ty.key?('wall_hung') && ty['wall_hung_note'].to_s.empty?
    end
  end
  raise "these types state no hung reading: #{silent.inspect}" unless silent.empty?

  man = JSON.parse(File.read(File.expand_path('../registry/cesar/_manifest.json', __dir__)))
  raise 'the wall exemption must be written down, not assumed' unless
    man.dig('page_symbols', 'sweep_done', 'wall_chapter').to_s.include?('no pictogram column')
end

check('52 codes refuse the hung version, and every move of that number is dated') do
  # A sweep that changed an availability would be a correction, and a
  # correction gets a dated note of its own (rule 9). The printed p.19 sweep
  # changed none, and that is worth pinning: if a later edit quietly flips a
  # true to a false, the count moves and this fails with the reason in its
  # title.
  #
  # 2026-08-24: 46 -> 52, and it is NOT a flip. printed p.116 arrived with
  # twelve new codes, six of which the page refuses - the 2+2 door position
  # (C50950, C60950) and all four jumbo-drawer codes. Nothing already held
  # changed its answer; tall went 42 -> 48 and base stayed at 4.
  refused = Registry.catalog.map { |c| Registry.lookup(c['code']) }
                    .select { |u| u['wall_hung'] == false }
  raise refused.length.to_s unless refused.length == 52
  by_class = refused.group_by { |u| u['unit_class'] }.transform_values(&:length)
  raise by_class.inspect unless by_class == { 'base' => 4, 'tall' => 48 }
end

puts "\nwaste units (Trash & Recycle) and their bin kits"
check('both waste types are in: P-One 2 codes, XL 3 codes') do
  by_type = Registry.catalog.group_by { |c| c['type_key'] }.transform_values(&:length)
  raise by_type.inspect unless by_type['base_waste_pone'] == 2 && by_type['base_waste_xl'] == 3
end
check('EVERY waste code yields contract-valid attributes') do
  %w[B80565 B80665 B80366 B80566 B80666].each do |code|
    Contract.validate!(Generator.attributes_for(Registry.lookup(code)))
  end
end
# v2: companion_refs is a list of LINES. Most checks care about which codes got
# resolved, so this pulls them out; the SHAPE is checked once, hard, further down.
def companion_codes(code)
  lines = Generator.attributes_for(Registry.lookup(code))['companion_refs'] || []
  lines.map { |l| l['code'] }
end

check('each waste unit orders the bin kit for its own width') do
  refs = ->(code) { companion_codes(code) }
  # P-One, printed p.524: W450 -> 2 bins, W600 -> 3 bins.
  raise refs.call('B80565').inspect unless refs.call('B80565') == %w[995625]
  raise refs.call('B80665').inspect unless refs.call('B80665') == %w[995626]
  # Envi Space XL, printed p.525: one kit per width, 30/45/60.
  raise refs.call('B80366').inspect unless refs.call('B80366') == %w[995603]
  raise refs.call('B80566').inspect unless refs.call('B80566') == %w[995605]
  raise refs.call('B80666').inspect unless refs.call('B80666') == %w[995606]
end
check('a waste unit is a full-height pull-out front, gola 750') do
  u = Registry.lookup('B80666')
  raise Generator.front_slabs(u).inspect unless
    Generator.front_slabs(u).map { |s| [s[:h_mm], s[:z_mm]] } == [[780.0, 0.0]]
  raise Panel.effective_slabs(u, true).inspect unless
    Panel.effective_slabs(u, true).map { |s| [s[:h_mm], s[:z_mm]] } == [[750.0, 0.0]]
end
check('the XL unit records that the source forbids Servo Drive') do
  u = Registry.lookup('B80366')
  raise u.inspect unless u['description'].include?('no Servo Drive mechanism')
end

puts "\ndishwasher door: an appliance panel and its companion order lines"
check('the door is an appliance_front panel, not a cabinet') do
  a = Generator.attributes_for(Registry.lookup('V80630'))
  raise a['object_class'] unless a['object_class'] == 'appliance_front'
  raise a.inspect unless [a['width_mm'], a['height_mm'], a['depth_mm']] == [600, 780, 22]
  Contract.validate!(a)
end
check('the door is never handed: its hinges belong to the machine') do
  u = Registry.lookup('V80730')
  raise u.inspect unless u['handed'] == false
  raise u['front_layout'].inspect unless u['front_layout']['hinge_axis'] == 'bottom'
  raise 'a panel must not carry hinge_side' if Generator.attributes_for(u).key?('hinge_side')
end
check('companion refs resolve per width: 45/60 take a filler, 75 adds GBBF01') do
  refs = ->(code) { companion_codes(code) }
  raise refs.call('V80530').inspect unless refs.call('V80530') == %w[995945]
  raise refs.call('V80630').inspect unless refs.call('V80630') == %w[995946]
  # 60 + 15 = 75: the appliance behind a 75 door is still 60 wide, so the
  # filler is the W60 one and GBBF01 makes up the difference.
  raise refs.call('V80730').inspect unless refs.call('V80730') == %w[995946 GBBF01]
end
check('a cabinet carries no companion key at all') do
  %w[B80601 B81087 B80614].each do |code|
    a = Generator.attributes_for(Registry.lookup(code))
    raise code if a.key?('companion_refs')
  end
end
check('EVERY appliance code yields contract-valid attributes') do
  Registry.catalog.select { |c| c['section'].include?('household appliances') }.each do |row|
    Contract.validate!(Generator.attributes_for(Registry.lookup(row['code'])))
  end
end
check('companion_refs is a contract key (v2 §4.2) and rejects nothing valid') do
  raise 'key missing from the contract' unless Contract::KEYS.include?('companion_refs')
  Contract.validate!(VALID.merge('companion_refs' => [
    { 'code' => '995946', 'qty' => 1, 'um' => 'PZ', 'origin' => 'implied' },
    { 'code' => 'GBBF01', 'qty' => 1, 'um' => 'PZ', 'origin' => 'implied' }
  ]))
end

if defined?(UCON::CabinetEngine::Symbols)
  Symbols = UCON::CabinetEngine::Symbols
  check('bottom-hung front symbol: base on the hinge axis, apex at the opening edge') do
    m = Symbols.bottom_hung_marks(600, 100, 780, -25)
    # Two lines from the bottom corners to the mid-point of the top edge: the
    # inverted V. Same rule as a side-hung door, rotated onto the bottom axis.
    apex = [300.0, -25, 880]
    raise m[:front].inspect unless m[:front] == [[[0.0, -25, 100], apex],
                                                 [[600.0, -25, 100], apex]]
  end
  check('bottom-hung plan symbol: the leaf falls forward by its own height') do
    m = Symbols.bottom_hung_marks(600, 100, 780, -25)
    raise m[:plan_rect].inspect unless m[:plan_rect] == [[0.0, -25], [600.0, -25],
                                                        [600.0, -805], [0.0, -805]]
  end
  check('gola shortens both marks together: 750 front, 750 projection') do
    m = Symbols.bottom_hung_marks(600, 100, 750, -25)
    raise m[:front].inspect unless m[:front].all? { |(_, apex)| apex[2] == 850 }
    raise m[:plan_rect].inspect unless m[:plan_rect][2] == [600.0, -775]
  end
def hung_codes(axis)
  Registry.catalog.map { |c| Registry.lookup(c['code']) }
          .select { |u| (u['front_layout'] || {})['hinge_axis'] == axis }
          .map { |u| u['code'] }.sort
  end
  check('the hinge axis is one rule read both ways: top-hung is the mirror') do
    # WAS AN INVENTORY, NOW AN INVARIANT (2026-08-23). This check used to pin
    # two literal code lists. They reached 17 and 49 entries in one day of wall
    # extraction, and a list that has to be retyped on every commit stops being
    # read - which is exactly how rule 18's invariant went unnoticed. What the
    # check is actually about is that ONE rule decides the axis, everywhere.
    axis_of = lambda { |u| (u['front_layout'] || {})['hinge_axis'] }
    units = Registry.catalog.map { |c| Registry.lookup(c['code']) }

    # ONE LEAF TAKES THE AXIS; A STACKED PAIR CANNOT. hinge_axis is a single
    # value for the whole front, so on a 'top-hung doorS' unit - two leaves of
    # 360 one above the other, printed p.228 and p.232 - setting it would make
    # 70_symbols draw ONE 720-tall leaf instead of two. So the rule is scoped to
    # kind 'single', and the stacked kind must carry no axis at all. That is not
    # a loophole: it is the check refusing to let an unstated figure be guessed.
    top = units.select { |u| u['description'].to_s.downcase.include?('top-hung') }
    raise 'no top-hung types at all' if top.empty?
    single_top = top.select { |u| (u['front_layout'] || {})['kind'] == 'single' }
    raise 'no single top-hung type left' if single_top.empty?
    bad = single_top.reject { |u| axis_of.call(u) == 'top' }
    raise "top-hung without a top axis: #{bad.map { |u| u['code'] }.inspect}" unless bad.empty?
    # AND THIS ONE WAS AN INVENTORY TOO, for one day. It pinned [360, 360],
    # which was every stacked pair the registry held - until H.84 arrived
    # splitting 480 + 360. A STACKED PAIR IS TWO STATED HEIGHTS THAT SUM TO THE
    # FAMILY HEIGHT, never two halves of it, and that is what is checked now.
    stacked_top = top - single_top
    raise 'the stacked pairs have vanished' if stacked_top.empty?
    bad = stacked_top.reject { |u|
      fl = u['front_layout'] || {}
      hs = fl['heights_mm_top_to_bottom']
      axis_of.call(u).nil? && fl['kind'] == 'horizontal' &&
        hs.is_a?(Array) && hs.length == 2 && hs.sum == u['height_mm']
    }
    raise "a stacked pair must be two fronts summing to the family height, and no axis: #{bad.map { |u| u['code'] }.inspect}" unless bad.empty?
    # Both shapes are held, and they are NOT the same shape. AND THIS LINE WAS
    # STILL AN INVENTORY: it pinned [[360, 360], [480, 360]] and H.96 broke it
    # the same day by splitting 480 + 480. What is actually being claimed is
    # that the registry holds an EQUAL pair and an UNEQUAL one, so that neither
    # shape can ever be assumed from the family height.
    splits = stacked_top.map { |u| u['front_layout']['heights_mm_top_to_bottom'] }.uniq
    raise 'an equal stacked pair must be held' unless splits.any? { |s| s[0] == s[1] }
    raise 'an UNEQUAL stacked pair must be held' unless splits.any? { |s| s[0] != s[1] }

    bottom = units.select { |u| u['description'].to_s.downcase.include?('bottom-hung') }
    raise 'no bottom-hung types at all' if bottom.empty?
    bad = bottom.reject { |u| axis_of.call(u) == 'bottom' }
    raise "bottom-hung without a bottom axis: #{bad.map { |u| u['code'] }.inspect}" unless bad.empty?

    # AND THE CONVERSE, which is the half an inventory could never state: no
    # CABINET gets an axis its description did not ask for.
    #
    # The dishwasher doors are the stated exception and the reason is worth
    # keeping: V80530 / V80630 / V80730 read 'Door for fully-integrated
    # dishwasher' and never say bottom-hung, because the axis is the MACHINE's
    # and not the catalog's wording. That is object_class appliance_front, the
    # one class whose geometry is decided by something Cesar does not sell. Any
    # OTHER object_class carrying an unexplained axis is a bug.
    stray = units.select { |u| axis_of.call(u) } - single_top - bottom
    bad = stray.reject { |u| u['object_class'] == 'appliance_front' }
    raise "an axis nobody asked for: #{bad.map { |u| u['code'] }.inspect}" unless bad.empty?
    raise 'the appliance-front exception has lost its subject' if stray.empty?

    # PUSH-UP IS IN NEITHER LIST, in every family. It is its own opening type in
    # this catalog and nothing we have read says its leaf sweeps a top-hung
    # figure. A symbol we cannot justify is not drawn - so hinge_axis is absent,
    # not guessed.
    push = units.select { |u| u['opening'] == 'push-up' }
    raise 'no push-up types to check' if push.empty?
    bad = push.reject { |u| axis_of.call(u).nil? }
    raise bad.map { |u| u['code'] }.inspect unless bad.empty?

    # Same unit, both ways up: the two figures are reflections of each other in
    # the mid-height plane, and the plan footprint is identical because the leaf
    # sweeps the same rectangle whichever way it swings.
    b = Symbols.bottom_hung_marks(600, 1400, 360, -25)
    t = Symbols.top_hung_marks(600, 1400, 360, -25)
    raise b[:front].inspect unless b[:front].all? { |(base, apex)| base[2] == 1400 && apex[2] == 1760 }
    raise t[:front].inspect unless t[:front].all? { |(base, apex)| base[2] == 1760 && apex[2] == 1400 }
    raise 'the plan rectangle must not differ' unless b[:plan_rect] == t[:plan_rect]
  end
end

check('the appliance niche is the occupied space, never an order line') do
  u = Registry.lookup('V80730')
  n = Generator.niche_attributes_for(u)
  Contract.validate!(n)
  raise n['object_class'] unless n['object_class'] == 'appliance'
  raise n['manufacturer'] unless n['manufacturer'] == 'client'
  raise 'a niche must carry no code' if n['code']
  raise 'a niche must never carry companions' if n.key?('companion_refs')
  # Width is the catalog door width - for a 75 door that is the whole opening,
  # appliance plus GBBF01, so the niche is right whichever side the cabinet
  # ends up on (Elda Q5).
  raise n['width_mm'].to_s unless n['width_mm'] == 750
  # CORRECTED 2026-08-24. It used to read "floor to worktop underside: an
  # appliance stands on the floor", and that was the honest description of a
  # drawing with nothing under the machine. The panel now carries a DRAWN
  # plinth, so the phantom starts on top of it and the span is the family's
  # 780. The appliance did not move; the drawing did.
  raise n['height_mm'].to_s unless n['height_mm'] == 780
end
check('the niche inherits the run depth when there is one, and says which') do
  u = Registry.lookup('V80630')
  default = Generator.niche_attributes_for(u)
  raise default['depth_mm'].to_s unless default['depth_mm'] == 620
  raise default['notes'] unless default['notes'].include?('no neighbour was selected')
  inherited = Generator.niche_attributes_for(u, 670, true)
  raise inherited['depth_mm'].to_s unless inherited['depth_mm'] == 670
  raise inherited['notes'] unless inherited['notes'].include?('inherited from the neighbouring unit')
end
check('appliance is a contract class (v1.4) and appliance_front still is too') do
  %w[appliance appliance_front].each do |k|
    raise k unless Contract::ENUMS['object_class'].include?(k)
  end
end

check('door version 75 shortens the panel to 750, through the normal front path') do
  u = Registry.lookup('V80630')
  raise Generator.front_slabs(u).inspect unless
    Generator.front_slabs(u) == [{ name: 'FRONT', x_mm: 0, z_mm: 0, w_mm: 600, h_mm: 780 }]
  raise Panel.effective_slabs(u, true).inspect unless
    Panel.effective_slabs(u, true) == [{ name: 'FRONT', x_mm: 0, z_mm: 0, w_mm: 600, h_mm: 750 }]
  # The slab is named FRONT, so Panel.rebuild_fronts replaces it like any other
  # front instead of leaving a stale 780 panel behind a new 750 one.
  raise 'the panel slab must be named FRONT*' unless
    Generator.front_slabs(u).all? { |sl| sl[:name].start_with?('FRONT') }
end
check('an appliance panel may take door 75 without ordering its own GOL profile') do
  u = Registry.lookup('V80630')
  patch = Panel.attributes_patch(u, 'door_version' => '75', 'hardware_ref' => '')
  raise patch.inspect unless patch['front_height_mm'] == 750 && patch['opening_method'] == 'gola'
  raise 'no profile must be invented' if patch.key?('hardware_ref')
  # A cabinet still must name one - that rule is source-backed and unchanged.
  cab = Registry.lookup('B80601')
  begin
    Panel.attributes_patch(cab, 'door_version' => '75', 'hardware_ref' => '')
    raise 'a cabinet without a GOL profile must be refused'
  rescue ArgumentError
    nil
  end
end

puts "\ncatalog map + picker gaps (what the printed index says exists)"
# A gap row is either a page (inside a section we hold) or a section carrying
# the pages we have read. This flattens both shapes to "find me printed p.N".
def gap_page(printed)
  Registry.gaps.flat_map { |g| g['pages'] || [g] }.find { |x| x['printed'] == printed }
end
check('every status in the map is from the closed vocabulary') do
  bad = []
  Registry.map_sections.each do |sec|
    bad << sec['section'] unless Registry::STATUSES.include?(sec['status'])
    (sec['pages'] || []).each do |pg|
      bad << "#{sec['section']} p.#{pg['printed']}" unless Registry::STATUSES.include?(pg['status'])
      Registry.normalize_types(pg, pg['status']).each do |t|
        bad << "p.#{pg['printed']} / #{t['title']}" unless Registry::STATUSES.include?(t['status'])
        bad << "p.#{pg['printed']} / (untitled type)" if t['title'].to_s.empty?
      end
    end
  end
  raise bad.inspect unless bad.empty?
end
check('every extracted section is present in the map, and vice versa') do
  in_registry = Registry.catalog.map { |r| r['section'] }.uniq.sort
  in_map      = Registry.map_sections.map { |s| s['section'] }
  raise "duplicate map sections: #{in_map.inspect}" unless in_map.uniq == in_map
  missing = in_registry - in_map
  raise "extracted but unmapped: #{missing.inspect}" unless missing.empty?
  in_registry.each do |name|
    sec = Registry.map_sections.find { |s| s['section'] == name }
    raise "#{name} is extracted but mapped as #{sec['status']}" unless
      %w[extracted partial].include?(sec['status'])
  end
end
check('a section we hold is never offered as a section-level gap') do
  have = Registry.catalog.map { |r| r['section'] }.uniq
  bad = Registry.gaps.select { |g| g['level'] == 'section' && have.include?(g['section']) }
  raise bad.map { |g| g['section'] }.inspect unless bad.empty?
end
check('type-level gaps only appear inside sections we hold') do
  have = Registry.catalog.map { |r| r['section'] }.uniq
  bad = Registry.gaps.select { |g| g['level'] == 'type' && !have.include?(g['section']) }
  raise bad.map { |g| g['printed'] }.inspect unless bad.empty?
end
check('p.44 is not a gap; p.45, p.46 and the H.84 sections are') do
  raise 'p.44 is extracted and must not be a gap' if gap_page('p.44')
  %w[p.45 p.46].each { |p| raise "#{p} missing" unless gap_page(p) }
  raise 'H.84 section missing' unless Registry.gaps.any? { |g| g['printed'] == 'p.49-52' }
end
check('a section appears once; a held section reports its pages as type rows') do
  sections = Registry.gaps.select { |g| g['level'] == 'section' }.map { |g| g['section'] }
  raise "duplicated rows: #{sections.inspect}" unless sections.uniq == sections
  # Appliances became a held section the moment the dishwasher door landed, so
  # its remaining pages now surface as type-level rows inside it.
  appl = Registry.gaps.select do |g|
    g['family'] == 'H.78' && g['section'].include?('household appliances')
  end
  raise appl.inspect unless appl.map { |g| g['printed'] } == ['p.47', 'p.48']
  raise appl.inspect unless appl.all? { |g| g['level'] == 'type' }
end
check('decisions are per position: p.47 excludes 3 of 4 types, the dishwasher door is in') do
  g47 = gap_page('p.47')
  raise g47.inspect unless g47
  by_status = g47['types'].group_by { |t| t['status'] }
  raise by_status.transform_values(&:size).inspect unless
    by_status['excluded'].to_a.size == 3 && by_status['extracted'].to_a.size == 1
  kept = by_status['extracted'].first
  raise kept.inspect unless kept['title'].include?('dishwasher')
  by_status['excluded'].each do |t|
    raise "#{t['title']} has no recorded reason" if t['note'].to_s.empty?
  end
end
check('the dishwasher kit is recorded: door and filler extracted, hob protection not') do
  # 'planned' became 'extracted' on 2026-08-23. The three door executions are
  # HELD AND NOT BUILDABLE - two fronts summing to 720 or 750 against a family
  # door height of 780 - and holding something we cannot draw is allowed as long
  # as the row says why. The hob protection stays out: it belongs to a hob, and
  # no hob is held.
  types = gap_page('p.48')['types']
  door   = types.find { |t| t['title'].include?('dish-washer') }
  filler = types.find { |t| t['title'].start_with?('Filler profile') }
  hob    = types.find { |t| t['title'].include?('induction hob') }
  raise door.inspect unless door && door['status'] == 'extracted'
  raise filler.inspect unless filler && filler['status'] == 'extracted'
  raise hob.inspect unless hob && hob['status'] == 'not_extracted'
  # And the six codes are in, none of them drawable.
  rows = Registry.catalog.select { |c| c['code'].to_s.start_with?('V88') }
  raise rows.length.to_s unless rows.length == 6
  raise 'a gola-only panel must not be offered for building' if rows.any? { |c| c['buildable'] }
  # The filler is the companion order line; the codes are the source's, and a
  # 75 door takes the 60 filler because the appliance behind it is 60 wide.
  %w[995945 995946].each { |c| raise "filler #{c} missing" unless filler['note'].include?(c) }
end
check('a bare string type inherits its page status; an object keeps its own') do
  page = { 'status' => 'not_extracted',
           'types' => ['plain', { 'title' => 'decided', 'status' => 'excluded', 'note' => 'why' }] }
  out = Registry.normalize_types(page, 'not_extracted')
  raise out.inspect unless out[0] == { 'title' => 'plain', 'status' => 'not_extracted', 'note' => nil }
  raise out.inspect unless out[1]['status'] == 'excluded' && out[1]['note'] == 'why'
end
check('p.41 carries its grammar warning into the gap row') do
  g = gap_page('p.41')
  raise g.inspect unless g && g['note'].to_s.include?('do NOT decode')
end
puts "\nwall units H. 36 (printed p.211) - Contract v1.5 mounting"
check('a hung object must say how high it hangs; a floor object must not') do
  base = Generator.attributes_for(Registry.lookup('B80601'))
  raise base.inspect unless base['mounting'] == 'floor'
  raise 'a floor unit must not carry a hanging height' if base.key?('mount_bottom_mm')

  wall = Generator.attributes_for(Registry.lookup('PB0600'))
  raise wall.inspect unless wall['mounting'] == 'wall_hung'
  raise wall.inspect unless wall['mount_bottom_mm'] == Standards::WALL_MOUNT_BOTTOM_MM
  Contract.validate!(wall)
end

rejects('a hung object with no hanging height',
        with('mounting' => 'wall_hung', 'mount_bottom_mm' => nil), 'requires mount_bottom_mm')
rejects('a hanging height on something that stands on the floor',
        with('mounting' => 'floor', 'mount_bottom_mm' => 1400), 'only meaningful')
rejects('a mounting outside the enum', with('mounting' => 'ceiling'), 'is not one of')
rejects('a hung object at a non-positive height',
        with('mounting' => 'wall_hung', 'mount_bottom_mm' => 0), 'must be positive')

check('H.36 is now the whole page: 17 codes in three types, all d.35') do
  rows = Registry.catalog.select { |c| c['section'] == 'Wall units H. 36' }
  raise rows.length.to_s unless rows.length == 17
  raise rows.map { |r| r['height_mm'] }.uniq.inspect unless rows.map { |r| r['height_mm'] }.uniq == [360]
  raise rows.map { |r| r['depth_mm'] }.uniq.inspect unless rows.map { |r| r['depth_mm'] }.uniq == [350]
  by_type = rows.group_by { |r| r['type_key'] }.map { |k, v| [k, v.length] }.sort
  raise by_type.inspect unless by_type == [['wall_bottom_hung_door', 6],
                                           ['wall_push_up_door', 5],
                                           ['wall_top_hung_door', 6]]
  # The push-up type is NARROWER: W.60-120, no W.45.
  push = rows.select { |r| r['type_key'] == 'wall_push_up_door' }.map { |r| r['width_mm'] }.sort
  raise push.inspect unless push == [600, 750, 900, 1050, 1200]
end

check('H.60 is 30 codes in eight types, all d.35, and it hangs') do
  # Was four types and 15 codes - the section's first page. printed p.222-223
  # were read on 2026-08-23 and brought the four compound types.
  rows = Registry.catalog.select { |c| c['section'] == 'Wall units H. 60' }
  raise rows.length.to_s unless rows.length == 30
  raise rows.map { |r| r['height_mm'] }.uniq.inspect unless rows.map { |r| r['height_mm'] }.uniq == [600]
  raise rows.map { |r| r['depth_mm'] }.uniq.inspect unless rows.map { |r| r['depth_mm'] }.uniq == [350]
  by_type = rows.group_by { |r| r['type_key'] }.map { |k, v| [k, v.length] }.sort
  raise by_type.inspect unless by_type == [['wall_compound_2_push_up', 2],
                                           ['wall_compound_2_top_hung', 5],
                                           ['wall_compound_3_push_up', 4],
                                           ['wall_compound_3_top_hung', 4],
                                           ['wall_door', 3],
                                           ['wall_push_up_door', 5],
                                           ['wall_top_hung_door', 6],
                                           ['wall_two_doors', 1]]
  rows.each { |r| Contract.validate!(Generator.attributes_for(Registry.lookup(r['code']))) }
  raise 'every H.60 unit must hang' unless
    rows.all? { |r| Generator.wall_hung?(Registry.lookup(r['code'])) }
end

check('the registry reproduces a real factory order line') do
  # Estimate 2026/30829 rows 15/18/25/27. This is the first time the registry
  # can be checked against Cesar's own output rather than against a page.
  u = Registry.lookup('PD0631')
  raise u.inspect unless u['width_mm'] == 600 && u['height_mm'] == 600 && u['depth_mm'] == 350
  raise 'the ..31 type must be handed' unless u['handed'] == true
  raise u['mounting'] unless u['mounting'] == 'wall_hung'
end

check('H.60 is the first wall page with a side-hinged door, and it says so') do
  # printed p.11: an rh/lh wall unit next to a tall unit or a wall wants a 5 cm
  # closing strip. p.211 was that rule's own escape hatch; p.221 is not.
  obs = Registry.data['families']['Wall H.60']['page_observations'].join(' ')
  raise 'the closing-strip consequence must be recorded' unless obs.include?('closing-strip')
  raise 'the missing W.30 must be recorded' unless obs.include?('no W.30')
  raise 'the absent pull-out type must be recorded' unless obs.include?('NO PULL-OUT DOOR TYPE')
end

check('a push-up door never claims a hinge axis, and never will') do
  %w[PB0610 PD1210].each do |code|
    fl = Registry.lookup(code)['front_layout']
    raise "#{code}: a push-up door must not claim a hinge axis" if fl.key?('hinge_axis')
    raise "#{code}: #{fl.inspect}" unless fl['mechanism'] == 'push_up'
    raise "#{code} must not be handed" unless Registry.lookup(code)['handed'] == false
  end
  # Same shape as the pull-out door on printed p.36 - one precedent, not two.
  raise 'the precedent must still hold' unless
    Registry.lookup('B80300')['front_layout']['mechanism'] == 'pull_out_door'
end

check('push-up is TWO motions, and the two families say which') do
  # printed p.560 heads H.36/H.48 "Vertical", p.561 heads H.60/H.72 "Oblique".
  # The unit pages call both of them "push-up" - the difference is only in the
  # mechanism chapter, and one symbol for both would be wrong half the time.
  raise 'H.36 must be the vertical system' unless
    Registry.lookup('PB0610')['front_layout']['system'] == 'vertical_push_up'
  raise 'H.60 must be the oblique system' unless
    Registry.lookup('PD0610')['front_layout']['system'] == 'oblique_push_up'
end

check('the printed push-up numbers close: an open leaf IS its own door') do
  # The whole reason the catalog can be trusted over its own picture.
  # H.60: 82 - 25,4 = 56,6 of run; a 60 leaf then drops sqrt(60^2 - 56,6^2)
  # = 19,9; length 60,0. Four printed numbers, no residue.
  { 'PB0610' => 360, 'PD0610' => 600 }.each do |code, door_h|
    ol = Registry.lookup(code)['front_layout']['open_leaf']
    dy = ol['free_mm'][0] - ol['upper_mm'][0]
    dz = ol['free_mm'][1] - ol['upper_mm'][1]
    len = Math.sqrt((dy * dy) + (dz * dz))
    raise "#{code}: leaf #{len.round(1)} but the door is #{door_h}" unless
      (len - door_h).abs < 1.0
    raise "#{code}: source_ref missing" unless ol['source_ref'].to_s.include?('printed')
  end
end

check('the forward reach is the number that matters, and it comes from the page') do
  reach = lambda do |code|
    ol = Registry.lookup(code)['front_layout']['open_leaf']
    -[ol['upper_mm'][0], ol['free_mm'][0]].min
  end
  # A top-hung H.36 sweeps 360 into the room; a vertical push-up only 150.
  # That difference is WHY a push-up is specified, and until now we drew zero.
  raise reach.call('PB0610').to_s unless reach.call('PB0610') == 150
  raise reach.call('PD0610').to_s unless reach.call('PD0610') == 470
end

if defined?(UCON::CabinetEngine::Symbols)
  Symbols = UCON::CabinetEngine::Symbols unless defined?(Symbols)

  check('the open leaf is the real front slab, thickened AWAY from the cabinet') do
    ol = Registry.lookup('PD0610')['front_layout']['open_leaf']
    rings = Symbols.open_leaf_slab(600, ol['upper_mm'], ol['free_mm'],
                                   Standards::FRONT_T_MM)
    raise rings.inspect unless rings && rings.length == 2 &&
                               rings.all? { |r| r.length == 4 }
    inner, outer = rings
    raise 'the inner face must be exactly the printed edge' unless
      inner[0][1] == ol['upper_mm'][0] && inner[0][2] == ol['upper_mm'][1]
    raise 'thickness grew INTO the cabinet' unless outer[0][1] < inner[0][1]
    d = Math.sqrt(((outer[0][1] - inner[0][1])**2) + ((outer[0][2] - inner[0][2])**2))
    raise "thickness #{d}" unless (d - Standards::FRONT_T_MM).abs < 0.001
  end

  check('an open door is the same slab as the same door closed') do
    # A door that changes thickness by opening is the model contradicting
    # itself. There is one front thickness and it is Standards::FRONT_T_MM.
    src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/70_symbols.rb', __dir__))
    raise 'a second thickness constant has appeared' if src =~ /(THICK|LEAF_T)_MM/
    raise 'the open leaf must ask Standards for the front thickness' unless
      src.include?('t  = Standards::FRONT_T_MM')
  end

  check('one swing quad feeds BOTH the plan symbol and the 3-D leaf') do
    # They used to be two copies of the same trigonometry. Two copies is two
    # chances to update one.
    src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/70_symbols.rb', __dir__))
    raise 'swing_quad is not shared' unless src.scan('swing_quad(').length >= 3
    q = Symbols.swing_quad(0, -25, 600, 'lh', 22)
    raise q.inspect unless q.length == 4
    raise 'the hinge corner must sit on the hinge' unless q[0] == [0, -25]
    # 85 degrees, not 90: the far corner is still short of the side plane.
    raise q.inspect unless q[2][1] < -500
  end

  check('a leaf that swings about a vertical edge is that quad, lifted') do
    q = Symbols.swing_quad(0, -25, 600, 'lh', 22)
    lo, hi = Symbols.open_leaf_prism(q, 0, 780)
    raise lo.inspect unless lo.length == 4 && hi.length == 4
    raise 'the lift must be the door height' unless
      hi.map { |p| p[2] }.uniq == [780] && lo.map { |p| p[2] }.uniq == [0]
    raise 'plan footprint must be identical top and bottom' unless
      lo.map { |p| p[0, 2] } == hi.map { |p| p[0, 2] }
  end
end

check('the palette window can grow, because the palette does') do
  # It was fixed at 240x360 and not resizable. Adding one row of buttons
  # pushed the rest off the bottom with no way to get them back. The lesson is
  # not "pick a taller number" - it is that a panel still being designed must
  # not be locked to a size.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/90_palette.rb', __dir__))
  raise 'the palette must be resizable' unless src.include?('resizable: true')
  raise 'a fixed-size palette has come back' if src.include?('resizable: false')
  h = src[/height:\s*(\d+)/, 1].to_i
  raise "declared height #{h} is too short for the buttons" unless h >= 440
  # The remembered geometry is per preferences_key: a stale key would restore
  # the old cramped size over any new default.
  raise 'the size changed but the preferences key did not' unless
    src.include?("preferences_key: 'UCONPalette2'")
end

check('the palette offers the open door as its own switch') do
  html = UCON::CabinetEngine::Palette.html
  raise 'no Open door button' unless html.include?(">Open door<")
  raise 'the door mode must be wired' unless html.include?("sketchup.symbols('door')")
  %w[plan front all off].each do |m|
    raise "the #{m} switch went missing" unless html.include?("sketchup.symbols('#{m}')")
  end
end

check('three tags, and the third is not a flat convention') do
  raise 'TAG_DOOR missing' unless defined?(UCON::CabinetEngine::Symbols::TAG_DOOR)
  tags = [UCON::CabinetEngine::Symbols::TAG_FRONT,
          UCON::CabinetEngine::Symbols::TAG_PLAN,
          UCON::CabinetEngine::Symbols::TAG_DOOR]
  raise tags.inspect unless tags.uniq.length == 3
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/70_symbols.rb', __dir__))
  raise 'show_mode must switch all three' unless
    src.include?('door.visible  = %i[door all].include?(mode)')
end

check('the width index is a lookup: no code decodes arithmetically') do
  # 45 rounds UP to 05 while 75 and 105 round DOWN to 07 and 10. Anything that
  # tries to compute a width from the digits gets two of these wrong.
  { 'PB0500' => 450, 'PB0700' => 750, 'PB1000' => 1050, 'PB1200' => 1200 }.each do |code, w|
    raise code unless Registry.lookup(code)['width_mm'] == w
  end
end

check('a wall unit is one full-height front and no plinth in the geometry') do
  slabs = Generator.front_slabs(Registry.lookup('PB1200'))
  raise slabs.inspect unless slabs.length == 1
  raise slabs.inspect unless slabs[0][:w_mm] == 1200 && slabs[0][:h_mm] == 360
  raise 'a wall unit must be hung' unless Generator.wall_hung?(Registry.lookup('PB1200'))
  raise 'a base unit must not be' if Generator.wall_hung?(Registry.lookup('B80601'))
end

puts "\nwall units chapter (map only - printed p.205 index, nothing extracted yet)"
def wall_sections
  Registry.map_sections.select { |s| s['class'] == 'wall' }
end


check('the wall chapter is in the map: 24 sections read from the printed p.205 index') do
  raise wall_sections.size.inspect unless wall_sections.size == 24
  families = wall_sections.map { |s| s['family'] }.uniq
  raise families.inspect unless families == %w[H.36 H.48 H.60 H.72 H.84 H.96 H.120]
  first = wall_sections.first
  raise first.inspect unless first['section'] == 'Wall units H. 36' &&
                             first['printed_pages'] == '211-212'
  raise wall_sections.last.inspect unless wall_sections.last['printed_pages'] == '256'
end

check('a hood variant is excluded by decision, dated, with its reason') do
  hoods = wall_sections.select { |s| s['section'].include?('Virgola') }
  raise hoods.size.inspect unless hoods.size == 11
  hoods.each do |h|
    raise h.inspect unless h['status'] == 'excluded' && h['decided_on'] == '2026-08-18'
    raise h.inspect unless h['note'].include?('per POSITION')
  end
  # AND 'not_extracted' LEFT THE SET ON 2026-08-23. Every one of the thirteen
  # non-hood wall sections is now extracted or partial - the first chapter in
  # this book with no unopened section in it. 'extracted' means nothing of the
  # section is held back; 'partial' here almost always means one corner waiting
  # on Elda Q7b.
  rest = (wall_sections - hoods).map { |s| s['status'] }.uniq.sort
  raise rest.inspect unless rest == %w[extracted partial]
  raise (wall_sections - hoods).length.to_s unless (wall_sections - hoods).length == 13
  whole = (wall_sections - hoods).select { |s| s['status'] == 'extracted' }
  raise whole.map { |s| s['section'] }.inspect unless
    whole.map { |s| s['section'] }.sort ==
      ['Dish-drainer units H. 36', 'Dish-drainer units H. 48']
  raise 'a whole section still says when it was read' unless
    whole.all? { |s| s['extracted_on'] == '2026-08-23' }
end

check('the wall grammar warning travels with the chapter, not with our memory of H.78') do
  h36 = wall_sections.first
  %w[PB PE PG LOOKUP].each do |frag|
    raise "#{frag} missing from the H.36 note" unless h36['note'].to_s.include?(frag)
  end
  # THE LIST IS NOW EMPTY. H.48, H.96 and H.120 were the last three, and all
  # three were named by the FILLER table on printed p.434 before any wall page
  # we held could have given them - then confirmed on their own pages.
  unread = wall_sections.select { |s| s['note'].to_s.include?('Family letter not read') }
  raise unread.map { |s| s['family'] }.inspect unless unread.empty?
  # H.60 left that list on 2026-08-20 - not by being read, but by turning up in
  # a factory order. The section stays not_extracted: a letter is not a page.
  h60 = wall_sections.find { |x| x['section'] == 'Wall units H. 60' }
  raise h60.inspect unless h60['note'].include?('PD0631') && h60['status'] == 'partial'
  # AND THE 'LETTER READ, PAGE NOT' SHELF IS EMPTY TOO. H.96 and H.120 were the
  # last two on it and both were read on 2026-08-23. The warnings are KEPT in
  # their notes rather than deleted (rule 9): each section that spent its letter
  # now carries both halves - the old 'LETTER READ' caution and the dated
  # extraction beside it - so the shape of the mistake stays visible after the
  # mistake is gone.
  %w[H.96 H.120].each do |fam|
    sec = wall_sections.find { |x| x['family'] == fam && x['section'].start_with?('Wall units') }
    raise "#{fam}: #{sec.inspect}" unless
      sec['status'] == 'partial' && sec['extracted_on'] == '2026-08-23'
    raise "#{fam} must keep the letter warning it outgrew" unless
      sec['note'].to_s.include?('LETTER READ') && sec['note'].to_s.include?('a letter is not a page')
  end
end

check('THE WALL CHAPTER IS OPEN END TO END: thirteen sections held, eleven hood rows left') do
  wall = Registry.gaps.select { |g| g['class'] == 'wall' }
  # ELEVEN, AND ALL ELEVEN ARE HOODS. When the last ordinary wall section was
  # opened on 2026-08-23 the only section-level gaps left in this chapter became
  # the eleven Virgola pages excluded by decision on 2026-08-18. A gap list that
  # contains only decisions is a chapter that has been read.
  sections = wall.select { |g| g['level'] == 'section' }
  raise sections.size.inspect unless sections.size == 11
  raise 'every wall section gap left is a hood decision' unless
    sections.all? { |g| g['section'].include?('Virgola') }
  held = Registry.catalog.select { |c| c['class'] == 'wall' }.map { |c| c['section'] }.uniq
  raise 'a section we hold must not also be a section gap' if
    sections.any? { |g| held.include?(g['section']) }

  # Both held sections surface their unextracted pages as TYPE rows, in the
  # order the catalog prints them. p.211 and p.221 are gone: they are whole.
  # FOUR PARTIAL PAGES, and every one of them is partial for the SAME reason:
  # p.212 (H.36 compounds, not yet read) is the only page here still waiting on
  # transcription. p.216, p.223 and p.225 are complete except for a corner, and
  # every corner in this registry waits on Elda Q7b. p.222 left this list on
  # 2026-08-23 by being finished.
  # SIX PARTIAL PAGES, and only ONE of them is partial for want of reading:
  # p.212, the H.36 compounds. The other five - p.216, p.223, p.225, p.230,
  # p.233 - are complete except for a corner, and every corner in this registry
  # waits on Elda Q7b. When she answers, five of these six close at once.
  # THIRTEEN PARTIAL PAGES, and only ONE of them is partial for want of reading:
  # p.212, the H.36 compounds. The other twelve are complete except for a
  # corner, and every corner waits on Elda Q7b. When she answers, twelve close
  # at once. THAT RATIO IS THE FINDING OF THIS CHAPTER: the wall units are READ,
  # and what is missing is one answer from the factory, not more transcription.
  pages = wall.select { |g| g['level'] == 'type' }.map { |g| g['printed'] }
  raise pages.inspect unless pages ==
    %w[p.212 p.216 p.223 p.225 p.230 p.233 p.239 p.242 p.246 p.249 p.252 p.253 p.254]
end

check('p.211 and p.221 are whole pages now, push-up included') do
  %w[211 221].each do |n|
    page = Registry.map_sections.flat_map { |sec| sec['pages'] || [] }
                   .find { |pg| pg['printed'].to_s == n }
    raise "p.#{n}: #{page.inspect}" unless page && page['status'] == 'extracted'
    push = page['types'].find { |t| t['title'].to_s.include?('push-up') }
    raise "p.#{n}: no push-up row" unless push
    raise "p.#{n}: #{push.inspect}" unless push['status'] == 'extracted'
    # The decision must carry its own date - it reversed an earlier one.
    raise "p.#{n}: the reversal must be dated" unless push['decided_on'] == '2026-08-20'
  end
end

check('the corner wall units on p.223 are RECORDED, not invented') do
  page = Registry.map_sections.flat_map { |sec| sec['pages'] || [] }
                 .find { |pg| pg['printed'].to_s == '223' }
  # p.223 became PARTIAL on 2026-08-23: its compound push-up position was
  # extracted and only the two corners are still out. The check is about the
  # CORNERS, and they have not moved.
  raise page.inspect unless page && page['status'] == 'partial'
  types = page['types'].map { |t| t.is_a?(Hash) ? "#{t['title']} #{t['note']}" : t }.join(' | ')
  raise types unless types.include?('PD094D/S') && types.include?('OD0713')
  # Neither grammar may leak into the catalog before a corner page is extracted.
  bad = Registry.codes.select { |c| c.start_with?('OD') || c.start_with?('PD094') }
  raise bad.inspect unless bad.empty?
  # And the note must say WHY, including the Q7b link - a wall family carrying
  # the same D/S letter as the base corners is evidence, not a coincidence.
  raise 'the Q7b link must be recorded' unless types.include?('Q7b')
  raise 'the 5x5 filler difference must be recorded' unless types.include?('5X5')
end

puts "\nwhere a unit's geometry starts - one answer, asked not recomputed"
check('base_z_mm is the plinth for a floor unit and the hanging height for a hung one') do
  raise Generator.base_z_mm(Registry.lookup('B80601')).to_s unless
    Generator.base_z_mm(Registry.lookup('B80601')) == Standards::PLINTH_H_MM
  raise Generator.base_z_mm(Registry.lookup('PB0625')).to_s unless
    Generator.base_z_mm(Registry.lookup('PB0625')) == Standards::WALL_MOUNT_BOTTOM_MM
end

puts "\nthe wall-hung option - printed p.548 (0.52.0)"

check('the family default is kept apart from what the object currently is') do
  # Same value in the registry row; they diverge only once somebody chooses.
  # Without the second name there is no way to tell a wall unit from a base
  # unit that has been hung, and the hanging height differs completely.
  base = Registry.lookup('B80601')
  wall = Registry.lookup('PB0625')
  raise base.inspect unless base['mounting'] == 'floor' && base['mounting_default'] == 'floor'
  raise wall.inspect unless wall['mounting'] == 'wall_hung' && wall['mounting_default'] == 'wall_hung'
  raise 'a wall unit hangs by nature' unless Generator.hangs_by_nature?(wall)
  raise 'a base unit never does' if Generator.hangs_by_nature?(base)
end

check('A CHOSEN HANG KEEPS THE RUN\'S WORKTOP LINE - it does not go up to 1400') do
  # The bug this exists to prevent: mount_bottom_mm ignored its argument and
  # returned WALL_MOUNT_BOTTOM_MM, so hanging a base unit would have put it at
  # wall-cabinet height. Its worktop is its neighbours\' worktop, so its bottom
  # sits where the plinth would have - and the gap that opens underneath, equal
  # to the plinth, is the whole point of the option.
  hung_base = Registry.lookup('B80601').merge('mounting' => 'wall_hung')
  raise Generator.mount_bottom_mm(hung_base).to_s unless
    Generator.mount_bottom_mm(hung_base) == Generator.plinth_h_mm(hung_base)
  raise 'and that is 100 for H.78' unless Generator.mount_bottom_mm(hung_base) == 100
  raise 'the carcass starts there too' unless Generator.base_z_mm(hung_base) == 100
  # A real wall unit is untouched by any of this.
  raise 'a wall unit still takes the project height' unless
    Generator.mount_bottom_mm(Registry.lookup('PB0625')) == Standards::WALL_MOUNT_BOTTOM_MM
end

check('a hung base unit is drawn with NO plinth, at the same height it had') do
  floor = Registry.lookup('B80601')
  hung  = floor.merge('mounting' => 'wall_hung')
  raise 'standing, it has a plinth' unless Generator.plinth?(floor)
  raise 'hung, it has none' if Generator.plinth?(hung)
  raise 'and the carcass does not move' unless
    Generator.base_z_mm(hung) == Generator.base_z_mm(floor)
end

check('who may be offered the option, and the three reasons for no') do
  raise 'a base cabinet may' unless Generator.wall_hung_available?(Registry.lookup('B80601'))
  raise 'a tall cabinet may'  unless Generator.wall_hung_available?(Registry.lookup('CR0631'))
  # 1 - it already hangs, so there is nothing to choose.
  raise 'a wall unit already hangs' if Generator.wall_hung_available?(Registry.lookup('PB0625'))
  # 2 - an appliance FRONT bolts to the client machine; it is fixed to no wall.
  raise 'a dishwasher door is not hung' if Generator.wall_hung_available?(Registry.lookup('V80730'))
  raise 'nor is a US fridge panel' if Generator.wall_hung_available?(Registry.lookup('CR9601'))
  raise 'nil must not blow up' if Generator.wall_hung_available?(nil)
end

check('THE PAGE CAN FORBID IT, and the flag is read even though nothing sets it') do
  # printed p.34 and p.37 print "not available wall hung" on three types -
  # a compact-oven base with a sheet-metal bottom, and the two 97 cm pull-out
  # table types. NONE of them is in this registry: those pages are not
  # extracted and rule 1 forbids inventing the rows. The mechanism is proved
  # here on a synthetic unit instead, so extracting the pages later is a data
  # change and not a code change.
  forbidden = Registry.lookup('B80601').merge('wall_hung' => false)
  raise 'the page must win' if Generator.wall_hung_available?(forbidden)
  # And it must be the explicit false that forbids, not merely a missing key.
  raise 'absence is not a prohibition' unless
    Generator.wall_hung_available?(Registry.lookup('B80601').merge('wall_hung' => nil))
end

check('THE FIRST CHOSEN COMPANION THIS ENGINE CAN PRODUCE') do
  # Contract v2 has carried origin: chosen since 17c20dd with nothing able to
  # make one. This is the first article that qualifies: the SAME code is
  # ordered whether the unit stands or hangs, and the difference travels as a
  # separate surcharge line - so no rule can rederive it, only a person.
  #
  # It does NOT contradict the sweep over all 180 codes further down, which
  # asserts that attributes_for never emits a chosen line. That check is about
  # what the generator produces BY ITSELF, and it must stay true: a chosen
  # line appears only when this method is asked, and asking is a decision.
  line = Generator.wall_hung_ref(Registry.lookup('B80601'))
  raise line.inspect unless line['code'] == '989410'
  raise 'it is CHOSEN, not implied' unless line['origin'] == 'chosen'
  raise 'one surcharge per unit, not per fixing' unless line['qty'] == 1 && line['um'] == 'PZ'
  raise 'it must cite its page' unless line['source_ref'].include?('548')
  # Four fixings for a tall, and the catalog prices it as a different article.
  raise 'a tall takes 989411' unless
    Generator.wall_hung_ref(Registry.lookup('CR0631'))['code'] == '989411'
  # Nothing that cannot hang produces a line.
  raise 'a wall unit orders no fixings' unless
    Generator.wall_hung_ref(Registry.lookup('PB0625')).nil?
end

check('the surcharge codes are the ones the page prints') do
  wh = Registry.data['modifications']['codes']['wall_hung']
  raise wh.inspect unless wh['base']['code'] == '989410' && wh['tall']['code'] == '989411'
  raise 'the source page must be cited' unless wh['source_ref'].include?('p.548')
  # A wall-hung base is NOT "without feet" - p.39 of the Project Guidelines is
  # explicit, and the drawing shows the foot bearing against the WALL. Losing
  # that sentence would invite a model with nothing at the bottom rear.
  raise 'the foot must be recorded' unless
    wh['construction_note'].include?('foot to stabilise')
  raise 'and the exception must say it is unenforced' unless
    wh['not_available_on']['enforcement'].include?('NOT ENFORCED')
end

puts "\nthe wall-hung option reaches geometry and the order (0.53.0)"

def hang_patch(code, on, extra = {})
  u = Registry.lookup(code)
  Panel.attributes_patch(u, { 'door_version' => '78', 'opening_method' => 'handle',
                              'hardware_mode' => 'client', 'wall_hung' => on }.merge(extra))
end

check('ticking it hangs the unit and orders the fixings') do
  patch = hang_patch('B80601', true)
  raise patch.inspect unless patch['mounting'] == 'wall_hung'
  raise 'it keeps the run worktop line' unless patch['mount_bottom_mm'] == 100
  line = patch['companion_refs'].find { |l| l['code'] == '989410' }
  raise patch['companion_refs'].inspect unless line
  raise 'and it is a CHOSEN line' unless line['origin'] == 'chosen'
end

check('UNTICKING IT PUTS THE UNIT BACK AND ERASES THE HANGING HEIGHT') do
  # The contract reconciles, so a key whose value goes away is DELETED. If it
  # were merely skipped, a unit put back on the floor would keep its old
  # mount_bottom_mm and the next rebuild would hang it again - the exact
  # accumulation bug 1932f20 was about, one layer up.
  patch = hang_patch('B80601', false)
  raise patch.inspect unless patch['mounting'] == 'floor'
  raise 'the hanging height must go' unless patch['mount_bottom_mm'].nil?
  raise 'and so must the fixings' if
    (patch['companion_refs'] || []).any? { |l| l['code'] == '989410' }

  # Proved through a real write/read round trip, not just on the patch hash.
  e = StubEntity.new
  Contract.write!(e, Generator.attributes_for(Registry.lookup('B80601'))
                              .merge(hang_patch('B80601', true)))
  raise 'it should be stored while hung' unless
    Contract.read(e)['mount_bottom_mm'] == 100
  Contract.write!(e, Contract.read(e).merge(hang_patch('B80601', false)))
  raise Contract.read(e).inspect unless Contract.read(e)['mount_bottom_mm'].nil?
  raise 'and the object says floor' unless Contract.read(e)['mounting'] == 'floor'
end

check('the panel REFUSES to hang what the catalog will not hang') do
  begin
    hang_patch('PB0625', true)
    raise 'a wall unit was allowed to be hung again'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('already hangs')
  end
  # A rule that lives only in the dialog is not a rule (rule 14): the refusal
  # is here, in the pure half, and not merely a hidden checkbox.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/80_panel.rb', __dir__))
  raise 'the check must be in the patch, not only in HTML' unless
    src.include?('Generator.wall_hung_available?(unit)')
end

check('a wall unit is untouched by the checkbox it never sees') do
  patch = Panel.attributes_patch(Registry.lookup('PB0625'),
                                 'door_version' => '78', 'opening_method' => 'handle',
                                 'hardware_mode' => 'client', 'wall_hung' => false)
  raise patch.inspect unless patch['mounting'] == 'wall_hung'
  raise 'and it keeps the project hanging height' unless
    patch['mount_bottom_mm'] == Standards::WALL_MOUNT_BOTTOM_MM
end

check('THE REBUILD ASKS ABOUT THE CHOSEN UNIT, NOT THE CATALOG ROW') do
  # The bug this prevents: Panel.apply looks the code up afresh, so a choice
  # stored on the object is invisible to the rebuild and a hung base unit is
  # redrawn standing on its plinth. Same shape as the gola pairing that was
  # lost for weeks.
  unit  = Registry.lookup('B80601')
  attrs = Generator.attributes_for(unit).merge(hang_patch('B80601', true))
  eff   = Generator.effective(unit, attrs)
  raise 'the overlay must carry the choice' unless eff['mounting'] == 'wall_hung'
  raise 'no plinth is drawn for it' if Generator.plinth?(eff)
  raise 'and the carcass keeps its height' unless Generator.base_z_mm(eff) == 100
  raise 'while the registry row is untouched' unless unit['mounting'] == 'floor'
  # Only what a PERSON can set is overlaid - an object may not out-vote the
  # registry about what article it is.
  liar = Generator.effective(unit, 'code' => 'NOPE', 'width_mm' => 9999)
  raise 'the catalog must win on facts' unless
    liar['code'] == 'B80601' && liar['width_mm'] == 600
  raise 'nil unit must not blow up' unless Generator.effective(nil, {}).is_a?(Hash)
end

check('the plinth has ONE writer, and the panel is not it') do
  # rebuild_plinth erases and redraws unconditionally; draw_plinth answers nil
  # when there is no plinth, which is what makes that safe. The panel must
  # hold no dimension, no material and no setback of its own - it used to add
  # PLINTH_H_MM itself, and that is how a rebuilt hanging front ended up on
  # the floor.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/80_panel.rb', __dir__))
  code = src.lines.reject { |l| l =~ /^\s*#/ }.join
  %w[PLINTH_SETBACK_MM PLINTH_T_MM PLINTH_H_MM].each do |const|
    raise "the panel computes the plinth itself (#{const})" if code.include?(const)
  end
  raise 'it must ask the generator' unless code.include?('Generator.draw_plinth')
  gen = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  builders = gen.lines.reject { |l| l =~ /^\s*#/ }.join.scan(/'PLINTH'/).size
  raise "the plinth box is built in #{builders} places, expected 1" unless builders == 1
end

check('the dialog is handed what it may offer, and what it would order') do
  st = Panel.selection_state(Registry.lookup('B80601'),
                             Generator.attributes_for(Registry.lookup('B80601')))
  raise 'a base unit may be hung' unless st['wall_hung_available']
  raise st['wall_hung_ref'].inspect unless st['wall_hung_ref'] == '989410'
  wall = Panel.selection_state(Registry.lookup('PB0625'),
                               Generator.attributes_for(Registry.lookup('PB0625')))
  raise 'a wall unit is offered nothing' if wall['wall_hung_available']
  raise 'and names no article' unless wall['wall_hung_ref'].nil?
end

check('and it reaches the ORDER as a chosen line') do
  attrs = Generator.attributes_for(Registry.lookup('B80601')).merge(hang_patch('B80601', true))
  row = Export.rows([attrs]).find { |r| r['code'] == '989410' }
  raise 'the surcharge must be an order line' unless row
  raise row.inspect unless row['qty'] == 1 && row['um'] == 'PZ'
  raise 'the order must say a person chose it' unless row['note'].to_s.include?('chosen')
end

puts "\nplinth height is a FAMILY fact, not a global constant (0.51.0)"

check('the family states its plinth, and the generator asks the object') do
  # Project Guidelines printed p.73 and p.82: "78 H. Cesar door" over
  # "10 Plinth H." H.84 prints 6 on p.90. So 100 is not a standard, it is
  # what THIS family happens to stand on, and Standards::PLINTH_H_MM is now
  # only the fallback for a family that has not said.
  raise 'H.78 must state its own plinth' unless
    Registry.lookup('B80601')['plinth_h_mm'] == 100
  raise 'and the generator must read it' unless
    Generator.plinth_h_mm(Registry.lookup('B80601')) == 100
  raise 'tall H.210 stands in the same run' unless
    Generator.plinth_h_mm(Registry.lookup('CR0631')) == 100
end

check('a family that says NOTHING falls back to the UCON standard, not to nil') do
  # Rule 7 says unknown is nil - but this is not unknown, it is undeclared,
  # and PLINTH_H_MM is a confirmed UCON decision that answers for it. Same
  # shape as `mounting || floor` one line above it in the lookup.
  raise Generator.plinth_h_mm({}).to_s unless
    Generator.plinth_h_mm({}) == Standards::PLINTH_H_MM
  raise 'nil must not blow it up' unless
    Generator.plinth_h_mm(nil) == Standards::PLINTH_H_MM
end

check('IT SURVIVES THE MERGE - three files share family H.78 and only one declares it') do
  # The loader merges non-unit_types keys LAST-FILE-WINS across every file
  # naming the same family (appliance_h78, base_h78, sink_base_h78 - and they
  # merge in that alphabetical order). plinth_h_mm is declared in base_h78
  # alone, deliberately, so there is one place to change it. This check is
  # what makes that safe: read it back through a code out of EACH file.
  {
    'B80601' => 'base_h78',
    'B80503' => 'sink_base_h78',
    'V80730' => 'appliance_h78'
  }.each do |code, file|
    got = Registry.lookup(code)['plinth_h_mm']
    raise "#{code} (#{file}) lost the family plinth: #{got.inspect}" unless got == 100
  end
end

check('ZERO IS A HEIGHT, and it means the carcass stands on the floor') do
  # Andriy, 2026-08-22: "ножку 5 мм высотой считаем за ноль." A shim-footed
  # base has no plinth and no gap worth drawing, so plinth_h_mm 0 must not be
  # mistaken for "not stated" - which is exactly what `|| Standards` would
  # have done, and why the fallback tests nil rather than truthiness.
  shim = Registry.lookup('B80601').merge('plinth_h_mm' => 0)
  raise 'zero must survive as zero' unless Generator.plinth_h_mm(shim) == 0
  raise 'nothing is drawn under it' if Generator.plinth?(shim)
  raise 'and the carcass sits on the floor' unless Generator.base_z_mm(shim) == 0
end

check('plinth? answers NO for two different reasons and the drawing cannot tell') do
  floor = Registry.lookup('B80601')
  hung  = Registry.lookup('PB0625')
  raise 'a floor unit on a stated plinth has one' unless Generator.plinth?(floor)
  raise 'a hung unit never meets the floor' if Generator.plinth?(hung)
  raise 'a shim-footed one meets it directly' if
    Generator.plinth?(floor.merge('plinth_h_mm' => 0))
end

check('the housing behind a panel starts at THIS family plinth, not at a global 100') do
  # niche_bottom_mm used to return Standards::PLINTH_H_MM outright, with a
  # comment saying the plinth height "is a standard and stays one". The H.84
  # drawings say it does not.
  u = Registry.lookup('CR9601').merge('plinth_h_mm' => 60)
  raise Generator.niche_bottom_mm(u).to_s unless Generator.niche_bottom_mm(u) == 60
end

check('nothing outside the asker reaches for the constant any more') do
  # The 100 was written out in five places in the generator. Exactly one may
  # name the constant now, and it is the fallback inside plinth_h_mm.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  code = src.lines.reject { |l| l =~ /^\s*#/ }.join
  hits = code.scan(/Standards::PLINTH_H_MM|s::PLINTH_H_MM/).size
  raise "the constant is read in #{hits} places, expected 1" unless hits == 1
end

check('the symbol renderer and the panel ask for it instead of working it out') do
  # The bug this guards: when wall units arrived, the generator and the symbol
  # renderer learned that a hung unit starts at its hanging height and the
  # properties panel did not - so re-applying a handle rebuilt a hanging front
  # down at plinth level. Three copies of a rule is three chances to update two.
  %w[70_symbols 80_panel].each do |file|
    src = File.read(File.expand_path("../src/ucon_cabinet_engine/core/#{file}.rb", __dir__))
    raise "#{file} computes the base height itself" if src.include?('::PLINTH_H_MM')
  end
end

check('row_datum_mm is a DIFFERENT question from base_z_mm, and answers it once') do
  # base_z_mm: where does the CARCASS begin (a floor unit begins on its plinth).
  # row_datum_mm: where does the ROW begin (the floor, or the hanging height).
  # For a floor unit the two deliberately disagree.
  floor = Registry.lookup('B80601')
  hung  = Registry.lookup('PD0631')
  raise Generator.row_datum_mm(floor).to_s unless Generator.row_datum_mm(floor) == 0
  raise Generator.row_datum_mm(hung).to_s unless
    Generator.row_datum_mm(hung) == Standards::WALL_MOUNT_BOTTOM_MM
  raise 'a floor unit must not confuse the two' if
    Generator.row_datum_mm(floor) == Generator.base_z_mm(floor)
end

check('a plan symbol rides with its row, and one line decides that') do
  # The bug: PLAN_Z_MM was an absolute height above the FLOOR, correct while
  # every unit stood on the floor. With two rows, a base unit and the wall unit
  # above it drew their swing arcs on the same millimetre, and the hung unit's
  # bounding box stretched to the floor to reach its own symbol.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/70_symbols.rb', __dir__))
  raise 'a plan symbol is still placed at an absolute height' if src.include?('PLAN_Z_MM.mm')
  raise 'the datum must be asked of the generator' unless src.include?('Generator.row_datum_mm')
  # Twice and no more: the constant's definition, and the ONE line that adds it
  # to the datum. A third occurrence is a second place deciding the same thing.
  raise "PLAN_Z_MM appears #{src.scan('PLAN_Z_MM').length} times" unless
    src.scan('PLAN_Z_MM').length == 2
end

puts "\ndoor version is family-scoped, not universal"
check('a family declares its own door versions, or has none') do
  base = Registry.lookup('B80601')['door_versions']
  raise base.inspect unless base && base['full_mm'] == 780 && base['gola_mm'] == 750
  raise 'the fact must cite its page' unless base['source_ref'].include?('p.36')

  # H.36 wall units are 360 tall. "78 or 75" is not a choice there, it is
  # nonsense - and the manifest always said the axis was per base-unit page.
  wall = Registry.lookup('PB0625')
  raise wall['door_versions'].inspect unless wall['door_versions'].nil?
  raise wall['height_mm'].to_s unless wall['height_mm'] == 360
end

check('gola is refused for a family that declares no gola version') do
  begin
    Panel.attributes_patch(Registry.lookup('PB0625'),
                           { 'door_version' => '75', 'hardware_ref' => 'GOL001' })
    raise 'a 750 front was accepted on a 360 tall wall unit'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('no gola door version')
  end
  # And a wall unit still takes an ordinary handle.
  p = Panel.attributes_patch(Registry.lookup('PB0625'),
                             { 'door_version' => '78', 'opening_method' => 'handle',
                               'hardware_mode' => 'factory', 'hardware_ref' => 'M00001' })
  raise p.inspect unless p['front_height_mm'] == 360 && p['opening_method'] == 'handle'
end

check('the base family is untouched: 75 still shortens the front to 750') do
  p = Panel.attributes_patch(Registry.lookup('B80601'),
                             { 'door_version' => '75', 'gola_system' => 'L-shaped' })
  raise p.inspect unless p['front_height_mm'] == 750 && p['opening_method'] == 'gola'
end

puts "\nthe shell stays cold (src/ucon_cabinet_engine/main.rb)"
check('the menu is an entry point, not a control panel') do
  shell = File.read(File.expand_path('../src/ucon_cabinet_engine/main.rb', __dir__))
  items = shell.scan(/menu\.add_item\('([^']+)'/).flatten
  # SketchUp cannot remove a menu item once added, so every one of these is
  # permanent for the session and costs a restart to change. The palette is the
  # day-to-day surface; the menu opens it and says what version this is.
  raise items.inspect unless items == ['Palette…', 'About']

  # Assert on what the shell CALLS, not on what it says: the comment explaining
  # the removals mentions the old items by name, and a prose match would fail on
  # its own explanation.
  %w[Units::B80601 Generator. Panel. Symbols.].each do |leak|
    raise "the shell reaches into #{leak}" if shell.include?(leak)
  end
end

check('the toolbar is one button, and its icons exist') do
  shell = File.read(File.expand_path('../src/ucon_cabinet_engine/main.rb', __dir__))
  raise 'no toolbar' unless shell.include?('UI::Toolbar.new')
  raise 'more than one toolbar button' unless shell.scan('toolbar.add_item').length == 1
  raise 'the toolbar must be restored or it never appears' unless
    shell.include?('toolbar.restore')

  # A missing icon file makes SketchUp drop the button silently.
  %w[ucon_24.png ucon_32.png].each do |icon|
    path = File.expand_path("../src/ucon_cabinet_engine/icons/#{icon}", __dir__)
    raise "missing icon #{icon}" unless File.exist?(path)
    raise "#{icon} is not a PNG" unless File.binread(path, 8) == "\x89PNG\r\n\x1A\n".b
  end
end

puts "\nplacement rules (core/22_placement.rb - no SketchUp)"
Placement = UCON::CabinetEngine::Placement

check('two vertical walls give a corner; two parallel ones give nothing') do
  # Walls at y = 0 and x = 0, both facing into the room.
  c = Placement.corner_point([0.0, 0.0, 0.0], [0.0, -1.0, 0.0],
                             [0.0, 0.0, 0.0], [-1.0, 0.0, 0.0])
  raise c.inspect unless c.map { |v| v.round(6) } == [0.0, 0.0, 0.0]

  # Offset walls: y = 2000 and x = 3000 cross at (3000, 2000).
  c = Placement.corner_point([0.0, 2000.0, 0.0], [0.0, -1.0, 0.0],
                             [3000.0, 0.0, 0.0], [-1.0, 0.0, 0.0])
  raise c.inspect unless c.map { |v| v.round(6) } == [3000.0, 2000.0, 0.0]

  # A wall at 45 degrees still crosses, because nothing here assumes a right
  # angle - the same reason the straight-unit frame works on any wall.
  d = Math.sqrt(0.5)
  c = Placement.corner_point([0.0, 0.0, 0.0], [0.0, -1.0, 0.0],
                             [1000.0, 0.0, 0.0], [-d, d, 0.0])
  raise c.inspect unless c.map { |v| v.round(3) } == [1000.0, 0.0, 0.0]

  # Parallel walls are not a corner, and must not be forced into one.
  raise 'parallel' unless Placement.corner_point([0.0, 0.0, 0.0], [0.0, -1.0, 0.0],
                                                 [0.0, 600.0, 0.0], [0.0, 1.0, 0.0]).nil?
end

check('the wall, not the door, decides which article the corner takes') do
  # The unit can only lie where the wall continues from the corner.
  raise 'wall runs +x' unless Placement.execution_for(2400.0) == 'right'
  raise 'wall runs -x' unless Placement.execution_for(-2400.0) == 'left'
  raise 'no run is no answer' unless Placement.execution_for(0.0).nil?
  raise 'no run is no answer' unless Placement.execution_for(nil).nil?
end

check('the node seats ONE FRONT GAP off the corner, wasted end first') do
  # REWRITTEN 2026-08-24. The numbers here used to be 100 and -1000, and they
  # were right for the decision this check was written under: seat the printed
  # node raw. That decision was wrong in a real kitchen - the neighbouring
  # run's front missed the outer face of the 8x8 filler by FRONT_GAP_MM,
  # because the printed node is a carcass dimension and our fronts stand proud
  # of the carcass plane. See Placement.corner_origin for the whole reason.
  #
  # EVERY EXPECTATION BELOW IS COMPUTED FROM Standards::FRONT_GAP_MM. A literal
  # 3 in the placement code would pass a literal 3 written here, and the two
  # would go stale together on the day the gap changes.
  # WRITTEN THREE TIMES IN ONE DAY AND BACK WHERE IT STARTED. Mid-day this
  # expected one FRONT_GAP_MM of clear space at the corner, because a real
  # kitchen showed the neighbouring run's front missing the outer face of the
  # 8x8 by 3 mm and the SEATING looked like the culprit. It was not: the
  # mismatch runs along the wall, and the body that had to move was the filler,
  # whose leg along the width overshot by exactly one gap. The factory's own
  # export of estimate 2026/30831 seats the corner carcass at exactly
  # nominal - carcass from the perpendicular wall, with nothing added.
  gap  = 0.0
  node = 1000.0

  # corner at the origin, wall facing -y, B7091D: right, carcass 900,
  # node 1000x430, d.350.
  o = Placement.corner_origin([0.0, 0.0, 0.0], [0.0, -1.0, 0.0],
                              350.0, 900.0, 1000.0, 'right')
  raise o.inspect unless o.map { |v| v.round(6) } == [node - 900.0, -350.0, 0.0]

  # Its sibling on the other wall of the same corner runs the other way.
  o = Placement.corner_origin([0.0, 0.0, 0.0], [0.0, -1.0, 0.0],
                              350.0, 900.0, 1000.0, 'left')
  raise o.inspect unless o.map { |v| v.round(6) } == [-node, -350.0, 0.0]

  # The invariant this all exists for, now with the gap in it: whichever
  # execution, the end of the node FACING the corner is the wasted end, never
  # the carcass - and it stands off the corner by exactly one gap.
  f = Placement.frame([0.0, -1.0, 0.0])
  { 'right' => [-100.0, 0.0], 'left' => [900.0, 1000.0] }.each do |exec, (lo, hi)|
    o = Placement.corner_origin([0.0, 0.0, 0.0], [0.0, -1.0, 0.0],
                                350.0, 900.0, 1000.0, exec)
    edges = [lo, hi].map { |x| Placement.dot(Placement.add(o, Placement.scale(f[:x], x)), f[:x]).round(6) }
    near = edges.min_by(&:abs)
    raise "#{exec}: the wasted end must touch the corner, got #{near}" unless
      near.abs.round(6) == gap.to_f.round(6)
  end
end

check('a wall runs one dominant way from the corner, and that picks the article') do
  # A wall from x=0 to x=3000 with the corner at 0: it runs +3000.
  raise Placement.wall_run(0.0, 0.0, 3000.0).to_s unless
    Placement.wall_run(0.0, 0.0, 3000.0) == 3000.0
  # Mirrored.
  raise Placement.wall_run(0.0, -3000.0, 0.0).to_s unless
    Placement.wall_run(0.0, -3000.0, 0.0) == -3000.0
  # A wall overhanging its corner by its own thickness must not flip the answer:
  # the DOMINANT side wins, not merely a non-zero one.
  raise Placement.wall_run(0.0, -100.0, 3000.0).to_s unless
    Placement.wall_run(0.0, -100.0, 3000.0) == 3000.0
  raise 'a corner outside the wall has no run' unless
    Placement.wall_run(5000.0, 0.0, 3000.0).nil?

  raise 'the run must choose the article' unless
    Placement.execution_for(Placement.wall_run(0.0, -100.0, 3000.0)) == 'right'
  raise 'the run must choose the article' unless
    Placement.execution_for(Placement.wall_run(0.0, -3000.0, 100.0)) == 'left'
end

check('one measure of what a unit occupies serves both the run and the snap') do
  raise 'straight' unless Placement.span_mm(width_mm: 600) == [0.0, 600.0]
  # The corner's node, not its carcass: the wasted end is space that must stay
  # free, so a neighbour has to begin past it.
  raise 'left' unless Placement.span_mm(carcass_mm: 900, nominal_mm: 1000,
                                        execution: 'left') == [0.0, 1000.0]
  raise 'right' unless Placement.span_mm(carcass_mm: 900, nominal_mm: 1000,
                                         execution: 'right') == [-100.0, 900.0]
  raise 'unknown is nil' unless Placement.span_mm(carcass_mm: 900).nil?
  # run_extent_mm is now the high end of the same span - one rule, two callers.
  %w[left right].each do |exec|
    span = Placement.span_mm(carcass_mm: 900, nominal_mm: 1000, execution: exec)
    raise exec unless Placement.run_extent_mm(carcass_mm: 900, nominal_mm: 1000,
                                              execution: exec) == span[1]
  end
end

check('the sibling article is looked up, never spelled') do
  raise 'S->D' unless Registry.sibling_execution_code('B7091S') == 'B7091D'
  raise 'D->S' unless Registry.sibling_execution_code('B7091D') == 'B7091S'
  raise 'a straight unit has no sibling' unless
    Registry.sibling_execution_code('B80601').nil?

  # Every corner article must have one: a U-shaped kitchen needs both letters of
  # a size, so a size with only one execution would be a hole in the catalog.
  corners = Registry.catalog.select { |c| c['corner_geometry'] }
  raise corners.length.to_s unless corners.length == 18
  corners.each do |c|
    twin = Registry.sibling_execution_code(c['code'])
    raise "#{c['code']} has no sibling" unless twin

    a = Registry.lookup(c['code'])
    b = Registry.lookup(twin)
    raise "#{c['code']} sibling differs in size" unless
      a['corner_geometry'] == b['corner_geometry'] &&
      a['carcass_length_mm'] == b['carcass_length_mm'] &&
      a['door_width_mm'] == b['door_width_mm'] &&
      a['execution'] != b['execution']
    raise "#{c['code']} is its own sibling" if twin == c['code']
  end
end

check('continuing a run past a corner steps over the node, not the carcass') do
  # A straight unit reaches its width.
  raise 'straight' unless Placement.run_extent_mm(width_mm: 600) == 600.0

  # B7091S and B7091D are the same 1000x430 node with a 900 carcass: 100 mm of
  # unreachable corner. The execution letter decides which side that 100 mm is
  # on, and therefore how far the next unit has to step.
  s_unit = Registry.lookup('B7091S')
  d_unit = Registry.lookup('B7091D')
  raise 'fixture drift' unless s_unit['execution'] == 'left' &&
                               d_unit['execution'] == 'right' &&
                               s_unit['carcass_length_mm'] == 900 &&
                               s_unit['corner_geometry'] == '1000x430'

  left = Placement.run_extent_mm(carcass_mm: 900, nominal_mm: 1000, execution: 'left')
  raise left.to_s unless left == 1000.0   # wasted space sits on +x: step over it

  right = Placement.run_extent_mm(carcass_mm: 900, nominal_mm: 1000, execution: 'right')
  raise right.to_s unless right == 900.0  # wasted space sits on -x: carcass is the reach
end

check('a reach that cannot be measured is nil, never zero') do
  # The bug: width_mm is absent on a corner unit by contract, and .to_f turned
  # that into 0.0, so the next unit landed exactly on top of the corner one.
  raise 'nil.to_f is still 0.0 - that is the trap' unless nil.to_f.zero?
  raise 'must be nil' unless Placement.run_extent_mm(carcass_mm: 900).nil?
  raise 'must be nil' unless Placement.run_extent_mm.nil?
  raise 'must be nil' unless
    Placement.run_extent_mm(nominal_mm: 1000, execution: 'left').nil?
end

check('a corner is placeable now, and refused only if it is under-specified') do
  corner = Generator.attributes_for(Registry.lookup('B7091D'))
  # Until 2026-08-20 this was refused for being a corner. It is now placed - it
  # needs a corner rather than a wall, and the wall decides which article it is.
  raise Placement.refusal_for(corner).to_s unless Placement.refusal_for(corner).nil?
  raise corner.inspect unless corner['corner_geometry'] && corner['width_mm'].nil?

  # A corner with nothing to seat is still refused, and says why.
  bare = { 'code' => 'X', 'geometry_kind' => 'corner' }
  raise 'a corner with no geometry must be refused' unless
    Placement.refusal_for(bare).to_s.include?('no corner_geometry')

  raise 'a straight unit must be placeable' unless
    Placement.refusal_for(Generator.attributes_for(Registry.lookup('B80601'))).nil?
  raise 'a bare component must be refused' unless
    Placement.refusal_for({ 'code' => 'X', 'geometry_kind' => 'linear' })
end

check('a wall is a horizontal normal, a floor is a vertical one') do
  # The three normals actually measured in SketchUp during the probes.
  raise 'side face' unless Placement.wall?([1.0, 0.0, 0.0])
  raise 'other wall' unless Placement.wall?([0.0, -1.0, 0.0])
  raise 'top face'   unless Placement.floor?([0.0, 0.0, 1.0])
  raise 'a floor must not read as a wall' if Placement.wall?([0.0, 0.0, 1.0])
  # A 45-degree roof is neither, and must not be mistaken for either.
  slope = [0.0, Math.sqrt(0.5), Math.sqrt(0.5)]
  raise 'slope' if Placement.wall?(slope) || Placement.floor?(slope)
end

check('the frame is orthonormal and right-handed at any wall angle') do
  [[0.0, -1.0, 0.0], [1.0, 0.0, 0.0], [0.6, 0.8, 0.0], [-0.3, 0.9, 0.0]].each do |n|
    f = Placement.frame(n)
    x, y, z = f[:x], f[:y], f[:z]
    [[x, y], [y, z], [x, z]].each do |a, b|
      raise "#{n.inspect} not orthogonal" unless Placement.dot(a, b).abs < 1e-9
    end
    [x, y, z].each do |v|
      raise "#{n.inspect} not unit" unless (Placement.dot(v, v) - 1.0).abs < 1e-9
    end
    # x cross y must be z, not minus z - a left-handed frame would mirror the
    # unit and put its front against the wall.
    handed = Placement.cross(x, y)
    raise "#{n.inspect} left-handed" unless
      Placement.sub(handed, z).all? { |c| c.abs < 1e-9 }
    # The depth axis points INTO the wall.
    raise "#{n.inspect} depth axis" unless Placement.dot(y, Placement.normalize(n)) < -0.999
  end
end

check('the back plane lands on the wall and the RIGHT end sits at the cursor') do
  wall_pt = [0.0, 2000.0, 0.0]
  normal  = [0.0, -1.0, 0.0]
  depth   = 620.0
  width   = 600.0

  o = Placement.origin_on_wall(wall_pt, normal, depth, width)
  f = Placement.frame(normal)

  # The far-right corner of the carcass: local (width, depth, 0).
  corner = Placement.add(Placement.add(o, Placement.scale(f[:x], width)),
                         Placement.scale(f[:y], depth))
  raise corner.inspect unless Placement.sub(corner, wall_pt).all? { |c| c.abs < 1e-9 }

  # And the whole back edge is on the wall plane, not just that corner.
  back_left = Placement.add(o, Placement.scale(f[:y], depth))
  raise back_left.inspect unless (back_left[1] - 2000.0).abs < 1e-9

  # The unit extends to the LEFT of the held corner, never to the right.
  raise o.inspect unless o[0] < corner[0]
end

check('a joint closes to the nearest end, from either side') do
  # Neighbour occupying 0..600 along the wall; we sit at 700..1300.
  raise 'left end onto their right' unless
    Placement.pull(700.0, 1300.0, [[0.0, 600.0]]) == -100.0
  # Mirrored: they are to our right.
  raise 'right end onto their left' unless
    Placement.pull(700.0, 1300.0, [[1400.0, 2000.0]]) == 100.0
  # Two candidates, both in range: the smaller correction wins.
  best = Placement.pull(680.0, 1280.0, [[0.0, 600.0], [1350.0, 2000.0]])
  raise best.inspect unless best == 70.0
  # Out of range is nil, not zero - "no joint" must not read as "already flush".
  raise 'too far' unless Placement.pull(1000.0, 1600.0, [[0.0, 600.0]]).nil?
  raise 'no neighbours' unless Placement.pull(0.0, 600.0, []).nil?
end

check('a neighbour has to earn it: mounting, direction and wall plane') do
  raise 'same row' unless Placement.same_row?('floor', 'floor', 1.0, 5.0)
  raise 'a wall unit must not butt a base unit' if
    Placement.same_row?('wall_hung', 'floor', 1.0, 0.0)
  raise 'a return wall must not pull the row' if
    Placement.same_row?('floor', 'floor', 0.5, 0.0)
  raise 'another run at another depth must not pull the row' if
    Placement.same_row?('floor', 'floor', 1.0, 120.0)
  # Symbol vs string must not decide a geometric question.
  raise 'string/symbol' unless Placement.same_row?(:floor, 'floor', 1.0, 0.0)
end

check('the rule set stays free of SketchUp') do
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/22_placement.rb', __dir__))
  offenders = src.scan(/\b(?:Sketchup|Geom|UI)\b/).uniq
  raise offenders.inspect unless offenders.empty?
end

if defined?(UCON::CabinetEngine::Palette)
  Palette = UCON::CabinetEngine::Palette
  check('picker HTML renders gaps as inert rows, never as buttons') do
    html = Palette.picker_html(Registry.catalog, Registry.gaps)
    raise 'no ghost rows' unless html.include?("class='ghost'") || html.include?('ghost')
    ghost_js = html[/function ghosts\(.*?\n              \}/m].to_s
    raise 'a gap row must not be clickable' if ghost_js.include?('onclick')
    raise 'gaps not injected' unless html.include?('var GAPS =')
    %w[p.37 H.\ 84].each { |frag| raise "missing #{frag}" unless html.include?(frag.delete('\\')) }
  end
  check('the picker offers a class we hold nothing in') do
    # Without this the wall chapter is invisible: the class level used to be
    # derived from the registry alone, so a class with no extracted unit was
    # skipped by autoAdvance and its grey rows were unreachable.
    html = Palette.picker_html(Registry.catalog, Registry.gaps)
    raise 'class level still derived from CAT alone' unless html.include?('function classes()')
    raise 'the class list must merge the map' unless
      html.include?("GAPS.map(function(g){return g['class'];})")
    raise 'a class we hold nothing in must say so' unless html.include?("'catalog only'")
    raise 'the wall chapter never reached the dialog' unless html.include?('Wall units H. 36')
  end
  check('the corner picker offers a size, not a hand') do
    html = Palette.picker_html(Registry.catalog, Registry.gaps)
    # The execution used to be a button of its own: 9 sizes x 2 letters = 18.
    raise 'the picker still offers the execution as a choice' if
      html.include?("'<br><small>' + c.execution")
    raise 'the size button must say what decides the hand' unless
      html.include?('the wall picks the hand')
  end
  check('the properties dialog does not hard-code 78 and 75') do
    html = Panel.html
    raise 'a literal door height is still written into the HTML' if
      html.include?('78 — full front') || html.include?('75 — gola')
    raise 'the fieldset must be addressable so it can be hidden' unless
      html.include?('id="dvFs"')
  end
  puts "\ninches are a way of READING a size, never of storing one"

check('the picker carries a units switch, and the palette does not') do
  html = Palette.picker_html(Registry.catalog, Registry.gaps)
  raise 'no units button' unless html.include?('id="units"')
  raise 'the switch must sit beside the search field' unless html.include?('class="srow"')
  raise 'the switch must be remembered on the Ruby side' unless
    html.include?("sketchup.units(INCH ? 'on' : 'off')")
  # The palette is a different dialog with a different job. A stray reference
  # there would throw on load, where nothing would report it.
  raise 'the units switch leaked into the palette' if Palette.html.include?('id="units"')
end

check('the switch has an initial state, so reopening does not forget it') do
  off = Palette.picker_html(Registry.catalog, Registry.gaps, false)
  on  = Palette.picker_html(Registry.catalog, Registry.gaps, true)
  raise 'INITIAL_INCH not injected' unless off.include?('var INITIAL_INCH = false')
  raise 'INITIAL_INCH not injected' unless on.include?('var INITIAL_INCH = true')
  raise 'the button must arrive already lit' unless
    on.include?("if(INCH) document.getElementById('units').className = 'on'")
end

check('a NOMINAL inch size is read, a converted one is marked') do
  # The rule the whole feature turns on. 610 mm is the catalog's rounding of
  # 24 inches (609,6); converting it back gives 24 1/16", which is not what
  # anyone ordered. So a nominal is LOOKED UP and returns before any
  # arithmetic happens - the same rule as the width index.
  html = Palette.picker_html(Registry.catalog, Registry.gaps, true)
  a = html.index('function inchLabel')
  b = html.index('function toggleUnits')
  raise 'inchLabel missing' unless a && b && b > a

  js = html[a...b]
  nominal_at = js.index('String(nominal)')
  convert_at = js.index('25.4')
  raise 'the nominal branch must come FIRST' unless nominal_at && convert_at &&
                                                    nominal_at < convert_at
  raise 'a conversion must carry a tilde' unless js.include?("\u2248")
  # ...and the nominal branch must not.
  raise 'a nominal must not be marked approximate' if
    js[0...nominal_at].include?("\u2248")
  raise 'the double prime must be a real character, not an entity' unless
    js.include?("\u2033")
end

puts "\nUSA elements, printed p.418 - the first US article and the first tall row"

check('p.418 is extracted whole: 8 codes, two types, four widths') do
  rows = Registry.catalog.select { |c| c['section'] == 'USA elements | for tall units H. 210' }
  raise rows.length.to_s unless rows.length == 8
  by_type = rows.group_by { |r| r['type_key'] }.map { |k, v| [k, v.length] }.sort
  raise by_type.inspect unless by_type == [['usa_fridge_door', 4], ['usa_wine_cooler_door', 4]]
  raise rows.map { |r| r['width_mm'] }.uniq.sort.inspect unless
    rows.map { |r| r['width_mm'] }.uniq.sort == [457, 610, 762, 914]
  raise 'every one is 2100 tall' unless rows.map { |r| r['height_mm'] }.uniq == [2100]
  rows.each { |r| Contract.validate!(Generator.attributes_for(Registry.lookup(r['code']))) }
end

check('the inch switch finally has real data behind it') do
  # Until this page landed, nothing in the registry carried a nominal and every
  # inch label was a conversion with a tilde. These eight are the first sizes
  # the catalog itself states in inches.
  rows = Registry.catalog.select { |c| c['section'] == 'USA elements | for tall units H. 210' }
  raise 'a US row without a nominal' unless rows.all? { |r| r['nominal_in'] }
  raise rows.map { |r| r['nominal_in'] }.uniq.sort.inspect unless
    rows.map { |r| r['nominal_in'] }.uniq.sort == [18, 24, 30, 36]
  # And each nominal must match its own width, not just be present.
  rows.each do |r|
    raise "#{r['code']}: #{r['width_mm']} is not #{r['nominal_in']} in" unless
      (r['width_mm'] - (r['nominal_in'] * 25.4)).abs <= 1.0
  end
end

check('there is ONE front line, and everything in a run asks for it') do
  # A panel is flush with its neighbours because both ask front_y_mm, not
  # because two expressions happen to agree. It was written out twice in
  # 60_generator and a third time in 70_symbols.
  raise 'front_y_mm missing' unless Generator.respond_to?(:front_y_mm)
  raise Generator.front_y_mm.to_s unless
    Generator.front_y_mm == -(Standards::FRONT_GAP_MM + Standards::FRONT_T_MM)
  # Four copies existed: two in 60_generator, one in 70_symbols, one in
  # 80_panel. The definition itself is the only place the sum may be written.
  %w[60_generator 70_symbols 80_panel].each do |file|
    src = File.read(File.expand_path("../src/ucon_cabinet_engine/core/#{file}.rb", __dir__))
    longhand = src.scan(/FRONT_GAP_MM \+ (?:s::|Standards::)FRONT_T_MM/).length
    allowed  = file == '60_generator' ? 1 : 0
    raise "#{file} writes the front line out longhand #{longhand} time(s)" unless
      longhand == allowed
  end
end

check('the plinth line carries on under a fridge panel AND under a dishwasher') do
  # OURS, not the catalog's: nothing on printed p.418 mentions a plinth. It is
  # drawn so the plinth line does not BREAK on the drawing where a machine
  # stands in the run.
  #
  # REVERSED 2026-08-24. This check used to read "and stops at a dishwasher",
  # asserting that the dishwasher panel must NOT carry it, with the reason
  # given as "the plinth in front of that machine really is cut away". The
  # observation was true and it was answering the wrong question: cut away is
  # what gets BUILT, unbroken is what gets DRAWN. The flag is about the
  # drawing, so it is now true for both.
  raise 'a US fridge panel must carry the run plinth' unless
    Registry.lookup('CR9700')['plinth_continues'] == true
  %w[V80530 V80630 V80730 V88559 V88566 V88569].each do |code|
    raise "#{code} must carry it too" unless
      Registry.lookup(code)['plinth_continues'] == true
  end
  # An ordinary cabinet never needs the flag: it gets a plinth by standing on
  # the floor, and saying so twice would be two places to disagree.
  raise 'a cabinet must not need the flag' if Registry.lookup('B80601')['plinth_continues']

  note = Registry.data['families']['USA Tall H.210']['plinth_note']
  raise 'the decision must admit whose it is' unless note.include?("OURS, NOT THE CATALOG'S")
  raise 'the reason must be the drawing, not the joinery' unless note.include?('BREAK')
  # 2026-08-24: this used to demand the note name p.47 as the EXCEPTION.
  # It is no longer an exception - it is the same answer - so what the
  # note must still carry is the pointer, not the word.
  raise 'the dishwasher must still travel with it' unless note.include?('p.47')
end

check('a front is drawn NOMINAL: no reveal is ever deducted') do
  # A 600 base unit is drawn with a 600 door; a 30-inch panel is drawn 762.
  # The real panel is slightly narrower and the shortfall is set by the
  # APPLIANCE's specification, not by Cesar - so it is not ours to draw. These
  # are not manufacturing drawings, and a nominal run reads cleanly in LayOut.
  %w[CR9700 CR9901 B80601 V80730].each do |code|
    u = Registry.lookup(code)
    slabs = Generator.front_slabs(u)
    raise "#{code}: #{slabs.inspect}" unless slabs.length == 1
    raise "#{code}: front #{slabs.first[:w_mm]} vs unit #{u['width_mm']}" unless
      slabs.first[:w_mm] == u['width_mm']
  end
end

check('the height needs no customisation, and the note carries the arithmetic') do
  notes = Registry.data['families']['USA Tall H.210']['representation_notes'].join(' ')
  raise 'the reveal rule is not recorded' unless notes.include?('NEVER NET')
  raise "the appliance must be named as the reveal's owner" unless
    notes.include?("APPLIANCE'S OWN SPECIFICATION")
  # 84 in = 2133,6; a tall unit is 2100 + 100 plinth = 2200; the unit is TALLER
  # than the appliance, so the door needs nothing done to it.
  raise 'the 84-inch figure is missing' unless notes.include?('2133,6')
  raise 'the 2200 overall is missing' unless notes.include?('2200')
  raise 'the leftover must point at the closing panel, not the door' unless
    notes.include?('66,4') && notes.include?('NOT extracted')
end

check('the swing PROJECTION is parked, while the hand itself is drawn') do
  # Three different things, and only the middle one is settled:
  #   the ORDER  - no hand, ever. The factory has no part in it.
  #   the HAND   - drawn, in the elevation, because nothing else can carry it.
  #   the SWING  - parked until appliances are modelled; it is the machine's.
  n = Registry.data['families']['USA Tall H.210']['unit_types']['usa_fridge_door']['notes']
  raise 'the order half must be explicit' unless n.include?('THE ORDER CARRIES NO HAND')
  raise 'the drawing half must be explicit' unless
    n.include?('THE DRAWING MUST CARRY IT ANYWAY')
  raise 'the projection must stay parked' unless n.include?('stays PARKED')
  raise 'a parked question needs a date' unless n.include?('Parked 2026-08-21')
end

check('a fridge door is a PANEL, and its depth is a thickness') do
  # Same relationship the dishwasher door has to its machine: it faces the
  # client's appliance. depth_mm is the front thickness, NOT a carcass depth,
  # and a 2100 x 914 object with a 620 depth would be a fiction.
  rows = Registry.catalog.select { |c| c['section'] == 'USA elements | for tall units H. 210' }
  raise rows.map { |r| r['depth_mm'] }.uniq.inspect unless
    rows.map { |r| r['depth_mm'] }.uniq == [Standards::FRONT_T_MM]
  rows.each do |r|
    a = Generator.attributes_for(Registry.lookup(r['code']))
    raise "#{r['code']}: #{a['object_class']}" unless a['object_class'] == 'appliance_front'
  end
end

check('a US fridge panel shows its hand in the ELEVATION and nowhere else') do
  # The hand cannot reach the installer any other way: the estimate has no
  # field for it, and fridges hinge one way while freezers hinge the other, so
  # a swapped pair is discovered on site with the hinges on the wrong edge.
  # The elevation is the only place the information can live.
  u = Registry.lookup('CR9700')
  raise 'the drawing must be able to state a hand' unless u['handed'] == true
  raise 'no hinge axis may be invented' if u['front_layout'].key?('hinge_axis')
  raise 'the hand must be elevation-only' unless
    u['front_layout']['hand_shown'] == 'elevation_only'
  n = Registry.data['families']['USA Tall H.210']['unit_types']['usa_fridge_door']['notes']
  raise 'both markets must be described' unless
    n.include?('INSIDE a cabinet') && n.include?('DIRECTLY on the appliance')
  raise 'the real-world reason must survive' unless
    n.include?('freezers') && n.include?('hinges have to be moved')
end

check('elevation-only means the plan and the open leaf are BOTH skipped') do
  # Two places had to be taught it, and a symbol that leaks into the plan
  # asserts a swing path we do not know.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/70_symbols.rb', __dir__))
  raise "the rule must be honoured twice, found #{src.scan("'elevation_only'").length}" unless
    src.scan("'elevation_only'").length == 2
  raise 'the open leaf must bail out' unless
    src.include?("return if layout['hand_shown'] == 'elevation_only'")
  raise 'the plan symbol must bail out' unless
    src.include?("next if layout['hand_shown'] == 'elevation_only'")
end

check('the hinge_side axis records where it does NOT apply') do
  n = Registry.data['order_axes_outside_code']['hinge_side']['note']
  raise 'the US exception is not recorded beside the axis' unless
    n.include?('DOES NOT EXIST AT ALL FOR A US APPLIANCE PANEL')
  raise 'the rule must be actionable' unless
    n.include?('never be ORDERED for an appliance_front')
  # Absent from the ORDER, present on the DRAWING - and the note must say both,
  # or the next reader will delete one of them as a contradiction.
  raise 'the drawing half must sit beside the order half' unless
    n.include?('THE DRAWING IS A SEPARATE MATTER')
  # The dishwasher panel is bottom-hung: it has no left or right to state.
  raise 'the dishwasher panel must not be handed' if Registry.lookup('V80730')['handed']
end

check('the two unmodelled restrictions on the wine cooler door survive') do
  n = Registry.data['families']['USA Tall H.210']['unit_types']['usa_wine_cooler_door']['notes']
  # A surcharge with no article code - never invented as a companion, the same
  # treatment Servo Drive gets on the wall pages.
  raise 'the 234 surcharge is lost' unless n.include?('234 points')
  raise 'it must say it has no code' unless n.include?('NO article code')
  # A finish prohibition, and finish is a level the engine does not model.
  raise 'the finish prohibition is lost' unless n.include?('Metal doors')
  raise 'M1.6 must be named as its future home' unless n.include?('M1.6')
  raise 'no companion may have been invented for the surcharge' unless
    Generator.attributes_for(Registry.lookup('CR9701'))['companion_refs'].nil?
end

check('a fabrication limit carries its source and its SCOPE, not just a number') do
  # 1200 mm came from Elda in writing, about one panel on one cabinet. Recording
  # the number without recording what she was looking at is how a caution turns
  # into a law - the same mistake the corner hand rule made.
  fl = Registry.data['fabrication_limits']
  raise 'fabrication_limits missing' unless fl

  w = fl['front_panel_max_width_mm']
  raise w.inspect unless w['value'] == 1200
  raise 'trust level missing' unless w['trust'] == 'CONTROL'
  raise 'the source must be named' unless w['source'].include?('2026-08-07')
  raise 'her words must survive verbatim' unless w['verbatim'].include?('max 1200mm wide')
  raise 'the open scope must be recorded' unless w['scope_open'].include?('hood cabinet')
  # It is NOT enforced anywhere yet, and the note must say so rather than let
  # someone assume the generator is already checking.
  raise 'the status must admit it is not wired' unless
    fl['status_note'].include?('NOT WIRED')
end

check('the two 2026-08-07 limits are not confused with each other') do
  fl = Registry.data['fabrication_limits']
  d  = fl['floor_to_ceiling_swing_door_max_mm']
  raise d.inspect unless d['width'] == 850 && d['height'] == 2780
  raise 'it must say it is a different product' unless
    d['note'].include?('different product')
  # A cabinet front and a floor-to-ceiling swing panel are both "panels" in
  # conversation and neither limit applies to the other.
  raise 'the two limits must not share a number' if
    d['width'] == fl['front_panel_max_width_mm']['value']
end

check('a nominal inch size is LOOKED UP, never computed') do
  n = ->(mm) { Registry.nominal_in(mm) }
  { 457 => 18, 610 => 24, 762 => 30, 914 => 36, 1067 => 42, 1219 => 48 }.each do |mm, inch|
    raise "#{mm} -> #{n.call(mm).inspect}" unless n.call(mm) == inch
  end
  # Every metric width in the catalog must resolve to NOTHING. If one ever
  # collided, a metric unit would start claiming an inch size it never had.
  usa    = Registry.catalog.select { |c| c['section'].to_s.start_with?('USA elements') }
  metric = Registry.catalog - usa
  colliding = metric.map { |c| c['width_mm'] }.compact.uniq.select { |w| n.call(w) }
  raise "metric widths claiming a nominal: #{colliding.inspect}" unless colliding.empty?
  # ...and every USA row must actually get one, or the switch is decorative.
  raise 'a USA row without a nominal' unless usa.any? && usa.all? { |c| c['nominal_in'] }
  # And the lookup must not be a division in disguise. 610 / 25,4 is 24 1/16.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/50_registry.rb', __dir__))
  body = src[src.index('def nominal_in')...src.index('def catalog(')]
  raise 'the nominal is being computed' if body.include?('25.4')
end

check('the six nominal widths are catalog data, with the page that prints them') do
  nw = Registry.data['nominal_widths_in']
  raise 'nominal_widths_in missing' unless nw && nw['mm_to_in']
  raise nw['mm_to_in'].inspect unless nw['mm_to_in'].length == 6
  # printed p.418 is the only page in the book that prints inches at all.
  raise 'the source page must be named' unless nw['source_ref'].include?('418')
  raise 'the rule must travel with the data' unless nw['note'].include?('NEVER COMPUTE')
end

check('the USA chapter is in the map: 16 sections, one of them extracted') do
  usa = Registry.map_sections.select { |x| x['collection'] == 'USA elements' }
  raise usa.length.to_s unless usa.length == 16
  done = usa.select { |x| x['status'] == 'extracted' }.map { |x| x['printed_pages'] }
  raise done.inspect unless done == ['418']
  # It is a COLLECTION, not a class: the printed general index lists it beside
  # Maxima e Intarsio. Its sections keep their real class so the picker files
  # them where a person would look.
  raise usa.map { |x| x['class'] }.uniq.sort.inspect unless
    usa.map { |x| x['class'] }.uniq.sort == %w[base tall]
end

check('the USA width field is recorded as UNDECODABLE, with the evidence') do
  g = Registry.data['code_grammar']['usa_elements']
  raise 'usa_elements grammar note missing' unless g
  # Three different fields for one width, two of them on the same page.
  %w[B89657 B89150 CR9900].each do |code|
    raise "the #{code} counter-example is missing" unless g['note'].include?(code)
  end
  raise 'the new family letters must be recorded' unless
    g['note'].include?('BL') && g['note'].include?('CR')
  # None of it may leak into the catalog before a page is extracted.
  # CR left this list on 2026-08-21: printed p.418 is extracted. The rest are
  # read but not extracted, and must not appear in the catalog.
  bad = Registry.codes.select { |c| c.start_with?('BL', 'BM', 'C8', 'Y4', 'Y7') }
  raise bad.inspect unless bad.empty?
end

check('printed p.418 is recorded as the page that prints inches') do
  page = Registry.map_sections.flat_map { |x| x['pages'] || [] }
                 .find { |pg| pg['printed'].to_s == '418' }
  raise 'p.418 not in the map' unless page
  raise 'the inch column must be recorded' unless page['note'].include?('INCH')
  raise 'the four sizes must be recorded' unless page['note'].include?('45.7')
end

check('any nominal a row declares must actually BE that size') do
  # Vacuous today - the USA elements chapter (printed 409-432) is not
  # extracted, so nothing declares one and every inch label is a conversion.
  # The moment a US row lands this stops being vacuous.
  Registry.catalog.each do |c|
    n = c['nominal_in']
    next unless n

    raise "#{c['code']}: nominal_in must be a number" unless n.is_a?(Numeric)
    raise "#{c['code']}: #{c['width_mm']} mm is not #{n} inches" unless
      (c['width_mm'] - (n * 25.4)).abs <= 1.0
  end
end

check('picker HTML escapes gap text (it comes from a data file)') do
    html = Palette.picker_html([], [{ 'level' => 'section', 'class' => 'base',
                                      'section' => '<script>x</script>', 'printed' => 'p.1',
                                      'status' => 'not_extracted', 'types' => [], 'note' => nil }])
    raise 'unescaped section title reached the HTML' if html.include?('<script>x</script>')
  end
end


# --------------------------------------------------------------------------
# Factory estimate 2026/30829-30830 (CONFIRMED). Not a catalog reading: this
# is what Cesar's own order system emitted for a real project. Where it
# disagrees with the registry it wins, so the facts it settled are pinned
# here rather than left in a document nobody re-reads.
# --------------------------------------------------------------------------
puts "\nfactory estimate 30829/30830 - what the order taught the registry"

check('the wall family letters are COMPLETE, and the run is not alphabetical') do
  # Was: "D = H.60 is recorded, and nothing was extrapolated", pinning the three
  # letters still unread. printed p.213-254 read them on 2026-08-23, so the
  # check now pins the finished lookup - and the one fact that makes it a
  # lookup rather than a sequence.
  letters = Registry.data['code_grammar']['wall_units']['family_letter']
  want = { 'B' => 'H.36', 'C' => 'H.48', 'D' => 'H.60', 'E' => 'H.72',
           'F' => 'H.96', 'G' => 'H.84', 'J' => 'H.120' }
  got = letters.select { |k, _| k.length == 1 }
  raise got.inspect unless got == want
  raise "nothing is unread now: #{letters['unread'].inspect}" if
    letters['unread'].to_s =~ /H\.\d/
  # THE PROOF that the letter is a lookup: F is H.96 and G is H.84, so the
  # letters run BACKWARDS across that pair. An alphabetical guess gets it wrong.
  raise 'F/G must run backwards against the heights' unless
    letters['F'] == 'H.96' && letters['G'] == 'H.84'
  raise 'the letter must be recorded as a lookup, not a sequence' unless
    letters['note'].downcase.include?('not a sequence')
end

check('P and O share ONE wall family-letter lookup') do
  # The manifest used to say the 90-degree corner prefix was "not P + family
  # letter at all". It is O + the same letter, shown by five families at once.
  # The correction is recorded beside the original, never instead of it.
  corner = Registry.data['code_grammar']['wall_units']['corner_wall_units']
  raise 'the original reading must stay' unless
    corner['note'].include?('not P + family letter at all')
  raise 'the correction must be recorded' unless
    corner['correction_2026_08_23'].to_s.include?('O plus the SAME letter')
  %w[OD OE OG OF OJ].each do |pre|
    raise "#{pre} not cited" unless corner['correction_2026_08_23'].include?(pre)
  end
end

check('the estimate named PD before any page we held could have') do
  # Recorded because the ORDER of arrival is the point: the letter came out of
  # a factory order on 2026-08-20, and printed p.221 was opened the same day
  # and agreed. Had the page come first this would be an ordinary extraction.
  sec = Registry.map_sections.find { |x| x['section'] == 'Wall units H. 60' }
  raise sec.inspect unless sec && sec['note'].include?('30829')
  raise 'the sequence must be recorded, not just the fact' unless
    sec['note'].include?('BEFORE the page was opened')
  obs = Registry.data['families']['Wall H.60']['page_observations']
  raise 'page observations missing' unless obs.is_a?(Array) && obs.length >= 4
end

check('SENTINEL: no wall family carries two codes for the two hands of one unit') do
  # Rows 15/18/25/27 of the estimate: PD0631 ships with OPENING DIRECTION Left
  # AND Right. One code, both hands. Nothing is wrong today - printed p.211 has
  # no side-hinged door at all - so this check exists to FIRE the moment H.72 or
  # H.84 is extracted and someone splits a ..31 into an rh code and an lh code.
  # FAMILY is part of the key. Without it PB0600 and PD0600 - the same type at
  # the same width in two different families - read as a split pair, and the
  # sentinel fires on correct data. Found the moment H.60 landed.
  wall  = Registry.catalog.select { |c| c['class'] == 'wall' }
  dupes = wall.group_by { |c| [c['family'], c['type_key'], c['width_mm']] }
              .select { |_size, rows| rows.length > 1 }
  raise "two codes for one wall size: #{dupes.keys.inspect}" unless dupes.empty?
  handed = wall.reject { |c| c['execution'].nil? }
  raise "a wall unit must not carry an execution letter: #{handed.map { |c| c['code'] }.inspect}" unless
    handed.empty?
end

check('the corner hand rule is recorded as corner-scoped, not as a catalog-wide law') do
  note = Registry.data['families']['H.78']['unit_types']['base_corner']['notes']
  raise 'the wall-unit refutation is not recorded' unless note.include?('PD0631')
  raise 'the rule must name its own scope' unless note.include?('corner')
  raise 'Q7 must stay open in its narrow form' unless note.include?('Q7b')
  # The general claim must not still be standing anywhere in the note.
  raise 'the dead general rule is still asserted' if
    note.include?('the hand can NEVER be read off a picture')
end

check('RECONCILIATION R1: 995626 is a bin kit, never a unit code') do
  # The hand-assembled package ordered 995626 where the factory ordered B80665.
  # The registry already had this right; pinning it stops the drift.
  raise '995626 must not be orderable as a unit' if Registry.codes.include?('995626')
  raise 'B80665 must be the unit' unless Registry.codes.include?('B80665')
  raise 'and 995626 must be its companion' unless
    companion_codes('B80665') == %w[995626]
end

check('RECONCILIATION R2: the invented prefixes UI / UH are nowhere in the registry') do
  # 13 of 26 manual rows carried a wrong code and 9 of those differed from the
  # factory's only by a prefix that was made up. The registry supplies the real
  # one, so every one of those rows would have been correct by construction.
  bad = Registry.codes.select { |c| c.start_with?('UI', 'UH') }
  raise bad.inspect unless bad.empty?
  raise 'B80657 must be present exactly once' unless Registry.codes.count('B80657') == 1
  raise 'B71200 must be present exactly once' unless Registry.codes.count('B71200') == 1
end

puts "\nthe wine cooler aperture (drawn, and drawn as a guess)"
# Cesar never dimensions this hole. The rails come from appliance specs, which
# makes them the first numbers in the registry that no Cesar page backs - so
# every guard below is about keeping that visible rather than about the shape.

CUTOUT_TYPES = Registry.data['families'].flat_map do |fam_name, fam|
  (fam['unit_types'] || {}).map { |k, t| [fam_name, k, t] }
end.select { |_f, _k, t| (t['front_layout'] || {})['cutout'] }

check('exactly one unit type in the registry carries a cutout, and it is the wine cooler') do
  keys = CUTOUT_TYPES.map { |_f, k, _t| k }
  raise keys.inspect unless keys == ['usa_wine_cooler_door']
end

check('every cutout is marked indicative and sourced from the appliance') do
  CUTOUT_TYPES.each do |fam, key, type|
    c = type['front_layout']['cutout']
    raise "#{fam}/#{key} trust"  unless c['trust']  == 'indicative'
    raise "#{fam}/#{key} source" unless c['source'] == 'appliance'
  end
end

check('the aperture is DERIVED - no width row may store one') do
  CUTOUT_TYPES.each do |_f, key, type|
    c = type['front_layout']['cutout']
    stored = c.keys.grep(/aperture/).reject { |k| k == 'aperture_note' }
    raise "#{key} stores an aperture: #{stored.inspect}" unless stored.empty?
    type['codes'].each do |row|
      raise "#{row['code']} stores an aperture" if row.keys.any? { |k| k.include?('aperture') }
    end
  end
end

check('every wine cooler width leaves a positive aperture') do
  %w[CR9401 CR9601 CR9701 CR9901].each do |code|
    u = Registry.lookup(code)
    slab = Generator.front_slabs(u).first
    r = Generator.cutout_rails(u, slab)
    raise "#{code}: no rails" unless r
    w = slab[:w_mm] - r[:left] - r[:right]
    h = slab[:h_mm] - r[:bottom] - r[:top]
    raise "#{code}: #{w} x #{h}" unless w > 0 && h > 0
  end
end

check('the plain fridge door gets no aperture - one suffix apart, and that is the difference') do
  raise 'CR9400 must have no rails' if
    Generator.cutout_rails(Registry.lookup('CR9400'),
                           Generator.front_slabs(Registry.lookup('CR9400')).first)
end

check('a split front gets no aperture rather than a guessed one') do
  u = Registry.lookup('CR9601')
  split = { name: 'FRONT_1_OF_2', x_mm: 0, z_mm: 0, w_mm: u['width_mm'] / 2, h_mm: u['height_mm'] }
  raise 'half a front must not take a hole' if Generator.cutout_rails(u, split)
  raise 'the whole front still must' unless
    Generator.cutout_rails(u, Generator.front_slabs(u).first)
end

check('no default rail is invented: each one is a value the measured table actually shows') do
  table = Registry.data['external_specs']['wine_cooler_panel_apertures']['rows']
  c = Registry.lookup('CR9601')['front_layout']['cutout']
  sides   = table.map { |r| r['rail_side_mm'] }
  tops    = table.map { |r| r['rail_top_mm'] }
  bottoms = table.map { |r| r['rail_bottom_mm'] }
  # side and top CONVERGE, so a default inside their range is defensible.
  raise "side #{c['rail_side_mm']} outside #{sides.inspect}" unless
    c['rail_side_mm'].between?(sides.min, sides.max)
  raise "top #{c['rail_top_mm']} outside #{tops.inspect}" unless
    c['rail_top_mm'].between?(tops.min, tops.max)
  # the bottom does NOT converge, so a midpoint would be a number nobody makes.
  # It must be one of the observed values, not an average of them.
  raise "bottom #{c['rail_bottom_mm']} is not a measured value: #{bottoms.inspect}" unless
    bottoms.include?(c['rail_bottom_mm'])
end

check('the measured table lives in the manifest and nowhere else') do
  section = File.read(File.expand_path('../registry/cesar/usa_tall_h210.json', __dir__))
  manifest = File.read(File.expand_path('../registry/cesar/_manifest.json', __dir__))
  # 1762 is the Miele panel height - a fact about a machine, not about a Cesar
  # article. If it appears in the section file the table has been copied.
  raise 'the appliance table has been copied into the section file' if section.include?('1762')
  raise 'the appliance table is missing from the manifest' unless manifest.include?('1762')
  raise 'the section file must point at the table' unless
    section.include?('wine_cooler_panel_apertures')
end

check('the warning is spelled once and reaches both the outliner and the notes') do
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  raise 'the label must be written out exactly once' unless
    src.scan('(cutout: INDICATIVE)').length == 1
  raise 'the label must be used, not merely declared' unless
    src.scan('CUTOUT_LABEL').length >= 3
  wine  = Generator.notes_for(Registry.lookup('CR9601'))
  plain = Generator.notes_for(Registry.lookup('CR9600'))
  raise wine  unless wine.include?('INDICATIVE')
  raise plain if plain.include?('INDICATIVE')
end

check('one place turns a slab into geometry, and every caller goes through it') do
  core = File.expand_path('../src/ucon_cabinet_engine/core', __dir__)
  gen   = File.read(File.join(core, '60_generator.rb'))
  panel = File.read(File.join(core, '80_panel.rb'))
  # 1 definition + 2 calls in build, 1 call in the properties panel.
  raise 'the generator must define it and use it twice' unless
    gen.scan('draw_front_slab').length == 3
  raise 'the properties panel must rebuild through it' unless
    panel.scan('Generator.draw_front_slab').length == 1
  # and must no longer keep its own copy of the box call
  raise 'the properties panel still builds its own front slab' if
    panel.include?('slab[:w_mm]')
end

puts "\nthe glass in it"
# Andriy, 2026-08-22: draw the glass, do not leave a hole. A void reads as a
# missing part on an elevation. So the PANE is geometry inside the front and
# the draftsman's diagonals are a symbol on the elevation tag - the same split
# the three tags are built on.

check('the hatch stays inside its pane and every line is 45 degrees') do
  u = Registry.lookup('CR9601')
  slab  = Generator.front_slabs(u).first
  r     = Generator.cutout_rails(u, slab)
  x0, z0 = r[:left], r[:bottom]
  gw = slab[:w_mm] - r[:left] - r[:right]
  gh = slab[:h_mm] - r[:bottom] - r[:top]
  lines = Symbols.glass_hatch(x0, z0, gw, gh)
  raise 'a pane this size must carry a hatch' if lines.length < 4
  lines.each do |a, b|
    raise "outside: #{a.inspect} #{b.inspect}" unless
      [a, b].all? { |pt| pt[0] >= x0 - 0.01 && pt[0] <= x0 + gw + 0.01 &&
                         pt[1] >= z0 - 0.01 && pt[1] <= z0 + gh + 0.01 }
    dx = b[0] - a[0]
    dz = b[1] - a[1]
    raise "not 45 degrees: #{dx} #{dz}" unless (dx - dz).abs < 0.01
  end
end

check('the diagonals come in PAIRS - a lone one reads as a section cut') do
  lines = Symbols.glass_hatch(0, 0, 400, 1600)
  raise "odd number of lines: #{lines.length}" unless lines.length.even?
  # within a pair the two intercepts differ by the pair gap, not by the spacing
  c = lines.map { |a, _b| a[1] - a[0] }
  c.each_slice(2) do |first, second|
    raise "pair gap #{second - first}" unless
      (second - first - Symbols::HATCH_PAIR_GAP_MM).abs < 0.01
  end
end

check('only a front with an aperture gets glass') do
  raise 'the plain fridge door must have no pane' unless
    Symbols.glass_hatch(0, 0, 0, 0).empty?
  u = Registry.lookup('CR9600')
  raise 'CR9600 must not reach the glass path' if
    Generator.cutout_rails(u, Generator.front_slabs(u).first)
end

check('the pane is geometry and the hatch is a symbol - neither does the other job') do
  core = File.expand_path('../src/ucon_cabinet_engine/core', __dir__)
  gen  = File.read(File.join(core, '60_generator.rb'))
  sym  = File.read(File.join(core, '70_symbols.rb'))
  raise 'the generator must build the pane' unless gen.include?('_GLASS"')
  raise 'symbols must not build solids' if sym.include?('Geometry.box')
  raise 'the hatch must live on the elevation tag' unless
    sym.include?('draw_glass_hatch(definition, unit, z0, y_face, front_tag')
end

check('a rebuilt front takes its glass with it') do
  panel = File.read(File.expand_path('../src/ucon_cabinet_engine/core/80_panel.rb', __dir__))
  # The pane is named FRONT_GLASS precisely so this prefix sweep catches it.
  # An exact-match refactor here would leave stale glass floating in a rebuilt
  # unit, so the prefix is pinned rather than assumed.
  raise 'the front sweep must be a PREFIX match' unless
    panel.include?("g.name.start_with?('FRONT')")
  raise 'FRONT_GLASS must be caught by it' unless 'FRONT_GLASS'.start_with?('FRONT')
end


puts "\ntall units H. 210 (printed p.111 / PDF 113) - the metric tall chapter opens"
def tall_sections
  Registry.map_sections.select { |s| s['class'] == 'tall' && s['collection'].nil? }
end

check('the tall chapter is in the map: 16 sections read from the printed p.79 index') do
  raise tall_sections.size.inspect unless tall_sections.size == 16
  first = tall_sections.first
  raise first.inspect unless first['section'] == 'Tall units H. 138' &&
                             first['printed_pages'] == '90-96'
  raise tall_sections.last.inspect unless tall_sections.last['printed_pages'] == '173'
  # The USA elements rows are also class tall and must NOT be swept in here:
  # they are a collection, filed under their own sections.
  usa = Registry.map_sections.select { |s| s['class'] == 'tall' && s['collection'] }
  raise usa.size.inspect if usa.empty?
end

check('printed p.111 holds three types and 14 codes, both depths') do
  codes = Registry.catalog.select { |c| c['section'] == 'Tall units H. 210' }
  raise codes.length.to_s unless codes.length == 14
  raise codes.map { |c| c['type_key'] }.uniq.sort.inspect unless
    codes.map { |c| c['type_key'] }.uniq.sort ==
      %w[tall_door tall_door_kit_ready tall_two_doors]
  raise 'every tall code is 2100 tall' unless codes.all? { |c| c['height_mm'] == 2100 }
  raise codes.map { |c| c['depth_mm'] }.uniq.sort.inspect unless
    codes.map { |c| c['depth_mm'] }.uniq.sort == [350, 620]
end

check('THE PREFIX IS THE DEPTH: every CQ is d.35 and every CR in this section is d.62') do
  Registry.catalog.select { |c| c['section'] == 'Tall units H. 210' }.each do |c|
    want = c['code'].start_with?('CQ') ? 350 : 620
    raise "#{c['code']} is d.#{c['depth_mm']}" unless c['depth_mm'] == want
  end
  # The pair is a LOOKUP and it is recorded as one. If someone ever "tidies"
  # the two shared pairs apart, this fails and sends them back to the page.
  fl = Registry.data['code_grammar']['tall_units']['family_letter']
  raise 'CQ/CR is shared by two printed sections' unless
    fl['H.210'] == fl['H.210_for_base_H.84']
  raise 'C0/C9 is shared by two printed sections' unless
    fl['H.234'] == fl['H.234_for_base_H.78']
end

check('CR spans three printed sections and no code collides') do
  cr = Registry.catalog.select { |c| c['code'].start_with?('CR') }
  metric = cr.select { |c| c['section'] == 'Tall units H. 210' }.map { |c| c['code'] }
  usa    = cr.select { |c| c['section'] != 'Tall units H. 210' }.map { |c| c['code'] }
  raise 'both sides must be populated' if metric.empty? || usa.empty?
  raise (metric & usa).inspect unless (metric & usa).empty?
  # Metric width indices are 03/05/06/07/09/12; the USA ones are 94/96/97/99.
  m = metric.map { |c| c[2, 2] }.uniq.sort
  u = usa.map    { |c| c[2, 2] }.uniq.sort
  raise (m & u).inspect unless (m & u).empty?
end

check('nothing from the pages we did NOT take has leaked in') do
  # printed p.112-115: uncoded interior mechanisms, corner tall units carrying
  # the D/S execution letter, and the fridge units. Recorded in catalog_map,
  # absent from the registry - and this fires the day one is pasted in.
  deferred = %w[CR0350 CR0550 CR0650 CR0385 CR0585 CR0586 CR0686 CR0688
                CR1512 CR1612 CR4611 CR4712]
  present = deferred & Registry.codes
  raise present.inspect unless present.empty?
  ds = Registry.codes.select { |c| c.start_with?('CQ', 'CR') && c.end_with?('D/S') }
  raise ds.inspect unless ds.empty?
end

check('a tall unit stands on the floor, on its plinth, and asks for no hanging height') do
  u = Registry.lookup('CR0631')
  raise 'a tall unit must not hang' if Generator.wall_hung?(u)
  raise Generator.base_z_mm(u).to_s unless
    Generator.base_z_mm(u) == Standards::PLINTH_H_MM
  attrs = Generator.attributes_for(u)
  raise attrs.inspect unless attrs['mounting'] == 'floor'
  raise 'a floor unit may not carry mount_bottom_mm' if attrs['mount_bottom_mm']
end

check('the 2100 front is one slab, and the two-door unit is two') do
  one = Generator.front_slabs(Registry.lookup('CR0631'))
  raise one.inspect unless one.length == 1 && one.first[:h_mm] == 2100
  two = Generator.front_slabs(Registry.lookup('CR1230'))
  raise two.inspect unless two.length == 2
  raise 'the two leaves must be equal' unless two[0][:w_mm] == two[1][:w_mm]
end

check('this family offers no 78/75 door version, and says so from the page') do
  raise 'H.210 must declare no door_versions' if Registry.lookup('CR0631')['door_versions']
  # The base family does offer one - so the absence above is a fact, not a hole.
  raise 'H.78 must still offer one' unless Registry.lookup('B80601')['door_versions']
end

check('the kit-ready type records NEITHER its chosen kit NOR its implied hinges') do
  u = Registry.lookup('CR0535')
  raise 'a companion may not be typed before options/ exists' unless
    u['companions'].empty?
  raise '155 degree hinges belong in interior_confirmed' unless
    u['interior_confirmed'].include?('155 degree hinges')
  raise 'the kit-ready type is d.62 only' unless
    Registry.catalog.select { |c| c['type_key'] == 'tall_door_kit_ready' }
                    .map { |c| c['depth_mm'] }.uniq == [620]
end

check('the USA chapter reuses metric family letters - recorded, not left as "new"') do
  usa = Registry.data['code_grammar']['usa_elements']
  raise 'the correction must be recorded' unless usa['family_letters_are_not_new']
  raise 'it must name the metric sections it came from' unless
    usa['family_letters_are_not_new'].include?('printed p.111-115')
end

puts "\nthe housing behind the panel"
# Andriy, 2026-08-22, off the model: the phantom was coming out from under the
# plinth. It ran floor to the top of the front - right for a dishwasher, wrong
# for a housing at BOTH ends.

check('the US housing starts on the plinth and stops at the appliance cutout') do
  u = Registry.lookup('CR9601')
  raise Generator.niche_bottom_mm(u).to_s unless
    Generator.niche_bottom_mm(u) == Standards::PLINTH_H_MM
  # 84 in. Measured, not converted from anything of ours.
  raise Generator.niche_top_mm(u).to_s unless Generator.niche_top_mm(u) == 2133.6
  raise Generator.niche_height_mm(u).to_s unless Generator.niche_height_mm(u) == 2033.6
end

check('the 66,4 leftover is now a fact of the model, not only of a note') do
  u = Registry.lookup('CR9601')
  front_top = Generator.base_z_mm(u) + u['height_mm']
  raise front_top.to_s unless front_top == 2200
  leftover = front_top - Generator.niche_top_mm(u)
  raise leftover.to_s unless (leftover - 66.4).abs < 0.001
  # The same number the registry already wrote down before anything drew it.
  notes = Registry.data['families']['USA Tall H.210']['representation_notes'].join(' ')
  raise 'the note and the geometry must agree' unless notes.include?('66,4')
end

check('the old rule survives untouched for anything that states no housing') do
  # 2026-08-24: V80730 used to BE that case and is not any more - every
  # appliance panel in the registry now states where its housing begins. The
  # rule is still live for the next family that says nothing, so the case is
  # CONSTRUCTED rather than the check deleted: floor to the top of the front.
  u = Registry.lookup('V80730').merge('appliance_niche' => nil)
  raise Generator.niche_bottom_mm(u).to_s unless Generator.niche_bottom_mm(u) == 0
  raise Generator.niche_height_mm(u).to_s unless
    Generator.niche_height_mm(u) == Standards::PLINTH_H_MM + 780
end

check('the plinth height is not copied into the registry') do
  section = File.read(File.expand_path('../registry/cesar/usa_tall_h210.json', __dir__))
  niche = Registry.data['families']['USA Tall H.210']['appliance_niche']
  raise 'the bottom must be named, not numbered' unless niche['bottom'] == 'plinth_top'
  raise 'a second copy of the plinth height has appeared' if niche.key?('bottom_mm')
  raise 'the section file must point at the measured table' unless
    section.include?('us_appliance_housing_cutouts')
end

check('the housing says on itself that it came from the appliance, not from Cesar') do
  n = Generator.niche_attributes_for(Registry.lookup('CR9601'))
  Contract.validate!(n)
  raise n['notes'] unless n['notes'].include?('INDICATIVE')
  raise n['notes'] unless n['notes'].include?('2133.6')
  raise n['height_mm'].to_s unless n['height_mm'] == 2033.6
  # and since 2026-08-24 a dishwasher says it too, in its own words. What it
  # must NOT borrow is the leftover sentence - see the dishwasher checks below.
end


puts "\nthe dictionary IS the object - Contract.write! reconciles (0.44.0)"

# 20_contract.rb is pure Ruby apart from the entity it writes to, so a stub
# stands in for a ComponentDefinition and the whole write/read ROUND TRIP runs
# headless. Nothing tested that round trip before, which is exactly why the
# erasure bug below shipped: every existing check exercised
# Panel.attributes_patch in isolation, where the answer was always correct.

check('write! then read returns exactly what was written') do
  e = StubEntity.new
  Contract.write!(e, VALID)
  back = Contract.read(e)
  raise back.inspect unless back == VALID.reject { |_, v| v.nil? }
end

check('REGRESSION: switching to a client handle erases the factory ref') do
  # The shipped bug, 2026-08-22: present? is false for '', and write! used to
  # SKIP such a key instead of deleting it. Every caller is read-merge-write,
  # so "GOL001" survived on an object whose hardware_source said "client" -
  # a code nobody chose, sitting on the record the exporter reads.
  u = Registry.lookup('B80601')
  e = StubEntity.new
  Contract.write!(e, Generator.attributes_for(u).merge(
    Panel.attributes_patch(u, 'door_version' => '78', 'opening_method' => 'handle',
                              'hardware_mode' => 'factory', 'hardware_ref' => 'M00001')))
  raise 'setup failed' unless Contract.read(e)['hardware_ref'] == 'M00001'

  patch = Panel.attributes_patch(u, 'door_version' => '78',
                                    'opening_method' => 'handle',
                                    'hardware_mode' => 'client')
  Contract.write!(e, Contract.read(e).merge(patch))
  after = Contract.read(e)
  raise "hardware_ref #{after['hardware_ref'].inspect} survived" if after.key?('hardware_ref')
  raise after['hardware_source'].inspect unless after['hardware_source'] == 'client'
end

check('an absent value never CREATES a key') do
  e = StubEntity.new
  Contract.write!(e, VALID.merge('notes' => ''))
  raise 'an empty value must not be stored' if Contract.read(e).key?('notes')
  raise 'nothing else may be invented' unless
    Contract.read(e).keys.sort == VALID.keys.sort
end

check('an empty LIST is absent too - the ordering rule v1.6 will rely on') do
  # v1.6 stores companion_refs as a list. [] means "no companions" and must
  # erase the key; encoding it first would make '[]' a non-empty String and
  # present? would happily persist it. Decide presence on the LOGICAL value.
  e = StubEntity.new
  one = [{ 'code' => '995626', 'qty' => 1, 'um' => 'PZ', 'origin' => 'implied' }]
  Contract.write!(e, VALID.merge('companion_refs' => one))
  raise 'setup failed' unless Contract.read(e)['companion_refs'] == one
  Contract.write!(e, VALID.merge('companion_refs' => []))
  raise 'an empty list must erase the key' if Contract.read(e).key?('companion_refs')
end

check('write! is idempotent, and leaves no key outside the contract') do
  e = StubEntity.new
  Contract.write!(e, VALID)
  first = e.stored.dup
  Contract.write!(e, VALID)
  raise 'not idempotent' unless e.stored == first
  raise 'a key outside KEYS reached the dictionary' unless
    (e.stored.keys - Contract::KEYS).empty?
end

check('a stale key left by an older write does not survive the next one') do
  e = StubEntity.new
  Contract.write!(e, VALID.merge('hinge_side' => 'rh'))
  raise 'setup failed' unless Contract.read(e)['hinge_side'] == 'rh'
  Contract.write!(e, VALID)
  raise 'the dictionary must equal the contract' if Contract.read(e).key?('hinge_side')
end

check('a corner swap puts the hand on the RECORD, not only into the symbol') do
  # Needs SketchUp to run, so it is checked at the source - the same technique
  # the front-line and slab-loop checks use. attributes_for deliberately never
  # carries a hand; Symbols.draw two lines later is passed the OLD one. Before
  # write! reconciled, the stale value made those agree BY ACCIDENT.
  gen  = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  swap = gen[/def swap_corner_execution!.*?\n      end\n/m]
  raise 'swap_corner_execution! not found' unless swap
  # Comments legitimately name the code they explain, so strip them before
  # asking about ORDER - otherwise a sentence mentioning Contract.write! above
  # the assignment fails a test about the assignment. (It did, first run.)
  code = swap.lines.reject { |l| l.strip.start_with?('#') }.join
  raise 'the hand must be written, not only drawn' unless
    code.include?("new_attrs['hinge_side'] = attrs['hinge_side']")
  raise 'the carry-forward must precede the write' unless
    code.index("new_attrs['hinge_side']") < code.index('Contract.write!')
end


puts "\nregistry duplicates - the class of loss that no parser reports"

# THREE WAYS THE REGISTRY CAN LOSE DATA IN SILENCE, and none of them is an
# error anywhere today:
#
#   1. a duplicated JSON key      - legal JSON, the last one wins
#   2. a duplicated article code  - lookup returns whichever it meets first
#   3. two files claiming the same unit_type in one family - the loader
#      merges by key, so the second file DELETES the first
#
# (1) reached HEAD on 2026-08-22: us_appliance_housing_cutouts sat twice in
# _manifest.json, the copies differing by one word, because an edit was pasted
# instead of replacing. json.load said nothing, and neither did this suite.

class DupKeyHash < Hash
  class << self; attr_accessor :found; end
  def []=(key, value)
    (self.class.found ||= []) << key if key?(key)
    super
  end
end

def duplicate_keys_in(path)
  DupKeyHash.found = []
  JSON.parse(File.read(path), object_class: DupKeyHash)
  DupKeyHash.found.uniq.sort
end

def registry_json_files
  Dir.glob(File.join(File.expand_path('..', __dir__), 'registry', '**', '*.json')).sort
end

def registry_section_files
  registry_json_files.reject { |f| File.basename(f) == '_manifest.json' }
end

check('THE DETECTOR PROVES ITSELF before any file is trusted to it') do
  # A guard that can quietly stop working is worse than no guard: it turns an
  # unchecked file into a file everyone believes is checked. If a future Ruby
  # or json ever ignores object_class, THIS fails - loudly - instead of every
  # registry file passing in silence.
  DupKeyHash.found = []
  JSON.parse('{"a": 1, "b": {"c": 2, "c": 3}, "a": 4}', object_class: DupKeyHash)
  raise "detector is blind: #{DupKeyHash.found.inspect}" unless
    DupKeyHash.found.uniq.sort == %w[a c]

  DupKeyHash.found = []
  JSON.parse('{"a": 1, "b": {"c": 2}, "d": [{"e": 1}, {"e": 2}]}',
             object_class: DupKeyHash)
  raise "false positive: #{DupKeyHash.found.inspect}" unless DupKeyHash.found.empty?
end

check('no registry JSON file carries a duplicated key') do
  files = registry_json_files
  raise 'no registry files found - the glob is wrong' if files.empty?
  bad = files.map { |f| [f, duplicate_keys_in(f)] }.reject { |_, d| d.empty? }
  raise bad.map { |f, d|
    "#{File.basename(f)}: #{d.join(', ')} - find it with " \
    "grep -n '\"#{d.first}\"' registry/**/#{File.basename(f)}"
  }.join(' | ') unless bad.empty?
end

check('THE COLLISION GUARD PROVES ITSELF before the real files are trusted to it') do
  # Rule 12. Run it against the defect it exists for, on a fixture, so that a
  # green suite means the guard works and not merely that today's files happen
  # to agree.
  fam = {}
  origin = {}
  Registry.merge_family_keys!(fam, { 'height_mm' => 780, 'unit_types' => { 'x' => 1 } },
                              'H.78', 'first.json', origin)
  raise fam.inspect unless fam == { 'height_mm' => 780 }
  raise 'unit_types must not be merged as a family key' if fam.key?('unit_types')

  # Saying the same thing twice is redundant, not wrong - and every H.78 file
  # really does state height_mm 780, so this must stay legal.
  Registry.merge_family_keys!(fam, { 'height_mm' => 780 }, 'H.78', 'second.json', origin)
  raise 'agreement must not raise' unless fam['height_mm'] == 780

  # Disagreement is the silent loss this exists to stop.
  begin
    Registry.merge_family_keys!(fam, { 'height_mm' => 840 }, 'H.78', 'third.json', origin)
    raise 'two files disagreed and nothing complained'
  rescue RuntimeError => e
    raise e.message unless e.message.include?('first.json') && e.message.include?('third.json')
    raise 'the message must name the key' unless e.message.include?('height_mm')
    raise 'and both values' unless e.message.include?('780') && e.message.include?('840')
  end
end

check('the real registry loads clean, and one key really is shared') do
  # Not a tautology: three files name family H.78 and all three state
  # height_mm. If the guard were wrong about agreement, this would raise.
  raise 'H.78 must be shared by three files' unless
    Registry.data['families']['H.78']['height_mm'] == 780
  # And the fact that was nearly lost is still where it was put.
  raise 'plinth_h_mm survived' unless
    Registry.data['families']['H.78']['plinth_h_mm'] == 100
end

check('no article code appears twice anywhere in the registry') do
  # Read from the FILES, not from Registry.codes: the loader is itself lossy
  # (see the next check), so asking it would hide exactly what we are looking
  # for.
  seen = {}
  dups = []
  registry_section_files.each do |f|
    sec = JSON.parse(File.read(f))
    ((sec['data'] || {})['unit_types'] || {}).each do |type_key, unit_type|
      (unit_type['codes'] || []).each do |row|
        where = "#{File.basename(f)}:#{type_key}"
        if seen[row['code']]
          dups << "#{row['code']} in #{seen[row['code']]} and #{where}"
        else
          seen[row['code']] = where
        end
      end
    end
  end
  raise dups.join(' | ') unless dups.empty?
  # And the scan must not be able to pass by reading NOTHING. Tying the raw
  # file count to the loader's own count does double duty: it fails if the glob
  # ever goes blind, and it fails if the loader silently merged a unit_type
  # away - the very loss the next check is about.
  raise "files hold #{seen.size} codes, the loader reports " \
        "#{Registry.codes.length} - something was merged away" unless
    seen.size == Registry.codes.length
end

check('two section files never claim the same unit_type inside one family') do
  # 50_registry merges each file's unit_types INTO the family by key, last file
  # winning by filename sort - so a collision does not raise, it DELETES. This
  # is not theoretical: base_h78, sink_base_h78 and appliance_h78 all merge
  # into family H.78 today, and tall_h210 / usa_tall_h210 are kept apart only
  # by their deliberately namespaced family names.
  owner   = {}
  clashes = []
  registry_section_files.each do |f|
    sec = JSON.parse(File.read(f))
    ((sec['data'] || {})['unit_types'] || {}).each_key do |type_key|
      key = [sec['family'], type_key]
      if owner[key]
        clashes << "#{sec['family']} / #{type_key}: #{owner[key]} and #{File.basename(f)}"
      else
        owner[key] = File.basename(f)
      end
    end
  end
  raise clashes.join(' | ') unless clashes.empty?
end

check('the three files that share family H.78 really do share it') do
  # Guards the guard above: if the fixtures ever stop overlapping, the
  # collision check would be passing on nothing and nobody would notice.
  fams = registry_section_files.map { |f| JSON.parse(File.read(f))['family'] }
  raise fams.inspect unless fams.count('H.78') >= 2
end


puts "\nObject Contract v2 - companion LINES, variants, and the v1 lift"

def v1_entity
  e = StubEntity.new
  VALID.each { |k, v| e.set_attribute(Contract::DICTIONARY, k, v) }
  e.set_attribute(Contract::DICTIONARY, 'schema_version', '1')
  e.set_attribute(Contract::DICTIONARY, 'companion_refs', '995946,GBBF01')
  e
end

LINE = { 'code' => '996PL6', 'qty' => 1, 'um' => 'PZ', 'origin' => 'chosen' }.freeze

check('the v1 string is refused on WRITE, and the refusal names the way in') do
  begin
    Contract.validate!(VALID.merge('companion_refs' => '995946,GBBF01'))
    raise 'accepted the v1 shape'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('list of lines')
    raise 'the message must point at the migration' unless e.message.include?('Contract.read')
  end
end

check('a line is checked field by field') do
  bad = {
    'not a hash'        => ['996PL6'],
    'unknown key'       => [LINE.merge('role' => 'kit')],
    'qty zero'          => [LINE.merge('qty' => 0)],
    'qty not a number'  => [LINE.merge('qty' => 'one')],
    'bad um'            => [LINE.merge('um' => 'EA')],
    'bad origin'        => [LINE.merge('origin' => 'default')],
    'no origin'         => [{ 'code' => 'X', 'qty' => 1, 'um' => 'PZ' }],
    'code not a string' => [LINE.merge('code' => 996)]
  }
  bad.each do |why, value|
    begin
      Contract.validate!(VALID.merge('companion_refs' => value))
      raise "accepted: #{why}"
    rescue ArgumentError
      nil
    end
  end
end

check('a line may carry NO code - the unresolvable chosen option (§4.2 rule 4)') do
  # W.750 has no kit on printed p.569 at all. Rule 7 applied to articles:
  # unknown is nil, not a stale code quietly kept and not a silent deletion.
  Contract.validate!(VALID.merge('companion_refs' => [LINE.merge('code' => nil)]))
end

check('ONE variant schema, used on the object and on a line alike') do
  v = { 'key' => 'FINISH', 'value' => 'Stainless steel' }
  Contract.validate!(VALID.merge('variants' => [v]))
  Contract.validate!(VALID.merge('companion_refs' => [LINE.merge('variants' => [v])]))
  %w[key value].each do |missing|
    begin
      Contract.validate!(VALID.merge('variants' => [v.reject { |k, _| k == missing }]))
      raise "accepted a variant with no #{missing}"
    rescue ArgumentError => e
      raise e.message unless e.message.include?(missing)
    end
  end
end

check('a variant may not carry what it costs, and the error says why') do
  # printed p.569 prints "Stainless steel 387" - the 387 is exactly what must
  # NOT come along. §1.2 reaches inside the structured keys.
  begin
    Contract.validate!(VALID.merge('variants' => [
      { 'key' => 'FINISH', 'value' => 'Stainless steel', 'surcharge' => 387 }
    ]))
    raise 'accepted a priced variant'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('§1.2')
    raise 'the message should say what a variant records' unless e.message.include?('never what it costs')
  end
end

check('NO RECURSION: a line may not contain lines') do
  begin
    Contract.validate!(VALID.merge('companion_refs' => [
      LINE.merge('companion_refs' => [LINE])
    ]))
    raise 'accepted a nested companion'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('companion_refs')
  end
end

check('structured keys are stored as JSON TEXT and come back as structure') do
  e = StubEntity.new
  attrs = VALID.merge('companion_refs' => [LINE.merge('variants' => [
                        { 'key' => 'FINISH', 'value' => 'Stainless steel' }])],
                      'variants' => [{ 'key' => 'OPENING DIRECTION', 'value' => 'Left' }])
  Contract.write!(e, attrs)
  Contract::STRUCTURED_KEYS.each do |k|
    raise "#{k} must be stored as text" unless e.stored[k].is_a?(String)
    raise "#{k} must be JSON" unless e.stored[k].start_with?('[')
  end
  back = Contract.read(e)
  raise back['companion_refs'].inspect unless back['companion_refs'] == attrs['companion_refs']
  raise back['variants'].inspect unless back['variants'] == attrs['variants']
end

check('an empty structured value is ABSENT, decided before encoding') do
  e = StubEntity.new
  Contract.write!(e, VALID.merge('companion_refs' => [LINE], 'variants' => [
                    { 'key' => 'K', 'value' => 'V' }]))
  raise 'setup failed' unless Contract.read(e)['companion_refs']
  Contract.write!(e, VALID.merge('companion_refs' => [], 'variants' => []))
  raise 'an empty list must not be stored as "[]"' if e.stored.key?('companion_refs')
  raise 'an empty list must not be stored as "[]"' if e.stored.key?('variants')
end

check('THE v1 LIFT: an old object reads as v2') do
  back = Contract.read(v1_entity)
  raise back['schema_version'].inspect unless back['schema_version'] == '2'
  raise back['companion_refs'].inspect unless back['companion_refs'] == [
    { 'code' => '995946', 'qty' => 1, 'um' => 'PZ', 'origin' => 'implied' },
    { 'code' => 'GBBF01', 'qty' => 1, 'um' => 'PZ', 'origin' => 'implied' }
  ]
end

check('and an old object stays EDITABLE - read, merge, write, no raise') do
  # The real path: someone opens the 545 Avenida model and changes one thing in
  # the panel. If the lift produced a shape validate! rejects, that fails here.
  e = v1_entity
  Contract.write!(e, Contract.read(e).merge('hinge_side' => 'rh'))
  back = Contract.read(e)
  raise back['schema_version'].inspect unless back['schema_version'] == '2'
  raise back['hinge_side'].inspect unless back['hinge_side'] == 'rh'
  raise 'the codes must survive the round trip' unless
    back['companion_refs'].map { |l| l['code'] } == %w[995946 GBBF01]
  raise 'and the entity now stores v2' unless e.stored['schema_version'] == '2'
end

check('a bare legacy code is never parsed as a NUMBER') do
  # JSON.parse('995626') returns the Integer 995626 in modern json. The lift
  # keys off the leading bracket precisely so a single-code v1 value cannot be
  # silently turned into a number.
  e = StubEntity.new
  VALID.each { |k, v| e.set_attribute(Contract::DICTIONARY, k, v) }
  e.set_attribute(Contract::DICTIONARY, 'schema_version', '1')
  e.set_attribute(Contract::DICTIONARY, 'companion_refs', '995626')
  line = Contract.read(e)['companion_refs'].first
  raise line.inspect unless line['code'] == '995626'
  raise 'the code must stay a STRING' unless line['code'].is_a?(String)
end

check('the generator emits implied lines, sourced from the registry rule') do
  lines = Generator.attributes_for(Registry.lookup('V80730'))['companion_refs']
  raise lines.inspect unless lines.map { |l| l['code'] } == %w[995946 GBBF01]
  raise 'every generated line is implied' unless lines.all? { |l| l['origin'] == 'implied' }
  raise 'qty/um must be resolved values' unless lines.all? { |l| l['qty'] == 1 && l['um'] == 'PZ' }
  # The rule carries the page; the line inherits it rather than restating it.
  raise 'source_ref must come from the registry rule' unless
    lines.all? { |l| l['source_ref'].to_s.include?('printed p.') }
  # Nothing the generator produces is ever chosen: that needs a person.
  Registry.codes.each do |code|
    (Generator.attributes_for(Registry.lookup(code))['companion_refs'] || []).each do |l|
      raise "#{code} produced a chosen line" if l['origin'] == 'chosen'
    end
  end
end

check('the contract implements the document that outranks it') do
  root = File.expand_path('..', __dir__)
  v2 = File.join(root, 'docs', 'UCON_Object_Contract_v2.md')
  v1 = File.join(root, 'docs', 'UCON_Object_Contract_v1.md')
  raise 'the v2 document is missing' unless File.exist?(v2)
  raise 'schema_version disagrees with the document' unless
    File.read(v2).include?('**Version:** v2')
  raise 'v1 must be marked superseded, not edited away' unless
    File.read(v1).include?('SUPERSEDED')
  raise 'the code must cite the document it implements' unless
    File.read(File.join(root, 'src', 'ucon_cabinet_engine', 'core', '20_contract.rb'))
        .include?('docs/UCON_Object_Contract_v2.md')
  raise Contract::SCHEMA_VERSION unless Contract::SCHEMA_VERSION == '2'
end


puts "\nwhat the DIALOG is handed (0.46.0 - the pairing that never arrived)"

check('a gola drawer unit is handed profile PAIRS, through the real path') do
  # The regression, found 2026-08-22 off a screenshot: push_selection called
  # gola_options with NO unit, because `unit` was scoped inside the branch
  # above the call. So the pairing was computed correctly, tested directly, and
  # never reached the dialog - and the order lost the intermediate profile that
  # joins a drawer unit's stacked front zones, which is the one thing pairing
  # them was for. This checks the STATE the dialog receives, not the helper it
  # is built from.
  drawer = Registry.lookup('B81253')
  names  = Panel.selection_state(drawer, Generator.attributes_for(drawer))['gola_profiles']
                .map { |r| r['name'] }
  raise names.inspect unless names == ['L-shaped system (GOL001 + GOL002)',
                                       'straight system (GOL005 + GOL006)']
end

check('and a single-door unit is still handed single profiles') do
  door  = Registry.lookup('B80601')
  names = Panel.selection_state(door, Generator.attributes_for(door))['gola_profiles']
               .map { |r| r['name'] }
  raise names.inspect unless names == ['L-shaped system (GOL001)', 'straight system (GOL005)']
end

check('the state carries the unit facts the dialog renders') do
  u  = Registry.lookup('CR0631')
  st = Panel.selection_state(u, Generator.attributes_for(u))
  raise 'handed must reach the dialog' unless st['handed'] == true
  # A family that declares no gola version must offer no door version, and the
  # tall chapter is the first family where that is true of a CABINET.
  raise 'no door version may be offered here' unless st['door_versions'].nil?
  raise st['desc'].inspect unless st['desc'].include?('Tall unit with door')
end

check('nothing selected still yields a renderable state') do
  st = Panel.selection_state(nil, nil)
  raise 'must not invent an attrs block' if st.key?('attrs')
  raise 'the dialog still needs its lists' unless st['gola_profiles'] && st['handles']
end

check('push_selection is glue, and selection_state stays pure') do
  src  = File.read(File.expand_path('../src/ucon_cabinet_engine/core/80_panel.rb', __dir__))
  body = src[/def push_selection.*?\n      end\n/m]
  raise 'push_selection not found' unless body
  raise 'the state must be built by selection_state' unless body.include?('selection_state(')
  raise 'no option list may be computed in the glue again' if body.include?('gola_options')
  raise 'nor the hardware table' if body.include?("Registry.data['hardware']")

  state = src[/def selection_state.*?\n      end\n/m]
  raise 'selection_state not found' unless state
  offenders = state.scan(/\b(?:Sketchup|Geom|UI|@dialog)\b/).uniq
  raise "selection_state must stay pure: #{offenders.inspect}" unless offenders.empty?
end


puts "\nhandle restrictions: data, not prose (printed p.587)"

def handles
  Registry.data['hardware']['handles'] || []
end

check('Lume carries its restriction as DATA with a page, not inside its name') do
  lume = handles.find { |h| h['code'] == 'M00014' }
  raise 'M00014 is missing' unless lume
  raise lume['name'].inspect unless lume['name'] == 'Lume'
  r = lume['requires']
  raise 'the restriction must be structured' unless r
  raise r['gola_system'].inspect unless r['gola_system'] == 'straight'
  raise 'the page must travel with it' unless r['source_ref'].to_s.include?('p.587')
  raise 'the wording must be preserved verbatim' unless
    r['verbatim'] == 'With straight grip recess system only'
end

check('NO handle smuggles a restriction inside its display name') do
  # The name is what the dropdown shows. A rule written there is a rule no code
  # can read and no test can check - it was "Lume - with straight grip recess
  # system only" until printed p.587 was actually opened.
  bad = handles.select { |h| h['name'] =~ /\bonly\b|recess|system/i }
  raise bad.map { |h| h['code'] }.inspect unless bad.empty?
  raise 'every handle needs a page' unless handles.all? { |h| h['source_ref'].to_s =~ /p\.\d+/ }
end

check('the restriction lives in ONE place') do
  note = Registry.data['hardware']['gola_note'].to_s
  raise 'gola_note must not restate the rule' if note =~ /straight system only/
  raise 'gola_note must point at the data instead' unless note.include?('M00014.requires')
end

check('SENTINEL: the picker still offers Lume, and the reason is recorded') do
  # A DELIBERATE gap, not an oversight. The restriction is COMPOSITION-scoped -
  # one grip system per kitchen, set once in the estimate header - so a
  # per-unit filter would be a rule generalising past its evidence (rule 4).
  # Not even the tempting case decides it: Tall H.210 declares no gola version
  # at all, and printed p.587 still never says a handle unit cannot stand in a
  # straight-grip composition. If someone adds a per-unit filter anyway, this
  # fails and the scope note explains why that is the wrong shape.
  u  = Registry.lookup('CR0631')
  st = Panel.selection_state(u, Generator.attributes_for(u))
  raise 'Lume is expected in the list until M1.6 lands' unless
    st['handles'].map { |h| h['code'] }.include?('M00014')
  scope = handles.find { |h| h['code'] == 'M00014' }['requires']['scope']
  raise 'the scope must say it is composition-level' unless scope.include?('COMPOSITION')
  raise 'and must name what it waits on' unless scope.include?('M1.6')
end


puts "\nexporter level 1 - order rows, not a cut list (M1.10)"

def export_attrs(code, extra = {})
  Generator.attributes_for(Registry.lookup(code)).merge(extra)
end

check('85_export is PURE - the model walk lives outside it') do
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/85_export.rb', __dir__))
  offenders = src.gsub(/^\s*#.*$/, '').scan(/\b(?:Sketchup|Geom|UI)\b/).uniq
  raise "SketchUp leaked into the exporter: #{offenders.inspect}" unless offenders.empty?
end

check('a unit becomes one numbered PZ row carrying its dimensions') do
  r = Export.rows([export_attrs('CR0631')]).first
  raise r.inspect unless r['row'] == 1 && r['level'] == 0
  raise r.inspect unless r['code'] == 'CR0631' && r['um'] == 'PZ' && r['qty'] == 1
  raise r.inspect unless [r['l_mm'], r['h_mm'], r['p_mm']] == [600, 2100, 620]
  raise r['description'].inspect unless r['description'].include?('Tall unit with door')
  raise r.inspect unless r['status'] == 'PLANNING' && r['code_status'] == 'PRELIMINARY'
end

check('a corner unit is dimensioned by its footprint, not by a width') do
  r = Export.rows([export_attrs('AU110D')]).first
  raise r.inspect unless r['corner'] == '1150x700'
  raise 'a corner has no single width to print' unless r['l_mm'].nil?
end

check('THE HAND BECOMES A VARIANT LINE, because that is what an order carries') do
  # The object keeps hinge_side as a first-class key - the symbol renderer
  # reads it. The ORDER has no such column: estimate 2026/30829 ships one code
  # with OPENING DIRECTION: Left / Right underneath it. Translating between the
  # two models is the exporter's job, and this is the first case of it.
  rows = Export.rows([export_attrs('CR0631', 'hinge_side' => 'rh')])
  hand = rows.find { |r| r['description'].to_s.start_with?('OPENING DIRECTION') }
  raise 'no hand line emitted' unless hand
  raise hand['description'].inspect unless hand['description'] == 'OPENING DIRECTION: Right'
  raise 'it hangs under the unit row' unless hand['level'] == 1 && hand['row'].nil?
  raise 'a variant line orders no article' unless hand['code'].nil?
  # And lh must not silently become the same thing.
  lh = Export.rows([export_attrs('CR0631', 'hinge_side' => 'lh')])
             .find { |r| r['description'].to_s.start_with?('OPENING DIRECTION') }
  raise lh['description'].inspect unless lh['description'] == 'OPENING DIRECTION: Left'
end

check('the 78/75 door version reaches the order NOWHERE') do
  # It is a drawing axis. A base page prints both heights over ONE code table,
  # and no order line distinguishes them.
  gola = export_attrs('B80601').merge(
    Panel.attributes_patch(Registry.lookup('B80601'),
                           'door_version' => '75', 'gola_system' => 'L-shaped'))
  text = Export.csv(Export.rows([gola]))
  raise 'a door version leaked into the order' if text =~ /\b78\b|\bdoor_version\b/
  raise 'front_height_mm is not an order column' if Export::COLUMNS.include?('front_height_mm')
end

check('a gola front orders its profile, in ML, with the quantity left OPEN') do
  gola = export_attrs('B80601').merge(
    Panel.attributes_patch(Registry.lookup('B80601'),
                           'door_version' => '75', 'gola_system' => 'L-shaped'))
  row = Export.rows([gola]).find { |r| r['code'] == 'GOL001' }
  raise 'the profile must be an order line' unless row
  raise row['um'].inspect unless row['um'] == 'ML'
  # NOT 1. A linear-metre line is quantified by the run it travels along,
  # across joints between units, and one object cannot know that.
  raise 'quantity must not be invented' unless row['qty'].nil?
  raise row['note'].inspect unless row['note'].include?('run')
end

def handle_row(code, handle = 'M00001')
  Export.rows([export_attrs(code, 'hardware_ref' => handle)])
        .find { |r| r['code'] == handle }
end

check('a factory handle is PZ, and it comes through the panel that way') do
  h = export_attrs('B80601').merge(
    Panel.attributes_patch(Registry.lookup('B80601'),
                           'door_version' => '78', 'opening_method' => 'handle',
                           'hardware_mode' => 'factory', 'hardware_ref' => 'M00001'))
  row = Export.rows([h]).find { |r| r['code'] == 'M00001' }
  raise row.inspect unless row['um'] == 'PZ'
  raise 'a single-door unit takes one handle' unless row['qty'] == 1
end

check('EIGHT CABINETS, EIGHT HANDLES - the stated rule, reproduced') do
  # The rule as Andriy gave it. Eight single-front cabinets, and the warehouse
  # holds eight handles. This is the check that must never go red without
  # somebody deciding it should.
  eight = Array.new(8) { export_attrs('CR0631', 'hardware_ref' => 'M00001') }
  total = Export.rows(eight).select { |r| r['code'] == 'M00001' }
               .map { |r| r['qty'] }.reduce(0) { |a, b| a + b.to_i }
  raise "expected 8 handles, got #{total.inspect}" unless total == 8
end

check('TWO DOORS TAKE TWO HANDLES - the case that proves it is not per cabinet') do
  # 8 -> 8 alone cannot tell "one per cabinet" from "one per front": every
  # cabinet in that example has one front. CR1230 is where the two rules
  # disagree, and the registry already says which is right - vertical_split,
  # count 2. Two doors are two things a hand opens.
  raise 'a two-door tall unit takes two handles' unless handle_row('CR1230')['qty'] == 2
end

check('a drawer stack takes one handle per drawer front') do
  # 2 drawers + 1 jumbo = three fronts, read off heights_mm_top_to_bottom.
  raise 'three fronts, three handles' unless handle_row('B80653')['qty'] == 3
end

check("a corner unit's fixed 8x8 filler opens on nothing, so it takes one") do
  raise 'a corner takes one handle, for its one door' unless handle_row('AU110D')['qty'] == 1
end

check('THE COUNT IS OUR READING, AND THE ROW SAYS SO') do
  # Rule 4 in its enforceable form. The catalog never prints how many handles
  # an article takes. If this ever silently becomes a claim about Cesar, the
  # note is where the lie would live, so the note is what is pinned.
  note = handle_row('CR0631')['note'].to_s
  raise note.inspect unless note.include?('OUR reading')
  raise 'it must name what could confirm it' unless note =~ /position 14|estimate/
  raise 'it must say what the count is per' unless note.include?('per opening front')
end

check('an unknown front_layout gives nil, never a plausible number') do
  # Rule 7 at the exporter boundary, twice: a shape nobody has taught it, and
  # a code the registry has never heard of. Neither may guess 1.
  raise 'an unteachable layout must be nil' unless
    Export.fronts_in('kind' => 'origami').nil?
  raise 'a missing layout must be nil' unless Export.fronts_in(nil).nil?
  raise 'an unknown code must not blow up an export' unless
    Export.front_layout_for('code' => 'NOSUCH').nil?
end

check('a gola unit never reaches the handle count at all') do
  # It has no handle - it has a profile. The guard is that no hardware row is
  # emitted, not that the count comes out right.
  gola = export_attrs('B80601').merge(
    Panel.attributes_patch(Registry.lookup('B80601'),
                           'door_version' => '75', 'gola_system' => 'L-shaped'))
  handles = Export.rows([gola]).select { |r| r['code'].to_s.start_with?('M000') }
  raise handles.inspect unless handles.empty?
end

check('companions become child rows carrying their own qty and um') do
  rows = Export.rows([export_attrs('V80730')])
  kids = rows.select { |r| r['level'] == 1 && r['code'] }
  raise kids.map { |k| k['code'] }.inspect unless
    kids.map { |k| k['code'] } == %w[995946 GBBF01]
  raise 'a child row carries no Riga number' unless kids.all? { |k| k['row'].nil? }
  raise kids.first.inspect unless kids.first['um'] == 'PZ' && kids.first['qty'] == 1
  raise 'the note should say why the line is there' unless
    kids.first['note'].include?('implied')
end

check('a variant on a COMPANION nests one level deeper') do
  a = export_attrs('CR0631').merge('companion_refs' => [
    { 'code' => '996PL6', 'qty' => 1, 'um' => 'PZ', 'origin' => 'chosen',
      'variants' => [{ 'key' => 'FINISH', 'value' => 'Stainless steel' }] }
  ])
  rows = Export.rows([a])
  kit = rows.find { |r| r['code'] == '996PL6' }
  fin = rows.find { |r| r['description'] == 'FINISH: Stainless steel' }
  raise 'the kit must be a child of the unit' unless kit['level'] == 1
  raise 'its finish must be a child of the KIT' unless fin && fin['level'] == 2
  raise 'a chosen line must say so' unless kit['note'].include?('chosen')
end

check('an unresolved companion is SHOWN, not swallowed') do
  a = export_attrs('CR0631').merge('companion_refs' => [
    { 'code' => nil, 'qty' => 1, 'um' => 'PZ', 'origin' => 'chosen' }
  ])
  row = Export.rows([a]).find { |r| r['level'] == 1 }
  raise 'the row must still appear' unless row
  raise row['description'].inspect unless row['description'].to_s.include?('UNRESOLVED')
end

check('the schedule carries no commercial column, and CSV quotes what it must') do
  bad = Export::COLUMNS.select { |c| Contract::COMMERCIAL_MARKERS.any? { |m| c.include?(m) } }
  raise bad.inspect unless bad.empty?
  text = Export.csv(Export.rows([export_attrs('B80601')]))
  head = text.lines.first.chomp
  raise head unless head == Export::COLUMNS.join(',')
  # The description holds commas; a naive join would shift every later column.
  raise 'a comma-bearing field must be quoted' unless text.include?('"Base unit with door - 1 rh or lh door, 1 shelf"')
end

check('numbering is per OBJECT, and children never take a number') do
  rows = Export.rows([export_attrs('B80601'), export_attrs('V80730')])
  numbered = rows.select { |r| r['row'] }
  raise numbered.map { |r| r['row'] }.inspect unless numbered.map { |r| r['row'] } == [1, 2]
  raise 'every numbered row is a top-level one' unless numbered.all? { |r| r['level'] == 0 }
end


puts "\nthe model walk: a rule in the pure module, a click in the glue"

check('ORDERABLE means carries a code - and the niche is why') do
  # An appliance niche is drawn and never ordered. It is not skipped by a
  # special case in the walk; it simply has no code, because the generator
  # gives it none and marks it manufacturer = client. Contract §2: the
  # dictionary is what tools read, so the dictionary answers.
  niche = Generator.niche_attributes_for(Registry.lookup('V80730'), 600, true)
  raise 'a niche must not be orderable' if Export.orderable?(niche)
  raise 'and it must not be orderable because of its class, but its code' unless
    niche['code'].to_s.empty?
  raise 'a cabinet must be' unless Export.orderable?(Generator.attributes_for(Registry.lookup('B80601')))
  raise 'nil must not blow up the walk' if Export.orderable?(nil)
end

check('the FILTER lives in the pure module, so no caller can lose it') do
  # If this test only checked the glue, the guarantee would live where the
  # headless suite cannot see it - exactly how the gola pairing was lost.
  niche = Generator.niche_attributes_for(Registry.lookup('V80730'), 600, true)
  mixed = [Generator.attributes_for(Registry.lookup('B80601')), niche,
           Generator.attributes_for(Registry.lookup('CR0631'))]
  rows  = Export.rows(mixed)
  codes = rows.select { |r| r['level'].zero? }.map { |r| r['code'] }
  raise codes.inspect unless codes == %w[B80601 CR0631]
  raise 'numbering must not skip the object it refused' unless
    rows.select { |r| r['row'] }.map { |r| r['row'] } == [1, 2]
end

check('86_export_run is GLUE - it holds no rules') do
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/86_export_run.rb', __dir__))
  code = src.gsub(/^\s*#.*$/, '')
  # It may TOUCH SketchUp - that is its whole reason to exist - but the
  # decisions must be borrowed, not made here.
  raise 'the orderable rule must come from Export' unless code.include?('Export.orderable?')
  raise 'row shaping must come from Export' unless code.include?('Export.rows')
  raise 'CSV rendering must come from Export' unless code.include?('Export.csv')
  raise 'no row shape may be built in the glue' if code =~ /'level'\s*=>|"level"\s*=>/
  raise 'no unit of measure may be decided in the glue' if code =~ /\bPZ\b|\bML\b|\bMQ\b/
end

check('the palette actually offers it, under a name JavaScript allows') do
  pal = File.read(File.expand_path('../src/ucon_cabinet_engine/core/90_palette.rb', __dir__))
  raise 'no callback' unless pal.include?("add_action_callback('export_order')")
  raise 'no button' unless pal.include?('sketchup.export_order()')
  # `export` is a reserved word in JavaScript, so a button calling it is a trap
  # that works until an engine decides it should not. Match the BUTTON form,
  # not the bare substring: this file explains itself in prose, and prose that
  # names the thing it warns about is not the thing. (It failed exactly that
  # way on the first run - for the second time today.)
  raise 'do not wire a button to export()' if pal =~ /onclick="sketchup\.export\(\)"/
end


puts "\nthe gola profile as an ORDER LINE (0.49.0)"

check('leaving gola takes the profiles away with it') do
  # The half nobody would have noticed: a front that stops being gola must stop
  # ordering a grip recess. Before 0.44.0 the contract could not even erase the
  # key, so this is two fixes meeting.
  u = Registry.lookup('B81253')
  gola = Generator.attributes_for(u).merge(
    Panel.attributes_patch(u, 'door_version' => '75', 'gola_system' => 'L-shaped'))
  raise 'setup failed' unless gola['companion_refs'].map { |l| l['code'] } == %w[GOL001 GOL002]

  back = gola.merge(Panel.attributes_patch(u, 'door_version' => '78',
                                              'opening_method' => 'handle',
                                              'hardware_mode' => 'client'))
  raise back['companion_refs'].inspect unless back['companion_refs'].nil?

  e = StubEntity.new
  Contract.write!(e, gola)
  Contract.write!(e, back)
  raise 'a grip recess must not survive on a handled door' if
    Contract.read(e).key?('companion_refs')
end

check('the system is read back off the codes, never stored twice') do
  u = Registry.lookup('B80601')
  attrs = Generator.attributes_for(u).merge(
    Panel.attributes_patch(u, 'door_version' => '75', 'gola_system' => 'straight'))
  raise Panel.gola_system_of(attrs).inspect unless Panel.gola_system_of(attrs) == 'straight'
  raise 'the dialog must preselect it' unless
    Panel.selection_state(u, attrs)['gola_system'] == 'straight'
  # Storing the system alongside the codes would be a second copy to keep true.
  raise 'the system must not become a key of its own' if attrs.key?('gola_system')
  raise 'and it is not a contract key at all' if Contract::KEYS.include?('gola_system')
end

check('SENTINEL: no joined pseudo-code may reach an object or an order') do
  # "GOL001+GOL002" read fine in a dropdown and reached a real export as an
  # article that does not exist. It cannot come back through any door.
  u = Registry.lookup('B81253')
  attrs = Generator.attributes_for(u).merge(
    Panel.attributes_patch(u, 'door_version' => '75', 'gola_system' => 'L-shaped'))
  text = Export.csv(Export.rows([attrs]))
  raise 'a composite code is in the schedule' if text =~ /GOL\d+\+/
  raise 'a composite code is on the object' if
    attrs['companion_refs'].any? { |l| l['code'].to_s.include?('+') }
  raise 'and the panel must not offer one' if
    Panel.gola_options(u).any? { |o| o['value'].to_s.include?('+') }
end

# ---- fillers and closing strips, printed p.434 ------------------------
#
# The third order axis outside the code, and the first that is a DIMENSION.
# claude/fillers-recon-2026-08-23.md is the reading these pin.

FILLER_CODES = %w[B70151 B70150 PB0151 PD0151 CQ0151].freeze

check('every filler extracted from printed p.434 is in the registry') do
  missing = FILLER_CODES.reject { |c| Registry.codes.include?(c) }
  raise "missing: #{missing.join(', ')}" unless missing.empty?
end

check('a filler states a width RANGE and no width') do
  FILLER_CODES.each do |code|
    u = Registry.lookup(code)
    raise "#{code} carries a width_mm the catalog never printed" if u['width_mm']
    raise "#{code} has no width_range_mm" unless u['width_range_mm'] == [23, 150]
    raise "#{code} is not object_class filler" unless u['object_class'] == 'filler'
  end
end

check('a filler cannot be built without the width being asked for') do
  begin
    Registry.with_ordered_width(Registry.lookup('B70150'), nil)
    raise 'a missing width was accepted'
  rescue ArgumentError => e
    raise "wrong refusal: #{e.message}" unless e.message.include?('per order')
  end
end

check('a width outside the printed range is refused, and both ends are not') do
  u = Registry.lookup('B70150')
  [22, 151].each do |w|
    begin
      Registry.with_ordered_width(u, w)
      raise "#{w} mm was accepted"
    rescue ArgumentError => e
      raise "wrong refusal for #{w}" unless e.message.include?('made from 23 to 150')
    end
  end
  raise 'the ends of the range must build' unless
    Registry.with_ordered_width(u, 23)['width_mm'] == 23 &&
    Registry.with_ordered_width(u, 150)['width_mm'] == 150
  raise 'a fractional millimetre is not a width' unless
    begin
      Registry.with_ordered_width(u, '60,5')
      false
    rescue ArgumentError
      true
    end
end

check('SENTINEL: a width may not be ordered for an article that names its own') do
  # The other half of Generator::INSTANCE_KEYS - an object may not out-vote the
  # registry about what article it is. B80601 is 600 wide and that is final; a
  # narrower one is a MODIFICATION with a surcharge (Elda position 4), never a
  # number typed into a dialog.
  begin
    Registry.with_ordered_width(Registry.lookup('B80601'), 560)
    raise 'a typed width was allowed to overwrite the catalog'
  rescue ArgumentError => e
    raise "wrong refusal: #{e.message}" unless e.message.include?('states its own width')
  end
  raise 'and an unranged article must pass through untouched' unless
    Registry.with_ordered_width(Registry.lookup('B80601'), nil)['width_mm'] == 600
end

check('an ordered filler satisfies the contract') do
  # 120 mm, not 600: the whole article tops out at 15 cm.
  u = Registry.with_ordered_width(Registry.lookup('B70150'), 120)
  attrs = Generator.attributes_for(u)
  raise 'the ordered width did not reach the object' unless attrs['width_mm'] == 120
  raise 'object_class' unless attrs['object_class'] == 'filler'
  Contract.validate!(attrs)
end

check('A FILLER INHERITS ITS FAMILY GROUND, which is why it waits for it') do
  base = Registry.lookup('B70150')
  raise 'height' unless base['height_mm'] == 780
  raise 'a base filler stands on the H.78 plinth' unless base['plinth_h_mm'] == 100
  raise 'and on the floor' unless base['mounting'] == 'floor'
  raise 'a wall filler hangs' unless Registry.lookup('PB0151')['mounting'] == 'wall_hung'
end

check('no filler file declares a family-level key of its own') do
  # The load-bearing half of the recon: a family fact belongs in ONE file. A
  # filler file restating height_mm or plinth_h_mm would not raise while it
  # happened to agree - and would raise on the day somebody corrected one of
  # the two copies.
  Dir[File.expand_path('../registry/cesar/fillers_*.json', __dir__)].each do |f|
    stray = ((JSON.parse(File.read(f))['data'] || {}).keys - ['unit_types'])
    raise "#{File.basename(f)} declares #{stray.join(', ')}" unless stray.empty?
  end
end

check('the front-only fillers are held, not buildable, and say why') do
  %w[B70151 CQ0151].each do |code|
    u = Registry.lookup(code)
    raise "#{code} claims to be buildable" if u.fetch('buildable', true)
    raise "#{code} gives no reason" unless
      u['not_buildable_reason'].to_s.downcase.include?('depth')
  end
end

check('the ORDER says the width was chosen, not read off a page') do
  a = Generator.attributes_for(Registry.with_ordered_width(Registry.lookup('B70150'), 96))
  row = Export.rows([a]).first
  raise row.inspect unless row['l_mm'] == 96
  raise 'the schedule does not say the width is ours' unless
    row['note'].to_s.include?('ORDER choice')
  # and an ordinary article must NOT carry that note - 600 is the catalog's.
  plain = Export.rows([Generator.attributes_for(Registry.lookup('B80601'))]).first
  raise plain.inspect unless plain['note'].nil?
end

puts "\nwall units H. 48 (printed p.214-216, read whole 2026-08-23)"
check('the section holds 34 codes in nine types, and the corner is not one of them') do
  rows = Registry.catalog.select { |c| c['section'] == 'Wall units H. 48' }
  raise rows.length.to_s unless rows.length == 34
  raise rows.map { |c| c['type_key'] }.uniq.length.to_s unless
    rows.map { |c| c['type_key'] }.uniq.length == 9
  raise 'the corner must NOT be held - Elda Q7b' if
    rows.any? { |c| c['code'].to_s.start_with?('PC094') }
  raise 'every code in this section begins PC' unless
    rows.all? { |c| c['code'].start_with?('PC') }
end

def registry_files
  Dir[File.expand_path('../registry/cesar/*.json', __dir__)].reject { |f|
    File.basename(f).start_with?('_')
  }.sort
end

check('A COMPOUND UNIT MUST ADD UP - its modules sum to its width, everywhere') do
  # The best arithmetic check a transcription can have: the page states both the
  # overall width and the module split beside every compound row, so a mistyped
  # digit in either shows up here and nowhere else. Scans EVERY registry file -
  # written against wall_h48 and earning its keep the same day, when the two
  # dish-drainer sections brought ten more compound rows.
  checked = 0
  registry_files.each do |file|
    JSON.parse(File.read(file))['data']['unit_types'].each_value do |t|
      t['codes'].each do |row|
        next unless row['modules_mm']

        checked += 1
        raise "#{row['code']}: #{row['modules_mm'].inspect} != #{row['width_mm']}" unless
          row['modules_mm'].sum == row['width_mm']
      end
    end
  end
  raise "expected 57 compound rows, checked #{checked}" unless checked == 57
end

check('a compound is ONE front, not a split - the modules are carcass') do
  # 60+45 and 60+90 are not equal halves, so a compound could never have been
  # drawn as an equal vertical split. The page says "1 top-hung door" across the
  # whole width, and front_layout says single.
  %w[PC1004 PC1504 PC1234 PC2434].each do |code|
    fl = Registry.lookup(code)['front_layout']
    raise "#{code}: #{fl.inspect}" unless fl['kind'] == 'single'
  end
  raise 'PC2434 is 2400 wide' unless Registry.lookup('PC2434')['width_mm'] == 2400
end

check('the finish restrictions are RECORDED and say they are not enforced') do
  blocks = registry_files.flat_map { |file|
    JSON.parse(File.read(file))['data']['unit_types'].each_value
        .map { |t| t['finish_restrictions'] }.compact
  }
  raise blocks.length.to_s unless blocks.length == 21
  blocks.each do |b|
    raise b.inspect unless b['kind'] == 'not_available'
    raise 'a restriction without its page' unless b['source_ref'].to_s.include?('printed p.')
    raise 'must say it is not enforced' unless b['note'].to_s.include?('NOT ENFORCED')
  end
  # Nothing in the engine reads them. That is the point, and it is checked so
  # that the day something does, this check is where the decision is recorded.
  ruby = Dir[File.expand_path('../src/ucon_cabinet_engine/core/*.rb', __dir__)]
  raise 'finish_restrictions must have no reader yet' if
    ruby.any? { |f| File.read(f).include?('finish_restrictions') }
end

check('a width restriction is recorded where the page prints it, and read nowhere') do
  # 'cannot be reduced in width' is printed inside the same prohibition block as
  # the finishes, under the same symbol. It is one of the ten facts waiting on
  # `restrictions`, so it is stored with its page and nothing acts on it.
  # STRUCTURAL, not a roll-call: listing the positions by name meant retyping
  # six entries per family, which is the habit rule 18 punished.
  #
  # CORRECTED 2026-08-23. This check used to assert 'a compound must NOT carry
  # it', which was true of H.36, H.48, H.60, H.72 and H.84 and therefore looked
  # like a rule. printed p.249 prints it on the H.96 compound. FIVE FAMILIES
  # AGREEING IS NOT A RULE - it is five pages that happened to agree, and the
  # sixth is the one that tells you so. What is checked now is that the mark
  # belongs to dish-drainers, that every SIMPLE dish-drainer carries it, and
  # that the compounds DISAGREE among themselves - which is the fact that makes
  # deriving it impossible and reading it necessary.
  fixed = registry_files.flat_map { |file|
    JSON.parse(File.read(file))['data']['unit_types']
        .select { |_, t| t['cannot_be_reduced_in_width'] }.keys
  }
  raise 'nothing carries the restriction' if fixed.empty?
  stray = fixed.uniq.reject { |k| k.start_with?('dish_drainer_') }
  raise "not a dish-drainer: #{stray.inspect}" unless stray.empty?
  # Every simple dish-drainer position in every family we hold carries it.
  simple = registry_files.flat_map { |file|
    JSON.parse(File.read(file))['data']['unit_types']
        .select { |k, _| k.start_with?('dish_drainer_') && !k.include?('compound') }.keys
  }
  raise "a simple position without the mark: #{(simple - fixed).inspect}" unless
    (simple - fixed).empty?
  # And the compounds go both ways, which is the whole point.
  compounds = registry_files.flat_map { |file|
    JSON.parse(File.read(file))['data']['unit_types']
        .select { |k, t| k.include?('compound') && k.start_with?('dish_drainer_') }
        .map { |k, t| [k, !t['cannot_be_reduced_in_width'].nil?] }
  }
  raise 'no compound dish-drainers' if compounds.empty?
  raise 'a compound carrying the mark must be held - printed p.249' unless
    compounds.any? { |_, marked| marked }
  raise 'a compound WITHOUT it must be held too - printed p.218, p.242' unless
    compounds.any? { |_, marked| !marked }
  ruby = Dir[File.expand_path('../src/ucon_cabinet_engine/core/*.rb', __dir__)]
  raise 'it must have no reader yet' if
    ruby.any? { |f| File.read(f).include?('cannot_be_reduced_in_width') }
end

puts "\ndish-drainer units H. 36 and H. 48 (printed p.213, 217-218)"
check('both dish-drainer sections are held WHOLE, 36 codes, nothing gated') do
  h36 = Registry.catalog.select { |c| c['section'] == 'Dish-drainer units H. 36' }
  h48 = Registry.catalog.select { |c| c['section'] == 'Dish-drainer units H. 48' }
  raise h36.length.to_s unless h36.length == 16 && h36.map { |c| c['type_key'] }.uniq.length == 3
  raise h48.length.to_s unless h48.length == 20 && h48.map { |c| c['type_key'] }.uniq.length == 6
  raise 'H.36 dish-drainers are PB' unless h36.all? { |c| c['code'].start_with?('PB') }
  raise 'H.48 dish-drainers are PC' unless h48.all? { |c| c['code'].start_with?('PC') }
end

check('H.60 dish-drainers: 21 codes in six types, the corner left out') do
  rows = Registry.catalog.select { |c| c['section'] == 'Dish-drainer units H. 60' }
  raise rows.length.to_s unless rows.length == 21
  raise rows.map { |c| c['type_key'] }.uniq.length.to_s unless
    rows.map { |c| c['type_key'] }.uniq.length == 6
  raise 'all PD' unless rows.all? { |c| c['code'].start_with?('PD') }
  raise 'the corner must stay out - Elda Q7b' if
    Registry.codes.any? { |c| c.start_with?('OD') }
end

puts "\nwall units H. 72 (printed p.228-233) - three new opening types and the first d.62"
check('PE0696 IS 360 TALL, PRINTED IN THE H.72 SECTION') do
  # The sharpest case yet of "the letter is a lookup, read the row". PE reads
  # H.72 in code_grammar.wall_units; printed p.230 dimensions this elevation 36.
  # A PRINTED DIMENSION OUTRANKS A DECODED LETTER, so the row belongs to family
  # Wall H.36 and lives in its own file - putting it in wall_h72.json would have
  # made the registry state a height the page contradicts.
  u = Registry.lookup('PE0696')
  raise u['height_mm'].to_s unless u['height_mm'] == 360
  raise u['family'].to_s unless u['family'] == 'Wall H.36'
  row = Registry.catalog.find { |c| c['code'] == 'PE0696' }
  raise row.inspect unless row['section'] == 'Wall units H. 72'
  raise 'it is a cabinet, not an appliance panel' unless
    (u['object_class'] || 'cabinet') == 'cabinet'
  # And its neighbours in the same SECTION are 720, which is the whole point.
  others = Registry.catalog.select { |c| c['section'] == 'Wall units H. 72' }
                   .map { |c| Registry.lookup(c['code'])['height_mm'] }.uniq.sort
  raise others.inspect unless others == [360, 720]
end

check('THE MICROWAVE-NICHE UNIT IS ITS SECTION HEIGHT MINUS 360 - three times, and it derives nothing') do
  # An OBSERVATION pinned at two instances so that a third would force a
  # decision rather than slip in as an assumption. THE THIRD ARRIVED on
  # 2026-08-23 - PF0696 is 600 in the H.96 section - AND THE DECISION IS NO.
  # It stays an observation and derives nothing, because all three PRINT their
  # own elevation: a derivation that can only ever agree with a printed number
  # buys nothing and costs the day a family prints something else. What the
  # check enforces is the part that is not arithmetic - each one is held under
  # the family its own HEIGHT names, never the one its letter does.
  #
  # And the roll-call is gone with it (rule 18): it read %w[PE0696 PG0696] and
  # had to be retyped the moment a third turned up.
  niches = Registry.catalog.select { |c| c['code'].to_s.end_with?('96') }
  raise 'the microwave niches have vanished' if niches.length < 3
  raise 'every niche code is a wall code' unless niches.all? { |c| c['class'] == 'wall' }
  raise 'a niche must be its own file, never its section family' unless
    niches.none? { |c| c['family'] == "Wall H.#{c['section'][/H\. (\d+)/, 1]}" }
  niches.each do |row|
    u = Registry.lookup(row['code'])
    section_h = row['section'][/H\. (\d+)/, 1].to_i * 10
    raise "#{row['code']}: #{u['height_mm']} is not #{section_h} - 360" unless
      u['height_mm'] == section_h - 360
    raise "#{row['code']} must sit in the family its height names" unless
      u['family'] == "Wall H.#{u['height_mm'] / 10}"
    raise "#{row['code']} is a cabinet, not an appliance panel" unless
      (u['object_class'] || 'cabinet') == 'cabinet'
  end
end

check('WHERE THE RACK GOES IS READ OFF EACH PAGE - the printed sentence derives nothing') do
  # THIS CHECK USED TO SAY "the widest-unit rack rule appears exactly where
  # there is ONE rack", and it was wrong for a day. printed p.213, p.218, p.225
  # print "In compound wall units, the dish-drainer rack is fitted in the widest
  # unit" beside positions with one rack; printed p.242 has TWO racks and does
  # not print it; so the two looked like one fact. printed p.249 then prints the
  # sentence beside a position that is H.84's twin in every respect - same
  # folding doors, same 60+45 and 60+60 splits, same TWO racks.
  #
  # THE SENTENCE IS BOILERPLATE THE CATALOG APPLIES UNEVENLY. It appears beside
  # SYMMETRIC modules at H.60 (PD0914 is 45+45), where there is no widest unit
  # to fit anything in, and it is absent from PC1811 (90+90) where a dimensioned
  # rack answers instead. So its presence is RECORDED per position, in
  # widest_unit_rack_rule, off the page - and derived from nothing: not from the
  # rack count, not from the module split, not from the family.
  #
  # Note what the old check did NOT do: it did not fail when p.249 arrived. It
  # classified the new position as :one_per_module and went green while the note
  # beside it said something false. A check can only fail on what it looks at,
  # so the fix is to look at the RECORDED sentence and never at a proxy for it.
  compounds = registry_files.flat_map { |file|
    JSON.parse(File.read(file))['data']['unit_types']
        .select { |k, _| k.start_with?('dish_drainer_') && k.include?('compound') }
        .values
  }
  raise 'no compound dish-drainers' if compounds.empty?

  # 1. EVERY compound records whether its page prints the sentence. Missing is
  #    not the same as absent: a position with no field was never read for it.
  compounds.each do |t|
    raise "a compound with no widest_unit_rack_rule: #{t['description']}" unless
      %w[printed absent].include?(t['widest_unit_rack_rule'])
  end

  # 2. The question the sentence answers - which module holds the rack - is
  #    still answered for every compound, by one of three means:
  #      a. the page prints the rule;
  #      b. the page states the rack SIZE against the modules (PC1811);
  #      c. there is one rack PER module, so nothing is placed (PG1092).
  #    A compound answering none of the three would be a position whose
  #    interior nobody can draw.
  answered = compounds.map { |t|
    racks = t['interior_confirmed'].select { |i| i.include?('rack') }
    if t['widest_unit_rack_rule'] == 'printed' then :rule
    elsif racks.any? { |r| r =~ /^1 x \d+ cm/ } then :dimensioned
    elsif racks.any? { |r| r.start_with?('2 ') } then :one_per_module
    end
  }
  raise "a compound with no answer: #{answered.inspect}" if answered.any?(&:nil?)
  raise "all three answers must be in the registry: #{answered.group_by { |x| x }.transform_values(&:length).inspect}" unless
    answered.uniq.sort == %i[dimensioned one_per_module rule]

  # 3. AND THE ANTI-DERIVATION CLAUSE, which is what the day cost. Two
  #    compounds with the SAME rack count disagree about the sentence. While
  #    that is true, nobody can quietly re-derive it; if it ever stops being
  #    true, this line fails and somebody re-reads the pages instead.
  by_racks = compounds.group_by { |t|
    t['interior_confirmed'].select { |i| i.include?('rack') }
     .map { |r| r[/^\d+/].to_i }.sum
  }
  raise 'the counter-example is gone: re-read before deriving anything' unless
    by_racks.any? { |_, ts| ts.map { |t| t['widest_unit_rack_rule'] }.uniq.length == 2 }
end

check('NOT EVERY WALL UNIT IS d.35 - the boiler housings are 620') do
  # Every wall code held before 2026-08-23 was 350 deep, and a check could
  # easily have been written asserting it. printed p.230-231 would have broken
  # it: a boiler housing is as deep as a base unit because a boiler is.
  # STRUCTURAL from the start would have been better: this listed four codes
  # and H.84 doubled them the next hour. The claim is not WHICH codes are deep,
  # it is that DEPTH FOLLOWS THE JOB - a boiler housing is as deep as a base
  # unit because a boiler is, and nothing else in the chapter is.
  deep = Registry.catalog.select { |c| c['class'] == 'wall' && c['depth_mm'] != 350 }
  raise 'the d.62 wall units have vanished' if deep.empty?
  raise deep.map { |c| c['depth_mm'] }.uniq.inspect unless
    deep.map { |c| c['depth_mm'] }.uniq == [620]
  stray = deep.reject { |c| Registry.lookup(c['code'])['description'].include?('boiler housing') }
  raise "deep and not a boiler housing: #{stray.map { |c| c['code'] }.inspect}" unless stray.empty?
  # And the converse: no boiler housing is shallow.
  shallow = Registry.catalog.select { |c|
    Registry.lookup(c['code'])['description'].to_s.include?('boiler housing') && c['depth_mm'] != 620
  }
  raise shallow.map { |c| c['code'] }.inspect unless shallow.empty?
end

check('SUFFIX 04 MEANS TWO DIFFERENT THINGS, and both are in the registry') do
  # The manifest has warned about this since the wall chapter was first read.
  # Now both readings are held, so the warning is evidence rather than caution.
  compound = Registry.lookup('PD1204')   # H.60: one door across 60+60
  stacked  = Registry.lookup('PE1204')   # H.72: two doors, 360 above 360
  raise 'H.60 04 must be a side-by-side compound' unless
    compound['front_layout']['kind'] == 'single' && compound['modules_mm'].nil?
  raise 'H.72 04 must be a stacked pair' unless
    stacked['front_layout']['kind'] == 'horizontal' &&
    stacked['front_layout']['heights_mm_top_to_bottom'] == [360, 360]
  raise 'both are 1200 wide, which is what makes the confusion possible' unless
    compound['width_mm'] == 1200 && stacked['width_mm'] == 1200
  # One counts ONE front, the other TWO - so the suffix decides a quantity.
  raise 'the handle count must differ' unless
    Export.fronts_in(compound['front_layout']) == 1 &&
    Export.fronts_in(stacked['front_layout']) == 2
end

check('the dish-drainer suffix is not the plain one plus a constant') do
  # 31->61, 30->60, 10->12, 04->07, 89->92: offsets 30, 30, 2, 3, 3. THREE
  # different answers across five pairs, and no reason for any of them. Written
  # down so nobody derives a dish-drainer code from a wall code.
  pairs = { 'PE0631' => 'PE0661', 'PE0930' => 'PE0960', 'PE1210' => 'PE1212',
            'PE1204' => 'PE1207', 'PE1289' => 'PE1292' }
  offsets = pairs.map { |plain, dd|
    raise "#{plain} missing" unless Registry.codes.include?(plain)
    raise "#{dd} missing" unless Registry.codes.include?(dd)
    dd[2..].to_i - plain[2..].to_i
  }
  raise "the offsets became constant: #{offsets.inspect}" if offsets.uniq.length == 1
  raise offsets.inspect unless offsets.sort == [2, 3, 3, 30, 30]
end

check('THE COMPOUND PUSH-UP IS NOT THE SAME ARTICLE FROM FAMILY TO FAMILY') do
  # The most tempting simplification on these pages, and the pages refuse it.
  # Anybody who "tidies" these three into one shape breaks this check, which is
  # the whole point of writing it down.
  shape = lambda { |section, key|
    Registry.catalog.select { |c| c['section'] == section && c['type_key'] == key }
            .map { |c| Registry.lookup(c['code']) }
            .map { |u| [u['code'], u['width_mm']] }.sort
  }
  h48 = shape.call('Wall units H. 48', 'wall_compound_2_push_up')
  h60 = shape.call('Wall units H. 60', 'wall_compound_2_push_up')
  raise h48.inspect unless h48 == [['PC1808', 1800]]
  raise h60.inspect unless h60 == [['PD0908', 900], ['PD1208', 1200]]
  raise 'the two families must not share a single width' unless
    (h48.map(&:last) & h60.map(&:last)).empty?

  # And the DISH-DRAINER compound push-up gives a third answer again: absent at
  # H.36, suffix 11 and one code at H.48, suffix 14 and two codes at H.60.
  dd48 = shape.call('Dish-drainer units H. 48', 'dish_drainer_compound_2_push_up')
  dd60 = shape.call('Dish-drainer units H. 60', 'dish_drainer_compound_2_push_up')
  raise dd48.inspect unless dd48 == [['PC1811', 1800]]
  raise dd60.inspect unless dd60 == [['PD0914', 900], ['PD1214', 1200]]
  raise 'H.36 has no compound push-up dish-drainer' unless
    shape.call('Dish-drainer units H. 36', 'dish_drainer_compound_2_push_up').empty?

  # WITHIN a family the two compounds DO agree on widths - which is the half
  # that makes the divergence across families look like a rule until you check.
  raise 'H.60 must agree with itself' unless h60.map(&:last) == dd60.map(&:last)
  raise 'H.48 must agree with itself' unless h48.map(&:last) == dd48.map(&:last)
end

check('the dish-drainer rack gains a second tier at H.60 and nowhere else') do
  tiers = lambda { |section|
    Registry.catalog.select { |c| c['section'] == section }
            .map { |c| Registry.lookup(c['code'])['interior_confirmed'] }
            .flatten.any? { |t| t.to_s.include?('2 tiers') }
  }
  raise 'H.60 must have the two-tier rack' unless tiers.call('Dish-drainer units H. 60')
  raise 'H.36 must not' if tiers.call('Dish-drainer units H. 36')
  raise 'H.48 must not' if tiers.call('Dish-drainer units H. 48')
end

puts "\nwall units H. 96 (printed p.245-249) - the family that broke two derived rules"
check('the two H.96 sections hold 39 codes, and every one of them is PF') do
  wall = Registry.catalog.select { |c| c['section'] == 'Wall units H. 96' }
  dish = Registry.catalog.select { |c| c['section'] == 'Dish-drainer units H. 96' }
  raise wall.length.to_s unless wall.length == 24
  raise dish.length.to_s unless dish.length == 16
  raise 'all PF' unless (wall + dish).all? { |c| c['code'].start_with?('PF') }
  raise 'the corners must stay out - Elda Q7b' if
    Registry.codes.any? { |c| c.start_with?('OF') }
  # 24, not 23: the microwave niche is IN this section and NOT in this family.
  raise wall.map { |c| c['type_key'] }.uniq.length.to_s unless
    wall.map { |c| c['type_key'] }.uniq.length == 9
  heights = wall.map { |c| Registry.lookup(c['code'])['height_mm'] }.uniq.sort
  raise heights.inspect unless heights == [600, 960]
end

check('PF0696 IS THE FIRST MICROWAVE NICHE WITH A SIDE-HINGED DOOR') do
  # Three niche units now, and the third is not the shape of the first two.
  # PE0696 and PG0696 are headed "Wall unit with top-hung door" and are not
  # handed; PF0696 is headed "Wall unit with door - 1 rh or lh door" and is.
  # The name of the position says nothing about its front - which is why the
  # front is read off the page and never carried across from a twin.
  u = Registry.lookup('PF0696')
  raise u['height_mm'].to_s unless u['height_mm'] == 600
  raise u['family'].to_s unless u['family'] == 'Wall H.60'
  raise 'it must be handed' unless u['handed'] == true
  raise 'a side-hinged door takes no hinge_axis' unless
    u['front_layout']['hinge_axis'].nil? && u['front_layout']['kind'] == 'single'
  %w[PE0696 PG0696].each do |code|
    other = Registry.lookup(code)
    raise "#{code} must stay top-hung" unless
      other['front_layout']['hinge_axis'] == 'top' && other['handed'] == false
  end
end

puts "\nwall units H. 120 (printed p.252-254) - the family that swapped its suffixes"
check('the H.120 section holds 23 codes over three pages, and every one of them is PJ') do
  rows = Registry.catalog.select { |c| c['section'] == 'Wall units H. 120' }
  raise rows.length.to_s unless rows.length == 23
  raise 'all PJ' unless rows.all? { |c| c['code'].start_with?('PJ') }
  raise 'the corners must stay out - Elda Q7b' if
    Registry.codes.any? { |c| c.start_with?('OJ') }
  # THE DISH-DRAINERS ARE IN THIS SECTION AND NOT IN ONE OF THEIR OWN. The wall
  # chapter index never names a dish-drainer section at H.120, so printed p.254
  # is held as a PAGE of the section whose range contains it - rule 1 untouched.
  dish = rows.select { |c| c['type_key'].to_s.start_with?('dish_drainer_') }
  raise dish.length.to_s unless dish.length == 9
  raise 'the reason must travel with the file, not with our memory of it' unless
    JSON.parse(File.read(File.expand_path('../registry/cesar/dish_drainer_h120.json', __dir__)))
        .fetch('section_note').downcase.include?('rule 1')
  heights = rows.map { |c| Registry.lookup(c['code'])['height_mm'] }.uniq.sort
  raise heights.inspect unless heights == [840, 1200]
end

check('A SUFFIX DOES NOT DETERMINE THE DEPTH - and H.120 is why that is written down') do
  # PF0601 is a boiler housing 620 deep; PJ0601 is an ordinary door 350 deep.
  # PF0631 is an ordinary door; PJ0631 is a boiler housing. THE DEPTH GOES WITH
  # THE MEANING, so a reader who derived a suffix would not merely mislabel a
  # box - it would build it 270 mm out.
  #
  # AND THIS CHECK CORRECTED THE NOTE THAT COMMISSIONED IT. H.120 was first
  # written up as a clean swap of a rule holding everywhere else; asked to list
  # every ambiguous suffix, the check answered FOUR, and 00 with three readings
  # - a single top-hung door at H.36/H.48/H.60, a boiler-housing pair at
  # H.72/H.84/H.96, a plain pair at H.120. There was no rule to swap.
  #
  # STRUCTURAL: the claim is not which suffixes swapped, it is that AT LEAST ONE
  # two-digit suffix carries two different depths in this chapter. While that is
  # true the suffix cannot be a shortcut. If it ever stops being true, this
  # fails and somebody re-reads before writing a decoder.
  by_suffix = Hash.new { |h, k| h[k] = [] }
  Registry.catalog.select { |c| c['class'] == 'wall' }.each do |c|
    next unless c['code'].to_s =~ /(\d\d)\z/

    by_suffix[Regexp.last_match(1)] << c
  end
  ambiguous = by_suffix.select { |_, rows| rows.map { |c| c['depth_mm'] }.uniq.length > 1 }
  raise 'no wall suffix carries two depths any more - re-read before deriving one' if
    ambiguous.empty?
  # And on every ambiguous suffix the two readings are a boiler housing and
  # something else, which is the pair that actually costs money.
  ambiguous.each do |suffix, rows|
    kinds = rows.map { |c|
      Registry.lookup(c['code'])['description'].to_s.include?('boiler housing')
    }.uniq
    raise "suffix #{suffix} is ambiguous for some other reason: #{rows.map { |c| c['code'] }.inspect}" unless
      kinds.include?(true) && kinds.include?(false)
  end
end

check('THE N_ELLE FIGURES ARE IN THE FILE AND NOT IN THE BOOK') do
  # Every wall page's text layer carries 'N- Elle' and a figure at H + 2,2, at a
  # normal 7,5 pt, positioned over the perspective drawing. RENDERING EXACTLY
  # THAT BOX AT 400 AND 600 DPI SHOWS BLANK PAPER - white text, or a hidden
  # layer for the N_Elle edition. Four of the five notes that recorded it said
  # 'the elevation carries', which was wrong, and a fifth blamed the render's
  # resolution, which was also wrong. Corrected in place and dated 2026-08-23.
  #
  # The numbers stay because they are in the document; what is checked is that
  # every one of them SAYS it is not printed, so nobody quotes it to Elda as a
  # catalog dimension - and that nothing in the engine reads it.
  noted = registry_files.map { |f| JSON.parse(File.read(f))['data'] }
                        .select { |d| d['overall_height_n_elle_mm'] }
  raise 'the N_Elle figures have vanished' if noted.length < 5
  noted.each do |d|
    raise "#{d['overall_height_n_elle_mm']} without its note" if d['n_elle_note'].to_s.empty?
    raise "#{d['overall_height_n_elle_mm']} must say it is not printed" unless
      d['n_elle_note'].include?('NOT PRINTED')
    raise "#{d['overall_height_n_elle_mm']} is not its family height plus 22" unless
      d['overall_height_n_elle_mm'] == d['height_mm'] + 22
  end
  ruby = Dir[File.expand_path('../src/ucon_cabinet_engine/core/*.rb', __dir__)]
  raise 'nothing may read the N_Elle height yet' if
    ruby.any? { |f| File.read(f).include?('n_elle') }
end

check('A SECTION FILE THAT JOINS AN EXISTING FAMILY DECLARES NO FAMILY KEY') do
  # The rule bc546b2 established, now with four users: three filler files and
  # two dish-drainer files all name a family another file owns. Height, mounting
  # and plinth are stated ONCE. A second copy would not raise while it happened
  # to agree, and would raise the day somebody corrected one.
  joiners = registry_files.select { |f|
    File.basename(f).start_with?('fillers_', 'dish_drainer_')
  }
  raise 'no joining files found' if joiners.empty?
  joiners.each do |f|
    stray = JSON.parse(File.read(f))['data'].keys - ['unit_types']
    raise "#{File.basename(f)} declares #{stray.join(', ')}" unless stray.empty?
  end
end

check('RULE 1 SCOPE: a page the index forgot is mapped as a PAGE, twice now') do
  # printed p.433 forced the note: the printed index is a SUFFICIENT condition
  # for a section, not a necessary one. The wall chapter is the second instance
  # and it is a stronger one, because the omission is inconsistent - every other
  # height in that chapter gets a dish-drainer entry in the index and H.120 does
  # not, while printed p.254 is headed 'Dish-drainer units H. 120' on the page.
  # Both are mapped the same way: as a PAGE of the section whose range contains
  # them, so no section is ever invented and no page is ever lost.
  [['Closing strips and fillers for Maxima and Intarsio', 435],
   ['Wall units H. 120', 254]].each do |section, printed|
    sec = Registry.map_sections.find { |x| x['section'] == section }
    raise "#{section} is not mapped" unless sec
    page = (sec['pages'] || []).find { |pg| pg['printed'] == printed }
    raise "p.#{printed} is not a page of #{section}" unless page
    raise "p.#{printed} must say the index forgot it" unless
      (page['note'].to_s + page['types'].to_s).match?(/ABSENT FROM THE CHAPTER INDEX/i)
  end
  # And neither may exist as a section of its own - that is the half rule 1 guards.
  names = Registry.map_sections.map { |x| x['section'] }
  raise 'a page was promoted to a section' if
    names.any? { |n| n.include?('N_Elle and N_Elle with framed door') } ||
    names.include?('Dish-drainer units H. 120')
end

check('THE DISH-DRAINER SECTION MIRRORS ITS OWN FAMILY') do
  # H.36 has no side-hinged wall unit, and its dish-drainer section has no door
  # type either. H.48 has both. The sections are not independent of the family
  # they sit in - which is the same fact that makes a filler wait for its family.
  side_hinged = lambda { |section|
    Registry.catalog.select { |c| c['section'] == section }
            .map { |c| Registry.lookup(c['code']) }
            .any? { |u| %w[door doors].include?(u['opening']) && !u['front_layout']['hinge_axis'] }
  }
  raise 'H.36 wall units must have no side-hinged door' if side_hinged.call('Wall units H. 36')
  raise 'H.36 dish-drainers must have none either' if side_hinged.call('Dish-drainer units H. 36')
  raise 'H.48 wall units must have one' unless side_hinged.call('Wall units H. 48')
  raise 'H.48 dish-drainers must have one' unless side_hinged.call('Dish-drainer units H. 48')
end

check('PC0151 inherits Wall H.48 - it hangs, and it is 480 tall') do
  u = Registry.lookup('PC0151')
  raise u['height_mm'].to_s unless u['height_mm'] == 480
  raise u['mounting'].to_s unless u['mounting'] == 'wall_hung'
  raise 'the filler must still carry a range and no width' unless
    u['width_range_mm'] == [23, 150] && u['width_mm'].nil?
end

check('a filler states its front_layout instead of letting a default invent one') do
  FILLER_CODES.each do |code|
    fl = Registry.lookup(code)['front_layout']
    raise "#{code} has no front_layout" unless fl && fl['kind'] == 'single'
    raise "#{code} claims a hinge axis it has no leaf for" if fl['hinge_axis']
  end
end

check('REGRESSION: every rebuild sees the ordered width, or the front collapses') do
  # 2026-08-23, found in SketchUp and not here: "Non-positive dimension for
  # FRONT: w=". Panel.apply re-reads the registry row, and a filler row has no
  # width - THE THIRD INSTANCE OF RULE 11, in the very method written to settle
  # the second. Every layer involved is pure, so the suite could have caught it
  # and did not. This is that sweep.
  Registry.codes.each do |code|
    row = Registry.lookup(code)
    next unless row.fetch('buildable', true)

    ordered = row['width_range_mm'] ? Registry.with_ordered_width(row, row['width_range_mm'][0]) : row
    attrs   = Generator.attributes_for(ordered)
    # A fresh lookup, exactly as Panel.apply does it - the object is the only
    # place the ordered width survives.
    chosen  = Generator.effective(Registry.lookup(code), attrs)
    [Generator.front_slabs(chosen),
     Panel.effective_slabs(chosen, false)].each do |slabs|
      bad = slabs.reject { |sl| sl[:w_mm].to_f > 0 && sl[:h_mm].to_f > 0 }
      raise "#{code}: #{bad.inspect}" unless bad.empty?
    end
  end
end

check('and the gola version of a filler front is 750 at the ordered width') do
  attrs  = Generator.attributes_for(Registry.with_ordered_width(Registry.lookup('B70150'), 50))
  chosen = Generator.effective(Registry.lookup('B70150'), attrs)
  slabs  = Panel.effective_slabs(chosen, true)
  raise slabs.inspect unless slabs.length == 1 &&
                             slabs[0][:w_mm] == 50 && slabs[0][:h_mm] == 750
end

check('SENTINEL: a rebuild may not smuggle a width outside the printed range') do
  attrs = Generator.attributes_for(Registry.with_ordered_width(Registry.lookup('B70150'), 50))
  begin
    Generator.effective(Registry.lookup('B70150'), attrs.merge('width_mm' => 900))
    raise 'an edited object widened the article'
  rescue ArgumentError => e
    raise "wrong refusal: #{e.message}" unless e.message.include?('made from 23 to 150')
  end
end

check('REGRESSION: a unit that hangs BY NATURE must not tick the wall-hung box') do
  # Found in SketchUp on PC0631: "Apply failed: PC0631 cannot be ordered
  # wall-hung: it already hangs." The dialog initialised the box from `mounting`
  # - the RESULT - and a wall unit's result is always wall_hung, so the hidden
  # box ticked itself and apply asked for something the guard rightly refuses.
  #
  # The box is a record of a CHOICE. selection_state decides what it shows.
  wall = Registry.lookup('PC0631')
  attrs = Generator.attributes_for(wall)
  raise 'a wall unit must already be hanging' unless attrs['mounting'] == 'wall_hung'
  st = Panel.selection_state(wall, attrs)
  raise 'the option must not be offered at all' if st['wall_hung_available']
  raise 'and the box must not be ticked' if st['wall_hung_chosen']

  # THE PAYLOAD THE DIALOG WOULD NOW BUILD must go through without raising, and
  # must leave the unit hanging - by nature, with no chosen line.
  patch = Panel.attributes_patch(wall, 'opening_method' => 'handle',
                                       'hardware_mode' => 'factory',
                                       'hardware_ref' => 'M00001',
                                       'hinge_side' => 'rh',
                                       'wall_hung' => st['wall_hung_chosen'])
  raise patch['mounting'].to_s unless patch['mounting'] == 'wall_hung'
  raise 'a wall unit must never order the fixing surcharge' if
    Array(patch['companion_refs']).any? { |l| l['origin'] == 'chosen' }
  Contract.validate!(attrs.merge(patch))

  # AND THE OLD PAYLOAD IS STILL REFUSED - the guard was right and stays.
  begin
    Panel.attributes_patch(wall, 'opening_method' => 'handle',
                                 'hardware_mode' => 'factory',
                                 'hardware_ref' => 'M00001',
                                 'wall_hung' => true)
    raise 'the guard stopped refusing'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('it already hangs')
  end
end

check('a BASE unit chosen to hang still ticks the box, and still orders 989410') do
  # The other half: for a base unit the box is a real choice, so a unit already
  # hung must come back ticked or the next apply would silently unhang it.
  base = Registry.lookup('B80601')
  hung = Generator.attributes_for(base).merge(
    Panel.attributes_patch(base, 'opening_method' => 'handle',
                                 'hardware_mode' => 'client',
                                 'wall_hung' => true))
  st = Panel.selection_state(base, hung)
  raise 'the option must be offered' unless st['wall_hung_available']
  raise 'the box must come back ticked' unless st['wall_hung_chosen']
  raise 'the fixing surcharge must be on the line' unless
    Array(hung['companion_refs']).any? { |l| l['code'] == '989410' && l['origin'] == 'chosen' }
end

check('the dialog reads the box from selection_state, not from mounting') do
  html = Panel.html
  raise 'the HTML must not decide this' if html.include?("mounting==='wall_hung'")
  raise 'it must read the pure answer' unless html.include?('st.wall_hung_chosen')
end

check('the picker offers a filler by HEIGHT, with preset widths beside the box') do
  html = Palette.picker_html(Registry.catalog, Registry.gaps, false)
  # Rows are depths and the buttons carry the height - PB0151 and PD0151 are
  # both d.35 and differ only in height, so one row per code read as two
  # identical rows. The width is not on a button at all; it is typed, with
  # 5 / 10 / 15 cm offered because printed p.11 asks for AT LEAST 5 cm.
  raise 'no height buttons' unless html.include?("'H. ' + (c.height_mm/10)")
  raise 'no width presets' unless html.include?('[50, 100, 150]')
  raise 'a preset outside the range must not be offered' unless
    html.include?('mm >= lo && mm <= hi')
  raise 'the ordered width must still be typeable' unless html.include?("inp.type = 'number'")
end

check('a filler is never offered the wall-hung surcharge') do
  # printed p.548 sells it for base and tall UNITS. wall_hung_available? already
  # refuses anything that is not a cabinet, so this costs nothing - but the
  # filler is the first object_class to exercise that arm.
  raise 'a filler was offered a fixing kit' if
    Generator.wall_hung_available?(Registry.lookup('B70150'))
end


puts "\nbase and sink units H. 58.5 (printed p.32-35, read whole 2026-08-24)"
check('the two H.58.5 sections hold 77 codes, and every prefix names its depth') do
  rows = Registry.catalog.select { |c|
    ['Base units H. 58.5', 'Sink base units H. 58.5'].include?(c['section'])
  }
  raise rows.length.to_s unless rows.length == 77
  raise 'the base section holds 53' unless
    rows.count { |c| c['section'] == 'Base units H. 58.5' } == 53
  # THE PREFIX IS A (FAMILY x DEPTH) KEY AND THIS IS THE CHECK THAT SAYS SO.
  # B3 / B6 / B4 is not alphabetical and it is not the H.78 mapping: sorting
  # the letters would put d.62 in the middle. Written against the family the
  # third time the catalog printed an out-of-order prefix trio.
  want = { 350 => 'B3', 470 => 'B6', 620 => 'B4' }
  bad = rows.reject { |c| c['code'].start_with?(want[c['depth_mm']].to_s) }
  raise "prefix does not match depth: #{bad.map { |c| [c['code'], c['depth_mm']] }.inspect}" if bad.any?
end

check('H.58.5 stands on 100 and its doors are 58,5 / 55,5') do
  u = Registry.lookup('B30601')
  raise u['plinth_h_mm'].inspect unless u['plinth_h_mm'] == 100
  raise u['height_mm'].inspect unless u['height_mm'] == 585
  raise u['door_versions'].inspect unless
    u['door_versions']['full_mm'] == 585 && u['door_versions']['gola_mm'] == 555
  # A SINK CODE READS THE SAME FAMILY FACTS THROUGH A FILE THAT STATES NONE.
  v = Registry.lookup('B40661')
  raise v.values_at('plinth_h_mm', 'height_mm').inspect unless
    v['plinth_h_mm'] == 100 && v['height_mm'] == 585
end

check('THE PULL-OUT DOOR IS THE ONE POSITION THIS FAMILY DRAWS ONCE') do
  # printed p.32 prints 58,5 alone over the pull-out door and 58,5 / 55,5 over
  # every other position in the section - where the SAME position at H.78,
  # printed p.36, prints 78 / 75. So a door version can be an ARTICLE fact and
  # door_versions is a FAMILY key, which means the panel will still offer
  # B30100 a 55,5 it has never seen printed. The gap is not fixed here; it is
  # PINNED, so that the day the axis narrows this check is what fails.
  base = JSON.parse(File.read(File.expand_path('../registry/cesar/base_h58_5.json', __dir__)))
  types = base['data']['unit_types']
  po = types['base_pull_out_door']
  raise 'the pull-out door must carry NO gola stack' if po['front_layout']['gola_stack_top_to_bottom']
  raise 'and it must say why, in the registry' unless
    po['door_version_note'].to_s.include?('ONE HEIGHT')

  drawn = %w[base_door base_doors base_jumbo_drawer_interior_drawer base_drawer_jumbo_drawer]
  missing = drawn.reject { |k| types[k]['front_layout']['gola_stack_top_to_bottom'] }
  raise "these positions print both elevations and must stack: #{missing.inspect}" if missing.any?

  # The family still offers the choice, because that is where the key lives.
  raise 'the family key must still be there' unless
    Registry.lookup('B30100')['door_versions']['gola_mm'] == 555
end

check('the split front sums to 585 - and so does its gola stack, over TWO recesses') do
  # 19,5 / 39 handle, 16,5 / 36 gola. The printed gola pair sums to 52,5, not
  # 55,5, and that is not an error: both fronts lose 30, one under the worktop
  # and one at the groove between them. The arithmetic is the only thing that
  # says so.
  base = JSON.parse(File.read(File.expand_path('../registry/cesar/base_h58_5.json', __dir__)))
  fl = base['data']['unit_types']['base_drawer_jumbo_drawer']['front_layout']
  raise fl['heights_mm_top_to_bottom'].inspect unless fl['heights_mm_top_to_bottom'] == [195, 390]
  raise 'handle fronts must sum to the family door' unless
    fl['heights_mm_top_to_bottom'].sum == 585
  stack = fl['gola_stack_top_to_bottom']
  raise stack.inspect unless stack.sum { |e| e['h_mm'] } == 585
  raise 'two recesses, not one' unless stack.count { |e| e['kind'] == 'zone' } == 2
  raise 'the fronts are 165 and 360' unless
    stack.select { |e| e['kind'] == 'front' }.map { |e| e['h_mm'] } == [165, 360]
end

check('the compact oven is held, not buildable, and refuses the hung version in WORDS') do
  u = Registry.lookup('B48698')
  raise 'it must be held' unless u['width_mm'] == 600 && u['depth_mm'] == 620
  raise 'and not buildable' if u['buildable']
  raise 'and say why' unless u['not_buildable_reason'].to_s.include?('NO HEIGHT')
  raise 'printed p.34 refuses the hung version' if
    Generator.wall_hung_available?(u)
  # FORTY-SIX ARTICLES REFUSE THE HUNG VERSION AND ONLY FOUR OF THEM SAY SO IN
  # WORDS. The tall families refuse by leaving a glyph off, which is an absence
  # and has to be re-read whenever a page is re-rendered; printed p.34 and
  # printed p.37 refuse in the catalog's own sentence, which does not. The
  # distinction is worth a check because it is the difference between a fact
  # and a reading.
  in_words = registry_files.flat_map { |file|
    JSON.parse(File.read(file))['data']['unit_types'].values
        .select { |t| t['wall_hung'] == false &&
                      t['wall_hung_note'].to_s.start_with?('PRINTED, NOT DERIVED') }
        .flat_map { |t| t['codes'].map { |r| r['code'] } }
  }
  raise in_words.sort.inspect unless in_words.sort == %w[B48698 B48999 B80672 B80972]
end

check('a sink section that joins an existing family declares no family key') do
  # The loader raises when two files disagree about a family fact and says
  # nothing when they agree, which is exactly right and exactly why the SECOND
  # file must stay thin. This one carries height_mm and its unit types, and
  # its page observations live OUTSIDE data where nothing merges them.
  sink = JSON.parse(File.read(File.expand_path('../registry/cesar/sink_base_h58_5.json', __dir__)))
  raise sink['data'].keys.inspect unless sink['data'].keys.sort == %w[height_mm unit_types]
  raise 'the observations must sit outside data' unless sink['page_observations'].is_a?(Array)
end


puts "\nthe suite runs on the Ruby the other Mac actually has"
check('NO RUBY 2.7+ METHOD MAY ENTER THE HEADLESS SUITE OR THE CORE') do
  # THE RULE WAS ALREADY WRITTEN DOWN, AND THAT DID NOT KEEP IT.
  # core/60_generator.rb carries it in a comment - map + compact, not
  # filter_map, "because the headless harness has to run on the Ruby macOS
  # actually ships, which is still 2.6" - and that comment cost nineteen
  # failures on one machine and none on the other to earn. This file then used
  # filter_map anyway, and tally beside it, and the bill arrived on 2026-08-24
  # as ONE failure on the office Mac and a green suite on the laptop.
  #
  # A rule in a comment is a rule nothing enforces. This is the enforcement.
  #
  # core/ is scanned too, not just tools/: the harness LOADS the core files, so
  # a 2.7 method in there breaks the suite on 2.6 exactly as one in here does.
  # SketchUp's own Ruby is far newer and would never notice.
  banned = {
    'filter_map' => '2.7 - use map { }.compact',
    'tally'      => '2.7 - use group_by { |x| x }.transform_values(&:length)',
    'except'     => '3.0 (Hash#except) - use reject { |k, _| ... }',
    'intersect?' => '3.1 - use (a & b).any?'
  }
  files = Dir[File.expand_path('../tools/*.rb', __dir__)] +
          Dir[File.expand_path('../src/ucon_cabinet_engine/**/*.rb', __dir__)]
  offenders = []
  files.sort.each do |file|
    File.readlines(file).each_with_index do |line, i|
      next if line.strip.start_with?('#') # the rule may be DISCUSSED in prose

      banned.each do |method, why|
        offenders << "#{File.basename(file)}:#{i + 1} - #{method} is #{why}" if
          line.include?(".#{method}")
      end
    end
  end
  raise "Ruby 2.7+ methods in a 2.6 harness:\n  #{offenders.join("\n  ")}" unless offenders.empty?

  # And the reason must stay written where it was learned. Deleting the comment
  # would not break anything today, which is exactly why it would get deleted.
  gen = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  raise 'the reason must stay next to the code that learned it' unless
    gen.include?('filter_map is Ruby 2.7')
end

puts "\nthe dishwasher panel: what is DRAWN is not what is ORDERED"
# Andriy, 2026-08-24, off the Avenida Primavera kitchen: the drawn plinth is
# there so the elevation looks right in LayOut; what goes to the warehouse is a
# request for a plinth WITH A CUTOUT.

check('THE FLAG IS ASKED OF THE OBJECT, because family H.78 is 131 other things') do
  # The bug this closes: plinth_continues and appliance_niche were read from
  # the FAMILY, and H.78 is three merged files - the base pages, the sink bases
  # and the appliance panels. Setting either one there to reach one dishwasher
  # would have drawn a plinth inside every base unit in the family and given
  # them all a housing they do not have. There was no way to say it at all.
  fam = Registry.data['families']['H.78']
  raise 'the family must not be the one saying it' if fam.key?('plinth_continues')
  raise 'nor this one' if fam.key?('appliance_niche')
  raise 'a base unit in the same family must be untouched' if
    Registry.lookup('B80601')['plinth_continues']
  raise 'and must still have no housing' unless
    Registry.lookup('B80601')['appliance_niche'].nil?
  # ...while the family stays the right place to say it where every member IS
  # a panel, which is the USA chapter. Both scopes work or the fix is half done.
  raise 'the USA family says it once for all of them' unless
    Registry.data['families']['USA Tall H.210']['plinth_continues'] == true
end

check('the housing hangs on the plinth and ends where the panel ends') do
  u = Registry.lookup('V80630')
  raise Generator.niche_bottom_mm(u).to_s unless
    Generator.niche_bottom_mm(u) == Standards::PLINTH_H_MM
  # NOT WRITTEN IN THE REGISTRY. 100 + 780 is already known to the generator,
  # and an 880 in a JSON file is a second copy that drifts the day a family
  # height moves.
  raise Generator.niche_top_mm(u).to_s unless Generator.niche_top_mm(u) == 880
  raise Generator.niche_height_mm(u).to_s unless Generator.niche_height_mm(u) == 780
  niche = JSON.parse(File.read(File.expand_path('../registry/cesar/appliance_h78.json', __dir__)))['data']['unit_types']['appliance_dishwasher_door']['appliance_niche']
  raise 'the bottom must be named, not numbered' unless niche['bottom'] == 'plinth_top'
  raise 'a second copy of the plinth height has appeared' if niche.key?('bottom_mm')
  raise 'a second copy of the panel top has appeared' if niche.key?('top_mm')
end

check('the model says on itself that the raised housing is drawn, not measured') do
  n = Generator.niche_attributes_for(Registry.lookup('V80630'))
  Contract.validate!(n)
  raise n['notes'] unless n['notes'].include?('Housing drawn 100.0 to 880.0')
  # NOT 'stands on the floor' and NOT 'cutout' - both were already in the
  # generic placeholder sentence every niche carries, so asserting them proved
  # nothing. What must be there is the sentence this change added.
  raise n['notes'] unless n['notes'].include?('reads unbroken on the sheet')
  raise n['notes'] unless n['notes'].include?('ORDERED under it is one with a cutout')
  # The fridge's leftover sentence must not come along: this panel ends exactly
  # where its phantom does.
  raise n['notes'] if n['notes'].include?('closing panel')
end

check('and the fridge keeps the sentence that is true about IT and not about this') do
  n = Generator.niche_attributes_for(Registry.lookup('CR9601'))
  raise n['notes'] unless n['notes'].include?('closing panel')
  raise n['notes'] if n['notes'].include?('reads unbroken')
end

check('DRAWN is not ORDERED, and the file that will be misread says so') do
  # The one place a future reader looks for permission to order plain linear
  # plinth is this section file. What is written there is that the drawn plinth
  # does not claim to be the ordered one. The order side is deferred, not lost.
  raw = File.read(File.expand_path('../registry/cesar/appliance_h78.json', __dir__))
  raise 'the reversal must be dated' unless raw.include?('2026-08-24')
  raise 'the order line must be named' unless raw.include?('WITH A CUTOUT')
  raise 'the 40 mm must stay open, not be quietly resolved' unless
    raw.include?('STILL UNREAD')
  gen = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  raise 'the correction must stay beside the code that changed' unless
    gen.include?('CORRECTED 2026-08-24')
  raise 'and it must distinguish the two' unless gen.include?('ORDERED')
end

# ---------------------------------------------------------------------------
# A NOTE IS A CLAIM, AND A COPIED NOTE IS A COPIED CLAIM (2026-08-24)
#
# One front_layout note was written for fillers_h78.json and pasted verbatim
# into three fillers of other families. It carried family H.78's gola door
# height - 750 - into a wall unit 360 tall and a tall unit 2100 tall, where the
# family declares no door-version axis at all. base_h78.json had said the axis
# was FAMILY-SCOPED since the day it was written, so the registry contradicted
# itself in prose and this suite stayed green through it, because nothing
# looked at prose. Now something does.
# ---------------------------------------------------------------------------

def foreign_front_height_quotes(pairs)
  gola = {}
  pairs.each do |_, raw|
    j  = JSON.parse(raw)
    dv = j['data'] && j['data']['door_versions']
    gola[j['family']] = dv['gola_mm'] if dv.is_a?(Hash) && dv['gola_mm']
  end
  bad = []
  pairs.each do |name, raw|
    fam = JSON.parse(raw)['family']
    raw.scan(/shortens to (\d+)/).flatten.map(&:to_i).uniq.each do |mm|
      next if gola[fam] == mm
      bad << "#{name} (family #{fam}) quotes #{mm}, its family declares #{gola[fam].inspect}"
    end
  end
  bad
end

check('THE PROSE READER PROVES ITSELF before the registry is trusted to it') do
  # Rule 12: run it against the defect it exists for, on a fixture, so a green
  # suite means the reader works and not that today's files happen to agree.
  legal = ['ok.json', '{"family":"H.78","data":{"door_versions":{"gola_mm":750},' \
           '"unit_types":{"x":{"note":"the front shortens to 750 with the run"}}}}']
  broken = ['bad.json', '{"family":"Wall H.36","data":{"door_versions":null,' \
            '"unit_types":{"x":{"note":"the front shortens to 750 with the run"}}}}']
  silent = ['quiet.json', '{"family":"Tall H.210","data":{"unit_types":{"x":{"note":"no claim here"}}}}']

  found = foreign_front_height_quotes([legal, broken, silent])
  raise "the reader is blind: #{found.inspect}" unless found.size == 1
  raise found.first unless found.first.start_with?('bad.json')

  raise 'false positive on a file that makes no claim' unless
    foreign_front_height_quotes([legal, silent]).empty?
end

check('a filler may not quote a front height its own family does not have') do
  pairs = registry_section_files.map { |f| [File.basename(f), File.read(f)] }
  raise 'no registry files found - the glob is wrong' if pairs.empty?
  bad = foreign_front_height_quotes(pairs)
  raise bad.join(' | ') unless bad.empty?
end

check('and the three files that were wrong say so, with the date') do
  %w[fillers_wall_h36.json fillers_wall_h60.json fillers_tall_h210.json].each do |fn|
    raw = File.read(File.expand_path("../registry/cesar/#{fn}", __dir__))
    raise "#{fn}: the correction must be dated" unless raw.include?('2026-08-24')
    raise "#{fn}: it must name what is actually true here" unless
      raw.include?('THIS FAMILY HAS NO DOOR-VERSION AXIS')
    raise "#{fn}: the mistake must not be erased, only demoted" unless
      raw.include?('copied from fillers_h78.json')
  end
  # and the source of the number must still say it is family-scoped
  h78 = File.read(File.expand_path('../registry/cesar/fillers_h78.json', __dir__))
  raise 'fillers_h78.json must warn that its own number does not travel' unless
    h78.include?('NOT PORTABLE')
end

# ---------------------------------------------------------------------------
# Tall units H. 210 | for base unit H. 78 - printed p.116, extracted 2026-08-24
#
# A SECOND SECTION INSIDE AN EXISTING FAMILY. The catalog gives it its own
# letter pair (C5 d.35 / C6 d.62) but the same body: 2100 on a 100 plinth,
# depths 350 and 620. What differs is the FRONT - it is split so the lower part
# is the door of the base unit standing beside it - and a front belongs to the
# unit type, not to the family.
# ---------------------------------------------------------------------------

def t210b78(code)
  u = Registry.lookup(code)
  raise "#{code} is not in the registry" if u.nil?
  u
end

def front_layout_of(type_key)
  j = JSON.parse(File.read(File.expand_path('../registry/cesar/tall_h210_base78.json', __dir__)))
  ty = j['data']['unit_types'][type_key]
  raise "#{type_key} is not in the section file" if ty.nil?
  ty['front_layout']
end

puts "\ntall units H. 210 for base unit H. 78 (printed p.116, read whole 2026-08-24)"

check('the section holds 12 codes, both depths, and inherits the family body') do
  codes = %w[C50551 C50651 C50751 C60551 C60651 C60751
             C50950 C60950 C51560 C51660 C61560 C61660]
  codes.each do |c|
    u = t210b78(c)
    raise "#{c}: height #{u['height_mm']}" unless u['height_mm'] == 2100
    raise "#{c}: plinth #{u['plinth_h_mm']}" unless u['plinth_h_mm'] == 100
  end
  # the section stamp lives on the catalog ROW, not on the resolved unit
  rows = Registry.catalog.select { |r| codes.include?(r['code']) }
  raise "rows #{rows.length}" unless rows.length == 12
  stamped = rows.map { |r| r['section'] }.uniq
  raise stamped.inspect unless stamped == ['Tall units H. 210 | for base unit H. 78']
  raise rows.map { |r| r['class'] }.uniq.inspect unless
    rows.map { |r| r['class'] }.uniq == ['tall']
  d35 = codes.select { |c| t210b78(c)['depth_mm'] == 350 }
  d62 = codes.select { |c| t210b78(c)['depth_mm'] == 620 }
  raise "d.35 #{d35.length} / d.62 #{d62.length}" unless d35.length == 6 && d62.length == 6
  raise 'the d.35 codes must all start C5' unless d35.all? { |c| c.start_with?('C5') }
  raise 'the d.62 codes must all start C6' unless d62.all? { |c| c.start_with?('C6') }
end

check('EVERY CODE OF THE NEW SECTION YIELDS CONTRACT-VALID ATTRIBUTES') do
  %w[C50551 C50651 C50751 C60551 C60651 C60751
     C50950 C60950 C51560 C51660 C61560 C61660].each do |code|
    Contract.validate!(Generator.attributes_for(t210b78(code)))
  end
end

check('THE SPLIT FRONT IS RECORDED, AND IT ADDS UP TO THE CARCASS') do
  # printed p.116: 132 + 78 handle, 132 + 75 gola, on the two door positions;
  # 132 + 39 + 39 and 132 + 36 + 36 on the jumbo-drawer one. The gola version
  # is not a different unit - the missing millimetres are recesses, and the
  # stack including them must still be the 2100 the carcass is.
  { 'tall_door_over_door'      => [[1320, 780],        2070],
    'tall_doors_over_doors'    => [[1320, 780],        2070],
    'tall_door_jumbo_drawers'  => [[1320, 390, 390],   2040] }.each do |key, (handle, gola_fronts)|
    fl = front_layout_of(key)
    raise "#{key}: #{fl['heights_mm_top_to_bottom'].inspect}" unless
      fl['heights_mm_top_to_bottom'] == handle
    raise "#{key}: the handle fronts must be the whole carcass" unless
      handle.inject(0) { |a, b| a + b } == 2100
    stack = fl['gola_stack_top_to_bottom']
    fronts = stack.select { |e| e['kind'] == 'front' }.map { |e| e['h_mm'] }
    zones  = stack.select { |e| e['kind'] == 'zone'  }.map { |e| e['h_mm'] }
    raise "#{key}: gola fronts #{fronts.inspect}" unless
      fronts.inject(0) { |a, b| a + b } == gola_fronts
    raise "#{key}: gola stack must still be 2100" unless
      (fronts + zones).inject(0) { |a, b| a + b } == 2100
    raise "#{key}: every recess is 30" unless zones.all? { |z| z == 30 }
  end
  # AND THE RECESS IS BETWEEN THE FRONTS, NOT ABOVE THEM. On a base unit the
  # undercounter recess is the topmost element of the stack; here the 1320 door
  # stands above it, because the recess lands at the neighbouring worktop line.
  # That is the difference this whole section exists to draw.
  first = front_layout_of('tall_door_over_door')['gola_stack_top_to_bottom'].first
  raise "the stack must start with the 1320 front, got #{first.inspect}" unless
    first['kind'] == 'front' && first['h_mm'] == 1320
end

check('AND THE SPLIT DOES NOT LEAK INTO THE PLAIN H.210 SECTION') do
  # door_versions merges by FAMILY, and this section shares family 'Tall H.210'
  # with tall_h210.json, whose page prints a single elevation 210. Declaring
  # the pair here would hand a plain full-height door a 2070 front the catalog
  # has never printed - which is Elda Q8 at H.58.5, exactly.
  raise 'the new section must not declare door_versions' unless
    t210b78('C50551')['door_versions'].nil?
  raise 'the plain section must not have gained one' unless
    Registry.lookup('CQ0531')['door_versions'].nil?
  raw = File.read(File.expand_path('../registry/cesar/tall_h210_base78.json', __dir__))
  raise 'the absence must be explained, not silent' unless
    raw.include?('DELIBERATELY DECLARES NO data.door_versions')
  raise 'and it must name the consequence for the panel' unless
    raw.include?('80_panel')
end

check('THE WIDTH FIELD IS POSITION-SCOPED, and this one page proves it') do
  # W.45 is 0551 in the first position of printed p.116 and 1560 in the third.
  # Same page, same width, two fields. Nothing may decode the tail.
  raise 'C50551 is W.45' unless t210b78('C50551')['width_mm'] == 450
  raise 'C51560 is W.45' unless t210b78('C51560')['width_mm'] == 450
  raise 'C50651 is W.60' unless t210b78('C50651')['width_mm'] == 600
  raise 'C51660 is W.60' unless t210b78('C51660')['width_mm'] == 600
  # the manifest's width_index would decode 15 as nothing and 05 as 450: if a
  # future reader wires it up, these two rows disagree with it and this fails.
  idx = JSON.parse(File.read(File.expand_path('../registry/cesar/_manifest.json', __dir__)))
        .dig('code_grammar', 'tall_units', 'width_index')
  raise 'the width index must not have grown a 15' if idx.key?('15')
  raise 'the width index must not have grown a 16' if idx.key?('16')
end

check('the hung capacity belongs to the PAIR, and the fixing count is in the data') do
  # printed p.548 heads both rows with '240 Kg capacity per pair' and then
  # differs them by COUNT: 2 fixings for a base, 4 for a tall. Until
  # 2026-08-24 the 240 sat inside the base entry, where it read as a property
  # of base units, and the count existed only as prose in the comment above
  # Generator.wall_hung_ref - so the engine knew a printed number it could not
  # be asked for. Same defect as the copied filler note, one level up.
  w = JSON.parse(File.read(File.expand_path('../registry/cesar/_manifest.json', __dir__)))
       .dig('modifications', 'codes', 'wall_hung')
  raise 'the capacity must be stated once, above both classes' unless
    w['capacity_per_pair_kg'] == 240
  raise 'a class may not carry a capacity of its own' if
    w['base'].key?('capacity') || w['tall'].key?('capacity')
  raise "base fixings #{w['base']['fixings'].inspect}" unless w['base']['fixings'] == 2
  raise "tall fixings #{w['tall']['fixings'].inspect}" unless w['tall']['fixings'] == 4
  raise 'a tall takes two pairs, and that is why it costs twice' unless
    w['tall']['fixings'] == w['base']['fixings'] * 2
  raise 'the correction must be dated' unless w['fixings_note'].include?('2026-08-24')
end

check('AND THE CATALOG STILL HANGS A FULL-DEPTH TALL UNIT') do
  # The question that found the defect: may CR0631 - 600 x 2100 x 620 - hang?
  # printed p.111 says yes, in that position's margin and with the glyph beside
  # both depth bands. Nothing in the registry may quietly narrow that to d.35.
  %w[CQ0331 CQ0531 CQ0631 CQ0731 CR0331 CR0531 CR0631 CR0731].each do |code|
    u = Registry.lookup(code)
    raise "#{code} lost its hung version" unless Generator.wall_hung_available?(u)
    raise "#{code} must order 989411" unless
      Generator.wall_hung_ref(u)['code'] == '989411'
  end
  deep = Registry.lookup('CR0631')
  raise 'CR0631 is the d.62 one' unless deep['depth_mm'] == 620
end

puts "\n#{$checks} checks, #{$failures} failure(s)\n\n"
exit($failures.zero? ? 0 : 1)

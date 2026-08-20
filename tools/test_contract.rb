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
  'schema_version' => '1',
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
        { 'schema_version' => '1', 'object_class' => 'accessory', 'manufacturer' => 'cesar',
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
rejects('the wrong schema_version', with('schema_version' => '2'), 'schema_version must be')
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

puts "\nregistry + generator (M1.4 integration)"
Registry  = UCON::CabinetEngine::Registry
Generator = UCON::CabinetEngine::Generator

check('registry loads and holds 138 codes (103 base + 20 sink + 3 appliance + 12 wall)') do
  n = Registry.codes.length
  raise "got #{n}" unless n == 138
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
check('EVERY registry code yields contract-valid attributes') do
  Registry.codes.each do |code|
    attrs = Generator.attributes_for(Registry.lookup(code))
    Contract.validate!(attrs)
  end
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

check('door 75 -> gola, front 750, GOL profile required and recorded') do
  p = Panel.attributes_patch(U, { 'door_version' => '75', 'hardware_ref' => 'GOL001' })
  raise p.inspect unless p['opening_method'] == 'gola' && p['front_height_mm'] == 750 &&
                         p['hardware_ref'] == 'GOL001' && p['hardware_source'] == 'factory'
end
check('door 75 without a GOL profile is refused') do
  begin
    Panel.attributes_patch(U, { 'door_version' => '75', 'hardware_ref' => '' })
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('GOL')
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
    { 'door_version' => '75', 'hardware_ref' => 'GOL001' },
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
check('panel offers exactly GOL001 and GOL005') do
  codes = Panel.gola_options.map { |r| r['code'] }.sort
  raise codes.inspect unless codes == %w[GOL001 GOL005]
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

check('registry catalog: 138 rows, each with code/dims/description/source') do
  cat = Registry.catalog
  raise cat.length.to_s unless cat.length == 138
  # A corner row is dimensioned by corner_geometry instead of a single width.
  raise 'incomplete row' unless cat.all? { |c|
    c['code'] && c['height_mm'] && c['depth_mm'] &&
    (c['width_mm'] || c['corner_geometry']) &&
    c['description'] && c['source_ref'] && c['type_key']
  }
end

puts "\ngola drawer stack (verified from p.39 elevation)"
check('gola slabs: 360 at 0, 180 at 390, 180 at 570 (zones 30 above jumbo-joint and under worktop)') do
  slabs = Panel.effective_slabs(Registry.lookup('B81253'), true)
  got = slabs.map { |sl| [sl[:h_mm], sl[:z_mm]] }
  raise got.inspect unless got == [[360.0, 0.0], [180.0, 390.0], [180.0, 570.0]]
end
check('gola drawer unit is offered profile PAIRS, both systems') do
  opts = Panel.gola_options(Registry.lookup('B81253'))
  codes = opts.map { |o| o['code'] }.sort
  raise codes.inspect unless codes == ['GOL001+GOL002', 'GOL005+GOL006']
end
check('door unit still gets single undercounter profiles') do
  codes = Panel.gola_options(Registry.lookup('B80601')).map { |o| o['code'] }.sort
  raise codes.inspect unless codes == %w[GOL001 GOL005]
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
    Contract.validate!(Generator.attributes_for(Registry.lookup(code)))
  end
end

check('split storage: every catalog row is stamped with its section and class') do
  cat = Registry.catalog
  bad = cat.reject { |c| c['section'].to_s != '' && c['class'].to_s != '' }
  raise "missing stamps: #{bad.map { |c| c['code'] }.inspect}" unless bad.empty?

  sections = cat.map { |c| c['section'] }.uniq.sort
  raise sections.inspect unless sections == ['Base units H. 78',
                                             'Base units H. 78 | for household appliances',
                                             'Sink base units H. 78',
                                             'Wall units H. 36']
  raise cat.map { |c| c['class'] }.uniq.sort.inspect unless
    cat.map { |c| c['class'] }.uniq.sort == %w[base wall]
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
  by_type = Registry.catalog.group_by { |c| c['type_key'] }.transform_values(&:length)
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
check('the 8x8 filler is one L: both legs 80 long, 22 thick, projecting forward') do
  plan = Generator.corner_parts(Registry.lookup('AU110S'))[:filler_plan]
  xs = plan.map(&:first)
  ys = plan.map(&:last)
  raise plan.inspect unless (xs.max - xs.min) == 80 && (ys.max - ys.min) == 80
  # It stands in FRONT of the front plane: the outermost y is -83, not +55.
  raise ys.min.to_s unless ys.min == -83
  raise ys.max.to_s unless ys.max == -3
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
  # The two pages disagree on which hand they draw, so the hand is never read
  # off a picture. That caution must travel with the data.
  raise 'the drawing caution must be recorded' unless notes.include?('NEVER be read off a picture')
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
  not_buildable = Registry.catalog.reject { |c| c['buildable'] }
  raise not_buildable.map { |c| c['code'] }.inspect unless not_buildable.empty?
  Registry.catalog.select { |c| c['type_key'] == 'base_corner' }.each do |row|
    a = Generator.attributes_for(Registry.lookup(row['code']))
    raise a.inspect unless a['geometry_kind'] == 'corner'
    Contract.validate!(a)
  end
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
check('each waste unit orders the bin kit for its own width') do
  refs = ->(code) { Generator.attributes_for(Registry.lookup(code))['companion_refs'] }
  # P-One, printed p.524: W450 -> 2 bins, W600 -> 3 bins.
  raise refs.call('B80565').inspect unless refs.call('B80565') == '995625'
  raise refs.call('B80665').inspect unless refs.call('B80665') == '995626'
  # Envi Space XL, printed p.525: one kit per width, 30/45/60.
  raise refs.call('B80366').inspect unless refs.call('B80366') == '995603'
  raise refs.call('B80566').inspect unless refs.call('B80566') == '995605'
  raise refs.call('B80666').inspect unless refs.call('B80666') == '995606'
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
  refs = ->(code) { Generator.attributes_for(Registry.lookup(code))['companion_refs'] }
  raise refs.call('V80530').inspect unless refs.call('V80530') == '995945'
  raise refs.call('V80630').inspect unless refs.call('V80630') == '995946'
  # 60 + 15 = 75: the appliance behind a 75 door is still 60 wide, so the
  # filler is the W60 one and GBBF01 makes up the difference.
  raise refs.call('V80730').inspect unless refs.call('V80730') == '995946,GBBF01'
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
check('companion_refs is a contract key (v1.3) and rejects nothing valid') do
  raise 'key missing from the contract' unless Contract::KEYS.include?('companion_refs')
  Contract.validate!(VALID.merge('companion_refs' => '995946,GBBF01'))
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
    down = hung_codes('bottom')
    raise down.inspect unless down ==
      %w[B80614 B90614 PB0525 PB0625 PB0725 PB0925 PB1025 PB1225 V80530 V80630 V80730]
    up = hung_codes('top')
    raise up.inspect unless up == %w[PB0500 PB0600 PB0700 PB0900 PB1000 PB1200]

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
  # Floor to worktop underside: an appliance stands on the floor.
  raise n['height_mm'].to_s unless n['height_mm'] == Standards::PLINTH_H_MM + 780
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
check('the dishwasher kit is recorded: door and filler planned, hob protection not') do
  types = gap_page('p.48')['types']
  door   = types.find { |t| t['title'].include?('dish-washer') }
  filler = types.find { |t| t['title'].start_with?('Filler profile') }
  hob    = types.find { |t| t['title'].include?('induction hob') }
  raise door.inspect unless door && door['status'] == 'planned'
  raise filler.inspect unless filler && filler['status'] == 'planned'
  raise hob.inspect unless hob && hob['status'] == 'not_extracted'
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

check('the wall section is 12 codes in two types, six widths each, all d.35') do
  rows = Registry.catalog.select { |c| c['section'] == 'Wall units H. 36' }
  raise rows.length.to_s unless rows.length == 12
  raise rows.map { |r| r['height_mm'] }.uniq.inspect unless rows.map { |r| r['height_mm'] }.uniq == [360]
  raise rows.map { |r| r['depth_mm'] }.uniq.inspect unless rows.map { |r| r['depth_mm'] }.uniq == [350]
  widths = rows.map { |r| r['width_mm'] }.uniq.sort
  raise widths.inspect unless widths == [450, 600, 750, 900, 1050, 1200]
  raise 'push-up must not have leaked in' if Registry.codes.include?('PB0610')
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
  # The rest of the chapter is an ordinary gap, not a decision - except the
  # one section we have started, which is partial.
  rest = (wall_sections - hoods).map { |s| s['status'] }.uniq.sort
  raise rest.inspect unless rest == %w[not_extracted partial]
end

check('the wall grammar warning travels with the chapter, not with our memory of H.78') do
  h36 = wall_sections.first
  %w[PB PE PG LOOKUP].each do |frag|
    raise "#{frag} missing from the H.36 note" unless h36['note'].to_s.include?(frag)
  end
  unread = wall_sections.select { |s| s['note'].to_s.include?('Family letter not read') }
  raise unread.map { |s| s['family'] }.inspect unless
    unread.map { |s| s['family'] } == %w[H.48 H.60 H.96 H.120]
end

check('the section we started reports pages; the 23 we have not are single rows') do
  wall = Registry.gaps.select { |g| g['class'] == 'wall' }
  sections = wall.select { |g| g['level'] == 'section' }
  raise sections.size.inspect unless sections.size == 23
  raise 'a section we hold must not also be a section gap' if
    sections.any? { |g| g['section'] == 'Wall units H. 36' }

  # Wall units H. 36 is held, so its unextracted pages surface as TYPE rows.
  pages = wall.select { |g| g['level'] == 'type' }.map { |g| g['printed'] }
  raise pages.inspect unless pages == %w[p.211 p.212]
end

check('p.211 is partial by POSITION: push-up is a gap inside a page we hold') do
  g = gap_page('p.211')
  raise g.inspect unless g && g['status'] == 'partial'
  by_title = g['types'].to_h { |t| [t['title'], t['status']] }
  raise by_title.inspect unless by_title == {
    'Wall unit with top-hung door'    => 'extracted',
    'Wall unit with push-up door'     => 'not_extracted',
    'Wall unit with bottom-hung door' => 'extracted'
  }
  push = g['types'].find { |t| t['title'].include?('push-up') }
  raise 'the reason must survive into the row' unless
    push['note'].include?('not hinged') && push['note'].include?('PB0610')
end

puts "\nwhere a unit's geometry starts - one answer, asked not recomputed"
check('base_z_mm is the plinth for a floor unit and the hanging height for a hung one') do
  raise Generator.base_z_mm(Registry.lookup('B80601')).to_s unless
    Generator.base_z_mm(Registry.lookup('B80601')) == Standards::PLINTH_H_MM
  raise Generator.base_z_mm(Registry.lookup('PB0625')).to_s unless
    Generator.base_z_mm(Registry.lookup('PB0625')) == Standards::WALL_MOUNT_BOTTOM_MM
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
                             { 'door_version' => '75', 'hardware_ref' => 'GOL001' })
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

check('the node seats in the angle, and the wasted space is what goes in it') do
  # Reproduces the probe exactly: corner at the origin, wall facing -y,
  # B7091D (right, carcass 900, node 1000x430, d.350) seated at x=100 y=-350.
  o = Placement.corner_origin([0.0, 0.0, 0.0], [0.0, -1.0, 0.0],
                              350.0, 900.0, 1000.0, 'right')
  raise o.inspect unless o.map { |v| v.round(6) } == [100.0, -350.0, 0.0]

  # Its sibling on the other wall of the same corner runs the other way.
  o = Placement.corner_origin([0.0, 0.0, 0.0], [0.0, -1.0, 0.0],
                              350.0, 900.0, 1000.0, 'left')
  raise o.inspect unless o.map { |v| v.round(6) } == [-1000.0, -350.0, 0.0]

  # And the invariant that all of it exists for: whichever execution, the end
  # of the node that touches the corner is the WASTED end, never the carcass.
  f = Placement.frame([0.0, -1.0, 0.0])
  { 'right' => [-100.0, 0.0], 'left' => [900.0, 1000.0] }.each do |exec, (lo, hi)|
    o = Placement.corner_origin([0.0, 0.0, 0.0], [0.0, -1.0, 0.0],
                                350.0, 900.0, 1000.0, exec)
    wasted_edges = [lo, hi].map { |x| Placement.dot(Placement.add(o, Placement.scale(f[:x], x)), f[:x]) }
    raise "#{exec}: wasted is not against the corner" unless
      wasted_edges.map { |v| v.round(6) }.include?(0.0)
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
  check('picker HTML escapes gap text (it comes from a data file)') do
    html = Palette.picker_html([], [{ 'level' => 'section', 'class' => 'base',
                                      'section' => '<script>x</script>', 'printed' => 'p.1',
                                      'status' => 'not_extracted', 'types' => [], 'note' => nil }])
    raise 'unescaped section title reached the HTML' if html.include?('<script>x</script>')
  end
end

puts "\n#{$checks} checks, #{$failures} failure(s)\n\n"
exit($failures.zero? ? 0 : 1)

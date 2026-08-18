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

check('registry loads and holds 126 codes (103 base + 20 sink + 3 appliance)') do
  n = Registry.codes.length
  raise "got #{n}" unless n == 126
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

check('registry catalog: 126 rows, each with code/dims/description/source') do
  cat = Registry.catalog
  raise cat.length.to_s unless cat.length == 126
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
                                             'Sink base units H. 78']
  raise cat.map { |c| c['class'] }.uniq.inspect unless cat.map { |c| c['class'] }.uniq == ['base']
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
  check('the two bottom-hung fronts we hold are the laundry unit and the panel') do
    hung = Registry.catalog.map { |c| Registry.lookup(c['code']) }
                   .select { |u| (u['front_layout'] || {})['hinge_axis'] == 'bottom' }
                   .map { |u| u['code'] }.sort
    raise hung.inspect unless hung == %w[B80614 B90614 V80530 V80630 V80730]
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
  # The rest of the chapter is an ordinary gap, not a decision.
  rest = wall_sections - hoods
  raise rest.map { |s| s['status'] }.uniq.inspect unless
    rest.map { |s| s['status'] }.uniq == ['not_extracted']
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

check('we hold no wall units, so every wall row is a SECTION gap carrying its pages') do
  wall = Registry.gaps.select { |g| g['class'] == 'wall' }
  raise wall.size.inspect unless wall.size == 24
  raise 'a wall gap must sit at section level' unless wall.all? { |g| g['level'] == 'section' }
  h36 = wall.first
  raise h36.inspect unless h36['pages'].map { |p| p['printed'] } == %w[p.211 p.212]
  raise 'p.211 must name the three opening kinds we read' unless
    h36['pages'][0]['types'].map { |t| t['title'] }.size == 3
  raise 'push-up must be flagged as an unsolved symbol' unless
    h36['pages'][0]['note'].downcase.include?('push-up is not a hinged door')
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
  check('picker HTML escapes gap text (it comes from a data file)') do
    html = Palette.picker_html([], [{ 'level' => 'section', 'class' => 'base',
                                      'section' => '<script>x</script>', 'printed' => 'p.1',
                                      'status' => 'not_extracted', 'types' => [], 'note' => nil }])
    raise 'unescaped section title reached the HTML' if html.include?('<script>x</script>')
  end
end

puts "\n#{$checks} checks, #{$failures} failure(s)\n\n"
exit($failures.zero? ? 0 : 1)

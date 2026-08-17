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

check('registry loads and holds 94 codes (74 base + 20 sink base)') do
  n = Registry.codes.length
  raise "got #{n}" unless n == 94
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

check('registry catalog: 94 rows, each with code/dims/description/source') do
  cat = Registry.catalog
  raise cat.length.to_s unless cat.length == 94
  raise 'incomplete row' unless cat.all? { |c|
    c['code'] && c['width_mm'] && c['height_mm'] && c['depth_mm'] &&
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
  raise sections.inspect unless sections == ['Base units H. 78', 'Sink base units H. 78']
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

puts "\ncatalog map + picker gaps (what the printed index says exists)"
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
  printed = Registry.gaps.map { |g| g['printed'] }
  raise printed.inspect if printed.include?('p.44')
  %w[p.45 p.46 p.49-52].each { |p| raise "#{p} missing" unless printed.include?(p) }
end
check('decisions are per position: p.47 excludes 3 of 4 types, keeps the dishwasher door') do
  g47 = Registry.gaps.find { |g| g['printed'] == 'p.47' }
  raise g47.inspect unless g47
  by_status = g47['types'].group_by { |t| t['status'] }
  raise by_status.transform_values(&:size).inspect unless
    by_status['excluded'].to_a.size == 3 && by_status['planned'].to_a.size == 1
  kept = by_status['planned'].first
  raise kept.inspect unless kept['title'].include?('dishwasher')
  by_status['excluded'].each do |t|
    raise "#{t['title']} has no recorded reason" if t['note'].to_s.empty?
  end
end
check('the dishwasher kit is recorded: door and filler planned, hob protection not') do
  types = Registry.gaps.find { |g| g['printed'] == 'p.48' }['types']
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
  g = Registry.gaps.find { |x| x['printed'] == 'p.41' }
  raise g.inspect unless g && g['note'].to_s.include?('do NOT decode')
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
  check('picker HTML escapes gap text (it comes from a data file)') do
    html = Palette.picker_html([], [{ 'level' => 'section', 'class' => 'base',
                                      'section' => '<script>x</script>', 'printed' => 'p.1',
                                      'status' => 'not_extracted', 'types' => [], 'note' => nil }])
    raise 'unescaped section title reached the HTML' if html.include?('<script>x</script>')
  end
end

puts "\n#{$checks} checks, #{$failures} failure(s)\n\n"
exit($failures.zero? ? 0 : 1)

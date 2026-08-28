# frozen_string_literal: true
#
# Headless check of the Object Contract implementation.
#
#   cd ~/dev/ucon-cabinet-engine && ruby tools/test_contract.rb
#
# SketchUp is NOT required and must not be. If this file ever needs SketchUp to
# run, something SketchUp-flavoured has leaked into core/20_contract.rb and the
# leak is the bug — not this test.

require 'digest'
# The panel kit loads with core, not at the end of this file: the panel is
# built by checks far above the kit's own, and it interpolates PanelKit::CSS.
require_relative '../src/ucon_cabinet_engine/core/05_panel_kit'
require_relative '../src/ucon_cabinet_engine/core/08_project'
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
# 95_dev_bridge is pure file-system questions and NEVER loads what it points at,
# which is the whole reason it can be required here at all.
require_relative '../src/ucon_cabinet_engine/core/95_dev_bridge'

Contract  = UCON::CabinetEngine::Contract
Standards = UCON::CabinetEngine::Standards
# Project facts - the numbers that belong to one kitchen. core/08_project.rb.
Project   = UCON::CabinetEngine::Project
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
  FRONT_GAP_MM: 3, PLINTH_H_MM: 100,
  PLINTH_H_ALT_MM: 60, PLINTH_T_MM: 18, PLINTH_SETBACK_MM: 45
}.each do |const, expected|
  check("#{const} == #{expected}") do
    actual = Standards.const_get(const)
    raise "got #{actual}" unless actual == expected
  end
end

check('FRONT_REVEAL_MM is gone and stays gone') do
  # Deleted 2026-08-26 (Andriy). It was declared, marked :confirmed_decision, and
  # read by nothing: fronts are drawn with their faces meeting, here and on the
  # Sub-Zero panels alike. A constant nobody draws reads as intent, and the next
  # person wires it up - so the deletion is pinned rather than trusted.
  raise 'it came back' if Standards.const_defined?(:FRONT_REVEAL_MM)
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core', __dir__) + '/10_standards.rb')
  raise 'the reason must survive the number' unless src.include?('WAS HERE AND IS DELETED')
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

check('registry loads and holds 937 codes (262 base + 44 sink + 9 appliance + 291 wall + 3 glass wall + 8 USA tall + 124 tall + 15 fillers + 124 end panels + 44 panel sheets + 4 Horizontal Thin + 9 shelves)') do
  # 2026-08-27: +44, and they are the first codes here out of a book that is not
  # the Kitchen System - Linear Elements printed p.215-220, panels priced by the
  # square metre. See the source_pdf note in 50_registry.rb -> data.
  n = Registry.codes.length
  raise "got #{n}" unless n == 937
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
    # AND THE HEIGHT CAN BE THE SAME KIND OF ABSENCE, 2026-08-27. A panel sold
    # by the square metre states neither dimension; the sweep orders both, for
    # the same reason it orders the width, and "valid once ordered" stays the
    # honest claim.
    u = Registry.with_ordered_height(u, u['height_range_mm'][0]) if u['height_range_mm']
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

check('registry catalog: 937 rows, each with code/dims/description/source') do
  cat = Registry.catalog
  raise cat.length.to_s unless cat.length == 937
  # THREE ways to be dimensioned, not one. A corner row carries corner_geometry
  # instead of a width; a filler carries the RANGE the catalog prints instead
  # of the width it never prints. A depth is required of anything we offer to
  # build - the front-only fillers have none and do not claim to be buildable.
  raise 'incomplete row' unless cat.all? { |c|
    # A HEIGHT OR THE STATEMENT THAT IT COMES FROM THE ORDER, 2026-08-27.
    # The width clause below has had that escape since the fillers; the height
    # never needed one until a panel priced by the square metre arrived, and
    # the asymmetry was invisible while every article had a printed height.
    c['code'] && (c['height_mm'] || c['height_range_mm']) &&
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
  raise sections.inspect unless sections == ['Adjoining end side panel for N_Elle',
                                             'Adjoining end side panel for N_Elle with framed door',
                                             'Base units H. 39',
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
                                             'End elements for Maxima-Intarsio',
                                             'Glass wall units H. 96',
                                             'Panels - Linear Elements',
                                             'Shelves - Linear Elements',
                                             'Sink base units H. 58.5',
                                             'Sink base units H. 78',
                                             'Tall unit top elements H. 36 | without fixings',
                                             'Tall unit top elements H. 60 | without fixings',
                                             'Tall unit top elements H. 72 | without fixings',
                                             'Tall units H. 138',
                                             'Tall units H. 198',
                                             'Tall units H. 210',
                                             'Tall units H. 210 | for base unit H. 78',
                                             'Tall units H. 222',
                                             'Tall units H. 222 | for base unit H. 78',
                                             'Tall units H. 234',
                                             'Tall units H. 234 | for base unit H. 78',
                                             'Thin | Horizontal Thin H. 39, for base units H. 78',
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
  # 'end_panel' arrived 2026-08-26 with printed p.440-447. Unlike the glass
  # chapter - whose SECTION class is 'glass' while its ROWS stay 'wall', because
  # the object really is a wall unit that hangs - an end panel is not a unit of
  # any class. It is a board beside one, and it spans base, wall and tall
  # heights in a single table. So section and row agree here, and the class is
  # its own.
  # 'panel_sheet' arrived 2026-08-27 with Linear Elements printed p.215-220, and
  # it is deliberately NOT 'end_panel'. Two articles, two classes: the end panel
  # is priced by CABINET height and carries a 45-degree edge into a door; this
  # one is a board sold by the square metre with no height, no hand and no edge
  # detail, out of a different book. Collapsing them would have made the picker
  # offer 168 codes for one question that is really two.
  raise cat.map { |c| c['class'] }.uniq.sort.inspect unless
    cat.map { |c| c['class'] }.uniq.sort == %w[base end_panel filler open_unit panel_sheet shelf tall wall]
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
  # exactly 4. The title says p.36; the count must say p.36 too. Learned rule 18.
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
  # printed p.37 and p.38 added thirteen more (learned rule 18, seventh instance). What
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
  # find every row in one grep. Learned rule 18's lesson pointed the other way for
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
    raise "#{row['code']} must own the inference" unless reason.include?('learned rule 4')
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

check('96 codes refuse the hung version, and every move of that number is dated') do
  # A sweep that changed an availability would be a correction, and a
  # correction gets a dated note of its own (learned rule 9). The printed p.19 sweep
  # changed none, and that is worth pinning: if a later edit quietly flips a
  # true to a false, the count moves and this fails with the reason in its
  # title.
  #
  # 2026-08-24: 46 -> 52, and it is NOT a flip. printed p.116 arrived with
  # twelve new codes, six of which the page refuses - the 2+2 door position
  # (C50950, C60950) and all four jumbo-drawer codes. Nothing already held
  # changed its answer; tall went 42 -> 48 and base stayed at 4.
  #
  # 2026-08-25: 52 -> 65, and it is not a flip either. printed p.121-123 and
  # p.125 arrived with thirteen codes and ALL THIRTEEN refuse: not one of the
  # eight positions carries the margin line. Tall 48 -> 61, base still 4.
  # The fridge unit is the awkward one and is refused DELIBERATELY - its
  # cabinet-in-a-bracket glyph is printed and its surcharge line is not, the
  # mirror image of the Magicorner disagreement on printed p.42, and the
  # priced offer is the one a person can actually order. See tall_fridge's
  # wall_hung_note; the glyph goes to Elda.
  #
  # 2026-08-25, later: 65 -> 75. The ten top elements of printed p.170 and p.173
  # refuse, and they are the FIRST codes in the registry to refuse in the
  # catalog's own words rather than by a missing glyph - the section title is
  # 'without fixings'. Tall 61 -> 71, base still 4.
  refused = Registry.catalog.map { |c| Registry.lookup(c['code']) }
                    .select { |u| u['wall_hung'] == false }
  #
  # 2026-08-25, later still: 75 -> 79. printed p.143 arrived with four codes when
  # Andriy chose H.222 + top H.72 for the east wall, and all four refuse. Tall
  # 71 -> 75, base still 4.
  #
  # 2026-08-25, last move of the evening: 79 -> 92. printed p.172 brought nine
  # top elements and printed p.162 four columns, and all thirteen refuse - the
  # top elements in the catalog's own words again, the columns by the absent
  # glyph. Tall 75 -> 88, base still 4.
  #
  # 2026-08-27: 92 -> 96, and a THIRD class joins. The four Horizontal Thin
  # modules of printed p.459 refuse, and like the top elements they refuse in
  # the catalog's own words rather than by an absent glyph: printed p.458 opens
  # with 'Can only be fitted below a top.' An element that must have a run under
  # it and a top over it is not a thing that hangs. base 4, tall 88, open_unit 4.
  raise refused.length.to_s unless refused.length == 96
  by_class = refused.group_by { |u| u['unit_class'] }.transform_values(&:length)
  raise by_class.inspect unless by_class == { 'base' => 4, 'tall' => 88, 'open_unit' => 4 }
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
    # read - which is exactly how learned rule 18's invariant went unnoticed. What the
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
  # their notes rather than deleted (learned rule 9): each section that spent its letter
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
  # extracted and domain rule 1 forbids inventing the rows. The mechanism is proved
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
  # A rule that lives only in the dialog is not a rule (learned rule 14): the refusal
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

check('a CHOICE the catalog has no opinion about survives the merge that draws it') do
  # THE LED WAS WRITTEN AND NEVER DRAWN, and every part in the chain was right
  # except the join. Panel#apply wrote the variant, Contract encoded, stored and
  # decoded it, Symbols#draw_led knew how to draw it - and Generator.effective,
  # which builds the `chosen` object that apply hands to the drawing, carried
  # only INSTANCE_KEYS and the ordered width. The variant was dropped on the
  # floor between the write and the draw, so draw_led returned at its first line
  # every time, in silence. Fourth instance of learned rule 11 this year: a key
  # written correctly that the thing needing it is never given.
  unit = Registry.lookup('MNS040060')
  raise 'the shelf must be in the registry' unless unit
  raise 'and the registry row has no opinion about lights' unless unit['variants'].nil?

  lit = Generator.effective(unit, 'width_mm' => 1200, 'variants' => [
          { 'key' => 'led', 'value' => 'Sky-B 1197 mm', 'source_ref' => 'printed p.224' }
        ])
  raise 'the choice must reach the object that gets drawn' unless
    Array(lit['variants']).any? { |v| v['key'] == 'led' }
  raise 'and the drawing must be able to find it' unless Symbols.led_variant(lit)
  # An object nobody has lit stays unlit - the merge must not invent one.
  dark = Generator.effective(unit, 'width_mm' => 1200)
  raise 'no light was chosen and none may appear' if Symbols.led_variant(dark)
end

check('THE LIGHT TAKES NO VIEW ON WHICH SIDE IS THE FRONT') do
  # It used to sit 1 mm proud of the face, which meant the symbol ASSERTED a
  # facing - and a facing turned out to be a thing this engine is bad at. Andriy
  # settled it by taking the question away: "Уже не будет значения, где лицо, где
  # не лицо. […] Потому что стены могут быть под разными углами."
  #
  # Half the depth is the one position equally right from either side. The label
  # reads backwards from one of them and that is accepted, not worked around.
  shelf = Registry.lookup('MNS040038')
  raise shelf['depth_mm'].inspect unless shelf['depth_mm'] == 380
  raise 'the light hangs under the middle of the board' unless
    Symbols.led_y_mm(shelf) == 190.0

  # THE SAME RULE FOR EVERYTHING, and that is the point: no branch on class, no
  # branch on front_layout, nothing to get the front wrong with.
  door = Registry.lookup('B80601')
  raise 'a cabinet is treated no differently' unless
    Symbols.led_y_mm(door) == door['depth_mm'].to_f / 2

  # No depth stated is not a reason to raise - the light still gets drawn, on
  # the object's own origin plane.
  raise 'a depthless object still gets its light' unless Symbols.led_y_mm({}) == 0.0
  raise 'and nil must not blow up' unless Symbols.led_y_mm(nil) == 0.0

  # The old signature took the front line as an argument. It must be gone, or a
  # caller could still hand one in and quietly reinstate the claim.
  raise 'led_y_mm must not accept a front line any more' unless
    Symbols.method(:led_y_mm).arity == 1
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
  # Learned rule 7 says unknown is nil - but this is not unknown, it is undeclared,
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
  #
  # THE WITNESS CHANGED 2026-08-26 AND THE RULE DID NOT. This asked CR9601, the
  # USA fridge door, until its datum moved to the floor (owed 10 finding 1) and
  # the check started reporting 0.0 for a rule that was never about that unit.
  # The dishwasher panel still states `bottom: plinth_top`, deliberately and
  # with `bottom_is_representation` beside it, so it is the witness now. A check
  # that follows its subject rather than its example is the point of learned rule 13.
  u = Registry.lookup('V80730').merge('plinth_h_mm' => 60)
  raise u['appliance_niche'].inspect unless u['appliance_niche']['bottom'] == 'plinth_top'
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
  # RENAMED 2026-08-25: the submenu is now the shared 'UCON' root, so a bare
  # 'About' would not say About WHAT with two extensions hanging off it.
  raise items.inspect unless items == ['Cabinet palette…', 'About Cabinet Engine']

  raise 'the shell builds its own submenu instead of the shared root' unless
    shell.include?('UCON.extensions_menu')

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
  # SCOPED TO THE USA CHAPTER ON 2026-08-26, and the reason is the finding.
  # This used to test every code in the registry, on the assumption that a
  # prefix names a family. The end-panel chapter falsified it in one commit:
  # printed p.440 prices BM0030 and printed p.444 prices Y40028, three hundred
  # pages away from the USA elements, and neither has anything to do with them.
  # A PREFIX IS NOT A CHAPTER - which is domain rule 5 arriving from the other side.
  # What the check is actually for survives: nothing may enter the catalog from
  # a USA page we have not extracted.
  usa = Registry.catalog.select { |r| r['section'].to_s.start_with?('USA elements') }
  bad = usa.map { |r| r['code'] }.select { |c| c.start_with?('BL', 'BM', 'C8', 'Y4', 'Y7') }
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
  # CODE ONLY, COMMENTS STRIPPED. This counted every occurrence in the file
  # until 2026-08-25, when a comment elsewhere in the generator referred to this
  # method by name and the count went to four. The check then said the seam had
  # been broken, and nothing had been broken - it had been explained. A check
  # that forbids naming the thing it protects protects nothing.
  code = lambda { |f|
    File.readlines(File.join(core, f)).reject { |l| l.strip.start_with?('#') }.join
  }
  gen   = code.call('60_generator.rb')
  panel = code.call('80_panel.rb')
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

# REVERSED 2026-08-26 (Andriy, owed 10 finding 1), and the reversal is recorded
# rather than the old check deleted. Drawn from the plinth top the opening came
# out 2033,6 tall where the machine needs 2133,6: the TOP was right and the
# HEIGHT was a hundred short, which is why the appliance seam compares both.
# The housing now starts on the FLOOR, and the plinth line in front of it is a
# representation whose ORDERED plinth carries a cutout.
check('the US housing starts on the FLOOR and stops at the appliance cutout') do
  u = Registry.lookup('CR9601')
  raise Generator.niche_bottom_mm(u).to_s unless Generator.niche_bottom_mm(u).zero?
  # 84 in. Measured, not converted from anything of ours.
  raise Generator.niche_top_mm(u).to_s unless Generator.niche_top_mm(u) == 2133.6
  raise Generator.niche_height_mm(u).to_s unless Generator.niche_height_mm(u) == 2133.6
end

check('and it says on itself that the plinth in front of it is a representation') do
  n = Generator.niche_attributes_for(Registry.lookup('CR9601'))
  raise n['notes'] unless n['notes'].include?('FINISHED FLOOR')
  raise n['notes'] unless n['notes'].include?('cutout')
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
  # 'plinth_top' until 2026-08-26, 'floor' since. Either way it is a NAME and
  # not a number, which is what this check has always been about: a datum
  # spelled as a word cannot drift away from the family that owns it.
  raise 'the bottom must be named, not numbered' unless
    %w[floor plinth_top].include?(niche['bottom'])
  raise 'a second copy of the plinth height has appeared' if niche.key?('bottom_mm')
  raise 'the reversal must be recorded, not erased (learned rule 9)' unless
    niche['bottom_correction_2026_08_26'].to_s.include?('2133,6')
  raise 'the section file must point at the measured table' unless
    section.include?('us_appliance_housing_cutouts')
end

check('the housing says on itself that it came from the appliance, not from Cesar') do
  n = Generator.niche_attributes_for(Registry.lookup('CR9601'))
  Contract.validate!(n)
  raise n['notes'] unless n['notes'].include?('INDICATIVE')
  raise n['notes'] unless n['notes'].include?('2133.6')
  raise n['height_mm'].to_s unless n['height_mm'] == 2133.6
  # and since 2026-08-24 a dishwasher says it too, in its own words. What it
  # must NOT borrow is the leftover sentence - see the dishwasher checks below.
end

check('the niche states which of its numbers is measured and which declared') do
  # Owed 10 findings 2 and 3, decided 2026-08-26: the drawing keeps the Cesar
  # door width and the run's depth, and the published cutout is NOT copied onto
  # the object. That decision is only honest if the object says so, because a
  # width that is right for a dishwasher and wrong for a fridge looks identical.
  n = Generator.niche_attributes_for(Registry.lookup('CR9601'))
  raise n['notes'] unless n['notes'].include?('NOMINAL')
  raise n['notes'] unless n['notes'].include?('NARROWER') && n['notes'].include?('WIDER')
  raise 'the required cutout must not be copied onto the object' unless
    n['notes'].include?('ApplianceCheck')
end

puts "\nthe remainder above the housing gets a body - owed 10 finding 4"

check('the filler above the housing validates, and carries no invented article') do
  info = { 'model' => 'DEC3050R/L', 'h_mm' => 66.0, 'bottom_mm' => 2134.0,
           'top_mm' => 2200.0, 'fill' => ['filler'], 'material' => 'carcass',
           'setback_mm' => 55 }
  a = Generator.above_housing_attributes_for(Registry.lookup('CR9700'), info)
  Contract.validate!(a)
  raise a['object_class'] unless a['object_class'] == 'filler'
  raise a.inspect if a['code']
  raise a['code_status'] unless a['code_status'] == 'PRELIMINARY'
  raise a['height_mm'].to_s unless a['height_mm'] == 66.0
  raise a['notes'] unless a['notes'].include?('NO ARTICLE YET')
  # It IS an order line - a filler somebody must make - so the exporter must
  # carry it and say the article is missing rather than drop it.
  raise 'a filler must reach the order' unless Export.orderable?(a)
  raise Export.order_description(a) unless
    Export.order_description(a).include?('NO ARTICLE')
end

check('the filler says it is an ORDER LINE and not a face') do
  # Decided 2026-08-26 by Andriy, after the live run and after the Sub-Zero page
  # was read: the nominal rule keeps the HEIGHT axis too, so the Cesar front is
  # drawn to the top of the run and covers this strip on an elevation. That is
  # the decision, and an object whose body is invisible has to say so - or the
  # next session finds a filler nobody can see and "fixes" the front.
  info = { 'model' => 'DEC3050R/L', 'h_mm' => 66.0, 'bottom_mm' => 2134.0,
           'top_mm' => 2200.0, 'fill' => ['filler'], 'material' => 'carcass',
           'setback_mm' => 55 }
  a = Generator.above_housing_attributes_for(Registry.lookup('CR9700'), info)
  raise a['notes'] unless a['notes'].include?('NOT VISIBLE ON AN ELEVATION')
  raise a['notes'] unless a['notes'].include?('2029')
  raise a['notes'] unless a['notes'].include?('ORDER LINE')
  # And it must still reach the order, which is the whole point of drawing it.
  raise 'an invisible body that is not ordered is nothing at all' unless Export.orderable?(a)
end

check('and NOTHING is drawn until a machine is named') do
  # The height, the setback and the material are all the appliance module's.
  # The engine owns only where the run's top is, so a body drawn without a
  # named machine would be three guesses wearing one box. Same shape as B6.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  body = src[/def draw_above_housing.*?\n      end\n/m] or raise 'draw_above_housing has gone'
  raise 'it must refuse without an appliance' unless body.include?('return nil unless appliance')
  raise 'it must refuse without the seam' unless body.include?('ApplianceCheck.available?')
  raise 'the setback must come from the seam, never from a constant' if body =~ /\b55\b/
  raise 'the height must come from the seam' unless body.include?("info['h_mm']")
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
  # Learned rule 12. Run it against the defect it exists for, on a fixture, so that a
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
  # W.750 has no kit on printed p.569 at all. Learned rule 7 applied to articles:
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
  # per-unit filter would be a rule generalising past its evidence (learned rule 4).
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
  # Learned rule 4 in its enforceable form. The catalog never prints how many handles
  # an article takes. If this ever silently becomes a claim about Cesar, the
  # note is where the lie would live, so the note is what is pinned.
  note = handle_row('CR0631')['note'].to_s
  raise note.inspect unless note.include?('OUR reading')
  raise 'it must name what could confirm it' unless note =~ /position 14|estimate/
  raise 'it must say what the count is per' unless note.include?('per opening front')
end

check('an unknown front_layout gives nil, never a plausible number') do
  # Learned rule 7 at the exporter boundary, twice: a shape nobody has taught it, and
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

check('ORDERABLE means somebody has to make it - and the niche is still why') do
  # An appliance niche is drawn and never ordered. It is not skipped by a
  # special case in the walk; the generator marks it manufacturer = CLIENT, and
  # Contract §2 says the dictionary is what tools read.
  #
  # THE RULE WAS 'CARRIES A CODE' UNTIL 2026-08-25, which got the niche right
  # for the wrong reason: a niche has no code AND no maker, and the test read
  # the wrong half. See the next check for what that cost.
  niche = Generator.niche_attributes_for(Registry.lookup('V80730'), 600, true)
  raise 'a niche must not be orderable' if Export.orderable?(niche)
  raise 'and the reason must be its maker, not its code' unless
    niche['manufacturer'].to_s == 'client'
  raise 'a cabinet must be' unless Export.orderable?(Generator.attributes_for(Registry.lookup('B80601')))
  raise 'nil must not blow up the walk' if Export.orderable?(nil)
end

check('A CUSTOM SIZE WITH NO ARTICLE IS ORDERED, NOT DELETED') do
  # Object Contract v2.1 §4.2 rule 4: unknown is null, 'never a quietly kept
  # stale article AND NEVER A SILENT DELETION'. The export's orderable? test was
  # 'carries a code', so the first object ever to use that rule - two custom 610
  # boxes above a fridge niche, which the factory has to build - dropped out of
  # the order without a word. The dictionary already told a custom size from a
  # client's machine: one says Cesar, the other says client.
  custom = {
    'schema_version' => '2', 'object_class' => 'cabinet', 'manufacturer' => 'Cesar',
    'geometry_kind' => 'linear', 'width_mm' => 610, 'depth_mm' => 620, 'height_mm' => 600,
    'unit_type' => 'Top element, custom width', 'code' => nil,
    'code_status' => 'PRELIMINARY', 'status' => 'PLANNING',
    'source_ref' => 'no printed article - Elda Q11'
  }
  Contract.validate!(custom.dup)
  raise 'a custom size must reach the order' unless Export.orderable?(custom)
  row = Export.rows([custom]).first
  raise row.inspect unless row['code'].nil?
  raise "the row must say so in words: #{row['description'].inspect}" unless
    row['description'].to_s.include?('NO ARTICLE')
  raise 'and it must still carry its size' unless
    [row['l_mm'], row['h_mm'], row['p_mm']] == [610, 600, 620]

  # AND A VOID IS STILL NOT ORDERED. A reservation is a span the drawing owns,
  # not a thing anyone builds, and it must not have followed the custom size in.
  void = { 'schema_version' => '2', 'object_class' => 'void', 'void_role' => 'run_gap',
           'manufacturer' => 'Cesar', 'geometry_kind' => 'linear',
           'width_mm' => 1220, 'depth_mm' => 620, 'height_mm' => 2440,
           'code' => nil, 'code_status' => 'PRELIMINARY', 'status' => 'PLANNING',
           'source_ref' => 'measured' }
  Contract.validate!(void.dup)
  raise 'a void must not be ordered' if Export.orderable?(void)
  raise 'a void must not produce a row' unless Export.rows([void]).empty?
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

check('SENTINEL: a width change keeps the CODE; only the DIRECTION is printed or not') do
  # 2026-08-25, correction the second. This check has been wrong twice, and both
  # corrections are kept because the reasoning is the value, not the verdict.
  #
  # (1) It used to refuse B80601 at 560 outright, on the grounds that an object
  #     may not out-vote the registry about what article it is. The ground was
  #     right and the refusal was wrong: Elda's letter of 2026-08-24 prices
  #     exactly that unit - '560 priced as B80601 with the variant WIDTH
  #     REDUCTION' - so 560 is not a typed number overriding the catalog, it is
  #     a MODIFICATION the catalog sells.
  # (2) It then asserted that a WIDER width 'does not exist' and must be refused.
  #     That confused two different things: the catalog does not PRINT a width
  #     increase (the Modifications section lists reduction only; the only
  #     printed increases are side-panel DEPTH and the assembled tall unit on
  #     p.550), and a width increase cannot be BUILT. The first is true and the
  #     engine still says so on every increased object. The second was mine to
  #     assume and not mine to assert: the drawing is what goes to Elda, she
  #     keys it into Metron, and a refusal here would have prevented the very
  #     question from being asked. So the engine now DRAWS an increase and marks
  #     it NOT PRINTED rather than refusing to draw it.
  #
  # What the sentinel guards is what survived both corrections: the CODE never
  # changes, and the two directions are never confused with one another.
  u = Registry.with_ordered_width(Registry.lookup('B80601'), 560)
  raise 'the reduced width did not take' unless u['width_mm'] == 560
  raise 'the code must stay the module it was cut from' unless u['code'] == 'B80601'
  raise 'and it must remember what it was cut from' unless u['width_reduced_from_mm'] == 600
  raise 'a reduction is not an increase' unless u['width_increased_from_mm'].nil?

  w = Registry.with_ordered_width(Registry.lookup('B80601'), 640)
  raise 'the wider width did not take' unless w['width_mm'] == 640
  raise 'the code must stay the module it was widened from' unless w['code'] == 'B80601'
  raise 'and it must remember what it was widened from' unless w['width_increased_from_mm'] == 600
  raise 'an increase is not a reduction' unless w['width_reduced_from_mm'].nil?

  # AND THE DRAWING MUST SAY IT IS AN ASK, NOT AN OPTION.
  a = Generator.attributes_for(w)
  Contract.validate!(a.dup)
  v = Array(a['variants']).find { |x| x['key'] == 'WIDTH INCREASE' }
  raise "no variant: #{a['variants'].inspect}" if v.nil?
  raise v.inspect unless v['value'].include?('600')
  raise 'the value must not read as a catalog option' unless v['value'].include?('NOT PRINTED')
  raise 'the variant must point at the open question' unless v['source_ref'].to_s.include?('Q11')
  raise 'the note must say the catalog does not print it' unless
    a['notes'].to_s.include?('THE CATALOG DOES NOT PRINT THIS')
  raise 'feasibility must be flagged' unless a['notes'].to_s.include?('Cesar')
  # it is still a real unit on the order, under its own code
  raise 'an increased unit must still be ordered under its module code' unless a['code'] == 'B80601'

  # a whole number of millimetres, in BOTH directions
  begin
    Registry.with_ordered_width(Registry.lookup('B80601'), 640.5)
    raise 'a fractional increase was allowed'
  rescue ArgumentError => e
    raise "wrong refusal: #{e.message}" unless e.message.include?('whole number')
  end

  # THE PROHIBITIONS ARE THE CATALOG'S, and they bite in BOTH directions.
  begin
    Registry.with_ordered_width(Registry.lookup('B80753'), 700)
    raise 'a jumbo-drawer unit was width-modified'
  rescue ArgumentError => e
    raise "wrong refusal: #{e.message}" unless e.message.include?('jumbo')
  end
  begin
    Registry.with_ordered_width(Registry.lookup('B80753'), 1000)
    raise 'a jumbo-drawer unit was WIDENED despite the prohibition'
  rescue ArgumentError => e
    raise "wrong refusal: #{e.message}" unless e.message.include?('jumbo')
  end

  raise 'and an unranged article must pass through untouched' unless
    Registry.with_ordered_width(Registry.lookup('B80601'), nil)['width_mm'] == 600
  raise 'asking for the width it already has is not a modification' unless
    Registry.with_ordered_width(Registry.lookup('B80601'), 600)['width_reduced_from_mm'].nil? &&
    Registry.with_ordered_width(Registry.lookup('B80601'), 600)['width_increased_from_mm'].nil?
end

check('HEIGHT IS THE SAME TWO DIRECTIONS AND NOT THE SAME EVIDENCE') do
  # Added 2026-08-25 with the width increase, for the same wall: over the range
  # the project needs 610 x 720 where printed p.172's position prints 600 x 600.
  #
  # The ASYMMETRY is what this check exists to hold still. Height REDUCTION is
  # printed and priced - printed p.548, 989370, 138 points, and for a TALL unit
  # at the same code and the same points, where a WIDTH reduction charges tall
  # units 989380 / 227. Height INCREASE is printed nowhere. Two directions, two
  # different kinds of statement, and the object must not blur them.
  base = Registry.lookup('SD0631')
  raise 'the fixture moved' unless base['height_mm'] == 600 && base['width_mm'] == 600

  up = Registry.with_ordered_height(base, 720)
  raise 'the taller height did not take' unless up['height_mm'] == 720
  raise 'the code must not change' unless up['code'] == 'SD0631'
  raise 'and it must remember what it grew from' unless up['height_increased_from_mm'] == 600
  raise 'an increase is not a reduction' unless up['height_reduced_from_mm'].nil?
  a = Generator.attributes_for(up)
  Contract.validate!(a.dup)
  v = Array(a['variants']).find { |x| x['key'] == 'HEIGHT INCREASE' }
  raise "no variant: #{a['variants'].inspect}" if v.nil?
  raise 'the value must not read as a catalog option' unless v['value'].include?('NOT PRINTED')
  raise 'and it must not claim a surcharge code of its own' if v['value'] =~ /9893\d\d/
  raise 'the note must say the catalog does not print it' unless
    a['notes'].to_s.include?('THE CATALOG DOES NOT PRINT THIS')

  down = Registry.with_ordered_height(base, 480)
  raise 'the reduced height did not take' unless down['height_mm'] == 480
  raise 'and it must remember what it was cut from' unless down['height_reduced_from_mm'] == 600
  b = Generator.attributes_for(down)
  Contract.validate!(b.dup)
  w = Array(b['variants']).find { |x| x['key'] == 'HEIGHT REDUCTION' }
  raise "no variant: #{b['variants'].inspect}" if w.nil?
  raise 'a printed modification names its code' unless w['source_ref'].include?('989370')
  # AND IT MUST NOT NAME THE WIDTH CODE FOR TALL UNITS. printed p.548 charges a
  # tall unit 989380 / 227 for WIDTH and 989370 / 138 for HEIGHT; copying the
  # width table across is the exact error this check is here to catch.
  raise 'the tall WIDTH code has leaked into the height row' if w['source_ref'].include?('989380')
  raise 'the missing minimum must be named, not silently absent' unless
    w['source_ref'].include?('Q3')
  raise 'and the exclusion list is for WIDTH - the note must say so' unless
    b['notes'].to_s.include?('NO EXCLUSION LIST IS PRINTED FOR HEIGHT')

  # THE FRONT FOLLOWS THE CARCASS, or the drawing lies about what is ordered.
  raise 'the front did not follow the height' unless
    Generator.front_slabs(up).map { |s| s[:h_mm] }.max == 720

  # AND THE BUILDER MUST BE ABLE TO ASK FOR IT. Generator.build is where a code
  # becomes geometry; if the ordered height cannot reach it, everything above is
  # true of an object nobody can draw. Checked by SIGNATURE because build itself
  # needs SketchUp and this file must not.
  raise 'Generator.build takes no height_mm' unless
    Generator.method(:build).parameters.include?(%i[key height_mm])
  raise 'Generator.build lost width_mm' unless
    Generator.method(:build).parameters.include?(%i[key width_mm])

  # an unmodified unit carries neither variant
  c = Generator.attributes_for(base)
  raise 'an unmodified unit must claim no height change' if
    Array(c['variants']).any? { |x| x['key'].to_s.start_with?('HEIGHT') }

  # asking for the height it already has is not a modification, and nil is not one either
  raise 'the same height is not a modification' unless
    Registry.with_ordered_height(base, 600)['height_reduced_from_mm'].nil?
  raise 'nil must pass through untouched' unless
    Registry.with_ordered_height(base, nil)['height_mm'] == 600

  # whole millimetres, exactly as for width
  begin
    Registry.with_ordered_height(base, 720.5)
    raise 'a fractional height was allowed'
  rescue ArgumentError => e
    raise "wrong refusal: #{e.message}" unless e.message.include?('whole number')
  end

  # AND THE ONE REFUSAL THAT IS OURS RATHER THAN THE PAGE'S: an appliance
  # housing's opening height is the appliance's. No printed prohibition says so;
  # the arithmetic of every stack in this registry does.
  # catalog rows are the RAW registry and carry no object_class; lookup is what
  # enriches them. Reading it off the raw row returns nil for every code and the
  # refusal below would then never be exercised - a check that passes by finding
  # nothing is the quietest way to test nothing at all.
  appliance = Registry.catalog.map { |x| Registry.lookup(x['code']) }.compact.find do |x|
    %w[appliance appliance_front].include?(x['object_class'].to_s)
  end
  raise 'no appliance code in the registry to test the refusal against' if appliance.nil?
  begin
    Registry.with_ordered_height(appliance, appliance['height_mm'].to_i - 60)
    raise 'an appliance housing was height-modified'
  rescue ArgumentError => e
    raise "wrong refusal: #{e.message}" unless e.message.include?('appliance')
  end
end

check('A REDUCTION REACHES THE OBJECT AND THE ORDER, as a variant') do
  # Metron's estimate 2026/30831 priced 560 as B80601 with the variant
  # WIDTH REDUCTION and 138 points on the SAME ROW, so a reduction is a variant
  # and not a companion line - the estimate is what actually went out.
  u = Registry.with_ordered_width(Registry.lookup('B80601'), 560)
  a = Generator.attributes_for(u)
  Contract.validate!(a.dup)
  raise a['width_mm'].inspect unless a['width_mm'] == 560
  raise 'the code must not change' unless a['code'] == 'B80601'
  v = Array(a['variants']).find { |x| x['key'] == 'WIDTH REDUCTION' }
  raise "no variant: #{a['variants'].inspect}" if v.nil?
  raise v.inspect unless v['value'].include?('600')
  raise 'the variant must cite where the rule came from' unless
    v['source_ref'].to_s.include?('Q3')
  # and the catalog's own master rule must be on the object
  raise 'feasibility must be flagged' unless
    a['notes'].to_s.include?('Feasibility to be confirmed')

  # an UNreduced unit carries neither
  b = Generator.attributes_for(Registry.lookup('B80601'))
  raise 'an unmodified unit must not claim a reduction' if
    Array(b['variants']).any? { |x| x['key'] == 'WIDTH REDUCTION' }
  raise 'nor carry the note' if b['notes'].to_s.include?('WIDTH REDUCED')

  # and the order carries the variant as its own row
  rows = Export.rows([a])
  raise 'the unit row is missing' if rows.empty?
  raise "the variant row is missing: #{rows.inspect}" unless
    rows.any? { |r| r['description'].to_s.include?('WIDTH REDUCTION') }
end

check('the prohibition list in the code is the one in the manifest') do
  # The list is the CATALOG'S - Modifications section - and _manifest.json holds
  # it. The lambdas in 50_registry.rb are only readings of it, so if the source
  # list ever changes, this fails instead of a prohibition quietly going
  # unenforced.
  printed = JSON.parse(File.read(File.expand_path('../registry/cesar/_manifest.json', __dir__)))
            .dig('modifications', 'width_modification_prohibited_for')
  raise 'the prohibition list has vanished from the manifest' if printed.nil? || printed.empty?
  raise "code #{Registry::WIDTH_MOD_FORBIDDEN.keys.sort.inspect} vs manifest #{printed.sort.inspect}" unless
    Registry::WIDTH_MOD_FORBIDDEN.keys.sort == printed.sort
end

check('EVERY held code is asked whether it may be cut, and the answer is stable') do
  # prose against prose - the catalog's prohibition words against the catalog's
  # own descriptions - and the weakest thing in 50_registry.rb. A false NO is
  # loud; a false YES is silent. So the whole registry is run past it and the
  # split is pinned: a change in either direction has to be looked at.
  refused = Hash.new(0)
  allowed = 0
  Registry.catalog.each do |row|
    u = Registry.lookup(row['code'])
    next if u['width_range_mm']

    why = Registry.width_modification_refusal(u)
    why ? refused[why] += 1 : allowed += 1
  end
  raise 'nothing is refused - the matcher has stopped matching' if refused.empty?
  raise 'nothing is allowed - the matcher matches everything' if allowed.zero?
  total = refused.values.sum + allowed
  raise "counted #{total}" unless total.positive?
  # named so a move is visible in the failure, not just a number
  # 2026-08-25, the day it was wired: 17 appliance, 12 pull-out, 155 jumbo,
  # 24 interior-drawer = 208 refused, 530 allowed. NO framed-glass refusal and
  # NO mechanism refusal fires today, and both are recorded as zero rather than
  # left out: an empty bucket that later fills is a change somebody should see.
  # 2026-08-26: the framed-glass bucket FILLED, from zero to three, the day the
  # H.96 glass wall units were extracted on demand - TF0541, TF0641, TF0940. The
  # note above said an empty bucket that later fills is a change somebody should
  # see; this is that change, and the matcher found them by their own
  # description without a line of new code.
  # 2026-08-26, second change of the day: 124 END PANELS arrived and the matcher
  # caught SIXTY of them in the jumbo-drawer bucket. Not because they have jumbo
  # drawers - because printed p.441's own title is "for base units with
  # drawers/jumbo drawers ... hinges on the side opposite the 45 degree edge",
  # so the description names the units the panel is FOR. That is the exact
  # failure this file already warns about two hundred lines up, where matching
  # 'push-pull' refused 133 codes for saying they had none: A WORD IS NOT A
  # SENTENCE. The other sixty-four answered "yes, cut me" - the silent kind of
  # wrong. Both are now refused by Registry.width_is_a_thickness?, which runs
  # BEFORE the catalog's list and is not part of it, and jumbo/allowed are back
  # to the numbers they held before the panels landed.
  raise "refusals now #{refused.inspect}, allowed #{allowed}" unless
    refused == { 'appliance units' => 17, 'pull-out units' => 12,
                 'units with jumbo drawers' => 155,
                 'units with interior drawers' => 24,
                 'end panels, whose width is a thickness' => 124,
                 'tall or wall units with framed glass doors' => 3 } && allowed == 534
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

# THE FRONT-ONLY FILLER, 2026-08-24: a refusal retired by LOOKING at the page.
#
# This check used to assert the opposite - that B70151 and CQ0151 were held and
# NOT buildable, because printed p.434 prints no depth beside their table and
# the 2,2 stated elsewhere in the book was refused as a guess. That refusal was
# right on the evidence it had, and it is kept verbatim in each row under
# superseded_not_buildable_reason rather than deleted.
#
# What retired it is not an argument but a rendering. At 300 dpi the section
# detail of THAT position draws a single layer in the front plane, bracketed to
# the hatched neighbour, with the foot beneath it DASHED; and the position
# directly below it on the same page dimensions the identical 'front in door
# finishes' as 35 / 0,3 / 2,2 - box, gap, front. The front thickness of the page
# is printed, one position over. The factory's own export says 22 as well.
FILLER_FRONT_CODES = %w[B00151 BC0151 BJ0151 B70151 C10151 CE0151 CQ0151 CG0151 C00151].freeze

# The filler_front unit type that holds a given code, read from the section
# files. One file per family is the rule; this is what makes it checkable.
def filler_front_type_for(code)
  Dir[File.expand_path('../registry/cesar/fillers_*.json', __dir__)].each do |f|
    ty = JSON.parse(File.read(f))['data']['unit_types']['filler_front']
    next if ty.nil?
    return ty if (ty['codes'] || []).any? { |c| c['code'] == code }
  end
  raise "no fillers_*.json holds #{code}"
end

check('the nine front-only fillers are buildable at 22, and each says what that rests on') do
  # notes live in the section FILE - the loader does not carry prose onto the
  # resolved unit, which is exactly why the copied filler note survived a day
  # and a half of green suites. Read the files.
  FILLER_FRONT_CODES.each do |code|
    u = Registry.lookup(code)
    raise "#{code} is not in the registry" if u.nil?
    raise "#{code} is still refused" unless u.fetch('buildable', true)
    raise "#{code} depth #{u['depth_mm'].inspect}" unless u['depth_mm'] == 22
    raise "#{code} carries no width range" unless u['width_range_mm'] == [23, 150]
    ty = filler_front_type_for(code)
    note = ty['notes'].to_s
    raise "#{code}: the decision must be dated" unless note.include?('2026-08-24')
    raise "#{code}: it must not be sold as a printed dimension" unless
      note.include?('NOT A PRINTED DIMENSION')
    raise "#{code}: it must name the dimensioned neighbour" unless note.include?('35 / 0,3 / 2,2')
    raise "#{code}: it must name the factory measurement" unless note.include?('30831')
  end
  # the two that were refused keep the refusal
  %w[B70151 CQ0151].each do |code|
    raise "#{code} erased its old reason" unless
      filler_front_type_for(code)['superseded_not_buildable_reason'].to_s.include?('NOT BUILDABLE')
  end
end

check('AND EVERY FILLER SITS ON ITS OWN FAMILY, which is why it could be extracted at all') do
  # printed p.434 prices this article by HEIGHT alone, and the height it prints
  # is the family's. If a filler ever resolves to a height its family does not
  # have, it has been attached to the wrong family - the failure the one-file-
  # per-family rule exists to prevent.
  { 'B00151' => 390,  'BC0151' => 480,  'BJ0151' => 585,  'B70151' => 780,
    'C10151' => 1380, 'CE0151' => 1980, 'CQ0151' => 2100, 'CG0151' => 2220,
    'C00151' => 2340 }.each do |code, printed_h|
    u = Registry.lookup(code)
    raise "#{code}: height #{u['height_mm']} against printed #{printed_h}" unless
      u['height_mm'] == printed_h
    raise "#{code}: a filler must inherit a plinth, not invent one" if u['plinth_h_mm'].nil?
    raise "#{code}: the notes must say the plinth is a run item" unless
      filler_front_type_for(code)['notes'].to_s.include?('ZOCC011')
  end
end

check('the three rows that are NOT held name the reason, one each') do
  # A gap that looks like an oversight gets closed by guessing. printed p.434
  # has twelve rows and this registry holds nine.
  note = JSON.parse(File.read(File.expand_path('../registry/cesar/_manifest.json', __dir__)))
         .dig('catalog_map', 'sections')
         .find { |s| s['section'] == 'Closing strips and fillers for Maxima and Intarsio' }['pages']
         .find { |q| q['printed'] == 434 }['types'][0]['note']
  # 2026-08-25: BE0151 moved from the unheld list to the held one, and the note
  # keeps WHY it was blocked - it was looked for in the base chapter, which has
  # no H.60 section, while the top-element chapter does. A row can be blocked by
  # the family you happen to look for it in, and that is worth more than the row.
  %w[BE0151 BK0151 CH9151].each do |code|
    raise "#{code} is unexplained" unless note.include?(code)
  end
  raise 'the held count must be named too' unless note.include?('TEN ARE NOW HELD')
  held = Registry.catalog.map { |c| c['code'] }
  %w[BK0151 CH9151].each do |code|
    raise "#{code} is in the registry but the map still calls it unheld" if held.include?(code)
  end
  raise 'BE0151 is held now and the map must not still be waiting for it' unless
    held.include?('BE0151')
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
  # six entries per family, which is the habit learned rule 18 punished.
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
  # And the roll-call is gone with it (learned rule 18): it read %w[PE0696 PG0696] and
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
  # is held as a PAGE of the section whose range contains it - learned rule 1 untouched.
  dish = rows.select { |c| c['type_key'].to_s.start_with?('dish_drainer_') }
  raise dish.length.to_s unless dish.length == 9
  raise 'the reason must travel with the file, not with our memory of it' unless
    JSON.parse(File.read(File.expand_path('../registry/cesar/dish_drainer_h120.json', __dir__)))
        .fetch('section_note').downcase.include?('learned rule 1')
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

check('LEARNED RULE 1 SCOPE: a page the index forgot is mapped as a PAGE, twice now') do
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
  # And neither may exist as a section of its own - that is the half learned rule 1 guards.
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
  # width - THE THIRD INSTANCE OF LEARNED RULE 11, in the very method written to settle
  # the second. Every layer involved is pure, so the suite could have caught it
  # and did not. This is that sweep.
  Registry.codes.each do |code|
    row = Registry.lookup(code)
    next unless row.fetch('buildable', true)

    ordered = row['width_range_mm'] ? Registry.with_ordered_width(row, row['width_range_mm'][0]) : row
    # both dimensions, for a sheet - see the whole-registry sweep near the top
    ordered = Registry.with_ordered_height(ordered, ordered['height_range_mm'][0]) if ordered['height_range_mm']
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
  # Learned rule 12: run it against the defect it exists for, on a fixture, so a green
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

# ---------------------------------------------------------------------------
# WHICH SIDE THE NEXT ELEMENT TAKES (2026-08-24)
#
# "Build next to selected" grew to the right and only to the right, so the left
# wing of a kitchen was placed by hand. Andriy's rule: something attached on the
# right and the left free -> go left; both free -> go right; both taken ->
# refuse. The DECISION is pure and lives here; the geometry that feeds it is in
# Generator.placement_side, where no headless check can reach.
# ---------------------------------------------------------------------------

puts "\nwhich side of the selected unit the next element takes"

# a 600 unit selected, sitting at 0..600 in its own frame
MINE = [0.0, 600.0].freeze

check('both sides free: the run continues RIGHT, as it always did') do
  raise Placement.side_beside(*MINE, []).to_s unless
    Placement.side_beside(MINE[0], MINE[1], []) == :right
end

check('SOMETHING ATTACHED ON THE RIGHT: the new element goes LEFT') do
  right_neighbour = [[600.0, 1050.0]]
  raise Placement.side_beside(MINE[0], MINE[1], right_neighbour).to_s unless
    Placement.side_beside(MINE[0], MINE[1], right_neighbour) == :left
end

check('attached on the left: RIGHT, which is also the default') do
  left_neighbour = [[-450.0, 0.0]]
  raise Placement.side_beside(MINE[0], MINE[1], left_neighbour).to_s unless
    Placement.side_beside(MINE[0], MINE[1], left_neighbour) == :right
end

check('BOTH SIDES TAKEN: the rule says so - and the caller builds anyway') do
  # The rule STATES the fact. The policy is the generator's, and Andriy set it
  # on 2026-08-24: build on the right regardless, because a unit in the wrong
  # place can be dragged and a unit that was never built has to be asked for
  # twice. Keeping the two apart is why :blocked still exists at all.
  boxed = [[-450.0, 0.0], [600.0, 1050.0]]
  raise Placement.side_beside(MINE[0], MINE[1], boxed).to_s unless
    Placement.side_beside(MINE[0], MINE[1], boxed) == :blocked

  gen = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  raise 'nothing may refuse to build over a blocked side' if gen.include?('side_refusal')
  raise 'the policy must be written where it is decided' unless
    gen.include?('ALSO BUILDS, on the right')
end

check('A FILLER TAKES THE SAME PATH AS A CABINET, width and all') do
  # Andriy, 2026-08-24: the side rule is for fillers too. A filler reaches the
  # placement with a width like any cabinet, because with_ordered_width turns
  # its catalog RANGE into a number before anything is drawn. If that ever
  # stopped happening, the left step would have nothing to step back by and a
  # filler would silently continue right.
  strip = Registry.with_ordered_width(Registry.lookup('CQ0151'), 50)
  raise strip['width_mm'].inspect unless strip['width_mm'] == 50
  raise Generator.span_for_attrs(strip).inspect unless
    Generator.span_for_attrs(strip) == [0.0, 50.0]

  # and the placement asks for the NEW element's width, not the selected one's
  gen = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  raise 'the whole unit must reach the placement - width AND depth' unless
    gen.include?('placement_transform(model, unit)')
  raise 'and the left step must use its width' unless
    gen.include?('span[0] - new_width_mm.to_f')
end

check('a unit further down the same wall is NOT attached') do
  # three metres away: the side is free and the run may grow into it.
  far = [[3600.0, 4200.0]]
  raise Placement.side_beside(MINE[0], MINE[1], far).to_s unless
    Placement.side_beside(MINE[0], MINE[1], far) == :right
  # and just inside SNAP_MM it IS attached, so this rule and the joint-closing
  # snap can never disagree about what "next to" means
  near = [[600.0 + Placement::SNAP_MM - 1, 1200.0]]
  raise Placement.side_beside(MINE[0], MINE[1], near).to_s unless
    Placement.side_beside(MINE[0], MINE[1], near) == :left
end

check('A NARROW FILLER DOES NOT REFUSE AGAINST ITSELF') do
  # The trap this rule was written for. A 50 mm filler is narrower than
  # SNAP_MM, so its own span - or an identical twin - lies within touching
  # distance of BOTH its ends. Without the "the neighbour must lie past me"
  # test, CQ0151 at 50 wide would report :blocked in an empty kitchen.
  narrow = [0.0, 50.0]
  raise 'a filler in an empty room must go right' unless
    Placement.side_beside(narrow[0], narrow[1], []) == :right
  raise 'its own span must not count as a neighbour' unless
    Placement.side_beside(narrow[0], narrow[1], [[0.0, 50.0]]) == :right
  # and it still sees a real neighbour on its right
  raise 'a real right-hand neighbour must still be seen' unless
    Placement.side_beside(narrow[0], narrow[1], [[50.0, 650.0]]) == :left
end

check('a CORNER on the right pushes the run left, wasted space and all') do
  # A corner's span is its NODE, not its carcass - Placement.span_mm - so the
  # unreachable depth counts as occupied. A run beside a left-execution corner
  # therefore starts past the node.
  corner = Placement.span_mm(carcass_mm: 900, nominal_mm: 1150, execution: 'left')
  raise corner.inspect unless corner == [0.0, 1150.0]
  # seat that corner immediately to the right of the selected unit
  raise 'the corner must occupy the right side' unless
    Placement.side_beside(MINE[0], MINE[1], [[600.0, 600.0 + 1150.0]]) == :left
end

check('the span rule now has ONE implementation, and both callers use it') do
  # Generator.run_extent_mm and the place tool both used to write it out.
  gen  = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  tool = File.read(File.expand_path('../src/ucon_cabinet_engine/core/75_place_tool.rb', __dir__))
  raise 'the generator must hold the one implementation' unless
    gen.include?('def span_for_attrs')
  raise 'the place tool must delegate, not repeat' unless
    tool.include?('Generator.span_for_attrs')
  raise 'the place tool must not look the corner up for itself any more' if
    tool.include?("Placement.span_mm(carcass_mm:")
  # and it still answers the same thing for a straight unit
  raise Generator.span_for_attrs('width_mm' => 600).inspect unless
    Generator.span_for_attrs('width_mm' => 600) == [0.0, 600.0]
end

check('THE TURN AT A CORNER IS PINNED TO A MEASURED ONE, not to a formula') do
  # Avenida Primavera, read out of the model 2026-08-24: AU110D sits at origin
  # (620, 250) turned 90 degrees, and the B80501 that turns the run onto the
  # south wall sits at (1153, 620) turned 180. In the corner's own frame that
  # is offset (370, -533) and a further +90 - and Andriy placed it by hand
  # before any of this existed, which is what makes it evidence rather than
  # agreement with myself.
  #
  # AU110D: carcass 900, nominal 1150, so wasted 250 and the span is
  # [-250, 900] - the wasted end low, which is the end that faces the
  # perpendicular wall. B80501 is 450 wide and 620 deep.
  span = Placement.span_mm(carcass_mm: 900, nominal_mm: 1150, execution: 'right')
  raise span.inspect unless span == [-250.0, 900.0]

  seat = Placement.corner_turn_seat(span, :low, 450, 620, 80, 3)
  raise seat.inspect unless seat == [370.0, -533.0, 90]

  # and the two halves must keep MEANING what they mean, or they are two
  # numbers that happened to fit:
  #   the back lands on the wasted-end plane - the perpendicular wall
  raise 'a full-depth unit still lands its back on the wall' unless seat[0] - 620 == span[0]
  #   the near end lands on the corner's outermost front face, 80 + 3
  raise 'the near end must meet the 8x8 face' unless seat[1] + 450 == -83
end

check('A SHALLOW ELEMENT TURNS ONTO THE FRONT LINE, not onto the wall') do
  # Found by trying it, 2026-08-24: the cabinet turned correctly and the filler
  # did not - "it built along the wall, not along the front". The seat took the
  # NEW element's depth, so a 350-deep filler pinned its own back to the
  # perpendicular wall and stood 270 mm proud of where the run's front is.
  # B80501 had hidden it: at 620 deep it is exactly as deep as the corner, so
  # both readings gave the same number and the wrong one fitted.
  #
  # A unit is drawn from its origin FORWARDS, so the origin is the front edge
  # whatever the depth. Feed the RUN's depth and every element, deep or shallow,
  # lands its front on the same line.
  span = [-250.0, 900.0]
  deep    = Placement.corner_turn_seat(span, :low, 450, 620, 80, 3)
  shallow = Placement.corner_turn_seat(span, :low, 150, 620, 80, 3)
  raise 'the front line must not move with the element depth' unless
    deep[0] == shallow[0]
  raise deep.inspect unless deep[0] == 370.0

  # and the shallow one's back then stands off the wall by the difference,
  # which is how Andriy's own B70501 sits in the 620 run: 620 - 350 = 270
  raise 'the gap behind a shallow element is the depth difference' unless
    (shallow[0] - 350) - span[0] == 270.0
end

check('A SHALLOW NEIGHBOUR IS STILL A NEIGHBOUR, or the run grows into it') do
  # Reported by Andriy 2026-08-24: a run with something on its right kept
  # building right. The row test measured BACKS, and a 350-deep filler standing
  # front-aligned in a 620 run has its back 270 mm off - nine times
  # COPLANAR_TOL_MM - so the rule could not see it at all. A neighbour it cannot
  # see is a side it calls free.
  raise 'two equal depths must be one row' unless
    Placement.same_row?('floor', 'floor', 1.0, 0)
  raise 'measured at the back, a shallow neighbour vanishes' if
    Placement.same_row?('floor', 'floor', 1.0, 270)
  raise 'measured at the front, it is there' unless
    Placement.same_row?('floor', 'floor', 1.0, 0)
  # a genuinely different row - another wall, another depth line - still fails
  raise 'a run at another depth is not this row' if
    Placement.same_row?('floor', 'floor', 1.0, 620)
  raise 'a wall unit is not in a base row' if
    Placement.same_row?('floor', 'wall', 1.0, 0)

  gen = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  raise 'the generator must measure the two origins, which are the two fronts' unless
    gen.include?('offset = (ot.origin - t.origin).dot(yv).to_mm')
  raise 'and must not go back to measuring backs' if
    gen.include?('back_mine')
end

check('the turn fires on the WASTED end and never on the 8x8 end') do
  # The 8x8 end is where the run continues straight - its width leg is drawn at
  # 77 to meet the next front. Turning there would put a cabinet through it.
  raise 'a right-execution corner wastes its low end' unless
    Placement.corner_turn_end('right') == :low
  raise 'a left-execution corner wastes its high end' unless
    Placement.corner_turn_end('left') == :high

  raise 'left onto a low-wasted corner turns' unless Placement.turning?(:left, :low)
  raise 'right onto a low-wasted corner must NOT turn' if Placement.turning?(:right, :low)
  raise 'right onto a high-wasted corner turns' unless Placement.turning?(:right, :high)
  raise 'left onto a high-wasted corner must NOT turn' if Placement.turning?(:left, :high)

  # B80603 continues straight off the same corner in the same model, at the
  # 8x8 end. If turning? ever said yes there, that unit would swing into it.
  raise 'the straight side must stay straight' if Placement.turning?(:right, :low)
end

check('THE MIRROR IS A MIRROR, and is marked as unmeasured') do
  # No hand-placed left-execution turn exists yet. What can be checked is that
  # the construction reflects rather than being a second guess: the two seats
  # occupy the same band along the corner's front, and the angles are opposite.
  low  = Placement.corner_turn_seat([-250.0, 900.0], :low,  450, 620, 80, 3)
  high = Placement.corner_turn_seat([-250.0, 900.0], :high, 450, 620, 80, 3)
  raise low.inspect  unless low[2]  == 90
  raise high.inspect unless high[2] == -90
  # low runs from -533 up to -83; high from -83 down to -533
  raise 'the two must sweep the same band' unless
    [low[1], low[1] + 450].minmax == [high[1] - 450, high[1]].minmax
  placement = File.read(File.expand_path('../src/ucon_cabinet_engine/core/22_placement.rb', __dir__))
  raise 'the unmeasured half must say so' unless
    placement.include?('THE MIRROR IS NOT MEASURED')
end

check('a corner that cannot say its execution does not turn anything') do
  # Better a straight continuation the eye catches than a turn built on a
  # missing letter.
  raise 'no width, no turn' unless
    Placement.corner_turn_seat([-250.0, 900.0], :low, nil, 620, 80, 3).nil?
  raise 'no depth, no turn' unless
    Placement.corner_turn_seat([-250.0, 900.0], :low, 450, nil, 80, 3).nil?
end


# ---------------------------------------------------------------- panel kit
#
# The kit is VENDORED into both extension trees, not shared, because the engine
# must keep working on a machine where the appliance extension was never
# installed - which a shared require would quietly make false. These checks are
# what stop the two copies from drifting apart instead.

KIT_EXPECTED_VERSION = 1

check('the vendored panel kit is the version this suite expects') do
  actual = UCON::CabinetEngine::PanelKit::KIT_VERSION
  raise "kit is v#{actual}, suite expects v#{KIT_EXPECTED_VERSION} - " \
        'if you regenerated the kit, bump the literal in BOTH suites' unless
    actual == KIT_EXPECTED_VERSION
end

check('the vendored panel kit still hashes to what the generator stamped') do
  css = UCON::CabinetEngine::PanelKit::CSS
  want = UCON::CabinetEngine::PanelKit::KIT_SHA
  got  = Digest::SHA256.hexdigest(css)[0, 16]
  raise "kit sha #{got}, stamped #{want} - core/05_panel_kit.rb was hand-edited. " \
        'Edit design/panel_kit.css and run tools/build_panel_kit.rb' unless got == want
end

check('the kit carries the trust encoding both panels depend on') do
  css = UCON::CabinetEngine::PanelKit::CSS
  %w[--ok --amber --red .trust-printed .trust-assumed .trust-decide .flag .peer].each do |token|
    raise "the kit lost #{token}" unless css.include?(token)
  end
end

check('the kit defines the shared submenu root without requiring the other extension') do
  raise 'UCON.extensions_menu is not defined' unless UCON.respond_to?(:extensions_menu)
end

puts "\ntall unit top elements - printed p.170 and p.173, what closes the wall"
check('nineteen top elements, d.62 only, and they refuse the hung version IN WORDS') do
  # 10 -> 19 on 2026-08-25 when printed p.172 came in: H.36 five, H.72 five,
  # H.60 nine. printed p.171 (H.48) is still unread on purpose.
  top = Registry.catalog.select { |c| c['section'].to_s.start_with?('Tall unit top elements') }
  raise top.length.to_s unless top.length == 19
  raise 'top elements are d.62 only' unless
    top.map { |c| Registry.lookup(c['code'])['depth_mm'] }.uniq == [620]
  raise 'widths' unless top.map { |c| Registry.lookup(c['code'])['width_mm'] }.uniq.sort ==
                        [450, 600, 750, 900, 1200]

  # THE FACT THAT DECIDED A LAYOUT: the side-hinged SINGLE door stops at W.60.
  # Above it the only door that does not open upward is the two-door position.
  # A 610 side-hinged single door therefore cannot be made - modifications
  # reduce, and there is nothing above 600 to reduce from.
  side = top.select { |c| Registry.lookup(c['code'])['unit_type'] == 'top_element_door' }
  raise "side-hinged singles: #{side.map { |c| c['code'] }.inspect}" unless
    side.map { |c| Registry.lookup(c['code'])['width_mm'] }.sort == [450, 600]
  two = top.select { |c| Registry.lookup(c['code'])['unit_type'] == 'top_element_two_doors' }
  raise "two-door tops: #{two.map { |c| c['code'] }.inspect}" unless
    two.map { |c| Registry.lookup(c['code'])['width_mm'] }.sort == [900, 1200]
  # and only ONE of the three held heights sells either of them
  raise 'the side-hinged positions must live at H.60 alone, for now' unless
    (side + two).map { |c| c['section'] }.uniq == ['Tall unit top elements H. 60 | without fixings']
  # The FIRST codes in this registry to refuse by the catalog's own sentence
  # rather than by a missing pictogram: the section title is 'without fixings'.
  top.each do |c|
    raise "#{c['code']} does not refuse" unless Registry.lookup(c['code'])['wall_hung'] == false
  end
  # THE REASON IS READ FROM THE FILE, not through Registry.lookup - the loader
  # carries `wall_hung` into the engine and deliberately not its note, the same
  # split the printed p.19 sweep's own check makes. A value the engine can act
  # on travels; the prose that justifies it stays where a person reads it.
  dir = File.expand_path('../registry/cesar', __dir__)
  %w[tall_top_h36.json tall_top_h60.json tall_top_h72.json].each do |f|
    JSON.parse(File.read(File.join(dir, f)))['data']['unit_types'].each do |k, ty|
      raise "#{f} #{k} does not say why" unless
        ty['wall_hung_note'].to_s.include?('without fixings')
    end
  end
end

check('A FRACTIONAL FILLER WIDTH ROUNDS UP, and the allowance is said out loud') do
  # THE HISTORY IS KEPT BECAUSE IT IS WHY THE RULE CAN BE TRUSTED.
  # Integer("49.2") raises and Integer(49.2) TRUNCATES, so the first guard caught
  # a string and let a float through: three fillers ordered at 49,2, 69,2 and
  # 109,3 on 2026-08-25 were built at 49, 69 and 109, and the only evidence was a
  # fraction of a millimetre against a wall. That evening the truncation became a
  # REFUSAL naming both roundings. On 2026-08-26 Andriy closed owed 2 and the
  # refusal became the RULE: UP, always, because up is the only direction a
  # fitter can correct - and the allowance goes ON THE OBJECT, which is the half
  # the refusal was really protecting.
  u = Registry.lookup('BE0151')
  r = Registry.with_ordered_width(u, 109.3)
  raise r['width_mm'].to_s unless r['width_mm'] == 110
  raise r['width_clear_mm'].to_s unless r['width_clear_mm'] == 109.3
  raise r['scribe_mm'].to_s unless (r['scribe_mm'] - 0.7).abs < 0.001

  # THE ORDER READS ONE WIDTH AND THE DRAWING READS THE OTHER, and that is the
  # whole point: 110 is bought, 109,3 is drawn, 0,7 is cut off on site.
  raise Generator.drawn_width_mm(r).to_s unless Generator.drawn_width_mm(r) == 109.3
  a = Generator.attributes_for(r)
  raise a['width_mm'].to_s unless a['width_mm'] == 110
  raise a['notes'] unless a['notes'].include?('scribed off on site')
  raise a['notes'] unless a['notes'].include?('109.3')
  raise 'the front must be drawn at the clear width, not the ordered one' unless
    Generator.front_slabs(r).sum { |sl| sl[:w_mm] } == 109.3

  # a whole number keeps both hands clean: no clear width, no allowance, no note
  w = Registry.with_ordered_width(u, 49.0)
  raise w['width_mm'].to_s unless w['width_mm'] == 49
  raise 'a whole width must carry no allowance' if w['scribe_mm'] || w['width_clear_mm']
  raise 'an integer must pass' unless Registry.with_ordered_width(u, 109)['width_mm'] == 109
  raise Generator.attributes_for(w)['notes'] if
    Generator.attributes_for(w)['notes'].include?('scribed off')

  # AND THE RANGE STILL BITES, on the ORDERED width rather than the asked one:
  # 0,5 rounds up to 1 and no filler is made at 1. The message must send the
  # reader to two fillers rather than to a width nobody prints.
  begin
    Registry.with_ordered_width(u, 0.5)
    raise '0.5 was accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('rounds up to 1')
    raise e.message unless e.message.include?('two fillers')
  end
  begin
    Registry.with_ordered_width(u, 20)
    raise '20 was accepted below the range'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('outside') || e.message.include?('rounds up to 20')
  end
end

check('A MODIFIED UNIT GETS A MODIFIED FRONT, in both axes') do
  # FOUND IN THE MODEL, 2026-08-26, by Andriy looking at a sheet: six top
  # elements carried a CARCASS 610 wide and a FRONT 600, and two of those had a
  # carcass 720 tall with a front 600 - a 120 mm band of cabinet with no front on
  # it at all. The engine is right today and those bodies are stale, built before
  # the increase path existed; nothing had re-drawn them and nothing would have
  # noticed.
  #
  # THE INTERESTING HALF IS THAT REDUCTION WAS NEVER WRONG. SD0930 cut to 770
  # drew 385 + 385 in the same model on the same day. One direction of the same
  # rule worked and the other did not, which is exactly the kind of asymmetry a
  # check has to hold, because reading the code proves nothing about the past.
  u = Registry.lookup('SD0631')
  raise u['width_mm'].to_s unless u['width_mm'] == 600

  wide = Registry.with_ordered_width(u, 610)
  slabs = Generator.front_slabs(wide)
  raise slabs.inspect unless slabs.sum { |sl| sl[:w_mm] } == 610
  raise 'the front must not keep the printed width' if slabs.any? { |sl| sl[:w_mm] == 600 }

  tall = Registry.with_ordered_height(wide, 720)
  slabs = Generator.front_slabs(tall)
  raise slabs.inspect unless slabs.sum { |sl| sl[:w_mm] } == 610
  raise slabs.inspect unless slabs.map { |sl| sl[:z_mm] + sl[:h_mm] }.max == 720
  raise 'the front must reach the top of a heightened carcass' if
    slabs.any? { |sl| sl[:h_mm] == 600 }

  # and the direction that always worked keeps working
  cut = Registry.with_ordered_width(Registry.lookup('SD0930'), 770)
  slabs = Generator.front_slabs(cut)
  raise slabs.inspect unless slabs.sum { |sl| sl[:w_mm] } == 770
  raise slabs.inspect unless slabs.length == 2
end

check('the glass wall units are held, and the page refuses them in BOTH axes') do
  # Extracted 2026-08-26 on demand: the Avenida Primavera west wall wants glass
  # doors at 600 x 960 x 350 and the plain-door PF0631 standing there has none.
  # printed p.314, chapter 'Glass display cabinet elements'.
  g = Registry.lookup('TF0641')
  raise g.inspect unless g['width_mm'] == 600 && g['height_mm'] == 960 && g['depth_mm'] == 350
  raise g['family'].inspect unless g['family'] == 'Glass wall H.96'
  raise g['description'] unless g['description'] =~ /glass door/i
  raise g['source_ref'] unless g['source_ref'].include?('p.314')

  # IT IS A DIFFERENT ARTICLE, NOT A VARIANT of the plain-door unit: PF is the
  # wall chapter at printed p.245, TF is the glass chapter at p.314, and the
  # letters run BACKWARDS across the F/G pair in BOTH chapters - TF is H.96 and
  # TG is H.84, exactly as PF is H.96 and PG would be H.84. A letter is a lookup.
  p = Registry.lookup('PF0631')
  raise 'same size, different article' unless
    p['width_mm'] == g['width_mm'] && p['height_mm'] == g['height_mm'] &&
    p['depth_mm'] == g['depth_mm'] && p['code'] != g['code']
  raise Registry.lookup('TG0641')['height_mm'].to_s if
    (Registry.lookup('TG0641') rescue nil) && Registry.lookup('TG0641')['height_mm'] == 960

  # "Cannot be reduced in width, height or depth" is printed on the position.
  # WIDTH was already refused by the p.548 framed-glass rule with no new code;
  # HEIGHT was wired on 2026-08-26 and must cite THIS page, not borrow that list.
  raise 'width must be refused' unless
    Registry.width_modification_refusal(g) == 'tall or wall units with framed glass doors'
  begin
    Registry.with_ordered_height(g, 900)
    raise 'a glass unit accepted a height change'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('p.314')
    raise e.message unless e.message.include?('width, height or depth')
  end
  # and an unchanged height is still a no-op, not a refusal
  raise 'an unchanged height must pass' unless
    Registry.with_ordered_height(g, 960)['height_mm'] == 960

  # THE PANE IS DRAWN, AND THE FRAME SAYS WHOSE NUMBER IT IS. The book prints no
  # frame section anywhere either Andriy or the session could find, so 25 is a
  # UCON declaration and wears '(frame: DECLARED)' - deliberately NOT the
  # aperture's '(cutout: INDICATIVE)', because an aperture's rails come from a
  # machine's published spec and this comes from us. Two labels, two claims.
  raise 'a glass door is not an appliance aperture' if (g['front_layout'] || {})['cutout']
  raise g['front_layout'].inspect unless g['front_layout']['glass_frame_mm'] == 25
  rails = Generator.cutout_rails(g, Generator.front_slabs(g).first)
  raise rails.inspect unless rails == { left: 25.0, right: 25.0, bottom: 25.0, top: 25.0 }
  raise Generator::GLASS_FRAME_LABEL unless Generator::GLASS_FRAME_LABEL == '(frame: DECLARED)'
  raise 'the two labels must not be the same claim' if
    Generator::GLASS_FRAME_LABEL == Generator::CUTOUT_LABEL
  n = Generator.notes_for(g)
  raise n unless n.include?('(frame: DECLARED)') && n.include?('25 mm')
  raise n unless n.include?('UCON declaration')
  raise n if n.include?('INDICATIVE')

  # BOTH LEAVES OF A TWO-DOOR GLASS UNIT ARE GLAZED. The aperture guard waits
  # for a slab as wide as the whole unit, which would have glazed neither door
  # of TF0940; a glass frame answers per leaf.
  two = Registry.lookup('TF0940')
  slabs = Generator.front_slabs(two)
  raise slabs.inspect unless slabs.length == 2
  slabs.each do |sl|
    raise "a leaf went unglazed: #{sl.inspect}" unless Generator.cutout_rails(two, sl)
  end

  # and the appliance aperture is untouched: it still waits, and still says
  # INDICATIVE rather than DECLARED.
  wine = Registry.lookup('CR9601')
  raise 'the wine cooler must keep its own label' unless
    Generator.notes_for(wine).include?('INDICATIVE')
  raise 'the wine cooler must not claim a declared frame' if
    Generator.notes_for(wine).include?('(frame: DECLARED)')
end

check('the reveal sentence died with the reveal') do
  # FRONT_REVEAL_MM was deleted on 2026-08-26 and notes_for went on telling every
  # object about "1.5 mm reveal recorded, not drawn" - a sentence that outlived
  # its number by one commit and pointed at nothing. A deletion is not finished
  # while something still says the number aloud.
  n = Generator.notes_for(Registry.lookup('B80601'))
  raise n if n.include?('1.5')
  raise n unless n.include?('the faces meet')
end

check('A TOP ELEMENT HAS NO PLINTH, and the zero is stated rather than left silent') do
  # Generator.plinth_h_mm falls back to Standards::PLINTH_H_MM when a family says
  # nothing, which was right for every family in the registry until these two:
  # a top element rests on the tall unit below it. Silence would have drawn a
  # 100 mm plinth floating 2200 mm off the floor.
  %w[SB0600 SE0600].each do |code|
    u = Registry.lookup(code)
    raise "#{code} plinth #{u['plinth_h_mm'].inspect}" unless u['plinth_h_mm'].to_f.zero?
    raise "#{code} would still be drawn a plinth" if Generator.plinth?(u)
    raise "#{code} must not start above the floor of its own definition" unless
      Generator.base_z_mm(u).to_f.zero?
  end
  # and the families that DO stand on a plinth still do
  raise 'a tall unit lost its plinth' unless Generator.plinth_h_mm(Registry.lookup('CH0635')) == 100.0
end

check('the two heights differ by a shelf, and that is printed rather than tidied') do
  # H.36 lists the door and nothing else; H.72 adds '1 shelf'. Two sections that
  # look like one section at two heights are exactly where a reader smooths over
  # a real difference.
  raise 'H.36 must hold no shelf' unless
    Registry.lookup('SB0600')['interior_confirmed'] == []
  raise 'H.72 must hold one shelf' unless
    Registry.lookup('SE0600')['interior_confirmed'] == ['1 shelf']
  raise 'both are top-hung' unless
    %w[SB0600 SE0600].all? { |c| Registry.lookup(c)['front_layout']['hinge_axis'] == 'top' }
end

check('N_Elle is a DOCUMENT LEAD here too, and every file that keeps one says so') do
  # printed p.170 and p.173 put 'N- Elle' and a second height in the text layer
  # and print neither. The wall chapter found this on 2026-08-23 and wrote that
  # it would not be the last; this is the second chapter. A file that keeps the
  # number without the warning would be quoting the book for something the book
  # does not say.
  dir = File.expand_path('../registry/cesar', __dir__)
  kept = Dir[File.join(dir, '*.json')].reject { |f| File.basename(f).start_with?('_') }
         .select { |f| JSON.parse(File.read(f))['data']['overall_height_n_elle_mm'] }
  raise 'the N_Elle lead has vanished' if kept.empty?
  kept.each do |f|
    note = JSON.parse(File.read(f))['data']['n_elle_note'].to_s
    raise "#{File.basename(f)}: the lead is kept without the warning" unless
      note.include?('NOT PRINTED') || note.include?('NOT PRINTED ON THE PAGE')
  end
  raise 'the top-element pages must carry it' unless
    kept.map { |f| File.basename(f) }.include?('tall_top_h72.json')
end

puts "\nthe reserved void - printed p.121-125, and the concept B6 shares"
# docs/Reserved_Void_Spec_v0.1.md. A void is a span whose extent is known and
# whose division is not. Three places wanted one and only the appliance module
# had it; these checks hold the engine's half.

check('EVERY STACK SUMS TO ITS HEIGHT - fronts, recesses and openings alike') do
  # The invariant measured on printed p.121-125, applied to the whole registry
  # so a future section cannot forget it. front_stack raises; a silent pass here
  # would mean nothing is being checked, so the count is asserted too.
  # BUILDABLE ONLY, and that is not a loophole. printed p.47's dishwasher doors
  # carry kind 'horizontal' with no heights at all - the printed pair does not
  # sum to the family door height - and they are marked not buildable and
  # front_layout_incomplete for exactly that reason. Asking them to sum would
  # re-raise a gap that is already recorded, in the wrong file.
  seen = 0
  Registry.catalog.select { |c| c['buildable'] }.each do |row|
    u = Registry.lookup(row['code'])
    fl = u['front_layout'] || {}
    next unless fl['kind'] == 'horizontal'

    seen += 1
    Generator.front_stack(fl, u['height_mm'])
  end
  raise 'no horizontal layout was checked' if seen.zero?
  raise "only #{seen} horizontal layouts - the registry has more" unless seen > 100
end

check('A REMAINDER IS EXECUTION-INDEPENDENT, or it is not a real number') do
  # 1125 on printed p.121 - 195 + 780 handle against 30 + 165 + 30 + 750 gola.
  # 1710 and 1515 on printed p.123. Handle and gola leave the SAME hole to the
  # millimetre, and that is the property that makes the span measurable at all.
  # If a future edit moves one stack and not the other, this is where it lands.
  found = 0
  Registry.catalog.each do |row|
    fl = Registry.lookup(row['code'])['front_layout'] || {}
    a = Array(fl['stack_top_to_bottom']).select { |e| e['kind'] == 'remainder' }
    next if a.empty?

    b = Array(fl['gola_stack_top_to_bottom']).select { |e| e['kind'] == 'remainder' }
    raise "#{row['code']}: gola stack has no remainder" if b.empty?
    raise "#{row['code']}: #{a.map { |e| e['h_mm'] }} vs #{b.map { |e| e['h_mm'] }}" unless
      a.map { |e| e['h_mm'] } == b.map { |e| e['h_mm'] }
    found += 1
  end
  raise 'the remainder has vanished from the registry' if found.zero?
  # 3 -> 5: printed p.121 and p.123 at H.210, printed p.143 at H.222. The count
  # is pinned so that a remainder appearing or vanishing is never silent.
  #
  # 7 -> 6 ON 2026-08-27, AND THE CHECK FIRING IS WHY THE NUMBER IS PINNED.
  # C92640's 1950 was DIVIDED - 750 door + 600 + 600 - because the east column of
  # 545 Avenida Primavera was drawn without its door and a column with no door
  # reads as an open shelf. The division is derived, not printed, and its
  # provenance is in the section file's split_note. Nothing vanished quietly:
  # this line went red first, which is exactly the job.
  raise "expected 6 remainder codes, got #{found}" unless found == 6
  # AND THE TWO HEIGHTS ARE 120 APART, EVERYWHERE. The oven-and-microwave column
  # leaves 1710 at H.210 and 1830 at H.222; 1515 becomes 1635. That is the whole
  # difference between the families, and a transcription slip breaks it here.
  # THREE FAMILIES NOW, AND THE LADDER IS THE CHECK. 1710 / 1830 / 1950 and
  # 1515 / 1635 / 1755 - every step 120, which is the whole difference between
  # H.210, H.222 and H.234. A transcription slip in any of the three files
  # breaks a rung instead of looking plausible.
  #
  # THE LADDER SURVIVES THE DIVISION, and that is the point of keeping it here
  # rather than deleting the rung. C92640 no longer HAS a remainder, so its span
  # is now the SUM of the parts the split left - 750 + 600 + 600 - and that sum
  # must still stand 120 above C42640's 1830. A division that changed the total
  # would break this rung, which is precisely the mistake a split can make.
  span = lambda do |code|
    stack = Registry.lookup(code)['front_layout']['stack_top_to_bottom']
    r = stack.find { |e| e['kind'] == 'remainder' }
    next r['h_mm'] if r

    # divided: everything above the bottom front, which is the drawer
    parts = stack[0...-1]
    raise "#{code}: divided stack has no parts above the drawer" if parts.empty?

    parts.sum { |e| e['h_mm'].to_f }
  end
  pairs = { 'C63640' => 'C42640', 'C63659' => 'C43659',
            'C42640' => 'C92640', 'C43659' => 'C93659' }
  pairs.each do |low, high|
    a = span.call(low)
    b = span.call(high)
    raise "#{low} #{a} vs #{high} #{b}" unless b - a == 120
  end

  # and the division itself: three parts, and they sum to the span they replaced
  c = Registry.lookup('C92640')['front_layout']
  handle = c['stack_top_to_bottom']
  raise 'C92640 is not divided' if handle.any? { |e| e['kind'] == 'remainder' }
  raise handle.inspect unless handle.map { |e| e['h_mm'] } == [750, 600, 600, 390]
  raise 'the handle stack no longer sums to 2340' unless handle.sum { |e| e['h_mm'] } == 2340
  gola = c['gola_stack_top_to_bottom']
  raise gola.inspect unless gola.map { |e| e['h_mm'] } == [750, 600, 600, 30, 360]
  raise 'the gola stack no longer sums to 2340' unless gola.sum { |e| e['h_mm'] } == 2340
  # THE DOOR IS THE SAME 750 IN BOTH EXECUTIONS. That is the property the
  # remainder had before it was divided, and losing it would mean the division
  # had invented something the page does not support.
  raise 'the custom-sized door differs between executions' unless
    handle.first['h_mm'] == gola.first['h_mm']
  # and it says on itself that it was derived rather than read
  raise 'the derived door does not say it is derived' unless
    handle.first['derivation'].to_s.include?('DERIVED')
end

check('the span is DRAWN - a remainder becomes a void slab, not an absence') do
  u = Registry.lookup('C62610')
  slabs = Generator.front_slabs(u)
  voids = slabs.select { |sl| sl[:kind] == :void }
  raise slabs.inspect unless voids.length == 1
  v = voids.first
  # 195 + 780 = 975 from the bottom, and 1125 tall - the top of the column.
  raise v.inspect unless v[:h_mm] == 1125.0 && v[:z_mm] == 975.0
  raise v.inspect unless v[:name] == 'VOID_REMAINDER_1125'
  raise v.inspect unless v[:holds] == %w[custom_sized_front appliance_opening]
  raise 'the void must reach the top of the unit' unless
    v[:z_mm] + v[:h_mm] == u['height_mm']
end

check('AND A NICHE IS NOT A VOID - the 600 is measured, so it is not red') do
  # The difference the whole concept turns on: a void's division is undecided,
  # a niche's is decided and the appliance decides it.
  slabs = Generator.front_slabs(Registry.lookup('C62650'))
  op = slabs.select { |sl| sl[:kind] == :opening }
  raise slabs.inspect unless op.length == 1
  raise op.first.inspect unless op.first[:h_mm] == 600.0
  raise op.first.inspect unless op.first[:appliance_class] == 'oven_h60'
  raise 'a niche must not be a void' if slabs.any? { |sl| sl[:kind] == :void }
  # and the five stacks that measured it still leave exactly 600
  %w[C62650 C62750 C62653 C62753 C62657 C62757 C62651 C62751].each do |code|
    got = Generator.front_slabs(Registry.lookup(code))
                   .select { |sl| sl[:kind] == :opening }.sum { |sl| sl[:h_mm] }
    raise "#{code}: #{got}" unless got == 600.0
  end
end

check('A REMAINDER HIDES FRONTS AND DOES NOT ABOLISH THEM') do
  # printed p.121 prints '1 rh or lh custom-sized door' in words: how many is
  # known, only how tall is not. Three fronts, three handles.
  raise Export.fronts_in(Registry.lookup('C62610')['front_layout']).inspect unless
    Export.fronts_in(Registry.lookup('C62610')['front_layout']) == 3
  raise 'oven + microwave prints two fronts' unless
    Export.fronts_in(Registry.lookup('C63640')['front_layout']) == 2
  # and the niche is never one of them
  raise 'the oven niche must not be counted as a front' unless
    Export.fronts_in(Registry.lookup('C62651')['front_layout']) == 2
end

check('object_class = void requires a role, and nothing else may claim one') do
  base = {
    'schema_version' => '2', 'object_class' => 'void', 'manufacturer' => 'Cesar',
    'geometry_kind' => 'linear', 'height_mm' => 1125, 'depth_mm' => 22,
    'width_mm' => 600, 'code' => nil, 'code_status' => 'PRELIMINARY',
    'status' => 'PLANNING', 'source_ref' => 'printed p.121 / PDF 123'
  }
  begin
    Contract.validate!(base.dup)
    raise 'a void without a role validated'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('void_role')
  end
  Contract.validate!(base.merge('void_role' => 'front_remainder'))
  begin
    Contract.validate!(base.merge('void_role' => 'somewhere'))
    raise 'an unknown role validated'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('void_role')
  end
  begin
    Contract.validate!(base.merge('object_class' => 'cabinet',
                                  'void_role' => 'front_remainder'))
    raise 'a cabinet claimed a void role'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('only meaningful')
  end
end

check('the two halves of one concept use one word for it') do
  # The engine's void and the appliance module's void must not drift into two
  # unrelated ideas with the same name. Neither file may reach for the other -
  # SS11 - so what holds them together is the spec, and the spec must be cited
  # from both sides or it is a document nobody is bound by.
  spec = File.expand_path('../docs/Reserved_Void_Spec_v0.1.md', __dir__)
  raise 'the spec is missing' unless File.exist?(spec)
  gen = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  raise 'the generator must cite the spec' unless
    gen.include?('Reserved_Void_Spec')
  text = File.read(spec)
  %w[above_housing run_gap front_remainder].each do |role|
    raise "the spec must name #{role}" unless text.include?(role)
  end
end

puts "\nthe run gap - B6, the third void, and the one the order must not carry"

# NOTHING HERE TOUCHES THE APPLIANCE PACKAGE, and that is the point: the width
# arrives as a parameter, so this suite keeps passing on a machine where the
# appliance extension was never installed. The Wolf numbers are checked on the
# other side of the seam, in tools/test_appliance_seam.rb.
RUN_GAP = lambda do |over|
  # ** and not a bare hash: on Ruby 3 a trailing hash is a positional argument
  # and never keywords, and the suite runs on both.
  Generator.run_gap_attributes('DF48650C/S/P',
                               **{ width_mm: 1219, depth_mm: 620, carcass_top_mm: 880,
                                   worktop_t_mm: 40, source_ref: 'appliance guide p.97',
                                   note: 'RESERVED - client-supplied machine' }.merge(over))
end

# A model that holds attributes and nothing else. Project facts live on the
# model, so the only way to check them headlessly is to hand them one.
FAKE_MODEL = Class.new do
  def initialize
    @d = {}
  end

  def get_attribute(dict, key, default = nil)
    (@d[dict] || {}).fetch(key, default)
  end

  def set_attribute(dict, key, value)
    (@d[dict] ||= {})[key] = value
  end
end

check('a project number is STATED, kept on the model, and never defaulted') do
  m = FAKE_MODEL.new
  raise 'an unstated worktop must be nil, not a number' unless Project.worktop_t_mm(m).nil?
  raise 'the stated value did not come back' unless Project.worktop_t_mm!(40, m) == 40.0
  raise 'it did not survive on the model' unless Project.worktop_t_mm(m) == 40.0
  ['', 0, -20, nil].each do |bad|
    begin
      Project.worktop_t_mm!(bad, m)
      raise "#{bad.inspect} was accepted as a thickness"
    rescue ArgumentError => e
      raise e.message unless e.message.include?('positive')
    end
  end
  raise 'a bad write must not destroy the good one' unless Project.worktop_t_mm(m) == 40.0
end

check('a run gap is a void with a role, and it validates') do
  a = RUN_GAP.call({})
  Contract.validate!(a.dup)
  raise a.inspect unless a['object_class'] == 'void' && a['void_role'] == 'run_gap'
  raise a.inspect unless [a['width_mm'], a['depth_mm'], a['height_mm']] == [1219, 620, 920.0]
  raise 'a reservation must carry no code' unless a['code'].nil?
  raise a.inspect unless a['status'] == 'PLANNING'
end

check('the top is MEASURED plus STATED, and the object says which is which') do
  # 2026-08-25, the real kitchen: the first reservation stopped at 880 - the
  # carcass - and a gap in the run is a gap in the FINISHED run. 880 + 40 = 920,
  # and the range's own 928,4 stands proud of it, which is what a range does.
  a = RUN_GAP.call({})
  raise a.inspect unless a['height_mm'] == 920.0
  raise a['notes'] unless a['notes'].include?('880 MEASURED')
  raise a['notes'] unless a['notes'].include?('40 STATED')
  raise a['notes'] unless a['notes'].include?('nothing in the model draws it')
  # and a different project gets a different number, with no constant anywhere
  raise 'the worktop is hard-wired' unless RUN_GAP.call(worktop_t_mm: 20)['height_mm'] == 900.0
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/10_standards.rb', __dir__))
  raise 'a worktop thickness must not become a standard' if src =~ /WORKTOP/i
end

check('it refuses each of the four numbers it must not invent') do
  { width_mm: 'printed width', depth_mm: "run's depth",
    carcass_top_mm: "run's carcass top", worktop_t_mm: 'worktop thickness' }.each do |k, word|
    begin
      RUN_GAP.call(k => nil)
      raise "#{k} was invented"
    rescue ArgumentError => e
      raise "#{k}: #{e.message}" unless e.message.include?(word.split.last)
    end
  end
end

check('the page the width came from survives onto the object') do
  a = RUN_GAP.call({})
  raise a.inspect unless a['source_ref'].include?('p.97')
  raise a['notes'] unless a['notes'].include?('RESERVED')
  # And what the ENGINE measured says so, so nobody reads 620 as a default.
  raise a['notes'] unless a['notes'].include?('MEASURED')
end

check('a reservation is never an order line, and a cabinet is never a reservation') do
  a = RUN_GAP.call({})
  cab = Generator.attributes_for(Registry.lookup('B80601'))
  raise 'a reservation was ordered' if Export.orderable?(a)
  raise 'a reservation was not recognised' unless Export.reservation?(a)
  raise 'a cabinet became a reservation' if Export.reservation?(cab)
  raise 'a cabinet stopped being orderable' unless Export.orderable?(cab)
  raise 'nil must not blow up either question' if Export.reservation?(nil)
end

check('the reserved span reaches the schedule, and in its own block') do
  a = RUN_GAP.call({})
  cab = Generator.attributes_for(Registry.lookup('B80601'))
  raise 'a void must still produce no order row' unless Export.rows([a]).empty?
  held = Export.reservations([cab, a, cab])
  raise held.inspect unless held.size == 1
  r = held.first
  raise r.inspect unless r['row'] == 1 && r['void_role'] == 'run_gap'
  raise r.inspect unless r['description'].start_with?('RESERVED, UNASSIGNED')
  raise r.inspect unless [r['l_mm'], r['p_mm'], r['h_mm']] == [1219, 620, 920.0]
  csv = Export.reservations_csv(held)
  raise csv unless csv.lines.first.start_with?('row,void_role,description')
  raise csv unless csv.include?('1219')
end

check('the palette offers the reservation and never carries the width itself') do
  pal = File.read(File.expand_path('../src/ucon_cabinet_engine/core/90_palette.rb', __dir__))
  raise 'no callback' unless pal.include?("add_action_callback('reserve_run_gap')")
  raise 'no button' unless pal.include?('sketchup.reserve_run_gap()')
  raise 'the list must come from the appliance module' unless pal.include?('ApplianceCheck.run_gap_models')
  raise 'the worktop must be asked for, not assumed' unless pal.include?('Project.worktop_t_mm')
  raise 'no worktop thickness may be written into the palette' if pal =~ /worktop_t_mm!\(\s*\d/
  # A model number in this tree would be a second copy of somebody else's data,
  # and the first thing to go stale when the guide is revised.
  raise 'the engine must not hold an appliance model number' if pal =~ /DF\d{5}/
end

check('the model walk treats a reservation as a leaf, not as a box to open') do
  # No headless test can walk a SketchUp model, and this is the line that made
  # the difference between a schedule that prints the hole and one that never
  # sees it: the walker used to ask orderable? alone, and a void - excluded from
  # the order by class - was descended into as if it were a container.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/86_export_run.rb', __dir__))
  code = src.gsub(/^\s*#.*$/, '')
  raise 'the walker must ask Export.reservation?' unless code.include?('Export.reservation?')
  raise 'the reservations must be shaped by Export' unless code.include?('Export.reservations')
end


puts "\nend panels — printed p.440-447, and the first section with no ground of its own"

PANEL_SECTIONS = ['End elements for Maxima-Intarsio',
                  'Adjoining end side panel for N_Elle',
                  'Adjoining end side panel for N_Elle with framed door'].freeze

check('three collections, 124 codes, and each is a separate ARTICLE and not a variant') do
  rows = Registry.catalog.select { |c| PANEL_SECTIONS.include?(c['section']) }
  raise rows.length.to_s unless rows.length == 124

  by_section = rows.group_by { |r| r['section'] }.transform_values(&:length)
  raise by_section.inspect unless by_section == {
    'End elements for Maxima-Intarsio' => 76,
    'Adjoining end side panel for N_Elle' => 24,
    'Adjoining end side panel for N_Elle with framed door' => 24
  }
  # CORRECTED THE SAME EVENING. This said "the two pages price the same heights
  # and the same depth groups under different codes", which is false - see
  # page_split_note in every one of the three files. What the check now pins is
  # what was actually measured.
  types = rows.map { |r| r['type_key'] }.uniq.sort
  raise types.inspect unless types == %w[end_panel_45 end_panel_45_opposite_hinge]
  raise 'the two pages share a code' unless rows.map { |r| r['code'] }.uniq.length == 124
end

check('THE TWO PAGES OF A COLLECTION NEVER PRICE THE SAME DEPTH GROUP') do
  # The measurement that killed the first reading of this chapter, pinned so it
  # cannot be un-noticed. Within one collection the two printed pages partition
  # the depth groups with ZERO overlap, so there is no height-and-depth that
  # exists on both and nothing is ever a choice between them: the depth group
  # picks the code and the page follows.
  #
  # AND THE PARTITION MOVES BETWEEN COLLECTIONS, which is what rules out the
  # tidy explanation. Maxima puts 35+35 on the banner page; N_Elle and N_Elle
  # framed put it on the 45-degree page. So the banner does not mean
  # "back-to-back", and what it does mean is Elda Q22.
  groups = lambda do |section, type|
    Registry.catalog.select { |c| c['section'] == section && c['type_key'] == type }
            .map { |c| Registry.lookup(c['code'])['printed_depth_label'] }.uniq.sort
  end
  PANEL_SECTIONS.each do |sec|
    a = groups.call(sec, 'end_panel_45')
    b = groups.call(sec, 'end_panel_45_opposite_hinge')
    raise "#{sec}: a page is empty" if a.empty? || b.empty?
    raise "#{sec} overlaps on #{(a & b).inspect}" unless (a & b).empty?
  end
  # and the partition really does differ, so this is a fact about the book and
  # not an accident of one collection
  m = groups.call('End elements for Maxima-Intarsio', 'end_panel_45')
  n = groups.call('Adjoining end side panel for N_Elle', 'end_panel_45')
  # BETWEEN DIGITS. The first version matched a bare '+' and every label on
  # every page ends '+ door thickness', so it called all of them paired and the
  # check failed on true data. Learned rule 18's shape again: the title said back-to-back
  # and the matcher said plus sign.
  paired = ->(g) { g.any? { |x| x =~ /\d\+\d/ } }
  raise 'the collections now agree - re-read the pages and Q22' unless
    !paired.call(m) && paired.call(n)
end

check('EVERY end panel yields contract-valid attributes') do
  Registry.catalog.select { |c| PANEL_SECTIONS.include?(c['section']) }.each do |row|
    Contract.validate!(Generator.attributes_for(Registry.lookup(row['code'])))
  end
end

check('a panel takes its height from its ROW, because one table holds sixteen of them') do
  # The precedence added to Registry.lookup on 2026-08-26. Before it, height was
  # a family fact and this whole section was unrepresentable.
  raise 'PB0030' unless Registry.lookup('PB0030')['height_mm'] == 360
  raise 'C00030' unless Registry.lookup('C00030')['height_mm'] == 2340
  raise 'the family must not be answering' unless
    Registry.lookup('PB0030')['height_mm'] != Registry.lookup('C00030')['height_mm']
  # and a section that says nothing per row is untouched
  raise 'B80601 lost its family height' unless Registry.lookup('B80601')['height_mm'] == 780
end

check('the drawn depth is the catalog\'s, and the label it disagrees with is kept') do
  # DERIVED, and pinned rather than computed: d = sum of the carcass depths plus
  # 2,2 per door face, rounded up. Eight groups, and the rule closes on all of
  # them - including 72+35, which only the N_Elle collection prints and which the
  # rule was not derived from. depth_mm holds the PRINTED d. and nothing else.
  seen = {}
  Registry.catalog.select { |c| PANEL_SECTIONS.include?(c['section']) }.each do |row|
    u = Registry.lookup(row['code'])
    (seen[u['printed_depth_label']] ||= []) << u['depth_mm']
  end
  got = seen.transform_values { |v| v.uniq.sort }
  raise got.inspect unless got == {
    'for 35-cm deep side panel + door thickness'    => [375],
    'for 62-cm deep side panel + door thickness'    => [645],
    'for 67-cm deep side panel + door thickness'    => [695],
    'for 35+35-cm deep side panel + door thickness' => [750],
    # THE COLLISION. printed p.436, p.441, p.445 and p.447 all label the d.102
    # and the d.107 group "62+35". They cannot both be; the codes and the
    # arithmetic say d.107 is 67+35. Elda Q20. The label is kept VERBATIM, which
    # is why this one entry holds two depths - a silent correction here would
    # have hidden the question.
    'for 62+35-cm deep side panel + door thickness' => [1020, 1070],
    'for 72+35-cm deep side panel + door thickness' => [1120],
    'for 62+62-cm deep side panel + door thickness' => [1290]
  }
end

check('the picker grid must have something to put ON the button') do
  # The routing rule in 90_palette.sizeGrid: a width is worth a button only when
  # it tells the codes apart. Pinned in DATA here, because the grid itself is
  # JavaScript and cannot be reached from this suite.
  #
  # Andriy, 2026-08-26, opening End panels: four rows of nine buttons all
  # reading 22. Nothing was missing - the width was CONSTANT, and a constant on
  # a button is a button that says nothing.
  panels = Registry.catalog.select { |c| c['class'] == 'end_panel' }
  raise 'the panel width stopped being one number' unless
    panels.map { |c| c['width_mm'] }.uniq == [22]
  raise 'the panel height stopped being the article' unless
    panels.map { |c| c['height_mm'] }.uniq.length > 10

  # and the sections that DO route on width must still have a width that varies
  # inside a depth row, or the same blank buttons appear somewhere else
  %w[base wall tall].each do |cls|
    rows = Registry.catalog.select { |c| c['class'] == cls && c['width_mm'] }
    next if rows.empty?

    flat = rows.group_by { |c| [c['section'], c['type_key'], c['depth_mm']] }
               .reject { |_k, v| v.length < 2 }
               .select { |_k, v| v.map { |c| c['width_mm'] }.uniq.length == 1 &&
                                 v.map { |c| c['height_mm'] }.uniq.length == 1 }
    raise "#{cls}: rows that cannot be told apart: #{flat.keys.inspect}" unless flat.empty?
  end
end

check('a selected code reaches the Build button, whatever else it still needs asked') do
  # A SOURCE CHECK, and it exists because the whole suite was blind to this.
  # heightGrid was written for fillers, where the width widget always runs and
  # ends by calling showCard and syncBuild. An end panel states no width range,
  # so it hit the early return above them and Andriy picked B90030 with nothing
  # to press. Nothing headless could see it - the grid is JavaScript - so what
  # is pinned is the ORDER of two lines in the file.
  #
  # REPOINTED 2026-08-27, and the failure was the check doing its job. The
  # widget moved out of heightGrid into dimRows so the SHEET grid could use the
  # same one instead of a copy, and this check went red naming a guard that had
  # not disappeared, only moved. Learned rule 18 in its other form: when a check
  # fails for a reason its title does not mention, look at the check. What the
  # title claims - a selected code always reaches the button - is still exactly
  # what is being held; it is now held of BOTH grids, which is more than before,
  # because a sheet reaches the button through the other one.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/90_palette.rb', __dir__))
  guard_body = src[/function dimRows\(el, c\)\{(.+?)\n              \}\n/m, 1]
  raise 'dimRows is gone or renamed - re-read this check before deleting it' unless guard_body
  raise 'the width-range early return is gone - so is the reason for this check' unless
    guard_body.index('if(!c.width_range_mm) return;')

  %w[sheetGrid heightGrid].each do |fn|
    body = src[/function #{fn}\(el\)\{(.+?)\n              \}/m, 1]
    raise "#{fn} is gone or renamed" unless body

    sync = body.index('syncBuild(c);')
    card = body.index('showCard(c);')
    dims = body.index('dimRows(el, c);')
    raise "#{fn} no longer calls syncBuild" unless sync
    raise "#{fn} no longer calls showCard" unless card
    raise "#{fn} no longer offers the dimension rows" unless dims
    # THE ORDER IS THE CLAIM: the card and the button come BEFORE the widget
    # that may return early, so a code that still needs a dimension asked is
    # still a code you can see and press.
    raise "#{fn}: the Build button is behind the width-range return again" unless sync < dims
    raise "#{fn}: the card is behind it too" unless card < dims
  end
end

check('A PANEL STANDS ON THE FLOOR AND ITS FRONT IS IN THE PLANE OF THE DOORS') do
  # Andriy, 2026-08-26, on the first two YU0028 in the model: "the panel must
  # stand on the floor - lower it 100" and "the front edge must line up with the
  # door - move it forward 22". Both were wrong because a panel was being built
  # through the ordinary cabinet path, which answers a CABINET's questions: a
  # cabinet stands on its plinth, and a cabinet is drawn from the carcass front.
  panel = Registry.lookup('YU0028').merge(
    'mounting' => 'floor', 'mounting_default' => 'floor', 'plinth_h_mm' => 100
  )
  raise 'a panel is still standing on the plinth' unless Generator.base_z_mm(panel).zero?
  raise 'a plinth is still being drawn under it' if Generator.plinth?(panel)
  raise 'the front did not move' unless
    Generator.panel_front_y_mm(panel) == -Standards::FRONT_T_MM

  # THE NEIGHBOUR IS UNTOUCHED. The ground it hands over is a whole ground -
  # plinth_h_mm included - and only the panel reads it differently.
  cab = Registry.lookup('B80653')
  raise 'a cabinet left its plinth' unless Generator.base_z_mm(cab) == 100
  raise 'a cabinet lost its plinth' unless Generator.plinth?(cab)
  raise 'a cabinet moved forward' unless Generator.panel_front_y_mm(cab).zero?

  # and a HUNG panel keeps the hung datum - "on the floor" means nothing 1400 up
  hung = panel.merge('mounting' => 'wall_hung', 'mounting_default' => 'wall_hung')
  raise 'a hung panel fell to the floor' unless Generator.base_z_mm(hung).positive?
end

check('a panel has no front, and the empty list is stated rather than reached') do
  u = Registry.lookup('B70030')
  raise 'front_layout' unless u['front_layout']['kind'] == 'none'
  raise 'a panel grew a door' unless Generator.front_slabs(u).empty?
  # the guard that matters: an unknown kind still gets a full face, so 'none'
  # must not be arriving there by accident.
  raise 'the else branch stopped working' unless
    Generator.front_slabs(Registry.lookup('B80601')).length == 1
end

check('a panel refuses a width modification, and NOT for the catalog\'s reason') do
  u = Registry.lookup('B70030')
  raise 'not refused' unless Registry.width_modification_refusal(u)
  raise 'wrong reason' unless
    Registry.width_modification_refusal(u) == 'end panels, whose width is a thickness'
  # It must come from the thickness guard and not from the catalog's list -
  # sixty of these matched 'units with jumbo drawers' before the guard existed,
  # on the strength of printed p.441's own title.
  raise 'the catalog list must not claim it' unless
    Registry::WIDTH_MOD_FORBIDDEN.none? { |_why, test| test.call(u) } ||
    Registry.width_is_a_thickness?(u)
  raise 'width_is_a_thickness? must be about panels only' if
    Registry.width_is_a_thickness?(Registry.lookup('B80601'))
end

check('the one misprinted height is corrected AND the printed value survives') do
  # Y00129 is printed H.84 on printed p.445 and recorded at H.36,8: the parallel
  # framed page prints the same group as 36,8/78/84, and Y0/Y3/Y6 is that triple
  # everywhere else in the collection. Verified against a rendered page image, so
  # it is the catalog's misprint. A correction that erases what was printed is
  # not a correction, it is a second source.
  reg = JSON.parse(File.read(File.expand_path('../registry/cesar/end_panels_nelle.json', __dir__)))
  ut  = reg['data']['unit_types']['end_panel_45_opposite_hinge']
  row = ut['codes'].find { |c| c['code'] == 'Y00129' }
  raise 'Y00129 is gone' unless row
  raise 'height' unless row['height_mm'] == 368
  raise 'the printed value was erased' unless row['printed_height_cm'] == '84'
  raise 'the reason is not written down' unless ut['height_correction_2026_08_26'].to_s.include?('misprint')
  raise 'and the group must hold no second H.84' unless
    ut['codes'].select { |c| c['depth_mm'] == 1120 }.map { |c| c['height_mm'] }.sort == [368, 780, 840]
end

check('NOTHING is drawn on a guessed ground, and the refusal says why') do
  msg = Generator.panel_needs_a_ground_message('B70030')
  raise 'the code' unless msg.include?('B70030')
  raise 'the page' unless msg.include?('p.440')
  raise 'what to do' unless msg.downcase.include?('select the unit')
  raise 'and that nothing happened' unless msg.include?('Nothing was drawn')
end

check('the 1,8 cm panel is held as a SURCHARGE and never as an article') do
  # printed p.553: "Surcharge for finishing side panels, 1.8 cm thick | Replacing
  # standard side panel". No codes on the page, and under domain rule 4 it draws
  # nothing - the carcass already occupies that volume. The map must say so, and
  # no registry row may claim it.
  sec = Registry.map_sections.find { |s| s['printed_pages'].to_s == '551-553' }
  raise 'the 1,8 section is not in the map' unless sec
  raise 'status' unless sec['status'] == 'not_extracted'
  raise 'the reason must be recorded' unless sec['note'].include?('Replacing standard side panel')
  raise 'it must not be sold as an article' unless sec['note'].include?('prints no codes')
  raise 'no row may be 1,8 thick' unless
    Registry.catalog.select { |c| c['class'] == 'end_panel' }.all? { |c| c['width_mm'] == 22 }
end


check('every class the catalog holds has a picker label') do
  # Added 2026-08-26 with 'end_panel'. Without it a new class reaches the picker
  # as its bare key - a heading reading "end_panel" over 124 codes - and nothing
  # would have failed. A label is display vocabulary and never travels into
  # data, so this only guards the display.
  # BOTH SETS, and the second one is why this check existed at all. The picker
  # draws a heading per class in the registry AND per class in the catalog map,
  # because an unextracted chapter shows as an inert CATALOG ONLY row. The first
  # version read only the registry and went green while three map classes -
  # glass, open_unit, side_panel - rendered as bare keys in the dialog. Andriy
  # saw it in the dialog the same evening. A check can only fail on what it
  # looks at, and it was looking at half.
  held    = Registry.catalog.map { |c| c['class'] }.uniq.compact
  mapped  = Registry.map_sections.map { |x| x['class'] }.uniq.compact
  classes = (held + mapped).uniq
  missing = classes.reject { |c| Palette::CLASS_LABELS.key?(c) }
  raise "no label for #{missing.inspect}" unless missing.empty?
  raise "a label exists for a class nothing holds: " \
        "#{(Palette::CLASS_LABELS.keys - classes).inspect}" unless
    (Palette::CLASS_LABELS.keys - classes).empty?
end

puts "\nthe rules — which list a number belongs to"

check('A BARE "rule N" IS A DEFECT: every citation names its list') do
  # 2026-08-27, while tidying. This repository cites rules by bare number about
  # ninety times and there are FOUR numbering schemes, three of them starting at
  # 1: domain rules (CLAUDE.md, 1-9), learned rules (the status document, 1-18),
  # the Object Contract's own §-scoped rules, and - discovered by this tidy - a
  # dozen notes citing a bare four for "this is a UCON decision", which is in NO
  # list at all. The bare one meant two different things four files apart; the
  # bare four meant three.
  #
  # Numbers are NOT renumbered: that would silently change what every historical
  # note and commit message says, which is exactly what learned rule 9 forbids.
  # Instead every citation names its list, and this keeps the new ones honest.
  # claude/rules.md is the index.
  ok = /(domain|learned|§[\d.]+|SS[\d.]+)\s+rule\s+\d/i
  any = /\brule\s+\d{1,2}/i
  bad = []
  root = File.expand_path('..', __dir__)
  paths = Dir[File.join(root, 'registry', '**', '*.json')] +
          Dir[File.join(root, 'src', '**', '*.rb')] +
          Dir[File.join(root, 'tools', '*.rb')]
  paths.each do |f|
    next if f.include?('probe_inbox')

    File.readlines(f).each_with_index do |line, i|
      next unless line =~ any

      # a line may hold several; strip the qualified ones and see what is left
      rest = line.gsub(ok, '')
      next unless rest =~ any

      bad << "#{f.sub(root + '/', '')}:#{i + 1}"
    end
  end
  raise "bare rule citations: #{bad.first(12).inspect}#{bad.length > 12 ? " (+#{bad.length - 12})" : ''}" unless
    bad.empty?
end

check('every Elda question is in the status table') do
  # 2026-08-27. The register's summary line - "Q11 to Q19 are the Avenida
  # Primavera batch..." - was hand-patched five times in one day and was wrong
  # by the end of it. A table that nothing checks is a table that lies quietly.
  doc = File.read(File.expand_path('../docs/Elda_Open_Questions_v0.1.md', __dir__))
  table = doc[/^## Status at a glance.*?^---$/m].to_s
  raise 'the status table is gone' if table.empty?

  # every numbered question heading, minus the CLOSED follow-up sections which
  # repeat a number they do not own
  asked = doc.scan(/^## (Q\d{1,2}) [—-]/).flatten.uniq
  raise 'no questions found - the heading format changed' if asked.length < 20

  missing = asked.reject { |q| table =~ /^\| #{q} \|/ }
  raise "not in the status table: #{missing.inspect}" unless missing.empty?

  # and every question must still say its own status where it is answered
  no_status = asked.reject do |q|
    body = doc[/^## #{q} [—-].*?(?=^## |\z)/m].to_s
    body.include?('**Status:**')
  end
  raise "no Status line: #{no_status.inspect}" unless no_status.empty?
end

check('every working note is named in claude/README.md') do
  # 2026-08-27. The index had stopped at 2026-08-24 and fifteen files were
  # missing from it, including every finding of the two busiest days. An index
  # nobody maintains is worse than no index, because it reads as a complete
  # list - which is learned rule 13 wearing a different hat: a record of
  # something outside the code is only true if something checks it.
  dir = File.expand_path('../claude', __dir__)
  readme = File.read(File.join(dir, 'README.md'))
  missing = Dir.children(dir).sort.reject do |f|
    f == 'README.md' || !File.file?(File.join(dir, f)) || readme.include?(f)
  end
  raise "not named in claude/README.md: #{missing.inspect}" unless missing.empty?
end

check('and the index names every list that is cited') do
  rules = File.read(File.expand_path('../claude/rules.md', __dir__))
  ['domain rule', 'learned rule', '§4.2 rule'].each do |scheme|
    raise "claude/rules.md does not explain #{scheme}" unless rules.include?(scheme)
  end
  # the two lists it reproduces must still be the length it claims
  claude = File.read(File.expand_path('../CLAUDE.md', __dir__))
  domain = claude[/^## Non-negotiable domain rules$(.+?)^## /m, 1].to_s.scan(/^\d+\. \*\*/).length
  raise "CLAUDE.md holds #{domain} domain rules; rules.md lists 9" unless domain == 9
  status = File.read(File.expand_path('../claude/ucon-cabinet-engine-status.md', __dir__))
  learned = status[/^## RULES LEARNED THE HARD WAY.*?$(.+?)^## /m, 1].to_s.scan(/^\*\*\d{1,2}\. /).length
  raise "the status document holds #{learned} learned rules; rules.md lists 18" unless learned == 18
end

puts "\npanels priced by the square metre - Linear Elements printed p.214-220"

check('THE REGISTRY NOW HOLDS TWO BOOKS, and every code says which') do
  # THE DEFECT THIS EXISTS FOR, and it was live until this commit: source_pdf
  # was one value in _manifest.json for the whole registry, so the first Linear
  # Elements code would have cited "CESAR - 2 Kitchen System.pdf printed p.215".
  # Both halves of that sentence are real - the Kitchen System HAS a p.215 - so
  # nothing would have looked wrong. Learned rule 15: a successful write is not
  # a correct write; check the identity fields.
  sheet = Registry.lookup('DZAK22')
  raise sheet['source_ref'].inspect unless
    sheet['source_ref'] == 'CESAR - 3 Linear Elements.pdf printed p.217 / PDF 219'

  # and the default did not move for the fifty-five sections that are Volume 2
  raise Registry.lookup('B80601')['source_ref'].inspect unless
    Registry.lookup('B80601')['source_ref'].start_with?('CESAR - 2 Kitchen System.pdf ')

  # no leakage, either way, across all 924
  # TWO CLASSES COME OUT OF VOLUME 3 NOW - the per-m2 panels and, since
  # 2026-08-27, the shelves. The list is written out rather than derived so that
  # a third one has to be added here on purpose.
  volume_three = %w[panel_sheet shelf]
  wrong = Registry.catalog.reject do |r|
    want = volume_three.include?(r['class']) ? 'CESAR - 3 Linear Elements.pdf' : 'CESAR - 2 Kitchen System.pdf'
    r['source_ref'].to_s.start_with?("#{want} ")
  end
  raise "cite the wrong book: #{wrong.map { |r| r['code'] }.first(8).inspect}" unless wrong.empty?
end

check('a sheet is 44 codes in ten blocks, and all of them build') do
  rows = Registry.catalog.select { |c| c['class'] == 'panel_sheet' }
  raise rows.length.to_s unless rows.length == 44
  raise rows.map { |r| r['type_key'] }.uniq.length.to_s unless
    rows.map { |r| r['type_key'] }.uniq.length == 10

  # HELD NOT-BUILDABLE AND RELEASED THE SAME DAY, 0.89.0 -> 0.90.0. The ten
  # blocks carried ONE refusal in ONE wording precisely so that the day the
  # generator learned the orientation, a single edit would clear all of them.
  # It did. The check turned over with the work instead of being deleted, and
  # what it holds now is that nothing was left behind.
  stuck = rows.reject { |r| r['buildable'] }
  raise "still not buildable: #{stuck.map { |r| r['code'] }.inspect}" unless stuck.empty?
  raise 'a reason survived the release' if rows.any? { |r| r['not_buildable_reason'] }
end

check('A SHEET IS DRAWN AS A BOARD, NOT AS AN END PANEL TURNED SIDEWAYS') do
  sheet = Registry.lookup('DZAK22')
  end_p = Registry.lookup('YU0028')
  raise 'a sheet' unless Registry.sheet_panel?(sheet)
  raise 'an end panel' if Registry.sheet_panel?(end_p)
  raise 'a cabinet' if Registry.sheet_panel?(Registry.lookup('B80601'))

  # NO FRONT EDGE. An end panel is pushed one door thickness forward so its edge
  # lands in the plane of the doors. A board behind a run has no such edge, and
  # the same shift would drive it into the carcass it is bolted to.
  raise Generator.panel_front_y_mm(sheet).inspect unless
    Generator.panel_front_y_mm(sheet) == 0.0
  raise Generator.panel_front_y_mm(end_p).inspect unless
    Generator.panel_front_y_mm(end_p) == -Standards::FRONT_T_MM.to_f

  # ON THE FLOOR, AND NOTHING INHERITED. printed p.214 stands it on 0,5 cm feet
  # whatever it is bolted to, so unlike an end panel it does not take its
  # neighbour's plinth - which on this island would have raised it 100 mm. That
  # is the exact error the two YU0028 in the model still carry from 0.87.4,
  # measured by probe run 53: drawn 940 against an article of 840.
  ordered = Registry.with_ordered_height(
    Registry.with_ordered_width(sheet.merge('mounting' => 'floor', 'plinth_h_mm' => 0), 1200), 880
  )
  raise Generator.base_z_mm(ordered).inspect unless Generator.base_z_mm(ordered).zero?
  raise 'a sheet must not carry a plinth box' if Generator.plinth?(ordered)

  # the board itself: 1200 along the run, 22 thick, 880 tall - floor to the
  # underside of the stone on a 620-deep H.78 run.
  attrs = Generator.attributes_for(ordered)
  raise attrs.inspect unless attrs['width_mm'] == 1200 &&
                             attrs['depth_mm'] == 22 &&
                             attrs['height_mm'] == 880
  Contract.validate!(attrs)
end

check('A SHEET HAS NO WIDTH AND NO HEIGHT, and both refusals name the order') do
  u = Registry.lookup('DZAD22')
  raise 'a sheet must not state a width' if u['width_mm']
  raise 'a sheet must not state a height' if u['height_mm']
  raise u['width_range_mm'].inspect  unless u['width_range_mm']  == [1, 2050]
  raise u['height_range_mm'].inspect unless u['height_range_mm'] == [1, 2780]
  # thickness is on DEPTH, because that is the axis a board is thin on
  raise u['depth_mm'].inspect unless u['depth_mm'] == 22

  begin
    Registry.with_ordered_height(u, nil)
    raise 'built with no height'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('priced by the square metre')
  end
  begin
    Registry.with_ordered_width(u, nil)
    raise 'built with no width'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('stated per order')
  end
end

check('880 is ordered, not modified - the whole point of the height range') do
  # The island of 545 Avenida Primavera: 1200 x 880, floor to the underside of
  # the top. Volume 1 printed p.73 and p.82 give the chain 780 + 100 = 880.
  u = Registry.with_ordered_height(Registry.lookup('DZAK22'), 880)
  raise u['height_mm'].inspect unless u['height_mm'] == 880
  # AND NOT AS A MODIFICATION. Before the range path this method compared 880
  # against a stated height and recorded the difference, which would have put a
  # reduction surcharge on an order line the catalog never charges.
  raise 'recorded as a modification' if u['height_reduced_from_mm'] || u['height_increased_from_mm']

  w = Registry.with_ordered_width(u, 1200)
  raise w['width_mm'].inspect unless w['width_mm'] == 1200
  raise 'a sheet must not be scribed' if w['scribe_mm']
end

check('a panel bigger than the sheet is refused, and the message says so') do
  # lacquer is cut from 120 x 300; the melamine beside it from 205 x 278.
  begin
    Registry.with_ordered_height(Registry.lookup('DZAK22'), 3200)
    raise 'accepted a height no sheet holds'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('does not come out of it')
  end
  raise 'and 3000 is inside it' unless
    Registry.with_ordered_height(Registry.lookup('DZAK22'), 3000)['height_mm'] == 3000
  # the tallest sheet in the chapter, and the counter-example to "278 is the sheet"
  raise 'laminate reaches 418 cm' unless
    Registry.with_ordered_height(Registry.lookup('DZBZ22'), 4180)['height_mm'] == 4180
end

check("A SHEET'S WIDTH IS NOT A THICKNESS, and an end panel's still is") do
  # learned rule 6, one day later: the predicate was written when there was one
  # kind of panel. It keyed on the CLASS, so all 44 sheets would have answered
  # "my width is a thickness, refuse to cut me" - about the one dimension that
  # is genuinely theirs.
  raise 'a sheet' if Registry.width_is_a_thickness?(Registry.lookup('DZAK22'))
  raise 'an end panel' unless Registry.width_is_a_thickness?(Registry.lookup('YU0028'))
  raise 'a cabinet' if Registry.width_is_a_thickness?(Registry.lookup('B80601'))
end

check('the minimum, the surcharges and the rate are held as the page prints them') do
  reg = Registry.data
  t = reg['families']['Panels (Linear Elements)']['unit_types']['panel_lacquered']
  raise t['minimum_invoicing_m2'].inspect unless t['minimum_invoicing_m2'] == 0.5
  raise 'the rate is per m2' unless t['codes'].find { |c| c['code'] == 'DZAK22' }['points_per_m2'] == 405
  s = t['surcharges']
  raise s.inspect unless s['cutout_for_electrical_socket']['points'] == 32 &&
                         s['out_of_square_reduction']['points'] == 27 &&
                         s['inner_or_outer_reduction']['points'] == 65
  # AND THE PRICES ARE NOT MONOTONE. Printed twice in the veneer pages: group C
  # costs more than group D. A reader tidying this would "fix" the catalog.
  v = reg['families']['Panels (Linear Elements)']['unit_types']['panel_veneer_2sides_horizontal']['codes']
  c_pts = v.find { |x| x['code'] == 'DV062Q' }['points_per_m2']
  d_pts = v.find { |x| x['code'] == 'DV063Q' }['points_per_m2']
  raise "C #{c_pts} D #{d_pts}" unless c_pts == 1038 && d_pts == 1002 && c_pts > d_pts
end

check('the fixing kit is priced per BASE UNIT, and that is why it is not a companion') do
  # Four 600 units behind TWO 1200 panels take FOUR kits. A companion_ref hangs
  # off the article it rides on and would have counted two. Held in the manifest
  # until Contract v2 4.2 can say "quantity comes from the run".
  hw = Registry.data['hardware']['linear_element_panel_fixings']
  kits = hw['fixing_kits']
  raise kits.length.to_s unless kits.length == 7
  k600 = kits.find { |k| k['base_unit_width_mm'] == 600 }
  raise k600.inspect unless k600['code'] == '990486' && k600['points'] == 69
  raise 'the foot' unless hw['adjustable_foot']['code'] == '990408' &&
                          hw['adjustable_foot']['points'] == 6
  # HOW MANY FEET IS NOT PRINTED, and the absence is recorded rather than filled
  raise 'a count was invented' if hw['adjustable_foot']['quantity_note'].to_s.empty?
  raise 'no panel carries a companion for the kit' if
    Registry.lookup('DZAK22')['companions'].any?
end

check('THE PICKER CAN ASK FOR A HEIGHT, and until 0.91.0 it could not') do
  # A SOURCE CHECK, because the grid is JavaScript and nothing headless can run
  # it - the same reason the Build-button check exists two hundred lines up.
  #
  # THE DEFECT: the palette knew width_range_mm and only that. One W field, one
  # validation, and doBuild sent two arguments. A panel priced by the square
  # metre states NEITHER dimension, so it reached the Build button and was
  # refused by the guard that makes it honest - the engine could draw it and the
  # dialog could not order it. Found by reading the palette after the geometry
  # landed, and named in the 0.90.0 commit rather than left for a click.
  html = Palette.picker_html(Registry.catalog, Registry.gaps)
  raise 'no height field' unless html.include?("hlab.textContent = 'H mm'")
  raise 'the height is not read back into the state' unless
    html.include?('st.h = hinp.value')
  raise 'build still sends two arguments' unless
    html.include?('(c && c.height_range_mm) ? String(parseInt(st.h, 10))')
  raise 'the height is not validated against the sheet' unless
    html.include?('c.height_range_mm[1]')
  raise 'a sheet is not routed to its own grid' unless
    html.include?('if(rs.length && rs[0].height_range_mm){ sheetGrid(el); return; }')
  # and the two grids share ONE widget rather than a copy
  raise 'dimRows is not shared' unless html.scan('dimRows(el, c);').length >= 2
end

check('and the sheet grid has something to put ON its buttons') do
  # THE SAME SHAPE AS THE END-PANEL BUTTON READING '22' TWENTY-SEVEN TIMES.
  # A sheet has no width and no height, and its depth is a thickness, so the
  # only things that tell two of its codes apart are the price group, the number
  # of faced sides and the rate. All three had to reach the catalog row; a
  # button cannot show what the picker was never given.
  rows = Registry.catalog.select { |c| c['class'] == 'panel_sheet' }
  blind = rows.reject { |r| r['faced_sides'] && r['points_per_m2'] }
  raise "nothing to label: #{blind.map { |r| r['code'] }.first(6).inspect}" unless blind.empty?
  # the lacquered block is the one that needs the group letter: sixteen codes,
  # four groups, four executions, and the thickness alone separates none of them
  lac = rows.select { |r| r['type_key'] == 'panel_lacquered' }
  raise lac.length.to_s unless lac.length == 16
  raise 'no price group' unless lac.map { |r| r['price_group'] }.uniq.sort == %w[A B C D]
  # one side or two, and it is a real distinction: 1,8 is sold both ways
  raise 'sides' unless lac.map { |r| r['faced_sides'] }.uniq.sort == [1, 2]
end

puts "\nHorizontal Thin - the first element whose ground is another unit"

check('four codes, and the page decides where they stand') do
  rows = Registry.catalog.select { |c| c['class'] == 'open_unit' }
  raise rows.length.to_s unless rows.length == 4
  raise rows.map { |r| r['code'] }.sort.inspect unless
    rows.map { |r| r['code'] }.sort == %w[B01862 B01869 B02462 B02469]
  u = Registry.lookup('B01869')
  raise u['height_mm'].inspect unless u['height_mm'] == 390
  raise u['depth_mm'].inspect  unless u['depth_mm'] == 350
  raise u['width_mm'].inspect  unless u['width_mm'] == 1800
  raise 'the shelf length is what separates the pairs' unless
    Registry.lookup('B01869')['shelf_length_mm'] == 874 &&
    Registry.lookup('B01862')['shelf_length_mm'] == 1174
  # the light is an OPTION with its own points, not part of the code
  raise 'lights' unless u['lights_surcharge_points'] == 274
  # an open module has no front, and the empty list is stated
  raise Generator.front_slabs(u).inspect unless Generator.front_slabs(u).empty?
end

check('IT CANNOT STAND ON THE FLOOR, and the refusal quotes the page') do
  # printed p.458: 'Can only be fitted below a top.' The datum is the run below,
  # and there is no honest default for which run - the same shape as an end
  # panel's ground, and the first time the catalog itself demands it.
  u = Registry.lookup('B01869')
  raise 'not marked' unless Generator.stands_on_unit_below?(u)
  raise 'a base unit must not be' if Generator.stands_on_unit_below?(Registry.lookup('B80601'))

  msg = Generator.stands_on_needs_a_unit_message('B01869')
  raise msg unless msg.include?('Can only be fitted below a top')
  raise msg unless msg.include?('Nothing was drawn')

  # and once it HAS a ground, the bottom is that run's top - 100 of plinth plus
  # 780 of H.78 carcass, taken through the code and not off a body
  grounded = u.merge('stands_on_top_mm' => 880.0, 'stands_on_code' => 'B80653')
  raise Generator.base_z_mm(grounded).inspect unless Generator.base_z_mm(grounded) == 880.0
  # which puts its own top at 1270, and the mandatory top above that
  raise 'the module tops out at 1270' unless
    Generator.base_z_mm(grounded) + grounded['height_mm'] == 1270
end

puts "\nshelves - Linear Elements printed p.223-224"

check('nine codes, three thicknesses, and the thickness is in the code') do
  rows = Registry.catalog.select { |c| c['class'] == 'shelf' }
  raise rows.length.to_s unless rows.length == 9
  rows.each do |r|
    u = Registry.lookup(r['code'])
    # MNS + thickness x10 + depth in cm. A row that disagreed with its own code
    # would be a transcription slip that looks like data.
    # MNS + thickness in MILLIMETRES, three digits (022 = 2,2 cm = 22 mm) + depth
    th = r['code'][3, 3].to_i
    raise "#{r['code']}: code says #{th}, row says #{u['height_mm']}" unless u['height_mm'] == th
    raise "#{r['code']}: no thickness" unless [22, 40, 60].include?(u['height_mm'])
  end
  raise 'three thicknesses' unless rows.map { |r| Registry.lookup(r['code'])['height_mm'] }.uniq.sort == [22, 40, 60]
  # and the depth field: 038 / 060 / 000, the last meaning per m2 at D.120
  d = rows.map { |r| Registry.lookup(r['code'])['depth_mm'] }.uniq.sort
  raise d.inspect unless d == [380, 600, 1200]
end

check('A SHELF HANGS, and it took three tries to make the loader agree') do
  # IT SAT NOT BUILDABLE IN THE PICKER, and Andriy saw it before any check did.
  # mounting was declared on the UNIT TYPE; Registry.lookup reads it from
  # family['mounting'] and nowhere else, so all nine came out 'floor', inherited
  # the default plinth of 100 and failed the contract's own rule that a hung
  # object needs a positive datum.
  #
  # THIS IS THE THIRD INSTANCE IN ONE DAY of one shape - a key written correctly
  # into a section file that the loader does not lift: the Horizontal Thin's
  # height this morning, height_range_mm on the sheets before that, and the
  # wall_hung key of 2026-08-22 that started the list. The fix is always one
  # line; finding it is not.
  u = Registry.with_ordered_width(Registry.lookup('MNS040038'), 1800)
  raise u['mounting'].inspect unless u['mounting'] == 'wall_hung'
  raise 'it must hang BY NATURE, or the datum falls through to a plinth' unless
    Generator.hangs_by_nature?(u)
  raise Generator.base_z_mm(u).inspect unless Generator.base_z_mm(u) == Standards::WALL_MOUNT_BOTTOM_MM
  raise 'a hung board has no plinth' if Generator.plinth?(u)
  raise 'and no front' unless Generator.front_slabs(u).empty?

  a = Generator.attributes_for(u)
  raise a['mount_bottom_mm'].inspect unless a['mount_bottom_mm'] == Standards::WALL_MOUNT_BOTTOM_MM
  raise a.values_at('width_mm', 'depth_mm', 'height_mm').inspect unless
    [a['width_mm'], a['depth_mm'], a['height_mm']] == [1800, 380, 40]
  Contract.validate!(a)
  # THE DATUM IS WRITTEN ONTO THE OBJECT, which is what makes moving it safe:
  # mount_bottom_mm recomputes only when nothing has stated one.
  moved = Generator.mount_bottom_mm(u.merge('mount_bottom_mm' => 1650))
  raise moved.inspect unless moved == 1650.0
end

check('THE 4 CM SHELF EXISTS, and the first search said it did not') do
  # The search note said this chapter prints 2,2 and 6,0 only. It was done on the
  # text layer; printed p.223 carries TWO blocks and the second is 4 cm.
  # learned rule 10 - look at the render - and this check is that correction with
  # teeth on it. NOTE the wrap: a citation must not be split across two lines, or
  # the bare-rule check sees the number stranded on the second one - which is the
  # defect it exists for, and it caught this comment twice while it was written.
  u = Registry.lookup('MNS040038')
  raise u['height_mm'].inspect unless u['height_mm'] == 40
  raise u['depth_mm'].inspect  unless u['depth_mm'] == 380
  raise 'the order states the length' unless u['width_range_mm'] == [1, 3000]
  raise 'and the table governs it' unless u['max_length_mm'] == 3000
  raise u['source_ref'].inspect unless
    u['source_ref'] == 'CESAR - 3 Linear Elements.pdf printed p.223 / PDF 225'
end

check('a price band the page leaves EMPTY stays empty') do
  # Band 2 is blank on all three 4 cm rows and bands 1 AND 2 on all three 6 cm
  # rows - read off the renders. A missing band is a fact about the article; a
  # filled-in one would be an invented price.
  b40 = Registry.data['families']['Shelves (Linear Elements)']['unit_types']['shelf_40']['codes']
  b60 = Registry.data['families']['Shelves (Linear Elements)']['unit_types']['shelf_60']['codes']
  b40.each { |c| raise "#{c['code']} band 2" if c['points_by_band'].key?('2') }
  b40.each { |c| raise "#{c['code']} band 1" unless c['points_by_band'].key?('1') }
  b60.each do |c|
    raise "#{c['code']} band 1" if c['points_by_band'].key?('1')
    raise "#{c['code']} band 2" if c['points_by_band'].key?('2')
    raise "#{c['code']} band 4" unless c['points_by_band']['4']
  end
  raise 'MNS040038 band 1' unless b40.first['points_by_band']['1'] == 91
  raise 'MNS060038 band 4' unless b60.first['points_by_band']['4'] == 234
end

check('THE FIXINGS ARE ORDER LINES AND NEVER GEOMETRY') do
  # Andriy, 2026-08-27: they are not drawn, they go to the warehouse. So they are
  # in hardware and NOT in any section - a code in a section file is a thing the
  # picker offers to build.
  hw = Registry.data['hardware']['shelf_fixings']
  codes = hw['items'].map { |i| i['code'] }.sort
  raise codes.inspect unless codes == %w[990307 990315 990316 990317 990331]
  raise 'a fixing leaked into the catalog' unless (Registry.codes & codes).empty?

  # the count rule is the catalog's, the spacing rule is ours, and both say so
  raise 'count rule' unless hw['count_rule'].include?('ceil(L / 500)')
  raise 'the spacing rule must name itself as ours' unless hw['spacing_rule'].start_with?('UCON')

  # the thickness gate, and the hole in it: nothing takes a 4 cm shelf on a back panel
  by_th = hw['items'].select { |i| Array(i['for_thickness_mm']).include?(40) }.map { |i| i['code'] }
  raise by_th.inspect unless by_th.sort == %w[990316 990317]
  back = hw['items'].find { |i| i['fixes_to'] == 'a back panel' }
  raise 'a back-panel support for 4 cm appeared' if Array(back['for_thickness_mm']).include?(40)
end

check('the led is a RULE on the shelf, not a surcharge - and its lamp is in another book') do
  led = Registry.data['families'] && Registry.data['catalog_map'] # touch, then read the section
  rule = JSON.parse(File.read(File.expand_path('../registry/cesar/shelves_linear_elements.json', __dir__)))['data']['led_rule']
  raise 'no led rule' unless rule
  raise rule['light_length_mm'].inspect unless rule['light_length_mm'] == 'shelf length - 3'
  raise rule['max_light_length_mm'].inspect unless rule['max_light_length_mm'] == 3000
  raise rule['lamp_position_in_depth_mm'].inspect unless rule['lamp_position_in_depth_mm'] == 18
  # THE LAMP IS PRICED IN VOLUME 2 AND WE HOLD NONE OF THAT PAGE. One order line,
  # two books - said out loud rather than half-held.
  raise 'the lamp must name its book' unless rule['lamp_source'].include?('Kitchen System')
  raise 'and say it is not extracted' unless rule['lamp_source'].include?('NOT YET EXTRACTED')
  # AND THE PAGE IT IS ACTUALLY ON. printed p.224 sends the reader to "page 526"
  # of the Kitchen System, and printed p.526 of the Kitchen System is waste bins.
  # The Sky-B is p.528-529. Our own earlier note copied the 526 without checking
  # it, which is how a wrong cross-reference becomes our wrong cross-reference.
  raise 'the lamp must cite the page it is really on' unless
    rule['lamp_source'].include?('p.528')
  raise 'and the catalog\'s own error must be recorded, not silently corrected' unless
    rule['cross_reference_error'].to_s.include?('526')

  # THE TEMPERATURE, which is the thing that arrives wrong. printed p.528: the
  # Emotion Dual Color device is PROVIDED and adjusts 3000K to 4000K, so there is
  # nothing to specify on the order - and the registry must say that rather than
  # leave a silence somebody fills with a guess.
  raise 'the temperature must be stated' unless
    rule['colour_temperature_k'].to_s.include?('3000/4000')
  raise 'and stated as adjustable' unless
    rule['colour_temperature_k'].to_s.include?('adjustable')
  raise 'the beam angle is the page\'s' unless rule['beam_angle_deg'] == 96
  # The LAMP's limit and the SHELF's limit are different numbers from different
  # pages, and the shorter one wins. Holding both is what stops one being read
  # as the other.
  raise 'the lamp has its own maximum' unless rule['lamp_max_length_mm'] == 3900
  raise 'and it is longer than the shelf can ever be' unless
    rule['lamp_max_length_mm'] > rule['max_light_length_mm']
  raise 'a lit shelf is never one line' unless
    rule['transformer_note'].to_s.include?('mandatory')
  raise 'the lamp code must not be invented' if Registry.codes.include?('Sky-B')
end

check('the Luminous glass shelf is NOT held, and the reason is 110V') do
  # printed p.539, Kitchen System: 'Not available version 110V' - the only such
  # exclusion in that book, and this is a 110V project. Andriy, 2026-08-27: on
  # principle. A deliberate absence has to be recorded or it reads as an oversight.
  sec = Registry.map_sections.find { |x| x['section'] == 'Shelves - Linear Elements' }
  raise 'the shelves section is unmapped' unless sec
  raise 'the deliberate absence is not recorded' unless
    sec['extracted_on'].include?('110V') && sec['extracted_on'].include?('p.539')
  raise 'a luminous shelf leaked in' if Registry.catalog.any? { |c| c['description'].to_s =~ /luminous/i }
end

puts "\nthe properties panel: what an object can be ASKED"

check('A SHELF IS NOT OFFERED A HANDLE, and a cabinet still is') do
  # Andriy, 2026-08-27, looking at the dialog on a shelf: "доступные опции ручки
  # не нужны по определению." The Opening fieldset was unconditional, so every
  # object got a handle and a push-to-open - including the things with no front.
  #
  # Asked of the FRONT LAYOUT rather than the class, because `kind: none` is
  # already stated on exactly those things, and stated for a different reason:
  # so that nothing defaults a door onto them. One fact, two readers.
  raise 'a shelf' if Panel.opens?(Registry.lookup('MNS040038'))
  raise 'a sheet' if Panel.opens?(Registry.lookup('DZAK22'))
  raise 'an end panel' if Panel.opens?(Registry.lookup('YU0028'))
  raise 'a cabinet must still open' unless Panel.opens?(Registry.lookup('B80601'))
  raise 'and a tall unit' unless Panel.opens?(Registry.lookup('C92640'))

  # and the patch takes none of the door machinery for something that cannot open
  shelf = Registry.with_ordered_width(Registry.lookup('MNS040038'), 847)
  patch = Panel.attributes_patch(shelf, {})
  raise patch.inspect unless patch.keys == ['variants']
end

check('THE LIGHT IS A CHOICE ON THE OBJECT, and it carries the arithmetic') do
  shelf = Registry.with_ordered_width(Registry.lookup('MNS040038'), 847)
  attrs = Generator.attributes_for(shelf)
  offer = Panel.led_offer(shelf, attrs)
  raise 'no offer' unless offer
  # printed p.224: length of light = length of the shelf minus 3 mm
  raise offer['length_mm'].inspect unless offer['length_mm'] == 844
  raise offer['depth_mm'].inspect unless offer['depth_mm'] == 18
  raise offer['lamp'].inspect unless offer['lamp'] == 'Sky-B'

  on = Panel.attributes_patch(shelf, 'led' => true, 'attrs' => attrs)
  v = on['variants'].find { |x| x['key'] == 'led' }
  raise on.inspect unless v
  raise 'the length must be on the object' unless v['value'].include?('844')
  raise 'and the page that says so' unless v['source_ref'].include?('p.224')
  # A VARIANT AND NOT A COMPANION LINE: the lamp is priced in a book we do not
  # hold, a line must carry a code, and inventing one is domain rule 1's whole
  # subject. The object says the choice; the order gets its line when p.526 is
  # extracted, and the variant says that in as many words.
  raise 'it must name the book it is not priced in' unless v['value'].include?('p.528')
  raise 'and carry the temperature onto the object' unless v['value'].include?('3000/4000')
  # v2.3: the short form, for a symbol that has room for three words.
  raise 'a variant that gets drawn needs a label' unless v['label']
  raise 'and the label must be shorter than the sentence' unless
    v['label'].length < v['value'].length
  raise 'a variant may not carry what it costs' if v.key?('points')
  Contract.validate!(attrs.merge(on))

  off = Panel.attributes_patch(shelf, 'led' => false, 'attrs' => attrs.merge(on))
  raise off.inspect unless off['variants'].none? { |x| x['key'] == 'led' }

  # a cabinet is offered nothing of the sort
  raise 'a cabinet has no led rule' if Panel.led_offer(Registry.lookup('B80601'), {})
end

check('THE TEMPERATURE IS A SETTING, NOT A CODE - and silence is the defect') do
  # Andriy: "Должна быть опция выбора температуры цвета. Смотри в каталогах."
  # I had told him there was nothing to choose. Looking again, in all five books:
  # THERE IS NOT ONE LAMP SOLD AT A FIXED TEMPERATURE ANYWHERE. Every stated
  # temperature is a range the Emotion Dual Color device adjusts. So he is right
  # that there is a choice and I was right that it is not an article - it is a
  # COMMISSIONING INSTRUCTION, and the way it goes wrong is that nobody states
  # it and the device is left wherever it powers up. That is exactly the failure
  # he has been burned by, and it is the unset case, not a wrong case.
  shelf = Registry.lookup('MNS040038')
  attrs = { 'width_mm' => 847 }
  offer = Panel.led_offer(shelf, attrs)
  raise 'the page must offer the temperatures' unless
    offer['temperature_options'] == %w[3000 4000]

  # CHOSEN: the object says SET TO, and says it is not a different article.
  on = Panel.attributes_patch(shelf, 'led' => true, 'attrs' => attrs,
                                     'led_temperature' => '3000')
  v = on['variants'].find { |x| x['key'] == 'led' }
  raise v.inspect unless v['value'].include?('SET TO 3000K')
  raise 'and must say it is not a code' unless v['value'].include?('not a code')
  raise 'the elevation carries the chosen one' unless v['label'] == 'LED 3000K'

  # UNSET: the object says so, out loud, rather than staying quiet.
  none = Panel.attributes_patch(shelf, 'led' => true, 'attrs' => attrs)
  nv = none['variants'].find { |x| x['key'] == 'led' }
  raise nv.inspect unless nv['value'].include?('NOT SPECIFIED')
  raise 'and must say what happens then' unless nv['value'].include?('powers up')
  raise 'the label falls back to the range' unless nv['label'] == 'LED 3000/4000K'

  # ONLY WHAT THE PAGE OFFERS. Checked in Ruby and not only in the dialog, for
  # the reason gola_available? is: a rule that lives only in HTML is not a rule.
  begin
    Panel.attributes_patch(shelf, 'led' => true, 'attrs' => attrs,
                                  'led_temperature' => '2700')
    raise 'a temperature this lamp does not offer must be refused'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('2700K is not a temperature')
    raise 'and the refusal must name the page' unless e.message.include?('p.528')
  end

  # IT SURVIVES A ROUND TRIP, and it is read from the INSTRUCTION rather than
  # from the label - the label is allowed to say 'LED 3000/4000K' when nothing
  # was chosen, and a naive match on that reads 4000 as a decision nobody took.
  # The first version did exactly that and this check caught it.
  raise 'it must read back off the object' unless
    Panel.led_temperature_of('variants' => [v]) == '3000'
  raise 'and answer nothing when nothing was set' unless
    Panel.led_temperature_of('variants' => [nv]).nil?
  raise 'the range in a label is not a decision' unless
    Panel.led_temperature_of('variants' => [{ 'key' => 'led', 'label' => 'LED 3000/4000K',
                                              'value' => 'no instruction here' }]).nil?

  # THE REGISTRY MUST SAY WHY THIS IS NOT AN ARTICLE, or the next person to read
  # it will add a second code for 4000K.
  rule = JSON.parse(File.read(File.expand_path(
    '../registry/cesar/shelves_linear_elements.json', __dir__)))['data']['led_rule']
  why = rule['colour_temperature_is_a_setting_not_a_code'].to_s
  raise 'the reason must be recorded' unless why.include?('not one')
  raise 'and the sweep that established it' unless why.include?('all five volumes')
end

check('the light guard is VACUOUS TODAY, and that is recorded rather than hidden') do
  # learned rule 18, taken early: the shelf's own max.L is 3000 and the light
  # stops at 3000, so a light of length-minus-3 can never exceed it. The guard is
  # correct and unreachable. Pinning the fact means the day the two limits stop
  # agreeing - they come from different sentences on different pages - somebody
  # sees it here instead of discovering the refusal for the first time in a
  # dialog.
  longest = Registry.with_ordered_width(Registry.lookup('MNS040038'), 3000)
  offer = Panel.led_offer(longest, Generator.attributes_for(longest))
  raise offer.inspect unless offer['length_mm'] == 2997
  raise 'the guard has become reachable - re-read this check' if offer['over_max']
  raise 'the shelf limit must be the stricter one' unless
    Registry.lookup('MNS040038')['max_length_mm'] <= offer['max_mm']
end

check('APPLY MUST NOT REACH FOR render(st) - the button dies silently if it does') do
  # THE DEFECT THIS EXISTS FOR, and it was live for one commit: the led work
  # added `attrs:st.attrs` inside apply(). `st` is render's PARAMETER and there
  # is no global by that name, so apply() threw a ReferenceError - and an
  # exception in an HtmlDialog callback is invisible. The button did nothing, on
  # every unit in the model, not only on a shelf. Andriy found it by ticking a
  # box and coming back to an untouched object.
  #
  # A SOURCE CHECK, because nothing headless runs this JavaScript - the same
  # reason the picker's Build-button check is one.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/80_panel.rb', __dir__))
  body = src[/function apply\(\)\{(.+?)\n            \}/m, 1]
  raise 'apply() is gone or renamed' unless body

  bare = body.scan(/(?<![\w.])st\./)
  raise "apply() reaches for render's parameter #{bare.length} time(s)" unless bare.empty?
  raise 'apply() must read the state through STATE' unless body.include?('STATE')
  # and render must actually put it there, or STATE is null and the patch is empty
  rend = src[/function render\(st\)\{(.+?)\n            \}/m, 1]
  raise 'render() is gone or renamed' unless rend
  raise 'render() does not publish the state' unless rend.include?('STATE=st;')
end

check('A CHOSEN LIGHT IS DRAWN, and it goes off with the elevation symbols') do
  # A SOURCE CHECK - Symbols needs SketchUp and nothing here can run it, the same
  # reason the picker and panel checks are source checks.
  #
  # WHY IT MATTERS: the led is a VARIANT, and the article is priced in a book
  # this registry does not hold, so there is no order line it could show up in.
  # A choice that appears nowhere on the sheet is a choice nobody checks. Andriy
  # asked for it in the same terms as the door swing - a dashed mark, same tag,
  # same button - and the tag is what makes the button work.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/70_symbols.rb', __dir__))
  body = src[/def draw_led\(.+?\n      end\n/m]
  raise 'draw_led is gone or renamed' unless body

  raise 'the light must be drawn from the VARIANT, not from a class' unless
    body.include?('led_variant(unit)')
  raise 'nothing is drawn without the choice' unless body =~ /return unless led_variant/
  # THE BUTTON IS THE POINT, AND THE TAG IS NOT. It rode TAG_FRONT until Andriy
  # asked for solid lines - and a line style belongs to the tag, so a solid mark
  # cannot live on the dashed one. It has its own tag now, and show_mode switches
  # that tag with TAG_FRONT rather than on a control of its own. Both halves are
  # checked, because either alone would let the button and the mark drift apart.
  raise 'the led must ride its own tag' unless body.include?('led_tag')
  mode = src[/def show_mode\(model, mode\).+?\n      end\n/m]
  raise 'show_mode is gone' unless mode
  raise 'the led tag must exist' unless src.include?("TAG_LED   = 'UCON")
  raise 'and be solid, which is why it is not on the front tag' unless
    mode.include?('tag(model, TAG_LED, dashed: false)')
  raise 'and go on and off with the elevation symbols' unless
    mode.include?('led.visible   = front.visible')
  raise 'and be a real named group, or clear() will not remove it' unless
    body.include?("g.name = 'SYM_LED'")

  # and it is called before any branch of draw() can return without it - the
  # mistake glass and the open leaf were both moved up to avoid.
  drawm = src[/def draw\(model, definition, unit, hinge_side.+?\n      end\n/m]
  raise 'draw() is gone' unless drawm
  led = drawm.index('draw_led(')
  raise 'draw() never draws the led' unless led
  kinds = drawm.index("if kind == 'horizontal'")
  raise 'the led is drawn after a branch that can return' unless kinds && led < kinds

  # the length is the page's: the shelf less 3, so 1,5 inset at each end
  raise 'the inset must come from the page' unless
    src =~ /LED_END_INSET_MM\s+= 1\.5/
end

check('A SHELF GOES ON THE WALL, NOT BESIDE') do
  # THE BUG, in Andriy's words: the label was going into the wall. A shelf built
  # off an island unit inherited the island's facing, was dragged to the north
  # wall where everything faces the other way, and ended up back-to-front. Read
  # out of the model rather than reasoned about: 50 objects, the north run at
  # yaw -180, the island at 0, and the shelf on the north wall at 0.
  #
  # TWO FIXES WENT IN AND ONLY THIS ONE SURVIVED. The other was three
  # quarter-turn buttons in the panel, removed the next morning: a wall at 37
  # degrees is not served by 90/180/270, SketchUp's own rotate tool serves every
  # angle, and a control that handles the easy quarter of the cases while
  # silently failing the rest is worse than none because it looks like the
  # answer. What remains is the half that made facing right by CONSTRUCTION.
  #
  # A SOURCE CHECK, because placement_transform needs a live selection and
  # nothing headless has one; the arithmetic is one line and is stated here so a
  # later edit cannot quietly invert it.
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  body = src[/def placement_transform.+?\n      end\n/m]
  raise 'placement_transform is gone' unless body

  raise 'a shelf must be recognised before the run logic' unless
    body.include?("new_unit['object_class'].to_s == 'shelf'")
  shelf = body.index("== 'shelf'")
  side  = body.index('side = placement_side(')
  raise 'the wall rule must come before the run rule' unless shelf && side && shelf < side
  raise 'the shelf seats by depth difference' unless
    body.include?("y = back - (new_unit['depth_mm'] || 0).to_f")
  raise 'no depth, no wall, no guess' unless
    body.include?('there is no wall behind it to')

  # AND THE BUTTONS ARE GONE. Checked, because a half-removed control is worse
  # than either state: the callback without the buttons is dead code, and the
  # buttons without the callback are a button that does nothing.
  pan = File.read(File.expand_path('../src/ucon_cabinet_engine/core/80_panel.rb', __dir__))
  raise 'the turn callback must be gone' if pan.include?("add_action_callback('turn')")
  raise 'and the buttons with it' if pan.include?('sketchup.turn')
  raise 'and the facing readout it fed' if pan.include?('faceNote')
  # The reason is recorded rather than the code just vanishing (learned rule 9).
  raise 'why it went must be written down' unless
    pan.include?('THE TURN BUTTONS ARE GONE')
end

check('A HAND COPY IS ONE OBJECT UNTIL SOMEBODY EDITS IT') do
  # Andriy copied a shelf in SketchUp, took the light off one, and it came off
  # the other. Copy a component and you get a second INSTANCE of one DEFINITION,
  # and every fact this engine keeps - code, mounting, hinge, variants - lives on
  # the definition. So Apply on either copy rewrote both.
  #
  # SketchUp is not wrong to share. This engine is wrong to let it: a unit here
  # is an ORDER LINE, and two lines that cannot differ in hinge side, mounting or
  # light are not two lines.
  #
  # A SOURCE CHECK, because it needs a live model and nothing headless has one.
  pan = File.read(File.expand_path('../src/ucon_cabinet_engine/core/80_panel.rb', __dir__))
  body = pan[/def apply\(payload\).+?\n      end\n/m]
  raise 'apply is gone' unless body
  raise 'apply must split a shared definition' unless body.include?('make_instance_unique!(inst)')

  # ORDER MATTERS TWICE OVER and both are easy to undo by accident:
  # the split must happen INSIDE the operation, so one undo puts it back...
  op    = body.index('start_operation')
  split = body.index('make_instance_unique!(inst)')
  write = body.index('Contract.write!')
  raise 'the split must be inside the undoable operation' unless op && split && op < split
  # ...and BEFORE the definition is read, because make_unique replaces the
  # definition the instance points at. Reading it earlier writes to the one
  # still being shared - which is the original bug wearing a fix.
  dref = body.index('defn = inst.definition')
  raise 'defn must be read AFTER the split' unless dref && split < dref && dref < write
  raise 'and not before apply even starts' if
    pan[/def apply\(payload\).+?start_operation/m].include?('defn  = inst.definition')

  helper = pan[/def make_instance_unique!\(inst\).+?\n      end\n/m]
  raise 'the helper is gone' unless helper
  raise 'it must be a no-op when the instance is already alone' unless
    helper.include?('count_instances <= 1')
  raise 'and rename in this engine\'s convention, not SketchUp\'s #1' unless
    helper.include?("Time.now.strftime('%Y%m%d_%H%M%S')")

  # THE GENERATOR ALREADY KNEW THIS and the panel did not inherit it. Named here
  # so the two cannot drift apart again.
  gen = File.read(File.expand_path('../src/ucon_cabinet_engine/core/60_generator.rb', __dir__))
  raise 'swap_corner_execution! must still guard the same way' unless
    gen.include?('instance.make_unique if instance.definition.count_instances > 1')

  # AND THE ORDER WAS NEVER WRONG - collect walks INSTANCES, so two instances
  # sharing a definition already produced two rows. Pinned, because "the copy is
  # missing from the schedule" would have been the far worse version of this bug
  # and the reason it is not true is one line in 86_export_run.
  run = File.read(File.expand_path('../src/ucon_cabinet_engine/core/86_export_run.rb', __dir__))
  col = run[/def collect\(entities, out, depth = 0\).+?\n      end\n/m]
  raise 'collect is gone' unless col
  raise 'the order must count instances, not definitions' unless
    col.include?('ComponentInstance') && col.include?('out << attrs')
end

check('CONTRACT v2.3 - a variant may say the same thing shorter, for a drawing') do
  base = VALID.merge('code' => 'MNS040038')
  ok = Contract.validate!(base.merge('variants' => [
        { 'key' => 'led', 'value' => 'Sky-B 397 mm - the shelf less 3, 3000/4000K',
          'label' => 'LED 3000/4000K', 'source_ref' => 'printed p.224' }
      ]))
  raise 'label must survive validation' unless
    ok['variants'][0]['label'] == 'LED 3000/4000K'
  # Optional, so nothing written before v2.3 becomes invalid.
  Contract.validate!(base.merge('variants' => [{ 'key' => 'f', 'value' => 'steel' }]))
  # And still no commercial data - a short form is not a loophole.
  begin
    Contract.validate!(base.merge('variants' => [
      { 'key' => 'led', 'value' => 'x', 'label' => 'y', 'points' => 96 }
    ]))
    raise 'a price on a variant must still be refused'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('commercial')
  end
  # The manifest states the revision the registry was written under.
  man = JSON.parse(File.read(File.expand_path('../registry/cesar/_manifest.json', __dir__)))
  raise man['contract_revision'].inspect unless man['contract_revision'] == '2.3'
  doc = File.read(File.expand_path('../docs/UCON_Object_Contract_v2.md', __dir__))
  raise 'the change log must carry v2.3' unless doc.include?('**v2.3 (2026-08-27)**')
end

check('CONTRACT v2.4 - a void may be a wall reservation, and the datum is why') do
  base = { 'schema_version' => '2', 'object_class' => 'void', 'manufacturer' => 'client',
           'geometry_kind' => 'linear', 'code_status' => 'PRELIMINARY', 'status' => 'PLANNING',
           'width_mm' => 1219, 'depth_mm' => 610, 'height_mm' => 457,
           'source_ref' => 'wolf-design-guide.pdf rev 7/2025 p.141' }

  # The fourth role validates, and a hood is wall-hung, which the contract
  # already had the words for: mount_bottom_mm is required with it and
  # forbidden without it, and nothing about that changed.
  Contract.validate!(base.merge('void_role' => 'wall_reservation',
                                'mounting' => 'wall_hung', 'mount_bottom_mm' => 1720))

  # The three older roles are untouched - widening an enum invalidates nothing.
  %w[above_housing run_gap front_remainder].each do |role|
    Contract.validate!(base.merge('void_role' => role))
  end

  # And an invented fourth word is still refused.
  begin
    Contract.validate!(base.merge('void_role' => 'hood'))
    raise 'an unknown void_role was accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('void_role')
  end

  doc = File.read(File.expand_path('../docs/UCON_Object_Contract_v2.md', __dir__))
  raise 'the change log must carry v2.4' unless doc.include?('**v2.4 (2026-08-28)**')
  raise 'the header must name the current revision' unless doc.include?('revision v2.4')
  # v2.2 had to record that `void` was in the code and not in the table; v2.4
  # records the same for `void_role` itself, and the row is now there.
  raise 'void_role must now be IN the table' unless doc.include?('| `void_role` |')

  # THE MANIFEST DELIBERATELY STILL READS 2.3, and this is the check that stops
  # a later session "fixing" it. contract_revision states the revision THE
  # REGISTRY was written under. v2.2 added an object_class the registry uses and
  # v2.3 a variant key it uses; v2.4 adds a void_role that is produced while
  # DRAWING and appears in no registry row, so the registry was not touched and
  # must not claim it was.
  man = JSON.parse(File.read(File.expand_path('../registry/cesar/_manifest.json', __dir__)))
  raise man['contract_revision'].inspect unless man['contract_revision'] == '2.3'
  raise 'no registry row may carry the new role' if
    Dir[File.expand_path('../registry/cesar/*.json', __dir__)]
      .any? { |f| File.read(f).include?('wall_reservation') }
end

check('the probe bridge stays a DEV TOOL: nothing in src/ requires it') do
  # The bridge's own first lines promise this - "nothing in src/ requires it, it
  # carries no version, and it never goes into an .rbz" - and a button is exactly
  # the convenience that quietly breaks such a promise. A `require` at the top of
  # a palette file would make the engine refuse to load wherever tools/ is absent.
  offenders = Dir[File.expand_path('../src/**/*.rb', __dir__)].select do |f|
    src = File.read(f)
    src.match?(/^\s*require(_relative)?\s+.*probe_bridge/)
  end
  raise "src/ requires the bridge: #{offenders.inspect}" unless offenders.empty?

  # And it is only ever NAMED behind a defined? guard, so a missing bridge is a
  # state and not a NameError.
  Dir[File.expand_path('../src/**/*.rb', __dir__)].each do |f|
    src = File.read(f)
    next unless src.include?('ProbeBridge')

    body = src.gsub(/^\s*#.*$/, '')
    next unless body.include?('ProbeBridge')
    raise "#{File.basename(f)} names ProbeBridge without a defined? guard" unless
      body.include?('defined?(::UCON::ProbeBridge)')
  end
end

check('the dev bridge door answers without loading anything') do
  D = UCON::CabinetEngine::DevBridge
  # It points at the repository's own tools/, derived from where core actually is.
  raise D.path unless D.path.end_with?('tools/probe_bridge.rb')
  raise 'this IS a dev checkout, so it must be available' unless D.available?
  raise D.path unless File.file?(D.path)

  # RUNNING? IS ABOUT A TIMER, NOT A CONSTANT. Headless there is no ProbeBridge
  # at all, and the honest answer is false rather than an exception - which is
  # also the answer after every Reload core, when the constant still exists and
  # the timer does not.
  raise 'nothing is running headless' if D.running?
  raise D.status_line unless D.status_line.include?('OFF')
end

check('the bridge button never arms, and is drawn only in a dev checkout') do
  # arm! makes the next probe COMMIT instead of roll back. That is typed out in
  # full, every time, with the model in front of you - a one-click arm is how a
  # probe applies to a kitchen nobody meant to change.
  dev  = File.read(File.expand_path('../src/ucon_cabinet_engine/core/95_dev_bridge.rb', __dir__))
  pal  = File.read(File.expand_path('../src/ucon_cabinet_engine/core/90_palette.rb', __dir__))
  main = File.read(File.expand_path('../src/ucon_cabinet_engine/main.rb', __dir__))
  [dev, pal, main].each do |src|
    body = src.gsub(/^\s*#.*$/, '')
    raise 'something offers a one-click arm' if body.include?('arm!')
  end

  raise 'the palette must have a reload_bridge callback' unless
    pal.include?("add_action_callback('reload_bridge')")
  raise 'the palette button must be conditional on there being a bridge' unless
    pal.include?('DevBridge.available? ?')
  # AND THE MENU MUST NOT HAVE GROWN ONE. The item was tried and taken back
  # out: a SketchUp menu item is permanent for the session, which is what the
  # 'entry point, not a control panel' guard exists to protect.
  raise 'the menu grew a dev item' if main.include?("menu.add_item('Reload probe bridge")
  # It reports the TIMER afterwards, not the return value of load.
  # Learned rule 13: a record of an outside action is only true if something checks it.
  raise 'the result must be read back from the bridge' unless
    pal.include?('DevBridge.status_line')
end

check('the light is drawn to be SEEN, and the first one was 5 pixels tall') do
  # It was in the model, on a visible tag, unhidden, gray, correct to the
  # millimetre - and invisible. A probe found it before a person could: on the
  # north-wall elevation 874 mm of shelf spanned about 350 px, so the spine sat
  # 0,4 px below the board's own bottom edge and the ticks were 5 px long.
  # Being right is not the same as being legible, and the suite now says so.
  #
  # The scale is the drawing's, not the screen's - a symbol is sized in model
  # units so it survives being plotted - but the ratios below are what stop it
  # collapsing back onto the edge it hangs from.
  raise 'the spine must clear the board it hangs under' unless
    Symbols::LED_GAP_MM >= 5
  raise 'and the cone must be deep enough to hold its own label' unless
    Symbols::LED_BEAM_DROP_MM >= Symbols::LED_LABEL_MM
  raise 'the cone must outrun the gap it starts from' unless
    Symbols::LED_BEAM_DROP_MM > Symbols::LED_GAP_MM

  # AND THE CONE STAYS INSIDE THE BOARD. It was the REAL 96 degree beam for one
  # version - true to printed p.528, overhanging 67 mm at each end - and it flew
  # into the wall the first time a shelf was hung against one. A true 96 degree
  # cone cannot be drawn inside the board at any depth, which is what a wide
  # beam means, so the mark stopped claiming to be the beam. The rule that
  # replaced it is general: A SYMBOL NEVER LEAVES ITS OBJECT'S FOOTPRINT.
  feet = Symbols.led_cone_feet_mm(874)
  raise 'a normal board gets a cone' unless feet
  raise 'and its foot is inside the board' unless feet[0] >= 0 && feet[1] <= 874
  raise 'stopping short of each end' unless
    feet[0] == Symbols::LED_BEAM_INSET_MM && feet[1] == 874 - Symbols::LED_BEAM_INSET_MM
  raise 'the clearance is the 25 mm Andriy asked for' unless
    Symbols::LED_BEAM_INSET_MM == 25
  # The widest shelf the page allows, and the narrowest thing that can hold a
  # cone at all - both inside, or the rule is not a rule.
  [400, 1200, 3000].each do |w|
    f = Symbols.led_cone_feet_mm(w)
    raise "cone escapes at #{w}" unless f && f[0] >= 0 && f[1] <= w
  end
  # Too short to say anything: the lamp line alone, rather than a cone folded
  # inside out.
  raise 'a 60 mm board cannot hold a cone' unless Symbols.led_cone_feet_mm(60).nil?
  sym = File.read(File.expand_path('../src/ucon_cabinet_engine/core/70_symbols.rb', __dir__))
  raise 'and the drawing must ask before drawing one' unless
    sym[/def draw_led\(.+?\n      end\n/m].include?('if feet && top')

  # AND IT POINTS DOWNWARD. The first version that stayed inside the board was
  # wide at the TOP - a funnel, not light. Andriy: "широкая внизу и усеченная
  # вверху." The two constraints hold together: the WIDE edge is the foot, and
  # the foot is what is capped 25 mm short of each end.
  [400, 874, 1200, 3000].each do |w|
    f = Symbols.led_cone_feet_mm(w)
    t = Symbols.led_cone_top_mm(w)
    raise "no cone at #{w}" unless f && t
    raise "the foot escapes the board at #{w}" unless f[0] >= 0 && f[1] <= w
    raise "the top is not narrower than the foot at #{w}" unless
      (t[1] - t[0]) < (f[1] - f[0])
    raise "the top is not inside the foot at #{w}" unless t[0] > f[0] && t[1] < f[1]
    raise "the splay is not the one declared at #{w}" unless
      (t[0] - f[0] - Symbols::LED_BEAM_SPLAY_MM).abs < 0.001
  end
  # Rather than draw one inside out, refuse. That is the mistake this shape was
  # correcting, and it must not come back through the short-board door.
  raise 'a board too narrow for a splay must get no cone' unless
    Symbols.led_cone_top_mm(100).nil?

  # THE LABEL IS MEANT TO BE ALMOST INVISIBLE. Unfilled glyphs - the thinnest a
  # letter is drawn - in a grey lighter than every other symbol in the file.
  lab = sym[/def draw_led_label\(.+?\n      end\n/m]
  raise 'draw_led_label is gone' unless lab
  raise 'the label must be OUTLINES, not filled glyphs' unless
    lab =~ /add_3d_text\([^)]*false,\s*0\.0\)/m
  raise 'and it must be paler than the other symbols' unless
    Symbols::LED_LABEL_RGB.first > Symbols::SYMBOL_RGB.first
  raise 'it gets its own material, not the symbol grey' unless
    lab.include?('label_material(definition)')

  # THE WORDS. A label wider than the lamp is worse than no label, and the
  # temperature is on it because that is the fact that arrives wrong.
  raise 'the label comes from the variant' unless
    Symbols.led_label('variants' => [{ 'key' => 'led', 'label' => 'LED 3000/4000K' }]) ==
    'LED 3000/4000K'
  raise 'and falls back rather than drawing nothing' unless
    Symbols.led_label('variants' => [{ 'key' => 'led', 'value' => 'x' }]) == 'LED'
  raise 'no light, no label' unless Symbols.led_label('variants' => []).nil?
  raise 'a long label must not overrun a short shelf' unless
    !Symbols.led_label_fits?('LED 3000/4000K', 200)
  raise 'and must fit a long one' unless
    Symbols.led_label_fits?('LED 3000/4000K', 1200)
  raise 'the bare word fits where the sentence does not' unless
    Symbols.led_label_fits?('LED', 200)
end

puts "\n#{$checks} checks, #{$failures} failure(s)\n\n"
exit($failures.zero? ? 0 : 1)

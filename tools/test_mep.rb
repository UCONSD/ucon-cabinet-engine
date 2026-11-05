# tools/test_mep.rb - MEP points of 7612 (tools/mep) against the issued v0.2 schedule.
#
#   /usr/bin/ruby tools/test_mep.rb
#
# Every v0.2 point must come back at the same horizontal distance from its reference and the same height (mm, +-1),
# except the changes listed in fixtures/v0_2_points.json (each must really differ, and nothing else may).
require 'json'
require_relative 'mep/mep_points'

MEP = UCON::MEP
FIX = File.join(__dir__, 'mep', 'fixtures')
$checks = 0
$fails = []
def check(what, ok, detail = '')
  $checks += 1
  $fails << "#{what} #{detail}" unless ok
end

boxes = MEP.load_json(File.join(FIX, '7612_kitchen_v0_4_1_boxes.json'))['boxes']
project = MEP.load_json(File.join(__dir__, 'mep', 'projects', '7612_kitchen.json'))
ref = MEP.load_json(File.join(FIX, 'v0_2_points.json'))
pts = MEP.points(boxes, project)
by = pts.map { |p| [p['id'], p] }.to_h
changes = ref['expected_changes']

ref['points'].each do |id, (h, z)|
  p = by[id]
  check("#{id} present", !p.nil?)
  next unless p
  same = (p['horiz_mm'] - h).abs <= 1 && (p['z'] - z).abs <= 1
  if changes.key?(id)
    check("#{id} must CHANGE (#{changes[id]})", !same, "got #{p['horiz_mm']} / #{p['z']}")
  else
    check("#{id} = v0.2", same, "got #{p['horiz_mm']} / #{p['z']}, v0.2 #{h} / #{z}")
  end
end
ref['schedule_only'].each { |id| check("#{id} schedule-only point present", by.key?(id) && by[id]['x'].nil?) }
check('E4 is the gas cooktop, 120 V', by['E4']['req'].include?('120 V') && by['E4']['item'].include?('SGSXP365TS'))
check('G1 is new', by.key?('G1') && !ref['points'].key?('G1'))
extra = by.keys - ref['points'].keys - ref['schedule_only'] - %w[G1 P6 E16 S1]
check('no other new points', extra.empty?, extra.inspect)
check('E3 carries the 90 deg door stop note', by['E3']['note'].to_s.include?('door stop pins'))
check('every positioned point has a status and a source', pts.all? { |p| %w[SOURCE PLANNING DECISION].include?(p['status']) && !p['src'].to_s.empty? })

check('E9 label', by['E9']['short'] == 'GFCI 120V 20A', by['E9']['short'].inspect)
check('E1 label', by['E1']['short'] == 'J-BOX 208/240V 50A', by['E1']['short'].inspect)
check('E6 label says hardwired', by['E6']['short'] == 'J-BOX 120V 15A HW', by['E6']['short'].inspect)
check('E4 label', by['E4']['short'] == 'REC 120V 15A', by['E4']['short'].inspect)
la = MEP.points([{ 'code' => 'BL0603', 'x0' => 22.0, 'x1' => 622.0, 'y0' => -645.0, 'y1' => 0.0, 'z0' => 0.0, 'z1' => 900.0 }],
                MEP.load_json(File.join(__dir__, 'mep', 'projects', '7612_laundry.json'))).map { |p| [p['id'], p] }.to_h
check('dryer receptacle label', la['E602']['short'] == 'REC 240V 30A 14-30R', la['E602']['short'].inspect)
kb = MEP.blocking(boxes, along: 'x', face: 'y1', wall_at: -483)
check('kitchen blocking: two zones along the backs of the PF0631 over the sink wall at CL 2375 (no fillers / end panels)', kb.map { |b| [b['a0'], b['a1'], b['cl']] } == [[2002, 3652, 2375], [4552, 6202, 2375]], kb.map { |b| [b['a0'], b['a1'], b['cl']] }.inspect)
side = [{ 'code' => 'SD0631', 'cls' => 'cabinet', 'x0' => 1262, 'x1' => 1907, 'y0' => -628, 'y1' => -28, 'z0' => 2440, 'z1' => 3040, 'back' => 'x+' },
        { 'code' => 'PD0151', 'cls' => 'filler', 'x0' => 1262, 'x1' => 1637, 'y0' => -28, 'y1' => -1, 'z0' => 2440, 'z1' => 3040, 'back' => 'x+' }]
check('no blocking on a wall that only a filler and a side-on cabinet touch (pantry C)', MEP.blocking(side, along: 'x', face: 'y1', wall_at: 0).empty?)
check('blocking where the back IS on the wall', MEP.blocking([side[0].merge('back' => 'y+')], along: 'x', face: 'y1', wall_at: 0).size == 1)
z = MEP.plumbing_zones(pts).find { |q| q['ids'].include?('P1') }
check('sink plumbing zone takes the ice maker box: 3775..4350 x 300..600', z && [z['x0'], z['x1'], z['z0'], z['z1']] == [3775, 4350, 300, 600], z.inspect)
check('P6 ice maker box in the sink group, left of the zone stubs', by['P6'] && by['P6']['group'] == by['P1']['group'] && (by['P6']['x'] - 3852).abs < 1 && by['P6']['short'] == 'ICE MAKER BOX 1/4"', by['P6'] && by['P6']['short'].inspect)
check('W1 in the freezer niche (CH4640 y -2448..-1838), from P6, no valve there', by['W1']['y'].between?(-2448, -1838) && by['W1']['req'].include?('NO valve'), by['W1']['y'].inspect)
check('E16 switched LED receptacle in the sink base', (by['E16']['x'] - 3652).abs < 1 && by['E16']['req'].include?('SWITCHED by S1'))
check('L1 / L2 are low voltage now', %w[L1 L2].all? { |i| by[i]['short'] == 'LV CABLE CL2' && !by[i]['req'].include?('Switched 120 V') })
check('S1 switch label and horizontal from the window wall', by['S1']['short'] == 'SWITCH 120V 15A' && by['S1']['horiz_mm'] == 510, [by['S1']['short'], by['S1']['horiz_mm']].inspect)
check('the oven column takes no water: no point of the MEDMC301WS but E1', pts.select { |p| p['anchor'] == 'CK7744' }.map { |p| p['id'] } == ['E1'])
check('tails: 10 ft at E1 E2 E3, 5 ft at E4 E5 E13, none elsewhere', pts.select { |p| p['tail_ft'] }.map { |p| [p['id'], p['tail_ft']] }.sort == [['E1', 10], ['E13', 5], ['E2', 10], ['E3', 10], ['E4', 5], ['E5', 5]], pts.select { |p| p['tail_ft'] }.map { |p| [p['id'], p['tail_ft']] }.inspect)
check('tail written into the requirement', by['E1']['req'].include?('10 ft electrical tail') && by['E4']['req'].include?('5 ft electrical tail'))
check('labels unchanged by the tail', by['E1']['short'] == 'J-BOX 208/240V 50A' && by['E4']['short'] == 'REC 120V 15A')
# core 1.9.31 (2026-10-16): sinks are engine objects - the plumbing follows the sink, the receptacle stays on the cabinet
lproj = MEP.load_json(File.join(__dir__, 'mep', 'projects', '7612_laundry.json'))
lbox = { 'code' => 'BL0603', 'x0' => 22.0, 'x1' => 622.0, 'y0' => -645.0, 'y1' => 0.0, 'z0' => 0.0, 'z1' => 900.0 }
mark = { 'code' => 'SINK-MARK', 'cls' => 'sink', 'x0' => 72.0, 'x1' => 472.0, 'y0' => -500.0, 'y1' => -100.0, 'z0' => 900.0, 'z1' => 901.0 }
l0 = MEP.points([lbox], lproj).map { |p| [p['id'], p] }.to_h
l1 = MEP.points([lbox, mark], lproj).map { |p| [p['id'], p] }.to_h
dr0 = l0.values.find { |p| p['sym'] == 'DR' && p['x'] }
dr1 = l1.values.find { |p| p['sym'] == 'DR' && p['x'] }
check('1.9.31: the laundry drain follows a sink mark off the cabinet centre (322 -> 272)', dr0 && dr1 && (dr0['x'] - 322).abs < 1 && (dr1['x'] - 272).abs < 1, [dr0 && dr0['x'], dr1 && dr1['x']].inspect)
e0 = l0.values.select { |p| p['sys'] == 'E' && p['x'] }.map { |p| [p['id'], p['x']] }
e1 = l1.values.select { |p| p['sys'] == 'E' && p['x'] }.map { |p| [p['id'], p['x']] }
check('1.9.31: electrical points do not move with the sink', e0 == e1, [e0, e1].inspect)
wb = { 'code' => 'LVBP04.003', 'cls' => 'accessory', 'x0' => 250.0, 'x1' => 950.0, 'y0' => -420.0, 'y1' => -140.0, 'z0' => 750.0, 'z1' => 851.0 }
check('1.9.31: an engine washbasin counts as a sink', MEP.sink_box?(wb) && !MEP.sink_box?(wb.merge('code' => 'UCON-MIR-RMU-120x070')))
mir = { 'code' => 'UCON-MIR-RMU-120x070', 'cls' => 'accessory', 'x0' => 0.0, 'x1' => 1200.0, 'y0' => -35.0, 'y1' => 0.0, 'z0' => 1250.0, 'z1' => 1950.0 }
check('1.9.31: a washbasin is never a blocking zone; the mirror still is', MEP.blocking([wb.merge('y1' => 0.0), mir], along: 'x', face: 'y1', wall_at: 0).size == 1)
# 2026-10-26 (1791 ADU, Andriy): runs extend to the next stud (406 each side, 16" o.c.); a wall-hung cabinet may take a
# second row 50 above its bottom edge - a project switch (bottom_row:), off by default so 7612 keeps one row
van = { 'code' => 'VANITY', 'cls' => 'cabinet', 'back' => 'y+', 'x0' => 930, 'x1' => 2186, 'y0' => 1000, 'y1' => 1600, 'z0' => 254, 'z1' => 825 }
b1 = MEP.blocking([van], along: 'x', face: 'y1', wall_at: 1600)
check('blocking default: one row at CL 775, extension 406', b1.map { |b| [b['id'], b['cl'], b['ext']] } == [['B1', 775, 406]], b1.map { |b| [b['id'], b['cl'], b['ext']] }.inspect)
b2 = MEP.blocking([van], along: 'x', face: 'y1', wall_at: 1600, bottom_row: true)
check('bottom_row: B1 top CL 775, B2 bottom CL 304, same run', b2.map { |b| [b['id'], b['cl'], b['a0'], b['a1']] } == [['B1', 775, 930, 2186], ['B2', 304, 930, 2186]], b2.map { |b| [b['id'], b['cl']] }.inspect)
flo = van.merge('z0' => 100, 'z1' => 2300)
check('bottom_row: no bottom row for a floor-standing tall', MEP.blocking([flo], along: 'x', face: 'y1', wall_at: 1600, bottom_row: true).size == 1)
check('item text names the extension', b1[0]['item'].include?('next stud'))
# axis ON the edge (Andriy 2026-11-04, 1791): top row on the top edge, bottom row on the bottom edge
b3 = MEP.blocking([van], along: 'x', face: 'y1', wall_at: 1600, bottom_row: true, below_top: 0, above_bottom: 0)
check('edge axis: B1 CL 825 = top edge, B2 CL 254 = bottom edge', b3.map { |b| [b['id'], b['cl']] } == [['B1', 825], ['B2', 254]], b3.map { |b| [b['id'], b['cl']] }.inspect)
check('edge axis: source names the 2026-11-04 rule', b3.all? { |b| b['src'].include?('2026-11-04') })
# ceiling (Andriy 2026-11-04): a tall run up to the ceiling 2421 - band right under the 1 1/2" (38) top plate
tall = van.merge('z0' => 900, 'z1' => 2421)
b4 = MEP.blocking([tall], along: 'x', face: 'y1', wall_at: 1600, below_top: 0, ceiling: 2421)
check('ceiling: CL = 2421 - 38 - 70 = 2313', b4.map { |b| b['cl'] } == [2313], b4.map { |b| b['cl'] }.inspect)
b5 = MEP.blocking([van], along: 'x', face: 'y1', wall_at: 1600, below_top: 0, ceiling: 2421)
check('ceiling: a vanity far below the ceiling keeps its edge axis 825', b5.map { |b| b['cl'] } == [825], b5.map { |b| b['cl'] }.inspect)
puts "#{$checks} checks, #{$fails.size} failures"
$fails.each { |f| puts "  FAIL #{f}" }
exit($fails.empty? ? 0 : 1)

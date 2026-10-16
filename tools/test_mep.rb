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
extra = by.keys - ref['points'].keys - ref['schedule_only'] - ['G1']
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
check('sink plumbing zone 3875..4350 x 300..600', z && [z['x0'], z['x1'], z['z0'], z['z1']] == [3875, 4350, 300, 600], z.inspect)
check('tails: 10 ft at E1 E2 E3, 5 ft at E4 E5 E13, none elsewhere', pts.select { |p| p['tail_ft'] }.map { |p| [p['id'], p['tail_ft']] }.sort == [['E1', 10], ['E13', 5], ['E2', 10], ['E3', 10], ['E4', 5], ['E5', 5]], pts.select { |p| p['tail_ft'] }.map { |p| [p['id'], p['tail_ft']] }.inspect)
check('tail written into the requirement', by['E1']['req'].include?('10 ft electrical tail') && by['E4']['req'].include?('5 ft electrical tail'))
check('labels unchanged by the tail', by['E1']['short'] == 'J-BOX 208/240V 50A' && by['E4']['short'] == 'REC 120V 15A')
puts "#{$checks} checks, #{$fails.size} failures"
$fails.each { |f| puts "  FAIL #{f}" }
exit($fails.empty? ? 0 : 1)

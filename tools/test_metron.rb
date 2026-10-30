# frozen_string_literal: true
#
# tools/test_metron.rb - core/87_metron.rb (SketchUp -> Metron, stage 2) against the two rooms already in Metron.
#
#   /usr/bin/ruby tools/test_metron.rb            check
#   /usr/bin/ruby tools/test_metron.rb --write    (re)write metron/export/fixtures/*.export.json from the bodies below
#
# The bodies are Bath 3 and Bath 2 AS THE MODEL MUST LOOK after the 2026-10-29 alignment (Andriy: side panels 18 / 22
# run INTO the wall like Metron, not 7 mm strips; and they are 495 deep, flush with the fronts - NOT the 470 of Metron R01,
# so the panels' X is the one deliberate difference from T_00018_v1 / T_00019_v2): room-local mm, measured the way the drawing set measures - the
# carcass, not the instance box. The export they give is the fixture; metron/laptop/gen/test_room_from_skp.py takes
# the fixture to the room JSON and to the .rit, byte for byte against T_00019_v2 / T_00018_v1.
require 'json'
require_relative '../src/ucon_cabinet_engine/core/87_metron'

M = UCON::CabinetEngine::Metron
FIX = File.expand_path('../metron/export/fixtures', __dir__)
$checks = 0
$fails = []
def check(what)
  $checks += 1
  yield
rescue StandardError => e
  $fails << "#{what}: #{e.class}: #{e.message}"
end

def cab(ref, code, x0, x1, z0 = 243, z1 = 828)
  { ref: ref, code: code, object_class: 'cabinet', mounting: 'wall_hung', x0: x0, x1: x1, y0: -495, y1: 0, z0: z0, z1: z1, rot_deg: 0 } # body incl. fronts, as probe 910 measures
end

def panel(ref, code, x0, x1)
  { ref: ref, code: nil, object_class: nil, metron: { 'kind' => 'panel', 'code' => code }, x0: x0, x1: x1, y0: -495, y1: 0, z0: 243, z1: 828, rot_deg: 0 }
end

MIRROR = { code: 'UCON-MIR-RMU-120x070', object_class: 'accessory', mounting: 'wall_hung',
           metron: { 'kind' => 'unit', 'code' => 'SPECCHIERA' }, y0: -36, y1: 0, z0: 1250, z1: 1950, rot_deg: 0 }.freeze

ROOMS = {
  '7612_BA3' => [{ 'room' => '7612-BA3', 'revision' => 'R01', 'estimate' => 'T_00019' }, [
    cab('u1', 'BA60557', 7, 457), cab('u2', 'BA60687', 457, 1057), cab('u3', 'BA60557', 1057, 1507),
    MIRROR.merge(ref: 'm1', x0: 157, x1: 1357),
    panel('p1', 'PAN018', -11, 7), panel('p2', 'PAN018', 1507, 1525),
    { ref: 't1', object_class: nil, metron: { 'kind' => 'top', 'code' => 'TOPDRBA', 'borsx' => 'BOR002', 'bordx' => 'BOR002', 'sink' => 'LVBF05.002' },
      x0: 0, x1: 1514, y0: -500, y1: 0, z0: 708, z1: 850, rot_deg: 0 },
    { ref: 'f1', object_class: nil, metron: nil, x0: 737, x1: 777, y0: -80, y1: -40, z0: 850, z1: 1050 } # faucet: no code, not exported
  ]],
  '7612_BA2' => [{ 'room' => '7612-BA2', 'revision' => 'R01', 'estimate' => 'T_00018' }, [
    cab('u1', 'BA61287', 18, 1218), cab('u2', 'BA60957', 1218, 2118),
    MIRROR.merge(ref: 'm1', x0: 18, x1: 1218),
    panel('p1', 'PAN018', 0, 18), panel('p2', 'PAN022', 2118, 2140),
    { ref: 't1', object_class: nil, metron: { 'kind' => 'top', 'code' => 'TOPDRBA', 'borsx' => 'BOR002', 'bordx' => 'BOR001', 'sink' => 'LVBF05.003' },
      x0: 0, x1: 2140, y0: -500, y1: 0, z0: 708, z1: 850, rot_deg: 0 }
  ]]
}.freeze

ROOMS.each do |name, (room, bodies)|
  out = M.room(bodies, room)
  path = File.join(FIX, "#{name}.export.json")
  if ARGV.include?('--write')
    File.write(path, JSON.pretty_generate(out) + "\n")
    puts "written #{path}"
  end
  check("#{name}: export equals the fixture") { raise 'differs' unless JSON.parse(File.read(path)) == out }
  check("#{name}: no item for a body without code or UCON_METRON") { raise 'faucet exported' if out['items'].any? { |i| i['ref'] == 'f1' } }
  check("#{name}: mirror is not hung") { raise 'hung' if out['items'].find { |i| i['ref'] == 'm1' }.key?('hung') }
end

check('a coded body with no Metron mapping is listed, not dropped') do
  out = M.room([cab('u1', 'BA60557', 7, 457),
                { ref: 'f', code: 'C00151', object_class: 'filler', x0: 0, x1: 72, y0: -645, y1: -557, z0: 0, z1: 2440 },
                { ref: 'm', code: 'UCON-MIR-RMU-120x070', object_class: 'accessory', metron: { 'kind' => 'skip' }, x0: 0, x1: 1, y0: 0, y1: 1, z0: 0, z1: 1 }], {})
  raise out.inspect unless out['not_exported'] == [{ 'ref' => 'f', 'code' => 'C00151', 'object_class' => 'filler' }]
end
check('a top with no unit under it is refused') do
  begin
    M.room([{ ref: 't', metron: { 'kind' => 'top', 'code' => 'TOPDRBA' }, x0: 0, x1: 100, y0: -500, y1: 0, z0: 828, z1: 850 }], {})
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('no unit under it')
  end
end
check('a panel lying along the wall is refused, not guessed') do
  begin
    M.room([{ ref: 'p', metron: { 'kind' => 'panel', 'code' => 'PAN022' }, x0: 0, x1: 600, y0: -22, y1: 0, z0: 0, z1: 585, rot_deg: 0 }], {})
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('across the wall')
  end
end
check('an unknown kind is refused') do
  begin
    M.room([{ ref: 'x', metron: { 'kind' => 'shelf', 'code' => 'X' }, x0: 0, x1: 1, y0: 0, y1: 1, z0: 0, z1: 1 }], {})
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('not one of')
  end
end
check('87_metron has no SketchUp in it') do
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/87_metron.rb', __dir__))
  raise 'Sketchup referenced' if src =~ /Sketchup::|Geom::|\.mm\b/
end

$fails.each { |f| puts "  FAIL  #{f}" }
puts "#{$checks} checks, #{$fails.size} failures"
exit($fails.empty? ? 0 : 1)

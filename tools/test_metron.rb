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
# ---- R02 of the 7612 baths (2026-11-02): countertop basin, stated finishes, fixed fronts, a second collection ----
R02_TOP = { ref: 't1', metron: { 'kind' => 'top', 'code' => 'TOPDRBA', 'sink' => 'FOG1.SP', 'finish' => 'CE26', 'th' => 20 },
            x0: 0, x1: 1514, y0: -500, y1: 0, z0: 738, z1: 758, rot_deg: 0 }.freeze
R02_BASIN = { ref: 'b1', object_class: nil, metron: { 'kind' => 'unit', 'code' => 'LAVABO', 'article' => 'LVB019.003' },
              x0: 467, x1: 1047, y0: -435, y1: -65, z0: 758, z1: 888, rot_deg: 0 }.freeze
r02 = M.room([cab('u1', 'BA60557', 7, 457, 153, 738), cab('u2', 'BA60687', 457, 1057, 153, 738), MIRROR.merge(ref: 'm1', x0: 157, x1: 1357),
              R02_BASIN, R02_TOP],
             { 'room' => '7612-BA3', 'revision' => 'R02', 'estimate' => 'T_00019', 'master' => 'INTBA',
               'finishes' => '{"front":"RI14 Intarsio Rovere Sbiancato"}' })
check('R02: the basin is a unit with its article, not hung, after the cabinets and before the mirror') do
  b = r02['items'].find { |i| i['ref'] == 'b1' }
  raise b.inspect unless b == { 'ref' => 'b1', 'kind' => 'unit', 'code' => 'LAVABO', 'x' => 467, 'y' => 758, 'article' => 'LVB019.003' }
  raise r02['items'].map { |i| i['ref'] }.inspect unless r02['items'].map { |i| i['ref'] } == %w[u1 u2 b1 m1 t1]
end
check('R02: the basin is never one of the units under the top') do
  t = r02['items'].find { |i| i['ref'] == 't1' }
  raise t.inspect unless t['units'] == %w[u1 u2] && t['sink'] == 'FOG1.SP' && t['finish'] == 'CE26' && t['th'] == 20
end
check('R02: room master and finishes are passed through, finishes parsed') do
  raise r02.inspect unless r02['master'] == 'INTBA' && r02['finishes'] == { 'front' => 'RI14 Intarsio Rovere Sbiancato' }
end
check('R02: a LAVABO with no article is refused') do
  begin
    M.room([R02_BASIN.merge(metron: { 'kind' => 'unit', 'code' => 'LAVABO' })], {})
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('no article')
  end
end
check('R02: a stated top thickness that the body does not measure is refused') do
  begin
    M.room([cab('u1', 'BA60557', 7, 457), R02_TOP.merge(z0: 828, z1: 850)], {})
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('states th 20')
  end
end
check('R02: fixed fronts and a unit master are emitted; an unknown fronts value is refused') do
  u = M.room([cab('u1', 'BA60957', 18, 918).merge(metron: { 'fronts' => 'fixed' }),
              { ref: 'f', code: 'C00151', object_class: 'filler', metron: { 'kind' => 'unit', 'code' => 'C00151', 'master' => 'MAX2.2' },
                x0: 0, x1: 72, y0: -645, y1: -557, z0: 0, z1: 2440 }], {})['items']
  raise u.inspect unless u.find { |i| i['ref'] == 'u1' }['fronts'] == 'fixed' && u.find { |i| i['ref'] == 'f' }['master'] == 'MAX2.2'
  begin
    M.room([cab('u1', 'BA60957', 18, 918).merge(metron: { 'fronts' => 'dummy' })], {})
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('not one of fixed')
  end
end
check('R02: a panel carries its stated finish') do
  p = M.room([panel('p1', 'PAN018', -11, 7).tap { |h| h[:metron] = h[:metron].merge('finish' => 'RR14') }], {})['items'].first
  raise p.inspect unless p['finish'] == 'RR14'
end
check('R02: an upstand stands on its top and lies along the wall; one on no top is refused') do
  up = { ref: 'a1', metron: { 'kind' => 'upstand', 'code' => 'ALZATINA', 'finish' => 'CE26' }, x0: 0, x1: 1514, y0: -20, y1: 0, z0: 758, z1: 858 }
  out = M.room([cab('u1', 'BA60557', 7, 457, 153, 738), R02_TOP, up], {})['items']
  a = out.find { |i| i['ref'] == 'a1' }
  raise a.inspect unless a == { 'ref' => 'a1', 'kind' => 'upstand', 'code' => 'ALZATINA', 'top' => 't1', 'x' => 0, 'L' => 1514, 'h' => 100, 'th' => 20, 'finish' => 'CE26' }
  raise 'order' unless out.last['ref'] == 'a1'
  begin
    M.room([up.merge(z0: 900, z1: 1000)], {})
    raise 'accepted'
  rescue ArgumentError => e
    raise e.message unless e.message.include?('stands on no top')
  end
end
check('R02: a panel MARKED along the wall is emitted with its distance from the wall; unmarked it is still refused') do
  p = { ref: 'p', metron: { 'kind' => 'panel', 'code' => 'PAN022', 'orient' => 'along', 'finish' => 'LM51' }, x0: 1990, x1: 3262, y0: -645, y1: -623, z0: 2440, z1: 2716 }
  i = M.room([p], {})['items'].first
  raise i.inspect unless i['orient'] == 'along' && i['pos'] == [1990, 2440, 0, 0] && i['X'] == 1272 && i['Y'] == 276 && i['th'] == 22 && i['from_wall'] == 623
end
check('87_metron has no SketchUp in it') do
  src = File.read(File.expand_path('../src/ucon_cabinet_engine/core/87_metron.rb', __dir__))
  raise 'Sketchup referenced' if src =~ /Sketchup::|Geom::|\.mm\b/
end

$fails.each { |f| puts "  FAIL  #{f}" }
puts "#{$checks} checks, #{$fails.size} failures"
exit($fails.empty? ? 0 : 1)

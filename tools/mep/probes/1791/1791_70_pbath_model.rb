# UCON-MODEL: 1791_PBATH_MEP
#
# 1791 PRIMARY BATH - model step 1 (Andriy 2026-11-08): walls, Leicht double vanity, top, two sink markers, AS-IS markers,
# five scenes. Built after 1791_62 (Bath 1).
#   Frame: origin = left end of the KPS wall 1 run (5334) at the wall 1 face; X along wall 1 to the right, wall 2 (right)
#   face at X = 5334; wall 1 inner face at Y = 2020 (room depth SCALED from the KPS plan, not measured); mm.
#   Ceiling 2438 (KPS). Vanity per KPS 1791_p.bATH 26.09.2026 (Leicht 238 METURO), from wall 2: filler 57 | sink unit 730
#   (153..788, drawers 279 / 356) | drawers 673 (153..788) | sink unit 730 (432..788, one drawer 356, open below) | panel 16.
#   Depth 559. Top ~76 scaled -> 864 (VERIFY). Sinks round, type unknown: circles D450 on KPS CLs 1826 / 422 from wall 2.
#   Shelf (60) under the left sink unit drawn as a board 160..215 (scaled).
#   AS-IS (DISTO IMG_4677, AFF = DISTO - 16): right drain 416 / 590; left drain 1812 / ~590 (height NOT measured);
#   supplies from the photo. Deck faucets (Andriy 2026-11-08).
# Empty model expected (no erase, no page erase). Writing probe: own operation, saved.
m = UCON::ProbeBridge.model
raise "wrong model: #{m.title}" unless m.title =~ /1791_PBATH_MEP/i
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_PBATH_MEP.skp'
raise "STOP: model not empty (#{m.entities.size} entities, #{m.pages.size} pages)" unless m.entities.size == 0 && m.pages.size == 0
W = 5334.0; D = 2020.0; H = 2438.0; T = 152.0
mm = ->(v) { v / 25.4 }
P = ->(x, y, z) { Geom::Point3d.new(mm.(x), mm.(y), mm.(z)) }
def boxg(ents, name, x0, y0, z0, x1, y1, z1, tag)
  g = ents.add_group; g.name = name; g.layer = tag
  f = g.entities.add_face(Geom::Point3d.new(x0 / 25.4, y0 / 25.4, z0 / 25.4), Geom::Point3d.new(x1 / 25.4, y0 / 25.4, z0 / 25.4),
                          Geom::Point3d.new(x1 / 25.4, y1 / 25.4, z0 / 25.4), Geom::Point3d.new(x0 / 25.4, y1 / 25.4, z0 / 25.4))
  f.reverse! if f.normal.z < 0
  f.pushpull((z1 - z0) / 25.4) if z1 > z0
  g
end
def mat(m, name, rgb, alpha = 1.0)
  mt = m.materials[name] || m.materials.add(name); mt.color = Sketchup::Color.new(*rgb); mt.alpha = alpha; mt
end
HIDE = ['1791 MEP Points', '1791 MEP Guides'].freeze
ASIS = [
  ['PL-DR', W - 1812, 590, 'left drain 1 1/2"', 'DISTO 1812 from wall 2; z NOT measured (= right drain, photo)'],
  ['PL-HW', W - 1932, 624, 'left supply HW', 'photo, NOT measured'],
  ['PL-CW', W - 1692, 624, 'left supply CW', 'photo, NOT measured'],
  ['PR-DR', W - 416, 590, 'right drain 1 1/2"', 'DISTO 416 from wall 2 / 606 from today\'s floor - 16'],
  ['PR-HW', W - 526, 594, 'right supply HW', 'photo, NOT measured'],
  ['PR-CW', W - 306, 594, 'right supply CW', 'photo, NOT measured']
].freeze
m.start_operation('1791 Primary Bath: walls, vanity, top, markers, scenes', true)
begin
  tg = ->(n) { m.layers[n] || m.layers.add(n) }
  shell = tg.('1791 Shell'); ctag = tg.('1791 Cabinets'); fix = tg.('1791 Fixtures'); ptag = tg.('1791 MEP Points'); gtag = tg.('1791 MEP Guides')
  ents = m.entities
  wallm = mat(m, '1791 Wall', [242, 241, 238]); floorm = mat(m, '1791 Floor Oak', [222, 203, 168])
  taupe = mat(m, '1791 Vanity Taupe', [140, 120, 100]); stone = mat(m, '1791 Top Stone', [214, 200, 182])
  walls = [boxg(ents, '1791 Wall 1', -T, D, 0, W + T, D + T, H, shell),
           boxg(ents, '1791 Wall 2', W, 0, 0, W + T, D, H, shell),
           boxg(ents, '1791 Wall 3 (part)', W - 2413, -T, 0, W + T, 0, H, shell)]
  walls.each { |g| g.material = wallm; g.set_attribute('UCON_MEP', 'source', 'KPS 1791_p.bATH: wall 1 = 5334, wall 3 = 2413; depth 2020 SCALED; ceiling 2438') }
  fl = ents.add_group; fl.name = '1791 Floor'; fl.layer = shell
  ff = fl.entities.add_face(P.(0, 0, 0), P.(W, 0, 0), P.(W, D, 0), P.(0, D, 0)); ff.reverse! if ff.normal.z < 0
  fl.material = floorm

  v = ents.add_group; v.name = '1791 Vanity'; v.layer = ctag
  y0 = D - 559
  [['1 Side panel L (10)', W - 2206, W - 2190, 432],
   ['2 Sink unit L 730 (22)', W - 2190, W - 1460, 432],
   ['3 Drawer unit 673 (31)', W - 1460, W - 787, 153],
   ['4 Sink unit R 730 (41)', W - 787, W - 57, 153],
   ['5 Filler R 57 (50)', W - 57, W, 153]].each do |n, a, b, z0|
    g = boxg(v.entities, n, a, y0, z0, b, D, 788, ctag); g.material = taupe
  end
  sh = boxg(v.entities, '6 Shelf (60)', W - 2206, y0, 160, W - 1460, D, 215, ctag); sh.material = taupe
  v.set_attribute('UCON_MEP', 'source', 'KPS 1791_p.bATH 26.09.2026 (Leicht 238 METURO): 16 | 730 | 673 | 730 | 57 = 2206; 153 / 432 ..788; depth 559')
  top = boxg(ents, '1791 Countertop', W - 2211, y0, 788, W, D, 864, ctag); top.material = stone
  top.set_attribute('UCON_MEP', 'source', 'KPS elevation: top ~76 scaled -> 864 (VERIFY, FC-M7)')

  [[W - 1826, 'L'], [W - 422, 'R']].each do |cx, s|
    sk = ents.add_group; sk.name = "1791 Sink marker #{s}"; sk.layer = fix
    c = sk.entities.add_circle(P.(cx, D - 290, 865), Z_AXIS, mm.(225), 36)
    sk.entities.add_face(c)
    sk.set_attribute('UCON_MEP', 'trust', "MARKER: sink type unknown (FC-M7); round D~450 on CL #{(W - cx).round} from wall 2, scaled from the KPS plan")
  end

  mk = ents.add_group; mk.name = '1791 AS-IS Points'; mk.layer = ptag
  am = mat(m, 'UCON MEP ASIS', [200, 30, 30])
  ASIS.each do |id, x, z, what, trust|
    g = boxg(mk.entities, id, x - 30, D - 20, z - 30, x + 30, D, z + 30, ptag); g.material = am
    { 'id' => id, 'x' => x, 'y' => D, 'z' => z, 'what' => what, 'trust' => trust }.each { |k, vv| g.set_attribute('UCON_MEP', k, vv) }
  end

  vw = m.active_view
  vis = m.layers.map { |l| [l, l.visible?] }
  m.layers.each { |l| l.visible = !HIDE.include?(l.name) unless l == m.layers[0] }
  m.rendering_options['DisplayText'] = false
  add = lambda do |name, cam, wire = false|
    vw.camera = cam
    pg = m.pages.add(name)
    pg.use_camera = true; pg.use_hidden_layers = true; pg.use_rendering_options = true
    pg.update
    if wire then pg.rendering_options['RenderMode'] = 0 end
    pg
  end
  cx = W - 1300
  hero = Sketchup::Camera.new(P.(cx - 400, -2600, 1500), P.(cx, D, 900), Z_AXIS, true); hero.fov = 55
  plan = -> { t = P.(cx, D / 2, 0); c = Sketchup::Camera.new(t.offset(Z_AXIS, mm.(15_000)), t, Geom::Vector3d.new(0, 1, 0), false); c.height = mm.(2600); c }
  elev = -> { t = P.(cx, D, 1219); c = Sketchup::Camera.new(t.offset(Geom::Vector3d.new(0, -1, 0), mm.(20_000)), t, Z_AXIS, false); c.height = mm.(2900); c }
  add.('A1 Hero', hero)
  add.('A2 Plan', plan.())
  add.('A3 Elevation 1', elev.())
  add.('1791 MEP Plan', plan.())
  add.('1791 MEP Elevation', elev.(), true)
  vis.each { |l, s| l.visible = s }
  m.commit_operation
rescue StandardError
  m.abort_operation
  raise
end
m.entities.grep(Sketchup::Group).each do |g|
  b = g.bounds
  puts format('%-24s x %6.0f..%6.0f y %6.0f..%6.0f z %6.0f..%6.0f', g.name, b.min.x.to_mm, b.max.x.to_mm, b.min.y.to_mm, b.max.y.to_mm, b.min.z.to_mm, b.max.z.to_mm)
end
m.pages.each { |pg| puts "#{pg.name}  persp #{pg.camera.perspective?}  RenderMode #{pg.rendering_options['RenderMode']}" }
puts "saved: #{m.save}  #{File.size(m.path) rescue '?'} bytes"

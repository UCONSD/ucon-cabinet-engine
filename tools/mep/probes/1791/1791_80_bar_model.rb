# UCON-MODEL: 1791_BAR_MEP
#
# 1791 FAMILY ROOM BAR - model step 1 (Andriy 2026-11-08): niche walls, Leicht bar (base on plinth, cooler, sink unit, top,
# backsplash, glass wall units, two open shelves), sink marker, AS-IS markers, five scenes. Built after 1791_70.
#   Frame: origin = inner corner of the left niche wall and the back wall; X to the right, right niche wall at X = 2058
#   (DISTO; KPS 2064); back wall face at Y = 695 (DISTO 694 / 696; KPS 673); niche soffit 2388 AFF (DISTO 2407 - 19).
#   Cabinets per KPS 1791_Family Room 26.09.2026 (Leicht 244 BOSSA), placed from the RIGHT wall (sink side), the left filler
#   takes the -6: filler 21 | unit 800 | cooler 610 | sink unit 600 | filler 26; plinth 100, carcass ..895, top 39 -> 934.
#   Wall units 832..2032 + panel 816..832 + filler 2032..2058, 1458..2385, depth 362; shelves 0..816 at ~1450 / ~1853 (scaled).
# Empty model expected. Writing probe: own operation, saved.
m = UCON::ProbeBridge.model
raise "wrong model: #{m.title}" unless m.title =~ /1791_BAR_MEP/i
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_BAR_MEP.skp'
raise "STOP: model not empty (#{m.entities.size} entities, #{m.pages.size} pages)" unless m.entities.size == 0 && m.pages.size == 0
W = 2058.0; D = 695.0; H = 2388.0; T = 152.0
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
  ['BR-DR', W - 332, 439, 'drain 1 1/2"', 'DISTO 332 / 458 - 19'],
  ['BR-HW', W - 375, 405, 'supply HW', 'photo, NOT measured'],
  ['BR-CW', W - 233, 405, 'supply CW', 'photo, NOT measured'],
  ['BR-E1', W - 705, 363, 'box behind the cooler', 'DISTO 705 / 382 - 19'],
  ['BR-E2', W - 517, 503, 'box in the sink base, upper', 'DISTO 517 / 522 - 19'],
  ['BR-E3', W - 517, 336, 'box in the sink base, lower', 'photo'],
  ['BR-E4', W - 177, 541, 'box right of the drain', 'photo'],
  ['BR-E5', W - 309, 270, 'round box under the drain', 'photo'],
  ['BR-E6', W - 1013, 906, 'box at the countertop line', 'photo'],
  ['BR-E7', W - 1727, 906, 'box at the countertop line', 'photo']
].freeze
m.start_operation('1791 Bar: niche, cabinets, markers, scenes', true)
begin
  tg = ->(n) { m.layers[n] || m.layers.add(n) }
  shell = tg.('1791 Shell'); ctag = tg.('1791 Cabinets'); fix = tg.('1791 Fixtures'); ptag = tg.('1791 MEP Points'); gtag = tg.('1791 MEP Guides')
  ents = m.entities
  wallm = mat(m, '1791 Wall', [242, 241, 238]); floorm = mat(m, '1791 Floor Oak', [222, 203, 168])
  dark = mat(m, '1791 Bar Dark Oak', [70, 52, 40]); stone = mat(m, '1791 Top Stone', [236, 231, 222]); glass = mat(m, '1791 Glass', [180, 160, 130], 0.5)
  walls = [boxg(ents, '1791 Back wall', -T, D, 0, W + T, D + T, H, shell),
           boxg(ents, '1791 Left niche wall', -T, 0, 0, 0, D, H, shell),
           boxg(ents, '1791 Right niche wall', W, 0, 0, W + T, D, H, shell)]
  # niche soffit at H NOT modelled: it would hide the plan from the top camera (see 1791_70 / front wall lesson)
  walls.each { |g| g.material = wallm; g.set_attribute('UCON_MEP', 'source', 'DISTO IMG_4681: 2058 wide, 694 / 696 deep, 2407 high (-19 floor)') }
  fl = ents.add_group; fl.name = '1791 Floor'; fl.layer = shell
  ff = fl.entities.add_face(P.(0, -600, 0), P.(W, -600, 0), P.(W, D, 0), P.(0, D, 0)); ff.reverse! if ff.normal.z < 0
  fl.material = floorm

  v = ents.add_group; v.name = '1791 Bar'; v.layer = ctag
  yb = D - 560
  [['1 Filler L (10)', 0, 21], ['2 Unit 800 (21)', 21, 821], ['4 Sink unit 600 (31)', W - 626, W - 26], ['5 Filler R (40)', W - 26, W]].each do |n, a, b|
    g = boxg(v.entities, n, a, yb, 100, b, D, 895, ctag); g.material = dark
  end
  ck = boxg(v.entities, '3 Cooler PRB24C01CPG (231)', 821, yb, 0, W - 626, D, 895, ctag); ck.material = dark
  pl = boxg(v.entities, 'Plinth 100', 0, yb + 50, 0, W, D, 100, ctag); pl.material = dark
  yw = D - 362
  [['8 Panel (110)', 816, 832], ['9 Glass unit 600 (120)', 832, 1432], ['10 Glass unit 600 (130)', 1432, 2032], ['11 Filler (140)', 2032, W]].each do |n, a, b|
    g = boxg(v.entities, n, a, yw, 1458, b, D, 2385, ctag); g.material = n.start_with?('9', '10') ? glass : dark
  end
  [['7 Shelf (100)', 1442], ['6 Shelf (70)', 1840]].each do |n, z|
    g = boxg(v.entities, n, 0, yw, z, 816, D, z + 27, ctag); g.material = dark
  end
  v.set_attribute('UCON_MEP', 'source', 'KPS 1791_Family Room 26.09.2026 (Leicht 244 BOSSA); placed from the right wall, left filler 27 -> 21 (niche 2058 vs 2064)')
  top = boxg(ents, '1791 Countertop', 0, D - 630, 895, W, D, 934, ctag); top.material = stone
  bs = boxg(ents, '1791 Backsplash', 0, D - 20, 934, W, D, 1442, ctag); bs.material = stone
  top.set_attribute('UCON_MEP', 'source', 'KPS: top 39 -> 934, backsplash stone 508 -> 1442')

  sk = ents.add_group; sk.name = '1791 Sink marker'; sk.layer = fix
  cx = W - 325; cy = D - 300
  sf = sk.entities.add_face(P.(cx - 190, cy - 170, 935), P.(cx + 190, cy - 170, 935), P.(cx + 190, cy + 170, 935), P.(cx - 190, cy + 170, 935))
  sk.set_attribute('UCON_MEP', 'trust', 'MARKER: bar sink model unknown (FC-M7); square ~380 x 340 on CL 325 from the right wall, scaled from the KPS plan')

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
  hero = Sketchup::Camera.new(P.(W / 2, -2800, 1500), P.(W / 2, D, 1100), Z_AXIS, true); hero.fov = 55
  plan = -> { t = P.(W / 2, D / 2, 0); c = Sketchup::Camera.new(t.offset(Z_AXIS, mm.(15_000)), t, Geom::Vector3d.new(0, 1, 0), false); c.height = mm.(1400); c }
  elev = -> { t = P.(W / 2, D, 1200); c = Sketchup::Camera.new(t.offset(Geom::Vector3d.new(0, -1, 0), mm.(20_000)), t, Z_AXIS, false); c.height = mm.(2700); c }
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

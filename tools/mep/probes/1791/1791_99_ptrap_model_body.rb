# 1791_99 body (v0.6 sink check, Andriy 2026-11-11): ORDERED sink + REAL Lusso drawers + Kohler trap into one of our
# 1791 MEP models, section plane + scene '1791 P-trap Section'. Lusso 3D coordinates: wall at y 0, room negative;
# caller gives DW (our wall y) so ours = DW + lusso_y; x is the same frame. Writing probe: own operation, saved.
m = UCON::ProbeBridge.model
raise "wrong file: #{m.path}" unless File.basename(m.path) == S[:file]
# SketchUp on the Mac crashes when a probe drives the view / section of a document that is NOT the front one (2026-11-11,
# twice). Refuse instead.
raise "STOP: #{m.title} is not the active document (active: #{Sketchup.active_model.title}) - open it last" unless Sketchup.active_model == m
mm = ->(v) { v / 25.4 }
P = ->(x, y, z) { Geom::Point3d.new(mm.(x), mm.(y), mm.(z)) }
DW = S[:dw].to_f
Y = ->(ly) { DW + ly }
m.options['PageOptions']['ShowTransition'] = false
m.start_operation('1791 P-trap check (ordered sink, Lusso drawer)', true)
begin
  m.entities.grep(Sketchup::Group).select { |g| g.name.start_with?('1791 PT ') }.each(&:erase!)
  m.entities.grep(Sketchup::ComponentInstance).select { |e| e.name.start_with?('1791 PT ') }.each(&:erase!)
  m.entities.grep(Sketchup::SectionPlane).select { |s| s.name.start_with?('1791 PT section') }.each(&:erase!)
  m.pages.erase(m.pages['1791 P-trap Section']) if m.pages['1791 P-trap Section']
  fix = m.layers['1791 Fixtures'] || m.layers.add('1791 Fixtures')
  cab = m.layers['1791 Cabinets'] || m.layers.add('1791 Cabinets')
  vb  = m.layers['1791 Vanity Box'] || m.layers.add('1791 Vanity Box')
  van = m.entities.grep(Sketchup::Group).find { |g| g.name == '1791 Vanity' } or raise 'STOP: 1791 Vanity not found'
  van.layer = vb
  mat = lambda do |n, rgb, a|
    x = m.materials[n] || m.materials.add(n); x.color = Sketchup::Color.new(*rgb); x.alpha = a; x
  end
  dmat = mat.('1791 PT Drawer', [220, 120, 40], 0.45); cmat = mat.('1791 PT Carcass', [170, 170, 170], 0.7); bmat = mat.('1791 PT Bowl', [250, 250, 250], 0.6)
  poly = lambda do |ents, pts2, z0, z1|
    f = ents.add_face(pts2.map { |x, y| P.(x, y, z0) }); f.reverse! if f.normal.z < 0; f.pushpull(mm.(z1 - z0))
  end
  box = ->(ents, x0, x1, y0, y1, z0, z1) { poly.(ents, [[x0, y0], [x1, y0], [x1, y1], [x0, y1]], z0, z1) }
  # carcass bottom
  c = S[:carcass]
  g = m.entities.add_group; g.name = '1791 PT Carcass (Lusso 3D)'; g.layer = cab
  box.(g.entities, c[:x0], c[:x1], Y.(-540), Y.(0), c[:z0], c[:z1]); g.material = cmat
  # drawers
  S[:drawers].each do |d|
    g = m.entities.add_group; g.name = "1791 PT Drawer #{d[:name]} (Lusso 3D)"; g.layer = cab
    e = g.entities
    sx0, sx1 = d[:sx0], d[:sx1]   # outer faces of the two sides (15 thick)
    yf = Y.(d[:yf]); ybi = Y.(d[:yb] - 6); ybo = Y.(d[:yb])
    box.(e, sx0, sx0 + 15, yf, ybo, d[:z0], d[:z1]); box.(e, sx1 - 15, sx1, yf, ybo, d[:z0], d[:z1])
    if (n = d[:notch])
      nx0, nx1, ny = n[0], n[1], Y.(n[2])
      poly.(e, [[sx0 + 15, yf], [sx1 - 15, yf], [sx1 - 15, ybi], [nx1, ybi], [nx1, ny], [nx0, ny], [nx0, ybi], [sx0 + 15, ybi]], d[:b0], d[:b1])
      box.(e, sx0 + 15, nx0, ybi, ybo, d[:z0], d[:z1]); box.(e, nx1, sx1 - 15, ybi, ybo, d[:z0], d[:z1])
      box.(e, nx0, nx0 + 8, ny, ybo, d[:z0], d[:z1]); box.(e, nx1 - 8, nx1, ny, ybo, d[:z0], d[:z1])
      box.(e, nx0, nx1, ny - 8, ny, d[:z0], d[:z1])
    else
      box.(e, sx0 + 15, sx1 - 15, yf, ybi, d[:b0], d[:b1]); box.(e, sx0 + 15, sx1 - 15, ybi, ybo, d[:z0], d[:z1])
    end
    g.material = dmat
    g.set_attribute('UCON_MEP', 'source', "Lusso 3D 10.11.26: drawer box #{d[:z0]}..#{d[:z1]}, bottom #{d[:b0]}..#{d[:b1]}#{d[:notch] ? ', U cut-out' : ', solid'}")
  end
  # countertop: 2 cm slab + built-up front edge (Andriy 2026-11-11); the solid block goes to its own tag, hidden in the scene
  cs = m.layers['1791 Countertop Solid'] || m.layers.add('1791 Countertop Solid')
  top = m.entities.grep(Sketchup::Group).find { |g| g.name == '1791 Countertop' } or raise 'STOP: 1791 Countertop'
  top.layer = cs
  smat = mat.('1791 PT Stone', [120, 120, 120], 1.0)
  tb = top.bounds; tx0 = tb.min.x.to_mm; tx1 = tb.max.x.to_mm; ty0 = tb.min.y.to_mm
  g = m.entities.add_group; g.name = '1791 PT Top slab 2 cm + built-up edge'; g.layer = cab
  box.(g.entities, tx0, tx1, ty0, DW, S[:top] - 20, S[:top]); box.(g.entities, tx0, tx1, ty0, ty0 + 20, S[:stone_under], S[:top] - 20)
  g.material = smat
  # ordered sink (glued under the 2 cm slab)
  S[:under] = S[:top] - 20
  b = S[:bowl]
  bw = m.entities.add_group; bw.name = "1791 PT Bowl #{b[:name]}"; bw.layer = fix
  zb = S[:under] - b[:h]
  if b[:round]
    ci = bw.entities.add_circle(P.(b[:cx], Y.(b[:cy]), zb), Z_AXIS, mm.(b[:w] / 2.0), 48); f = bw.entities.add_face(ci); f.reverse! if f.normal.z < 0; f.pushpull(mm.(b[:h]))
  else
    box.(bw.entities, b[:cx] - b[:w] / 2.0, b[:cx] + b[:w] / 2.0, Y.(b[:cy]) - b[:d] / 2.0, Y.(b[:cy]) + b[:d] / 2.0, zb, S[:under])
  end
  bw.material = bmat
  bw.set_attribute('UCON_MEP', 'source', b[:src])
  # trap (definition saved from the Primary Bath model; same orientation: flange on the wall at +y)
  td = m.definitions['skp84D'] || m.definitions.load(File.expand_path('~/Documents/1791_Lusso_3D/Kohler_P-trap_skp84D.skp'))
  tr = Geom::Transformation.new([-1.0, 0, 0, 0, 0, 0, -1.0, 0, 0, -1.0, 0, 0, mm.(S[:xd]), mm.(DW - 161.7), mm.(S[:zd] - 37.7), 1.0])
  ti = m.entities.add_instance(td, tr); ti.name = '1791 PT Kohler P-trap'; ti.layer = fix
  # section + scene
  sp = m.entities.add_section_plane([P.(S[:xd], 0, 0), Geom::Vector3d.new(-1, 0, 0)]); sp.name = '1791 PT section'
  m.entities.active_section_plane = sp
  t = P.(S[:xd], DW - 300, 600)
  cam = Sketchup::Camera.new(t.offset(Geom::Vector3d.new(1, 0, 0), mm.(20_000)), t, Z_AXIS, false); cam.height = mm.(800)
  m.active_view.camera = cam
  vb.visible = false; cs.visible = false; fix.visible = true; cab.visible = true
  pg = m.pages.add('1791 P-trap Section')
  pg.use_camera = true; pg.use_section_planes = true; pg.use_hidden_layers = true; pg.use_rendering_options = true
  pg.update
  m.entities.active_section_plane = nil
  vb.visible = true; cs.visible = true
  m.commit_operation
rescue StandardError
  m.abort_operation
  raise
end
puts "saved: #{m.save}"
tb = m.entities.grep(Sketchup::ComponentInstance).find { |e| e.name == '1791 PT Kohler P-trap' }.bounds
puts format('trap x %.0f..%.0f y %.0f..%.0f z %.0f..%.0f', tb.min.x.to_mm, tb.max.x.to_mm, tb.min.y.to_mm, tb.max.y.to_mm, tb.min.z.to_mm, tb.max.z.to_mm)
m.pages.selected_page = m.pages['1791 P-trap Section']
img = File.expand_path("~/dev/_claude/1791_ptrap_#{S[:tag]}.png")
m.active_view.write_image(filename: img, width: 1200, height: 900, antialias: true)
puts "image #{File.size(img)} b"

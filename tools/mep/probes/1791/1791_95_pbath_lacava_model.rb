# UCON-MODEL: 1791_PBATH_MEP
#
# 1791 PRIMARY BATH - model step for set v0.6 (Andriy 2026-11-11): the ORDERED sinks and the REAL Lusso drawers.
# Sources: plumbing fixture order S6689471 (Lodha 11.08): Lacava 5451-001 x2, undermount, 552 x 391 x 162 (spec sheet).
# Lusso 3D LUSSO_1791_PBATH.skp (10.11): stone 788..864; sink-unit upper drawer box 449..635 (sides 15, back at 30..38
# from the wall), bottom 452..462 SOLID - no U cut-out; left unit carcass bottom 432..451, open below; right unit lower
# drawer box 170..356. Lusso x -> ours: +2362; Lusso y (wall 0, room -) -> ours: 2020 + y.
# Does: removes the 11.08 design bowl and assumed U bottom; adds both Lacava bowls, both Lusso drawer boxes, copies the
# Kohler trap to the right drain (x 4918 / 590); section planes + scenes '1791 P-trap Section L' / '... R'.
# Writing probe: own operation, saved. Re-run safe.
m = UCON::ProbeBridge.model
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_PBATH_MEP.skp'
mm = ->(v) { v / 25.4 }
P = ->(x, y, z) { Geom::Point3d.new(mm.(x), mm.(y), mm.(z)) }
D = 2020.0; ZARM = 590.0
SINKS = { 'L' => { cx: 3508.0, dx: 3522.0, ux0: 3167.0, ux1: 3849.0 }, 'R' => { cx: 4912.0, dx: 4918.0, ux0: 4570.0, ux1: 5253.0 } }
trapL = m.entities.grep(Sketchup::ComponentInstance).find { |e| e.name == '1791 PT Kohler P-trap L' } or raise 'STOP: trap L not found'
m.start_operation('1791 PBATH v0.6: Lacava + Lusso drawers', true)
begin
  old = m.entities.grep(Sketchup::Group).select { |g| g.name.start_with?('1791 PT ') }
  m.entities.erase_entities(old) unless old.empty?
  m.entities.grep(Sketchup::ComponentInstance).select { |e| e.name == '1791 PT Kohler P-trap R' }.each(&:erase!)
  m.entities.grep(Sketchup::SectionPlane).select { |s| s.name.start_with?('1791 PT section') }.each(&:erase!)
  %w[L R].each { |s| m.pages.erase(m.pages["1791 P-trap Section #{s}"]) if m.pages["1791 P-trap Section #{s}"] }
  fix = m.layers['1791 Fixtures'] || m.layers.add('1791 Fixtures')
  cab = m.layers['1791 Cabinets'] || m.layers.add('1791 Cabinets')
  dmat = m.materials['1791 PT Drawer'] || m.materials.add('1791 PT Drawer'); dmat.color = Sketchup::Color.new(220, 120, 40); dmat.alpha = 0.45
  bmat = m.materials['1791 PT Bowl'] || m.materials.add('1791 PT Bowl'); bmat.color = Sketchup::Color.new(250, 250, 250); bmat.alpha = 0.6
  slab = lambda do |ents, x0, x1, y0, y1, z0, z1|
    f = ents.add_face(P.(x0, y0, z0), P.(x1, y0, z0), P.(x1, y1, z0), P.(x0, y1, z0)); f.reverse! if f.normal.z < 0; f.pushpull(mm.(z1 - z0))
  end
  SINKS.each do |s, k|
    # Lusso upper drawer box (no U cut-out in the Lusso 3D)
    g = m.entities.add_group; g.name = "1791 PT Drawer #{s} (Lusso 3D)"; g.layer = cab
    x0 = k[:ux0]; x1 = k[:ux1]; yf = D - 542; yb = D - 30
    slab.(g.entities, x0 + 15, x1 - 15, yf, D - 38, 452, 462)          # bottom
    slab.(g.entities, x0, x0 + 15, yf, yb, 449, 635)                   # side L
    slab.(g.entities, x1 - 15, x1, yf, yb, 449, 635)                   # side R
    slab.(g.entities, x0 + 15, x1 - 15, D - 38, yb, 449, 635)          # back
    g.material = dmat
    g.set_attribute('UCON_MEP', 'source', 'Lusso 3D 10.11.26: drawer box 449..635, solid bottom 452..462, no U cut-out')
    # ordered sink: Lacava 5451-001, 552 x 391 x 162 under the stone (Lusso 3D: underside 788); centre y as the Lusso sink
    b = m.entities.add_group; b.name = "1791 PT Bowl #{s} Lacava 5451-001"; b.layer = fix
    slab.(b.entities, k[:cx] - 276, k[:cx] + 276, D - 310 - 195.5, D - 310 + 195.5, 788 - 162, 788)
    b.material = bmat
    b.set_attribute('UCON_MEP', 'source', 'Lacava 5451-001 spec: exterior 21 3/4 x 15 3/8 x 6 3/8 in (552 x 391 x 162)')
  end
  # trap R = copy of L on the right drain
  tr = m.entities.add_instance(trapL.definition, trapL.transformation)
  tr.transform!(Geom::Transformation.translation([mm.(SINKS['R'][:dx] - SINKS['L'][:dx]), 0, 0]))
  tr.name = '1791 PT Kohler P-trap R'; tr.layer = trapL.layer
  # sections + scenes
  SINKS.each do |s, k|
    sp = m.entities.add_section_plane([P.(k[:dx], 0, 0), Geom::Vector3d.new(-1, 0, 0)])
    sp.name = "1791 PT section #{s}"
    sp.activate
    t = P.(k[:dx], D - 300, 600)
    cam = Sketchup::Camera.new(t.offset(Geom::Vector3d.new(1, 0, 0), mm.(20_000)), t, Z_AXIS, false); cam.height = mm.(800)
    m.active_view.camera = cam
    pg = m.pages.add("1791 P-trap Section #{s}")
    pg.use_camera = true; pg.use_section_planes = true; pg.use_hidden_layers = true; pg.use_rendering_options = true
    pg.update
  end
  m.commit_operation
rescue StandardError
  m.abort_operation
  raise
end
puts "saved: #{m.save}"
%w[L R].each do |s|
  m.pages.selected_page = m.pages["1791 P-trap Section #{s}"]
  img = File.expand_path("~/dev/_claude/1791_pbath_ptrap_#{s}_v06.png")
  m.active_view.write_image(filename: img, width: 1600, height: 1200, antialias: true)
  puts "image #{s} #{File.size(img)} b"
end

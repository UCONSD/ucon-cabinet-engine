# UCON-MODEL: 1791_PBATH_MEP
#
# 1791 PRIMARY BATH - physical P-trap check, model step (Andriy 2026-11-08): Andriy imported a Kohler P-trap (definition
# skp84D, 77 x 323 x 153; probe 974: flange at +y, arm centre 114 above the bend bottom, inlet leg ~285 from the flange).
# This probe: (1) puts that trap under the LEFT sink - flange on the wall 1 face (y 2020), arm on the actual drain
# (x 3522, z 590); (2) adds the drawer bottom of the left sink unit (top 494 = front bottom 432 + 62, ASSUMED) as a
# U-shape sink-drawer bottom (Grass Vionaro sink drawer): notch 300 wide x 330 deep at the trap; (3) a 6" design bowl
# under the stone (636..788); (4) a section plane through the trap axis and the scene '1791 P-trap Section L'.
# Writing probe: own operation, saved. Re-run safe: removes its own previous groups / plane / scene first.
m = UCON::ProbeBridge.model
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_PBATH_MEP.skp'
mm = ->(v) { v / 25.4 }
P = ->(x, y, z) { Geom::Point3d.new(mm.(x), mm.(y), mm.(z)) }
D = 2020.0; XD = 3522.0; ZARM = 590.0
inst = m.entities.grep(Sketchup::ComponentInstance).find { |e| e.definition.name == 'skp84D' } or raise 'STOP: trap skp84D not found'
m.start_operation('1791 PBATH: trap, U drawer bottom, bowl, section', true)
begin
  old = m.entities.grep(Sketchup::Group).select { |g| g.name.start_with?('1791 PT ') }
  m.entities.erase_entities(old) unless old.empty?
  m.entities.grep(Sketchup::SectionPlane).select { |s| s.name == '1791 PT section L' }.each(&:erase!)
  m.pages.erase(m.pages['1791 P-trap Section L']) if m.pages['1791 P-trap Section L']
  fix = m.layers['1791 Fixtures'] || m.layers.add('1791 Fixtures')
  # (1) the trap: translate only (its axes already have the flange at +y, z up)
  b = inst.bounds
  dx = mm.(XD) - (b.min.x + b.max.x) / 2; dy = mm.(D) - b.max.y; dz = mm.(ZARM - 114) - b.min.z
  inst.transform!(Geom::Transformation.translation([dx, dy, dz]))
  inst.name = '1791 PT Kohler P-trap L'; inst.layer = fix
  inst.set_attribute('UCON_MEP', 'source', 'Kohler P-trap imported by Andriy 2026-11-08; arm on the left drain x 3522 / 590 AFF (height assumed = right drain)')
  # (2) U-shape drawer bottom
  glass = m.materials['1791 PT Drawer'] || m.materials.add('1791 PT Drawer'); glass.color = Sketchup::Color.new(220, 120, 40); glass.alpha = 0.45
  g = m.entities.add_group; g.name = '1791 PT Drawer bottom L (U-shape)'; g.layer = m.layers['1791 Cabinets']
  x0 = 3144 + 20; x1 = 3874 - 20; yf = 1461 + 25; yb = D - 25; nx0 = XD - 150; nx1 = XD + 150; ny = yb - 330
  f = g.entities.add_face([P.(x0, yf, 482), P.(x1, yf, 482), P.(x1, yb, 482), P.(nx1, yb, 482), P.(nx1, ny, 482), P.(nx0, ny, 482), P.(nx0, yb, 482), P.(x0, yb, 482)])
  f.reverse! if f.normal.z < 0
  f.pushpull(mm.(12))
  g.material = glass
  g.set_attribute('UCON_MEP', 'trust', 'ASSUMED: bottom top 494 (front bottom + 62, ADU); U notch 300 x 330 - Leicht / Grass sink drawer drawing NOT received')
  # (3) 6" design bowl
  bm = m.materials['1791 PT Bowl'] || m.materials.add('1791 PT Bowl'); bm.color = Sketchup::Color.new(250, 250, 250); bm.alpha = 0.6
  bw = m.entities.add_group; bw.name = '1791 PT Bowl L 6in (design)'; bw.layer = fix
  bf = bw.entities.add_face(P.(3508 - 170, D - 290 - 200, 636), P.(3508 + 170, D - 290 - 200, 636), P.(3508 + 170, D - 290 + 200, 636), P.(3508 - 170, D - 290 + 200, 636))
  bf.reverse! if bf.normal.z < 0
  bf.pushpull(mm.(152))
  bw.material = bm
  # (4) section plane + scene (camera from +x looking -x; the plane keeps x < cut)
  sp = m.entities.add_section_plane([P.(XD, 0, 0), Geom::Vector3d.new(-1, 0, 0)])
  sp.name = '1791 PT section L'
  sp.activate
  vw = m.active_view
  t = P.(XD, D - 300, 600)
  cam = Sketchup::Camera.new(t.offset(Geom::Vector3d.new(1, 0, 0), mm.(20_000)), t, Z_AXIS, false); cam.height = mm.(800)
  vw.camera = cam
  pg = m.pages.add('1791 P-trap Section L')
  pg.use_camera = true; pg.use_section_planes = true; pg.use_hidden_layers = true; pg.use_rendering_options = true
  pg.update
  m.commit_operation
rescue StandardError
  m.abort_operation
  raise
end
tb = inst.bounds
puts format('trap x %.0f..%.0f y %.0f..%.0f z %.0f..%.0f', tb.min.x.to_mm, tb.max.x.to_mm, tb.min.y.to_mm, tb.max.y.to_mm, tb.min.z.to_mm, tb.max.z.to_mm)
puts "saved: #{m.save}"
img = File.expand_path('~/dev/_claude/1791_pbath_src/ptrap_section_L.png')
m.active_view.write_image(filename: img, width: 1600, height: 1200, antialias: true)
puts "image #{File.size(img)} b"

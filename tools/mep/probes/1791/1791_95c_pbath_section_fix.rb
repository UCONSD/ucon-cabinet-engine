# UCON-MODEL: 1791_PBATH_MEP
# 1791_95c (v0.6 model step 2): the solid '1791 Vanity' box hid the trap in the section scenes. Moves it to its own tag
# '1791 Vanity Box' (hidden in the P-trap scenes only) and adds the Lusso 3D carcass parts the section needs:
# L unit bottom 432..451 (open below); R unit lower drawer box 170..356 + carcass bottom 153..172. Writing probe, saved.
m = UCON::ProbeBridge.model
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_PBATH_MEP.skp'
mm = ->(v) { v / 25.4 }
P = ->(x, y, z) { Geom::Point3d.new(mm.(x), mm.(y), mm.(z)) }
D = 2020.0
m.start_operation('1791 PBATH v0.6: section fix', true)
begin
  vb = m.layers['1791 Vanity Box'] || m.layers.add('1791 Vanity Box')
  van = m.entities.grep(Sketchup::Group).find { |g| g.name == '1791 Vanity' } or raise 'STOP: 1791 Vanity not found'
  van.layer = vb
  m.entities.grep(Sketchup::Group).select { |g| g.name.start_with?('1791 PT Carcass') }.each(&:erase!)
  cmat = m.materials['1791 PT Carcass'] || m.materials.add('1791 PT Carcass'); cmat.color = Sketchup::Color.new(170, 170, 170); cmat.alpha = 0.7
  slab = lambda do |ents, x0, x1, y0, y1, z0, z1|
    f = ents.add_face(P.(x0, y0, z0), P.(x1, y0, z0), P.(x1, y1, z0), P.(x0, y1, z0)); f.reverse! if f.normal.z < 0; f.pushpull(mm.(z1 - z0))
  end
  cab = m.layers['1791 Cabinets']
  gl = m.entities.add_group; gl.name = '1791 PT Carcass L (Lusso 3D)'; gl.layer = cab
  slab.(gl.entities, 3143, 3873, D - 540, D, 432, 451)            # bottom panel, open below
  slab.(gl.entities, 3143, 3162, D - 540, D, 432, 788)            # side
  slab.(gl.entities, 3854, 3873, D - 540, D, 432, 788)            # side
  gl.material = cmat
  gr = m.entities.add_group; gr.name = '1791 PT Carcass R (Lusso 3D)'; gr.layer = cab
  slab.(gr.entities, 4546, 5277, D - 540, D, 153, 172)            # carcass bottom
  slab.(gr.entities, 4546, 4565, D - 540, D, 153, 788)
  slab.(gr.entities, 5258, 5277, D - 540, D, 153, 788)
  slab.(gr.entities, 4585, 5238, D - 542, D - 38, 173, 183)       # lower drawer bottom
  slab.(gr.entities, 4585, 5238, D - 38, D - 30, 170, 356)        # lower drawer back
  slab.(gr.entities, 4570, 4585, D - 542, D - 30, 170, 356)       # lower drawer sides
  slab.(gr.entities, 5238, 5253, D - 542, D - 30, 170, 356)
  gr.material = cmat
  %w[L R].each do |s|
    pg = m.pages["1791 P-trap Section #{s}"] or raise "STOP: scene #{s}"
    m.pages.selected_page = pg
    vb.visible = false
    m.layers['1791 Fixtures'].visible = true
    m.entities.grep(Sketchup::SectionPlane).find { |sp| sp.name == "1791 PT section #{s}" }.activate
    pg.update
  end
  vb.visible = true
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

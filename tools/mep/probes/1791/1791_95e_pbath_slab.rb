# UCON-MODEL: 1791_PBATH_MEP
# 1791_95e (set v0.7, Andriy 2026-11-11): the countertop is a 2 cm slab with a built-up 3" edge, the undermount sink is
# glued UNDER THE SLAB (rim at top - 20 = 844), not under the visible edge. Moves both Lacava bowls up to 682..844, adds
# the slab (844..864) + front built-up edge (788..844), hides the solid '1791 Countertop' in the P-trap scenes, moves
# both traps to the proposed drain 572 (22 1/2"). Writing probe, saved. Refuses unless this model is the active one.
m = UCON::ProbeBridge.model
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_PBATH_MEP.skp'
raise "STOP: #{m.title} is not the active document (active: #{Sketchup.active_model.title})" unless Sketchup.active_model == m
mm = ->(v) { v / 25.4 }
P = ->(x, y, z) { Geom::Point3d.new(mm.(x), mm.(y), mm.(z)) }
D = 2020.0; ZNEW = 572.0
m.options['PageOptions']['ShowTransition'] = false
m.start_operation('1791 PBATH v0.7: slab 2 cm, bowls up, traps at 572', true)
begin
  cs = m.layers['1791 Countertop Solid'] || m.layers.add('1791 Countertop Solid')
  top = m.entities.grep(Sketchup::Group).find { |g| g.name == '1791 Countertop' } or raise 'STOP: 1791 Countertop'
  top.layer = cs
  m.entities.grep(Sketchup::Group).select { |g| g.name.start_with?('1791 PT Top') }.each(&:erase!)
  smat = m.materials['1791 PT Stone'] || m.materials.add('1791 PT Stone'); smat.color = Sketchup::Color.new(120, 120, 120); smat.alpha = 1.0
  g = m.entities.add_group; g.name = '1791 PT Top slab 2 cm + built-up edge'; g.layer = m.layers['1791 Cabinets']
  b = top.bounds; x0 = b.min.x.to_mm; x1 = b.max.x.to_mm; y0 = b.min.y.to_mm
  [[x0, x1, y0, D, 844, 864], [x0, x1, y0, y0 + 20, 788, 844]].each do |a0, a1, c0, c1, z0, z1|
    f = g.entities.add_face(P.(a0, c0, z0), P.(a1, c0, z0), P.(a1, c1, z0), P.(a0, c1, z0)); f.reverse! if f.normal.z < 0; f.pushpull(mm.(z1 - z0))
  end
  g.material = smat
  g.set_attribute('UCON_MEP', 'source', 'Andriy 2026-11-11: 2 cm slab, built-up visible edge (3" per Lusso 3D); undermount sink under the slab')
  m.entities.grep(Sketchup::Group).select { |e| e.name =~ /\A1791 PT Bowl [LR] Lacava/ }.each do |bw|
    dz = 844 - bw.bounds.max.z.to_mm
    bw.transform!(Geom::Transformation.translation([0, 0, mm.(dz)]))
  end
  m.entities.grep(Sketchup::ComponentInstance).select { |e| e.name =~ /\A1791 PT Kohler P-trap [LR]\z/ }.each do |t|
    arm = t.bounds.min.z.to_mm + 114
    t.transform!(Geom::Transformation.translation([0, 0, mm.(ZNEW - arm)]))
  end
  %w[L R].each do |s|
    pg = m.pages["1791 P-trap Section #{s}"]
    m.pages.selected_page = pg
    m.entities.active_section_plane = m.entities.grep(Sketchup::SectionPlane).find { |x| x.name == "1791 PT section #{s}" }
    m.layers['1791 Vanity Box'].visible = false; cs.visible = false
    pg.update(1 | 2 | 4 | 8 | 16 | 32 | 64)
  end
  m.layers['1791 Vanity Box'].visible = true; cs.visible = true
  m.commit_operation
rescue StandardError
  m.abort_operation
  raise
end
puts "saved: #{m.save}"
m.entities.each { |e| next unless e.respond_to?(:name) && e.name.to_s.start_with?('1791 PT'); bb = e.bounds; puts format('%s z %.0f..%.0f', e.name, bb.min.z.to_mm, bb.max.z.to_mm) }

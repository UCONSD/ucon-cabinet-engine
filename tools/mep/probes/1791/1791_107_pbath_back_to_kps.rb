# UCON-MODEL: 1791_PBATH_MEP
# 1791_107 (set v0.9, Andriy 2026-11-11): back to the KPS height (top 864, 34") - undoes probe 1791_105 (-19); drains stay 590.
# Adds the sink DRAIN BODY under each bowl so the gap bowl -> trap is visible: Lacava 7100-13(OF) European drain with overflow,
# dia 42 / 67, fixed length 4 1/2" (114) from the flange (spec sheet, labels unreadable - ASSUMED) minus ~20 sink wall = 94 under
# the bowl bottom. Writing probe, saved; front document only. Section images L / R.
m = UCON::ProbeBridge.model
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_PBATH_MEP.skp'
raise "STOP: #{m.title} is not the front document" unless Sketchup.active_model == m
mm = ->(v) { v / 25.4 }
P = ->(x, y, z) { Geom::Point3d.new(mm.(x), mm.(y), mm.(z)) }
up = m.get_attribute('UCON_MEP', 'vanity_raised_mm', 0).to_f
m.options['PageOptions']['ShowTransition'] = false
names = ['1791 Vanity', '1791 Countertop', '1791 Sink marker L', '1791 Sink marker R']
m.start_operation('1791 PBATH v0.9: back to KPS height, drain bodies', true)
begin
  if up > 0
    m.entities.each do |e|
      next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
      n = e.name.to_s
      next unless names.include?(n) || n =~ /\A1791 PT (Top slab|Drawer|Carcass|Bowl)/
      e.transform!(Geom::Transformation.translation([0, 0, mm.(-up)]))
    end
    m.set_attribute('UCON_MEP', 'vanity_raised_mm', 0)
  end
  m.entities.grep(Sketchup::Group).select { |g| g.name.start_with?('1791 PT Drain body') }.each(&:erase!)
  dm = m.materials['1791 PT Drain'] || m.materials.add('1791 PT Drain'); dm.color = Sketchup::Color.new(200, 40, 40); dm.alpha = 0.8
  { 'L' => 3522.0, 'R' => 4918.0 }.each do |s, xd|
    bw = m.entities.grep(Sketchup::Group).find { |g| g.name == "1791 PT Bowl #{s} Lacava 5451-001" } or raise "STOP: bowl #{s}"
    zb = bw.bounds.min.z.to_mm
    tr = m.entities.grep(Sketchup::ComponentInstance).find { |e| e.name == "1791 PT Kohler P-trap #{s}" }
    # the trap inlet leg: x = drain x, y = 285 from the wall face (probe 974)
    yc = 2020.0 - 285
    g = m.entities.add_group; g.name = "1791 PT Drain body #{s} (Lacava 7100-13, ASSUMED 94 under the bowl)"; g.layer = m.layers['1791 Fixtures']
    c = g.entities.add_circle(P.(xd, yc, zb - 94), Z_AXIS, mm.(21), 32); f = g.entities.add_face(c); f.reverse! if f.normal.z < 0; f.pushpull(mm.(94))
    g.material = dm
    puts format('%s: bowl bottom %.0f, drain body bottom %.0f, trap top %.0f', s, zb, zb - 94, tr.bounds.max.z.to_mm)
  end
  m.commit_operation
rescue StandardError
  m.abort_operation
  raise
end
puts "saved: #{m.save}"
%w[L R].each do |s|
  m.pages.selected_page = m.pages["1791 P-trap Section #{s}"]
  img = File.expand_path("~/dev/_claude/1791_pbath_ptrap_#{s}_v09.png")
  m.active_view.write_image(filename: img, width: 1800, height: 1350, antialias: true)
  puts "image #{s} #{File.size(img)} b"
end

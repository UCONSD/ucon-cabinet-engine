# UCON-MODEL: 1791_PBATH_MEP
# 1791_107b: centres each drain body on the trap inlet leg (inlet axis = mean y of the trap's top-ring vertices). Saved.
m = UCON::ProbeBridge.model
raise "STOP: #{m.title} is not the front document" unless Sketchup.active_model == m
mm = ->(v) { v / 25.4 }
m.options['PageOptions']['ShowTransition'] = false
m.start_operation('1791 PBATH: centre drain bodies on the trap inlet', true)
begin
  %w[L R].each do |s|
    tr = m.entities.grep(Sketchup::ComponentInstance).find { |e| e.name == "1791 PT Kohler P-trap #{s}" } or raise "trap #{s}"
    t = tr.transformation
    pts = []
    walk = lambda do |ents, tt|
      ents.each do |e|
        if e.is_a?(Sketchup::Face) then e.vertices.each { |v| pts << v.position.transform(tt) }
        elsif e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) then walk.call(e.definition.entities, tt * e.transformation)
        end
      end
    end
    walk.call(tr.definition.entities, t)
    ymin = pts.map(&:y).min
    pts = pts.select { |p| p.y < ymin + mm.(60) } # inlet leg = the part of the trap farthest from the wall
    ztop = pts.map(&:z).max
    ring = pts.select { |p| p.z > ztop - mm.(2) }
    yc = ring.map(&:y).sum / ring.size; xc = ring.map(&:x).sum / ring.size
    g = m.entities.grep(Sketchup::Group).find { |e| e.name.start_with?("1791 PT Drain body #{s}") } or raise "drain #{s}"
    c = g.bounds.center
    g.transform!(Geom::Transformation.translation([xc - c.x, yc - c.y, 0]))
    puts format('%s: inlet axis x %.0f y %.0f (top %.0f); drain moved by y %.0f', s, xc.to_mm, yc.to_mm, ztop.to_mm, (yc - c.y).to_mm)
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
end

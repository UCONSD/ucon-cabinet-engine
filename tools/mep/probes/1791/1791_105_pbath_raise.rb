# UCON-MODEL: 1791_PBATH_MEP
# 1791_105 (set v0.8, Andriy 2026-11-11): the whole vanity goes UP 3/4" (19 mm) instead of lowering the drains: vanity box,
# countertop (solid + slab), sink markers, Lusso drawers + carcass, Lacava bowls. Top 864 -> 883 (34 3/4"). Drains stay
# as-is (590, both measured by Andriy) - the traps go back to 590. Blocking unchanged (edges stay inside the 5 1/2" bands).
# Writing probe, saved; front document only. Writes section images L / R.
m = UCON::ProbeBridge.model
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_PBATH_MEP.skp'
raise "STOP: #{m.title} is not the front document" unless Sketchup.active_model == m
mm = ->(v) { v / 25.4 }
UP = 19.0; ARM = 590.0
done = m.get_attribute('UCON_MEP', 'vanity_raised_mm', 0).to_f
raise "STOP: already raised by #{done}" if done > 0
m.options['PageOptions']['ShowTransition'] = false
names = ['1791 Vanity', '1791 Countertop', '1791 Sink marker L', '1791 Sink marker R']
m.start_operation('1791 PBATH v0.8: vanity up 3/4"', true)
begin
  moved = []
  m.entities.each do |e|
    next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
    n = e.name.to_s
    next unless names.include?(n) || n =~ /\A1791 PT (Top slab|Drawer|Carcass|Bowl)/
    e.transform!(Geom::Transformation.translation([0, 0, mm.(UP)])); moved << n
  end
  m.entities.grep(Sketchup::ComponentInstance).select { |e| e.name =~ /\A1791 PT Kohler P-trap [LR]\z/ }.each do |t|
    arm = t.bounds.min.z.to_mm + 114
    t.transform!(Geom::Transformation.translation([0, 0, mm.(ARM - arm)])); moved << t.name
  end
  m.set_attribute('UCON_MEP', 'vanity_raised_mm', UP)
  m.commit_operation
  puts "moved: #{moved.join(' | ')}"
rescue StandardError
  m.abort_operation
  raise
end
puts "saved: #{m.save}"
m.entities.each { |e| next unless e.respond_to?(:name) && e.name.to_s =~ /\A1791 (PT|Vanity|Countertop)/; bb = e.bounds; puts format('%-40s z %4.0f..%4.0f', e.name, bb.min.z.to_mm, bb.max.z.to_mm) }
%w[L R].each do |s|
  m.pages.selected_page = m.pages["1791 P-trap Section #{s}"]
  img = File.expand_path("~/dev/_claude/1791_pbath_ptrap_#{s}_v08.png")
  m.active_view.write_image(filename: img, width: 1800, height: 1350, antialias: true)
  puts "image #{s} #{File.size(img)} b"
end

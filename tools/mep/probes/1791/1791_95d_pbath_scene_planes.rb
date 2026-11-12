# UCON-MODEL: 1791_PBATH_MEP
# 1791_95d: scene R showed the L section (page transitions overrode the plane). Transitions off, then per scene:
# select, activate its own plane, update. Writing probe, saved. Images to verify.
m = UCON::ProbeBridge.model
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_PBATH_MEP.skp'
po = m.options['PageOptions']; po['ShowTransition'] = false
m.start_operation('1791 PBATH v0.6: scene planes', true)
begin
  %w[L R].each do |s|
    pg = m.pages["1791 P-trap Section #{s}"]
    m.pages.selected_page = pg
    sp = m.entities.grep(Sketchup::SectionPlane).find { |x| x.name == "1791 PT section #{s}" }
    m.entities.active_section_plane = sp
    m.layers['1791 Vanity Box'].visible = false
    pg.update(1 | 2 | 4 | 8 | 16 | 32 | 64)
    puts "#{s}: active plane #{m.entities.active_section_plane&.name}"
  end
  m.layers['1791 Vanity Box'].visible = true
  m.commit_operation
rescue StandardError
  m.abort_operation
  raise
end
puts "saved: #{m.save}"
%w[L R].each do |s|
  m.pages.selected_page = m.pages["1791 P-trap Section #{s}"]
  puts "#{s} after select: #{m.entities.active_section_plane&.name}"
  img = File.expand_path("~/dev/_claude/1791_pbath_ptrap_#{s}_v06.png")
  m.active_view.write_image(filename: img, width: 1200, height: 900, antialias: true)
end

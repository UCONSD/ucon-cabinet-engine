# READ ONLY - builds nothing, changes nothing.
m = UCON::CabinetEngine
puts "=== core #{m::CORE_VERSION} ==="

st = m::Standards
puts "\n--- Standards ---"
st.constants.sort.each { |c| puts "  #{c} = #{st.const_get(c).inspect}" rescue nil }

begin
  puts "\nfront_y_mm = #{m::Generator.front_y_mm}"
rescue => e
  puts "\nfront_y_mm: #{e.class} #{e.message[0, 90]}"
end

puts "\n--- corner rows as the registry holds them ---"
%w[B7091D B7110D AU090D AU110D AU110S AW110D].each do |code|
  begin
    u = m::Registry.lookup(code)
    puts "  #{code}: " + %w[width_mm depth_mm door_width_mm carcass_length_mm
                            corner_geometry execution unit_type]
      .map { |k| "#{k}=#{u[k].inspect}" }.select { |x| !x.end_with?('=nil') }.join(', ')
    puts "     front_layout: #{u['front_layout'].inspect}"
  rescue => e
    puts "  #{code}: #{e.class} #{e.message[0, 90]}"
  end
end

puts "\n--- what is actually SELECTED in the model ---"
sel = Sketchup.active_model.selection.to_a
puts '  (nothing selected)' if sel.empty?
sel.each do |ent|
  next unless ent.respond_to?(:bounds)
  name = (ent.respond_to?(:definition) ? ent.definition.name : ent.typename) rescue ent.typename
  bb = ent.bounds
  puts "  #{name}: bbox mm #{bb.width.to_mm.round(2)} x #{bb.depth.to_mm.round(2)} x #{bb.height.to_mm.round(2)}"
  d = ent.attribute_dictionary('CabinetEngine')
  d&.each { |k, v| puts "     #{k}: #{v.inspect}" }
end

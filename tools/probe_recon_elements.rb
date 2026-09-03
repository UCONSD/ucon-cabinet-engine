# tools/probe_recon_elements.rb - OUR SIDE OF THE L2 DIFF, kept as a tool.
#
# Spec claude/spec-2026-09-02-model-vs-order-reconciliation.md §7: if the join
# works the probe is kept, because this is the first instance of the L2 diff and
# it should not be written twice. It ran as probe 147 on 2026-09-02 and produced
# the 60 rows behind claude/recon-2026-09-02-model-vs-30833.md.
#
# Drop a copy into tools/probe_inbox/ to run it. It reads and only reads.
# ---------------------------------------------------------------------------
# 147 - READ ONLY. OUR SIDE OF THE DIFF: every orderable body in 545, with the
# code the model believes and the box it actually occupies.
#
# IT DOES NOT ASK Sketchup.active_model, AND THAT IS THE POINT. On this Mac
# active_model answered "T42IT100NP_TradeCAD" - a document whose window is
# closed - three runs in a row while 545 sat in front with the checkmark beside
# it in the Window menu. The model is taken from ObjectSpace by name instead,
# and the probe refuses unless exactly one model answers to it.
#
# The join against estimate 30833 is by SIZE AND POSITION and the comparison is
# by CODE (spec §2), so a row carries both and never joins on the code.
#
# It measures the CARCASS group inside each instance, not the instance box: an
# instance box carries the plan symbols and a drawer's travel runs ~549 mm out
# in front, which read four covered island units as 53% on 2026-08-29. Where
# there is no CARCASS group the row says INSTANCE, so the reader knows.
#
# Writes one CSV. No Declare.apply!, no Generator.build.
puts 'PROBE 147 - read only.'

found = []
ObjectSpace.each_object(Sketchup::Model) do |mm|
  found << mm if mm.title.to_s =~ /545_Avenida/i
end

if found.length != 1
  puts "   REFUSED - #{found.length} model(s) answer to '545_Avenida'."
  found.each { |mm| puts "     #{mm.title}  #{mm.path}" }
  puts '   Nothing was read and nothing was written.'
  return
end
m = found.first
puts "   model    : #{m.title}"
puts "   modified?: #{m.modified?}   entities: #{m.entities.length}"

unless defined?(UCON::CabinetEngine::Export)
  puts '   core/85_export.rb IS NOT LOADED. Press "Reload core", then'
  puts '   "Reload probe bridge (dev)", and drop this again.'
  return
end

ex = UCON::CabinetEngine::Export
ct = UCON::CabinetEngine::Contract

bbox_mm = lambda do |inst|
  body = inst.definition.entities.grep(Sketchup::Group).find { |g| g.name == 'CARCASS' }
  src  = body ? 'CARCASS' : 'INSTANCE'
  bb   = body ? body.bounds : inst.definition.bounds
  tr   = inst.transformation
  xs = []
  ys = []
  zs = []
  8.times do |i|
    p = bb.corner(i).transform(tr)
    xs << p.x.to_f
    ys << p.y.to_f
    zs << p.z.to_f
  end
  [src,
   (xs.min * 25.4).round(1), (ys.min * 25.4).round(1), (zs.min * 25.4).round(1),
   ((xs.max - xs.min) * 25.4).round(1),
   ((ys.max - ys.min) * 25.4).round(1),
   ((zs.max - zs.min) * 25.4).round(1)]
end

rows  = []
mute  = []
walk  = nil
walk = lambda do |entities, depth|
  return if depth > 8

  entities.each do |ent|
    if ent.is_a?(Sketchup::ComponentInstance)
      a = ct.read(ent.definition)
      if ex.orderable?(a) || ex.reservation?(a)
        rows << [ent, a]
      else
        mute << ent if a.nil? || a.empty?
        walk.call(ent.definition.entities, depth + 1)
      end
    elsif ent.is_a?(Sketchup::Group)
      walk.call(ent.entities, depth + 1)
    end
  end
end
walk.call(m.entities, 0)

hdr = %w[n name code object_class unit_type manufacturer code_status mounting
         width_mm height_mm depth_mm box_src x0 y0 z0 w_meas d_meas h_meas tag variants].join(',')
lines = [hdr]
rows.each_with_index do |(ent, a), i|
  src, x0, y0, z0, wm, dm, hm = bbox_mm.call(ent)
  nm = ent.name.to_s
  nm = ent.definition.name.to_s if nm.empty?
  vs = Array(a['variants']).map do |v|
    if v.is_a?(Hash)
      v['label'].to_s.empty? ? "#{v['key']}=#{v['value']}" : v['label'].to_s
    else
      v.to_s
    end
  end
  cells = [i + 1, nm, a['code'], a['object_class'], a['unit_type'], a['manufacturer'],
           a['code_status'], a['mounting'],
           a['width_mm'], a['height_mm'], a['depth_mm'],
           src, x0, y0, z0, wm, dm, hm,
           (ent.layer ? ent.layer.name : ''), vs.join('|')]
  lines << cells.map { |c| s = c.to_s; s =~ /[,"]/ ? '"' + s.gsub('"', '""') + '"' : s }.join(',')
end

out = File.join(File.dirname(File.dirname(__FILE__)), 'recon_ours.csv')
File.write(out, lines.join("\n") + "\n")

puts ''
puts "== OUR ELEMENTS: #{rows.length} orderable/reserved bodies =="
by_code = Hash.new(0)
rows.each { |(_e, a)| by_code[a['code'].to_s.empty? ? '(NO CODE)' : a['code']] += 1 }
by_code.sort_by { |k, v| [-v, k] }.each { |k, v| puts format('   %-18s %d', k, v) }

puts ''
puts "== BODIES WITH NO CONTRACT AT ALL, walked past: #{mute.length} =="
mute.first(12).each { |e| puts "   #{e.name.to_s.empty? ? e.definition.name : e.name}" }

bb = m.bounds
puts ''
puts format('   model extents  x %.1f .. %.1f   y %.1f .. %.1f   z %.1f .. %.1f  (mm)',
            bb.min.x.to_f * 25.4, bb.max.x.to_f * 25.4,
            bb.min.y.to_f * 25.4, bb.max.y.to_f * 25.4,
            bb.min.z.to_f * 25.4, bb.max.z.to_f * 25.4)

puts ''
puts '== IS HER FILE LOADED YET =='
seen = 0
ObjectSpace.each_object(Sketchup::Model) do |mm|
  if mm.title.to_s =~ /30833/
    seen += 1
    puts "   #{mm.title}  top-level entities: #{mm.entities.length}"
  end
end
puts '   not loaded yet - 204 MB takes a while' if seen.zero?

puts ''
puts "   csv written: #{out}"
puts 'PROBE 147 done. Nothing was written to the model.'

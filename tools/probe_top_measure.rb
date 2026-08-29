# tools/probe_top_measure.rb - MEASURE THE STONE BEFORE IT IS STAMPED.
#
# Dev tool. Nothing in src/ requires it, it is never in an .rbz, and it writes
# nothing: drop it in tools/probe_inbox/ and read tools/probe_outbox.txt.
#
# ---- WHY IT EXISTS ---------------------------------------------------------
#
# `core/62_top_stamp.rb` says out loud what was given up when the engine stopped
# drawing tops: "a stamped top does not know the run beneath it, so nothing
# checks the stone covers the cabinets. build_worktop knew, because it measured
# them." This is that check, plus the two questions the stamp cannot ask because
# it only ever sees one piece at a time:
#
#   1. IS THE PIECE ITS OWN BOUNDING RECTANGLE? The order figure is the sheet
#      the piece is cut from (Elda Q28). On a straight run with a mitre that
#      costs nothing. On an L it costs the whole inside corner, and on
#      2026-08-29 that was measured for the first time: 7,206 m2 ordered
#      against 3,012 m2 drawn - 4,195 m2, 58% of the sheet.
#   2. IS THE RUN COVERED BY THE STONE AS A WHOLE? One slab per piece means a
#      per-slab answer is meaningless; the union is what matters.
#
# ---- THE MEASUREMENT MISTAKE THIS TOOL WAS BUILT OUT OF ---------------------
#
# The first version measured an instance's BOUNDING BOX and reported four island
# units as 53% covered. They were fully covered. An instance box includes the
# PLAN SYMBOLS, and Drawing_Spec puts a drawer's travel on the floor in front of
# the unit - about 549 mm - so 600 x 1194 is a 600 x 644,5 cabinet plus its own
# drawer symbol. It was measuring the symbol.
#
# So: the carcass is found INSIDE the definition, by name, and only falls back
# to the instance box when there is no CARCASS group - and says so when it does.
# Any covering check that ever becomes engine code has to do the same, or every
# unit with drawers is permanently "not covered".
#
# Two smaller ones, kept because they cost a probe run each (learned rule 9):
# BoundingBox#width/height/depth are X/Y/Z - `width x depth` is an elevation,
# not a plan; and a face search compares DEFINITION coordinates, so a world z
# finds nothing.
begin
  m    = Sketchup.active_model
  ce   = UCON::CabinetEngine
  ts   = ce::TopStamp
  gen  = ce::Generator
  reg  = ce::Registry
  dict = ce::Contract::DICTIONARY
  mm   = ->(v) { v.to_mm }
  SQMM = 645.16 # square inches -> square mm

  puts "core : #{ce.version_line rescue 'n/a'}"
  puts ''

  # ---- find the stone ----------------------------------------------------
  # The SELECTION if there is one - that is the piece being worked on. Failing
  # that, every top-level body with no CabinetEngine dictionary that is thin in
  # one direction and standing above the floor. A hand-drawn slab is by
  # definition not one of ours yet, which is what makes it findable at all.
  sel = m.selection.to_a.select { |e| e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) }
  slabs =
    if sel.any?
      sel
    else
      m.entities.select do |e|
        next false unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)

        d = (e.respond_to?(:definition) ? e.definition : nil)
        oc = (e.get_attribute(dict, 'object_class') rescue nil) ||
             (d && (d.get_attribute(dict, 'object_class') rescue nil))
        next false if oc

        b = e.bounds
        mm[b.depth] <= 120 && mm[b.max.z] > 700 && [mm[b.width], mm[b.height]].max > 300
      end
    end

  if slabs.empty?
    puts 'NO STONE FOUND. Select the piece, or check it is a group above 700 mm and under 120 thick.'
  else
    puts "== #{slabs.length} SLAB(S) #{sel.any? ? '(from the selection)' : '(found: thin, high, not ours)'} =="
    puts ''
  end

  tops = reg.catalog.select { |c| c['class'] == 'worktop' }

  slabs.each_with_index do |e, i|
    d  = (e.respond_to?(:definition) ? e.definition : nil)
    wb = e.bounds
    lb = d ? d.bounds : e.bounds
    nm = (e.name.to_s.empty? ? (d ? d.name.to_s : '(unnamed)') : e.name.to_s)

    own = [mm[lb.width], mm[lb.height], mm[lb.depth]].map { |v| v.round(1) }
    wld = [mm[wb.width], mm[wb.height], mm[wb.depth]].map { |v| v.round(1) }

    puts "-- PIECE #{i + 1}: #{nm} --"
    puts format('   own axes  : %s', own.sort.join('  x  '))
    puts format('   world box : %s', wld.sort.join('  x  '))
    if own.sort != wld.sort
      puts '   !! THE TWO DIFFER. The stamp measures definition.bounds - the piece in its OWN'
      puts '      axes - so a group left on the world axes is stamped at a box bigger than'
      puts '      its sheet. 90_palette.rb warns about exactly this.'
    end
    puts format('   world  x %.1f..%.1f   y %.1f..%.1f   z %.1f..%.1f',
                mm[wb.min.x], mm[wb.max.x], mm[wb.min.y], mm[wb.max.y], mm[wb.min.z], mm[wb.max.z])

    # ---- rectangle or not, in square metres ------------------------------
    ents  = d ? d.entities : e.entities
    faces = ents.grep(Sketchup::Face).select do |f|
      f.normal.z.abs > 0.99 && (f.bounds.max.z - lb.max.z).abs < 0.04
    end
    bbox = mm[lb.width] * mm[lb.height]
    if faces.empty?
      puts format('   top surface: NOT FOUND (%d faces in the group)', ents.grep(Sketchup::Face).length)
    else
      area  = faces.map(&:area).inject(0.0, :+) * SQMM
      waste = bbox - area
      pct   = bbox.positive? ? waste / bbox * 100.0 : 0.0
      puts format('   plan bounding rectangle : %.1f x %.1f = %.3f m2',
                  mm[lb.width], mm[lb.height], bbox / 1_000_000.0)
      puts format('   real top surface        : %.3f m2, outline %d vertices',
                  area / 1_000_000.0, faces.map { |f| f.outer_loop.vertices.length }.inject(0, :+))
      if pct > 2.0
        puts format('   >>> ORDERED AND NOT DRAWN: %.3f m2, %.0f%% of the sheet. THIS IS NOT A',
                    waste / 1_000_000.0, pct)
        puts '       RECTANGLE, and the bounding-rectangle order (Elda Q28) is what it costs.'
        puts '       Cutting it into rectangles at the corner makes that cost zero and is'
        puts '       also how it gets under the sheet length. The joint is Elda Q27.'
      else
        puts '   the piece IS its bounding rectangle - Q28 costs nothing here'
      end
    end
    puts ''

    # ---- what every band would make of it --------------------------------
    tops.each do |c|
      u = reg.lookup(c['code'])
      groups = (u['points_per_lm_by_group_and_band'] || {}).keys.sort
      Array(u['depth_bands_mm']).each do |band|
        meas = (ts.measure(own, band) rescue nil)
        next unless meas

        art = (gen.worktop_article(c['code'], band.to_s, groups.first, '') rescue nil)
        next unless art

        verdict = begin
          ts.verify(meas, art)
          r = ts.remarks(meas, art)
          r.empty? ? 'OK' : "OK - #{r.join('; ')}"
        rescue StandardError => err
          "REFUSED - #{err.message.split("\n").first}"
        end
        puts format('   %-12s band %-5s L %-8s D %-7s T %-6s  %s',
                    c['code'], band.to_i, meas[:length_mm].round(1),
                    meas[:depth_mm].round(1), meas[:thickness_mm].round(1), verdict)
      end
    end
    puts ''
  end

  # ---- does the stone cover the run, MEASURED ON THE CARCASS --------------
  rects = slabs.map { |e| b = e.bounds; [mm[b.min.x], mm[b.max.x], mm[b.min.y], mm[b.max.y]] }

  # The carcass, in world coordinates, out of the unit's own definition. This is
  # the whole point: an instance box carries the plan symbols with it.
  carcass_box = lambda do |inst|
    d = (inst.respond_to?(:definition) ? inst.definition : nil)
    sub = d && d.entities.find do |x|
      (x.is_a?(Sketchup::Group) || x.is_a?(Sketchup::ComponentInstance)) &&
        x.name.to_s.upcase.start_with?('CARCASS')
    end
    return [inst.bounds, false] unless sub

    b = sub.bounds
    t = inst.transformation
    pts = (0..7).map { |k| b.corner(k).transform(t) }
    bb = Geom::BoundingBox.new
    pts.each { |p| bb.add(p) }
    [bb, true]
  end

  puts '== DOES THE STONE COVER THE RUN (carcass measured, symbols excluded) =='
  any = false
  m.entities.each do |o|
    next unless o.is_a?(Sketchup::ComponentInstance) || o.is_a?(Sketchup::Group)

    od = (o.respond_to?(:definition) ? o.definition : nil)
    oc = (o.get_attribute(dict, 'object_class') rescue nil) ||
         (od && (od.get_attribute(dict, 'object_class') rescue nil))
    next unless %w[cabinet filler corner_unit appliance_front].include?(oc.to_s)

    box, real = carcass_box.call(o)
    top_z = mm[box.max.z]
    next unless top_z > 700 && top_z < 1000

    ox1 = mm[box.min.x]; ox2 = mm[box.max.x]
    oy1 = mm[box.min.y]; oy2 = mm[box.max.y]
    n = 30
    hit = 0
    (0...n).each do |ix|
      (0...n).each do |iy|
        px = ox1 + (ox2 - ox1) * (ix + 0.5) / n
        py = oy1 + (oy2 - oy1) * (iy + 0.5) / n
        hit += 1 if rects.any? { |x1, x2, y1, y2| px >= x1 && px <= x2 && py >= y1 && py <= y2 }
      end
    end
    cov = hit.to_f / (n * n) * 100.0
    next if cov >= 99.0

    any = true
    onm = (o.name.to_s.empty? ? (od ? od.name.to_s : '?') : o.name.to_s)
    puts format('  %-42s %5.0f%%  x %.1f..%.1f  y %.1f..%.1f  %s',
                onm[0, 42], cov, ox1, ox2, oy1, oy2,
                real ? '' : '(NO CARCASS GROUP - instance box, symbols included)')
  end
  puts '  every carcass under the stone is covered' unless any

rescue Exception => e
  puts "PROBE FAILED: #{e.class}: #{e.message}"
  puts e.backtrace.first(12)
end

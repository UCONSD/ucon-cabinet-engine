# ARMED. Run 107 - paint the oak/black split so it reads on an elevation.
#
# HELD, not in the inbox. It CHANGES THE MODEL: run
#   UCON::ProbeBridge.arm!
# first, then move this file into tools/probe_inbox/. Unarmed it rolls back and
# is a harmless rehearsal.
#
# WHY PAINT AT ALL. The Object Contract has 31 keys and not one is a finish, so
# there is nowhere in the model's data to write "this door is RR09 and that one
# is LX19". Every finish block of the Maxima 2.2 order form (printed p.65) says
# mixed finishes must be specified per element "in the list or on the drawing",
# and the printed form carries only the FAMILY - Structured for the lacquer,
# First for the veneer - never the colour code. So the drawing is the only place
# the split can live, and two materials are the cheapest honest way to put it
# there. This is a DRAWING act, not a contract act.
#
# THE SPLIT, decided by Andriy 2026-08-30:
#   OAK   RR09 Rovere Nordico (First veneer, F6) - the east wall floor to 3040,
#         and the island
#   BLACK LX19 Nero (structured lacquer, F6)     - the west run, the south base
#         run, and the south uppers
#   The three TF0641 are untouched: black frame, black silk-screen, transparent
#   glass was decided on 2026-08-29 and is not a door finish.
#
# WHAT IT DOES NOT SURVIVE. The generator paints UCON_Front_White at build time
# (60_generator.rb:387, :577; 80_panel.rb:708). Anything rebuilt after this run
# comes back white and must be repainted. That is a fact about the engine, not a
# fault in this script, and it is the same "the model is not recomputed when the
# engine changes" that repo-state has carried for a week.
begin
  m    = Sketchup.active_model
  ce   = UCON::CabinetEngine
  dict = ce::Contract::DICTIONARY
  mm   = ->(v) { v.to_mm.round(1) }

  oak   = 'RR09 Rovere Nordico'
  black = 'LX19 Nero'
  glass = '(glass door - decided separately)'

  # Named for what they ARE, not for what kind of body carries them. Every other
  # UCON_* material in this model says "this is a front" or "this is a carcass";
  # these two say which finish was ordered, which is the whole point.
  mat_oak   = m.materials['UCON_Finish_RR09_Rovere_Nordico'] ||
              m.materials.add('UCON_Finish_RR09_Rovere_Nordico')
  mat_oak.color = Sketchup::Color.new(186, 151, 106)
  mat_black = m.materials['UCON_Finish_LX19_Nero'] ||
              m.materials.add('UCON_Finish_LX19_Nero')
  mat_black.color = Sketchup::Color.new(31, 30, 32)

  # ---- the two plans -------------------------------------------------------
  # A. objects with a FRONT group: only the front is painted. 43 lines, and
  #    probe 106 proved each matches exactly one object and that no definition
  #    is wanted in two finishes.
  fronts = [
    ['C00151', 5587.5,  646.1,    0.0, oak], ['C92640', 5587.5, 1915.3,    0.0, oak],
    ['C90635', 5587.5, 2515.3,    0.0, oak], ['C90635', 5587.5, 3115.3,    0.0, oak],
    ['C90635', 5587.5, 3715.3,    0.0, oak], ['C90635', 5587.5, 4315.3,    0.0, oak],
    ['BE0151', 5587.5,  646.1, 2440.0, oak], ['SD0631', 5587.5,  695.3, 2440.0, oak],
    ['SD0631', 5587.5, 1305.3, 2440.0, oak], ['SD0631', 5587.5, 1915.3, 2440.0, oak],
    ['SD0631', 5587.5, 2515.3, 2440.0, oak], ['SD0631', 5587.5, 3115.3, 2440.0, oak],
    ['SD0631', 5587.5, 3715.3, 2440.0, oak], ['SD0631', 5587.5, 4315.3, 2440.0, oak],
    [nil,      5587.5,  695.3, 2127.0, oak],
    ['B80653', 1733.8, 1687.9,    0.0, oak], ['B80653', 2333.8, 1687.9,    0.0, oak],
    ['B80653', 2933.8, 1687.9,    0.0, oak], ['B80653', 3533.8, 1687.9,    0.0, oak],
    ['AU110D',    0.0,    0.0,    0.0, black], ['B80565',    0.0, 1150.0,   0.0, black],
    ['B81087',    0.0, 1600.0,    0.0, black], ['V80630',  557.0, 2650.0,   0.0, black],
    ['B70501',  270.0, 3250.0,    0.0, black], ['B70150',  270.0, 3700.0,   0.0, black],
    ['B80501',  703.0,    0.0,    0.0, black], ['B80753', 1153.0,    0.0,   0.0, black],
    ['B80753', 3123.0,    0.0,    0.0, black], ['B70151', 3873.0,  557.0,   0.0, black],
    ['PF0151',    0.0,    0.0, 1480.0, black], ['BE0151',    0.0,  598.0, 2440.0, black],
    ['SD0631',  103.0,    0.0, 2440.0, black], ['SD0631',  703.0,    0.0, 2440.0, black],
    ['SD0631', 1303.0,    0.0, 2440.0, black], ['SD0631', 1903.0,    0.0, 1720.0, black],
    ['SD0631', 1903.0,    0.0, 2440.0, black], ['SD0631', 2513.0,    0.0, 1720.0, black],
    ['SD0631', 2513.0,    0.0, 2440.0, black], ['SD0930', 3123.0,    0.0, 2440.0, black],
    ['BE0151', 3893.0,  598.0, 2440.0, black],
    ['TF0641',  103.0,    0.0, 1480.0, glass], ['TF0641',  703.0,    0.0, 1480.0, glass],
    ['TF0641', 1303.0,    0.0, 1480.0, glass]
  ]

  # B. bodies with NO front group - the whole body is the surface. The six Cesar
  #    veneer panels are ALREADY oak by article: DZ731Q / DV731Q / DV061Q are
  #    price group A, First wood veneers, and printed p.218 and p.220 print that
  #    group as exactly seven Rovere, Rovere Nordico among them. There is no
  #    lacquer in group A at all. Painting them oak is not a choice being made
  #    here; it is the drawing catching up with an article already ordered.
  #    The three Sub-Zero overlay panels carry no article - they are ours, they
  #    stand in the east wall, and the east wall is oak.
  bodies = [
    ['DV731Q', 1711.8, 1687.9,    0.0, oak], ['DV731Q', 4133.8, 1687.9,    0.0, oak],
    ['DZ731Q', 1733.8, 2332.9,    0.0, oak], ['DZ731Q', 1733.8, 2332.9,  764.0, oak],
    ['DZ731Q', 2933.8, 2332.9,    0.0, oak], ['DZ731Q', 2933.8, 2332.9,  764.0, oak],
    ['DV061Q', 5587.5, 4915.3,    0.0, oak], ['DV061Q', 5587.5, 4915.3, 2440.0, oak],
    [nil,      5587.5,  695.3,  100.0, oak],   # Sub-Zero refrigerator overlay
    [nil,      5587.5, 1428.8,  100.0, oak],   # Sub-Zero freezer overlay
    [nil,      5587.5,  695.3, 1912.0, oak]    # Sub-Zero grille overlay
  ]

  tol = 0.6

  objs = []
  m.entities.each do |e|
    next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
    dfn = (e.respond_to?(:definition) ? e.definition : nil)
    oc  = (e.get_attribute(dict, 'object_class') rescue nil)
    oc ||= (dfn && (dfn.get_attribute(dict, 'object_class') rescue nil))
    next unless oc
    cd = (e.get_attribute(dict, 'code') rescue nil)
    cd ||= (dfn && (dfn.get_attribute(dict, 'code') rescue nil))
    bb = Geom::BoundingBox.new
    if dfn
      dfn.entities.each do |sub|
        next unless sub.is_a?(Sketchup::Group) || sub.is_a?(Sketchup::ComponentInstance)
        nm = sub.name.to_s
        nm = sub.definition.name.to_s if nm.empty? && sub.respond_to?(:definition)
        next if nm.upcase.start_with?('SYM_')
        sb = sub.bounds
        8.times { |i| bb.add(sb.corner(i).transform(sub.transformation).transform(e.transformation)) }
      end
    end
    bb = e.bounds if bb.empty?
    objs << { e: e, dfn: dfn, code: cd.to_s,
              x: mm.call(bb.min.x), y: mm.call(bb.min.y), z: mm.call(bb.min.z),
              nm: (e.name.to_s.empty? ? (dfn ? dfn.name : '?') : e.name) }
  end

  find = lambda do |code, x, y, z|
    objs.select do |o|
      (code.nil? ? o[:code].empty? : o[:code] == code) &&
        (o[:x] - x).abs <= tol && (o[:y] - y).abs <= tol && (o[:z] - z).abs <= tol
    end
  end

  # ---- REFUSE BEFORE PAINTING ---------------------------------------------
  # A guard must prove itself before it is trusted, and the cheapest proof is
  # that it runs before anything is changed rather than after.
  problems = []
  (fronts + bodies).each do |code, x, y, z, _f|
    hits = find.call(code, x, y, z)
    problems << "#{code || '(no code)'} @ #{x}/#{y}/#{z} matched #{hits.size}" unless hits.size == 1
  end
  unless problems.empty?
    puts "REFUSED - the model is not the model this plan was written against:"
    problems.each { |p| puts "  #{p}" }
    puts "Nothing was painted."
    raise 'plan does not match the model'
  end

  painted = Hash.new(0)
  skipped = 0

  paint_faces = lambda do |ent, mat|
    n = 0
    return 0 unless ent.respond_to?(:entities)
    ent.entities.each do |f|
      next unless f.is_a?(Sketchup::Face)
      cur = f.material && f.material.name
      if cur.nil? || cur.start_with?('UCON_Front_') || cur.start_with?('UCON_Finish_')
        f.material = mat
        n += 1
      end
    end
    n
  end

  fronts.each do |code, x, y, z, fin|
    if fin == glass
      skipped += 1
      next
    end
    mat = (fin == oak ? mat_oak : mat_black)
    o = find.call(code, x, y, z).first
    hit = false
    o[:dfn].entities.each do |sub|
      next unless sub.is_a?(Sketchup::Group) || sub.is_a?(Sketchup::ComponentInstance)
      nm = sub.name.to_s
      nm = sub.definition.name.to_s if nm.empty? && sub.respond_to?(:definition)
      up = nm.upcase
      next if up.start_with?('SYM_')
      next unless up.include?('FRONT') || up.include?('DOOR') || up.include?('DRAWER')
      sub.material = mat
      paint_faces.call(sub, mat)
      hit = true
    end
    painted[fin] += 1 if hit
    puts "  [!] no front group painted on #{code} @ #{x}/#{y}/#{z}" unless hit
  end

  bodies.each do |code, x, y, z, fin|
    mat = (fin == oak ? mat_oak : mat_black)
    o = find.call(code, x, y, z).first
    o[:e].material = mat
    paint_faces.call(o[:dfn], mat)
    painted["#{fin} (body)"] += 1
  end

  puts "core  : #{ce.version_line rescue 'n/a'}"
  puts "PAINTED:"
  painted.sort.each { |k, v| puts format("  %-34s %d", k, v) }
  puts format("  %-34s %d", 'TF0641 left alone (glass)', skipped)
  puts ""
  puts "materials now in the model:"
  m.materials.each { |x| puts "  #{x.name}" if x.name.start_with?('UCON_F') }
  puts ""
  puts "If this ran ARMED the split is in the model and every elevation will show"
  puts "it. If it ran unarmed nothing was kept - arm and run again."
rescue Exception => e
  puts "PROBE FAILED: #{e.class}: #{e.message}"
  puts e.backtrace.first(12)
end

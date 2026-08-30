# ARMED. Run 112 - the whole drawing, not just the fronts. Supersedes run 107.
#
# HELD. Run  UCON::ProbeBridge.arm!  first, then move this into probe_inbox/.
# Unarmed it rolls back and is a rehearsal.
#
# WHY THIS REPLACES 107. Run 107 painted FRONTS and nothing else, and reported
# an object as done if ANY sub-group matched FRONT/DOOR/DRAWER. Two consequences,
# both found by Andriy looking at the model rather than by any check:
#   - AU110D's 8x8 fixed corner panel is called FILLER_8X8, was never painted,
#     and the object still reported "painted" because its door was.
#   - 518 faces carried no material at all, and 506 of them belong to bodies
#     whose finish was DECIDED on 2026-08-29 and simply never drawn.
#
# So this paints BY RULE where a rule exists, and by plan only where a choice
# was actually made. A unit built tomorrow gets its carcass painted by the same
# rule without anybody editing a list.
#
#   CARCASS                 -> Grigio Fumo        decided 2026-08-29
#   PLINTH                  -> Aluminium Black    decided 2026-08-29, H.10
#   FRONT (frame: DECLARED) -> Aluminium Black    decided 2026-08-29, glass frames
#   FRONT_GLASS             -> transparent glass with OAK FABRIC, decided 2026-08-30
#   FRONT*, FILLER_8X8, PANEL -> the oak/black split, per object
#   APPLIANCE_OPENING_600   -> nothing, on purpose. A niche is drawn and never
#                              ordered (domain rule 8), so it has no finish.
#
# THE SPLIT, as it stands after 2026-08-30: the upper tier is ALL oak; black
# survives on the base runs and on the two CUSTOM boxes over the range at 1720,
# which is where the hood goes.
begin
  m    = Sketchup.active_model
  ce   = UCON::CabinetEngine
  dict = ce::Contract::DICTIONARY
  mm   = ->(v) { v.to_mm.round(1) }

  oak   = 'RR09 Rovere Nordico'
  black = 'LX19 Nero'

  mk = lambda do |name, rgb|
    mat = m.materials[name] || m.materials.add(name)
    mat.color = Sketchup::Color.new(*rgb)
    mat
  end
  mat_oak    = mk.call('UCON_Finish_RR09_Rovere_Nordico', [186, 151, 106])
  mat_black  = mk.call('UCON_Finish_LX19_Nero',            [31, 30, 32])
  mat_fumo   = mk.call('UCON_Finish_Grigio_Fumo',          [122, 117, 112])
  # Deliberately NOT the same black as LX19: one is a lacquered front, the other
  # anodised aluminium, and on an elevation they should be tellable apart.
  mat_alu    = mk.call('UCON_Finish_Aluminium_Black',      [44, 44, 47])
  # Opaque on purpose. Andriy, 2026-08-30: no transparency - a see-through pane
  # would show the unpainted inside and we would be back at the white we started
  # from. The fabric is lighter than the fronts so a vitrine reads as a vitrine.
  mat_fabric = mk.call('UCON_Finish_Glass_Oak_Fabric',     [205, 179, 142])

  rules = {
    'CARCASS'                 => mat_fumo,
    'PLINTH'                  => mat_alu,
    'FRONT (frame: DECLARED)' => mat_alu,
    'FRONT_GLASS'             => mat_fabric
  }
  front_names = %w[FRONT FRONT_1_FROM_BOTTOM FRONT_2_FROM_BOTTOM FRONT_3_FROM_BOTTOM
                   FRONT_1_OF_2 FRONT_2_OF_2 FILLER_8X8 PANEL].freeze
  # Named and left alone. A niche and a reservation are drawn, never ordered.
  inert = %w[APPLIANCE_OPENING_600 APPLIANCE_NICHE RUN_GAP WASTED_SPACE].freeze

  # code, x0, y0, z0, finish - the carcass box, as probe 105 measured it.
  plan = [
    # ---- EAST WALL, floor to 3040 - OAK ----
    ['C00151', 5587.5,  646.1,    0.0, oak], ['C92640', 5587.5, 1915.3,    0.0, oak],
    ['C90635', 5587.5, 2515.3,    0.0, oak], ['C90635', 5587.5, 3115.3,    0.0, oak],
    ['C90635', 5587.5, 3715.3,    0.0, oak], ['C90635', 5587.5, 4315.3,    0.0, oak],
    ['BE0151', 5587.5,  646.1, 2440.0, oak], ['SD0631', 5587.5,  695.3, 2440.0, oak],
    ['SD0631', 5587.5, 1305.3, 2440.0, oak], ['SD0631', 5587.5, 1915.3, 2440.0, oak],
    ['SD0631', 5587.5, 2515.3, 2440.0, oak], ['SD0631', 5587.5, 3115.3, 2440.0, oak],
    ['SD0631', 5587.5, 3715.3, 2440.0, oak], ['SD0631', 5587.5, 4315.3, 2440.0, oak],
    [nil,      5587.5,  695.3, 2127.0, oak],                    # UCON-BESP-001
    [nil,      5587.5,  695.3,  100.0, oak],                    # Sub-Zero fridge overlay
    [nil,      5587.5, 1428.8,  100.0, oak],                    # Sub-Zero freezer overlay
    [nil,      5587.5,  695.3, 1912.0, oak],                    # Sub-Zero grille overlay
    ['DV061Q', 5587.5, 4915.3,    0.0, oak], ['DV061Q', 5587.5, 4915.3, 2440.0, oak],
    # ---- ISLAND - OAK ----
    ['B80653', 1733.8, 1687.9,    0.0, oak], ['B80653', 2333.8, 1687.9,    0.0, oak],
    ['B80653', 2933.8, 1687.9,    0.0, oak], ['B80653', 3533.8, 1687.9,    0.0, oak],
    ['DV731Q', 1711.8, 1687.9,    0.0, oak], ['DV731Q', 4133.8, 1687.9,    0.0, oak],
    ['DZ731Q', 1733.8, 2332.9,    0.0, oak], ['DZ731Q', 1733.8, 2332.9,  764.0, oak],
    ['DZ731Q', 2933.8, 2332.9,    0.0, oak], ['DZ731Q', 2933.8, 2332.9,  764.0, oak],
    # ---- SOUTH UPPERS - OAK, the whole tier ----
    ['PF0151',    0.0,    0.0, 1480.0, oak], ['BE0151',    0.0,  598.0, 2440.0, oak],
    ['SD0631',  103.0,    0.0, 2440.0, oak], ['SD0631',  703.0,    0.0, 2440.0, oak],
    ['SD0631', 1303.0,    0.0, 2440.0, oak], ['SD0631', 1903.0,    0.0, 2440.0, oak],
    ['SD0631', 2513.0,    0.0, 2440.0, oak], ['SD0930', 3123.0,    0.0, 2440.0, oak],
    ['BE0151', 3893.0,  598.0, 2440.0, oak],
    # ASSUMED, and the one thing here nobody has decided: the two open shelves.
    # They are Linear Elements sold per linear metre, no finish block on printed
    # p.65 covers them, and Andriy painted the lower one oak by hand while
    # testing. Oak matches the tier they hang in. ONE WORD TO CHANGE.
    ['MNS040038', 3123.0, 0.0, 1720.0, oak], ['MNS040038', 3123.0, 0.0, 2040.0, oak],
    # ---- WEST RUN - BLACK ----
    ['AU110D',    0.0,    0.0,    0.0, black], ['B80565',    0.0, 1150.0,   0.0, black],
    ['B81087',    0.0, 1600.0,    0.0, black], ['V80630',  557.0, 2650.0,   0.0, black],
    ['B70501',  270.0, 3250.0,    0.0, black], ['B70150',  270.0, 3700.0,   0.0, black],
    # ---- SOUTH BASE RUN - BLACK ----
    ['B80501',  703.0,    0.0,    0.0, black], ['B80753', 1153.0,    0.0,   0.0, black],
    ['B80753', 3123.0,    0.0,    0.0, black], ['B70151', 3873.0,  557.0,   0.0, black],
    # ---- THE TWO CUSTOM BOXES OVER THE RANGE - BLACK, and the hood goes here ----
    ['SD0631', 1903.0,    0.0, 1720.0, black], ['SD0631', 2513.0,    0.0, 1720.0, black]
  ]

  tol = 0.6

  # ---- inventory, measured on the CARCASS box like probe 105 --------------
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
    objs << { e: e, dfn: dfn, code: cd.to_s, oc: oc.to_s,
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
  assigned = {}
  problems = []
  plan.each do |code, x, y, z, fin|
    hits = find.call(code, x, y, z)
    if hits.size == 1
      assigned[hits.first[:e].entityID] = fin
    else
      problems << "#{code || '(no code)'} @ #{x}/#{y}/#{z} matched #{hits.size}"
    end
  end

  # And the check run 107 should have had: is there a FRONT-family body anywhere
  # whose object was never given a finish? That is the AU110D defect generalised.
  objs.each do |o|
    next unless o[:dfn]
    next if assigned.key?(o[:e].entityID)
    o[:dfn].entities.each do |sub|
      next unless sub.is_a?(Sketchup::Group) || sub.is_a?(Sketchup::ComponentInstance)
      nm = sub.name.to_s
      nm = sub.definition.name.to_s if nm.empty? && sub.respond_to?(:definition)
      next if nm.upcase.start_with?('SYM_') || rules.key?(nm) || inert.include?(nm)
      next unless front_names.include?(nm) ||
                  (nm == 'CARCASS' && %w[panel shelf].include?(o[:oc]))
      problems << "#{o[:code]} @ #{o[:x]}/#{o[:y]}/#{o[:z]} has a #{nm} and no finish"
    end
  end

  unless problems.empty?
    puts 'REFUSED - nothing was painted:'
    problems.each { |p| puts "  #{p}" }
    raise 'the plan does not match the model'
  end

  # ---- paint ---------------------------------------------------------------
  painted   = Hash.new(0)
  untouched = Hash.new(0)

  faces_of = lambda do |ent|
    ent.respond_to?(:definition) ? ent.definition.entities.grep(Sketchup::Face) : ent.entities.grep(Sketchup::Face)
  end

  objs.each do |o|
    fin = assigned[o[:e].entityID]
    mat = (fin == oak ? mat_oak : (fin == black ? mat_black : nil))
    # The instance material is cleared on purpose. It renders only where a face
    # has none, which is exactly the ambiguity that let run 108 report success
    # over an unpainted body. After this, the FACE is the only carrier.
    o[:e].material = nil
    next unless o[:dfn]

    o[:dfn].entities.each do |sub|
      if sub.is_a?(Sketchup::Face)
        if mat
          sub.material = mat
          painted["#{fin} (bare face)"] += 1
        else
          untouched['bare face, object has no finish'] += 1
        end
        next
      end
      next unless sub.is_a?(Sketchup::Group) || sub.is_a?(Sketchup::ComponentInstance)
      nm = sub.name.to_s
      nm = sub.definition.name.to_s if nm.empty? && sub.respond_to?(:definition)
      next if nm.upcase.start_with?('SYM_')

      # A PANEL AND A SHELF HAVE NO CARCASS. The generator names every solid
      # body CARCASS, so DV731Q, DZ731Q, DV061Q and both MNS040038 shelves carry
      # a group by that name which IS the visible object - the island's two ends,
      # its whole back, and the tall run's end. Painting those Grigio Fumo would
      # have turned the oak half of the split grey, and the summary would have
      # said 312 faces painted and looked correct. Found by adding the numbers
      # up rather than by reading them.
      body_is_the_object = (nm == 'CARCASS' && %w[panel shelf].include?(o[:oc]))
      if (rm = rules[nm]) && !body_is_the_object
        sub.material = nil
        faces_of.call(sub).each { |f| f.material = rm }
        painted["#{nm} -> #{rm.name.sub('UCON_Finish_', '')}"] += faces_of.call(sub).size
      elsif front_names.include?(nm) || body_is_the_object
        sub.material = nil
        faces_of.call(sub).each { |f| f.material = mat }
        painted["#{nm} -> #{fin}"] += faces_of.call(sub).size
      else
        untouched[nm] += faces_of.call(sub).size
      end
    end
  end

  puts "core : #{ce.version_line rescue 'n/a'}"
  puts "== PAINTED, by what and how many faces =="
  painted.sort.each { |k, v| puts format("  %-46s %d", k, v) }
  puts ""
  puts "== LEFT ALONE (should be the niche and the reservation only) =="
  if untouched.empty?
    puts '  nothing'
  else
    untouched.sort.each { |k, v| puts format("  %-46s %d", k, v) }
  end
  puts ""
  puts "materials:"
  m.materials.each { |x| puts "  #{x.name}" if x.name.start_with?('UCON_Finish_') }
rescue Exception => e
  puts "PROBE FAILED: #{e.class}: #{e.message}"
  puts e.backtrace.first(12)
end

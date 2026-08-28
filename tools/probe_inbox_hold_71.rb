# ARMED. Run 71 - the island's six panels rebuilt in wood, at the seats they
# already occupy.
#
# THIS ONE APPLIES. Generator.build opens an operation of its own and the
# bridge's outer rollback closes with it, so nothing here is reversible. Arm the
# bridge first:  UCON::ProbeBridge.arm!
# Unarmed it will still apply, because the hole is Generator.build and not the
# arming flag - said out loud rather than relied on.
#
# WHY A PROBE AND NOT THE PICKER. Four of the six the engine can seat by itself;
# two it cannot. placement_transform puts a sheet on the FLOOR at a selected
# unit's origin, and it knows nothing about a second course above a breakfast
# top, nor about turning a board to finish an end. Those two rules do not exist
# and must not be invented from one kitchen. So the geometry and the attributes
# come from the engine - Generator.build makes every one of these - and only the
# SEAT is set here, from the coordinates probe run 56 measured off the boards
# Andriy had already placed. Nothing is invented; the panels do not move.
#
# WHAT CHANGES: the article, and the thickness that follows from it.
#   ends   DZAK22 (lacquer, gloss B, 2,2, two sides, 405) -> DV731Q  2,2 two sides, vertical grain, 549
#   backs  DZAK22                                          -> DZ731Q  1,8 ONE side, melamine reverse, vertical grain, 343
# and because the back is now 18 and not 22, the ends that WRAP its edge go
# from 667 to 663. Four millimetres, and they are the reason this is a rebuild
# and not an attribute edit.
#
# THE GROUP IS A - FIRST WOOD VENEERS, AND IT MOVED TWICE IN ONE DAY. 2026-08-28,
# and both moves are kept because the second is only legible against the first.
#
#   this probe was written assuming A, and nobody had ever confirmed it;
#   the letters were then given their names off printed p.217-220 and Andriy
#     chose B, Prime;
#   then the designer's render arrived and the kitchen is OAK - at which point
#     the groups stop being a price ladder and become a species list.
#
# GROUP A IS THE OAK GROUP: all seven First veneers are Rovere - Sbiancato,
# Nordico, Mediterraneo, Fossile, Dark, Corvino, Cortado - and the one-sided back
# and the two-sided end offer THE SAME SEVEN, so any of them matches across this
# island. Group B holds only two oaks that both sides can carry (Termocotto and
# Rigatino Sbiancato); its other seven oaks are all Trama and exist on the END
# ONLY. C and D contain no oak at all. And A is the cheaper of the two: 343/549
# against 358/579.
#
# So the original codes were right for the wrong reason, and are right again for
# the right one. THE FINISH NAME IS STILL UNCHOSEN and it is an ORDER field that
# changes no code here - which is exactly why nothing in this script can catch it.
begin
  m   = Sketchup.active_model
  ce  = UCON::CabinetEngine
  c   = ce::Contract
  reg = ce::Registry
  gen = ce::Generator
  mm  = ->(v) { v.to_mm }

  puts "core     : #{ce.version_line}"
  unless reg.respond_to?(:sheet_panel?)
    puts 'STALE CORE: Reload core, then re-drop.'
    raise 'stale core'
  end

  # ---- the plan, in world millimetres --------------------------------------
  # [code, W, H, origin x, y, z, rotation about z]
  PLAN = [
    ['DZ731Q', 1200, 722, 1733.8, 2332.9,   0.0,  0, 'back lower, left half'],
    ['DZ731Q', 1200, 722, 2933.8, 2332.9,   0.0,  0, 'back lower, right half'],
    ['DZ731Q', 1200, 116, 1733.8, 2332.9, 764.0,  0, 'back upper, left half'],
    ['DZ731Q', 1200, 116, 2933.8, 2332.9, 764.0,  0, 'back upper, right half'],
    ['DV731Q',  663, 880, 1733.8, 1687.9,   0.0, 90, 'end, left'],
    ['DV731Q',  663, 880, 4155.8, 1687.9,   0.0, 90, 'end, right']
  ].freeze

  host = m.entities.grep(Sketchup::ComponentInstance).select do |i|
    a = (c.read(i.definition) rescue nil)
    a && a['code'].to_s == 'B80653'
  end.min_by { |i| mm.call(i.transformation.origin.x) }
  unless host
    puts 'no B80653 to seat a panel against - stopping, nothing touched.'
    raise 'no host'
  end

  # ---- the old six, counted before anything is erased -----------------------
  old = m.entities.grep(Sketchup::ComponentInstance).select do |i|
    a = (c.read(i.definition) rescue nil)
    a && a['code'].to_s == 'DZAK22'
  end
  puts "found #{old.length} DZAK22 to replace"
  unless old.length == 6
    puts 'expected exactly 6 - the model is not what run 56 measured.'
    puts 'STOPPING, nothing erased and nothing built.'
    raise 'unexpected model'
  end

  m.start_operation('UCON: island panels in wood', true)
  old.each(&:erase!)
  puts 'erased the six lacquer panels'

  built = []
  PLAN.each do |code, w, h, x, y, z, rot, label|
    m.selection.clear
    m.selection.add(host)
    inst = gen.build(code, m, width_mm: w, height_mm: h)
    raise "build returned nothing for #{code}" unless inst

    t = Geom::Transformation.translation(Geom::Point3d.new(x.mm, y.mm, z.mm))
    t = t * Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0),
                                          Geom::Vector3d.new(0, 0, 1), rot.degrees) unless rot.zero?
    inst.transformation = t

    # THE OBJECT SAYS WHAT IS DECLARED AND WHAT IS MEASURED, as the run gap does.
    # A board standing at 764 is not on the floor, and `mounting` has exactly two
    # words - floor and wall_hung - neither of which is "on the breakfast top".
    # Recorded in notes rather than forced into an enum that has no room for it.
    if z.positive?
      a = c.read(inst.definition)
      note = "SECOND COURSE. Bottom at #{z.round} mm is a DECLARED datum - the top of the " \
             'breakfast surface at 762 (30 in) plus 2 of play - not the floor and not a ' \
             "wall. mounting still reads 'floor' because the contract has no third word; " \
             'the number here is the truth. Seated by build/71, not by any command.'
      c.write!(inst.definition, a.merge('notes' => [a['notes'], note].compact.join(' | ')))
    end
    inst.name = "Cesar #{code} — island #{label}"
    built << [code, label, inst]
    puts format('  built %-8s %4d x %-4d at (%.1f, %.1f, %.1f) rot %d  - %s',
                code, w, h, x, y, z, rot, label)
  end
  m.commit_operation

  puts ''
  puts '== as drawn =='
  built.each do |code, label, inst|
    lo = hi = nil
    inst.definition.entities.each do |e|
      next unless e.is_a?(Sketchup::Group)
      next if e.name.to_s.start_with?('SYM_')

      b = e.bounds
      8.times do |k|
        p = b.corner(k).transform(inst.transformation)
        v = [mm.call(p.x), mm.call(p.y), mm.call(p.z)]
        lo = lo ? [lo, v].transpose.map(&:min) : v
        hi = hi ? [hi, v].transpose.map(&:max) : v
      end
    end
    puts format('  %-8s %-22s x %8.1f..%8.1f  y %8.1f..%8.1f  z %7.1f..%7.1f',
                code, label, lo[0], hi[0], lo[1], hi[1], lo[2], hi[2])
  end
  puts ''
  puts 'APPLIED. Six wood panels; the six lacquer ones are gone.'
rescue StandardError => e
  puts "failed: #{e.class}: #{e.message}"
  puts e.backtrace.first(8)
  begin
    m.commit_operation
  rescue StandardError
    nil
  end
end

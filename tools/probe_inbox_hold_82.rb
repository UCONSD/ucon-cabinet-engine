# ARMED. Run 82 - the east wall's open end closed with two Volume 3 sheets.
#
# THIS ONE APPLIES. Generator.build opens an operation of its own and the
# bridge's outer rollback closes with it, so nothing here is reversible. Arm the
# bridge first:  UCON::ProbeBridge.arm!
# Unarmed it will still apply, because the hole is Generator.build and not the
# arming flag - said out loud rather than relied on.
#
# WHY A PROBE AND NOT THE PICKER. The engine seats a sheet BEHIND a run - that is
# what placement_transform and sheet_ground do, and the registry's own
# buildable_note says so. It has no rule for finishing an END, and one kitchen is
# not enough to invent one (the island's two ends were seated by run 71 for the
# same reason). So the geometry and the attributes come from the engine and only
# the SEAT is set here, from what probe run 81 measured.
#
# WHAT IS MEASURED, off run 81:
#   the last C90635  carcass x 5612,5..6232,5   y 4315,3..4915,3   z  100..2440
#   the SD0631 above carcass x 5612,5..6232,5   y 4315,3..4915,3   z 2440..3040
#   the door face                x 5587,5       (the run's front plane)
# so the end spans x 5587,5..6232,5 = 645 - which is exactly the d. 64,5 Volume 2
# prints for a 62-cm carcass, arrived at from the model and not copied from it.
#
# THE SPLIT IS ANDRIY'S, 2026-08-28: two sheets, joint at 2440, where the real
# joint between the two carcasses already is. Floor to top is 3040 and NO sheet in
# the chapter exceeds 3000 in any axis, so one board was never possible.
#
# THE ARTICLE, AND THE PART OF IT THAT IS A READING:
#   DV061Q - 2,2 thick, veneered on TWO sides, group A First, HORIZONTAL grain.
#   2,2 and two sides to match the island's ends. Group A because the kitchen is
#   OAK and A is the oak group - all seven First veneers are Rovere, and back and
#   end offer the same seven. HORIZONTAL because the grain has to run UP a 2440 board and a
#   vertical-grain article caps its grain axis at 1200 (printed p.220's glyph runs
#   along the 120). So it is ordered 2440 wide x 645 high and stood on its side.
#   THAT LAST STEP IS ELDA Q26 AND IS NOT SETTLED. If she reads height as the
#   installed height, this end cannot be veneer at all and these two rows change.
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

  # THE SEAT, AND WHY IT IS A ROTATION ABOUT Y AND NOT A YAW.
  #
  # 60_generator.rb:642 boxes a panel as (0, front_y, z0) by (w, d, h) - w along
  # its own X, thickness along Y, h along Z - and panel_front_y_mm returns 0 for a
  # sheet. So DV061Q ordered 2440 x 645 is DRAWN LYING DOWN: 2440 along x, 645
  # along z, 22 thick.
  #
  # This end needs 645 along the world x (door face 5587,5 to wall 6232,5), 22
  # along y, and 2440 up the world z. That is the board's own x becoming world z
  # and its own z becoming world -x: a rotation about the Y AXIS of -90 degrees,
  # not a yaw. Every other seat in this project has been a yaw, which is exactly
  # why this one is written out rather than copied.
  #
  #   -90 about Y:  local x -> +z        local z -> -x
  #   so the origin goes at the WALL end, x 6232,5, and the board runs back to
  #   5587,5 as its own z grows.
  #
  # AND THE ORDER COULD NOT HAVE BEEN WRITTEN THE OTHER WAY ROUND. The engine
  # refuses 645 x 2440 in as many words - "DV061Q is cut from a sheet 1200 mm on
  # that axis; 2440 does not come out of it" - because the article's height range
  # is 1..1200. The rotation is not a convenience; it is the only way this board
  # exists. Elda Q26 is whether that is a legitimate order.
  #
  # [code, ordered W, ordered H, origin x, y, z, label, expected world box]
  PLAN = [
    ['DV061Q', 2440, 645, 6232.5, 4915.3,    0.0, 'end, lower - floor to the top of the tall unit',
     [5587.5, 6232.5, 4915.3, 4937.3, 0.0, 2440.0]],
    ['DV061Q',  600, 645, 6232.5, 4915.3, 2440.0, 'end, upper - the top element',
     [5587.5, 6232.5, 4915.3, 4937.3, 2440.0, 3040.0]]
  ].freeze

  ROT = Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0),
                                      Geom::Vector3d.new(0, 1, 0), -90.degrees)

  host = m.entities.grep(Sketchup::ComponentInstance).find do |i|
    a = (c.read(i.definition) rescue nil)
    a && a['code'].to_s == 'C90635' && mm.call(i.bounds.max.y) > 4900
  end
  unless host
    puts 'the last C90635 at the open end was not found - stopping, nothing touched.'
    raise 'no host'
  end
  puts "host: #{host.name}"

  existing = m.entities.grep(Sketchup::ComponentInstance).select do |i|
    a = (c.read(i.definition) rescue nil)
    a && a['code'].to_s == 'DV061Q'
  end
  unless existing.empty?
    puts "#{existing.length} DV061Q already in the model - this has run before."
    puts 'STOPPING, nothing built.'
    raise 'already run'
  end

  # ONE AT A TIME, AND THE FIRST IS CHECKED BEFORE THE SECOND IS BUILT.
  # Generator.build commits its own operation, so nothing here can be rolled
  # back; the most this script can do is stop after ONE wrong object instead of
  # two. That is worth the extra lines.
  def box_of(inst, mm)
    lo = hi = nil
    inst.definition.entities.each do |e|
      next unless e.is_a?(Sketchup::Group)
      next if e.name.to_s.start_with?('SYM_')

      8.times do |k|
        p = e.bounds.corner(k).transform(inst.transformation)
        v = [mm.call(p.x), mm.call(p.y), mm.call(p.z)]
        lo = lo ? [lo, v].transpose.map(&:min) : v
        hi = hi ? [hi, v].transpose.map(&:max) : v
      end
    end
    [lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]]
  end

  m.start_operation('UCON: east wall end panels', true)
  built = []
  PLAN.each_with_index do |(code, w, h, x, y, z, label, want), n|
    m.selection.clear
    m.selection.add(host)
    inst = gen.build(code, m, width_mm: w, height_mm: h)
    raise "build returned nothing for #{code}" unless inst

    t = Geom::Transformation.translation(Geom::Point3d.new(x.mm, y.mm, z.mm)) * ROT
    inst.transformation = t

    got = box_of(inst, mm)
    off = got.each_with_index.map { |v, i| (v - want[i]).abs }.max
    puts format('  %-8s %-46s box x %.1f..%.1f y %.1f..%.1f z %.1f..%.1f  (worst error %.2f)',
                code, label, *got, off)
    if off > 0.5
      puts ''
      puts "  THE FIRST BOARD DID NOT LAND WHERE IT WAS MEASURED TO GO."
      puts "  wanted x %.1f..%.1f y %.1f..%.1f z %.1f..%.1f" % want
      puts '  STOPPING. One object is in the model and must be deleted by hand;'
      puts '  the second was not built. The rotation is wrong, not the seat.'
      m.commit_operation
      raise 'seat check failed'
    end
    a = c.read(inst.definition)
    note = "END OF RUN, seated by build/82 from run 81's measurement - no command in " \
           "the engine seats a sheet at an END, only behind a run. Spans the finished " \
           "end: 645 from the door face at 5587,5 to the wall at 6232,5, which is the " \
           "d. 64,5 Volume 2 prints for a 62-cm carcass, reached from the model. " \
           "ORDERED #{w} x #{h}; INSTALLED with the #{w} standing vertical, so the " \
           "horizontal-grain article's grain runs UP the panel - ELDA Q26, unsettled."
    c.write!(inst.definition, a.merge('notes' => [a['notes'], note].compact.join(' | ')))
    inst.name = "Cesar #{code} — east end #{label}"
    built << [code, label, inst]
  end
  m.commit_operation

  puts ''
  puts '== as drawn =='
  built.each do |code, label, inst|
    lo = hi = nil
    inst.definition.entities.each do |e|
      next unless e.is_a?(Sketchup::Group)
      next if e.name.to_s.start_with?('SYM_')

      8.times do |k|
        p = e.bounds.corner(k).transform(inst.transformation)
        v = [mm.call(p.x), mm.call(p.y), mm.call(p.z)]
        lo = lo ? [lo, v].transpose.map(&:min) : v
        hi = hi ? [hi, v].transpose.map(&:max) : v
      end
    end
    puts format('  %-8s %-46s x %8.1f..%8.1f  y %8.1f..%8.1f  z %7.1f..%7.1f',
                code, label, lo[0], hi[0], lo[1], hi[1], lo[2], hi[2])
  end
  puts ''
  puts 'APPLIED. Check the two boards stand at x 5587,5..6232,5 and meet at z 2440.'
  puts 'If they do not, the seat needs a yaw and this run must be undone by hand.'
rescue StandardError => e
  puts "failed: #{e.class}: #{e.message}"
  puts e.backtrace.first(8)
  begin
    m.commit_operation
  rescue StandardError
    nil
  end
end

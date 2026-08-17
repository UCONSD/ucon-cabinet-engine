# frozen_string_literal: true
#
# UCON — corner probe (SCRATCH, not part of the engine)
#
# Built step by step from Andriy's dictation, now generalised to the whole
# corner block: all nine codes of printed p.42, either hand, either door
# version. Touches nothing in core/ and writes no Contract attributes.
#
#   load '/Users/andriydemko/dev/ucon-cabinet-engine/tools/corner_probe.rb'
#
#   UCON_CornerProbe.build                             # door left, hinge outer, 78
#   UCON_CornerProbe.build('AU110D/S', hand: :right)   # mirrored cabinet
#   UCON_CornerProbe.build('AU110D/S', hinge: :corner) # other hinge side
#   UCON_CornerProbe.build('AW125D/S', door: 75)       # gola version
#   UCON_CornerProbe.build_four                        # one size, all 4 combos
#   UCON_CornerProbe.build_all                         # all nine, side by side
#   UCON_CornerProbe.build_u_kitchen                   # a U: two corners, mirrored
#   UCON_CornerProbe.report                            # positions in mm
#
# Axes: the carcass starts at x_offset, its rear face on y = 0, the front
# faces -Y, z is up from the floor.
#
# THE RULES, as dictated:
#   carcass — carcass length x depth x 780, on the standard plinth
#   door    — on the chosen hand, 22 thick; its height follows the door
#             version (78 -> 780, 75 -> 750), exactly like every other unit
#   8x8     — ONE solid L, both legs 80 long and 22 thick, standing beside the
#             door on the CORNER side; its height follows the door
#   wasted  — the nominal W from the catalog minus the carcass length, on the
#             corner side past the carcass: edges only, no faces, its own tag,
#             because it is space to keep free, not something we sell
#   symbol  — dashed V, base on the hinge axis, apex on the opening edge
#
# TWO INDEPENDENT AXES, and they are not the same thing:
#
#   hand  — the MIRRORED CABINET. Which end carries the door and the 8x8, and
#           which end is blind with the wasted space behind it. This is inside
#           the article: AU110D against AU110S. It changes the order line.
#   hinge — which vertical edge of that door carries the hinges. This is the
#           ordinary per-order hinge_side, outside the code, exactly as on a
#           straight unit. It changes nothing in the order line.
#
# So a corner unit is fully specified by a code AND an axis, four combinations
# per size. Pass hinge: :outer (away from the corner) or :corner, or name the
# edge absolutely with :left / :right.
#
# ALSO UNCONFIRMED: which letter is which. D/S is Destra / Sinistra, but
# whether D means the door sits right or hinges right is not established, so
# the probe speaks :left / :right and never prints a letter.
#
# WHY THE HAND IS THE ARTICLE, NOT AN AXIS ON TOP OF IT: a corner carcass is
# not symmetric. Door and 8x8 sit at one end, blind carcass and wasted space at
# the other. A straight unit can be ordered once and hung either way, so
# hinge_side is a per-order axis; a corner unit cannot — turning it 180 degrees
# puts its front against the wall. Only a mirror image works, and the mirror is
# a different execution of the code. A U-shaped kitchen proves it: two corners,
# one article, both letters. See build_u_kitchen.

module UCON_CornerProbe
  # code => [depth, door width, carcass length, nominal W along the wall]
  # all in mm, printed p.42 / PDF 44
  ROWS = {
    'B7091D/S' => [350, 300,  900, 1000],
    'B7110D/S' => [350, 450,  900, 1150],
    'B7125D/S' => [350, 600, 1200, 1300],
    'AU090D/S' => [620, 300,  900, 1000],
    'AU110D/S' => [620, 450,  900, 1150],
    'AU125D/S' => [620, 600, 1200, 1300],
    'AW090D/S' => [670, 300,  900, 1050],
    'AW110D/S' => [670, 450,  900, 1200],
    'AW125D/S' => [670, 600, 1200, 1350]
  }.freeze

  HEIGHT_MM         = 780
  FILLER_MM         =  80
  FRONT_T_MM        =  22
  FRONT_GAP_MM      =   3
  PLINTH_H_MM       = 100
  PLINTH_T_MM       =  18
  PLINTH_SETBACK_MM =  45

  PREFIX     = 'UCON_PROBE'
  WASTED_TAG = 'UCON — Wasted space'
  SYMBOL_TAG = 'UCON — Opening (probe)'
  PLAN_Z_MM  = 1

  module_function

  def model
    Sketchup.active_model
  end

  def mat(name, rgb)
    m = model.materials[name] || model.materials.add(name)
    m.color = Sketchup::Color.new(*rgb)
    m
  end

  def tag(name, dashed: false)
    layer = model.layers[name] || model.layers.add(name)
    if dashed && layer.respond_to?(:line_style=) && model.respond_to?(:line_styles)
      dash = model.line_styles['Dash']
      layer.line_style = dash if dash
    end
    layer
  end

  # Solid part from a plan polygon, extruded up.
  def ents
    @ents || model.active_entities
  end

  def prism(name, plan_pts, z, h, rgb)
    g = ents.add_group
    g.name = "#{PREFIX}_#{name}"
    f = g.entities.add_face(plan_pts.map { |p| [p[0].mm, p[1].mm, z.mm] })
    f.reverse! if f.normal.z < 0
    f.pushpull(h.mm)
    g.material = mat("#{PREFIX}_#{name}", rgb)
    g
  end

  def box(name, x, y, z, w, d, h, rgb)
    prism(name, [[x, y], [x + w, y], [x + w, y + d], [x, y + d]], z, h, rgb)
  end

  # Edges only: a volume that must stay free is not a thing we sell.
  def wire_box(name, x, y, z, w, d, h, rgb, layer)
    g = box(name, x, y, z, w, d, h, rgb)
    g.entities.grep(Sketchup::Face).each(&:erase!)
    m = mat("#{PREFIX}_#{name}", rgb)
    g.entities.grep(Sketchup::Edge).each { |e| e.material = m }
    g.layer = layer
    g.entities.grep(Sketchup::Edge).each { |e| e.layer = layer }
    g
  end

  def lines(name, segs, rgb, layer)
    g = ents.add_group
    g.name = "#{PREFIX}_#{name}"
    m = mat("#{PREFIX}_#{name}", rgb)
    segs.each do |a, b|
      e = g.entities.add_line([a[0].mm, a[1].mm, a[2].mm], [b[0].mm, b[1].mm, b[2].mm])
      e.material = m
    end
    g.entities.grep(Sketchup::Face).each(&:erase!)
    g.layer = layer
    g.entities.grep(Sketchup::Edge).each { |e| e.layer = layer }
    g
  end

  def clear
    doomed = model.active_entities.grep(Sketchup::Group)
                  .select { |g| g.name.to_s.start_with?(PREFIX) }
    model.active_entities.erase_entities(doomed) unless doomed.empty?
    doomed.length
  end

  # One corner unit. hand: :left or :right is the side the DOOR is on; the 8x8
  # and the wasted space are always on the other side, which is the corner.
  def one(code, hand: :left, hinge: :outer, door: 78, x_offset: 0)
    container = model.active_entities.add_group
    container.name = "#{PREFIX}_UNIT_#{code.sub('/', '_')}_#{hand}"
    prev = @ents
    @ents = container.entities
    depth, door_mm, carcass, nominal = ROWS.fetch(code)
    front_h = door == 75 ? HEIGHT_MM - 30 : HEIGHT_MM
    wasted  = nominal - carcass
    z0      = PLINTH_H_MM
    front_y = -(FRONT_GAP_MM + FRONT_T_MM)   # -25, outer face of the front
    back_y  = front_y + FRONT_T_MM           #  -3, back face of the front
    out_y   = back_y - FILLER_MM             # -83, outer face of the 8x8
    sfx     = "#{code.sub('/', '_')}_#{hand}_h#{hinge}_#{door}"

    box("CARCASS_#{sfx}", x_offset, 0, z0, carcass, depth, HEIGHT_MM, [220, 220, 216])
    box("PLINTH_#{sfx}", x_offset, PLINTH_SETBACK_MM, 0,
        carcass, PLINTH_T_MM, PLINTH_H_MM, [245, 245, 245])

    if hand == :left
      door_x   = x_offset
      fill_l   = door_x + door_mm            # 8x8 occupies fill_l .. fill_l+80
      out_x    = fill_l + FILLER_MM          # its outer face, toward the corner
      in_x     = out_x - FRONT_T_MM
      wasted_x = x_offset + carcass          # corner side is the right
      outer_edge  = door_x                   # away from the corner
      corner_edge = door_x + door_mm
      plan = [[fill_l, back_y], [out_x, back_y], [out_x, out_y],
              [in_x, out_y], [in_x, front_y], [fill_l, front_y]]
    else
      door_x   = x_offset + carcass - door_mm
      fill_l   = door_x - FILLER_MM
      out_x    = fill_l                      # outer face toward the corner
      in_x     = out_x + FRONT_T_MM
      wasted_x = x_offset - wasted           # corner side is the left
      outer_edge  = door_x + door_mm
      corner_edge = door_x
      plan = [[fill_l + FILLER_MM, back_y], [out_x, back_y], [out_x, out_y],
              [in_x, out_y], [in_x, front_y], [fill_l + FILLER_MM, front_y]]
    end

    # The hinge is its own choice, independent of the cabinet's hand.
    hinge_x =
      case hinge
      when :outer  then outer_edge
      when :corner then corner_edge
      when :left   then door_x
      when :right  then door_x + door_mm
      else raise ArgumentError, "hinge must be :outer, :corner, :left or :right"
      end
    open_x   = hinge_x == door_x ? door_x + door_mm : door_x
    swing_to = [hinge_x, front_y - door_mm]

    box("DOOR_#{sfx}", door_x, front_y, z0, door_mm, FRONT_T_MM, front_h, [245, 245, 245])
    prism("FILLER_8x8_#{sfx}", plan, z0, front_h, [235, 235, 240])

    if wasted.positive?
      wire_box("WASTED_#{wasted}_#{sfx}", wasted_x, 0, z0, wasted, depth, HEIGHT_MM,
               [138, 138, 138], tag(WASTED_TAG))
    end

    sym  = tag(SYMBOL_TAG, dashed: true)
    apex = [open_x, front_y, z0 + front_h / 2.0]
    lines("SYM_FRONT_#{sfx}",
          [[[hinge_x, front_y, z0], apex],
           [[hinge_x, front_y, z0 + front_h], apex]],
          [128, 128, 128], sym)

    # Plan: the leaf swung 90 degrees off the hinge, drawn at floor level.
    lines("SYM_PLAN_#{sfx}",
          [[[hinge_x, front_y, PLAN_Z_MM], [swing_to[0], swing_to[1], PLAN_Z_MM]],
           [[swing_to[0], swing_to[1], PLAN_Z_MM],
            [swing_to[0] + (hand == :left ? FRONT_T_MM : -FRONT_T_MM), swing_to[1], PLAN_Z_MM]]],
          [128, 128, 128], sym)

    @ents = prev
    { code: code, hand: hand, hinge: hinge, door: door, depth: depth,
      door_mm: door_mm, carcass: carcass, nominal: nominal, wasted: wasted,
      front_h: front_h, hinge_edge: (hinge_x == door_x ? :left : :right),
      group: container }
  end

  # A plain straight unit, only enough of one to read as a run.
  def plain(width, depth, x_offset: 0, door: 78)
    container = model.active_entities.add_group
    container.name = "#{PREFIX}_RUN_#{width}"
    prev = @ents
    @ents = container.entities
    front_h = door == 75 ? HEIGHT_MM - 30 : HEIGHT_MM
    box("CARCASS_run_#{x_offset}", x_offset, 0, PLINTH_H_MM, width, depth, HEIGHT_MM,
        [220, 220, 216])
    box("PLINTH_run_#{x_offset}", x_offset, PLINTH_SETBACK_MM, 0, width, PLINTH_T_MM,
        PLINTH_H_MM, [245, 245, 245])
    box("FRONT_run_#{x_offset}", x_offset, -(FRONT_GAP_MM + FRONT_T_MM), PLINTH_H_MM,
        width, FRONT_T_MM, front_h, [245, 245, 245])
    @ents = prev
    container
  end

  def build(code = 'AU110D/S', hand: :left, hinge: :outer, door: 78)
    model.start_operation('UCON corner probe', true)
    info = nil
    begin
      clear
      info = one(code, hand: hand, hinge: hinge, door: door)
      model.commit_operation
    rescue StandardError => e
      model.abort_operation
      raise e
    end
    puts summary([info])
    nil
  end

  # All nine side by side, so the whole block can be judged at once.
  def build_all(hand: :left, hinge: :outer, door: 78, gap_mm: 400)
    model.start_operation('UCON corner probe (all)', true)
    infos = []
    begin
      clear
      x = 0
      ROWS.each_key do |code|
        infos << one(code, hand: hand, hinge: hinge, door: door, x_offset: x)
        x += ROWS[code][3] + gap_mm
      end
      model.commit_operation
    rescue StandardError => e
      model.abort_operation
      raise e
    end
    puts summary(infos)
    nil
  end

  # One size, all FOUR combinations: two hands x two hinge sides. This is the
  # picture that settles what is in the article and what is beside it.
  def build_four(code = 'AU110D/S', door: 78, gap_mm: 500)
    _d, _dr, _ca, nominal = ROWS.fetch(code)
    model.start_operation('UCON corner probe (four)', true)
    infos = []
    begin
      clear
      x = 0
      [[:left, :outer], [:left, :corner], [:right, :outer], [:right, :corner]].each do |hand, hinge|
        infos << one(code, hand: hand, hinge: hinge, door: door, x_offset: x)
        x += nominal + gap_mm
      end
      model.commit_operation
    rescue StandardError => e
      model.abort_operation
      raise e
    end
    puts summary(infos)
    nil
  end

  # A U-shaped kitchen: one back run between two corners, and a leg off each
  # corner. The two corners are the SAME article in opposite hands — that is
  # the whole point of the exercise. Nothing here is placement logic for the
  # engine; it is a demonstration.
  def build_u_kitchen(code: 'AU110D/S', hinge: :outer, door: 78,
                      back_len: 4200, leg_len: 2400, run_w: 600)
    depth, _door_mm, carcass, nominal = ROWS.fetch(code)
    leg_b = depth + FILLER_MM        # what the node occupies along the side wall
    model.start_operation('UCON U kitchen probe', true)
    begin
      clear

      # LEFT corner: the corner is at the left, so the door is on the right.
      one(code, hand: :right, hinge: hinge, door: door, x_offset: nominal - carcass)

      # RIGHT corner: mirror image, same article, other hand.
      one(code, hand: :left, hinge: hinge, door: door, x_offset: back_len - nominal)

      # Back run between the two corners.
      x = nominal
      while x + run_w <= back_len - nominal
        plain(run_w, depth, x_offset: x, door: door)
        x += run_w
      end

      # Left leg: rotated a quarter turn about the left corner point, so its
      # fronts face into the room. It starts leg_b from the back wall.
      rot_l = Geom::Transformation.rotation(ORIGIN, Z_AXIS, -90.degrees)
      y = leg_b
      while y + run_w <= leg_len
        g = plain(run_w, depth, x_offset: y, door: door)
        g.transform!(rot_l)
        y += run_w
      end

      # Right leg: the same, mirrored about the far end of the back run.
      rot_r = Geom::Transformation.rotation(Geom::Point3d.new(back_len.mm, 0, 0),
                                            Z_AXIS, 90.degrees)
      y = leg_b
      while y + run_w <= leg_len
        g = plain(run_w, depth, x_offset: -(y + run_w), door: door)
        g.transform!(rot_r)
        y += run_w
      end

      model.commit_operation
    rescue StandardError => e
      model.abort_operation
      raise e
    end

    puts <<~TXT

      U kitchen — #{code}, door #{door}
      back run #{back_len}, legs #{leg_len}, node #{nominal} x #{leg_b}
      LEFT corner  : hand right (door on the right, corner and wasted space on the left)
      RIGHT corner : hand left  (mirror image, SAME article, other letter)
      hinge #{hinge} on both — the hinge side is a SEPARATE choice and does not
      change the code; the hand does.

    TXT
    nil
  end

  def summary(infos)
    out = +"\nUCON corner probe\n"
    out << format("%-11s %6s %7s %6s %5s %8s %8s %7s %6s\n",
                  'code', 'hand', 'hinge', 'edge', 'door', 'carcass', 'nominal', 'wasted', 'front')
    infos.each do |i|
      out << format("%-11s %6s %7s %6s %5s %8d %8d %7d %6d\n",
                    i[:code], i[:hand], i[:hinge], i[:hinge_edge], i[:door],
                    i[:carcass], i[:nominal], i[:wasted], i[:front_h])
    end
    out << "\nwasted space sits on the corner side past the carcass — tag '#{WASTED_TAG}'\n"
    out << "hand = the mirrored article (D/S, in the code); hinge = the per-order axis (rh/lh)\n\n"
    out
  end

  def report
    rows = model.active_entities.grep(Sketchup::Group)
                .select { |g| g.name.to_s.start_with?(PREFIX) }
                .sort_by { |g| g.name.to_s }
    if rows.empty?
      puts 'No probe groups found — run UCON_CornerProbe.build first.'
      return nil
    end
    puts "\nprobe positions, mm"
    puts format('%-46s %8s %8s %8s   %8s %8s %8s', 'part', 'x0', 'y0', 'z0', 'dx', 'dy', 'dz')
    rows.each do |g|
      b = g.bounds
      puts format('%-46s %8.0f %8.0f %8.0f   %8.0f %8.0f %8.0f',
                  g.name.to_s.sub("#{PREFIX}_", ''),
                  b.min.x.to_mm, b.min.y.to_mm, b.min.z.to_mm,
                  b.width.to_mm, b.height.to_mm, b.depth.to_mm)
    end
    puts
    nil
  end
end

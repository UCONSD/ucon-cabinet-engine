# frozen_string_literal: true
#
# UCON Cabinet Engine — core/70_symbols.rb
#
# Dashed opening symbols on three hideable tags. The first two are FLAT
# CONVENTIONS — abstractions that live in one view and say what a door does.
# The third is not a convention at all: it is the front itself, dashed, where
# it ends up. That distinction is the reason there are three and not two.
#
#   TAG_FRONT — elevation: dashed V per door leaf (base at the hinge edge,
#               apex at the opening edge); one diagonal per drawer front,
#               top-left to bottom-right (UCON convention).
#   TAG_PLAN  — plan: door leaf as the real 22 mm slab open at
#               DOOR_OPEN_ANGLE_DEG plus the swing arc; drawer as two runner
#               lines inset RUNNER_INSET_MM plus the 22 mm front slab at the
#               full-extension travel (user-provided Blum table).
#               No dashed line along the facade itself.
#
# Appearance: all symbol edges carry the UCON_Symbol_Gray material and the
# model's edge color mode is switched to by-material, so symbols render gray
# while ordinary edges (no material) stay the style foreground color.
# Line WIDTH is a style property in SketchUp — free edges draw at Profiles
# width; the palette's "Thin lines" button toggles Profiles for the model.
#
# Tags get the native "Dash" line style (SketchUp 2019+). Symbols live INSIDE
# the unit definition, so they move with the instance. Groups are named SYM_*
# and are wiped before redraw — idempotent.

module UCON
  module CabinetEngine
    module Symbols
      TAG_FRONT = 'UCON — Opening (front)'
      TAG_PLAN  = 'UCON — Opening (plan)'
      # The open leaf in space. Not a symbol: real geometry, true in EVERY
      # view including iso and section, which is why push-up gets one at all.
      # A push-up leaf has no hinge axis, so no elevation V can describe it and
      # this is the only honest thing that can be drawn for it.
      TAG_DOOR  = 'UCON — Opening (door)'

      # How far a plan symbol sits above the bottom of ITS OWN ROW. Not above
      # the floor: that was the rule while every unit stood on the floor, and
      # it broke the moment a second row existed — a base unit and the wall
      # unit above it drew their swing arcs on the same millimetre, and the
      # hung unit's bounding box hung down to the floor to reach its own
      # symbol. Just above the row's bottom keeps the original reason intact
      # (under the section cut that shows that row, read against its footprint)
      # and lets the two rows be told apart. The datum comes from
      # Generator.row_datum_mm — asked, never worked out again here.
      PLAN_Z_MM = 1

      # Plan symbol: drawer runner lines drawn inset from the unit sides.
      RUNNER_INSET_MM = 25

      # Plan symbol: doors drawn open at this angle, not fully at 90.
      DOOR_OPEN_ANGLE_DEG = 85

      # GLASS, THE WAY A DRAFTSMAN DRAWS IT. Pairs of parallel 45 degree lines
      # across the pane. Pairs and not singles because that is the convention
      # on the drawings this engine has to sit beside, and one lone diagonal
      # reads as a section cut instead. Drawing choices, like the 85 above -
      # no catalog states them and none ever will.
      HATCH_ANGLE_DEG   = 45
      HATCH_SPACING_MM  = 250
      HATCH_PAIR_GAP_MM = 25

      SYMBOL_RGB = [128, 128, 128].freeze

      module_function

      # Palette-driven visibility: plan views want only the plan tag,
      # elevations only the front tag. mode: :plan | :front | :off | :all
      def show_mode(model, mode)
        front = tag(model, TAG_FRONT)
        plan  = tag(model, TAG_PLAN)
        door  = tag(model, TAG_DOOR)
        front.visible = %i[front all].include?(mode)
        plan.visible  = %i[plan all].include?(mode)
        door.visible  = %i[door all].include?(mode)
        model.active_view.invalidate
        mode
      end

      # Style-level line weight: free edges render at Profiles width, so the
      # one-click way to thin the symbols (and the whole drawing) is toggling
      # Profiles. Returns the new state.
      def toggle_thin_lines(model)
        ro = model.rendering_options
        ro['DrawSilhouettes'] = !ro['DrawSilhouettes']
        model.active_view.invalidate
        ro['DrawSilhouettes'] ? 'profiles ON (thick)' : 'profiles OFF (thin)'
      end

      def tag(model, name)
        layer = model.layers[name] || model.layers.add(name)
        if layer.respond_to?(:line_style=) && model.respond_to?(:line_styles)
          dash = model.line_styles['Dash']
          layer.line_style = dash if dash && layer.line_style != dash
        end
        layer
      end

      def symbol_material(model)
        Geometry.material(model, 'UCON_Symbol_Gray', SYMBOL_RGB)
      end

      # Symbols render gray only when edge color mode is by-material (0).
      # Ordinary edges carry no material and keep the foreground color.
      def enable_material_edges(model)
        model.rendering_options['EdgeColorMode'] = 0
      rescue StandardError
        nil
      end

      # Assign tag + gray material to a finished symbol group.
      def finalize(group, layer, mat)
        group.layer = layer
        group.entities.grep(Sketchup::Edge).each do |ed|
          ed.layer    = layer
          ed.material = mat
        end
      end

      # Pure geometry of a corner unit's door symbol. The door is only part of
      # the front, so the V is drawn on the door's own rectangle, not on the
      # carcass. hinge_side is the ordinary per-order axis — the execution
      # letter of the code decides WHERE the door is, this decides which edge
      # it turns on.
      def corner_door_marks(door_x_mm, door_w_mm, z0_mm, door_h_mm, y_face_mm, hinge_side)
        left_edge  = door_x_mm.to_f
        right_edge = door_x_mm + door_w_mm.to_f
        hinge_x    = hinge_side == 'lh' ? left_edge : right_edge
        open_x     = hinge_side == 'lh' ? right_edge : left_edge
        apex = [open_x, y_face_mm, z0_mm + door_h_mm / 2.0]
        {
          front: [
            [[hinge_x, y_face_mm, z0_mm], apex],
            [[hinge_x, y_face_mm, z0_mm + door_h_mm], apex]
          ],
          plan_leaf: [[hinge_x, y_face_mm], [hinge_x, y_face_mm - door_w_mm]]
        }
      end

      # Pure geometry of the bottom-hung symbol, in mm, so the rule itself is
      # testable without SketchUp: the renderer only draws what this returns.
      #
      #   :front     — two lines from the bottom corners to the top mid-point
      #                (base on the hinge axis, apex at the opening edge)
      #   :plan_rect — the leaf fallen to horizontal: the front width by its own
      #                height, projecting forward from the front face
      def bottom_hung_marks(width_mm, z0_mm, door_h_mm, y_face_mm)
        hung_marks(width_mm, z0_mm, door_h_mm, y_face_mm, 'bottom')
      end

      # The mirror, and nothing more. A top-hung door hangs on its TOP edge, so
      # the base of the figure moves to the top edge and the apex drops to the
      # opening edge below: the same rule read the other way up, an inverted
      # Λ rather than a new symbol.
      #
      # The PLAN is identical for both, and deliberately so: the rectangle is
      # the footprint the leaf sweeps through on its way to horizontal. A
      # bottom-hung leaf ends horizontal below, a top-hung one ends horizontal
      # above, and both pass through exactly the same forward projection - the
      # front width by the front's own height. One rule, one rectangle.
      def top_hung_marks(width_mm, z0_mm, door_h_mm, y_face_mm)
        hung_marks(width_mm, z0_mm, door_h_mm, y_face_mm, 'top')
      end

      def hung_marks(width_mm, z0_mm, door_h_mm, y_face_mm, axis)
        hinge_z = axis == 'top' ? z0_mm + door_h_mm : z0_mm
        apex_z  = axis == 'top' ? z0_mm : z0_mm + door_h_mm
        apex    = [width_mm / 2.0, y_face_mm, apex_z]
        {
          front: [
            [[0.0, y_face_mm, hinge_z], apex],
            [[width_mm.to_f, y_face_mm, hinge_z], apex]
          ],
          plan_rect: [
            [0.0, y_face_mm],
            [width_mm.to_f, y_face_mm],
            [width_mm.to_f, y_face_mm - door_h_mm],
            [0.0, y_face_mm - door_h_mm]
          ]
        }
      end

      # Closed dashed rectangle at height z; the auto-created face is erased
      # so plans get four lines, not a fill.
      # The hatch, in the pane's own rectangle, in millimetres. Pure: returns
      # [[x1, z1], [x2, z2]] pairs and touches nothing. A 45 degree line is
      # v = u + c in pane coordinates, so the whole job is choosing c and
      # clipping u to the pane - which is why this needs no trigonometry and
      # no SketchUp.
      def glass_hatch(x0_mm, z0_mm, w_mm, h_mm,
                      spacing_mm = HATCH_SPACING_MM, gap_mm = HATCH_PAIR_GAP_MM)
        out = []
        c = -w_mm.to_f
        while c < h_mm
          pair = [c, c + gap_mm].map do |cc|
            u_lo = [0.0, -cc].max
            u_hi = [w_mm.to_f, h_mm - cc].min
            next nil unless u_hi - u_lo > 0.5

            [[x0_mm + u_lo, z0_mm + u_lo + cc],
             [x0_mm + u_hi, z0_mm + u_hi + cc]]
          end
          # BOTH OR NEITHER. At the two corners one member of a pair clips away
          # entirely, and a single surviving diagonal is the very thing the
          # pairs exist to avoid being mistaken for.
          out.concat(pair) if pair.all?
          c += spacing_mm
        end
        out
      end

      # The pane outline plus its hatch, on the elevation tag.
      #
      # THE PANE ITSELF IS GEOMETRY AND LIVES IN THE FRONT, NOT HERE. That
      # split is the same one the three tags are built on: the thing that is
      # really there is modelled, the convention that describes it is a symbol.
      # So the glass stays visible when the elevation tag is off, and the
      # draftsman's hatch comes and goes with the rest of the elevation.
      def draw_glass_hatch(definition, unit, z0, y_face, layer, mat, slabs)
        (slabs || Generator.front_slabs(unit)).each_with_index do |slab, i|
          rails = Generator.cutout_rails(unit, slab)
          next unless rails

          x0 = slab[:x_mm] + rails[:left]
          zz = z0 + slab[:z_mm] + rails[:bottom]
          gw = slab[:w_mm] - rails[:left] - rails[:right]
          gh = slab[:h_mm] - rails[:bottom] - rails[:top]
          next unless gw > 0 && gh > 0

          g = definition.entities.add_group
          g.name = "SYM_FRONT_GLASS_#{i + 1}"
          rect = [[x0, zz], [x0 + gw, zz], [x0 + gw, zz + gh], [x0, zz + gh]]
          rect.each_index do |j|
            a = rect[j]
            b = rect[(j + 1) % rect.length]
            g.entities.add_line([a[0].mm, y_face.mm, a[1].mm],
                                [b[0].mm, y_face.mm, b[1].mm])
          end
          glass_hatch(x0, zz, gw, gh).each do |a, b|
            g.entities.add_line([a[0].mm, y_face.mm, a[1].mm],
                                [b[0].mm, y_face.mm, b[1].mm])
          end
          g.entities.grep(Sketchup::Face).each(&:erase!)
          finalize(g, layer, mat)
        end
      end

      def dashed_rect(group, corners, z)
        corners.each_index do |i|
          a = corners[i]
          b = corners[(i + 1) % corners.length]
          group.entities.add_line([a[0].mm, a[1].mm, z], [b[0].mm, b[1].mm, z])
        end
        group.entities.grep(Sketchup::Face).each(&:erase!)
      end

      # ---- the open leaf ---------------------------------------------------
      #
      # THE FRONT SLAB IS THE FRONT SLAB. Thickness is Standards::FRONT_T_MM,
      # the same 22 the closed front is built with — an open door that is a
      # different thickness from the same door closed would be the model
      # contradicting itself. If US fronts ever become 19, that is one change
      # in Standards and every front follows, this one included.

      # The open leaf's footprint in plan: the real front slab swung out by
      # DOOR_OPEN_ANGLE_DEG about its hinge edge, as four [x, y] pairs.
      # ONE definition, used by the plan symbol AND by the 3-D leaf, so the two
      # can never drift apart.
      def swing_quad(hinge_x, y_face, leaf_w, hinge, thickness)
        open_rad = DOOR_OPEN_ANGLE_DEG * Math::PI / 180
        u_ang = hinge == 'lh' ? -open_rad : Math::PI + open_rad
        v_ang = hinge == 'lh' ? u_ang + Math::PI / 2 : u_ang - Math::PI / 2
        ux = Math.cos(u_ang)
        uy = Math.sin(u_ang)
        vx = Math.cos(v_ang)
        vy = Math.sin(v_ang)
        t = thickness
        l = leaf_w
        [[hinge_x, y_face],
         [hinge_x + (t * vx), y_face + (t * vy)],
         [hinge_x + (t * vx) + (l * ux), y_face + (t * vy) + (l * uy)],
         [hinge_x + (l * ux), y_face + (l * uy)]]
      end

      # A leaf that swings about a VERTICAL edge: the plan quad lifted from
      # z_lo to z_hi. Returns two rings of four [x, y, z].
      def open_leaf_prism(quad, z_lo, z_hi)
        [quad.map { |x, y| [x, y, z_lo] }, quad.map { |x, y| [x, y, z_hi] }]
      end

      # A leaf that moves in the SIDE plane — hung, or a push-up mechanism.
      # upper and free are its two long edges as [y_mm, z_mm]; the slab is swept
      # across the width and thickened on the outer face. The normal (dz, -dy)
      # points away from the cabinet for every motion the catalog prints.
      def open_leaf_slab(width_mm, upper, free, thickness)
        dy  = free[0] - upper[0]
        dz  = free[1] - upper[1]
        len = Math.sqrt((dy * dy) + (dz * dz))
        return nil unless len > 0

        ny = dz / len * thickness
        nz = -dy / len * thickness
        face = lambda do |oy, oz|
          [[0,         upper[0] + oy, upper[1] + oz],
           [width_mm,  upper[0] + oy, upper[1] + oz],
           [width_mm,  free[0] + oy,  free[1] + oz],
           [0,         free[0] + oy,  free[1] + oz]]
        end
        [face.call(0, 0), face.call(ny, nz)]
      end

      # Twelve edges from two rings of four. z is relative to the carcass base.
      def draw_box(group, rings, z0)
        a, b = rings
        [a, b].each do |ring|
          ring.each_with_index do |p, i|
            q = ring[(i + 1) % 4]
            group.entities.add_line([p[0].mm, p[1].mm, (z0 + p[2]).mm],
                                    [q[0].mm, q[1].mm, (z0 + q[2]).mm])
          end
        end
        a.each_with_index do |p, i|
          q = b[i]
          group.entities.add_line([p[0].mm, p[1].mm, (z0 + p[2]).mm],
                                  [q[0].mm, q[1].mm, (z0 + q[2]).mm])
        end
      end

      def clear(definition)
        doomed = definition.entities.grep(Sketchup::Group)
                           .select { |g| g.name.start_with?('SYM_') }
        definition.entities.erase_entities(doomed) unless doomed.empty?
      end

      # unit: registry hash; hinge_side: 'lh'/'rh'/nil;
      # front_height_mm: the ACTUAL door height (780 handle / 750 gola) —
      # the elevation V outlines the real leaf, not the family height.
      # nil falls back to the family height (handle default).
      # Draws the open leaf for whatever kind of door this is, on TAG_DOOR.
      # Every branch of draw() returns early, so this runs FIRST and once.
      # Drawer stacks fall through and get nothing: a drawer front is not a
      # leaf, and its travel is already in the plan symbol.
      def draw_open_leaf(definition, unit, layout, w, h, z0,
                         front_height_mm, y_face, hinge_side, door_tag, mat)
        t  = Standards::FRONT_T_MM
        fh = front_height_mm || h
        kind = layout['kind'] || 'single'

        # ELEVATION ONLY. Some objects show which side opens but must not
        # assert HOW it opens: an appliance panel is hung on the client's
        # machine, so the swing path is the machine's and not ours. The hand
        # still has to reach the drawing - the order cannot carry it - so it
        # is drawn in the elevation and nowhere else.
        return if layout['hand_shown'] == 'elevation_only'

        if (ol = layout['open_leaf'])
          # Catalog geometry, printed per family. NEVER derived: the two
          # push-up systems move differently and only the page knows how.
          rings = open_leaf_slab(w, ol['upper_mm'], ol['free_mm'], t)
          return draw_leaf_group(definition, rings, z0, 'SYM_DOOR_MECHANISM', door_tag, mat)
        end

        if %w[bottom top].include?(layout['hinge_axis'].to_s)
          axis = layout['hinge_axis'].to_s
          z    = axis == 'top' ? fh : 0
          rings = open_leaf_slab(w, [0, z], [-fh, z], t)
          return draw_leaf_group(definition, rings, z0,
                                 "SYM_DOOR_#{axis.upcase}_HUNG", door_tag, mat)
        end

        if unit['geometry_kind'] == 'corner'
          return unless hinge_side

          p  = Generator.corner_parts(unit, front_height_mm)
          hx = hinge_side == 'lh' ? p[:door_x] : p[:door_x] + p[:door]
          quad = swing_quad(hx, y_face, p[:door], hinge_side, t)
          return draw_leaf_group(definition, open_leaf_prism(quad, 0, p[:front_h]),
                                 z0, 'SYM_DOOR_CORNER', door_tag, mat)
        end

        return unless %w[single vertical_split].include?(kind)

        leaves =
          if kind == 'single'
            return unless hinge_side

            [{ x: 0, w: w, hinge: hinge_side }]
          else
            [{ x: 0, w: w / 2.0, hinge: 'lh' },
             { x: w / 2.0, w: w / 2.0, hinge: 'rh' }]
          end

        leaves.each_with_index do |leaf, i|
          hx = leaf[:hinge] == 'lh' ? leaf[:x] : leaf[:x] + leaf[:w]
          quad = swing_quad(hx, y_face, leaf[:w], leaf[:hinge], t)
          draw_leaf_group(definition, open_leaf_prism(quad, 0, fh), z0,
                          "SYM_DOOR_#{i + 1}", door_tag, mat)
        end
        nil
      end

      def draw_leaf_group(definition, rings, z0, name, door_tag, mat)
        return nil unless rings

        g = definition.entities.add_group
        g.name = name
        draw_box(g, rings, z0)
        finalize(g, door_tag, mat)
        nil
      end

      def draw(model, definition, unit, hinge_side, front_height_mm = nil, slabs = nil)
        clear(definition)
        layout = unit['front_layout'] || {}
        kind   = layout['kind'] || 'single'

        s  = Standards
        # Symbols must start where the carcass starts - asked of the generator,
        # never worked out again here.
        z0 = Generator.base_z_mm(unit)
        # Every plan symbol in this method uses this one height. There is no
        # second place that decides it.
        z_plan = (Generator.row_datum_mm(unit) + PLAN_Z_MM).mm
        w  = unit['width_mm']
        h  = unit['height_mm']
        # 1 mm proud of the front line, and the LINE is asked for, not
        # recomputed - a symbol that drifts off its own front is worse than no
        # symbol at all.
        y_face = Generator.front_y_mm - 1

        front_tag = tag(model, TAG_FRONT)
        plan_tag  = tag(model, TAG_PLAN)
        door_tag  = tag(model, TAG_DOOR)
        mat       = symbol_material(model)
        enable_material_edges(model)

        # The leaf where it ends up. Drawn for every kind of door and before
        # any branch returns, so no type can quietly miss out.
        draw_open_leaf(definition, unit, layout, w, h, z0,
                       front_height_mm, y_face, hinge_side, door_tag, mat)

        # Glass, for the same reason and in the same place: every branch below
        # returns, so anything that must apply to all door types is drawn here
        # or it is quietly missed by one of them.
        draw_glass_hatch(definition, unit, z0, y_face, front_tag, mat, slabs)

        # ---- drawer stacks -------------------------------------------------
        if kind == 'horizontal'
          (slabs || Generator.front_slabs(unit)).each_with_index do |slab, i|
            g = definition.entities.add_group
            g.name = "SYM_FRONT_DRAWER_#{i + 1}"
            x1 = slab[:x_mm]
            x2 = slab[:x_mm] + slab[:w_mm]
            z1 = z0 + slab[:z_mm]
            z2 = z1 + slab[:h_mm]
            # UCON convention: one diagonal, top-left to bottom-right.
            g.entities.add_line([x1.mm, y_face.mm, z2.mm], [x2.mm, y_face.mm, z1.mm])
            finalize(g, front_tag, mat)
          end

          travel = Generator.runner_travel_for(unit['depth_mm'])
          if travel
            t  = s::FRONT_T_MM
            y0 = y_face
            y1 = y_face - travel      # outer face of the front at full extension
            yb = y1 + t               # its back face
            xi = RUNNER_INSET_MM
            g = definition.entities.add_group
            g.name = 'SYM_PLAN_PULLOUT'
            [[[xi, y0], [xi, yb]], [[w - xi, y0], [w - xi, yb]]].each do |a, b|
              g.entities.add_line([a[0].mm, a[1].mm, z_plan], [b[0].mm, b[1].mm, z_plan])
            end
            dashed_rect(g, [[0, yb], [w, yb], [w, y1], [0, y1]], z_plan)
            finalize(g, plan_tag, mat)
          end
          return
        end

        # ---- corner units --------------------------------------------------
        # The door sits at one end of a longer, blind front. Nothing is drawn
        # until a hinge side is chosen, exactly as for a straight single door.
        if unit['geometry_kind'] == 'corner'
          return unless hinge_side

          p = Generator.corner_parts(unit, front_height_mm)
          marks = corner_door_marks(p[:door_x], p[:door], z0,
                                    p[:front_h], y_face, hinge_side)
          g = definition.entities.add_group
          g.name = 'SYM_FRONT_CORNER'
          marks[:front].each do |a, b|
            g.entities.add_line([a[0].mm, a[1].mm, a[2].mm], [b[0].mm, b[1].mm, b[2].mm])
          end
          finalize(g, front_tag, mat)

          g = definition.entities.add_group
          g.name = 'SYM_PLAN_CORNER'
          a, b = marks[:plan_leaf]
          g.entities.add_line([a[0].mm, a[1].mm, z_plan], [b[0].mm, b[1].mm, z_plan])
          finalize(g, plan_tag, mat)
          return
        end

        # ---- bottom-hung fronts --------------------------------------------
        # Drawing_Spec: one rule, not a third symbol — the base of the V lies on
        # the hinge axis and the apex points at the opening edge. With the hinge
        # along the bottom, that base is the bottom edge and the figure reads as
        # an inverted V. In plan the leaf falls flat, projecting forward by its
        # own height. No hinge_side is involved: the axis is a fact of the type
        # (a laundry unit) or a constant of the class (an appliance panel).
        if %w[bottom top].include?(layout['hinge_axis'].to_s)
          axis  = layout['hinge_axis'].to_s
          marks = hung_marks(w, z0, front_height_mm || h, y_face, axis)

          g = definition.entities.add_group
          g.name = axis == 'top' ? 'SYM_FRONT_TOP_HUNG' : 'SYM_FRONT_BOTTOM_HUNG'
          marks[:front].each do |a, b|
            g.entities.add_line([a[0].mm, a[1].mm, a[2].mm], [b[0].mm, b[1].mm, b[2].mm])
          end
          finalize(g, front_tag, mat)

          g = definition.entities.add_group
          g.name = axis == 'top' ? 'SYM_PLAN_TOP_HUNG' : 'SYM_PLAN_BOTTOM_HUNG'
          dashed_rect(g, marks[:plan_rect], z_plan)
          finalize(g, plan_tag, mat)
          return
        end

        return unless %w[single vertical_split].include?(kind)

        leaves =
          if kind == 'single'
            return unless hinge_side # no hinge chosen -> nothing to declare
            [{ x: 0, w: w, hinge: hinge_side }]
          else
            [{ x: 0, w: w / 2.0, hinge: 'lh' },
             { x: w / 2.0, w: w / 2.0, hinge: 'rh' }]
          end

        door_h = front_height_mm || h

        leaves.each_with_index do |leaf, i|
          hinge_x   = leaf[:hinge] == 'lh' ? leaf[:x] : leaf[:x] + leaf[:w]
          opening_x = leaf[:hinge] == 'lh' ? leaf[:x] + leaf[:w] : leaf[:x]

          g = definition.entities.add_group
          g.name = "SYM_FRONT_#{i + 1}"
          apex = [opening_x.mm, y_face.mm, (z0 + door_h / 2.0).mm]
          g.entities.add_line([hinge_x.mm, y_face.mm, z0.mm], apex)
          g.entities.add_line([hinge_x.mm, y_face.mm, (z0 + door_h).mm], apex)
          finalize(g, front_tag, mat)

          # Same rule as the open leaf: an elevation-only hand stops here.
          next if layout['hand_shown'] == 'elevation_only'

          g = definition.entities.add_group
          g.name = "SYM_PLAN_#{i + 1}"
          center  = [hinge_x.mm, y_face.mm, z_plan]
          r       = leaf[:w].mm

          # Open leaf drawn as the actual front slab, dashed, at
          # DOOR_OPEN_ANGLE_DEG from closed - the SAME quad the 3-D leaf is
          # built from, so the plan and the door can never disagree.
          open_rad = DOOR_OPEN_ANGLE_DEG * Math::PI / 180
          a1, a2 = leaf[:hinge] == 'lh' ? [-open_rad, 0] : [Math::PI, Math::PI + open_rad]
          dashed_rect(g, swing_quad(hinge_x, y_face, leaf[:w], leaf[:hinge], s::FRONT_T_MM),
                      z_plan)
          g.entities.add_arc(Geom::Point3d.new(*center), Geom::Vector3d.new(1, 0, 0),
                             Geom::Vector3d.new(0, 0, 1), r, a1, a2, 12)
          finalize(g, plan_tag, mat)
        end
        nil
      end
    end
  end
end

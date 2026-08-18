# frozen_string_literal: true
#
# UCON Cabinet Engine — core/70_symbols.rb
#
# Dashed opening symbols on two hideable tags:
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

      # Plan symbols are drawn just above the FLOOR, not above the unit.
      # Drawn at cabinet top they float over the worktops of the neighbours,
      # and any plan view cut below the worktop loses them entirely — the one
      # view they exist for. At the floor they sit under every section cut and
      # read against the run's footprint, which is what a plan shows.
      PLAN_Z_MM = 1

      # Plan symbol: drawer runner lines drawn inset from the unit sides.
      RUNNER_INSET_MM = 25

      # Plan symbol: doors drawn open at this angle, not fully at 90.
      DOOR_OPEN_ANGLE_DEG = 85

      SYMBOL_RGB = [128, 128, 128].freeze

      module_function

      # Palette-driven visibility: plan views want only the plan tag,
      # elevations only the front tag. mode: :plan | :front | :off | :all
      def show_mode(model, mode)
        front = tag(model, TAG_FRONT)
        plan  = tag(model, TAG_PLAN)
        front.visible = %i[front all].include?(mode)
        plan.visible  = %i[plan all].include?(mode)
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
      def dashed_rect(group, corners, z)
        corners.each_index do |i|
          a = corners[i]
          b = corners[(i + 1) % corners.length]
          group.entities.add_line([a[0].mm, a[1].mm, z], [b[0].mm, b[1].mm, z])
        end
        group.entities.grep(Sketchup::Face).each(&:erase!)
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
      def draw(model, definition, unit, hinge_side, front_height_mm = nil, slabs = nil)
        clear(definition)
        layout = unit['front_layout'] || {}
        kind   = layout['kind'] || 'single'

        s  = Standards
        # Symbols must start where the carcass starts. A hung unit has no
        # plinth, so its zero is the hanging height, not PLINTH_H_MM - asked
        # of the generator so there is exactly one answer in the engine.
        z0 = Generator.wall_hung?(unit) ? Generator.mount_bottom_mm(unit) : s::PLINTH_H_MM
        w  = unit['width_mm']
        h  = unit['height_mm']
        y_face = -(s::FRONT_GAP_MM + s::FRONT_T_MM) - 1

        front_tag = tag(model, TAG_FRONT)
        plan_tag  = tag(model, TAG_PLAN)
        mat       = symbol_material(model)
        enable_material_edges(model)

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
            z_plan = PLAN_Z_MM.mm
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
          g.entities.add_line([a[0].mm, a[1].mm, PLAN_Z_MM.mm], [b[0].mm, b[1].mm, PLAN_Z_MM.mm])
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
          dashed_rect(g, marks[:plan_rect], PLAN_Z_MM.mm)
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

          g = definition.entities.add_group
          g.name = "SYM_PLAN_#{i + 1}"
          z_plan  = PLAN_Z_MM.mm
          center  = [hinge_x.mm, y_face.mm, z_plan]
          r       = leaf[:w].mm

          # Open leaf drawn as the actual 22 mm front slab, dashed, at
          # DOOR_OPEN_ANGLE_DEG from closed. Thickness points into the swing
          # region (toward where the arc comes from).
          t = s::FRONT_T_MM
          open_rad = DOOR_OPEN_ANGLE_DEG * Math::PI / 180
          if leaf[:hinge] == 'lh'
            u_ang = -open_rad                      # closed along +x, swings to -y
            a1, a2 = -open_rad, 0
          else
            u_ang = Math::PI + open_rad            # closed along -x
            a1, a2 = Math::PI, Math::PI + open_rad
          end
          ux, uy = Math.cos(u_ang), Math.sin(u_ang)
          v_ang = leaf[:hinge] == 'lh' ? u_ang + Math::PI / 2 : u_ang - Math::PI / 2
          vx, vy = Math.cos(v_ang), Math.sin(v_ang)
          l = leaf[:w]
          dashed_rect(g,
                      [[hinge_x, y_face],
                       [hinge_x + t * vx, y_face + t * vy],
                       [hinge_x + t * vx + l * ux, y_face + t * vy + l * uy],
                       [hinge_x + l * ux, y_face + l * uy]],
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

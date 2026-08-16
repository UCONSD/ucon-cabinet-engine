# frozen_string_literal: true
#
# UCON Cabinet Engine — core/70_symbols.rb
#
# Dashed opening symbols on two hideable tags:
#
#   TAG_FRONT — elevation: dashed V per door leaf. Base of the V at the hinge
#               edge, apex at mid-height of the opening edge (European
#               drawing convention — flip here if UCON draws it the other way).
#   TAG_PLAN  — plan: dashed quarter-arc of the door swing plus the open leaf,
#               drawn just above the carcass top.
#
# Tags get the native "Dash" line style (SketchUp 2019+); on both the tag and
# the edges, so hiding the tag hides the symbols and the dashes render.
# Symbols live INSIDE the unit definition, so they move with the instance.
# Groups are named SYM_* and are wiped before redraw — idempotent.

module UCON
  module CabinetEngine
    module Symbols
      TAG_FRONT = 'UCON — Opening (front)'
      TAG_PLAN  = 'UCON — Opening (plan)'

      module_function

      def tag(model, name)
        layer = model.layers[name] || model.layers.add(name)
        if layer.respond_to?(:line_style=) && model.respond_to?(:line_styles)
          dash = model.line_styles['Dash']
          layer.line_style = dash if dash && layer.line_style != dash
        end
        layer
      end

      def clear(definition)
        doomed = definition.entities.grep(Sketchup::Group)
                           .select { |g| g.name.start_with?('SYM_') }
        definition.entities.erase_entities(doomed) unless doomed.empty?
      end

      # unit: registry hash; hinge_side: 'lh'/'rh'/nil; door_version: 780/750.
      def draw(model, definition, unit, hinge_side)
        clear(definition)
        layout = unit['front_layout'] || {}
        kind   = layout['kind'] || 'single'
        return unless %w[single vertical_split].include?(kind)

        s  = Standards
        z0 = s::PLINTH_H_MM
        w  = unit['width_mm']
        h  = unit['height_mm']
        y_face = -(s::FRONT_GAP_MM + s::FRONT_T_MM) - 1

        leaves =
          if kind == 'single'
            return unless hinge_side # no hinge chosen -> nothing to declare
            [{ x: 0, w: w, hinge: hinge_side }]
          else
            [{ x: 0, w: w / 2.0, hinge: 'lh' },
             { x: w / 2.0, w: w / 2.0, hinge: 'rh' }]
          end

        front_tag = tag(model, TAG_FRONT)
        plan_tag  = tag(model, TAG_PLAN)

        leaves.each_with_index do |leaf, i|
          hinge_x   = leaf[:hinge] == 'lh' ? leaf[:x] : leaf[:x] + leaf[:w]
          opening_x = leaf[:hinge] == 'lh' ? leaf[:x] + leaf[:w] : leaf[:x]

          g = definition.entities.add_group
          g.name  = "SYM_FRONT_#{i + 1}"
          g.layer = front_tag
          apex = [opening_x.mm, y_face.mm, (z0 + h / 2.0).mm]
          e1 = g.entities.add_line([hinge_x.mm, y_face.mm, z0.mm], apex)
          e2 = g.entities.add_line([hinge_x.mm, y_face.mm, (z0 + h).mm], apex)
          [e1, e2].each { |ed| ed.layer = front_tag if ed }

          g = definition.entities.add_group
          g.name  = "SYM_PLAN_#{i + 1}"
          g.layer = plan_tag
          z_plan  = (z0 + h + 1).mm
          center  = [hinge_x.mm, y_face.mm, z_plan]
          r       = leaf[:w].mm
          open_pt = [hinge_x.mm, (y_face - leaf[:w]).mm, z_plan]
          leaf_edge = g.entities.add_line(center, open_pt)
          a1, a2 = leaf[:hinge] == 'lh' ? [-Math::PI / 2, 0] : [Math::PI, Math::PI * 1.5]
          arc = g.entities.add_arc(Geom::Point3d.new(*center), Geom::Vector3d.new(1, 0, 0),
                                   Geom::Vector3d.new(0, 0, 1), r, a1, a2, 12)
          ([leaf_edge] + Array(arc)).compact.each { |ed| ed.layer = plan_tag }
        end
        nil
      end
    end
  end
end

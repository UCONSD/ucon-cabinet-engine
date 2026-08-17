# frozen_string_literal: true
#
# UCON Cabinet Engine — core/30_geometry.rb
#
# Primitive geometry helpers. This is the one core file that legitimately
# depends on the SketchUp API; everything above it (standards, contract
# validation, and the future code grammar) stays SketchUp-free so it can be
# exercised headlessly.
#
# All public arguments are plain millimetre numbers. Conversion to SketchUp's
# internal Length happens here and nowhere else — so the rest of the engine
# never has to remember which unit it is holding.
#
# Origin convention, inherited unchanged from the frozen B80601 baseline:
#   x — across the cabinet face, left to right
#   y — depth, front face at 0, increasing toward the back
#   z — height, floor at 0, increasing upward

module UCON
  module CabinetEngine
    module Geometry
      EDGE_TOLERANCE_MM = 0.001

      module_function

      # Fetch-or-create a named material. The model is passed in rather than
      # reached for globally, so nothing here depends on the active document.
      def material(model, name, rgb)
        mat = model.materials[name] || model.materials.add(name)
        mat.color = Sketchup::Color.new(*rgb)
        mat
      end

      # Axis-aligned box as a named group.
      def box(entities, name, x_mm, y_mm, z_mm, w_mm, d_mm, h_mm, material)
        unless [w_mm, d_mm, h_mm].all? { |v| v.to_f > 0 }
          raise ArgumentError,
                "Non-positive dimension for #{name}: w=#{w_mm} d=#{d_mm} h=#{h_mm}"
        end

        x = x_mm.mm
        y = y_mm.mm
        z = z_mm.mm
        w = w_mm.mm
        d = d_mm.mm
        h = h_mm.mm

        group = entities.add_group
        group.name = name

        face = group.entities.add_face(
          [x,     y,     z],
          [x + w, y,     z],
          [x + w, y + d, z],
          [x,     y + d, z]
        )
        raise "Face creation failed for #{name}" unless face

        face.reverse! if face.normal.z < 0
        face.pushpull(h)
        group.material = material

        # Edge color mode is by-material (symbols render gray); without an
        # explicit material, edges INHERIT the group's material and the whole
        # carcass would outline in its face color. Pin unit edges to black.
        edge_mat = Geometry.material(group.model, 'UCON_Edge_Black', [0, 0, 0])
        group.entities.grep(Sketchup::Edge).each { |e| e.material = edge_mat }
        group
      end

      # A box with no faces: the twelve edges only.
      #
      # Convention (Drawing_Spec): a Cesar object has surfaces, a stand-in for
      # something that is not ours has none. A solid grey box for a client
      # appliance reads as a cabinet we are selling, which is a lie on a
      # presentation sheet; a wireframe volume reads as "this space is taken,
      # by something else". Built as a normal box, then its faces are erased —
      # the same trick the opening symbols use.
      def wire_box(entities, name, x_mm, y_mm, z_mm, w_mm, d_mm, h_mm, material)
        group = box(entities, name, x_mm, y_mm, z_mm, w_mm, d_mm, h_mm, material)
        group.entities.grep(Sketchup::Face).each(&:erase!)
        group.entities.grep(Sketchup::Edge).each { |e| e.material = material }
        group
      end

      # Hide the four vertical corner edges of a group. Used on the plinth so a
      # run of adjacent cabinets reads as one continuous base rather than a row
      # of separate blocks.
      def hide_vertical_edges(group)
        tolerance = EDGE_TOLERANCE_MM.mm
        group.entities.grep(Sketchup::Edge).each do |edge|
          vector = edge.end.position - edge.start.position
          next unless vector.x.abs < tolerance &&
                      vector.y.abs < tolerance &&
                      vector.z.abs > tolerance

          edge.hidden = true
        end
      end
    end
  end
end

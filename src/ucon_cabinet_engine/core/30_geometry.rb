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

      # A solid from a plan polygon, extruded up. The 8x8 corner filler is one
      # L-shaped piece, not two panels leaning together.
      def prism(entities, name, plan_pts_mm, z_mm, h_mm, material)
        group = entities.add_group
        group.name = name
        face = group.entities.add_face(
          plan_pts_mm.map { |p| [p[0].mm, p[1].mm, z_mm.mm] }
        )
        raise "Face creation failed for #{name}" unless face

        face.reverse! if face.normal.z < 0
        face.pushpull(h_mm.mm)
        group.material = material
        edge_mat = Geometry.material(group.model, 'UCON_Edge_Black', [0, 0, 0])
        group.entities.grep(Sketchup::Edge).each { |e| e.material = edge_mat }
        group
      end

      # A FRONT WITH A HOLE THROUGH IT.
      #
      # An aperture is not a box. `box` extrudes a FOOTPRINT upwards, so the
      # hole it could make would run top to bottom; the wine cooler door needs
      # one that runs through the THICKNESS. So this one is built the other way
      # round - the front face in the x-z plane, an inner loop dropped out of
      # it, and the remaining ring extruded backwards by the front thickness.
      #
      # Rails are measured from the panel's own four edges. That is how every
      # appliance maker dimensions the panel, and it is the only form in which
      # the numbers can be carried from one machine to another.
      def framed_slab(entities, name, x_mm, y_mm, z_mm, w_mm, d_mm, h_mm,
                      rails, material)
        left   = rails[:left].to_f
        right  = rails[:right].to_f
        bottom = rails[:bottom].to_f
        top    = rails[:top].to_f
        ap_w   = w_mm - left - right
        ap_h   = h_mm - bottom - top
        unless ap_w > 0 && ap_h > 0
          raise ArgumentError,
                "Aperture for #{name} is not positive: #{ap_w} x #{ap_h}. " \
                "Rails l#{left} r#{right} b#{bottom} t#{top} do not fit " \
                "#{w_mm} x #{h_mm}."
        end

        group = entities.add_group
        group.name = name
        y = y_mm.mm
        outer = [[x_mm, z_mm], [x_mm + w_mm, z_mm],
                 [x_mm + w_mm, z_mm + h_mm], [x_mm, z_mm + h_mm]]
        face = group.entities.add_face(outer.map { |a, b| [a.mm, y, b.mm] })
        raise "Face creation failed for #{name}" unless face

        ax = x_mm + left
        az = z_mm + bottom
        hole = [[ax, az], [ax + ap_w, az],
                [ax + ap_w, az + ap_h], [ax, az + ap_h]]
        inner = group.entities.add_face(hole.map { |a, b| [a.mm, y, b.mm] })
        # Erasing the FACE leaves its edges behind - they bound the ring too -
        # which is exactly the hole we want. A nil here would leave a solid
        # slab with a rectangle drawn on it, which looks close enough to right
        # to survive a glance, so it is an error and not a fallback.
        raise "Inner loop failed for #{name}" unless inner

        inner.erase!

        ring = group.entities.grep(Sketchup::Face).first
        raise "Aperture cut failed for #{name}" unless ring

        # The slab must end up occupying y .. y + d, exactly where a box would.
        # Which way that is depends on which way the face came out facing, so
        # ask it rather than assume.
        ring.pushpull(ring.normal.y < 0 ? -d_mm.mm : d_mm.mm)
        group.material = material
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

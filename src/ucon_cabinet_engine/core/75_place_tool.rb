# frozen_string_literal: true
#
# UCON Cabinet Engine — core/75_place_tool.rb
#
# The interactive placement tool (Roadmap M2.3, first half: GRAB).
#
# This file is glue and nothing else. Every rule it obeys lives in
# core/22_placement.rb, in plain Ruby over millimetre arrays, where it can be
# tested headlessly. What is left here is the part that genuinely needs
# SketchUp: firing rays, reading transformations, drawing feedback, and owning
# one undo step.
#
# What the tool does, and deliberately does not do:
#   * the WALL decides rotation and depth - the unit's back plane seats on it
#   * the NEIGHBOUR decides position along the wall - ends close themselves
#   * the HEIGHT is latched: the held corner travels along the wall, never up
#     and down it. A run is level by construction.
#
# Because the height is latched, the unit's real height above the floor never
# changes here, so `mount_bottom_mm` written by the generator stays true. The
# day this tool learns to re-hang a unit, that attribute has to be rewritten
# with the height it actually ended at - and the mounting height will have to
# come out of the definition, where it is baked today.
#
# Lessons paid for during the probes, all load-bearing:
#   * SketchUp SWALLOWS exceptions raised inside tool callbacks - the tool just
#     stops responding, silently. Anything on the mouse-move path traps its own
#     errors and reports once.
#   * Neither the status bar nor the tooltip survives on macOS; SketchUp
#     repaints both on its own schedule. Feedback is drawn into the viewport.
#   * The unit being placed HIDES the wall behind it, and pick_helper only ever
#     reports the front-most entity. The ray is walked instead: every hit that
#     belongs to the unit is stepped past and the ray re-fired.

module UCON
  module CabinetEngine
    module PlaceTool
      MARKER_ARM_MM   = 120
      # How far from the cursor a crossing wall may be and still be THIS corner.
      CORNER_REACH_MM = 3000
      WALL_SCAN_DEPTH = 4
      RAY_STEPS     = 8      # how many times the ray may step past our own geometry
      RAY_STEP_MM   = 1

      module_function

      def start(instance = nil, model = Sketchup.active_model)
        instance ||= model.selection.grep(Sketchup::ComponentInstance).find do |i|
          i.definition.get_attribute(Contract::DICTIONARY, 'code')
        end
        unless instance
          UI.messagebox("Select a UCON unit first, then start the placement tool.")
          return nil
        end

        attrs   = Contract.read(instance.definition)
        refusal = Placement.refusal_for(attrs)
        if refusal
          UI.messagebox(refusal)
          return nil
        end

        model.select_tool(Tool.new(instance, attrs))
      end

      class Tool
        def initialize(instance, attrs)
          @instance = instance
          @width    = attrs['width_mm'].to_f
          @depth    = attrs['depth_mm'].to_f
          @mounting = attrs['mounting'].to_s
          @code     = attrs['code'].to_s
          @corner   = attrs['geometry_kind'].to_s == 'corner'
          @top      = instance.definition.bounds.max.z   # as built, plinth or hung
          @home     = instance.transformation
          @xaxis    = X_AXIS
          read_corner_facts if @corner
          @butted   = false
          @label    = ''
          @mx       = 0
          @my       = 0
        end

        # ---- tool protocol -------------------------------------------------

        # One undo step for the whole placement: opened here, committed on drop,
        # aborted on cancel or on the tool being taken away. Without this every
        # mouse move would leave its own entry in the undo stack.
        def activate
          @model     = Sketchup.active_model
          @committed = false
          @model.start_operation("UCON: place #{@code}", true)
          Sketchup.status_text = 'UCON place — click to drop, Esc to cancel'
        end

        def deactivate(view)
          @model.abort_operation unless @committed
          Sketchup.status_text = ''
          view.invalidate
        end

        def getExtents
          Sketchup.active_model.bounds
        end

        def onMouseMove(_flags, x, y, view)
          @mx = x
          @my = y
          @butted = false

          wall = wall_under(view, x, y)
          if wall && @corner
            seat_in_corner(wall)
          elsif wall
            seat_on_wall(wall)
            @label = @butted ? 'on the wall — butted' : 'on the wall'
          else
            slide_on_ground(view, x, y)
            @label = @corner ? 'no wall — a corner unit needs one' : 'off the wall'
          end
          view.invalidate
        rescue StandardError => e
          report(e)
          @label = "error: #{e.class}"
          view.invalidate
        end

        def draw(view)
          if @corner
            return unless @corner_pt

            view.line_width = 4
            view.drawing_color = 'green'
            view.draw(GL_LINES, [Geom::Point3d.new(@corner_pt.x, @corner_pt.y, 0),
                                 Geom::Point3d.new(@corner_pt.x, @corner_pt.y, 2500.mm)])
            view.line_width = 3
            view.drawing_color = 'blue'
            view.draw(GL_LINE_LOOP, node_outline)
            view.draw_text([@mx + 18, @my + 18], @label, size: 12, color: 'green')
            return
          end

          corner, arms = marker
          view.line_width = 3
          view.drawing_color = @butted ? 'green' : 'red'
          arms.each { |a| view.draw(GL_LINES, [corner, a]) }
          view.draw_text([@mx + 18, @my + 18], @label,
                         size: 12, color: @butted ? 'green' : 'red')
        rescue StandardError
          nil   # feedback must never be the thing that breaks a placement
        end

        def onLButtonDown(_flags, _x, _y, view)
          @model.commit_operation
          @committed = true
          view.model.select_tool(nil)
        end

        def onCancel(_reason, view)
          @instance.transformation = @home
          @model.abort_operation
          @committed = true
          view.model.select_tool(nil)
        end

        # ---- placement -----------------------------------------------------

        private

        # Three short arms along the three edges meeting at the held corner:
        # right, top, far. An invisible promise is not a promise.
        # A corner is held by its NODE - the rectangle the catalog prints, with
        # the wasted end in the angle - not by a corner of a box it does not have.
        def node_outline
          wasted = @nominal - @carcass
          x0 = @execution == 'left' ? 0.0 : -wasted
          x1 = @execution == 'left' ? @nominal : @carcass
          t  = @instance.transformation
          [[x0, -80.0], [x1, -80.0], [x1, @depth], [x0, @depth]].map do |x, y|
            Geom::Point3d.new(x.mm, y.mm, 0).transform(t)
          end
        end

        def marker
          t = @instance.transformation
          c = Geom::Point3d.new(@width.mm, @depth.mm, @top).transform(t)
          arms = [
            Geom::Point3d.new((@width - MARKER_ARM_MM).mm, @depth.mm, @top),
            Geom::Point3d.new(@width.mm, (@depth - MARKER_ARM_MM).mm, @top),
            Geom::Point3d.new(@width.mm, @depth.mm, @top - MARKER_ARM_MM.mm)
          ].map { |p| p.transform(t) }
          [c, arms]
        end

        # ---- corners --------------------------------------------------------

        def read_corner_facts
          unit = Registry.lookup(@code)
          @carcass   = unit['carcass_length_mm'].to_f
          @nominal   = unit['corner_geometry'].to_s.split('x').first.to_i.to_f
          @execution = unit['execution'].to_s
        end

        # A corner unit does not sit on a wall, it sits in the angle where two
        # meet - and WHICH article it is follows from the way the wall runs from
        # that angle. The swap is silent by decision, but the code, the name and
        # the notes all change with it, so nothing reaches an order unstated.
        def seat_in_corner(hit)
          second = second_wall(hit)
          unless second
            @label = 'one wall only — a corner needs two'
            return
          end

          f    = Placement.frame(vec(hit[:normal]))
          xv   = vector(f[:x])
          run  = wall_run_along(hit[:face], hit[:face_tr], second[:corner], xv)
          want = Placement.execution_for(run)
          unless want
            @label = 'cannot tell which way the wall runs'
            return
          end

          if want != @execution
            swapped = Generator.swap_corner_execution!(@instance, @model)
            if swapped
              @code = swapped
              read_corner_facts
            end
          end

          o = point(Placement.corner_origin(mm(second[:corner]), vec(hit[:normal]),
                                            @depth, @carcass, @nominal, @execution))
          o.z = 0
          @instance.transformation =
            Geom::Transformation.axes(o, xv, vector(f[:y]), Z_AXIS)
          @corner_pt = second[:corner]
          @label = "in the corner — #{@code} (#{@execution})"
        end

        # Nearest wall whose plane genuinely crosses this one. Parallel faces are
        # the same wall seen twice; a crossing far away belongs to another corner.
        def second_wall(a)
          best = nil
          room_walls.each do |w|
            next if w[:face] == a[:face]
            next if w[:normal].dot(a[:normal]).abs > Placement::PARALLEL_MIN

            c = Placement.corner_point(mm(a[:point]), vec(a[:normal]),
                                       mm(w[:point]), vec(w[:normal]))
            next unless c

            pt = point(c)
            d  = pt.distance(a[:point]).to_mm
            next if d > CORNER_REACH_MM

            best = { corner: pt, distance: d } if best.nil? || d < best[:distance]
          end
          best
        end

        # How far the wall reaches on each side of the corner, along the unit's x.
        def wall_run_along(face, tr, corner, xv)
          projections = face.vertices.map { |v| along(v.position.transform(tr), xv) }
          Placement.wall_run(along(corner, xv), projections.min, projections.max)
        end

        # The room is WHAT IS NOT OURS: a wall in a client's model carries no
        # attribute of ours, so the only honest test is to exclude our own.
        def room_walls
          @room_walls ||= begin
            out = []
            collect_walls(@model.entities, Geom::Transformation.new, 0, out)
            out
          end
        end

        def collect_walls(entities, tr, depth, out)
          return if depth > WALL_SCAN_DEPTH

          entities.each do |ent|
            case ent
            when Sketchup::Face
              n = ent.normal.transform(tr)
              n.normalize!
              next unless Placement.wall?(vec(n))

              out << { face: ent, normal: n,
                       point: ent.vertices.first.position.transform(tr) }
            when Sketchup::Group
              collect_walls(ent.entities, tr * ent.transformation, depth + 1, out)
            when Sketchup::ComponentInstance
              next if ent.definition.get_attribute(Contract::DICTIONARY, 'code')

              collect_walls(ent.definition.entities, tr * ent.transformation,
                            depth + 1, out)
            end
          end
        end

        def seat_on_wall(hit)
          n_mm = Placement.origin_on_wall(mm(hit[:point]), vec(hit[:normal]),
                                          @depth, @width)
          f  = Placement.frame(vec(hit[:normal]))
          xv = vector(f[:x])
          yv = vector(f[:y])
          @xaxis = xv

          origin = point(n_mm)
          delta  = neighbour_pull(origin, xv, yv, hit)
          if delta
            origin = origin.offset(xv, delta.mm)
            @butted = true
          end
          origin.z = 0   # height stays as built; see the note at the top

          @instance.transformation =
            Geom::Transformation.axes(origin, xv, yv, Z_AXIS)
        end

        def slide_on_ground(view, x, y)
          pt = Geom.intersect_line_plane(view.pickray(x, y), [ORIGIN, Z_AXIS])
          return unless pt

          yv = Z_AXIS.cross(@xaxis)
          o  = pt.offset(@xaxis, -@width.mm).offset(yv, -@depth.mm)
          o.z = 0
          @instance.transformation =
            Geom::Transformation.axes(o, @xaxis, yv, Z_AXIS)
        end

        # Ends of every unit that is genuinely in this row, measured along the
        # wall axis, handed to the pure rule to pick the nearest joint.
        def neighbour_pull(origin, xv, yv, hit)
          mine_lo = along(origin, xv)
          spans   = []

          @model.entities.grep(Sketchup::ComponentInstance).each do |other|
            next if other == @instance

            a = Contract.read(other.definition)
            next unless a['code'] && a['depth_mm']

            # A corner neighbour has no width, and its NODE is longer than its
            # carcass: the wasted end is space that must stay free, so the run
            # has to start past it, not past the box.
            span = span_for(a)
            next unless span

            t  = other.transformation
            dn = a['depth_mm'].to_f

            axis = Geom::Vector3d.new(0, 1, 0).transform(t)
            axis.normalize!
            back = Geom::Point3d.new(0, dn.mm, 0).transform(t)
            offset = (back - hit[:point]).dot(hit[:normal]).to_mm

            next unless Placement.same_row?(@mounting, a['mounting'],
                                            axis.dot(yv), offset)

            ends = span.map { |x| along(Geom::Point3d.new(x.mm, 0, 0).transform(t), xv) }
            spans << ends.minmax
          end

          Placement.pull(mine_lo, mine_lo + @width, spans)
        end

        # What a neighbour occupies along its own x. A straight unit is its
        # width; a corner is its node, read from the registry because the
        # contract carries corner_geometry rather than a width.
        def span_for(attrs)
          return Placement.span_mm(width_mm: attrs['width_mm'].to_f) if attrs['width_mm']
          return nil unless attrs['corner_geometry']

          unit = begin
            Registry.lookup(attrs['code'])
          rescue StandardError
            nil
          end
          return nil unless unit

          Placement.span_mm(carcass_mm: unit['carcass_length_mm'],
                            nominal_mm: attrs['corner_geometry'].to_s.split('x').first.to_i,
                            execution:  unit['execution'])
        end

        # ---- unit plumbing: SketchUp in, millimetres out --------------------

        def along(point, axis)
          (point - ORIGIN).dot(axis).to_mm
        end

        def mm(point)
          [point.x.to_mm, point.y.to_mm, point.z.to_mm]
        end

        def vec(vector)
          [vector.x, vector.y, vector.z]
        end

        def point(arr)
          Geom::Point3d.new(arr[0].mm, arr[1].mm, arr[2].mm)
        end

        def vector(arr)
          v = Geom::Vector3d.new(arr[0], arr[1], arr[2])
          v.normalize!
          v
        end

        def wall_under(view, x, y)
          origin, dir = view.pickray(x, y)
          dir = dir.clone
          dir.normalize!

          RAY_STEPS.times do
            hit = @model.raytest([origin, dir], true)
            return nil unless hit

            point, path = hit
            if path.include?(@instance)
              origin = point.offset(dir, RAY_STEP_MM.mm)
              next
            end

            face = path.reverse.find { |e| e.is_a?(Sketchup::Face) }
            return nil unless face

            n = face.normal.transform(path_transform(path))
            n.normalize!
            n.reverse! if n.dot(dir) > 0
            return nil unless Placement.wall?(vec(n))

            return { point: point, normal: n, face: face,
                     face_tr: path_transform(path) }
          end
          nil
        end

        def path_transform(path)
          path.inject(Geom::Transformation.new) do |t, e|
            e.respond_to?(:transformation) ? t * e.transformation : t
          end
        end

        def report(error)
          return if @reported

          @reported = true
          puts "[UCON place] #{error.class}: #{error.message}"
          puts error.backtrace.first(6)
        end
      end
    end
  end
end

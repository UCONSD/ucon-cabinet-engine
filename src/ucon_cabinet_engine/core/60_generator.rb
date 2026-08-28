# frozen_string_literal: true
#
# UCON Cabinet Engine — core/60_generator.rb
#
# The forward generator (Roadmap M1.4): article code in, coded placeholder
# component out. All catalog facts come from the registry; all working
# standards from 10_standards.rb; the attribute schema from 20_contract.rb.
#
# Representation (settled on B80601 and inherited here):
#   * carcass = one volume, exterior envelope only (§6.2)
#   * front   = one slab drawn flush with the carcass outline; the 1.5 mm
#     reveal per side is recorded data, deliberately not drawn
#   * plinth  = recessed, vertical end edges hidden
#
# The front is a single slab even for drawer units — front splits are interior
# configuration by our standards and stay undrawn until a drawing needs them.
# attributes_for is pure (no SketchUp) so the whole mapping is headless-testable.

module UCON
  module CabinetEngine
    module Generator
      module_function

      # Placement: a new unit lands on the floor (z = 0). If a UCON unit is
      # selected when building, the new one continues the run - flush to the
      # selected unit's right edge, inheriting its orientation (a rotated run
      # keeps its direction); the visual joint comes from the reveal, so no
      # gap. Nothing selected -> origin.
      def placement_transform(model, new_unit = nil)
        sel = selected_unit(model)
        return Geom::Transformation.new unless sel

        sel_attrs = Contract.read(sel.definition)
        span = span_for_attrs(sel_attrs)
        # Nothing we can measure: land at the origin, where it is obvious the
        # run was not continued. The old code read the missing width as 0.0 and
        # dropped the new unit exactly on top of the selected one - a lie that
        # looked like a placement.
        return Geom::Transformation.new unless span

        # ---- BEHIND, NOT BESIDE ------------------------------------------
        #
        # A sheet is the first element in this engine that does not continue a
        # run. Everything below asks WHICH SIDE - left, right, or the turn at a
        # corner - because every element so far stood in the row. A panel behind
        # base units stands across the BACK of the row, and the question "which
        # side" has no answer for it.
        #
        # So it seats at the selected unit's own origin - no x offset at all,
        # because the panel starts where the person said it starts - and steps
        # back along that unit's OWN y by that unit's depth. Its own thickness
        # then grows further back from there, which is what the box does. Two
        # 1200 panels across four 600 units means selecting the first unit and
        # then the third: the person places the joints, because the catalog
        # prices the area and says nothing about where a board is cut.
        #
        # The selected unit's depth, NOT the panel's: the same trap that was
        # caught at the corner on 2026-08-24, where the new element's depth
        # turned a filler onto the wall. What the panel must clear is the run.
        if new_unit && Registry.sheet_panel?(new_unit)
          back = (sel_attrs['depth_mm'] || 0).to_f
          if back <= 0
            raise ArgumentError,
                  "#{sel_attrs['code']} states no depth, so there is no back to " \
                  'stand behind. Select a unit that carries one.'
          end

          behind = sel.transformation *
                   Geom::Transformation.translation(Geom::Vector3d.new(0, back.mm, 0))
          o = behind.origin
          return Geom::Transformation.translation(Geom::Vector3d.new(0, 0, -o.z)) * behind
        end

        # ---- ON THE SAME WALL, NOT BESIDE --------------------------------
        #
        # ANDRIY'S RULE, and it fixes a bug the run logic could only ever get
        # right by luck: "Я выделяю кабинет. Полка генерируется по задней стене,
        # к которой этот кабинет приторочен."
        #
        # A shelf is not a run element. It butts against nothing, it is cut to
        # any length, and it hangs wherever a person wants it - so "which side
        # of the selected unit" is the wrong question, exactly as it was for the
        # sheet panel above. What a shelf actually needs from the selection is
        # THE WALL: the plane the cabinet's back is against, and the direction
        # that cabinet faces.
        #
        # What went wrong without this: a shelf built off an ISLAND unit
        # inherited the island's facing, and was then dragged to the north wall,
        # where everything faces the other way. It ended up back-to-front - its
        # front symbols, the light and its label pointing into the plaster. The
        # placement was never checked because it looked right in plan.
        #
        # Its BACK lands on the selected unit's back, which is where the wall is;
        # its own depth then comes forward from there into the room. x is zero
        # for the sheet panel's reason - the person places it, and the catalog
        # prices a length without an opinion about where it starts.
        if new_unit && new_unit['object_class'].to_s == 'shelf'
          back = (sel_attrs['depth_mm'] || 0).to_f
          if back <= 0
            raise ArgumentError,
                  "#{sel_attrs['code']} states no depth, so there is no wall behind it to " \
                  'hang a shelf on. Select a unit that carries one.'
          end

          y = back - (new_unit['depth_mm'] || 0).to_f
          on_wall = sel.transformation *
                    Geom::Transformation.translation(Geom::Vector3d.new(0, y.mm, 0))
          o = on_wall.origin
          return Geom::Transformation.translation(Geom::Vector3d.new(0, 0, -o.z)) * on_wall
        end

        # ON TOP OF, so the x offset is zero: it starts where the run it stands
        # on starts. The lift itself is in base_z_mm and not here - the box is
        # drawn from z0 upward, exactly as a wall unit's is.
        if new_unit && new_unit['stands_on_top_mm']
          on = sel.transformation
          o  = on.origin
          return Geom::Transformation.translation(Geom::Vector3d.new(0, 0, -o.z)) * on
        end

        side = placement_side(model, sel, span)
        new_width_mm = new_unit && new_unit['width_mm']
        new_depth_mm = new_unit && new_unit['depth_mm']

        # THE TURN. If the selected unit is a corner and the side the rule chose
        # is the corner's WASTED end - the one facing the perpendicular wall -
        # the run does not continue, it turns. Everything about where it lands
        # is in Placement.corner_turn_seat, pinned by a check against the turn
        # Andriy placed by hand in Avenida Primavera.
        turn = corner_turn_for(sel_attrs, span, side, new_width_mm, new_depth_mm)
        if turn
          x, y, angle = turn
          shifted = sel.transformation *
                    Geom::Transformation.translation(Geom::Vector3d.new(x.mm, y.mm, 0)) *
                    Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0),
                                                  Geom::Vector3d.new(0, 0, 1),
                                                  angle.degrees)
          o = shifted.origin
          return Geom::Transformation.translation(Geom::Vector3d.new(0, 0, -o.z)) * shifted
        end

        # RIGHT steps past this unit's high end. LEFT steps back by the NEW
        # element's own width, because a unit is drawn from its origin forwards
        # - so to sit on the left its origin must land that much before this
        # one's low end. Without the new width there is nothing to step back by
        # and the run continues right, which is what it always did.
        #
        # :blocked - both sides attached - ALSO BUILDS, on the right. Andriy,
        # 2026-08-24: "if it lands on the wrong side I can always move it with
        # the mouse; what matters is that the run continues." So the rule still
        # STATES that both sides are taken, because that is a fact and a check
        # holds it, and the policy of what to do about it lives here, in the
        # caller, where a person decided it. Never blocking beats never being
        # wrong: a unit in the wrong place can be dragged, a unit that was not
        # built has to be asked for twice.
        offset =
          if side == :left && new_width_mm
            span[0] - new_width_mm.to_f
          else
            span[1]
          end

        t = sel.transformation
        shifted = t * Geom::Transformation.translation(Geom::Vector3d.new(offset.mm, 0, 0))
        # pin to the floor regardless of where the selected unit sits
        o = shifted.origin
        Geom::Transformation.translation(Geom::Vector3d.new(0, 0, -o.z)) * shifted
      end

      def selected_unit(model)
        model.selection.grep(Sketchup::ComponentInstance).find do |i|
          i.definition.get_attribute(Contract::DICTIONARY, 'code')
        end
      end

      # What a unit occupies along its own x, as [lo, hi]. ONE implementation:
      # run_extent_mm reads its high end and the place tool asks the same
      # question when it snaps a joint. It used to be written twice.
      def span_for_attrs(attrs)
        return Placement.span_mm(width_mm: attrs['width_mm'].to_f) if attrs['width_mm']
        return nil unless attrs['corner_geometry'] && attrs['code']

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

      # nil unless the selected unit is a corner AND the chosen side is its
      # wasted end. The execution letter is what says which end that is, and it
      # lives in the registry rather than on the object, so it is looked up.
      def corner_turn_for(sel_attrs, span, side, new_width_mm, _new_depth_mm)
        return nil unless sel_attrs['geometry_kind'].to_s == 'corner'
        return nil unless new_width_mm && sel_attrs['depth_mm']

        unit = begin
          Registry.lookup(sel_attrs['code'])
        rescue StandardError
          nil
        end
        return nil unless unit

        turn_end = Placement.corner_turn_end(unit['execution'])
        return nil unless Placement.turning?(side, turn_end)

        # THE RUN'S depth, which at a corner is the corner's own - not the new
        # element's. A shallow filler joins the run at its FRONT, exactly as
        # B70501 does at d.350 in the 620 run of Avenida Primavera.
        Placement.corner_turn_seat(span, turn_end, new_width_mm,
                                   sel_attrs['depth_mm'].to_f,
                                   FILLER_MM, Standards::FRONT_GAP_MM)
      end

      # The SketchUp half of the side rule: gather what already touches the
      # selected unit, in ITS frame, and let the pure rule decide. Everything
      # that can be got wrong about geometry is here; everything that can be
      # got wrong about the decision is in Placement.side_beside, where a
      # headless check can reach it.
      def placement_side(model, sel, span)
        mine = Contract.read(sel.definition)
        t    = sel.transformation
        xv   = Geom::Vector3d.new(1, 0, 0).transform(t); xv.normalize!
        yv   = Geom::Vector3d.new(0, 1, 0).transform(t); yv.normalize!

        spans = []
        model.entities.grep(Sketchup::ComponentInstance).each do |other|
          next if other == sel

          a = Contract.read(other.definition)
          next unless a['code'] && a['depth_mm']

          other_span = span_for_attrs(a)
          next unless other_span

          ot   = other.transformation
          axis = Geom::Vector3d.new(0, 1, 0).transform(ot); axis.normalize!

          # MEASURED AT THE FRONT, NOT AT THE BACK - corrected 2026-08-24 after
          # Andriy reported that a run with something on its right still built
          # right. A row is aligned at its FRONT: a 350 filler stands in a 620
          # run with its back 270 mm off the wall, and 270 is nine times
          # COPLANAR_TOL_MM, so measuring backs made every shallow neighbour
          # INVISIBLE to the rule. Invisible on the right means the right looks
          # free, and the run keeps growing into it.
          #
          # The origin IS the front edge - a unit is drawn from it forwards -
          # so the two origins projected on the depth axis are the two front
          # planes. This is the third time today the same distinction decided
          # something: the 8x8 leg, the turn, and now this.
          offset = (ot.origin - t.origin).dot(yv).to_mm

          next unless Placement.same_row?(mine['mounting'], a['mounting'],
                                          axis.dot(yv), offset)

          ends = other_span.map do |x|
            (Geom::Point3d.new(x.mm, 0, 0).transform(ot) - t.origin).dot(xv).to_mm
          end
          spans << ends.minmax
        end

        Placement.side_beside(span[0], span[1], spans)
      end

      # ---- corner units ---------------------------------------------------
      #
      # A corner unit is not a wider cabinet: its carcass is not symmetric and
      # its footprint is not its box. Decoded from printed p.42 with Andriy,
      # 2026-08-17:
      #
      #   * the LETTER in the code is the EXECUTION — which end carries the
      #     door and the 8x8 filler. S = door at the left end, D = mirrored.
      #     Turning a corner unit round would put its front against the wall,
      #     so the mirror is a different article, and a U-shaped kitchen needs
      #     both. The door's own hand (LH/RH) is the ordinary per-order
      #     hinge_side and changes nothing in the code.
      #   * the 8x8 is ONE solid L: front leg 80 along the wall, return 80
      #     projecting FORWARD of the front plane, both 22 thick, inner faces
      #     flush. Door and filler share the front height, so door 75 shortens
      #     both.
      #   * the printed W notation is the NODE, not the box: second number =
      #     depth + 80, first = nominal length along the door wall. Nominal
      #     minus carcass = WASTED SPACE, the unreachable corner depth. It is
      #     drawn as edges only on its own tag, because it is space that must
      #     stay free, not something we sell.
      WASTED_TAG = 'UCON — Wasted space'
      FILLER_MM  = 80

      # Said once, in the group name and in the notes, spelled the same both
      # times so a search for it finds every place the claim is made.
      CUTOUT_LABEL = '(cutout: INDICATIVE)'
      # AND ITS SIBLING, 2026-08-26. A glass DOOR is not an appliance APERTURE
      # and the two must not wear one label: an aperture's rails come from a
      # machine's published specification and are INDICATIVE of it, while a
      # glass door's frame is a number UCON declared because the catalog prints
      # none. Andriy read the glass chapter, the Unit-structure pages, the
      # technical pages and the filler table himself and confirmed the absence -
      # then set 25 and said to draw it CAD-style. So the label says DECLARED,
      # which is a different claim from INDICATIVE and has to look different in
      # an outliner.
      GLASS_FRAME_LABEL = '(frame: DECLARED)'

      # GLASS_RGB WAS HERE AND IS DELETED, 2026-08-26 (Andriy). It was a cool
      # grey chosen on 2026-08-22 to be "plainly not the front's white" - and
      # 205,214,218 sat close enough to the 164,178,187 SketchUp paints on an
      # unpainted BACK face that the drawing read as a modelling error. He
      # looked at the west wall and asked whether he was seeing the reverse of
      # a surface. He was not; he was seeing our own decision. A colour that
      # makes a correct drawing look wrong has failed at the only job it had.
      #
      # The pane now takes its own door's material and the glass is said by the
      # hatch - see draw_front_slab, and HATCH_ANGLE_DEG in 70_symbols.
      # A reservation reads as a warning, not as a material. Same red the
      # appliance module already uses for the void above a housing, so the two
      # halves of one concept look like one concept in the model.
      VOID_RGB  = [214, 69, 65].freeze
      # A niche is decided, so it does not shout. Grey, not red.
      OPENING_RGB = [150, 156, 160].freeze

      # Reach of the selected unit along its own +x, in millimetres, or nil.
      # A corner carries no width by contract, so its reach comes from the
      # registry: the node it occupies, read through the execution letter.
      def run_extent_mm(definition)
        span = span_for_attrs(Contract.read(definition))
        span && span[1]
      end

      def corner_parts(unit, front_height_mm = nil)
        s        = Standards
        carcass  = unit['carcass_length_mm']
        door     = unit['door_width_mm']
        depth    = unit['depth_mm']
        nominal  = unit['corner_geometry'].to_s.split('x').first.to_i
        front_h  = front_height_mm || unit['height_mm']
        front_y  = front_y_mm
        back_y   = front_y + s::FRONT_T_MM
        out_y    = back_y - FILLER_MM
        wasted   = nominal - carcass
        left     = unit['execution'] == 'left'

        if left
          door_x = 0
          fill_l = door
          # 77, NOT 80, AND THE 3 MM IS THE FRONT GAP. The catalog prints this
          # panel as 8x8 and that is the NOMINAL. The leg that runs along the
          # width is the one the neighbouring run meets, and the run's FRONT
          # stands FRONT_GAP_MM proud of its carcass - so a leg of a full 80
          # overshoots the front it is supposed to meet by exactly that gap.
          # Measured in Avenida Primavera 2026-08-24; the return leg, which
          # meets nothing, keeps its 80. (A UCON decision, its scope recorded - learned rule 4.)
          out_x  = fill_l + FILLER_MM - s::FRONT_GAP_MM
          in_x   = out_x - s::FRONT_T_MM
          plan   = [[fill_l, back_y], [out_x, back_y], [out_x, out_y],
                    [in_x, out_y], [in_x, front_y], [fill_l, front_y]]
          wasted_x = carcass
        else
          door_x = carcass - door
          fill_l = door_x - FILLER_MM
          out_x  = fill_l + s::FRONT_GAP_MM
          in_x   = out_x + s::FRONT_T_MM
          plan   = [[fill_l + FILLER_MM, back_y], [out_x, back_y], [out_x, out_y],
                    [in_x, out_y], [in_x, front_y], [fill_l + FILLER_MM, front_y]]
          wasted_x = -wasted
        end

        { carcass: carcass, depth: depth, door: door, door_x: door_x,
          front_h: front_h, front_y: front_y, filler_plan: plan,
          wasted: wasted, wasted_x: wasted_x, nominal: nominal }
      end

      # Every part of a corner unit, drawn into a definition. Extracted from
      # build so that CHANGING the execution redraws it by the same path -
      # a second copy of this would be a second chance to update only one.
      def draw_corner(definition, unit, model)
        s = Standards
        e = definition.entities
        p = corner_parts(unit)
        z0 = base_z_mm(unit)

        draw_plinth(e, unit, model)

        front_mat = Geometry.material(model, 'UCON_Front_White', [245, 245, 245])
        Geometry.box(e, 'CARCASS', 0, 0, z0, p[:carcass], p[:depth],
                     unit['height_mm'],
                     Geometry.material(model, 'UCON_Carcass_Light_Gray', [220, 220, 216]))
        Geometry.box(e, 'FRONT', p[:door_x], p[:front_y], z0,
                     p[:door], s::FRONT_T_MM, p[:front_h], front_mat)
        Geometry.prism(e, 'FILLER_8X8', p[:filler_plan], z0, p[:front_h], front_mat)

        return unless p[:wasted].positive?

        g = Geometry.wire_box(
          e, 'WASTED_SPACE', p[:wasted_x], 0, z0,
          p[:wasted], p[:depth], unit['height_mm'],
          Geometry.material(model, 'UCON_Placeholder_Gray', [138, 138, 138])
        )
        tag = model.layers[WASTED_TAG] || model.layers.add(WASTED_TAG)
        g.layer = tag
        g.entities.grep(Sketchup::Edge).each { |ed| ed.layer = tag }
      end

      # Turn a corner unit into its sibling article - the same node with the
      # door and the 8x8 at the other end.
      #
      # The letter belongs to the WALL, so placement decides it and does not
      # ask (Andriy, 2026-08-20). Silent applies to the GESTURE only: the code,
      # the name and the notes are all rewritten, so nothing reaches an order
      # that the model does not state plainly. A mirror of the instance would
      # not do - the carcass is not symmetric, and it is a different article.
      def swap_corner_execution!(instance, model = Sketchup.active_model)
        attrs   = Contract.read(instance.definition)
        sibling = Registry.sibling_execution_code(attrs['code'].to_s)
        return nil unless sibling

        # Attributes live on the DEFINITION. If two instances share it, editing
        # in place would silently re-article the other one too.
        instance.make_unique if instance.definition.count_instances > 1

        unit = Registry.lookup(sibling)
        definition = instance.definition
        definition.entities.clear!
        draw_corner(definition, unit, model)

        new_attrs = attributes_for(unit)
        new_attrs['notes'] = "#{new_attrs['notes']} Execution chosen by placement " \
                             "from the wall, not by the picker: #{attrs['code']} -> #{sibling}."
        # THE HAND SURVIVES THE SWAP, and now it survives on purpose. The line
        # below draws the symbol with the OLD hinge_side, so the record has to
        # agree with it; attributes_for deliberately never carries a hand, so
        # without this the two would disagree the moment Contract.write!
        # started reconciling (it used to leave the stale value behind, which
        # made them agree by accident). Everything else on this object IS
        # rebuilt from the article a few lines up - draw_corner has just
        # redrawn the geometry - so a panel choice that is not re-applied
        # reverts in the drawing and in the record together. That is the
        # honest outcome; it is not the same as silently keeping it.
        new_attrs['hinge_side'] = attrs['hinge_side'] if
          attrs['hinge_side'] && !attrs['hinge_side'].to_s.empty?
        Contract.write!(definition, new_attrs)
        Symbols.draw(model, definition, unit, attrs['hinge_side'])
        instance.name = "Cesar #{sibling} — #{unit['description']}"
        sibling
      end

      # width_mm is the ORDERED width, and it is nil for almost everything.
      # A filler is priced by height alone and its width is stated per order
      # (printed p.434); with_ordered_width refuses a width for an article that
      # names its own, and refuses to build one that does not without it. See
      # _manifest.json -> order_axes_outside_code.filler_width_mm.
      # height_mm joined width_mm 2026-08-25, and for the same reason: the
      # kitchen asked for a size the page does not print and the answer is a
      # DRAWING, not a refusal. Both go through the registry, which decides
      # whether the change is a printed modification or an unprinted request -
      # this method never decides that and must not learn how.
      def build(code, model = Sketchup.active_model, width_mm: nil, height_mm: nil,
                appliance: nil, installation: nil)
        unit = Registry.with_ordered_height(
          Registry.with_ordered_width(Registry.lookup(code), width_mm), height_mm
        )
        # BEFORE ANY DIMENSION IS READ. base_z_mm, plinth? and the placement
        # transform all ask the unit where it stands, and for a panel the unit
        # cannot answer until its neighbour has.
        if unit['object_class'] == 'panel'
          # TWO PANELS, TWO QUESTIONS, AND THEY ARE NOT THE SAME ONE.
          #
          # An END panel has no ground of its own and takes mounting and plinth
          # off the unit it finishes - that is panel_ground, and the long note
          # beside it says why.
          #
          # A SHEET's ground is never in doubt: printed p.214 says it stands on
          # the floor on 0,5 cm feet, whatever it is bolted to, so nothing is
          # inherited. It still REFUSES without a selection, and for the other
          # reason: a board behind a run has to know which run, and there is no
          # honest default for that either.
          ground = Registry.sheet_panel?(unit) ? sheet_ground(model) : panel_ground(model)
          raise ArgumentError, panel_needs_a_ground_message(code, unit) if ground.nil?

          unit = unit.merge(ground)
        end

        # ---- AN ELEMENT WHOSE GROUND IS ANOTHER UNIT ------------------------
        # printed p.458, in the catalog's own words: 'Can only be fitted below a
        # top.' A Horizontal Thin stands on a base run and a top stands on it.
        # Like an end panel it has no ground of its own, and like an end panel it
        # takes one from the unit it is placed against - through that unit's CODE
        # and the registry, never off its geometry, so the answer is the one the
        # neighbour was built from rather than a measurement of whatever anybody
        # has since moved.
        if stands_on_unit_below?(unit)
          ground = unit_below_ground(model)
          raise ArgumentError, stands_on_needs_a_unit_message(code) if ground.nil?

          unit = unit.merge(ground)
        end

        unless unit.fetch('buildable', true)
          raise ArgumentError,
                "#{code} is in the registry but cannot be built yet.\n\n" \
                "#{unit['not_buildable_reason']}"
        end

        s    = Standards
        # DRAWN, not ordered - see drawn_width_mm. For everything except a
        # scribed filler the two are the same number.
        w    = drawn_width_mm(unit)
        h    = unit['height_mm']
        d    = unit['depth_mm']
        # A base unit stands on its plinth; a wall unit hangs and has neither
        # plinth nor contact with the floor. Everything below is written in
        # terms of z0, so the difference is this one line and the skipped
        # plinth box - the front line, the symbols and build-next-to-selected
        # need no special case.
        #
        # There used to be a `wall` local here, read only by `unless wall`
        # around the plinth. Since 0.51 that question is `plinth?`, which
        # answers no for a hung unit AND for a shim-footed one, so the local
        # had one reader left and it was the wrong question.
        z0 = base_z_mm(unit)

        # WHICH SIDE OF THE SELECTED UNIT (2026-08-24). The new element's own
        # width goes in because stepping LEFT means stepping back by ITS width,
        # not by the selected one's - and a FILLER reaches this line with a
        # width like any cabinet, because with_ordered_width has already turned
        # its catalog range into a number at the top of this method. The rule
        # is the same for both and there is no second path.
        placement = placement_transform(model, unit)

        model.start_operation("UCON: build #{code}", true)
        begin
          carcass_mat = Geometry.material(model, 'UCON_Carcass_Light_Gray', [220, 220, 216])
          front_mat   = Geometry.material(model, 'UCON_Front_White',        [245, 245, 245])

          definition = model.definitions.add(
            "CESAR_#{code}_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
          )
          e = definition.entities

          # An appliance front is a PANEL, not a cabinet: it bolts onto the
          # machine's own door. No carcass — the box behind it is the client's
          # appliance, not a Cesar object. The panel sits on the same front
          # line and at the same height as any other front in the run.
          #
          # A PLINTH only where the registry says the run's plinth carries on
          # under it. A dishwasher gets none: the plinth in front of that
          # machine really is cut away. A US fridge housing gets one, so the
          # plinth line does not break on the drawing where the fridge stands.
          #
          # CORRECTED 2026-08-24 (Andriy, off the Avenida Primavera kitchen).
          # THE SENTENCE ABOVE IS RIGHT ABOUT THE JOINERY AND WRONG ABOUT THE
          # DRAWING, because it answers one question with the other. Two facts
          # wear the word "plinth" here and they are not the same fact:
          #
          #   DRAWN   - what LayOut shows. The line has to run past the machine
          #             unbroken or the elevation reads as a hole. So the
          #             dishwasher panel now gets a plinth box like the fridge
          #             housing does, and that box is a REPRESENTATION. It
          #             claims nothing about what is built.
          #   ORDERED - what the warehouse is asked for. A plinth WITH A
          #             CUTOUT, because the real one in front of the machine
          #             is of course cut away. Today designers order plain
          #             linear plinth and the cutout is improvised on site;
          #             that side is not written yet and is not this method's
          #             business.
          #
          # Nothing in the geometry tells them apart, which is exactly why it
          # is written here: the box below is the DRAWING's answer.
          if unit['object_class'] == 'appliance_front'
            niche_depth = selected_depth_mm(model)

            draw_plinth(e, unit, model) if unit['plinth_continues']
            # Built through the ordinary front_slabs path and named FRONT…, so
            # the properties panel rebuilds it like any other front: choosing
            # door version 75 shortens the panel to 750 with no special case.
            front_slabs(unit).each do |slab|
              draw_front_slab(e, slab, unit, z0, front_mat)
            end
            Contract.write!(definition, attributes_for(unit))
            Symbols.draw(model, definition, unit, nil)

            instance = model.active_entities.add_instance(definition, placement)
            instance.name = "Cesar #{code} — #{unit['description']}"

            # The niche is a SEPARATE object, not part of the panel: opposite
            # natures. The panel is ordered and drawn; the niche is drawn and
            # never ordered. Keeping them apart is what lets the exporter emit
            # one and skip the other.
            niche_attrs = niche_attributes_for(unit, niche_depth, !niche_depth.nil?)
            niche_def = model.definitions.add(
              "UCON_APPLIANCE_NICHE_#{unit['width_mm']}_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
            )
            # Edges only, no surfaces: a solid box would read as a cabinet we
            # are selling. See Geometry.wire_box.
            Geometry.wire_box(
              niche_def.entities, 'APPLIANCE_NICHE',
              0, 0, niche_bottom_mm(unit),
              niche_attrs['width_mm'], niche_attrs['depth_mm'], niche_attrs['height_mm'],
              Geometry.material(model, 'UCON_Placeholder_Gray', [138, 138, 138])
            )
            Contract.write!(niche_def, niche_attrs)
            niche = model.active_entities.add_instance(niche_def, placement)
            niche.name = "Appliance niche #{unit['width_mm']} — client-supplied machine"
            # Its own hideable tag, like the symbol tags: one switch takes every
            # placeholder off the sheet.
            niche.layer = model.layers[PLACEHOLDER_TAG] || model.layers.add(PLACEHOLDER_TAG)

            # And the remainder ABOVE it gets a body, when a machine has been
            # named. See draw_above_housing: without one the height cannot be
            # known, so nothing is drawn and the niche note still says why.
            draw_above_housing(model, unit, placement, appliance, carcass_mat, installation)

            model.selection.clear
            model.selection.add(instance)
            model.commit_operation
            model.active_view.zoom(instance)
            return instance
          end

          if unit['geometry_kind'] == 'corner'
            draw_corner(definition, unit, model)
            Contract.write!(definition, attributes_for(unit))
            Symbols.draw(model, definition, unit, nil)

            instance = model.active_entities.add_instance(definition, placement)
            instance.name = "Cesar #{code} — #{unit['description']}"
            model.selection.clear
            model.selection.add(instance)
            model.commit_operation
            model.active_view.zoom(instance)
            return instance
          end

          draw_plinth(e, unit, model)

          # The group keeps the name CARCASS even for a panel, which is not
          # what a panel is: selected_top_mm and the gap audits measure a box
          # by that name, and renaming it would make a panel invisible to them.
          Geometry.box(e, 'CARCASS', 0, panel_front_y_mm(unit), z0, w, d, h, carcass_mat)

          front_slabs(unit).each do |slab|
            draw_front_slab(e, slab, unit, z0, front_mat)
          end

          Contract.write!(definition, attributes_for(unit))
          # Symbols that need no user choice (drawer crosses) appear at build
          # time; door symbols wait for a hinge_side from the panel.
          Symbols.draw(model, definition, unit, nil)

          instance = model.active_entities.add_instance(definition, placement)
          instance.name = "Cesar #{code} — #{unit['description']}"

          model.selection.clear
          model.selection.add(instance)
          model.commit_operation
          model.active_view.zoom(instance)
          instance
        rescue StandardError
          model.abort_operation
          raise
        end
      end

      # Front layout -> flat slab list, in mm, z measured from the carcass
      # bottom. Slabs butt together with no drawn gap, so each joint reads as
      # exactly one line — the same one-line-per-edge rule as the flush front.
      # Pure; tested headless.
      # THE WIDTH THAT IS DRAWN, WHICH IS NOT ALWAYS THE WIDTH THAT IS ORDERED.
      # A filler is ordered in whole millimetres and rounded UP by rule (owed 2,
      # closed 2026-08-26): a 109,3 clear space is ordered at 110 and 0,7 is
      # scribed off on site. The BODY has to fill 109,3, or the sheet shows a gap
      # that will not exist - so `width_clear_mm` is what gets drawn and
      # `width_mm` stays what gets ordered.
      #
      # ONE ASKER, three readers - build, front_slabs and plinth_width_mm - for
      # the same reason plinth_h_mm has one: three copies of a rule is three
      # chances to update two.
      def drawn_width_mm(unit)
        unit['width_clear_mm'] || unit['width_mm']
      end

      def front_slabs(unit)
        w = drawn_width_mm(unit)
        h = unit['height_mm']
        layout = unit['front_layout'] || { 'kind' => 'single' }

        # A corner unit has no single width: its front is the door, sitting at
        # the end the execution letter decides. Returning it here means the
        # properties panel rebuilds a corner door through the ordinary path.
        if unit['geometry_kind'] == 'corner'
          p = corner_parts(unit, h)
          return [{ name: 'FRONT', x_mm: p[:door_x], z_mm: 0,
                    w_mm: p[:door], h_mm: h }]
        end

        case layout['kind']
        # A PANEL HAS NO FRONT, and the empty list is the whole answer. Stated
        # rather than reached by absence: the `else` below hands anything it
        # does not recognise a full-face slab, which for a 22 mm board beside a
        # run would draw a door on the end of the kitchen.
        when 'none'
          []
        when 'vertical_split'
          n = layout['count'].to_i
          slab_w = w / n.to_f
          (0...n).map do |i|
            { name: "FRONT_#{i + 1}_OF_#{n}",
              x_mm: (i * slab_w).round(1), z_mm: 0,
              w_mm: slab_w.round(1), h_mm: h }
          end
        when 'horizontal'
          slabs_from_stack(front_stack(layout, h), w)
        else
          [{ name: 'FRONT', x_mm: 0, z_mm: 0, w_mm: w, h_mm: h }]
        end
      end

      # THE STACK, IN ONE FORM. A horizontal layout states itself either as
      # `heights_mm_top_to_bottom` - the shorthand, and what 708 of 711 codes
      # use - or as `stack_top_to_bottom`, whose entries carry a kind. The
      # shorthand is the stack with every entry a front, so it is lifted rather
      # than special-cased.
      #
      # Kinds and their meanings: docs/Reserved_Void_Spec_v0.1.md §4.
      #
      # THE SUM CHECK IS THE INVARIANT, not bookkeeping. Printed p.121-125
      # satisfy it on 16 of 16 codes and it is what recovers every number that
      # section does not print - the 600 mm oven niche above all. A section that
      # fails here has been misread, and this raise is where that surfaces.
      # ONE PLACE THAT TURNS A STACK INTO SLABS, and it exists for the same
      # reason draw_front_slab does: 80_panel walked its own copy of this loop
      # for the gola version and dropped every entry that was not a front. That
      # was harmless while the only other kind was an empty 30 mm zone. It stops
      # being harmless the moment an entry is a RESERVATION, because the one
      # thing a reservation must never do is disappear quietly.
      def slabs_from_stack(stack, w)
        z = 0.0
        n = 0
        slabs = []
        stack.reverse_each do |entry|
          hh = entry['h_mm'].to_f
          case entry['kind']
          when 'front'
            n += 1
            slabs << { name: "FRONT_#{n}_FROM_BOTTOM",
                       x_mm: 0, z_mm: z.round(1), w_mm: w, h_mm: hh.round(1) }
          when 'remainder'
            # THE SPAN IS OWNED, THE BODY IS NOT. See §5 of
            # claude/findings-2026-08-25-tall-h210-appliance-columns.md: the
            # catalog prints the SUM of a custom-sized front and the appliance
            # opening below it, and refuses to divide it. Drawing nothing here
            # is what leaves 1125 mm of column unmarked, and in a real kitchen
            # that is what gets built over.
            slabs << { name: "VOID_REMAINDER_#{hh.round}",
                       x_mm: 0, z_mm: z.round(1), w_mm: w, h_mm: hh.round(1),
                       kind: :void, holds: entry['holds'],
                       appliance_class: entry['appliance_class'] }
          when 'appliance_opening'
            # A NICHE IS NOT A VOID, and the difference is the whole point of
            # the concept: a void's division is undecided, a niche's is decided
            # and the appliance is what decides it. printed p.121-125 never
            # print this number - 600 for an oven H.60 is MEASURED, five times
            # over, from what the front stacks leave. See §1 of
            # claude/findings-2026-08-25-tall-h210-appliance-columns.md.
            slabs << { name: "APPLIANCE_OPENING_#{hh.round}",
                       x_mm: 0, z_mm: z.round(1), w_mm: w, h_mm: hh.round(1),
                       kind: :opening, appliance_class: entry['appliance_class'] }
          when 'zone'
            # The gola recess. Drawing_Spec: the 30 mm zone stays empty - it is
            # not a front, and it is not a reservation either, because what
            # fills it is decided and ordered as a GOL profile.
            nil
          else
            raise "front_layout stack: unknown kind #{entry['kind'].inspect}"
          end
          z += hh
        end
        slabs
      end

      def front_stack(layout, h)
        stack = layout['stack_top_to_bottom']
        stack ||= Array(layout['heights_mm_top_to_bottom'])
                  .map { |hh| { 'kind' => 'front', 'h_mm' => hh } }
        total = stack.sum { |e| e['h_mm'].to_f }
        unless (total - h).abs < 0.001
          raise "front_layout heights #{stack.map { |e| e['h_mm'] }.inspect} " \
                "do not sum to #{h}"
        end
        stack
      end

      # ONE PLACE THAT TURNS A SLAB INTO GEOMETRY. This loop stood written out
      # three times - twice in build and once in the properties panel - and a
      # front with a hole in it is exactly the change that gets made in two of
      # the three. Same lesson as front_y_mm, learned the same way.
      def draw_front_slab(entities, slab, unit, z0, material)
        t     = Standards::FRONT_T_MM
        if %i[void opening].include?(slab[:kind])
          return draw_void_slab(entities, slab, unit, z0, t)
        end

        rails = cutout_rails(unit, slab)
        unless rails
          return Geometry.box(
            entities, slab[:name],
            slab[:x_mm], front_y_mm, z0 + slab[:z_mm],
            slab[:w_mm], t, slab[:h_mm], material
          )
        end

        # THE NAME CARRIES THE WARNING. Whoever opens the outliner is the
        # person who can still catch this before it reaches a drawing, and the
        # notes on the definition are one click further away than the tree.
        label = (unit['front_layout'] || {})['glass_frame_mm'] ? GLASS_FRAME_LABEL : CUTOUT_LABEL
        frame = Geometry.framed_slab(
          entities, "#{slab[:name]} #{label}",
          slab[:x_mm], front_y_mm, z0 + slab[:z_mm],
          slab[:w_mm], t, slab[:h_mm], rails, material
        )

        # AND THE GLASS IS DRAWN, not left as a hole (Andriy, 2026-08-22). A
        # void reads as a missing part on an elevation - the pane reads as what
        # it is. Opaque and flat, the CAD convention: a transparent material
        # would show the room through a cabinet in every rendered view, and the
        # draftsman's diagonals live on the elevation tag in 70_symbols.
        #
        # Full front thickness, flush both faces. A thinner pane would be more
        # like the real thing and would need a number no source gives us; the
        # one thickness in play is already in dispute (Cesar 22 against the
        # appliance planning's 19), and inventing a third is how that argument
        # gets lost.
        #
        # THE PANE TAKES THE FRONT'S OWN MATERIAL, 2026-08-26 (Andriy, looking at
        # the west wall): "no need for it to be a different colour - maybe it is
        # the back side of a flat surface." It was not the back side; it was
        # OURS. UCON_Glass_Gray was 205,214,218 and SketchUp paints an unpainted
        # back face 164,178,187 - two grey-blues close enough that a correct
        # drawing looked like a modelling mistake, which is a good enough reason
        # on its own to stop using one of them.
        #
        # SO THE GLASS READING NOW RESTS ENTIRELY ON THE HATCH, and that is the
        # split 70_symbols already describes: the pane is the thing that is
        # really there, the diagonals are the convention that says what it is.
        # A pane the colour of its own door says nothing by itself and is not
        # meant to.
        Geometry.box(
          entities, "#{slab[:name]}_GLASS",
          slab[:x_mm] + rails[:left], front_y_mm,
          z0 + slab[:z_mm] + rails[:bottom],
          slab[:w_mm] - rails[:left] - rails[:right], t,
          slab[:h_mm] - rails[:bottom] - rails[:top],
          material
        )
        frame
      end

      # A RESERVATION, DRAWN. Same plane and same thickness as a front, because
      # that is where it has to appear on an elevation - a band that is missing
      # from the elevation is exactly the information nobody receives. The name
      # carries the number for whoever opens the outliner, the same reason
      # CUTOUT_LABEL is in a name and not only in a note.
      #
      # UNTESTED HEADLESS - it needs SketchUp, like everything that draws. Try
      # it in the model before believing it.
      def draw_void_slab(entities, slab, unit, z0, t)
        void = slab[:kind] == :void
        mat = Geometry.material(entities.model,
                                void ? 'UCON_Void_Red' : 'UCON_Opening_Gray',
                                void ? VOID_RGB : OPENING_RGB)
        mat.alpha = 0.35 if mat.respond_to?(:alpha=)
        box = Geometry.box(
          entities, slab[:name],
          slab[:x_mm], front_y_mm, z0 + slab[:z_mm],
          slab[:w_mm], t, slab[:h_mm], mat
        )
        return box unless box.respond_to?(:set_attribute)

        cls = slab[:appliance_class]
        if void
          holds = Array(slab[:holds])
          box.set_attribute(Contract::DICTIONARY, 'object_class', 'void')
          box.set_attribute(Contract::DICTIONARY, 'void_role', 'front_remainder')
          note = "TO BE FILLED - #{slab[:h_mm].round} mm. Holds: " \
                 "#{holds.empty? ? 'undecided' : holds.map { |x| x.tr('_', ' ') }.join(' + ')}" \
                 "#{cls ? " (#{cls})" : ''}. " \
                 'The catalog prints this span and not its division.'
        else
          # NO object_class HERE, and the absence is deliberate. A niche is part
          # of the cabinet, not a thing beside it; claiming a class for it would
          # put a second object in the order for one article. What it carries is
          # a measurement, and 88_appliance_check is what reads it.
          note = "APPLIANCE OPENING - KEEP CLEAR, #{slab[:h_mm].round} mm" \
                 "#{cls ? " (#{cls})" : ''}. Measured from the printed front " \
                 'stack, not printed as a number.'
        end
        box.set_attribute(Contract::DICTIONARY, 'height_mm', slab[:h_mm])
        box.set_attribute(Contract::DICTIONARY, 'width_mm', slab[:w_mm])
        box.set_attribute(Contract::DICTIONARY, 'notes', note)
        box
      end

      # THE APERTURE, OR NOTHING.
      #
      # The wine cooler front is a solid panel with a rectangular hole in it.
      # Cesar never dimensions that hole - not on the unit page, not in the
      # mechanisms chapter, not in Modifications - and prices it as a flat
      # +50 % variant, which is a price for "this is the wine cooler front",
      # not for a piece of machining of a given size. So the numbers cannot
      # come from the catalog and come from the appliance instead.
      #
      # Three specifications (Miele KWT 6722 iS, Thermador T18IW100SP and
      # T24IW100SP) agree closely on two of the three rails and not at all on
      # the third; the registry records that, and this reads it. Nothing is
      # computed here - see registry/cesar/_manifest.json appliance_apertures.
      #
      # It applies to a WHOLE front only. A slab that is one of several is a
      # split front, and no aperture in this catalog crosses a joint, so a
      # split gets no hole rather than a guessed one.
      def cutout_rails(unit, slab)
        layout = unit['front_layout'] || {}

        # A GLASS DOOR IS A FRAME WITH A PANE IN IT, and every leaf of a glass
        # unit is glazed - so unlike an appliance aperture this does NOT wait
        # for a slab as wide as the whole unit. TF0940 has two glass doors and
        # both are glass; the aperture guard below would have glazed neither.
        frame = layout['glass_frame_mm']
        if frame
          f = frame.to_f
          return { left: f, right: f, bottom: f, top: f }
        end

        cutout = layout['cutout']
        return nil unless cutout
        return nil unless slab[:w_mm] == drawn_width_mm(unit)

        side = cutout['rail_side_mm'].to_f
        { left:   side,
          right:  side,
          bottom: cutout['rail_bottom_mm'].to_f,
          top:    cutout['rail_top_mm'].to_f }
      end

      # Largest LEGRABOX nominal length that fits a carcass depth, from the
      # user-provided Blum table in registry external_specs (overlay column).
      # Internal depth = carcass depth - back inset - back panel (UCON working
      # standards). Returns nil when nothing fits - callers draw nothing then.
      def runner_nl_for(depth_mm)
        spec = Registry.data['external_specs']
        return nil unless spec && spec['legrabox_runners']

        internal = depth_mm - Standards::BACK_INSET_MM - Standards::BACK_T_MM
        fitting = spec['legrabox_runners']['rows']
                  .select { |row| row['min_internal_depth_overlay_mm'] <= internal }
        fitting.max_by { |row| row['nl_mm'] }
      end

      # Travel (front displacement at full extension) for a carcass depth,
      # from the user-provided table (travel = NL - 2, values approximate).
      def runner_travel_for(depth_mm)
        row = runner_nl_for(depth_mm)
        row && row['travel_mm']
      end

      # Registry row -> Object Contract v2 attributes. Pure; tested headless
      # for every code in the registry.
      #
      # opening_method defaults to handle per the Q1 disposition (model the
      # full-height front; gola is a separate non-default option).
      # hinge_side is NOT set here even for handed units — it is a
      # per-placement order choice, and guessing it would violate §6.4.
      # Order lines the catalog obliges alongside this one (Contract v2 §4.2).
      # Resolved from the registry for THIS code's width — never typed by a
      # user, never guessed. Returns a list of LINES (§1.4), or nil when the
      # unit has no companions, so the key stays absent rather than empty.
      #
      # Every line here is origin = implied: the article obliges it, nobody
      # chose it, and it is therefore recomputed on every rebuild. A CHOSEN
      # companion cannot arise in this method at all — it needs an input from a
      # person, which the panel does not yet collect.
      #
      # qty 1 / um PZ is not a guess about the catalog: one companion RULE in
      # the registry resolves to one order line for one piece, which is exactly
      # what the v1 string could express. When registry/cesar/options/ exists,
      # quantity comes from the rule — including the printed calculation rules,
      # like the one that says how many Servo Drive kits a composition needs.
      # THE GOLA PROFILES ARE ORDER LINES, and since 0.49.0 they are companion
      # LINES rather than a single hardware_ref string. The reason is concrete:
      # a drawer stack needs TWO profiles, undercounter plus intermediate, and
      # one string cannot hold two codes. The panel used to join them into
      # "GOL001+GOL002", which reads fine in a dropdown and reaches an order as
      # an article that does not exist - the first real export run printed it.
      #
      # qty is nil ON PURPOSE (Contract v2.1). A profile is bought by the metre
      # along the RUN, which crosses joints between units, so no single cabinet
      # can state the number.
      def gola_profile_refs(unit, system)
        return [] if system.to_s.empty?

        rows = ((Registry.data['hardware'] || {})['gola_profiles'] || [])
               .select { |r| r['system'] == system }
        gola_positions_for(unit).map do |position|
          row = rows.find { |r| r['position'] == position }
          next nil unless row

          { 'code' => row['code'], 'qty' => nil, 'um' => row['um'] || 'ML',
            'origin' => 'implied', 'source_ref' => row['source_ref'] }
        end.compact
      end

      # An undercounter profile closes the front under the worktop; an
      # intermediate one joins stacked front zones, so only a horizontal stack
      # needs the second. Same rule the picker used to apply to its dropdown -
      # moved here, where companions are resolved, because a rule in the UI is
      # a rule the order cannot rely on.
      def gola_positions_for(unit)
        kind = (unit['front_layout'] || {})['kind']
        kind == 'horizontal' ? %w[undercounter intermediate] : %w[undercounter]
      end

      def companion_refs_for(unit, gola_system = nil)
        # map + compact, not filter_map: filter_map is Ruby 2.7 and the headless
        # harness has to run on the Ruby macOS actually ships, which is still
        # 2.6. SketchUp's own Ruby is far newer, so this only ever showed up as
        # nineteen failures on one machine and none on the other.
        lines = (unit['companions'] || []).map do |c|
          code =
            if c['by'] == 'width'
              (c['map'] || {})[unit['width_mm'].to_s]
            elsif c['applies_to_widths_mm']
              c['code'] if c['applies_to_widths_mm'].include?(unit['width_mm'])
            else
              c['code']
            end
          next nil unless code

          line = { 'code' => code, 'qty' => 1, 'um' => 'PZ', 'origin' => 'implied' }
          line['source_ref'] = c['source_ref'] if c['source_ref']
          line
        end
        lines = lines.compact + gola_profile_refs(unit, gola_system)
        lines.empty? ? nil : lines
      end

      # The volume an appliance occupies in the run, NOT the machine itself.
      # Deliberate: the machine is the client's and its real dimensions are not
      # a catalog fact, but the space it takes is — the door width comes from
      # the catalog and the height from our own standards (floor to worktop
      # underside, because an appliance stands on the floor and the plinth in
      # front of it is cut away). Depth is inherited from the run when a
      # neighbour is selected, otherwise the d.62 default, and the note says
      # which happened.
      #
      # It is never an order line: manufacturer is the client, there is no
      # code, and the exporter must skip object_class = appliance.
      NICHE_DEFAULT_DEPTH_MM = 620
      PLACEHOLDER_TAG        = 'UCON — Placeholder (not ours)'

      # HOW TALL THE APPLIANCE'S SPACE IS - asked of the object, not assumed.
      # It was PLINTH_H_MM + 780, hard-wired to a dishwasher under a worktop,
      # and it drew an 880-tall box behind a 2100 fridge panel: a phantom base
      # cabinet standing where the fridge is. The rule that replaces it gives
      # the SAME 880 for the dishwasher, because a dishwasher panel really does
      # run from the plinth to the worktop underside.
      # A niche has a BOTTOM as well as a top, and until 0.43 it had neither of
      # its own. Floor to the top of the panel is right for a dishwasher: the
      # machine stands on the floor and the panel covers its opening. For a US
      # fridge housing it was wrong at both ends - the phantom came out from
      # under the plinth, and it ran 66,4 past the real cutout at the top.
      #
      # Both ends now come from the registry when the family states them, and
      # the old rule stands unchanged for every family that does not.
      def niche_bottom_mm(unit)
        niche = unit['appliance_niche']
        return 0 unless niche
        # The top of the plinth - THIS unit's plinth, which since 0.51 is a
        # family fact rather than a global 100. The older comment here said
        # "the plinth height is a standard and stays one"; the factory
        # drawings say otherwise for H.84, so it is asked of the object like
        # everything else (domain rule 5). Still no second copy of the number: the
        # family states it once and this reads it.
        return plinth_h_mm(unit) if niche['bottom'] == 'plinth_top'

        niche['bottom_mm'].to_f
      end

      def niche_top_mm(unit)
        niche = unit['appliance_niche']
        # The old rule - the top of the front - answers for anything stating no
        # housing AND, since 2026-08-24, for anything stating only where its
        # housing BEGINS. The dishwasher panel is the second case: its phantom
        # starts on the plinth like the fridge's and ends where the panel ends.
        # Writing 880 into the registry would have put a second copy of
        # 100 + 780 somewhere it can drift away from the family that owns it.
        return base_z_mm(unit) + unit['height_mm'] if niche.nil? || niche['top_mm'].nil?

        niche['top_mm'].to_f
      end

      def niche_height_mm(unit)
        niche_top_mm(unit) - niche_bottom_mm(unit)
      end

      # Said on the object, because both numbers come from outside Cesar and
      # nobody reading the model would otherwise know where to argue with them.
      def niche_span_note(unit)
        niche = unit['appliance_niche']
        return '' unless niche

        note = "Housing drawn #{niche_bottom_mm(unit).round(1)} to " \
               "#{niche_top_mm(unit).round(1)} above the floor - the appliance " \
               "maker's required cutout, not a Cesar dimension, so INDICATIVE " \
               'like the aperture. '
        # 2026-08-24: a housing raised onto the plinth because the DRAWING
        # needs it there, not because the machine is, has to say so on itself -
        # otherwise the model states a measurement it never made.
        if niche['bottom_is_representation']
          note += 'The machine itself stands on the floor: the housing is ' \
                  'drawn from the plinth top so the plinth line reads unbroken ' \
                  'on the sheet, and the plinth ORDERED under it is one with a ' \
                  'cutout. '
        end
        # THE SAME SENTENCE READ FROM THE OTHER END, 2026-08-26 (owed 10
        # finding 1). A housing drawn from the FLOOR is honest about the
        # machine and breaks the plinth line, so the drawing has to say what
        # the elevation will show. There the box was raised to keep the line;
        # here the line is kept in front of a housing that starts on the floor.
        # Both are representations and both have to admit it - which is the
        # whole of learned rule 4 applied to our own drawing.
        if niche['bottom'] == 'floor' && unit['plinth_continues']
          note += 'The machine stands on the FINISHED FLOOR and the housing is ' \
                  'drawn from it. The plinth box in front is a REPRESENTATION ' \
                  'that keeps the plinth line unbroken on the sheet, and the ' \
                  'plinth ORDERED there is one with a cutout. '
        end
        # No leftover, no sentence about one. A fridge front runs past its
        # cutout; a dishwasher panel ends exactly where its phantom does, and
        # 880 - 880 is not a closing panel.
        if (base_z_mm(unit) + unit['height_mm']) - niche_top_mm(unit) > 0.001
          note += 'The front runs past it at the top, and that leftover is the ' \
                  'closing panel inside the housing - not this article. '
        end
        note
      end

      def niche_attributes_for(unit, depth_mm = nil, inherited = false)
        d = depth_mm || NICHE_DEFAULT_DEPTH_MM
        {
          'schema_version' => Contract::SCHEMA_VERSION,
          'object_class'   => 'appliance',
          'manufacturer'   => 'client',
          'unit_type'      => "Appliance niche for #{unit['description']}",
          'geometry_kind'  => 'linear',
          'width_mm'       => unit['width_mm'],
          'depth_mm'       => d,
          'height_mm'      => niche_height_mm(unit),
          'code_status'    => 'PRELIMINARY',
          'status'         => 'PLANNING',
          'source_ref'     => unit['source_ref'],
          'notes'          => 'Placeholder for the client-supplied appliance: the SPACE it ' \
                              'occupies in the run, not the machine. Width from the Cesar door ' \
                              "code #{unit['code']}; height = floor to the top of the panel " \
                              '(the appliance stands on the floor and the panel covers its ' \
                              'opening, so the two share a top - unless the family states a ' \
                              'housing of its own); ' \
                              "depth #{inherited ? 'inherited from the neighbouring unit' : 'defaulted to d.62 - no neighbour was selected'}. " \
                              'TWO STATES, AND THE OBJECT SAYS WHICH IS WHICH (2026-08-26, owed ' \
                              '10 findings 2 and 3). The width above is the Cesar door NOMINAL, ' \
                              'declared for the drawing - it is not the machine\'s cutout, and for ' \
                              'built-in refrigeration the two differ with the sign of the ' \
                              'installation: the published opening is NARROWER than the door at a ' \
                              'standard install and WIDER at flush inset, from one nominal. The ' \
                              'depth is MEASURED when a neighbour was selected and DECLARED ' \
                              'otherwise. The required cutout is deliberately not copied here: ' \
                              'ApplianceCheck asks the appliance module for it live, because a ' \
                              'second copy of a published number is a second thing to go stale. ' \
                              'Name the machine and the seam reports every disagreement. ' \
                              "#{niche_span_note(unit)}" \
                              'Never an order line: the machine is not a Cesar object. The ' \
                              "page's 'cutout for plinth 40' is recorded as unresolved and is not drawn."
        }
      end

      # ------------------------------------------- the remainder above a housing
      #
      # 2026-08-26, Andriy, owed 10 finding 4. In a 2200 run a Designer column
      # leaves 66 mm above its opening and a Classic 73, and the engine drew
      # NOTHING there. The niche note called the span "the closing panel inside
      # the housing"; no closing panel existed. A span named in prose and drawn
      # by no body is the silent deletion SS4.2 rule 4 forbids, wearing a
      # sentence as a disguise.
      #
      # THREE NUMBERS AND NOT ONE OF THEM IS OURS. The HEIGHT is what is left
      # over the machine's published opening; the SETBACK is an appliance rule
      # (a Sub-Zero hinge draws the panel inward as the door opens); the
      # MATERIAL is one too. The engine owns only where the run's top is. They
      # are therefore asked through the seam, in the direction the seam already
      # runs, and NOTHING IS DRAWN UNTIL A MACHINE IS NAMED - the same shape as
      # B6's run gap: the number that fixes the body does not exist until
      # somebody says which machine stands there.
      #
      # THE ARTICLE IS OPEN AND THE OBJECT SAYS SO. A filler is priced by
      # HEIGHT and printed p.434 prints no H.66 and no H.73, so there is no
      # code to give this. It goes out as a row with no article - which the
      # exporter already prints as "CUSTOM SIZE - NO ARTICLE, to be quoted" -
      # rather than as a guess that would look answered.
      def above_housing_attributes_for(unit, info)
        {
          'schema_version' => Contract::SCHEMA_VERSION,
          'object_class'   => 'filler',
          'manufacturer'   => 'Cesar',
          'unit_type'      => "Closing filler above the #{info['model']} housing",
          'geometry_kind'  => 'linear',
          'width_mm'       => unit['width_mm'],
          'depth_mm'       => Standards::PANEL_T_MM,
          'height_mm'      => info['h_mm'],
          'code_status'    => 'PRELIMINARY',
          'status'         => 'PLANNING',
          'source_ref'     => unit['source_ref'],
          'notes'          => "The span left above #{info['model']}'s published opening " \
                              "inside our own #{unit['height_mm']} run: " \
                              "#{info['bottom_mm'].round(1)} to #{info['top_mm'].round(1)} " \
                              'above the floor. THE HEIGHT IS THE MACHINE\'S, not Cesar\'s - ' \
                              'it is the run top less the published opening, so it moves with ' \
                              'the installation type. Set back ' \
                              "#{info['setback_mm']} mm from the front plane because the " \
                              'appliance hinge draws the panel inward; material ' \
                              "#{info['material']}. NO ARTICLE YET: a filler is priced by " \
                              'height and the page prints none at this height, so the code is ' \
                              'deliberately absent rather than guessed, and the appliance ' \
                              "rules offer #{Array(info['fill']).join(' or ')}. " \
                              'Until it is answered this is a row to be quoted, not a code. ' \
                              'NOT VISIBLE ON AN ELEVATION, and that is a decision rather than ' \
                              'an oversight (Andriy, 2026-08-26). The Cesar front in front of ' \
                              'this strip is drawn NOMINAL to the top of the run, so it covers ' \
                              'this band; the panel Sub-Zero actually supplies is shorter - its ' \
                              'typical column panel is 2029 on a 102 toe kick with a 3 reveal, ' \
                              'which is 69 below our 2200. The nominal rule was confirmed in ' \
                              'the WIDTH axis on the same reading (762 drawn, 756 supplied) and ' \
                              'is kept in the height axis too. So this article is an ORDER LINE ' \
                              'and not a face: somebody must still make it, and the sheet will ' \
                              'not show it.'
        }
      end

      def draw_above_housing(model, unit, placement, appliance, material, installation = nil)
        return nil unless appliance
        return nil unless defined?(ApplianceCheck) && ApplianceCheck.available?

        info = ApplianceCheck.above_housing(
          unit, appliance, 'installation' => installation
        )
        return nil unless info['checked'] && info['applies']
        return nil if info['error'] || info['h_mm'].to_f <= 0.5

        attrs = above_housing_attributes_for(unit, info)
        defn  = model.definitions.add(
          "UCON_ABOVE_HOUSING_#{unit['width_mm']}_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
        )
        Geometry.box(
          defn.entities, 'FILLER_ABOVE_HOUSING',
          0, front_y_mm + info['setback_mm'].to_f, info['bottom_mm'],
          attrs['width_mm'], attrs['depth_mm'], attrs['height_mm'], material
        )
        Contract.write!(defn, attrs)
        inst = model.active_entities.add_instance(defn, placement)
        inst.name = "Filler above #{appliance} — #{attrs['height_mm'].round(1)} mm, no article yet"
        inst
      end

      # Depth of the selected UCON unit, so a niche can inherit the run it is
      # placed into instead of guessing.
      def selected_depth_mm(model)
        sel = model.selection.grep(Sketchup::ComponentInstance).first
        return nil unless sel

        attrs = Contract.read(sel.definition)
        d = attrs && attrs['depth_mm']
        d && d.to_i.positive? && d.to_i != Standards::FRONT_T_MM ? d.to_i : nil
      rescue StandardError
        nil
      end

      # ---- where an end panel sits, once it has a ground --------------------
      #
      # BOTH OF THESE ARE ANDRIY'S, 2026-08-26, looking at the first two YU0028
      # in the model. Both are drawing decisions the catalog does not make, and
      # both were wrong in the first version because the panel was built through
      # the ordinary cabinet path, which answers a cabinet's questions.
      #
      # ON THE FLOOR, NOT ON THE PLINTH. A cabinet stands on its plinth and the
      # plinth is drawn under it. A panel runs PAST the plinth to the floor -
      # the plinth returns behind it - so its bottom is the floor and nothing is
      # drawn beneath it. The first version inherited plinth_h_mm from the
      # neighbour and used it as a datum, which is what panel_ground is for; the
      # ground answers WHICH FLOOR, not how high above it.
      #
      # A hung panel is the other case and keeps the hung datum: "on the floor"
      # is meaningless 1400 up a wall.
      def panel_base_z_mm(unit)
        wall_hung?(unit) ? mount_bottom_mm(unit) : 0.0
      end

      # ITS FRONT EDGE IS IN THE PLANE OF THE DOORS. Every unit is drawn from
      # its origin BACKWARDS from the front line, so y = 0 is the CARCASS front
      # and a door occupies the 22 mm in front of it. A panel drawn at y = 0
      # therefore finished 22 mm behind the fronts it adjoins - which is exactly
      # what Andriy saw. It starts one front thickness further forward.
      #
      # The 3 mm this leaves at the back is the catalog's own rounding: d.64,5
      # is 620 of carcass plus 22 of door rounded up from 642. The panel is
      # longer than the thing it finishes, and the surplus has to be at one end
      # or the other. It goes at the BACK, where a wall hides it - the front is
      # the edge that must line up, and that is the whole point of the article.
      # AND A SHEET IS THE OTHER CASE, 2026-08-27. Everything above is about an
      # end panel, which finishes a run from the SIDE and therefore has a front
      # edge that must land in the plane of the doors. A panel behind a run has
      # no front edge at all - it is seen from the room side, its face is its
      # width, and shifting it forward by a door thickness would push it into
      # the carcass it is bolted to. Its y is where the placement puts it.
      def panel_front_y_mm(unit)
        return 0.0 unless (unit || {})['object_class'].to_s == 'panel'
        return 0.0 if Registry.sheet_panel?(unit)

        -Standards::FRONT_T_MM.to_f
      end

      # ---- an end panel's ground -------------------------------------------
      #
      # WHERE AN END PANEL'S BOTTOM SITS IS NOT A CATALOG FACT, and the panel
      # pages are the first section in this registry where that is true. Every
      # other object knows its own ground because its FAMILY does: a base unit
      # stands on the H.78 plinth, a wall unit hangs. printed p.440 prices
      # SIXTEEN heights in one table - H.36 beside H.278 - and says nothing
      # about where any of them begins, because the honest answer is "wherever
      # the run it joins begins". A panel is a board beside a kitchen, not a
      # module in it.
      #
      # So the panel does not guess: it reads the ground off the unit it is
      # placed beside, through that unit's CODE and the registry, not off its
      # geometry. Going through the code is what makes the answer the same one
      # the neighbour was built from - a measured bottom would also be a
      # measurement of whatever anybody has since moved.
      #
      # Returns nil when there is nothing to read, and build refuses rather
      # than defaulting. Standards::PLINTH_H_MM would have been RIGHT for the
      # island and wrong for every wall-height panel in the same table, which
      # is the kind of default that survives until it reaches a sheet.
      def panel_ground(model)
        sel = selected_unit(model)
        return nil unless sel

        attrs = Contract.read(sel.definition) || {}
        code  = attrs['code'].to_s
        return nil if code.empty?

        neighbour = Registry.lookup(code)
        { 'mounting'         => neighbour['mounting'],
          'mounting_default' => neighbour['mounting_default'],
          'plinth_h_mm'      => neighbour['plinth_h_mm'],
          'ground_from_code' => code }
      rescue StandardError
        nil
      end

      # A SHEET DOES NOT INHERIT - it stands on the floor and says so. What the
      # selection gives it is WHERE, not how high: placement_transform seats it
      # against the back of whatever is selected.
      def sheet_ground(model)
        sel = selected_unit(model)
        return nil unless sel

        attrs = Contract.read(sel.definition) || {}
        code  = attrs['code'].to_s
        return nil if code.empty?

        { 'mounting' => 'floor', 'plinth_h_mm' => 0, 'ground_from_code' => code }
      rescue StandardError
        nil
      end

      def stands_on_unit_below?(unit)
        (unit || {})['stands_on'].to_s == 'unit_below'
      end

      # The CARCASS TOP of the selected unit, from its code: where it stands plus
      # how tall it is. A floor unit's plinth is part of the answer; a hung one's
      # mount height is.
      def unit_below_ground(model)
        sel = selected_unit(model)
        return nil unless sel

        attrs = Contract.read(sel.definition) || {}
        code  = attrs['code'].to_s
        return nil if code.empty?

        below = Registry.lookup(code)
        top = base_z_mm(below).to_f + below['height_mm'].to_f
        return nil unless top.positive?

        { 'stands_on_top_mm' => top, 'stands_on_code' => code }
      rescue StandardError
        nil
      end

      def stands_on_needs_a_unit_message(code)
        "#{code} cannot stand on the floor.\n\n" \
        "printed p.458 opens with 'Can only be fitted below a top', and the page " \
        'draws the three in order: a set of base units underneath, this module, ' \
        "and a mandatory top above. So its bottom is the top of the run it joins, " \
        "and there is no honest default for which run.\n\n" \
        'Select the unit it sits on and build again. Nothing was drawn.'
      end

      def panel_needs_a_ground_message(code, unit = nil)
        if unit && Registry.sheet_panel?(unit)
          return "#{code} is a panel cut to size, and it needs a run to stand behind.\n\n" \
                 'Linear Elements printed p.214 prices it by the square metre and ' \
                 'draws it in one place: behind base units, on adjustable feet, ' \
                 'fixed to their backs with a kit. Which units decides where the ' \
                 "board goes and how many kits the order carries.\n\n" \
                 'Select the unit the panel starts behind and build again. Nothing ' \
                 'was drawn - a board dropped at the origin is not a placement.'
        end

        "#{code} is an end panel, and an end panel has no ground of its own.\n\n" \
        "printed p.440 prices sixteen heights in one table and states where none " \
        "of them begins, because that is a fact about the run, not about the " \
        "article. Select the unit this panel finishes and build again: the panel " \
        "takes that unit's mounting and plinth through its code.\n\n" \
        "Nothing was drawn - a panel dropped on a guessed datum is a wrong " \
        "elevation that looks like a right one."
      end

      # ---- THE WORKTOP, 2026-08-27 -----------------------------------------
      #
      # THE FIRST OBJECT IN THIS MODEL WITH object_class 'worktop'. The Contract
      # has allowed the word since v1; nothing ever wrote it, which is why
      # core/08_project.rb says in as many words that the thickness "cannot be
      # measured, in that model or in any other like it". It still cannot. What
      # CAN be measured is everything else, and this method measures all of it.
      #
      #   LENGTH and DEPTH  - from the selected run.
      #   THE TOP IT SITS ON - from each selected unit's CODE and the registry,
      #                        the same way an end panel takes its ground.
      #   THICKNESS          - STATED on the model, and refused if nobody stated it.
      #
      # AND IT REFUSES A RUN THAT DOES NOT AGREE WITH ITSELF. Two units of
      # different heights under one slab is not a worktop, it is two; drawing one
      # would put a surface through the middle of a cabinet and call it a
      # measurement. The message names both heights.
      #
      # DRAWN, NOT ORDERED. The tops chapter is Volume 3 printed p.9-71 and is
      # not extracted, so this object carries no code and says so on itself -
      # the same shape as the run gap, and for the same reason: a factory must
      # not receive a line nobody can make, and a person must see the surface.
      def build_worktop(model = Sketchup.active_model)
        t = Project.worktop_t_mm(model)
        if t.nil?
          raise ArgumentError,
                "No worktop thickness is stated on this model.\n\n" \
                'A worktop is 20, 30, 40 or 60 depending on what the client chose, ' \
                'and no drawn body here can be measured for it. State it once - it ' \
                'is kept on the model and every run uses the same number.'
        end

        picked = model.selection.grep(Sketchup::ComponentInstance).select do |i|
          a = (Contract.read(i.definition) rescue nil)
          a && a['code'] && %w[cabinet corner_unit].include?(a['object_class'].to_s)
        end
        if picked.empty?
          raise ArgumentError,
                "Select the run this top covers.\n\n" \
                'A worktop has no length of its own: it is as long as what is under ' \
                'it. Select one unit for one unit, or the whole run for the whole run.'
        end

        anchor = picked.min_by { |i| i.transformation.origin.x.to_mm }
        frame  = anchor.transformation
        inv    = frame.inverse

        tops = {}
        lo = nil
        hi = nil
        picked.each do |i|
          a = Contract.read(i.definition)
          u = Registry.lookup(a['code'])
          tops[(base_z_mm(u).to_f + u['height_mm'].to_f).round(1)] ||= a['code']
          w = drawn_width_mm(u).to_f
          [0.0, w].each do |x|
            pt = Geom::Point3d.new(x.mm, 0, 0).transform(i.transformation).transform(inv)
            v  = pt.x.to_mm
            lo = lo.nil? || v < lo ? v : lo
            hi = hi.nil? || v > hi ? v : hi
          end
        end

        if tops.length > 1
          raise ArgumentError,
                "That is two worktops, not one.\n\n" \
                "The selection stands at #{tops.keys.sort.join(' and ')} mm - " \
                "#{tops.values.join(', ')}. One slab across two heights would run " \
                'through the middle of a cabinet. Select one run at a time.'
        end

        top   = tops.keys.first
        depth = Registry.lookup(Contract.read(anchor.definition)['code'])['depth_mm'].to_f
        y0    = front_y_mm
        d     = depth - y0
        w     = (hi - lo).round(1)

        attrs = {
          'schema_version' => Contract::SCHEMA_VERSION,
          'object_class'   => 'worktop',
          # Nobody has chosen the article. Volume 3 prints tops on p.9-71 and
          # this registry holds none of it, so the honest manufacturer is the
          # one who has not been asked yet.
          'manufacturer'   => 'client',
          'unit_type'      => 'Worktop - drawn, not ordered',
          'geometry_kind'  => 'linear',
          'width_mm'       => w,
          'depth_mm'       => d.round(1),
          'height_mm'      => t,
          'code'           => nil,
          'code_status'    => 'PRELIMINARY',
          'status'         => 'PLANNING',
          'source_ref'     => 'no article chosen - CESAR - 3 Linear Elements.pdf printed p.9-71 is the tops chapter and is not extracted',
          'notes'          => "Length #{w.round} and depth #{d.round} MEASURED off the run; " \
                              "it starts at #{top.round}, which is that run's top taken through its " \
                              "code and not off a body somebody may have moved; thickness #{t.round} " \
                              'STATED on the model. NOT ORDERED: no top article is chosen, and this ' \
                              'object must not reach a factory as a line.'
        }
        Contract.validate!(attrs)

        model.start_operation('UCON: build worktop', true)
        begin
          defn = model.definitions.add("UCON_WORKTOP_#{Time.now.strftime('%Y%m%d_%H%M%S')}")
          mat  = Geometry.material(model, 'UCON_Worktop_Stone', [200, 200, 198])
          Geometry.box(defn.entities, 'CARCASS', lo, y0, top, w, d, t, mat)
          Contract.write!(defn, attrs)
          o = frame.origin
          seat = Geom::Transformation.translation(Geom::Vector3d.new(0, 0, -o.z)) * frame
          inst = model.active_entities.add_instance(defn, seat)
          inst.name = "UCON worktop - #{w.round} x #{d.round} x #{t.round}, drawn not ordered"
          model.selection.clear
          model.selection.add(inst)
          model.commit_operation
          inst
        rescue StandardError
          model.abort_operation
          raise
        end
      end

      # ---- the run gap, B6 -------------------------------------------------
      #
      # A SPAN BETWEEN TWO CABINETS WHERE A FREESTANDING MACHINE STANDS ON THE
      # FLOOR. Not an opening in anything: the guide prints such a machine's
      # WIDTH and nothing else, because nothing is built around it. Until this
      # existed the item was skipped and the span was marked by nothing - and a
      # foreign component standing in an unmarked span looks like a settled
      # question, which is worse than an empty one.
      #
      # WHY IT IS DRAWN HERE AND NOT BY THE APPLIANCE MODULE, WHICH KNOWS THE
      # WIDTH. Decided 2026-08-25, claude/appliance-rules-decided.md §12: a
      # reservation nobody can see is worse than no reservation, so it must
      # carry this contract - and only this tree may write it. Nothing is lost,
      # because a run gap exists only inside a run and a run is drawn here. The
      # arrow of §11 survives intact: the ENGINE asks (88_appliance_check.rb)
      # and the appliance module answers.
      RESERVED_TAG = 'UCON — Reserved void'

      # PURE, and it RAISES instead of defaulting. 610, 620 and 635 are all live
      # depths in this project, so a silently chosen one is a wrong drawing that
      # looks right - and the top of the run is the same kind of number.
      # THE TOP IS TWO NUMBERS AND THEY HAVE DIFFERENT NATURES, which is why they
      # are not summed by the caller and handed over as one. The carcass top is
      # MEASURED off the body beside the gap; the worktop is STATED for the
      # project, because no model here draws one. The object says which is which.
      #
      # CORRECTED 2026-08-25, the same evening, from the first run in the real
      # kitchen (learned rule 9). The reservation was drawn to 880 - the carcass - and
      # the answer was that a gap in the run is a gap in the FINISHED run: floor
      # to the top of the stone. 880 + 40 = 920, and the range's own 928,4 stands
      # 8,4 proud of it, which is what a pro range does.
      def run_gap_attributes(model_no, width_mm:, depth_mm:, carcass_top_mm:, worktop_t_mm:,
                             source_ref:, note: nil)
        unless width_mm.to_f.positive?
          raise ArgumentError, "no printed width for #{model_no} - a run gap is its width or nothing"
        end
        unless depth_mm.to_f.positive?
          raise ArgumentError, "the run's depth is not measured - select the unit beside the gap"
        end
        unless carcass_top_mm.to_f.positive?
          raise ArgumentError, "the run's carcass top is not measured - select the unit beside the gap"
        end
        unless worktop_t_mm.to_f.positive?
          raise ArgumentError,
                'the worktop thickness is not stated for this project - nothing in the model draws ' \
                'a worktop, so it cannot be measured'
        end

        top_mm = carcass_top_mm.to_f + worktop_t_mm.to_f

        { 'schema_version' => Contract::SCHEMA_VERSION,
          'object_class'   => 'void',
          'void_role'      => 'run_gap',
          # The span holds the client's own machine, exactly as an appliance
          # niche does, and nobody manufactures a reservation. The exporter
          # keeps it out of the order by CLASS and not by this, so this key is
          # here to be read by a person and not by a filter.
          'manufacturer'   => 'client',
          'unit_type'      => "Reserved run gap — #{model_no}",
          'geometry_kind'  => 'linear',
          'width_mm'       => width_mm,
          'depth_mm'       => depth_mm,
          'height_mm'      => top_mm,
          'code'           => nil,
          'code_status'    => 'PRELIMINARY',
          'status'         => 'PLANNING',
          'source_ref'     => source_ref,
          'notes'          => [note,
                               "Top #{top_mm.round} = #{carcass_top_mm.round} MEASURED off the unit " \
                               "beside the gap + #{worktop_t_mm.round} STATED for the worktop; depth " \
                               "#{depth_mm.round} measured the same way. Nothing here is defaulted.",
                               Project.stated_note('worktop thickness', worktop_t_mm.to_f)]
                              .compact.join(' | ') }
      end

      # The top of the CARCASS beside the gap, read off the neighbour the way the
      # corner seat is: by measuring a body that is already standing correctly
      # rather than by rebuilding the number from a family and a plinth.
      #
      # THE BODY, NOT THE INSTANCE. An instance's bounds are everything its
      # definition carries, and a definition carries symbols too - an open door
      # leaf reaches forward, a plan symbol sits above its row. The box the
      # generator named CARCASS is the only thing here that is the cabinet. Where
      # there is none - a corner unit draws its own geometry - the instance is
      # the honest fallback and there is nothing better to measure.
      def selected_top_mm(model)
        sel = selected_unit(model)
        return nil unless sel

        body = sel.definition.entities.grep(Sketchup::Group).find { |g| g.name == 'CARCASS' }
        t = if body
              (sel.transformation.origin.z + body.bounds.max.z).to_mm
            else
              sel.bounds.max.z.to_mm
            end
        t.positive? ? t : nil
      rescue StandardError
        nil
      end

      # THE COMMAND. Ask the appliance layer for the printed width, measure the
      # run off the neighbour, draw the reservation. Refuses, with a sentence,
      # rather than inventing any of the three.
      def build_run_gap(model_no, model = Sketchup.active_model, worktop_t_mm: nil)
        depth   = selected_depth_mm(model)
        carcass = selected_top_mm(model)
        unless depth && carcass
          raise ArgumentError,
                "Select the unit beside the gap first.\n\n" \
                'A run gap takes its depth and its top from the RUN, and the guide ' \
                'prints neither. Nothing is defaulted here on purpose.'
        end

        worktop = worktop_t_mm || Project.worktop_t_mm(model)
        unless worktop.to_f.positive?
          raise ArgumentError,
                "This project has not stated its worktop thickness.\n\n" \
                'A gap in the run is a gap in the FINISHED run - floor to the top of the ' \
                'stone - and no model here draws a worktop to measure. State it once in ' \
                'the palette and it travels in the .skp.'
        end

        gap = ApplianceCheck.run_gap(model_no, 'depth_mm' => depth,
                                     'section_top_mm' => carcass + worktop)
        raise ArgumentError, gap['reason'].to_s unless gap['checked']
        raise ArgumentError, "#{model_no}: #{gap['reason']}" unless gap['applies']

        attrs = run_gap_attributes(model_no, width_mm: gap['w'], depth_mm: gap['d'],
                                   carcass_top_mm: carcass, worktop_t_mm: worktop,
                                   source_ref: gap['source'], note: gap['note'])

        # Seated exactly like a cabinet continuing the run - same side rule,
        # same corner turn, same inherited rotation. A reservation that lands by
        # a different path is a reservation that lands somewhere else.
        placement = placement_transform(model, attrs)

        model.start_operation("UCON: reserve run gap #{model_no}", true)
        begin
          mat = Geometry.material(model, 'UCON_Void_Red', VOID_RGB)
          mat.alpha = 0.35 if mat.respond_to?(:alpha=)
          definition = model.definitions.add(
            "UCON_VOID_RUN_GAP_#{attrs['width_mm'].round}_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
          )
          Geometry.box(definition.entities, "VOID_RUN_GAP_#{attrs['width_mm'].round}",
                       0, 0, 0, attrs['width_mm'], attrs['depth_mm'], attrs['height_mm'], mat)
          Contract.write!(definition, attrs)

          instance = model.active_entities.add_instance(definition, placement)
          instance.name = "UCON void — run gap #{attrs['width_mm'].round(1)} mm " \
                          "(#{model_no}, unassigned)"
          instance.layer = model.layers[RESERVED_TAG] || model.layers.add(RESERVED_TAG)

          model.selection.clear
          model.selection.add(instance)
          model.commit_operation
          model.active_view.zoom(instance)
          instance
        rescue StandardError
          model.abort_operation
          raise
        end
      end

      # ---- the wall reservation, the hood ---------------------------------
      #
      # A hood is built into nothing. It is not a niche, because nothing decides
      # its division; it is not a run gap, because a run gap is a span on the
      # FLOOR between two runs and this hangs. What it is, is a volume that no
      # wall unit may be planned into - and Contract v2.4 gives that its own
      # void_role because THE DATUM IS DIFFERENT: this one is measured from the
      # countertop, and nothing else in the contract is.
      #
      # TWO NUMBERS, TWO NATURES, exactly as the run gap's top has. The
      # countertop is MEASURED off the object the hood hangs over; the height
      # above it is STATED by a person, because Wolf printed p.144 gives a RANGE
      # - 762 to 914 - and 152 mm of decision is not something this file may
      # settle. The object says which is which.

      # Anything in the selection carrying our dictionary, not only a coded unit.
      # The thing a hood hangs over in this kitchen is a run-gap VOID, which has
      # no code at all, so selected_unit cannot see it.
      def selected_contract_instance(model)
        model.selection.grep(Sketchup::ComponentInstance).find do |i|
          i.definition.attribute_dictionary(Contract::DICTIONARY)
        end
      end

      # WHERE THIS KITCHEN'S COUNTERTOP IS, measured off the thing below and
      # never assumed - and it answers WHY as well as WHAT, because a number
      # whose provenance is not written down becomes a constant within a week.
      #
      # Two honest paths and they are not the same measurement:
      #   * a run-gap void is already drawn floor-to-FINISHED-run, so its own
      #     height IS the countertop and nothing is added to it;
      #   * a cabinet is drawn to its CARCASS, so the stated worktop is added -
      #     the same two-natured sum run_gap_attributes makes.
      def countertop_from(model, inst, attrs)
        if attrs['object_class'].to_s == 'void' && attrs['void_role'].to_s == 'run_gap'
          top = attrs['height_mm'].to_f
          return [top, "#{top.round} MEASURED off the run-gap reservation below, which is " \
                       'already drawn floor to the finished run']
        end

        carcass = begin
          body = inst.definition.entities.grep(Sketchup::Group).find { |g| g.name == 'CARCASS' }
          body ? (inst.transformation.origin.z + body.bounds.max.z).to_mm : inst.bounds.max.z.to_mm
        rescue StandardError
          nil
        end
        return [nil, nil] unless carcass.to_f.positive?

        worktop = Project.worktop_t_mm(model)
        return [nil, nil] unless worktop.to_f.positive?

        [carcass.to_f + worktop.to_f,
         "#{(carcass.to_f + worktop.to_f).round} = #{carcass.round} MEASURED off the body below " \
         "+ #{worktop.round} STATED for the worktop"]
      end

      # PURE, and it RAISES instead of defaulting, for the same reasons the run
      # gap's does. Reachable from the headless suite.
      def wall_reservation_attributes(model_no, width_mm:, depth_mm:, height_mm:,
                                      bottom_mm:, countertop_mm:, bottom_above_top_mm:,
                                      source_ref:, note: nil, countertop_note: nil)
        unless width_mm.to_f.positive? && depth_mm.to_f.positive? && height_mm.to_f.positive?
          raise ArgumentError,
                "#{model_no} publishes no envelope - a hood reservation is its envelope or nothing"
        end
        unless countertop_mm.to_f.positive?
          raise ArgumentError,
                "the countertop is not measured - select what the hood hangs over"
        end
        unless bottom_mm.to_f > countertop_mm.to_f
          raise ArgumentError,
                "a hood cannot hang at or below the countertop (#{bottom_mm.round} vs #{countertop_mm.round})"
        end

        { 'schema_version' => Contract::SCHEMA_VERSION,
          'object_class'   => 'void',
          'void_role'      => 'wall_reservation',
          # The client's own machine, exactly as a run gap holds one. The
          # exporter keeps a void out of the order by CLASS, so this key is here
          # for a person to read and not for a filter.
          'manufacturer'   => 'client',
          'unit_type'      => "Reserved wall volume - #{model_no}",
          'geometry_kind'  => 'linear',
          # THE CONTRACT ALREADY HAD THE WORDS FOR THIS, and finding that out is
          # why the void_role is the only thing v2.4 added. A hood IS wall-hung,
          # and §1.3 says mount_bottom_mm is 'a PROJECT decision at trust level
          # PLANNING, never a catalog fact' - which is exactly what a mounting
          # height chosen inside a printed range is. The first draft wrote
          # mount_bottom_mm without mounting and the contract refused it, which
          # is the invariant doing its job.
          'mounting'       => 'wall_hung',
          'width_mm'       => width_mm,
          'depth_mm'       => depth_mm,
          'height_mm'      => height_mm,
          'mount_bottom_mm' => bottom_mm,
          'code'           => nil,
          'code_status'    => 'PRELIMINARY',
          'status'         => 'PLANNING',
          'source_ref'     => source_ref,
          'notes'          => [note,
                               "Countertop #{countertop_note}; the hood hangs #{bottom_above_top_mm.round} " \
                               "above it, which is STATED - the guide prints a range and not a number - " \
                               "so the bottom is #{bottom_mm.round} and the top #{(bottom_mm + height_mm).round}.",
                               'DRAWN, NEVER ORDERED: the machine is the client\'s and no Cesar article ' \
                               'carries a hood.']
                              .compact.join(' | ') }
      end

      # THE COMMAND. Measure the countertop off what the hood hangs over, take
      # the envelope and the printed range from the appliance layer, and refuse
      # with a sentence rather than inventing any of it.
      def build_wall_reservation(model_no, model = Sketchup.active_model, bottom_above_top_mm: nil)
        inst = selected_contract_instance(model)
        unless inst
          raise ArgumentError,
                "Select what the hood hangs over first.\n\n" \
                'A hood is measured from the COUNTERTOP, and no page can know where this ' \
                "kitchen's is. Select the range's reservation, or the unit the cooking " \
                'surface stands in.'
        end
        attrs = Contract.read(inst.definition)
        countertop, countertop_note = countertop_from(model, inst, attrs)
        unless countertop
          raise ArgumentError,
                "That selection cannot say where the countertop is.\n\n" \
                'A cabinet is drawn to its carcass, so this project must also state its ' \
                'worktop thickness; a run-gap reservation already carries the finished top. ' \
                'Nothing is defaulted here on purpose.'
        end

        r = ApplianceCheck.wall_reservation(model_no,
                                            'countertop_mm' => countertop,
                                            'bottom_above_top_mm' => bottom_above_top_mm)
        raise ArgumentError, r['reason'].to_s unless r['checked']
        raise ArgumentError, "#{model_no}: #{r['reason']}" unless r['applies']

        # printed p.144: a wall hood should be AT LEAST AS WIDE as the cooking
        # surface. Refused rather than drawn narrow, because a hood that does not
        # cover what it hangs over is a wrong drawing that looks right - and the
        # selection is the cooking surface by construction, since that is what
        # the command asked to be selected.
        below_w = attrs['width_mm'].to_f
        if below_w.positive? && r['w'].to_f < below_w
          raise ArgumentError,
                "#{model_no} is #{r['w'].round} wide and it hangs over #{below_w.round}.\n\n" \
                'Wolf printed p.144: a wall hood should be at least as wide as the cooking ' \
                'surface. Pick the wider hood rather than drawing this one short.'
        end

        below_d = attrs['depth_mm'].to_f
        wall_y  = below_d.positive? ? below_d : r['d'].to_f
        x0      = below_w.positive? ? ((below_w - r['w'].to_f) / 2.0) : 0.0
        y0      = wall_y - r['d'].to_f

        full = wall_reservation_attributes(
          model_no,
          width_mm: r['w'], depth_mm: r['d'], height_mm: r['h'],
          bottom_mm: r['bottom_mm'], countertop_mm: countertop,
          bottom_above_top_mm: bottom_above_top_mm.to_f,
          source_ref: r['source'], note: r['note'], countertop_note: countertop_note
        )
        Contract.validate!(full)

        frame = inst.transformation
        model.start_operation("UCON: reserve wall volume #{model_no}", true)
        begin
          mat = Geometry.material(model, 'UCON_Void_Red', VOID_RGB)
          mat.alpha = 0.35 if mat.respond_to?(:alpha=)
          defn = model.definitions.add(
            "UCON_VOID_WALL_#{full['width_mm'].round}_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
          )
          Geometry.box(defn.entities, "VOID_WALL_#{full['width_mm'].round}",
                       x0, y0, full['mount_bottom_mm'],
                       full['width_mm'], full['depth_mm'], full['height_mm'], mat)
          Contract.write!(defn, full)

          o    = frame.origin
          seat = Geom::Transformation.translation(Geom::Vector3d.new(0, 0, -o.z)) * frame
          i    = model.active_entities.add_instance(defn, seat)
          i.name = "UCON void - wall reservation #{full['width_mm'].round} mm " \
                   "(#{model_no}, client's machine)"
          i.layer = model.layers[RESERVED_TAG] || model.layers.add(RESERVED_TAG)

          model.selection.clear
          model.selection.add(i)
          model.commit_operation
          model.active_view.zoom(i)
          i
        rescue StandardError
          model.abort_operation
          raise
        end
      end

      # Does this unit hang? Catalog-level fact, carried by the registry
      # family. Asked in one place so nothing downstream has to know the
      # spelling.
      def wall_hung?(unit)
        unit['mounting'].to_s == 'wall_hung'
      end

      # HOW TALL THIS UNIT'S PLINTH IS - asked of the object, never assumed.
      #
      # It was Standards::PLINTH_H_MM, one global 100, in five places. The
      # factory drawings say it is a property of the HEIGHT FAMILY: H.78
      # stands on 100 (Project Guidelines printed p.73 and p.82), H.84 on 60
      # (p.90), and N_Elle repeats both pairings, so it follows the height
      # family and not the collection. A constant chosen when there was one
      # family is learned rule 6 waiting for the second, and the H.84 chapter is
      # already mapped in catalog_map.
      #
      # ZERO IS A REAL VALUE, NOT A MISSING ONE: it means the carcass stands
      # on the floor and nothing is drawn beneath it. That is how the 5 mm
      # shim foot is modelled - see the note in 10_standards.rb for the
      # decision and the article numbers.
      #
      # Absent means the family has not said, and the UCON standard answers.
      def plinth_h_mm(unit)
        stated = (unit || {})['plinth_h_mm']
        stated.nil? ? Standards::PLINTH_H_MM : stated.to_f
      end

      # Is there anything to draw down there at all? Two different reasons for
      # no, and the drawing cannot tell them apart: a hung unit never meets the
      # floor, and a shim-footed one meets it directly.
      def plinth?(unit)
        # A THIRD REASON FOR NO, added 2026-08-26: a panel runs past the plinth
        # to the floor and the plinth returns behind it. It still INHERITS
        # plinth_h_mm from its neighbour - panel_ground needs the whole ground,
        # not a piece of it - so the flag cannot be read off that number.
        return false if (unit || {})['object_class'].to_s == 'panel'

        !wall_hung?(unit) && plinth_h_mm(unit) > 0
      end

      # How wide the plinth is. A corner unit is not dimensioned by a width, so
      # it answers from its own footprint.
      def plinth_width_mm(unit)
        unit['geometry_kind'] == 'corner' ? corner_parts(unit)[:carcass] : drawn_width_mm(unit)
      end

      # THE ONE WRITER OF A PLINTH. It was written out three times in this file
      # and the panel could not draw one at all, which stopped mattering the
      # moment mounting became a choice: switching a unit to wall-hung has to
      # take its plinth away, and switching back has to bring it. Four copies
      # of that would have been four chances to update three.
      #
      # Returns nil when this unit has no plinth, so a caller can erase and
      # redraw unconditionally.
      def draw_plinth(entities, unit, model)
        return nil unless plinth?(unit)

        s = Standards
        plinth = Geometry.box(
          entities, 'PLINTH', 0, s::PLINTH_SETBACK_MM, 0,
          plinth_width_mm(unit), s::PLINTH_T_MM, plinth_h_mm(unit),
          Geometry.material(model, 'UCON_Plinth_White', [245, 245, 245])
        )
        Geometry.hide_vertical_edges(plinth) if s::HIDE_PLINTH_VERTICAL_EDGES
        plinth
      end

      # Does this unit hang BY NATURE, because its family does? A wall unit
      # does. A base unit does not, however it has been configured - and that
      # is the distinction, not whether it happens to be hanging right now.
      def hangs_by_nature?(unit)
        (unit || {})['mounting_default'].to_s == 'wall_hung'
      end

      # How high the bottom of a hung unit sits above the finished floor.
      # TWO DIFFERENT QUESTIONS WEARING ONE NAME, and until 0.52 this method
      # answered only the first:
      #
      #   * A WALL unit hangs because that is what it is, and how high is a
      #     PROJECT decision Cesar says nothing about. That is the seam M1.6
      #     takes over; until then every wall unit gets the same number.
      #
      #   * A BASE or TALL unit that has been CHOSEN to hang is a different
      #     case entirely. Its worktop is the same worktop as its neighbours',
      #     so its bottom is not free: it sits exactly where its plinth would
      #     have put it. The gap that opens underneath is then the plinth
      #     height, and that gap IS what the option is bought for. Returning
      #     1400 here would have hung a base unit at wall-cabinet height.
      #
      # Derived, not invented: the number comes from the family's own plinth.
      def mount_bottom_mm(unit)
        # A value already written onto the object wins: it is what the drawing
        # was made from, and recomputing it would quietly move geometry the
        # next time anything is re-applied. This is also the seam M1.6 needs.
        stated = (unit || {})['mount_bottom_mm']
        return stated.to_f unless stated.nil?
        return Standards::WALL_MOUNT_BOTTOM_MM if hangs_by_nature?(unit)

        plinth_h_mm(unit)
      end

      # THE REGISTRY ROW AS THIS INSTANCE HAS IT: catalog facts overlaid with
      # the choices made on one object.
      #
      # Every geometry question must be asked of this and never of the bare
      # registry row, and the reason is a bug we have already paid for once.
      # Panel.apply looks the code up afresh, so a choice stored on the object
      # was invisible to the rebuild - the same shape as the gola pairing that
      # was lost for weeks because the dialog and the helper disagreed. A base
      # unit somebody hung would have been redrawn standing on its plinth.
      #
      # Only keys a PERSON can set are overlaid. Dimensions, codes and family
      # facts stay the catalog's - an object may not out-vote the registry
      # about what article it is.
      INSTANCE_KEYS = %w[mounting mount_bottom_mm].freeze

      def effective(unit, attrs)
        u = (unit || {}).dup
        a = attrs || {}
        INSTANCE_KEYS.each { |k| u[k] = a[k] unless a[k].nil? }
        # AND THE ORDERED WIDTH - which is NOT an instance key and must not
        # become one. The two do opposite things: INSTANCE_KEYS overrides what
        # the catalog SAID, this restores what the catalog NEVER said. A filler
        # row carries width_range_mm and no width at all, so every rebuild
        # re-read a nil width and the front collapsed - which is exactly what
        # the first filler to meet the properties panel did, with
        # "Non-positive dimension for FRONT: w=".
        #
        # THE THIRD INSTANCE OF LEARNED RULE 11, and in the very method written to
        # settle the second one. Validated on the way back in, so an edited
        # object cannot smuggle a width the article cannot be made at.
        u = Registry.with_ordered_width(u, a['width_mm']) if u['width_range_mm']
        # AND THE VARIANTS, which are neither of the two above. An INSTANCE_KEY
        # overrides what the catalog said; the ordered width restores what it
        # never said; a VARIANT is a choice the catalog has no opinion about at
        # all - stainless rather than lacquer, a light under the shelf. It lives
        # only on the object, so the merge that hands the object to the drawing
        # code must carry it or the drawing cannot see the choice.
        #
        # THIS IS WHY THE LED WAS NEVER DRAWN. Panel#apply wrote the variant
        # correctly, Contract stored and read it back correctly, and then handed
        # Symbols.draw a `chosen` built here - with the variant dropped on the
        # floor. Symbols#draw_led asks led_variant(unit) first and returned
        # immediately, every time, silently. Same shape as the wall-hung overlay
        # two screens above: a key written correctly that the thing which needs
        # it is never given. Fourth time this year (learned rule 11).
        u['variants'] = a['variants'] unless a['variants'].nil?
        u
      end

      # ---- the wall-hung option (printed p.548) -------------------------
      #
      # A standing catalog option, not an exception: nearly every base and
      # tall price table prints "Surch. for wall-hung version on page 548" in
      # its margin. It is the FIRST option in this engine that nobody can
      # infer from the article code - the same code is ordered either way and
      # the difference travels as a surcharge line - which makes it the first
      # true `origin: chosen` companion Contract v2 was built to carry.
      #
      # Three ways to be unavailable, and they are not the same:
      #   * the unit already hangs, so there is nothing to choose;
      #   * it is not a cabinet - an appliance FRONT bolts to the client's
      #     machine and is never fixed to a wall;
      #   * the page says so. Three types in the whole book print "not
      #     available wall hung" (printed p.34 and p.37) and NONE of them is
      #     in this registry, because those pages are not extracted. The flag
      #     is read anyway, so extracting them later is a data change and not
      #     a code change.
      def wall_hung_available?(unit)
        u = unit || {}
        return false if hangs_by_nature?(u)
        return false if u['wall_hung'] == false
        return false unless (u['object_class'] || 'cabinet') == 'cabinet'

        %w[base tall].include?(u['unit_class'].to_s)
      end

      # The order line the choice produces. ORIGIN: CHOSEN - a person decided
      # this and no rule can rederive it, which is exactly the distinction
      # Contract v2 4.2 draws against an implied line: an implied line is
      # recomputed on every apply, a chosen one is not.
      #
      # Two fixings for a base, four for a tall, and the catalog prices them
      # as two different articles. qty is 1 - one surcharge per unit, not per
      # fixing; p.548 prices the pair.
      def wall_hung_ref(unit)
        return nil unless wall_hung_available?(unit)

        row = ((Registry.data['modifications'] || {})['codes'] || {})['wall_hung'] || {}
        entry = row[(unit || {})['unit_class'].to_s]
        return nil unless entry && entry['code']

        { 'code' => entry['code'], 'qty' => 1, 'um' => 'PZ', 'origin' => 'chosen',
          'source_ref' => 'printed p.548 - wall-hung version, fixings 240 kg per pair' }
      end

      # Where this unit's carcass starts above the floor: the plinth for
      # something that stands, the hanging height for something that hangs.
      #
      # It lives HERE and only here. It used to be recomputed independently in
      # the generator, the symbol renderer and the properties panel, and when
      # wall units arrived two of the three were updated - so re-applying a
      # handle dropped a hanging front to plinth height. Three copies of a rule
      # is three chances to update two of them.
      # THE FRONT LINE. Every front in a run stands on it, whatever is behind
      # it - a carcass, or a client's fridge. It was written out twice in build
      # and a third time in 70_symbols, which is three chances to move two.
      # A panel is flush with its neighbours BECAUSE they ask the same method,
      # not because two expressions happen to agree.
      def front_y_mm
        -(Standards::FRONT_GAP_MM + Standards::FRONT_T_MM)
      end

      def base_z_mm(unit)
        # Set by unit_below_ground before anything reads a dimension: the top of
        # the run this element sits on.
        on = (unit || {})['stands_on_top_mm']
        return on.to_f if on

        return panel_base_z_mm(unit) if (unit || {})['object_class'].to_s == 'panel'

        wall_hung?(unit) ? mount_bottom_mm(unit) : plinth_h_mm(unit)
      end

      # WHERE THE UNIT'S ROW STARTS - a different question from base_z_mm, and
      # the two must not be confused. base_z_mm answers "where does the carcass
      # begin" (a floor unit begins on top of its plinth). row_datum_mm answers
      # "where does the row this unit belongs to begin" - the floor for a floor
      # unit, the hanging height for a hung one.
      #
      # It exists because plan symbols must ride with their row. Drawn at one
      # global height they collide: a base unit and the wall unit above it put
      # their swing arcs on the same millimetre and neither can be read.
      def row_datum_mm(unit)
        wall_hung?(unit) ? mount_bottom_mm(unit) : 0
      end

      def attributes_for(unit)
        corner = unit['geometry_kind'] == 'corner'
        attrs = {
          'schema_version'  => Contract::SCHEMA_VERSION,
          'object_class'    => unit['object_class'] || 'cabinet',
          'manufacturer'    => unit['manufacturer'],
          'family'          => unit['family'],
          'unit_type'       => unit['description'],
          'geometry_kind'   => corner ? 'corner' : 'linear',
          'height_mm'       => unit['height_mm'],
          'depth_mm'        => unit['depth_mm'],
          'opening'         => unit['opening'],
          'opening_method'  => 'handle',
          'front_height_mm' => unit['height_mm'],
          'code'            => unit['code'],
          'code_status'     => 'PRELIMINARY',
          'status'          => 'PLANNING',
          'source_ref'      => unit['source_ref'],
          'notes'           => notes_for(unit)
        }
        # A corner unit is dimensioned by its corner geometry, not by a single
        # width — Contract §1.1 requires exactly one of the two.
        if corner
          attrs['corner_geometry'] = unit['corner_geometry']
        else
          attrs['width_mm'] = unit['width_mm']
        end
        # Stated on every object, not only the hung ones: "floor" is a fact
        # about a base unit, and leaving it out would make the absence of the
        # key mean two different things (floor, or nobody asked).
        if wall_hung?(unit)
          attrs['mounting']        = 'wall_hung'
          attrs['mount_bottom_mm'] = mount_bottom_mm(unit)
        else
          attrs['mounting'] = 'floor'
        end
        # A REDUCTION IS A VARIANT, NOT A COMPANION, and that is read off a real
        # order rather than off the Modifications page. The source extract calls
        # a modification 'a separate order line'; Metron's estimate 2026/30831
        # priced 560 as B80601 with the variant WIDTH REDUCTION and a flat 138
        # points ON THE SAME ROW. The estimate is the thing that actually went
        # out, so the estimate wins. §4.2 rule 6: a variant earns its own key
        # only when geometry reads it - nothing reads this, so it lives in
        # `variants` and not in the key list.
        # AN INCREASE IS THE OTHER HALF, AND IT IS NOT THE SAME THING. A
        # reduction is a printed option with a code and a point value; an
        # increase is printed nowhere. Both reach the drawing, and the drawing
        # says which is which - because the LayOut sheet goes to Elda, she
        # enters it in Metron, and the difference between what she can key in
        # and what she cannot is the whole point of sending it.
        if unit['width_increased_from_mm']
          attrs['variants'] = Array(attrs['variants']) + [{
            'key' => 'WIDTH INCREASE',
            'value' => "REQUESTED, from #{unit['width_increased_from_mm']} mm - NOT PRINTED",
            'source_ref' => 'No printed option: the Modifications section lists reduction only ' \
                            '(989370 / 989380). No code and no surcharge exists for a wider ' \
                            'carcass in anything read. Elda Q11, open - this drawing is the ask.'
          }]
          attrs['notes'] = [attrs['notes'],
                            "WIDTH INCREASED #{unit['width_increased_from_mm']} -> " \
                            "#{unit['width_mm']} mm. THE CATALOG DOES NOT PRINT THIS. Drawn to " \
                            'be priced: no article code exists for the change, and feasibility ' \
                            'must be confirmed with Cesar before it is relied on.'].compact.join(' | ')
        end
        if unit['width_reduced_from_mm']
          attrs['variants'] = Array(attrs['variants']) + [{
            'key' => 'WIDTH REDUCTION',
            'value' => "Yes, from #{unit['width_reduced_from_mm']} mm",
            'source_ref' => 'Elda 2026-08-24 (Q3, closed for width); surcharge codes ' \
                            '989370 base/wall and 989380 tall, _manifest.json'
          }]
          # FEASIBILITY IS NOT OURS TO ASSERT. The Modifications section's own
          # master rule: 'Always check feasibility with Cesar before relying on a
          # modified item.' So the note says so on the object, where whoever
          # reads the order sees it.
          attrs['notes'] = [attrs['notes'],
                            "WIDTH REDUCED #{unit['width_reduced_from_mm']} -> " \
                            "#{unit['width_mm']} mm. Feasibility to be confirmed with " \
                            'Cesar before it is relied on.'].compact.join(' | ')
        end
        # HEIGHT, the same two directions and NOT the same evidence. Reduction
        # is printed and priced - 989370 / 138 points, printed p.548, and for a
        # TALL unit at the same code and the same points, where a width
        # reduction charges tall units 989380 / 227. Increase is printed
        # nowhere. The variants say which is which, because the difference
        # between what Elda can key into Metron and what she cannot is the whole
        # reason the sheet is being sent.
        if unit['height_increased_from_mm']
          attrs['variants'] = Array(attrs['variants']) + [{
            'key' => 'HEIGHT INCREASE',
            'value' => "REQUESTED, from #{unit['height_increased_from_mm']} mm - NOT PRINTED",
            'source_ref' => 'No printed option: the Modifications section prices height ' \
                            'REDUCTION only (989370). The only printed way to a taller unit ' \
                            'is printed p.550\'s combined tall unit, which stacks two standard ' \
                            'carcasses under one door and is a different article. Elda Q11 ' \
                            'question 4, open - this drawing is the ask.'
          }]
          attrs['notes'] = [attrs['notes'],
                            "HEIGHT INCREASED #{unit['height_increased_from_mm']} -> " \
                            "#{unit['height_mm']} mm. THE CATALOG DOES NOT PRINT THIS. Drawn to " \
                            'be priced: no article code exists for the change, and feasibility ' \
                            'must be confirmed with Cesar before it is relied on.'].compact.join(' | ')
        end
        if unit['height_reduced_from_mm']
          attrs['variants'] = Array(attrs['variants']) + [{
            'key' => 'HEIGHT REDUCTION',
            'value' => "Yes, from #{unit['height_reduced_from_mm']} mm",
            'source_ref' => 'printed p.548 / PDF 550, surcharge code 989370 at 138 points for ' \
                            'base, wall AND tall alike, _manifest.json ' \
                            'modifications.codes.height_reduction. No minimum height is ' \
                            'printed - Elda Q3.'
          }]
          attrs['notes'] = [attrs['notes'],
                            "HEIGHT REDUCED #{unit['height_reduced_from_mm']} -> " \
                            "#{unit['height_mm']} mm. NO EXCLUSION LIST IS PRINTED FOR HEIGHT - " \
                            'the one on printed p.548 is headed for WIDTH (Elda Q17). ' \
                            'Feasibility to be confirmed with Cesar before it is relied on.'].compact.join(' | ')
        end
        companions = companion_refs_for(unit)
        attrs['companion_refs'] = companions if companions
        attrs
      end

      def notes_for(unit)
        interior = unit['interior_confirmed']
        interior_note =
          if interior.empty?
            'No interior configuration confirmed by source.'
          else
            "Source confirms interior: #{interior.join(', ')} — deliberately not drawn (envelope-only representation)."
          end
        handed_note = unit['handed'] ? ' Handed unit: hinge_side is chosen per order and is not set by the generator.' : ''
        # The aperture is the one thing on this object that no Cesar page
        # states. Saying so on the object itself is the difference between a
        # placeholder and a wrong drawing.
        # A GLASS DOOR SAYS WHOSE NUMBER ITS FRAME IS, 2026-08-26. The catalog
        # prints no frame section anywhere Andriy or this session could find -
        # not the glass chapter, not Unit structure, not the technical pages,
        # not the filler table - so 25 is UCON's, declared once and drawn
        # CAD-style, and the object is the place that has to admit it.
        glass_note =
          if (frame_mm = (unit['front_layout'] || {})['glass_frame_mm'])
            " Glass door #{GLASS_FRAME_LABEL}: the frame is drawn at #{frame_mm} mm, " \
            'which is a UCON declaration and not a Cesar dimension - the catalog ' \
            'prints no frame section for a glass door on any page read so far. The ' \
            'pane is drawn opaque and flat, the CAD convention, and at full front ' \
            'thickness. Nothing here is a manufacturing statement.'
          else
            ''
          end
        cutout_note =
          if (unit['front_layout'] || {})['cutout']
            " Aperture #{CUTOUT_LABEL}: the catalog never dimensions it. " \
            'Rails are carried from appliance specifications and must be ' \
            'checked against the actual machine before this leaves the office.'
          else
            ''
          end
        # SAID ONLY WHERE IT IS TRUE. A filler whose clear space was not a whole
        # number is ordered UP and cut on site, and the two widths on this object
        # disagree on purpose - so the object has to say which is which.
        scribe_note =
          if unit['scribe_mm']
            " ORDERED #{unit['width_mm']} FOR A CLEAR SPACE OF #{unit['width_clear_mm']}: " \
            "#{format('%.1f', unit['scribe_mm'])} mm is scribed off on site. A filler is " \
            'ordered in whole millimetres and the rounding is UP by rule, because up is the ' \
            'only direction a fitter can correct. THE BODY IS DRAWN AT THE CLEAR SPACE, so ' \
            'the sheet shows no gap that will not exist: the attributes are the order and ' \
            'the geometry is the drawing.'
          else
            ''
          end
        # WAS 'Front drawn flush; 1.5 mm reveal recorded, not drawn.' until
        # 2026-08-26. FRONT_REVEAL_MM was deleted that day because nothing read
        # it, and the sentence outlived the number by one commit - it went on
        # telling every object about a 1,5 that no longer existed anywhere.
        # AN END PANEL SAYS WHOSE GROUND IT IS STANDING ON, and what its two
        # depths mean. Both because nobody reading the sheet can tell: the
        # panel's bottom came from a neighbour rather than from its own family,
        # and the depth it is drawn at is the catalog's DRAWN depth, which is
        # not the carcass depth it serves.
        panel_note =
          if unit['object_class'] == 'panel'
            base = unit['ground_from_code'] ?
                   "Ground taken from #{unit['ground_from_code']}, the unit it finishes - " \
                   'the catalog states no ground for a panel. ' : ''
            label = unit['printed_depth_label']
            depth = label ? "Drawn at the catalog's own d. #{unit['depth_mm']} mm, printed " \
                            "'#{label}'. The two numbers differ by a door face per side and " \
                            'which one describes the board is Elda Q21. ' : ''
            " END PANEL, 2.2 cm thick - the FRONT thickness, because the board lies in the " \
            "plane of the doors it adjoins. #{base}#{depth}" \
            'No front is drawn: a panel does not open. The 45-degree edge must face the ' \
            'door, which follows from which end it stands at and is placement, not an ' \
            'attribute - but WHICH PAGE the code came from is a real choice and cannot be ' \
            'undone by moving it.'
          else
            ''
          end
        "Generated from registry/cesar.json (#{unit['registry_status']}). " \
        "#{interior_note}#{handed_note} Front drawn flush: the faces meet, and no reveal is " \
        'drawn or stored.' \
        "#{scribe_note}#{glass_note}#{cutout_note}#{panel_note}"
      end
    end
  end
end

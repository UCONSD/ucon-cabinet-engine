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
      def placement_transform(model)
        sel = model.selection.grep(Sketchup::ComponentInstance).find do |i|
          i.definition.get_attribute(Contract::DICTIONARY, 'code')
        end
        return Geom::Transformation.new unless sel

        width = run_extent_mm(sel.definition)
        # Nothing we can measure: land at the origin, where it is obvious the
        # run was not continued. The old code read the missing width as 0.0 and
        # dropped the new unit exactly on top of the selected one - a lie that
        # looked like a placement.
        return Geom::Transformation.new unless width

        t = sel.transformation
        shifted = t * Geom::Transformation.translation(Geom::Vector3d.new(width.mm, 0, 0))
        # pin to the floor regardless of where the selected unit sits
        o = shifted.origin
        Geom::Transformation.translation(Geom::Vector3d.new(0, 0, -o.z)) * shifted
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

      # CAD glass: a cool grey that is plainly not the front's white and is
      # plainly not transparent.
      GLASS_RGB = [205, 214, 218].freeze

      # Reach of the selected unit along its own +x, in millimetres, or nil.
      # A corner carries no width by contract, so its reach comes from the
      # registry: the node it occupies, read through the execution letter.
      def run_extent_mm(definition)
        attrs = Contract.read(definition)
        return attrs['width_mm'].to_f if attrs['width_mm']
        return nil unless attrs['code']

        unit = begin
          Registry.lookup(attrs['code'])
        rescue StandardError
          nil
        end
        return nil unless unit && unit['corner_geometry']

        Placement.run_extent_mm(
          carcass_mm: unit['carcass_length_mm'],
          nominal_mm: unit['corner_geometry'].to_s.split('x').first.to_i,
          execution:  unit['execution']
        )
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
          out_x  = fill_l + FILLER_MM
          in_x   = out_x - s::FRONT_T_MM
          plan   = [[fill_l, back_y], [out_x, back_y], [out_x, out_y],
                    [in_x, out_y], [in_x, front_y], [fill_l, front_y]]
          wasted_x = carcass
        else
          door_x = carcass - door
          fill_l = door_x - FILLER_MM
          out_x  = fill_l
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

        plinth = Geometry.box(
          e, 'PLINTH', 0, s::PLINTH_SETBACK_MM, 0,
          p[:carcass], s::PLINTH_T_MM, s::PLINTH_H_MM,
          Geometry.material(model, 'UCON_Plinth_White', [245, 245, 245])
        )
        Geometry.hide_vertical_edges(plinth) if s::HIDE_PLINTH_VERTICAL_EDGES

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

      def build(code, model = Sketchup.active_model)
        unit = Registry.lookup(code)
        unless unit.fetch('buildable', true)
          raise ArgumentError,
                "#{code} is in the registry but cannot be built yet.\n\n" \
                "#{unit['not_buildable_reason']}"
        end

        s    = Standards
        w    = unit['width_mm']
        h    = unit['height_mm']
        d    = unit['depth_mm']
        # A base unit stands on its plinth; a wall unit hangs and has neither
        # plinth nor contact with the floor. Everything below is written in
        # terms of z0, so the difference is this one line and the skipped
        # plinth box - the front line, the symbols and build-next-to-selected
        # need no special case.
        wall = wall_hung?(unit)
        z0   = base_z_mm(unit)

        model.start_operation("UCON: build #{code}", true)
        begin
          carcass_mat = Geometry.material(model, 'UCON_Carcass_Light_Gray', [220, 220, 216])
          front_mat   = Geometry.material(model, 'UCON_Front_White',        [245, 245, 245])
          plinth_mat  = Geometry.material(model, 'UCON_Plinth_White',       [245, 245, 245])

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
          if unit['object_class'] == 'appliance_front'
            niche_depth = selected_depth_mm(model)
            placement   = placement_transform(model)

            if unit['plinth_continues']
              plinth = Geometry.box(
                e, 'PLINTH',
                0, s::PLINTH_SETBACK_MM, 0,
                w, s::PLINTH_T_MM, s::PLINTH_H_MM, plinth_mat
              )
              Geometry.hide_vertical_edges(plinth) if s::HIDE_PLINTH_VERTICAL_EDGES
            end
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

            instance = model.active_entities.add_instance(definition, placement_transform(model))
            instance.name = "Cesar #{code} — #{unit['description']}"
            model.selection.clear
            model.selection.add(instance)
            model.commit_operation
            model.active_view.zoom(instance)
            return instance
          end

          unless wall
            plinth = Geometry.box(
              e, 'PLINTH',
              0, s::PLINTH_SETBACK_MM, 0,
              w, s::PLINTH_T_MM, s::PLINTH_H_MM, plinth_mat
            )
            Geometry.hide_vertical_edges(plinth) if s::HIDE_PLINTH_VERTICAL_EDGES
          end

          Geometry.box(e, 'CARCASS', 0, 0, z0, w, d, h, carcass_mat)

          front_slabs(unit).each do |slab|
            draw_front_slab(e, slab, unit, z0, front_mat)
          end

          Contract.write!(definition, attributes_for(unit))
          # Symbols that need no user choice (drawer crosses) appear at build
          # time; door symbols wait for a hinge_side from the panel.
          Symbols.draw(model, definition, unit, nil)

          instance = model.active_entities.add_instance(definition, placement_transform(model))
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
      def front_slabs(unit)
        w = unit['width_mm']
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
        when 'vertical_split'
          n = layout['count'].to_i
          slab_w = w / n.to_f
          (0...n).map do |i|
            { name: "FRONT_#{i + 1}_OF_#{n}",
              x_mm: (i * slab_w).round(1), z_mm: 0,
              w_mm: slab_w.round(1), h_mm: h }
          end
        when 'horizontal'
          heights = layout['heights_mm_top_to_bottom'].map(&:to_f)
          unless (heights.sum - h).abs < 0.001
            raise "front_layout heights #{heights.inspect} do not sum to #{h}"
          end
          z = 0.0
          heights.reverse.each_with_index.map do |hh, i|
            slab = { name: "FRONT_#{i + 1}_FROM_BOTTOM",
                     x_mm: 0, z_mm: z.round(1), w_mm: w, h_mm: hh.round(1) }
            z += hh
            slab
          end
        else
          [{ name: 'FRONT', x_mm: 0, z_mm: 0, w_mm: w, h_mm: h }]
        end
      end

      # ONE PLACE THAT TURNS A SLAB INTO GEOMETRY. This loop stood written out
      # three times - twice in build and once in the properties panel - and a
      # front with a hole in it is exactly the change that gets made in two of
      # the three. Same lesson as front_y_mm, learned the same way.
      def draw_front_slab(entities, slab, unit, z0, material)
        t     = Standards::FRONT_T_MM
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
        frame = Geometry.framed_slab(
          entities, "#{slab[:name]} #{CUTOUT_LABEL}",
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
        Geometry.box(
          entities, "#{slab[:name]}_GLASS",
          slab[:x_mm] + rails[:left], front_y_mm,
          z0 + slab[:z_mm] + rails[:bottom],
          slab[:w_mm] - rails[:left] - rails[:right], t,
          slab[:h_mm] - rails[:bottom] - rails[:top],
          Geometry.material(entities.model, 'UCON_Glass_Gray', GLASS_RGB)
        )
        frame
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
        cutout = (unit['front_layout'] || {})['cutout']
        return nil unless cutout
        return nil unless slab[:w_mm] == unit['width_mm']

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
        # The plinth height is a standard and stays one. A second copy of 100
        # sitting in a JSON file is a second thing to change.
        return Standards::PLINTH_H_MM if niche['bottom'] == 'plinth_top'

        niche['bottom_mm'].to_f
      end

      def niche_top_mm(unit)
        niche = unit['appliance_niche']
        return base_z_mm(unit) + unit['height_mm'] unless niche

        niche['top_mm'].to_f
      end

      def niche_height_mm(unit)
        niche_top_mm(unit) - niche_bottom_mm(unit)
      end

      # Said on the object, because both numbers come from outside Cesar and
      # nobody reading the model would otherwise know where to argue with them.
      def niche_span_note(unit)
        return '' unless unit['appliance_niche']

        "Housing drawn #{niche_bottom_mm(unit).round(1)} to " \
        "#{niche_top_mm(unit).round(1)} above the floor - the appliance maker's " \
        'required cutout, not a Cesar dimension, so INDICATIVE like the ' \
        'aperture. The front runs past it at the top, and that leftover is the ' \
        'closing panel inside the housing - not this article. '
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
                              "#{niche_span_note(unit)}" \
                              'Never an order line: the machine is not a Cesar object. The ' \
                              "page's 'cutout for plinth 40' is recorded as unresolved and is not drawn."
        }
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

      # Does this unit hang? Catalog-level fact, carried by the registry
      # family. Asked in one place so nothing downstream has to know the
      # spelling.
      def wall_hung?(unit)
        unit['mounting'].to_s == 'wall_hung'
      end

      # How high the bottom of a hung unit sits above the finished floor.
      # A PROJECT decision, never a catalog fact - Cesar prices the box and
      # says nothing about the wall. This method is the seam M1.6 will take
      # over; until then every wall unit in the model gets the same number,
      # and it is written into the object so the drawing can be dimensioned
      # from data rather than from a measurement.
      def mount_bottom_mm(_unit)
        Standards::WALL_MOUNT_BOTTOM_MM
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
        wall_hung?(unit) ? mount_bottom_mm(unit) : Standards::PLINTH_H_MM
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
        cutout_note =
          if (unit['front_layout'] || {})['cutout']
            " Aperture #{CUTOUT_LABEL}: the catalog never dimensions it. " \
            'Rails are carried from appliance specifications and must be ' \
            'checked against the actual machine before this leaves the office.'
          else
            ''
          end
        "Generated from registry/cesar.json (#{unit['registry_status']}). " \
        "#{interior_note}#{handed_note} Front drawn flush; 1.5 mm reveal recorded, not drawn." \
        "#{cutout_note}"
      end
    end
  end
end

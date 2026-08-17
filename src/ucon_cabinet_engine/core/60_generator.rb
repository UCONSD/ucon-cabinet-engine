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

        width = sel.definition.get_attribute(Contract::DICTIONARY, 'width_mm').to_f
        t = sel.transformation
        shifted = t * Geom::Transformation.translation(Geom::Vector3d.new(width.mm, 0, 0))
        # pin to the floor regardless of where the selected unit sits
        o = shifted.origin
        Geom::Transformation.translation(Geom::Vector3d.new(0, 0, -o.z)) * shifted
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
        z0   = s::PLINTH_H_MM

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
          # machine's own door. No carcass, no plinth — the box behind it is
          # the client's appliance, not a Cesar object, and it is not drawn
          # until the placeholder task. The panel sits on the same front line
          # and at the same height as any other front in the run.
          if unit['object_class'] == 'appliance_front'
            niche_depth = selected_depth_mm(model)
            placement   = placement_transform(model)
            # Built through the ordinary front_slabs path and named FRONT…, so
            # the properties panel rebuilds it like any other front: choosing
            # door version 75 shortens the panel to 750 with no special case.
            front_slabs(unit).each do |slab|
              Geometry.box(
                e, slab[:name],
                slab[:x_mm], -(s::FRONT_GAP_MM + s::FRONT_T_MM), z0 + slab[:z_mm],
                slab[:w_mm], s::FRONT_T_MM, slab[:h_mm], front_mat
              )
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
              0, 0, 0,
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

          plinth = Geometry.box(
            e, 'PLINTH',
            0, s::PLINTH_SETBACK_MM, 0,
            w, s::PLINTH_T_MM, s::PLINTH_H_MM, plinth_mat
          )
          Geometry.hide_vertical_edges(plinth) if s::HIDE_PLINTH_VERTICAL_EDGES

          Geometry.box(e, 'CARCASS', 0, 0, z0, w, d, h, carcass_mat)

          front_y = -(s::FRONT_GAP_MM + s::FRONT_T_MM)
          front_slabs(unit).each do |slab|
            Geometry.box(
              e, slab[:name],
              slab[:x_mm], front_y, z0 + slab[:z_mm],
              slab[:w_mm], s::FRONT_T_MM, slab[:h_mm], front_mat
            )
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

      # Registry row -> Object Contract v1.2 attributes. Pure; tested headless
      # for every code in the registry.
      #
      # opening_method defaults to handle per the Q1 disposition (model the
      # full-height front; gola is a separate non-default option).
      # hinge_side is NOT set here even for handed units — it is a
      # per-placement order choice, and guessing it would violate §6.4.
      # Codes the catalog mandates alongside this one (Contract v1.3 §4.2).
      # Resolved from the registry for THIS code's width — never typed by a
      # user, never guessed. Returns a comma-separated string, or nil when the
      # unit has no companions, so the key stays absent rather than empty.
      def companion_refs_for(unit)
        refs = (unit['companions'] || []).filter_map do |c|
          if c['by'] == 'width'
            (c['map'] || {})[unit['width_mm'].to_s]
          elsif c['applies_to_widths_mm']
            c['code'] if c['applies_to_widths_mm'].include?(unit['width_mm'])
          else
            c['code']
          end
        end
        refs.empty? ? nil : refs.join(',')
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

      def niche_height_mm
        Standards::PLINTH_H_MM + 780
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
          'height_mm'      => niche_height_mm,
          'code_status'    => 'PRELIMINARY',
          'status'         => 'PLANNING',
          'source_ref'     => unit['source_ref'],
          'notes'          => 'Placeholder for the client-supplied appliance: the SPACE it ' \
                              'occupies in the run, not the machine. Width from the Cesar door ' \
                              "code #{unit['code']}; height = plinth + carcass (the appliance " \
                              'stands on the floor, the plinth in front of it is cut away); ' \
                              "depth #{inherited ? 'inherited from the neighbouring unit' : 'defaulted to d.62 - no neighbour was selected'}. " \
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
        "Generated from registry/cesar.json (#{unit['registry_status']}). " \
        "#{interior_note}#{handed_note} Front drawn flush; 1.5 mm reveal recorded, not drawn."
      end
    end
  end
end

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

      def build(code, model = Sketchup.active_model)
        unit = Registry.lookup(code)
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

          instance = model.active_entities.add_instance(definition, Geom::Transformation.new)
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
      def attributes_for(unit)
        attrs = {
          'schema_version'  => Contract::SCHEMA_VERSION,
          'object_class'    => 'cabinet',
          'manufacturer'    => unit['manufacturer'],
          'family'          => unit['family'],
          'unit_type'       => unit['description'],
          'geometry_kind'   => 'linear',
          'height_mm'       => unit['height_mm'],
          'depth_mm'        => unit['depth_mm'],
          'width_mm'        => unit['width_mm'],
          'opening'         => unit['opening'],
          'opening_method'  => 'handle',
          'front_height_mm' => unit['height_mm'],
          'code'            => unit['code'],
          'code_status'     => 'PRELIMINARY',
          'status'          => 'PLANNING',
          'source_ref'      => unit['source_ref'],
          'notes'           => notes_for(unit)
        }
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

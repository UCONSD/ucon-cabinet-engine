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

          Geometry.box(
            e, 'FRONT',
            0, -(s::FRONT_GAP_MM + s::FRONT_T_MM), z0,
            w, s::FRONT_T_MM, h, front_mat
          )

          Contract.write!(definition, attributes_for(unit))

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

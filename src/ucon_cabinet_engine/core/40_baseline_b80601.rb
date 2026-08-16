# frozen_string_literal: true
#
# UCON Cabinet Engine — core/40_baseline_b80601.rb
#
# Port of CESAR_B80601_BASELINE_v1.0.rb — the frozen baseline whose geometry
# Andriy visually accepted on 2026-08-04. That file stays frozen at
# ~/dev/ucon-sketchup-scripts/ and is never edited in place; this is a port,
# not a replacement.
#
# EVERY DIMENSION IS CARRIED OVER UNCHANGED. What changed in the port:
#
#   1. The four loose attributes in the ad-hoc `UCON` dictionary are replaced
#      by the Object Contract v1.1 `CabinetEngine` dictionary (core/20_contract.rb).
#      This is the entire reason the port exists — the old dictionary was
#      readable by nothing but itself.
#   2. The top-level script body is now a module function taking the model as
#      an argument, so it can be called from a menu, a console, or a batch.
#   3. Magic numbers moved to core/10_standards.rb, which holds the same values
#      the control document locks.
#
# ---------------------------------------------------------------------------
# KNOWN CONTRACT DEVIATION — read before promoting this to a family template.
#
# Object Contract §6.2 states: "Envelope only until confirmed. Model exterior
# dimensions only; never invent internal configuration."
#
# This baseline models BACK_PANEL_4MM_INSET20 and ADJUSTABLE_SHELF_01. Neither
# is derived from a verified source statement about B80601's interior; both
# come from the approved 2026-08-04 geometry. They are carried over knowingly
# rather than silently dropped, because the approval is real — but the conflict
# is real too, and it is logged here per invariant §6.1 rather than laundered.
#
# Resolve it before this shape becomes the template other units inherit.
# ---------------------------------------------------------------------------

module UCON
  module CabinetEngine
    module Baseline
      module B80601
        CODE       = 'B80601'
        FAMILY     = 'H.78'
        SOURCE_REF = 'CESAR - 2 Kitchen System.pdf p.36 / PDF 38'

        WIDTH_MM          = 600
        CARCASS_HEIGHT_MM = 780
        CARCASS_DEPTH_MM  = 620

        BASELINE_VERSION  = '1.0'
        VALIDATED_ON      = '2026-08-04'

        module_function

        def build(model = Sketchup.active_model)
          s  = Standards
          w  = WIDTH_MM
          h  = CARCASS_HEIGHT_MM
          d  = CARCASS_DEPTH_MM
          pt = s::PANEL_T_MM

          interior_w = w - 2 * pt                      # 564
          interior_h = h - 2 * pt                      # 744
          front_w    = w - 2 * s::FRONT_REVEAL_MM      # 597.0
          front_h    = h - 2 * s::FRONT_REVEAL_MM      # 777.0
          back_y     = d - s::BACK_INSET_MM - s::BACK_T_MM  # 596
          shelf_d    = back_y - pt                     # 578
          z0         = s::PLINTH_H_MM                  # 100

          model.start_operation("UCON: build #{CODE} (baseline v#{BASELINE_VERSION})", true)

          begin
            carcass_mat = Geometry.material(model, 'UCON_Carcass_Light_Gray', [220, 220, 216])
            front_mat   = Geometry.material(model, 'UCON_Front_White',        [245, 245, 245])
            back_mat    = Geometry.material(model, 'UCON_Back_Light_Gray',    [205, 205, 200])
            plinth_mat  = Geometry.material(model, 'UCON_Plinth_White',       [245, 245, 245])

            definition = model.definitions.add(definition_name)
            e = definition.entities

            plinth = Geometry.box(
              e, 'PLINTH_WHITE_H100_SETBACK45',
              0, s::PLINTH_SETBACK_MM, 0,
              w, s::PLINTH_T_MM, s::PLINTH_H_MM, plinth_mat
            )
            Geometry.hide_vertical_edges(plinth) if s::HIDE_PLINTH_VERTICAL_EDGES

            Geometry.box(e, 'CARCASS_LEFT_SIDE',  0,      0, z0,               pt,         d, h,  carcass_mat)
            Geometry.box(e, 'CARCASS_RIGHT_SIDE', w - pt, 0, z0,               pt,         d, h,  carcass_mat)
            Geometry.box(e, 'CARCASS_BOTTOM',     pt,     0, z0,               interior_w, d, pt, carcass_mat)
            Geometry.box(e, 'CARCASS_TOP',        pt,     0, z0 + h - pt,      interior_w, d, pt, carcass_mat)

            Geometry.box(
              e, 'BACK_PANEL_4MM_INSET20',
              pt, back_y, z0 + pt,
              interior_w, s::BACK_T_MM, interior_h, back_mat
            )

            shelf_z = z0 + pt + (interior_h - pt) / 2.0
            Geometry.box(
              e, 'ADJUSTABLE_SHELF_01',
              pt, pt, shelf_z,
              interior_w, shelf_d, pt, carcass_mat
            )

            Geometry.box(
              e, 'FRONT_SINGLE',
              s::FRONT_REVEAL_MM,
              -(s::FRONT_GAP_MM + s::FRONT_T_MM),
              z0 + s::FRONT_REVEAL_MM,
              front_w, s::FRONT_T_MM, front_h, front_mat
            )

            Contract.write!(definition, contract_attributes)

            instance = model.active_entities.add_instance(definition, Geom::Transformation.new)
            instance.name = "Cesar #{CODE} (baseline v#{BASELINE_VERSION})"

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

        # Contract §1.1 attributes for this unit.
        #
        # front_height_mm is DERIVED, not measured: §4.1 gives the full family
        # door height for opening_method = handle. The modelled front is 777 mm,
        # which is that 780 less the 1.5 mm reveal per side — the contract
        # records the door, the geometry records the opening it sits in.
        #
        # opening_method = handle follows the disposition in
        # docs/Elda_Open_Questions_v0.1.md Q1: model the full-height front by
        # default, treat gola as a separate non-default option.
        #
        # hardware_ref / hardware_source are deliberately absent — which handle
        # is used has not been decided, and guessing would violate §6.4.
        def contract_attributes
          {
            'schema_version'  => Contract::SCHEMA_VERSION,
            'object_class'    => 'cabinet',
            'manufacturer'    => 'cesar',
            'family'          => FAMILY,
            'geometry_kind'   => 'linear',
            'height_mm'       => CARCASS_HEIGHT_MM,
            'depth_mm'        => CARCASS_DEPTH_MM,
            'width_mm'        => WIDTH_MM,
            'opening'         => 'door',
            'opening_method'  => 'handle',
            'front_height_mm' => CARCASS_HEIGHT_MM,
            'code'            => CODE,
            'code_status'     => 'PRELIMINARY',
            'status'          => 'PLANNING',
            'source_ref'      => SOURCE_REF,
            'notes'           => notes
          }
        end

        def notes
          'Geometry ported verbatim from CESAR_B80601_BASELINE_v1.0.rb, ' \
          "visually accepted #{VALIDATED_ON}. Includes a back panel and one " \
          'adjustable shelf, which exceeds the envelope-only rule of Object ' \
          'Contract §6.2; carried from the approved baseline, NOT derived from ' \
          'a verified source statement. Resolve before templating.'
        end

        # The frozen baseline stamped a timestamp into the definition name so
        # each run produced a clean definition. Kept as-is: during development
        # that is the behaviour you want. It is the wrong behaviour for a
        # component library — revisit when units start being reused rather than
        # regenerated.
        def definition_name
          "CESAR_#{CODE}_BASELINE_V1_0_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
        end
      end
    end
  end
end

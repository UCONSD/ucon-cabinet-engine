# frozen_string_literal: true
#
# UCON Cabinet Engine — core/40_unit_b80601.rb
#
# Cesar B80601 — H.78 base unit, 600 x 780 x 620, single hinged front.
#
# DIMENSIONS come from CESAR_B80601_BASELINE_v1.0.rb, the frozen baseline whose
# geometry Andriy accepted on 2026-08-04. That file stays frozen at
# ~/dev/ucon-sketchup-scripts/ and remains the authority for every number here.
# Nothing below changes a dimension.
#
# REPRESENTATION deliberately differs from it. The baseline built the carcass
# out of six 18 mm panels; this builds one solid volume. Two reasons, which are
# really the same reason:
#
#   1. Object Contract §6.2 — "envelope only; never invent internal
#      configuration". The panel version modelled a back panel and an
#      adjustable shelf that no verified source statement supports. Both are
#      gone. The deviation logged in the previous version of this file is
#      closed, not carried.
#
#   2. LayOut. Every panel-to-panel joint is an edge. A run of cabinets built
#      from panel geometry reads as hatching rather than as cabinetry, and the
#      18 mm carcass thickness is not information a preliminary elevation is
#      trying to convey.
#
# What stays visible is what carries meaning: the front, separated from the
# carcass by the 3 mm gap and the 1.5 mm reveal, and the recessed plinth. Those
# lines describe the elevation. The panel thickness does not.
#
# Interior configuration comes back only when a source confirms it AND a
# drawing needs it — as a separate representation, never as a flag on this one.
# (Control document, "Failure Signals": one script accumulating many unrelated
# conditionals.)

module UCON
  module CabinetEngine
    module Units
      module B80601
        CODE       = 'B80601'
        FAMILY     = 'H.78'
        SOURCE_REF = 'CESAR - 2 Kitchen System.pdf p.36 / PDF 38'

        WIDTH_MM  = 600   # nominal catalog width
        HEIGHT_MM = 780   # carcass height, excluding the plinth
        DEPTH_MM  = 620   # carcass depth

        DIMENSIONS_FROM = 'CESAR_B80601_BASELINE_v1.0.rb, accepted 2026-08-04'

        module_function

        # Since M1.4 this is a thin delegate: the registry-driven generator
        # builds every unit, B80601 included. Kept so the existing menu item,
        # dev_reload habit and tests keep working unchanged.
        def build(model = Sketchup.active_model)
          Generator.build(CODE, model)
        end

        # Overall bounding dimensions of what actually gets drawn, including the
        # front standing proud of the carcass. Useful for layout spacing; NOT
        # the catalog dimensions, which are the carcass ones above.
        def overall_depth_mm
          DEPTH_MM + Standards::FRONT_GAP_MM + Standards::FRONT_T_MM
        end

        def overall_height_mm
          HEIGHT_MM + Standards::PLINTH_H_MM
        end

        # Contract §1.1 attributes.
        #
        # front_height_mm is DERIVED, not measured: §4.1 gives the full family
        # door height for opening_method = handle. The drawn front is 777 mm,
        # which is that 780 less the 1.5 mm reveal per side — the contract
        # records the door, the geometry records the opening it sits in.
        #
        # opening_method = handle follows the disposition in
        # docs/Elda_Open_Questions_v0.1.md Q1: model the full-height front by
        # default, treat gola as a separate non-default option.
        #
        # hardware_ref / hardware_source are deliberately absent — which handle
        # is used has not been decided, and guessing would breach §6.4.
        def contract_attributes
          {
            'schema_version'  => Contract::SCHEMA_VERSION,
            'object_class'    => 'cabinet',
            'manufacturer'    => 'cesar',
            'family'          => FAMILY,
            'geometry_kind'   => 'linear',
            'height_mm'       => HEIGHT_MM,
            'depth_mm'        => DEPTH_MM,
            'width_mm'        => WIDTH_MM,
            'opening'         => 'door',
            'opening_method'  => 'handle',
            'front_height_mm' => HEIGHT_MM,
            'code'            => CODE,
            'code_status'     => 'PRELIMINARY',
            'status'          => 'PLANNING',
            'source_ref'      => SOURCE_REF,
            'notes'           => notes
          }
        end

        def notes
          'Exterior envelope only, per Object Contract §6.2: carcass is one ' \
          'volume, no back panel, no shelf. Front is drawn flush with the ' \
          'carcass outline; the true 1.5 mm reveal per side is a recorded ' \
          'standard, deliberately not drawn. Dimensions from ' \
          "#{DIMENSIONS_FROM}."
        end

        # The frozen baseline stamped a timestamp into the definition name so
        # each run produced a clean definition. Kept: during development that is
        # the behaviour you want. It is the wrong behaviour for a component
        # library — revisit when units start being reused rather than
        # regenerated.
        def definition_name
          "CESAR_#{CODE}_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
        end
      end
    end
  end
end

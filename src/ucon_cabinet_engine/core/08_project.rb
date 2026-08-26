# frozen_string_literal: true
#
# UCON Cabinet Engine — core/08_project.rb
#
# PROJECT FACTS — numbers that are true of THIS kitchen and of no other, that no
# catalog page can answer and no drawn body can be measured for.
#
# THE FIRST OF THEM IS THE WORKTOP, and it arrived the way every rule here
# arrives: from a real kitchen. 2026-08-25, Avenida Primavera. The run gap under
# the 48in range was reserved to 880 — the top of the neighbouring CARCASS,
# measured off the body standing beside it — and Andriy's answer was that the
# reservation runs to the top of the WORKTOP, which is 40 mm of stone laid on
# those 880. The model draws no worktop at all: every base unit in it stops at
# 880 and there is not one object declaring `object_class: worktop`. So the
# number cannot be measured, in that model or in any other like it.
#
# WHY IT IS NOT A CONSTANT IN Standards. A standard is what the catalog or the
# factory fixes for everybody. A worktop is 20, 30, 40 or 60 depending on what
# the client picked, and a constant would be one project's choice quietly
# applied to the next one. Andriy, 2026-08-25, choosing between the two: a
# project number, in the palette.
#
# WHY IT IS ON THE MODEL. It belongs to the kitchen, so it travels in the .skp
# and it is answered once rather than typed into every dialog. This is the first
# key of the project axis the exporter's header has been waiting for (M1.6);
# when that lands, it lands here.
#
# THE CONTRACT IS NOT TOUCHED. Object Contract v2 §1.1 closes the key list of
# the `CabinetEngine` dictionary, which lives on DEFINITIONS and describes
# objects. This is a different dictionary on a different thing — the model —
# and it describes the project. An object that uses one of these numbers says on
# itself that the number was STATED and not measured, which is the whole point:
# a drawing must never present a declaration as a measurement.

module UCON
  module CabinetEngine
    module Project
      module_function

      DICTIONARY = 'UCON_PROJECT'

      # nil, not a default. Every caller must decide what to do without it, and
      # "draw it anyway with a number I chose" is not one of the options.
      def worktop_t_mm(model = Sketchup.active_model)
        v = model.get_attribute(DICTIONARY, 'worktop_t_mm')
        v.to_f.positive? ? v.to_f : nil
      rescue StandardError
        nil
      end

      def worktop_t_mm!(value, model = Sketchup.active_model)
        v = value.to_f
        unless v.positive?
          raise ArgumentError,
                "The worktop thickness must be a positive number of millimetres; got #{value.inspect}."
        end

        model.set_attribute(DICTIONARY, 'worktop_t_mm', v)
        v
      end

      # The sentence that goes onto anything drawn from a project number, so the
      # object carries its own provenance and nobody has to remember it.
      def stated_note(key, value)
        "#{value.round} mm for #{key.to_s.tr('_', ' ')} is STATED for this project, not measured — " \
          'nothing in the model draws it.'
      end
    end
  end
end

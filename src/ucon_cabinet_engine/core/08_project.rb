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

      # ---- WHICH TOP THIS KITCHEN IS GETTING, 2026-08-28 -------------------
      #
      # A PROJECT FACT, exactly like the thickness above and for a stronger
      # reason: a kitchen has ONE worktop material. The south run, the west run,
      # the island and the breakfast counter are four objects and one article -
      # asking again at each of them is four chances to answer differently, and
      # a model with two ceramics in it is a defect nobody would see in a
      # drawing.
      #
      # THE DEPTH BAND IS NOT HERE, ON PURPOSE. It is the one part of the choice
      # that is genuinely per-run: 650 over the 620 carcasses, 380 for the 350
      # counter. Keeping it out means it is asked every time, which is right.
      #
      # The thickness is NOT kept here either - it is the code's, and
      # worktop_t_mm already holds the project's stated number. If the two ever
      # disagree, Generator.build_worktop refuses rather than choosing.
      def worktop_code(model = Sketchup.active_model)
        v = model.get_attribute(DICTIONARY, 'worktop_code')
        v.to_s.empty? ? nil : v.to_s
      rescue StandardError
        nil
      end

      def worktop_finish_group(model = Sketchup.active_model)
        v = model.get_attribute(DICTIONARY, 'worktop_finish_group')
        v.to_s.empty? ? nil : v.to_s
      rescue StandardError
        nil
      end

      def worktop_finish(model = Sketchup.active_model)
        v = model.get_attribute(DICTIONARY, 'worktop_finish')
        v.to_s.empty? ? nil : v.to_s
      rescue StandardError
        nil
      end

      def worktop_article!(code, finish_group, finish, model = Sketchup.active_model)
        model.set_attribute(DICTIONARY, 'worktop_code', code.to_s)
        model.set_attribute(DICTIONARY, 'worktop_finish_group', finish_group.to_s)
        model.set_attribute(DICTIONARY, 'worktop_finish', finish.to_s)
        [code.to_s, finish_group.to_s, finish.to_s]
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

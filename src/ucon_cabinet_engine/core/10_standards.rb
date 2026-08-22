# frozen_string_literal: true
#
# UCON Cabinet Engine — core/10_standards.rb
#
# UCON working standards, transcribed verbatim from the "Locked Standards"
# table of CESAR_SketchUp_Script_Template_Control_v0.1.md. These are recorded
# decisions, not catalog facts read from a Cesar PDF — the `STATUS` map below
# records which is which, because the two carry different authority.
#
# No SketchUp dependency: this file loads under plain `ruby`.

module UCON
  module CabinetEngine
    module Standards
      PANEL_T_MM        = 18    # carcass panel thickness
      BACK_T_MM         = 4     # back panel thickness
      BACK_INSET_MM     = 20    # back panel inset from the rear face
      FRONT_T_MM        = 22    # standard front thickness
      FRONT_GAP_MM      = 3     # carcass-to-front gap
      FRONT_REVEAL_MM   = 1.5   # front reveal, per side
      PLINTH_H_MM       = 100   # default plinth height
      PLINTH_H_ALT_MM   = 60    # alternate plinth height, special request only
      #
      # CORRECTION, 2026-08-22 (rule 9: dated and added, the lines above are
      # left standing). The two numbers are right and the comment on the
      # second one is wrong. 60 is NOT a special request: it is the DEFAULT
      # plinth of the H.84 family, printed on p.90 of the factory Project
      # Guidelines exactly as 100 is printed for H.78 on p.73 and p.82.
      # N_Elle repeats both pairings, so it follows the HEIGHT FAMILY and not
      # the collection.
      #
      # Consequently PLINTH_H_MM is no longer the authority, only the
      # FALLBACK: the registry family states its own `plinth_h_mm` and
      # Generator.plinth_h_mm asks the object. This constant answers only for
      # a family that has not said. When M1.6 lands, a project override sits
      # between the two.
      #
      # A THIRD VALUE IS LEGAL AND IS NOT A HEIGHT: **zero**. It means the
      # carcass stands on the floor and no plinth is drawn - which is how the
      # 5 mm shim foot is modelled, by decision (Andriy, 2026-08-22:
      # "ножку 5 мм высотой считаем за ноль").
      #
      # WHAT THAT FOOT IS, and why zero is the right number rather than a
      # convenient one. It is a disc on a threaded stud: the stud screws into
      # an insert sunk in the bottom panel and disappears, so nothing of it
      # shows. Its range, as UCON specifies it (Andriy, 2026-08-22):
      #
      #   * minimum design height  0 mm  - the panel sits FLAT ON THE FLOOR
      #   * maximum                5 mm  - and that 5 is TRAVEL, there to take
      #                                    out unevenness in the floor
      #
      # So the 5 is a tolerance the fitter spends on site, not a height the
      # cabinet is designed to stand at. **The drawing shows zero: panel on
      # the floor, no gap.** Anything else would dimension the installer's
      # allowance as if it were a design intent.
      #
      # This is a DECISION, not a Cesar statement, and the scope matters
      # (rule 4): the catalog prints only the phrase "adjustable feet H. 5 mm"
      # and never says where in that range a cabinet is meant to sit.
      #
      # The 5 is therefore not written down anywhere: a number we have decided
      # not to draw is not a number we store. For anyone who needs the
      # article, it is 989053 on printed p.548 of the price list, and the same
      # foot is sold as 990408 on printed p.214 of Linear Elements
      # ("Adjustable foot H. 0.5 cm", with the note "0.5-cm high feet").
      #
      # The catalog sells exactly two plinth heights and the height is IN the
      # code: printed p.625, front plinth ZOCC001 = H.6 and ZOCC011 = H.10.
      PLINTH_T_MM       = 18    # plinth thickness
      PLINTH_SETBACK_MM = 45    # plinth setback from the front face

      # Where the bottom of a wall unit sits above the finished floor. This is
      # NOT a catalog fact and not a locked standard: Cesar prices the box and
      # says nothing about how high it hangs. It is a project default, and the
      # only reason it lives here rather than in a project file is that M1.6
      # (project defaults) does not exist yet. When M1.6 lands, this constant
      # becomes its fallback, not its authority.
      WALL_MOUNT_BOTTOM_MM = 1400

      # Where each number's authority comes from. Anything marked
      # :ucon_working_standard is ours to change; :elda_confirmed is not.
      STATUS = {
        PANEL_T_MM:        :ucon_working_standard,
        BACK_T_MM:         :ucon_working_standard,
        BACK_INSET_MM:     :ucon_working_standard,
        FRONT_T_MM:        :elda_confirmed,
        FRONT_GAP_MM:      :derived_from_elda_dimensions,
        FRONT_REVEAL_MM:   :confirmed_decision,
        PLINTH_H_MM:       :confirmed_decision,
        PLINTH_H_ALT_MM:   :confirmed_decision,
        PLINTH_T_MM:       :confirmed_decision,
        PLINTH_SETBACK_MM: :confirmed_decision,
        # Weaker than everything above it, and deliberately named so: nobody
        # has confirmed 1400, it is what we draw until a real kitchen says
        # otherwise. Loosely corroborated by the led-bar height of 132 on the
        # electrical diagram, printed p.16 - a hint, not a rule.
        WALL_MOUNT_BOTTOM_MM: :project_default_pending_m1_6
      }.freeze

      SOURCE_DOCUMENT = 'CESAR_SketchUp_Script_Template_Control_v0.1.md'

      # Plinth vertical end edges are hidden so adjacent cabinets read as one
      # continuous base. Confirmed decision, same table.
      HIDE_PLINTH_VERTICAL_EDGES = true
    end
  end
end

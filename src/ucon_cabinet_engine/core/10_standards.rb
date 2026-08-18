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

# frozen_string_literal: true
#
# UCON Cabinet Engine — core/85_export.rb
#
# The ORDER schedule: take a set of objects and emit the rows a Cesar order is
# made of. NOT a joinery cut list — Cesar order lines (roadmap M1.10).
#
# PURE RUBY, NO SKETCHUP, and a test fails if that stops being true. This module
# takes attribute hashes exactly as Contract.read returns them; the glue that
# walks a model and reads them lives elsewhere. Same split as 22_placement, and
# it is what lets the exporter be checked headlessly against a real factory
# estimate instead of by opening SketchUp and squinting.
#
# THE OBJECT MODEL AND THE ORDER MODEL ARE NOT THE SAME, and translating
# between them is this file's whole job:
#
#   - `hinge_side` is a first-class contract key because geometry reads it.
#     The ORDER has no such column: estimate 2026/30829 carries the hand as a
#     variant line, `OPENING DIRECTION: Left` / `Right`, under one code
#     (rows 15/18/25/27). So the exporter turns the key into that line.
#   - the door version 78/75 is a DRAWING axis and appears in no order at all,
#     so nothing is emitted for it. The gola profile it implies is a separate
#     order line, and that one IS emitted.
#   - a row is a TREE: variant lines and child rows sit under a numbered row.
#     `level` says how deep. Only numbered rows get a `row`.
#
# WHAT THIS DELIBERATELY DOES NOT DO:
#   - no price. Contract §1.2 forbids commercial data, and the estimate prices
#     in points against a dated coefficient nothing in the model holds.
#   - no composition header (MODELLO, finishes, gola system, foot type). Those
#     are project axes and wait on M1.6.
#   - no component explosion (FRN / RPN / DVN / KCAS). The factory generates
#     those from our article; we never order them.

module UCON
  module CabinetEngine
    module Export
      module_function

      COLUMNS = %w[row level code description corner l_mm h_mm p_mm
                   um qty status code_status note].freeze

      # A cabinet, a front, a top, a plinth: one piece. Estimate UM table.
      UNIT_UM = 'PZ'

      # CONFIRMED from estimate 2026/30829: one code, both hands, the hand
      # carried as a variant line. This mapping is the order's wording, not
      # ours.
      HAND_TO_ORDER = { 'rh' => 'Right', 'lh' => 'Left' }.freeze

      # ORDERABLE = carries a code. One test, and it is not a convenience.
      # An appliance niche is DRAWN AND NEVER ORDERED - it is the space the
      # client's machine occupies - and the generator deliberately gives it no
      # code and manufacturer = client. Contract §2 says tools derive meaning
      # only from the dictionary, so this is the dictionary answering.
      #
      # The filter lives HERE, in the pure module, and not in the glue that
      # walks the model. A rule that sits in the glue is a rule the headless
      # suite cannot see - which is how a drawer unit came to be offered a
      # single gola profile for weeks.
      def orderable?(attrs)
        !(attrs || {})['code'].to_s.empty?
      end

      def rows(objects)
        number = 0
        Array(objects).select { |o| orderable?(o) }.each_with_object([]) do |attrs, out|
          a = attrs || {}
          number += 1
          out << unit_row(number, a)
          hand_row(a).tap { |r| out << r if r }
          variant_rows(a['variants'], 1).each { |r| out << r }
          hardware_row(a).tap { |r| out << r if r }
          Array(a['companion_refs']).each do |line|
            out << companion_row(line)
            variant_rows(line['variants'], 2).each { |r| out << r }
          end
        end
      end

      def csv(rows)
        table = [COLUMNS] + rows.map { |r| COLUMNS.map { |c| r[c] } }
        table.map { |cells| cells.map { |v| csv_cell(v) }.join(',') }.join("\n") + "\n"
      end

      # ---- rows ---------------------------------------------------------

      def blank
        COLUMNS.each_with_object({}) { |c, h| h[c] = nil }
      end

      def unit_row(number, a)
        blank.merge(
          'row' => number, 'level' => 0,
          'code' => a['code'],
          'description' => a['unit_type'],
          # A corner unit is dimensioned by its footprint instead of a width.
          # What the factory actually prints in the L column for one of these
          # is NOT known - positions 1 and 2 of the estimate now with Elda are
          # exactly those two corners, so the answer is in the post.
          'corner' => a['corner_geometry'],
          'l_mm' => a['width_mm'],
          'h_mm' => a['height_mm'],
          'p_mm' => a['depth_mm'],
          'um' => UNIT_UM, 'qty' => 1,
          'status' => a['status'], 'code_status' => a['code_status']
        )
      end

      def hand_row(a)
        hand = HAND_TO_ORDER[a['hinge_side'].to_s]
        return nil unless hand

        blank.merge('level' => 1, 'description' => "OPENING DIRECTION: #{hand}",
                    'note' => 'variant line; one code serves both hands (estimate 2026/30829)')
      end

      def variant_rows(variants, level)
        Array(variants).map do |v|
          blank.merge('level' => level,
                      'description' => "#{v['key']}: #{v['value']}",
                      'note' => v['source_ref'])
        end
      end

      def hardware_row(a)
        code = a['hardware_ref'].to_s
        return nil if code.empty?

        row = hardware_lookup(code)
        um  = row && row['um']
        blank.merge(
          'level' => 1, 'code' => code,
          'description' => row && row['name'],
          'um' => um,
          # QUANTITY IS NOT A PROPERTY OF THE ARTICLE, so it is not invented.
          # An ML profile is quantified by the RUN it travels along, across
          # joints between units; a PZ handle by how many fronts the unit has.
          # Neither is readable from one object, so the cell stays empty and
          # says why. Rule 7 applied to an order line.
          'qty' => nil,
          'note' => hardware_qty_note(um)
        )
      end

      # An EMPTY quantity is not a gap in the export, it is the honest state of
      # the object (Contract v2.1 made qty nullable for exactly this). Say which
      # kind of unknown it is, so a reader can tell "nobody worked it out yet"
      # from "nothing at this level could".
      def qty_note(um)
        case um
        when 'ML' then 'qty = running length of the run, not of this unit (needs M2.1a)'
        when 'MQ' then 'qty = area; not derivable from one object'
        else 'qty not determinable from a single object'
        end
      end

      def hardware_qty_note(um)
        return 'qty = one per front; not derived here until an estimate shows the row' if
          um == 'PZ'
        return 'qty and um both unknown - this article carries no um in the registry' if
          um.to_s.empty?

        qty_note(um)
      end

      def companion_row(line)
        l = line || {}
        note = [l['origin'], l['source_ref']].compact
        note << qty_note(l['um']) if l['qty'].nil?
        blank.merge(
          'level' => 1, 'code' => l['code'],
          'um' => l['um'], 'qty' => l['qty'],
          'note' => note.join(' · '),
          # §4.2 rule 4: a chosen line whose article stopped resolving carries
          # no code, and the order must show that rather than swallow it.
          'description' => l['code'].nil? ? 'UNRESOLVED companion - no article for this size' : nil
        )
      end

      def hardware_lookup(code)
        hw = Registry.data['hardware'] || {}
        ((hw['gola_profiles'] || []) + (hw['handles'] || [])).find { |h| h['code'] == code }
      end

      def csv_cell(value)
        return '' if value.nil?

        text = value.to_s
        return text unless text =~ /["\n,]/

        '"' + text.gsub('"', '""') + '"'
      end
    end
  end
end

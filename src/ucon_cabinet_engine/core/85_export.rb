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
#   - a PZ handle is counted ONE PER OPENING FRONT, read off the registry's
#     front_layout. Eight single-front cabinets put eight handles in the
#     warehouse; a two-door tall unit puts two. OUR reading, and every such
#     row says so.
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
      # CORRECTED 2026-08-25, and the correction is the contract's own sentence.
      # This used to be "carries a code", which is right about the niche for the
      # WRONG REASON and silently wrong about anything else. §4.2 rule 4: when no
      # valid article exists the code becomes null and the object carries a
      # visible warning - "unknown is null, never a quietly kept stale article
      # AND NEVER A SILENT DELETION". A code-only test deletes it silently, and
      # that surfaced the first time the rule was used: two custom 610 boxes over
      # a fridge niche, which the factory has to make and which vanished from the
      # order.
      #
      # The dictionary already told the two apart and nobody read it. A niche
      # carries manufacturer = CLIENT, because it is the space the client's own
      # machine occupies. A custom-size cabinet carries manufacturer = Cesar and
      # no code, because SOMEBODY HAS TO MAKE IT and we do not know the article
      # yet. So the question is not "is there a code" but "is there somebody to
      # make it", and the missing code becomes a warning on the row instead of a
      # reason to drop it.
      #
      # A void is excluded by class: a reservation is a span the drawing owns,
      # not a thing anyone builds.
      def orderable?(attrs)
        a = attrs || {}
        return false if a['object_class'].to_s == 'void'
        return false if a['manufacturer'].to_s == 'client'

        !a['manufacturer'].to_s.empty?
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

      # A ROW WITHOUT A CODE SAYS SO IN WORDS. The companion rows have done this
      # since v2 - 'UNRESOLVED companion - no article for this size' - and a unit
      # row had no equivalent because until 2026-08-25 a unit without a code
      # never reached here. Whoever reads the order must see the hole, not infer
      # it from an empty cell.
      def order_description(a)
        return a['unit_type'] unless a['code'].to_s.empty?

        ['CUSTOM SIZE - NO ARTICLE, to be quoted', a['unit_type']].compact.join(' - ')
      end

      def unit_row(number, a)
        blank.merge(
          'row' => number, 'level' => 0,
          'code' => a['code'],
          'description' => order_description(a),
          # A corner unit is dimensioned by its footprint instead of a width.
          # What the factory actually prints in the L column for one of these
          # is NOT known - positions 1 and 2 of the estimate now with Elda are
          # exactly those two corners, so the answer is in the post.
          'corner' => a['corner_geometry'],
          'l_mm' => a['width_mm'],
          'h_mm' => a['height_mm'],
          'p_mm' => a['depth_mm'],
          'um' => UNIT_UM, 'qty' => 1,
          'status' => a['status'], 'code_status' => a['code_status'],
          'note' => ordered_width_note(a)
        )
      end

      # WHEN THE L COLUMN IS OUR NUMBER AND NOT THE CATALOG'S.
      #
      # printed p.434 prices fillers and closing strips by HEIGHT alone: one
      # article covers every width from 2,3 to 15 cm, so the width on this line
      # was chosen by whoever placed the object. Nothing in the number says so,
      # and the difference matters to whoever reads the estimate - quoting a
      # catalog size and specifying a cut are not the same request.
      #
      # Asked of the registry, never trusted from the object: the range is a
      # catalog fact, the same rule front_layout_for follows and for the same
      # reason.
      def ordered_width_note(a)
        range = width_range_for(a)
        return nil unless range

        'width is an ORDER choice, not a catalog size: this article is made ' \
        "from #{range[0]} to #{range[1]} mm (printed p.434)"
      end

      def width_range_for(attrs)
        code = (attrs || {})['code'].to_s
        return nil if code.empty?

        Registry.lookup(code)['width_range_mm']
      rescue ArgumentError
        nil
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
        # QUANTITY IS NOT A PROPERTY OF THE ARTICLE. But it is not equally
        # unknowable for both kinds: a PZ handle is quantified by how many
        # fronts the unit opens on, and that IS readable from one object,
        # because front_layout has described the fronts since the geometry
        # needed them. An ML profile is quantified by the RUN it travels
        # along, across joints between units, and no single object can see a
        # run. So one of the two open quantities closes here; the other waits
        # for M2.1a and says so.
        layout = um == 'PZ' ? front_layout_for(a) : nil
        qty    = um == 'PZ' ? fronts_in(layout) : nil
        blank.merge(
          'level' => 1, 'code' => code,
          'description' => row && row['name'],
          'um' => um,
          'qty' => qty,
          'note' => hardware_qty_note(um, qty, layout)
        )
      end

      # ---- how many handles a cabinet takes ------------------------------
      #
      # The rule in Andriy's words: "если у нас есть 8 шкафов и 8 ручек - на
      # складе лежит 8." Eight cabinets, eight handles waiting in the
      # warehouse.
      #
      # Every cabinet in that example carries ONE front, so the example by
      # itself does not say whether the count follows the CABINET or the
      # FRONT. The registry does. `front_layout` already describes the fronts
      # of every type we hold - a two-door tall unit says `vertical_split,
      # count 2`, a drawer stack lists its front heights top to bottom - and
      # two doors are two things a hand opens. So the rule implemented is ONE
      # HANDLE PER OPENING FRONT. It reproduces 8 -> 8 exactly on the units
      # that produced the example, and it does not have to be rewritten the
      # first time somebody orders CR1230.
      #
      # SCOPE, and it is the whole of rule 4: THIS IS OUR READING, NOT A CESAR
      # STATEMENT. The catalog nowhere prints how many handles an article
      # takes; the manifest already records handle `um: PZ` the same way. The
      # note on every such row says so, and position 14 of the estimate now
      # with Elda is the first order line that could confirm or refute it.
      #
      # Two cases that look like exceptions and are not:
      #   - a GOLA front has no handle at all, it has a profile. Such a unit
      #     carries no `hardware_ref`, so it never reaches here.
      #   - an 8x8 corner filler is FIXED and opens on nothing, so a corner
      #     unit takes one handle, for its one door.
      def fronts_in(front_layout)
        fl = front_layout || {}
        case fl['kind']
        when 'single', 'corner_door' then 1
        when 'vertical_split'        then positive_int(fl['count'])
        when 'horizontal'            then horizontal_fronts(fl)
        end
      end

      # A drawer stack states its fronts twice - the handle version as heights
      # top to bottom, the gola version as a stack of fronts and recess zones.
      # Every type we hold agrees between the two, and the handle version is
      # the one that applies here by definition, so it is read first.
      def horizontal_fronts(fl)
        heights = fl['heights_mm_top_to_bottom']
        return heights.size if heights.is_a?(Array) && !heights.empty?

        # A TYPE WITH A REMAINDER DECLARES NO SHORTHAND, on purpose: a partial
        # list of heights that looks complete is the failure this avoids. So the
        # handle stack is asked before the gola one, and only entries that are
        # FRONTS are counted - a remainder is a span nobody can order a front
        # for yet, and counting it would put a handle on a door whose height
        # nobody knows. docs/Reserved_Void_Spec_v0.1.md §4.
        %w[stack_top_to_bottom gola_stack_top_to_bottom].each do |key|
          stack = Array(fl[key])
          next if stack.empty?

          # A REMAINDER HIDES FRONTS, IT DOES NOT ABOLISH THEM. printed p.121
          # says '1 rh or lh custom-sized door' in words: HOW MANY is printed,
          # only HOW TALL is not. So the count is known and the handle is
          # ordered; refusing to count it would drop a real order line to
          # protect a number nobody asked for. `fronts_within` is that count,
          # and it is read from the page, not derived.
          n = stack.count { |e| e['kind'] == 'front' } +
              stack.sum { |e| e['kind'] == 'remainder' ? e['fronts_within'].to_i : 0 }
          return n if n.positive?
        end
        nil
      end

      def positive_int(value)
        n = value.to_i
        n > 0 ? n : nil
      end

      # front_layout is a catalog fact, so it is asked of the registry rather
      # than copied onto the object - exactly as the handle's name and um are.
      # A code the registry no longer knows must not blow an export up: rule 7
      # says the answer is nil, and the note then says the count is unknown.
      def front_layout_for(attrs)
        code = (attrs || {})['code'].to_s
        return nil if code.empty?

        Registry.lookup(code)['front_layout']
      rescue ArgumentError
        nil
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

      def hardware_qty_note(um, qty = nil, layout = nil)
        return 'qty and um both unknown - this article carries no um in the registry' if
          um.to_s.empty?
        return qty_note(um) unless um == 'PZ'
        return 'qty = one per opening front; this article has no front_layout to count' if
          qty.nil?

        "qty = one per opening front (front_layout: #{(layout || {})['kind']}); OUR " \
        'reading, not a Cesar statement - estimate position 14 is the first order ' \
        'line that could confirm it'
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

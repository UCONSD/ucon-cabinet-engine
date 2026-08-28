# frozen_string_literal: true
#
# UCON Cabinet Engine — core/64_sink_mark.rb  ::  WHERE THE SINK GOES, AND WHAT
# IT COSTS, WHICH ARE TWO DIFFERENT FACTS.
#
# 2026-08-28, after the tops stopped being generated and started being stamped.
# A sink is the first thing this engine has drawn that is NOT an article it
# makes, and the two halves of it belong in different places:
#
#   THE ORDER FACT is a surcharge on the TOP. printed p.110 prices an integrated
#   bowl at 1671 each, beside the top's own per-metre price, and a bowl has no
#   article code of its own. So the bowl is written as a VARIANT on the stamped
#   worktop, which is the line it will be charged on. Count and size are the
#   order; position is not.
#
#   THE DRAWING FACT is a dashed rectangle 1 mm above the stone. Andriy's spec.
#   It marks where the hole goes without pretending to be the hole: nothing here
#   cuts the top, because a cutout is a workmanship on the unread p.172 table
#   (Elda Q27's neighbour) and because cutting his geometry is not this engine's
#   business any more.
#
# WHY THE POSITION IS NOT IN THE ORDER, SAID ONCE. Two bowls of the same size on
# one top cost the same wherever they sit. So a mark somebody nudges does not
# make the order stale - which is what lets the mark be a plain group and the
# variant be the truth.
#
# ---- AND IT RECOVERS SOMETHING THAT WAS LOST ------------------------------
#
# When build_worktop lost its button, the model lost the only thing that checked
# stone actually covered the cabinets. This tool cannot place a mark without
# finding a stamped top above the cabinet, and it says so when it fails. It is
# not the report that is owed - it looks at one cabinet, not the kitchen - but
# it is the first thing since the change that refuses to pretend there is stone
# where there is none.

module UCON
  module CabinetEngine
    module SinkMark
      module_function

      MARK_TAG      = 'UCON — Sink marks'
      LIFT_MM       = 1.0   # Andriy's spec: 1 mm above the stone, so nothing z-fights
      CLIENT_KEY    = 'client_sink'

      # ---- THE SIZES COME FROM THE PAGE, NOT FROM MEMORY ------------------
      #
      # Read out of the section file rather than retyped here, so that the day
      # printed p.110 is re-read the sizes and the points move together and this
      # file is not a second, staler copy of the catalog. The keys are the
      # catalog's own - integrated_bowl_50x40x19 - and they carry the
      # dimensions in CENTIMETRES, which is how that page prints every size.
      def catalog_bowls
        file = File.join(Registry.registry_dir, 'tops_ceramic_linear_elements.json')
        return [] unless File.exist?(file)

        sec = JSON.parse(File.read(file))
        (sec['surcharges'] || {}).map do |key, v|
          m = key.match(/\Aintegrated_bowl_(\d+)x(\d+)x(\d+)\z/)
          next unless m

          { 'key'    => key,
            'label'  => "Integrated bowl #{m[1]}×#{m[2]}×#{m[3]} cm",
            'w_mm'   => m[1].to_i * 10,
            'd_mm'   => m[2].to_i * 10,
            'h_mm'   => m[3].to_i * 10,
            'points' => v['points'],
            'um'     => v['um'] }
        end.compact.sort_by { |b| b['w_mm'] }
      end

      # THE FOURTH TYPE IS NOT A CATALOG ONE AND MUST NOT LOOK LIKE ONE. A sink
      # the client buys elsewhere is drawn the same way and priced completely
      # differently: Cesar charges nothing for it, and the CUTOUT it needs is a
      # workmanship on the table at printed p.172 that nobody has read. So it
      # carries no points, no code, and a note that says both.
      def client_bowl(w_mm, d_mm)
        w = w_mm.to_f
        d = d_mm.to_f
        unless w.positive? && d.positive?
          raise ArgumentError,
                "A sink of your own still has a size; got #{w_mm.inspect} × #{d_mm.inspect}."
        end

        { 'key'   => CLIENT_KEY,
          'label' => "Client's own sink #{w.round} × #{d.round} mm",
          'w_mm'  => w, 'd_mm' => d, 'h_mm' => nil,
          'points' => nil, 'um' => nil }
      end

      def options
        catalog_bowls.map { |b| b['label'] } + ["Client's own — size below"]
      end

      # ---- IT HAS TO FIT THE STONE ----------------------------------------
      #
      # A 70 cm bowl does not go into a 380 band, and finding that out at the
      # factory is worse than finding it out here. The margin is not a rule
      # anybody printed - it is the plain fact that a hole needs stone around it
      # - so this REMARKS on a tight fit and REFUSES only what cannot physically
      # be cut.
      MIN_STONE_MM = 30.0

      def fit(bowl, top_attrs)
        depth = top_attrs['depth_mm'].to_f
        width = top_attrs['width_mm'].to_f
        if bowl['d_mm'].to_f >= depth
          raise ArgumentError,
                "That bowl is #{bowl['d_mm'].round} mm front to back and the top is " \
                "#{depth.round} deep.\n\nThere is no stone left around it. A bigger band " \
                'or a smaller bowl - the drawing cannot decide which.'
        end
        if bowl['w_mm'].to_f >= width
          raise ArgumentError,
                "That bowl is #{bowl['w_mm'].round} mm wide and the piece of stone is " \
                "#{width.round}.\n\nIt does not fit in this piece at all."
        end

        clear = ((depth - bowl['d_mm'].to_f) / 2.0).round(1)
        return [] if clear >= MIN_STONE_MM

        ["only #{clear} mm of stone front and back of the bowl - thin enough to be worth " \
         'looking at before it is cut']
      end

      # ---- THE ORDER FACT --------------------------------------------------
      #
      # One variant per bowl, keyed by the CABINET it sits over, so running the
      # tool twice on the same sink unit replaces its entry instead of quietly
      # ordering a second bowl. Two different sink units on one top are two
      # entries, which is correct - and two bowls over one unit is not a thing
      # this offers, because nobody has asked for it and inventing it would be
      # inventing a kitchen.
      #
      # NO POINTS TRAVEL. Contract SS1.2. The label names the catalog key and the
      # exporter looks the number up where it is printed.
      def variants_with(top_attrs, bowl, over_code)
        kept = Array(top_attrs['variants']).reject do |v|
          v['key'].to_s.start_with?('sink_') && v['value'].to_s.include?("over #{over_code}")
        end
        kept + [{
          'key'   => "sink_#{bowl['key']}",
          'label' => bowl['label'],
          'value' => if bowl['key'] == CLIENT_KEY
                       "#{bowl['w_mm'].round} × #{bowl['d_mm'].round} mm over #{over_code} - " \
                       "THE CLIENT'S OWN: Cesar charges nothing for it, and the CUTOUT it " \
                       'needs is a workmanship on the table at printed p.172, which is unread ' \
                       'and unpriced.'
                     else
                       "#{bowl['key']} over #{over_code} - a surcharge on THIS top, printed " \
                       'p.110, priced each. The plug is a separate line if it is wanted.'
                     end
        }]
      end

      # The rectangle, in the cabinet's own frame so that a unit standing at an
      # angle gets a mark standing at the same angle. Returned as plain corner
      # pairs in millimetres; the drawing code turns them into edges, and this
      # stays testable without SketchUp.
      #
      # CENTRED ON THE CABINET, NOT ON THE STONE, and the difference is 30 mm.
      # The top is drawn by hand now, so where its front edge falls in this
      # cabinet's frame is not something the engine can be sure of; the cabinet
      # it sits over is exact. A sink centres on its unit anyway - that is what
      # the unit is for - and a bowl somebody wants further forward is a bowl
      # somebody drags, because position is not in the order.
      def rect_mm(bowl, cabinet_width_mm, cabinet_depth_mm)
        cx = cabinet_width_mm.to_f / 2.0
        cy = cabinet_depth_mm.to_f / 2.0
        hw = bowl['w_mm'].to_f / 2.0
        hd = bowl['d_mm'].to_f / 2.0
        [[cx - hw, cy - hd], [cx + hw, cy - hd], [cx + hw, cy + hd], [cx - hw, cy + hd]]
      end
    end
  end
end

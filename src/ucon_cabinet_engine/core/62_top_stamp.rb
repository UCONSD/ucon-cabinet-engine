# frozen_string_literal: true
#
# UCON Cabinet Engine — core/62_top_stamp.rb  ::  THE ENGINE STOPS DRAWING TOPS
# AND STARTS NAMING THEM.
#
# 2026-08-28, Andriy's call, and it is a better division of labour than the one
# it replaces:
#
#   HE draws the stone. Real kitchens have angled walls, scribed ends, mitres
#   and 45-degree returns, and every rule that generated such a shape would
#   have been inferred from ONE kitchen — which is the thing this project has
#   spent weeks refusing to do everywhere else.
#
#   THE ENGINE names it. Which article, which finish group, which depth band,
#   what it measures, whether it comes out of a sheet at all, and what line it
#   becomes on an order. None of that is visible in geometry and all of it is
#   what the engine is actually for.
#
# WHAT IS NOT LOST. The registry, the two price axes, the eight bands, the
# 3140 sheet, the refusals — all of it stands and all of it is enforced here
# instead of in the generator. Only Generator.build_worktop's geometry goes
# unused, and that was the least valuable part of it.
#
# WHAT IS LOST, SAID OUT LOUD. A stamped top does not know the run beneath it,
# so nothing checks that the stone actually covers the cabinets. build_worktop
# knew, because it measured them. That check has to come back one day as a
# report over the model — 'carcasses with no stone above them' — and until it
# does, covering the run is Andriy's eye and nothing else.
#
# ---- THE ONE ASSUMPTION IN THIS FILE ---------------------------------------
#
# A top is priced BY THE LINEAR METRE at a depth band. A piece with a mitre or
# a 45-degree return has no single length, so the order figure is taken from
# the piece's BOUNDING RECTANGLE — the sheet it is cut from — and everything
# the shape does inside that rectangle is a workmanship.
#
# THE CATALOG DOES NOT SAY THIS. It is our reading of how stone is sold, it is
# held on Andriy's decision of 2026-08-28, it is written onto every object it
# touches, and it is Elda Q28. If she answers otherwise, the numbers move and
# nothing else does — which is exactly why the assumption lives in one place.

module UCON
  module CabinetEngine
    module TopStamp
      module_function

      # ---- MEASURING A SLAB WITHOUT AN AXIS CONVENTION --------------------
      #
      # A slab is THIN IN ONE DIRECTION and that is the only thing true of every
      # one of them. So the thickness is the smallest of the three dimensions —
      # no convention to remember, no group axes to set, nothing to get wrong at
      # 45 degrees.
      #
      # WHICH OF THE OTHER TWO IS THE DEPTH IS DECIDED BY HIS OWN CHOICE, not by
      # size. Sorting would call a 300 x 650 return piece '650 long and 300
      # deep', which is backwards and would price it at a band it was never cut
      # to. The BAND is already being chosen in the dialog, so the dimension
      # nearer the band is the depth and the other is the length. Deterministic,
      # and it uses a decision that has already been made rather than inventing
      # a second one.
      def measure(dims_mm, band_mm)
        d = Array(dims_mm).map { |v| v.to_f.round(1) }.sort
        raise ArgumentError, 'a slab is measured in three dimensions' unless d.length == 3
        raise ArgumentError, 'that has no thickness at all' unless d[0].positive?

        thickness = d[0]
        rest      = [d[1], d[2]]
        band      = band_mm.to_f
        depth     = rest.min_by { |v| (v - band).abs }
        length    = (rest - [depth]).first || depth

        { thickness_mm: thickness, depth_mm: depth, length_mm: length }
      end

      # ---- WHAT THE MEASUREMENT HAS TO SURVIVE ----------------------------
      #
      # Three of these REFUSE and one only speaks, and the difference is whether
      # the drawing would become a lie or merely an expensive choice.
      #
      #   a thickness that is not the article's IS a lie — a 30 mm slab stamped
      #   TOPDR008040 says 40 in the order and shows 30 in the elevation;
      #   a piece longer than the sheet cannot be made at all;
      #   a piece DEEPER than its band is priced at a depth it does not have,
      #   and the band, not the drawing, is what is wrong.
      #
      #   a piece SHALLOWER than its band is perfectly makeable: it is stone cut
      #   down from a wider band, and somebody is paying for the part that was
      #   cut off. That is a decision, not an error, so it is named and left
      #   alone. It is also the shape of a legitimate order — a 620 band does not
      #   exist, so a 644,5 run buys 650 and cuts nothing.
      #
      # TOLERANCE. Hand-drawn geometry lands on fractions of a millimetre, and a
      # refusal at 0,3 mm would be a refusal about SketchUp rather than about
      # stone. One millimetre, everywhere, stated once.
      TOLERANCE_MM = 1.0

      def verify(measured, article)
        t = article[:thickness_mm].to_f
        if (measured[:thickness_mm] - t).abs > TOLERANCE_MM
          raise ArgumentError,
                "That slab is #{measured[:thickness_mm].round(1)} mm thick and " \
                "#{article[:code]} is #{t.round}.\n\n" \
                'The order would say one number and the drawing would show the other. ' \
                'Redraw it at the article\'s thickness, or stamp it with the article ' \
                'it was drawn at.'
        end

        max = article[:unit]['max_length_mm'].to_f
        if max.positive? && measured[:length_mm] > max + TOLERANCE_MM
          raise ArgumentError,
                "That piece is #{measured[:length_mm].round} mm long and one top is " \
                "#{max.round} at most.\n\n" \
                'It does not come out of a sheet. Cut it into two pieces and stamp each ' \
                'of them - the joint between them is a line somebody has to price ' \
                '(Elda Q27), and where it falls is a decision worth making on purpose.'
        end

        band = article[:depth_mm].to_f
        if measured[:depth_mm] > band + TOLERANCE_MM
          raise ArgumentError,
                "That piece is #{measured[:depth_mm].round} mm deep and band #{band.round} " \
                "is what it would be ordered at.\n\n" \
                'Stone cannot be wider than the band it is cut from, so the BAND is what ' \
                "is wrong here, not the drawing. The bands are " \
                "#{Array(article[:unit]['depth_bands_mm']).join(', ')} mm."
        end

        nil
      end

      # A SENTENCE, NOT A REFUSAL. Everything here is legal and priced; it is
      # just worth a person seeing it once.
      def remarks(measured, article)
        out = []
        band = article[:depth_mm].to_f
        waste = (band - measured[:depth_mm]).round(1)
        if waste > TOLERANCE_MM
          out << "cut down from band #{band.round}: #{waste.round} mm of the band's " \
                 'width is paid for and not drawn'
        end
        out
      end

      # ---- THE ORDER LINE -------------------------------------------------
      #
      # MEASURED and STATED are kept apart on the object, exactly as they are
      # everywhere else in this engine. The article, the group, the finish and
      # the band are DECISIONS and they are stated. The length, the depth and
      # the thickness are MEASURED off geometry Andriy drew, and the note says
      # when - because he can move an edge afterwards and the number here would
      # not know. Re-stamping the same piece re-measures it, which is the whole
      # reason stamping is idempotent.
      #
      # NO POINTS, NO PRICE. Contract SS1.2: pricing_group_ref carries the
      # REFERENCE and never a number, and nothing else here goes near one. The
      # exporter looks the points up from the registry, where they are printed.
      def attributes_for(measured, article, visible_side_edges: 0, drawn_on: nil)
        edges = visible_side_edges.to_i
        raise ArgumentError, 'a piece has two side edges at most' unless (0..2).cover?(edges)

        variants = []
        if edges.positive?
          variants << { 'key' => 'visible_side_edge', 'label' => 'Visible side edge',
                        'value' => "#{edges} side(s), #{measured[:depth_mm].round} mm each - " \
                                   'printed p.110 prices it per linear metre' }
        end

        { 'schema_version'    => Contract::SCHEMA_VERSION,
          'object_class'      => 'worktop',
          'manufacturer'      => 'cesar',
          'family'            => article[:family],
          'unit_type'         => article[:unit_type],
          'geometry_kind'     => 'linear',
          'width_mm'          => measured[:length_mm],
          'depth_mm'          => article[:depth_mm],
          'height_mm'         => measured[:thickness_mm],
          'code'              => article[:code],
          'code_status'       => 'PRELIMINARY',
          'status'            => 'PLANNING',
          'pricing_group_ref' => article[:pricing_group_ref],
          'source_ref'        => article[:source_ref],
          'variants'          => variants,
          'notes'             => stamp_note(measured, article, edges, drawn_on) }
      end

      def stamp_note(measured, article, edges, drawn_on)
        parts = []
        parts << "DRAWN BY HAND and stamped#{drawn_on ? " on #{drawn_on}" : ''}: this engine did " \
                 'not make this shape and does not know the run beneath it.'
        parts << "MEASURED off the geometry - #{measured[:length_mm].round} long, " \
                 "#{measured[:depth_mm].round} deep, #{measured[:thickness_mm].round(1)} thick. " \
                 'Move an edge and this number is stale until the piece is stamped again.'
        parts << "STATED: band #{article[:depth_mm].round}, finish group " \
                 "#{article[:pricing_group_ref]}. #{article[:finish_note]}"
        parts << 'ORDERED BY THE BOUNDING RECTANGLE - the sheet this piece is cut from - ' \
                 'because a mitred or angled piece has no single length. THE CATALOG DOES ' \
                 'NOT SAY THIS: it is our reading of how stone is sold, and it is Elda Q28.'
        unless (r = remarks(measured, article)).empty?
          parts << "Noted: #{r.join('; ')}."
        end
        if edges.positive?
          parts << "#{edges} visible side edge(s) - a surcharge per linear metre, printed p.110."
        end
        parts.join(' ')
      end
    end
  end
end

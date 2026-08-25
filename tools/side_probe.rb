# tools/side_probe.rb - READ-ONLY: why the side rule chose what it chose.
#
# Select the unit you would build next to, then run:
#
#   load '/Users/andriydemko/dev/ucon-cabinet-engine/tools/side_probe.rb'
#
# Changes NOTHING. Prints to the console AND writes tools/side_probe_report.txt
# inside the repository.
#
# It runs the REAL code path - Generator.span_for_attrs, Placement.same_row?,
# Placement.side_beside - and shows every candidate neighbour with the three
# numbers the row test looks at, so a wrong answer names its own reason instead
# of being guessed at from a screenshot.

module UCON
  module SideProbe
    MM = 25.4
    module_function

    def mm(v); (v.to_f * MM).round(1); end

    def run
      m = Sketchup.active_model
      g = UCON::CabinetEngine::Generator
      pl = UCON::CabinetEngine::Placement
      c  = UCON::CabinetEngine::Contract
      out = []

      sel = m.selection.grep(Sketchup::ComponentInstance).find do |i|
        i.definition.get_attribute(c::DICTIONARY, 'code')
      end
      if sel.nil?
        puts 'Nothing with a UCON code is selected.'
        return false
      end

      mine = c.read(sel.definition)
      t    = sel.transformation
      xv   = Geom::Vector3d.new(1, 0, 0).transform(t); xv.normalize!
      yv   = Geom::Vector3d.new(0, 1, 0).transform(t); yv.normalize!
      span = g.span_for_attrs(mine)

      out << 'UCON side probe - READ-ONLY. Millimetres.'
      out << "selected: #{mine['code']}  #{mine['unit_type'].to_s[0, 60]}"
      out << "  width=#{mine['width_mm']} depth=#{mine['depth_mm']} mounting=#{mine['mounting']} " \
             "kind=#{mine['geometry_kind']}"
      out << "  origin #{[mm(t.origin.x), mm(t.origin.y), mm(t.origin.z)].inspect}"
      out << "  its own +x in world: #{[xv.x.round(3), xv.y.round(3), xv.z.round(3)].inspect}" \
             '   <- THIS is what "right" means'
      out << "  span along its x: #{span.inspect}"
      out << ''
      out << 'candidates (every component with a code, in the selected unit\'s frame):'

      spans = []
      m.entities.grep(Sketchup::ComponentInstance).each do |other|
        next if other == sel

        a = c.read(other.definition)
        next unless a['code']

        ot = other.transformation
        line = "  #{a['code'].to_s.ljust(9)}"
        unless a['depth_mm']
          out << line + 'skipped: no depth_mm'
          next
        end
        os = g.span_for_attrs(a)
        if os.nil?
          out << line + 'skipped: no span (no width and no corner geometry)'
          next
        end

        axis = Geom::Vector3d.new(0, 1, 0).transform(ot); axis.normalize!
        dot    = axis.dot(yv)
        offset = (ot.origin - t.origin).dot(yv).to_mm
        ends   = os.map { |x| (Geom::Point3d.new(x.mm, 0, 0).transform(ot) - t.origin).dot(xv).to_mm }
        lo, hi = ends.minmax

        same = pl.same_row?(mine['mounting'], a['mounting'], dot, offset)
        line += "x #{lo.round(1)}..#{hi.round(1)}  axis_dot #{dot.round(3)}  " \
                "front_offset #{offset.round(1)}  mounting #{a['mounting']}  "
        if same
          spans << [lo, hi]
          touch_r = hi > span[1] && (lo - span[1]).abs <= pl::SNAP_MM
          touch_l = lo < span[0] && (span[0] - hi).abs <= pl::SNAP_MM
          line += 'IN ROW'
          line += touch_r ? '  -> TOUCHES ON THE RIGHT' : ''
          line += touch_l ? '  -> TOUCHES ON THE LEFT' : ''
          line += '  (in the row, but not touching)' unless touch_r || touch_l
        else
          why = []
          why << "mounting #{mine['mounting']} vs #{a['mounting']}" unless
            mine['mounting'].to_s == a['mounting'].to_s
          why << "not parallel (#{dot.round(3)} < #{pl::PARALLEL_MIN})" if dot < pl::PARALLEL_MIN
          why << "front planes #{offset.round(1)} apart (tolerance #{pl::COPLANAR_TOL_MM})" if
            offset.abs > pl::COPLANAR_TOL_MM
          line += "NOT IN ROW: #{why.join('; ')}"
        end
        out << line
      end

      side = pl.side_beside(span[0], span[1], spans)
      out << ''
      out << "DECISION: #{side}"
      if mine['geometry_kind'].to_s == 'corner'
        u = begin
          UCON::CabinetEngine::Registry.lookup(mine['code'])
        rescue StandardError
          nil
        end
        if u
          te = pl.corner_turn_end(u['execution'])
          out << "corner: execution #{u['execution']}, wasted end #{te}, " \
                 "turns on this side: #{pl.turning?(side, te)}"
        end
      end

      text = out.join("\n")
      path = File.join(File.dirname(__FILE__), 'side_probe_report.txt')
      File.open(path, 'w') { |f| f.write(text) }
      puts text
      puts "\nreport written: #{path}"
      puts 'Nothing in the model was changed.'
      true
    end
  end
end

UCON::SideProbe.run

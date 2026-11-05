# tools/layout/details/blocking_2x6.rb - UNIVERSAL DETAIL D-501: 2x6 blocking for cabinets in a 2x4 stud wall.
# Andriy 2026-10-26: the band on the MEP elevations was not readable on its own; every MEP set that carries blocking now
# ends with this sheet, and the bands say "SEE D-501". Not project data: it is drawn from the rules in mep_points.rb
# (2x6 flat, axis 50 = 2" below the top / above the bottom of the cabinet, to the next stud past each end) and the
# decisions of 2026-10-26 (16" o.c., three fastening options, top + bottom rows for wall-hung cabinets).
# Pure LayOut 2D: no viewport, no model - so it looks the same in every set. Paper inches, y down.
module UCON
  module DrawingSet
    DET_INK = [0x1C, 0x1D, 0x1F].freeze
    DET_WOOD = [0xEF, 0xE3, 0xD3].freeze
    DET_STUD = [0xF6, 0xF1, 0xE8].freeze
    DET_GYP = [0xE6, 0xE6, 0xE2].freeze

    # a dimension between two paper points with its own text (not tied to a model)
    def det_dim(ax, ay, bx, by, off, txt)
      @l_dims_det = nil if @l_dims_det && @l_dims_det.document != @doc rescue nil
      @l_dims_det ||= @doc.layers.add('Dimensions (details)', false)
      d = Layout::LinearDimension.new(Geom::Point2d.new(ax, ay), Geom::Point2d.new(bx, by), off)
      add(d, @l_dims_det)
      d.style = dim_style
      d.custom_text = true
      t = d.text; t.plain_text = txt
      t.style = dim_style.get_sub_style(Layout::Style::DIMENSION_TEXT) rescue nil
      d.text = t
      d.style = dim_style
      d
    end

    # leader: a line from (x0, y0) to the text, text left- or right-aligned at (x1, y1)
    def det_lead(x0, y0, x1, y1, str, l, align: :left, size: 6.5)
      line(x0, y0, x1, y1, l, w: 0.35, c: INK2)
      text(str, x1 + (align == :left ? 0.04 : -0.04), y1 - 0.06, l, size: size, font: MONO, c: INK, align: align)
    end

    def det_screw(x0, y0, x1, y1, l)
      line(x0, y0, x1, y1, l, w: 1.2, c: DET_INK)
      ang = Math.atan2(y1 - y0, x1 - x0); r = 0.035
      line(x0 - Math.sin(ang) * r, y0 + Math.cos(ang) * r, x0 + Math.sin(ang) * r, y0 - Math.cos(ang) * r, l, w: 1.2, c: DET_INK)
    end

    # off: the 2x6 axis from the cabinet edge, inches - 2 (2026-10-15/26: on the hanging rail) or 0 (Andriy 2026-11-04,
    # 1791: axis ON the top / bottom edge, so the cabinet can move up or down and still land on the band)
    def mep_page_detail_blocking(code = 'D-501', off: 2.0)
      @detail_code = code
      edge = off.zero?
      next_page('BLOCKING DETAIL'); header(NTS); sheet_code(code)
      l = @l_sheet
      gap = GUT
      w1 = 5.6; w2 = 3.2; w3 = WW - w1 - w2 - 2 * gap
      x1 = WX; x2 = WX + w1 + gap; x3 = x2 + w2 + gap
      vh = WH - LABEL_GAP - LABEL_H

      # ---------------------------------------------------- 1 ELEVATION (studs 16" o.c., 3/4" = 1'-0")
      k = 0.0625 # paper in per real inch
      ox = x1 + 0.45; floor = WY + 4.4
      studs = (0..5).map { |i| i * 16.0 }
      zr = ->(zin) { floor - zin * k }
      xr = ->(xin) { ox + xin * k }
      line(xr.(-4), zr.(0), xr.(84), zr.(0), l, w: 1.0) # floor
      text('FLOOR', xr.(-4), zr.(0) + 0.05, l, size: 6, font: MONO, c: INK2)
      studs.each do |sx|
        rect(xr.(sx - 0.75), zr.(54), 1.5 * k, 54 * k, l, stroke: DET_INK, sw: 0.5, fill: DET_STUD)
      end
      cab = [20.0, 56.0, 10.0, 32.5] # a wall-hung cabinet, x0 x1 z0 z1 (inches) - an example, not a project
      rows = edge ? [[cab[3], 'TOP ROW - CL ON THE CABINET TOP EDGE'], [cab[2], 'BOTTOM ROW - CL ON THE CABINET BOTTOM EDGE']] :
                   [[cab[3] - off, 'TOP ROW - CL 2" BELOW CABINET TOP (HANGING RAIL)'], [cab[2] + off, 'BOTTOM ROW - CL 2" ABOVE CABINET BOTTOM']]
      rows.each do |cl, _|
        studs.each_cons(2) do |a, b|
          solid = b > cab[0] && a < cab[1]
          ext = (b == 16.0 || a == 64.0)
          next unless solid || ext
          rect(xr.(a + 0.75), zr.(cl + 2.75), (b - a - 1.5) * k, 5.5 * k, l, stroke: DET_INK, sw: 0.5, fill: solid ? DET_WOOD : nil, dash: !solid)
        end
        line(xr.(16.75), zr.(cl), xr.(63.25), zr.(cl), l, w: 0.35, c: INK2, dash: true)
      end
      rect(xr.(cab[0]), zr.(cab[3]), (cab[1] - cab[0]) * k, (cab[3] - cab[2]) * k, l, stroke: ACCENT, sw: 0.75, dash: true)
      text('CABINET (WALL-HUNG)', xr.((cab[0] + cab[1]) / 2), zr.((cab[2] + cab[3]) / 2) - 0.05, l, size: 6, font: MONO, c: ACCENT, align: :center)
      # labels ABOVE the studs and BELOW the floor - never inside the frame, never toward the section (v0.2)
      line(xr.(8), zr.(rows[0][0]), xr.(30), zr.(66), l, w: 0.35, c: INK2)
      det_lead(xr.(72), zr.(rows[0][0]), xr.(30), zr.(66), 'DASHED = EXTEND TO NEXT STUD EACH SIDE', l)
      det_lead(xr.(40), zr.(rows[0][0]), xr.(30), zr.(60), rows[0][1], l)
      det_lead(xr.(40), zr.(rows[1][0]), xr.(30), zr.(-11), rows[1][1], l)
      # 16" o.c. under the floor, the band height inside the last solid bay
      [[0, 16], [16, 32], [32, 48]].each { |a, b| det_dim(xr.(a), zr.(0), xr.(b), zr.(0), 0.2, '16" O.C.') }
      det_dim(xr.(60), zr.(rows[0][0] + 2.75), xr.(60), zr.(rows[0][0] - 2.75), 0.0, '5 1/2"')
      view(x1, WY, w1, WH, 1, code, 'BLOCKING - ELEVATION', :nts, placeholder: false)

      # ---------------------------------------------------- 2 SECTION (1 1/2" = 1'-0")
      s = 0.125
      wx = x2 + 1.85 # back face of the stud - labels all on the left (v0.2)
      fl = WY + 6.2
      zs = ->(zin) { fl - zin * s }
      face = wx + 3.5 * s # room face of the stud = face of the blocking
      rect(wx, zs.(44), 3.5 * s, 44 * s, l, stroke: DET_INK, sw: 0.5, fill: DET_STUD)
      rect(face, zs.(44), 0.5 * s, 44 * s, l, stroke: DET_INK, sw: 0.5, fill: DET_GYP)
      line(wx - 0.3, zs.(0), face + 0.5 * s + 0.95, zs.(0), l, w: 1.0)
      cab = [10.0, 32.5]
      [cab[1] - off, cab[0] + off].each do |cl|
        rect(face - 1.5 * s, zs.(cl + 2.75), 1.5 * s, 5.5 * s, l, stroke: DET_INK, sw: 0.75, fill: DET_WOOD)
        line(face - 1.5 * s, zs.(cl + 2.75), face, zs.(cl - 2.75), l, w: 0.3, c: INK2)
        line(face - 1.5 * s, zs.(cl - 2.75), face, zs.(cl + 2.75), l, w: 0.3, c: INK2)
        det_screw(face + 0.5 * s + 0.45, zs.(cl), face - 1.2 * s, zs.(cl), l)
      end
      cx = face + 0.5 * s
      rect(cx, zs.(cab[1]), 0.85, (cab[1] - cab[0]) * s, l, stroke: ACCENT, sw: 0.75, dash: true)
      text('CABINET', cx + 0.45, zs.((cab[0] + cab[1]) / 2) - 0.05, l, size: 6, font: MONO, c: ACCENT, align: :center)
      rect(cx, zs.(cab[1] - 0.5), 0.12, 2.5 * s, l, stroke: DET_INK, sw: 0.5, fill: [0xC8, 0xC8, 0xC4])
      det_lead(wx + 1.75 * s, zs.(40), wx - 0.25, zs.(43), '2x4 STUD', l, align: :right)
      det_lead(face - 0.75 * s, zs.(cab[1] - off), wx - 0.25, zs.(33.5), "2x6 FLAT, FLUSH\nWITH STUD FACE", l, align: :right)
      det_lead(wx + 1.0 * s, zs.(cab[1] - 9), wx - 0.25, zs.(cab[1] - 12), "2\" CLEAR BEHIND\nFOR PIPE / CABLE", l, align: :right)
      det_lead(face + 0.25 * s, zs.(42), wx - 0.25, zs.(47), '1/2" DRYWALL', l, align: :right)
      det_lead(cx + 0.06, zs.(cab[1] - 0.8), wx - 0.25, zs.(38.5), "HANGING RAIL\n(CABINET MFR)", l, align: :right)
      det_lead(face + 0.5 * s + 0.3, zs.(cab[0] + off), wx - 0.25, zs.(cab[0] - 4), "SCREWS THROUGH\nCABINET BACK", l, align: :right)
      det_dim(wx, zs.(44), face, zs.(44), -0.22, '3 1/2"')
      det_dim(face - 1.5 * s, zs.(-1), face, zs.(-1), 0.3, '1 1/2"')
      view(x2, WY, w2, WH, 2, code, 'SECTION', :nts, placeholder: false)

      # ---------------------------------------------------- 3 FASTENING - three options, plan views (3" = 1'-0")
      q = 0.25
      opts = [['A', 'THROUGH THE STUD', '2 x #10 x 3" STRUCTURAL SCREWS EACH END, INTO THE END GRAIN'],
              ['B', 'POCKET SCREWS', '2 x 2 1/2" POCKET SCREWS EACH END, FROM THE BACK FACE'],
              ['C', 'TOE SCREWS', '2 x 3" SCREWS EACH END, AT 45 DEG FROM THE ROOM FACE']]
      ch = (vh - 0.3) / 3
      opts.each_with_index do |(tag, name, how), i|
        y0 = WY + i * ch + 0.15
        text("#{tag}  #{name}", x3, y0, l, size: 8, bold: true)
        box_text(how, x3, y0 + 0.17, w3, 0.3, l, size: 6.5, c: INK2)
        by = y0 + 0.75 # back face line of the studs (plan: room face is down)
        sx0 = x3 + 0.25; sx1 = sx0 + 1.5 * q + 7.0 * q
        [sx0, sx1].each { |sx| rect(sx, by, 1.5 * q, 3.5 * q, l, stroke: DET_INK, sw: 0.5, fill: DET_STUD) }
        bx0 = sx0 + 1.5 * q; bx1 = sx1
        rect(bx0, by + 2.0 * q, bx1 - bx0, 1.5 * q, l, stroke: DET_INK, sw: 0.75, fill: DET_WOOD)
        line(sx0 - 0.1, by + 3.5 * q, sx1 + 1.5 * q + 0.1, by + 3.5 * q, l, w: 0.35, c: INK2, dash: true)
        text('ROOM FACE', sx1 + 1.5 * q + 0.12, by + 3.5 * q - 0.06, l, size: 5.5, font: MONO, c: INK2)
        ym = by + 2.75 * q
        case tag
        when 'A'
          [ym - 0.08, ym + 0.08].each { |yy| det_screw(sx0 - 0.05, yy, bx0 + 0.55, yy, l); det_screw(sx1 + 1.5 * q + 0.05, yy, bx1 - 0.55, yy, l) }
        when 'B'
          [[bx0 + 0.6, bx0 - 0.08], [bx1 - 0.6, bx1 + 0.08]].each do |fx, tx|
            [-0.05, 0.05].each { |d| det_screw(fx, by + 2.0 * q + 0.02 + d, tx, ym + d, l) }
          end
        when 'C'
          [[bx0 + 0.45, bx0 - 0.12], [bx1 - 0.45, bx1 + 0.12]].each do |fx, tx|
            [-0.05, 0.05].each { |d| det_screw(fx, by + 3.5 * q - 0.02 + d * 0.3, tx, by + 1.6 * q + d, l) }
          end
        end
      end
      view(x3, WY, w3, WH, 3, code, 'FASTENING', :nts, placeholder: false)

      # ---------------------------------------------------- notes under the elevation
      ny = WY + 5.2
      label('NOTES', x1, ny, l)
      line(x1, ny + 0.2, x1 + w1 - 0.2, ny + 0.2, l, w: 1.0)
      notes = ['2x6 laid FLAT between studs, its face flush with the room face of the studs - the drywall stays flat.',
               edge ? 'Axis ON the cabinet top edge: the 5 1/2" band covers 2 3/4" up and down, so the cabinet can be set a little higher or lower and still land on it (hanging rail inside the band). Heights and lengths per the MEP elevations.' :
                      'Axis 2" (50 mm) below the cabinet top, on the hanging rail; heights and lengths per the MEP elevations.',
               edge ? 'Wall-hung cabinets fixed top AND bottom (cabinet maker): second row, axis ON the cabinet bottom edge.' :
                      'Wall-hung cabinets fixed top AND bottom (cabinet maker): second row, axis 2" above the cabinet bottom.',
               'Run each row to the next stud past each end of the cabinet (one more bay) - dashed on the elevations.',
               'Studs assumed 16" o.c. - verify in the field. Fasten each end by A, B or C.']
      notes.each_with_index do |n, i|
        text("#{i + 1}.", x1, ny + 0.32 + i * 0.36, l, size: 7.5, font: MONO)
        box_text(n, x1 + 0.25, ny + 0.32 + i * 0.36, w1 - 0.5, 0.34, l, size: 7.5)
      end
      @index << [code, 'BLOCKING DETAIL']
      @log << "#{code}: blocking detail (universal, axis #{edge ? 'ON the edge' : "#{off}\" from the edge"})"
    end
  end
end

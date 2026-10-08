# AP Capital - LayOut drawing set (wall panels, subframe, clips, door D01), Tabloid 11x17, mm.
# Builds the whole set from the SAVED model. Used by read-only probes; nothing in src/ requires it.
# Spec: project doc claude/spec-2026-10-07-ap-layout-sheet-set.md (v5). Template: ucon_sheet_template.rb / ucon_drawing_set.rb.
require 'csv'
load File.join(__dir__, 'ucon_drawing_set.rb')

module UCON
  module APSet
    include UCON::SheetTemplate
    include UCON::DrawingSet
    extend UCON::SheetTemplate
    extend UCON::DrawingSet

    FY = -44.3            # panel face (frame 19 + clip gap 3.3 + panel 22)
    FRY0 = -32.3          # D01 jamb front
    FRY1 = 169.5          # D01 jamb back -> jamb 201.8

    TAGS = { 'ProjectName' => 'AP Capital', 'ProjectAddress' => "29 Waves End\nNewport Coast, CA 92657\nUnited States",
             'ProjectNumber' => 'TM 260318', 'ClientName' => 'AP Capital', 'Designer' => 'AD', 'Drafter' => 'AD',
             'CheckedBy' => ' ', 'Issue' => 'For factory review', 'Revision' => '1.1', 'IssueDate' => '10.08.26',
             'Status' => 'FOR FACTORY REVIEW',
             'StatusDesc' => 'Dimensions per UCON site survey. Not for production until the open questions are answered and the drawings are reissued.',
             'Rev1' => '0.1', 'Rev1Desc' => 'Pilot A-301', 'Rev1Date' => '10.07.26',
             'Rev2' => '0.2', 'Rev2Desc' => 'Tables G-002, A-701, A-702', 'Rev2Date' => '10.08.26',
             'Rev3' => '0.3', 'Rev3Desc' => 'Views A-101..A-601', 'Rev3Date' => '10.08.26',
             'Rev4' => '1.1', 'Rev4Desc' => 'Full set, clip gap 3.3', 'Rev4Date' => '10.08.26' }.freeze

    INDEX = [['G-000', 'COVER'], ['G-001', 'LEGEND & GENERAL NOTES'], ['G-002', 'OPEN QUESTIONS'],
             ['A-101', 'EXISTING WALL'], ['A-201', 'SUBFRAME LAYOUT'], ['A-202', 'CLIP LAYOUT & DETAIL'],
             ['A-301', 'PANEL LAYOUT'], ['A-501', 'DOOR D01'], ['A-502', 'D01 DETAILS'], ['A-601', '3D VIEW'],
             ['A-701', 'PANEL SCHEDULE'], ['A-702', 'SUBFRAME SCHEDULE'],
             ['D-01', 'PANEL DRILLING 1'], ['D-02', 'PANEL DRILLING 2'], ['D-03', 'PANEL DRILLING 3'], ['D-04', 'PANEL DRILLING 4']].freeze
    DRILL = { 'D-01' => [%w[P02 P05 P06 P13]], 'D-02' => [%w[P14 P16]],
              'D-03' => [%w[P03 P04 P07 P08], %w[P09 P10 P11]], 'D-04' => [%w[P12 P15]] }.freeze


    QUESTIONS = [
      ['Q1', 'A-501 A-502', 'TM', 'Door D01 must be flush with the wall panels. Our build-up: backing frame 19 + clip gap 3.3 (Fastmount VL-03H, recess mount) + panel 22 = finished face 44.3 mm from wall. Please confirm a jamb depth of 201.8 mm on a 170 mm wall, and send the revised hinge/stop detail.'],
      ['Q2', 'A-501', 'TM', 'Opening per UCON survey is 995 x 2505 mm (your drawing: 989 x 2451). Please build D01 to our opening with your technical gaps: head 9, sides 4.3, floor 0 -> frame 986.3 x 2496, leaf cladding 884 x 2404, 10 mm to finished floor. Please confirm.'],
      ['Q3', 'A-501', 'TM', 'Right-handed, opens into Laundry, concealed hinges, soft-close. Please send hinge make, model and specification.'],
      ['Q4', 'A-502', 'TM', 'Your section shows the leaf body and hinge block down to 0 mm at the floor; only the cladding has a 5 mm gap. What is the actual clearance of the leaf body? Is there a threshold or seal?'],
      ['Q5', 'A-502', 'TM', 'Door cladding thickness: the current profile shows 12 mm, an older table showed 25 mm. Please confirm 12 mm.'],
      ['Q6', 'A-202 D-01..D-04', 'TM', 'Panels are hung on Fastmount VL-03H clips, recess mount, gap 3.3. Please make the clip recesses in the panel backs at the factory per sheets D-01..D-04 (D25 x 7 deep). Please confirm which clip half goes into the panel (we assume male) and that you can drill per the schedule.'],
      ['Q8', 'A-101', 'Info', 'Wall height per UCON survey is 3112 mm (your drawing: 3052). Panel rows are laid out to 3112.'],
      ['Q9', 'A-301', 'Site', 'Wine room glass door is installed; final measurement pending. Panel edges P14/P16 at the opening and bottom of P11/P12 are TBD until then.'],
      ['Q10', 'D-01..D-04', 'TM', 'All drilling coordinates are given from the panel BACK: X from the left edge as seen from the back, Z from the bottom edge. A control column gives X from the face. Please confirm before drilling - mirrored drilling is the main risk.']
    ].freeze

    # stiles per frame (left / right), from proposal-2026-10-07-ap-backing-frames
    STILES = { 'S01' => %w[4" 6"], 'S02' => %w[4" 6"], 'S03' => %w[4" 4"], 'S04' => %w[4" 6"], 'S05' => %w[4" 4"],
               'S06' => %w[4" 4"], 'S07' => %w[4" 6"], 'S08' => %w[4" 6"], 'S09' => %w[4" 4"], 'S10' => %w[6" 6"],
               'S11' => %w[4" 6"], 'S12' => %w[4" 4"], 'S13' => %w[6" 6"], 'S14' => %w[4" 6"], 'S15' => %w[4" 4"] }.freeze
    CUT = [['4"', 2355, 9], ['4"', 820, 6], ['4"', 732, 9], ['4"', 691, 2], ['4"', 681, 2], ['4"', 667, 2], ['4"', 626, 6],
           ['4"', 607, 1], ['4"', 602, 6], ['4"', 585, 6], ['4"', 376, 6], ['4"', 372, 6],
           ['6"', 2355, 3], ['6"', 820, 1], ['6"', 732, 3], ['6"', 626, 1], ['6"', 607, 5], ['6"', 602, 1], ['6"', 585, 1],
           ['6"', 376, 1], ['6"', 372, 1]].freeze


    DTXT = 6.5
    MM = 1 / 25.4

    def self.P(x, y, z) = Geom::Point3d.new(x * MM, y * MM, z * MM)
    def self.fmt(v) = ((v - v.round).abs < 0.05 ? v.round.to_s : format('%.1f', v))
    def self.pt2(x, y) = Geom::Point2d.new(x, y)

    def self.dstyle
      return @dsty if @dsty
      s = Layout::Style.new
      t = Layout::Style.new; t.font_family = SANS; t.font_size = DTXT; t.text_color = color(INK)
      s.set_sub_style(Layout::Style::DIMENSION_TEXT, t)
      [Layout::Style::DIMENSION_START_EXTENSION_LINE, Layout::Style::DIMENSION_END_EXTENSION_LINE].each do |k|
        l = Layout::Style.new; l.stroke_width = 0.25; l.stroke_color = color(INK); s.set_sub_style(k, l)
      end
      l = Layout::Style.new; l.stroke_width = 0.25; l.stroke_color = color(INK)
      l.start_arrow_type = Layout::Style::ARROW_SLASH_RIGHT; l.end_arrow_type = Layout::Style::ARROW_SLASH_RIGHT
      s.set_sub_style(Layout::Style::DIMENSION_LINE, l)
      @dsty = s
    end

    # paper dimension a->b (Point2d), offset `off` toward paper point t
    def self.pdim(a, b, off, t, label, vp: nil, a3: nil, b3: nil)
      @l_dm ||= @doc.layers.add('Dimensions mm', false)
      d = Layout::LinearDimension.new(a, b, off); add(d, @l_dm)
      c = d.bounds; cxp = c.upper_left.x + c.width / 2; cyp = c.upper_left.y + c.height / 2
      pmx = (a.x + b.x) / 2; pmy = (a.y + b.y) / 2
      if (cxp - pmx) * (t.x - pmx) + (cyp - pmy) * (t.y - pmy) < 0
        @doc.remove_entity(d); d = Layout::LinearDimension.new(a, b, -off); add(d, @l_dm)
      end
      d.style = dstyle
      (d.connect(Layout::ConnectionPoint.new(vp, a3), Layout::ConnectionPoint.new(vp, b3)) rescue nil) if vp
      d.custom_text = true
      tx = d.text; tx.plain_text = label
      (tx.style = dstyle.get_sub_style(Layout::Style::DIMENSION_TEXT) rescue nil)
      d.text = tx; d.style = dstyle
      @ndim += 1
    end

    def self.dim(vp, a3, b3, off, tw3, val, label: nil)
      a = vp.model_to_paper_point(a3); b = vp.model_to_paper_point(b3); t = vp.model_to_paper_point(tw3)
      pdim(a, b, off, t, label || fmt(val), vp: vp, a3: a3, b3: b3)
    end

    def self.bub(q, label, red: true, d: 0.30, size: 7)
      @l_q ||= @doc.layers.add('Bubbles', false)
      col = red ? RED : INK
      e = Layout::Ellipse.new(Geom::Bounds2d.new(q.x - d / 2, q.y - d / 2, d, d))
      st = Layout::Style.new; st.stroked = true; st.stroke_width = 0.75; st.stroke_color = color(col)
      st.solid_filled = true; st.fill_color = Sketchup::Color.new(255, 255, 255)
      e.style = st; add(e, @l_q)
      text(label, q.x, q.y - 0.07, @l_q, size: size, font: MONO, c: col, align: :center)
    end

    def self.vlabel(x, ly, w, no, code, name, scale_txt)
      d = LABEL_H
      circle(x + d / 2, ly + d / 2, d, @l_sheet)
      line(x + 0.06, ly + d / 2, x + d - 0.06, ly + d / 2, @l_sheet, w: 0.5)
      text(no.to_s, x + d / 2, ly + 0.035, @l_sheet, size: 8, font: MONO, align: :center)
      text(code, x + d / 2, ly + d / 2 + 0.03, @l_sheet, size: 6, font: MONO, align: :center)
      nx = x + d + 0.139
      text(name, nx, ly + 0.10, @l_sheet, size: 13.5, font: SANS_MED)
      line(nx, ly + d, x + w, ly + d, @l_sheet, w: 1.5)
      text(scale_txt, x + w, ly + 0.13, @l_sheet, size: 8, font: MONO, c: INK2, align: :right)
    end

    def self.notes(x, y, w, list, red_idx: [], size: 7.5, step: 0.18)
      label('NOTES', x, y, @l_sheet)
      line(x, y + 0.17, x + w, y + 0.17, @l_sheet, w: 1.0)
      yy = y + 0.25
      list.each_with_index do |t, i|
        c = red_idx.include?(i) ? RED : INK
        text("#{i + 1}.", x, yy, @l_sheet, size: size, font: MONO, c: c)
        lines = (t.size * size * 0.0075 / (w - 0.25)).ceil.clamp(1, 4)
        box_text(t, x + 0.22, yy, w - 0.22, step * lines + 0.04, @l_sheet, size: size, c: c)
        yy += step * lines + 0.02
      end
      yy
    end

    # viewport whose model point `c3` lands on paper point q, cropped (clip mask) to cw x ch paper inches around q.
    # proj: model point -> paper offset (dx, dy) from the scene target, in model mm, for this scene's orientation.
    def self.cropped(skp, scene, target, c3mm, q, cw, ch, scale, proj)
      dx, dy = proj.(c3mm.zip(target).map { |a, b| a - b })
      tx = q.x - dx * scale * MM; ty = q.y - dy * scale * MM
      hw = (tx - q.x).abs + cw / 2 + 0.3; hh = (ty - q.y).abs + ch / 2 + 0.3
      vp = viewport(skp, scene, tx - hw, ty - hh, 2 * hw, 2 * hh, scale: scale)
      begin
        mask = Layout::Rectangle.new(Geom::Bounds2d.new(q.x - cw / 2, q.y - ch / 2, cw, ch))
        vp.clip_mask = mask
        @log << "#{scene}: clip mask ok"
      rescue StandardError => e
        @log << "#{scene}: clip mask FAILED #{e.class}: #{e.message}"
      end
      vp.render if vp.render_needed?
      vp
    end
    ELEV = ->(d) { [d[0], -d[2]] }   # looking +y: x right, z up
    SIDE = ->(d) { [d[1], -d[2]] }   # looking -x: y right, z up
    PLAN = ->(d) { [d[0], -d[1]] }   # from above, up = +y

    # elevation 1:30 + plan 1:30 like A-301
    def self.elev_plan(skp, es, ps, code, et, pt)
      cx = WX + WW / 2
      ecy = 2.35 + 4.084 / 2
      ev = viewport(skp, es, cx - 5.5, ecy - 2.15, 11.0, 4.3, scale: 1.0 / 30); ev.render if ev.render_needed?
      vlabel(WX, 7.02, WW, 1, code, et, 'SCALE 1:30')
      pcy = 7.55 + (930 - 50) / 30.0 / 25.4
      pv = viewport(skp, ps, cx - 5.5, pcy - 1.2, 11.0, 2.4, scale: 1.0 / 30); pv.render if pv.render_needed?
      vlabel(WX, 9.35, WW, 2, code, pt, 'SCALE 1:30')
      [ev, pv, cx]
    end


    def self.data(model)
      e = model.entities
      pg = e.grep(Sketchup::Group).find { |g| g.name.start_with?('REC-LAU | solid panels 22') }
      t = pg.transformation
      dg = e.grep(Sketchup::Group).find { |g| g.name.start_with?('REC-LAU | drilling') }
      cyl = dg.entities.grep(Sketchup::Group).map do |c|
        b = Geom::BoundingBox.new; 8.times { |i| b.add(c.bounds.corner(i).transform(dg.transformation)) }
        [c.name, b.center]
      end
      panels = pg.entities.grep(Sketchup::Group).map do |c|
        b = Geom::BoundingBox.new; 8.times { |i| b.add(c.bounds.corner(i).transform(t)) }
        id = c.name[0, 3]; pos = c.name[/ (C\d-[LU]) /, 1]
        faces = c.entities.grep(Sketchup::Face).size
        holes = cyl.count { |n, _| n.start_with?("#{id}-H") && n.include?('panel') }
        { id: id, pos: pos, w: (b.max.x - b.min.x).to_mm, h: (b.max.z - b.min.z).to_mm, x0: b.min.x.to_mm, rebate: faces > 6, holes: holes }
      end.sort_by { |p| p[:id] }
      frames = e.grep(Sketchup::ComponentInstance).select { |i| i.name =~ /backing S\d\d/ }.map do |i|
        b = i.bounds
        id = i.name[/S\d\d/]
        fh = cyl.count { |n, c| n.include?('frame') && c.x.between?(b.min.x, b.max.x) && c.z.between?(b.min.z, b.max.z) }
        { id: id, x0: b.min.x.to_mm, x1: b.max.x.to_mm, z0: b.min.z.to_mm, z1: b.max.z.to_mm, holes: fh }
      end.sort_by { |f| f[:id] }
      [panels, frames, cyl]
    end

    def self.cols_x(x0, total_w, cols)
      k = total_w / cols.sum { |_, w| w }
      ws = cols.map { |_, w| w * k }
      [ws, ws.each_with_index.map { |_, i| x0 + ws[0, i].sum }]
    end

    def self.table(x0, y, total_w, cols, rows, row_h: 0.30, red: nil, size: 7.5)
      ws, xs = cols_x(x0, total_w, cols)
      cols.each_with_index { |(h, _), i| text(h, xs[i] + 0.04, y + 0.02, @l_sheet, size: 7, font: MONO, c: HEAD) }
      y += 0.22
      line(x0, y, x0 + total_w, y, @l_sheet, w: 1.0)
      rows.each do |r|
        ink = red && red.(r) ? RED : INK
        bold_row = r.first.to_s == 'TOTAL'
        r.each_with_index do |cell, i|
          next if cell.nil? || cell.to_s.empty?
          text(cell.to_s, xs[i] + 0.04, y + 0.07, @l_sheet, size: size, font: i.zero? ? MONO : SANS, c: ink, bold: bold_row)
        end
        y += row_h
        line(x0, y, x0 + total_w, y, @l_sheet, w: 0.5, c: ROWLINE)
      end
      y
    end


    def self.f1(v) = ((v - v.round).abs < 0.05 ? v.round.to_s : format('%.1f', v))

    def self.panel_boxes(model)
      g = model.entities.grep(Sketchup::Group).find { |x| x.name.start_with?('REC-LAU | solid panels 22') }
      t = g.transformation
      g.entities.grep(Sketchup::Group).map do |c|
        b = Geom::BoundingBox.new; 8.times { |i| b.add(c.bounds.corner(i).transform(t)) }
        { n: c.name[0, 3], x0: b.min.x.to_mm, x1: b.max.x.to_mm, z0: b.min.z.to_mm, z1: b.max.z.to_mm }
      end
    end

    # per panel: box, back-view holes [id, xb, z] and back-view rebate strips [xb0, xb1, z0, z1]
    def self.drill_data(model)
      e = model.entities
      pg = e.grep(Sketchup::Group).find { |g| g.name.start_with?('REC-LAU | solid panels 22') }
      dg = e.grep(Sketchup::Group).find { |g| g.name.start_with?('REC-LAU | drilling') }
      holes = dg.entities.grep(Sketchup::Group).select { |c| c.name.include?('panel') }.map do |c|
        b = Geom::BoundingBox.new; 8.times { |i| b.add(c.bounds.corner(i).transform(dg.transformation)) }
        [c.name[/P\d\d-H\d\d/], b.center.x.to_mm, b.center.z.to_mm]
      end
      t = pg.transformation
      pg.entities.grep(Sketchup::Group).to_h do |c|
        b = Geom::BoundingBox.new; 8.times { |i| b.add(c.bounds.corner(i).transform(t)) }
        x0 = b.min.x.to_mm; x1 = b.max.x.to_mm; z0 = b.min.z.to_mm; z1 = b.max.z.to_mm
        id = c.name[0, 3]
        hs = holes.select { |h, _, _| h.start_with?("#{id}-") }.map { |h, x, z| [h[-3..], (x1 - x).round(1), (z - z0).round(1)] }.sort
        tc = t * c.transformation
        reb = c.entities.grep(Sketchup::Face).select do |f|
          n = f.normal.transform(tc); next false unless n.y.abs > 0.99
          (f.vertices.first.position.transform(tc).y.to_mm - (FY + 12)).abs < 0.05
        end.map do |f|
          fb = Geom::BoundingBox.new; f.vertices.each { |v| fb.add(v.position.transform(tc)) }
          [(x1 - fb.max.x.to_mm).round(1), (x1 - fb.min.x.to_mm).round(1), (fb.min.z.to_mm - z0).round(1), (fb.max.z.to_mm - z0).round(1)]
        end
        [id, { w: x1 - x0, h: z1 - z0, holes: hs, reb: reb }]
      end
    end

    def self.drill_panel(id, d, ox, oy, k)
      px = ->(xb) { ox + xb * k }
      pz = ->(z) { oy - z * k }
      w = d[:w]; h = d[:h]
      d[:reb].each { |a, b, z0, z1| rect(px.(a), pz.(z1), (b - a) * k, (z1 - z0) * k, @l_sheet, stroke: MINOR, sw: 0.25, fill: [222, 222, 222]) }
      rect(ox, pz.(h), w * k, h * k, @l_sheet, stroke: INK, sw: 0.75)
      text("#{id} — BACK VIEW", ox + w * k / 2, pz.(h) - 0.40, @l_sheet, size: 9, font: SANS_MED, align: :center)
      text("#{f1(w)} x #{f1(h)} x 22 · #{d[:holes].size} recesses D25 x 7 · top up", ox + w * k / 2, pz.(h) - 0.20, @l_sheet, size: 6.5, font: MONO, c: INK2, align: :center)
      r = 12.5 * k; c = 0.09
      d[:holes].each do |hid, xb, z|
        cx = px.(xb); cy = pz.(z)
        e2 = Layout::Ellipse.new(Geom::Bounds2d.new(cx - r, cy - r, 2 * r, 2 * r))
        st = Layout::Style.new; st.stroked = true; st.stroke_width = 0.5; st.stroke_color = color(RED); st.solid_filled = false
        e2.style = st; add(e2, @l_sheet)
        line(cx - c, cy, cx + c, cy, @l_sheet, w: 0.25, c: RED); line(cx, cy - c, cx, cy + c, @l_sheet, w: 0.25, c: RED)
        text(hid, cx + 0.05, cy - 0.17, @l_sheet, size: 5, font: MONO, c: RED)
      end
      xs = d[:holes].map { |_, xb, _| xb }.uniq.sort
      last = -9
      xs.each_with_index do |xb, i|
        q = px.(xb); row = (q - last) < 0.32 ? 1 : 0; last = q
        line(q, oy + 0.04, q, oy + 0.14 + row * 0.13, @l_sheet, w: 0.25)
        text(f1(xb), q, oy + 0.15 + row * 0.13, @l_sheet, size: 6, font: MONO, align: :center)
      end
      d[:holes].map { |_, _, z| z }.uniq.sort.each do |z|
        q = pz.(z); line(ox - 0.14, q, ox - 0.03, q, @l_sheet, w: 0.25)
        text(f1(z), ox - 0.16, q - 0.06, @l_sheet, size: 6, font: MONO, align: :right)
      end
      pdim(pt2(ox, oy), pt2(ox + w * k, oy), 0.55, pt2(ox + w * k / 2, oy + 5), f1(w))
      pdim(pt2(ox, oy), pt2(ox, pz.(h)), 0.62, pt2(ox - 5, oy), f1(h))
    end

    def self.page_drill(code, rows, dd)
      next_page(INDEX.find { |c, _| c == code }[1]); header('SCALE 1:15 · BACK VIEW · DIMENSIONS IN MM'); sheet_code(code)
      k = MM / 15.0; gap = 0.85
      ytop = WY + 0.55
      rows.each do |ids|
        hmax = ids.map { |i| dd[i][:h] }.max * k
        ox = WX + 0.6
        ids.each do |i|
          drill_panel(i, dd[i], ox, ytop + hmax, k)
          ox += dd[i][:w] * k + gap
        end
        ytop += hmax + 1.45
      end
      box_text('BACK VIEW - the panel is seen from the WALL side. X from the LEFT edge as seen from the back, Z from the BOTTOM edge. ' \
               'Recesses D25 x 7 deep for the Fastmount VL-03H male clip (recess mount, gap 3.3) - made by the factory (Q6, Q10). ' \
               'Grey strip = rebate at the D01 frame (12 mm face remains) - no recesses there. Coordinates also in AP_REC-LAU_drilling_panels.csv.',
               WX + 0.45, WY + WH - 0.55, WW - 0.45, 0.5, @l_sheet, size: 8, c: RED)
      bub(pt2(WX + 0.17, WY + WH - 0.42), 'Q10')
    end

    def self.page_cover(skp)
      next_page('COVER', cover: true)
      cover(placeholder: false)
      v = viewport(skp, '04 3D', 0.965, 2.20, 15.264, 6.65, render: :hybrid); v.render if v.render_needed?
      text('RECREATION -> LAUNDRY WALL · WALL PANELS, BACKING FRAMES, CLIPS, CONCEALED DOOR D01', 0.965, 1.98, @l_sheet, size: 11, font: MONO, c: INK2)
    end

    def self.page_g001
      next_page('LEGEND & GENERAL NOTES'); header('NOT TO SCALE'); sheet_code('G-001')
      w = (WW - GUT) / 2; x2 = WX + w + GUT
      label('SHEET INDEX', WX, WY, @l_sheet)
      y = WY + 0.22; line(WX, y, WX + w, y, @l_sheet, w: 1.0)
      INDEX.each_with_index do |(code, name), i|
        text("#{i + 1} / #{INDEX.size}", WX, y + 0.07, @l_sheet, size: 8, font: MONO)
        text(code, WX + 0.7, y + 0.07, @l_sheet, size: 8, font: MONO, c: INK2)
        text(name, WX + 1.5, y + 0.07, @l_sheet, size: 8)
        text(TAGS['Revision'], WX + w, y + 0.07, @l_sheet, size: 8, font: MONO, c: INK2, align: :right)
        y += 0.27; line(WX, y, WX + w, y, @l_sheet, w: 0.5, c: ROWLINE)
      end
      y += 0.30
      label('LEGEND', WX, y, @l_sheet); y += 0.22; line(WX, y, WX + w, y, @l_sheet, w: 1.0); y += 0.12
      bub(pt2(WX + 0.2, y + 0.15), 'Q1'); text('Open question - see G-002 (red = open / TBD)', WX + 0.6, y + 0.08, @l_sheet, size: 8); y += 0.40
      bub(pt2(WX + 0.2, y + 0.15), 'S01', red: false, d: 0.34, size: 6.5); text('Backing frame number (A-201, A-702)', WX + 0.6, y + 0.08, @l_sheet, size: 8); y += 0.40
      text('P02', WX + 0.2, y + 0.05, @l_sheet, size: 9, align: :center); text('Panel number per TM order 260318', WX + 0.6, y + 0.08, @l_sheet, size: 8); y += 0.36
      line(WX + 0.05, y + 0.25, WX + 0.35, y + 0.05, @l_sheet, w: 0.5, dash: true); line(WX + 0.05, y + 0.25, WX + 0.35, y + 0.45, @l_sheet, w: 0.5, dash: true)
      text('Door swing on elevation - apex at the hinge side', WX + 0.6, y + 0.18, @l_sheet, size: 8); y += 0.55
      rect(WX + 0.08, y + 0.02, 0.25, 0.22, @l_sheet, stroke: MINOR, sw: 0.25, fill: [222, 222, 222]); text('Rebate at D01 frame (back view, D-sheets)', WX + 0.6, y + 0.06, @l_sheet, size: 8)
      label('GENERAL NOTES', x2, WY, @l_sheet)
      line(x2, WY + 0.22, x2 + w, WY + 0.22, @l_sheet, w: 1.0)
      notes = [
        'All dimensions in millimetres. Do not scale the drawings.',
        'Dimensions per UCON site survey govern. From TM Italia drawings only the door D01 profile is used.',
        'Build-up from the wall: backing frame S (plywood 19) + clip gap 3.3 + panel P (MDF 22) = finished face 44.3. Door D01 flush with the panels (jamb 201.8, Q1).',
        'All joints 10 mm. 10 mm to floor, ceiling and wall corners. No baseboard.',
        'Numbering: P02..P16 panels (TM order 260318), S01..S15 backing frames, Hnn clip recess per panel, D01 door.',
        'Clips: Fastmount VL-03H, recess mount, 103 on this wall. Panel recesses D25 x 7 made by the factory per D-01..D-04 (back view); frame holes D25 x 8 by UCON CNC.',
        'Panels: MDF 22, finish per TM. P06, P07, P08, P09, P13 rebated at the D01 frame (12 mm face remains).',
        'Red marks are open questions or TBD items (Q9 wine-room door). Not for production until G-002 is answered and the set is reissued.'
      ]
      ny = WY + 0.34
      notes.each_with_index do |n, i|
        text("#{i + 1}.", x2, ny, @l_sheet, size: 8.5, font: MONO, c: i == 7 ? RED : INK)
        lines = (n.size / 80.0).ceil
        box_text(n, x2 + 0.32, ny, w - 0.32, 0.17 * lines + 0.1, @l_sheet, size: 8.5, c: i == 7 ? RED : INK)
        ny += 0.17 * lines + 0.16
      end
    end

    # frames CNC list with S numbers: every frame hole, in its frame (face view) and in its member
    def self.frames_csv(model, path)
      return @log << "frames CSV exists, not rewritten: #{path}" if File.exist?(path)
      e = model.entities
      dg = e.grep(Sketchup::Group).find { |g| g.name.start_with?('REC-LAU | drilling') }
      fh = dg.entities.grep(Sketchup::Group).select { |c| c.name.include?('frame') }.map do |c|
        b = Geom::BoundingBox.new; 8.times { |i| b.add(c.bounds.corner(i).transform(dg.transformation)) }
        [c.name[/P\d\d-H\d\d/], b.center]
      end
      frames = e.grep(Sketchup::ComponentInstance).select { |i| i.name =~ /backing S\d\d/ }
      rows = []
      fh.each do |hid, pt|
        f = frames.find { |i| b = i.bounds; pt.x.between?(b.min.x, b.max.x) && pt.z.between?(b.min.z, b.max.z) } or next
        fid = f.name[/S\d\d/]; fb = f.bounds
        mem = f.definition.entities.select { |x| x.is_a?(Sketchup::Group) || x.is_a?(Sketchup::ComponentInstance) }.find do |m|
          mb = Geom::BoundingBox.new; 8.times { |i| mb.add(m.bounds.corner(i).transform(f.transformation)) }
          pt.x.between?(mb.min.x - 0.01, mb.max.x + 0.01) && pt.z.between?(mb.min.z - 0.01, mb.max.z + 0.01)
        end
        mname = '-'; ml = mw = along = across = nil
        if mem
          mb = Geom::BoundingBox.new; 8.times { |i| mb.add(mem.bounds.corner(i).transform(f.transformation)) }
          wx = (mb.max.x - mb.min.x).to_mm; hz = (mb.max.z - mb.min.z).to_mm
          nm = mem.respond_to?(:name) && !mem.name.empty? ? mem.name : (mem.respond_to?(:definition) ? mem.definition.name : 'member')
          mname = "#{fid} #{nm.sub(/\A[FS]\d\d\s*/, '')}"
          if hz >= wx
            ml = hz; mw = wx; along = (pt.z - mb.min.z).to_mm; across = (pt.x - mb.min.x).to_mm
          else
            ml = wx; mw = hz; along = (pt.x - mb.min.x).to_mm; across = (pt.z - mb.min.z).to_mm
          end
        end
        rows << [fid, mname, ml && f1(ml), mw && f1(mw), along && f1(along), across && f1(across),
                 f1((pt.x - fb.min.x).to_mm), f1((pt.z - fb.min.z).to_mm), '25', '8', hid]
      end
      rows.sort_by! { |r| [r[0], r[1], r[4].to_f] }
      CSV.open(path, 'w') do |csv|
        csv << ['frame', 'member', 'member length (mm)', 'member width (mm)', 'hole along member from its start (bottom / left end) (mm)',
                'hole across member from its left / bottom edge (mm)', 'X in frame, FACE view (mm)', 'Z in frame (mm)', 'dia (mm)', 'depth (mm)', 'mates with panel hole']
        rows.each { |r| csv << r }
      end
      @log << "frames CSV: #{rows.size} holes (#{fh.size} frame cylinders), members found #{rows.count { |r| r[1] != '-' }} -> #{path}"
    end


    def self.page_a101(skp, e)
      next_page('EXISTING WALL'); header('SCALE 1:30 · DIMENSIONS IN MM'); sheet_code('A-101')
      ev, pv, cx = elev_plan(skp, '01 Wall — Elevation', '01 Wall — Plan', 'A-101', 'ELEVATION — FROM RECREATION', 'PLAN — CUT AT 1200')
      fy = 0
      up = P(3808, fy, 9000); dn = P(3808, fy, -9000); lf = P(-9000, fy, 1556); rt = P(19000, fy, 1556)
      dim(ev, P(0, fy, 3112), P(7616, fy, 3112), 0.28, up, 7616)
      [[0, 2509], [2509, 3504], [3504, 4698], [4698, 6600], [6600, 7616]].each { |a, b| dim(ev, P(a, fy, 0), P(b, fy, 0), 0.28, dn, b - a) }
      dim(ev, P(0, fy, 0), P(0, fy, 3112), 0.28, lf, 3112)
      dim(ev, P(7616, fy, 0), P(7616, fy, 2505), 0.28, rt, 2505)
      dim(ev, P(7616, fy, 2505), P(7616, fy, 3112), 0.28, rt, 607)
      text('D01 OPENING', ev.model_to_paper_point(P(3006.5, fy, 1300)).x, ev.model_to_paper_point(P(3006.5, fy, 1300)).y, @l_sheet, size: 7, font: MONO, align: :center)
      text('WINE ROOM (GLASS DOOR INSTALLED)', ev.model_to_paper_point(P(5649, fy, 1300)).x, ev.model_to_paper_point(P(5649, fy, 1300)).y, @l_sheet, size: 7, font: MONO, align: :center)
      bub(ev.model_to_paper_point(P(450, fy, 2850)), 'Q8')
      bub(ev.model_to_paper_point(P(5649, fy, 900)), 'Q9')
      dim(pv, P(7616, 0, 1200), P(7616, 170, 1200), 0.28, P(19000, 85, 1200), 170)
      notes(cx - 0.05, 7.42, WX + WW - cx + 0.05, [
        'Wall, openings and heights per UCON site survey - they govern over factory drawings.',
        'Wall 170 mm. Openings: D01 995 x 2505 from 2509; wine room 1902 x 2505 from 4698.',
        'Q8: wall height 3112 (factory drawing 3052). Q9: wine-room glass door to be measured.'
      ], red_idx: [2], size: 7, step: 0.165)

    end

    def self.page_a201(skp, e)
      next_page('SUBFRAME LAYOUT'); header('SCALE 1:30 · DIMENSIONS IN MM'); sheet_code('A-201')
      ev, pv, cx = elev_plan(skp, '02 Wall + Subframe — Elevation', '02 Wall + Subframe — Plan', 'A-201', 'BACKING FRAMES S01-S15 — FROM RECREATION', 'PLAN — CUT AT 1200')
      fy = -19
      up = P(3808, fy, 9000); dn = P(3808, fy, -9000); lf = P(-9000, fy, 1556); rt = P(19000, fy, 1556)
      fr = e.grep(Sketchup::ComponentInstance).select { |i| i.name =~ /backing S\d\d/ }.map { |i| b = i.bounds; [i.name[/S\d\d/], b.min.x.to_mm, b.max.x.to_mm, b.min.z.to_mm, b.max.z.to_mm] }
      fr.select { |_, _, _, z0, _| z0 > 2000 }.sort_by { |f| f[1] }.each { |_, a, b| dim(ev, P(a, fy, 3112), P(b, fy, 3112), 0.28, up, b - a) }
      dim(ev, P(0, fy, 3112), P(7616, fy, 3112), 0.56, up, 7616)
      fr.select { |_, _, _, z0, _| z0 < 100 }.sort_by { |f| f[1] }.each { |_, a, b| dim(ev, P(a, fy, 0), P(b, fy, 0), 0.28, dn, b - a) }
      [[25, 2380], [2380, 3112]].each { |a, b| dim(ev, P(0, fy, a), P(0, fy, b), 0.28, lf, b - a) }
      dim(ev, P(7616, fy, 25), P(7616, fy, 2380), 0.28, rt, 2355)
      dim(ev, P(7616, fy, 2380), P(7616, fy, 3112), 0.28, rt, 732)
      dim(ev, P(6600, fy, 2505), P(6600, fy, 3112), 0.28, P(6000, fy, 2800), 607)
      fr.each { |id, a, b, z0, z1| bub(ev.model_to_paper_point(P((a + b) / 2, fy, (z0 + z1) / 2)), id, red: false, d: 0.34, size: 6.5) }
      notes(cx - 0.05, 7.42, WX + WW - cx + 0.05, [
        'Backing frames: plywood 3/4" (19 mm), stiles 4" = 98 mm and 6" = 152 mm - schedule and cut list on A-702.',
        'Frame face 19 mm from wall; clip gap 3.3 (Fastmount VL-03H recess); panel 22 -> panel face 44.3 mm (see A-202, Q1).',
        'Lower tier 25..2380, upper tier 2380..3112, over openings 2505..3112. No frame joint falls in a panel joint.',
        'Frame clip holes D25 x 8 deep (female clip), 103 total - drilled by UCON CNC (frames CSV). Panel recesses by the factory (D-01..D-04).'
      ], size: 7, step: 0.165)

    end

    def self.page_a202(skp, e)
      next_page('CLIP LAYOUT & DETAIL'); header('SCALE 1:40 / 2:1 · DIMENSIONS IN MM'); sheet_code('A-202')
      s40 = 1.0 / 40
      ccx = WX + 0.75 + 7616 * MM * s40 / 2; ccy = WY + 0.45 + 3112 * MM * s40 / 2
      cv = viewport(skp, '02 Clips — X-ray', ccx - 4.1, ccy - 1.75, 8.2, 3.5, scale: s40, render: :hybrid); cv.render if cv.render_needed?
      fy = -22.3
      lf = P(-9000, fy, 1556); rt = P(19000, fy, 1556); up = P(3808, fy, 9000)
      zs = [0, 85, 648.5, 1212, 1775.5, 2339, 2499, 3027, 3112]
      zs[1..-2].each do |z|
        q0 = cv.model_to_paper_point(P(0, fy, z)); line(q0.x - 0.30, q0.y, q0.x - 0.05, q0.y, @l_sheet, w: 0.5)
        text(fmt(z), q0.x - 0.34, q0.y - 0.06, @l_sheet, size: 6.5, font: MONO, align: :right)
      end
      q0 = cv.model_to_paper_point(P(7616, fy, 2555.8)); line(q0.x + 0.05, q0.y, q0.x + 0.30, q0.y, @l_sheet, w: 0.5)
      text('2555.8 (over openings)', q0.x + 0.34, q0.y - 0.06, @l_sheet, size: 6.5, font: MONO)
      text('CLIP ROWS Z', WX, cv.model_to_paper_point(P(0, fy, 3112)).y - 0.30, @l_sheet, size: 6, font: MONO, c: INK2)
      dim(cv, P(0, fy, 3112), P(7616, fy, 3112), 0.28, up, 7616)
      bub(cv.model_to_paper_point(P(1290, fy, 3200)), 'Q6')
      vlabel(WX, WY + 0.45 + 3112 * MM * s40 + 0.55, WW, 1, 'A-202', 'CLIP LAYOUT — 103 x FASTMOUNT VL-03H (X-RAY)', 'SCALE 1:40')
      # ---- detail 2:1, horizontal section through one clip: x = depth from wall face, y = along the wall
      k = 2.0 * MM
      dx0 = WX + 0.7; dyc = 7.45 + 13 * 2.0 * MM
      xf = ->(mm) { dx0 + (mm + 16) * k }
      yf = ->(mm) { dyc - mm * k }
      fill_rect = lambda do |x0, x1, y0, y1, fill, sw: 0.5, dash: false|
        rect(xf.(x0), yf.(y1), (x1 - x0) * k, (y1 - y0) * k, @l_sheet, stroke: INK, sw: sw, fill: fill, dash: dash)
      end
      gap = 3.3
      fill_rect.(-16, 0, -13, 13, [214, 214, 214])                 # wall
      fill_rect.(0, 19, -13, 13, [236, 226, 204])                  # frame S
      fill_rect.(19 + gap, 19 + gap + 22, -13, 13, [246, 246, 242]) # panel P
      fill_rect.(11, 19, -12.5, 12.5, [255, 255, 255], dash: true)   # hole frame D25 x 8
      fill_rect.(19 + gap, 19 + gap + 7, -12.5, 12.5, [255, 255, 255], dash: true) # hole panel D25 x 7
      fill_rect.(11.4, 19, -12.25, 12.25, [70, 70, 72], sw: 0.25)      # female clip (schematic)
      fill_rect.(19 + gap, 19 + gap + 7.1, -12, 12, [120, 120, 124], sw: 0.25) # male clip (schematic)
      fill_rect.(19, 19 + gap, -6, 6, [95, 95, 98], sw: 0.25)          # engagement in the gap
      far = pt2(xf.(80), yf.(0)); top = pt2(xf.(20), yf.(80)); bot = pt2(xf.(20), yf.(-80)); dt = 13; db = -13
      pdim(pt2(xf.(0), yf.(dt)), pt2(xf.(19), yf.(dt)), 0.22, top, '19')
      pdim(pt2(xf.(19), yf.(dt)), pt2(xf.(19 + gap), yf.(dt)), 0.42, top, '3.3')
      pdim(pt2(xf.(19 + gap), yf.(dt)), pt2(xf.(19 + gap + 22), yf.(dt)), 0.22, top, '22')
      pdim(pt2(xf.(0), yf.(dt)), pt2(xf.(19 + gap + 22), yf.(dt)), 0.70, top, '44.3')
      pdim(pt2(xf.(11), yf.(-12.5)), pt2(xf.(19), yf.(-12.5)), 0.30, bot, '8')
      pdim(pt2(xf.(19 + gap), yf.(-12.5)), pt2(xf.(19 + gap + 7), yf.(-12.5)), 0.30, bot, '7')
      pdim(pt2(xf.(19 + gap + 22), yf.(-12.5)), pt2(xf.(19 + gap + 22), yf.(12.5)), 0.30, far, 'D25')
      lx = xf.(19 + gap + 22) + 0.75
      [['WALL', -8, 11], ['FRAME S 19', 5, 11], ['PANEL P 22', 37, 11]].each do |t, xm, ym|
        text(t, xf.(xm), yf.(ym) - 0.02, @l_sheet, size: 6, font: MONO, align: :center)
      end
      bub(pt2(xf.(-8), yf.(0)), 'Q6')
      bub(pt2(xf.(19 + gap + 22) + 0.40, yf.(13) - 0.35), 'Q1')
      vlabel(WX, WY + WH - LABEL_H, 6.0, 2, 'A-202', 'CLIP DETAIL — RECESS MOUNT', 'SCALE 2:1')
      tx0 = WX + 6.45; tw = WX + WW - tx0
      label('FASTMOUNT VL-03H - CATALOGUE DATA', tx0, 6.95, @l_sheet)
      line(tx0, 7.12, tx0 + tw, 7.12, @l_sheet, w: 1.0)
      [['Female clip', 'in frame S: D24.5 body, flange D28, height 7.6, screw VL-SS3'], ['Male clip', 'in panel back: D24 body, height 7.1'],
       ['Recess mount', 'holes D25: 8 deep (female) / 7 deep (male), gap 3.3'], ['Pull-out', '10 kg (22 lbs) per clip; 103 clips on this wall'],
       ['Placement', 'on frame stile centre, clip centre >= 40 mm from panel edge'], ['Drilling', 'panel recesses: factory per D-01..D-04; frame holes: UCON CNC'],
       ['Order', '115 sets (103 + 10%) -> 2 boxes x 100 = 200 sets, Sugatsune US, item VL-03H']].each_with_index do |(a, b), i|
        yy = 7.22 + i * 0.27
        text(a, tx0, yy, @l_sheet, size: 7.5, font: MONO, c: INK2)
        text(b, tx0 + 1.25, yy, @l_sheet, size: 7.5)
        line(tx0, yy + 0.22, tx0 + tw, yy + 0.22, @l_sheet, w: 0.5, c: ROWLINE)
      end
      text('Clip shapes on the detail are schematic - dimensions per Fastmount catalogue 2023, p. 6.', tx0, 7.22 + 7 * 0.27 + 0.05, @l_sheet, size: 7, c: INK2)

    end

    def self.page_a501(skp, e)
      fry0 = FRY0; fry1 = FRY1
      next_page('DOOR D01'); header('SCALE 1:20 / 1:10 · DIMENSIONS IN MM'); sheet_code('A-501')
      tgt_e = [3808, 0, 1556]; fy = FY
      qe = pt2(WX + 0.9 + 1.5, WY + 0.4 + 3.16)
      ev = cropped(skp, '03 Doors + Panels — Elevation', tgt_e, [3030, fy, 1556], qe, 2.62, 6.32, 1.0 / 20, ELEV)
      up = P(3006, fy, 9000); dn = P(3006, fy, -9000); lf = P(-9000, fy, 1556); rt = P(19000, fy, 1556)
      dim(ev, P(2564.5, fy, 3102), P(3448.5, fy, 3102), 0.25, up, 884)
      dim(ev, P(2509, 0, 0), P(3504, 0, 0), 0.25, dn, 995)
      dim(ev, P(2564.5, fy, 0), P(3448.5, fy, 0), 0.50, dn, 884)
      [[10, 2414], [2424, 3102]].each { |a, b| dim(ev, P(2370, fy, a), P(2370, fy, b), 0.25, lf, b - a) }
      dim(ev, P(2370, fy, 0), P(2370, fy, 3112), 0.50, lf, 3112)
      dim(ev, P(3700, fy, 0), P(3700, fy, 2505), 0.25, rt, 2505)
      bub(ev.model_to_paper_point(P(2800, fy, 1900)), 'Q2')
      bub(ev.model_to_paper_point(P(3250, fy, 700)), 'Q3')
      vlabel(WX, WY + 0.4 + 6.32 + 0.45, 4.6, 1, 'A-501', 'ELEVATION', '1:20')
      tgt_p = [3006.5, 400, 0]
      qp = pt2(WX + WW - 3.95, WY + 0.25 + 2.2)
      pv = cropped(skp, '05 D01 — Plan Section', tgt_p, [3006.5, 390, 1000], qp, 6.3, 4.4, 1.0 / 10, PLAN)
      zc = 1000
      dim(pv, P(2564.5, fy, zc), P(3448.5, fy, zc), 0.25, P(3006, -9000, zc), 884)
      dim(pv, P(2509, 0, zc), P(3504, 0, zc), 0.80, P(3006, -9000, zc), 995)
      dim(pv, P(2400, 0, zc), P(2400, 170, zc), 0.25, P(-9000, 85, zc), 170)
      dim(pv, P(2400, fy, zc), P(2400, 0, zc), 0.25, P(-9000, 85, zc), 44.3)
      dim(pv, P(3575, fry0, zc), P(3575, fry1, zc), 0.30, P(19000, 85, zc), fry1 - fry0, label: '201.8 JAMB')
      bub(pv.model_to_paper_point(P(2470, 120, zc)), 'Q1')
      vlabel(WX + 5.0, 6.95, WW - 5.0, 2, 'A-501', 'PLAN SECTION AT 1000', '1:10')
      notes(WX + 5.0, 7.55, WW - 5.0, [
        'D01: right-handed, opens into Laundry, concealed hinges, soft-close, handles (Laundry side) by client. Profile per TM Italia DWG 20260903 rev.3.',
        'Built to the UCON opening 995 x 2505 with TM technical gaps head 9, sides 4.3, floor 0: frame 986.3 x 2496 (Q2).',
        'Leaf cladding 884 x 2404 x 12, 10 mm to finished floor; joint 10 to P08 above, 10 to P07 / P09 (rebated) beside.',
        "Cladding face flush with panels at 44.3 mm from wall (frame 19 + clip gap 3.3 + panel 22) -> jamb depth #{fmt(fry1 - fry0)} on wall 170 (Q1).",
        'Q3: hinge make / model to be confirmed by TM.'
      ], red_idx: [4], size: 7, step: 0.17)

    end

    def self.page_a502(skp, e)
      fry0 = FRY0; fry1 = FRY1; fy = FY; zc = 1000; tgt_p = [3006.5, 400, 0]
      next_page('D01 DETAILS'); header('SCALE 1:5 · DIMENSIONS IN MM'); sheet_code('A-502')
      cw = (WW - GUT) / 2; chh = (WH - GUT) / 2
      cells = [[WX, WY], [WX + cw + GUT, WY], [WX, WY + chh + GUT], [WX + cw + GUT, WY + chh + GUT]]
      s5 = 1.0 / 5
      tgt_s = [3006.5, 60, 1556]
      # 1 head (side section)
      x0, y0 = cells[0]; q = pt2(x0 + cw / 2, y0 + 0.2 + 1.35)
      hv = cropped(skp, '06 D01 — Section', tgt_s, [3006.5, 70, 2470], q, cw - 1.2, 2.7, s5, SIDE)
      xs = 3006.5
      dim(hv, P(xs, fy, 2414), P(xs, fy, 2424), 0.30, P(xs, -9000, 2419), 10)
      dim(hv, P(xs, 120, 2496), P(xs, 120, 2505), 0.30, P(xs, 9000, 2500), 9)
      dim(hv, P(xs, fy, 2580), P(xs, -22.3, 2580), 0.20, P(xs, 0, 9000), 22)
      dim(hv, P(xs, -19, 2580), P(xs, 0, 2580), 0.20, P(xs, 0, 9000), 19)
      dim(hv, P(xs, fy, 2580), P(xs, 0, 2580), 0.42, P(xs, 0, 9000), 44.3)
      bub(hv.model_to_paper_point(P(xs, 60, 2440)), 'Q1')
      vlabel(x0, y0 + chh - LABEL_H, cw, 1, 'A-502', 'HEAD — SECTION', '1:5')
      # 2 floor (side section)
      x0, y0 = cells[1]; q = pt2(x0 + cw / 2, y0 + 0.2 + 1.35)
      bv = cropped(skp, '06 D01 — Section', tgt_s, [3006.5, 70, 80], q, cw - 1.2, 2.7, s5, SIDE)
      dim(bv, P(xs, fy, 0), P(xs, fy, 10), 0.30, P(xs, -9000, 5), 10)
      dim(bv, P(xs, fy, 0), P(xs, 0, 0), 0.25, P(xs, 0, -9000), 44.3)
      dim(bv, P(xs, fry0, 0), P(xs, fry1, 0), 0.50, P(xs, 0, -9000), fry1 - fry0, label: '201.8 JAMB')
      bub(bv.model_to_paper_point(P(xs, 60, 120)), 'Q4')
      bub(bv.model_to_paper_point(P(xs, -95, 200)), 'Q5')
      vlabel(x0, y0 + chh - LABEL_H, cw, 2, 'A-502', 'FLOOR — SECTION', '1:5')
      # 3 jamb left, 4 jamb right (plan section)
      [[2, 2560, 'JAMB LEFT — PLAN SECTION', [[2509, 2513.3, 120], [2554.5, 2564.5, fy]]],
       [3, 3455, 'JAMB RIGHT (HINGE SIDE) — PLAN SECTION', [[3499.7, 3504, 120], [3448.5, 3458.5, fy]]]].each do |ci, xc, name, gaps|
        x0, y0 = cells[ci]; q = pt2(x0 + cw / 2, y0 + 0.15 + 1.4)
        jv = cropped(skp, '05 D01 — Plan Section', tgt_p, [xc, 90, 1000], q, cw - 1.0, 2.8, s5, PLAN)
        gaps.each { |a, b, yy| dim(jv, P(a, yy, zc), P(b, yy, zc), 0.30, P((a + b) / 2, -9000, zc), b - a) }
        xe = ci == 2 ? xc - 150 : xc + 150
        dim(jv, P(xe, 0, zc), P(xe, 170, zc), 0.25, P(ci == 2 ? -9000 : 19000, 85, zc), 170)
        dim(jv, P(xe, fy, zc), P(xe, 0, zc), 0.25, P(ci == 2 ? -9000 : 19000, 85, zc), 44.3)
        bub(jv.model_to_paper_point(P(xc, 220, zc)), ci == 3 ? 'Q3' : 'Q1')
        vlabel(x0, y0 + chh - LABEL_H, cw, ci + 1, 'A-502', name, '1:5')
      end

    end

    def self.page_a601(skp, e)
      next_page('3D VIEW'); header('NOT TO SCALE'); sheet_code('A-601')
      v3 = viewport(skp, '04 3D', WX, WY, WW, WH - LABEL_H - 0.2, render: :hybrid); v3.render if v3.render_needed?
      vlabel(WX, WY + WH - LABEL_H, WW, 1, 'A-601', '3D — RECREATION SIDE', 'NTS')
      vlabel(WX, WY + WH - LABEL_H, WW, 1, 'A-601', '3D — RECREATION SIDE', 'NTS')
    end

    def self.page_a301(skp, model)
      cx = WX + WW / 2
      # elevation: wall 7616 x 3112 at 1:30 = 9.995 x 4.084 in; camera target (3808, 0, 1556) = viewport centre
      ecy = 2.35 + 4.084 / 2
      ev = viewport(skp, '03 Doors + Panels — Elevation', cx - 5.5, ecy - 2.15, 11.0, 4.3, scale: 1.0 / 30)
      ev.render if ev.render_needed?
      ps = panel_boxes(model)
      fy = FY
      above = P(3808, fy, 9000); below = P(3808, fy, -9000); left = P(-9000, fy, 1556); right = P(19000, fy, 1556)
      # row 1 above: panel widths (upper row = every column)
      ps.select { |p| p[:z0] > 2000 }.sort_by { |p| p[:x0] }.each do |p|
        dim(ev, P(p[:x0], fy, 3112), P(p[:x1], fy, 3112), 0.28, above, p[:x1] - p[:x0])
      end
      dim(ev, P(0, fy, 3112), P(7616, fy, 3112), 0.56, above, 7616)
      # row 1 below: wall and openings (UCON survey)
      [[0, 2509], [2509, 3504], [3504, 4698], [4698, 6600], [6600, 7616]].each { |a, b| dim(ev, P(a, fy, 0), P(b, fy, 0), 0.28, below, b - a) }
      # left: panel rows, overall
      [[10, 2414], [2424, 3102]].each { |a, b| dim(ev, P(0, fy, a), P(0, fy, b), 0.28, left, b - a) }
      dim(ev, P(0, fy, 0), P(0, fy, 3112), 0.56, left, 3112)
      # right: openings height
      dim(ev, P(7616, fy, 0), P(7616, fy, 2505), 0.28, right, 2505)
      dim(ev, P(7616, fy, 2505), P(7616, fy, 3112), 0.28, right, 607)
      # Q9 bubbles: P14 / P16 edges at the wine-room opening, bottom of P11 / P12
      [[4753 + 120, 1250], [6545 - 120, 1250], [5200, 2424 - 150], [6100, 2424 - 150]].each do |x, z|
        bub(ev.model_to_paper_point(P(x, fy, z)), 'Q9')
      end
      bub(ev.model_to_paper_point(P(3006.5 + 250, fy, 1600)), 'Q1')
      vlabel(WX, 7.02, WW, 1, 'A-301', 'ELEVATION — FROM RECREATION', 'SCALE 1:30')

      # plan below, same scale; scene target (3808, 50, 0) = viewport centre
      pcy = 7.55 + (930 - 50) / 30.0 / 25.4
      pv = viewport(skp, '03 Doors + Panels — Plan', cx - 5.5, pcy - 1.2, 11.0, 2.4, scale: 1.0 / 30)
      pv.render if pv.render_needed?
      vlabel(WX, 9.35, WW, 2, 'A-301', 'PLAN — CUT AT 1200', 'SCALE 1:30')

      # notes, to the right of the door swing, above the plan wall (wall face at y ~8.45 in)
      nx = cx - 0.05; ny = 7.42; nw = WX + WW - nx
      label('NOTES', nx, ny, @l_sheet)
      line(nx, ny + 0.17, nx + nw, ny + 0.17, @l_sheet, w: 1.0)
      notes = ['All joints 10 mm. 10 mm to floor, ceiling and wall corners. No baseboard.',
               'Panel MDF 22 on backing frame 19 + clip gap 3.3: face 44.3 mm from wall. D01 flush with panels.',
               'Numbers per TM Italia order 260318. Panel widths above, wall and openings below (UCON survey).',
               'P06, P07, P08, P09, P13 rebated at the D01 frame, 12 mm face remains - see A-501.',
               'Q9: P14 / P16 edges and bottom of P11 / P12 TBD until the wine-room door is measured - see G-002.']
      yy = ny + 0.24
      notes.each_with_index do |t, i|
        c = i == 4 ? RED : INK
        text("#{i + 1}.", nx, yy, @l_sheet, size: 7, font: MONO, c: c)
        text(t, nx + 0.22, yy, @l_sheet, size: 7, c: c)
        yy += 0.165
      end
    end

    def self.page_g002
      next_page('OPEN QUESTIONS'); header('FOR FACTORY REVIEW'); sheet_code('G-002')
      cols = [['NO.', 0.45], ['SHEET', 1.05], ['TO', 0.45], ['QUESTION', 6.6], ['ANSWER (TM / SITE)', 3.2], ['DATE', 0.7]]
      ws, xs = cols_x(WX, WW, cols)
      y = WY
      cols.each_with_index { |(h, _), i| text(h, xs[i] + 0.04, y + 0.02, @l_sheet, size: 7, font: MONO, c: HEAD) }
      y += 0.22; line(WX, y, WX + WW, y, @l_sheet, w: 1.0)
      QUESTIONS.each do |no, sh, to, q|
        lines = (q.size / 105.0).ceil
        rh = [0.17 * lines + 0.16, 0.42].max
        ink = no == 'Q9' ? RED : INK
        text(no, xs[0] + 0.04, y + 0.07, @l_sheet, size: 8, font: MONO, c: RED)
        box_text(sh, xs[1] + 0.04, y + 0.07, ws[1] - 0.08, rh - 0.1, @l_sheet, size: 7.5, font: MONO, c: INK2)
        text(to, xs[2] + 0.04, y + 0.07, @l_sheet, size: 7.5, font: MONO)
        box_text(q, xs[3] + 0.04, y + 0.07, ws[3] - 0.10, rh - 0.08, @l_sheet, size: 7.5, c: ink)
        y += rh
        line(WX, y, WX + WW, y, @l_sheet, w: 0.5, c: ROWLINE)
      end
      [xs[4], xs[5]].each { |x| line(x, WY + 0.22, x, y, @l_sheet, w: 0.5, c: ROWLINE) }
      box_text('Red number = open question, marked with the same red bubble on the sheet it belongs to. Q7 is internal to UCON. ' \
               'Please answer in the ANSWER column (or by e-mail quoting the number). The drawings are reissued once all TM questions are answered.',
               WX, y + 0.20, WW, 0.5, @l_sheet, size: 8.5, c: INK2)

    end

    def self.page_a701(panels)
      next_page('PANEL SCHEDULE'); header('DIMENSIONS IN MM'); sheet_code('A-701')
      pcols = [['PANEL', 0.7], ['POSITION', 0.9], ['W', 0.8], ['H', 0.8], ['T', 0.5], ['MATERIAL', 1.9], ['BACK REBATE', 1.3], ['CLIP HOLES', 0.9], ['AREA M2', 0.8], ['NOTE', 3.6]]
      tbd = %w[P11 P12 P14 P16]
      rows = panels.map do |p|
        note = tbd.include?(p[:id]) ? 'Q9 - edge / bottom TBD (wine-room door)' : ''
        [p[:id], p[:pos], f1(p[:w]), f1(p[:h]), '22', 'MDF 22, finish per TM', p[:rebate] ? 'YES (12 face)' : '-',
         p[:holes].to_s, format('%.2f', p[:w] * p[:h] / 1e6), note]
      end
      area = panels.sum { |p| p[:w] * p[:h] } / 1e6
      rows << ['D01', 'door leaf', '884', '2404', '12', 'Cladding per TM profile', '-', '-', format('%.2f', 0.884 * 2.404), 'Door cladding - see A-501 / Q1 Q2 Q5']
      rows << ['TOTAL', "#{panels.size} panels", nil, nil, nil, nil, "#{panels.count { |p| p[:rebate] }} rebated", panels.sum { |p| p[:holes] }.to_s, format('%.2f', area), 'Panels only (D01 cladding not included)']
      y = table(WX, WY, WW, pcols, rows, row_h: 0.30, red: ->(r) { tbd.include?(r[0]) })
      box_text('Position: column C1..C9 from the left, L = lower row (10..2414), U = upper row (2424..3102). All joints 10 mm. ' \
               'Back rebate: rear 10 mm removed where the panel passes in front of the D01 frame. Clip recesses D25 x 7 deep in the panel back, made by the factory - see A-202 and D-01..D-04.',
               WX, y + 0.20, WW, 0.5, @l_sheet, size: 8.5, c: INK2)

    end

    def self.page_a702(frames)
      next_page('SUBFRAME SCHEDULE'); header('DIMENSIONS IN MM'); sheet_code('A-702')
      lw = 7.6; rx = WX + lw + 0.35; rw = WX + WW - rx
      label('BACKING FRAMES S01-S15 - PLYWOOD 3/4" (19 MM)', WX, WY - 0.02, @l_sheet)
      fcols = [['FRAME', 0.6], ['TIER', 0.9], ['X', 1.3], ['Z', 1.3], ['W', 0.6], ['H', 0.6], ['STILES L / R', 0.9], ['CLIP HOLES', 0.8]]
      tier = ->(f) { f[:z0] < 100 ? 'lower' : (f[:z0] > 2400 ? 'over opening' : 'upper') }
      frows = frames.map do |f|
        st = STILES[f[:id]] || ['?', '?']
        [f[:id], tier.(f), "#{f1(f[:x0])} - #{f1(f[:x1])}", "#{f1(f[:z0])} - #{f1(f[:z1])}", f1(f[:x1] - f[:x0]), f1(f[:z1] - f[:z0]),
         "#{st[0]} / #{st[1]}", f[:holes].to_s]
      end
      frows << ['TOTAL', "#{frames.size} frames", nil, nil, nil, nil, nil, frames.sum { |f| f[:holes] }.to_s]
      y1 = table(WX, WY + 0.2, lw, fcols, frows, row_h: 0.30)
      box_text('Stile 4" = 98 mm (12 strips per sheet width), 6" = 152 mm. A joint between panels lies on the 6" right stile of the left frame ' \
               '(20 mm past the joint centre). Frame clip holes D25 x 8 deep (female clip) - see A-202. X / Z from wall left end / finished floor.',
               WX, y1 + 0.18, lw, 0.7, @l_sheet, size: 8, c: INK2)
      label('CUT LIST - PARTS', rx, WY - 0.02, @l_sheet)
      crows = CUT.map { |w, l, q| [w, l.to_s, q.to_s] }
      y2 = table(rx, WY + 0.2, rw, [['STRIP', 1.0], ['LENGTH', 1.0], ['QTY', 0.8]], crows, row_h: 0.255, size: 7.5)
      box_text("4\": 61 parts, 52.8 m (23 strips of 96\"). 6\": 17 parts, 15.7 m (7 strips).\nSheets 4 x 8: 2 mixed (4 x 6\" + 6 x 4\") + 1 of 12 x 4\" = 3 sheets. Kerf 3.2 mm.",
               rx, y2 + 0.12, rw, 0.7, @l_sheet, size: 8, c: INK2)
    end

    def self.run(skp, out, logo, model, csv_path)
      @ndim = 0; @l_vp = nil; @l_dm = nil; @l_q = nil; @dsty = nil; @l_key = nil
      @log = []
      e = model.entities
      panels, frames, _cyl = data(model)
      dd = drill_data(model)
      @log << "drill: #{dd.size} panels, #{dd.values.sum { |d| d[:holes].size }} holes, rebates #{dd.select { |_, d| d[:reb].any? }.keys.join(' ')}"
      @log << "spot-check P02 H01 #{dd['P02'][:holes].first.inspect}, P16 H15 #{dd['P16'][:holes].last.inspect} (issued CSV: 51/75 and 957/2329)"
      start([logo], TAGS)
      page_cover(skp)
      page_g001
      page_g002
      page_a101(skp, e)
      page_a201(skp, e)
      page_a202(skp, e)
      next_page('PANEL LAYOUT'); header('SCALE 1:30 · DIMENSIONS IN MM'); sheet_code('A-301')
      page_a301(skp, model)
      page_a501(skp, e)
      page_a502(skp, e)
      page_a601(skp, e)
      page_a701(panels)
      page_a702(frames)
      DRILL.each { |code, rows| page_drill(code, rows, dd) }
      frames_csv(model, csv_path)
      @log << "dimensions: #{@ndim}"
      finish(out)
    end
  end
end

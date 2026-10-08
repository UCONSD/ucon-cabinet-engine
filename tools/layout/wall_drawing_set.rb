# UCON wall-panel drawing set - ANY wall: panels P, backing frames S, clips, concealed door, drilling D-sheets.
# Tabloid 11x17, mm. Built from the SAVED model's scenes plus the wall's JSON (tools/wallpanels/walls/<model>.json):
# every number on the sheets comes from UCON::WallPanels (the generators) or from that JSON, none from this file.
#
# Generalised 2026-10-08 from tools/layout/ap_drawing_set.rb (UCON::APSet, AP Capital REC -> LAU only), which stays
# as it was: it built the issued set v1.1. Same pages, same paper positions, same order of drawing - so REC -> LAU
# rebuilt with this file is the comparison (probe 600). What changed is where the numbers come from:
#   * panels, frames, clips, holes, cut list    -> UCON::WallPanels.build(spec)   (the model is checked against
#     the same generator by probe 599, so drawing from data and drawing from the model are the same thing)
#   * wall, openings, door, tiers, rows          -> the JSON
#   * texts: tags, questions, notes, bubbles     -> the JSON ('sheets'); {jamb} etc. filled in here
# Door pages (A-501, A-502) are drawn for the FIRST door of the wall; a wall with no door has no A-50x pages.
# Runs inside SketchUp (LayOut API). Reads the model, never writes it. Refuses to overwrite.
require 'csv'
load File.join(__dir__, 'ucon_drawing_set.rb')
load File.join(__dir__, '..', 'wallpanels', 'wall_panels.rb')

module UCON
  module WallSet
    include UCON::SheetTemplate
    include UCON::DrawingSet
    extend UCON::SheetTemplate
    extend UCON::DrawingSet

    WP = UCON::WallPanels
    DTXT = 6.5
    MM = 1 / 25.4
    FASTMOUNT = { 'Pull-out kg' => 10, 'box' => 100, 'spare' => 0.10 }.freeze # catalogue 2023 p. 6; Sugatsune US box

    def self.P(x, y, z) = Geom::Point3d.new(x * MM, y * MM, z * MM)
    def self.fmt(v) = ((v - v.round).abs < 0.05 ? v.round.to_s : format('%.1f', v))
    def self.f1(v) = fmt(v)
    def self.pt2(x, y) = Geom::Point2d.new(x, y)

    # ------------------------------------------------------------------ the wall, from the JSON
    def self.sh = @s['sheets']
    def self.wl = @s['wall']['length'].to_f
    def self.wh = @s['wall']['height'].to_f
    def self.wt = @s['wall']['thickness'].to_f
    def self.door = WP.doors(@s).first
    def self.fy = -@s['build_up']['face'].to_f
    def self.id_list(ids) = ids.size > 2 ? "#{ids[0..-2].join(', ')}, #{ids[-1]}" : ids.join(' / ')
    def self.q_bubbles(code) = (sh['bubbles'][code] || [])
    def self.notes_of(code) = (sh['notes'][code] || []).map { |t| t.gsub('{jamb}', fmt(jamb)) }
    def self.red_of(code) = (sh['notes']["#{code}_red"] || [])
    def self.jamb = door ? door['frame']['jamb_y1'] - door['frame']['jamb_y0'] : 0
    def self.rebated = @o[:grid][:panels].reject { |p| p[:rebates].empty? }.map { |p| p[:id] }
    def self.prows = @o[:grid][:rows]
    def self.upper_panels = @o[:grid][:panels].select { |p| p[:row] == 'U' }
    def self.lower_panels = @o[:grid][:panels].select { |p| p[:row] == 'L' }
    def self.oh = @s['openings'].map { |o| o['h'].to_f }.max

    # wall chain along the floor: wall ends and opening edges
    def self.wall_chain
      xs = [0.0, wl] + @s['openings'].flat_map { |o| [o['x0'].to_f, o['x1'].to_f] }
      xs.uniq.sort.each_cons(2).to_a
    end

    def self.index
      list = [['G-000', 'COVER'], ['G-001', 'LEGEND & GENERAL NOTES'], ['G-002', 'OPEN QUESTIONS'],
              ['A-101', 'EXISTING WALL'], ['A-201', 'SUBFRAME LAYOUT'], ['A-202', 'CLIP LAYOUT & DETAIL'],
              ['A-301', 'PANEL LAYOUT']]
      list += [['A-501', "DOOR #{door['id']}"], ['A-502', "#{door['id']} DETAILS"]] if door
      list += [['A-601', '3D VIEW'], ['A-701', 'PANEL SCHEDULE'], ['A-702', 'SUBFRAME SCHEDULE']]
      drill_map.keys.each_with_index { |c, i| list << [c, "PANEL DRILLING #{i + 1}"] }
      list
    end

    # D-sheets: the JSON's split, or packed left to right at 1:15 on the sheet's work width, rows of panels
    def self.drill_map
      return @dmap if @dmap
      if sh['drill']
        @dmap = sh['drill']
      else
        k = MM / 15.0; gap = 0.85; avail = WW - 0.6 - 0.3; hmax = WH - 0.55 - 1.2
        sheets = []; cur = []; row = []; x = 0.0; rows_h = 0.0; rh = 0.0
        flush_row = lambda do
          next if row.empty?
          if rows_h + rh + (cur.empty? ? 0 : 1.45) > hmax && !cur.empty?
            sheets << cur; cur = []; rows_h = 0.0
          end
          rows_h += rh + (cur.empty? ? 0 : 1.45); cur << row; row = []; x = 0.0; rh = 0.0
        end
        @o[:grid][:panels].sort_by { |p| [p[:row] == 'L' ? 0 : 1, p[:x0]] }.each do |p|
          w = p[:w] * k
          flush_row.call if !row.empty? && x + w > avail
          row << p[:id]; x += w + gap; rh = [rh, p[:h] * k].max
        end
        flush_row.call
        sheets << cur unless cur.empty?
        @dmap = sheets.each_with_index.to_h { |rows, i| [format('D-%02d', i + 1), rows] }
      end
      @dmap
    end

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

    # the elevation scale: 1:30 while the wall fits the 11 in viewport, then the next one that does
    def self.escale
      @escale ||= [30, 40, 50, 60, 75, 100].find { |s| wl / s * MM <= 10.4 && wh / s * MM <= 4.3 } || 100
    end

    # elevation + plan at the elevation scale, like A-301
    def self.elev_plan(skp, es, ps, code, et, pt)
      s = escale
      cx = WX + WW / 2
      ecy = 2.35 + wh / s / 25.4 / 2
      ev = viewport(skp, es, cx - 5.5, ecy - 2.15, 11.0, 4.3, scale: 1.0 / s); ev.render if ev.render_needed?
      vlabel(WX, 7.02, WW, 1, code, et, "SCALE 1:#{s}")
      pcy = 7.55 + (930 - 50) / s.to_f / 25.4
      pv = viewport(skp, ps, cx - 5.5, pcy - 1.2, 11.0, 2.4, scale: 1.0 / s); pv.render if pv.render_needed?
      vlabel(WX, 9.35, WW, 2, code, pt, "SCALE 1:#{s}")
      [ev, pv, cx]
    end

    # ------------------------------------------------------------------ data, from the generators
    def self.data
      hs = @o[:holes]
      panels = @o[:grid][:panels].map do |p|
        { id: p[:id], pos: p[:pos], w: p[:w], h: p[:h], x0: p[:x0], rebate: !p[:rebates].empty?, holes: hs.count { |h| h[:panel] == p[:id] } }
      end.sort_by { |p| p[:id] }
      frows = WP.frame_csv_rows(@s, @o[:frames], hs)
      frames = @o[:frames].map do |f|
        { id: f[:id], kind: f[:kind], x0: f[:x0], x1: f[:x1], z0: f[:z0], z1: f[:z1], holes: frows.count { |r| r[0] == f[:id] },
          stiles: f[:stiles].map { |_, _, w| "#{w}\"" } }
      end
      [panels, frames]
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

    # per panel: back-view holes [Hnn, xb, zb] and back-view rebate strips [xb0, xb1, z0, z1]
    def self.drill_data
      @o[:grid][:panels].to_h do |p|
        hs = @o[:holes].select { |h| h[:panel] == p[:id] }.map { |h| [h[:id][-3..], h[:xb], h[:zb]] }.sort
        reb = p[:rebates].map { |rx0, rx1, rz0, rz1| [WP.r1(p[:x1] - rx1), WP.r1(p[:x1] - rx0), WP.r1(rz0 - p[:z0]), WP.r1(rz1 - p[:z0])] }
        [p[:id], { w: p[:x1] - p[:x0], h: p[:z1] - p[:z0], holes: hs, reb: reb }]
      end
    end

    def self.drill_panel(id, d, ox, oy, k)
      px = ->(xb) { ox + xb * k }
      pz = ->(z) { oy - z * k }
      w = d[:w]; h = d[:h]
      t = @s['build_up']['panel_t']; c = @s['clips']
      d[:reb].each { |a, b, z0, z1| rect(px.(a), pz.(z1), (b - a) * k, (z1 - z0) * k, @l_sheet, stroke: MINOR, sw: 0.25, fill: [222, 222, 222]) }
      rect(ox, pz.(h), w * k, h * k, @l_sheet, stroke: INK, sw: 0.75)
      text("#{id} — BACK VIEW", ox + w * k / 2, pz.(h) - 0.40, @l_sheet, size: 9, font: SANS_MED, align: :center)
      text("#{f1(w)} x #{f1(h)} x #{f1(t)} · #{d[:holes].size} recesses D#{f1(c['hole_d'])} x #{f1(c['panel_depth'])} · top up",
           ox + w * k / 2, pz.(h) - 0.20, @l_sheet, size: 6.5, font: MONO, c: INK2, align: :center)
      r = c['hole_d'] / 2.0 * k; cc = 0.09
      d[:holes].each do |hid, xb, z|
        cx = px.(xb); cy = pz.(z)
        e2 = Layout::Ellipse.new(Geom::Bounds2d.new(cx - r, cy - r, 2 * r, 2 * r))
        st = Layout::Style.new; st.stroked = true; st.stroke_width = 0.5; st.stroke_color = color(RED); st.solid_filled = false
        e2.style = st; add(e2, @l_sheet)
        line(cx - cc, cy, cx + cc, cy, @l_sheet, w: 0.25, c: RED); line(cx, cy - cc, cx, cy + cc, @l_sheet, w: 0.25, c: RED)
        text(hid, cx + 0.05, cy - 0.17, @l_sheet, size: 5, font: MONO, c: RED)
      end
      xs = d[:holes].map { |_, xb, _| xb }.uniq.sort
      last = -9
      xs.each_with_index do |xb, _i|
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
      c = @s['clips']
      codes = drill_map.keys
      next_page(index.find { |cc, _| cc == code }[1]); header('SCALE 1:15 · BACK VIEW · DIMENSIONS IN MM'); sheet_code(code)
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
      grey = door ? "Grey strip = rebate at the #{door['id']} frame (#{f1(@s['build_up']['panel_t'] - door['rebate']['depth'])} mm face remains) - no recesses there. " : ''
      box_text("BACK VIEW - the panel is seen from the WALL side. X from the LEFT edge as seen from the back, Z from the BOTTOM edge. " \
               "Recesses D#{f1(c['hole_d'])} x #{f1(c['panel_depth'])} deep for the #{c['make']} male clip (#{c['mount']} mount, gap #{f1(@s['build_up']['clip_gap'])}) - made by the factory (Q6, Q10). " \
               "#{grey}Coordinates also in #{@s['files']['panels_csv']}.",
               WX + 0.45, WY + WH - 0.55, WW - 0.45, 0.5, @l_sheet, size: 8, c: RED)
      bub(pt2(WX + 0.17, WY + WH - 0.42), 'Q10')
      codes
    end

    def self.page_cover(skp)
      next_page('COVER', cover: true)
      cover(placeholder: false)
      v = viewport(skp, sh['scenes']['cover'], 0.965, 2.20, 15.264, 6.65, render: :hybrid); v.render if v.render_needed?
      text(sh['cover_title'], 0.965, 1.98, @l_sheet, size: 11, font: MONO, c: INK2)
    end

    def self.page_g001
      next_page('LEGEND & GENERAL NOTES'); header('NOT TO SCALE'); sheet_code('G-001')
      idx = index
      w = (WW - GUT) / 2; x2 = WX + w + GUT
      label('SHEET INDEX', WX, WY, @l_sheet)
      y = WY + 0.22; line(WX, y, WX + w, y, @l_sheet, w: 1.0)
      idx.each_with_index do |(code, name), i|
        text("#{i + 1} / #{idx.size}", WX, y + 0.07, @l_sheet, size: 8, font: MONO)
        text(code, WX + 0.7, y + 0.07, @l_sheet, size: 8, font: MONO, c: INK2)
        text(name, WX + 1.5, y + 0.07, @l_sheet, size: 8)
        text(sh['tags']['Revision'], WX + w, y + 0.07, @l_sheet, size: 8, font: MONO, c: INK2, align: :right)
        y += 0.27; line(WX, y, WX + w, y, @l_sheet, w: 0.5, c: ROWLINE)
      end
      y += 0.30
      fr = @o[:frames]
      label('LEGEND', WX, y, @l_sheet); y += 0.22; line(WX, y, WX + w, y, @l_sheet, w: 1.0); y += 0.12
      bub(pt2(WX + 0.2, y + 0.15), 'Q1'); text('Open question - see G-002 (red = open / TBD)', WX + 0.6, y + 0.08, @l_sheet, size: 8); y += 0.40
      bub(pt2(WX + 0.2, y + 0.15), fr.first[:id], red: false, d: 0.34, size: 6.5); text('Backing frame number (A-201, A-702)', WX + 0.6, y + 0.08, @l_sheet, size: 8); y += 0.40
      text(@o[:grid][:panels].first[:id], WX + 0.2, y + 0.05, @l_sheet, size: 9, align: :center); text(sh['legend_panel'] || 'Panel number per TM order 260318', WX + 0.6, y + 0.08, @l_sheet, size: 8); y += 0.36
      line(WX + 0.05, y + 0.25, WX + 0.35, y + 0.05, @l_sheet, w: 0.5, dash: true); line(WX + 0.05, y + 0.25, WX + 0.35, y + 0.45, @l_sheet, w: 0.5, dash: true)
      text('Door swing on elevation - apex at the hinge side', WX + 0.6, y + 0.18, @l_sheet, size: 8); y += 0.55
      if door
        rect(WX + 0.08, y + 0.02, 0.25, 0.22, @l_sheet, stroke: MINOR, sw: 0.25, fill: [222, 222, 222]); text("Rebate at #{door['id']} frame (back view, D-sheets)", WX + 0.6, y + 0.06, @l_sheet, size: 8)
      end
      label('GENERAL NOTES', x2, WY, @l_sheet)
      line(x2, WY + 0.22, x2 + w, WY + 0.22, @l_sheet, w: 1.0)
      nl = notes_of('G-001'); red = red_of('G-001')
      ny = WY + 0.34
      nl.each_with_index do |n, i|
        text("#{i + 1}.", x2, ny, @l_sheet, size: 8.5, font: MONO, c: red.include?(i) ? RED : INK)
        lines = (n.size / 80.0).ceil
        box_text(n, x2 + 0.32, ny, w - 0.32, 0.17 * lines + 0.1, @l_sheet, size: 8.5, c: red.include?(i) ? RED : INK)
        ny += 0.17 * lines + 0.16
      end
    end

    # frames CNC list - from the generators, the same rows the model reader of APSet produced
    def self.frames_csv(path)
      return @log << "frames CSV exists, not rewritten: #{path}" if File.exist?(path)
      rows = WP.frame_csv_rows(@s, @o[:frames], @o[:holes])
      WP.write_csv(path, WP::FRAME_CSV_HEAD, rows)
      @log << "frames CSV: #{rows.size} holes -> #{path}"
    end

    def self.page_a101(skp, _e)
      sc = sh['scenes']
      next_page('EXISTING WALL'); header("SCALE 1:#{escale} · DIMENSIONS IN MM"); sheet_code('A-101')
      ev, pv, cx = elev_plan(skp, sc['wall_elev'], sc['wall_plan'], 'A-101', "ELEVATION — FROM #{sh['side_from']}", "PLAN — CUT AT #{sh['plan_cut']}")
      fy0 = 0
      up = P(wl / 2, fy0, 9000); dn = P(wl / 2, fy0, -9000); lf = P(-9000, fy0, wh / 2); rt = P(wl + 11_384, fy0, wh / 2)
      dim(ev, P(0, fy0, wh), P(wl, fy0, wh), 0.28, up, wl)
      wall_chain.each { |a, b| dim(ev, P(a, fy0, 0), P(b, fy0, 0), 0.28, dn, b - a) }
      dim(ev, P(0, fy0, 0), P(0, fy0, wh), 0.28, lf, wh)
      dim(ev, P(wl, fy0, 0), P(wl, fy0, oh), 0.28, rt, oh)
      dim(ev, P(wl, fy0, oh), P(wl, fy0, wh), 0.28, rt, wh - oh)
      @s['openings'].each do |o|
        q = ev.model_to_paper_point(P((o['x0'] + o['x1']) / 2.0, fy0, 1300))
        text(o['kind'] == 'door' ? "#{o['id']} OPENING" : (o['label'] || "#{o['id']} OPENING"), q.x, q.y, @l_sheet, size: 7, font: MONO, align: :center)
      end
      q_bubbles('A-101').each { |l, x, z| bub(ev.model_to_paper_point(P(x, fy0, z)), l) }
      dim(pv, P(wl, 0, sh['plan_cut']), P(wl, wt, sh['plan_cut']), 0.28, P(wl + 11_384, wt / 2, sh['plan_cut']), wt)
      notes(cx - 0.05, 7.42, WX + WW - cx + 0.05, notes_of('A-101'), red_idx: red_of('A-101'), size: 7, step: 0.165)
    end

    def self.page_a201(skp, _e)
      sc = sh['scenes']; sf = @s['subframe']
      next_page('SUBFRAME LAYOUT'); header("SCALE 1:#{escale} · DIMENSIONS IN MM"); sheet_code('A-201')
      fr = @o[:frames]
      title = "BACKING FRAMES #{fr.first[:id]}-#{fr.last[:id]} — FROM #{sh['side_from']}"
      ev, pv, cx = elev_plan(skp, sc['frames_elev'], sc['frames_plan'], 'A-201', title, "PLAN — CUT AT #{sh['plan_cut']}")
      ffy = -19
      up = P(wl / 2, ffy, 9000); dn = P(wl / 2, ffy, -9000); lf = P(-9000, ffy, wh / 2); rt = P(wl + 11_384, ffy, wh / 2)
      tj = sf['tier_joint'].to_f; fg = sf['floor_gap'].to_f
      fr.reject { |f| f[:kind] == 'LOW' }.sort_by { |f| f[:x0] }.each { |f| dim(ev, P(f[:x0], ffy, wh), P(f[:x1], ffy, wh), 0.28, up, f[:x1] - f[:x0]) }
      dim(ev, P(0, ffy, wh), P(wl, ffy, wh), 0.56, up, wl)
      fr.select { |f| f[:kind] == 'LOW' }.sort_by { |f| f[:x0] }.each { |f| dim(ev, P(f[:x0], ffy, 0), P(f[:x1], ffy, 0), 0.28, dn, f[:x1] - f[:x0]) }
      [[fg, tj], [tj, wh]].each { |a, b| dim(ev, P(0, ffy, a), P(0, ffy, b), 0.28, lf, b - a) }
      dim(ev, P(wl, ffy, fg), P(wl, ffy, tj), 0.28, rt, tj - fg)
      dim(ev, P(wl, ffy, tj), P(wl, ffy, wh), 0.28, rt, wh - tj)
      last = @s['openings'].max_by { |o| o['x1'] }
      dim(ev, P(last['x1'], ffy, last['h']), P(last['x1'], ffy, wh), 0.28, P(last['x1'] - 600, ffy, 2800), wh - last['h']) if last
      fr.each { |f| bub(ev.model_to_paper_point(P((f[:x0] + f[:x1]) / 2, ffy, (f[:z0] + f[:z1]) / 2)), f[:id], red: false, d: 0.34, size: 6.5) }
      bu = @s['build_up']; cl = @s['clips']
      notes(cx - 0.05, 7.42, WX + WW - cx + 0.05, [
        "Backing frames: plywood 3/4\" (19 mm), stiles 4\" = #{f1(sf['strip'])} mm and 6\" = #{f1(sf['strip_wide'])} mm - schedule and cut list on A-702.",
        "Frame face 19 mm from wall; clip gap #{f1(bu['clip_gap'])} (#{cl['make']} #{cl['mount']}); panel #{f1(bu['panel_t'])} -> panel face #{f1(bu['face'])} mm (see A-202, Q1).",
        "Lower tier #{f1(fg)}..#{f1(tj)}, upper tier #{f1(tj)}..#{f1(wh)}, over openings #{f1(oh)}..#{f1(wh)}. No frame joint falls in a panel joint.",
        "Frame clip holes D#{f1(cl['hole_d'])} x #{f1(cl['frame_depth'])} deep (female clip), #{@o[:holes].size} total - drilled by UCON CNC (frames CSV). Panel recesses by the factory (#{drill_range})."
      ], size: 7, step: 0.165)
    end

    def self.drill_range
      k = drill_map.keys
      k.size > 1 ? "#{k.first}..#{k.last}" : k.first
    end

    def self.page_a202(skp, _e)
      cl = @s['clips']; bu = @s['build_up']
      next_page('CLIP LAYOUT & DETAIL'); header('SCALE 1:40 / 2:1 · DIMENSIONS IN MM'); sheet_code('A-202')
      s40 = 1.0 / 40
      ccx = WX + 0.75 + wl * MM * s40 / 2; ccy = WY + 0.45 + wh * MM * s40 / 2
      cv = viewport(skp, sh['scenes']['clips'], ccx - 4.1, ccy - 1.75, 8.2, 3.5, scale: s40, render: :hybrid); cv.render if cv.render_needed?
      cfy = -22.3
      up = P(wl / 2, cfy, 9000)
      over = cl['row_over_opening'] && cl['row_over_opening'].to_f
      rows_all = @o[:clips].map { |c| c[:z] }.uniq.sort
      over_rows = rows_all.select { |z| over ? (z - over).abs < 0.05 : @s['openings'].any? { |o| z > o['h'] && z < o['h'] + 152 } && !lower_upper_row?(z) }
      zs = [0.0] + (rows_all - over_rows) + [wh]
      zs[1..-2].each do |z|
        q0 = cv.model_to_paper_point(P(0, cfy, z)); line(q0.x - 0.30, q0.y, q0.x - 0.05, q0.y, @l_sheet, w: 0.5)
        text(fmt(z), q0.x - 0.34, q0.y - 0.06, @l_sheet, size: 6.5, font: MONO, align: :right)
      end
      over_rows.each do |z|
        q0 = cv.model_to_paper_point(P(wl, cfy, z)); line(q0.x + 0.05, q0.y, q0.x + 0.30, q0.y, @l_sheet, w: 0.5)
        text("#{fmt(z)} (over openings)", q0.x + 0.34, q0.y - 0.06, @l_sheet, size: 6.5, font: MONO)
      end
      text('CLIP ROWS Z', WX, cv.model_to_paper_point(P(0, cfy, wh)).y - 0.30, @l_sheet, size: 6, font: MONO, c: INK2)
      dim(cv, P(0, cfy, wh), P(wl, cfy, wh), 0.28, up, wl)
      q_bubbles('A-202').each { |l, x, z| bub(cv.model_to_paper_point(P(x, cfy, z)), l) }
      n = @o[:clips].size
      vlabel(WX, WY + 0.45 + wh * MM * s40 + 0.55, WW, 1, 'A-202', "CLIP LAYOUT — #{n} x #{cl['make'].upcase} (X-RAY)", 'SCALE 1:40')
      # ---- detail 2:1, horizontal section through one clip: x = depth from wall face, y = along the wall
      k = 2.0 * MM
      dx0 = WX + 0.7; dyc = 7.45 + 13 * 2.0 * MM
      xf = ->(mm) { dx0 + (mm + 16) * k }
      yf = ->(mm) { dyc - mm * k }
      fill_rect = lambda do |x0, x1, y0, y1, fill, sw: 0.5, dash: false|
        rect(xf.(x0), yf.(y1), (x1 - x0) * k, (y1 - y0) * k, @l_sheet, stroke: INK, sw: sw, fill: fill, dash: dash)
      end
      gap = bu['clip_gap'].to_f; pt = bu['panel_t'].to_f; ft = 19.0
      pd = cl['panel_depth'].to_f; fd = cl['frame_depth'].to_f; hr = cl['hole_d'] / 2.0
      fill_rect.(-16, 0, -13, 13, [214, 214, 214])                 # wall
      fill_rect.(0, ft, -13, 13, [236, 226, 204])                  # frame S
      fill_rect.(ft + gap, ft + gap + pt, -13, 13, [246, 246, 242]) # panel P
      fill_rect.(ft - fd, ft, -hr, hr, [255, 255, 255], dash: true)   # hole frame
      fill_rect.(ft + gap, ft + gap + pd, -hr, hr, [255, 255, 255], dash: true) # hole panel
      fill_rect.(11.4, ft, -12.25, 12.25, [70, 70, 72], sw: 0.25)      # female clip (schematic)
      fill_rect.(ft + gap, ft + gap + 7.1, -12, 12, [120, 120, 124], sw: 0.25) # male clip (schematic)
      fill_rect.(ft, ft + gap, -6, 6, [95, 95, 98], sw: 0.25)          # engagement in the gap
      far = pt2(xf.(80), yf.(0)); top = pt2(xf.(20), yf.(80)); bot = pt2(xf.(20), yf.(-80)); dt = 13
      pdim(pt2(xf.(0), yf.(dt)), pt2(xf.(ft), yf.(dt)), 0.22, top, fmt(ft))
      pdim(pt2(xf.(ft), yf.(dt)), pt2(xf.(ft + gap), yf.(dt)), 0.42, top, fmt(gap))
      pdim(pt2(xf.(ft + gap), yf.(dt)), pt2(xf.(ft + gap + pt), yf.(dt)), 0.22, top, fmt(pt))
      pdim(pt2(xf.(0), yf.(dt)), pt2(xf.(ft + gap + pt), yf.(dt)), 0.70, top, fmt(bu['face']))
      pdim(pt2(xf.(ft - fd), yf.(-hr)), pt2(xf.(ft), yf.(-hr)), 0.30, bot, fmt(fd))
      pdim(pt2(xf.(ft + gap), yf.(-hr)), pt2(xf.(ft + gap + pd), yf.(-hr)), 0.30, bot, fmt(pd))
      pdim(pt2(xf.(ft + gap + pt), yf.(-hr)), pt2(xf.(ft + gap + pt), yf.(hr)), 0.30, far, "D#{fmt(cl['hole_d'])}")
      [['WALL', -8, 11], ["FRAME S #{fmt(ft)}", 5, 11], ["PANEL P #{fmt(pt)}", 37, 11]].each do |t, xm, ym|
        text(t, xf.(xm), yf.(ym) - 0.02, @l_sheet, size: 6, font: MONO, align: :center)
      end
      bub(pt2(xf.(-8), yf.(0)), 'Q6')
      bub(pt2(xf.(ft + gap + pt) + 0.40, yf.(13) - 0.35), 'Q1')
      vlabel(WX, WY + WH - LABEL_H, 6.0, 2, 'A-202', "CLIP DETAIL — #{cl['mount'].upcase} MOUNT", 'SCALE 2:1')
      tx0 = WX + 6.45; tw = WX + WW - tx0
      label("#{cl['make'].upcase} - CATALOGUE DATA", tx0, 6.95, @l_sheet)
      line(tx0, 7.12, tx0 + tw, 7.12, @l_sheet, w: 1.0)
      order = ((n * (1 + FASTMOUNT['spare'])) / 5.0).ceil * 5 # + 10 %, up to the next 5 (103 -> 115, as ordered 2026-10-07)
      boxes = (order / FASTMOUNT['box'].to_f).ceil
      [['Female clip', 'in frame S: D24.5 body, flange D28, height 7.6, screw VL-SS3'], ['Male clip', 'in panel back: D24 body, height 7.1'],
       ['Recess mount', "holes D#{fmt(cl['hole_d'])}: #{fmt(fd)} deep (female) / #{fmt(pd)} deep (male), gap #{fmt(gap)}"],
       ['Pull-out', "#{FASTMOUNT['Pull-out kg']} kg (22 lbs) per clip; #{n} clips on this wall"],
       ['Placement', "on frame stile centre, clip centre >= #{fmt(cl['edge_min'])} mm from panel edge"],
       ['Drilling', "panel recesses: factory per #{drill_range}; frame holes: UCON CNC"],
       ['Order', "#{order} sets (#{n} + 10%) -> #{boxes} boxes x #{FASTMOUNT['box']} = #{boxes * FASTMOUNT['box']} sets, Sugatsune US, item VL-03H"]].each_with_index do |(a, b), i|
        yy = 7.22 + i * 0.27
        text(a, tx0, yy, @l_sheet, size: 7.5, font: MONO, c: INK2)
        text(b, tx0 + 1.25, yy, @l_sheet, size: 7.5)
        line(tx0, yy + 0.22, tx0 + tw, yy + 0.22, @l_sheet, w: 0.5, c: ROWLINE)
      end
      text('Clip shapes on the detail are schematic - dimensions per Fastmount catalogue 2023, p. 6.', tx0, 7.22 + 7 * 0.27 + 0.05, @l_sheet, size: 7, c: INK2)
    end

    # a clip row that also exists on a panel not over an opening is an ordinary row
    def self.lower_upper_row?(z)
      @o[:grid][:panels].any? { |p| WP.clip_rows(@s, p).include?(z) }
    end

    # door geometry, from the opening and its leaf
    def self.dgeo
      d = door; lx0, lx1 = WP.leaf_x(d); fr = d['frame']; j = @s['panels']['joint']
      top = d['leaf']['floor_gap'] + d['leaf']['h']
      { id: d['id'], x0: d['x0'].to_f, x1: d['x1'].to_f, h: d['h'].to_f, cx: (d['x0'] + d['x1']) / 2.0, w: d['x1'] - d['x0'],
        lx0: lx0, lx1: lx1, lw: d['leaf']['w'], lh: d['leaf']['h'], lt: d['leaf']['t'], lfg: d['leaf']['floor_gap'],
        top: top, j: j, gh: fr['gap_head'], gs: fr['gap_side'], gf: fr['gap_floor'], fy0: fr['jamb_y0'], fy1: fr['jamb_y1'] }
    end

    def self.page_a501(skp, _e)
      g = dgeo; fy0 = fy; sc = sh['scenes']
      fry0 = g[:fy0]; fry1 = g[:fy1]
      next_page("DOOR #{g[:id]}"); header('SCALE 1:20 / 1:10 · DIMENSIONS IN MM'); sheet_code('A-501')
      tgt_e = [wl / 2, 0, wh / 2]
      qe = pt2(WX + 0.9 + 1.5, WY + 0.4 + 3.16)
      ev = cropped(skp, sc['panels_elev'], tgt_e, [g[:cx] + 23.5, fy0, wh / 2], qe, 2.62, 6.32, 1.0 / 20, ELEV)
      up = P(g[:cx] - 0.5, fy0, 9000); dn = P(g[:cx] - 0.5, fy0, -9000); lf = P(-9000, fy0, wh / 2); rt = P(wl + 11_384, fy0, wh / 2)
      ztop = wh - @s['panels']['margin_ceiling']
      dim(ev, P(g[:lx0], fy0, ztop), P(g[:lx1], fy0, ztop), 0.25, up, g[:lw])
      dim(ev, P(g[:x0], 0, 0), P(g[:x1], 0, 0), 0.25, dn, g[:w])
      dim(ev, P(g[:lx0], fy0, 0), P(g[:lx1], fy0, 0), 0.50, dn, g[:lw])
      xl = g[:x0] - 139
      [[g[:lfg], g[:top]], [g[:top] + g[:j], ztop]].each { |a, b| dim(ev, P(xl, fy0, a), P(xl, fy0, b), 0.25, lf, b - a) }
      dim(ev, P(xl, fy0, 0), P(xl, fy0, wh), 0.50, lf, wh)
      dim(ev, P(g[:x1] + 196, fy0, 0), P(g[:x1] + 196, fy0, g[:h]), 0.25, rt, g[:h])
      bub(ev.model_to_paper_point(P(g[:cx] - 206.5, fy0, 1900)), 'Q2')
      bub(ev.model_to_paper_point(P(g[:cx] + 243.5, fy0, 700)), 'Q3')
      vlabel(WX, WY + 0.4 + 6.32 + 0.45, 4.6, 1, 'A-501', 'ELEVATION', '1:20')
      tgt_p = [g[:cx], 400, 0]
      qp = pt2(WX + WW - 3.95, WY + 0.25 + 2.2)
      pv = cropped(skp, sc['door_plan'], tgt_p, [g[:cx], 390, 1000], qp, 6.3, 4.4, 1.0 / 10, PLAN)
      zc = 1000
      dim(pv, P(g[:lx0], fy0, zc), P(g[:lx1], fy0, zc), 0.25, P(g[:cx] - 0.5, -9000, zc), g[:lw])
      dim(pv, P(g[:x0], 0, zc), P(g[:x1], 0, zc), 0.80, P(g[:cx] - 0.5, -9000, zc), g[:w])
      dim(pv, P(g[:x0] - 109, 0, zc), P(g[:x0] - 109, wt, zc), 0.25, P(-9000, wt / 2, zc), wt)
      dim(pv, P(g[:x0] - 109, fy0, zc), P(g[:x0] - 109, 0, zc), 0.25, P(-9000, wt / 2, zc), -fy0)
      dim(pv, P(g[:x1] + 71, fry0, zc), P(g[:x1] + 71, fry1, zc), 0.30, P(wl + 11_384, wt / 2, zc), fry1 - fry0, label: "#{fmt(fry1 - fry0)} JAMB")
      bub(pv.model_to_paper_point(P(g[:x0] - 39, 120, zc)), 'Q1')
      vlabel(WX + 5.0, 6.95, WW - 5.0, 2, 'A-501', 'PLAN SECTION AT 1000', '1:10')
      notes(WX + 5.0, 7.55, WW - 5.0, notes_of('A-501'), red_idx: red_of('A-501'), size: 7, step: 0.17)
    end

    def self.page_a502(skp, _e)
      g = dgeo; fy0 = fy; sc = sh['scenes']
      fry0 = g[:fy0]; fry1 = g[:fy1]; zc = 1000; tgt_p = [g[:cx], 400, 0]
      next_page("#{g[:id]} DETAILS"); header('SCALE 1:5 · DIMENSIONS IN MM'); sheet_code('A-502')
      cw = (WW - GUT) / 2; chh = (WH - GUT) / 2
      cells = [[WX, WY], [WX + cw + GUT, WY], [WX, WY + chh + GUT], [WX + cw + GUT, WY + chh + GUT]]
      s5 = 1.0 / 5
      tgt_s = [g[:cx], 60, wh / 2]
      bp = -(@s['build_up']['face'] - @s['build_up']['panel_t'])
      # 1 head (side section)
      x0, y0 = cells[0]; q = pt2(x0 + cw / 2, y0 + 0.2 + 1.35)
      hv = cropped(skp, sc['door_section'], tgt_s, [g[:cx], 70, g[:top] + 56], q, cw - 1.2, 2.7, s5, SIDE)
      xs = g[:cx]
      dim(hv, P(xs, fy0, g[:top]), P(xs, fy0, g[:top] + g[:j]), 0.30, P(xs, -9000, g[:top] + g[:j] / 2), g[:j])
      dim(hv, P(xs, 120, g[:h] - g[:gh]), P(xs, 120, g[:h]), 0.30, P(xs, 9000, g[:h] - g[:gh] / 2), g[:gh])
      dim(hv, P(xs, fy0, 2580), P(xs, bp, 2580), 0.20, P(xs, 0, 9000), @s['build_up']['panel_t'])
      dim(hv, P(xs, -19, 2580), P(xs, 0, 2580), 0.20, P(xs, 0, 9000), 19)
      dim(hv, P(xs, fy0, 2580), P(xs, 0, 2580), 0.42, P(xs, 0, 9000), -fy0)
      bub(hv.model_to_paper_point(P(xs, 60, g[:top] + 26)), 'Q1')
      vlabel(x0, y0 + chh - LABEL_H, cw, 1, 'A-502', 'HEAD — SECTION', '1:5')
      # 2 floor (side section)
      x0, y0 = cells[1]; q = pt2(x0 + cw / 2, y0 + 0.2 + 1.35)
      bv = cropped(skp, sc['door_section'], tgt_s, [g[:cx], 70, 80], q, cw - 1.2, 2.7, s5, SIDE)
      dim(bv, P(xs, fy0, 0), P(xs, fy0, g[:lfg]), 0.30, P(xs, -9000, g[:lfg] / 2.0), g[:lfg])
      dim(bv, P(xs, fy0, 0), P(xs, 0, 0), 0.25, P(xs, 0, -9000), -fy0)
      dim(bv, P(xs, fry0, 0), P(xs, fry1, 0), 0.50, P(xs, 0, -9000), fry1 - fry0, label: "#{fmt(fry1 - fry0)} JAMB")
      bub(bv.model_to_paper_point(P(xs, 60, 120)), 'Q4')
      bub(bv.model_to_paper_point(P(xs, -95, 200)), 'Q5')
      vlabel(x0, y0 + chh - LABEL_H, cw, 2, 'A-502', 'FLOOR — SECTION', '1:5')
      # 3 jamb left, 4 jamb right (plan section); the hinge side per the JSON (handing 'Right-handed ...' -> right)
      hinge_r = door['handing'].to_s =~ /\Aright/i
      [[2, g[:x0] + 51, "JAMB LEFT#{hinge_r ? '' : ' (HINGE SIDE)'} — PLAN SECTION", [[g[:x0], g[:x0] + g[:gs], 120], [g[:lx0] - g[:j], g[:lx0], fy0]]],
       [3, g[:x1] - 49, "JAMB RIGHT#{hinge_r ? ' (HINGE SIDE)' : ''} — PLAN SECTION", [[g[:x1] - g[:gs], g[:x1], 120], [g[:lx1], g[:lx1] + g[:j], fy0]]]].each do |ci, xc, name, gaps|
        x0, y0 = cells[ci]; q = pt2(x0 + cw / 2, y0 + 0.15 + 1.4)
        jv = cropped(skp, sc['door_plan'], tgt_p, [xc, 90, 1000], q, cw - 1.0, 2.8, s5, PLAN)
        gaps.each { |a, b, yy| dim(jv, P(a, yy, zc), P(b, yy, zc), 0.30, P((a + b) / 2, -9000, zc), b - a) }
        xe = ci == 2 ? xc - 150 : xc + 150
        dim(jv, P(xe, 0, zc), P(xe, wt, zc), 0.25, P(ci == 2 ? -9000 : wl + 11_384, wt / 2, zc), wt)
        dim(jv, P(xe, fy0, zc), P(xe, 0, zc), 0.25, P(ci == 2 ? -9000 : wl + 11_384, wt / 2, zc), -fy0)
        bub(jv.model_to_paper_point(P(xc, 220, zc)), (ci == 3) == !hinge_r.nil? ? 'Q3' : 'Q1')
        vlabel(x0, y0 + chh - LABEL_H, cw, ci + 1, 'A-502', name, '1:5')
      end
    end

    def self.page_a601(skp, _e)
      next_page('3D VIEW'); header('NOT TO SCALE'); sheet_code('A-601')
      v3 = viewport(skp, sh['scenes']['iso'], WX, WY, WW, WH - LABEL_H - 0.2, render: :hybrid); v3.render if v3.render_needed?
      vlabel(WX, WY + WH - LABEL_H, WW, 1, 'A-601', "3D — #{sh['side_from']} SIDE", 'NTS')
      vlabel(WX, WY + WH - LABEL_H, WW, 1, 'A-601', "3D — #{sh['side_from']} SIDE", 'NTS')
    end

    def self.page_a301(skp)
      sc = sh['scenes']; s = escale
      cx = WX + WW / 2
      ecy = 2.35 + wh / s / 25.4 / 2
      ev = viewport(skp, sc['panels_elev'], cx - 5.5, ecy - 2.15, 11.0, 4.3, scale: 1.0 / s)
      ev.render if ev.render_needed?
      fy0 = fy
      above = P(wl / 2, fy0, 9000); below = P(wl / 2, fy0, -9000); left = P(-9000, fy0, wh / 2); right = P(wl + 11_384, fy0, wh / 2)
      top_row = upper_panels.empty? ? lower_panels : upper_panels
      top_row.sort_by { |p| p[:x0] }.each { |p| dim(ev, P(p[:x0], fy0, wh), P(p[:x1], fy0, wh), 0.28, above, p[:x1] - p[:x0]) }
      dim(ev, P(0, fy0, wh), P(wl, fy0, wh), 0.56, above, wl)
      wall_chain.each { |a, b| dim(ev, P(a, fy0, 0), P(b, fy0, 0), 0.28, below, b - a) }
      prows.values.sort.each { |a, b| dim(ev, P(0, fy0, a), P(0, fy0, b), 0.28, left, b - a) }
      dim(ev, P(0, fy0, 0), P(0, fy0, wh), 0.56, left, wh)
      unless @s['openings'].empty?
        dim(ev, P(wl, fy0, 0), P(wl, fy0, oh), 0.28, right, oh)
        dim(ev, P(wl, fy0, oh), P(wl, fy0, wh), 0.28, right, wh - oh)
      end
      q_bubbles('A-301').each { |l, x, z| bub(ev.model_to_paper_point(P(x, fy0, z)), l) }
      vlabel(WX, 7.02, WW, 1, 'A-301', "ELEVATION — FROM #{sh['side_from']}", "SCALE 1:#{s}")
      pcy = 7.55 + (930 - 50) / s.to_f / 25.4
      pv = viewport(skp, sc['panels_plan'], cx - 5.5, pcy - 1.2, 11.0, 2.4, scale: 1.0 / s)
      pv.render if pv.render_needed?
      vlabel(WX, 9.35, WW, 2, 'A-301', "PLAN — CUT AT #{sh['plan_cut']}", "SCALE 1:#{s}")
      nx = cx - 0.05; ny = 7.42; nw = WX + WW - nx
      label('NOTES', nx, ny, @l_sheet)
      line(nx, ny + 0.17, nx + nw, ny + 0.17, @l_sheet, w: 1.0)
      red = red_of('A-301')
      yy = ny + 0.24
      notes_of('A-301').each_with_index do |t, i|
        c = red.include?(i) ? RED : INK
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
      redq = sh['red_questions'] || []
      sh['questions'].each do |no, shc, to, q|
        lines = (q.size / 105.0).ceil
        rh = [0.17 * lines + 0.16, 0.42].max
        ink = redq.include?(no) ? RED : INK
        text(no, xs[0] + 0.04, y + 0.07, @l_sheet, size: 8, font: MONO, c: RED)
        box_text(shc, xs[1] + 0.04, y + 0.07, ws[1] - 0.08, rh - 0.1, @l_sheet, size: 7.5, font: MONO, c: INK2)
        text(to, xs[2] + 0.04, y + 0.07, @l_sheet, size: 7.5, font: MONO)
        box_text(q, xs[3] + 0.04, y + 0.07, ws[3] - 0.10, rh - 0.08, @l_sheet, size: 7.5, c: ink)
        y += rh
        line(WX, y, WX + WW, y, @l_sheet, w: 0.5, c: ROWLINE)
      end
      [xs[4], xs[5]].each { |x| line(x, WY + 0.22, x, y, @l_sheet, w: 0.5, c: ROWLINE) }
      box_text(sh['questions_note'] || ('Red number = open question, marked with the same red bubble on the sheet it belongs to. Q7 is internal to UCON. ' \
               'Please answer in the ANSWER column (or by e-mail quoting the number). The drawings are reissued once all TM questions are answered.'),
               WX, y + 0.20, WW, 0.5, @l_sheet, size: 8.5, c: INK2)
    end

    def self.page_a701(panels)
      next_page('PANEL SCHEDULE'); header('DIMENSIONS IN MM'); sheet_code('A-701')
      pcols = [['PANEL', 0.7], ['POSITION', 0.9], ['W', 0.8], ['H', 0.8], ['T', 0.5], ['MATERIAL', 1.9], ['BACK REBATE', 1.3], ['CLIP HOLES', 0.9], ['AREA M2', 0.8], ['NOTE', 3.6]]
      tbd = sh['tbd_panels'] || []
      t = f1(@s['build_up']['panel_t'])
      face_left = door ? f1(@s['build_up']['panel_t'] - door['rebate']['depth']) : nil
      rows = panels.map do |p|
        note = tbd.include?(p[:id]) ? sh['tbd_note'] : ''
        [p[:id], p[:pos], f1(p[:w]), f1(p[:h]), t, @s['panels']['material'], p[:rebate] ? "YES (#{face_left} face)" : '-',
         p[:holes].to_s, format('%.2f', p[:w] * p[:h] / 1e6), note]
      end
      area = panels.sum { |p| p[:w] * p[:h] } / 1e6
      if door
        g = dgeo
        rows << [g[:id], 'door leaf', fmt(g[:lw]), fmt(g[:lh]), fmt(g[:lt]), 'Cladding per TM profile', '-', '-', format('%.2f', g[:lw] / 1000.0 * g[:lh] / 1000.0),
                 "Door cladding - see A-501 / Q1 Q2 Q5"]
      end
      rows << ['TOTAL', "#{panels.size} panels", nil, nil, nil, nil, "#{panels.count { |p| p[:rebate] }} rebated", panels.sum { |p| p[:holes] }.to_s, format('%.2f', area),
               door ? "Panels only (#{door['id']} cladding not included)" : 'Panels only']
      y = table(WX, WY, WW, pcols, rows, row_h: 0.30, red: ->(r) { tbd.include?(r[0]) })
      cols = @o[:grid][:cols].size
      rl = prows['L']; ru = prows['U']
      pos = "Position: column C1..C#{cols} from the left, L = lower row (#{f1(rl[0])}..#{f1(rl[1])})" + (ru ? ", U = upper row (#{f1(ru[0])}..#{f1(ru[1])})" : '') +
            ". All joints #{f1(@s['panels']['joint'])} mm. "
      reb = door ? "Back rebate: rear #{f1(door['rebate']['depth'])} mm removed where the panel passes in front of the #{door['id']} frame. " : ''
      box_text(pos + reb + "Clip recesses D#{f1(@s['clips']['hole_d'])} x #{f1(@s['clips']['panel_depth'])} deep in the panel back, made by the factory - see A-202 and #{drill_range}.",
               WX, y + 0.20, WW, 0.5, @l_sheet, size: 8.5, c: INK2)
    end

    def self.page_a702(frames)
      next_page('SUBFRAME SCHEDULE'); header('DIMENSIONS IN MM'); sheet_code('A-702')
      sf = @s['subframe']
      lw = 7.6; rx = WX + lw + 0.35; rw = WX + WW - rx
      label("BACKING FRAMES #{frames.first[:id]}-#{frames.last[:id]} - PLYWOOD 3/4\" (19 MM)", WX, WY - 0.02, @l_sheet)
      fcols = [['FRAME', 0.6], ['TIER', 0.9], ['X', 1.3], ['Z', 1.3], ['W', 0.6], ['H', 0.6], ['STILES L / R', 0.9], ['CLIP HOLES', 0.8]]
      tier = ->(f) { f[:kind] == 'LOW' ? 'lower' : (f[:kind] == 'UP' ? 'upper' : 'over opening') }
      frows = frames.map do |f|
        [f[:id], tier.(f), "#{f1(f[:x0])} - #{f1(f[:x1])}", "#{f1(f[:z0])} - #{f1(f[:z1])}", f1(f[:x1] - f[:x0]), f1(f[:z1] - f[:z0]),
         "#{f[:stiles][0]} / #{f[:stiles][1]}", f[:holes].to_s]
      end
      frows << ['TOTAL', "#{frames.size} frames", nil, nil, nil, nil, nil, frames.sum { |f| f[:holes] }.to_s]
      y1 = table(WX, WY + 0.2, lw, fcols, frows, row_h: 0.30)
      box_text("Stile 4\" = #{f1(sf['strip'])} mm (12 strips per sheet width), 6\" = #{f1(sf['strip_wide'])} mm. A joint between panels lies on the 6\" right stile of the left frame " \
               "(#{f1(sf['seam_overrun'])} mm past the joint centre). Frame clip holes D#{f1(@s['clips']['hole_d'])} x #{f1(@s['clips']['frame_depth'])} deep (female clip) - see A-202. X / Z from wall left end / finished floor.",
               WX, y1 + 0.18, lw, 0.7, @l_sheet, size: 8, c: INK2)
      label('CUT LIST - PARTS', rx, WY - 0.02, @l_sheet)
      crows = WP.cut_list_print(@o[:cut]).map { |w, l, q| [w, l.to_s, q.to_s] }
      y2 = table(rx, WY + 0.2, rw, [['STRIP', 1.0], ['LENGTH', 1.0], ['QTY', 0.8]], crows, row_h: 0.255, size: 7.5)
      st = @o[:strips]; shs = @o[:sheets]
      parts = shs.group_by { |a| a }.map do |(a, b), l|
        comp = [a.positive? ? "#{a} x 6\"" : nil, b.positive? ? "#{b} x 4\"" : nil].compact.join(' + ')
        "#{l.size} of #{comp}"
      end
      box_text("4\": #{st['4'][:pieces]} parts, #{st['4'][:metres]} m (#{st['4'][:strips]} strips of 96\"). 6\": #{st['6'][:pieces]} parts, #{st['6'][:metres]} m (#{st['6'][:strips]} strips).\n" \
               "Sheets 4 x 8: #{parts.join(', ')} = #{shs.size} sheets. Kerf #{f1(sf['sheet']['kerf'])} mm.",
               rx, y2 + 0.12, rw, 0.7, @l_sheet, size: 8, c: INK2)
    end

    # spec_path: the wall JSON; skp: the saved model; out: new .layout (refused if it exists); csv_path: frames CSV
    def self.run(spec_path, skp, out, logo, model, csv_path)
      raise "exists, not overwriting: #{out}" if File.exist?(out)
      @ndim = 0; @l_vp = nil; @l_dm = nil; @l_q = nil; @dsty = nil; @l_key = nil; @dmap = nil; @escale = nil
      @s = WP.load(spec_path)
      @o = WP.build(@s)
      @log = []
      raise "wall checks failed: #{@o[:checks].join(' | ')}" unless @o[:checks].empty?
      raise "more than one door on the wall is not drawn yet (#{WP.doors(@s).map { |d| d['id'] }.join(', ')})" if WP.doors(@s).size > 1
      e = model.entities
      panels, frames = data
      dd = drill_data
      start([logo], sh['tags']) # resets @log
      @log << "wall #{@s['id']}: #{panels.size} panels, #{frames.size} frames, #{@o[:clips].size} clips, D-sheets #{drill_map.keys.join(' ')}, scale 1:#{escale}"
      @log << "drill: #{dd.size} panels, #{dd.values.sum { |d| d[:holes].size }} holes, rebates #{dd.select { |_, d| d[:reb].any? }.keys.join(' ')}"
      page_cover(skp)
      page_g001
      page_g002
      page_a101(skp, e)
      page_a201(skp, e)
      page_a202(skp, e)
      next_page('PANEL LAYOUT'); header("SCALE 1:#{escale} · DIMENSIONS IN MM"); sheet_code('A-301')
      page_a301(skp)
      if door
        page_a501(skp, e)
        page_a502(skp, e)
      end
      page_a601(skp, e)
      page_a701(panels)
      page_a702(frames)
      drill_map.each { |code, rows| page_drill(code, rows, dd) }
      frames_csv(csv_path)
      @log << "dimensions: #{@ndim}"
      finish(out)
    end
  end
end

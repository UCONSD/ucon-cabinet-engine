# UCON::RoomSet - THE wall-panel drawing set writer (standard 2026-10-17, claude/spec-2026-10-17-drawing-standard.md).
# Tabloid 11x17, mm. One writer for every room: the room is data (a snapshot JSON made by
# tools/wallpanels/room_snapshot.rb, or the Main Kitchen snapshot read from its model), the look is
# tools/layout/drawing_style.json (palette, sheet titles, key plan). Sheet texts come from the snapshot's 'sheets'
# (questions, notes, page_notes, details) with {{expr}} tokens resolved against the data - no number typed by hand.
# Built from UCON::FoyerSet (foyer_drawing_set.rb, ML Foyer v1.0) + the kitchen parts of UCON::MKSet as options.
# Never writes the model. Refuses to overwrite.
require 'json'
require 'csv'
load File.join(__dir__, 'ucon_drawing_set.rb')

module UCON
  module RoomSet
    include UCON::SheetTemplate
    include UCON::DrawingSet
    extend UCON::SheetTemplate
    extend UCON::DrawingSet

    MM = 1 / 25.4
    DTXT = 6.5
    STYLE = JSON.parse(File.read(File.join(__dir__, 'drawing_style.json'))).freeze
    STC = STYLE['colors']
    PAN_FILL = STC['panel'].freeze
    WOOD = STC['frame'].freeze
    WOOD6 = STC['frame_wide'].freeze
    STONE = STC['stone'].freeze
    GLASS = STC['window'].freeze
    DOORF = STC['door'].freeze
    NICHEF = STC['niche'].freeze
    CLADF = STC['cladding'].freeze
    LINERF = STC['liner'].freeze
    FASTMOUNT = { 'Pull-out kg' => 10, 'box' => 100, 'spare' => 0.10 }.freeze # catalogue 2023 p. 6; Sugatsune US box
    SHEET = { 'w' => 1219.2, 'l' => 2438.4, 'kerf' => 3.0 }.freeze               # plywood 4 x 8

    def self.fmt(v) = ((v - v.round).abs < 0.05 ? v.round.to_s : format('%.1f', v))
    def self.f1(v) = fmt(v)
    def self.f2(v) = format('%.2f', v).sub(/\.?0+\z/, '')   # levels: 57.15, 82.15, 67.15 must not round
    def self.pt2(x, y) = Geom::Point2d.new(x, y)
    def self.P(x, y, z) = Geom::Point3d.new(x * MM, y * MM, z * MM)
    def self.wall(id) = @s['walls'].find { |w| w['id'] == id }
    def self.panels_of(id) = @s['panels'].select { |p| p['wall'] == id }
    def self.top_of(w) = w['ceil'].map { |a| a[2] }.max
    def self.lev = @s['levels']
    def self.sh = @s['sheets']
    def self.bu = @s['build_up']
    def self.cl = @s['clips']
    def self.all_frames = @s['frames'].flat_map { |wid, v| v['frames'].map { |f| f.merge('wall' => wid) } }
    def self.all_clips = @s['frames'].flat_map { |wid, v| v['clips'].map { |c| c.merge('wall' => wid) } }
    # room-specific note lines of a page kind ('A-1', 'A-2:B', 'A-3:A', 'A-5:OB2', 'A-701', 'A-100') from the snapshot
    def self.pnotes(key) = ((sh['page_notes'] || {})[key] || []).map { |n| n.is_a?(Array) ? n : [n, false] }
    def self.title(key, **v) = v.reduce(STYLE['titles'][key]) { |s, (k, x)| s.gsub("{#{k}}", x.to_s) }
    # the horizontal joint of a wall: per wall (snapshot by RoomSnapshot) or one for the room (Main Kitchen)
    def self.seam_of(wid) = lev['seam'].is_a?(Hash) ? lev['seam'][wid] : lev['seam']
    # question numbers the writer itself places (door, opening heads, stone, panel size, drilling) - per room, from
    # sheets.qref; the defaults are the ML Foyer numbers
    QREF = { 'drill' => 'Q5', 'door' => 'Q4', 'heads' => 'Q6', 'stone' => 'Q8', 'panel_size' => 'Q1', 'mitre' => 'Q11' }.freeze
    # a room's qref may set a key to null: no bubble for it (REC-LAU has no stone / panel-size / mitre question)
    def self.qref(k) = (sh['qref'] || {}).key?(k) ? sh['qref'][k] : QREF[k]
    # what Z is measured from (header and A-702 note): top of the subfloor unless the room says otherwise
    def self.zfrom = sh['z_from'] || (@s['levels']['ffl'].to_f.zero? ? 'FINISHED FLOOR' : 'TOP OF THE SUBFLOOR')
    def self.qtext(no) = (sh['questions'].find { |q| q[0] == no } || [])[3]

    # wall-local (s along the wall, d into the room, z) -> model mm
    def self.wpt(w, s, d, z)
      (ox, oy), (tx, ty), (nx, ny) = w['wf']
      P(ox + s * tx + d * nx, oy + s * ty + d * ny, z)
    end

    # ------------------------------------------------------------------ paper helpers (as WallSet)
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

    # paper dimension a->b, offset `off` toward paper point t; with vp: also connected to the model points a3 / b3
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

    # dimension on a viewport between model points (mm numbers already in a3 / b3), text = the number given
    def self.vdim(vp, a3, b3, off, t3, val, label: nil)
      a = vp.model_to_paper_point(a3); b = vp.model_to_paper_point(b3); t = vp.model_to_paper_point(t3)
      pdim(a, b, off, t, label || f1(val), vp: vp, a3: a3, b3: b3)
    end

    def self.bub(q, label, red: true, d: 0.30, size: 7)
      return if label.nil?
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

    # notes; a note may be [text, true] = red (open question / TBD)
    def self.notes(x, y, w, list, size: 7, step: 0.165)
      label('NOTES', x, y, @l_sheet)
      line(x, y + 0.17, x + w, y + 0.17, @l_sheet, w: 1.0)
      yy = y + 0.25
      list.each_with_index do |t, i|
        t, red = t.is_a?(Array) ? t : [t, false]
        c = red ? RED : INK
        text("#{i + 1}.", x, yy, @l_sheet, size: size, font: MONO, c: c)
        lines = (t.size * size * 0.0075 / (w - 0.25)).ceil.clamp(1, 5)
        box_text(t, x + 0.22, yy, w - 0.22, step * lines + 0.04, @l_sheet, size: size, c: c)
        yy += step * lines + 0.02
      end
      yy
    end

    def self.poly(pts, layer, stroke: INK, sw: 0.5, fill: nil, dash: false)
      p = Layout::Path.new(pt2(*pts[0]), pt2(*pts[1]))
      pts[2..].each { |x, y| p.append_point(pt2(x, y)) }
      p.close
      s = Layout::Style.new
      s.stroked = true; s.stroke_width = sw; s.stroke_color = color(stroke)
      if fill then s.solid_filled = true; s.fill_color = color(fill) else s.solid_filled = false end
      s.stroke_pattern = Layout::Style::STROKE_PATTERN_DASH if dash
      p.style = s
      add(p, layer)
    end

    def self.cols_x(x0, total_w, cols)
      k = total_w / cols.sum { |_, w| w }
      ws = cols.map { |_, w| w * k }
      [ws, ws.each_with_index.map { |_, i| x0 + ws[0, i].sum }]
    end

    def self.table(x0, y, total_w, cols, rows, row_h: 0.27, red: nil, size: 7)
      ws, xs = cols_x(x0, total_w, cols)
      cols.each_with_index { |(h, _), i| text(h, xs[i] + 0.04, y + 0.02, @l_sheet, size: 6.5, font: MONO, c: HEAD) }
      y += 0.22
      line(x0, y, x0 + total_w, y, @l_sheet, w: 1.0)
      rows.each do |r|
        ink = red && red.(r) ? RED : INK
        bold_row = r.first.to_s == 'TOTAL'
        r.each_with_index do |cell, i|
          next if cell.nil? || cell.to_s.empty?
          text(cell.to_s, xs[i] + 0.04, y + 0.06, @l_sheet, size: size, font: i.zero? ? MONO : SANS, c: ink, bold: bold_row)
        end
        y += row_h
        line(x0, y, x0 + total_w, y, @l_sheet, w: 0.5, c: ROWLINE)
      end
      y
    end

    # viewport whose model point `c3mm` lands on paper point q, cropped (clip mask) to cw x ch paper inches around q.
    # target = the scene camera target (mm); proj maps a model mm vector to the paper (right, down) mm vector.
    def self.cropped(skp, scene, target, c3mm, q, cw, ch, scale, proj)
      dx, dy = proj.(c3mm.zip(target).map { |a, b| a - b })
      tx = q.x - dx * scale * MM; ty = q.y - dy * scale * MM
      hw = (tx - q.x).abs + cw / 2 + 0.3; hh = (ty - q.y).abs + ch / 2 + 0.3
      vp = viewport(skp, scene, tx - hw, ty - hh, 2 * hw, 2 * hh, scale: scale)
      begin
        vp.clip_mask = Layout::Rectangle.new(Geom::Bounds2d.new(q.x - cw / 2, q.y - ch / 2, cw, ch))
      rescue StandardError => e
        @log << "#{scene}: clip mask FAILED #{e.class}: #{e.message}"
      end
      vp.render if vp.render_needed?
      vp
    end
    SIDE = ->(d) { [d[1], -d[2]] }   # looking -x: y right, z up
    PLAN = ->(d) { [d[0], -d[1]] }   # from above, up = +y

    # ------------------------------------------------------------------ the elevation frame of a wall on paper
    # scale: the largest of 1:20 / 25 / 30 / 40 / 50 / 60 / 75 that fits 10.6 x 5.0 in (room for the dimension chains)
    def self.escale(w)
      [20, 25, 30, 40, 50, 60, 75].find { |s| (w['L'] + 200) / s * MM <= 10.6 && top_of(w) / s * MM <= 5.0 } || 75
    end

    def self.frame_of(w, y_floor, s: nil, ox: nil)
      s ||= escale(w); k = MM / s
      ox ||= WX + WW / 2 - w['L'] * k / 2
      [->(v) { ox + v * k }, ->(z) { y_floor - z * k }, k, s]
    end

    def self.draw_wall(w, px, pz, k)
      lv = lev
      pts = [[px.(0), pz.(0)]]
      w['ceil'].each { |a, b, h| pts << [px.(a), pz.(h)] << [px.(b), pz.(h)] }
      pts << [px.(w['L']), pz.(0)]
      poly(pts, @l_sheet, stroke: MINOR, sw: 0.5)
      line(px.(-120), pz.(0), px.(w['L'] + 120), pz.(0), @l_sheet, w: 0.75, c: INK)
      line(px.(-120), pz.(lv['ffl']), px.(w['L'] + 120), pz.(lv['ffl']), @l_sheet, w: 0.5, c: INK, dash: true)
      if lv['ffl'].to_f.zero?   # REC-LAU: the survey is from the finished floor - no subfloor line
        text('±0 FFL', px.(-130), pz.(0) - 0.02, @l_sheet, size: 6, font: MONO, c: INK2, align: :right)
      else
        text("FFL +#{f2(lv['ffl'])}", px.(-130), pz.(lv['ffl']) - 0.07, @l_sheet, size: 6, font: MONO, c: RED, align: :right)
        text('±0 SUBFLOOR', px.(-130), pz.(0) - 0.02, @l_sheet, size: 6, font: MONO, c: INK2, align: :right)
      end
    end

    def self.draw_openings(w, px, pz, k, label: true)
      w['openings'].each do |o|
        z0 = o['kind'] == 'window' ? o['z0'] : lev['ffl']
        fill = { 'window' => GLASS, 'door' => DOORF, 'niche' => NICHEF, 'closet' => NICHEF, 'opening' => [255, 255, 255] }[o['kind']]
        rect(px.(o['s0']), pz.(o['z1']), (o['s1'] - o['s0']) * k, (o['z1'] - z0) * k, @l_sheet, stroke: MINOR, sw: 0.5, fill: fill)
        if o['clad']
          a, b, c0, c1 = o['clad']
          rect(px.(a), pz.(c1), (b - a) * k, (c1 - c0) * k, @l_sheet, stroke: INK, sw: 0.5, fill: CLADF)
        end
        next unless label
        cz = o['kind'] == 'window' ? (o['z0'] + o['z1']) / 2 : 1500
        txt = o['short'] || (sh['opening_labels'] || {})[o['kind']] || { 'window' => "#{o['id']} OPENING", 'door' => "#{o['id']} (TM door)", 'niche' => 'NICHE', 'closet' => 'CLOSET', 'opening' => 'OPENING' }[o['kind']]
        text(txt, px.((o['s0'] + o['s1']) / 2), pz.(cz), @l_sheet, size: 6.5, font: MONO, c: INK2, align: :center)
      end
    end

    def self.draw_stone(w, px, pz, k)
      (@s['stone'][w['id']] || []).each do |a, b|
        rect(px.(a), pz.(lev['stone_top']), (b - a) * k, (lev['stone_top'] - lev['ffl']) * k, @l_sheet, stroke: MINOR, sw: 0.4, fill: STONE)
      end
    end

    # FOYER L-liner (UCON proposal, Q2): the leg against the reveal shows as a 6 strip on each jamb that is not a wall end
    # and on the head; the flange behind the panel is dashed.
    def self.draw_liners(w, px, pz, k)
      w['openings'].each do |o|
        ln = o['liner'] or next
        # leg = [from, to] into the opening from the jamb line (ML Foyer [0, 6] against the reveal; Main Kitchen windows
        # [23, 29] on the 3rd step of the window trim); flange = from the jamb line out to the backing frame
        t = ln['t'].to_f; fl = ln['flange'].to_f; la, lb = (ln['leg'] || [0, t]).map(&:to_f)
        sill = o['kind'] == 'window' && o['z0'].to_f > 0.5
        z0 = sill ? o['z0'] + la : lev['ffl']; h = o['z1'] - la; zf0 = sill ? o['z0'] - fl : lev['ffl']
        sides = []
        sides << [o['s0'] + la, o['s0'] + lb, o['s0'] - fl, o['s0'] + la] if o['s0'] > 0.5
        sides << [o['s1'] - lb, o['s1'] - la, o['s1'] - la, o['s1'] + fl] if o['s1'] < w['L'] - 0.5
        sides.each do |a, b, fa, fb|
          rect(px.(a), pz.(h), (b - a) * k, (h - z0) * k, @l_sheet, stroke: INK, sw: 0.4, fill: LINERF)
          poly([[px.(fa), pz.(zf0)], [px.(fa), pz.(o['z1'] + fl)], [px.(fb), pz.(o['z1'] + fl)], [px.(fb), pz.(zf0)]], @l_sheet, stroke: INK2, sw: 0.25, dash: true)
        end
        a = o['s0'] > 0.5 ? o['s0'] - fl : o['s0']; b = o['s1'] < w['L'] - 0.5 ? o['s1'] + fl : o['s1']
        rect(px.(o['s0'] + la), pz.(h), (o['s1'] - o['s0'] - 2 * la) * k, (lb - la) * k, @l_sheet, stroke: INK, sw: 0.4, fill: LINERF)
        line(px.(a), pz.(o['z1'] + fl), px.(b), pz.(o['z1'] + fl), @l_sheet, w: 0.25, c: INK2, dash: true)
        next unless sill
        rect(px.(o['s0'] + la), pz.(o['z0'] + lb), (o['s1'] - o['s0'] - 2 * la) * k, (lb - la) * k, @l_sheet, stroke: INK, sw: 0.4, fill: LINERF)
        line(px.(a), pz.(o['z0'] - fl), px.(b), pz.(o['z0'] - fl), @l_sheet, w: 0.25, c: INK2, dash: true)
      end
      return unless @s['liner']
      w['openings'].each do |o|
        next unless %w[window niche].include?(o['kind'])
        lg = @s['liner'][o['kind']]['leg']
        a = lg[0]; b = lg[1]
        bottom = o['kind'] == 'window'
        z0i = bottom ? o['z0'] - b : lev['ffl']; z0o = bottom ? o['z0'] - a : lev['ffl']
        outer = [[o['s0'] - b, z0i], [o['s1'] + b, z0i], [o['s1'] + b, o['z1'] + b], [o['s0'] - b, o['z1'] + b]]
        inner = [[o['s0'] - a, z0o], [o['s1'] + a, z0o], [o['s1'] + a, o['z1'] + a], [o['s0'] - a, o['z1'] + a]]
        poly(outer.map { |s, z| [px.(s), pz.(z)] }, @l_sheet, stroke: INK, sw: 0.4)
        poly(inner.map { |s, z| [px.(s), pz.(z)] }, @l_sheet, stroke: INK, sw: 0.25)
      end
    end

    # cabinet in a closet / niche (by the factory): dashed outline + its height above FFL and width, red
    def self.draw_cabinets(w, px, pz, k)
      w['openings'].each do |o|
        c = o['cab'] or next
        poly([[px.(c['x0']), pz.(lev['ffl'])], [px.(c['x0']), pz.(c['top'])], [px.(c['x1']), pz.(c['top'])], [px.(c['x1']), pz.(lev['ffl'])]],
             @l_sheet, stroke: RED, sw: 0.4, dash: true)
        x = px.((c['x0'] + c['x1']) / 2)
        zt = 1500
        text(sh['cabinet_label'] || 'CABINET', x, pz.(zt), @l_sheet, size: 6, font: MONO, c: RED, align: :center)
        text("H #{f2(c['top'] - lev['ffl'])}", x, pz.(zt) + 0.11, @l_sheet, size: 6, font: MONO, c: RED, align: :center)
        text("FFL", x, pz.(zt) + 0.22, @l_sheet, size: 6, font: MONO, c: RED, align: :center)
        text("W #{f1(c['x1'] - c['x0'])}", x, pz.(zt) + 0.33, @l_sheet, size: 6, font: MONO, c: RED, align: :center)
      end
    end

    def self.draw_panels(w, px, pz, k, ids: true, fill: PAN_FILL, sw: 0.75)
      panels_of(w['id']).each do |p|
        rect(px.(p['s0']), pz.(p['z1']), (p['s1'] - p['s0']) * k, (p['z1'] - p['z0']) * k, @l_sheet, stroke: INK, sw: sw, fill: fill)
        next unless ids
        cx = px.((p['s0'] + p['s1']) / 2); cz = pz.((p['z0'] + p['z1']) / 2)
        big = (p['z1'] - p['z0']) * k > 0.45 && (p['s1'] - p['s0']) * k > 0.55
        text(p['id'], cx, cz - (big ? 0.12 : 0.06), @l_sheet, size: big ? 8 : 6.5, font: MONO, c: RED, align: :center)
        text("#{f1(p['s1'] - p['s0'])} x #{f1(p['z1'] - p['z0'])}", cx, cz + 0.02, @l_sheet, size: 5.5, font: MONO, c: INK2, align: :center) if big
      end
    end

    def self.members(f)
      out = []
      f['stiles'].each_with_index { |(a, b), i| out << { name: "#{f['id']} stile #{'LR'[i]}", s0: a, s1: b, z0: f['z0'], z1: f['z1'], w: (b - a).round } }
      ia = f['stiles'].empty? ? f['x0'] : f['stiles'][0][1]; ib = f['stiles'].size < 2 ? f['x1'] : f['stiles'][1][0]
      f['rails'].each_with_index { |(c, d), i| out << { name: "#{f['id']} rail #{i + 1}", s0: ia, s1: ib, z0: c, z1: d, w: (d - c).round } }
      out
    end

    def self.draw_frames(w, px, pz, k)
      fr = @s['frames'][w['id']]['frames']
      fr.each do |f|
        members(f).each do |m|
          rect(px.(m[:s0]), pz.(m[:z1]), (m[:s1] - m[:s0]) * k, (m[:z1] - m[:z0]) * k, @l_sheet, stroke: STC['frame_line'], sw: 0.3,
               fill: m[:w] == 152 ? WOOD6 : WOOD)
        end
      end
      fr
    end

    def self.draw_clips(w, px, pz, k)
      @s['frames'][w['id']]['clips'].each do |c|
        d = 28 * k
        e = Layout::Ellipse.new(Geom::Bounds2d.new(px.(c['x']) - d / 2, pz.(c['z']) - d / 2, d, d))
        st = Layout::Style.new; st.stroked = true; st.stroke_width = 0.3; st.stroke_color = color(c['ok'] ? INK : RED)
        st.solid_filled = true; st.fill_color = color(c['ok'] ? [60, 60, 60] : RED); e.style = st; add(e, @l_sheet)
      end
    end

    def self.hchain(xs_mm, px, y_ref, off, toward_y)
      xs_mm.each_cons(2) { |a, b| pdim(pt2(px.(a), y_ref), pt2(px.(b), y_ref), off, pt2((px.(a) + px.(b)) / 2, toward_y), f1(b - a)) }
    end

    def self.vchain(zs_mm, pz, x_ref, off, toward_x)
      zs_mm.each_cons(2) { |a, b| pdim(pt2(x_ref, pz.(a)), pt2(x_ref, pz.(b)), off, pt2(toward_x, (pz.(a) + pz.(b)) / 2), f1(b - a)) }
    end

    # question bubbles of a wall page: [label, s, z] from the JSON (sheets.bubbles."A-1|A-2|A-3:<wall id>")
    def self.wall_bubbles(kind, w, px, pz)
      (sh['bubbles']["#{kind}:#{w['id']}"] || []).each { |l, s, z| bub(pt2(px.(s), pz.(z)), l) }
    end

    # ------------------------------------------------------------------ wall pages
    # one wall, or several short walls side by side at one scale (B, C, D - Andriy 2026-10-09)
    def self.page_existing(code, name, ws)
      ws = [ws] unless ws.is_a?(Array)
      next_page(name); sheet_code(code)
      yf = WY + 5.75
      s = ws.map { |w| escale(w) }.max; k = MM / s
      gap = 2.2
      total = ws.sum { |w| w['L'] * k } + gap * (ws.size - 1)
      x0 = WX + WW / 2 - total / 2
      header("SCALE 1:#{s} · DIMENSIONS IN MM · Z FROM #{zfrom == 'TOP OF THE SUBFLOOR' ? 'T.O. SUBFLOOR' : zfrom}")
      ws.each do |w|
        px, pz, = frame_of(w, yf, s: s, ox: x0)
        draw_wall(w, px, pz, k); draw_stone(w, px, pz, k); draw_openings(w, px, pz, k)
        top = top_of(w)
        hchain([0, w['L']], px, pz.(top), 0.55, pz.(top) - 3)
        hchain(w['ceil'].flat_map { |a, b, _| [a, b] }.uniq, px, pz.(top), 0.28, pz.(top) - 3) if w['ceil'].size > 1
        xs = ([0, w['L']] + w['openings'].flat_map { |o| [o['s0'], o['s1']] }).uniq.sort
        hchain(xs, px, pz.(0), 0.40, pz.(0) + 3) if xs.size > 2
        vchain([0, lev['ffl'], lev['stone_top'], top].compact.uniq, pz, px.(0), 0.75, px.(0) - 3)
        w['openings'].each do |o|
          x = px.(o['s1'])
          vchain(o['kind'] == 'window' ? [0, o['z0'], o['z1']] : [0, o['z1']], pz, x, 0.22, x + 3)
        end
        w['ceil'].each_cons(2) { |_, (a2, _, h2)| vchain([0, h2], pz, px.(a2), 0.30, px.(a2) - 3) }
        wall_bubbles('A-1', w, px, pz)
        text(w['id'].upcase, px.(w['L'] / 2), pz.(0) + 0.62, @l_sheet, size: 11, font: SANS_MED, align: :center) if ws.size > 1
        x0 += w['L'] * k + gap
      end
      ids = ws.map { |w| w['id'].upcase }
      vlabel(WX, yf + 0.95, WW, 1, code, "ELEVATION#{ws.size > 1 ? 'S' : ''} #{ids.join(', ')} — FROM THE ROOM", "SCALE 1:#{s}")
      notes(WX, yf + 1.55, WW, pnotes('A-1') + [ws.map { |w| "#{w['id']}: left #{w['ends'][0]}, right #{w['ends'][1]}" }.join('; ') + '.'])
    end

    def self.page_frames(code, name, w)
      next_page(name); sheet_code(code)
      yf = WY + 5.75
      px, pz, k, s = frame_of(w, yf)
      header("SCALE 1:#{s} · DIMENSIONS IN MM · Z FROM #{zfrom == 'TOP OF THE SUBFLOOR' ? 'T.O. SUBFLOOR' : zfrom}")
      draw_wall(w, px, pz, k); draw_stone(w, px, pz, k); draw_openings(w, px, pz, k, label: false)
      draw_panels(w, px, pz, k, ids: false, fill: nil, sw: 0.25)
      fr = draw_frames(w, px, pz, k); draw_clips(w, px, pz, k)
      fr.each { |f| bub(pt2(px.((f['x0'] + f['x1']) / 2), pz.((f['z0'] + f['z1']) / 2)), f['id'], red: false, d: 0.30, size: 6) }
      top = top_of(w)
      ups = fr.reject { |f| f['kind'] == 'LOW' }.flat_map { |f| [f['x0'], f['x1']] }.uniq.sort
      lows = fr.select { |f| f['kind'] == 'LOW' }.flat_map { |f| [f['x0'], f['x1']] }.uniq.sort
      hchain(ups, px, pz.(top), 0.30, pz.(top) - 3) if ups.size > 1
      hchain(lows, px, pz.(0), 0.40, pz.(0) + 3) if lows.size > 1
      vchain([lev['floor_gap'] || lev['stone_top'], lev['tier_joint'], (fr.any? { |f| f['kind'] == 'BAND' } ? fr.select { |f| f['kind'] == 'BAND' }.map { |f| f['z0'] }.min : nil), top].compact.uniq.sort, pz, px.(0), 0.60, px.(0) - 3)
      nc = @s['frames'][w['id']]['clips'].size
      vlabel(WX, yf + 0.95, WW, 1, code, "BACKING FRAMES + #{nc} CLIPS #{w['id'].upcase} — FROM THE ROOM, PANELS OUTLINED", "SCALE 1:#{s}")
      notes(WX, yf + 1.55, WW, [
        "Plywood 3/4\" (#{f1(bu['frame_t'])}), strips 4\" = 98 (light) and 6\" = 152 (dark) on the wall face; clip gap #{f1(bu['clip_gap'])}; panel #{f1(bu['panel_t'])} -> panel face #{f1(bu['face'])} from the wall. Schedule A-702, cut list A-703.",
        *pnotes("A-2:#{w['id']}"),
        "Dots = #{cl['make']} clips (#{nc} on this wall): frame holes D#{f1(cl['hole_d'])} x #{f1(cl['frame_depth'])} by UCON CNC, panel recesses D#{f1(cl['hole_d'])} x #{f1(cl['panel_depth'])} by the factory (D-sheets). Detail A-210."
      ])
    end

    def self.page_panels(code, name, w)
      next_page(name); sheet_code(code)
      yf = WY + 5.75
      px, pz, k, s = frame_of(w, yf)
      header("SCALE 1:#{s} · DIMENSIONS IN MM · Z FROM #{zfrom == 'TOP OF THE SUBFLOOR' ? 'T.O. SUBFLOOR' : zfrom}")
      draw_wall(w, px, pz, k); draw_stone(w, px, pz, k); draw_openings(w, px, pz, k, label: false)
      draw_panels(w, px, pz, k); draw_liners(w, px, pz, k); draw_cabinets(w, px, pz, k)
      top = top_of(w)
      ps = panels_of(w['id'])
      upper = ps.select { |p| p['z1'] > 3000 }.flat_map { |p| [p['s0'], p['s1']] }.uniq.sort
      lower = ps.select { |p| p['z0'] < 400 }.flat_map { |p| [p['s0'], p['s1']] }.uniq.sort
      hchain(upper, px, pz.(top), 0.30, pz.(top) - 3)
      hchain([upper.first, upper.last], px, pz.(top), 0.60, pz.(top) - 3) if upper.size > 2
      hchain(lower, px, pz.(0), 0.40, pz.(0) + 3)
      s_first = ps.map { |p| p['s0'] }.min
      zl = ps.select { |p| (p['s0'] - s_first).abs < 1 }.flat_map { |p| [p['z0'], p['z1']] }.uniq.sort
      vchain(zl, pz, px.(s_first), 0.60, px.(s_first) - 3)
      lo = ps.select { |p| p['kind'] == 'L' }.min_by { |p| p['s0'] }
      vchain([0, lev['ffl'], lo['z0'], lo['z1']], pz, px.(lo['s0']), 0.45, px.(lo['s0']) - 3) if lo && (lo['s0'] - s_first).abs > 1
      w['openings'].each do |o|
        col = ps.select { |p| p['s0'] > o['s0'] - 30 && p['s1'] < o['s1'] + 30 }
        next if col.empty? || o['kind'] != 'window'
        x = px.(o['s1'] + 120)
        vchain(col.flat_map { |p| [p['z0'], p['z1']] }.uniq.sort, pz, x, 0.05, x + 3)
      end
      wall_bubbles('A-3', w, px, pz)
      vlabel(WX, yf + 0.95, WW, 1, code, "PANEL LAYOUT #{w['id'].upcase} — FROM THE ROOM", "SCALE 1:#{s}")
      notes(WX, yf + 1.55, WW, pnotes("A-3:#{w['id']}"))
    end

    # ------------------------------------------------------------------ key plan, cover, 3D
    def self.page_cover(skp)
      next_page('COVER', cover: true)
      cover(placeholder: false)
      begin
        v = viewport(skp, sh['scenes']['cover'], 0.965, 2.20, 15.264, 6.65, scale: 1.0 / (sh['cover_scale'] || 50), render: :hybrid); v.render if v.render_needed?
      rescue StandardError => e
        @log << "cover viewport: #{e.class}: #{e.message}"
      end
      text(sh['cover_title'], 0.965, 1.98, @l_sheet, size: 11, font: MONO, c: INK2)
    end

    # A-100: top view drawn from the data - walls, panel zone, openings, wall lengths; no distances between walls
    def self.page_key(code, name)
      next_page(name)
      kp = STYLE['key_plan']; wt = (sh['key_wall_t'] || kp['wall_t']).to_f; fc = bu['face']
      xy = lambda do |w, s_, d|
        (ox, oy), (tx, ty), (nx, ny) = w['plan_wf'] || w['wf']
        [ox + s_ * tx + d * nx, oy + s_ * ty + d * ny]
      end
      pts = @s['walls'].flat_map { |w| [0, w['L']].product([-wt - 1400, fc + 1400]).map { |s_, d| xy.(w, s_, d) } }
      x0, x1 = pts.map(&:first).minmax; y0, y1 = pts.map(&:last).minmax
      img = @s['files'] && @s['files']['key_plan'] && File.join(@data_dir, @s['files']['key_plan'])
      img = nil unless img && File.exist?(img)
      aw = img ? WW * 0.62 : WW   # the architect's plan, if any, as a reference inset on the right
      sc = [kp['scale'], 50, 75, 100].find { |s| (x1 - x0) / s * MM <= aw + 0.01 && (y1 - y0) / s * MM <= WH - LABEL_H - 0.6 } || 100
      k = MM / sc
      header("SCALE 1:#{sc} · DIMENSIONS IN MM"); sheet_code(code)
      ox = WX + aw / 2 - (x1 - x0) * k / 2; oy = WY + (WH - LABEL_H - 1.2) / 2 - (y1 - y0) * k / 2
      pp = ->(x, y) { [ox + (x - x0) * k, oy + (y1 - y) * k] }
      q = ->(w, s_, d) { pp.(*xy.(w, s_, d)) }
      quad = ->(w, a, b, d0, d1) { [q.(w, a, d0), q.(w, b, d0), q.(w, b, d1), q.(w, a, d1)] }
      @s['walls'].each do |w|
        poly(quad.(w, 0, w['L'], -wt, 0), @l_sheet, stroke: INK, sw: 0.5, fill: STC['wall_plan'])
        w['openings'].each do |o|
          poly(quad.(w, o['s0'], o['s1'], -wt, 0), @l_sheet, stroke: INK, sw: 0.35, fill: o['kind'] == 'window' ? GLASS : [255, 255, 255])
        end
        panels_of(w['id']).select { |p| p['z0'] < 400 }.each do |p|
          poly(quad.(w, p['s0'], p['s1'], 0, fc), @l_sheet, stroke: INK2, sw: 0.25, fill: PAN_FILL)
        end
        a = pt2(*q.(w, 0, -wt)); b = pt2(*q.(w, w['L'], -wt)); t = pt2(*q.(w, w['L'] / 2, -5000))
        xs = ([0, w['L']] + w['openings'].flat_map { |o| [o['s0'], o['s1']] }).uniq.sort
        xs.each_cons(2) { |s0, s1| pdim(pt2(*q.(w, s0, -wt)), pt2(*q.(w, s1, -wt)), 0.22, t, f1(s1 - s0)) } if xs.size > 2
        pdim(a, b, xs.size > 2 ? 0.50 : 0.25, t, f1(w['L']))
        no = @wall_no[w['id']]
        side = (sh['key_label_side'] || {})[w['id']] == 'behind' ? -wt - 1150 : fc + kp['label_offset']   # room side, or behind the wall past its dimensions
        lx, ly = q.(w, w['L'] / 2, side)
        text(w['id'].upcase, lx, ly - 0.10, @l_sheet, size: 10, font: SANS_MED, c: RED, align: :center)
        text(@sheet_of[w['id']], lx, ly + 0.08, @l_sheet, size: 6, font: MONO, c: INK2, align: :center)
      end
      if img
        asp = (@s['files']['key_plan_aspect'] || 1.0).to_f
        iw = WW - aw - GUT; ih = [iw / asp, WH - LABEL_H - 1.4].min; iw = ih * asp
        add(Layout::Image.new(img, Geom::Bounds2d.new(WX + WW - iw, WY, iw, ih)), @l_sheet)
        text("REFERENCE - ARCHITECT'S PLAN, NTS, NOTHING MEASURED FROM IT", WX + WW - iw, WY + ih + 0.08, @l_sheet, size: 6.5, font: MONO, c: INK2)
      end
      vlabel(WX, WY + WH - LABEL_H, WW, 1, code, 'KEY PLAN — WALLS, PANEL ZONE, WALL LENGTHS', "SCALE 1:#{sc}")
      box_text("Wall lengths along the wall face (survey). Grey = existing wall #{f1(wt)}, light band = panels #{f1(fc)} from the wall face, " \
               'blue = windows, white = doors, openings and niches. Red = wall name as on the sheets, below it the sheet numbers. ' + pnotes('A-100').map(&:first).join(' '),
               WX, WY + WH - LABEL_H - 0.55, WW, 0.4, @l_sheet, size: 8, c: INK2)
    end

    def self.page_3d(skp, code, name)
      next_page(name); header('NOT TO SCALE'); sheet_code(code)
      ch = (WH - GUT) / 2; h = ch - LABEL_H - 0.12
      [[sh['scenes']['iso'], sh['iso_title'] || 'FINISHED PANELS'], [sh['scenes']['iso_frames'], 'BACKING FRAMES + CLIPS (PANELS HIDDEN)']].each_with_index do |(sc, t), i|
        y = WY + i * (ch + GUT)
        begin
          v = viewport(skp, sc, WX, y, WW, h, scale: 1.0 / (sh['iso_scale'] || 75), render: :hybrid); v.render if v.render_needed?
        rescue StandardError => e
          @log << "3D viewport #{sc}: #{e.class}: #{e.message}"
        end
        vlabel(WX, y + ch - LABEL_H, WW, i + 1, code, "3D — #{t}", 'NTS')
      end
    end

    # ------------------------------------------------------------------ G-001 / G-002
    def self.page_g001(code, name, idx)
      next_page(name); header('NOT TO SCALE'); sheet_code(code)
      w = (WW - GUT) / 2; x2 = WX + w + GUT
      label('SHEET INDEX', WX, WY, @l_sheet)
      y = WY + 0.22; line(WX, y, WX + w, y, @l_sheet, w: 1.0)
      rh = [0.175, (WH - 0.4) / idx.size].min
      idx.each_with_index do |(c, n), i|
        text("#{i + 1} / #{idx.size}", WX, y + 0.03, @l_sheet, size: 6.5, font: MONO)
        text(c, WX + 0.65, y + 0.03, @l_sheet, size: 6.5, font: MONO, c: INK2)
        text(n, WX + 1.35, y + 0.03, @l_sheet, size: 6.5)
        text(sh['tags']['Revision'], WX + w, y + 0.03, @l_sheet, size: 6.5, font: MONO, c: INK2, align: :right)
        y += rh; line(WX, y, WX + w, y, @l_sheet, w: 0.25, c: ROWLINE)
      end
      y = WY
      label('LEGEND', x2, y, @l_sheet); y += 0.22; line(x2, y, x2 + w, y, @l_sheet, w: 1.0); y += 0.10
      bub(pt2(x2 + 0.2, y + 0.15), 'Q1'); text('Open question - see G-002 (red = open / TBD)', x2 + 0.6, y + 0.08, @l_sheet, size: 8); y += 0.38
      bub(pt2(x2 + 0.2, y + 0.15), all_frames.first['id'], red: false, d: 0.32, size: 6); text('Backing frame number (A-20x, A-702)', x2 + 0.6, y + 0.08, @l_sheet, size: 8); y += 0.38
      text(@s['panels'].first['id'], x2 + 0.2, y + 0.05, @l_sheet, size: 8, font: MONO, c: RED, align: :center); text('Panel number (A-30x, A-701, D-sheets)', x2 + 0.6, y + 0.08, @l_sheet, size: 8); y += 0.32
      rect(x2 + 0.08, y + 0.04, 0.25, 0.18, @l_sheet, stroke: STC['frame_line'], sw: 0.3, fill: WOOD6); text('Frame strip 6" = 152 (light 4" = 98)', x2 + 0.6, y + 0.06, @l_sheet, size: 8); y += 0.30
      circle(x2 + 0.2, y + 0.13, 0.08, @l_sheet, sw: 0.5); text("Clip #{cl['make']} (frames) / recess D#{f1(cl['hole_d'])} (D-sheets, red)", x2 + 0.6, y + 0.06, @l_sheet, size: 8); y += 0.30
      ops = @s['walls'].flat_map { |x| x['openings'] }
      if @s['panels'].any? { |p| !p['rebates'].empty? }
        rect(x2 + 0.08, y + 0.04, 0.25, 0.18, @l_sheet, stroke: MINOR, sw: 0.25, fill: [222, 222, 222]); text("Rear #{f1(bu['rebate'])} rebate at a door frame (back view, D-sheets)", x2 + 0.6, y + 0.06, @l_sheet, size: 8); y += 0.30
      end
      if ops.any? { |o| o['kind'] == 'window' }
        rect(x2 + 0.08, y + 0.04, 0.25, 0.18, @l_sheet, stroke: MINOR, sw: 0.25, fill: GLASS); text('Window opening', x2 + 0.6, y + 0.06, @l_sheet, size: 8); y += 0.30
      end
      if ops.any? { |o| %w[closet niche].include?(o['kind']) }
        rect(x2 + 0.08, y + 0.04, 0.25, 0.18, @l_sheet, stroke: MINOR, sw: 0.25, fill: NICHEF); text(sh['legend_niche'] || 'Niche / closet (reference)', x2 + 0.6, y + 0.06, @l_sheet, size: 8); y += 0.30
      end
      if (@s['stone'] || {}).values.any? { |v| !v.empty? }
        rect(x2 + 0.08, y + 0.04, 0.25, 0.18, @l_sheet, stroke: MINOR, sw: 0.4, fill: STONE); text('Stone plinth - by others (reference)', x2 + 0.6, y + 0.06, @l_sheet, size: 8); y += 0.30
      end
      if ops.any? { |o| o['liner'] } || @s['liner']
        rect(x2 + 0.08, y + 0.04, 0.06, 0.18, @l_sheet, stroke: INK, sw: 0.4, fill: LINERF)
        poly([[x2 + 0.14, y + 0.22], [x2 + 0.14, y + 0.04], [x2 + 0.33, y + 0.04]], @l_sheet, stroke: INK2, sw: 0.25, dash: true)
        text('L-liner MDF 6: leg (strip) + flange behind the panel (dashed)', x2 + 0.6, y + 0.06, @l_sheet, size: 8); y += 0.30
      end
      unless (@s['doors'] || []).empty?
        rect(x2 + 0.08, y + 0.04, 0.25, 0.18, @l_sheet, stroke: INK, sw: 0.5, fill: CLADF); text("#{@s['doors'].all? { |d| d['profile'] == 'tm_pull' } ? 'Door leaf (TM, flush with the panels)' : 'Door cladding'}; swing on elevation - base on the hinges, apex at the handle", x2 + 0.6, y + 0.06, @l_sheet, size: 8); y += 0.30
      end
      y += 0.12
      label('GENERAL NOTES', x2, y, @l_sheet); y += 0.22
      line(x2, y, x2 + w, y, @l_sheet, w: 1.0); y += 0.10
      (sh['notes']['G-001'] || []).each_with_index do |(n, red), i|
        c = red ? RED : INK
        text("#{i + 1}.", x2, y, @l_sheet, size: 7.5, font: MONO, c: c)
        lines = (n.size / 82.0).ceil
        box_text(n, x2 + 0.28, y, w - 0.28, 0.15 * lines + 0.08, @l_sheet, size: 7.5, c: c)
        y += 0.15 * lines + 0.10
      end
    end

    def self.page_g002(code, name)
      next_page(name); header((sh['tags']['Status'] || 'FOR REVIEW').upcase); sheet_code(code)
      cols = [['NO.', 0.45], ['SHEET', 1.05], ['TO', 0.45], ['QUESTION', 6.9], ['ANSWER (FACTORY / SITE)', 3.0], ['DATE', 0.6]]
      ws, xs = cols_x(WX, WW, cols)
      y = WY
      cols.each_with_index { |(h, _), i| text(h, xs[i] + 0.04, y + 0.02, @l_sheet, size: 7, font: MONO, c: HEAD) }
      y += 0.22; line(WX, y, WX + WW, y, @l_sheet, w: 1.0)
      sh['questions'].each do |no, shc, to, q|
        lines = (q.size / 112.0).ceil
        rh = [0.145 * lines + 0.14, 0.36].max
        text(no, xs[0] + 0.04, y + 0.06, @l_sheet, size: 8, font: MONO, c: RED)
        box_text(shc, xs[1] + 0.04, y + 0.06, ws[1] - 0.08, rh - 0.08, @l_sheet, size: 6.5, font: MONO, c: INK2)
        text(to, xs[2] + 0.04, y + 0.06, @l_sheet, size: 7, font: MONO)
        box_text(q, xs[3] + 0.04, y + 0.06, ws[3] - 0.10, rh - 0.06, @l_sheet, size: 7, c: RED)
        y += rh
        line(WX, y, WX + WW, y, @l_sheet, w: 0.5, c: ROWLINE)
      end
      [xs[4], xs[5]].each { |x| line(x, WY + 0.22, x, y, @l_sheet, w: 0.5, c: ROWLINE) }
      box_text(sh['questions_note'], WX, y + 0.15, WW, 0.5, @l_sheet, size: 8, c: INK2)
    end

    # ------------------------------------------------------------------ A-210 clip detail + order
    def self.page_clips(code, name)
      next_page(name); header('SCALE 2:1 · DIMENSIONS IN MM'); sheet_code(code)
      k = 2.0 * MM
      dx0 = WX + 0.9; dyc = WY + 2.6
      xf = ->(mm) { dx0 + (mm + 16) * k }
      yf = ->(mm) { dyc - mm * k }
      fr = lambda do |x0, x1, y0, y1, fill, sw: 0.5, dash: false|
        rect(xf.(x0), yf.(y1), (x1 - x0) * k, (y1 - y0) * k, @l_sheet, stroke: INK, sw: sw, fill: fill, dash: dash)
      end
      gap = bu['clip_gap'].to_f; pt = bu['panel_t'].to_f; ft = bu['frame_t'].to_f
      pd = cl['panel_depth'].to_f; fd = cl['frame_depth'].to_f; hr = cl['hole_d'] / 2.0
      fr.(-16, 0, -13, 13, [214, 214, 214])
      fr.(0, ft, -13, 13, [236, 226, 204])
      fr.(ft + gap, ft + gap + pt, -13, 13, [246, 246, 242])
      fr.(ft - fd, ft, -hr, hr, [255, 255, 255], dash: true)
      fr.(ft + gap, ft + gap + pd, -hr, hr, [255, 255, 255], dash: true)
      fr.(11.4, ft, -12.25, 12.25, [70, 70, 72], sw: 0.25)
      fr.(ft + gap, ft + gap + 7.1, -12, 12, [120, 120, 124], sw: 0.25)
      fr.(ft, ft + gap, -6, 6, [95, 95, 98], sw: 0.25)
      far = pt2(xf.(80), yf.(0)); top = pt2(xf.(20), yf.(80)); bot = pt2(xf.(20), yf.(-80)); dt = 13
      pdim(pt2(xf.(0), yf.(dt)), pt2(xf.(ft), yf.(dt)), 0.22, top, f1(ft))
      pdim(pt2(xf.(ft), yf.(dt)), pt2(xf.(ft + gap), yf.(dt)), 0.42, top, f1(gap))
      pdim(pt2(xf.(ft + gap), yf.(dt)), pt2(xf.(ft + gap + pt), yf.(dt)), 0.22, top, f1(pt))
      pdim(pt2(xf.(0), yf.(dt)), pt2(xf.(ft + gap + pt), yf.(dt)), 0.70, top, f1(bu['face']))
      pdim(pt2(xf.(ft - fd), yf.(-hr)), pt2(xf.(ft), yf.(-hr)), 0.30, bot, f1(fd))
      pdim(pt2(xf.(ft + gap), yf.(-hr)), pt2(xf.(ft + gap + pd), yf.(-hr)), 0.30, bot, f1(pd))
      pdim(pt2(xf.(ft + gap + pt), yf.(-hr)), pt2(xf.(ft + gap + pt), yf.(hr)), 0.30, far, "D#{f1(cl['hole_d'])}")
      [['WALL', -8, 11], ["FRAME S #{f1(ft)}", ft / 2, 11], ["PANEL P #{f1(pt)}", ft + gap + pt / 2, 11]].each do |t, xm, ym|
        text(t, xf.(xm), yf.(ym) - 0.02, @l_sheet, size: 6, font: MONO, align: :center)
      end
      text('ROOM →', xf.(ft + gap + pt) + 0.15, yf.(0) - 0.06, @l_sheet, size: 7, font: MONO, c: INK2)
      vlabel(WX, WY + 4.9, 6.0, 1, code, "CLIP DETAIL — #{cl['mount'].upcase} MOUNT", 'SCALE 2:1')
      # clips per wall
      yy = WY + 5.6
      cols = [['WALL', 1.0], ['CLIPS', 0.8], ['FRAMES', 0.8], ['PANELS WITH CLIPS', 1.5], ['NOT ON A FRAME', 1.3]]
      rows = @s['walls'].map do |w|
        c = @s['frames'][w['id']]['clips']
        [w['id'], c.size.to_s, @s['frames'][w['id']]['frames'].size.to_s, c.map { |x| x['panel'] }.uniq.size.to_s, c.count { |x| !x['ok'] }.to_s]
      end
      n = all_clips.size
      rows << ['TOTAL', n.to_s, all_frames.size.to_s, all_clips.map { |x| x['panel'] }.uniq.size.to_s, all_clips.count { |x| !x['ok'] }.to_s]
      table(WX, yy, 6.0, cols, rows, row_h: 0.25)
      tx0 = WX + 6.45; tw = WX + WW - tx0
      label("#{cl['make'].upcase} - CATALOGUE DATA AND ORDER", tx0, WY, @l_sheet)
      line(tx0, WY + 0.17, tx0 + tw, WY + 0.17, @l_sheet, w: 1.0)
      order = ((n * (1 + FASTMOUNT['spare'])) / 5.0).ceil * 5
      boxes = (order / FASTMOUNT['box'].to_f).ceil
      [['Female clip', 'in frame S: D24.5 body, flange D28, height 7.6, screw VL-SS3'], ['Male clip', 'in panel back: D24 body, height 7.1'],
       ['Recess mount', "holes D#{f1(cl['hole_d'])}: #{f1(fd)} deep (female, frame) / #{f1(pd)} deep (male, panel), gap #{f1(gap)}"],
       ['Pull-out', "#{FASTMOUNT['Pull-out kg']} kg (22 lbs) per clip"],
       ['Placement', "on the frame members, clip centre >= #{f1(cl['edge'])} mm from the panel edge"],
       ['Drilling', 'panel recesses: factory per the D-sheets (BACK VIEW); frame holes: UCON CNC'],
       ['Quantity', "#{n} clips on #{@s['walls'].size} walls, all on a frame member"],
       ['Order', "#{order} sets (#{n} + 10%, to the next 5) -> #{boxes} boxes x #{FASTMOUNT['box']} = #{boxes * FASTMOUNT['box']} sets, Sugatsune US, item VL-03H"]].each_with_index do |(a, b), i|
        y = WY + 0.27 + i * 0.30
        text(a, tx0, y, @l_sheet, size: 7.5, font: MONO, c: INK2)
        box_text(b, tx0 + 1.25, y, tw - 1.25, 0.28, @l_sheet, size: 7.5)
        line(tx0, y + 0.25, tx0 + tw, y + 0.25, @l_sheet, w: 0.5, c: ROWLINE)
      end
      text('Clip shapes on the detail are schematic - dimensions per Fastmount catalogue 2023, p. 6.', tx0, WY + 0.27 + 8 * 0.30 + 0.05, @l_sheet, size: 7, c: INK2)
    end

    # ------------------------------------------------------------------ doors
    def self.door(id) = @s['doors'].find { |d| d['id'] == id }
    def self.opening(w, id) = w['openings'].find { |o| o['id'] == id }

    # A-501 / A-503: elevation 1:20 (vector) + plan section 1:10 (scene)
    def self.page_door(skp, code, name, dr)
      # scales picked by size (Main Kitchen DK1 1:20 / 1:10; ML Foyer OB2, 2219 wide on a 4000 wall, 1:30 / 1:20)
      es = [20, 25, 30, 40].find { |s| top_of(wall(dr['wall'])) / s * MM <= 5.3 } || 40
      ps = [10, 20, 25].find { |s| (dr['open_x'][1] - dr['open_x'][0] + 600) / s * MM <= 6.4 } || 25
      next_page(name); header("SCALE 1:#{es} / 1:#{ps} · DIMENSIONS IN MM"); sheet_code(code)
      w = wall(dr['wall']); o = opening(w, dr['id'])
      ca, cb, cz0, cz1 = o['clad']
      lo = o['s0'] - 300; hi = o['s1'] + 300
      k = MM / es; ox = WX + 0.75; yf = WY + 0.35 + top_of(w) * k
      px = ->(s) { ox + (s - lo) * k }; pz = ->(z) { yf - z * k }
      clip = ->(a, b) { [[a, lo].max, [b, hi].min] }
      # wall, stone, panels (clipped to the window lo..hi), opening, cladding
      ztop = w['ceil'].select { |a, b, _| a < hi && b > lo }.map { |c| c[2] }.max
      rect(px.(lo), pz.(ztop), (hi - lo) * k, ztop * k, @l_sheet, stroke: MINOR, sw: 0.5)
      line(px.(lo) - 0.1, pz.(0), px.(hi) + 0.1, pz.(0), @l_sheet, w: 0.75)
      line(px.(lo) - 0.1, pz.(lev['ffl']), px.(hi) + 0.1, pz.(lev['ffl']), @l_sheet, w: 0.5, dash: true)
      (@s['stone'][w['id']] || []).each do |a, b|
        a, b = clip.(a, b); next if b <= a
        rect(px.(a), pz.(lev['stone_top']), (b - a) * k, (lev['stone_top'] - lev['ffl']) * k, @l_sheet, stroke: MINOR, sw: 0.4, fill: STONE)
      end
      near = panels_of(w['id']).select { |p| p['s1'] > lo && p['s0'] < hi }
      near.each do |p|
        a, b = clip.(p['s0'], p['s1'])
        rect(px.(a), pz.(p['z1']), (b - a) * k, (p['z1'] - p['z0']) * k, @l_sheet, stroke: INK, sw: 0.75, fill: PAN_FILL)
        text(p['id'], px.((a + b) / 2), pz.((p['z0'] + p['z1']) / 2), @l_sheet, size: 7, font: MONO, c: RED, align: :center)
      end
      cm = (ca + cb) / 2.0; jn = dr['leaf_joint'].to_f / 2
      leaves = dr['leaves'].to_i == 2 ? [[ca, cm - jn, ca], [cm + jn, cb, cb]] : [[ca, cb, dr['hinge'] == 'right' ? cb : ca]]
      leaves.each do |a, b, hs|
        rect(px.(a), pz.(cz1), (b - a) * k, (cz1 - cz0) * k, @l_sheet, stroke: INK, sw: 0.75, fill: CLADF)
        sl = hs == a ? b : a
        # swing (Andriy 2026-10-17, one rule with the cabinet engine, docs/Drawing_Spec_v0.1.md - the European reading
        # TM / Cesar use): the BASE of the V on the hinge edge, the APEX at the handle edge, mid-height; HINGES written
        # at the hinge edge so a US reader cannot take it the other way
        line(px.(sl), pz.((cz0 + cz1) / 2), px.(hs), pz.(cz1), @l_sheet, w: 0.5, dash: true)
        line(px.(sl), pz.((cz0 + cz1) / 2), px.(hs), pz.(cz0), @l_sheet, w: 0.5, dash: true)
        text('HINGES', px.(hs) + (hs == a ? 0.05 : -0.05), pz.((cz0 + cz1) / 2) - 0.03, @l_sheet, size: 6, font: MONO, c: INK2, align: hs == a ? :left : :right)
        text("#{f1(b - a)}", px.((a + b) / 2), pz.(1700), @l_sheet, size: 6.5, font: MONO, c: INK2, align: :center)
      end
      pull = dr['profile'] == 'tm_pull'   # AP SAFE / AV 2026-10-17: veneered TM leaf flush with the panels, no cladding
      text(pull ? "#{dr['id']} LEAF (TM)" : "#{dr['id']} CLADDING#{leaves.size > 1 ? 'S' : ''}", px.(cm), pz.(1900), @l_sheet, size: 7, font: MONO, c: INK2, align: :center)
      # chains: top = panel edges + cladding, bottom = opening, left = levels, right = opening height
      lp = near.select { |p| p['s1'] <= ca + 1 && p['z0'] < 1000 }.map { |p| p['s1'] }.max
      rp = near.select { |p| p['s0'] >= cb - 1 && p['z0'] < 1000 }.map { |p| p['s0'] }.min
      hchain([lp, ca, cb, rp].compact, px, pz.(ztop), 0.30, pz.(ztop) - 3)
      hchain([o['s0'], o['s1']], px, pz.(0), 0.30, pz.(0) + 3)
      hchain(leaves.flat_map { |a, b, _| [a, b] }, px, pz.(0), 0.60, pz.(0) + 3)
      hchain([ca, cb], px, pz.(0), 0.90, pz.(0) + 3) if leaves.size > 1
      above = near.select { |p| p['s0'] < cb && p['s1'] > ca && p['z0'] > cz1 }.flat_map { |p| [p['z0'], p['z1']] }
      vchain(([0, lev['ffl'], cz0, cz1] + above).uniq.sort, pz, px.(lo), 0.35, px.(lo) - 3)
      vchain([0, o['z1']], pz, px.(hi), 0.30, px.(hi) + 3)
      bub(pt2(px.(cm), pz.(1300)), qref('door'))
      bub(pt2(px.(o['s0']) - 0.05, pz.(o['z1']) - 0.25), qref('heads'))
      bub(pt2(px.(lo + 150), pz.(lev['stone_top']) - 0.25), qref('stone')) if lev['stone_top']
      vlabel(WX, yf + 1.15, 4.6, 1, code, "#{dr['id']} ELEVATION — FROM #{sh['room_side'] || 'THE ROOM'}", "1:#{es}")   # below the 3 chains
      # plan section 1:10
      xc = dr['section_x']; yw = dr['wall_face_y']; zc = dr['plan_z']
      qp = pt2(WX + WW - 3.55, WY + 0.25 + 2.3)
      xm = (dr['open_x'][0] + dr['open_x'][1]) / 2.0
      # a door opening TOWARD the panels (tm_pull, AP SAFE / AV 2026-10-17): centre the view so the swing fits in front
      rsw = dr['clad_x'][1] - dr['clad_x'][0]
      yc = pull ? yw + (dr['wall_t'].to_f - bu['face'] - rsw) / 2.0 : yw + 380
      pv = cropped(skp, dr['scenes']['plan'], dr['cams']['plan'], [xm, yc, zc], qp, 6.6, 4.6, 1.0 / ps, PLAN)
      # swing on the plan (Andriy 2026-10-17): the leaf open at 90 degrees, dashed, and its arc from the latch edge;
      # pivot = the hinge edge of the leaf face; tm_pull opens into the room the panels face (-y)
      if pull
        hx = dr['hinge'] == 'right' ? dr['clad_x'][1] : dr['clad_x'][0]; ux = dr['hinge'] == 'right' ? -1 : 1
        py = yw - bu['face']; pp = ->(x, y) { pv.model_to_paper_point(P(x, y, zc)) }
        a0 = pp.(hx, py); a1 = pp.(hx, py - rsw)
        line(a0.x, a0.y, a1.x, a1.y, @l_sheet, w: 0.5, c: INK2, dash: true)
        arc = (0..18).map { |i| t = Math::PI / 2 * i / 18; pp.(hx + ux * rsw * Math.cos(t), py - rsw * Math.sin(t)) }
        arc.each_cons(2) { |m, n| line(m.x, m.y, n.x, n.y, @l_sheet, w: 0.35, c: INK2, dash: true) }
        text('SWING', a1.x + (ux.positive? ? 0.08 : -0.08), a1.y - 0.04, @l_sheet, size: 6, font: MONO, c: INK2, align: ux.positive? ? :left : :right)
      end
      x0 = dr['open_x'][0]; x1 = dr['open_x'][1]; yf0 = yw - bu['face']; yb = yw + dr['wall_t']
      kit = P(xc, -9000, zc)
      vdim(pv, P(dr['clad_x'][0], yf0, zc), P(dr['clad_x'][1], yf0, zc), 0.25, kit, dr['clad_x'][1] - dr['clad_x'][0])
      vdim(pv, P(x0, yw, zc), P(x1, yw, zc), 0.75, kit, x1 - x0)
      xl = x0 - 110; lft = P(-90_000, yw, zc); rgt = P(90_000, yw, zc)
      vdim(pv, P(xl, yw, zc), P(xl, yb, zc), 0.25, lft, dr['wall_t'])
      vdim(pv, P(xl, yf0, zc), P(xl, yw, zc), 0.25, lft, bu['face'])
      vdim(pv, P(x1 + 70, dr['jamb_y'][0], zc), P(x1 + 70, dr['jamb_y'][1], zc), 0.30, rgt, 0,
           label: "#{f1(dr['jamb_y'][1] - dr['jamb_y'][0])} JAMB")
      bub(pv.model_to_paper_point(pull ? P(xm, yw - bu['face'] - rsw * 0.3, zc) : P(xc, yw + 450, zc)), qref('door'))
      vlabel(WX + 5.0, WY + 5.05, WW - 5.0, 2, code, "#{dr['id']} PLAN SECTION AT #{f1(zc)}", "1:#{ps}")
      notes(WX + 5.0, WY + 5.65, WW - 5.0, [
        *pnotes("A-5:#{dr['id']}"),
        if pull
          st = dr['leaf_step'] || {}
          ["Leaf #{f1(cb - ca)} x #{f1(cz1 - cz0)} x #{f1(dr['leaf_t'])} (face #{f1(dr['leaf_t'].to_f - st['t'].to_f)} + back step #{f1(st['t'])} x #{f1(st['inset'])}), veneered, no applied panel, face = panel face; #{f1(cz0 - lev['ffl'])} above FFL, top #{f1(cz1)}; joints to the panels #{f1(ca - lp)} / #{f1(rp - cb)}. Opens toward the panels.", false]
        else
          [(leaves.size > 1 ? "#{leaves.size} claddings " : 'Cladding ') + "#{leaves.map { |a, b, _| f1(b - a) }.uniq.join(' / ')} x #{f1(cz1 - cz0)}#{leaves.size > 1 ? ", joint #{f1(dr['leaf_joint'])}" : ''}, #{f1(cz0 - lev['ffl'])} above FFL, top at the panel joint #{f1(cz1)}; joints to the panels #{f1(ca - lp)} / #{f1(rp - cb)}.", false]
        end,
        ["Door face = panel face #{f1(bu['face'])} from the wall; wall #{f1(dr['wall_t'])}#{sh['wall_t_note'] || ' (not surveyed)'}, jamb #{f1(dr['jamb_y'][1] - dr['jamb_y'][0])}. Panels in front of the frame rebated #{f1(bu['rebate'])} at the back (A-701, D-sheets).", true],
        'Details 1:5 on the next sheet.'
      ], size: 7, step: 0.165)
    end

    # A-502 / A-504: head + floor (vertical section), both jambs (plan section), 1:5
    def self.page_door_details(skp, code, name, dr)
      next_page(name); header('SCALE 1:5 · DIMENSIONS IN MM'); sheet_code(code)
      w = wall(dr['wall']); o = opening(w, dr['id'])
      cw = (WW - GUT) / 2; chh = (WH - GUT) / 2
      cells = [[WX, WY], [WX + cw + GUT, WY], [WX, WY + chh + GUT], [WX + cw + GUT, WY + chh + GUT]]
      s5 = 1.0 / 5
      xc = dr['section_x']; yw = dr['wall_face_y']; zc = dr['plan_z']
      yf0 = yw - bu['face']; ypb = yf0 + bu['panel_t']; yfr = yw - bu['frame_t']; yb = yw + dr['wall_t']
      ca, cb, cz0, cz1 = o['clad']
      kit = ->(z) { P(xc, -90_000, z) }; but = ->(z) { P(xc, 90_000, z) }
      # 1 head
      x0, y0 = cells[0]; q = pt2(x0 + cw / 2, y0 + 0.15 + 1.4)
      hz = (cz1 + o['z1']) / 2
      hv = cropped(skp, dr['scenes']['section'], dr['cams']['section'], [xc, yw + 60, hz], q, cw - 1.0, 2.8, s5, SIDE)
      sm = seam_of(w['id'])
      vdim(hv, P(xc, yf0, cz1), P(xc, yf0, sm[1]), 0.30, kit.(cz1), sm[1] - cz1)
      vdim(hv, P(xc, yw + 76, dr['head_z'][1]), P(xc, yw + 76, o['z1']), 0.30, but.(o['z1']), o['z1'] - dr['head_z'][1])
      zt = hz + 120
      up = P(xc, yw, 90_000)
      vdim(hv, P(xc, yf0, zt), P(xc, ypb, zt), 0.20, up, bu['panel_t'])
      vdim(hv, P(xc, yfr, zt), P(xc, yw, zt), 0.20, up, bu['frame_t'])
      vdim(hv, P(xc, yf0, zt), P(xc, yw, zt), 0.45, up, bu['face'])
      bub(hv.model_to_paper_point(P(xc, yw + 100, dr['head_z'][0])), qref('door'))
      vlabel(x0, y0 + chh - LABEL_H, cw, 1, code, "#{dr['id']} HEAD — SECTION", '1:5')
      # 2 floor
      x0, y0 = cells[1]; q = pt2(x0 + cw / 2, y0 + 0.15 + 1.4)
      bv = cropped(skp, dr['scenes']['section'], dr['cams']['section'], [xc, yw + 60, 130], q, cw - 1.0, 2.8, s5, SIDE)
      vdim(bv, P(xc, yf0, lev['ffl']), P(xc, yf0, cz0), 0.30, kit.(lev['ffl']), cz0 - lev['ffl'])
      vdim(bv, P(xc, yf0, 0), P(xc, yf0, lev['ffl']), 0.30, kit.(0), lev['ffl'])
      dn = P(xc, yw, -90_000)
      vdim(bv, P(xc, yf0, lev['ffl']), P(xc, yw, lev['ffl']), 0.25, dn, bu['face'])
      vdim(bv, P(xc, dr['jamb_y'][0], lev['ffl']), P(xc, dr['jamb_y'][1], lev['ffl']), 0.50, dn, 0,
           label: "#{f1(dr['jamb_y'][1] - dr['jamb_y'][0])} JAMB")
      bub(bv.model_to_paper_point(P(xc, yw + 60, 200)), qref('stone'))
      vlabel(x0, y0 + chh - LABEL_H, cw, 2, code, "#{dr['id']} FLOOR — SECTION", '1:5')
      # 3 / 4 jambs
      hinge_r = dr['hinge'] == 'right'
      x_open = dr['open_x']; fx = dr['frame_x']
      lp = panels_of(w['id']).select { |p| p['s1'] <= ca + 1 && p['z0'] < 1000 }.map { |p| p['s1'] }.max
      rp = panels_of(w['id']).select { |p| p['s0'] >= cb - 1 && p['z0'] < 1000 }.map { |p| p['s0'] }.min
      s2x = ->(s) { dr['clad_x'][0] + (s - ca) }   # Wall 2 runs along +x
      both = dr['hinge'] == 'both'
      [[2, x_open[0] + 50, hinge_r && !both ? 'LATCH' : 'HINGE', [[x_open[0], fx[0], yw + 76], [s2x.(lp), dr['clad_x'][0], yf0]], -1],
       [3, x_open[1] - 50, hinge_r || both ? 'HINGE' : 'LATCH', [[fx[1], x_open[1], yw + 76], [dr['clad_x'][1], s2x.(rp), yf0]], 1]].each do |ci, xj, side, gaps, sg|
        x0, y0 = cells[ci]; q = pt2(x0 + cw / 2, y0 + 0.15 + 1.4)
        jv = cropped(skp, dr['scenes']['plan'], dr['cams']['plan'], [xj, yw + 80, zc], q, cw - 1.0, 2.8, s5, PLAN)
        gaps.each { |a, b, yy| vdim(jv, P(a, yy, zc), P(b, yy, zc), 0.30, P((a + b) / 2, -90_000, zc), b - a) }
        xe = xj + sg * 150; far = P(sg * 90_000, yw, zc)
        vdim(jv, P(xe, yw, zc), P(xe, yb, zc), 0.25, far, dr['wall_t'])
        vdim(jv, P(xe, yf0, zc), P(xe, yw, zc), 0.25, far, bu['face'])
        bub(jv.model_to_paper_point(P(xj, yw + 260, zc)), qref('door'))
        vlabel(x0, y0 + chh - LABEL_H, cw, ci + 1, code, "#{dr['id']} JAMB #{sg.negative? ? 'LEFT' : 'RIGHT'} (#{side} SIDE) — PLAN SECTION", '1:5')
      end
    end

    # ------------------------------------------------------------------ A-511.. details (images, for approval)
    def self.page_detail(code, name, d)
      next_page(name); header('SCALE ~2:1 · DIMENSIONS IN MM · FOR APPROVAL'); sheet_code(code)
      fw = 8.3; fh = fw / d['aspect'][0]
      iw = WW - fw - GUT; ih = iw / d['aspect'][1]
      [[d['flat'], WX, WY, fw, fh], [d['iso'], WX + fw + GUT, WY, iw, ih]].each do |f, x, y, ww, hh|
        path = File.join(@data_dir, f)
        if File.exist?(path)
          img = Layout::Image.new(path, Geom::Bounds2d.new(x, y, ww, hh)); add(img, @l_sheet)
        else
          @log << "detail image missing: #{path}"
          rect(x, y, ww, hh, @l_sheet, stroke: RED, sw: 0.5); text("MISSING #{f}", x + 0.2, y + 0.2, @l_sheet, size: 8, c: RED)
        end
      end
      vlabel(WX, WY + fh + 0.15, fw, 1, code, d['title'], '~2:1')
      vlabel(WX + fw + GUT, WY + ih + 0.15, iw, 2, code, 'ISO', 'NTS')
      notes(WX + fw + GUT, WY + ih + 0.8, iw, d['notes'].map { |t| t.is_a?(Array) ? t : [t, false] }, size: 7, step: 0.16)
    end

    # A-511..: two sections cut from the model's detail scenes, 1:5, side by side; notes from the room JSON
    def self.page_sections(skp, code, name, d)
      next_page(name); header('SCALE 1:5 · DIMENSIONS IN MM · FOR APPROVAL'); sheet_code(code)
      n = d['cells'].size; cw = (WW - GUT * (n - 1)) / n
      tab = d['table']; th = tab ? 0.25 + 0.24 * tab['rows'].size : 0
      ch = WH - LABEL_H - 1.15 - th
      d['cells'].each_with_index do |c, i|
        x0 = WX + i * (cw + GUT)
        q = pt2(x0 + cw / 2, WY + ch / 2)
        begin
          fl = ->(a) { a && a.map { |v| Float(v) } }  # tokens resolve to strings
          vp = cropped(skp, c['scene'], fl.(c['cam']), fl.(c['at']), q, cw - 0.2, ch - 0.1, 1.0 / 5, c['proj'] == 'plan' ? PLAN : SIDE)
          # dims [a, b, offset, toward] - model mm points, resolved from the snapshot ({{tokens}}); value = |b - a|
          (c['dims'] || []).each do |da, db, off, tw|
            fa = da.map { |v| Float(v) }; fb = db.map { |v| Float(v) }; ft = tw.map { |v| Float(v) }
            vdim(vp, P(*fa), P(*fb), off.to_f, P(*ft), Math.sqrt(fa.zip(fb).sum { |m, n| (n - m)**2 }))
          end
        rescue StandardError => e
          @log << "#{code} #{c['scene']}: #{e.class}: #{e.message}"
          rect(x0, WY, cw, ch, @l_sheet, stroke: RED, sw: 0.5); text("MISSING SCENE #{c['scene']}", x0 + 0.2, WY + 0.2, @l_sheet, size: 8, c: RED)
        end
        rect(x0, WY, cw, ch, @l_sheet, stroke: ROWLINE, sw: 0.25)
        vlabel(x0, WY + ch + 0.05, cw, i + 1, code, c['title'], '1:5')
      end
      if tab
        ws_ = tab['cols'].map { |c| c[1] }; sc = WW / ws_.sum
        table(WX, WY + ch + LABEL_H + 0.15, WW, tab['cols'].map { |h, wd| [h, wd * sc] }, tab['rows'], row_h: 0.24, red: tab['red'] ? ->(_) { true } : nil, size: 7)
      end
      notes(WX, WY + ch + LABEL_H + 0.2 + th, WW, d['notes'].map { |t| t.is_a?(Array) ? t : [t, false] }, size: 7, step: 0.16)
      (d['bubbles'] || []).each { |l, ci, x, y| bub(pt2(WX + ci * (cw + GUT) + x, WY + y), l) }
    end

    # ------------------------------------------------------------------ schedules
    def self.page_a701(code, name)
      next_page(name); header("DIMENSIONS IN MM · MDF #{f1(bu['panel_t'])}, FINISH PER #{sh['finish_by'] || 'FACTORY'}"); sheet_code(code)
      ps = @s['panels']
      cols = [['PANEL', 0.55], ['WALL', 0.65], ['W', 0.65], ['H', 0.65], ['ENDS', 0.95], ['BACK', 0.85], ['CLIPS', 0.5], ['M2', 0.5]]
      row = lambda do |p|
        ends = [p['mitre_start'] ? 'L 45°' : nil, p['mitre_end'] ? 'R 45°' : nil].compact.join(' / ')
        reb = p['rebates'].empty? ? '-' : "#{f1(bu['rebate'])} #{p['rebates'].map { |r| r['door'] }.uniq.join('/')}"
        [p['id'], p['wall'], f1(p['s1'] - p['s0']), f1(p['z1'] - p['z0']), ends.empty? ? '-' : ends, reb, p['holes'].to_s,
         format('%.2f', (p['s1'] - p['s0']) * (p['z1'] - p['z0']) / 1e6)]
      end
      half = (ps.size + 1) / 2
      tw = (WW - GUT) / 2
      y1 = table(WX, WY, tw, cols, ps[0, half].map(&row), row_h: 0.255)
      rest = ps[half..].map(&row)
      area = ps.sum { |p| (p['s1'] - p['s0']) * (p['z1'] - p['z0']) } / 1e6
      rest << ['TOTAL', "#{ps.size} pcs", nil, nil, "#{ps.count { |p| p['mitre_start'] || p['mitre_end'] }} mitred",
               "#{ps.count { |p| !p['rebates'].empty? }} rebated", ps.sum { |p| p['holes'] }.to_s, format('%.2f', area)]
      y2 = table(WX + tw + GUT, WY, tw, cols, rest, row_h: 0.255)
      box_text("W = width as seen from the room (on a mitred end: to the long point at the face), H = height. ENDS: 45° mitre at the left / right end. " \
               "BACK = rear #{f1(bu['rebate'])} rebate where the panel passes in front of a door frame (D-sheets). " \
               "CLIPS: recesses D#{f1(cl['hole_d'])} x #{f1(cl['panel_depth'])} on the back, D-sheets. " + pnotes('A-701').map(&:first).join(' '),
               WX, [y1, y2].max + 0.18, WW, 0.6, @l_sheet, size: 8, c: INK2)
      bub(pt2(WX + WW - 0.2, [y1, y2].max + 0.9), qref('panel_size'))
    end

    def self.frame_clips(f)
      @s['frames'][f['wall']]['clips'].count { |c| c['x'] >= f['x0'] - 0.1 && c['x'] <= f['x1'] + 0.1 && c['z'] >= f['z0'] - 0.1 && c['z'] <= f['z1'] + 0.1 }
    end

    def self.page_a702(code, name)
      next_page(name); header('DIMENSIONS IN MM · PLYWOOD 3/4" (19)'); sheet_code(code)
      fr = all_frames
      cols = [['FRAME', 0.5], ['WALL', 0.6], ['TIER', 1.2], ['S', 1.15], ['Z', 1.15], ['W x H', 1.0], ['PARTS', 0.45], ['CLIPS', 0.45]]
      row = lambda do |f|
        [f['id'], f['wall'], f['kind'].downcase, "#{f1(f['x0'])} - #{f1(f['x1'])}", "#{f1(f['z0'])} - #{f1(f['z1'])}",
         "#{f1(f['x1'] - f['x0'])} x #{f1(f['z1'] - f['z0'])}", members(f).size.to_s, frame_clips(f).to_s]
      end
      half = (fr.size + 1) / 2
      tw = (WW - GUT) / 2
      y1 = table(WX, WY, tw, cols, fr[0, half].map(&row), row_h: 0.25, size: 6.5)
      rest = fr[half..].map(&row)
      rest << ['TOTAL', "#{fr.size} frames", nil, nil, nil, nil, fr.sum { |f| members(f).size }.to_s, fr.sum { |f| frame_clips(f) }.to_s]
      y2 = table(WX + tw + GUT, WY, tw, cols, rest, row_h: 0.25, size: 6.5)
      box_text("S = along the wall from its left end as seen from the room, Z = from the #{zfrom.downcase}. Stiles 4\" = 98 / 6\" = 152, rails on the clip rows. " \
               "Frames built, drilled (D#{f1(cl['hole_d'])} x #{f1(cl['frame_depth'])}, UCON CNC) and fixed by UCON - for information, nothing to make at the factory.",
               WX, [y1, y2].max + 0.15, WW, 0.5, @l_sheet, size: 8, c: INK2)
    end

    # cut list -> 96" strips (first fit decreasing) -> 4 x 8 sheets
    def self.cut_plan
      path = File.join(@data_dir, @s['files']['cut_list'].to_s)
      rows = if File.file?(path)
               CSV.read(path, headers: true).map { |r| [r[0].to_f, r[1].to_f, r[2].to_i] }
             else
               # no cut list next to the snapshot (Main Kitchen: written on the office Mac) - the same list from the frames
               parts = Hash.new(0)   # widths from the geometry (stile b - a, rail d - c); a frame may have no stiles
               all_frames.each do |f|
                 f['stiles'].each { |a, b, _| parts[[(b - a).round, (f['z1'] - f['z0']).round(1)]] += 1 }
                 ia = f['stiles'].empty? ? f['x0'] : f['stiles'].first[1]; ib = f['stiles'].size < 2 ? f['x1'] : f['stiles'].last[0]
                 f['rails'].each { |c, d, _| parts[[(d - c).round, (ib - ia).round(1)]] += 1 }
               end
               @log << "cut list #{path} not found - built from the frames (#{parts.size} rows)"
               parts.map { |(w, l), q| [w, l, q] }
             end
      kerf = SHEET['kerf']
      strips = []
      rows.group_by(&:first).sort_by { |w, _| -w }.each do |wd, list|
        parts = list.flat_map { |_, l, q| [l] * q }.sort.reverse
        bins = []
        parts.each do |l|
          b = bins.find { |x| x[:used] + l <= SHEET['l'] + 0.01 }
          b ||= (bins << { w: wd, used: 0.0, parts: [] }).last
          b[:parts] << l; b[:used] += l + kerf
        end
        strips.concat(bins)
      end
      sheets = []
      strips.sort_by { |s| -s[:w] }.each do |st|
        sh_ = sheets.find { |x| x[:used] + st[:w] <= SHEET['w'] + 0.01 }
        sh_ ||= (sheets << { used: 0.0, strips: [] }).last
        sh_[:strips] << st; sh_[:used] += st[:w] + kerf
      end
      [rows, strips, sheets]
    end

    def self.page_a703(code, name)
      next_page(name); header('DIMENSIONS IN MM · PLYWOOD 3/4" 4 x 8'); sheet_code(code)
      rows, strips, sheets = cut_plan
      cols = [['STRIP', 0.6], ['LENGTH', 0.8], ['QTY', 0.5]]
      lines = rows.map { |w, l, q| [f1(w), f1(l), q.to_s] }
      lines << ['TOTAL', nil, rows.sum { |r| r[2] }.to_s]
      half = (lines.size + 1) / 2
      tw = 1.95
      table(WX, WY, tw, cols, lines[0, half], row_h: 0.15, size: 6)
      table(WX + tw + 0.15, WY, tw, cols, lines[half..], row_h: 0.15, size: 6)
      # sheets portrait at 1:40, smaller (1:50 / 1:60 / 1:80) when the rows would run into the note at the bottom
      sx0 = WX + 2 * tw + 0.55; gap = 0.35; k = per_row = nil
      [40, 50, 60, 80].each do |dn|
        k = MM / dn.to_f
        per_row = ((WX + WW - sx0 + gap) / (SHEET['w'] * k + gap)).floor
        break if 0.30 + (sheets.size.to_f / per_row).ceil * (SHEET['l'] * k + 0.65) <= WH - 0.60
      end
      sheets.each_with_index do |s, i|
        r, c = i.divmod(per_row)
        x = sx0 + c * (SHEET['w'] * k + gap); y = WY + 0.30 + r * (SHEET['l'] * k + 0.65)
        rect(x, y, SHEET['w'] * k, SHEET['l'] * k, @l_sheet, stroke: INK, sw: 0.5)
        text("SHEET #{i + 1}", x, y - 0.20, @l_sheet, size: 7, font: MONO)
        xx = x
        s[:strips].each do |st|
          yy = y
          st[:parts].each do |l|
            rect(xx, yy, st[:w] * k, l * k, @l_sheet, stroke: STC['frame_line'], sw: 0.25, fill: st[:w] == 152 ? WOOD6 : WOOD)
            yy += (l + SHEET['kerf']) * k
          end
          xx += (st[:w] + SHEET['kerf']) * k
        end
        text(s[:strips].group_by { |st| st[:w] }.map { |wd, l| "#{l.size}x#{f1(wd)}" }.join(' '), x, y + SHEET['l'] * k + 0.05, @l_sheet, size: 5.5, font: MONO, c: INK2)
      end
      byw = strips.group_by { |s| s[:w] }.sort_by { |w, _| -w }.map do |wd, l|
        "#{f1(wd)}: #{l.sum { |s| s[:parts].size }} parts, #{format('%.1f', l.sum { |s| s[:parts].sum } / 1000.0)} m, #{l.size} strips of 96\""
      end
      box_text("#{byw.join(' · ')}. #{sheets.size} sheets 4 x 8, kerf #{f1(SHEET['kerf'])}. Parts in the strips from the top of each sheet, longest first. " \
               "UCON shop - not for the factory.", WX, WY + WH - 0.55, WW, 0.5, @l_sheet, size: 8, c: INK2)
      sheets.size
    end

    # ------------------------------------------------------------------ D-sheets (panel backs)
    # drilling scale: 1:15 (Main Kitchen) unless the tallest panel then runs off the sheet (ML Foyer: ~2.9 m -> 1:20)
    def self.dk = @dk ||= ([15, 20, 25].find { |s| @s['panels'].map { |p| p['z1'] - p['z0'] }.max / s * MM <= 6.6 } || 25).to_f
    def self.drill_panel(p, ox, oy, k)
      w = p['s1'] - p['s0']; h = p['z1'] - p['z0']
      px = ->(xb) { ox + xb * k }; pz = ->(z) { oy - z * k }
      p['rebates'].each do |r|
        a = p['s1'] - r['s1']; b = p['s1'] - r['s0']
        rect(px.(a), pz.(r['z1'] - p['z0']), (b - a) * k, (r['z1'] - r['z0']) * k, @l_sheet, stroke: MINOR, sw: 0.25, fill: [222, 222, 222])
      end
      rect(ox, pz.(h), w * k, h * k, @l_sheet, stroke: INK, sw: 0.75)
      hs = @s['holes'].select { |x| x['panel'] == p['id'] }
      mit = p['mitre_start'] || p['mitre_end']
      text("#{p['id']} — BACK VIEW", ox + w * k / 2, pz.(h) - 0.52, @l_sheet, size: 9, font: SANS_MED, align: :center)
      text("#{f1(w)} x #{f1(h)} x #{f1(bu['panel_t'])}#{mit ? ' · mitre 45' : ''}", ox + w * k / 2, pz.(h) - 0.33, @l_sheet, size: 6.5, font: MONO, c: mit ? RED : INK2, align: :center)
      text("#{hs.size} x D#{f1(cl['hole_d'])} x #{f1(cl['panel_depth'])} · top up", ox + w * k / 2, pz.(h) - 0.19, @l_sheet, size: 6.5, font: MONO, c: INK2, align: :center)
      r = cl['hole_d'] / 2.0 * k; cc = 0.09
      hs.each do |hh|
        cx = px.(hh['xb']); cy = pz.(hh['zb'])
        e2 = Layout::Ellipse.new(Geom::Bounds2d.new(cx - r, cy - r, 2 * r, 2 * r))
        st = Layout::Style.new; st.stroked = true; st.stroke_width = 0.5; st.stroke_color = color(RED); st.solid_filled = false
        e2.style = st; add(e2, @l_sheet)
        line(cx - cc, cy, cx + cc, cy, @l_sheet, w: 0.25, c: RED); line(cx, cy - cc, cx, cy + cc, @l_sheet, w: 0.25, c: RED)
        text(hh['id'][-3..], cx + 0.05, cy - 0.17, @l_sheet, size: 5, font: MONO, c: RED)
      end
      last = -9
      hs.map { |x| x['xb'] }.uniq.sort.each do |xb|
        q = px.(xb); row = (q - last) < 0.32 ? 1 : 0; last = q
        line(q, oy + 0.04, q, oy + 0.14 + row * 0.13, @l_sheet, w: 0.25)
        text(f1(xb), q, oy + 0.15 + row * 0.13, @l_sheet, size: 6, font: MONO, align: :center)
      end
      hs.map { |x| x['zb'] }.uniq.sort.each do |z|
        q = pz.(z); line(ox - 0.14, q, ox - 0.03, q, @l_sheet, w: 0.25)
        text(f1(z), ox - 0.16, q - 0.06, @l_sheet, size: 6, font: MONO, align: :right)
      end
      pdim(pt2(ox, oy), pt2(ox + w * k, oy), 0.55, pt2(ox + w * k / 2, oy + 5), f1(w))
      pdim(pt2(ox, oy), pt2(ox, pz.(h)), 0.62, pt2(ox - 5, oy), f1(h))
      bub(pt2(ox + w * k - 0.1, pz.(h) - 0.55), qref('mitre')) if mit
    end

    def self.drill_sheets
      k = MM / dk; gap = 0.85; avail = WW - 0.9; hmax = WH - 1.75
      all = @s['panels'].select { |p| p['holes'].positive? }
      tall, short = all.partition { |p| p['z1'] - p['z0'] > 1500 }
      pack(tall, k, gap, avail, hmax) + pack(short, k, gap, avail, hmax)
    end

    # panels in id order -> rows across the work width -> sheets (rows stacked while they fit)
    def self.pack(ps, k, gap, avail, hmax)
      sheets = []; cur = []; row = []; x = 0.0; used = 0.0; rh = 0.0
      flush = lambda do
        next if row.empty?
        if used + rh + (cur.empty? ? 0 : 1.45) > hmax && !cur.empty?
          sheets << cur; cur = []; used = 0.0
        end
        used += rh + (cur.empty? ? 0 : 1.45); cur << row; row = []; x = 0.0; rh = 0.0
      end
      ps.each do |p|
        w = (p['s1'] - p['s0']) * k
        flush.call if !row.empty? && x + w > avail
        row << p; x += w + gap; rh = [rh, (p['z1'] - p['z0']) * k].max
      end
      flush.call
      sheets << cur unless cur.empty?
      sheets
    end

    def self.page_drill(code, name, rows)
      next_page(name); header("SCALE 1:#{dk.round} · BACK VIEW · DIMENSIONS IN MM"); sheet_code(code)
      k = MM / dk; gap = 0.85; ytop = WY + 0.55
      rows.each do |row|
        hm = row.map { |p| p['z1'] - p['z0'] }.max * k
        ox = WX + 0.6
        row.each { |p| drill_panel(p, ox, ytop + hm, k); ox += (p['s1'] - p['s0']) * k + gap }
        ytop += hm + 1.45
      end
      box_text('BACK VIEW - the panel seen from the WALL side. X from the LEFT edge as seen from the back, Z from the BOTTOM edge. ' \
               "Recesses D#{f1(cl['hole_d'])} x #{f1(cl['panel_depth'])} for the #{cl['make']} male clip, made by the factory#{qref('drill') ? " (#{qref('drill')})" : ''}. " \
               "Coordinates also in #{@s['files']['panels_csv'].sub('{rev}', sh['tags']['Revision'])}.",
               WX + 0.45, WY + WH - 0.55, WW - 0.45, 0.5, @l_sheet, size: 8, c: RED)
    end

    # ------------------------------------------------------------------ run
    # spec_path: the JSON; skp: the SAVED model; out: new .layout (refused if it exists); logo; data_dir: cut list + detail images
    def self.run(spec_path, skp, out, logo, data_dir)
      raise "exists, not overwriting: #{out}" if File.exist?(out)
      raise "exists, not overwriting: #{out.sub(/\.layout\z/, '.pdf')}" if File.exist?(out.sub(/\.layout\z/, '.pdf'))
      @s = JSON.parse(File.read(spec_path))
      @dk = nil
      # a snapshot written by hand / read from a model may still carry {{tokens}} - resolve them here (Main Kitchen)
      if JSON.generate(@s['sheets']).include?('{{') && defined?(UCON::RoomSnapshot)
        @s['sheets'] = UCON::RoomSnapshot.resolve(UCON::RoomSnapshot.expand(@s['sheets'], @s), UCON::RoomSnapshot::Ctx.new(@s))
      end
      @data_dir = data_dir
      @ndim = 0; @l_dm = nil; @l_q = nil; @dsty = nil; @l_vp = nil
      @wall_no = @s['walls'].each_with_index.to_h { |w, i| [w['id'], i + 1] }
      ws = @s['walls']
      ds = drill_sheets
      plan = [['G-000', 'COVER', -> { page_cover(skp) }],
              ['G-001', title('G-001'), nil],
              ['G-002', title('G-002'), -> { page_g002('G-002', title('G-002')) }],
              ['A-100', title('A-100'), -> { page_key('A-100', title('A-100')) }]]
      groups = sh['existing_groups'] || ws.map { |w| [w['id']] }
      @sheet_of = {}
      groups.each_with_index do |ids, gi|
        gw = ids.map { |i| wall(i) }
        c = "A-10#{gi + 1}"; n = title('existing', s: ids.size > 1 ? 'S' : '', ids: ids.map(&:upcase).join(', '))
        ids.each { |i| @sheet_of[i] = "#{c} / A-20#{@wall_no[i]} / A-30#{@wall_no[i]}" }
        plan << [c, n, -> { page_existing(c, n, gw) }]
      end
      ws.each { |w| c = "A-20#{@wall_no[w['id']]}"; n = title('frames', id: w['id'].upcase); plan << [c, n, -> { page_frames(c, n, w) }] }
      plan << ['A-210', title('A-210'), -> { page_clips('A-210', title('A-210')) }]
      ws.each { |w| c = "A-30#{@wall_no[w['id']]}"; n = title('panels', id: w['id'].upcase); plan << [c, n, -> { page_panels(c, n, w) }] }
      @s['doors'].each_with_index do |dr, i|
        c1 = format('A-5%02d', 2 * i + 1); c2 = format('A-5%02d', 2 * i + 2)
        plan << [c1, title('door', id: dr['id']), -> { page_door(skp, c1, title('door', id: dr['id']), dr) }]
        plan << [c2, title('door_details', id: dr['id']), -> { page_door_details(skp, c2, title('door_details', id: dr['id']), dr) }]
      end
      (sh['details'] || []).each do |d|
        f = d['kind'] == 'sections' ? -> { page_sections(skp, d['code'], d['name'], d) } : -> { page_detail(d['code'], d['name'], d) }
        plan << [d['code'], d['name'], f]
      end
      plan << ['A-601', title('A-601'), -> { page_3d(skp, 'A-601', title('A-601')) }]
      plan << ['A-701', title('A-701'), -> { page_a701('A-701', title('A-701')) }]
      plan << ['A-702', title('A-702'), -> { page_a702('A-702', title('A-702')) }]
      plan << ['A-703', title('A-703'), -> { page_a703('A-703', title('A-703')) }]
      ds.each_with_index do |rows, i|
        c = format('D-%02d', i + 1); ids = rows.flatten.map { |p| p['id'] }.sort; n = title('drill', first: ids.first, last: ids.last, n: ids.size); n = n.sub("#{ids.first}…#{ids.first}", ids.first) if ids.size == 1
        plan << [c, n, -> { page_drill(c, n, rows) }]
      end
      idx = plan.map { |c, n, _| [c, n] }
      start([logo], sh['tags'])
      plan.each do |c, n, f|
        begin
          c == 'G-001' ? page_g001(c, n, idx) : f.call
        rescue StandardError => e
          @log << "PAGE #{c} FAILED: #{e.class}: #{e.message} @ #{e.backtrace.first(3).join(' | ')}"
        end
      end
      @log << "pages #{idx.size}: #{idx.map(&:first).join(' ')}; dimensions #{@ndim}"
      finish(out)
    end
  end
end

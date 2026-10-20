# UCON bathroom drawing set - room sheets for a client approval set (7612 Hillside Dr bathrooms + laundry, 2026-10-14).
# Extends UCON::DrawingSet (ucon_drawing_set.rb): the same 11x17 template, viewports, dimension style and line weights.
# Two sheets per room: PLAN & 3D (plan 1/2" = 1'-0" dimensioned, 3D view NTS) and ELEVATION (1/2" = 1'-0", dimensioned). Scenes per room in the model: "<R> Elevation", "<R> Plan", "<R> ISO" (probe 687).
#
# WHY A BATH ELEVATION OF ITS OWN. DrawingSet#elevation reads a kitchen: base units stand on the floor (z0 < 200) and wall
# units hang above 1200. A bathroom vanity hangs at 243 and is neither, so the kitchen rules find no floor run and no
# heights. Here the run is every cabinet / filler in the room, measured wall to wall, the mirrors get their own row above,
# and the heights are the ones a client reads: vanity bottom, carcass top, worktop, mirror bottom and top.
# Runs inside SketchUp. Reads the models, never writes them. Writes one new .layout and its .pdf.
require 'json'
load File.join(__dir__, 'ucon_drawing_set.rb')

module UCON
  module DrawingSet

    # room: { code:, x0:, x1:, y: (back wall, mm), ceiling: (mm or nil = clip above the objects),
    #         breaks: [room-local x, ...] extra stops in the floor chain (the shower edge),
    #         figures: [[key, room-local x of the feet, height mm, flip], ...] scale figures on the elevation,
    #         pouf: { x:, y: (room-local, y from the back wall, negative = into the room), d:, h: },
    #         shower: { x0:, x1:, h:, depth: } (room-local) }  - all drawn in LayOut, the model is not touched
    def room_bodies(room)
      @boxes.select { |b| cx(b).between?(room[:x0] - 50, room[:x1] + 50) && cy(b).between?(room[:y] - 1300, room[:y] + 50) }
    end

    def room_tops(room)
      @tops.select { |t| cx(t).between?(room[:x0] - 50, room[:x1] + 50) && cy(t).between?(room[:y] - 1300, room[:y] + 50) }
    end

    def stop_in(cell, e)
      raise unless e.message.start_with?('STOP')
      (@doc.remove_entity(@cur_vp) rescue nil)
      x, y, w, h = cell
      text(e.message, x + w / 2, y + h / 2, @l_sheet, size: 9, font: MONO, c: ACCENT, align: :center)
      @log << e.message; @stops << e.message
    end

    # Two sheets per room (a 1/2" elevation with its dimension rows and a plan do not fit one 11x17 work area for the
    # taller rooms - M-BA1 to the ceiling needs ~7 in for the elevation alone):
    #   plan_code: PLAN (top, full width) + 3D VIEW (below, full width)
    #   elev_code: ELEVATION (the whole work area)
    # kind :bath (hung vanities, bath_elevation) or :kitchen (floor + wall units, DrawingSet#elevation)
    PLAN_CELL_H = 4.10     # in, plan cell incl. its label (v0.2: 3.85 was 0.2 in short)

    def room_pages(skp, plan_code, elev_code, name, room, kind: :bath)
      objs = room_bodies(room); tops = room_tops(room)
      # 1 - plan + 3D
      next_page("#{name} - PLAN & 3D"); header(SCALE_HALF); sheet_code(plan_code)
      pcell = [WX, WY, WW, PLAN_CELL_H - LABEL_GAP - LABEL_H]
      begin
        pv = bath_plan(skp, "#{room[:code]} Plan", objs, room, pcell, tops)
        entourage_plan(pv, room) if pv
      rescue RuntimeError => e
        stop_in(pcell, e)
      end
      view(WX, WY, WW, PLAN_CELL_H, 1, plan_code, 'PLAN', :half, placeholder: false)
      iy = WY + PLAN_CELL_H + GUT; ih = WH - PLAN_CELL_H - GUT
      v = viewport(skp, "#{room[:code]} ISO", WX, iy, WW, ih - LABEL_GAP - LABEL_H)
      v.render if v.render_needed?
      view(WX, iy, WW, ih, 2, plan_code, '3D VIEW', :nts, placeholder: false)
      @index << [plan_code, "#{name} - PLAN & 3D"]
      # 2 - elevation
      next_page("#{name} - ELEVATION"); header(SCALE_HALF); sheet_code(elev_code)
      ecell = work_zone
      begin
        if kind == :bath
          bath_elevation(skp, "#{room[:code]} Elevation", objs, room, ecell, tops)
        else
          @after_elev = ->(v, p3) { entourage_elev(v, p3, room) }
          elevation(skp, "#{room[:code]} Elevation", objs, :x, ecell, tops: tops)
        end
      rescue RuntimeError => e
        stop_in(ecell, e)
      end
      view(WX, WY, WW, WH, 1, elev_code, 'ELEVATION', :half, placeholder: false)
      @index << [elev_code, "#{name} - ELEVATION"]
      @log << "#{name}: #{objs.size} bodies (#{objs.map { |o| o[:code] }.join(' ')}), #{tops.size} tops"
    end

    def bath_elevation(skp, scene, objs, room, zone, tops)
      raise "STOP: no bodies in #{scene}" if objs.empty?
      depth = room[:y] - 300.0
      p3 = ->(am, zm) { Geom::Point3d.new(am / 25.4, depth / 25.4, zm / 25.4) }
      zx, zy, zw, zh = zone
      vp = viewport(skp, scene, zx, zy, zw, zh, scale: 1.0 / 24)
      @cur_vp = vp
      amin = room[:x0].to_f; amax = room[:x1].to_f
      cabs = objs.select { |b| %w[cabinet filler].include?(b[:cls]) }
      # mirrors only: an engine washbasin (core 1.9.31, LVB...) is an accessory too and sits IN the top
      mirrors = objs.select { |b| b[:cls] == 'accessory' && b[:code].to_s.start_with?('UCON-MIR') }
      hung = cabs.select { |b| b[:z0] > 100 }
      floor = cabs - hung
      mode = ->(vals) { vals.empty? ? nil : vals.map(&:round).group_by { |v| v }.max_by { |_, v| v.size }.first.to_f }
      z_max = [objs.map { |b| b[:z1] }.max, tops.map { |t| t[:z1] }.max || 0, room[:ceiling] || 0].max
      levels = breaks([0.0, mode.(hung.map { |b| b[:z0] }), mode.(hung.map { |b| b[:z1] }),
                       *tops.map { |t| t[:z1] }, *mirrors.flat_map { |b| [b[:z0], b[:z1]] },
                       mode.(floor.map { |b| b[:z1] }), room[:ceiling]].compact)
      pa = vp.model_to_paper_point(p3.(amin, 0)); pb = vp.model_to_paper_point(p3.(amax, z_max))
      right_end = vp.model_to_paper_point(p3.(amax, 0)).x > pa.x ? amax : amin
      cw = (pb.x - pa.x).abs; ch = (pb.y - pa.y).abs
      plen = ->(u, v) { (vp.model_to_paper_point(p3.(u, 0)).x - vp.model_to_paper_point(p3.(v, 0)).x).abs }
      hlen = ->(u, v) { (vp.model_to_paper_point(p3.(0, u)).y - vp.model_to_paper_point(p3.(0, v)).y).abs }
      fpts = breaks([amin, amax] + cabs.flat_map { |b| [b[:x0], b[:x1]] } + Array(room[:breaks]).map { |x| amin + x })
      mpts = breaks(mirrors.empty? ? [] : [amin, amax] + mirrors.flat_map { |b| [b[:x0], b[:x1]] })
      shorts_f = fpts.each_cons(2).any? { |u, v| plen.(u, v) < SHORT_IN }
      shorts_m = mpts.each_cons(2).any? { |u, v| plen.(u, v) < SHORT_IN }
      shorts_h = levels.each_cons(2).any? { |u, v| hlen.(u, v) < SHORT_IN }
      rows_b = 1 + (shorts_f ? 1 : 0) + 1
      rows_t = mpts.size > 1 ? 1 + (shorts_m ? 1 : 0) : 0
      cols_r = 1 + (shorts_h ? 1 : 0) + 1
      need_w = cw + cols_r * ROW + TEXT_ROOM + 0.2
      need_w += fig_extra_w(room, cols_r * ROW + TEXT_ROOM + 0.2)
      need_h = ch + (rows_b + rows_t) * ROW + 2 * TEXT_ROOM
      if need_w > zw || need_h > zh
        raise "STOP: #{scene} does not fit at 1/2\": #{need_w.round(2)} x #{need_h.round(2)} in, window #{zw.round(2)} x #{zh.round(2)}"
      end
      left = [pa.x, pb.x].min; top = [pa.y, pb.y].min
      tx = zx + (zw - need_w) / 2 + 0.1 - left
      ty = zy + (zh - need_h) / 2 + rows_t * ROW + TEXT_ROOM - top
      vp.transform!(Geom::Transformation2d.new([1, 0, 0, 1, tx, ty]))
      c1 = vp.model_to_paper_point(p3.(amin - 110, -20)); c2 = vp.model_to_paper_point(p3.(amax + 110, z_max + 60))
      vp.clip_mask = Layout::Rectangle.new(Geom::Bounds2d.new([c1.x, c2.x].min, [c1.y, c2.y].min, (c2.x - c1.x).abs, (c2.y - c1.y).abs))
      vp.render if vp.render_needed?
      tops.each { |t| hatch(c4(vp, p3, t[:x0], t[:x1], t[:z0], t[:z1])) }
      Array(@notes_here).each { |txt, am, zm| q = vp.model_to_paper_point(p3.(am, zm)); note_text(txt, q.x, q.y) }
      @notes_here = nil
      entourage_elev(vp, p3, room)
      used = chain(vp, p3, fpts, 0, :below, ROW, plen)
      dim(vp, p3, [amin, 0], [amax, 0], ROW * (used + 1), :below)
      chain(vp, p3, mpts, z_max, :above, ROW, plen) if mpts.size > 1
      long, short = levels.each_cons(2).partition { |u, v| hlen.(u, v) >= SHORT_IN }
      long.each { |u, v| dim(vp, p3, [right_end, u], [right_end, v], ROW, :right) }
      short.each { |u, v| dim(vp, p3, [right_end, u], [right_end, v], ROW * 2, :right) }
      dim(vp, p3, [right_end, levels.first], [right_end, levels.last], ROW * (short.empty? ? 2 : 3), :right)
      @log << "#{scene}: run #{fpts.each_cons(2).map { |u, v| (v - u).round }.inspect}, mirrors #{mpts.each_cons(2).map { |u, v| (v - u).round }.inspect}, heights #{levels.map(&:round).inspect}"
      vp
    end

    def bath_plan(skp, scene, objs, room, zone, tops)
      zx, zy, zw, zh = zone
      xa = room[:x0] - 150; xb = room[:x1] + 150; ya = room[:y] - (room[:plan_depth] || 1100); yb = room[:y] + 150
      vp = viewport(skp, scene, zx, zy, zw, zh, scale: 1.0 / 24)
      @cur_vp = vp
      # the run on the floor plan: what stands or hangs below 1000 (vanities, base and tall units) - wall units hang
      # over it and would double the chain
      cabs = objs.select { |b| %w[cabinet filler].include?(b[:cls]) && b[:z0] < 1000 }
      a = vp.model_to_paper_point(P.(xa, ya)); b = vp.model_to_paper_point(P.(xb, yb))
      w = (b.x - a.x).abs; h = (b.y - a.y).abs
      need_h = h + 3 * ROW + TEXT_ROOM
      raise "STOP: #{scene} does not fit at 1/2\": #{w.round(2)} x #{need_h.round(2)} in, window #{zw.round(2)} x #{zh.round(2)}" if w > zw || need_h > zh
      vp.transform!(Geom::Transformation2d.new([1, 0, 0, 1, zx + (zw - w) / 2 - [a.x, b.x].min, zy + (zh - need_h) / 2 - [a.y, b.y].min]))
      c1 = vp.model_to_paper_point(P.(xa, ya)); c2 = vp.model_to_paper_point(P.(xb, yb))
      vp.clip_mask = Layout::Rectangle.new(Geom::Bounds2d.new([c1.x, c2.x].min, [c1.y, c2.y].min, (c2.x - c1.x).abs, (c2.y - c1.y).abs))
      vp.render if vp.render_needed?
      tops.each { |t| plan_hatch(vp, t) }
      return vp if cabs.empty?
      hung = cabs.select { |c| c[:z0] > 100 }
      # the vanity front line: units face -y, so the front is the smallest y
      face = (hung.empty? ? cabs : hung).map { |c| c[:y0] }.min
      pts = breaks([room[:x0], room[:x1]] + cabs.flat_map { |c| [c[:x0], c[:x1]] } + Array(room[:breaks]).map { |x| room[:x0] + x })
      pt = ->(x) { P.(x, face) }
      tw = ->(x) { P.(x, face - 2000) }
      plen = ->(u, v) { vp.model_to_paper_point(pt.(u)).distance(vp.model_to_paper_point(pt.(v))) }
      long, short = pts.each_cons(2).partition { |u, v| plen.(u, v) >= SHORT_IN }
      long.each { |u, v| dim_toward(vp, pt.(u), pt.(v), ROW, tw.((u + v) / 2)) }
      short.each { |u, v| dim_toward(vp, pt.(u), pt.(v), ROW * 2, tw.((u + v) / 2)) }
      dim_toward(vp, pt.(pts.first), pt.(pts.last), ROW * (short.empty? ? 2 : 3), tw.((pts.first + pts.last) / 2))
      # depths: the vanity, and any deeper body (a tall unit) at its own x
      depths = cabs.group_by { |c| (room[:y] - c[:y0]).round }.map { |dpt, cs| [dpt, cs.max_by { |c| c[:x1] }] }
      depths.each do |dpt, c|
        x = c[:x1] - 60
        dim_toward(vp, P.(x, room[:y]), P.(x, room[:y] - dpt), ROW, P.(x + 3000, room[:y] - dpt / 2.0))
      end
      @log << "#{scene}: run #{pts.each_cons(2).map { |u, v| (v - u).round }.inspect}, depths #{depths.map(&:first).inspect}"
      vp
    end
    # ---------------------------------------------------------------- entourage (set v0.4, Andriy 2026-10-14)
    # Drawn in LayOut over the views, never in the model: scale figures (the shipped LayOut scrapbook "People",
    # row 1 "Detailed", outlines re-drawn from scale_figures.json at the view's scale), the pouf under the M-MST
    # make-up table, the L-BA2 shower. Own tag "Entourage", created after the views so it sits above them.
    FIG_FILE = File.join(__dir__, 'scale_figures.json')
    FIG_INK = [118, 118, 118].freeze
    FIG_GAP_IN = 3 * ROW + TEXT_ROOM + 0.25   # paper in from the wall line to the first figure: clears 3 height columns
    FIG_STEP_IN = 0.20                        # paper in between figures

    def fig_aspect(key)
      @fig_data ||= JSON.parse(File.read(FIG_FILE))['figures']
      (@fig_data[key] || {})['aspect'].to_f
    end

    # paper width the figures add to an elevation at 1/2" (beyond what its dimension columns already take)
    def fig_extra_w(room, dims_w)
      figs = Array(room[:figures])
      return 0.0 if figs.empty?
      ws = figs.map { |key, _x, h_mm, _f| fig_aspect(key) * h_mm / 25.4 / 24 }
      FIG_GAP_IN - dims_w + ws.sum + FIG_STEP_IN * (ws.size - 1) + 0.15
    end
    ENT_INK = [0x3A, 0x3B, 0x3E].freeze

    def ent_layer
      @l_ent = nil if @l_ent && @l_ent.document != @doc rescue nil
      @l_ent ||= @doc.layers.add('Entourage', false)
    end

    def ent_style(w, ink, fill: nil, dash: false)
      st = Layout::Style.new
      st.stroked = true; st.stroke_width = w; st.stroke_color = color(ink)
      if fill then st.solid_filled = true; st.fill_color = color(fill) else st.solid_filled = false end
      st.stroke_pattern = Layout::Style::STROKE_PATTERN_DASH if dash
      st
    end

    # one figure: feet centre at paper point foot, height h (paper in); flip mirrors it left-right
    def figure(key, foot, h, flip: false)
      @fig_data ||= JSON.parse(File.read(FIG_FILE))['figures']
      f = @fig_data[key] or (@log << "figure #{key}: not in #{File.basename(FIG_FILE)}"; return)
      sx = flip ? -h : h
      pt = ->(x, y) { Geom::Point2d.new(foot.x + x * sx, foot.y + y * h) }
      made = []
      f['paths'].each do |pth|
        path = nil; cur = nil
        pth['s'].each do |s|
          case s[0]
          when 'M' then cur = pt.(s[1], s[2])
          when 'L'
            q = pt.(s[1], s[2])
            next if q.distance(path ? path.end_point : cur) < 1e-5
            path ? path.append_point(q) : (path = Layout::Path.new(cur, q))
          when 'C'
            path ||= Layout::Path.new(cur, Geom::Point2d.new(cur.x + 1e-4, cur.y))
            path.append_point(pt.(s[1], s[2]), pt.(s[3], s[4]), pt.(s[5], s[6]))
          end
        end
        next unless path
        path.style = ent_style(pth['o'] ? 0.35 : 0.2, FIG_INK)
        made << path
      end
      begin
        add(Layout::Group.new(made), ent_layer)
      rescue StandardError
        made.each { |e| add(e, ent_layer) }
      end
      @figures = (@figures || 0) + 1
    rescue StandardError => e
      @log << "figure #{key} failed: #{e.class}: #{e.message}"
    end

    # a rounded rectangle on paper from two model corners (pouf body)
    def ent_rounded(vp, p3, a0, a1, z0, z1, r_mm, w: 0.5, fill: [255, 255, 255], dash: false)
      q = c4(vp, p3, a0, a1, z0, z1)
      xs = q.map(&:x); ys = q.map(&:y)
      r = (vp.model_to_paper_point(p3.(a0 + r_mm, z0)).x - q[0].x).abs
      b = Geom::Bounds2d.new(xs.min, ys.min, xs.max - xs.min, ys.max - ys.min)
      e = begin
        Layout::Rectangle.new(b, Layout::Rectangle::TYPE_ROUNDED, r)
      rescue StandardError
        Layout::Rectangle.new(b)
      end
      e.style = ent_style(w, ENT_INK, fill: fill, dash: dash)
      add(e, ent_layer)
    end

    def ent_line(a, b, w: 0.35, ink: ENT_INK, dash: false)
      e = Layout::Path.new(a, b)
      e.style = ent_style(w, ink, dash: dash)
      add(e, ent_layer)
    end

    def ent_ellipse(cx, cy, w, h, sw: 0.35, fill: nil, dash: false)
      e = Layout::Ellipse.new(Geom::Bounds2d.new(cx - w / 2, cy - h / 2, w, h))
      e.style = ent_style(sw, ENT_INK, fill: fill, dash: dash)
      add(e, ent_layer)
    end

    def entourage_elev(vp, p3, room)
      a0 = room[:x0].to_f
      pp = ->(a, z) { vp.model_to_paper_point(p3.(a0 + a, z)) }
      if (sh = room[:shower])
        # glass partition seen on edge, 10 mm, curb to sh[:h]
        q = c4(vp, p3, a0 + sh[:x0], a0 + sh[:x0] + 10, 0, sh[:h])
        e = Layout::Rectangle.new(Geom::Bounds2d.new(q.map(&:x).min, q.map(&:y).min, (q[1].x - q[0].x).abs, (q[2].y - q[1].y).abs))
        e.style = ent_style(0.5, ENT_INK, fill: [225, 232, 236]); add(e, ent_layer)
        cx = (sh[:x0] + sh[:x1]) / 2.0
        mm2in = (pp.(0, 0).x - pp.(1000, 0).x).abs / 1000.0
        # wall-mounted head: escutcheon, arm, head
        hz = [sh[:h] - 50, (room[:ceiling] || 9999) - 110].min
        e1 = pp.(cx, hz); ent_ellipse(e1.x, e1.y, 60 * mm2in, 60 * mm2in, sw: 0.35)
        ent_line(pp.(cx, hz - 30), pp.(cx, hz - 80), w: 0.5)
        hd = pp.(cx, hz - 95); ent_ellipse(hd.x, hd.y, 230 * mm2in, 30 * mm2in, sw: 0.5, fill: [255, 255, 255])
        # valve trim and lever
        v = pp.(cx, 1100); ent_ellipse(v.x, v.y, 170 * mm2in, 170 * mm2in, sw: 0.5)
        ent_ellipse(v.x, v.y, 40 * mm2in, 40 * mm2in, sw: 0.35)
        ent_line(v, pp.(cx + 100, 1100), w: 0.75)
        # floor drain
        ent_line(pp.(cx - 60, 8), pp.(cx + 60, 8), w: 1.0)
        n = pp.(cx, 1500); note_text("SHOWER\nGLASS & FIXTURES\nBY OTHERS", n.x, n.y)
      end
      if (pf = room[:pouf])
        r = pf[:d] / 2.0
        ent_rounded(vp, p3, a0 + pf[:x] - r, a0 + pf[:x] + r, 0, pf[:h], 70)
        ent_line(pp.(pf[:x] - r + 25, pf[:h] - 60), pp.(pf[:x] + r - 25, pf[:h] - 60), w: 0.25)
        n = pp.(pf[:x], pf[:h] / 2.0 + 40); note_text("POUF\nD#{pf[:d]} H#{pf[:h]}", n.x, n.y)
      end
      # figures stand OUTSIDE the drawing, to the right of the height dimensions, on the floor line
      # (Andriy 2026-10-14: in front of the vanities they cluttered the drawing)
      figs = Array(room[:figures])
      unless figs.empty?
        y0 = pp.(0, 0).y
        xr = [pp.(0, 0).x, pp.(room[:x1] - a0, 0).x].max + FIG_GAP_IN
        x = xr
        figs.each do |key, _x, h_mm, flip|
          h = (y0 - pp.(0, h_mm).y).abs
          w = fig_aspect(key) * h
          figure(key, Geom::Point2d.new(x + w / 2, y0), h, flip: flip)
          x += w + FIG_STEP_IN
        end
        ent_line(Geom::Point2d.new(xr - 0.1, y0), Geom::Point2d.new(x - FIG_STEP_IN + 0.1, y0), w: 0.35, ink: FIG_INK)
      end
    rescue StandardError => e
      @log << "entourage #{room[:code]} elevation failed: #{e.class}: #{e.message}"
    end

    def entourage_plan(vp, room)
      a0 = room[:x0].to_f; yw = room[:y].to_f
      pp = ->(x, y) { vp.model_to_paper_point(P.(a0 + x, yw + y)) }
      mm2in = pp.(0, 0).distance(pp.(1000, 0)) / 1000.0
      if (sh = room[:shower])
        dep = sh[:depth] || 900
        ent_line(pp.(sh[:x0] + 5, 0), pp.(sh[:x0] + 5, -dep), w: 1.0)
        cx = (sh[:x0] + sh[:x1]) / 2.0
        d = pp.(cx, -dep / 2.0)
        s = 110 * mm2in
        e = Layout::Rectangle.new(Geom::Bounds2d.new(d.x - s / 2, d.y - s / 2, s, s))
        e.style = ent_style(0.35, ENT_INK); add(e, ent_layer)
        ent_line(Geom::Point2d.new(d.x - s / 2, d.y - s / 2), Geom::Point2d.new(d.x + s / 2, d.y + s / 2), w: 0.25)
        ent_line(Geom::Point2d.new(d.x + s / 2, d.y - s / 2), Geom::Point2d.new(d.x - s / 2, d.y + s / 2), w: 0.25)
        n = pp.(cx, -dep / 2.0 + 260); note_text('SHOWER', n.x, n.y)
      end
      if (pf = room[:pouf])
        c = pp.(pf[:x], pf[:y]); d = pf[:d] * mm2in
        ent_ellipse(c.x, c.y, d, d, sw: 0.5, dash: true)
      end
    rescue StandardError => e
      @log << "entourage #{room[:code]} plan failed: #{e.class}: #{e.message}"
    end
  end
end

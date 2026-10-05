# UCON drawing set writer - a project's LayOut set built with the SheetTemplate primitives (same frame, title
# block, headers, view labels, scale bars), plus SketchUp viewports from the project's scenes, dimensions tied to
# model points (text D1: inches to 1/16 over mm), and the cabinet schedule from the engine's order CSV.
# Runs inside SketchUp. Reads the model, never writes it. Writes one new .layout and its .pdf; refuses to overwrite.
require 'csv'
load File.join(__dir__, 'ucon_sheet_template.rb')

module UCON
  module DrawingSet
    include UCON::SheetTemplate
    extend UCON::SheetTemplate
    extend self

    LINE_BASE = 0.25       # pt, model edges on paper (see #viewport)
    DIM_LINE = 0.25        # pt, dimension and extension lines - level 6 of the hierarchy, was 0.35
    ROW = 0.375            # spec 7: first row 3/8 from the object, 3/8 between rows
    SHORT_IN = 0.30        # a span shorter than this on paper goes to its own row (text would not fit between ticks)
    TEXT_ROOM = 0.35
    INK_C = [0x1C, 0x1D, 0x1F].freeze
    RED = [0xC6, 0x28, 0x28].freeze # custom / to-quote rows (Andriy 2026-10-04)

    def mm(v) = v.to_f * 25.4

    def inch_txt(mmv)
      s = (mmv / 25.4 * 16).round; w = s / 16; f = s % 16
      return "#{w}\"" if f.zero?
      g = f.gcd(16)
      "#{w.zero? ? '' : "#{w} "}#{f / g}/#{16 / g}\""
    end

    # MILLIMETRES ONLY (Andriy 2026-10-04). Was D1, inches to 1/16 over mm; inch_txt stays for a set that wants it.
    def d1(mmv) = mmv.round.to_s

    # ---------------------------------------------------------------- model facts
    def collect(model)
      ce = UCON::CabinetEngine
      @boxes = []; @tops = []
      walk = lambda do |ents, depth|
        ents.each do |e|
          if e.is_a?(Sketchup::ComponentInstance)
            a = ce::Contract.read(e.definition)
            if ce::Export.orderable?(a)
              b = body_bounds(e)
              @boxes << { id: e.entityID, rank: ce::Export.flag_rank(a), idx: @boxes.size, code: a['code'].to_s, cls: a['object_class'].to_s,
                          x0: mm(b.min.x), x1: mm(b.max.x), y0: mm(b.min.y), y1: mm(b.max.y), z0: mm(b.min.z), z1: mm(b.max.z) }
            elsif depth < 6
              walk.(e.definition.entities, depth + 1)
            end
          elsif e.is_a?(Sketchup::Group)
            if e.layer.name =~ /Worktop/
              b = e.bounds
              @tops << { ent: e, name: e.name, x0: mm(b.min.x), x1: mm(b.max.x), y0: mm(b.min.y), y1: mm(b.max.y), z0: mm(b.min.z), z1: mm(b.max.z) }
            elsif depth < 6
              walk.(e.entities, depth + 1)
            end
          end
        end
      end
      walk.(model.entities, 0)
      # THE ROW NUMBER OF THE ORDER CSV, reproduced: Export.rows numbers the orderable bodies in the walk order of
      # ExportRun.objects after a stable sort on flag_rank. Same walk here, same sort, so ITEM n on a key sheet is row n.
      @boxes.sort_by { |b| [b[:rank], b[:idx]] }.each_with_index { |b, i| b[:row] = i + 1 }
      @log << "model: #{@boxes.size} orderable bodies, #{@tops.size} worktop / backsplash groups"
    end

    # THE BODY, NOT THE INSTANCE BOX: an instance box carries the plan symbols on the floor and the door swing
    # (SE0700 at 2280..3000 reads z 0..3022, CK7744 reads 1194 deep - probe 327). Parts on UCON tags are symbols.
    def body_bounds(inst)
      bb = Geom::BoundingBox.new
      inst.definition.entities.each do |c|
        next unless c.is_a?(Sketchup::Group) || c.is_a?(Sketchup::ComponentInstance)
        next if c.layer.name.start_with?('UCON')
        (0..7).each { |k| bb.add(c.bounds.corner(k).transform(inst.transformation)) }
      end
      bb.empty? ? inst.bounds : bb
    end

    def cx(b) = (b[:x0] + b[:x1]) / 2
    def cy(b) = (b[:y0] + b[:y1]) / 2

    # ---------------------------------------------------------------- viewport
    def viewport(skp, scene_part, bx, by, bw, bh, scale: nil, render: :vector)
      vp = Layout::SketchUpModel.new(skp, Geom::Bounds2d.new(bx, by, bw, bh))
      names = vp.scenes
      idx = names.index { |n| n.to_s.include?(scene_part) } or raise "STOP: scene '#{scene_part}' not found (#{names.join(' | ')})"
      vp.current_scene = idx
      vp.render_mode = { vector: Layout::SketchUpModel::VECTOR_RENDER, hybrid: Layout::SketchUpModel::HYBRID_RENDER,
                         raster: Layout::SketchUpModel::RASTER_RENDER }[render]
      if scale
        vp.perspective = false
        vp.scale = scale
        vp.preserve_scale_on_resize = true
      end
      vp.display_background = false
      # LINE HIERARCHY (Andriy 2026-10-04): base 0.25 pt; the UCON CAD style multiplies it - profiles x2 = 0.5,
      # section cut x3 = 0.75. It was 0.5 / 1.0 / 1.5 in set v0.3. The colour HERO keeps LayOut's default.
      vp.line_weight = LINE_BASE unless render == :hybrid
      @l_vp ||= @doc.layers.add('Views', false)
      add(vp, @l_vp)
      vp
    end

    # ---------------------------------------------------------------- dimensions
    def dim_style
      return @dst if @dst
      s = Layout::Style.new
      t = Layout::Style.new; t.font_family = SANS; t.font_size = 9.0; t.text_color = color(INK_C)
      s.set_sub_style(Layout::Style::DIMENSION_TEXT, t)
      [Layout::Style::DIMENSION_START_EXTENSION_LINE, Layout::Style::DIMENSION_END_EXTENSION_LINE].each do |k|
        l = Layout::Style.new; l.stroke_width = DIM_LINE; l.stroke_color = color(INK_C); s.set_sub_style(k, l)
      end
      l = Layout::Style.new; l.stroke_width = DIM_LINE; l.stroke_color = color(INK_C)
      l.start_arrow_type = Layout::Style::ARROW_SLASH_RIGHT; l.end_arrow_type = Layout::Style::ARROW_SLASH_RIGHT
      s.set_sub_style(Layout::Style::DIMENSION_LINE, l)
      @dst = s
    end

    # q1/q2: [axis_mm, z_mm]; side :below :above :right
    def dim(vp, p3, q1, q2, off, side)
      a = vp.model_to_paper_point(p3.(*q1)); b = vp.model_to_paper_point(p3.(*q2))
      d = Layout::LinearDimension.new(a, b, off)
      add(d, @l_dims)
      ok = case side
           when :below then d.bounds.lower_right.y > [a.y, b.y].max + 0.01
           when :above then d.bounds.upper_left.y < [a.y, b.y].min - 0.01
           when :right then d.bounds.lower_right.x > [a.x, b.x].max + 0.01
           end
      unless ok
        @doc.remove_entity(d)
        d = Layout::LinearDimension.new(a, b, -off); add(d, @l_dims)
      end
      finish_dim(d, vp, p3.(*q1), p3.(*q2), side == :right ? (q2[1] - q1[1]).abs : (q2[0] - q1[0]).abs)
    end

    def finish_dim(d, vp, a3, b3, mmv)
      d.style = dim_style
      begin
        d.connect(Layout::ConnectionPoint.new(vp, a3), Layout::ConnectionPoint.new(vp, b3))
        @connected += 1
      rescue StandardError => e
        @conn_err ||= "#{e.class}: #{e.message}"
      end
      d.custom_text = true
      t = d.text; t.plain_text = d1(mmv)
      # the custom text comes back in LayOut's default Helvetica unless it carries its own style (set 329c, pdffonts)
      t.style = dim_style.get_sub_style(Layout::Style::DIMENSION_TEXT) rescue nil
      d.text = t
      d.style = dim_style
      @dims += 1
      d
    end

    # a dimension between two model points, its line on the side of `toward` (a model point), `off` inches out
    def dim_toward(vp, a3, b3, off, toward3)
      a = vp.model_to_paper_point(a3); b = vp.model_to_paper_point(b3); t = vp.model_to_paper_point(toward3)
      mx = (a.x + b.x) / 2; my = (a.y + b.y) / 2
      d = Layout::LinearDimension.new(a, b, off); add(d, @l_dims)
      c = d.bounds; cxp = c.upper_left.x + c.width / 2; cyp = c.upper_left.y + c.height / 2
      if (cxp - mx) * (t.x - mx) + (cyp - my) * (t.y - my) < 0
        @doc.remove_entity(d)
        d = Layout::LinearDimension.new(a, b, -off); add(d, @l_dims)
      end
      finish_dim(d, vp, a3, b3, a3.distance(b3).to_f * 25.4)
    end

    P = ->(x, y, z = 900) { Geom::Point3d.new(x / 25.4, y / 25.4, z / 25.4) }

    # a run on the plan: chain of module widths along `along` (:x / :y) on the face line `face` (mm),
    # dimension lines toward `inward` (+1 / -1 on the other axis); long spans row 1, short row 2, overall last
    def plan_run(vp, objs, along, face, inward)
      k0, k1 = along == :x ? %i[x0 x1] : %i[y0 y1]
      pts = breaks(objs.flat_map { |o| [o[k0], o[k1]] })
      return if pts.size < 2
      pt = ->(a) { along == :x ? P.(a, face) : P.(face, a) }
      tw = ->(a) { along == :x ? P.(a, face + inward * 2000) : P.(face + inward * 2000, a) }
      plen = ->(u, v) { vp.model_to_paper_point(pt.(u)).distance(vp.model_to_paper_point(pt.(v))) }
      long, short = pts.each_cons(2).partition { |u, v| plen.(u, v) >= SHORT_IN }
      long.each { |u, v| dim_toward(vp, pt.(u), pt.(v), ROW, tw.((u + v) / 2)) }
      short.each { |u, v| dim_toward(vp, pt.(u), pt.(v), ROW * 2, tw.((u + v) / 2)) }
      dim_toward(vp, pt.(pts.first), pt.(pts.last), ROW * (short.empty? ? 2 : 3), tw.((pts.first + pts.last) / 2))
      @log << "plan run #{along} @#{face.round}: #{pts.each_cons(2).map { |u, v| (v - u).round }.inspect}"
    end

    def breaks(vals)
      vals.map { |v| v.round(1) }.uniq.sort.each_with_object([]) { |v, acc| acc << v if acc.empty? || v - acc.last > 1.0 }
    end

    # a chain row by row: spans >= SHORT_IN on paper in the first row, shorter ones in the next; returns rows used
    def chain(vp, p3, pts, z, side, first_off, paper_len)
      return 0 if pts.size < 2
      spans = pts.each_cons(2).to_a
      long, short = spans.partition { |a, b| paper_len.(a, b) >= SHORT_IN }
      long.each { |a, b| dim(vp, p3, [a, z], [b, z], first_off, side) }
      short.each { |a, b| dim(vp, p3, [a, z], [b, z], first_off + ROW, side) } unless short.empty?
      short.empty? ? 1 : 2
    end

    # one elevation: objs are the bodies the scene shows, axis :x or :y is the sheet's horizontal
    def elevation(skp, scene, objs, axis, zone, tops: [])
      raise "STOP: no bodies selected for #{scene}" if objs.empty?
      a0k, a1k = axis == :x ? %i[x0 x1] : %i[y0 y1]
      dk = axis == :x ? :y : :x
      depth = objs.map { |b| (b[:"#{dk}0"] + b[:"#{dk}1"]) / 2 }.sum / objs.size
      p3 = lambda do |am, zm|
        axis == :x ? Geom::Point3d.new(am / 25.4, depth / 25.4, zm / 25.4) : Geom::Point3d.new(depth / 25.4, am / 25.4, zm / 25.4)
      end
      zx, zy, zw, zh = zone
      vp = viewport(skp, scene, zx, zy, zw, zh, scale: 1.0 / 24)
      @cur_vp = vp
      amin = objs.map { |b| b[a0k] }.min; amax = objs.map { |b| b[a1k] }.max
      floor = objs.select { |b| b[:z0] < 200 }
      walls = objs.select { |b| b[:z0] > 1200 }
      cab = floor.select { |b| b[:z1] < 1000 && b[:cls] == 'cabinet' }.map { |b| b[:z1].round }
      z_base = cab.empty? ? nil : cab.group_by { |v| v }.max_by { |_, v| v.size }.first.to_f
      z_tops = tops.map { |t| t[:z1] }
      wcab = walls.select { |b| %w[cabinet filler].include?(b[:cls]) }
      tall = floor.select { |b| b[:z1] > 1500 && %w[cabinet appliance_front].include?(b[:cls]) }.map { |b| b[:z1].round }
      z_tall = tall.empty? ? nil : tall.group_by { |v| v }.max_by { |_, v| v.size }.first.to_f
      z_max = objs.map { |b| b[:z1] }.max
      levels = breaks([0.0, z_base, *z_tops, z_tall, wcab.map { |b| b[:z0] }.min, wcab.map { |b| b[:z1] }.max, z_max].compact)
      # paper geometry before moving
      pa = vp.model_to_paper_point(p3.(amin, 0)); pb = vp.model_to_paper_point(p3.(amax, z_max))
      right_end = vp.model_to_paper_point(p3.(amax, 0)).x > pa.x ? amax : amin
      cw = (pb.x - pa.x).abs; ch = (pb.y - pa.y).abs
      plen = ->(u, v) { (vp.model_to_paper_point(p3.(u, 0)).x - vp.model_to_paper_point(p3.(v, 0)).x).abs }
      hlen = ->(u, v) { (vp.model_to_paper_point(p3.(0, u)).y - vp.model_to_paper_point(p3.(0, v)).y).abs }
      fpts = breaks(floor.flat_map { |b| [b[a0k], b[a1k]] })
      wpts = breaks(walls.flat_map { |b| [b[a0k], b[a1k]] })
      shorts_f = fpts.each_cons(2).any? { |u, v| plen.(u, v) < SHORT_IN }
      shorts_h = levels.each_cons(2).any? { |u, v| hlen.(u, v) < SHORT_IN }
      rows_b = (fpts.size > 1 ? 1 : 0) + (shorts_f ? 1 : 0) + 1
      rows_t = wpts.size > 1 ? 1 : 0
      cols_r = 1 + (shorts_h ? 1 : 0) + 1
      need_w = cw + cols_r * ROW + TEXT_ROOM + 0.2
      need_h = ch + (rows_b + rows_t) * ROW + 2 * TEXT_ROOM
      if need_w > zw || need_h > zh
        raise "STOP: #{scene} does not fit at 1/2\" with its dimension rows: #{need_w.round(2)} x #{need_h.round(2)} in, window #{zw.round(2)} x #{zh.round(2)}"
      end
      left = [pa.x, pb.x].min; top = [pa.y, pb.y].min
      tx = zx + (zw - need_w) / 2 + 0.1 - left
      ty = zy + (zh - need_h) / 2 + rows_t * ROW + TEXT_ROOM - top
      vp.transform!(Geom::Transformation2d.new([1, 0, 0, 1, tx, ty]))
      c1 = vp.model_to_paper_point(p3.(amin - 60, -20)); c2 = vp.model_to_paper_point(p3.(amax + 60, z_max + 120))
      vp.clip_mask = Layout::Rectangle.new(Geom::Bounds2d.new([c1.x, c2.x].min, [c1.y, c2.y].min, (c2.x - c1.x).abs, (c2.y - c1.y).abs))
      vp.render if vp.render_needed?
      tops.each { |t| hatch(c4(vp, p3, t[a0k], t[a1k], t[:z0], t[:z1])) }
      Array(@notes_here).each { |txt, am, zm| q = vp.model_to_paper_point(p3.(am, zm)); note_text(txt, q.x, q.y) }
      @notes_here = nil
      # rows below: floor chain (+ short spans), then overall
      used = chain(vp, p3, fpts, 0, :below, ROW, plen)
      dim(vp, p3, [amin, 0], [amax, 0], ROW * (used + 1), :below)
      # row above: wall units
      chain(vp, p3, wpts, z_max, :above, ROW, plen) if wpts.size > 1
      # heights at the right end, short ones in their own column, then overall
      long, short = levels.each_cons(2).partition { |u, v| hlen.(u, v) >= SHORT_IN }
      long.each { |u, v| dim(vp, p3, [right_end, u], [right_end, v], ROW, :right) }
      short.each { |u, v| dim(vp, p3, [right_end, u], [right_end, v], ROW * 2, :right) }
      dim(vp, p3, [right_end, levels.first], [right_end, levels.last], ROW * (short.empty? ? 2 : 3), :right)
      @log << "#{scene}: #{objs.size} bodies, chain #{fpts.each_cons(2).map { |u, v| (v - u).round }.inspect}, " \
              "upper #{wpts.each_cons(2).map { |u, v| (v - u).round }.inspect}, heights #{levels.map(&:round).inspect}, overall #{(amax - amin).round}"
      vp
    end

    # ---------------------------------------------------------------- stone hatch (Andriy 2026-10-04: Terrazzo)
    PATTERN = '/Applications/SketchUp 2025/LayOut.app/Contents/Resources/PatternFills/Material Symbols/Terrazzo.png'.freeze

    def c4(vp, p3, a0, a1, z0, z1)
      [[a0, z0], [a1, z0], [a1, z1], [a0, z1]].map { |a, z| vp.model_to_paper_point(p3.(a, z)) }
    end

    def hatch(pts)
      return if pts.size < 3
      @l_hatch = nil if @l_hatch && @l_hatch.document != @doc rescue nil
      @l_hatch ||= @doc.layers.add('Stone hatch', false)
      path = Layout::Path.new(pts[0], pts[1])
      pts[2..].each { |q| path.append_point(q) }
      begin; path.close; rescue StandardError; path.append_point(pts[0]); end
      st = Layout::Style.new
      st.stroked = false; st.solid_filled = false
      st.pattern_filled = true; st.pattern_fill_path = PATTERN; st.pattern_fill_scale = 0.35
      path.style = st
      add(path, @l_hatch)
      @hatches = (@hatches || 0) + 1
    rescue StandardError => e
      @log << "hatch failed: #{e.class}: #{e.message}"
    end

    # the top face of a stone group on the plan, as a polygon on paper
    def plan_hatch(vp, top)
      g = top[:ent]
      faces = g.entities.grep(Sketchup::Face).select { |f| f.normal.z > 0.99 }
      f = faces.max_by(&:area) or return
      pts = f.outer_loop.vertices.map { |v| vp.model_to_paper_point(v.position.transform(g.transformation)) }
      hatch(pts)
    end

    # ---------------------------------------------------------------- key sheets (numbers = order CSV rows)
    def bubble(q, label, taken, red = false)
      d = 0.21
      q = Geom::Point2d.new(q.x, q.y)
      8.times { break unless taken.any? { |t| (t.x - q.x).abs < d && (t.y - q.y).abs < d }; q = Geom::Point2d.new(q.x, q.y + d + 0.02) }
      taken << q
      @l_key = nil if @l_key && @l_key.document != @doc rescue nil
      @l_key ||= @doc.layers.add('Cabinet numbers', false)
      e = Layout::Ellipse.new(Geom::Bounds2d.new(q.x - d / 2, q.y - d / 2, d, d))
      ink = red ? RED : INK_C # custom / to-quote rows in red (Andriy 2026-10-04)
      st = Layout::Style.new; st.stroked = true; st.stroke_width = red ? 0.75 : 0.5; st.stroke_color = color(ink)
      st.solid_filled = true; st.fill_color = Sketchup::Color.new(255, 255, 255)
      e.style = st
      add(e, @l_key)
      t = text(label.to_s, q.x, q.y - 0.055, @l_key, size: 6.5, font: MONO, c: ink, align: :center)
      @bubbles = (@bubbles || 0) + 1
      t
    end

    def page_key_plan(skp, code, scene, extent)
      next_page('CABINET KEY - PLAN'); header(SCALE_HALF); sheet_code(code)
      zx, zy, zw, zh = work_zone
      xa, xb, ya, yb = extent
      vp = viewport(skp, scene, zx, zy, zw, zh, scale: 1.0 / 24)
      a = vp.model_to_paper_point(P.(xa, ya)); b = vp.model_to_paper_point(P.(xb, yb))
      w = (b.x - a.x).abs; h = (b.y - a.y).abs
      vp.transform!(Geom::Transformation2d.new([1, 0, 0, 1, zx + (zw - w) / 2 - [a.x, b.x].min, zy + (zh - h) / 2 - [a.y, b.y].min]))
      vp.render if vp.render_needed?
      taken = []
      @boxes.select { |o| o[:z0] < 200 }.sort_by { |o| o[:row] }.each do |o|
        bubble(vp.model_to_paper_point(P.((o[:x0] + o[:x1]) / 2, (o[:y0] + o[:y1]) / 2, o[:z1])), o[:row], taken, Array(@custom_rows).include?(o[:row]))
      end
      Array(@extra_marks).each { |mk| bubble(vp.model_to_paper_point(P.(mk[:x], mk[:y], mk[:z])), mk[:label], taken, true) }
      text('Numbers = ITEM in the cabinet schedule, the custom list and the order CSV. Floor-standing units, tall units and the island; wall units on the next sheet. RED = custom / to quote.',
           WX, WY + WH - LABEL_GAP - LABEL_H - 0.18, @l_sheet, size: 8, c: INK2)
      view(WX, WY, WW, WH, 1, code, 'CABINET KEY - PLAN', :half, placeholder: false)
      @index << [code, 'CABINET KEY - PLAN']
    end

    # several elevations, small, every body numbered; cells [[scene, title, objs, axis, x, y, w, h]]
    def page_key_elevations(skp, code, cells)
      next_page('CABINET KEY - ELEVATIONS'); header(NTS); sheet_code(code)
      taken = []
      cells.each_with_index do |(scene, title, objs, axis, x, y, w, h), n|
        zh = h - LABEL_GAP - LABEL_H
        a0k, a1k = axis == :x ? %i[x0 x1] : %i[y0 y1]
        dk = axis == :x ? :y : :x
        depth = objs.map { |o| (o[:"#{dk}0"] + o[:"#{dk}1"]) / 2 }.sum / objs.size
        p3 = ->(am, zm) { axis == :x ? Geom::Point3d.new(am / 25.4, depth / 25.4, zm / 25.4) : Geom::Point3d.new(depth / 25.4, am / 25.4, zm / 25.4) }
        vp = viewport(skp, scene, x, y, w, zh, scale: 1.0 / 48)
        amin = objs.map { |o| o[a0k] }.min; amax = objs.map { |o| o[a1k] }.max; zmax = objs.map { |o| o[:z1] }.max
        pa = vp.model_to_paper_point(p3.(amin, 0)); pb = vp.model_to_paper_point(p3.(amax, zmax))
        cw = (pb.x - pa.x).abs; ch = (pb.y - pa.y).abs
        vp.transform!(Geom::Transformation2d.new([1, 0, 0, 1, x + (w - cw) / 2 - [pa.x, pb.x].min, y + (zh - ch) / 2 - [pa.y, pb.y].min]))
        c1 = vp.model_to_paper_point(p3.(amin - 60, -20)); c2 = vp.model_to_paper_point(p3.(amax + 60, zmax + 120))
        vp.clip_mask = Layout::Rectangle.new(Geom::Bounds2d.new([c1.x, c2.x].min, [c1.y, c2.y].min, (c2.x - c1.x).abs, (c2.y - c1.y).abs))
        vp.render if vp.render_needed?
        objs.sort_by { |o| o[:row] }.each do |o|
          bubble(vp.model_to_paper_point(p3.((o[a0k] + o[a1k]) / 2, (o[:z0] + o[:z1]) / 2)), o[:row], taken, Array(@custom_rows).include?(o[:row]))
        end
        Array(@extra_marks).select { |mk| Array(mk[:scenes]).include?(scene) }.each do |mk|
          bubble(vp.model_to_paper_point(p3.(axis == :x ? mk[:x] : mk[:y], mk[:z])), mk[:label], taken, true)
        end
        view(x, y, w, h, n + 1, code, title, :nts, placeholder: false)
      end
      @index << [code, 'CABINET KEY - ELEVATIONS']
    end

    # ---------------------------------------------------------------- pages
    def work_zone
      [WX, WY, WW, WH - LABEL_GAP - LABEL_H]
    end

    def page_elevation(skp, name, code, view_title, scene, objs, axis, tops)
      next_page(name); header(SCALE_HALF); sheet_code(code)
      begin
        elevation(skp, scene, objs, axis, work_zone, tops: tops)
      rescue RuntimeError => e
        raise unless e.message.start_with?('STOP')
        (@doc.remove_entity(@cur_vp) rescue nil)
        zx, zy, zw, zh = work_zone
        text(e.message, zx + zw / 2, zy + zh / 2, @l_sheet, size: 10, font: MONO, c: ACCENT, align: :center)
        @log << e.message; @stops << e.message
      end
      view(WX, WY, WW, WH, 1, code, view_title, :half, placeholder: false)
      @index << [code, name]
    end

    def page_plan(skp, code, scene, extent)
      next_page('TOP VIEW'); header(SCALE_HALF); sheet_code(code)
      zx, zy, zw, zh = work_zone
      xa, xb, ya, yb = extent # mm, what the plan must show
      vp = viewport(skp, scene, zx, zy, zw, zh, scale: 1.0 / 24)
      p = ->(x, y) { vp.model_to_paper_point(Geom::Point3d.new(x / 25.4, y / 25.4, 900 / 25.4)) }
      a = p.(xa, ya); b = p.(xb, yb)
      w = (b.x - a.x).abs; h = (b.y - a.y).abs
      if w > zw || h > zh
        @doc.remove_entity(vp)
        msg = "STOP: plan does not fit at 1/2\": #{w.round(2)} x #{h.round(2)} in, window #{zw.round(2)} x #{zh.round(2)} - scale is Andriy's decision"
        text(msg, zx + zw / 2, zy + zh / 2, @l_sheet, size: 12, font: MONO, c: ACCENT, align: :center)
        @log << msg; @stops << msg
      else
        vp.transform!(Geom::Transformation2d.new([1, 0, 0, 1, zx + (zw - w) / 2 - [a.x, b.x].min, zy + (zh - h) / 2 - [a.y, b.y].min]))
        vp.render if vp.render_needed?
        @tops.each { |t| plan_hatch(vp, t) }
        Array(@plan_notes).each { |txt, x, y| q = vp.model_to_paper_point(P.(x, y)); note_text(txt, q.x, q.y) }
        @log << "plan: #{w.round(2)} x #{h.round(2)} in of #{zw.round(2)} x #{zh.round(2)}"
      end
      view(WX, WY, WW, WH, 1, code, 'TOP VIEW', :half, placeholder: false)
      @index << [code, 'TOP VIEW']
    end

    # the dimensioned plan: same placement as page_plan, then runs and free dimensions
    # runs: [{ objs:, along:, face:, inward: }]; free: [[a3, b3, toward3]]
    def page_plan_dims(skp, code, scene, extent, runs, free)
      next_page('TOP VIEW - DIMENSIONS'); header(SCALE_HALF); sheet_code(code)
      zx, zy, zw, zh = work_zone
      xa, xb, ya, yb = extent
      vp = viewport(skp, scene, zx, zy, zw, zh, scale: 1.0 / 24)
      a = vp.model_to_paper_point(P.(xa, ya)); b = vp.model_to_paper_point(P.(xb, yb))
      w = (b.x - a.x).abs; h = (b.y - a.y).abs
      raise "STOP: dimension plan does not fit at 1/2\": #{w.round(2)} x #{h.round(2)}" if w > zw || h > zh
      vp.transform!(Geom::Transformation2d.new([1, 0, 0, 1, zx + (zw - w) / 2 - [a.x, b.x].min, zy + (zh - h) / 2 - [a.y, b.y].min]))
      vp.render if vp.render_needed?
      runs.each { |r| plan_run(vp, r[:objs], r[:along], r[:face], r[:inward]) }
      free.each { |a3, b3, t3| dim_toward(vp, a3, b3, ROW, t3) }
      view(WX, WY, WW, WH, 1, code, 'TOP VIEW - DIMENSIONS', :half, placeholder: false)
      @index << [code, 'TOP VIEW - DIMENSIONS']
    end

    # several elevations on one sheet, stacked or side by side: cells [[scene, title, objs, axis, tops, x, y, w, h]]
    def page_multi(skp, name, code, scale_text, cells, iso: nil)
      next_page(name); header(scale_text); sheet_code(code)
      n = 0
      cells.each do |scene, title, objs, axis, tops, x, y, w, h|
        n += 1
        begin
          elevation(skp, scene, objs, axis, [x, y, w, h - LABEL_GAP - LABEL_H], tops: tops)
        rescue RuntimeError => e
          raise unless e.message.start_with?('STOP')
          (@doc.remove_entity(@cur_vp) rescue nil)
          text(e.message, x + w / 2, y + h / 2, @l_sheet, size: 9, font: MONO, c: ACCENT, align: :center)
          @log << e.message; @stops << e.message
        end
        view(x, y, w, h, n, code, title, :half, placeholder: false)
      end
      if iso
        scene, title, x, y, w, h = iso
        n += 1
        v = viewport(skp, scene, x, y, w, h - LABEL_GAP - LABEL_H)
        v.render if v.render_needed?
        view(x, y, w, h, n, code, title, :nts, placeholder: false)
      end
      @index << [code, name]
    end

    def page_3d(skp, code, big, small)
      next_page('3D VIEWS'); header(NTS); sheet_code(code)
      bw = 7.6; sw = WW - bw - GUT; sh = (WH - GUT * (small.size - 1)) / small.size
      cells = [[big, WX, WY, bw, WH, 1]] + small.each_with_index.map { |sc, i| [sc, WX + bw + GUT, WY + i * (sh + GUT), sw, sh, i + 2] }
      cells.each do |(scene, title), x, y, w, h, n|
        v = viewport(skp, scene, x, y, w, h - LABEL_GAP - LABEL_H)
        v.render if v.render_needed?
        view(x, y, w, h, n, code, title, :nts, placeholder: false)
      end
      @index << [code, '3D VIEWS']
    end

    def page_cover(skp, scene)
      next_page('COVER', cover: true)
      cover(placeholder: false)
      v = viewport(skp, scene, 0.965, 2.20, 16.229 - 0.965, 6.65, render: :hybrid)
      v.render if v.render_needed?
      @index << ['G-000', 'COVER']
    end

    # ---------------------------------------------------------------- schedule
    def read_order(csv_path)
      items = []
      CSV.read(csv_path, headers: true).each do |r|
        if r['level'] == '0'
          items << { row: r['row'], code: r['code'].to_s, flag: r['flag'].to_s, desc: r['description'].to_s,
                     w: r['l_mm'].to_s, h: r['h_mm'].to_s, d: r['p_mm'].to_s, qty: r['qty'].to_s, kids: [] }
        elsif items.last
          items.last[:kids] << (r['code'].to_s.empty? ? r['description'].to_s : "#{r['code']} #{r['description']}")
        end
      end
      items
    end

    QUOTE_RX = /INCREASE|REDUCTION|SPECIAL ORDER|NOT PRINTED|REQUESTED/.freeze

    def finish_of(kids)
      f = kids.find { |k| k.start_with?('FINISH:') }
      return '' unless f
      return 'Oak veneer, col. 6, TBS' if f =~ /oak veneer/i
      return Regexp.last_match(1).strip if f =~ /(LM\d+ [A-Za-z ]+?)\s*(?:-|,|\(|$)/
      f.sub('FINISH:', '').strip.sub(/\Afront /, '').split(/ - |;/).first.strip
    end

    def notes_of(kids)
      kids.reject { |k| k.start_with?('FINISH:') }.map do |k|
        k.sub(/\AOPENING DIRECTION: (\w+).*/, 'hinge \1').sub(/:\s.*/, '')
      end.uniq.join(', ')
    end

    # a note on a drawing: 7 pt mono, centred, on a white box so hatch and swing lines do not run through it (set v1.4)
    def note_text(txt, x, y)
      lines = txt.split("\n")
      w = lines.map(&:length).max * 7 * 0.62 / 72 + 0.10
      h = lines.size * 7 * 1.25 / 72 + 0.06
      # own layer, created after the first viewport, so it sits ABOVE the views (Sheet is below them)
      @l_note = nil if @l_note && @l_note.document != @doc rescue nil
      @l_note ||= @doc.layers.add('Notes', false)
      rect(x - w / 2, y - 0.03, w, h, @l_note, fill: [255, 255, 255])
      text(txt, x, y, @l_note, size: 7, font: MONO, c: INK2, align: :center)
    end

    def fit(str, width_in, size)
      n = (width_in * 72 / (size * 0.58)).floor # 0.50 let caps-heavy notes run past the column (set v0.2)
      s = str.to_s.gsub(/\s+/, ' ').strip
      s.length > n ? "#{s[0, n - 1]}…" : s
    end

    def schedule_pages(items, title, code0, extra_note, color_rows: nil)
      k = WW / SCHEDULE_COLS.sum { |_, cw| cw }
      widths = SCHEDULE_COLS.map { |_, cw| cw * k }
      xs = widths.each_with_index.map { |_, i| WX + widths[0, i].sum }
      per = ((WY + WH - 0.45 - (WY + 0.24)) / SCHEDULE_ROW_H).floor
      pages = items.each_slice(per).to_a
      pages = [[]] if pages.empty?
      pages.each_with_index do |chunk, pi|
        code = format('A-7%02d', code0 + pi)
        name = pages.size > 1 ? "#{title} #{pi + 1}/#{pages.size}" : title
        next_page(name); header(NTS); sheet_code(code)
        y = WY
        SCHEDULE_COLS.each_with_index { |(h, _), i| text(h, xs[i] + 0.04, y + 0.02, @l_sheet, size: 7.5, font: MONO, c: HEAD) }
        y += 0.24
        line(WX, y, WX + WW, y, @l_sheet, w: 1.0)
        chunk.each do |it|
          vals = [it[:row], it[:code].empty? ? '—'.encode('UTF-8') : it[:code], it[:desc], it[:w], it[:h], it[:d], it[:qty], it[:finish], it[:notes]]
          vals.each_with_index do |v, i|
            size = i.zero? || i == 1 || (3..6).cover?(i) ? 8 : 7.5
            font = [0, 1, 3, 4, 5, 6].include?(i) ? MONO : SANS
            str = fit(v, widths[i] - 0.08, size)
            next if str.empty? # LayOut refuses an empty FormattedText
            text(str, xs[i] + 0.04, y + 0.08, @l_sheet, size: size, font: font, c: color_rows || INK_C)
          end
          y += SCHEDULE_ROW_H
          line(WX, y, WX + WW, y, @l_sheet, w: 0.5, c: ROWLINE)
        end
        text(extra_note, WX, WY + WH - 0.25, @l_sheet, size: 9, c: color_rows || INK2)
        @index << [code, name]
      end
      code0 + pages.size
    end

    # a generic table sheet: cols [[label, width_in]] (scaled to the work width), rows [[cell, ...]], a cell may hold
    # two lines ("a\nb"); red: ->(row) { true } paints a row red. Returns the next free code number.
    def table_pages(title, code0, cols, rows, note, red: nil, row_h: 0.40)
      k = WW / cols.sum { |_, w| w }
      widths = cols.map { |_, w| w * k }
      xs = widths.each_with_index.map { |_, i| WX + widths[0, i].sum }
      per = ((WY + WH - 0.45 - (WY + 0.24)) / row_h).floor
      pages = rows.each_slice(per).to_a
      pages = [[]] if pages.empty?
      pages.each_with_index do |chunk, pi|
        code = format('A-7%02d', code0 + pi)
        name = pages.size > 1 ? "#{title} #{pi + 1}/#{pages.size}" : title
        next_page(name); header(NTS); sheet_code(code)
        y = WY
        cols.each_with_index { |(h, _), i| text(h, xs[i] + 0.04, y + 0.02, @l_sheet, size: 7.5, font: MONO, c: HEAD) }
        y += 0.24
        line(WX, y, WX + WW, y, @l_sheet, w: 1.0)
        chunk.each do |r|
          ink = red && red.(r) ? RED : INK_C
          r.each_with_index do |cell, i|
            cell.to_s.split("\n").first(2).each_with_index do |ln, li|
              str = fit(ln, widths[i] - 0.08, 7.5)
              next if str.empty?
              text(str, xs[i] + 0.04, y + 0.05 + li * 0.15, @l_sheet, size: 7.5, font: i.zero? ? MONO : SANS, c: ink)
            end
          end
          y += row_h
          line(WX, y, WX + WW, y, @l_sheet, w: 0.5, c: ROWLINE)
        end
        text(note, WX, WY + WH - 0.25, @l_sheet, size: 8.5, c: INK2)
        @index << [code, name]
      end
      code0 + pages.size
    end

    def legend_page(code)
      next_page('LEGEND & GENERAL NOTES'); header(NTS); sheet_code(code)
      @legend_page = @page
      @index << [code, 'LEGEND & GENERAL NOTES']
    end

    # the sheet index needs the final list, so the legend is filled last
    def fill_legend(total, rev)
      @page = @legend_page
      w = (WW - GUT) / 2; x2 = WX + w + GUT
      label('SHEET INDEX', WX, WY, @l_sheet)
      y = WY + 0.22
      line(WX, y, WX + w, y, @l_sheet, w: 1.0)
      @index.each_with_index do |(code, name), i|
        text("#{i + 1} / #{total}", WX, y + 0.09, @l_sheet, size: 9, font: MONO)
        text(code, WX + 0.7, y + 0.09, @l_sheet, size: 9, font: MONO, c: INK2)
        text(name, WX + 1.5, y + 0.09, @l_sheet, size: 9)
        text(rev, WX + w, y + 0.09, @l_sheet, size: 9, font: MONO, c: INK2, align: :right)
        y += 0.30
        line(WX, y, WX + w, y, @l_sheet, w: 0.5, c: ROWLINE)
      end
      label('GENERAL NOTES', x2, WY, @l_sheet)
      line(x2, WY + 0.22, x2 + w, WY + 0.22, @l_sheet, w: 1.0)
      ny = WY + 0.36
      @notes.each_with_index do |n, i|
        text("#{i + 1}.", x2, ny, @l_sheet, size: 9, font: MONO)
        box_text(n, x2 + 0.32, ny, w - 0.32, 0.62, @l_sheet, size: 9)
        ny += 0.62
      end
    end
  end
end

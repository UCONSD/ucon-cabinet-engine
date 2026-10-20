# UCON MEP drawing set - MEP rough-in sheets for a GC, a set of its own (Andriy 2026-10-15: separate from the cabinet
# and demolition sets). Extends UCON::DrawingSet (ucon_drawing_set.rb): the same 11x17 template, viewports, line
# weights. The points come from tools/mep/mep_points.rb (rules + project data, tested by tools/test_mep.rb); this file
# only draws them: a symbol per point on the plan viewport, its ID beside it, notes on white boxes.
# Runs inside SketchUp. Reads the model, never writes it. Writes one new .layout and its .pdf.
require 'json'
load File.join(__dir__, 'ucon_drawing_set.rb')
load File.join(__dir__, '..', 'mep', 'mep_points.rb')

module UCON
  module DrawingSet
    MEP_SYM_D = 0.11   # in, symbol size on paper
    MEP_LAB_OFF = 0.24 # in, symbol centre to label centre
    MEP_LAB_STEP = 0.24
    MEP_DIRS = { 'N' => [0, 1], 'S' => [0, -1], 'E' => [1, 0], 'W' => [-1, 0] }.freeze

    def mep_layer
      @l_mep = nil if @l_mep && @l_mep.document != @doc rescue nil
      @l_mep ||= @doc.layers.add('MEP', false)
    end

    # boxes from collect (symbol keys) -> the string-keyed boxes mep_points.rb reads
    # model given: 'back' = world direction of the carcass back ('x+' 'x-' 'y+' 'y-'), the instance's local +y (the
    # engine builds y = 0 at the front, depth along +y; probe 746). Blocking goes only where a back is on the wall.
    def mep_boxes(model = nil)
      out = @boxes.map do |b|
        h = { 'code' => b[:code], 'cls' => b[:cls], 'x0' => b[:x0], 'x1' => b[:x1], 'y0' => b[:y0], 'y1' => b[:y1], 'z0' => b[:z0], 'z1' => b[:z1] }
        if model && (e = model.find_entity_by_id(b[:id]))
          v = e.transformation.yaxis
          h['back'] = v.x.abs > v.y.abs ? (v.x > 0 ? 'x+' : 'x-') : (v.y > 0 ? 'y+' : 'y-')
        end
        h
      end
      # sink marks (core 1.9.31): the plumbing of a sink role follows them
      sinks = Array(@sinks).map do |s|
        { 'code' => 'SINK-MARK', 'cls' => 'sink', 'x0' => s[:x0], 'x1' => s[:x1], 'y0' => s[:y0], 'y1' => s[:y1], 'z0' => s[:z0], 'z1' => s[:z1] }
      end
      out + sinks
    end

    # ---------------------------------------------------------------- units
    # Inches to the nearest 1/4" (Andriy 2026-10-15, kitchen); 12" and up as feet-inches, as a US contractor reads them.
    def in_q(mmv)
      q = (mmv.to_f / 25.4 * 4).round
      neg = q.negative?; q = q.abs
      whole = q / 4; frac = q % 4
      fr = { 0 => '', 1 => ' 1/4', 2 => ' 1/2', 3 => ' 3/4' }[frac]
      t = if whole >= 12 then "#{whole / 12}'-#{whole % 12}#{fr}\"" else "#{whole}#{fr}\"" end
      t = t.sub(/\A0 /, '') if whole.zero? && !fr.empty?
      neg ? "-#{t}" : t
    end

    def mep_len(mmv) = @mep_in ? in_q(mmv) : mmv.round.to_s
    def dim_text(mmv) = @mep_in ? in_q(mmv) : d1(mmv)

    # ---------------------------------------------------------------- symbols
    # US residential plan symbols (NECA 100 / common practice, recon 2026-10-15): duplex receptacle = circle with two
    # parallel lines; GFCI = duplex + "GFCI"; 240 V receptacle = circle with three lines; split-wired (half switched)
    # = duplex with half the circle filled; junction box / hardwired = circle with "J"; gas valve = bow-tie; plumbing
    # stub = square; duct = circle to scale (plan). dir: paper unit vector from the wall into the room.
    def mep_symbol(sys, x, y, sym: nil, dir: [0, 1])
      d = MEP_SYM_D; l = mep_layer; r = d / 2
      px, py = -dir[1], dir[0] # along the wall
      lines = lambda do |n|
        offs = n == 2 ? [-0.022, 0.022] : [-0.032, 0, 0.032]
        offs.each do |o|
          ax = x + px * o; ay = y + py * o
          line(ax - dir[0] * r * 1.45, ay - dir[1] * r * 1.45, ax + dir[0] * r * 1.45, ay + dir[1] * r * 1.45, l, w: 0.5)
        end
      end
      case sym
      when 'DUP', 'GFCI'
        circle(x, y, d, l, sw: 0.6); lines.(2)
      when 'SPLIT'
        circle(x, y, d, l, sw: 0.6); lines.(2)
        e = Layout::Ellipse.new(Geom::Bounds2d.new(x - r * 0.55, y - r * 0.55, r * 1.1, r * 1.1))
        st = Layout::Style.new; st.solid_filled = true; st.fill_color = color(INK); st.stroked = false; e.style = st; add(e, l)
      when 'R240'
        circle(x, y, d, l, sw: 0.6); lines.(3)
      when 'J', 'J240', 'LED'
        circle(x, y, d, l, sw: 0.6)
        text('J', x, y - 0.052, l, size: 6, font: MONO, align: :center)
      when 'S'
        # wall switch: the letter S (US plan practice)
        text('S', x, y - 0.075, l, size: 9, font: MONO, c: INK, bold: true, align: :center)
      when 'LV'
        # low-voltage cable outlet: small circle with LV
        circle(x, y, d, l, sw: 0.5)
        text('LV', x, y - 0.04, l, size: 4.2, font: MONO, align: :center)
      when 'G'
        a = d * 0.6
        line(x - a, y - a / 2, x + a, y + a / 2, l, w: 0.6); line(x + a, y + a / 2, x + a, y - a / 2, l, w: 0.6)
        line(x + a, y - a / 2, x - a, y + a / 2, l, w: 0.6); line(x - a, y + a / 2, x - a, y - a / 2, l, w: 0.6)
      when 'DUCT'
        rect(x - r, y - r, d, d, l, stroke: INK, sw: 0.75)
        line(x - r, y - r, x + r, y + r, l, w: 0.5); line(x - r, y + r, x + r, y - r, l, w: 0.5)
      else
        rect(x - r, y - r, d, d, l, stroke: INK, sw: 0.75, fill: [255, 255, 255])
      end
    end

    # paper direction of a model direction at a point (the plan may be rotated on the sheet)
    def mep_paper_dir(vp, x, y, dir)
      a = vp.model_to_paper_point(P.(x, y)); b = vp.model_to_paper_point(P.(x + dir[0] * 100, y + dir[1] * 100))
      dx = b.x - a.x; dy = b.y - a.y; n = Math.sqrt(dx * dx + dy * dy)
      [dx / n, dy / n]
    end

    # symbols + IDs; labels that would land on top of each other step outward
    def mep_plan_marks(vp, pts)
      placed = []
      pts.select { |p| p['x'] }.each do |p|
        q = vp.model_to_paper_point(P.(p['x'], p['y']))
        dir = mep_paper_dir(vp, p['x'], p['y'], MEP_DIRS[p['lab'] || 'S'])
        if p['sym'] == 'DUCT' && (dd = p['req'].to_s[/(\d+)" round|(\d+)" rigid/] && p['req'].to_s[/(\d+)"/, 1].to_f * 25.4)
          # the duct to scale (Andriy 2026-10-15): its real diameter on the plan, crossed = going down
          rr = vp.model_to_paper_point(P.(p['x'] + dd / 2, p['y'])).distance(q)
          circle(q.x, q.y, 2 * rr, mep_layer, sw: 0.75)
          line(q.x - rr * 0.7, q.y - rr * 0.7, q.x + rr * 0.7, q.y + rr * 0.7, mep_layer, w: 0.4)
          line(q.x - rr * 0.7, q.y + rr * 0.7, q.x + rr * 0.7, q.y - rr * 0.7, mep_layer, w: 0.4)
        else
          mep_symbol(p['sys'], q.x, q.y, sym: p['sym'], dir: dir)
        end
        off = MEP_LAB_OFF
        lx = ly = nil
        8.times do
          lx = q.x + dir[0] * off; ly = q.y + dir[1] * off
          break if placed.none? { |px, py| (px - lx).abs < 0.80 && (py - ly).abs < 0.24 }
          off += MEP_LAB_STEP
        end
        placed << [lx, ly]
        line(q.x + dir[0] * MEP_SYM_D / 2, q.y + dir[1] * MEP_SYM_D / 2, lx - dir[0] * 0.06, ly - dir[1] * 0.06, mep_layer, w: 0.35, c: INK2) if off > MEP_LAB_OFF
        text(p['id'], lx, ly - 0.09, mep_layer, size: 7, font: MONO, c: INK, align: :center)
        text(p['short'].to_s, lx, ly + 0.03, mep_layer, size: 5.5, font: MONO, c: INK2, align: :center) unless p['short'].to_s.empty?
      end
      placed.size
    end

    # ---------------------------------------------------------------- ordinate dimensions
    # Variant A (Andriy 2026-10-15): one base line, 0 at the reference (window CL, a wall, the floor), every feature its
    # CUMULATIVE distance from the reference, left and right separately (no sign). Paper inches throughout.
    # base: Point2d on the base line at the reference; u: unit along the base; n: unit normal away from the drawing
    # (the text side); feats: [[Point2d feature, mm, tag]] - an extension line runs from the feature to the base unless
    # ext: false; zero: [Point2d, tag] - the reference itself.
    MEP_ORD_GAP = 0.105  # in, min. distance between two texts along the base
    MEP_ORD_SIZE = 6.5

    def mep_ord_text(str, x, y, n, layer)
      ft = Layout::FormattedText
      rot = n[0].abs < n[1].abs # base runs horizontally on paper: text turned 90 deg, read from the right
      anchor = if rot then (n[1] > 0 ? ft::ANCHOR_TYPE_CENTER_RIGHT : ft::ANCHOR_TYPE_CENTER_LEFT)
               else (n[0] > 0 ? ft::ANCHOR_TYPE_CENTER_LEFT : ft::ANCHOR_TYPE_CENTER_RIGHT) end
      t = ft.new(str, Geom::Point2d.new(x, y), anchor)
      t.style = st(size: MEP_ORD_SIZE, font: MONO, c: INK, align: (anchor == ft::ANCHOR_TYPE_CENTER_LEFT ? :left : :right))
      add(t, layer)
      return t unless rot
      pivot = Geom::Point2d.new(x, y)
      turn = lambda do |ang|
        tr = begin
          Geom::Transformation2d.rotation(pivot, ang)
        rescue StandardError
          c = Math.cos(ang); s = Math.sin(ang)
          Geom::Transformation2d.new([c, s, -s, c, x - c * x + s * y, y - s * x - c * y])
        end
        t.transform!(tr)
      end
      turn.(-Math::PI / 2)
      b = t.bounds
      @ord_rot_fail ||= "text not turned: #{b.width.round(3)} x #{b.height.round(3)}" if b.width > b.height
      cyb = b.upper_left.y + b.height / 2
      turn.(Math::PI) if (cyb - y) * n[1] < 0 # extends to the wrong side - turn it over
      t
    end

    def mep_ordinate(base, u, n, feats, zero: nil, ext: true)
      l = mep_layer
      fmt = ->(v) { @mep_in ? in_q(v.abs) : v.abs.round.to_s }
      s_of = ->(q) { (q.x - base.x) * u[0] + (q.y - base.y) * u[1] }
      at = ->(s, k = 0.0) { [base.x + u[0] * s + n[0] * k, base.y + u[1] * s + n[1] * k] }
      items = feats.map { |q, v, tag| { s: s_of.(q), q: q, v: v, tags: [tag].compact } }
      items << { s: 0.0, q: zero[0], v: 0.0, tags: [zero[1]].compact, zero: true } if zero
      # one tick per position; tags of features at the same position are joined
      merged = []
      items.sort_by { |i| i[:s] }.each do |i|
        if (m = merged.last) && (i[:s] - m[:s]).abs < 0.01 && (i[:v].abs - m[:v].abs).abs < 1.0
          m[:tags] |= i[:tags]; m[:qs] << i[:q]; m[:zero] ||= i[:zero]
        else
          merged << i.merge(qs: [i[:q]])
        end
      end
      return 0 if merged.empty?
      # base line, with a little run-out at both ends
      lo = [merged.first[:s], 0.0].min - 0.08; hi = [merged.last[:s], 0.0].max + 0.08
      line(*at.(lo), *at.(hi), l, w: 0.35, c: INK)
      # texts spread apart where they would touch, keeping their order
      ts = merged.map { |m| m[:s] }
      30.times do
        moved = false
        (0...ts.size - 1).each do |k|
          d = ts[k + 1] - ts[k]
          next if d >= MEP_ORD_GAP - 1e-6
          push = (MEP_ORD_GAP - d) / 2; ts[k] -= push; ts[k + 1] += push; moved = true
        end
        break unless moved
      end
      merged.each_with_index do |m, k|
        bx, by = at.(m[:s])
        if ext
          m[:qs].compact.each do |q|
            dn = (q.x - base.x) * n[0] + (q.y - base.y) * n[1] # negative: on the drawing side
            next if dn > -0.05
            line(q.x + n[0] * 0.05, q.y + n[1] * 0.05, *at.(s_of.(q), 0.04), l, w: 0.25, c: INK2)
          end
        end
        # tick: a short slash across the base
        dx = (u[0] + n[0]) * 0.035; dy = (u[1] + n[1]) * 0.035
        line(bx - dx, by - dy, bx + dx, by + dy, l, w: 0.6, c: INK)
        # jog out to the text when it had to move
        tx, ty = at.(ts[k], 0.13)
        if (ts[k] - m[:s]).abs > 0.005
          ex, ey = at.(m[:s], 0.05)
          line(bx, by, ex, ey, l, w: 0.25, c: INK2)
          line(ex, ey, *at.(ts[k], 0.10), l, w: 0.25, c: INK2)
        else
          line(bx, by, *at.(ts[k], 0.10), l, w: 0.25, c: INK2)
        end
        str = m[:zero] ? '0' : fmt.(m[:v])
        tg = m[:tags].sort_by { |t| t =~ /\A[A-Z]+\d+\z/ ? [0, t[/\A[A-Z]+/], t[/\d+/].to_i] : [1, t, 0] }
        str += "  #{tg.join(', ')}" unless tg.empty?
        mep_ord_text(str, tx, ty, n, l)
      end
      @ord_count = (@ord_count || 0) + merged.size
      merged.size
    end

    def mep_unit(a, b)
      dx = b.x - a.x; dy = b.y - a.y; d = Math.sqrt(dx * dx + dy * dy)
      [dx / d, dy / d]
    end

    # ---------------------------------------------------------------- cover: MEP axonometric
    # Andriy 2026-10-15: the cover of the MEP set shows the MEP, not the model. Scene '20 MEP ISO' (grey cabinets, raster -
    # vector ignores the grey) with every point projected from 3D: a coloured mark per system, its ID, a riser down
    # through the floor (all feeds come from below), electrical tails flagged, the duct to the tech room, blocking
    # bands on the walls, plumbing zones. blocks: [{ 'a0', 'a1', 'cl', 'along' => 'x'/'y', 'at' => wall mm }]
    MEP_SYS_C = { 'E' => [0xB7, 0x4B, 0x22], 'L' => [0xB7, 0x4B, 0x22], 'P' => [0x1F, 0x5F, 0x9E], 'W' => [0x1F, 0x5F, 0x9E],
                  'G' => [0xB8, 0x8A, 0x00], 'M' => [0x2E, 0x7D, 0x32], 'B' => [0x8A, 0x8A, 0x84] }.freeze

    def mep_dot(x, y, d, c, l)
      e = Layout::Ellipse.new(Geom::Bounds2d.new(x - d / 2, y - d / 2, d, d))
      s = Layout::Style.new; s.solid_filled = true; s.fill_color = color(c); s.stroked = true
      s.stroke_color = color([255, 255, 255]); s.stroke_width = 0.5; e.style = s
      add(e, l)
    end

    def mep_page_cover(skp, scene, pts, zones: [], blocks: [], ducts: [], floor_drop: 300, footprints: [], bars: [], routes: [])
      next_page('COVER', cover: true)
      cover(placeholder: false)
      vp = viewport(skp, scene, 0.965, 2.20, 16.229 - 0.965, 6.65, render: :raster)
      vp.render if vp.render_needed?
      l = mep_layer
      pp = ->(x, y, z) { vp.model_to_paper_point(P.(x, y, z)) }
      # where the cabinets will stand: their footprints on the floor, thin and light (the cabinets themselves are off)
      footprints.each do |x0, x1, y0, y1|
        q = [[x0, y0], [x1, y0], [x1, y1], [x0, y1]].map { |x, y| pp.(x, y, 0) }
        q.each_with_index { |a, i| b = q[(i + 1) % 4]; line(a.x, a.y, b.x, b.y, l, w: 0.35, c: [0xA8, 0xA8, 0xA4]) }
      end
      # blocking: a band on the wall at its axis
      blocks.each do |b|
        a = b['along'] == 'x' ? pp.(b['a0'], b['at'], b['cl']) : pp.(b['at'], b['a0'], b['cl'])
        z = b['along'] == 'x' ? pp.(b['a1'], b['at'], b['cl']) : pp.(b['at'], b['a1'], b['cl'])
        line(a.x, a.y, z.x, z.y, l, w: 3.0, c: MEP_SYS_C['B'])
        text("#{b['id']} 2x6", (a.x + z.x) / 2, (a.y + z.y) / 2 - 0.16, l, size: 5.5, font: MONO, c: INK2, align: :center)
      end
      # blocking by others (anti-tip 2x4): its axis, brown, with its id
      bars.each do |br|
        xm = (br[:x0] + br[:x1]) / 2.0; zm = (br[:z0] + br[:z1]) / 2.0
        a = pp.(xm, br[:y0], zm); z = pp.(xm, br[:y1], zm)
        line(a.x, a.y, z.x, z.y, l, w: 2.5, c: [0x8A, 0x5A, 0x2B])
        text("#{br[:id]} 2x4 BY CABINET INSTALLERS", (a.x + z.x) / 2, (a.y + z.y) / 2 - 0.16, l, size: 5.5, font: MONO, c: [0x8A, 0x5A, 0x2B], align: :center)
      end
      # routes in 3D: { pts: [[x, y, z], ...], c: rgb, label: } - dashed (ice maker line under the floor, LV cable)
      routes.each do |ro|
        q = ro[:pts].map { |x, y, z| pp.(x, y, z) }
        q.each_cons(2) { |u, v| line(u.x, u.y, v.x, v.y, l, w: 1.0, c: ro[:c], dash: true) }
        if ro[:label]
          k = ro[:at] || 0; u = q[k]; v = q[k + 1]
          text(ro[:label], (u.x + v.x) / 2, (u.y + v.y) / 2 + 0.04, l, size: 5.5, font: MONO, c: ro[:c], align: :center)
        end
      end
      # plumbing zones: the rectangle in the wall plane
      zones.each do |zn|
        xs = (zn['x1'] - zn['x0']) >= (zn['y1'] - zn['y0'])
        ym = (zn['y0'] + zn['y1']) / 2.0; xm = (zn['x0'] + zn['x1']) / 2.0
        cs = if xs then [[zn['x0'], ym], [zn['x1'], ym], [zn['x1'], ym], [zn['x0'], ym]]
             else [[xm, zn['y0']], [xm, zn['y1']], [xm, zn['y1']], [xm, zn['y0']]] end
        q = cs.zip([zn['z0'], zn['z0'], zn['z1'], zn['z1']]).map { |(x, y), z| pp.(x, y, z) }
        q.each_with_index { |a, i| b = q[(i + 1) % 4]; line(a.x, a.y, b.x, b.y, l, w: 0.6, c: MEP_SYS_C['P'], dash: true) }
      end
      # ducts: { x:, y:, z0:, z1: } a thick line down through the floor
      ducts.each do |du|
        a = pp.(du[:x], du[:y], du[:z1]); b = pp.(du[:x], du[:y], du[:z0])
        line(a.x, a.y, b.x, b.y, l, w: 4.0, c: MEP_SYS_C['M'])
      end
      placed = []
      n = 0
      vis = pts.select { |p| p['x'] && p['z'] }
      dots = vis.map { |p| q = pp.(p['x'], p['y'], p['z']); [q.x, q.y] }
      vis.each do |p|
        c = MEP_SYS_C[p['sys']] || INK
        q = pp.(p['x'], p['y'], p['z'])
        f = pp.(p['x'], p['y'], -floor_drop)
        line(q.x, q.y, f.x, f.y, l, w: 0.6, c: c) unless p['sys'] == 'M'
        mep_dot(q.x, q.y, 0.075, c, l)
        lab = p['id'] + (p['tail_ft'] ? "  #{p['tail_ft']}' TAIL" : '')
        lx = q.x + 0.06; ly = q.y - 0.17
        lw = lab.size * 0.055
        12.times do
          clear = placed.none? { |px, py, pw| ly > py - 0.12 && ly < py + 0.12 && lx < px + pw && lx + lw > px } &&
                  dots.none? { |dx, dy| (dx - q.x).abs + (dy - q.y).abs > 0.001 && dx > lx - 0.05 && dx < lx + lw + 0.05 && dy > ly - 0.05 && dy < ly + 0.15 }
          break if clear
          ly -= 0.12
        end
        placed << [lx, ly, lab.size * 0.055]
        line(q.x, q.y, lx, ly + 0.1, l, w: 0.3, c: c) if ly < q.y - 0.18
        text(lab, lx, ly, l, size: 6, font: MONO, c: c)
        n += 1
      end
      # key
      kx = 1.10; ky = 7.95
      [['E', 'ELECTRICAL / LIGHTING'], ['P', 'PLUMBING (dashed: PLUMBING ZONE)'], ['G', 'GAS'], ['M', 'DUCT / MAKE-UP AIR'], ['B', '2x6 BLOCKING']].each_with_index do |(k, t), i|
        y = ky + i * 0.16
        k == 'B' ? line(kx - 0.05, y + 0.06, kx + 0.05, y + 0.06, l, w: 3.0, c: MEP_SYS_C['B']) : mep_dot(kx, y + 0.06, 0.075, MEP_SYS_C[k], l)
        text(t, kx + 0.12, y, l, size: 6, font: MONO, c: INK2)
      end
      text('Lines down = feeds from BELOW (tech room). TAIL = coiled electrical tail out of the floor. Grey on the floor = cabinet footprints.', kx - 0.05, ky + 5 * 0.16 + 0.02, l, size: 6, font: MONO, c: INK2)
      @index << ['G-000', 'COVER - MEP AXONOMETRIC']
      @log << "G-000: MEP axonometric, #{n} points, #{blocks.size} blocking, #{zones.size} zones"
    end

    # M-101: the plan scene at 1/2", MEP symbols over it. extent [xa, xb, ya, yb] mm.
    # plan dimensions (Andriy 2026-10-15: the top view needs its tie-in dimensions). groups: { along: :x/:y, at: mm (the
    # line of the points), ref: mm, stops: [mm], toward: [x, y] model point on the side of the dimension line, off: in };
    # locate: [[a3, b3, toward3, off]] single dimensions.
    def mep_plan_dims(vp, groups, locate)
      # ABOVE the viewport: a raster view is opaque, dimensions on the start-up 'Dimensions' layer vanish under it
      @l_dims_top = nil if @l_dims_top && @l_dims_top.document != @doc rescue nil
      @l_dims_top ||= @doc.layers.add('Dimensions (over views)', false)
      keep = @l_dims; @l_dims = @l_dims_top
      # ordinate (variant A): 0 at the reference, each stop its distance from it; stops: mm or [mm, tag]
      groups.each do |g|
        pt = ->(a) { g[:along] == :x ? P.(a, g[:at]) : P.(g[:at], a) }
        o = vp.model_to_paper_point(pt.(g[:ref]))
        u = mep_unit(o, vp.model_to_paper_point(pt.(g[:ref] + 1000)))
        tw = vp.model_to_paper_point(P.(*g[:toward]))
        n = [-u[1], u[0]]
        n = [u[1], -u[0]] if (tw.x - o.x) * n[0] + (tw.y - o.y) * n[1] < 0
        base = Geom::Point2d.new(o.x + n[0] * g[:off], o.y + n[1] * g[:off])
        # a stop: mm, or [mm, tag], or [mm, tag, the other coordinate of the feature] when it is off the line `at`
        feats = g[:stops].map do |st|
          a, tag, oc = Array(st)
          q = oc ? (g[:along] == :x ? P.(a, oc) : P.(oc, a)) : pt.(a)
          [vp.model_to_paper_point(q), a - g[:ref], tag]
        end
        k = mep_ordinate(base, u, n, feats, zero: [o, g[:zero]])
        @log << "plan ordinate #{g[:along]} @#{g[:at].round} from #{g[:ref].round}: #{k} ticks"
      end
      locate.each { |a3, b3, t3, off| dim_toward(vp, a3, b3, off, t3) }
    ensure
      @l_dims = keep if keep
    end

    def mep_page_plan(skp, code, title, scene, extent, pts, notes, render: :vector, dims: nil, after: nil)
      next_page(title); header(@mep_scale || SCALE_HALF); sheet_code(code)
      zx, zy, zw, zh = work_zone
      xa, xb, ya, yb = extent
      vp = viewport(skp, scene, zx, zy, zw, zh, scale: 1.0 / 24, render: render)
      a = vp.model_to_paper_point(P.(xa, ya)); b = vp.model_to_paper_point(P.(xb, yb))
      w = (b.x - a.x).abs; h = (b.y - a.y).abs
      raise "STOP: MEP plan does not fit at 1/2\": #{w.round(2)} x #{h.round(2)} in, window #{zw.round(2)} x #{zh.round(2)}" if w > zw || h > zh
      vp.transform!(Geom::Transformation2d.new([1, 0, 0, 1, zx + (zw - w) / 2 - [a.x, b.x].min, zy + (zh - h) / 2 - [a.y, b.y].min]))
      vp.render if vp.render_needed?
      n = mep_plan_marks(vp, pts)
      mep_plan_dims(vp, dims[:groups], dims[:locate]) if dims
      after.call(vp) if after
      notes.each { |txt, x, y| q = vp.model_to_paper_point(P.(x, y)); note_text(txt, q.x, q.y) }
      view(WX, WY, WW, WH, 1, code, title, :half, placeholder: false)
      @index << [code, title]
      @log << "#{code}: #{n} symbols, #{notes.size} notes, plan #{w.round(2)} x #{h.round(2)} in"
    end

    # ---------------------------------------------------------------- elevations
    # One MEP elevation: the scene at 1/2" (raster - LayOut vector ignores the grey edge colour), blocking bands,
    # plumbing zones (a dimensioned rectangle per fixture, Andriy 2026-10-15), the points with ID + type / power,
    # a reference line, ordinate dimensions from it along the floor and heights from the floor at the right.
    # c: { scene:, axis: :x/:y, depth:, a0:, a1:, zmax:, pts: [], blocks: [], zones: [], ref: { at:, text: } }
    def mep_elevation(skp, c, zone)
      axis = c[:axis]; depth = c[:depth]
      p3 = lambda do |am, zm|
        axis == :x ? Geom::Point3d.new(am / 25.4, depth / 25.4, zm / 25.4) : Geom::Point3d.new(depth / 25.4, am / 25.4, zm / 25.4)
      end
      zx, zy, zw, zh = zone
      vp = viewport(skp, c[:scene], zx, zy, zw, zh, scale: 1.0 / 24, render: :raster)
      @cur_vp = vp
      a0 = c[:a0].to_f; a1 = c[:a1].to_f; zmax = c[:zmax].to_f
      pa = vp.model_to_paper_point(p3.(a0, 0)); pb = vp.model_to_paper_point(p3.(a1, zmax))
      right_end = vp.model_to_paper_point(p3.(a1, 0)).x > pa.x ? a1 : a0
      cw = (pb.x - pa.x).abs; ch = (pb.y - pa.y).abs
      need_w = cw + 3 * ROW + 2 * TEXT_ROOM + 0.6
      need_h = ch + 3 * ROW + 2 * TEXT_ROOM
      raise "STOP: #{c[:scene]} does not fit at 1/2\": #{need_w.round(2)} x #{need_h.round(2)} in, window #{zw.round(2)} x #{zh.round(2)}" if need_w > zw || need_h > zh
      left = [pa.x, pb.x].min; top = [pa.y, pb.y].min
      vp.transform!(Geom::Transformation2d.new([1, 0, 0, 1, zx + (zw - need_w) / 2 + TEXT_ROOM + 0.3 - left, zy + (zh - need_h) / 2 + TEXT_ROOM - top]))
      q1 = vp.model_to_paper_point(p3.(a0 - 60, (c[:zmin] || 0) - 20)); q2 = vp.model_to_paper_point(p3.(a1 + 60, zmax + 60))
      vp.clip_mask = Layout::Rectangle.new(Geom::Bounds2d.new([q1.x, q2.x].min, [q1.y, q2.y].min, (q2.x - q1.x).abs, (q2.y - q1.y).abs))
      vp.render if vp.render_needed?
      l = mep_layer
      # ducts to scale: { a: centre along, d: diameter, z0:, z1:, label: }
      Array(c[:ducts]).each do |du|
        u = vp.model_to_paper_point(p3.(du[:a] - du[:d] / 2.0, du[:z1])); v = vp.model_to_paper_point(p3.(du[:a] + du[:d] / 2.0, du[:z0]))
        rect([u.x, v.x].min, [u.y, v.y].min, (u.x - v.x).abs, (u.y - v.y).abs, l, stroke: INK, sw: 0.75)
        text(du[:label].sub(' DOWN TO ', " DOWN\nTO "), [u.x, v.x].max + 0.06, [u.y, v.y].max - 0.24, l, size: 6, font: MONO, c: INK2)
      end
      Array(c[:notes]).each { |txt, am, zm| q = vp.model_to_paper_point(p3.(am, zm)); note_text(txt, q.x, q.y) }
      am_of = ->(p) { axis == :x ? p['x'] : p['y'] }
      # blocking bands
      c[:blocks].each do |b|
        u = vp.model_to_paper_point(p3.(b['a0'], b['cl'] + b['h'] / 2.0)); v = vp.model_to_paper_point(p3.(b['a1'], b['cl'] - b['h'] / 2.0))
        x = [u.x, v.x].min; y = [u.y, v.y].min
        rect(x, y, (u.x - v.x).abs, (u.y - v.y).abs, l, stroke: INK2, sw: 0.5, fill: [0xE4, 0xE4, 0xE0])
        line(x, y + (u.y - v.y).abs / 2, x + (u.x - v.x).abs, y + (u.y - v.y).abs / 2, l, w: 0.35, c: INK2, dash: true)
        text("#{b['id']}  2x6 BLOCKING  CL #{mep_len(b['cl'])}", x + (u.x - v.x).abs - 0.04, y - 0.13, l, size: 6.5, font: MONO, c: INK2, align: :right)
      end
      # other blocking shown for information, by others (Andriy 2026-10-15: the anti-tip 2x4 over the tall wall stays
      # on our drawings, marked BY CABINET INSTALLERS): { id:, a0:, a1:, z0:, z1:, label:, hidden: } - dashed when it
      # sits behind what the view shows
      Array(c[:bars]).each do |br|
        u = vp.model_to_paper_point(p3.(br[:a0], br[:z1])); v = vp.model_to_paper_point(p3.(br[:a1], br[:z0]))
        x = [u.x, v.x].min; y = [u.y, v.y].min
        rect(x, y, (u.x - v.x).abs, [(u.y - v.y).abs, 0.03].max, l, stroke: [0x8A, 0x5A, 0x2B], sw: 0.75, fill: [0xEF, 0xE3, 0xD3], dash: br[:hidden])
        text("#{br[:id]}  #{br[:label]}", x + (u.x - v.x).abs / 2, y + [(u.y - v.y).abs, 0.03].max + 0.05, l, size: 6, font: MONO, c: [0x8A, 0x5A, 0x2B], align: :center)
      end
      # routes: { pts: [[along, z], ...], c: rgb, label:, at: index of the segment to label } - dashed polylines
      # (LV cable from the driver, the ice maker line)
      Array(c[:routes]).each do |ro|
        q = ro[:pts].map { |am, zm| vp.model_to_paper_point(p3.(am, zm)) }
        q.each_cons(2) { |u, v| line(u.x, u.y, v.x, v.y, l, w: 0.6, c: ro[:c], dash: true) }
        if ro[:label]
          k = ro[:at] || 0; u = q[k]; v = q[k + 1]
          text(ro[:label], (u.x + v.x) / 2 + 0.05, (u.y + v.y) / 2 - 0.12, l, size: 5.5, font: MONO, c: ro[:c])
        end
      end
      # plumbing zones
      zones = Array(c[:zones])
      zones.each do |zn|
        za0 = axis == :x ? zn['x0'] : zn['y0']; za1 = axis == :x ? zn['x1'] : zn['y1']
        u = vp.model_to_paper_point(p3.(za0, zn['z1'])); v = vp.model_to_paper_point(p3.(za1, zn['z0']))
        x = [u.x, v.x].min; y = [u.y, v.y].min
        rect(x, y, (u.x - v.x).abs, (u.y - v.y).abs, l, stroke: [0x1F, 0x5F, 0x9E], sw: 0.75, dash: true)
        text('PLUMBING ZONE', x + 0.03, y + (u.y - v.y).abs + 0.02, l, size: 5.5, font: MONO, c: [0x1F, 0x5F, 0x9E])
      end
      # reference line
      if (r = c[:ref])
        f = vp.model_to_paper_point(p3.(r[:at], 0)); t = vp.model_to_paper_point(p3.(r[:at], zmax))
        line(f.x, f.y, t.x, t.y, l, w: 0.35, c: ACCENT, dash: true)
        text(r[:text].upcase, t.x, t.y - 0.14, l, size: 6.5, font: MONO, c: ACCENT, align: :center)
      end
      fl = vp.model_to_paper_point(p3.(a0, 0))
      text('FIN. FLOOR 0', [fl.x, vp.model_to_paper_point(p3.(a1, 0)).x].min - 0.08, fl.y - 0.06, l, size: 6.5, font: MONO, c: INK2, align: :right)
      # points: symbol, then ID + type / power above it (two lines), stepped up when they would collide
      placed = []
      pts = c[:pts].select { |p| p['x'] }
      pts.each do |p|
        q = vp.model_to_paper_point(p3.(am_of.(p), p['z']))
        mep_symbol(p['sys'], q.x, q.y, sym: p['sym'], dir: [0, -1])
        off = 0.27; lx = q.x; ly = nil
        8.times do
          ly = q.y - off
          break if placed.none? { |px, py| (px - lx).abs < 0.80 && (py - ly).abs < 0.22 }
          off += 0.23
        end
        placed << [lx, ly]
        line(q.x, q.y - MEP_SYM_D / 2, lx, ly + 0.17, l, w: 0.35, c: INK2) if off > 0.27
        text(p['id'], lx, ly - 0.06, l, size: 6.5, font: MONO, c: INK, align: :center)
        text(p['short'].to_s, lx, ly + 0.05, l, size: 5.5, font: MONO, c: INK2, align: :center) unless p['short'].to_s.empty?
      end
      # dimensions, ordinate (variant A, Andriy 2026-10-15): plumbing inside a zone is dimensioned by the zone,
      # everything else by itself. Along the wall: 0 at the reference line, cumulative to each side. Heights: 0 at the
      # finished floor, straight to the centre of each box / stub, zone edges and blocking axes - no cabinet heights.
      in_zone = zones.flat_map { |zn| zn['ids'] }
      free = pts.reject { |p| in_zone.include?(p['id']) }
      zb = (c[:zmin] || 0).to_f
      ra = c[:ref] ? c[:ref][:at].to_f : a0
      o = vp.model_to_paper_point(p3.(ra, zb))
      u = mep_unit(o, vp.model_to_paper_point(p3.(ra + 1000, zb)))
      hf = free.map { |p| q = vp.model_to_paper_point(p3.(am_of.(p), p['z'])); [Geom::Point2d.new(q.x, q.y + MEP_SYM_D / 2), am_of.(p) - ra, p['id']] }
      zones.each do |zn|
        (axis == :x ? [zn['x0'], zn['x1']] : [zn['y0'], zn['y1']]).each { |za| hf << [vp.model_to_paper_point(p3.(za, zn['z0'])), za - ra, 'PZ'] }
      end
      nh = mep_ordinate(Geom::Point2d.new(o.x, o.y + ROW), u, [0.0, 1.0], hf,
                        zero: [vp.model_to_paper_point(p3.(ra, 0)), c[:ref] ? c[:ref][:text].upcase : nil])
      re = vp.model_to_paper_point(p3.(right_end, 0))
      uv = mep_unit(re, vp.model_to_paper_point(p3.(right_end, 1000)))
      vf = free.reject { |p| p['sys'] == 'M' }.map { |p| [vp.model_to_paper_point(p3.(right_end, p['z'])), p['z'], p['id']] }
      zones.each { |zn| [zn['z0'], zn['z1']].each { |zz| vf << [vp.model_to_paper_point(p3.(right_end, zz)), zz, 'PZ'] } }
      c[:blocks].each { |b| vf << [vp.model_to_paper_point(p3.(right_end, b['cl'])), b['cl'], "#{b['id']} CL"] }
      Array(c[:bars]).each { |br| zc = (br[:z0] + br[:z1]) / 2.0; vf << [vp.model_to_paper_point(p3.(right_end, zc)), zc, "#{br[:id]} CL"] }
      nv = mep_ordinate(Geom::Point2d.new(re.x + ROW, re.y), uv, [1.0, 0.0], vf, zero: [re, 'FIN. FLOOR'])
      @log << "#{c[:scene]}: #{pts.size} points, #{zones.size} zones, #{c[:blocks].size} blocking; ordinate along #{nh}, heights #{nv}#{@ord_rot_fail ? ' / ' + @ord_rot_fail : ''}"
      vp
    end

    def mep_page_elevations(skp, code, title, cells)
      next_page(title); header(@mep_scale || SCALE_HALF); sheet_code(code)
      cells.each_with_index do |(c, vtitle, x, y, w, h), i|
        begin
          mep_elevation(c[:skp] || skp, c, [x, y, w, h - LABEL_GAP - LABEL_H])
        rescue RuntimeError => e
          raise unless e.message.start_with?('STOP')
          (@doc.remove_entity(@cur_vp) rescue nil)
          text(e.message, x + w / 2, y + h / 2, @l_sheet, size: 9, font: MONO, c: ACCENT, align: :center)
          @log << e.message; @stops << e.message
        end
        view(x, y, w, h, i + 1, code, vtitle, :half, placeholder: false)
      end
      @index << [code, title]
    end

    # ---------------------------------------------------------------- tables
    # cols [[label, width]], rows [[cell, ...]]; cells wrap inside their column (FormattedText box), row_h fixed.
    # Pages are numbered from code0 ('M-601' -> 'M-602' ...). Returns the codes used.
    def mep_table(title, code0, cols, rows, note, row_h: 0.46, size: 6.8)
      k = WW / cols.sum { |_, w| w }
      widths = cols.map { |_, w| w * k }
      xs = widths.each_with_index.map { |_, i| WX + widths[0, i].sum }
      per = ((WH - 0.55 - 0.24) / row_h).floor
      pages = rows.each_slice(per).to_a
      pages = [[]] if pages.empty?
      pre, num_s = code0.split('-'); num = num_s.to_i
      pages.each_with_index.map do |chunk, pi|
        code = format("%s-%0#{num_s.size}d", pre, num + pi)
        name = pages.size > 1 ? "#{title} #{pi + 1}/#{pages.size}" : title
        next_page(name); header(NTS); sheet_code(code)
        y = WY
        cols.each_with_index { |(h, _), i| text(h, xs[i] + 0.04, y + 0.02, @l_sheet, size: 7, font: MONO, c: HEAD) }
        y += 0.24
        line(WX, y, WX + WW, y, @l_sheet, w: 1.0)
        chunk.each do |r|
          ink = r.last == :red ? RED : INK_C
          r.each_with_index do |cell, i|
            next if cell.is_a?(Symbol)
            str = cell.to_s.strip
            next if str.empty?
            box_text(str, xs[i] + 0.04, y + 0.04, widths[i] - 0.08, row_h - 0.06, @l_sheet, size: size, font: i.zero? ? MONO : SANS, c: ink)
          end
          y += row_h
          line(WX, y, WX + WW, y, @l_sheet, w: 0.5, c: ROWLINE)
        end
        box_text(note, WX, WY + WH - 0.42, WW, 0.40, @l_sheet, size: 7.5, c: INK2)
        @index << [code, name]
        code
      end
    end

    # symbol legend block at (x, y), width w
    def mep_symbol_legend(x, y, w)
      label('MEP SYMBOLS', x, y, @l_sheet)
      line(x, y + 0.22, x + w, y + 0.22, @l_sheet, w: 1.0)
      rows = [['DUP', 'Duplex receptacle 120 V (amps next to the symbol)'],
              ['GFCI', 'GFCI receptacle 120 V - "GFCI" next to the symbol'],
              ['SPLIT', 'Split-wired receptacle: one half switched (disposal), one always on'],
              ['R240', '240 V receptacle (e.g. dryer 14-30R)'],
              ['J', 'Junction box: hardwired appliance / provision'],
              ['S', 'Wall switch'],
              ['LV', 'Low-voltage (Class 2) cable outlet - LED, from the driver; dashed violet = its route'],
              ['HW', 'Plumbing stub-out / box: HW / CW / DRAIN / ice maker box + line / washer box'],
              ['G', 'Gas stub-out with accessible shut-off valve'],
              ['DUCT', 'Exhaust duct (drawn to scale on the plan)'],
              ['B', 'Blocking 2x6, band = 5 1/2" high, dashed line = its axis'],
              ['Z', 'PLUMBING ZONE: stub-outs anywhere inside the dashed blue rectangle']]
      yy = y + 0.40
      rows.each do |sym, txt|
        if sym == 'B'
          rect(x + 0.02, yy - 0.05, 0.36, 0.10, mep_layer, stroke: INK2, sw: 0.5, fill: [0xE4, 0xE4, 0xE0])
        elsif sym == 'Z'
          rect(x + 0.02, yy - 0.07, 0.36, 0.14, mep_layer, stroke: [0x1F, 0x5F, 0x9E], sw: 0.75, dash: true)
        else
          mep_symbol(sym == 'HW' ? 'P' : 'E', x + 0.2, yy, sym: sym, dir: [0, -1])
        end
        text(txt, x + 0.5, yy - 0.07, @l_sheet, size: 8)
        yy += 0.27
      end
      text("Heights to the CENTRE of the box / stub above finished floor (AFF), #{@mep_in ? 'inches' : 'mm'}.", x, yy, @l_sheet, size: 7.5, c: INK2)
      text('Status: SOURCE = manufacturer document; PLANNING = our default, to verify; DECISION = owner / designer decision.', x, yy + 0.18, @l_sheet, size: 7.5, c: INK2)
      yy + 0.4
    end

    # G-002: symbols (left) + questions for the client / open items (right)
    def mep_page_legend_questions(code, questions, title: 'SYMBOLS & OPEN QUESTIONS', notes: [])
      next_page(title); header(NTS); sheet_code(code)
      lw = 4.6
      ny = mep_symbol_legend(WX, WY, lw) + 0.15
      unless notes.empty?
        label('NOTES', WX, ny, @l_sheet)
        line(WX, ny + 0.22, WX + lw, ny + 0.22, @l_sheet, w: 1.0)
        ny += 0.32
        notes.each_with_index do |n, i|
          text("#{i + 1}.", WX, ny, @l_sheet, size: 7.5, font: MONO)
          box_text(n, WX + 0.25, ny, lw - 0.25, 0.55, @l_sheet, size: 7.5)
          ny += 0.56
        end
      end
      x = WX + lw + 0.5; w = WW - lw - 0.5
      label('OPEN QUESTIONS - FOR THE CLIENT / GC / FACTORY', x, WY, @l_sheet)
      line(x, WY + 0.22, x + w, WY + 0.22, @l_sheet, w: 1.0)
      y = WY + 0.32
      rh = [(WH - 0.5) / [questions.size, 1].max, 0.55].min
      questions.each_with_index do |(topic, q, pts), i|
        text("#{i + 1}.", x, y, @l_sheet, size: 8, font: MONO)
        text(topic, x + 0.3, y, @l_sheet, size: 8, bold: true)
        text(pts, x + w, y, @l_sheet, size: 7, font: MONO, c: INK2, align: :right)
        box_text(q, x + 0.3, y + 0.15, w - 0.3, rh - 0.17, @l_sheet, size: 7.5, c: INK2)
        y += rh
        line(x, y - 0.03, x + w, y - 0.03, @l_sheet, w: 0.5, c: ROWLINE)
      end
      @index << [code, title]
    end
  end
end

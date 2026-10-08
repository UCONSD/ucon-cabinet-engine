# UCON::WallPanels - wall-panel generators: panel grid, backing frames S, clips, clip drilling, cut list.
#
# PURE RUBY. No SketchUp, no LayOut: the same code runs in the test suite under the Ruby macOS ships (2.6.10,
# learned rule 2 - so no endless defs, no numbered block params, no filter_map), inside a probe, and inside the
# LayOut set writer. One wall = one JSON file in tools/wallpanels/walls/ (the wall's numbers); this file is the
# rules. Everything is in mm, wall-local: x along the wall from its left end as seen from the room, z up from
# finished floor, y = 0 at the wall face, negative toward the room.
#
# Written 2026-10-08 from the REC -> LAU wall of AP Capital, where every rule below was first applied by hand
# (probes 538 panels, 543/564 clips, 566 frames, 570 holes, 596 gap 3.3). tools/test_wallpanels.rb regenerates
# that wall from its JSON and compares with what the model and the issued files hold.
#
# The rules, as Andriy decided them (handoff 2026-10-07, proposal-2026-10-07-ap-backing-frames, spec v5):
#   PANELS  joints 10, 10 to floor / ceiling / wall ends, no baseboard. A door is one of the grid's panels: its
#           cladding is a column, and the horizontal joint runs along its top. Over a plain opening the panels
#           run `panel_overlap` into it. Between those fixed columns a segment is split into equal columns no
#           wider than max_width (widths cut to 0.1, the last column takes the rest). A panel passing in front of
#           a door frame loses its rear 10 mm there (rebate, 12 face remains).
#   FRAMES  plywood 3/4". Lower tier floor_gap..tier_joint, upper tier tier_joint..ceiling, over an opening
#           opening top..ceiling. A frame joint never falls in a panel joint: a vertical joint lies on the 6"
#           right stile of the left frame, `seam_overrun` past the joint centre - unless the joint is closer than
#           a 6" strip to the span's end, then that end stile is 6" and there is no frame joint. Any edge member
#           (stile or rail) with a panel joint within a 6" strip of it is 6", every other one 4" (98). Rails
#           between the stiles: one at each edge, one centred on each clip row the edge rails do not carry.
#   CLIPS   centre 75 from the panel edges, rows <= 600 apart (at least 2), a third column at the centre of a
#           panel wider than 900. A column over a stile moves onto the stile's centre line, never closer than 40
#           to the panel edge. A row whose clip would not sit fully on a member is raised onto the next rail up.
#   HOLES   per panel, numbered from the BACK: X from the left edge as seen from the back (right-to-left from the
#           face), then bottom-up. Panel D25 x 7 (male, factory), frame D25 x 8 (female, UCON CNC).
require 'json'

module UCON
  module WallPanels
    EPS = 1e-6
    CLIP_R = 12.5          # clip hole radius - a clip "sits on" a member when its whole D25 does

    module_function

    def load(path)
      spec = JSON.parse(File.read(path))
      spec['_path'] = path
      spec
    end

    # 0.1 mm, the precision every issued number carries
    def r1(v)
      (v * 10).round / 10.0
    end

    # 0.1 rounded DOWN (a column width; the last column of a segment takes the remainder)
    def floor1(v)
      (v * 10 + EPS).floor / 10.0
    end

    # integer if it is one, else one decimal - the way the issued CSVs and sheets print numbers
    def f1(v)
      (v - v.round).abs < 0.05 ? v.round.to_s : format('%.1f', v)
    end

    # half to even, the rounding the 2026-10-07 cut list was computed with (Python); 626.5 -> 626
    def round_even(v)
      f = v.floor
      d = v - f
      return f if d < 0.5 - EPS
      return f + 1 if d > 0.5 + EPS
      f.even? ? f : f + 1
    end

    def overlap(a0, a1, b0, b1)
      [a1, b1].min - [a0, b0].max
    end

    # ------------------------------------------------------------------ the wall
    def doors(spec)
      spec['openings'].select { |o| o['kind'] == 'door' }
    end

    def opening(spec, id)
      spec['openings'].find { |o| o['id'] == id } or raise "no opening #{id}"
    end

    def leaf_x(door)
      c = (door['x0'] + door['x1']) / 2.0
      [c - door['leaf']['w'] / 2.0, c + door['leaf']['w'] / 2.0]
    end

    # ------------------------------------------------------------------ panel grid
    # -> { cols: [[x0, x1], ...], rows: { 'L' => [z0, z1], 'U' => [z0, z1] }, seam_z: [z0, z1], panels: [...] }
    def grid(spec)
      pr = spec['panels']
      len = spec['wall']['length'].to_f
      hgt = spec['wall']['height'].to_f
      j = pr['joint'].to_f

      # rows
      rs = pr['row_seam'] || {}
      seam = if rs['from_door']
               d = opening(spec, rs['from_door'])
               d['leaf']['floor_gap'].to_f + d['leaf']['h']
             else
               rs['z'] && rs['z'].to_f
             end
      rows = {}
      if seam
        rows['L'] = [pr['margin_floor'].to_f, seam]
        rows['U'] = [seam + j, hgt - pr['margin_ceiling']]
      else
        rows['L'] = [pr['margin_floor'].to_f, hgt - pr['margin_ceiling']]
      end

      # fixed columns (door leaves, spans over openings) and the free segments between them
      items = pr['columns'] || auto_columns(spec)
      fixed = items.map do |it|
        if it.is_a?(String)
          d = opening(spec, it)
          lx = leaf_x(d)
          { span: lx, n: 1, door: it }
        elsif it.is_a?(Hash)
          o = opening(spec, it['over'])
          ov = (o['panel_overlap'] || 0).to_f
          { span: [o['x0'] + ov + j, o['x1'] - ov - j], n: it['n'], over: it['over'] }
        end
      end
      cols = []
      items.each_with_index do |it, i|
        if fixed[i]
          cols.concat(split(fixed[i][:span][0], fixed[i][:span][1], fixed[i][:n] || auto_n(fixed[i][:span], pr), j))
          next
        end
        prev = (0...i).to_a.reverse.map { |k| fixed[k] }.compact.first
        nxt = ((i + 1)...items.size).map { |k| fixed[k] }.compact.first
        a = prev ? prev[:span][1] + j : pr['margin_ends'].to_f
        b = nxt ? nxt[:span][0] - j : len - pr['margin_ends']
        n = it.is_a?(Integer) ? it : auto_n([a, b], pr)
        cols.concat(split(a, b, n, j))
      end

      # cells -> panels; a lower cell inside an opening is the opening (or the door leaf)
      cells = []
      cols.each_with_index do |(x0, x1), ci|
        rows.each do |rk, (z0, z1)|
          inside = spec['openings'].find { |o| x0 >= o['x0'] - EPS && x1 <= o['x1'] + EPS && z0 < o['h'] }
          next if inside && rk == 'L'
          cells << { col: ci + 1, row: rk, x0: x0, x1: x1, z0: z0, z1: z1 }
        end
      end
      number(spec, cells)
      panels = cells.sort_by { |c| c[:n] }.map do |c|
        p = c.merge(id: format('P%02d', c[:n]), w: r1(c[:x1] - c[:x0]), h: r1(c[:z1] - c[:z0]))
        p[:pos] = "C#{c[:col]}-#{c[:row]}"
        p[:rebates] = rebates(spec, p)
        p
      end
      { cols: cols, rows: rows, seam_z: seam && [seam, seam + j], panels: panels }
    end

    def auto_n(span, pr)
      j = pr['joint'].to_f
      w = span[1] - span[0]
      [((w + j) / (pr['max_width'].to_f + j) - EPS).ceil, 1].max
    end

    def split(a, b, n, j)
      w = floor1((b - a - (n - 1) * j) / n)
      out = []
      x = a
      n.times do |k|
        x1 = k == n - 1 ? b : r1(x + w)
        out << [r1(x), r1(x1)]
        x = x1 + j
      end
      out
    end

    # no `columns` in the JSON: doors become columns, other openings get panels over them, free segments by width
    def auto_columns(spec)
      spec['openings'].sort_by { |o| o['x0'] }.flat_map do |o|
        if o['kind'] == 'door'
          [nil, o['id']]
        elsif o['h'] < spec['wall']['height']
          [nil, { 'over' => o['id'] }]
        else
          [nil]
        end
      end.push(nil).each_with_object([]) { |it, a| a << it unless it.nil? && a.last.nil? && !a.empty? }
    end

    def number(spec, cells)
      list = spec['panels']['numbering']
      if list
        list.each do |n, col, row|
          c = cells.find { |x| x[:col] == col && x[:row] == row } or raise "numbering: no panel at C#{col}-#{row}"
          c[:n] = n
        end
        missing = cells.reject { |c| c[:n] }
        raise "numbering: no number for #{missing.map { |c| "C#{c[:col]}-#{c[:row]}" }.join(', ')}" unless missing.empty?
      else
        k = 0
        cells.sort_by { |c| [c[:col], c[:row]] }.each { |c| c[:n] = (k += 1) }
      end
    end

    # the part of a panel's back that passes in front of a door frame (wall-local rectangles [x0, x1, z0, z1])
    def rebates(spec, p)
      doors(spec).map do |d|
        rb = d['rebate'] or next
        zx0 = d['x0'] + rb['inset']; zx1 = d['x1'] - rb['inset']
        rx0 = [p[:x0], zx0].max; rx1 = [p[:x1], zx1].min; rz1 = [p[:z1], d['h'].to_f].min
        next if rx0 >= rx1 - EPS || p[:z0] >= rz1 - EPS
        [r1(rx0), r1(rx1), p[:z0], r1(rz1)]
      end.compact
    end

    # ------------------------------------------------------------------ backing frames S
    # -> [{ id: 'S01', kind:, x0:, x1:, z0:, z1:, stiles: [[a, b, '4'|'6'], ...], rails: [[c, d, w], ...] }]
    def frames(spec, g)
      sf = spec['subframe']
      len = spec['wall']['length'].to_f
      hgt = spec['wall']['height'].to_f
      wn = sf['strip'].to_f; ww = sf['strip_wide'].to_f
      vseams = g[:cols].each_cons(2).map { |(_, a), (b, _)| [a, b] }
      hseams = g[:seam_z] ? [g[:seam_z]] : []
      ops = spec['openings'].sort_by { |o| o['x0'] }
      rows = clip_rows_all(spec, g)

      # tier spans
      low = []
      x = 0.0
      ops.each { |o| low << [x, o['x0'].to_f] if o['x0'] > x + EPS; x = o['x1'].to_f }
      low << [x, len] if len > x + EPS
      up = []
      x = 0.0
      ops.each do |o|
        up << [x, o['x0'].to_f, sf['tier_joint'].to_f, nil] if o['x0'] > x + EPS
        up << [o['x0'].to_f, o['x1'].to_f, o['h'].to_f, o]
        x = o['x1'].to_f
      end
      up << [x, len, sf['tier_joint'].to_f, nil] if len > x + EPS

      out = []
      add = lambda do |a, b, z0, z1, kind|
        cuts = vseams.map { |s0, s1| (s0 + s1) / 2.0 }.select { |c| c - a >= ww - EPS && b - c >= ww - EPS }
        edges = [a] + cuts.map { |c| r1(c + sf['seam_overrun']) } + [b]
        edges.each_cons(2) do |fa, fb|
          out << frame(fa, fb, z0, z1, kind, vseams, hseams, rows, wn, ww)
        end
      end
      low.each { |a, b| add.call(a, b, sf['floor_gap'].to_f, sf['tier_joint'].to_f, 'LOW') }
      up.each { |a, b, z0, o| add.call(a, b, z0, hgt, o ? "UP-#{o['kind'] == 'door' ? 'door' : o['id'].downcase}" : 'UP') }
      out.each_with_index { |f, i| f[:id] = format('S%02d', i + 1) }
      out
    end

    def frame(a, b, z0, z1, kind, vseams, hseams, rows, wn, ww)
      near_lo = ->(e, seams) { seams.any? { |s0, s1| s1 > e + EPS && s0 < e + ww - EPS } }
      near_hi = ->(e, seams) { seams.any? { |s0, s1| s0 < e - EPS && s1 > e - ww + EPS } }
      lw = near_lo.call(a, vseams) ? ww : wn
      rw = near_hi.call(b, vseams) ? ww : wn
      stiles = [[a, r1(a + lw), lw == ww ? '6' : '4'], [r1(b - rw), b, rw == ww ? '6' : '4']]
      bw = near_lo.call(z0, hseams) ? ww : wn
      tw = near_hi.call(z1, hseams) ? ww : wn
      rails = [[z0, r1(z0 + bw), bw == ww ? '6' : '4'], [r1(z1 - tw), z1, tw == ww ? '6' : '4']]
      rows.each do |z|
        next unless z - CLIP_R > z0 + EPS && z + CLIP_R < z1 - EPS
        next if rails.any? { |c, d, _| z - CLIP_R >= c - EPS && z + CLIP_R <= d + EPS }
        rails << [r1(z - wn / 2), r1(z + wn / 2), '4']
      end
      { kind: kind, x0: a, x1: b, z0: z0, z1: z1, stiles: stiles, rails: rails.sort_by(&:first) }
    end

    # every panel's clip rows before support is checked (frames are laid out on them)
    def clip_rows_all(spec, g)
      g[:panels].flat_map { |p| clip_rows(spec, p) }.uniq.sort
    end

    def clip_rows(spec, p)
      c = spec['clips']
      zb = p[:z0] + c['edge']; zt = p[:z1] - c['edge']
      n = [((zt - zb) / c['row_max'].to_f - EPS).ceil + 1, 2].max
      (0...n).map { |k| r1(zb + (zt - zb) * k / (n - 1).to_f) }
    end

    # members of all frames as wall-local boxes, in definition order (stiles L, R, then rails bottom-up)
    def members(fr)
      ia = fr[:stiles].first[1]; ib = fr[:stiles].last[0]
      st = fr[:stiles].each_with_index.map do |(a, b, w), k|
        { name: "#{fr[:id]} stile #{k.zero? ? 'L' : 'R'} #{w == '6' ? 152 : 98}", x0: a, x1: b, z0: fr[:z0], z1: fr[:z1], w: w }
      end
      ra = fr[:rails].each_with_index.map do |(c, d, w), k|
        { name: "#{fr[:id]} rail #{k + 1} #{w == '6' ? 152 : 98}", x0: ia, x1: ib, z0: c, z1: d, w: w }
      end
      st + ra
    end

    # ------------------------------------------------------------------ clips
    # -> [{ panel: 'P02', x:, z:, support: :ok | :part | :no }], per panel columns left-to-right, rows bottom-up
    def clips(spec, g, frs)
      c = spec['clips']
      mem = frs.flat_map { |f| members(f) }
      out = []
      g[:panels].each do |p|
        base = [p[:x0] + c['edge'], p[:x1] - c['edge']]
        base.insert(1, (p[:x0] + p[:x1]) / 2.0) if p[:w] > c['wide_panel']
        backing = frs.select { |f| overlap(f[:x0], f[:x1], p[:x0], p[:x1]) > EPS && overlap(f[:z0], f[:z1], p[:z0], p[:z1]) > EPS }
                     .sort_by { |f| -overlap(f[:z0], f[:z1], p[:z0], p[:z1]) }
        cols = base.map do |x|
          st = backing.flat_map { |f| members(f).first(2) }.find { |m| x >= m[:x0] - EPS && x <= m[:x1] + EPS }
          next r1(x) unless st
          r1([[(st[:x0] + st[:x1]) / 2.0, p[:x0] + c['edge_min']].max, p[:x1] - c['edge_min']].min)
        end
        rows = clip_rows(spec, p)
        rows = rows.each_with_index.map do |z, k|
          next z if cols.all? { |x| sits?(mem, x, z) }
          raise "#{p[:id]}: clip row #{z} has no support and is not the bottom row" unless k.zero?
          if c['row_over_opening']
            c['row_over_opening'].to_f
          else
            # the bottom rail of the frame behind each column, the lowest frame above the row
            up = cols.map { |x| frs.select { |f| f[:z0] > z && x >= f[:x0] - EPS && x <= f[:x1] + EPS }.min_by { |f| f[:z0] } }
            raise "#{p[:id]}: no frame above row #{z} to raise it onto" if up.any?(&:nil?)
            r1(up.map { |f| (f[:rails].first[0] + f[:rails].first[1]) / 2.0 }.max)
          end
        end
        cols.each do |x|
          rows.each do |z|
            full = sits?(mem, x, z)
            on = mem.any? { |m| x >= m[:x0] && x <= m[:x1] && z >= m[:z0] && z <= m[:z1] }
            out << { panel: p[:id], x: x, z: z, support: full ? :ok : (on ? :part : :no) }
          end
        end
      end
      out
    end

    def sits?(mem, x, z)
      mem.any? { |m| x - CLIP_R >= m[:x0] - 0.05 && x + CLIP_R <= m[:x1] + 0.05 && z - CLIP_R >= m[:z0] - 0.05 && z + CLIP_R <= m[:z1] + 0.05 }
    end

    # ------------------------------------------------------------------ drilling
    # holes per panel, numbered from the back: X right-to-left on the face, then bottom-up
    # -> [{ id: 'P02-H01', panel:, x:, z:, xb: from left edge seen from the back, zb: from bottom, xf: from left on the face }]
    def holes(g, cl)
      g[:panels].flat_map do |p|
        cl.select { |c| c[:panel] == p[:id] }.sort_by { |c| [-c[:x], c[:z]] }.each_with_index.map do |c, i|
          { id: format('%s-H%02d', p[:id], i + 1), panel: p[:id], x: c[:x], z: c[:z],
            xb: r1(p[:x1] - c[:x]), zb: r1(c[:z] - p[:z0]), xf: r1(c[:x] - p[:x0]) }
        end
      end
    end

    PANEL_CSV_HEAD = ['hole', 'panel', 'panel W x H x T (mm)', 'X from LEFT edge, BACK VIEW (mm)', 'Z from BOTTOM edge (mm)',
                      'dia (mm)', 'depth (mm)', 'side', 'check: X from left edge, FACE view'].freeze
    FRAME_CSV_HEAD = ['frame', 'member', 'member length (mm)', 'member width (mm)',
                      'hole along member from its start (bottom / left end) (mm)', 'hole across member from its left / bottom edge (mm)',
                      'X in frame, FACE view (mm)', 'Z in frame (mm)', 'dia (mm)', 'depth (mm)', 'mates with panel hole'].freeze

    # factory list: one row per panel recess (D-sheets carry the same numbers)
    def panel_csv_rows(spec, g, hs)
      c = spec['clips']; t = spec['build_up']['panel_t']
      hs.map do |h|
        p = g[:panels].find { |x| x[:id] == h[:panel] }
        [h[:id], h[:panel], format('%.1f x %.1f x %s', p[:w], p[:h], f1(t)), format('%.1f', h[:xb]), format('%.1f', h[:zb]),
         format('%.1f', c['hole_d']), format('%.1f', c['panel_depth']), 'BACK (wall side)', format('%.1f', h[:xf])]
      end
    end

    # UCON CNC list: the mating hole in the frame member under each recess
    def frame_csv_rows(spec, frs, hs)
      c = spec['clips']
      tol = 0.254 # the 0.01 in the model reader allowed
      rows = hs.map do |h|
        fr = frs.find { |f| h[:x].between?(f[:x0], f[:x1]) && h[:z].between?(f[:z0], f[:z1]) } or next
        m = members(fr).find { |mm| h[:x].between?(mm[:x0] - tol, mm[:x1] + tol) && h[:z].between?(mm[:z0] - tol, mm[:z1] + tol) }
        wx = m[:x1] - m[:x0]; hz = m[:z1] - m[:z0]
        if hz >= wx
          ml = hz; mw = wx; along = h[:z] - m[:z0]; across = h[:x] - m[:x0]
        else
          ml = wx; mw = hz; along = h[:x] - m[:x0]; across = h[:z] - m[:z0]
        end
        [fr[:id], m[:name], f1(ml), f1(mw), f1(along), f1(across), f1(h[:x] - fr[:x0]), f1(h[:z] - fr[:z0]),
         f1(c['hole_d']), f1(c['frame_depth']), h[:id]]
      end.compact
      rows.sort_by { |r| [r[0], r[1], r[4].to_f] }
    end

    def write_csv(path, head, rows)
      require 'csv'
      CSV.open(path, 'w') { |csv| csv << head; rows.each { |r| csv << r } }
      path
    end

    # ------------------------------------------------------------------ cut list
    # parts: stiles run the frame height, rails run between the stiles
    def cut_list(spec, frs)
      parts = Hash.new(0)
      frs.each do |f|
        f[:stiles].each { |_, _, w| parts[[w, r1(f[:z1] - f[:z0])]] += 1 }
        ia = f[:stiles].first[1]; ib = f[:stiles].last[0]
        f[:rails].each { |_, _, w| parts[[w, r1(ib - ia)]] += 1 }
      end
      list = parts.map { |(w, l), q| { w: w, len: l, qty: q } }
      list.sort_by { |p| [p[:w], -p[:len]] }
    end

    # cut list as the 2026-10-07 proposal printed it: whole mm, half to even, merged
    def cut_list_print(cl)
      merged = Hash.new(0)
      cl.each { |p| merged[[p[:w], round_even(p[:len])]] += p[:qty] }
      merged.map { |(w, l), q| ["#{w}\"", l, q] }.sort_by { |w, l, _| [w, -l] }
    end

    # strips per width (first fit decreasing along a sheet length, kerf per cut) and sheets across the width
    def strips(spec, cl)
      sh = spec['subframe']['sheet']; k = sh['kerf']
      out = {}
      %w[4 6].each do |w|
        pieces = cl.select { |p| p[:w] == w }.flat_map { |p| [p[:len]] * p[:qty] }.sort.reverse
        bins = []
        pieces.each do |l|
          b = bins.find { |x| x + l <= sh['l'] + EPS }
          if b then bins[bins.index(b)] = b + l + k else bins << l + k end
        end
        out[w] = { pieces: pieces.size, metres: (pieces.sum / 1000.0).round(1), strips: bins.size }
      end
      out
    end

    def sheets(spec, st)
      sh = spec['subframe']['sheet']; sf = spec['subframe']; k = sh['kerf']
      n6 = st['6'][:strips]; n4 = st['4'][:strips]
      list = []
      while n6 > 0 || n4 > 0
        room = sh['w']; a = 0; b = 0
        while n6 > 0 && room >= sf['strip_wide'] - EPS
          room -= sf['strip_wide'] + k; n6 -= 1; a += 1
        end
        while n4 > 0 && room >= sf['strip'] - EPS
          room -= sf['strip'] + k; n4 -= 1; b += 1
        end
        list << [a, b]
      end
      list
    end

    # ------------------------------------------------------------------ everything for one wall
    def build(spec)
      g = grid(spec)
      frs = frames(spec, g)
      cl = clips(spec, g, frs)
      hs = holes(g, cl)
      cut = cut_list(spec, frs)
      st = strips(spec, cut)
      { spec: spec, grid: g, frames: frs, clips: cl, holes: hs, cut: cut, strips: st, sheets: sheets(spec, st),
        checks: checks(spec, g, frs, cl) }
    end

    # what a wall must satisfy before anything is drawn; each line is a fact, an empty list is the pass
    def checks(spec, g, frs, cl)
      bad = []
      lmax = spec['subframe']['max_length']
      frs.each do |f|
        bad << "#{f[:id]}: height #{f1(f[:z1] - f[:z0])} > #{lmax}" if f[:z1] - f[:z0] > lmax + EPS
        bad << "#{f[:id]}: width #{f1(f[:x1] - f[:x0])} > #{lmax}" if f[:x1] - f[:x0] > lmax + EPS
      end
      vseams = g[:cols].each_cons(2).map { |(_, a), (b, _)| [a, b] }
      frs.each do |f|
        [f[:x0], f[:x1]].each do |x|
          next if x < EPS || x > spec['wall']['length'] - EPS
          s = vseams.find { |s0, s1| x > s0 - 5 && x < s1 + 5 }
          bad << "#{f[:id]}: frame joint x #{f1(x)} in the panel joint #{f1(s[0])}..#{f1(s[1])}" if s
        end
      end
      cl.each do |c|
        p = g[:panels].find { |x| x[:id] == c[:panel] }
        e = [c[:x] - p[:x0], p[:x1] - c[:x]].min
        bad << "#{c[:panel]}: clip #{f1(c[:x])},#{f1(c[:z])} is #{f1(e)} from the panel edge" if e < spec['clips']['edge_min'] - 0.05
        bad << "#{c[:panel]}: clip #{f1(c[:x])},#{f1(c[:z])} support #{c[:support]}" unless c[:support] == :ok
      end
      bad
    end
  end
end

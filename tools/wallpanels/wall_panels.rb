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
      return grid_explicit(spec) if spec['panels']['explicit']
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
          { span: lx, n: (d['leaf']['n'] || 1).to_i, door: it }   # n = 2: a double door, two cladding columns
        elsif it.is_a?(Hash)
          o = opening(spec, it['over'])
          ov = (o['panel_overlap'] || 0).to_f
          # an opening that runs to a wall end: on that side the panel stops margin_ends short of the end (2026-10-16)
          sa = o['x0'] <= EPS ? pr['margin_ends'].to_f : o['x0'] + ov + j
          sb = o['x1'] >= len - EPS ? len - pr['margin_ends'] : o['x1'] - ov - j
          { span: [sa, sb], n: it['n'], over: it['over'] }
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
          inside = spec['openings'].find { |o| x0 >= o['x0'] - EPS && x1 <= o['x1'] + EPS && (z0 < o['h'] || rk == 'U') }
          next if inside && rk == 'L'
          # an opening with a head liner: the panel over it stops head_gap above the head (AP ML Foyer 2026-10-16)
          z0 = [z0, inside['h'].to_f + inside['head_gap'].to_f].max if inside && rk == 'U' && inside['head_gap']
          # a closet with a TM cabinet of known height: the panel over it starts one joint above the cabinet top, below
          # the row if need be (Andriy 2026-10-17: walls and the ordered cabinets are fixed, panels follow them)
          z0 = cab_top(spec, inside) + j if inside && rk == 'U' && cab_top(spec, inside)
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

    # 2026-10-17 (Main Kitchen): the panels are GIVEN - issued to TM, numbers and sizes fixed - and the generator only
    # builds frames, clips and drilling for them. panels.explicit = [{ id, x0, x1, z0, z1, row: 'L'|'U'|'S'|'H',
    # mitre_start, mitre_end }]; x may run past 0 / length at a 45° corner (long point).
    def grid_explicit(spec)
      pr = spec['panels']; j = pr['joint'].to_f
      panels = pr['explicit'].map do |e|
        p = { id: e['id'], row: e['row'], x0: e['x0'].to_f, x1: e['x1'].to_f, z0: e['z0'].to_f, z1: e['z1'].to_f,
              mitre_start: e['mitre_start'] ? true : false, mitre_end: e['mitre_end'] ? true : false, glued: e['glued'] ? true : false }
        p.merge!(w: r1(p[:x1] - p[:x0]), h: r1(p[:z1] - p[:z0]), pos: "#{e['row']}-#{e['id']}")
        p[:rebates] = rebates(spec, p)
        p
      end
      rows = panels.group_by { |p| p[:row] }.transform_values { |ps| [ps.map { |p| p[:z0] }.min, ps.map { |p| p[:z1] }.max] }
      seam = pr['row_seam'] && pr['row_seam']['z'] && pr['row_seam']['z'].to_f
      cols = panels.map { |p| [p[:x0], p[:x1]] }.uniq.sort
      { cols: cols, rows: rows, seam_z: seam && [seam, seam + j], panels: panels, vseams: adjacency(panels, j) }
    end

    # vertical panel joints [x_left_edge, x_right_edge] between panels side by side (any row), unique, sorted
    def adjacency(panels, j)
      out = []
      panels.each do |p|
        panels.each do |q|
          d = q[:x0] - p[:x1]
          out << [p[:x1], q[:x0]] if d > EPS && d <= j + EPS && overlap(p[:z0], p[:z1], q[:z0], q[:z1]) > EPS
        end
      end
      out.uniq.sort
    end

    def vseams_of(g)
      g[:vseams] || g[:cols].each_cons(2).map { |(_, a), (b, _)| [a, b] }
    end

    # ceiling over [a, b]: the lowest step of wall.ceil ([[x0, x1, h], ...]) the range touches, else wall.height
    def ceil_at(spec, a, b)
      cs = spec['wall']['ceil'] or return spec['wall']['height'].to_f
      hs = cs.select { |c0, c1, _| c1 > a + EPS && c0 < b - EPS }.map { |c| c[2].to_f }
      hs.empty? ? spec['wall']['height'].to_f : hs.min
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

    # top of a TM closet cabinet from the subfloor, nil if not given
    # 2026-10-17 evening: the two cabinets differ in height - each fits its niche: top = niche head - top_gap (fit_niche);
    # tm_top_ffl stays as TM's drawing value, for the notes only
    def cab_top(spec, o)
      cb = o['cabinet'] or return nil
      return o['h'].to_f - cb['top_gap'].to_f if cb['fit_niche']
      cb['tm_top_ffl'] or return nil
      spec['levels']['ffl'].to_f + cb['tm_top_ffl'].to_f
    end

    # the part of a panel's back that passes in front of a door frame (wall-local rectangles [x0, x1, z0, z1])
    def rebates(spec, p)
      doors(spec).map do |d|
        rb = d['rebate'] or next
        zx0 = d['x0'] + rb['inset']; zx1 = d['x1'] - rb['inset']
        rx0 = [p[:x0], zx0].max; rx1 = [p[:x1], zx1].min; rz1 = [p[:z1], d['h'].to_f - (rb['head_inset'] || 0).to_f].min
        next if rx0 >= rx1 - EPS || p[:z0] >= rz1 - EPS
        [r1(rx0), r1(rx1), p[:z0], r1(rz1)]
      end.compact
    end

    # ------------------------------------------------------------------ backing frames S
    # -> [{ id: 'S01', kind:, x0:, x1:, z0:, z1:, stiles: [[a, b, '4'|'6'], ...], rails: [[c, d, w], ...] }]
    def frames(spec, g)
      return frames_band(spec, g) if spec['subframe']['layout'] == 'band'
      sf = spec['subframe']
      len = spec['wall']['length'].to_f
      hgt = spec['wall']['height'].to_f
      wn = sf['strip'].to_f; ww = sf['strip_wide'].to_f
      vseams = vseams_of(g)
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

    # BAND LAYOUT (subframe.layout = "band", AP ML Foyer, Andriy 2026-10-16). For walls whose openings run from the floor
    # to near one head line, with the panels' horizontal joint at that line:
    #   R1  a pier narrower than two 4" stiles gets ONE solid strip of plywood across its width (no rails).
    #   R2  above the openings: continuous frames along the whole wall from the upper panel row's bottom to the ceiling,
    #       cut into pieces <= max_length; a cut that would fall within a 6" strip of a panel joint moves to
    #       `seam_overrun` past the joint centre (as REC-LAU). On the piers below: floor_gap..tier_joint..band bottom.
    #   R3  a pier frame stops `jamb_setback` short of an opening's jamb (the frame must not show in the reveal); a
    #       frame edge at a jamb line is allowed (the frame cannot run into the opening).
    def frames_band(spec, g)
      sf = spec['subframe']
      len = spec['wall']['length'].to_f
      hgt = spec['wall']['height'].to_f
      wn = sf['strip'].to_f; ww = sf['strip_wide'].to_f
      set = (sf['jamb_setback'] || 0).to_f
      vseams = vseams_of(g)
      hseams = g[:seam_z] ? [g[:seam_z]] : []
      rows = clip_rows_all(spec, g)
      ops = spec['openings'].sort_by { |o| o['x0'] }
      # the band cannot run below an opening head: it starts at the upper panel row or at the highest head, whichever
      # is higher (2026-10-16: with the window-type liner the upper panels come 13 below the head, the band does not)
      u0 = (g[:rows]['U'] || raise('band layout needs an upper panel row'))[0]
      # an opening with a liner: the band also clears the head flange and the strips B / A behind the panel over it -
      # it starts frame_setback above the head (= head_gap 10 + 46, as Main Kitchen S09 over W2-WIN: 3088 = 3042 + 46)
      # 2026-10-17 (Main Kitchen): only openings with a liner (doorways, windows) set the band bottom; an opening
      # without one (closet, niche, door) gets a LINTEL below the band or, if its head is higher, lifts the band piece
      # over it. A wall with no liner opening: the band starts at the tier joint (no PIER tier).
      heads = ops.select { |o| o['liner'] }.map { |o| o['h'].to_f + o['frame_setback'].to_f }
      bz = heads.empty? ? sf['tier_joint'].to_f : (heads + [u0]).max
      lmax = sf['max_length'].to_f
      # the band pieces: cut at EVERY vertical panel joint (seam centre + seam_overrun), at ceiling steps, <= a sheet
      # 2026-10-19 (AP Dining C): seam_overrun_at { "<joint left edge>" => overrun } turns single band cuts the other way
      ova = sf['seam_overrun_at'] || {}
      # 2026-10-19 (AP Dining B / C): subframe.ends_setback [start, end] - the frames stop that far from the wall ends
      # (an inside corner where the neighbour wall's panels stand in front of this wall's ends); default none
      e0, e1 = (sf['ends_setback'] || [0, 0]).map(&:to_f)
      cuts = vseams.map { |s0, s1| r1((s0 + s1) / 2.0 + (ova[f1(s0)] || sf['seam_overrun']).to_f) }.select { |c| c > e0 + EPS && c < len - e1 - EPS }
      steps = (spec['wall']['ceil'] || []).map { |c| c[1].to_f }.select { |x| x > EPS && x < len - EPS }   # ceiling steps
      cuts = cuts.reject { |c| steps.any? { |x| (c - x).abs < ww } }   # a joint by a ceiling step: cut at the step
      edges = ([e0] + cuts + steps + [len - e1]).uniq.sort
      edges = edges.each_cons(2).flat_map do |fa, fb|
        n = [((fb - fa) / lmax - EPS).ceil, 1].max
        (0...n).map { |k| r1(fa + (fb - fa) * k / n) }
      end + [len - e1]
      # band_bottom 'local' (Main Kitchen, 2026-10-17): each piece starts over the openings it touches - a liner opening
      # at head + frame_setback, any other at its head; none: the tier joint. The pier frames below reach the highest
      # piece over them. 'global' (ML Foyer v1.0): one band bottom for the wall, LINTELs below it over closets / doors.
      local = sf['band_bottom'] == 'local'
      sb = ->(o) { o && o['frame_setback'] ? o['frame_setback'].to_f : set }
      pbot = lambda do |fa, fb|
        # an opening reaches its frame setback on both sides (the liner flange is there)
        over = ops.select { |o| o['x1'] + sb.(o) > fa + EPS && o['x0'] - sb.(o) < fb - EPS }
        if local
          z = ([sf['tier_joint'].to_f] + over.map { |o| o['h'].to_f + (o['liner'] ? o['frame_setback'].to_f : 0) }).max
          # a piece edge must not cut through a clip: lift it to a rail centred on that clip row (Main Kitchen P14 2813)
          # 2026-10-19 (AP Dining C): only the clip rows of the panels this piece is behind - a row of a pier panel must not
          # lift the band pieces over the opening (that left the band joints bare between the head flange and the band)
          ce = spec['clips']['edge'].to_f
          prow = g[:panels].reject { |p| p[:glued] || [p[:x0] + ce, p[:x1] - ce].none? { |x| x > fa - EPS && x < fb + EPS } }.flat_map { |p| clip_rows(spec, p) }.uniq
          prow = rows if spec['clips']['fixed']
          while (hit = prow.find { |r| z > r - CLIP_R - EPS && z < r + CLIP_R + EPS })
            z = r1(hit + wn / 2)
          end
          z
        else
          ([bz] + over.reject { |o| o['liner'] }.map { |o| o['h'].to_f }).max
        end
      end
      ptop = lambda do |a, b|
        next bz unless local
        edges.each_cons(2).select { |fa, fb| fb > a + EPS && fa < b - EPS }.map { |fa, fb| pbot.(fa, fb) }.max
      end

      out = []
      piers = []
      x = e0; prev = nil
      ops.each { |o| piers << [x, o['x0'].to_f, prev, o] if o['x0'] > x + EPS; x = [x, o['x1'].to_f].max; prev = o }
      piers << [x, len - e1, prev, nil] if len - e1 > x + EPS
      # setback per jamb: the opening's own frame_setback (liner openings: clear of the strips B / A, as Main Kitchen
      # S07 / W2-WIN - frame edge 46 behind the panel edge), else the wall's jamb_setback
      piers.each do |a, b, ol, orr|
        a2 = ol ? r1(a + sb.(ol)) : a
        b2 = orr ? r1(b - sb.(orr)) : b
        # 2026-10-17 (Main Kitchen): a pier with two panel columns is cut at the joint between them, as the band
        pc = vseams.map { |s0, s1| r1((s0 + s1) / 2.0 + sf['seam_overrun']) }.select { |c| c > a2 + 2 * wn && c < b2 - 2 * wn }
        ([a2] + pc + [b2]).each_cons(2) do |pa, pb|
          [[sf['floor_gap'].to_f, sf['tier_joint'].to_f, 'LOW'], [sf['tier_joint'].to_f, ptop.(pa, pb), 'PIER']].each do |z0, z1, kind|
            next if z1 - z0 < EPS
            out << if pb - pa < 2 * wn - EPS
                     solid(pa, pb, z0, z1, kind)
                   else
                     frame(pa, pb, z0, z1, kind, vseams, hseams, rows, wn, ww)
                   end
          end
        end
      end

      # Andriy 2026-10-17: no raw wall through a joint - over an opening WITHOUT a liner (closet, door) the wall between
      # its head and the band gets one solid plywood piece (LINTEL), jamb to jamb: the joints over the closet cabinet and
      # around the closet / door panels show plywood, not wall (with jamb_setback 0 the pier frames run to the jambs)
      ops.each do |o|
        next if o['liner']
        if local
          # under each band piece over the opening, up to that piece (DK2: 2917 under the pier piece, 3187 under the
          # piece that also touches the niche); neighbouring parts of the same height are one lintel
          segs = edges.each_cons(2).select { |fa, fb| fb > o['x0'] + EPS && fa < o['x1'] - EPS }
                      .map { |fa, fb| [[fa, o['x0'].to_f].max, [fb, o['x1'].to_f].min, pbot.(fa, fb)] }
          segs = segs.chunk_while { |p, q| (p[2] - q[2]).abs < EPS }.map { |c| [c.first[0], c.last[1], c.first[2]] }
          segs.each { |sa, sb2, top| out << solid(sa, sb2, o['h'].to_f, top, 'LINTEL') if top > o['h'].to_f + EPS }
        else
          next if bz <= o['h'].to_f + EPS
          out << solid(o['x0'].to_f, o['x1'].to_f, o['h'].to_f, bz, 'LINTEL')
        end
      end

      # 2026-10-17 (Main Kitchen): a window (opening with 'sill' = its bottom) gets frames below it, jamb - setback to
      # jamb + setback, from floor_gap to sill - sill_setback (S03 W1: 293..933 x 260.35..767), in pieces <= a sheet
      ops.select { |o| o['sill'] }.each do |o|
        a = r1(o['x0'] - sb.(o)); b = r1(o['x1'] + sb.(o))
        z1 = r1(o['sill'].to_f - (o['sill_setback'] || o['frame_setback']).to_f)
        next if z1 - sf['floor_gap'].to_f < EPS
        n = [((b - a) / lmax - EPS).ceil, 1].max
        (0...n).each do |k|
          fa = r1(a + (b - a) * k / n); fb = r1(a + (b - a) * (k + 1) / n)
          out << if z1 - sf['floor_gap'].to_f < 2 * wn - EPS || fb - fa < wn + ww - EPS
                   solid(fa, fb, sf['floor_gap'].to_f, z1, 'SILL')
                 else
                   frame(fa, fb, sf['floor_gap'].to_f, z1, 'SILL', vseams, hseams, rows, wn, ww)
                 end
        end
      end

      # Andriy 2026-10-17: no raw wall may show through a joint, so the band is cut at EVERY vertical panel joint
      # (seam centre + seam_overrun: the joint lies on the 6" right stile of the left piece); a piece still longer than
      # a sheet is cut again in equal parts (those cuts lie behind a panel). A piece narrower than its two stiles: R1.
      edges.each_cons(2) do |fa, fb|
        raise "band piece #{f1(fa)}..#{f1(fb)} longer than #{f1(lmax)}" if fb - fa > lmax + EPS
        # the piece starts at the band bottom, or over the head of a no-liner opening it touches if that is higher
        # (Main Kitchen niche 3125 > 3088); it ends at the ceiling over it (Wall 2 soffit step)
        pz0 = pbot.(fa, fb)
        pz1 = ceil_at(spec, fa, fb)
        out << if fb - fa < wn + ww - EPS
                 solid(fa, fb, pz0, pz1, 'BAND')
               else
                 frame(fa, fb, pz0, pz1, 'BAND', vseams, hseams, rows, wn, ww)
               end
      end
      first = (sf['first_id'] || 1).to_i
      out.each_with_index { |f, i| f[:id] = format('S%02d', first + i) }
      out
    end

    # R1: one plywood strip across a narrow pier; its width code is "S" + the width in mm
    # 2026-10-19 (AP Dining v2.0, Andriy: "these are better made of solid plywood"): subframe.solid_below = c (mm).
    # A frame becomes ONE solid piece of plywood when its openings are too small to be worth it:
    #   S1  the clear width between its two stiles is under c, or
    #   S2  every clear gap between its rails (and between a rail and the frame edge) is under c,
    # and S3 the piece nests: short side <= 606 (two across a 4 x 8 sheet), long side <= 2438. Openings under c save little plywood and
    # cost parts, joints and assembly; a solid piece is one CNC part, stiffer, and takes a clip anywhere.
    SHEET_MM = [1219.2, 2438.4].freeze
    def solidify(spec, frs)
      c = spec['subframe']['solid_below'] or return frs
      c = c.to_f
      frs.map do |f|
        next f if f[:stiles].size < 2
        w = f[:x1] - f[:x0]; h = f[:z1] - f[:z0]
        # S3 (draft 4, A-703: the 1252 x 660 bands of A / D took a sheet each - 16 sheets instead of 11): the short side
        # must leave room for a second strip across the sheet (<= half the sheet width less a kerf), else it stays a frame
        fits = [w, h].min <= SHEET_MM[0] / 2 - 3 + EPS && [w, h].max <= SHEET_MM[1] + EPS
        cw = f[:stiles][1][0] - f[:stiles][0][1]
        zs = [f[:z0]] + f[:rails].sort_by(&:first).flat_map { |a, b, _| [a, b] } + [f[:z1]]
        ch = zs.each_slice(2).map { |a, b| b - a }.max
        next f unless fits && (cw < c - EPS || ch < c - EPS)
        f.merge(stiles: [[f[:x0], f[:x1], "S#{f1(w)}"]], rails: [], solid_rule: cw < c - EPS ? 'S1' : 'S2')
      end
    end

    def solid(a, b, z0, z1, kind)
      { kind: kind, x0: a, x1: b, z0: z0, z1: z1, stiles: [[a, b, "S#{f1(b - a)}"]], rails: [] }
    end

    def strip_mm(w, sf = nil)
      return 152 if w == '6'
      return 98 if w == '4'
      w.to_s.sub('S', '').to_f
    end

    def frame(a, b, z0, z1, kind, vseams, hseams, rows, wn, ww)
      near_lo = ->(e, seams) { seams.any? { |s0, s1| s1 > e + EPS && s0 < e + ww - EPS } }
      near_hi = ->(e, seams) { seams.any? { |s0, s1| s0 < e - EPS && s1 > e - ww + EPS } }
      lw = near_lo.call(a, vseams) ? ww : wn
      rw = near_hi.call(b, vseams) ? ww : wn
      stiles = [[a, r1(a + lw), lw == ww ? '6' : '4'], [r1(b - rw), b, rw == ww ? '6' : '4']]
      bw = near_lo.call(z0, hseams) ? ww : wn
      tw = near_hi.call(z1, hseams) ? ww : wn
      # 2026-10-17 (Main Kitchen): a frame lower than its two edge rails (PIER 2694..2917 = 223 < 152 + 98) is one piece
      return solid(a, b, z0, z1, kind) if z1 - z0 < bw + tw - EPS
      rails = [[z0, r1(z0 + bw), bw == ww ? '6' : '4'], [r1(z1 - tw), z1, tw == ww ? '6' : '4']]
      need = rows.select { |z| z - CLIP_R > z0 + EPS && z + CLIP_R < z1 - EPS }
                 .reject { |z| rails.any? { |c, d, _| z - CLIP_R >= c - EPS && z + CLIP_R <= d + EPS } }
      # 2026-10-17: a horizontal panel joint inside the frame gets a rail behind it (no raw wall through a joint)
      hseams.each do |s0, s1|
        next unless s0 > z0 + EPS && s1 < z1 - EPS
        next if rails.any? { |c, d, _| s0 >= c - EPS && s1 <= d + EPS } || need.any? { |z| s0 >= z - wn / 2 && s1 <= z + wn / 2 }
        need << r1((s0 + s1) / 2.0)
      end
      # rows closer than one 4" rail can carry share one rail centred between them (AP ML Foyer 2026-10-16: two panel
      # rows 55 apart on one band frame gave two overlapping rails); one row per rail as before otherwise
      groups = []
      need.sort.each { |z| groups.last && z - groups.last.first <= wn - 2 * CLIP_R + EPS ? groups.last << z : groups << [z] }
      # 2026-10-17 (Main Kitchen): a clip-row rail must not overlap another rail. It is pushed off an edge / seam rail
      # while it still carries its rows (S09: 6" bottom rail 2694..2846 + the row 2868); two rows too far apart for one
      # 4" rail and too close for two (3040 / 3117 over 2917..3015) share one 6" rail.
      fits = ->(r, g) { g.all? { |z| z - CLIP_R >= r[0] - EPS && z + CLIP_R <= r[1] + EPS } }
      place = lambda do |g, w, code|
        c = (g.first + g.last) / 2.0
        r = [r1(c - w / 2), r1(c + w / 2), code]
        rails.each do |c0, d0, _|
          next unless r[0] < d0 - EPS && r[1] > c0 + EPS
          r = r[0] < c0 ? [r1(c0 - w), c0, code] : [d0, r1(d0 + w), code]
        end
        clash = rails.any? { |c0, d0, _| r[0] < d0 - EPS && r[1] > c0 + EPS }
        fits.(r, g) && !clash ? r : nil
      end
      last = nil
      groups.each do |g|
        r = place.(g, wn, '4')
        if r.nil? && last
          rails.delete(last[:rail])
          both = last[:rows] + g
          r = place.(both, ww, '6')
          g = both if r
        end
        r ||= place.(g, ww, '6')
        raise "rail for rows #{g.inspect} cannot clear the rails #{rails.inspect} of #{f1(a)}..#{f1(b)} z #{f1(z0)}..#{f1(z1)}" unless r
        rails << r
        last = { rail: r, rows: g }
      end
      { kind: kind, x0: a, x1: b, z0: z0, z1: z1, stiles: stiles, rails: rails.sort_by(&:first) }
    end

    # every panel's clip rows before support is checked (frames are laid out on them)
    def clip_rows_all(spec, g)
      return spec['clips']['fixed'].map { |_, _, z| z.to_f }.uniq.sort if spec['clips']['fixed']
      g[:panels].reject { |p| p[:glued] }.flat_map { |p| clip_rows(spec, p) }.uniq.sort
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
        side = fr[:stiles].size == 1 ? 'solid' : (k.zero? ? 'L' : 'R')
        { name: "#{fr[:id]} stile #{side} #{w.to_s.start_with?('S') ? w.to_s.sub('S', '') : (w == '6' ? 152 : 98)}",
          x0: a, x1: b, z0: fr[:z0], z1: fr[:z1], w: w }
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
      # 2026-10-17 (Main Kitchen): the panel recesses were ISSUED to the factory (v1.0) - clips.fixed = [[panel, x, z]]
      # keeps them; the frames are laid out on those rows and every clip is checked for support
      if c['fixed']
        # [panel, x, z, xb, zb, xf]: the issued back / face coordinates are kept to the digit (v1.0 rounded 1233.85 down)
        return c['fixed'].map do |pid, x, z, xb, zb, xf|
          on = mem.any? { |m| x >= m[:x0] && x <= m[:x1] && z >= m[:z0] && z <= m[:z1] }
          { panel: pid, x: x.to_f, z: z.to_f, xb: xb, zb: zb, xf: xf, support: sits?(mem, x, z) ? :ok : (on ? :part : :no) }
        end
      end
      out = []
      g[:panels].each do |p|
        next if p[:glued]   # Main Kitchen W2 / A sill strips (85 high): glued, no clips (v1.0 A-301 note)
        base = [p[:x0] + c['edge'], p[:x1] - c['edge']]
        base.insert(1, (p[:x0] + p[:x1]) / 2.0) if p[:w] > c['wide_panel']
        # a panel too narrow for two columns a clip apart (AP ML Foyer 170 / 180 piers): one column at its centre
        base = [(p[:x0] + p[:x1]) / 2.0] if c['narrow_panel'] && p[:w] < c['narrow_panel']
        backing = frs.select { |f| overlap(f[:x0], f[:x1], p[:x0], p[:x1]) > EPS && overlap(f[:z0], f[:z1], p[:z0], p[:z1]) > EPS }
                     .sort_by { |f| [f[:stiles].size == 1 ? 1 : 0, -overlap(f[:z0], f[:z1], p[:z0], p[:z1])] }
        # 2026-10-19 (AP Dining P05): the clip columns snap to the stiles of a real frame before a solid strip - a solid
        # covers its whole width anyway; snapping to its centre merged two columns onto a pier stile edge
        cols = base.map do |x|
          # 2026-10-19 (AP Dining v2.0 solid pieces): a solid piece never moves a column - the clip sits on it anywhere
          st = backing.reject { |f| f[:stiles].size == 1 }.flat_map { |f| members(f).first(2) }.find { |m| x >= m[:x0] - EPS && x <= m[:x1] + EPS }
          next r1(x) unless st
          r1([[(st[:x0] + st[:x1]) / 2.0, p[:x0] + c['edge_min']].max, p[:x1] - c['edge_min']].min)
        end.uniq
        rows = clip_rows(spec, p)
        rows = rows.each_with_index.map do |z, k|
          next z if cols.all? { |x| sits?(mem, x, z) }
          raise "#{p[:id]}: clip row #{z} has no support and is not the bottom row" unless k.zero?
          if c['row_over_opening']
            c['row_over_opening'].to_f
          else
            # the bottom rail of the frame behind each column, the lowest frame above the row
            # 2026-10-16: also a frame that starts just below the row (its bottom rail centre above the row) - AP ML Foyer
            # closet panels start 10 above the closet head, their bottom row falls on the band's bottom edge
            up = cols.map { |x| frs.select { |f| f[:rails].first && (f[:rails].first[0] + f[:rails].first[1]) / 2.0 > z && x >= f[:x0] - EPS && x <= f[:x1] + EPS }.min_by { |f| f[:z0] } }
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
            xb: c[:xb] || r1(p[:x1] - c[:x]), zb: c[:zb] || r1(c[:z] - p[:z0]), xf: c[:xf] || r1(c[:x] - p[:x0]) }
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
        if f[:stiles].size == 1 && f[:rails].empty?
          # a solid piece: cut as a strip of its shorter side along the sheet length (2026-10-19, Dining band 1405 x 200)
          a, b = [r1(f[:x1] - f[:x0]), r1(f[:z1] - f[:z0])].minmax
          parts[["S#{f1(a)}", b]] += 1
          next
        end
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
      sol = cl.select { |p| p[:w].to_s.start_with?('S') }
      out['solid'] = sol.map { |p| { w: strip_mm(p[:w]), len: p[:len], qty: p[:qty] } } unless sol.empty?
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
      frs = solidify(spec, frames(spec, g))
      cl = clips(spec, g, frs)
      hs = holes(g, cl)
      cut = cut_list(spec, frs)
      st = strips(spec, cut)
      { spec: spec, grid: g, frames: frs, clips: cl, holes: hs, cut: cut, strips: st, sheets: sheets(spec, st),
        blocks: joint_blocks(spec, g, frs), checks: checks(spec, g, frs, cl) }
    end

    # Andriy 2026-10-17: no raw wall may show through a joint. Every joint between two panels (and between a closet
    # panel and the cabinet top under it) must have a frame member behind it, except where the joint lies over an
    # opening (nothing behind). -> [{ joint: 'P60|P61', x0:, x1:, z0:, z1: }] the uncovered parts, sampled at 1 mm
    # 2026-10-19 (AP Dining v2.0, Andriy): with the liner slot strips B / A (Main Kitchen v1.0) the flange ends 25.2 behind
    # the panel edge and the frame 46 behind it - a joint across that zone shows ~20 of wall. Each such joint gets a
    # JOINT BLOCK MDF 6 glued to the wall by UCON (wall face .. 6; strip B is 10.3 off the wall): 20 past the joint each
    # side, from 20 under the flange to the frame edge. -> [{ id:, joint:, x0:, x1:, z0:, z1: }] (none without strips)
    def joint_blocks(spec, g, frs)
      return [] unless spec['openings'].any? { |o| o['liner'] && o['liner']['strips'] }
      mem = frs.flat_map { |f| members(f) }
      ov = ->(a0, a1, b0, b1) { a0 < b1 - EPS && b0 < a1 - EPS }
      n = 0
      joint_gaps(spec, g, frs, blocks: []).map do |r|
        vert = r[:joint].include?('|')        # side by side panels: a vertical joint, the gap runs along z
        if vert
          x0 = r[:x0] - 20; x1 = r[:x1] + 20
          up = mem.select { |m| ov.(m[:x0], m[:x1], x0, x1) && m[:z0] >= r[:z1] - 1 - EPS && m[:z0] <= r[:z1] + 2 + EPS }.map { |m| m[:z0] }.min
          dn = mem.select { |m| ov.(m[:x0], m[:x1], x0, x1) && m[:z1] <= r[:z0] + 1 + EPS && m[:z1] >= r[:z0] - 2 - EPS }.map { |m| m[:z1] }.max
          z0 = dn || r[:z0] - 20; z1 = up || r[:z1] + 20
        else
          z0 = r[:z0] - 20; z1 = r[:z1] + 20
          rt = mem.select { |m| ov.(m[:z0], m[:z1], z0, z1) && m[:x0] >= r[:x1] - 1 - EPS && m[:x0] <= r[:x1] + 2 + EPS }.map { |m| m[:x0] }.min
          lf = mem.select { |m| ov.(m[:z0], m[:z1], z0, z1) && m[:x1] <= r[:x0] + 1 + EPS && m[:x1] >= r[:x0] - 2 - EPS }.map { |m| m[:x1] }.max
          x0 = lf || r[:x0] - 20; x1 = rt || r[:x1] + 20
        end
        n += 1
        { id: format('J%02d', n), joint: r[:joint], x0: r1(x0), x1: r1(x1), z0: r1(z0), z1: r1(z1) }
      end
    end

    def joint_gaps(spec, g, frs, blocks: nil)
      blocks = joint_blocks(spec, g, frs) if blocks.nil?
      j = spec['panels']['joint'].to_f
      mem = frs.flat_map { |f| members(f) }
      ops = spec['openings']
      void = ->(x, z) { ops.any? { |o| x > o['x0'] + EPS && x < o['x1'] - EPS && z < o['h'] - EPS && z > (o['sill'] || -1).to_f + EPS } }
      len = spec['wall']['length'].to_f
      fl = ops.select { |o| o['liner'] }.flat_map do |o|
        f = o['liner']['flange'].to_f; h = o['h'].to_f
        r = [{ x0: o['x0'] - f, x1: o['x1'] + f, z0: h, z1: h + f }]      # head flange (the liner is continuous)
        r << { x0: o['x0'] - f, x1: o['x0'], z0: 0, z1: h + f } if o['x0'] > EPS
        r << { x0: o['x1'], x1: o['x1'] + f, z0: 0, z1: h + f } if o['x1'] < len - EPS
        r << { x0: o['x0'] - f, x1: o['x1'] + f, z0: o['sill'].to_f - f, z1: o['sill'].to_f } if o['sill']   # sill flange
        r
      end
      # beyond the wall end (a 45° corner's long point): the adjoining wall's frame / panel is behind it
      cov = ->(x, z) { x < -EPS || x > len + EPS || void.(x, z) || (mem + fl + blocks).any? { |m| x >= m[:x0] - EPS && x <= m[:x1] + EPS && z >= m[:z0] - EPS && z <= m[:z1] + EPS } }
      rects = []
      ps = g[:panels]
      ps.each do |p|
        ps.each do |q|
          next if p.equal?(q)
          d = q[:x0] - p[:x1]
          if d > EPS && d <= j + EPS
            z0 = [p[:z0], q[:z0]].max; z1 = [p[:z1], q[:z1]].min
            rects << ["#{p[:id]}|#{q[:id]}", p[:x1], q[:x0], z0, z1] if z1 > z0 + EPS
          end
          d = q[:z0] - p[:z1]
          if d > EPS && d <= j + EPS
            x0 = [p[:x0], q[:x0]].max; x1 = [p[:x1], q[:x1]].min
            rects << ["#{p[:id]}/#{q[:id]}", x0, x1, p[:z1], q[:z0]] if x1 > x0 + EPS
          end
        end
        o = ops.find { |x| x['cabinet'] && cab_top(spec, x) && p[:x0] >= x['x0'] - EPS && p[:x1] <= x['x1'] + EPS && p[:z0] > x['h'] - 50 }
        rects << ["#{o['id']} cabinet/#{p[:id]}", p[:x0], p[:x1], [cab_top(spec, o), o['h'].to_f].max, p[:z0]] if o && p[:z0] > [cab_top(spec, o), o['h'].to_f].max + EPS
      end
      out = []
      rects.each do |nm, x0, x1, z0, z1|
        xs = [x0 + 0.5, (x0 + x1) / 2.0, x1 - 0.5].uniq
        zs = [z0 + 0.5, (z0 + z1) / 2.0, z1 - 0.5].uniq
        vert = (x1 - x0) < (z1 - z0)
        if vert
          bad = (z0.ceil..z1.floor).select { |z| xs.any? { |x| !cov.(x, z) } }
          bad.chunk_while { |a, b| b == a + 1 }.each { |r| out << { joint: nm, x0: x0, x1: x1, z0: r.first, z1: r.last } }
        else
          bad = (x0.ceil..x1.floor).select { |x| zs.any? { |z| !cov.(x, z) } }
          bad.chunk_while { |a, b| b == a + 1 }.each { |r| out << { joint: nm, x0: r.first, x1: r.last, z0: z0, z1: z1 } }
        end
      end
      out
    end

    # what a wall must satisfy before anything is drawn; each line is a fact, an empty list is the pass
    def checks(spec, g, frs, cl)
      bad = []
      lmax = spec['subframe']['max_length']
      frs.each do |f|
        if f[:stiles].size == 2 && f[:stiles][0][1] > f[:stiles][1][0] + EPS
          bad << "#{f[:id]}: width #{f1(f[:x1] - f[:x0])} - the two stiles overlap"
        end
        bad << "#{f[:id]}: height #{f1(f[:z1] - f[:z0])} > #{lmax}" if f[:z1] - f[:z0] > lmax + EPS
        bad << "#{f[:id]}: width #{f1(f[:x1] - f[:x0])} > #{lmax}" if f[:x1] - f[:x0] > lmax + EPS
      end
      vseams = vseams_of(g)
      frs.each do |f|
        [f[:x0], f[:x1]].each do |x|
          next if x < EPS || x > spec['wall']['length'] - EPS
          # 2026-10-17: pier frame | LINTEL at a closet / door jamb - the panel joint there is backed by the LINTEL
          next if frs.any? { |l| l[:kind] == 'LINTEL' && ((l[:x0] - x).abs < EPS || (l[:x1] - x).abs < EPS) }
          next if (spec['wall']['ceil'] || []).any? { |c| (c[1].to_f - x).abs < EPS }   # cut at a ceiling step
          s = vseams.find { |s0, s1| x > s0 - 5 && x < s1 + 5 }
          bad << "#{f[:id]}: frame joint x #{f1(x)} in the panel joint #{f1(s[0])}..#{f1(s[1])}" if s
        end
      end
      # 2026-10-17: no raw wall through a joint
      joint_gaps(spec, g, frs).each { |x| bad << "joint #{x[:joint]} shows the wall at x #{f1(x[:x0])}..#{f1(x[:x1])} z #{f1(x[:z0])}..#{f1(x[:z1])}" } if spec['panels']['no_wall_in_joints']
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

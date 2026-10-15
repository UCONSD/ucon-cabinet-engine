# tools/mep/mep_points.rb - MEP rough-in points from a cabinet model, by rule (roles.json) and by project data
# (projects/<name>.json). Pure Ruby, no SketchUp: boxes in, points out, so the same code runs in the test and in the
# LayOut writer. Ruby 2.6-safe.
#
# boxes: [{ 'code', 'x0','x1','y0','y1','z0','z1' }] in mm (the model export, or DrawingSet.collect inside SketchUp).
# A point: { id, sys, sym, x, y, z, item, req, where, status, src, ref, horiz, note }. Points without a position
# (schedule only) have x = nil.
require 'json'

module UCON
  module MEP
    module_function

    DIR = File.expand_path(__dir__)

    def load_json(path)
      JSON.parse(File.read(path))
    end

    def roles
      load_json(File.join(DIR, 'roles.json'))['roles'] # read every time: a SketchUp session keeps the module between loads
    end

    def pick(boxes, a)
      found = boxes.select { |b| b['code'] == a['code'] }
      (a['pick'] || {}).each do |k, v|
        found = found.select { |b| (b[k].to_f - v.to_f).abs < 1.0 }
      end
      raise "STOP: anchor #{a['code']} #{a['pick'].inspect} matches #{found.size} boxes" unless found.size == 1
      found.first
    end

    # the back face of an anchor: a number (a wall, a cladding plane) or a face of the box ('x0', 'y1', ...)
    def back_of(b, a)
      a['back'].is_a?(String) ? b[a['back']].to_f : a['back'].to_f
    end

    def horiz(project, ref_key, x, y, axis_override = nil)
      r = project['refs'][ref_key] or return nil
      axis = axis_override || r['axis']
      d = (axis == 'x' ? x : y) - r['at']
      side = if ref_key == 'CL' then (d < 0 ? 'L of' : 'R of') else 'from' end
      d = d.abs if side == 'from' || ref_key == 'CL'
      { mm: d.round, text: "#{d.round} #{side} #{r['text']}" }
    end

    def points(boxes, project)
      out = []
      project['anchors'].each_with_index do |a, ai|
        b = a['box'] || pick(boxes, a)
        rule = roles[a['role']] or raise "STOP: no role #{a['role']}"
        back = back_of(b, a)
        v = a['v'].to_f
        cu = a['axis'] == 'x' ? (b['x0'] + b['x1']) / 2.0 : (b['y0'] + b['y1']) / 2.0
        # v goes INTO the room from the back face: away from the anchor's far side
        far = a['axis'] == 'x' ? (back == b['y0'] ? b['y1'] : b['y0']) : (back == b['x0'] ? b['x1'] : b['x0'])
        dir = far > back ? 1 : -1
        rule['points'].each do |r|
          p = r.dup
          p['id'] = a['id'] if a['id'] && r['id'] == 'E?'
          p['id'] = a['ids'][r['id']] if a['ids'] && a['ids'][r['id']]
          p['room'] = a['room'] if a['room']
          p['item'] = a['item'] if a['item']
          p['where'] = a['where']
          p['note'] = a['note'] if a['note']
          p['anchor'] = a['code']
          p['group'] = "#{a['role']}-#{ai}"
          p['lab'] = a['lab'] if a['lab']
          if r.key?('u')
            u = cu + r['u'].to_f
            w = back + dir * v
            p['x'], p['y'] = a['axis'] == 'x' ? [u, w] : [w, u]
            p['z'] = r['z'] == 'center' ? (b['z0'] + b['z1']) / 2.0 : r['z'].to_f
            p['ref'] = a['ref']
            h = horiz(project, a['ref'], p['x'], p['y'])
            p['horiz'] = h && h[:text]
            p['horiz_mm'] = h && h[:mm]
          end
          out << p
        end
      end
      project['placed'].each do |r|
        p = r.dup
        h = r["x"] ? horiz(project, r["ref"], r["x"].to_f, r["y"].to_f, r["refaxis"]) : nil
        p['horiz'] = h && h[:text]
        p['horiz_mm'] = h && h[:mm]
        out << p
      end
      out.each { |p| p['room'] ||= project['room']; p['short'] ||= short_label(p) }
      # ELECTRICAL TAILS (Andriy 2026-10-15): feeds out of the floor under tall cabinets / fridge columns and in the
      # island are left as a coiled tail long enough to reach the box after the cabinets are set. tails: [{ ids:, ft:, why: }]
      Array(project['tails']).each do |t|
        t['ids'].each do |id|
          p = out.find { |q| q['id'] == id } or raise "STOP: tail for unknown point #{id}"
          raise "STOP: tail on #{id} - not electrical" unless %w[E L].include?(p['sys'])
          p['tail_ft'] = t['ft']
          p['req'] = "#{p['req']} Leave a #{t['ft']} ft electrical tail out of the floor (#{t['why']})."
        end
      end
      ids = out.map { |p| p['id'] }
      dup = ids.select { |i| ids.count(i) > 1 }.uniq
      raise "STOP: duplicate point ids #{dup.inspect}" unless dup.empty?
      out.sort_by { |p| [%w[E P G M L B].index(p['sys']) || 9, p['id'][1..-1].to_i, p['id']] }
    end

    # The label printed next to a point (Andriy 2026-10-15: receptacles say their type and power right on the drawing).
    # From the symbol and the requirement text, so it can never disagree with the schedule.
    SHORT_TYPE = { 'GFCI' => 'GFCI', 'DUP' => 'REC', 'SPLIT' => 'REC SPLIT', 'J' => 'J-BOX', 'J240' => 'J-BOX', 'LED' => 'LED J-BOX',
                   'R240' => 'REC', 'HW' => 'HW', 'CW' => 'CW', 'DR' => 'DRAIN', 'W' => 'WATER', 'WB' => 'WASHER BOX', 'G' => 'GAS',
                   'DUCT' => 'DUCT' }.freeze
    def short_label(p)
      t = SHORT_TYPE[p['sym']] or return nil
      r = p['req'].to_s
      case p['sys']
      when 'E', 'L'
        v = r[%r{208/240 V|240 V|120 V}] || (p['sys'] == 'L' ? '120 V' : nil)
        a = r[/(\d+) A\b/]
        a ||= '' 
        hw = r =~ /HARDWIRED/i ? ' HW' : ''
        [t, v && v.delete(' '), a.delete(' ')].compact.reject(&:empty?).join(' ') + hw + (r.include?('14-30R') ? ' 14-30R' : '')
      when 'P'
        d = r[%r{\d+(?: \d/\d)?"|\d/\d"}]
        [t, d].compact.join(' ')
      when 'G' then 'GAS + VALVE'
      when 'M' then r[/(\d+)" (?:round |rigid )?/] ? "DUCT #{r[/(\d+)"/]}" : t
      else t
      end
    end

    # PLUMBING ZONES (Andriy 2026-10-15): a rectangle on the elevation that holds all the plumbing of one fixture,
    # dimensioned, so the plumber has room to move inside it. One zone per anchor (group) of P / W points: their
    # bounding box + ZONE_MARGIN, rounded OUT to ZONE_ROUND.
    ZONE_MARGIN = 75
    ZONE_ROUND = 25
    def plumbing_zones(pts)
      out = []
      pts.select { |p| %w[P].include?(p['sys']) && p['x'] && p['group'] }.group_by { |p| p['group'] }.each do |g, ps|
        lo = ->(v) { ((v - ZONE_MARGIN) / ZONE_ROUND).floor * ZONE_ROUND }
        hi = ->(v) { ((v + ZONE_MARGIN) / ZONE_ROUND).ceil * ZONE_ROUND }
        out << { 'group' => g, 'ids' => ps.map { |p| p['id'] },
                 'x0' => lo.(ps.map { |p| p['x'] }.min), 'x1' => hi.(ps.map { |p| p['x'] }.max),
                 'y0' => lo.(ps.map { |p| p['y'] }.min), 'y1' => hi.(ps.map { |p| p['y'] }.max),
                 'z0' => [lo.(ps.map { |p| p['z'] }.min), 0].max, 'z1' => hi.(ps.map { |p| p['z'] }.max) }
      end
      out
    end

    # BLOCKING (Andriy 2026-10-15): one 2x6 per zone, its axis 50 below the top edge of what hangs on it, on the same
    # axis as the hanging rail. Zones = runs of wall-hung bodies (and floor-standing talls, anchored at the top) on one
    # wall; mirrors are their own zones. Bodies touching each other (gap <= 60) with the same top make one run.
    # boxes: string-keyed; along 'x'/'y'; wall_at: the wall plane on the other axis; face: 'y1' / 'y0' / 'x0' / 'x1' =
    # the face of the body that touches that wall.
    BLOCK_BELOW_TOP = 50
    BLOCK_H = 140 # 2x6 actual 5 1/2"
    def blocking(boxes, along:, face:, wall_at:, prefix: 'B', start: 1, extra: [])
      a0, a1 = along == 'x' ? %w[x0 x1] : %w[y0 y1]
      on = boxes.select do |b|
        (b[face].to_f - wall_at).abs <= 60 && (b['z0'].to_f > 100 || b['z1'].to_f > 2000) &&
          %w[cabinet filler panel accessory].include?(b['cls'].to_s)
      end
      groups = on.group_by { |b| [b['cls'] == 'accessory' ? 'mirror' : 'cab', (b['z1'].to_f / 10).round] }
      zones = []
      groups.each do |(kind, _), bs|
        bs.sort_by { |b| b[a0] }.each do |b|
          last = zones.reverse.find { |z| z[:kind] == kind && z[:top] == b['z1'].round }
          if last && b[a0] - last[:a1] <= 60
            last[:a1] = [last[:a1], b[a1]].max; last[:codes] << b['code']
          else
            zones << { kind: kind, a0: b[a0].to_f, a1: b[a1].to_f, top: b['z1'].round, codes: [b['code']] }
          end
        end
      end
      zones.reject! { |z| z[:a1] - z[:a0] < 150 } # end panels and top fillers on edge are not a zone
      zones.concat(extra)
      zones.sort_by { |z| [-z[:top], z[:a0]] }.each_with_index.map do |z, i|
        { 'id' => "#{prefix}#{start + i}", 'sys' => 'B', 'a0' => z[:a0].round, 'a1' => z[:a1].round, 'cl' => z[:top] - BLOCK_BELOW_TOP,
          'h' => BLOCK_H, 'item' => "2x6 blocking, CL #{z[:top] - BLOCK_BELOW_TOP} AFF (#{z[:kind] == 'mirror' ? 'mirror' : 'top of ' + z[:codes].uniq.join(' ')} at #{z[:top]})",
          'status' => 'DECISION', 'src' => 'Andriy 2026-10-15: 2x6, axis 50 below the top edge, on the hanging rail axis' }
      end
    end
  end
end

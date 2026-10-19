# UCON::RoomSnapshot - one ROOM of wall-panel walls (each its own WallPanels JSON) -> the snapshot JSON the multi-wall
# LayOut writers read (format of tools/wallpanels/walls/AP_MF_Main_Kitchen.json: walls / levels / panels / frames /
# holes / sheets), plus the factory drilling CSV, the UCON CNC frame CSV and the cut list.
#
# PURE RUBY (2.6-safe, no SketchUp). Every number comes from UCON::WallPanels.build of each wall; the room JSON only adds
# order, wall ends, sheet texts and questions. Written 2026-10-16 for AP Capital ML Foyer (room AP_ML_Foyer.json).
# Wall-local s = the wall's x; the model origin of each wall is its origin_model_x along +x, face toward -y.
require 'json'
require_relative 'wall_panels'

module UCON
  module RoomSnapshot
    WP = UCON::WallPanels
    module_function

    def build(room_path)
      dir = File.dirname(room_path)
      room = JSON.parse(File.read(room_path))
      specs = room['walls'].map { |f| WP.load(File.join(dir, f)) }
      outs = specs.map { |s| WP.build(s) }
      bad = specs.zip(outs).reject { |_, o| o[:checks].empty? }
      raise "wall checks failed: #{bad.map { |s, o| "#{s['id']}: #{o[:checks].join(' | ')}" }.join(' || ')}" unless bad.empty?
      ids = outs.flat_map { |o| o[:grid][:panels].map { |p| p[:id] } }
      raise "panel ids repeat across walls: #{ids.select { |i| ids.count(i) > 1 }.uniq.inspect}" if ids.uniq.size != ids.size
      fids = outs.flat_map { |o| o[:frames].map { |f| f[:id] } }
      raise "frame ids repeat across walls: #{fids.select { |i| fids.count(i) > 1 }.uniq.inspect}" if fids.uniq.size != fids.size
      s0 = specs.first
      snap = {
        'id' => room['id'], 'model' => room['model'],
        '_about' => "Snapshot of #{room['walls'].join(', ')} made by tools/wallpanels/room_snapshot.rb - do not edit, regenerate.",
        'levels' => { 'subfloor' => 0, 'ffl' => s0['levels']['ffl'], 'stone_top' => s0['levels']['stone_top'], 'stone' => s0['levels']['stone'], 'floor_gap' => s0['subframe']['floor_gap'],
                      'tier_joint' => s0['subframe']['tier_joint'],
                      'seam' => specs.zip(outs).map { |s, o| [wid(s), o[:grid][:seam_z]] }.to_h },
        'build_up' => s0['build_up'].merge('rebate' => specs.flat_map { |s| s['openings'] }.map { |op| op['rebate'] && op['rebate']['depth'] }.compact.max || 0),
        'clips' => s0['clips'],
        'walls' => [], 'panels' => [], 'frames' => {}, 'holes' => [], 'stone' => {}, 'doors' => [],
        'files' => room['files'], 'sheets' => room['sheets']
      }
      specs.zip(outs).each do |s, o|
        w = wid(s)
        len = s['wall']['length'].to_f; hgt = s['wall']['height'].to_f
        snap['walls'] << {
          'id' => w, 'code' => s['id'].split('_').last, 'L' => len, 'ceil' => s['wall']['ceil'] || [[0, len, hgt]],
          'ends' => (room['ends'] || {})[w] || s['wall']['ends'],
          'openings' => s['openings'].map do |op|
            k = %w[door window niche].include?(op['kind']) ? op['kind'] : (op['depth'] ? 'closet' : 'opening')
            h = { 'kind' => k, 'id' => op['id'], 's0' => op['x0'], 's1' => op['x1'], 'z0' => op['sill'] || 0, 'z1' => op['h'],
                  'label' => op['label'], 'short' => op['short'] }
            h['liner'] = op['liner'] if op['liner']
            if op['cabinet']
              h['cabinet'] = op['cabinet']
              cb = op['cabinet']; ct = WP.cab_top(s, op)
              h['cab'] = { 'x0' => op['x0'] + cb['side_gap'], 'x1' => op['x1'] - cb['side_gap'], 'top' => ct }
            end
            if k == 'door'
              gs = op['frame']['gap_side'].to_f
              ci = (op['clad_inset'] || 55.5).to_f
              h['clad'] = [op['x0'] + ci, op['x1'] - ci, op['leaf']['floor_gap'], op['leaf']['floor_gap'] + op['leaf']['h']]
              h['leaves'] = op['leaf']['leaves'] || 1
            end
            h
          end,
          'wf' => s['wall']['wf'] || [[s['origin_model_x'].to_f, 0], [1, 0], [0, -1]],
          'plan_wf' => plan_wf((room['plan'] || {})[w], len)
        }
        o[:grid][:panels].each do |p|
          snap['panels'] << { 'wall' => w, 'id' => p[:id], 's0' => p[:x0], 's1' => p[:x1], 'z0' => p[:z0], 'z1' => p[:z1],
                              'kind' => p[:row], 'pos' => p[:pos], 'mitre_start' => p[:mitre_start] ? true : false, 'mitre_end' => p[:mitre_end] ? true : false,
                              'rebates' => (p[:rebates] || []).map do |x0, x1, z0, z1|
                                d = s['openings'].find { |op| op['rebate'] && x0 >= op['x0'] - 200 && x1 <= op['x1'] + 200 }
                                { 'door' => d && d['id'], 's0' => x0, 's1' => x1, 'z0' => z0, 'z1' => z1 }
                              end,
                              'holes' => o[:holes].count { |h| h[:panel] == p[:id] } }
        end
        snap['frames'][w] = {
          'frames' => o[:frames].map do |f|
            { 'id' => f[:id], 'kind' => f[:kind], 'x0' => f[:x0], 'x1' => f[:x1], 'z0' => f[:z0], 'z1' => f[:z1],
              'stiles' => f[:stiles].map { |a, b, k| [a, b, k] }, 'rails' => f[:rails].map { |a, b, k| [a, b, k] } }
          end,
          'clips' => o[:clips].map { |c| { 'panel' => c[:panel], 'x' => c[:x], 'z' => c[:z], 'ok' => c[:support] == :ok } }
        }
        st = s['levels']['stone_top']
        snap['stone'][w] = o[:grid][:panels].select { |p| st && (p[:z0] - st).abs < 0.05 }.map { |p| [p[:x0], p[:x1]] }.sort if st
        snap['stone'][w] = s['levels']['stone_runs'] if s['levels']['stone_runs']   # as built (Main Kitchen v1.0)
        # door coordinates in the MODEL: the wall's frame wf (origin, t along, n into the room); doors only on walls
        # running along +x, face toward -y (ML Foyer B, Main Kitchen Wall 2) - the door pages cut along x
        (wox, woy), wt, wn = s['wall']['wf'] || [[s['origin_model_x'].to_f, 0], [1, 0], [0, -1]]
        ox = wox.to_f
        s['openings'].select { |op| op['kind'] == 'door' }.each do |op|
          raise "door #{op['id']}: wall #{w} does not run along +x" unless wt == [1, 0] && wn == [0, -1]
          f = op['frame']; gs = f['gap_side'].to_f; hz = op['h'].to_f - f['gap_head'].to_f
          snap['doors'] << {
            'id' => op['id'], 'wall' => w, 'hinge' => op['hinge'] || 'both', 'leaves' => op['leaf']['leaves'] || 1,
            'open_x' => [WP.r1(ox + op['x0']), WP.r1(ox + op['x1'])], 'frame_x' => [WP.r1(ox + op['x0'] + gs), WP.r1(ox + op['x1'] - gs)],
            'clad_x' => [WP.r1(ox + op['x0'] + (op['clad_inset'] || 55.5).to_f), WP.r1(ox + op['x1'] - (op['clad_inset'] || 55.5).to_f)], 'jamb_y' => [woy + f['jamb_y0'], woy + f['jamb_y1']],
            'head_z' => [hz - f['head'].to_f, hz], 'section_x' => op['section_x'] || ox + op['x0'] + (op['x1'] - op['x0']) / 4.0,
            'wall_face_y' => woy, 'wall_t' => f['wall_t'], 'plan_z' => 1000, 'handing' => op['handing'],
            'gap_side' => gs, 'gap_head' => f['gap_head'], 'jamb' => f['jamb'], 'leaf_joint' => op['leaf']['joint'] || 10,
            'scenes' => op['scenes'], 'cams' => op['cams'], 'profile' => op['profile'] || 'clad',
            'leaf_t' => op['leaf']['t'], 'leaf_step' => op['leaf']['step']
          }
        end
        o[:holes].each do |h|
          snap['holes'] << { 'id' => h[:id], 'panel' => h[:panel], 'wall' => w, 's' => h[:x], 'z' => h[:z],
                             'xb' => h[:xb], 'zb' => h[:zb], 'xf' => h[:xf] }
        end
      end
      ctx = Ctx.new(snap)
      snap['sheets'] = resolve(expand(JSON.parse(JSON.generate(snap['sheets'])), snap), ctx)
      [snap, specs, outs]
    end

    # Sheet texts (questions, notes) carry their numbers as {{expr}} tokens, evaluated against the snapshot, so no
    # number in a text is typed by hand (Andriy's rule). Helpers: w h z0 z1 (panel), ow oh (opening), cab_top, ffl,
    # stone, seam(wall), gap_over(closet) - see Ctx. Numbers print to 0.1 (0.01 if needed); a failing token raises.
    class Ctx
      def initialize(snap)
        @s = snap
      end

      def pn(id)
        @s['panels'].find { |p| p['id'] == id } || raise("{{}}: no panel #{id}")
      end
      def op(id)
        @s['walls'].flat_map { |w| w['openings'] }.find { |o| o['id'] == id } || raise("{{}}: no opening #{id}")
      end
      def w(id)
        pn(id)['s1'] - pn(id)['s0']
      end
      def h(id)
        pn(id)['z1'] - pn(id)['z0']
      end
      def z0(id)
        pn(id)['z0']
      end
      def z1(id)
        pn(id)['z1']
      end
      def ow(id)
        op(id)['s1'] - op(id)['s0']
      end
      def oh(id)
        op(id)['z1']
      end
      def ffl
        @s['levels']['ffl']
      end
      def stone
        @s['levels']['stone_top']
      end
      def seam(wid)
        sm = @s['levels']['seam']
        (sm.is_a?(Hash) ? sm[wid] : sm)[0]
      end
      def upper(wid)
        sm = @s['levels']['seam']
        (sm.is_a?(Hash) ? sm[wid] : sm)[1]
      end
      def cab_top(id)
        cb = op(id)['cabinet'] || raise("{{}}: no cabinet at #{id}")
        return oh(id) - cb.fetch('top_gap', 0) if cb['fit_niche'] || !cb['tm_top_ffl']
        ffl + cb['tm_top_ffl']
      end

      def cab(id)
        op(id)['cabinet'] || raise("{{}}: no cabinet at #{id}")
      end
      # the panel over a closet: the one whose span covers the closet
      def over(id)
        o = op(id)
        wid = @s['walls'].find { |x| x['openings'].include?(o) }['id']; mid = (o['s0'] + o['s1']) / 2.0
        @s['panels'].find { |p| p['wall'] == wid && p['s0'] < mid && p['s1'] > mid && p['z0'] >= o['z1'] - 0.05 } || raise("{{}}: nothing over #{id}")
      end
      def gap_over(id)
        over(id)['z0'] - cab_top(id)
      end
      def dr(id)
        @s['doors'].find { |d| d['id'] == id } || raise("{{}}: no door #{id}")
      end

      def ln(id)
        op(id)['liner'] || raise("{{}}: no liner at #{id}")
      end

      def bu
        @s['build_up']
      end

      def stn
        @s['levels']['stone'] || raise('{{}}: no levels.stone')
      end

      def rebated
        @s['panels'].reject { |p| p['rebates'].empty? }.map { |p| p['id'] }.sort.join(', ')
      end

      def pier(a, b)
        op(b)['s0'] - op(a)['s1']
      end

      def tail(wid, a)
        @s['walls'].find { |x| x['id'] == wid }['L'] - op(a)['s1']
      end

      def tm_top(id)
        ffl + cab(id)['tm_top_ffl']
      end

      def ox(wid)
        @s['walls'].find { |x| x['id'] == wid }['wf'][0][0]
      end

      def fy(wid)
        @s['walls'].find { |x| x['id'] == wid }['wf'][0][1]
      end

      def pb
        -bu['face'] + bu['panel_t']
      end

      def range(*ids)
        ids.map { |i| h(i) }.minmax
      end
      def ev(src)
        instance_eval(src)
      end
    end

    def num(v)
      return v.map { |x| num(x) }.join(' - ') if v.is_a?(Array)
      return v.to_s unless v.is_a?(Numeric)
      r = v.round(2)
      (r - r.round(1)).abs < 0.005 ? ((r - r.round).abs < 0.05 ? r.round.to_s : format('%.1f', r)) : format('%.2f', r)
    end

    def resolve(v, ctx)
      case v
      when String then v.gsub(/\{\{(.+?)\}\}/) { num(ctx.ev(Regexp.last_match(1))) }
      when Array then v.map { |x| resolve(x, ctx) }
      when Hash then v.transform_values { |x| resolve(x, ctx) }
      else v
      end
    end

    # the wall's frame in PLAN for the key plan (the model may hold unfolded elevations only): room.plan.<wall> =
    # { start: [x, y] | end: [x, y], t: [tx, ty], n: [nx, ny] (into the room) } -> [[ox, oy], t, n]; nil = use 'wf'
    def plan_wf(pl, len)
      return nil unless pl
      t = pl['t']; n = pl['n']
      o = pl['start'] || [pl['end'][0] - len * t[0], pl['end'][1] - len * t[1]]
      [o, t, n]
    end

    # page_notes keys 'X:*' -> one key per wall ({w} = the wall id), 'A-5:*' -> one per door ({d} = the door id)
    def expand(sheets, snap)
      pn = sheets['page_notes'] or return sheets
      out = {}
      pn.each do |k, v|
        if k == 'A-5:*'
          snap['doors'].each { |d| out["A-5:#{d['id']}"] = JSON.parse(JSON.generate(v).gsub('{d}', d['id'])) }
        elsif k.end_with?(':*')
          snap['walls'].each { |w| out[k.sub('*', w['id'])] = JSON.parse(JSON.generate(v).gsub('{w}', w['id'])) + (pn[k.sub('*', w['id'])] || []) }
        elsif !out.key?(k)
          out[k] = v
        end
      end
      sheets.merge('page_notes' => out)
    end

    def wid(spec)
      spec['wall']['name'] || spec['id'].split('_').last
    end

    # snapshot JSON + the three CSVs into out_dir; refuses to overwrite
    def write(room_path, out_dir, rev)
      snap, specs, outs = build(room_path)
      f = snap['files']
      paths = { snap: File.join(out_dir, "#{snap['id']}_snapshot_v#{rev}.json"),
                panels: File.join(out_dir, f['panels_csv'].sub('{rev}', rev)),
                frames: File.join(out_dir, f['frames_csv'].sub('{rev}', rev)),
                cut: File.join(out_dir, f['cut_list']) }
      paths.each_value { |p| raise "exists, not overwriting: #{p}" if File.exist?(p) }
      File.write(paths[:snap], JSON.pretty_generate(snap))
      prow = specs.zip(outs).flat_map { |s, o| WP.panel_csv_rows(s, o[:grid], o[:holes]) }
      frow = specs.zip(outs).flat_map { |s, o| WP.frame_csv_rows(s, o[:frames], o[:holes]) }
      WP.write_csv(paths[:panels], WP::PANEL_CSV_HEAD, prow)
      WP.write_csv(paths[:frames], WP::FRAME_CSV_HEAD, frow)
      cut = Hash.new(0)
      outs.each { |o| o[:cut].each { |c| cut[[WP.strip_mm(c[:w]), c[:len]]] += c[:qty] } }
      WP.write_csv(paths[:cut], ['strip width (mm)', 'length (mm)', 'qty'],
                   cut.sort_by { |(w, l), _| [-w, -l] }.map { |(w, l), q| [WP.f1(w), WP.f1(l), q] })
      { paths: paths, panels: snap['panels'].size, holes: prow.size, frame_rows: frow.size, cut_rows: cut.size }
    end
  end
end

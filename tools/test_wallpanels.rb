# tools/test_wallpanels.rb - the wall-panel generators against the one wall they were written from.
#
#   /usr/bin/ruby tools/test_wallpanels.rb
#
# Regenerates AP Capital REC -> LAU from tools/wallpanels/walls/AP_BF_Recreation_Laundry.json and compares,
# number by number, with what was built and issued by hand on 2026-10-07/08:
#   fixtures/rec_lau_model_568.json        panels, clips and frame members read out of the model (probe 568)
#   fixtures/rec_lau_probe_566_570.json    frames F01-F15 as applied (566) and the hole ids (570)
#   fixtures/rec_lau_drilling_panels.csv   the factory list, as sent (Drive, UCON Drilling 2026-10-07)
#   fixtures/rec_lau_drilling_frames_CNC_S.csv  the CNC list with S numbers (set v1.1, probe 597)
# plus the cut list and sheet count printed on A-702. A difference is a failure, printed with both values.
require 'json'
require 'csv'
require_relative 'wallpanels/wall_panels'

WP = UCON::WallPanels
DIR = File.join(__dir__, 'wallpanels')
FIX = File.join(DIR, 'fixtures')
$checks = 0
$fails = []

def check(what, got, want)
  $checks += 1
  return if got == want
  $fails << "#{what}\n    got:  #{got.inspect}\n    want: #{want.inspect}"
end

def near(a, b, tol = 0.051)
  (a - b).abs <= tol
end

spec = WP.load(File.join(DIR, 'walls', 'AP_BF_Recreation_Laundry.json'))
# v1.2 (Andriy 2026-10-17): frames 10 off the floor, no raw wall in a joint. The fixtures below are v1.1 as built
# (frames from 25), so sections 1.. regenerate v1.1 with floor_gap 25; the v1.2 delta is checked right here.
v12 = WP.build(spec)
check('REC-LAU v1.2: floor_gap', spec['subframe']['floor_gap'], 10)
check('REC-LAU v1.2: no raw wall in a joint', WP.joint_gaps(spec, v12[:grid], v12[:frames]), [])
check('REC-LAU v1.2: lower frames from 10', v12[:frames].select { |f| f[:z0] < 100 }.map { |f| f[:z0] }.uniq, [10.0])
spec = JSON.parse(JSON.generate(spec)); spec['subframe']['floor_gap'] = 25
out = WP.build(spec)
check('REC-LAU v1.2 vs v1.1: panels, clips, holes unchanged', [v12[:grid][:panels], v12[:clips], v12[:holes]] == [out[:grid][:panels], out[:clips], out[:holes]], true)
g = out[:grid]
m568 = JSON.parse(File.read(File.join(FIX, 'rec_lau_model_568.json')))
p566 = JSON.parse(File.read(File.join(FIX, 'rec_lau_probe_566_570.json')))

# ---- 1. panels: ids, positions, boxes (model 568) ------------------------------------------------
want = m568['panels'].map { |p| b = p['box']; [p['name'][0, 3], p['name'][/C\d-[LU]/], b['x0'], b['x1'], b['z0'], b['z1']] }.sort
got = g[:panels].map { |p| [p[:id], p[:pos], p[:x0], p[:x1], p[:z0], p[:z1]] }.sort
check('panels: count', got.size, want.size)
got.zip(want).each do |a, b|
  ok = a[0, 2] == b[0, 2] && a[2..-1].zip(b[2..-1]).all? { |x, y| near(x, y) }
  check("panel #{b[0]}", ok ? b : a, b)
end
check('panels: names as drawn', g[:panels].map { |p| format('%s %s | %.1f x %.1f x 22', p[:id], p[:pos], p[:w], p[:h]) }.sort,
      m568['panels'].map { |p| p['name'] }.sort)
check('panels: rebated at D01', g[:panels].reject { |p| p[:rebates].empty? }.map { |p| p[:id] }, %w[P06 P07 P08 P09 P13])
check('panels: area m2 (A-701 total 16.80)', (g[:panels].sum { |p| p[:w] * p[:h] } / 1e6).round(2), 16.8)

# ---- 2. frames: the 15 frames of 566 (F -> S), member by member ----------------------------------
fr = out[:frames]
check('frames: count', fr.size, p566['frames'].size)
p566['frames'].each_with_index do |w, i|
  f = fr[i] or next
  sid = w['n'].sub('F', 'S')
  check("#{sid}: id", f[:id], sid)
  check("#{sid}: kind", f[:kind], w['kind'])
  check("#{sid}: box", [f[:x0], f[:x1], f[:z0], f[:z1]].map(&:to_f), [w['x0'], w['x1'], w['z0'], w['z1']].map(&:to_f))
  check("#{sid}: stiles", f[:stiles].map { |a, b, s| [a.to_f, b.to_f, s] }, w['stiles'].map { |a, b, s| [a.to_f, b.to_f, s] })
  check("#{sid}: rails", f[:rails].map { |a, b, s| [a.to_f, b.to_f, s] }, w['rails'].map { |a, b, s| [a.to_f, b.to_f, s] })
end
# member boxes against the model (names F -> S, as renamed in 585)
mm = m568['frames'].flat_map { |f| f['members'].map { |x| b = x['box']; [x['name'].sub(/\AF/, 'S'), b['x0'], b['x1'], b['z0'], b['z1']] } }.sort
gm = fr.flat_map { |f| WP.members(f).map { |x| [x[:name], x[:x0], x[:x1], x[:z0], x[:z1]] } }.sort
check('frame members: count', gm.size, mm.size)
gm.zip(mm).each { |a, b| check("member #{b[0]}", a[0] == b[0] && a[1..-1].zip(b[1..-1]).all? { |x, y| near(x, y) } ? b : a, b) }

# ---- 3. clips (566 as applied, 568 as read back) -------------------------------------------------
cl = out[:clips]
check('clips: count', cl.size, 103)
check('clips: as applied in 566', cl.map { |c| [c[:panel], c[:x], c[:z].to_f] }, p566['clips'].map { |p, x, z| [p, x.to_f, z.to_f] })
check('clips: as read from the model (568)', cl.map { |c| [c[:panel], c[:x], c[:z]] }.sort,
      m568['clips'].map { |c| [c['panel'], c['x'], c['z']] }.sort)
check('clips: all on backing', cl.map { |c| c[:support] }.uniq, [:ok])

# ---- 4. holes: ids and positions (570) -----------------------------------------------------------
hs = out[:holes]
check('holes', hs.map { |h| [h[:id], h[:x], h[:z].to_f] }, p566['holes'].map { |i, x, z| [i, x.to_f, z.to_f] })

# ---- 5. the two CSVs, text for text ----------------------------------------------------------------
pr = WP.panel_csv_rows(spec, g, hs)
want = CSV.read(File.join(FIX, 'rec_lau_drilling_panels.csv'))
check('panels CSV: header', WP::PANEL_CSV_HEAD, want[0])
check('panels CSV: rows', pr.size, want.size - 1)
pr.zip(want[1..-1]).each { |a, b| check("panels CSV #{b[0]}", a, b) }
frw = WP.frame_csv_rows(spec, fr, hs)
want = CSV.read(File.join(FIX, 'rec_lau_drilling_frames_CNC_S.csv'))
check('frames CSV: header', WP::FRAME_CSV_HEAD, want[0])
check('frames CSV: rows', frw.size, want.size - 1)
frw.zip(want[1..-1]).each { |a, b| check("frames CSV #{b[-1]}", a, b) }

# ---- 6. cut list and sheets (A-702 v1.1) ------------------------------------------------------------
cut_a702 = [['4"', 2355, 9], ['4"', 820, 6], ['4"', 732, 9], ['4"', 691, 2], ['4"', 681, 2], ['4"', 667, 2], ['4"', 626, 6],
            ['4"', 607, 1], ['4"', 602, 6], ['4"', 585, 6], ['4"', 376, 6], ['4"', 372, 6],
            ['6"', 2355, 3], ['6"', 820, 1], ['6"', 732, 3], ['6"', 626, 1], ['6"', 607, 5], ['6"', 602, 1], ['6"', 585, 1],
            ['6"', 376, 1], ['6"', 372, 1]]
check('cut list (A-702)', WP.cut_list_print(out[:cut]), cut_a702)
st = out[:strips]
check('4" parts / metres / strips', [st['4'][:pieces], st['4'][:metres], st['4'][:strips]], [61, 52.8, 23])
check('6" parts / metres / strips', [st['6'][:pieces], st['6'][:metres], st['6'][:strips]], [17, 15.7, 7])
check('sheets 4 x 8', out[:sheets].size, 3)

# ---- 7. the wall's own checks, and the D-sheet split ------------------------------------------------
check('wall checks', out[:checks], [])
check('D-sheets carry every panel once', spec['sheets']['drill'].values.flatten.sort, g[:panels].map { |p| p[:id] }.sort)

# ---- 8. a second wall from the same rules: no numbering, no column counts, no legacy row ------------
s2 = JSON.parse(JSON.generate(spec))
s2['panels'].delete('numbering'); s2['panels'].delete('columns'); s2['clips'].delete('row_over_opening')
o2 = WP.build(s2)
check('auto: same columns as the TM layout', o2[:grid][:cols], g[:cols])
check('auto: 15 panels numbered 1..15', o2[:grid][:panels].map { |p| p[:id] }, (1..15).map { |i| format('P%02d', i) })
check('auto: bottom row over openings on the rail centre', o2[:clips].map { |c| c[:z] }.uniq.sort.select { |z| z > 2500 && z < 2600 }, [2554.0])
check('auto: checks pass', o2[:checks], [])

# ---- 9. AP ML Foyer, band layout (2026-10-16): R1 solid strip, R2 band frames, R3 jamb setback ---------
# 2026-10-17: band cut at every panel joint, LINTEL over closets / door, jamb_setback 0
{ 'A' => [9, 14, 69, 4], 'B' => [9, 14, 78, 2] }.each do |w, (np, nf, nc, nsol)|
  sf = WP.load(File.join(DIR, 'walls', "AP_ML_Foyer_#{w}.json"))
  of = WP.build(sf)
  check("foyer #{w}: panels / frames / clips", [of[:grid][:panels].size, of[:frames].size, of[:clips].size], [np, nf, nc])
  check("foyer #{w}: checks pass", of[:checks], [])
  check("foyer #{w}: every clip fully supported", of[:clips].reject { |c| c[:support] == :ok }, [])
  check("foyer #{w}: solid strips", of[:frames].count { |f| f[:stiles].size == 1 }, nsol)
  band = of[:frames].select { |f| f[:kind] == 'BAND' }
  check("foyer #{w}: band covers the wall", [band.first[:x0], band.last[:x1]], [0.0, sf['wall']['length'].to_f])
  check("foyer #{w}: band pieces <= 2438", band.all? { |f| f[:x1] - f[:x0] <= 2438 }, true)
  jambs = sf['openings'].flat_map { |o| [[o['x0'], o], [o['x1'], o]] }.reject { |x, _| x <= 0 || x >= sf['wall']['length'] }
  near = of[:frames].reject { |f| f[:kind] == 'BAND' }.select do |f|
    jambs.any? { |x, o| d = (o['frame_setback'] || sf['subframe']['jamb_setback']).to_f; [(f[:x0] - x).abs, (f[:x1] - x).abs].min.between?(0.05, d - 0.05) }
  end
  check("foyer #{w}: pier frames keep each jamb's setback (closet / door 0, liner 56)", near.map { |f| f[:id] }, [])
  ids = w == 'B' ? (47..55) : (56..64)
  check("foyer #{w}: TM panel numbers", of[:grid][:panels].map { |p| p[:id] }.sort, ids.map { |i| "P#{i}" })
  # no raw wall through a joint (Andriy 2026-10-17; liner flange widened to the frame - variant 2)
  check("foyer #{w}: every joint backed by a frame or the liner flange", WP.joint_gaps(sf, of[:grid], of[:frames]), [])
  check("foyer #{w}: liner flange reaches the frame", sf['openings'].select { |o| o['liner'] }.map { |o| o['liner']['flange'] == o['frame_setback'] }.uniq, [true])
  check("foyer #{w}: frame ids", of[:frames].map { |f| f[:id] }, (w == 'B' ? (1..14) : (15..28)).map { |i| format('S%02d', i) })
end

# ---- 10. AP Main Kitchen on the generator (2026-10-17): panels GIVEN as issued (v1.0), frames generated by the band
# rules + windows (sill frames), every joint backed, the issued panel recesses unchanged to the digit
mk = JSON.parse(File.read(File.join(DIR, 'walls', 'AP_MF_Main_Kitchen.json')))
fids = []
%w[W1 W2 A B C D].each do |c|
  sk = WP.load(File.join(DIR, 'walls', "AP_MF_Kitchen_#{c}.json"))
  ok = WP.build(sk)
  wid = sk['wall']['name']
  check("kitchen #{c}: checks pass", ok[:checks], [])
  check("kitchen #{c}: no raw wall in a joint", WP.joint_gaps(sk, ok[:grid], ok[:frames]), [])
  check("kitchen #{c}: panels as issued", ok[:grid][:panels].map { |q| [q[:id], q[:x0], q[:x1], q[:z0], q[:z1]] }.sort,
        mk['panels'].select { |q| q['wall'] == wid }.map { |q| [q['id'], q['s0'].to_f, q['s1'].to_f, q['z0'].to_f, q['z1'].to_f] }.sort)
  check("kitchen #{c}: panel recesses as issued", ok[:holes].map { |h| [h[:id], h[:xb], h[:zb], h[:xf]] }.sort,
        mk['holes'].select { |h| h['wall'] == wid }.map { |h| [h['id'], h['xb'], h['zb'], h['xf']] }.sort)
  check("kitchen #{c}: rebates as issued", ok[:grid][:panels].map { |q| [q[:id], q[:rebates].map { |r| r.map { |v| v.round(1) } }] }.sort,
        mk['panels'].select { |q| q['wall'] == wid }.map { |q| [q['id'], q['rebates'].map { |r| [r['s0'], r['s1'], r['z0'], r['z1']].map { |v| v.round(1) } }] }.sort)
  fids.concat(ok[:frames].map { |f| f[:id] })
end
check('kitchen: frame ids S01.. in sequence across the six walls, no repeats', fids, (1..fids.size).map { |i| format('S%02d', i) })

# ---- 11. AP Safe / AV (2026-10-17): our survey (probe 812c), TM pull doors centred in our openings, panels 3 from the
# leaves, free spans split equally (Andriy); profile tm_pull (no stops / casings / cladding, leaf flush with the panels)
require_relative 'wallpanels/room_extras'
ss = WP.load(File.join(DIR, 'walls', 'AP_BF_Safe_AV.json'))
so = WP.build(ss)
check('safe-av: checks pass', so[:checks], [])
check('safe-av: no raw wall in a joint', WP.joint_gaps(ss, so[:grid], so[:frames]), [])
check('safe-av: TM numbers P01-P14', so[:grid][:panels].map { |q| q[:id] }.sort, (1..14).map { |i| format('P%02d', i) })
sp = so[:grid][:panels].to_h { |q| [q[:id], q] }
check('safe-av: rows 10..2499 / 2509..2837 (joint along the leaf top)', sp.values.map { |q| [q[:row], q[:z0], q[:z1]] }.uniq.sort, [['L', 10.0, 2499.0], ['U', 2509.0, 2837.0]])
ss['openings'].each do |o|
  la = o['x0'] + o['clad_inset']; lb = o['x1'] - o['clad_inset']
  check("safe-av #{o['id']}: leaf centred, width = opening - 2 x 52 + 19", [((la + lb) / 2.0).round(1), (lb - la).round(1)],
        [((o['x0'] + o['x1']) / 2.0).round(1), (o['x1'] - o['x0'] - 85.0).round(1)])
  nb = so[:grid][:panels].select { |q| q[:row] == 'L' && ((q[:x1] - la).abs - 10).abs < 0.05 || ((q[:x0] - lb).abs - 10).abs < 0.05 && q[:row] == 'L' }
  check("safe-av #{o['id']}: a lower panel 10 from each leaf edge", nb.size, 2)
  check("safe-av #{o['id']}: jamb = wall + 32.3 - 18 (front 12 behind the panel face)", o['frame']['jamb'], (o['frame']['wall_t'] + 14.3).round(1))
  check("safe-av #{o['id']}: rebate as all AP walls (rear 10)", o['rebate']['depth'], 10)
end
check('safe-av: equal free spans', [%w[P09], %w[P10 P11], %w[P12 P13 P14]].map { |ids| ids.map { |i| sp[i][:w] }.minmax.then { |a, b| (b - a).round(1) <= 0.1 } }, [true, true, true])
check('safe-av: side rebates 30 wide (frame + 2.5 .. panel edge 10 from the leaf)', sp.values.flat_map { |q| q[:rebates].map { |r| (r[1] - r[0]).round(1) } }.reject { |w| w > 100 }.uniq, [30.0])
ex = UCON::RoomExtras.pieces(ss, so).select { |b| b[:tag] == 'doors' }
check('safe-av: door pieces (3 jamb parts + 3 lip parts + leaf + leaf step, x 2)', ex.size, 16)
st = ex.select { |b| b[:name].end_with?('leaf step') }
jm = ex.select { |b| b[:name] =~ /frame jamb [LR]\z/ }
check('safe-av: leaf step 2.5 clear of the jamb body', st.flat_map { |b| jm.select { |j| (j[:x][1] - b[:x][0]).abs < 10 || (b[:x][1] - j[:x][0]).abs < 10 }.map { |j| [(b[:x][0] - j[:x][1]).abs, (j[:x][0] - b[:x][1]).abs].min.round(1) } }.uniq, [2.5])
check('safe-av: leaf 50 thick', ex.select { |b| b[:name] =~ /leaf/ }.group_by { |b| b[:name][0, 3] }.map { |_, bs| (bs.map { |b| b[:y][1] }.max - bs.map { |b| b[:y][0] }.min).round(1) }.uniq, [50.0])
check('safe-av: leaf face = panel face', ex.select { |b| b[:name].end_with?('leaf') }.map { |b| b[:y][0] }.uniq, [-ss['build_up']['face']])

# ---- 12. AP Dining (2026-10-19): our survey (probes 820 / 821), inside corners (A / D through, B / C between their
# panel faces), lower 2755 as TM REV 3 with one joint all round (option A), window B as Main Kitchen, opening C as ML Foyer
dfids = []
%w[B A C D].each do |c|
  sd = WP.load(File.join(DIR, 'walls', "AP_MF_Dining_#{c}.json"))
  od = WP.build(sd)
  check("dining #{c}: checks pass", od[:checks], [])
  check("dining #{c}: no raw wall in a joint", WP.joint_gaps(sd, od[:grid], od[:frames]), [])
  check("dining #{c}: every clip fully supported", od[:clips].reject { |q| q[:support] == :ok }, [])
  check("dining #{c}: no panel taller than TM's 2755", od[:grid][:panels].map { |q| q[:z1] - q[:z0] }.max <= 2755.05, true)
  check("dining #{c}: one row joint 3015.35 / 3025.35", od[:grid][:seam_z], [3015.35, 3025.35])
  dfids.concat(od[:frames].map { |f| f[:id] })
end
check('dining: frame ids S01..S42 in sequence', dfids, (1..42).map { |i| format('S%02d', i) })
check('dining: walls as surveyed (Andriy) - A / D 7524, B / C 4830', %w[A B C D].map { |c| WP.load(File.join(DIR, 'walls', "AP_MF_Dining_#{c}.json"))['wall']['length'] }, [7524, 4830, 4830, 7524])
lb = UCON::RoomExtras.pieces(WP.load(File.join(DIR, 'walls', 'AP_MF_Dining_B.json')), WP.build(WP.load(File.join(DIR, 'walls', 'AP_MF_Dining_B.json')))).select { |b| b[:name] =~ /B-WIN liner [LR] leg/ }
check('dining B: window liner legs start on the stone top (liner.z0)', lb.map { |b| (b[:z][0] - 260.35).abs < 0.06 }.uniq, [true])

# v2.0 (Andriy 2026-10-19): liner flange in the slot of strips B / A on the panel back (Main Kitchen v1.0), joint blocks MDF 6
ovl = ->(a, b) { a[:x][0] < b[:x][1] - 0.05 && b[:x][0] < a[:x][1] - 0.05 && a[:z][0] < b[:z][1] - 0.05 && b[:z][0] < a[:z][1] - 0.05 }
nst = 0; nbl = 0
%w[B C].each do |c|
  sd = WP.load(File.join(DIR, 'walls', "AP_MF_Dining_#{c}.json")); od = WP.build(sd)
  pcs = UCON::RoomExtras.pieces(sd, od)
  sa = pcs.select { |b| b[:name] =~ /strip A/ }; sb = pcs.select { |b| b[:name] =~ /strip B/ }
  fl = pcs.select { |b| b[:name] =~ /liner .* flange/ }; bl = pcs.select { |b| b[:tag] == 'blocks' }
  mem = od[:frames].flat_map { |f| WP.members(f) }.map { |m| { x: [m[:x0], m[:x1]], z: [m[:z0], m[:z1]] } }
  nst += sa.size + sb.size; nbl += bl.size
  check("dining #{c}: no frame member on a strip", (sa + sb).select { |b| mem.any? { |m| ovl.(m, b) } }.map { |b| b[:name] }, [])
  check("dining #{c}: no frame member on a joint block", bl.select { |b| mem.any? { |m| ovl.(m, b) } }.map { |b| b[:name] }, [])
  check("dining #{c}: the flange clear of strip A", fl.select { |f| sa.any? { |a| ovl.(f, a) } }.map { |f| f[:name] }, [])
  check("dining #{c}: every pier / head strip B holds a flange", sb.reject { |b| fl.any? { |f| ovl.(f, b) } }.map { |b| b[:name] }, [])
  check("dining #{c}: joint blocks on the wall face, under strip B (6 of 10.3)", bl.map { |b| b[:y] }.uniq, [[-6.0, 0.0]])
end
# v2.0 (Andriy 2026-10-19): frames with openings under 150 are one solid plywood piece (subframe.solid_below, S1 / S2)
dsol = %w[B A C D].flat_map { |c| WP.build(WP.load(File.join(DIR, 'walls', "AP_MF_Dining_#{c}.json")))[:frames] }
check('dining: solid pieces (S1 / S2 + the narrow S09)', dsol.select { |f| f[:stiles].size == 1 }.map { |f| f[:id] },
      %w[S01 S02 S03 S04 S05 S06 S07 S08 S09 S23 S25 S26 S27 S28 S29 S30])   # A / D bands 660 high stay frames (S3: they do not nest)
check('dining: every solid piece nests two across a 4 x 8 sheet', dsol.select { |f| f[:stiles].size == 1 }.reject { |f| d = [f[:x1] - f[:x0], f[:z1] - f[:z0]].sort; d[0] <= 606.65 && d[1] <= 2438.45 }.map { |f| f[:id] }, [])
check('dining: every frame left has stiles 150+ apart', dsol.reject { |f| f[:stiles].size == 1 }.map { |f| f[:stiles][1][0] - f[:stiles][0][1] >= 150 }.uniq, [true])
check('dining: 14 panels x strips B + A, 12 joint blocks', [nst, nbl], [28, 12])

puts "#{$checks} checks, #{$fails.size} failures"
$fails.each { |f| puts "FAIL #{f}" }
exit($fails.empty? ? 0 : 1)

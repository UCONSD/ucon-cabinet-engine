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
out = WP.build(spec)
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

puts "#{$checks} checks, #{$fails.size} failures"
$fails.each { |f| puts "FAIL #{f}" }
exit($fails.empty? ? 0 : 1)

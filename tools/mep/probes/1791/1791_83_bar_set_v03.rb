# UCON-MODEL: 1791_BAR_MEP
#
# 1791 FAMILY ROOM BAR - SET v0.3 (Andriy 2026-11-08): cooler outlet - two options (E1 recessed per the Zephyr guide / E8 in
# the sink base, E1 capped); LED - driver receptacle E2 in the sink base switched by S1, LV1-LV3 + route. Built from 1791_82.
# v0.2 (Andriy 2026-11-08): lower shelf on the B2 row (B2 extended wall to wall, inside its band),
# upper shelf B3; row labels fixed (B1 is not wall to wall). Built from 1791_81.
# v0.1 (Andriy 2026-11-08): AS-IS rough-ins from DISTO IMG_4680 / 4681 + photos over the
# Leicht 244 BOSSA bar (KPS 26.09.2026). Built after 1791_72. Floor 3/4" wood assumed. Base units on a plinth: no blocking
# (Andriy). Wall units: two rows on the edges, the top one under the niche soffit; open shelves: one row each (blocking_extra).
# Main findings: FC-D1 niche soffit 2388 AFF vs KPS wall units 2385 + fascia 54; boxes at the countertop line; cooler feed.
# READ ONLY for the model. Writes ~/Documents/1791_BAR_Set_v0.3.layout + .pdf; model snapshot next to it.
load File.expand_path('~/dev/ucon-cabinet-engine/tools/layout/mep_drawing_set.rb')
load File.expand_path('~/dev/ucon-cabinet-engine/tools/layout/symbols/plan_symbols.rb')
m = UCON::ProbeBridge.model
raise "wrong model: #{m.title}" unless m.title =~ /1791_BAR_MEP/i
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_BAR_MEP.skp'
['A2 Plan', 'A3 Elevation 1', '1791 MEP Plan', '1791 MEP Elevation'].each { |n| raise "scene missing: #{n}" unless m.pages[n] }
OUT = File.expand_path('~/Documents/1791_BAR_Set_v0.3.layout')
%w[draft1 draft2 draft3].each do |dn|
  src = [OUT, OUT.sub('.layout', '.pdf')]
  next if src.any? { |f| File.exist?(f.sub('_Set_v0.3', "_Set_v0.3_#{dn}")) }
  src.each { |f| File.rename(f, f.sub('_Set_v0.3', "_Set_v0.3_#{dn}")) if File.exist?(f) }
  break
end
raise "STOP: exists #{OUT}" if File.exist?(OUT)
LOGO = File.expand_path('~/Documents/CE_logo_cube_transparent.png')
DS = UCON::DrawingSet
skp = m.path
tags = {
  'ProjectName' => '1791 - Family Room Bar', 'ProjectAddress' => "876 Highlands Circle\nLos Altos, CA 94024", 'ProjectNumber' => '1791',
  'ClientName' => 'Sangeeta Anand', 'Designer' => 'Lusso / KPS', 'Drafter' => 'UCON', 'CheckedBy' => ' ',
  'Issue' => 'COORDINATION', 'Revision' => '0.3', 'IssueDate' => '11.08.26',
  'Status' => 'PRELIMINARY - FOR COORDINATION',
  'StatusDesc' => 'Rough-ins AS-IS from the UCON site survey 10.29.26 (DISTO + photos). RED = to verify with GC. Cabinets from KPS 26.09.2026. Not engineered.',
  'Rev1' => '0.1', 'Rev1Desc' => 'As-is, senior review', 'Rev1Date' => '11.08.26',
  'Rev2' => '0.2', 'Rev2Desc' => 'Shelf on the B2 row', 'Rev2Date' => '11.08.26', 'Rev3' => '0.3', 'Rev3Desc' => 'Cooler outlet, LED', 'Rev3Date' => '11.08.26',
  'Rev4' => ' ', 'Rev4Desc' => ' ', 'Rev4Date' => ' '
}
M  = UCON::MEP
pr = M.load_json(File.expand_path('~/dev/ucon-cabinet-engine/tools/mep/projects/1791_bar_asis.json'))
D = 695; W = 2058; HC = pr['ceiling_mm']
boxes = pr['blocking_boxes']
pts   = M.points(boxes, pr).reject { |p| p['scope'] == 'out' }
zones = M.plumbing_zones(pts.select { |p| p['group'] })
blk = M.blocking(boxes, along: 'x', face: 'y1', wall_at: D, bottom_row: true, below_top: 0, above_bottom: 0, ext: 0, ceiling: HC)
blk.each { |b| b['item'] = b['item'].sub(/\)\z/, '; from the right niche wall)') }
# blocking_extend (Andriy 2026-11-08): a shelf inside the band of an existing row extends that row - no second axis next to it
Array(pr['blocking_extend']).each do |e|
  r = blk.find { |b| b['cl'].to_i == e['cl'].to_i } or raise "STOP: blocking_extend: no row at #{e['cl']}"
  r['a0'] = [r['a0'], e['a0']].min if e['a0']; r['a1'] = [r['a1'], e['a1']].max if e['a1']
  r['item'] = r['item'].sub(/\)\z/, '; extended under the open shelf - the shelf fixes inside this band)')
  r['src'] = r['src'].to_s + ' / ' + e['why'].to_s.split(':').first
end
blk += Array(pr['blocking_extra']).map { |b| b.merge('item' => b['item'].sub(/\)\z/, '; from the left niche wall)')) }
SC = { one: [1.0 / 12, %(1" = 1'-0"), [0.5, 0.5, 1.0, 1.0]], three_q: [1.0 / 16, %(3/4" = 1'-0"), [0.375, 0.375, 0.75, 0.75]] }.freeze
DS.define_singleton_method(:label_view) do |x, y, w, h, no, code, name, key|
  vh = h - self::LABEL_GAP - self::LABEL_H
  ly = y + vh + self::LABEL_GAP; d = self::LABEL_H
  circle(x + d / 2, ly + d / 2, d, @l_sheet)
  line(x + 0.06, ly + d / 2, x + d - 0.06, ly + d / 2, @l_sheet, w: 0.5)
  text(no.to_s, x + d / 2, ly + 0.035, @l_sheet, size: 8, font: self::MONO, align: :center)
  text(code, x + d / 2, ly + d / 2 + 0.03, @l_sheet, size: 6, font: self::MONO, align: :center)
  text(name, x + d + 0.139, ly + 0.10, @l_sheet, size: 13.5, font: self::SANS_MED)
  line(x + d + 0.139, ly + d, x + w, ly + d, @l_sheet, w: 1.5)
  return unless SC[key]
  segs = SC[key][2]; bw = segs.sum; x0 = x + w - bw - 0.09; hy = ly + 0.07
  xx = x0
  segs.each_with_index { |s, i| rect(xx, hy, s, 0.055, @l_sheet, stroke: self::INK, sw: 0.5, fill: i.even? ? self::INK : nil); xx += s }
  [[0, '0'], [segs[0] + segs[1], %(1')], [segs[0] + segs[1] + segs[2], %(2')], [bw, %(4')]].each { |o, t| text(t, x0 + o, hy + 0.085, @l_sheet, size: 7, font: self::MONO, align: :center) }
  text(SC[key][1], x0 - 0.18, ly + 0.13, @l_sheet, size: 8, font: self::MONO, c: self::INK2, align: :right)
end
DS.define_singleton_method(:place) do |skp, scene, key, pa3, pb3, render: :vector, room: [0.9, 0.9]|
  zx, zy, zw, zh = work_zone
  vp = viewport(skp, scene, zx, zy, zw, zh, scale: SC[key][0], render: render)
  a = vp.model_to_paper_point(pa3); b = vp.model_to_paper_point(pb3)
  w = (b.x - a.x).abs; h = (b.y - a.y).abs
  raise "STOP: #{scene} does not fit: #{w.round(2)} x #{h.round(2)} + room, window #{zw.round(2)} x #{zh.round(2)}" if w + 2 * room[0] > zw || h + 2 * room[1] > zh
  vp.transform!(Geom::Transformation2d.new([1, 0, 0, 1, zx + (zw - w) / 2 - [a.x, b.x].min, zy + (zh - h) / 2 - [a.y, b.y].min]))
  vp.render if vp.render_needed?
  @log << "#{scene}: #{w.round(2)} x #{h.round(2)} in"
  vp
end
DS.define_singleton_method(:note_text) do |txt, x, y|
  red = txt.start_with?('!')
  t = red ? txt.sub(/\A!\s*/, '') : txt
  lines = t.split("\n")
  w = lines.map(&:length).max * 7 * 0.62 / 72 + 0.10
  h = lines.size * 7 * 1.25 / 72 + 0.06
  @l_note = nil if @l_note && @l_note.document != @doc rescue nil
  @l_note ||= @doc.layers.add('Notes', false)
  rect(x - w / 2, y - 0.03, w, h, @l_note, fill: [255, 255, 255], stroke: red ? self::RED : nil, sw: 0.75)
  text(t, x, y, @l_note, size: 7, font: self::MONO, c: red ? self::RED : self::INK2, align: :center)
end


P0 = ->(x, y, z = 0) { Geom::Point3d.new(x / 25.4, y / 25.4, z / 25.4) }

SC_X = W - 325 # bar sink CL (KPS 325 from the right wall)
questions = [
  ['FC-D1 CRITICAL - Niche height', 'Niche soffit 94" AFF (DISTO 2407 - 3/4" floor). KPS stack: wall units top 93 7/8" + fascia 2 1/8" = 96". Lusso: lower the wall units / shorten them or the backsplash; fascia does not fit.', 'H'],
  ['FC-D1 Niche and cooler depth', 'Site 2058 x 694-696 vs KPS 2064 x 673 (left filler 27 -> 21). Cooler Zephyr PRB24C01CPG: 23 3/4" deep incl. panel + 1" for the plug. Lusso: base front plane and how the cooler sits flush.', 'W D'],
  ['FC-M2 Cooler outlet - choose', 'E1 is behind the cooler. OPTION 1: keep it there as a recessed box (Zephyr: 1" rear clearance, cord back right). OPTION 2: new outlet E8 in the sink base (cord 72"), E1 capped. Dedicated, not switched.', 'E1 E8'],
  ['Boxes at the countertop line', 'E6 / E7 ~35 3/4" AFF (photo) - top 35 1/4" - 36 3/4" and stone backsplash. GC: measure, move above the top or confirm function.', 'E6 E7'],
  ['FC-M7 Sink base + LED', 'Sink model and sink-unit fronts unknown. GC: function of E2-E5. Proposed: E2 = LED driver outlet switched by S1 (right niche wall); LV cable in the wall to LV1-LV3.', 'E2-E5 S1 LV'],
  ['FC-C4 Blocking behind closed wall', 'Niche walls are finished. GC to confirm 2x6: B1 under the soffit, B2 57 1/2" (wall units, wall to wall - the lower shelf fixes in its band), B3 73" (upper shelf, scaled) - see D-501.', 'B1-B3']
]
notes = [
  'UCON scope only: rough-ins inside our base units, boxes at the countertop line, the cooler feed, LED feed, blocking. Base units on a 100 plinth: no blocking (Andriy 2026-11-08). Bar faucet deck-mounted.',
  'LED: driver outlet inside the sink base, switched (S1); LV (Class 2) cable in the wall from the driver to each LED run (LV1 glass wall units, LV2 / LV3 shelves), 24" spare coiled at each outlet.',
  'AT CABINET INSTALL: test lines CUT; no stops / valves installed - capped stubs only. Valves and trim by the plumber after the cabinets are set.',
  'Rough-ins AS-IS from the UCON site survey 10.29.26 (Leica DISTO IMG_4680 / 4681 + photos). Heights to the CENTRE above FINISHED floor = DISTO - 3/4" (wood floor assumed, FC-M6). Cabinets: KPS 1791_Family Room 26.09.2026 (Leicht 244 BOSSA).',
  'SENIOR REVIEW 11.08.26 (UCON Failure Case Library): OPEN FC-D1 (critical, height), FC-D1 width / depth, FC-M2, FC-M7, FC-C4, FC-M6 (photo points in red). CLOSED: FC-M5 (deck faucet, drain 1/4" off the sink CL).'
]
plan_dims = { groups: [{ along: :x, at: D + 152, ref: W, toward: [D, 3000], off: 0.45, zero: 'RIGHT NICHE WALL',
                        stops: [[SC_X, 'SINK CL'], [W - 626, 'SINK UNIT'], [W - 1236, 'COOLER']] }], locate: [] }
red_notes = [
  ["! E1 COOLER OUTLET - CHOOSE (FC-M2):\nOPT 1  RECESSED BOX BEHIND THE UNIT\n       (ZEPHYR: 1\" REAR CLEARANCE)\nOPT 2  NEW OUTLET E8 IN THE SINK BASE,\n       E1 CAPPED", -950, 1150],
  ["! E2-E5: FOUR BOXES IN THE SINK BASE\nGC TO NAME EACH FUNCTION\nE2 PROPOSED: LED DRIVER OUTLET (S1)", -950, 650]
]
cell = { scene: '1791 MEP Elevation', axis: :x, depth: D, a0: -1800, a1: W, zmax: 2400, scale: 1.0 / 24, view_key: :half, top_from: 934,
         blk_note_at: [-950, 2150], blk_tail: 'B1 FROM THE RIGHT WALL; B2 WALL TO WALL; B3 FROM THE LEFT WALL',
         conflicts: [], pts: pts, blocks: blk, zones: zones,
         routes: [{ pts: pr['led']['route'], c: [0x6A, 0x3D, 0x9A], label: 'LV CABLE (CL2) FROM THE DRIVER AT E2', at: 1 },
                  { pts: pr['led']['route2'], c: [0x6A, 0x3D, 0x9A], label: nil }], ref: { at: W, text: 'right niche wall' }, notes: red_notes,
         outlines: [{ a0: 21, a1: 821, z0: 100, z1: 895, label: 'UNIT 800' },
                    { a0: 821, a1: W - 626, z0: 0, z1: 895, label: 'COOLER' },
                    { a0: W - 626, a1: W - 26, z0: 100, z1: 895, label: 'SINK UNIT' },
                    { a0: 0, a1: W, z0: 895, z1: 934, label: nil },
                    { a0: 816, a1: W, z0: 1458, z1: 2385, label: 'WALL UNITS' }] }

rows = pts.map do |p|
  loc = if p['ref'] == 'WB' then "right niche wall, #{DS.in_q(p['horiz_mm'])} from the back wall" elsif p['x'] then "#{DS.in_q(p['horiz_mm'])} from the right wall" else 'see note' end
  r = [p['id'], p['item'].to_s, p['req'].to_s, loc, p['z'] ? DS.in_q(p['z']) : '-', p['status'], p['src'].to_s]
  p['flag'] ? r + [:red] : r
end
blk.each { |b| rows << [b['id'], '2x6 blocking (see D-501)', b['item'] + ' WALL CLOSED - CONFIRM IN PLACE.', "#{DS.in_q(W - b['a1'])} .. #{DS.in_q(W - b['a0'])} from the right wall", DS.in_q(b['cl']), b['status'], b['src'], :red] }
cols = [['ID', 0.45], ['ITEM', 2.1], ['REQUIREMENT', 4.9], ['LOCATION', 1.5], ['AFF', 0.7], ['STATUS', 1.2], ['SOURCE', 2.2]]

DS.instance_eval do
  start([LOGO], tags)
  @index = []; @stops = []; @dims = 0; @connected = 0
  @notes = [
    'Cabinets: KPS designstudio / Lusso, 1791_Family Room installation sheets 26.09.2026 (Leicht 244 BOSSA). Niche and rough-ins: UCON site survey 10.29.26 (Leica DISTO + photo).',
    'Niche per DISTO: 2058 wide, 694 / 696 deep, soffit 2407 above today\'s floor (2388 AFF). KPS: 2064 wide, 673 deep, stack to 2439.',
    'Base on a 100 plinth, carcass to 895, top 39 -> 934: filler 27 (21 on site) | unit 800 | cooler PRB24C01CPG 610 | sink unit 600 | filler 26. Backsplash stone to 1442.',
    'Wall units glass 600 + 600 (+ panel 16, filler 26) 1458..2385, depth 362; open shelves 822 at ~1450 / ~1853 (scaled). A-sheets in mm, M-sheets in inches. RED = verify with GC.',
    'Placed from the RIGHT wall (sink side); the left filler takes the -6. Bar sink model unknown: square marker on CL 325 from the right wall.',
    'Blocking: wall units 2x6 flat, axis ON the bottom edge (1458, extended wall to wall for the lower shelf) and under the soffit top plate (2280); upper shelf B3 at mid-height - see D-501.'
  ]
  @l_vp = @doc.layers.add('Views', false)
  @l_blk = @doc.layers.add('Blocking', false)
  @doc.layers.reorder(@l_blk, @doc.layers.index(@l_vp))
  @blk_under_view = true
  @l_mep = @doc.layers.add('MEP', false)
  @l_dims = @doc.layers.add('Dimensions A', false)
  r = self::ROW

  legend_page('G-001')

  @mep_in = false
  next_page('PLAN'); header(%(SCALE 3/4" = 1'-0" · DIMENSIONS IN MM)); sheet_code('A-101')
  vp = place(skp, 'A2 Plan', :three_q, P0.(-152, -300), P0.(W + 152, D + 152), room: [1.2, 1.3])
  p3 = ->(a, b) { P0.(a, b) }
  ch = [0, 21, 821, W - 626, W - 26, W]
  ch.each_cons(2) { |a, b| dim(vp, p3, [a, D + 152], [b, D + 152], r, :above) }
  dim(vp, p3, [0, D + 152], [W, D + 152], 2 * r, :above)
  dim(vp, p3, [SC_X, -150], [W, -150], r, :below)
  dim_toward(vp, P0.(W + 152, 0), P0.(W + 152, D), r, P0.(6000, D / 2.0))
  dim_toward(vp, P0.(-152, D - 630), P0.(-152, D), r, P0.(-3000, D / 2.0))
  sa = vp.model_to_paper_point(P0.(SC_X, D)); sb = vp.model_to_paper_point(P0.(SC_X, -100))
  line(sa.x, sa.y, sb.x, sb.y, @l_dims, w: 0.5, c: self::ACCENT, dash: true)
  text('SINK CL', sb.x, sb.y + 0.05, @l_dims, size: 7, font: self::MONO, c: self::ACCENT, align: :center)
  label_view(self::WX, self::WY, self::WW, self::WH, 1, 'A-101', 'PLAN - BAR NICHE', :three_q)
  @index << ['A-101', 'PLAN']

  next_page('ELEVATION 1'); header(%(SCALE 3/4" = 1'-0" · DIMENSIONS IN MM)); sheet_code('A-201')
  ve = place(skp, 'A3 Elevation 1', :three_q, P0.(0, D, 0), P0.(W, D, HC), render: :vector, room: [1.3, 0.9])
  pe = ->(a, z) { P0.(a, D, z) }
  ch.each_cons(2) { |a, b| dim(ve, pe, [a, 0], [b, 0], r, :below) }
  dim(ve, pe, [0, 0], [W, 0], 2 * r, :below)
  dim(ve, pe, [SC_X, 1700], [W, 1700], r, :above)
  zr = [0, 100, 895, 934, 1442, 1458, 2385, HC]
  zr.each_cons(2) { |a, b| dim(ve, ->(a2, z) { P0.(W, D, z) }, [W, a], [W, b], r, :right) }
  dim(ve, ->(a2, z) { P0.(W, D, z) }, [W, 0], [W, HC], 2 * r, :right)
  a = ve.model_to_paper_point(P0.(SC_X, D, 934)); b = ve.model_to_paper_point(P0.(SC_X, D, 1400))
  line(a.x, a.y, b.x, b.y, @l_dims, w: 0.5, c: self::ACCENT, dash: true)
  text('SINK CL', b.x - 0.05, b.y - 0.16, @l_dims, size: 7, font: self::MONO, c: self::ACCENT, align: :right)
  q = ve.model_to_paper_point(P0.(500, D, 2150))
  note_text("! NICHE SOFFIT 2388 AFF (SITE)\nKPS: WALL UNITS 2385 + FASCIA 54 = 2439\nFASCIA DOES NOT FIT - FC-D1", q.x, q.y)
  label_view(self::WX, self::WY, self::WW, self::WH, 1, 'A-201', 'ELEVATION 1 - BAR NICHE', :three_q)
  @index << ['A-201', 'ELEVATION 1']

  @mep_in = true
  @mep_scale = %(SCALE 3/4" = 1'-0" · DIMENSIONS IN INCHES)
  mep_page_legend_questions('M-001', questions, notes: notes)
  mep_page_plan(skp, 'M-101', 'FAMILY ROOM BAR - MEP PLAN (AS-IS)', '1791 MEP Plan', [-152, W + 152, -300, D + 152], pts, [], render: :vector, dims: plan_dims,
                scale: 1.0 / 16, view_key: :three_q)
  @mep_scale = %(SCALE 1/2" = 1'-0" · DIMENSIONS IN INCHES) # full height of the niche does not fit at 3/4" (STOP 7.49 x 8.86)
  mep_page_elevations(skp, 'M-201', 'FAMILY ROOM BAR - BACK WALL (AS-IS)', [[cell, 'BACK WALL - BAR', DS::WX, DS::WY, DS::WW, DS::WH]])
  @mep_scale = %(SCALE 1/2" = 1'-0" · DIMENSIONS IN INCHES)
  mep_table('POINT SCHEDULE', 'M-601', cols, rows, 'Locations from the face of the right niche wall, heights to the centre above finished floor (DISTO - 3/4", assumed wood floor, FC-M6). ' \
            'AS-IS = installed (DISTO 10.29.26). RED rows: from the photo or in conflict - VERIFY WITH GC. At cabinet install: capped stubs only, test lines cut.')
  mep_page_detail_blocking('D-501', off: 0.0)
  fill_legend(@index.size, '0.3')
  @log << "dimensions #{@dims}, connected to the model #{@connected}#{@conn_err ? ' / ' + @conn_err : ''}"
  @log << "pages: #{@index.map(&:first).join(' ')}"
  finish(OUT)
end
puts DS.instance_variable_get(:@log)
stops = DS.instance_variable_get(:@stops)
puts "STOPS: #{stops.inspect}" unless stops.empty?
[OUT, OUT.sub('.layout', '.pdf')].each { |f| puts "#{File.basename(f)}  #{File.size(f)} b" }
require 'fileutils'
FileUtils.cp(OUT.sub('.layout', '.pdf'), File.expand_path('~/dev/_claude/1791_BAR_Set_v0.3.pdf'))
snap = File.join(File.dirname(m.path), '1791_BAR_MEP_at_Set_v0.3.skp')
FileUtils.cp(m.path, snap)
puts "model: #{m.path}  snapshot: #{File.basename(snap)} #{File.size(snap)} b"

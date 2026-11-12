# UCON-MODEL: 1791_PBATH_MEP
#
# 1791 PRIMARY BATH - SET v0.9 (Andriy 2026-11-11): back to the KPS height (top 864, 34"); drains stay 590 (both measured);
# blocking unchanged. The sink drain body is in the model (Lacava 7100-13 type, 4 1/2" long - ASSUMED): it lands on the trap
# inlet (586). Conditions: Lusso U-shape drawers; drain body max 4 1/2" from the flange. Model: probes 1791_107 / 107b.
# Built from 1791_106.
# 1791 PRIMARY BATH - SET v0.7 (Andriy 2026-11-11): the countertop is a 2 cm slab with a built-up 3" edge; the undermount
# sink is glued under the SLAB (rim 33 1/4"), not under the visible edge. Bowl bottom 682 (26 7/8"), trap arm needed <= 579.
# Both sinks fit with a U-shape drawer + drains lowered to 22 1/2". Model step: probe 1791_95e. Built from 1791_96.
# 1791 PRIMARY BATH - SET v0.6 (Andriy 2026-11-11): the ORDERED sinks (Lacava 5451-001 x2, 552 x 391 x 162, fixture order
# S6689471) and the REAL Lusso drawers (Lusso 3D 10.11.26: stone 76, drawer box 449..635, SOLID bottom 452..462, no U cut-out).
# Model step: probe 1791_95. D-502 = left sink (does not fit), D-503 = right sink (fits with a U drawer + drain lowered to ~20").
# Built from 1791_76.
# 1791 PRIMARY BATH - SET v0.5 (Andriy 2026-11-08): D-502 from the MODEL - the real Kohler P-trap (imported by Andriy,
# placed by probe 1791_75) in a section through the left sink: U-shape sink drawer required (the bend 476 is below a
# solid drawer bottom 494), bowl max ~5" at the actual drain. Built from 1791_74.
# v0.4 (Andriy 2026-11-08): P-trap vs the drawer bottom - a 6" undermount bowl does not fit at ANY
# drain height (the drawer has its own bottom ~494); lowering the drain makes it worse. New D-502 'P-trap fit' section,
# M-001 / M-201 rewritten: do NOT lower the drains. Built from 1791_73.
# v0.3 (Andriy 2026-11-08): B4 dropped - the shelf sits inside the B3 band, B3 extended under it
# (two axes 35 mm apart looked dirty). Built from 1791_72.
# v0.2 (Andriy 2026-11-08): + B4 blocking under the open shelf (pos. 60), axis at the shelf mid-height
# 188 AFF (shelf scaled - VERIFY); the shelf drawn on M-201. Built from 1791_71 (v0.1).
# v0.1 (Andriy 2026-11-08): AS-IS rough-ins from DISTO IMG_4677 + photos IMG_4396 / 4408 over the
# Leicht 238 METURO double vanity (KPS 26.09.2026). Built after 1791_64d (Bath 1 v0.2). Deck faucets (no spout point).
# Floor build-up 5/8" assumed as ADU. Main finding: FC-M4 / FC-M7 - the drains (23 1/4" AFF) sit above the trap window of the
# 14" upper drawer for a 6" bowl under a ~3" top. Blocking per cabinet: bottom row 153 (right sink + drawers) and 432 (left
# sink unit, open below) - computed per box (the engine merges a run into one bottom row at the lowest edge).
# READ ONLY for the model. Writes ~/Documents/1791_PBATH_Set_v0.9.layout + .pdf; model snapshot next to it.
load File.expand_path('~/dev/ucon-cabinet-engine/tools/layout/mep_drawing_set.rb')
load File.expand_path('~/dev/ucon-cabinet-engine/tools/layout/symbols/plan_symbols.rb')
m = UCON::ProbeBridge.model
raise "wrong model: #{m.title}" unless m.title =~ /1791_PBATH_MEP/i
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_PBATH_MEP.skp'
['A2 Plan', 'A3 Elevation 1', '1791 MEP Plan', '1791 MEP Elevation', '1791 P-trap Section L', '1791 P-trap Section R'].each { |n| raise "scene missing: #{n}" unless m.pages[n] }
OUT = File.expand_path('~/Documents/1791_PBATH_Set_v0.9.layout')
%w[draft1 draft2 draft3].each do |dn|
  src = [OUT, OUT.sub('.layout', '.pdf')]
  next if src.any? { |f| File.exist?(f.sub('_Set_v0.9', "_Set_v0.9_#{dn}")) }
  src.each { |f| File.rename(f, f.sub('_Set_v0.9', "_Set_v0.9_#{dn}")) if File.exist?(f) }
  break
end
raise "STOP: exists #{OUT}" if File.exist?(OUT)
LOGO = File.expand_path('~/Documents/CE_logo_cube_transparent.png')
DS = UCON::DrawingSet
skp = m.path
tags = {
  'ProjectName' => '1791 - Primary Bath', 'ProjectAddress' => "876 Highlands Circle\nLos Altos, CA 94024", 'ProjectNumber' => '1791',
  'ClientName' => 'Sangeeta Anand', 'Designer' => 'Lusso / KPS', 'Drafter' => 'UCON', 'CheckedBy' => ' ',
  'Issue' => 'COORDINATION', 'Revision' => '0.9', 'IssueDate' => '11.11.26',
  'Status' => 'PRELIMINARY - FOR COORDINATION',
  'StatusDesc' => 'Rough-ins AS-IS from the UCON site survey 10.29.26 (DISTO + photos). RED = to verify with GC. Cabinets from KPS 26.09.2026. Not engineered.',
  'Rev1' => '0.6', 'Rev1Desc' => 'Lacava sinks, Lusso 3D', 'Rev1Date' => '11.11.26',
  'Rev2' => '0.7', 'Rev2Desc' => 'Sink under 2 cm slab', 'Rev2Date' => '11.11.26', 'Rev3' => '0.8', 'Rev3Desc' => 'Vanity up 3/4" (study)', 'Rev3Date' => '11.11.26',
  'Rev4' => '0.9', 'Rev4Desc' => 'KPS height, drain body', 'Rev4Date' => '11.11.26'
}
M  = UCON::MEP
pr = M.load_json(File.expand_path('~/dev/ucon-cabinet-engine/tools/mep/projects/1791_pbath_asis.json'))
D = 2020; W = 5334
XL = W - 2900 # plan / elevation window starts here (the left 2400 of wall 1 is empty)
boxes = pr['blocking_boxes']
pts   = M.points(boxes, pr).reject { |p| p['scope'] == 'out' }
zones = M.plumbing_zones(pts.select { |p| p['group'] })
# per box: the engine would merge both boxes into one bottom row at 153; the left sink unit hangs at 432 (open below)
bargs = { along: 'x', face: 'y1', wall_at: D, bottom_row: true, below_top: 0, above_bottom: 0, ext: 0, ceiling: pr['ceiling_mm'] }
top_row = M.blocking(boxes, **bargs).find { |b| b['cl'].to_i == 788 }
bl = M.blocking([boxes[0]], **bargs).find { |b| b['cl'].to_i == 432 }
br = M.blocking([boxes[1]], **bargs).find { |b| b['cl'].to_i == 153 }
raise "STOP: blocking rows not found #{[top_row, bl, br].map { |b| b && b['cl'] }.inspect}" unless top_row && bl && br
blk = [top_row, bl, br]
blk = blk.each_with_index.map { |b, i| b.merge('id' => "B#{i + 1}") }
blk.each { |b| b['item'] = b['item'].sub(/\)\z/, ', from wall 2; extend left to the next stud past the vanity (16" o.c.))') }
# blocking_extend (Andriy 2026-11-08): a shelf inside the band of an existing row extends that row - no second axis next to it
Array(pr['blocking_extend']).each do |e|
  r = blk.find { |b| b['cl'].to_i == e['cl'].to_i } or raise "STOP: blocking_extend: no row at #{e['cl']}"
  r['a0'] = [r['a0'], e['a0']].min if e['a0']; r['a1'] = [r['a1'], e['a1']].max if e['a1']
  r['item'] = r['item'].sub(/\)\z/, '; extended under the open shelf - the shelf fixes inside this band)')
  r['src'] = r['src'].to_s + ' / ' + e['why'].to_s.split(':').first
end

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


SL = W - 1826; SR = W - 422 # sink CLs (KPS)
questions = [
  ['FC-M4 / FC-M7 CRITICAL - Lusso U-shape drawers', 'Lacava 5451-001 under the 2 cm slab, KPS height (top 34"): bowl bottom 26 7/8", the drain body (max 4 1/2" from the flange) lands on the trap inlet 23"; drains stay 23 1/4". The trap sits inside the Lusso drawer box and the arm runs through its back: U-shape sink drawers required under both sinks (D-502 / D-503).', 'P1 P4'],
  ['FC-M6 Supplies from the photo', 'Both drains measured: 23 1/4" (left by Andriy 11.11.26 = right). The four supplies are from the photo. Floor build-up ASSUMED 5/8" as ADU. Plumber: sink drain body max 4 1/2" long from the flange (none in the fixture order).', 'P2 P3 P5 P6'],
  ['FC-M7 Sink + countertop', 'Sinks: Lacava 5451-001 undermount x2 (fixture order S6689471): 21 3/4 x 15 3/8 x 6 3/8", drain 1 3/4" with overflow, glued under the 2 cm slab (rim 33 1/4"). Top 34" (KPS), visible edge 3" built up (Lusso 3D). Faucets Graff G-6300 on the top. Countertop and sinks by others - fabricator to confirm the 2 cm slab.', 'TOP'],
  ['FC-C4 Blocking behind closed wall', 'Wall 1 is closed. GC to confirm 2x6 blocking: B1 at 31" (top edge), B2 at 17" (left sink unit), B3 at 6" (right sink + drawers, extended under the shelf) - see D-501.', 'B1-B3'],
  ['FC-C2 Left shelf', 'Open shelf (pos. 60) under the left sink unit (~6 1/4" - 8 1/2" scaled) fixes into the B3 row (band 3 1/4" - 8 3/4"). Lusso to confirm shelf height, thickness and fixing (brackets / hidden rail).', 'B3']
]
notes = [
  'UCON scope only: rough-ins behind / inside our cabinets, blocking, clearances from fixtures to our cabinets. Faucets are deck-mounted on the top (no wall rough-in); receptacles above the top and mirror boxes are by others.',
  'AT CABINET INSTALL: test lines CUT; no stops / valves installed - capped stubs only. Valves and trim by the plumber after the vanity is set.',
  'Rough-ins AS-IS from the UCON site survey 10.29.26 (Leica DISTO IMG_4677 + photos). Heights to the CENTRE of the stub above FINISHED floor = DISTO - 5/8" (assumed as ADU, FC-M6). Cabinets: KPS 1791_p.bATH 26.09.2026 (Leicht 238 METURO).',
  'SENIOR REVIEW 11.11.26 (UCON Failure Case Library): OPEN FC-M7 + FC-M4 (critical - Lusso U drawers, drain body max 4 1/2", D-502 / D-503), FC-M6, FC-C4, FC-C2 (shelf height). CLOSED: FC-M5 (deck faucets - drains 1/4" and 9/16" off the sink CLs, OK for a drain), FC-C5 blocking on the edges, FC-P2 assumptions in red.'
]
plan_dims = {
  groups: [{ along: :x, at: D + 152, ref: W, toward: [D, 3000], off: 0.45, zero: 'WALL 2 FACE',
             stops: [[SR, 'SINK R CL'], [SL, 'SINK L CL'], [W - 2206, 'VAN']] }],
  locate: []
}
red_notes = [
  ["! LUSSO U-SHAPE SINK DRAWERS REQUIRED\nDRAIN BODY MAX 4 1/2\" (D-502/503) - FC-M4", 2500, 640]
]
cell = { scene: '1791 MEP Elevation', axis: :x, depth: D, a0: W - 3500, a1: W, zmax: 1300, scale: 1.0 / 16, view_key: :three_q, top_from: 864,
         blk_note_at: [2500, 1150], blk_tail: 'FROM WALL 2; EXTEND LEFT TO THE NEXT STUD PAST THE VANITY',
         conflicts: [],
         pts: pts, blocks: blk, zones: zones, ref: { at: W, text: 'wall 2 face' }, notes: red_notes,
         outlines: [{ a0: W - 2206, a1: W - 1460, z0: 432, z1: 788, label: 'SINK L' },
                    { a0: W - 2206, a1: W - 1460, z0: 160, z1: 215, label: nil },
                    { a0: W - 1460, a1: W - 787, z0: 153, z1: 788, label: 'DRAWERS' },
                    { a0: W - 787, a1: W, z0: 153, z1: 788, label: 'SINK R' },
                    { a0: SL - 276, a1: SL + 276, z0: 682, z1: 844, label: nil },
                    { a0: SR - 276, a1: SR + 276, z0: 682, z1: 844, label: nil }] }

rows = pts.map do |p|
  loc = p['x'] ? "#{DS.in_q(p['horiz_mm'])} from wall 2" : 'see note'
  r = [p['id'], p['item'].to_s, p['req'].to_s, loc, p['z'] ? DS.in_q(p['z']) : '-', p['status'], p['src'].to_s]
  p['flag'] ? r + [:red] : r
end
blk.each { |b| rows << [b['id'], '2x6 blocking (see D-501)', b['item'] + ' WALL CLOSED - CONFIRM IN PLACE.', "#{DS.in_q(W - b['a1'])} .. #{DS.in_q(W - b['a0'])} from wall 2 + 1 stud bay left", DS.in_q(b['cl']), b['status'], b['src'], :red] }
cols = [['ID', 0.45], ['ITEM', 2.1], ['REQUIREMENT', 4.9], ['LOCATION', 1.5], ['AFF', 0.7], ['STATUS', 1.2], ['SOURCE', 2.2]]

DS.instance_eval do
  start([LOGO], tags)
  @index = []; @stops = []; @dims = 0; @connected = 0
  @notes = [
    'Cabinets: KPS designstudio / Lusso, 1791_p.bATH installation sheets 26.09.2026 (Leicht 238 METURO). Room and rough-ins: UCON site survey 10.29.26 (Leica DISTO + photo).',
    'Room per KPS: wall 1 = 5334, ceiling 2438. Room depth ~2020 scaled from the KPS plan (not measured). Only the vanity end of wall 1 is drawn.',
    'Vanity wall-hung, depth 559, from wall 2: filler 57 | sink unit 730 (153..788, drawers 279 / 356) | drawers 673 (153 / 203 / 280) | sink unit 730 (432..788, one drawer 356, open below, shelf) | panel 16. Top 864 (KPS).',
    'A-sheets: millimetres, to compare with the KPS sheets. M-sheets: inches, for the GC. RED = to verify with GC.',
    'Sinks: Lacava 5451-001 undermount x2 (fixture order S6689471, 11.08.26), 552 x 391 x 162, on the KPS CLs 1826 / 422 from wall 2, glued under a 2 cm slab (rim 844). Top 864 with a 76 built-up edge (Lusso 3D 10.11.26). Faucets Graff G-6300 on the top. Sinks and top by others.',
    'Blocking: 2x6 flat, axis ON the top (788) and bottom (432 left unit / 153 right + drawers) edges, B3 extended under the open shelf - see D-501.'
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
  vp = place(skp, 'A2 Plan', :three_q, P0.(XL, D - 1300), P0.(W + 152, D + 152), room: [1.2, 1.3])
  p3 = ->(a, b) { P0.(a, b) }
  ch = [W - 2206, W - 2190, W - 1460, W - 787, W - 57, W]
  ch.each_cons(2) { |a, b| dim(vp, p3, [a, D + 152], [b, D + 152], r, :above) }
  dim(vp, p3, [W - 2206, D + 152], [W, D + 152], 2 * r, :above)
  dim(vp, p3, [SL, D - 1100], [W, D - 1100], 2 * r, :below)
  dim(vp, p3, [SR, D - 1100], [W, D - 1100], r, :below)
  dim_toward(vp, P0.(W - 2206, D - 559), P0.(W - 2206, D), r * 0.6, P0.(XL, D - 280))
  [[SL, 'SINK L CL'], [SR, 'SINK R CL']].each do |x, t|
    sa = vp.model_to_paper_point(P0.(x, D)); sb = vp.model_to_paper_point(P0.(x, D - 1000))
    line(sa.x, sa.y, sb.x, sb.y, @l_dims, w: 0.5, c: self::ACCENT, dash: true)
    text(t, sb.x, sb.y + 0.05, @l_dims, size: 7, font: self::MONO, c: self::ACCENT, align: :center)
  end
  label_view(self::WX, self::WY, self::WW, self::WH, 1, 'A-101', 'PLAN - VANITY END OF WALL 1', :three_q)
  @index << ['A-101', 'PLAN']

  next_page('ELEVATION 1'); header(%(SCALE 3/4" = 1'-0" · DIMENSIONS IN MM)); sheet_code('A-201')
  ve = place(skp, 'A3 Elevation 1', :three_q, P0.(XL, D, 0), P0.(W, D, 2438), render: :vector, room: [1.3, 0.9])
  pe = ->(a, z) { P0.(a, D, z) }
  ch.each_cons(2) { |a, b| dim(ve, pe, [a, 0], [b, 0], r, :below) }
  dim(ve, pe, [W - 2206, 0], [W, 0], 2 * r, :below)
  dim(ve, pe, [SR, 1450], [W, 1450], r, :above)
  dim(ve, pe, [SL, 1450], [W, 1450], 2 * r, :above)
  zr = [0, 153, 432, 788, 864, 2438]
  zr.each_cons(2) { |a, b| dim(ve, ->(a2, z) { P0.(W, D, z) }, [W, a], [W, b], r, :right) }
  dim(ve, ->(a2, z) { P0.(W, D, z) }, [W, 0], [W, 2438], 2 * r, :right)
  [[SL, 'SINK L CL'], [SR, 'SINK R CL']].each_with_index do |(x, t), i|
    a = ve.model_to_paper_point(P0.(x, D, 864)); b = ve.model_to_paper_point(P0.(x, D, 1380))
    line(a.x, a.y, b.x, b.y, @l_dims, w: 0.5, c: self::ACCENT, dash: true)
    text(t, b.x - 0.05, b.y - 0.16, @l_dims, size: 7, font: self::MONO, c: self::ACCENT, align: :right)
  end
  q = ve.model_to_paper_point(P0.(XL + 700, D, 1900))
  note_text("CEILING 2438 PER KPS\nSINKS LACAVA 5451-001 (162 DEEP)\nUNDER 2 CM SLAB, TOP 864 (KPS)", q.x, q.y)
  label_view(self::WX, self::WY, self::WW, self::WH, 1, 'A-201', 'ELEVATION 1 - VANITY WALL', :three_q)
  @index << ['A-201', 'ELEVATION 1']

  @mep_in = true
  @mep_scale = %(SCALE 3/4" = 1'-0" · DIMENSIONS IN INCHES)
  mep_page_legend_questions('M-001', questions, notes: notes)
  mep_page_plan(skp, 'M-101', 'PRIMARY BATH - MEP PLAN (AS-IS)', '1791 MEP Plan', [XL, W + 152, D - 1300, D + 152], pts, [], render: :vector, dims: plan_dims,
                scale: 1.0 / 16, view_key: :three_q)
  mep_page_elevations(skp, 'M-201', 'PRIMARY BATH - WALL 1 (AS-IS)', [[cell, 'WALL 1 - DOUBLE VANITY', DS::WX, DS::WY, DS::WW, DS::WH]])
  @mep_scale = %(SCALE 1/2" = 1'-0" · DIMENSIONS IN INCHES)
  mep_table('POINT SCHEDULE', 'M-601', cols, rows, 'Locations from the face of wall 2 (right), heights to the centre above finished floor (DISTO - 5/8", assumed as ADU, FC-M6). ' \
            'AS-IS = installed (DISTO 10.29.26). RED rows: from the photo or in conflict - VERIFY WITH GC. At cabinet install: capped stubs only, test lines cut.')
  mep_page_detail_blocking('D-501', off: 0.0)

  # D-502 / D-503 P-TRAP FIT from the MODEL (v0.6, Andriy 2026-11-11): section scenes through each drain (probe 1791_95) -
  # the Kohler trap, the ORDERED Lacava 5451 bowl, the Lusso 3D drawer box (solid bottom, no U cut-out). Notes in inches.
  DW = 2020
  ptrap = lambda do |code, title, scene, xd, marks, items, foot|
    next_page(title); header('SCALE 1:5 (SECTION AT THE DRAIN, FROM THE MODEL) · NOTES IN INCHES'); sheet_code(code)
    zx = self::WX - 0.3; zy = self::WY + 0.4; zw = 5.6; zh = 5.4
    vs = viewport(skp, scene, zx, zy, zw, zh, scale: 1.0 / 5, render: :vector)
    pa = vs.model_to_paper_point(P0.(xd, DW - 640, 330)); pb = vs.model_to_paper_point(P0.(xd, DW + 152, 900))
    ww = (pb.x - pa.x).abs; hh = (pb.y - pa.y).abs
    vs.transform!(Geom::Transformation2d.new([1, 0, 0, 1, zx + (zw - ww) / 2 - [pa.x, pb.x].min, zy + (zh - hh) / 2 - [pa.y, pb.y].min]))
    vs.render if vs.render_needed?
    sp = ->(y, z) { vs.model_to_paper_point(P0.(xd, y, z)) }
    rx = sp.(DW + 152, 0).x + 0.15
    last = nil
    marks.sort_by { |z, *_r| -z }.each do |z, t, c|
      q = sp.(DW, z)
      ty = q.y - 0.05
      ty = last + 0.13 if last && ty < last + 0.13
      last = ty
      line(q.x, q.y, rx + 0.2, q.y, @l_sheet, w: 0.35, c: c, dash: true)
      text(t, rx + 0.25, ty, @l_sheet, size: 6.5, font: self::MONO, c: c)
    end
    tx = self::WX + 8.85; ty = self::WY + 0.3; tw = self::WW - 8.9
    label('WHAT THE MODEL SHOWS', tx, ty, @l_sheet)
    line(tx, ty + 0.22, tx + tw, ty + 0.22, @l_sheet, w: 1.0)
    yy = ty + 0.35
    items.each do |h, t, red|
      text(h, tx, yy, @l_sheet, size: 8, bold: true, c: red ? self::RED : self::INK)
      box_text(t, tx, yy + 0.17, tw, 1.3, @l_sheet, size: 7.5, c: self::INK2)
      yy += 1.6
    end
    box_text(foot, self::WX, self::WY + self::WH - 0.75, self::WW, 0.7, @l_sheet, size: 7, c: self::INK2)
    @index << [code, title]
  end
  foot = 'From the model (probes 1791_107 / 107b): vanity at the KPS height; Kohler P-trap at the AS-IS drain 23 1/4"; Lacava 5451-001 552 x 391 x 162 (spec) glued under the 2 cm slab (rim 33 1/4"); sink drain body (red) Lacava 7100-13 type, 4 1/2" from the flange (spec drawing, labels unreadable - ASSUMED), centred on the trap inlet; drawers and carcass from the Lusso 3D LUSSO_1791_PBATH (10.11.26). Slab 2 cm ASSUMED - fabricator to confirm.'
  ptrap.call('D-502', 'P-TRAP FIT - LEFT SINK', '1791 P-trap Section L', 3522,
    [[864, 'TOP 34" (KPS)', self::INK], [844, 'SLAB UNDERSIDE 33 1/4" (2 CM)', self::INK], [682, 'LACAVA BOWL BOTTOM 26 7/8"', self::INK], [635, 'DRAWER BOX TOP 25"', self::RED],
     [590, 'DRAIN AS-IS 23 1/4" - STAYS', self::INK], [586, 'DRAIN BODY END = TRAP INLET 23"', self::ACCENT],
     [476, 'BEND 18 3/4"', self::INK], [462, 'DRAWER BOTTOM 18 1/4"', self::RED], [451, 'CABINET BOTTOM 17 3/4"', self::INK2]],
    [['1. FITS AT THE KPS HEIGHT', 'Top 34". Bowl bottom 26 7/8". The sink drain body (4 1/2" from the flange) ends on the trap inlet at 23"; the trap arm on the as-is drain 23 1/4". Bend 18 3/4", 1/2" above the drawer bottom. Drains and blocking stay.', false],
     ['2. LUSSO: U-SHAPE DRAWER', 'Lusso 3D: standard drawer box 18 1/4" - 25". The trap sits inside it and the arm runs through its back - the drawer could not close. A U-shape sink drawer is required.', true],
     ['3. PLUMBER: DRAIN BODY', 'No drain in the fixture order. Use a European drain with overflow for the Lacava 1 3/4" hole, max 4 1/2" long from the flange (Lacava 7100-13 type); cut the tailpiece to the trap.', true],
     ['4. CONFIRM', 'Lusso: U drawer. Plumber: drain body. Fabricator: 2 cm slab (3 cm = 3/8" less room).', false]], foot)
  ptrap.call('D-503', 'P-TRAP FIT - RIGHT SINK', '1791 P-trap Section R', 4918,
    [[864, 'TOP 34" (KPS)', self::INK], [844, 'SLAB UNDERSIDE 33 1/4" (2 CM)', self::INK], [682, 'LACAVA BOWL BOTTOM 26 7/8"', self::INK], [635, 'DRAWER BOX TOP 25"', self::RED],
     [590, 'DRAIN AS-IS 23 1/4" - STAYS', self::INK], [586, 'DRAIN BODY END = TRAP INLET 23"', self::ACCENT],
     [476, 'BEND 18 3/4"', self::INK], [462, 'DRAWER BOTTOM 18 1/4"', self::RED], [356, 'LOWER DRAWER BOX TOP 14"', self::INK2]],
    [['1. FITS AT THE KPS HEIGHT', 'Same as the left sink: drain 23 1/4" stays, drain body ends on the trap inlet 23", bend 18 3/4". Room below down to the lower drawer box (14").', false],
     ['2. LUSSO: U-SHAPE DRAWER', 'Lusso 3D: standard drawer box 18 1/4" - 25" - the trap sits inside it. U-shape upper sink drawer required.', true],
     ['3. SUPPLIES', 'Supply stubs (~24 1/2", from the photo) sit in the upper drawer zone - the U cut-out must clear them, or the stops move into the cut-out zone.', false],
     ['4. PLUMBER: DRAIN BODY', 'European drain with overflow for the Lacava 1 3/4" hole, max 4 1/2" from the flange; cut the tailpiece to the trap.', false]], foot)
  fill_legend(@index.size, '0.5')
  @log << "dimensions #{@dims}, connected to the model #{@connected}#{@conn_err ? ' / ' + @conn_err : ''}"
  @log << "pages: #{@index.map(&:first).join(' ')}"
  finish(OUT)
end
puts DS.instance_variable_get(:@log)
stops = DS.instance_variable_get(:@stops)
puts "STOPS: #{stops.inspect}" unless stops.empty?
[OUT, OUT.sub('.layout', '.pdf')].each { |f| puts "#{File.basename(f)}  #{File.size(f)} b" }
require 'fileutils'
FileUtils.cp(OUT.sub('.layout', '.pdf'), File.expand_path('~/dev/_claude/1791_PBATH_Set_v0.9.pdf'))
snap = File.join(File.dirname(m.path), '1791_PBATH_MEP_at_Set_v0.9.skp')
FileUtils.cp(m.path, snap)
puts "model: #{m.path}  snapshot: #{File.basename(snap)} #{File.size(snap)} b"

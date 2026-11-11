# UCON-MODEL: 1791_BATH1_MEP
#
# 1791 BATH 1 - SET v0.2 (Andriy 2026-11-08): left stub = SPOUT, GC to move it 4" onto the sink CL; floor build-up 5/8" as ADU
# (heights AFF = DISTO from slab - 16); E1 shown approx, function to GC. Rebuilt on the laptop from Drive copy of 64c.
# v0.1 (Andriy 2026-11-06): AS-IS rough-ins from DISTO IMG_4679 + photos over the Leicht 226 IOS-M vanity (KPS 26.09.2026).
# Senior review (FC) on M-001. Rules: wall faucet = SPOUT CL only (handle out); drain type tolerance (round = exact, slot = 1/2");
# requirement at cabinet install: test lines cut, capped stubs only; trap window from the 10" upper drawer; M-001 max 6 questions.
# (v0.1) draft 1 not released (blocking past wall 4, notes over the spout label): moved aside, rebuilt.
# READ ONLY for the model. Writes ~/Documents/1791_BATH1_Set_v0.2.layout + .pdf; model snapshot next to it.
load File.expand_path('~/dev/ucon-cabinet-engine/tools/layout/mep_drawing_set.rb')
load File.expand_path('~/dev/ucon-cabinet-engine/tools/layout/symbols/plan_symbols.rb')
m = UCON::ProbeBridge.model
raise "wrong model: #{m.title}" unless m.title =~ /1791_BATH1_MEP/i
# laptop 2026-11-08: an empty '1791_BATH1_MEP..skp' also matches the title - insist on the real file
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_BATH1_MEP.skp'
['A2 Plan', 'A3 Elevation 1', '1791 MEP Plan', '1791 MEP Elevation'].each { |n| raise "scene missing: #{n}" unless m.pages[n] }
OUT = File.expand_path('~/Documents/1791_BATH1_Set_v0.2.layout')
# drafts not released (11.08.26): 1 - revision text over the date, FC-M4 drain height; 2 - M-001 spout in 1/8" vs M-601 in 1/4"
%w[draft1 draft2].each do |dn|
  src = [OUT, OUT.sub('.layout', '.pdf')]
  next if src.any? { |f| File.exist?(f.sub('_Set_v0.2', "_Set_v0.2_#{dn}")) }
  src.each { |f| File.rename(f, f.sub('_Set_v0.2', "_Set_v0.2_#{dn}")) if File.exist?(f) }
  break
end
raise "STOP: exists #{OUT}" if File.exist?(OUT)
LOGO = File.expand_path('~/Documents/CE_logo_cube_transparent.png')
DS = UCON::DrawingSet
skp = m.path
tags = {
  'ProjectName' => '1791 - Bath 1', 'ProjectAddress' => "876 Highlands Circle\nLos Altos, CA 94024", 'ProjectNumber' => '1791',
  'ClientName' => 'Sangeeta Anand', 'Designer' => 'Lusso / KPS', 'Drafter' => 'UCON', 'CheckedBy' => ' ',
  'Issue' => 'COORDINATION', 'Revision' => '0.2', 'IssueDate' => '11.08.26',
  'Status' => 'PRELIMINARY - FOR COORDINATION',
  'StatusDesc' => 'Rough-ins AS-IS from the UCON site survey 10.29.26 (DISTO). RED = to verify with GC. Cabinets from KPS 26.09.2026. Not engineered.',
  'Rev1' => '0.1', 'Rev1Desc' => 'As-is, senior review', 'Rev1Date' => '11.06.26',
  'Rev2' => '0.2', 'Rev2Desc' => 'Spout to sink CL, floor 5/8"', 'Rev2Date' => '11.08.26', 'Rev3' => ' ', 'Rev3Desc' => ' ', 'Rev3Date' => ' ',
  'Rev4' => ' ', 'Rev4Desc' => ' ', 'Rev4Date' => ' '
}
M  = UCON::MEP
pr = M.load_json(File.expand_path('~/dev/ucon-cabinet-engine/tools/mep/projects/1791_bath1_asis.json'))
D = 1575; W = 2743
boxes = pr['blocking_boxes']
pts   = M.points(boxes, pr).reject { |p| p['scope'] == 'out' }
zones = M.plumbing_zones(pts.select { |p| p['group'] == 'vanity' })
bk = pr['blocking'] || {}
# left end is wall 4: no extension past it (engine extends both ends) -> ext 0, the right extension is written in the item
blk = M.blocking(boxes, along: 'x', face: 'y1', wall_at: D, bottom_row: true, below_top: 0, above_bottom: 0, ext: 0, ceiling: pr['ceiling_mm'])
blk.each { |b| b['item'] = b['item'].sub(/\)\z/, ', from wall 4; extend right to the next stud past 958 (16" o.c.))') }
WC = pr['wc']

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

questions = [
  ['FC-M7 CRITICAL - Sink type and drain type', 'Top is solid stone 4" (762-864) over a 10" upper drawer. Drain 23" AFF: the trap fits only if the bowl bottom is at 27 1/4" AFF or higher (max 2 3/4" below the stone). Designer: sink model, round or slot drain.', 'P1'],
  ['FC-M5 Spout vs sink CL', 'Left stub = SPOUT (UCON 11.08.26), at 29" from wall 4; sink CL 25" (KPS 632): 4" off. GC to move the spout rough-in 4" left onto the sink CL before drywall. Handle stub stays (by others).', 'P2'],
  ['FC-M4 Trap vs sink drawer', 'Upper drawer 20" - 30" AFF (508-762), lower 10" - 20". Drain 23" AFF inside the upper drawer. Lusso / Leicht to send the sink drawer cut-out (W x D x H) and drawer box heights.', 'P1'],
  ['FC-M6 Heights and site items', 'DISTO heights read from the slab; floor build-up ASSUMED 5/8" as in the ADU (heights here = slab - 5/8"). GC to confirm. P4 copper test loop: GC to cut. E1 low box ~6" AFF right of the vanity: GC to confirm function and exact position.', 'P1 P2 P4 E1'],
  ['FC-C4 Blocking behind closed wall', 'Wall 1 is closed. GC to confirm 2x6 blocking B1 / B2: axis on the vanity top edge 30" and bottom edge 10" AFF (D-501).', 'B1 B2']
]
notes = [
  'UCON scope only: rough-ins behind / inside our cabinets, blocking, clearances from fixtures to our cabinets. The faucet SPOUT is shown because it must sit on the sink CL; the handle is by others.',
  'AT CABINET INSTALL: test lines CUT; no stops / valves installed - capped stubs only. Valves and trim by the plumber after the vanity is set.',
  'Rough-ins AS-IS from the UCON site survey 10.29.26 (Leica DISTO IMG_4679 + photos). Heights to the CENTRE of the stub, above FINISHED floor = DISTO from slab - 5/8" (assumed as ADU, FC-M6). Cabinets: KPS 1791_Bath 1 26.09.2026 (Leicht 226 IOS-M).',
  'SENIOR REVIEW 11.06.26 (UCON Failure Case Library): OPEN FC-M7 (critical), FC-M5, FC-M4, FC-M6, FC-C4. CLOSED: WC carrier CL 1400 - 17 3/8" clear to the vanity (min 15"), FC-C5 blocking on the edges, FC-P2 assumptions in red.'
]
plan_dims = {
  groups: [{ along: :x, at: D + 152, ref: 0, toward: [D, 3000], off: 0.45, zero: 'WALL 4 FACE',
             stops: [[632, 'SINK CL'], [734, 'SPOUT AS-IS'], [958, 'VAN'], [1400, 'WC CL']] }],
  locate: []
}
red_notes = [
  ["! UPPER DRAWER 10\" - TRAP WINDOW 22 1/2\" - 26\"\nONLY IF THE BOWL STAYS IN THE STONE (FC-M7)", 1850, 700],
  ["! P4 COPPER TEST LOOP\nGC TO CUT BEFORE VANITY INSTALL", 1850, 380]
]
cell = { scene: '1791 MEP Elevation', axis: :x, depth: D, a0: 0, a1: W, zmax: 1300, scale: 1.0 / 16, view_key: :three_q, top_from: 864,
         blk_note_at: [1750, 1150], blk_tail: 'FROM WALL 4; EXTEND RIGHT TO THE NEXT STUD PAST THE VANITY',
         conflicts: [{ a0: 632, a1: 734, z: 1180, label: 'MOVE SPOUT 4" LEFT', t0: 'SINK CL', t1: nil }],
         pts: pts, blocks: blk, zones: zones, ref: { at: 0, text: 'wall 4 face' }, notes: red_notes,
         outlines: [{ a0: 0, a1: 958, z0: 254, z1: 762, label: 'VANITY' },
                    { a0: 330, a1: 930, z0: 508, z1: 762, label: nil },
                    { a0: 572, a1: 692, z0: 570, z1: 659, label: nil }] }

rows = pts.map do |p|
  loc = p['x'] ? "#{DS.in_q(p['horiz_mm'])} from wall 4" : 'see note'
  r = [p['id'], p['item'].to_s, p['req'].to_s, loc, p['z'] ? DS.in_q(p['z']) : '-', p['status'], p['src'].to_s]
  p['flag'] ? r + [:red] : r
end
blk.each { |b| rows << [b['id'], '2x6 blocking (see D-501)', b['item'] + ' WALL CLOSED - CONFIRM IN PLACE.', "#{DS.in_q(b['a0'])} .. #{DS.in_q(b['a1'])} + 1 stud bay right", DS.in_q(b['cl']), b['status'], b['src'], :red] }
cols = [['ID', 0.45], ['ITEM', 2.1], ['REQUIREMENT', 4.9], ['LOCATION', 1.5], ['AFF', 0.7], ['STATUS', 1.2], ['SOURCE', 2.2]]

DS.instance_eval do
  start([LOGO], tags)
  @index = []; @stops = []; @dims = 0; @connected = 0
  @notes = [
    'Cabinets: KPS designstudio / Lusso, 1791_Bath 1 installation sheets 26.09.2026 (Leicht 226 IOS-M). Room and rough-ins: UCON site survey 10.29.26 (Leica DISTO + photo).',
    'Room per KPS: wall 1 = 2743, depth 1575. Ceiling not measured (2438 shown, assumed).',
    'Vanity wall-hung 254..762 AFF, depth 559: filler 30 | unit 300 | sink unit 600 | panel 28 = 958. Fronts 254 / 254. Top solid stone 102 -> 864.',
    'A-sheets: millimetres, to compare with the KPS sheets. M-sheets: inches, for the GC. RED = to verify with GC.',
    'Sink type NOT known: shown as a round marker on CL 632 (KPS). Faucet: wall-mount, only the SPOUT is dimensioned.',
    'WC: wall-hung on a carrier, CL 1400 (DISTO). Blocking: 2x6 flat, axis ON the top (762) and bottom (254) edges - see D-501.'
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
  vp = place(skp, 'A2 Plan', :three_q, P0.(-152, 0), P0.(W + 152, D + 152), room: [1.2, 1.3])
  p3 = ->(a, b) { P0.(a, b) }
  [0, 30, 330, 930, 958, W].each_cons(2) { |a, b| dim(vp, p3, [a, D + 152], [b, D + 152], r, :above) }
  [[0, 958], [958, W]].each { |a, b| dim(vp, p3, [a, D + 152], [b, D + 152], 2 * r, :above) }
  dim(vp, p3, [0, D + 152], [W, D + 152], 3 * r, :above)
  dim(vp, p3, [0, 0], [632, 0], r, :below)
  dim(vp, p3, [958, 0], [1400, 0], r, :below)
  dim(vp, p3, [0, 0], [1400, 0], 2 * r, :below)
  dim_toward(vp, P0.(W + 152, 0), P0.(W + 152, D), r, P0.(6000, D / 2.0))
  dim_toward(vp, P0.(958, D - 559), P0.(958, D), r * 0.6, P0.(1300, D - 280))
  [[632, 'SINK CL'], [1400, 'WC CL']].each do |x, t|
    sa = vp.model_to_paper_point(P0.(x, D)); sb = vp.model_to_paper_point(P0.(x, 300))
    line(sa.x, sa.y, sb.x, sb.y, @l_dims, w: 0.5, c: self::ACCENT, dash: true)
    text(t, sb.x, sb.y + 0.05, @l_dims, size: 7, font: self::MONO, c: self::ACCENT, align: :center)
  end
  plan_symbol(vp, WC['symbol'], WC['cl_x'], WC['wall_y'], depth: WC['depth_mm'])
  label_view(self::WX, self::WY, self::WW, self::WH, 1, 'A-101', 'PLAN', :three_q)
  @index << ['A-101', 'PLAN']

  next_page('ELEVATION 1'); header(%(SCALE 3/4" = 1'-0" · DIMENSIONS IN MM)); sheet_code('A-201')
  ve = place(skp, 'A3 Elevation 1', :three_q, P0.(0, D, 0), P0.(W, D, 2438), render: :vector, room: [1.3, 0.9])
  pe = ->(a, z) { P0.(a, D, z) }
  [0, 30, 330, 930, 958, W].each_cons(2) { |a, b| dim(ve, pe, [a, 0], [b, 0], r, :below) }
  dim(ve, pe, [0, 0], [W, 0], 2 * r, :below)
  dim(ve, pe, [0, 1450], [632, 1450], r, :above)
  dim(ve, pe, [632, 1450], [734, 1450], r, :above)
  dim(ve, pe, [0, 1450], [1400, 1450], 2 * r, :above)
  zr = [0, 254, 508, 762, 864, 990, 2438]
  zr.each_cons(2) { |a, b| dim(ve, ->(a2, z) { P0.(W, D, z) }, [W, a], [W, b], r, :right) }
  dim(ve, ->(a2, z) { P0.(W, D, z) }, [W, 0], [W, 2438], 2 * r, :right)
  [[632, 'SINK CL', self::ACCENT, 864, 1380], [734, 'SPOUT AS-IS', self::RED, 864, 1380], [1400, 'WC CL', self::ACCENT, 0, 1300]].each_with_index do |(x, t, c, z0, z1), i|
    a = ve.model_to_paper_point(P0.(x, D, z0)); b = ve.model_to_paper_point(P0.(x, D, z1))
    line(a.x, a.y, b.x, b.y, @l_dims, w: 0.5, c: c, dash: true)
    text(t, b.x + (i.zero? ? -0.05 : 0.05), b.y - 0.16, @l_dims, size: 7, font: self::MONO, c: c, align: i.zero? ? :right : :left)
  end
  q = ve.model_to_paper_point(P0.(1900, D, 2100))
  note_text("! SPOUT STUB 734 (SITE) -> MOVE TO SINK CL 632\nGC: 102 (4\") LEFT, BEFORE DRYWALL (FC-M5)", q.x, q.y)
  q = ve.model_to_paper_point(P0.(1900, D, 1750))
  note_text("CEILING NOT MEASURED (2438 ASSUMED)\nSINK TYPE UNKNOWN - MARKER ONLY", q.x, q.y)
  label_view(self::WX, self::WY, self::WW, self::WH, 1, 'A-201', 'ELEVATION 1 - VANITY WALL', :three_q)
  @index << ['A-201', 'ELEVATION 1']

  @mep_in = true
  @mep_scale = %(SCALE 3/4" = 1'-0" · DIMENSIONS IN INCHES)
  mep_page_legend_questions('M-001', questions, notes: notes)
  mep_page_plan(skp, 'M-101', 'BATH 1 - MEP PLAN (AS-IS)', '1791 MEP Plan', [-152, W + 152, 0, D + 152], pts, [], render: :vector, dims: plan_dims,
                scale: 1.0 / 16, view_key: :three_q, after: ->(v) { plan_symbol(v, WC['symbol'], WC['cl_x'], WC['wall_y'], depth: WC['depth_mm']) })
  mep_page_elevations(skp, 'M-201', 'BATH 1 - WALL 1 (AS-IS)', [[cell, 'WALL 1 - VANITY', DS::WX, DS::WY, DS::WW, DS::WH]])
  @mep_scale = %(SCALE 1/2" = 1'-0" · DIMENSIONS IN INCHES)
  mep_table('POINT SCHEDULE', 'M-601', cols, rows, 'Locations from the face of wall 4 (left), heights to the centre above finished floor (slab - 5/8", assumed as ADU, FC-M6). ' \
            'AS-IS = installed (DISTO 10.29.26). RED rows: from the photo or in conflict - VERIFY WITH GC. At cabinet install: capped stubs only, test lines cut.')
  mep_page_detail_blocking('D-501', off: 0.0)
  fill_legend(@index.size, '0.2')
  @log << "dimensions #{@dims}, connected to the model #{@connected}#{@conn_err ? ' / ' + @conn_err : ''}"
  @log << "pages: #{@index.map(&:first).join(' ')}"
  finish(OUT)
end
puts DS.instance_variable_get(:@log)
stops = DS.instance_variable_get(:@stops)
puts "STOPS: #{stops.inspect}" unless stops.empty?
[OUT, OUT.sub('.layout', '.pdf')].each { |f| puts "#{File.basename(f)}  #{File.size(f)} b" }
require 'fileutils'
FileUtils.cp(OUT.sub('.layout', '.pdf'), File.expand_path('~/dev/_claude/1791_BATH1_Set_v0.2.pdf'))
snap = File.join(File.dirname(m.path), '1791_BATH1_MEP_at_Set_v0.2.skp')
FileUtils.cp(m.path, snap)
puts "model: #{m.path}  snapshot: #{File.basename(snap)} #{File.size(snap)} b"

# UCON-MODEL: 1791_ADU_MEP
#
# 1791 ADU - SET v0.11 (Andriy 2026-11-11): ORDERED sink Lacava 5451-001 (552 x 391 x 162, fixture order S6689471) glued under
# the 2 cm slab (rim 33 1/4"); drawers from the Lusso 3D (U cut-out in the upper drawer, lower drawer box top 457). Window for
# the trap arm 571..579 (22 1/2" - 22 3/4"); drain 568 (22 3/8") is 3 mm low. New D-502 from the model (probe 1791_99b).
# Built from 1791_53b (v0.10).
# 1791 ADU - SET v0.10 (Andriy 2026-11-06): GC tape heights in (Mario 11.06.26, on slab + 5/8" tile): P1 22 3/8", P2/P3 24" AFF, FC-M6 closed; drain at the top of the window - sink bowl max 6" (FC-M7 critical). Base v0.9: SENIOR REVIEW by the UCON Failure Case Library - open cases on M-001 with their FC numbers;
# M-101 / M-201 at 3/4" (M-201 up to 1400); estimated drain window note (FC-M4); model snapshot next to the set. Base v0.8: M-sheets in INCHES ONLY, no feet-inches (engine in_q). Base v0.7: WC as a LayOut scrapbook 2D symbol on the plans (no 3D WC); blocking ceiling rule wired. Base v0.6:: cabinets in front - blocking bands on a layer under the transparent wireframe view. Base: v0.5: blocking axis ON the cabinet edges; UCON SCOPE ONLY - the sheets show what touches
# our cabinetry (vanity rough-ins, blocking, WC CL to the vanity). Shower, WC installation, mirror / sconce wiring, lights: out
# (kept in the data with scope 'out'). Every change of the drawings = next revision 0.N, no letter suffixes. Otherwise as v0.3 AS-IS (Andriy 2026-11-04): rough-ins as installed, from the UCON site survey 2026-10-29 (DISTO Plan
# 125345 + photo IMG_4409). Shell 3204 x 2421, WC floor-mounted. Heights not measured on site: from the photo, RED = VERIFY
# WITH GC. Points from tools/mep/projects/1791_adu_asis.json (placed only, no role defaults). READ ONLY for the model.
#   G-001 sheet index + general notes | A-101 plan, A-201 elevation (mm, to compare with KPS) |
#   M-001 symbols + questions, M-101 MEP plan, M-201 wall 1, M-601 point schedule (inches, for the US GC)
# Model state: vanity depth 600, top 40, faucet schematic, WC as CL only (probe 1791_10b).
# Writes ~/Documents/1791_ADU_Set_v0.9.layout + .pdf; refuses to overwrite.
load File.expand_path('~/dev/ucon-cabinet-engine/tools/layout/mep_drawing_set.rb')
load File.expand_path('~/dev/ucon-cabinet-engine/tools/layout/symbols/plan_symbols.rb')
load File.expand_path('~/dev/ucon-cabinet-engine/tools/mep/probes/1791/1791_ptrap_page.rb')
m = UCON::ProbeBridge.model
raise "wrong model: #{m.title}" unless m.title =~ /1791_ADU_MEP/i
raise "wrong file: #{m.path}" unless File.basename(m.path) == '1791_ADU_MEP.skp'
['A2 Plan', 'A3 Elevation 1', '1791 MEP Plan', '1791 MEP Elevation', '1791 P-trap Section'].each { |n| raise "scene missing: #{n}" unless m.pages[n] }
OUT = File.expand_path('~/Documents/1791_ADU_Set_v0.11.layout')
# v0.4 was not released (rev text over the date, shower glass dims out of scope): this build replaces it - Andriy 2026-11-04,
# a version number changes per RELEASED set; an unreleased build of the same version may be rebuilt.
# v0.10 draft 1 was not released (AFF rounded to 1/4", M-001 text overlap): moved aside, rebuilt (Andriy rule: unreleased build may be rebuilt)
[OUT, OUT.sub('.layout', '.pdf')].each { |f| File.rename(f, f.sub('_Set_v0.11', '_Set_v0.11_draft1')) if File.exist?(f) && !File.exist?(f.sub('_Set_v0.11', '_Set_v0.11_draft1')) }
raise "STOP: exists #{OUT}" if File.exist?(OUT)
LOGO = File.expand_path('~/Documents/CE_logo_cube_transparent.png')
DS = UCON::DrawingSet
skp = m.path
tags = {
  'ProjectName' => '1791 - ADU Bath', 'ProjectAddress' => "876 Highlands Circle\nLos Altos, CA 94024", 'ProjectNumber' => '1791',
  'ClientName' => 'Sangeeta Anand', 'Designer' => 'Lusso / KPS', 'Drafter' => 'UCON', 'CheckedBy' => ' ',
  'Issue' => 'COORDINATION', 'Revision' => '0.11', 'IssueDate' => '11.11.26',
  'Status' => 'PRELIMINARY - FOR COORDINATION',
  'StatusDesc' => 'Rough-ins AS-IS: X from the UCON site survey 10.29.26, heights by GC tape 11.06.26. Cabinets from KPS 26.09.2026. Not engineered.',
  'Rev1' => '0.8', 'Rev1Desc' => 'Inches only', 'Rev1Date' => '11.04.26',
  'Rev2' => '0.9', 'Rev2Desc' => 'Senior review (FC)', 'Rev2Date' => '11.06.26',
  'Rev3' => '0.10', 'Rev3Desc' => 'GC heights measured', 'Rev3Date' => '11.06.26',
  'Rev4' => '0.11', 'Rev4Desc' => 'Lacava sink, D-502', 'Rev4Date' => '11.11.26'
}

M  = UCON::MEP
pr = M.load_json(File.expand_path('~/dev/ucon-cabinet-engine/tools/mep/projects/1791_adu_asis.json'))
boxes = pr['blocking_boxes']
pts   = M.points(boxes, pr).reject { |p| p['scope'] == 'out' } # UCON scope only (Andriy 2026-11-04)
zones = M.plumbing_zones(pts)
bk = pr['blocking'] || {}
edge = !!bk['edge_axis']
# bottom row only for Leicht; a run up to the ceiling goes under the 1 1/2" top plate (Andriy 2026-11-04)
blk   = M.blocking(boxes, along: 'x', face: 'y1', wall_at: 1600, bottom_row: !!bk['bottom_row'] || pr['brand'] == 'Leicht',
                   below_top: edge ? 0 : M::BLOCK_BELOW_TOP, above_bottom: edge ? 0 : M::BLOCK_ABOVE_BOTTOM, ceiling: pr['ceiling_mm'])
WC = pr['wc'] # 2D symbol on the plans, CL only on the elevations

# Scales the template does not carry (it knows 1/2" and 1 1/2"): 1" and 3/4" = 1'-0", label + bar.
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

# place a scaled viewport centred in the work zone on the model extent [a0, b0, a1, b1] (two model points)
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

P0 = ->(x, y, z = 0) { Geom::Point3d.new(x / 25.4, y / 25.4, z / 25.4) }

questions = [
  ['FC-M7 / FC-M4 CRITICAL - Lacava 5451 vs the drawers', 'Lacava 5451-001 (6 3/8") under the 2 cm slab: bowl bottom 26 7/8", trap arm needed at 22 3/4" or lower. Lusso drawer: U cut-out OK; lower drawer box top 18" - the bend must stay above it: arm at 22 1/2" or higher. Drain 22 3/8" is 1/8" low (D-502).', 'P1'],
  ['FC-M4 Fix for the 1/8"', 'Plumber: set the trap 1/8" - 3/8" above the stub (the arm slopes 1/4"/ft down to the wall), trap at ~22 5/8". No wall opening. If not possible: a sink with a lower drain body, or Lusso lowers the lower drawer box.', 'P1'],
  ['FC-D1 Vanity depth and top', 'KPS / Lusso 3D: vanity 559 deep, top 864 (2 cm slab + built-up edge 39). The UCON model uses 600 deep. Fabricator to confirm the 2 cm slab.', '-'],
  ['FC-C4 Blocking behind closed wall', 'Wall 1 is closed. GC to confirm 2x6 blocking B1 / B2 in place: axis on the vanity top edge 825 and bottom edge 254 AFF (D-501).', 'B1 B2'],
  ['FC-M3 Power inside the vanity', 'KPS shows no light or power inside the vanity. Confirm that none is planned.', '-']
]
notes = [
  'UCON scope only: rough-ins behind / inside our cabinets, blocking, clearances from fixtures to our cabinets. Shower, WC installation, mirror / light wiring: by others, not shown.',
  'Rough-ins AS-IS: X from the UCON site survey 10.29.26 (Leica DISTO; P2 / P3 X from the photo). Heights by GC tape 11.06.26 (M. Martinez), taken on the slab and converted to finished floor.',
  'Heights to the CENTRE of the stub above finished floor. Cabinets from KPS 1791_ADU 26.09.2026 (Leicht 238 METURO). Finished floor = 30x30 tile 8.5 mm + thinset, about 5/8" over the slab (GC 11.06.26). Room: wall 1 = 3204, ceiling 2421.',
  'SENIOR REVIEW 11.11.26 (UCON Failure Case Library): OPEN FC-M7 / FC-M4 (critical - Lacava 5451 vs the Lusso drawers, D-502), FC-M4, FC-D1, FC-C4, FC-M3 (questions above). CLOSED: FC-M6 heights by GC tape 11.06.26, FC-C5 blocking on the edges, FC-P2 assumptions in red, FC-P3 revisions, WC CL 18 1/2" clear to the vanity (min 15").'
]

plan_dims = {
  groups: [{ along: :x, at: 1752, ref: 0, toward: [1600, 3000], off: 0.45, zero: 'WALL 4 FACE',
             stops: [[461, 'WC CL'], [930, 'VAN'], [1445, 'P2'], [1558, 'P1'], [1670, 'P3'], [2186, 'VAN']] }],
  locate: []
}
red_notes = [
  ["! LACAVA 5451: TRAP WINDOW 22 1/2\" - 22 3/4\"\nDRAIN 22 3/8\" IS 1/8\" LOW - SEE D-502 (FC-M4)", 2700, 700]
]
cell = { scene: '1791 MEP Elevation', axis: :x, depth: 1600, a0: 0, a1: 3204, zmax: 1400, scale: 1.0 / 16, view_key: :three_q,
         pts: pts, blocks: blk, zones: zones, ref: { at: 0, text: 'wall 4 face' }, notes: red_notes,
         outlines: [{ a0: 930, a1: 2186, z0: 254, z1: 825, label: 'VANITY' },
                    { a0: 1498, a1: 1618, z0: 571, z1: 579, label: nil },
                    { a0: 1559 - 276, a1: 1559 + 276, z0: 682, z1: 844, label: nil }] } # v0.9: estimated drain window (FC-M4) # v0.5: cabinet over the bands

# AFF of MEASURED points to 1/8" (GC tape), the engine rounds to 1/4"
in8 = ->(mmv) { q = (mmv.to_f / 25.4 * 8).round; w, f = q.divmod(8); f.zero? ? %(#{w}") : %(#{w} #{(f / f.gcd(8))}/#{8 / f.gcd(8)}") }
rows = pts.map do |p|
  loc = p['x'] ? "#{DS.in_q(p['horiz_mm'])} from wall 4" : 'see note'
  r = [p['id'], p['item'].to_s, p['req'].to_s, loc, p['z'] ? (p['status'].to_s =~ /MEASURED/ ? in8.(p['z']) : DS.in_q(p['z'])) : '-', p['status'], p['src'].to_s]
  p['flag'] ? r + [:red] : r
end
blk.each { |b| rows << [b['id'], '2x6 blocking (see D-501)', b['item'] + ' WALL CLOSED - CONFIRM IN PLACE.', "#{DS.in_q(b['a0'])} .. #{DS.in_q(b['a1'])} + 1 stud bay each side", DS.in_q(b['cl']), b['status'], b['src'], :red] }
cols = [['ID', 0.45], ['ITEM', 2.1], ['REQUIREMENT', 4.9], ['LOCATION', 1.5], ['AFF', 0.7], ['STATUS', 1.2], ['SOURCE', 2.2]]

# RED notes: a note whose text starts with "!" is drawn red with a red frame (VERIFY WITH GC)
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


DS.instance_eval do
  start([LOGO], tags)
  @index = []; @stops = []; @dims = 0; @connected = 0
  @notes_old = [
    'Source: KPS designstudio / Lusso, 1791_ADU installation sheets 26.09.2026 (Leicht 238 METURO). Dimensions on those sheets are used as given; others were scaled and are flagged.',
    'Vanity depth 600 per UCON (KPS plan prints 559). Countertop 40 = 2 + 2 cm stone, top 865 AFF.',
    'A-sheets: millimetres, to compare with the KPS sheets. M-sheets: inches, for the GC.',
    'KPS chain 930 + 1256 + 1020 = 3206 against their overall 3207; our chain closes at 1021.',
    'Faucet drawn as a schematic block; WC shown as its centre line only (carrier by others).',
    'Blocking: 2x6 flat in the 2x4 wall, two rows for the wall-hung vanity, each run to the next stud past the cabinet - see D-501.'
  ]
  @notes = [
    'Cabinets: KPS designstudio / Lusso, 1791_ADU installation sheets 26.09.2026 (Leicht 238 METURO). Room and rough-ins: UCON site survey 10.29.26 (Leica DISTO + photo).',
    'Room AS-IS: wall 1 = 3204 (KPS 3207), ceiling 2421 (KPS 2438). Vanity kept at 930 from wall 4: its sink CL 1558 = the as-is drain.',
    'Vanity depth 600 per UCON (KPS plan prints 559). Countertop 2 cm slab, built-up edge to 40, top 865 AFF. Sink: Lacava 5451-001 undermount (fixture order S6689471) glued under the slab - by others.',
    'A-sheets: millimetres, to compare with the KPS sheets. M-sheets: inches, for the GC. RED = height from the photo, verify with GC.',
    'WC is FLOOR-MOUNTED (as built), CL 461 from wall 4: only its clearance to the vanity is ours; its installation is by others. Faucet drawn as a schematic block.',
    'Blocking: 2x6 flat in the stud wall, two rows for the wall-hung vanity: axis ON the top edge (825) and ON the bottom edge (254), so the vanity can move up or down; each run to the next stud past the cabinet - see D-501. Wall 1 is closed: confirm in place.'
  ]
  # LAYER ORDER: views first, then everything that must sit on top of them (see 1791_07c)
  @l_vp = @doc.layers.add('Views', false)
  # v0.6: blocking bands on their own layer UNDER the views (cabinets in front, Andriy 2026-11-04)
  @l_blk = @doc.layers.add('Blocking', false)
  @doc.layers.reorder(@l_blk, @doc.layers.index(@l_vp))
  @blk_under_view = true
  @log << "layers: #{@doc.layers.map(&:name).join(' < ')}"
  @l_mep = @doc.layers.add('MEP', false)
  @l_dims = @doc.layers.add('Dimensions A', false)
  r = self::ROW

  legend_page('G-001')

  @mep_in = false
  # ---- A-101 plan: model x right, y up (wall 1 at the top)
  next_page('PLAN'); header(%(SCALE 3/4" = 1'-0" · DIMENSIONS IN MM)); sheet_code('A-101')
  vp = place(skp, 'A2 Plan', :three_q, P0.(-152, 0), P0.(3356, 1752), room: [1.2, 1.3])
  p3 = ->(a, b) { P0.(a, b) }
  # row 1 above wall 1: the vanity broken down; row 2: wall to vanity to wall; row 3: overall (KPS: 958/28/600/28/1048 and 930/1020)
  xs = [0, 930, 958, 1258, 1858, 2158, 2186, 3204]
  xs.each_cons(2) { |a, b| dim(vp, p3, [a, 1752], [b, 1752], r, :above) }
  [[0, 930], [930, 2186], [2186, 3204]].each { |a, b| dim(vp, p3, [a, 1752], [b, 1752], 2 * r, :above) }
  dim(vp, p3, [0, 1752], [3204, 1752], 3 * r, :above)
  # below the room: WC CL and glass from wall 4 (KPS: not dimensioned)
  dim(vp, p3, [0, 0], [461, 0], r, :below)
  dim(vp, p3, [461, 0], [930, 0], r, :below) # WC CL to the vanity - the clearance that is ours
  # depths, on the right: room 1600, vanity 559
  dim_toward(vp, P0.(3356, 0), P0.(3356, 1600), r, P0.(5000, 800))
  dim_toward(vp, P0.(2186, 1000), P0.(2186, 1600), r, P0.(2500, 1300))
  # WC: centre line only (Andriy) - dashed, from wall 1 into the room
  wa = vp.model_to_paper_point(P0.(461, 1600)); wb = vp.model_to_paper_point(P0.(461, 700))
  line(wa.x, wa.y, wb.x, wb.y, @l_dims, w: 0.5, c: self::ACCENT, dash: true)
  text('WC CL', wb.x, wb.y + 0.05, @l_dims, size: 7, font: self::MONO, c: self::ACCENT, align: :center)
  plan_symbol(vp, WC['symbol'], WC['cl_x'], WC['wall_y'], depth: WC['depth_mm'])
  label_view(self::WX, self::WY, self::WW, self::WH, 1, 'A-101', 'PLAN', :three_q)
  @index << ['A-101', 'PLAN']

  # ---- A-201 elevation 1: model x right, z up, seen on the face of wall 1 (y = 1600)
  next_page('ELEVATION 1'); header(%(SCALE 3/4" = 1'-0" · DIMENSIONS IN MM)); sheet_code('A-201')
  ve = place(skp, 'A3 Elevation 1', :three_q, P0.(0, 1600, 0), P0.(3204, 1600, 2421), render: :vector, room: [1.3, 0.9])
  pe = ->(a, z) { P0.(a, 1600, z) }
  # along the floor: same breakdown as the plan + glass (KPS: 930 / 1256 / 3207)
  xe = [0, 930, 958, 1258, 1858, 2158, 2186, 3204]
  xe.each_cons(2) { |a, b| dim(ve, pe, [a, 0], [b, 0], r, :below) }
  [[0, 930], [930, 2186], [2186, 3204]].each { |a, b| dim(ve, pe, [a, 0], [b, 0], 2 * r, :below) }
  dim(ve, pe, [0, 0], [3204, 0], 3 * r, :below)
  # sink / mirror CL from wall 4, above the mirror (KPS: 1558)
  dim(ve, pe, [0, 1800], [1558, 1800], r, :above)
  # heights on the right (KPS: 254 / 571 / 1613 / 2438)
  zr = [0, 254, 825, 865, 2421]
  zr.each_cons(2) { |a, b| dim(ve, ->(a2, z) { P0.(3204, 1600, z) }, [3204, a], [3204, b], r, :right) }
  [[0, 254], [254, 825], [825, 2421]].each { |a, b| dim(ve, ->(a2, z) { P0.(3204, 1600, z) }, [3204, a], [3204, b], 2 * r, :right) }
  dim(ve, ->(a2, z) { P0.(3204, 1600, z) }, [3204, 0], [3204, 2421], 3 * r, :right)
  # fronts of the left 300 unit, on its left side (KPS: 152 / 203 / 216)
  [[254, 470], [470, 673], [673, 825]].each { |a, b| dim_toward(ve, P0.(930, 1600, a), P0.(930, 1600, b), r, P0.(0, 1600, (a + b) / 2.0)) }
  ea = ve.model_to_paper_point(P0.(461, 1600, 0)); eb = ve.model_to_paper_point(P0.(461, 1600, 1100))
  line(ea.x, ea.y, eb.x, eb.y, @l_dims, w: 0.5, c: self::ACCENT, dash: true)
  text('WC CL', eb.x, eb.y - 0.16, @l_dims, size: 7, font: self::MONO, c: self::ACCENT, align: :center)
  dim(ve, pe, [0, 1150], [461, 1150], r * 0.6, :above)
  dim(ve, pe, [461, 1150], [930, 1150], r * 0.6, :above)
  q = ve.model_to_paper_point(P0.(2700, 1600, 2150))
  note_text("TOP 40: 2 CM SLAB + BUILT-UP EDGE\nSINK LACAVA 5451-001 UNDER THE SLAB", q.x, q.y)
  label_view(self::WX, self::WY, self::WW, self::WH, 1, 'A-201', 'ELEVATION 1 - VANITY WALL', :three_q)
  @index << ['A-201', 'ELEVATION 1']


  @mep_in = true
  @mep_scale = %(SCALE 3/4" = 1'-0" · DIMENSIONS IN INCHES)
  mep_page_legend_questions('M-001', questions, notes: notes)
  mep_page_plan(skp, 'M-101', 'ADU BATH - MEP PLAN (AS-IS)', '1791 MEP Plan', [-152, 3356, 0, 1752], pts, [], render: :vector, dims: plan_dims, scale: 1.0 / 16, view_key: :three_q,
                after: ->(v) { plan_symbol(v, WC['symbol'], WC['cl_x'], WC['wall_y'], depth: WC['depth_mm']) })
  mep_page_elevations(skp, 'M-201', 'ADU BATH - WALL 1 (AS-IS)', [[cell, 'WALL 1 - VANITY', DS::WX, DS::WY, DS::WW, DS::WH]])
  @mep_scale = %(SCALE 1/2" = 1'-0" · DIMENSIONS IN INCHES)
  mep_table('POINT SCHEDULE', 'M-601', cols, rows, 'Locations from the face of wall 4 (left), heights to the centre above finished floor. ' \
            'AS-IS = installed. X with DISTO 10.29.26; heights by GC tape 11.06.26 (on slab + 5/8" floor). RED rows: not measured - VERIFY WITH GC.')

  mep_page_detail_blocking('D-501', off: edge ? 0.0 : 2.0)

  ptrap_page(skp, 'D-502', 'P-TRAP FIT - SINK', '1791 P-trap Section', 1558, 1600,
    [[864, 'TOP 34"', self::INK], [844, 'SLAB UNDERSIDE 33 1/4" (2 CM)', self::INK], [682, 'LACAVA BOWL BOTTOM 26 7/8"', self::INK], [673, 'UPPER DRAWER TOP 26 1/2"', self::ACCENT],
     [579, 'TRAP ARM NEEDED <= 22 3/4"', self::RED], [575, 'TRAP AT ~22 5/8" (PROPOSED)', self::ACCENT], [568, 'DRAIN AS-IS 22 3/8" - 1/8" LOW', self::RED],
     [500, 'UPPER DRAWER BOTTOM 19 3/4" - U CUT', self::ACCENT], [461, 'BEND AT 22 5/8" = 18 1/8"', self::INK], [457, 'LOWER DRAWER BOX TOP 18"', self::RED]],
    [['1. WINDOW 22 1/2" - 22 3/4"', 'Bowl bottom 26 7/8" - 4" trap stack = 22 3/4" (top). The bend 4 1/2" below the arm must clear the lower drawer box (18") = 22 1/2" (bottom). Only 1/4" of window.', true],
     ['2. DRAIN 22 3/8" IS 1/8" LOW', 'At the as-is stub the bend touches the lower drawer box. Plumber: set the trap 1/8" - 3/8" above the stub - the arm slopes 1/4"/ft down to the wall (11" arm = ~1/4"). No wall opening.', true],
     ['3. LUSSO DRAWER: U CUT-OUT', 'Lusso 3D: upper drawer 19" - 26 1/2" with a U cut-out 11 3/4" wide x ~10" deep from the back - the trap fits in it. Lower drawer box: solid, top 18".', false],
     ['4. CONFIRM', 'Fabricator: 2 cm slab (3 cm = 3/8" less room, then nothing fits). Plumber: trap model and arm slope. Lusso: drawer as in their 3D.', false]],
    'From the model (probe 1791_99b): Kohler P-trap at the proposed ~22 5/8"; Lacava 5451-001 exterior 552 x 391 x 162 (spec sheet) glued under the 2 cm slab (rim 33 1/4"); drawers and carcass from the Lusso 3D LUSSO_1791_ADU (10.11.26). Trap stack: ~4" (103) from the bowl bottom to the arm, bend 4 1/2" (114) below the arm. Drain height by GC tape 11.06.26.')
  fill_legend(@index.size, '0.11')
  @log << "dimensions #{@dims}, connected to the model #{@connected}#{@conn_err ? ' / ' + @conn_err : ''}"
  @log << "pages: #{@index.map(&:first).join(' ')}"
  finish(OUT)
end
puts DS.instance_variable_get(:@log)
stops = DS.instance_variable_get(:@stops)
puts "STOPS: #{stops.inspect}" unless stops.empty?
[OUT, OUT.sub('.layout', '.pdf')].each { |f| puts "#{File.basename(f)}  #{File.size(f)} b" }
require 'fileutils'
FileUtils.cp(OUT.sub('.layout', '.pdf'), File.expand_path('~/dev/_claude/1791_ADU_Set_v0.11.pdf'))
# MODEL SNAPSHOT next to the issued set (Andriy 2026-11-06): the set and the model state it was built from stay linked.
snap = File.join(File.dirname(m.path), '1791_ADU_MEP_at_Set_v0.11.skp')
FileUtils.cp(m.path, snap)
puts "model: #{m.path}  snapshot: #{File.basename(snap)} #{File.size(snap)} b"

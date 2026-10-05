# UCON 11x17 LayOut sheet template - writer.
# Builds a NEW LayOut document from claude/LayOut_Sheet_Template_Spec_v1.md (design A, margins 1/2 in,
# Helvetica Neue + Menlo, imperial scales with scale bars). Runs inside SketchUp (LayOut Ruby API).
# Dev tool: nothing in src/ requires it. The base ~/Documents/UCON_LayOut_Base_11x17.layout is NOT opened:
# a new document carries none of 545 (no embedded model, no auto-text values, no stray texts off the sheet).
# Coordinates are inches from the sheet's top-left corner, as in the spec.
module UCON
  module SheetTemplate
    module_function

    INK = [0x1C, 0x1D, 0x1F].freeze
    INK2 = [0x3A, 0x3B, 0x3E].freeze
    LABEL = [0x6B, 0x6C, 0x6F].freeze
    HEAD = [0x5C, 0x5D, 0x60].freeze
    MINOR = [0x8A, 0x8B, 0x8E].freeze
    ROWLINE = [0xC9, 0xC9, 0xC6].freeze
    FILL = [0xF2, 0xF2, 0xF0].freeze
    ACCENT = [0xB7, 0x4B, 0x22].freeze
    SANS = 'Helvetica Neue'.freeze
    # MEDIUM IS NOT A FAMILY NAME TO LAYOUT. Style#font_family= with 'Helvetica Neue Medium' or 'HelveticaNeue-Medium'
    # reads back 'Verdana' and exports Verdana (probe 324, pdffonts). An RTF font table with the PostScript name
    # does give HelveticaNeue-Medium, so medium text is written through FormattedText#rtf= (see #medium_rtf).
    SANS_MED = 'HelveticaNeue-Medium'.freeze
    MONO = 'Menlo'.freeze

    # frame and title block (spec 2, 4)
    FX0, FY0, FX1, FY1 = 0.521, 0.521, 16.479, 10.479
    SX0 = 13.708
    TX = SX0 + 0.139
    TXR = FX1 - 0.139
    # sheet header and work area (spec 3)
    HX0, HX1 = 0.882, 13.347
    WX, WY, WW, WH = 0.882, 1.653, 12.465, 8.493
    LABEL_GAP, LABEL_H = 0.139, 0.389
    GUT = 0.25

    SCALE_HALF = %(SCALE 1/2" = 1'-0" · DIMENSIONS IN MM)
    SCALE_ONE_HALF = %(SCALE 1 1/2" = 1'-0" · DIMENSIONS IN MM)
    NTS = 'NOT TO SCALE'.freeze

    PROGRESS_DESC = 'This drawing is not intended to be used for contract pricing or fabrication purposes. ' \
                    'All content is subject to change.'.freeze
    APPROVAL_TEXT = 'By signing below, the client acknowledges review and approval of this design, its dimensions, ' \
                    'finishes, and specifications, and accepts responsibility for verification prior to ordering.'.freeze

    # Project fields are TAGS. Values here are visible placeholders in square brackets: the writer of a project
    # replaces every one from <project>_sheet_fields.json, and a bracket left on a sheet is a defect to report.
    # Company values are the company's own and are not placeholders.
    TAGS = [
      ['CompanyName', 'CABINETRY EDIT'],
      ['CompanyAddress', "7965 Silverton Ave Unit 1304\nSan Diego, CA 92126\n+1 (858) 432-6444"],
      ['ProjectName', '[Project name]'],
      ['ProjectAddress', "[Address line 1]\n[City, State ZIP]\n[Country]"],
      ['ProjectNumber', '[No.]'],
      ['ClientName', '[Client]'],
      ['Designer', '[Designer]'],
      ['Drafter', '[Drafter]'],
      ['CheckedBy', '[Checked]'],
      ['Issue', '[Issue]'],
      ['Revision', '[Rev]'],
      ['IssueDate', '[MM.DD.YY]'],
      ['Status', 'PROGRESS DRAWING'],
      ['StatusDesc', PROGRESS_DESC],
      ['Rev1', '[Rev]'], ['Rev1Desc', '[Description]'], ['Rev1Date', '[MM.DD.YY]'],
      ['Rev2', ' '], ['Rev2Desc', ' '], ['Rev2Date', ' '],
      ['Rev3', ' '], ['Rev3Desc', ' '], ['Rev3Date', ' '],
      ['Rev4', ' '], ['Rev4Desc', ' '], ['Rev4Date', ' ']
    ].freeze

    # [page name, sheet code, scale text, kind]
    PAGES = [
      ['COVER', 'G-000', nil, :cover],
      ['LEGEND & GENERAL NOTES', 'G-001', NTS, :legend],
      ['TOP VIEW', 'A-101', SCALE_HALF, :one],
      ['ELEVATION', 'A-201', SCALE_HALF, :one],
      ['ISLAND', 'A-202', SCALE_HALF, :two_stacked],
      ['DETAILS', 'A-501', SCALE_ONE_HALF, :details],
      ['3D VIEWS', 'A-601', NTS, :two_side],
      ['CABINET SCHEDULE', 'A-701', NTS, :schedule]
    ].freeze

    SCHEDULE_COLS = [['ITEM', 0.556], ['CODE', 1.250], ['DESCRIPTION', 3.759], ['W', 0.778], ['H', 0.778],
                     ['D', 0.778], ['QTY', 0.556], ['FINISH', 1.880], ['NOTES', 2.632]].freeze
    SCHEDULE_ROW_H = 0.30
    COVER_COLS = [2.550, 2.318, 2.550, 2.086, 3.709, 3.245].freeze

    def color(c) = Sketchup::Color.new(*c)

    # A new document with frame, title block and tags. tags: { 'ProjectName' => '...' } overrides TAGS values;
    # an empty value is written as one space (LayOut keeps a definition, the sheet shows nothing).
    def start(logo_paths, tags = {})
      @log = []
      @logo_logged = false
      doc = Layout::Document.new
      pi = doc.page_info
      pi.width = 17.0; pi.height = 11.0
      %w[left_margin right_margin top_margin bottom_margin].each { |k| pi.send("#{k}=", 0.5) }
      @doc = doc
      setup_tags(doc, tags)
      @l_frame = doc.layers.add('Frame', true)
      @l_block = doc.layers.add('Title Block', true)
      @l_sheet = doc.layers.add('Sheet', false)
      @l_views = doc.layers.add('View placeholders', false)
      @l_dims = doc.layers.add('Dimensions', false)
      @logo = logo_paths
      shared_frame
      shared_title_block
      @first_page_used = false
      doc
    end

    # the next page: the document's own first page once, then new ones
    def next_page(name, cover: false)
      page = @first_page_used ? @doc.pages.add(name) : @doc.pages.first
      @first_page_used = true
      page.name = name
      @page = page
      page.set_layer_visibility(@l_block, false) if cover
      page
    end

    def finish(out_path)
      @doc.save(out_path)
      pdf = out_path.sub(/\.layout\z/, '.pdf')
      @doc.export(pdf)
      @log << "saved #{out_path} (#{File.size(out_path)}), pdf #{File.size(pdf)}"
      @log
    end

    def build(out_path, logo_paths)
      raise "exists, not overwriting: #{out_path}" if File.exist?(out_path)
      start(logo_paths)
      PAGES.each do |name, code, scale, kind|
        next_page(name, cover: kind == :cover)
        if kind == :cover
          cover
        else
          header(scale)
          sheet_code(code)
          send("page_#{kind}", code)
        end
      end
      finish(out_path)
    end

    # ---------------------------------------------------------------- tags
    def setup_tags(doc, over = {})
      defs = doc.auto_text_definitions
      have = {}
      defs.each { |d| have[d.name] = d }
      TAGS.each do |name, value|
        d = have[name] || defs.add(name, Layout::AutoTextDefinition::TYPE_CUSTOM_TEXT)
        v = over.key?(name) ? over[name].to_s : value
        d.custom_text = v.strip.empty? ? ' ' : v
      end
      @log << "auto-text: #{defs.length} definitions (#{TAGS.size} custom)"
    end

    # ---------------------------------------------------------------- primitives
    def st(size: 8.5, font: SANS, c: INK, bold: false, align: :left)
      s = Layout::Style.new
      s.font_family = font; s.font_size = size; s.text_color = color(c); s.text_bold = bold
      s.text_alignment = { left: Layout::Style::ALIGN_LEFT, right: Layout::Style::ALIGN_RIGHT,
                           center: Layout::Style::ALIGN_CENTER }[align]
      s
    end

    def add(e, layer)
      layer.shared? ? @doc.add_entity(e, layer, nil) : @doc.add_entity(e, layer, @page)
      e
    end

    def text(str, x, y, layer, size: 8.5, font: SANS, c: INK, bold: false, align: :left)
      anchor = { left: Layout::FormattedText::ANCHOR_TYPE_TOP_LEFT, right: Layout::FormattedText::ANCHOR_TYPE_TOP_RIGHT,
                 center: Layout::FormattedText::ANCHOR_TYPE_TOP_CENTER }[align]
      t = Layout::FormattedText.new(str, Geom::Point2d.new(x, y), anchor)
      t.style = st(size: size, font: font, c: c, bold: bold, align: align)
      t.rtf = medium_rtf(str, size, c, align) if font == SANS_MED
      add(t, layer)
    end

    def medium_rtf(str, size, c, align)
      body = str.each_char.map do |ch|
        case ch
        when '\\', '{', '}' then "\\#{ch}"
        when "\n" then '\\line '
        else ch.ord < 128 ? ch : "\\u#{ch.ord}?"
        end
      end.join
      q = { left: '\\ql', right: '\\qr', center: '\\qc' }[align]
      "{\\rtf1\\ansi\\ansicpg1252{\\fonttbl\\f0\\fnil\\fcharset0 #{SANS_MED};}" \
        "{\\colortbl;\\red#{c[0]}\\green#{c[1]}\\blue#{c[2]};}" \
        "\\pard#{q}\\f0\\fs#{(size * 2).round}\\cf1 #{body}}"
    end

    def box_text(str, x, y, w, h, layer, size: 8.5, font: SANS, c: INK, bold: false, align: :left)
      t = Layout::FormattedText.new(str, Geom::Bounds2d.new(x, y, w, h))
      t.style = st(size: size, font: font, c: c, bold: bold, align: align)
      add(t, layer)
    end

    def label(str, x, y, layer, align: :left)
      text(str, x, y, layer, size: 7, font: MONO, c: LABEL, align: align)
    end

    def line(x0, y0, x1, y1, layer, w: 0.5, c: INK, dash: false)
      p = Layout::Path.new(Geom::Point2d.new(x0, y0), Geom::Point2d.new(x1, y1))
      s = Layout::Style.new
      s.stroked = true; s.stroke_width = w; s.stroke_color = color(c); s.solid_filled = false
      s.stroke_pattern = Layout::Style::STROKE_PATTERN_DASH if dash
      p.style = s
      add(p, layer)
    end

    def rect(x, y, w, h, layer, stroke: nil, sw: 0.5, fill: nil, dash: false)
      r = Layout::Rectangle.new(Geom::Bounds2d.new(x, y, w, h))
      s = Layout::Style.new
      if stroke then s.stroked = true; s.stroke_width = sw; s.stroke_color = color(stroke) else s.stroked = false end
      if fill then s.solid_filled = true; s.fill_color = color(fill) else s.solid_filled = false end
      s.stroke_pattern = Layout::Style::STROKE_PATTERN_DASH if dash
      r.style = s
      add(r, layer)
    end

    def circle(cx, cy, d, layer, sw: 1.5)
      e = Layout::Ellipse.new(Geom::Bounds2d.new(cx - d / 2, cy - d / 2, d, d))
      s = Layout::Style.new
      s.stroked = true; s.stroke_width = sw; s.stroke_color = color(INK); s.solid_filled = false
      e.style = s
      add(e, layer)
    end

    def logo(cx, cy, size, layer)
      @logo.each do |path|
        next unless File.exist?(path)
        begin
          img = Layout::Image.new(path, Geom::Bounds2d.new(cx - size / 2, cy - size / 2, size, size))
          add(img, layer)
          @log << "logo from #{File.basename(path)}" unless @logo_logged
          @logo_logged = true
          return img
        rescue StandardError => e
          @log << "logo #{File.basename(path)} refused: #{e.class}: #{e.message}"
        end
      end
      @log << 'NO LOGO placed'
      nil
    end

    # ---------------------------------------------------------------- shared: frame
    def shared_frame
      h = 0.75 / 72 # half of 1.5 pt, drawn inward
      rect(0.5 + h, 0.5 + h, 16.0 - 2 * h, 10.0 - 2 * h, @l_frame, stroke: INK, sw: 1.5)
    end

    # ---------------------------------------------------------------- shared: title block A (spec 4)
    def shared_title_block
      l = @l_block
      line(SX0, FY0, SX0, FY1, l, w: 1.5)
      # 1 logo
      logo((SX0 + FX1) / 2, (0.521 + 1.861) / 2, 0.944, l)
      line(SX0, 1.861, FX1, 1.861, l, w: 0.5, c: MINOR)
      # 2 company
      text('<CompanyName>', TX, 1.861 + 0.11, l, size: 10, bold: true)
      text('<CompanyAddress>', TX, 1.861 + 0.32, l, size: 8.5, c: INK2)
      line(SX0, 2.788, FX1, 2.788, l, w: 1.0)
      # 3 project
      label('PROJECT', TX, 2.788 + 0.08, l)
      text('<ProjectName>', TX, 2.788 + 0.24, l, size: 12, font: SANS_MED)
      text('<ProjectAddress>', TX, 2.788 + 0.47, l, size: 8.5, c: INK2)
      line(SX0, 3.847, FX1, 3.847, l, w: 0.5, c: MINOR)
      # 4 project no / client
      label('PROJECT NO.', TX, 3.847 + 0.07, l)
      text('<ProjectNumber>', TX, 3.847 + 0.22, l, size: 8.5, font: MONO)
      label('CLIENT', SX0 + 1.375 + 0.07, 3.847 + 0.07, l)
      text('<ClientName>', SX0 + 1.375 + 0.07, 3.847 + 0.22, l, size: 8.5)
      line(SX0, 4.285, FX1, 4.285, l, w: 0.5, c: MINOR)
      # 5 designer / drafter / checked
      [['DESIGNER', '<Designer>'], ['DRAFTER', '<Drafter>'], ['CHECKED', '<CheckedBy>']].each_with_index do |(lab, tag), i|
        x = i.zero? ? TX : SX0 + 0.917 * i + 0.07
        label(lab, x, 4.285 + 0.07, l)
        text(tag, x, 4.285 + 0.22, l, size: 8.5)
      end
      line(SX0, 4.729, FX1, 4.729, l, w: 1.0)
      # 6 issue / revision
      label('ISSUE / REVISION', TX, 4.729 + 0.07, l)
      cx = [TX, TX + 0.333, TX + 0.333 + 1.500]
      y = 4.729 + 0.24
      %w[REV DESCRIPTION DATE].each_with_index { |h, i| label(h, cx[i], y, l) }
      y += 0.17
      line(TX, y, TXR, y, l, w: 0.5, c: MINOR)
      4.times do |r|
        n = r + 1
        text("<Rev#{n}>", cx[0], y + 0.04, l, size: 7.5, font: MONO)
        text("<Rev#{n}Desc>", cx[1], y + 0.04, l, size: 7.5)
        text("<Rev#{n}Date>", cx[2], y + 0.04, l, size: 7.5, font: MONO)
        y += 0.201
        line(TX, y, TXR, y, l, w: 0.5, c: ROWLINE)
      end
      line(SX0, 6.072, FX1, 6.072, l, w: 0.5, c: MINOR)
      # 7 approval (fills the free height)
      label('APPROVAL', TX, 6.072 + 0.07, l)
      rect(TX, 6.33, TXR - TX, 1.33, l, stroke: MINOR, sw: 0.5, dash: true)
      text('STAMP / SEAL', (TX + TXR) / 2, 6.95, l, size: 7, font: MONO, c: MINOR, align: :center)
      text('Signature', TX, 7.80, l, size: 7.5, c: INK2)
      line(TX + 0.62, 7.93, TXR, 7.93, l, w: 0.75)
      text('Date', TX, 8.08, l, size: 7.5, c: INK2)
      line(TX + 0.62, 8.21, TXR, 8.21, l, w: 0.75)
      line(SX0, 8.424, FX1, 8.424, l, w: 0.5, c: MINOR)
      # 8 progress drawing (status)
      text('<Status>', (SX0 + FX1) / 2, 8.424 + 0.09, l, size: 9, bold: true, align: :center)
      box_text('<StatusDesc>', TX, 8.424 + 0.30, TXR - TX, 0.40, l, size: 7, c: INK2, align: :center)
      line(SX0, 9.186, FX1, 9.186, l, w: 1.0)
      # 9 page title
      label('PAGE TITLE', TX, 9.186 + 0.07, l)
      text('<PageName>', TX, 9.186 + 0.22, l, size: 12, font: SANS_MED)
      line(SX0, 9.742, FX1, 9.742, l, w: 0.5, c: MINOR)
      # 10 sheet
      label('SHEET', TX, 9.742 + 0.07, l)
      text('<PageNumber> / <PageCount>', TX, 9.742 + 0.20, l, size: 30, bold: true)
    end

    # ---------------------------------------------------------------- per page
    def sheet_code(code)
      text(code, TXR, FY1 - 0.20, @l_sheet, size: 7, font: MONO, c: LABEL, align: :right)
    end

    def header(scale)
      text('<PageName>', HX0, 0.826, @l_sheet, size: 30, font: SANS_MED)
      text(scale, HX1, 1.10, @l_sheet, size: 9, font: MONO, c: INK2, align: :right)
      line(HX0, 1.392, HX1, 1.392, @l_sheet, w: 1.5)
    end

    # a view zone + its label strip; bottom of the zone leaves room for the label
    def view(x, y, w, h, no, code, name, scale, placeholder: true)
      vh = h - LABEL_GAP - LABEL_H
      if placeholder
        rect(x, y, w, vh, @l_views, fill: FILL)
        text("SKETCHUP VIEWPORT — #{name}", x + w / 2, y + vh / 2 - 0.05, @l_views, size: 7, font: MONO, c: MINOR, align: :center)
      end
      ly = y + vh + LABEL_GAP
      d = LABEL_H
      circle(x + d / 2, ly + d / 2, d, @l_sheet)
      line(x + 0.06, ly + d / 2, x + d - 0.06, ly + d / 2, @l_sheet, w: 0.5)
      text(no.to_s, x + d / 2, ly + 0.035, @l_sheet, size: 8, font: MONO, align: :center)
      text(code, x + d / 2, ly + d / 2 + 0.03, @l_sheet, size: 6, font: MONO, align: :center)
      nx = x + d + 0.139
      text(name, nx, ly + 0.10, @l_sheet, size: 13.5, font: SANS_MED)
      line(nx, ly + d, x + w, ly + d, @l_sheet, w: 1.5)
      bar_w = scale_bar(x + w, ly + 0.07, scale)
      sc = scale == :half ? %(1/2" = 1'-0") : scale == :one_half ? %(1 1/2" = 1'-0") : 'NTS'
      # a narrow view (details 3 across) has no room for name + scale text + bar: the sheet header states the scale
      return if w < 5.0 && bar_w.positive?
      text(sc, x + w - bar_w - (bar_w.positive? ? 0.18 : 0), ly + 0.13, @l_sheet, size: 8, font: MONO, c: INK2, align: :right)
    end

    # right-aligned at x_right; returns its width (0 for NTS)
    def scale_bar(x_right, y, scale)
      case scale
      when :half then segs = [0.25, 0.25, 0.5, 0.5, 0.5]; labels = [[0, '0'], [0.5, %(1')], [1.0, %(2')], [2.0, %(4')]]
      when :one_half then segs = [0.375, 0.375, 0.375, 0.375]; labels = [[0, '0'], [0.375, %(3")], [0.75, %(6")], [1.5, %(1')]]
      else return 0
      end
      w = segs.sum; x0 = x_right - w - 0.09; hgt = 0.055 # 0.09: the end label is centred on the last tick
      x = x0
      segs.each_with_index do |s, i|
        rect(x, y, s, hgt, @l_sheet, stroke: INK, sw: 0.5, fill: i.even? ? INK : nil)
        x += s
      end
      labels.each { |off, t| text(t, x0 + off, y + hgt + 0.03, @l_sheet, size: 7, font: MONO, align: :center) }
      w + 0.09
    end

    def page_one(code)
      name = @page.name
      view(WX, WY, WW, WH, 1, code, name, :half)
    end

    def page_two_stacked(code)
      h = (WH - GUT) / 2
      view(WX, WY, WW, h, 1, code, "ISLAND \u2014 FRONT", :half)
      view(WX, WY + h + GUT, WW, h, 2, code, "ISLAND — BACK", :half)
    end

    def page_details(code)
      w = (WW - 2 * GUT) / 3; h = (WH - GUT) / 2
      6.times { |i| view(WX + (i % 3) * (w + GUT), WY + (i / 3) * (h + GUT), w, h, i + 1, code, "DETAIL #{i + 1}", :one_half) }
    end

    def page_two_side(code)
      w = (WW - GUT) / 2
      view(WX, WY, w, WH, 1, code, 'HERO', :nts)
      view(WX + w + GUT, WY, w, WH, 2, code, 'ISO', :nts)
    end

    def page_legend(_code)
      w = (WW - GUT) / 2; x2 = WX + w + GUT
      label('SHEET INDEX', WX, WY, @l_sheet)
      y = WY + 0.22
      line(WX, y, WX + w, y, @l_sheet, w: 1.0)
      PAGES.each_with_index do |(name, code, _s, _k), i|
        text("#{i + 1} / #{PAGES.size}", WX, y + 0.09, @l_sheet, size: 9, font: MONO)
        text(code, WX + 0.7, y + 0.09, @l_sheet, size: 9, font: MONO, c: INK2)
        text(name, WX + 1.5, y + 0.09, @l_sheet, size: 9)
        text('<Revision>', WX + w, y + 0.09, @l_sheet, size: 9, font: MONO, c: INK2, align: :right)
        y += 0.30
        line(WX, y, WX + w, y, @l_sheet, w: 0.5, c: ROWLINE)
      end
      y += 0.35
      label('LEGEND', WX, y, @l_sheet)
      y += 0.22
      line(WX, y, WX + w, y, @l_sheet, w: 1.0)
      rect(WX, y + 0.12, w, WY + WH - y - 0.12, @l_views, fill: FILL)
      text("SYMBOLS \u00B7 LINE TYPES \u00B7 HATCHES", WX + w / 2, y + (WY + WH - y) / 2, @l_views, size: 7, font: MONO, c: MINOR, align: :center)
      label('GENERAL NOTES', x2, WY, @l_sheet)
      line(x2, WY + 0.22, x2 + w, WY + 0.22, @l_sheet, w: 1.0)
      notes = [
        'All dimensions in millimetres.',
        "Sizes are the article's, not the finished opening.",
        'Do not scale drawings - figured dimensions govern. Verify all dimensions on site prior to ordering.',
        'Report any discrepancies to the designer before fabrication.'
      ]
      ny = WY + 0.36
      notes.each_with_index do |n, i|
        text("#{i + 1}.", x2, ny, @l_sheet, size: 9, font: MONO)
        box_text(n, x2 + 0.32, ny, w - 0.32, 0.45, @l_sheet, size: 9)
        ny += 0.48
      end
    end

    def page_schedule(_code)
      k = WW / SCHEDULE_COLS.sum { |_, cw| cw }
      xs = []; x = WX
      SCHEDULE_COLS.each { |_, cw| xs << x; x += cw * k }
      y = WY
      SCHEDULE_COLS.each_with_index { |(h, _), i| text(h, xs[i] + 0.04, y + 0.02, @l_sheet, size: 7.5, font: MONO, c: HEAD) }
      y += 0.24
      line(WX, y, WX + WW, y, @l_sheet, w: 1.0)
      rows = ((WY + WH - 0.45 - y) / SCHEDULE_ROW_H).floor
      rows.times do |r|
        text(format('%02d', r + 1), xs[0] + 0.04, y + 0.08, @l_sheet, size: 9, font: MONO, c: LABEL)
        y += SCHEDULE_ROW_H
        line(WX, y, WX + WW, y, @l_sheet, w: 0.5, c: ROWLINE)
      end
      @log << "schedule: #{rows} rows of #{SCHEDULE_ROW_H} in"
      text("All dimensions in mm: W = width, H = height, D = depth. Sizes are the article's, not the finished opening.",
           WX, WY + WH - 0.25, @l_sheet, size: 9, c: INK2)
    end

    # ---------------------------------------------------------------- cover (spec 5, designer cover moved in 1/4)
    def cover(placeholder: true)
      l = @l_sheet
      x0 = 0.965; x1 = 16.229
      text('<Issue>', x0, 0.80, l, size: 9, font: MONO, c: LABEL)
      text('<ProjectName>', x0, 0.98, l, size: 60, font: SANS_MED)
      text("<Issue> \u00B7 Rev <Revision>", x1, 1.12, l, size: 20, font: SANS_MED, c: ACCENT, align: :right)
      rect(x0, 2.20, x1 - x0, 6.65, @l_views, fill: FILL) if placeholder
      text("SKETCHUP VIEWPORT — HERO", (x0 + x1) / 2, 5.45, @l_views, size: 7, font: MONO, c: MINOR, align: :center) if placeholder
      by = 9.10
      line(FX0, by, FX1, by, l, w: 1.5)
      k = (FX1 - FX0) / COVER_COLS.sum
      xs = []; x = FX0
      COVER_COLS.each { |w| xs << x; x += w * k }
      pad = 0.14; ty = by + 0.14
      # 1 logo + company
      logo(xs[0] + pad + 0.30, ty + 0.40, 0.60, l)
      text('<CompanyName>', xs[0] + pad + 0.72, ty + 0.02, l, size: 8.5, bold: true)
      text('<CompanyAddress>', xs[0] + pad + 0.72, ty + 0.20, l, size: 7.5, c: INK2)
      # 2 team
      label('TEAM', xs[1] + pad, ty, l)
      text("Designer: <Designer>\nDrafter: <Drafter>\nChecked by: <CheckedBy>\nProject Number: <ProjectNumber>", xs[1] + pad, ty + 0.18, l, size: 8)
      # 3 project address
      label('PROJECT ADDRESS', xs[2] + pad, ty, l)
      text('<ProjectAddress>', xs[2] + pad, ty + 0.18, l, size: 8)
      # 4 status
      label('STATUS', xs[3] + pad, ty, l)
      text("<Status>\nIssue: <Issue>\nRevision: <Revision>\nDate: <IssueDate>", xs[3] + pad, ty + 0.18, l, size: 8)
      # 5 approval
      label('APPROVAL', xs[4] + pad, ty, l)
      box_text(APPROVAL_TEXT, xs[4] + pad, ty + 0.18, xs[5] - xs[4] - 2 * pad, 1.0, l, size: 8.5)
      # 6 client
      label('CLIENT', xs[5] + pad, ty, l)
      text('Client Name: <ClientName>', xs[5] + pad, ty + 0.18, l, size: 8)
      text('Client Signature:', xs[5] + pad, ty + 0.55, l, size: 8)
      line(xs[5] + pad + 1.0, ty + 0.68, FX1 - pad, ty + 0.68, l, w: 0.75)
      text('Date:', xs[5] + pad, ty + 0.85, l, size: 8)
      line(xs[5] + pad + 1.0, ty + 0.98, FX1 - pad, ty + 0.98, l, w: 0.75)
      COVER_COLS.each_index { |i| line(xs[i], by + 0.10, xs[i], FY1 - 0.10, l, w: 0.5, c: MINOR) if i.positive? }
    end
  end
end

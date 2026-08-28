# frozen_string_literal: true
#
# UCON Cabinet Engine — core/90_palette.rb
#
# Floating tool palette. Lives in core, so unlike the Extensions menu it is
# fully reload-safe: new buttons appear after Reload core, no SketchUp restart
# ever needed. The menu stays as a cold entry point; day to day, this palette
# is the front door.

module UCON
  module CabinetEngine
    module Palette
      module_function

      def show
        @dialog&.close rescue nil
        # RESIZABLE, and tall enough for its own content. It was fixed at
        # 240x360 and not resizable, which was fine until the palette grew a
        # row: the buttons fell off the bottom and there was no way to get them
        # back. A window that cannot be resized has to be right forever, and
        # nothing here is finished enough for that.
        #
        # The preferences_key is bumped with the size. SketchUp remembers the
        # last geometry PER KEY, so a stale 240x360 would be restored over any
        # new default and the fix would look like it had not worked.
        @dialog = UI::HtmlDialog.new(
          dialog_title: 'UCON Cabinet Engine', preferences_key: 'UCONPalette2',
          style: UI::HtmlDialog::STYLE_UTILITY,
          width: 260, height: 470,
          min_width: 230, min_height: 260,
          resizable: true
        )
        @dialog.set_html(html)
        @dialog.add_action_callback('build_by_code') { |_| show_picker }
        @dialog.add_action_callback('panel')  { |_| Panel.show }
        # Named export_order, not export: `export` is a reserved word in
        # JavaScript, and sketchup.export() is the kind of thing that works
        # until a browser engine decides it should not.
        @dialog.add_action_callback('export_order') { |_| ExportRun.run }
        # B6. The span between two cabinets where a freestanding machine stands.
        # The list comes from the appliance module when it is installed, because
        # nobody should have to type a model number the other tree already
        # holds; with no module there is nothing to offer and the button says so
        # rather than opening an empty box.
        # THE WORKTOP. Everything about it is measured except the thickness,
        # which no model can be measured for - core/08_project.rb. If it has not
        # been stated, ask once here rather than defaulting: a slab drawn at a
        # number nobody chose is a wrong elevation that looks like a right one.
        @dialog.add_action_callback('worktop') { |_| build_worktop_from_dialog }
        @dialog.add_action_callback('reserve_run_gap') do |_|
          begin
            models = ApplianceCheck.run_gap_models
            if models.empty?
              why = ApplianceCheck.run_gap_reason ||
                    'it knows no machine that stands in a run'
              UI.messagebox("Nothing to reserve.\n\n#{why.to_s.capitalize}.\n\n" \
                            'The width of a run gap is the appliance maker\'s number, ' \
                            'and this extension does not hold it.')
            else
              su = Sketchup.active_model
              # The worktop is a PROJECT number: no model here draws one, so it
              # cannot be measured, and it is not the same for two kitchens. It
              # is asked once and kept on the model - core/08_project.rb.
              stated = Project.worktop_t_mm(su)
              answer = UI.inputbox(
                ['Machine standing in the gap', 'Worktop thickness, mm — stated, nothing draws it'],
                [models.first, stated ? stated.round.to_s : ''],
                [models.join('|'), ''], 'Reserve a run gap'
              )
              if answer
                Project.worktop_t_mm!(answer[1], su)
                Generator.build_run_gap(answer[0], su)
              end
            end
          rescue StandardError => e
            UI.messagebox("Nothing was reserved.\n\n#{e.message}")
          end
        end
        @dialog.add_action_callback('reserve_wall') do |_|
          begin
            models = ApplianceCheck.wall_reservation_models
            if models.empty?
              why = ApplianceCheck.wall_reservation_reason ||
                    'it knows no machine that hangs on a wall'
              UI.messagebox("Nothing to reserve.\n\n#{why.to_s.capitalize}.\n\n" \
                            'The envelope of a hood and the height it hangs at are the ' \
                            'appliance maker\'s numbers, and this extension does not hold them.')
            else
              su = Sketchup.active_model
              # THE RANGE IS OFFERED AND NOT PRE-ANSWERED. Wolf printed p.144
              # gives 762 to 914 from the bottom of the hood to the countertop,
              # and the field opens EMPTY on purpose: a prefilled 762 is a
              # default wearing a question's clothes, and 152 mm of decision
              # would then be made by whoever pressed OK without reading.
              answer = UI.inputbox(
                ['Machine hanging on the wall',
                 'Bottom above the countertop, mm — 762 to 914, printed as a range'],
                [models.first, ''],
                [models.join('|'), ''], 'Reserve a wall volume'
              )
              if answer
                if answer[1].to_s.strip.empty?
                  UI.messagebox("Nothing was reserved.\n\n" \
                                'Wolf printed p.144 gives the mounting height as a RANGE, ' \
                                '762 to 914 above the countertop. A range is a decision, so ' \
                                'nothing here chooses it for you.')
                else
                  Generator.build_wall_reservation(answer[0], su,
                                                   bottom_above_top_mm: answer[1].to_f)
                end
              end
            end
          rescue StandardError => e
            UI.messagebox("Nothing was reserved.\n\n#{e.message}")
          end
        end
        # The tool lives in core, so it arrives with a Reload core - no restart.
        @dialog.add_action_callback('place') do |_|
          begin
            PlaceTool.start
          rescue StandardError => e
            UI.messagebox("Placement failed:\n\n#{e.message}")
          end
        end
        @dialog.add_action_callback('symbols') do |_, mode|
          Symbols.show_mode(Sketchup.active_model, mode.to_sym)
        end
        @dialog.add_action_callback('thin') do |_|
          Symbols.toggle_thin_lines(Sketchup.active_model)
        end
        # THE PAIR. `Reload core` kills the bridge's timer, so the button that
        # puts it back sits beside the button that breaks it. Never arms - see
        # core/95_dev_bridge.rb for why that is not an oversight.
        @dialog.add_action_callback('reload_bridge') do |_|
          begin
            DevBridge.reload!
            # REPORTED FROM THE TIMER, NOT FROM THE RETURN VALUE. `load` returning
            # true says the file was read, not that a timer is ticking.
            # Learned rule 13: a record of an outside action is only true if
            # something checks it.
            #
            # AND IT IS NOT A MESSAGEBOX. A modal blocks SketchUp's timer loop,
            # and the thing being reported IS a timer - the first press left the
            # queued probe unrun for four minutes behind a dialog that said the
            # bridge was on. Status bar and console; see core/95_dev_bridge.rb.
            DevBridge.announce
          rescue StandardError => e
            UI.messagebox("The probe bridge was not reloaded.\n\n#{e.message}")
          end
        end
        @dialog.add_action_callback('reload') do |_|
          begin
            files = CabinetEngine.load_core
            @dialog.execute_script("setVersion(#{CabinetEngine.version_line.inspect})")
            UI.messagebox("Core reloaded — #{CabinetEngine.version_line}\n#{files.length} file(s).")
          rescue StandardError => e
            UI.messagebox("Reload failed:\n\n#{e.message}")
          end
        end
        @dialog.show
        @dialog.execute_script("setVersion(#{CabinetEngine.version_line.inspect})")
        nil
      end

      NOT_DECIDED = 'not decided yet'

      # WHICH MACHINE STANDS BEHIND THIS FRONT, and asked ONLY where the answer
      # changes what gets drawn. A front that states a housing leaves a
      # remainder above it in a 2200 run - 66 mm behind a Designer column, 73
      # behind a Classic - and that height is the MACHINE'S, not ours. Without a
      # name there is nothing to draw, so the question is worth one dialog.
      # Every other code is built exactly as before and is never asked.
      #
      # "not decided yet" is a real answer and it is the DEFAULT, deliberately:
      # a run is usually drawn before the appliance is chosen, and a forced pick
      # would put a number on the sheet nobody has agreed to. Cancel means the
      # same thing. The niche note still says what is missing and why.
      def appliance_for(code)
        unit  = Registry.lookup(code)
        niche = unit['appliance_niche']
        return nil unless unit['object_class'] == 'appliance_front' && niche && niche['top_mm']

        models = ApplianceCheck.housing_models
        return nil if models.empty?

        answer = UI.inputbox(
          ['Machine standing in this housing'], [NOT_DECIDED],
          [([NOT_DECIDED] + models).join('|')],
          'Which machine? — it decides the filler above it'
        )
        return nil unless answer && answer[0] != NOT_DECIDED

        answer[0]
      rescue StandardError
        # An unknown code, an absent appliance module, a dialog that could not
        # open: none of them is a reason not to build the front. The remainder
        # simply goes undrawn, which is what happened before this existed.
        nil
      end

      def show_picker
        require 'json'
        @picker&.close rescue nil
        @picker = UI::HtmlDialog.new(
          dialog_title: 'UCON — Build unit', preferences_key: 'UCONPicker',
          style: UI::HtmlDialog::STYLE_UTILITY, width: 360, height: 470,
          resizable: true
        )
        @picker.set_html(picker_html(Registry.catalog, Registry.gaps, @picker_inches))
        # The switch survives a reopen. Nothing about it reaches the model or
        # an order - it is a way of READING sizes, not a property of them.
        @picker.add_action_callback('units') do |_, on|
          @picker_inches = (on == 'on')
        end
        # The second argument is the ORDERED width, empty for everything the
        # catalog dimensions itself. Empty becomes nil here and nowhere else,
        # so Registry.with_ordered_width sees one shape however the dialog
        # spells "nothing typed".
        # THREE ARGUMENTS SINCE 0.91.0, and the third exists because an article
        # can state neither dimension. A panel out of Linear Elements p.215-220
        # is priced by the square metre and cut to size: the picker asks for both
        # numbers or the build is refused for a height nothing could type.
        @picker.add_action_callback('build') do |_, code, width, height|
          begin
            Generator.build(
              code,
              width_mm: (width.to_s.strip.empty? ? nil : width.to_s.strip),
              height_mm: (height.to_s.strip.empty? ? nil : height.to_s.strip),
              appliance: appliance_for(code)
            )
          rescue StandardError => e
            UI.messagebox("Build failed:\n\n#{e.message}")
          end
        end
        @picker.show
      end

      # ---- THE WORKTOP BUTTON, rewritten 2026-08-28 ------------------------
      #
      # It used to ask one number - the thickness - because there was no article
      # to ask about. Now there is, and the thickness is the ARTICLE'S, so the
      # question changed shape rather than growing a field.
      #
      # NOTHING IS PRE-CHOSEN. Both dropdowns open on "— choose —" and building
      # refuses if either comes back that way. A SketchUp inputbox selects its
      # first entry, so any real value put first is a value somebody gets by
      # pressing OK without reading - and both of these are decisions with a
      # price behind them. The depth band decides an overhang and the finish
      # group decides the money; neither is this dialog's to guess.
      #
      # THE ARTICLE IS REMEMBERED AND THE BAND IS NOT. A kitchen has one top
      # material and several depths - 650 over the 620 runs, 380 for the 350
      # counter - so core/08_project.rb keeps the code, the group and the finish
      # and this asks the band every time.
      def build_worktop_from_dialog
        su = Sketchup.active_model
        tops = Registry.catalog.select { |c| c['class'] == 'worktop' }
        if tops.empty?
          UI.messagebox("No worktop article is held.\n\n" \
                        'The tops chapter has to be extracted before one can be ordered.')
          return
        end

        bands = (tops.first['depth_bands_mm'] || []).map { |b| b.to_i.to_s }
        groups = (Registry.lookup(tops.first['code'])['points_per_lm_by_group_and_band'] || {})
                 .keys.sort
        # Double-quoted: in single quotes \u2014 is a backslash and a u, and the
        # dropdown would read literally "\u2014 choose \u2014".
        chose = "\u2014 choose \u2014"

        codes = tops.map { |c| "#{c['code']} - #{c['height_mm'].to_i} mm" }
        prev  = Project.worktop_code(su)
        answer = UI.inputbox(
          ['Article (the thickness is the code\'s)',
           'Depth band, mm - CHOSEN, not measured',
           'Finish group - not in the code, and it decides the price',
           'Finish name - an order field, may be left blank'],
          [codes.find { |c| prev && c.start_with?(prev) } || codes.first,
           chose,
           Project.worktop_finish_group(su) || chose,
           Project.worktop_finish(su).to_s],
          [codes.join('|'), ([chose] + bands).join('|'),
           ([chose] + groups).join('|'), ''],
          'UCON - worktop'
        )
        return unless answer

        code  = answer[0].to_s.split(' - ').first
        band  = answer[1]
        group = answer[2]
        if band == chose || group == chose
          UI.messagebox("Nothing was drawn.\n\n" \
                        'The depth band and the finish group are both choices with a price ' \
                        "behind them - the band decides how far the top stands past the door " \
                        'face, the group decides what it costs - and neither is this dialog\'s ' \
                        'to guess.')
          return
        end

        Project.worktop_article!(code, group, answer[3], su)
        # The stated thickness follows the article rather than contradicting it,
        # and only where nothing has stated one yet: build_worktop refuses on a
        # disagreement, and this must not resolve that refusal behind its back.
        t = Registry.lookup(code)['height_mm'].to_f
        Project.worktop_t_mm!(t, su) if Project.worktop_t_mm(su).nil?

        Generator.build_worktop(su, code: code, depth_band_mm: band,
                                    finish_group: group, finish: answer[3])
      rescue StandardError => e
        UI.messagebox("Worktop not drawn:\n\n#{e.message}")
      end

      # 'filler' is OUR class, not one of the catalog's three element classes.
      # The book prints closing strips and fillers as their own chapter after
      # every collection, and their rows are base, wall and tall at once - see
      # catalog_map, the section note. The FAMILY still decides how each one
      # meets the room.
      # 'end_panel' is OURS for the same reason and one step further: a filler
      # is at least a unit-shaped thing that fills a run, while an end panel is
      # a board beside one. It spans base, wall and tall heights in a single
      # printed table, so it belongs to no element class the book has.
      # AND A CLASS THAT ONLY THE MAP HOLDS STILL NEEDS ONE, 2026-08-26. The
      # picker draws a heading for every class in the CATALOG MAP as well as
      # for every class in the registry - a chapter we have not extracted shows
      # as an inert CATALOG ONLY row, which is the whole point of the map. Three
      # of them were rendering as bare keys: 'glass' since the glass wall units
      # were mapped this morning, 'open_unit' and 'side_panel' since the panel
      # chapter was mapped this evening. Andriy saw it in the dialog. The check
      # meant to prevent exactly this looked only at the registry - a check can
      # only fail on what it looks at, and it was looking at half.
      CLASS_LABELS = {
        'base' => 'Base units', 'wall' => 'Wall units', 'tall' => 'Tall units',
        'filler' => 'Fillers and closing strips',
        'end_panel' => 'End panels',
        'glass' => 'Glass display units',
        'open_unit' => 'Open units',
        'side_panel' => 'Finishing side panels',
        # 2026-08-27, with the first Linear Elements section. NOT 'end_panel':
        # these are boards sold BY THE SQUARE METRE and cut to size, and a
        # person looking for one is not looking for the article that carries a
        # 45-degree edge into a door. Two classes because they are two articles.
        'panel_sheet' => 'Panels cut to size (per m²)',
        'shelf' => 'Shelves',
        # 2026-08-28, the first worktop this engine has ever held. NOT a panel
        # and not a shelf: a top is priced by the LINEAR METRE across a depth
        # band and a finish group, which is a different order line from anything
        # above it.
        'worktop' => 'Worktops'
      }.freeze

      # Display labels only — UCON's own vocabulary for the picker. The
      # registry keeps the catalog's wording; this map never travels into data
      # or into an order. An unmapped type falls back to its key.
      TYPE_LABELS = {
        # THE LABELS ARE THE PRINTED PAGE HEADINGS AND NOTHING MORE, corrected
        # 2026-08-26. They first read as though the person were choosing between
        # two articles for the same end. They are not: the two pages of a
        # collection price DISJOINT depth groups, so the depth picks the code and
        # this level picks nothing. Labelling it as a choice invited a decision
        # that does not exist. What the second page's banner MEANS is Elda Q22.
        'end_panel_45'            => 'End panel — p. “with 45° vertical edge”',
        'end_panel_45_opposite_hinge' =>
          'End panel — p. “drawers / push-up / hinges opposite”',
        'filler_front'            => 'Filler, front only',
        'filler_base_unit'        => 'Base unit filler',
        'filler_wall_unit'        => 'Wall unit filler',
        'base_door'               => 'Door units',
        'base_doors'              => 'Two-door units',
        'base_drawers_jumbo'      => 'Drawer units (2 + jumbo)',
        'base_jumbo_drawers'      => 'Jumbo drawer units (2 jumbo)',
        'base_drawer_jumbo'       => 'Drawer + jumbo units',
        'base_pull_out_door'      => 'Pull-out door units',
        'base_laundry_basket'     => 'Laundry basket units',
        'base_waste_pone'         => 'Trash & Recycle (P-One)',
        'base_waste_xl'           => 'Trash & Recycle (XL / Envi Space)',
        'sink_base_door'          => 'Sink units, one door',
        'sink_base_doors'         => 'Sink units, two doors',
        'sink_base_jumbo_drawer'  => 'Sink units, jumbo drawer',
        'sink_base_jumbo_drawers' => 'Sink units, two jumbo drawers',
        'appliance_dishwasher_door' => 'Dishwasher door',
        'base_corner'             => 'Corner units',
        'wall_top_hung_door'      => 'Top-hung door units',
        'wall_bottom_hung_door'   => 'Bottom-hung door units',
        'wall_compound_2_top_hung' => 'Compound, 2 modules, top-hung',
        'wall_compound_2_push_up'  => 'Compound, 2 modules, push-up',
        'wall_compound_3_top_hung' => 'Compound, 3 modules, top-hung',
        'wall_compound_3_push_up'  => 'Compound, 3 compartments, push-up',
        # The page heading again, and the thickness with it, because thickness
        # is the ONLY thing that tells the three ceramic-top pages apart -
        # printed p.104 (1,2), p.107 (2,2) and p.110 (4 and 6) carry identical
        # headings. Only p.110 is held.
        'ceramic_top'             => 'Ceramic tops — 4 / 6 cm'
      }.freeze

      # JSON that is safe to paste inside an inline <script>: a literal
      # "</script>" anywhere in the data (a description, a section title)
      # would otherwise close the tag and kill the dialog.
      def script_json(obj)
        require 'json'
        obj.to_json.gsub('</', '<\/')
      end

      # Cascading picker: class > section > type > depth x width grid.
      # The tree is derived entirely from the registry catalog, so a newly
      # extracted section file appears here by itself. Levels with a single
      # option auto-advance; the breadcrumb steps back. Search jumps straight
      # to a code from any level.
      #
      # Gaps (Registry.gaps) are rendered as inert grey rows next to the real
      # ones, so the picker shows the whole printed catalog and is honest about
      # what is missing. They come from the registry map — nothing about them
      # is hardcoded here.
      def picker_html(catalog, gaps = [], inches = false)
        require 'json'
        <<~HTML
          <!DOCTYPE html><html><head><meta charset="utf-8"><style>
            body{font:13px -apple-system,Helvetica,Arial;margin:0;padding:12px;background:#f5f5f4;color:#222}
            #crumb{font-size:11px;color:#666;margin-bottom:8px;min-height:14px}
            #crumb a{color:#2563eb;cursor:pointer;text-decoration:none}
            .srow{display:flex;gap:6px;margin-bottom:8px}
            #search{flex:1;min-width:0;box-sizing:border-box;padding:5px 8px;
                    border:1px solid #ccc;border-radius:6px;font-size:12px}
            #units{flex:none;width:34px;padding:5px 0;border:1px solid #ccc;border-radius:6px;
                   background:#fff;color:#555;font-size:12px;cursor:pointer;line-height:1}
            #units:hover{background:#eef2ff;border-color:#93b4f5}
            #units.on{background:#2563eb;color:#fff;border-color:#2563eb}
            .item{display:block;width:100%;text-align:left;margin:0 0 6px;padding:8px 10px;
                  border:1px solid #d4d4d4;border-radius:6px;background:#fff;font-size:13px;cursor:pointer}
            .item:hover{background:#eef2ff;border-color:#93b4f5}
            .item small{color:#888}
            .ghost{display:block;width:100%;text-align:left;margin:0 0 6px;padding:8px 10px;
                   border:1px dashed #d4d4d4;border-radius:6px;background:#fafaf9;color:#9a9a9a;
                   font-size:13px;cursor:default}
            .ghost small{color:#b0b0b0}
            .ghost .page{margin:6px 0 0 10px;padding-left:8px;border-left:2px solid #e6e6e6}
            /* Each line is its own flex row so a badge stays pinned right and
               a long title wraps beside it instead of flowing underneath. */
            .ghost .row{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
            .ghost .row span{min-width:0}
            .tag{flex:none;white-space:nowrap;font-size:10px;letter-spacing:.04em;
                 text-transform:uppercase;color:#9a9a9a;border:1px solid #e0e0e0;
                 border-radius:4px;padding:1px 5px;background:#fff}
            .drow{display:flex;align-items:center;gap:4px;margin-bottom:6px}
            .dlab{width:44px;color:#555;font-size:12px}
            .wbtn{flex:1;padding:6px 0;border:1px solid #d4d4d4;border-radius:5px;background:#fff;
                  font-size:11px;cursor:pointer;text-align:center}
            /* THE HEIGHT GRID STANDS UP, 2026-08-26. Laid out as rows it ran
               off the right edge: the end-panel chapter prints sixteen heights
               in one depth group and a flex row cannot wrap without lying about
               which depth a button belongs to. One COLUMN per depth, heights
               down it, so the whole article table is on screen at once. */
            .dcols{display:flex;gap:8px;align-items:flex-start;margin-bottom:6px}
            .dcol{flex:1;min-width:0;display:flex;flex-direction:column;gap:4px}
            .dcol .wbtn{flex:0 0 auto}
            .dch{color:#555;font-size:12px;text-align:center;padding-bottom:2px}
            .wbtn:hover{background:#eef2ff}
            .wbtn.sel{background:#2563eb;color:#fff;border-color:#2563eb}
            .wbtn small{display:block;color:#8a8a8a;font-size:10px;line-height:1.2;margin-top:1px}
            .wbtn.sel small{color:rgba(255,255,255,.85)}
            #card{background:#fff;border:1px solid #ddd;border-radius:6px;padding:10px;margin:8px 0;
                  font-size:12px;line-height:1.5;display:none}
            #card b{font-size:13px} .src{color:#888;font-size:11px}
            #buildBtn{width:100%;padding:9px;border:0;border-radius:6px;background:#2563eb;color:#fff;
                      font-size:13px;cursor:pointer;display:none}
          </style></head><body>
            <div class="srow">
              <input id="search" placeholder="Search code or description…" oninput="doSearch()">
              <button id="units" onclick="toggleUnits()"
                      title="Also show sizes in inches">in</button>
            </div>
            <div id="crumb"></div>
            <div id="content"></div>
            <div id="card"></div>
            <button id="buildBtn" onclick="doBuild()">Build</button>
            <script>
              var CAT = #{script_json(catalog)};
              var GAPS = #{script_json(gaps)};
              var INITIAL_INCH = #{inches ? 'true' : 'false'};
              var CLS = #{script_json(CLASS_LABELS)};
              var TYP = #{script_json(TYPE_LABELS)};
              var st = { cls:null, sec:null, typ:null, code:null };

              function uniq(a){ return a.filter(function(v,i){ return a.indexOf(v)===i; }); }

              // ---- inches -------------------------------------------------
              // Millimetres are the truth: the catalog is metric, INCLUDING
              // its US sizes, which it prints as centimetres (W. 76.2 = 30").
              // Inches here are a way of READING a size, never of storing one.
              //
              // A NOMINAL size is one the catalog itself built to an inch
              // figure. It is exact by definition and carries no tilde. Its
              // value is READ FROM THE ROW, never computed - 610 mm is the
              // catalog's rounding of 24" (609,6), so converting it back gives
              // 24 1/16" and that is not what anyone ordered. Same rule as the
              // width index: a lookup, never arithmetic.
              //
              // Everything else is a CONVERSION and says so with a tilde,
              // because 600 mm is NOT 24" - it is a centimetre short of it,
              // and a bare "23 5/8" would read as a size somebody chose.
              var INCH = INITIAL_INCH;
              function frac16(v){
                var whole = Math.floor(v);
                var n = Math.round((v - whole) * 16);
                if(n === 16){ whole += 1; n = 0; }
                if(n === 0) return String(whole);
                var d = 16;
                while(n % 2 === 0){ n = n / 2; d = d / 2; }
                return whole + ' ' + n + '/' + d;
              }
              function inchLabel(mm, nominal){
                if(nominal !== undefined && nominal !== null && nominal !== '')
                  return String(nominal) + '\u2033';
                return '\u2248' + frac16(mm / 25.4) + '\u2033';
              }
              function toggleUnits(){
                INCH = !INCH;
                document.getElementById('units').className = INCH ? 'on' : '';
                if(window.sketchup && sketchup.units) sketchup.units(INCH ? 'on' : 'off');
                var q = document.getElementById('search').value.trim();
                if(q.length >= 2){ doSearch(); } else { render(); }
              }
              // The class level is the one place the picker cannot be derived
              // from the registry alone. A whole element class we have not
              // started - the wall chapter, the tall chapter - exists only in
              // the catalog map, and if the class list came from CAT alone the
              // picker would auto-advance straight past it and its grey rows
              // would be unreachable. So: classes we HOLD first, then classes
              // the map names and we hold nothing in.
              function classes(){
                var have = uniq(CAT.map(function(c){return c['class'];}));
                return have.concat(uniq(GAPS.map(function(g){return g['class'];}))
                  .filter(function(v){ return v && have.indexOf(v) < 0; }));
              }
              function holds(cls){
                return CAT.some(function(c){ return c['class'] === cls; });
              }
              function rows(){ return CAT.filter(function(c){
                return (!st.cls || c['class']===st.cls) && (!st.sec || c.section===st.sec) &&
                       (!st.typ || c.type_key===st.typ); }); }

              function setLevel(cls, sec, typ, code){
                st = { cls:cls, sec:sec, typ:typ, code:code || null };
                autoAdvance(); render();
              }
              function autoAdvance(){
                if(!st.cls){ var cs = classes();
                             if(cs.length===1) st.cls = cs[0]; else return; }
                if(!st.sec){ var ss = uniq(rows().map(function(c){return c.section;}));
                             if(ss.length===1) st.sec = ss[0]; else return; }
                if(!st.typ){ var ts = uniq(rows().map(function(c){return c.type_key;}));
                             if(ts.length===1) st.typ = ts[0]; }
              }

              function crumb(){
                var parts = [];
                parts.push(st.cls ? link(CLS[st.cls]||st.cls, 'null,null,null') : '');
                if(st.sec) parts.push(link(st.sec, JSON.stringify(st.cls)+',null,null'));
                if(st.typ) parts.push(link(TYP[st.typ]||st.typ,
                  JSON.stringify(st.cls)+','+JSON.stringify(st.sec)+',null'));
                document.getElementById('crumb').innerHTML =
                  parts.filter(Boolean).join(' › ') || 'Catalog';
              }
              function link(txt, args){ return '<a onclick="setLevel('+args+')">'+txt+'</a>'; }

              function render(){
                crumb();
                var el = document.getElementById('content'); el.innerHTML='';
                document.getElementById('card').style.display='none';
                document.getElementById('buildBtn').style.display='none';
                if(!st.cls){ list(classes(),
                  function(v){return CLS[v]||v;}, function(v){ setLevel(v,null,null); },
                  function(v){ return holds(v) ? null : 'catalog only'; }); return; }
                if(!st.sec){ list(uniq(rows().map(function(c){return c.section;})),
                  function(v){return v;}, function(v){ setLevel(st.cls,v,null); });
                  ghosts(el, function(g){ return g.level==='section' && g['class']===st.cls; },
                         function(g){ return g.section; });
                  return; }
                if(!st.typ){
                  var ts = uniq(rows().map(function(c){return c.type_key;}));
                  ts.forEach(function(t){
                    var n = CAT.filter(function(c){return c.section===st.sec && c.type_key===t;}).length;
                    var d = CAT.find(function(c){return c.type_key===t;});
                    // A type whose geometry is not implemented is listed but
                    // never clickable: the codes must be findable, and a build
                    // that cannot be honest must not be offered.
                    if(d.buildable === false){
                      var g = document.createElement('div'); g.className='ghost';
                      g.innerHTML = row((TYP[t]||t) + ' <small>· ' + n + ' codes</small>', 'not buildable') +
                        '<small>' + esc(d.description) + '</small>' +
                        (d.not_buildable_reason ? '<br><small>' + esc(d.not_buildable_reason) + '</small>' : '') +
                        '<div class="page">' + CAT.filter(function(c){
                          return c.section===st.sec && c.type_key===t; })
                          .map(function(c){ return '<small>' + esc(c.code) +
                            (c.corner_geometry ? ' — ' + esc(c.corner_geometry) + ' mm' : '') +
                            '</small>'; }).join('<br>') + '</div>';
                      el.appendChild(g);
                      return;
                    }
                    var b = document.createElement('button'); b.className='item';
                    b.innerHTML = (TYP[t]||t) + ' <small>· ' + n + ' codes</small><br><small>' +
                                  d.description + '</small>';
                    b.onclick = function(){ setLevel(st.cls, st.sec, t); };
                    el.appendChild(b);
                  });
                  ghosts(el, function(g){ return g.level==='type' && g.section===st.sec; },
                         function(g){ return g.printed; });
                  return;
                }
                sizeGrid(el);
              }
              // Inert rows for catalog entries we have not extracted. Never
              // clickable: there is nothing behind them yet, and pretending
              // otherwise would be worse than the gap itself.
              function esc(s){ return String(s==null?'':s)
                .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
              function badge(s){ return '<span class="tag">' + esc(String(s).replace(/_/g,' ')) + '</span>'; }
              // A type carries its own badge only when a decision was made about
              // that position — p.47 excludes the fridge housings but keeps the
              // dishwasher door. Reasons live in the tooltip so the row stays a
              // row and not a paragraph.
              function row(inner, status, tip){
                return '<div class="row"' + (tip ? ' title="' + esc(tip) + '"' : '') + '>' +
                       '<span>' + inner + '</span>' + (status ? badge(status) : '') + '</div>';
              }
              function typeLines(types, parentStatus){
                return (types||[]).map(function(t){
                  var own = t.status && t.status !== parentStatus;
                  return row('<small>' + esc(t.title) + '</small>', own ? t.status : null, t.note);
                }).join('');
              }
              function ghosts(el, keep, title){
                GAPS.filter(keep).forEach(function(g){
                  var d = document.createElement('div'); d.className='ghost';
                  var html = row(esc(title(g)) +
                    (g.level==='type' ? '' : ' <small>· ' + esc(g.printed) + '</small>'), g.status);
                  if(g.note) html += '<small>' + esc(g.note) + '</small>';
                  html += typeLines(g.types, g.status);
                  // Pages we have read, nested under their section — the index
                  // names a section once, so the picker shows it once.
                  (g.pages||[]).forEach(function(p){
                    html += '<div class="page">' + row('<small>' + esc(p.printed) + '</small>', p.status) +
                            (p.note ? '<small>' + esc(p.note) + '</small>' : '') +
                            typeLines(p.types, p.status) + '</div>';
                  });
                  d.innerHTML = html;
                  el.appendChild(d);
                });
              }
              // A class row stays a BUTTON even when we hold nothing in it:
              // it is navigation, not a catalog entry. What is inert is what
              // lies inside - the section rows are ghosts and stay ghosts. The
              // badge says plainly that there is nothing behind this door yet.
              function list(vals, lab, go, tag){
                var el = document.getElementById('content');
                vals.forEach(function(v){
                  var b = document.createElement('button'); b.className='item';
                  var t = tag ? tag(v) : null;
                  b.innerHTML = esc(lab(v)) + (t ? ' ' + badge(t) : '');
                  b.onclick = function(){ go(v); };
                  el.appendChild(b);
                });
              }
              // A corner type has no single width: it is dimensioned by the
              // node it occupies, and each size exists in two EXECUTIONS that
              // are different articles. So it gets a list, not a grid.
              function cornerList(el){
                var rs = rows();
                var sizes = uniq(rs.map(function(c){return c.corner_geometry;}));
                sizes.forEach(function(geom){
                  var lab = document.createElement('div');
                  lab.className = 'dlab'; lab.style.width='auto'; lab.style.margin='8px 0 4px';
                  var any = rs.find(function(c){return c.corner_geometry===geom;});
                  lab.textContent = geom.replace('x',' × ') + ' mm · door ' + any.door_width_mm +
                                    ' · carcass ' + any.carcass_length_mm + ' · d.' + (any.depth_mm/10);
                  el.appendChild(lab);
                  // ONE button per size, not one per execution. S and D are
                  // different articles, but which one this is follows from the
                  // wall it gets placed against - the placement tool swaps it
                  // and rewrites the code. Asking here would be asking a
                  // question whose answer is not yet knowable.
                  var mates = rs.filter(function(c){return c.corner_geometry===geom;})
                                .sort(function(a,b){return a.execution < b.execution ? -1 : 1;});
                  var pick = mates[0];
                  var row = document.createElement('div'); row.className='drow';
                  var b = document.createElement('button'); b.className='wbtn';
                  if(mates.some(function(c){return st.code===c.code;})) b.className += ' sel';
                  b.style.width = 'auto';
                  b.innerHTML = pick.code + '<br><small>the wall picks the hand</small>';
                  b.onclick = function(){ st.code = pick.code; render(); };
                  row.appendChild(b);
                  el.appendChild(row);
                });
                if(st.code) showCard(CAT.find(function(c){return c.code===st.code;}));
              }
              // THE BUTTON MUST CARRY WHAT VARIES. Rows are depths either way;
              // this grid puts the HEIGHT on the button instead of the width.
              //
              // Written for FILLERS, which have no width in their code: one
              // article covers 2,3 to 15 cm and the number is stated when it is
              // ordered (printed p.434). PB0151 and PD0151 are both d.35 and
              // differ only in height, so a width grid read as two identical
              // rows labelled 'd. 35'.
              //
              // END PANELS NEED IT FOR THE OPPOSITE REASON, 2026-08-26. A panel
              // HAS a width and it is 22 - the 2,2 cm thickness, the same on
              // every code in the chapter. Andriy opened the picker and got
              // four rows of nine buttons all reading 22. The width was not
              // missing, it was constant, and a constant on a button is a
              // button that says nothing. So the routing rule below is not
              // 'is it a filler' but 'does the width distinguish anything'.
              // THE W AND H WIDGETS, LIFTED OUT OF heightGrid 2026-08-27.
              // They were written inside it because only a filler ever reached
              // them; the sheet grid needs the same two rows and copying them
              // would have been two places to change one behaviour.
              function dimRows(el, c){
                if(!c.width_range_mm) return;
                var lo = c.width_range_mm[0], hi = c.width_range_mm[1];
                var wrap = document.createElement('div'); wrap.className='drow';
                var wlab = document.createElement('div'); wlab.className='dlab';
                wlab.textContent = 'W mm';
                wrap.appendChild(wlab);
                // PRESETS, then a box for anything else. 5 cm is not a round
                // number chosen for tidiness: printed p.11 asks for a closing
                // strip of AT LEAST 5 cm, so it is the size this article is
                // reached for most. A preset outside the range is not offered.
                //
                // AND THEY ARE A FILLER'S PRESETS, NOT EVERY ARTICLE'S, 2026-08-27.
                // A shelf covers 1 to 3000 and nobody reaches for a 5 cm one, so
                // three buttons offering it were three wrong answers taking up
                // the row. Andriy: "не нужны предустановленные опции, это для
                // филлеров". Keyed on the CLASS, because that is what the presets
                // were chosen for.
                ((c['class'] === 'filler') ? [50, 100, 150] : [])
                  .filter(function(mm){ return mm >= lo && mm <= hi; })
                  .forEach(function(mm){
                    var pb = document.createElement('button'); pb.className='wbtn';
                    pb.style.cssText = 'flex:0 0 auto;min-width:52px';
                    if(parseInt(st.w, 10) === mm) pb.className += ' sel';
                    pb.textContent = (mm/10) + ' cm';
                    pb.onclick = function(){ st.w = String(mm); render(); };
                    wrap.appendChild(pb);
                  });
                var inp = document.createElement('input');
                inp.type = 'number';
                inp.value = (st.w == null ? '' : st.w);
                inp.min = lo; inp.max = hi;
                inp.placeholder = lo + '\u2013' + hi;
                inp.style.cssText = 'flex:1;min-width:60px;padding:6px;font-size:11px;' +
                                    'border:1px solid #d4d4d4;border-radius:5px;text-align:center';
                // NO re-render on input - it would take the focus away between
                // two digits. Only the Build button and the hint are touched.
                // A PRESET may re-render, because the click has already ended.
                inp.oninput = function(){ st.w = inp.value; syncBuild(c); };
                wrap.appendChild(inp);
                el.appendChild(wrap);
                // AND A HEIGHT, WHEN THE ARTICLE STATES NONE. A filler has a
                // height from its family and only the width is asked. A sheet
                // out of Linear Elements p.215-220 has neither: it is priced by
                // the square metre and cut, and the page prints only the board
                // it comes off. No presets here - 88 is this kitchen's number,
                // not the article's, and a preset is a recommendation.
                if(c.height_range_mm){
                  var hlo = c.height_range_mm[0], hhi = c.height_range_mm[1];
                  var hrow = document.createElement('div'); hrow.className='drow';
                  var hlab = document.createElement('div'); hlab.className='dlab';
                  hlab.textContent = 'H mm';
                  hrow.appendChild(hlab);
                  var hinp = document.createElement('input');
                  hinp.type = 'number';
                  hinp.value = (st.h == null ? '' : st.h);
                  hinp.min = hlo; hinp.max = hhi;
                  hinp.placeholder = hlo + '\u2013' + hhi;
                  hinp.style.cssText = 'flex:1;min-width:60px;padding:6px;font-size:11px;' +
                                       'border:1px solid #d4d4d4;border-radius:5px;text-align:center';
                  hinp.oninput = function(){ st.h = hinp.value; syncBuild(c); };
                  hrow.appendChild(hinp);
                  el.appendChild(hrow);
                  var note = document.createElement('div');
                  note.className='src'; note.style.margin='4px 0 0';
                  note.textContent = 'per m\u00b2, minimum 0,5 m\u00b2 \u2014 ' +
                    'a board off a ' + (hhi/10) + ' cm sheet, cut to what you type';
                  el.appendChild(note);
                }
                var hint = document.createElement('div');
                hint.className='src'; hint.id='whint'; hint.style.margin='6px 0 0';
                el.appendChild(hint);
                showCard(c);
                syncBuild(c);
              }
              // THE SHEET GRID. Columns are THICKNESSES, because that is the one
              // dimension a sheet states and the page groups its blocks by. The
              // button carries the price group and the number of faced sides -
              // 'B / 2 sides' - with the code and the rate under it, because
              // those are the only things that tell one of these codes from
              // another. Points are shown here and nowhere else: they are
              // commercial data and never reach the object (Contract v2 1.2).
              function sheetGrid(el){
                var rs = rs_by_depth(rows());
                var cols = document.createElement('div'); cols.className='dcols';
                rs.depths.forEach(function(d){
                  var col = document.createElement('div'); col.className='dcol';
                  var head = document.createElement('div'); head.className='dch';
                  head.textContent = d ? String(d/10).replace('.', ',') + ' cm' : 'sheet';
                  col.appendChild(head);
                  rs.by[d].forEach(function(c){
                    var b = document.createElement('button'); b.className='wbtn';
                    if(st.code===c.code) b.className += ' sel';
                    var lab = (c.price_group ? c.price_group + ' \u00b7 ' : '') +
                              (c.faced_sides === 1 ? '1 side' : '2 sides');
                    b.innerHTML = esc(lab) + '<small>' + esc(c.code) +
                                  (c.points_per_m2 ? ' \u00b7 ' + c.points_per_m2 + ' pt/m\u00b2' : '') +
                                  '</small>';
                    b.onclick = function(){ st.w = null; st.h = null; st.code = c.code; render(); };
                    col.appendChild(b);
                  });
                  cols.appendChild(col);
                });
                el.appendChild(cols);
                if(!st.code) return;
                var c = CAT.find(function(x){ return x.code===st.code; });
                if(!c) return;
                showCard(c);
                syncBuild(c);
                dimRows(el, c);
              }
              function heightGrid(el){
                var rs = rs_by_depth(rows());
                var cols = document.createElement('div'); cols.className='dcols';
                rs.depths.forEach(function(d){
                  var col = document.createElement('div'); col.className='dcol';
                  var head = document.createElement('div'); head.className='dch';
                  head.textContent = d ? 'd. ' + (d/10) : 'front';
                  col.appendChild(head);
                  rs.by[d].forEach(function(c){
                    var b = document.createElement('button'); b.className='wbtn';
                    if(st.code===c.code) b.className += ' sel';
                    b.innerHTML = 'H. ' + (c.height_mm/10) +
                                  '<small>' + esc(c.code) + '</small>';
                    b.onclick = function(){ st.w = null; st.code = c.code; render(); };
                    col.appendChild(b);
                  });
                  cols.appendChild(col);
                });
                el.appendChild(cols);
                if(!st.code) return;
                var c = CAT.find(function(x){ return x.code===st.code; });
                if(!c) return;
                // THE CARD AND THE BUILD BUTTON COME FIRST, and until 2026-08-26
                // they came LAST - after a `return` that only a filler ever got
                // past. This function was written for fillers, where the width
                // widget below always runs and ends by calling both. An end
                // panel states no width range, so it took the early return and
                // reached neither: Andriy picked B90030 and had nothing to press.
                // A selected code is a selected code, whatever else the article
                // still needs asked.
                showCard(c);
                syncBuild(c);
                dimRows(el, c);
              }
              // Depths in order, and the codes under each in height order.
              function rs_by_depth(rs){
                var by = {}, depths = [];
                rs.slice().sort(function(a,b){ return a.height_mm-b.height_mm; })
                  .forEach(function(c){
                    var d = c.depth_mm || 0;
                    if(!by[d]){ by[d] = []; depths.push(d); }
                    by[d].push(c);
                  });
                depths.sort(function(a,b){ return a-b; });
                return { by: by, depths: depths };
              }
              function syncBuild(c){
                var ok = true, why = '';
                if(c && c.width_range_mm){
                  var w = parseInt(st.w, 10);
                  if(!(w >= c.width_range_mm[0] && w <= c.width_range_mm[1])){
                    ok = false;
                    why = 'This article is made from ' + c.width_range_mm[0] + ' to ' +
                          c.width_range_mm[1] + ' mm \u2014 type the width to order.';
                  }
                }
                // BOTH DIMENSIONS, since a sheet states neither. The width hint
                // wins when both are missing: one instruction at a time is what
                // a person can act on.
                if(ok && c && c.height_range_mm){
                  var hh = parseInt(st.h, 10);
                  if(!(hh >= c.height_range_mm[0] && hh <= c.height_range_mm[1])){
                    ok = false;
                    why = 'Cut to size, up to ' + c.height_range_mm[1] +
                          ' mm on this axis \u2014 type the height to order.';
                  }
                }
                document.getElementById('buildBtn').style.display = ok ? 'block' : 'none';
                var h = document.getElementById('whint');
                if(h) h.textContent = why;
              }
              function sizeGrid(el){
                var rs = rows();
                if(rs.length && rs[0].corner_geometry){ cornerList(el); return; }
                // The width is worth a button only when it tells the codes
                // apart. A filler states a RANGE and no width at all; an end
                // panel states the same 22 on every row while the height is the
                // whole article. Both go one dimension over.
                var ws = uniq(rs.map(function(c){return c.width_mm;}));
                var hs = uniq(rs.map(function(c){return c.height_mm;}));
                // A SHEET FIRST, because it breaks the rule the two grids below
                // share: they both put a printed DIMENSION on the button, and a
                // sheet has none. Sent to heightGrid it drew one button per code
                // reading 'H. 0'. What separates its codes is the lacquer or
                // veneer group and how many sides are faced.
                if(rs.length && rs[0].height_range_mm){ sheetGrid(el); return; }
                if(rs.length && (rs[0].width_range_mm ||
                                 (ws.length === 1 && hs.length > 1))){
                  heightGrid(el); return;
                }
                var depths = uniq(rs.map(function(c){return c.depth_mm;})).sort(function(a,b){return a-b;});
                depths.forEach(function(d){
                  var row = document.createElement('div'); row.className='drow';
                  var lab = document.createElement('div'); lab.className='dlab';
                  lab.textContent = 'd. ' + (d/10);
                  row.appendChild(lab);
                  rs.filter(function(c){return c.depth_mm===d;})
                    .sort(function(a,b){return a.width_mm-b.width_mm;})
                    .forEach(function(c){
                      var b = document.createElement('button'); b.className='wbtn';
                      if(st.code===c.code) b.className += ' sel';
                      b.innerHTML = INCH
                        ? esc(String(c.width_mm)) + '<small>' +
                          esc(inchLabel(c.width_mm, c.nominal_in)) + '</small>'
                        : esc(String(c.width_mm));
                      b.onclick = function(){ st.code = c.code; render(); };
                      row.appendChild(b);
                    });
                  el.appendChild(row);
                });
                if(st.code) showCard(CAT.find(function(c){return c.code===st.code;}));
              }
              function showCard(c){
                if(!c) return;
                var el = document.getElementById('card');
                var dims = c.width_range_mm
                  ? 'W ' + c.width_range_mm[0] + '\u2013' + c.width_range_mm[1] +
                    ' mm, stated per order \u00b7 H ' + c.height_mm + ' mm' +
                    (c.depth_mm ? ' \u00b7 D ' + c.depth_mm + ' mm'
                                : ' \u00b7 no depth printed') +
                    '<br><i>the catalog gives the range and not the width \u2014 ' +
                    'the same kind of axis as the hinge side</i>'
                  : c.corner_geometry
                  ? 'node ' + c.corner_geometry.replace('x',' × ') + ' mm · carcass ' +
                    c.carcass_length_mm + ' × ' + c.depth_mm + ' · door ' + c.door_width_mm +
                    '<br><i>' + c.execution + ' execution — the mirror is a different code; ' +
                    'the door hand is set in the properties panel</i>'
                  : c['class'] === 'end_panel'
                  ? 'H ' + c.height_mm + ' × D ' + c.depth_mm + ' mm, ' +
                    c.width_mm + ' mm thick' +
                    '<br><i>the depth is the catalog\u2019s DRAWN d. \u2014 the carcass ' +
                    'depth it serves is the smaller number on the page</i>'
                  : 'W ' + c.width_mm + ' × H ' + c.height_mm + ' × D ' + c.depth_mm + ' mm' +
                    (INCH ? '<br><span class="src">' +
                            esc(inchLabel(c.width_mm, c.nominal_in)) + ' × ' +
                            esc(inchLabel(c.height_mm, c.nominal_h_in)) + ' × ' +
                            esc(inchLabel(c.depth_mm, c.nominal_d_in)) + '</span>' : '');
                el.innerHTML = '<b>' + c.code + '</b> · ' + c.family + '<br>' + c.description +
                  '<br>' + dims + '<br>' +
                  '<span class="src">' + c.source_ref + ' · PRELIMINARY</span>';
                el.style.display='block';
                document.getElementById('buildBtn').style.display='block';
              }
              function doSearch(){
                var q = document.getElementById('search').value.trim().toUpperCase();
                if(q.length < 2){ render(); return; }
                var el = document.getElementById('content'); el.innerHTML='';
                document.getElementById('crumb').innerHTML = 'Search results';
                document.getElementById('card').style.display='none';
                document.getElementById('buildBtn').style.display='none';
                CAT.filter(function(c){
                  return c.code.indexOf(q) >= 0 ||
                         c.description.toUpperCase().indexOf(q) >= 0;
                }).slice(0, 20).forEach(function(c){
                  var size = c.buildable === false && c.corner_geometry
                    ? c.corner_geometry + ' mm · d.' + (c.depth_mm/10)
                    : c.width_mm + '×' + c.height_mm + '×' + c.depth_mm;
                  if(c.buildable === false){
                    var g = document.createElement('div'); g.className='ghost';
                    g.innerHTML = row(esc(c.code) + ' <small>— ' + esc(size) + '</small>', 'not buildable') +
                                  '<small>' + esc(c.description) + '</small>';
                    el.appendChild(g);
                    return;
                  }
                  var b = document.createElement('button'); b.className='item';
                  b.innerHTML = c.code + ' <small>— ' + size + ' · ' + c.description + '</small>';
                  b.onclick = function(){
                    document.getElementById('search').value='';
                    st = { cls:c['class'], sec:c.section, typ:c.type_key, code:c.code };
                    render();
                  };
                  el.appendChild(b);
                });
              }
              function doBuild(){
                if(!st.code) return;
                var c = CAT.find(function(x){ return x.code===st.code; });
                sketchup.build(st.code,
                  (c && c.width_range_mm)  ? String(parseInt(st.w, 10)) : '',
                  (c && c.height_range_mm) ? String(parseInt(st.h, 10)) : '');
              }
              window.onload = function(){
                if(INCH) document.getElementById('units').className = 'on';
                setLevel(null, null, null);
              };
            </script>
          </body></html>
        HTML
      end

      def html
        <<~HTML
          <!DOCTYPE html><html><head><meta charset="utf-8"><style>
            body{font:13px -apple-system,Helvetica,Arial;margin:0;padding:12px;background:#f5f5f4;color:#222}
            button{display:block;width:100%;margin:0 0 8px;padding:9px;border:0;border-radius:6px;
                   background:#fff;border:1px solid #d4d4d4;font-size:13px;cursor:pointer;text-align:left}
            button:hover{background:#eef2ff;border-color:#93b4f5}
            .primary{background:#2563eb;color:#fff;border-color:#2563eb}
            .primary:hover{background:#1d4ed8}
            #ver{color:#999;font-size:10px;margin-top:6px;text-align:center}
            .grp{color:#777;font-size:11px;margin:6px 0 4px}
            .row{display:flex;gap:4px}
            .seg{flex:1;margin:0;padding:6px 2px;text-align:center;font-size:12px}
          </style></head><body>
            <button class="primary" onclick="sketchup.build_by_code()">Build by code…</button>
            <button onclick="sketchup.place()">Place selected unit…</button>
            <button onclick="sketchup.panel()">Unit Properties panel</button>
            <button onclick="sketchup.export_order()">Order schedule (CSV)…</button>
            <button onclick="sketchup.reserve_run_gap()">Reserve run gap…</button>
            <button onclick="sketchup.reserve_wall()">Reserve wall volume (hood)…</button>
            <button onclick="sketchup.worktop()">Worktop over selected run…</button>
            <button onclick="sketchup.reload()">Reload core</button>
            #{DevBridge.available? ? '<button onclick="sketchup.reload_bridge()">Reload probe bridge (dev)</button>' : ''}
            <div class="grp">Opening symbols</div>
            <div class="row">
              <button class="seg" onclick="sketchup.symbols('plan')">Plan</button>
              <button class="seg" onclick="sketchup.symbols('front')">Elevation</button>
              <button class="seg" onclick="sketchup.symbols('door')">Open door</button>
            </div>
            <div class="row" style="margin-top:4px">
              <button class="seg" onclick="sketchup.symbols('all')">All</button>
              <button class="seg" onclick="sketchup.symbols('off')">Off</button>
            </div>
            <button onclick="sketchup.thin()" style="margin-top:8px">Thin / thick lines</button>
            <div id="ver"></div>
            <script>
              function setVersion(v){document.getElementById('ver').textContent=v;}
              window.onload=function(){};
            </script>
          </body></html>
        HTML
      end
    end
  end
end

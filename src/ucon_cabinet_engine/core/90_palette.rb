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
        @dialog = UI::HtmlDialog.new(
          dialog_title: 'UCON Cabinet Engine', preferences_key: 'UCONPalette',
          style: UI::HtmlDialog::STYLE_UTILITY, width: 240, height: 360,
          resizable: false
        )
        @dialog.set_html(html)
        @dialog.add_action_callback('build_by_code') { |_| show_picker }
        @dialog.add_action_callback('panel')  { |_| Panel.show }
        @dialog.add_action_callback('symbols') do |_, mode|
          Symbols.show_mode(Sketchup.active_model, mode.to_sym)
        end
        @dialog.add_action_callback('thin') do |_|
          Symbols.toggle_thin_lines(Sketchup.active_model)
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

      def show_picker
        require 'json'
        @picker&.close rescue nil
        @picker = UI::HtmlDialog.new(
          dialog_title: 'UCON — Build unit', preferences_key: 'UCONPicker',
          style: UI::HtmlDialog::STYLE_UTILITY, width: 360, height: 470,
          resizable: true
        )
        @picker.set_html(picker_html(Registry.catalog, Registry.gaps))
        @picker.add_action_callback('build') do |_, code|
          begin
            Generator.build(code)
          rescue StandardError => e
            UI.messagebox("Build failed:\n\n#{e.message}")
          end
        end
        @picker.show
      end

      CLASS_LABELS = {
        'base' => 'Base units', 'wall' => 'Wall units', 'tall' => 'Tall units'
      }.freeze

      # Display labels only — UCON's own vocabulary for the picker. The
      # registry keeps the catalog's wording; this map never travels into data
      # or into an order. An unmapped type falls back to its key.
      TYPE_LABELS = {
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
        'appliance_dishwasher_door' => 'Dishwasher door'
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
      def picker_html(catalog, gaps = [])
        require 'json'
        <<~HTML
          <!DOCTYPE html><html><head><meta charset="utf-8"><style>
            body{font:13px -apple-system,Helvetica,Arial;margin:0;padding:12px;background:#f5f5f4;color:#222}
            #crumb{font-size:11px;color:#666;margin-bottom:8px;min-height:14px}
            #crumb a{color:#2563eb;cursor:pointer;text-decoration:none}
            #search{width:100%;box-sizing:border-box;padding:5px 8px;margin-bottom:8px;
                    border:1px solid #ccc;border-radius:6px;font-size:12px}
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
            .wbtn:hover{background:#eef2ff}
            .wbtn.sel{background:#2563eb;color:#fff;border-color:#2563eb}
            #card{background:#fff;border:1px solid #ddd;border-radius:6px;padding:10px;margin:8px 0;
                  font-size:12px;line-height:1.5;display:none}
            #card b{font-size:13px} .src{color:#888;font-size:11px}
            #buildBtn{width:100%;padding:9px;border:0;border-radius:6px;background:#2563eb;color:#fff;
                      font-size:13px;cursor:pointer;display:none}
          </style></head><body>
            <input id="search" placeholder="Search code or description…" oninput="doSearch()">
            <div id="crumb"></div>
            <div id="content"></div>
            <div id="card"></div>
            <button id="buildBtn" onclick="doBuild()">Build</button>
            <script>
              var CAT = #{script_json(catalog)};
              var GAPS = #{script_json(gaps)};
              var CLS = #{script_json(CLASS_LABELS)};
              var TYP = #{script_json(TYPE_LABELS)};
              var st = { cls:null, sec:null, typ:null, code:null };

              function uniq(a){ return a.filter(function(v,i){ return a.indexOf(v)===i; }); }
              function rows(){ return CAT.filter(function(c){
                return (!st.cls || c['class']===st.cls) && (!st.sec || c.section===st.sec) &&
                       (!st.typ || c.type_key===st.typ); }); }

              function setLevel(cls, sec, typ, code){
                st = { cls:cls, sec:sec, typ:typ, code:code || null };
                autoAdvance(); render();
              }
              function autoAdvance(){
                if(!st.cls){ var cs = uniq(CAT.map(function(c){return c['class'];}));
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
                if(!st.cls){ list(uniq(CAT.map(function(c){return c['class'];})),
                  function(v){return CLS[v]||v;}, function(v){ setLevel(v,null,null); }); return; }
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
              function list(vals, lab, go){
                var el = document.getElementById('content');
                vals.forEach(function(v){
                  var b = document.createElement('button'); b.className='item';
                  b.textContent = lab(v);
                  b.onclick = function(){ go(v); };
                  el.appendChild(b);
                });
              }
              function sizeGrid(el){
                var rs = rows();
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
                      b.textContent = c.width_mm;
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
                el.innerHTML = '<b>' + c.code + '</b> · ' + c.family + '<br>' + c.description +
                  '<br>W ' + c.width_mm + ' × H ' + c.height_mm + ' × D ' + c.depth_mm + ' mm<br>' +
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
                  var b = document.createElement('button'); b.className='item';
                  b.innerHTML = c.code + ' <small>— ' + c.width_mm + '×' + c.height_mm + '×' +
                                c.depth_mm + ' · ' + c.description + '</small>';
                  b.onclick = function(){
                    document.getElementById('search').value='';
                    st = { cls:c['class'], sec:c.section, typ:c.type_key, code:c.code };
                    render();
                  };
                  el.appendChild(b);
                });
              }
              function doBuild(){ if(st.code) sketchup.build(st.code); }
              window.onload = function(){ setLevel(null, null, null); };
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
            <button onclick="sketchup.panel()">Unit Properties panel</button>
            <button onclick="sketchup.reload()">Reload core</button>
            <div class="grp">Opening symbols</div>
            <div class="row">
              <button class="seg" onclick="sketchup.symbols('plan')">Plan</button>
              <button class="seg" onclick="sketchup.symbols('front')">Elevation</button>
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

# frozen_string_literal: true
#
# UCON Cabinet Engine — core/80_panel.rb
#
# Floating properties panel (UI::HtmlDialog, STYLE_UTILITY). Select a UCON
# unit, the panel shows its contract attributes; choose the door version,
# opening method, hardware and hinge side; Apply writes attributes through
# the contract validator, rebuilds the front slabs and redraws the dashed
# opening symbols.
#
# Rules enforced (Object Contract §4.1 + registry hardware):
#   door 75  -> opening_method = gola, front_height = family door − 30,
#               a GOL profile is REQUIRED (separate line item)
#   door 78  -> handle (factory M-code OR client-provided) or push_to_open
#               (device code pending Elda — hardware_ref stays empty)
#   hinge side only on handed units; never guessed, only chosen here.
#
# The panel lives in core, so Reload core rebuilds it — close and reopen the
# dialog to pick up changes. attributes_patch is pure and headless-tested.

require 'json'

module UCON
  module CabinetEngine
    module Panel
      module_function

      # ---------- pure logic (headless-tested) --------------------------
      # unit: registry hash; payload: from the dialog:
      #   'door_version' => '78' | '75'
      #   'opening_method' => 'handle' | 'push_to_open' | 'gola'
      #   'hardware_mode' => 'factory' | 'client'   (handle only)
      #   'hardware_ref'  => 'M00001' / 'GOL001' / ''
      #   'hinge_side'    => 'rh' | 'lh' | ''
      def attributes_patch(unit, payload)
        gola = payload['door_version'] == '75'
        method = gola ? 'gola' : payload['opening_method']
        raise ArgumentError, 'Door 78 cannot use gola profile logic' if method == 'gola' && !gola
        # The door-version axis is FAMILY-SCOPED - the manifest says "each
        # base-unit page shows door heights 78 and 75". A family that declares
        # no versions has no choice to make, and a wall unit 360 tall cannot be
        # given a 750 front. Checked here and not only in the dialog, because a
        # rule that lives only in HTML is not a rule.
        if gola && !gola_available?(unit)
          raise ArgumentError,
                "#{unit['code']} (#{unit['family']}, H #{unit['height_mm']}) has no gola door " \
                'version: its family does not declare one.'
        end
        raise ArgumentError, 'opening_method is required' if method.nil? || method.empty?

        h = unit['height_mm']
        patch = {
          'opening_method'  => method,
          'front_height_mm' => gola ? h - 30 : h
        }

        case method
        when 'gola'
          ref = payload['hardware_ref'].to_s
          # A cabinet front in the 75 version orders its own GOL profile.
          # An APPLIANCE panel is not a cabinet front: the profile above it
          # belongs to the run, and the source never gives the panel a profile
          # line of its own. Whether one is nevertheless ordered is Elda Q6, so
          # the profile is optional here rather than invented or demanded.
          appliance = unit['object_class'] == 'appliance_front'
          if ref.empty?
            raise ArgumentError, 'Gola (door 75) requires a grip-recess profile (GOL…) — it is a separate order line' unless appliance
          else
            patch['hardware_ref']    = ref
            patch['hardware_source'] = 'factory'
          end
        when 'handle'
          if payload['hardware_mode'] == 'client'
            patch['hardware_ref']    = ''
            patch['hardware_source'] = 'client'
          else
            ref = payload['hardware_ref'].to_s
            raise ArgumentError, 'Factory handle requires an M-code (or switch to client-provided)' if ref.empty?
            patch['hardware_ref']    = ref
            patch['hardware_source'] = 'factory'
          end
        when 'push_to_open'
          patch['hardware_ref']    = ''
          patch['hardware_source'] = 'factory'
        else
          raise ArgumentError, "Unknown opening_method #{method.inspect}"
        end

        hinge = payload['hinge_side'].to_s
        if unit['handed']
          patch['hinge_side'] = hinge unless hinge.empty?
        elsif !hinge.empty?
          raise ArgumentError, 'hinge_side applies only to handed (single-door) units'
        end
        patch
      end

      # Gola profiles valid for this unit. A base-unit front sits under the
      # worktop, so only position=undercounter profiles apply (GOL001 L-shaped,
      # GOL005 straight); intermediate profiles join stacked front zones and
      # offering them here would invite a wrong order line.
      # Does this unit's family print a second, shortened door height?
      def gola_available?(unit)
        versions = unit && unit['door_versions']
        !!(versions && versions['gola_mm'])
      end

      def gola_options(unit = nil)
        rows = (Registry.data['hardware'] || {})['gola_profiles'] || []
        kind = unit && (unit['front_layout'] || {})['kind']
        if kind == 'horizontal'
          # A drawer stack needs BOTH profiles (undercounter + intermediate,
          # same system) - offered as a pair so the order can't lose one.
          %w[L-shaped straight].map do |sys|
            pair = rows.select { |row| row['system'] == sys }
                       .sort_by { |row| row['position'] == 'undercounter' ? 0 : 1 }
            { 'code' => pair.map { |row| row['code'] }.join('+'),
              'name' => "#{sys} system (#{pair.map { |row| row['code'] }.join(' + ')})" }
          end
        else
          rows.select { |row| row['position'] == 'undercounter' }
        end
      end

      # Effective slab list for a door version (gola shortens door slabs by 30,
      # leaving the grip zone empty at the top; horizontal drawer stacks keep
      # catalog heights until the gola stack is verified).
      def effective_slabs(unit, gola)
        layout = unit['front_layout'] || { 'kind' => 'single' }
        if gola && %w[single vertical_split corner_door].include?(layout['kind'])
          Generator.front_slabs(unit.merge('height_mm' => unit['height_mm'] - 30))
        elsif gola && layout['kind'] == 'horizontal' && layout['gola_stack_top_to_bottom']
          stack = layout['gola_stack_top_to_bottom']
          total = stack.sum { |seg| seg['h_mm'].to_f }
          unless (total - unit['height_mm']).abs < 0.001
            raise "gola stack #{total} does not sum to #{unit['height_mm']}"
          end
          w = unit['width_mm']
          z = 0.0
          slabs = []
          stack.reverse.each do |seg|
            if seg['kind'] == 'front'
              slabs << { name: "FRONT_#{slabs.length + 1}_FROM_BOTTOM",
                         x_mm: 0, z_mm: z.round(1), w_mm: w, h_mm: seg['h_mm'].round(1) }
            end
            z += seg['h_mm']
          end
          slabs
        else
          Generator.front_slabs(unit)
        end
      end

      # ---------- SketchUp side -----------------------------------------
      def show
        @dialog&.close rescue nil
        @dialog = UI::HtmlDialog.new(
          dialog_title: 'UCON Unit Properties', preferences_key: 'UCONPanel',
          style: UI::HtmlDialog::STYLE_UTILITY, width: 330, height: 560,
          resizable: true
        )
        @dialog.set_html(html)
        @dialog.add_action_callback('ready')  { |_| push_selection }
        @dialog.add_action_callback('apply')  { |_, json| apply(JSON.parse(json)) }
        @dialog.show
        install_observer
        nil
      end

      def install_observer
        @observer ||= Class.new(Sketchup::SelectionObserver) do
          def onSelectionBulkChange(_sel); UCON::CabinetEngine::Panel.push_selection; end
          def onSelectionCleared(_sel);    UCON::CabinetEngine::Panel.push_selection; end
        end.new
        sel = Sketchup.active_model.selection
        sel.remove_observer(@observer) rescue nil
        sel.add_observer(@observer)
      end

      def selected_unit_instance
        Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).find do |i|
          i.definition.get_attribute(Contract::DICTIONARY, 'code')
        end
      end

      def push_selection
        return unless @dialog&.visible?
        inst = selected_unit_instance
        state =
          if inst
            attrs = Contract.read(inst.definition)
            unit  = Registry.lookup(attrs['code']) rescue nil
            { 'attrs' => attrs, 'handed' => unit && unit['handed'],
              'desc' => unit && unit['description'],
              'door_versions' => unit && unit['door_versions'] }
          else
            {}
          end
        hw = Registry.data['hardware'] || {}
        state['gola_profiles'] = gola_options
        state['handles']       = hw['handles'] || []
        @dialog.execute_script("render(#{state.to_json})")
      end

      def apply(payload)
        inst = selected_unit_instance
        return UI.messagebox('Select a UCON unit first.') unless inst

        model = Sketchup.active_model
        defn  = inst.definition
        attrs = Contract.read(defn)
        unit  = Registry.lookup(attrs['code'])
        patch = attributes_patch(unit, payload)

        model.start_operation('UCON: apply unit properties', true)
        begin
          Contract.write!(defn, attrs.merge(patch))
          gola = patch['opening_method'] == 'gola'
          rebuild_fronts(model, defn, unit, gola)
          Symbols.draw(model, defn, unit,
                       patch['hinge_side'] || attrs['hinge_side'],
                       patch['front_height_mm'],
                       effective_slabs(unit, gola))
          model.commit_operation
        rescue StandardError
          model.abort_operation
          raise
        end
        push_selection
      rescue StandardError => e
        UI.messagebox("Apply failed:\n\n#{e.message}")
      end

      def rebuild_fronts(model, defn, unit, gola)
        s = Standards
        # The 8x8 corner filler shares the door's height, so it is rebuilt with
        # the fronts, not left behind at the old one.
        doomed = defn.entities.grep(Sketchup::Group).select do |g|
          g.name.start_with?('FRONT') || g.name == 'FILLER_8X8'
        end
        defn.entities.erase_entities(doomed) unless doomed.empty?
        front_mat = Geometry.material(model, 'UCON_Front_White', [245, 245, 245])
        front_y   = -(s::FRONT_GAP_MM + s::FRONT_T_MM)
        effective_slabs(unit, gola).each do |slab|
          Geometry.box(defn.entities, slab[:name],
                       slab[:x_mm], front_y, s::PLINTH_H_MM + slab[:z_mm],
                       slab[:w_mm], s::FRONT_T_MM, slab[:h_mm], front_mat)
        end

        if unit['geometry_kind'] == 'corner'
          front_h = effective_slabs(unit, gola).first[:h_mm]
          parts   = Generator.corner_parts(unit, front_h)
          Geometry.prism(defn.entities, 'FILLER_8X8', parts[:filler_plan],
                         s::PLINTH_H_MM, front_h, front_mat)
        end

        # Gola (door 75): the 30 mm zone above the shortened door stays EMPTY
        # by decision (2026-08-16) - drawing the profile body read as noise.
        # The true cross-section stays recorded in the registry
        # (hardware.gola_profile_body) for when a detailed view needs it.
      end

      def html
        <<~HTML
          <!DOCTYPE html><html><head><meta charset="utf-8"><style>
            body{font:13px -apple-system,Helvetica,Arial;margin:0;padding:14px;background:#f5f5f4;color:#222}
            h3{margin:0 0 2px;font-size:14px} .muted{color:#777;font-size:11px;margin-bottom:10px}
            fieldset{border:1px solid #ddd;border-radius:6px;margin:0 0 10px;padding:8px 10px;background:#fff}
            legend{font-size:11px;color:#555;padding:0 4px}
            label{display:block;margin:3px 0} select{width:100%;margin-top:3px}
            button{width:100%;padding:8px;border:0;border-radius:6px;background:#2563eb;color:#fff;font-size:13px;cursor:pointer}
            button:disabled{background:#aaa} .warn{color:#b45309;font-size:11px;margin-top:4px}
            #empty{color:#888;padding:30px 0;text-align:center}
          </style></head><body>
          <div id="empty">Select a UCON unit in the model</div>
          <div id="form" style="display:none">
            <h3 id="code"></h3><div class="muted" id="desc"></div>
            <fieldset id="dvFs"><legend>Door height</legend>
              <label><input type="radio" name="dv" value="78" checked onchange="rules()">
                <span id="dvFull">full front</span></label>
              <label><input type="radio" name="dv" value="75" onchange="rules()">
                <span id="dvGola">gola</span></label>
            </fieldset>
            <fieldset><legend>Opening</legend>
              <select id="om" onchange="rules()">
                <option value="handle">Handle</option>
                <option value="push_to_open">Push-to-open</option>
              </select>
              <div id="golaNote" class="warn" style="display:none">Door 75 opens by gola only. A grip-recess profile is required (separate order line):</div>
              <select id="gol" style="display:none"></select>
              <div id="handleBlock">
                <select id="hmode" onchange="rules()">
                  <option value="factory">Handle from catalog</option>
                  <option value="client">Client-supplied</option>
                </select>
                <select id="handle"></select>
              </div>
              <div id="ptoNote" class="warn" style="display:none">Push-pull device code not found in source — P3, pending Elda. hardware_ref stays empty.</div>
            </fieldset>
            <fieldset id="hingeFs"><legend>Hinge side</legend>
              <select id="hinge">
                <option value="">— not chosen —</option>
                <option value="lh">Left (hinges left)</option>
                <option value="rh">Right (hinges right)</option>
              </select>
            </fieldset>
            <button onclick="apply()">Apply</button>
          </div>
          <script>
            var HANDED=false;
            function opt(s,items,sel){s.innerHTML='';items.forEach(function(it){
              var o=document.createElement('option');o.value=it.code;o.text=it.code+' — '+it.name;
              if(it.code===sel)o.selected=true;s.add(o);});}
            function rules(){
              var gola=document.querySelector('input[name=dv]:checked').value==='75';
              document.getElementById('om').style.display=gola?'none':'';
              document.getElementById('golaNote').style.display=gola?'':'none';
              document.getElementById('gol').style.display=gola?'':'none';
              var om=document.getElementById('om').value;
              document.getElementById('handleBlock').style.display=(!gola&&om==='handle')?'':'none';
              document.getElementById('ptoNote').style.display=(!gola&&om==='push_to_open')?'':'none';
              document.getElementById('handle').style.display=
                document.getElementById('hmode').value==='factory'?'':'none';
              document.getElementById('hingeFs').style.display=HANDED?'':'none';
            }
            function render(st){
              var has=st.attrs&&st.attrs.code;
              document.getElementById('empty').style.display=has?'none':'';
              document.getElementById('form').style.display=has?'':'none';
              if(!has)return;
              HANDED=!!st.handed;
              // A family that declares no door versions gets no door-version
              // control - and the labels are written from the declared heights,
              // so nothing in this dialog hard-codes 78 or 75.
              var dv = st.door_versions;
              document.getElementById('dvFs').style.display = dv ? '' : 'none';
              if(dv){
                document.getElementById('dvFull').textContent =
                  (dv.full_mm/10) + ' — full front';
                document.getElementById('dvGola').textContent =
                  (dv.gola_mm/10) + ' — gola (−' + (dv.full_mm - dv.gola_mm) + ' mm)';
              } else {
                document.querySelector('input[name=dv][value="78"]').checked = true;
              }
              var dims = st.attrs.corner_geometry
                ? st.attrs.corner_geometry.replace('x','×')+' mm node · H '+st.attrs.height_mm+' · D '+st.attrs.depth_mm
                : st.attrs.width_mm+'×'+st.attrs.height_mm+'×'+st.attrs.depth_mm;
              document.getElementById('code').textContent=st.attrs.code+'  ('+dims+')';
              document.getElementById('desc').textContent=(st.desc||'')+' · '+st.attrs.code_status+' / '+st.attrs.status;
              opt(document.getElementById('gol'),st.gola_profiles,st.attrs.hardware_ref);
              opt(document.getElementById('handle'),st.handles,st.attrs.hardware_ref);
              var m=st.attrs.opening_method||'handle';
              if(m==='gola'){document.querySelector('input[name=dv][value="75"]').checked=true;}
              else{document.querySelector('input[name=dv][value="78"]').checked=true;
                   document.getElementById('om').value=m;}
              if(st.attrs.hardware_source==='client')document.getElementById('hmode').value='client';
              if(st.attrs.hinge_side)document.getElementById('hinge').value=st.attrs.hinge_side;
              rules();
            }
            function apply(){
              var gola=document.querySelector('input[name=dv]:checked').value==='75';
              var p={door_version:gola?'75':'78',
                     opening_method:gola?'gola':document.getElementById('om').value,
                     hardware_mode:document.getElementById('hmode').value,
                     hardware_ref:gola?document.getElementById('gol').value
                                      :(document.getElementById('hmode').value==='factory'
                                        ?document.getElementById('handle').value:''),
                     hinge_side:HANDED?document.getElementById('hinge').value:''};
              sketchup.apply(JSON.stringify(p));
            }
            window.onload=function(){sketchup.ready();};
          </script></body></html>
        HTML
      end
    end
  end
end

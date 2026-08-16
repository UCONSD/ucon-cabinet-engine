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
        raise ArgumentError, 'opening_method is required' if method.nil? || method.empty?

        h = unit['height_mm']
        patch = {
          'opening_method'  => method,
          'front_height_mm' => gola ? h - 30 : h
        }

        case method
        when 'gola'
          ref = payload['hardware_ref'].to_s
          raise ArgumentError, 'Gola (door 75) requires a grip-recess profile (GOL…) — it is a separate order line' if ref.empty?
          patch['hardware_ref']    = ref
          patch['hardware_source'] = 'factory'
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
      def gola_options(unit = nil)
        rows = (Registry.data['hardware'] || {})['gola_profiles'] || []
        rows.select { |row| row['position'] == 'undercounter' }
      end

      # Effective slab list for a door version (gola shortens door slabs by 30,
      # leaving the grip zone empty at the top; horizontal drawer stacks keep
      # catalog heights until the gola stack is verified).
      def effective_slabs(unit, gola)
        layout = unit['front_layout'] || { 'kind' => 'single' }
        if gola && %w[single vertical_split].include?(layout['kind'])
          Generator.front_slabs(unit.merge('height_mm' => unit['height_mm'] - 30))
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
              'desc' => unit && unit['description'] }
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
          rebuild_fronts(model, defn, unit, patch['opening_method'] == 'gola')
          Symbols.draw(model, defn, unit, patch['hinge_side'] || attrs['hinge_side'])
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
        doomed = defn.entities.grep(Sketchup::Group).select { |g| g.name.start_with?('FRONT') }
        defn.entities.erase_entities(doomed) unless doomed.empty?
        front_mat = Geometry.material(model, 'UCON_Front_White', [245, 245, 245])
        front_y   = -(s::FRONT_GAP_MM + s::FRONT_T_MM)
        effective_slabs(unit, gola).each do |slab|
          Geometry.box(defn.entities, slab[:name],
                       slab[:x_mm], front_y, s::PLINTH_H_MM + slab[:z_mm],
                       slab[:w_mm], s::FRONT_T_MM, slab[:h_mm], front_mat)
        end

        # Gola: the profile body occupies the 30 mm zone above the shortened
        # door, so the elevation reads 750 + 30 = 780 like the catalog page.
        # Drawn as the visible strip at the front plane, front thickness; the
        # true cross-section (57 zone / 27 depth) is recorded in the registry
        # (hardware.gola_profile_body) and stays out of the drawing until the
        # system is confirmed. Named FRONT_* so the rebuild wipe catches it.
        kind = (unit['front_layout'] || {})['kind'] || 'single'
        if gola && %w[single vertical_split].include?(kind)
          body = (Registry.data['hardware'] || {})['gola_profile_body'] || {}
          bh = body['upper_dim_mm'] || 30
          gola_mat = Geometry.material(model, 'UCON_Gola_Aluminium', [168, 168, 168])
          Geometry.box(defn.entities, 'FRONT_GOLA_PROFILE',
                       0, front_y,
                       s::PLINTH_H_MM + unit['height_mm'] - bh,
                       unit['width_mm'], s::FRONT_T_MM, bh, gola_mat)
        end
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
            <fieldset><legend>Door height</legend>
              <label><input type="radio" name="dv" value="78" checked onchange="rules()"> 78 — full front</label>
              <label><input type="radio" name="dv" value="75" onchange="rules()"> 75 — gola (−30 mm)</label>
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
              document.getElementById('code').textContent=st.attrs.code+'  ('+st.attrs.width_mm+'×'+st.attrs.height_mm+'×'+st.attrs.depth_mm+')';
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

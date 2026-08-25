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
          system = payload['gola_system'].to_s
          # A cabinet front in the 75 version orders its own GOL profile.
          # An APPLIANCE panel is not a cabinet front: the profile above it
          # belongs to the run, and the source never gives the panel a profile
          # line of its own. Whether one is nevertheless ordered is Elda Q6, so
          # the profile is optional here rather than invented or demanded.
          appliance = unit['object_class'] == 'appliance_front'
          if system.empty?
            raise ArgumentError, 'Gola (door 75) requires a grip-recess SYSTEM — its profiles are separate order lines' unless appliance
          elsif Generator.gola_profile_refs(unit, system).empty?
            raise ArgumentError, "No grip-recess profile is registered for system #{system.inspect}"
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

        # MOUNTING IS A CHOICE NOW (printed p.548), and the patch must be able
        # to take it back as well as make it - the contract reconciles, so a
        # unit returned to the floor gets mount_bottom_mm DELETED rather than
        # left behind at its old hanging height.
        hang = payload['wall_hung'] ? true : false
        if hang && !Generator.wall_hung_available?(unit)
          raise ArgumentError,
                "#{unit['code']} cannot be ordered wall-hung: " \
                "#{Generator.hangs_by_nature?(unit) ? 'it already hangs' : 'the catalog does not offer it for this type'}."
        end
        # Two ways to be hanging and they must not be confused: a wall unit
        # hangs whatever the checkbox says, a base unit only if it was ticked.
        hung = hang || Generator.hangs_by_nature?(unit)
        patch['mounting'] = hung ? 'wall_hung' : 'floor'
        patch['mount_bottom_mm'] =
          hung ? Generator.mount_bottom_mm(unit.merge('mounting' => 'wall_hung')) : nil

        # COMPANIONS ARE RE-RESOLVED ON EVERY APPLY, gola profiles included.
        # They are IMPLIED lines and an implied line is recomputed, never
        # inherited (Contract v2 §4.2 rule 3) - which is also what takes the
        # profiles away again when a front stops being gola. Leaving them
        # behind would order a grip recess for a door that now opens with a
        # handle, and until 0.44.0 the contract could not even erase it.
        lines = Generator.companion_refs_for(
          unit, method == 'gola' ? payload['gola_system'].to_s : nil
        ) || []
        # ...AND THE CHOSEN ONE IS ADDED BACK, not preserved. That looks like a
        # violation of "a chosen line is never recomputed" and is not: the
        # checkbox IS the record of the choice, so re-deriving the line from it
        # reproduces exactly what the person decided. Preserving the old line
        # instead would keep ordering fixings for a unit somebody has just put
        # back on the floor. When a chosen option arrives that has no control
        # of its own to be read from, THAT is when the lines must be merged.
        wall_hung_line = hang ? Generator.wall_hung_ref(unit) : nil
        lines << wall_hung_line if wall_hung_line
        patch['companion_refs'] = lines.empty? ? nil : lines

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

      # THE CHOICE IS A SYSTEM, NOT A CODE. It used to be a code, and for a
      # drawer stack - which needs undercounter AND intermediate - the two were
      # joined into "GOL001+GOL002" so the dropdown could hold them in one
      # value. That string then reached hardware_ref, and the first real export
      # run printed it into an order schedule as an article that does not
      # exist. So the option carries the SYSTEM and the codes are resolved from
      # the registry where every other companion is resolved.
      #
      # `value` is what gets stored; `name` shows which profiles it will order,
      # so the person choosing still sees them.
      def gola_options(unit = nil)
        rows = (Registry.data['hardware'] || {})['gola_profiles'] || []
        positions = Generator.gola_positions_for(unit || {})
        rows.map { |row| row['system'] }.compact.uniq.map do |system|
          codes = positions.map do |position|
            found = rows.find { |r| r['system'] == system && r['position'] == position }
            found && found['code']
          end.compact
          { 'value' => system, 'name' => "#{system} system (#{codes.join(' + ')})" }
        end
      end

      # Which grip-recess system this object is on, read back from the profile
      # lines it carries. Stored as codes, derived as a system: the same "store
      # the code, look the rest up" rule the whole contract runs on.
      def gola_system_of(attrs)
        codes = Array((attrs || {})['companion_refs']).map { |l| l['code'] }
        rows  = (Registry.data['hardware'] || {})['gola_profiles'] || []
        row   = rows.find { |r| codes.include?(r['code']) }
        row && row['system']
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

      # EVERYTHING the dialog is handed, built from the selected unit. PURE -
      # no SketchUp - so the suite can check what the dialog actually receives
      # instead of what a helper would have returned had it been asked properly.
      #
      # That distinction is the whole reason this method exists. push_selection
      # used to call gola_options with NO unit, because `unit` was scoped inside
      # the branch above the call. A gola drawer unit was therefore offered a
      # single undercounter profile instead of the undercounter+intermediate
      # PAIR - and the order silently lost the profile that joins its stacked
      # front zones, which is exactly what pairing them was for. The suite was
      # green throughout: its check called gola_options(unit) directly and never
      # went through the caller. A pure layer being right proves nothing about
      # the thing that calls it.
      def selection_state(unit, attrs)
        state =
          if attrs
            { 'attrs' => attrs, 'handed' => unit && unit['handed'],
              'desc' => unit && unit['description'],
              'door_versions' => unit && unit['door_versions'] }
          else
            {}
          end
        # Whether this cabinet may be hung at all, and what it would order.
        # Computed here, in the pure half, because a rule that lives only in
        # the HTML is not a rule - the same reason gola_available? is checked
        # in attributes_patch and not only in the dialog.
        state['wall_hung_available'] = Generator.wall_hung_available?(unit)
        ref = Generator.wall_hung_ref(unit)
        state['wall_hung_ref'] = ref && ref['code']
        # WHAT THE CHECKBOX SHOULD SHOW, decided HERE and not in the HTML.
        #
        # The box records a CHOICE; `mounting` records the RESULT, and for a
        # wall unit the result is 'wall_hung' whether anybody chose anything or
        # not. The dialog used to initialise the box straight from `mounting`,
        # so on a wall unit the hidden box ticked itself, apply sent
        # wall_hung:true, and attributes_patch refused it - correctly - with
        # "it already hangs". The Ruby said as much two lines below the guard:
        # "a wall unit hangs whatever the checkbox says, a base unit only if it
        # was ticked." The rule was written down and only the HTML did not have
        # it, which is the whole reason it belongs in the pure half.
        state['wall_hung_chosen'] =
          state['wall_hung_available'] && (attrs || {})['mounting'] == 'wall_hung'
        hw = Registry.data['hardware'] || {}
        state['gola_profiles'] = gola_options(unit)
        state['gola_system']   = gola_system_of(attrs)
        state['handles']       = hw['handles'] || []
        state
      end

      # SketchUp glue only: find the selection, read it, hand it over. Any rule
      # that appears here instead of in selection_state is a rule the headless
      # suite cannot see.
      def push_selection
        return unless @dialog&.visible?
        inst  = selected_unit_instance
        attrs = inst && Contract.read(inst.definition)
        unit  = attrs ? (Registry.lookup(attrs['code']) rescue nil) : nil
        @dialog.execute_script("render(#{selection_state(unit, attrs).to_json})")
      end

      def apply(payload)
        inst = selected_unit_instance
        return UI.messagebox('Select a UCON unit first.') unless inst

        model = Sketchup.active_model
        defn  = inst.definition
        attrs = Contract.read(defn)
        unit  = Registry.lookup(attrs['code'])
        patch = attributes_patch(unit, payload)
        # THE REGISTRY ROW IS NOT THIS OBJECT. Everything below asks the
        # generator where geometry goes, and the generator must be asked about
        # the unit AS CHOSEN - otherwise a base unit somebody has just hung is
        # redrawn standing on its plinth, and the drawing tells a lie the
        # order does not. Same shape as the gola pairing that went missing.
        chosen = Generator.effective(unit, attrs.merge(patch))

        model.start_operation('UCON: apply unit properties', true)
        begin
          Contract.write!(defn, attrs.merge(patch))
          gola = patch['opening_method'] == 'gola'
          rebuild_fronts(model, defn, chosen, gola)
          rebuild_plinth(model, defn, chosen)
          Symbols.draw(model, defn, chosen,
                       patch['hinge_side'] || attrs['hinge_side'],
                       patch['front_height_mm'],
                       # `chosen`, not `unit`: effective_slabs reads the
                       # width, and on a filler the bare registry row has
                       # none. The same mistake as the line above it, one
                       # argument later.
                       effective_slabs(chosen, gola))
          model.commit_operation
        rescue StandardError
          model.abort_operation
          raise
        end
        push_selection
      rescue StandardError => e
        UI.messagebox("Apply failed:\n\n#{e.message}")
      end

      # A plinth appears and disappears with the mounting choice, so it is
      # erased and redrawn unconditionally - draw_plinth answers nil when this
      # unit has none, which is what makes that safe. HOW one is built is the
      # generator's answer and not ours: this method deliberately holds no
      # dimension, no material and no setback.
      def rebuild_plinth(model, defn, unit)
        doomed = defn.entities.grep(Sketchup::Group).select { |g| g.name == 'PLINTH' }
        defn.entities.erase_entities(doomed) unless doomed.empty?
        return if unit['object_class'] == 'appliance_front' && !unit['plinth_continues']

        Generator.draw_plinth(defn.entities, unit, model)
      end

      def rebuild_fronts(model, defn, unit, gola)
        # The 8x8 corner filler shares the door's height, so it is rebuilt with
        # the fronts, not left behind at the old one.
        doomed = defn.entities.grep(Sketchup::Group).select do |g|
          g.name.start_with?('FRONT') || g.name == 'FILLER_8X8'
        end
        defn.entities.erase_entities(doomed) unless doomed.empty?
        front_mat = Geometry.material(model, 'UCON_Front_White', [245, 245, 245])
        # Where the fronts start is the generator's answer, not ours. Asking it
        # is the whole fix: this method used to add PLINTH_H_MM itself, so
        # re-applying a handle to a hanging unit rebuilt its front on the floor.
        z0 = Generator.base_z_mm(unit)
        # HOW a slab becomes geometry is the generator's answer too. This used
        # to be its own copy of the box call, which is how a rebuilt wine
        # cooler front would have come back without its hole.
        effective_slabs(unit, gola).each do |slab|
          Generator.draw_front_slab(defn.entities, slab, unit, z0, front_mat)
        end

        if unit['geometry_kind'] == 'corner'
          front_h = effective_slabs(unit, gola).first[:h_mm]
          parts   = Generator.corner_parts(unit, front_h)
          Geometry.prism(defn.entities, 'FILLER_8X8', parts[:filler_plan],
                         z0, front_h, front_mat)
        end

        # Gola (door 75): the 30 mm zone above the shortened door stays EMPTY
        # by decision (2026-08-16) - drawing the profile body read as noise.
        # The true cross-section stays recorded in the registry
        # (hardware.gola_profile_body) for when a detailed view needs it.
      end

      # OBSERVATION, mirroring what the appliance panel says about us. The
      # engine may ACT on the appliance module - that is the permitted
      # direction and 88_appliance_check.rb is where it happens - but here we
      # only report, so the line is honest on a machine with no appliances.
      def peer_state
        unless defined?(UCON::CabinetEngine::ApplianceCheck) &&
               UCON::CabinetEngine::ApplianceCheck.available?
          return { ok: false, text: 'Appliances not installed — the engine does not need them.' }
        end

        v = if defined?(UCON::Appliances::VERSION)
              UCON::Appliances::VERSION
            else
              'installed'
            end
        { ok: true, text: "Appliances #{v} — seam active." }
      end

      def html
        <<~HTML
          <!DOCTYPE html><html><head><meta charset="utf-8"><style>
          #{UCON::CabinetEngine::PanelKit::CSS}
            /* engine panel, structural only - every colour comes from the kit */
            body{padding:14px;background:var(--bg-sunk)}
            h3{margin:0 0 2px;font-size:14px}
            .muted{color:var(--muted);font-size:11px;margin-bottom:10px}
            fieldset{border:1px solid var(--line);border-radius:6px;margin:0 0 10px;padding:8px 10px;background:var(--bg)}
            legend{font-size:11px;color:var(--muted);padding:0 4px}
            label{display:block;margin:3px 0} select{width:100%;margin-top:3px}
            button{width:100%;padding:8px;border:1px solid var(--accent);border-radius:6px;background:var(--accent);color:#fff;font-size:13px;cursor:pointer}
            #empty{color:var(--muted);padding:30px 0;text-align:center}
          </style></head><body>
          <div class="peer#{UCON::CabinetEngine::Panel.peer_state[:ok] ? '' : ' off'}" style="margin:-14px -14px 10px;padding:7px 14px;border-bottom:1px solid var(--line);background:var(--bg)">#{UCON::CabinetEngine::Panel.peer_state[:text]}</div>
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
              <div id="golaNote" class="flag" style="display:none">Door 75 opens by gola only. Its grip-recess profiles are separate order lines — a drawer stack needs two:</div>
              <select id="gol" style="display:none"></select>
              <div id="handleBlock">
                <select id="hmode" onchange="rules()">
                  <option value="factory">Handle from catalog</option>
                  <option value="client">Client-supplied</option>
                </select>
                <select id="handle"></select>
              </div>
              <div id="ptoNote" class="flag" style="display:none">Push-pull device code not found in source — P3, pending Elda. hardware_ref stays empty.</div>
            </fieldset>
            <fieldset id="hingeFs"><legend>Hinge side</legend>
              <select id="hinge">
                <option value="">— not chosen —</option>
                <option value="lh">Left (hinges left)</option>
                <option value="rh">Right (hinges right)</option>
              </select>
            </fieldset>
            <fieldset id="mountFs"><legend>Mounting</legend>
              <label><input type="checkbox" id="wallHung" onchange="rules()"> Wall-hung (no plinth)</label>
              <div id="mountNote" class="muted" style="margin:2px 0 0"></div>
            </fieldset>
            <button onclick="apply()">Apply</button>
          </div>
          <script>
            var HANDED=false, WALL_HUNG_REF='';
            function opt(s,items,sel){s.innerHTML='';items.forEach(function(it){
              var v=(it.value!==undefined&&it.value!==null)?it.value:it.code;
              var o=document.createElement('option');o.value=v;
              o.text=it.code?(it.code+' — '+it.name):it.name;
              if(v===sel)o.selected=true;s.add(o);});}
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
              // The surcharge article is shown only while the option is on, so
              // the code on screen is always the code that will be ordered.
              var wh=document.getElementById('wallHung').checked;
              document.getElementById('mountNote').textContent=
                wh?('Orders '+(WALL_HUNG_REF||'the wall-hung surcharge')+
                    ' — fixings, 240 kg per pair. The plinth is removed and the '+
                    'carcass keeps its worktop line.')
                  :'Stands on its plinth.';
            }
            function render(st){
              var has=st.attrs&&st.attrs.code;
              document.getElementById('empty').style.display=has?'none':'';
              document.getElementById('form').style.display=has?'':'none';
              if(!has)return;
              HANDED=!!st.handed;
              // Offered only where the catalog offers it. A wall unit already
              // hangs and an appliance front is bolted to the machine, so for
              // those the whole fieldset goes away rather than showing a
              // control that cannot be used.
              WALL_HUNG_REF=st.wall_hung_ref||'';
              document.getElementById('mountFs').style.display=
                st.wall_hung_available?'':'none';
              // From the CHOICE, never from the result - selection_state decides,
              // because a rule that lives only in HTML is not a rule.
              document.getElementById('wallHung').checked=!!st.wall_hung_chosen;
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
              opt(document.getElementById('gol'),st.gola_profiles,st.gola_system);
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
                     gola_system:gola?document.getElementById('gol').value:'',
                     hardware_ref:(!gola&&document.getElementById('hmode').value==='factory')
                                        ?document.getElementById('handle').value:'',
                     hinge_side:HANDED?document.getElementById('hinge').value:'',
                     wall_hung:document.getElementById('wallHung').checked};
              sketchup.apply(JSON.stringify(p));
            }
            window.onload=function(){sketchup.ready();};
          </script></body></html>
        HTML
      end
    end
  end
end

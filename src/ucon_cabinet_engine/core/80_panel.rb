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
      # DOES THIS OBJECT OPEN AT ALL? A shelf does not, and neither does a panel
      # or a filler. Until 0.95.0 the dialog offered every one of them a handle
      # and a push-to-open, because the fieldset was unconditional - Andriy saw
      # it on a shelf: "доступные опции ручки не нужны по определению."
      #
      # Asked of the FRONT LAYOUT and not of the class, because that is where the
      # answer already lives: `kind: none` is stated on exactly the things with
      # no front, and it was stated for a different reason - so that nothing
      # defaults a door onto them.
      def core_version
        CabinetEngine::CORE_VERSION
      rescue NameError
        nil
      end

      def opens?(unit)
        return false if unit.nil?
        return false if (unit['front_layout'] || {})['kind'].to_s == 'none'

        !unit['opening'].nil?
      end

      # THE LED RULE OF A SECTION, and the length it computes for THIS object.
      # printed p.224: the Sky-B fits on these shelves, the light is the shelf
      # minus 3 mm, and it stops at 3 metres. The rule is data on the section;
      # what varies is the shelf, so the arithmetic is done here and shown.
      def led_offer(unit, attrs)
        rule = section_led_rule(unit)
        return nil unless rule

        w = ((attrs || {})['width_mm'] || (unit || {})['width_mm']).to_f
        return nil unless w.positive?

        len = w - 3
        over = len > rule['max_light_length_mm'].to_f
        { 'lamp' => rule['lamp'], 'length_mm' => len.round,
          'max_mm' => rule['max_light_length_mm'],
          'over_max' => over,
          'depth_mm' => rule['lamp_position_in_depth_mm'],
          # THE TEMPERATURE, carried from the page to the panel to the drawing.
          # It is the fact about a lamp that most often arrives wrong, so it is
          # shown wherever there is room for it rather than only in the order.
          'temperature' => rule['colour_temperature_k'],
          'temperature_options' => rule['colour_temperature_options'],
          'label' => rule['label'],
          'source_ref' => rule['source_ref'],
          'lamp_source' => rule['lamp_source'] }
      end

      def section_led_rule(unit)
        return nil unless unit

        dir = File.expand_path('../../../registry/cesar', __dir__)
        Dir.glob(File.join(dir, '*.json')).each do |f|
          next if File.basename(f) == '_manifest.json'

          sec = JSON.parse(File.read(f))
          next unless sec['family'] == unit['family']

          rule = (sec['data'] || {})['led_rule']
          return rule if rule
        end
        nil
      rescue StandardError
        nil
      end

      def attributes_patch(unit, payload)
        # AN OBJECT THAT DOES NOT OPEN TAKES NONE OF WHAT FOLLOWS. Everything
        # below is about a front - the door version, the opening method, the
        # handle, the hinge - and a shelf has no front to ask about. It returns
        # early with the one choice it DOES have.
        unless opens?(unit)
          return led_patch(unit, payload)
        end

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
          # THE WALK LIVES IN THE GENERATOR NOW. This loop used to be written
          # out here and kept only the fronts, which quietly dropped anything
          # else in the stack. A 30 mm recess survived that treatment; a
          # RESERVATION does not - see Generator.slabs_from_stack.
          Generator.slabs_from_stack(stack, unit['width_mm'])
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
        # What this object can be ASKED, decided here rather than in the HTML -
        # same rule as wall_hung_available? below it.
        # What the LOADED core is, so the dialog can notice it was baked earlier.
        # GUARDED, because 00_version.rb is not in the headless suite's load
        # list: the suite exercises the pure half and a version string is not
        # part of it. nil simply means "cannot compare", and the banner then
        # never fires - which is the right answer, not a failure.
        state['core_version'] = core_version
        state['opens'] = opens?(unit)
        state['led'] = led_offer(unit, attrs)
        state['led_chosen'] =
          Array((attrs || {})['variants']).any? { |v| v['key'] == LED_VARIANT_KEY }
        state['led_temperature'] = led_temperature_of(attrs)
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

      # THE LIGHT IS A VARIANT, NOT A COMPANION LINE, and the difference is that we
      # cannot name the article. printed p.224 says the Sky-B fits and gives the
      # arithmetic; the lamp itself is priced in the KITCHEN SYSTEM at printed
      # p.526, which this registry does not hold. A companion line must carry a
      # code, and inventing one would be exactly the thing domain rule 1
      # forbids - so the object states the CHOICE and its size, with the page
      # that says so, and the order gets a line when that page is extracted.
      #
      # A variant may not carry what it costs (Contract v2 §4.2 and a check),
      # which is right here for the same reason: the points are in the other book.
      LED_VARIANT_KEY = 'led'

      # READ BACK OFF THE OBJECT, from the INSTRUCTION and not from the label.
      # The label is the short form for a drawing and it is deliberately allowed
      # to say 'LED 3000/4000K' when nothing was chosen - which a naive match
      # reads as 4000. 'SET TO 3000K' is the sentence that means a decision was
      # taken, so that is the one parsed. The first version got this wrong and a
      # check caught it before Andriy did.
      def led_temperature_of(attrs)
        v = Array((attrs || {})['variants']).find { |x| x['key'] == LED_VARIANT_KEY }
        return nil unless v

        m = v['value'].to_s.match(/SET TO (\d{4})K/)
        m && m[1]
      end

      def led_patch(unit, payload)
        offer = led_offer(unit, payload['attrs'] || {})
        others = Array((payload['attrs'] || {})['variants'])
                 .reject { |v| v['key'] == LED_VARIANT_KEY }
        return { 'variants' => others } unless payload['led'] && offer

        # UNREACHABLE TODAY, AND SAID SO RATHER THAN LEFT TO LOOK LIKE A GUARD
        # THAT WORKS. The shelf's own max.L is 300 cm and the light stops at the
        # same 300, so a light computed as the shelf less 3 can never exceed it.
        # The guard stays because the two limits come from different sentences on
        # different pages and either can move; a check pins the fact that it is
        # currently vacuous, so the day it stops being vacuous is visible.
        if offer['over_max']
          raise ArgumentError,
                "The light would be #{offer['length_mm']} mm and printed p.224 stops at " \
                "#{offer['max_mm']}. A shelf longer than #{offer['max_mm'].to_i + 3} mm " \
                'cannot be lit in one run; the page prints no second lamp rule.'
        end

        # THE TEMPERATURE IS A SETTING AND NOT A CODE, and it is validated here
        # rather than trusted from the dialog for the reason gola_available? is:
        # a rule that lives only in HTML is not a rule. Only what the page offers
        # may be chosen; anything else is refused by name.
        want = payload['led_temperature'].to_s
        allowed = Array(offer['temperature_options'])
        unless want.empty? || allowed.include?(want)
          raise ArgumentError,
                "#{want}K is not a temperature this lamp offers. printed p.528 gives " \
                "#{allowed.join(' and ')}, adjusted on site by the Emotion Dual Color device."
        end

        set = want.empty? ? nil : want
        { 'variants' => others + [{
          'key' => LED_VARIANT_KEY,
          'value' => "#{offer['lamp']} #{offer['length_mm']} mm - the shelf less 3, " \
                     "lamp #{offer['depth_mm']} in from the edge in depth. " \
                     "#{led_temperature_sentence(set, allowed)} " \
                     "NOT PRICED HERE: #{offer['lamp_source']}",
          # The short form, for the elevation. Contract v2.3 §1.4.
          'label' => led_short_label(offer, set),
          'source_ref' => offer['source_ref']
        }] }
      end

      # WHAT THE ORDER IS TOLD, and the unchosen case is the one that matters.
      # Nobody can be sent the wrong lamp - there is only one lamp - so the way
      # this goes wrong is that nobody says which temperature and the device is
      # left wherever it powers up. An empty choice therefore SAYS SO on the
      # object rather than staying quiet about it.
      def led_temperature_sentence(set, allowed)
        return "SET TO #{set}K on commissioning - a setting, not a code: the same " \
               'article is supplied either way.' if set

        "TEMPERATURE NOT SPECIFIED. The device adjusts #{allowed.join('/')}K and will be " \
          'left wherever it powers up unless somebody sets it.'
      end

      def led_short_label(offer, set)
        return "LED #{set}K" if set

        offer['label'] || 'LED'
      end

      # THE TURN BUTTONS ARE GONE, AND THAT IS A SIMPLIFICATION RATHER THAN A
      # RETREAT. They were added because an object could be built back-to-front
      # and there was no way to correct it. The real fix landed instead: the
      # light no longer takes a view on which side is the front (Symbols#led_y_mm
      # draws it under the middle of the board), so nothing in the drawing
      # depends on facing any more.
      #
      # And three quarter-turn buttons were the wrong tool anyway. Andriy:
      # "Я просто его разверну руками обычными инструментами со скетчапом. Потому
      # что стены могут быть под разными углами." A wall at 37 degrees is not
      # served by 90/180/270, and SketchUp's own rotate tool serves every angle.
      # A control that handles the easy quarter of the cases and silently fails
      # the rest is worse than no control: it looks like the answer.
      #
      # What stays is the placement rule that made facing right by CONSTRUCTION -
      # a shelf seats on the wall the selected cabinet is against, in that
      # cabinet's own frame (Generator#placement_transform). That was always the
      # better half of the fix.

      # Gives the instance a definition of its own when it is sharing one, and a
      # name in the engine's own convention rather than SketchUp's `…#1`, so the
      # outliner stays readable. A no-op when the instance is already alone.
      def make_instance_unique!(inst)
        return false if inst.definition.count_instances <= 1

        was = inst.definition.name
        inst.make_unique
        code = Contract.read(inst.definition)['code'].to_s
        stem = code.empty? ? was.split('_').first.to_s : "CESAR_#{code}"
        inst.definition.name = "#{stem}_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
        true
      rescue StandardError
        # A name is a nicety; the split itself is what matters and has happened.
        true
      end

      def apply(payload)
        inst = selected_unit_instance
        return UI.messagebox('Select a UCON unit first.') unless inst

        model = Sketchup.active_model
        attrs = Contract.read(inst.definition)
        unit  = Registry.lookup(attrs['code'])
        patch = attributes_patch(unit, payload)
        # `defn` is deliberately NOT read yet - make_unique below replaces it.
        # THE REGISTRY ROW IS NOT THIS OBJECT. Everything below asks the
        # generator where geometry goes, and the generator must be asked about
        # the unit AS CHOSEN - otherwise a base unit somebody has just hung is
        # redrawn standing on its plinth, and the drawing tells a lie the
        # order does not. Same shape as the gola pairing that went missing.
        chosen = Generator.effective(unit, attrs.merge(patch))

        # WHICH STEP FAILED, AND SAY SO. Until 0.96.1 this rescued, aborted and
        # re-raised - and a raise inside an HtmlDialog callback goes nowhere a
        # person will look. So a failure in ANY step after the write rolled the
        # write back too, in silence: Andriy ticked the light, pressed Apply,
        # came back and found an untouched object with no error anywhere. The
        # operation stays atomic, which is right - a half-applied unit is worse
        # than an unapplied one - but the failure now names its step and reaches
        # the screen.
        step = 'writing the attributes'
        model.start_operation('UCON: apply unit properties', true)
        begin
          # A COPY MADE BY HAND IS THE SAME OBJECT UNTIL SOMEBODY SAYS OTHERWISE.
          # Copy a unit in SketchUp and you get a second INSTANCE of one
          # DEFINITION - and every fact this engine keeps lives on the
          # definition. So editing either copy edited both: Andriy took the
          # light off one shelf and it came off the other.
          #
          # SketchUp is not wrong to share; this engine is wrong to let it.
          # A unit here is an ORDER LINE, and two order lines that cannot differ
          # in hinge side, mounting or light are not two lines. Every unit the
          # generator builds already gets its own definition; sharing only ever
          # arises from a hand copy, and this is the moment it has to end.
          #
          # INSIDE the operation, so one undo puts it back, and BEFORE `defn` is
          # read, because make_unique replaces the definition the instance points
          # at - reading it earlier would write to the one still being shared.
          # The same guard already existed in Generator#swap_corner_execution!,
          # with the same comment. It was never carried here.
          make_instance_unique!(inst)
          defn = inst.definition
          Contract.write!(defn, attrs.merge(patch))
          gola = patch['opening_method'] == 'gola'
          step = 'rebuilding the fronts'
          rebuild_fronts(model, defn, chosen, gola)
          step = 'rebuilding the plinth'
          rebuild_plinth(model, defn, chosen)
          step = 'drawing the symbols'
          Symbols.draw(model, defn, chosen,
                       patch['hinge_side'] || attrs['hinge_side'],
                       patch['front_height_mm'],
                       # `chosen`, not `unit`: effective_slabs reads the
                       # width, and on a filler the bare registry row has
                       # none. The same mistake as the line above it, one
                       # argument later.
                       effective_slabs(chosen, gola))
          model.commit_operation
        rescue StandardError => e
          model.abort_operation
          UI.messagebox("Nothing was applied.\n\nFailed while #{step}:\n#{e.class}: " \
                        "#{e.message}\n\nThe whole change was rolled back, including the " \
                        'attributes - one operation, so a half-applied unit is not possible.')
          return
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
          <div id="stale" style="display:none;margin:-4px 0 10px;padding:7px 9px;border-radius:6px;
               background:#fde68a;color:#7c2d12;font-size:12px;line-height:1.35"></div>
          <div id="empty">Select a UCON unit in the model</div>
          <div id="form" style="display:none">
            <h3 id="code"></h3><div class="muted" id="desc"></div>
            <fieldset id="dvFs"><legend>Door height</legend>
              <label><input type="radio" name="dv" value="78" checked onchange="rules()">
                <span id="dvFull">full front</span></label>
              <label><input type="radio" name="dv" value="75" onchange="rules()">
                <span id="dvGola">gola</span></label>
            </fieldset>
            <fieldset id="openFs"><legend>Opening</legend>
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
            <fieldset id="ledFs" style="display:none"><legend>Light</legend>
              <label style="display:flex;align-items:center;gap:6px;margin:0 0 4px">
                <input type="checkbox" id="led" onchange="rules()" style="margin:0;width:auto">
                <span>Integrated led</span></label>
              <div id="ledTempRow" style="display:none;margin:2px 0 0">
                <label style="display:block;margin:0 0 2px">Colour temperature</label>
                <select id="ledTemp" onchange="rules()"></select>
              </div>
              <div id="ledNote" class="muted" style="margin:2px 0 0"></div>
              <div id="ledTempWarn" class="flag" style="display:none"></div>
              <div id="ledWarn" class="flag" style="display:none"></div>
            </fieldset>
            <fieldset id="mountFs"><legend>Mounting</legend>
              <label><input type="checkbox" id="wallHung" onchange="rules()"> Wall-hung (no plinth)</label>
              <div id="mountNote" class="muted" style="margin:2px 0 0"></div>
            </fieldset>
            <button onclick="apply()">Apply</button>
          </div>
          <script>
            // STATE is the last thing render() was given. It exists because
            // apply() needs the object's CURRENT attributes to build a patch on
            // top of, and `st` is render's parameter and nothing else - reaching
            // for it from apply() throws a ReferenceError and the button then
            // does nothing at all, silently, for every unit in the model.
            // THE VERSION THIS HTML WAS BAKED UNDER. An HtmlDialog builds its
            // markup and its callbacks ONCE, at open, and Reload core does not
            // touch a window that is already up - CLAUDE.md has said so since
            // 0.23 and it has cost an evening more than once, most recently
            // 2026-08-27 when a fixed apply() sat on disk while the open panel
            // kept running the broken one and the button did nothing, silently.
            // So the dialog now compares what it was baked from with what is
            // loaded, and says so itself instead of leaving a person to guess.
            var BAKED='#{UCON::CabinetEngine::Panel.core_version}';
            var HANDED=false, WALL_HUNG_REF='', LED=null, STATE=null;
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
              // The length is COMPUTED and shown while the box is on, so the
              // number on screen is the number that reaches the object.
              if(LED){
                var on=document.getElementById('led').checked;
                var t=document.getElementById('ledTemp').value;
                document.getElementById('ledTempRow').style.display=on?'':'none';
                document.getElementById('ledNote').textContent = on
                  ? (LED.lamp+' '+LED.length_mm+' mm \u2014 the shelf less 3 mm, '+
                     LED.depth_mm+' in from the edge in depth. Priced in another book: '+
                     LED.lamp_source)
                  : 'No light. printed p.224 fits a '+LED.lamp+' on these shelves.';
                // THE ONE THING THAT ACTUALLY GOES WRONG. Nobody can be sent the
                // wrong lamp - there is only one lamp - so the failure is that
                // nobody says which temperature and the device is left wherever
                // it powers up. An unset choice is therefore a WARNING, not a
                // blank: silence is the defect.
                document.getElementById('ledTempWarn').style.display=(on&&!t)?'':'none';
                document.getElementById('ledTempWarn').textContent=
                  'No temperature set. The same article is supplied either way \u2014 '+
                  'so nothing can arrive wrong, but nothing tells the installer '+
                  'either, and the device stays wherever it powers up.';
                document.getElementById('ledWarn').style.display=(on&&LED.over_max)?'':'none';
                document.getElementById('ledWarn').textContent=
                  'The light would be '+LED.length_mm+' mm and the page stops at '+
                  LED.max_mm+'. Apply will refuse.';
              }
              var wh=document.getElementById('wallHung').checked;
              document.getElementById('mountNote').textContent=
                wh?('Orders '+(WALL_HUNG_REF||'the wall-hung surcharge')+
                    ' — fixings, 240 kg per pair. The plinth is removed and the '+
                    'carcass keeps its worktop line.')
                  :'Stands on its plinth.';
            }
            function render(st){
              STATE=st;
              if(st.core_version && st.core_version!==BAKED){
                var b=document.getElementById('stale');
                b.style.display='';
                b.textContent='This window was opened under core '+BAKED+
                  ' and '+st.core_version+' is loaded. An HtmlDialog bakes its '+
                  'markup and its callbacks at open, so Apply here is still the '+
                  'old one. Close this panel and open it again.';
              }
              var has=st.attrs&&st.attrs.code;
              document.getElementById('empty').style.display=has?'none':'';
              document.getElementById('form').style.display=has?'':'none';
              if(!has)return;
              HANDED=!!st.handed;
              // Offered only where the catalog offers it. A wall unit already
              // hangs and an appliance front is bolted to the machine, so for
              // those the whole fieldset goes away rather than showing a
              // control that cannot be used.
              // A SHELF HAS NOTHING TO OPEN. Offering it a handle was a control
              // that could not be used - the same fault the mounting fieldset
              // already avoids for a wall unit.
              document.getElementById('openFs').style.display=st.opens?'':'none';
              LED=st.led||null;
              document.getElementById('ledFs').style.display=LED?'':'none';
              document.getElementById('led').checked=!!st.led_chosen;
              // The options come from the PAGE, through led_rule, and never from
              // this file - a lamp with a 2700-6500 range offers that instead
              // without a line of JavaScript changing.
              if(LED){
                var ts=document.getElementById('ledTemp');
                ts.innerHTML='';
                var none=document.createElement('option');
                none.value='';none.textContent='\u2014 not set \u2014';ts.add(none);
                (LED.temperature_options||[]).forEach(function(k){
                  var o=document.createElement('option');
                  o.value=k;o.textContent=k+'K';
                  if(k===st.led_temperature)o.selected=true;ts.add(o);});
                if(!st.led_temperature)none.selected=true;
              }
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
                     led:document.getElementById('led').checked,
                     led_temperature:document.getElementById('ledTemp').value,
                     attrs:(STATE&&STATE.attrs)||{},
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

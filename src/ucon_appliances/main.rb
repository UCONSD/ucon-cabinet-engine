# frozen_string_literal: true
#
# UCON Appliances — the SketchUp layer.
#
# Every rule lives in lib/appliances.rb, which has no SketchUp in it and is
# covered by test_appliances.rb. This file draws, asks and writes attributes,
# and it is deliberately thin: if a decision is being made here rather than
# there, that is the bug.
#
# WHAT IT DRAWS
#   housing        a COMPONENT, neutral, tag UCON_APPLIANCE_OPENING
#   void above     a group, RED, tag UCON_APPLIANCE_VOID
#   service zones  groups, coloured by service, tag UCON_APPLIANCE_UTILITIES
#
# WHY THE HOUSING IS A COMPONENT AND NOT A GROUP
# UCON_Appliance_Register_v1 walks the model and yields ComponentInstances only
# (a Group is descended into but never handed to the block). A housing drawn as
# a group would be invisible to the schedule. It also writes the register's own
# six keys into the same UCON_APPLIANCE dictionary, so LIST OF APPLIANCES and
# the CSV export work with no change to that file at all.

require 'sketchup.rb'
require 'json'
require File.join(File.dirname(__FILE__), 'lib', 'appliances')

module UCON
  module AppliancesUI
    extend self

    A = UCON::Appliances

    DICT     = 'UCON_APPLIANCE'
    TAG_OPEN = 'UCON_APPLIANCE_OPENING'
    TAG_VOID = 'UCON_APPLIANCE_VOID'
    TAG_UTIL = 'UCON_APPLIANCE_UTILITIES'

    COLORS = {
      'housing' => [120, 160, 200], 'void' => [198, 58, 48],
      'power'   => [232, 178,  30], 'gas'  => [206,  92, 48],
      'water'   => [ 58, 132, 200], 'drain' => [110, 122, 138],
      'duct'    => [138, 104, 190]
    }.freeze

    ZONE_T = 25

    # ------------------------------------------------------------------ util

    def mm(v)
      v.to_f.mm
    end

    def material(model, name, rgb, alpha)
      m = model.materials[name] || model.materials.add(name)
      m.color = Sketchup::Color.new(*rgb)
      m.alpha = alpha
      m
    end

    def tag(model, name)
      model.layers[name] || model.layers.add(name)
    end

    def box_entities(ents, x, y, z, w, d, h, mat)
      f = ents.add_face([x, y, z], [x + w, y, z], [x + w, y + d, z], [x, y + d, z])
      return nil unless f

      f.reverse! if f.normal.z < 0
      f.pushpull(h)
      ents.grep(Sketchup::Face).each { |q| q.material = mat; q.back_material = mat }
      true
    end

    def group_box(model, name, x, y, z, w, d, h, mat)
      g = model.entities.add_group
      g.name = name
      return nil unless box_entities(g.entities, 0, 0, 0, w, d, h, mat)

      g.transform!(Geom::Transformation.new(Geom::Point3d.new(x, y, z)))
      g
    end

    # A definition per model+installation, so two identical housings in one
    # kitchen are two instances of one component and the schedule counts them.
    def component_box(model, defname, x, y, z, w, d, h, mat)
      defn = model.definitions[defname]
      unless defn
        defn = model.definitions.add(defname)
        box_entities(defn.entities, 0, 0, 0, w, d, h, mat)
      end
      model.entities.add_instance(defn, Geom::Transformation.new(Geom::Point3d.new(x, y, z)))
    end

    # ---------------------------------------------------------- the register
    #
    # A-01, A-02 … in placement order, skipping ids already used in the model,
    # so a second run beside a hand-assigned appliance does not collide.

    def next_register_id(model)
      used = []
      model.definitions.each do |d|
        d.instances.each { |i| used << i.get_attribute(DICT, 'ID') }
      end
      used.compact!
      n = 1
      n += 1 while used.include?(format('A-%02d', n))
      format('A-%02d', n)
    end

    def register_keys(rec, model_no, id)
      { 'ID'           => id,
        'Manufacturer' => rec['brand'].to_s.upcase,
        'Model'        => model_no,
        'Description'  => rec['product_name'] || rec['type'].to_s.tr('_', ' ').upcase,
        'Product_No'   => 'TBD',
        'Status'       => 'PRELIMINARY - from the manufacturer design guide' }
    end

    # ------------------------------------------------------------------ draw

    def place(model_no, installation: nil, front_system: 'handle', section_top_mm: 2200,
              origin: ORIGIN, quiet: false)
      su = Sketchup.active_model

      sub = A.for_front_system(model_no, front_system)
      unless sub['ok']
        UI.messagebox([sub['error'], '', 'What the catalogue offers instead:',
                       *sub['remedies'].map { |r| "  - #{[r['code'], r['what']].compact.join(': ')}" }].join("\n"))
        return nil
      end
      model_no = sub['model']

      rec = A.find(model_no) || A.find(sub['from'])
      inst = installation || A.default_installation(model_no) || 'standard'
      open = A.opening(model_no, inst)
      unless open
        UI.messagebox("#{model_no} has no published opening — it is not built into the cabinetry.")
        return nil
      end

      su.start_operation("Appliance housing #{model_no}", true)
      begin
        w = open['w']
        h = open['h']
        d = open['d'] || 610
        id = next_register_id(su)

        housing = component_box(
          su, "UCON_HOUSING_#{model_no.gsub(/[^A-Za-z0-9]/, '_')}_#{inst}",
          origin.x, origin.y, origin.z, mm(w), mm(d), mm(h),
          material(su, 'UCON_HOUSING', COLORS['housing'], 0.18)
        )
        housing.layer = tag(su, TAG_OPEN)
        housing.name = "#{id}_#{model_no}"

        notes = ['APPLIANCE HOUSING - KEEP CLEAR. Datum: floor.']
        notes << "Installation: #{inst.tr('_', ' ')}"
        notes << A.rules['filler']['reason'] if A.setback_for(model_no).positive?
        notes << "Filler plane: set back #{A.setback_for(model_no)} from the cabinet front." if A.setback_for(model_no).positive?
        notes << "Substituted for #{sub['from']} because the front system is gola." if sub['substituted']
        notes << "Source: #{open['source']}"

        attrs = register_keys(rec, model_no, id).merge(
          'BRAND' => rec['brand'], 'SERIES' => rec['series'], 'TYPE' => rec['type'],
          'INSTALL_CLASS' => rec['install_class'], 'INSTALLATION' => inst,
          'FRONT_SYSTEM' => front_system, 'DATUM' => 'floor',
          'OPENING_W_MM' => w, 'OPENING_H_MM' => h, 'OPENING_D_MM' => open['d'],
          'FILLER_SETBACK_MM' => A.setback_for(model_no),
          'MSRP_USD' => A.price(model_no),
          'SOURCE' => open['source'], 'NOTES' => notes.join(' | ')
        )
        attrs.each { |k, v| housing.set_attribute(DICT, k, v) }

        t = su.entities.add_text(([model_no] + notes).join("\n"),
                                 Geom::Point3d.new(origin.x + mm(w / 2.0), origin.y, origin.z + mm(h + 80)))
        t.layer = tag(su, TAG_OPEN) if t

        draw_void(su, model_no, inst, section_top_mm, origin, w, d)
        draw_zones(su, rec, model_no, origin, w, d)

        su.commit_operation
        su.selection.clear
        su.selection.add(housing)
        su.active_view.zoom(housing)
        report(model_no, inst, open, section_top_mm, sub) unless quiet
        housing
      rescue StandardError => e
        su.abort_operation
        UI.messagebox("Failed: #{e.message}")
        nil
      end
    end

    # Red, on its own tag, and NOT a component: the void is cabinetry to be
    # decided, not an appliance, and the schedule must never count it.
    def draw_void(su, model_no, inst, section_top_mm, origin, w, d)
      v = A.void(section_top_mm, model_no, inst)
      return unless v['applies'] && v['h'].to_f.positive?

      setback = A.setback_for(model_no)
      g = group_box(su, "VOID_ABOVE_#{model_no.gsub(/[^A-Za-z0-9]/, '_')}_#{v['h']}",
                    origin.x, origin.y + mm(setback), origin.z + mm(A.opening_h(model_no, inst)),
                    mm(w), mm(d - setback), mm(v['h']),
                    material(su, 'UCON_VOID_RED', COLORS['void'], 0.35))
      return unless g

      g.layer = tag(su, TAG_VOID)
      note = ["TO BE FILLED - #{v['h']} mm",
              "Offer: #{v['fill'].map { |f| f.tr('_', ' ') }.join(' or ')}, #{v['material']} material.",
              setback.positive? ? "PLANE: set back #{setback} from the cabinet front, on the appliance carcass." : nil].compact
      { 'VOID_H_MM' => v['h'], 'FILL_OPTIONS' => v['fill'].join(' | '),
        'FILL_MATERIAL' => v['material'], 'SETBACK_MM' => setback,
        'ABOVE_MODEL' => model_no, 'RUN_TOP_MM' => section_top_mm,
        'NOTES' => note.join(' | ') }.each { |k, val| g.set_attribute(DICT, k, val) }
      t = su.entities.add_text(note.join("\n"),
                               Geom::Point3d.new(origin.x + mm(w / 2.0), origin.y, origin.z + mm(section_top_mm + 100)))
      t.layer = tag(su, TAG_VOID) if t
    end

    def draw_zones(su, rec, model_no, origin, w, d)
      rec['services'].each do |s|
        next if s['datum_x'].to_s == 'none' || s['h'].nil?

        zw = s['w'] || w
        x0 = case s['datum_x']
             when 'right_side_of_opening' then w - s['x'].to_i - zw
             when 'left_side_of_opening'  then s['x'].to_i
             else 0
             end
        y0 = d - ZONE_T
        g = group_box(su, "ZONE_#{s['service'].upcase}_#{model_no.gsub(/[^A-Za-z0-9]/, '_')}",
                      origin.x + mm(x0), origin.y + mm(y0), origin.z + mm(s['y'].to_i),
                      mm(zw), mm(ZONE_T), mm(s['h']),
                      material(su, "UCON_ZONE_#{s['service'].upcase}", COLORS[s['service']] || [128, 128, 128], 0.55))
        next unless g

        g.layer = tag(su, TAG_UTIL)
        { 'SERVICE' => s['service'], 'SPEC' => s['spec'],
          'DATUM_X' => s['datum_x'].tr('_', ' '), 'DATUM_Y' => s['datum_y'],
          'GEOMETRY' => "#{zw} x #{s['h']}, #{s['x']} from #{s['datum_x'].tr('_', ' ')}, " \
                        "bottom #{s['y']} from floor",
          'NOTE' => s['note'], 'SOURCE' => s['source'] }.each { |k, v| g.set_attribute(DICT, k, v) }
        t = su.entities.add_text(s['service'].upcase,
                                 Geom::Point3d.new(origin.x + mm(x0 + zw / 2.0), origin.y + mm(y0),
                                                   origin.z + mm(s['y'].to_i + s['h'])))
        t.layer = tag(su, TAG_UTIL) if t
      end
    end

    def report(model_no, inst, open, top, sub)
      v = A.void(top, model_no, inst)
      lines = ["#{model_no} — #{inst.tr('_', ' ')}",
               "Opening #{open['w']} x #{open['h']} x #{open['d'] || '?'} mm, from the floor.",
               '']
      lines << "Substituted for #{sub['from']}: the front system is gola." if sub['substituted']
      if v['applies'] && v['h'].to_f.positive?
        lines << "Void above: #{v['h']} mm — offer #{v['fill'].map { |f| f.tr('_', ' ') }.join(' or ')}."
      elsif v['error']
        lines << "WARNING: #{v['error']}."
      end
      UI.messagebox(lines.join("\n"))
    end

    # ------------------------------------------------------------- whole set

    def place_set(key, front_system: 'handle', section_top_mm: 2200)
      s = A.set(key) or return
      su = Sketchup.active_model
      x = 0.0
      placed = 0
      skipped = []
      s['items'].each do |it|
        it['qty'].to_i.times do
          sub = A.for_front_system(it['model'], front_system)
          unless sub['ok']
            skipped << sub['error']
            next
          end
          mn = sub['model']
          open = A.opening(mn)
          unless open
            skipped << "#{mn} — no opening (not built in)"
            next
          end
          place(it['model'], front_system: front_system, section_top_mm: section_top_mm,
                origin: Geom::Point3d.new(mm(x), 0, 0), quiet: true)
          x += open['w'] + 100
          placed += 1
        end
      end
      su.active_view.zoom_extents
      t = A.set_total(key)
      msg = ["Set #{s['cooking_width_in']}\" #{s['level']}: #{placed} housings placed.", '',
             "List #{format('$%s', t['total_usd'].to_i)} · rebate #{format('$%s', t['rebate_usd'])} · " \
             "net #{format('$%s', t['net_usd'].to_i)}",
             'US list MSRP, snapshot ' + A.prices['snapshot'] + '. Not supplied by UCON.']
      unless skipped.empty?
        msg << ''
        msg << 'Not placed:'
        skipped.uniq.each { |k| msg << "  - #{k}" }
      end
      UI.messagebox(msg.join("\n"))
    end

    def clear
      su = Sketchup.active_model
      su.start_operation('Clear appliance housings', true)
      begin
        tags = [TAG_OPEN, TAG_VOID, TAG_UTIL]
        su.entities.to_a.each do |e|
          next unless e.respond_to?(:layer) && e.layer && tags.include?(e.layer.name)

          e.erase! if e.valid?
        end
        su.commit_operation
      rescue StandardError => e
        su.abort_operation
        UI.messagebox(e.message)
      end
    end
  end
end

require File.join(File.dirname(__FILE__), 'ui_panel')

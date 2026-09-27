# frozen_string_literal: true
#
# tools/tangram_place.rb - draws a Tangram CURVED module as a planning volume,
# from the plan the registry holds. Dev tool beside module_grid.rb: nothing in
# src/ requires it and it never goes into an .rbz.
#
#   load '/Users/demchenkoandrew/dev/ucon-cabinet-engine/tools/tangram_place.rb'
#
# Extensions > UCON > Tangram: place module. Pick the code and the hand; the
# module appears at the origin: plinth on the floor, carcass on top, the height
# from its family (H.84 on 60, or H.138). Move it into place.
#
# WHY A TOOL AND NOT THE ENGINE: the engine's builder makes boxes, and a box is
# the wrong shape for a curve. The curve now exists as data -
# registry/cesar/tangram_h84.json -> unit_types -> plan_geometry - MEASURED
# FROM THE BROCHURE'S VECTOR PLAN (trust stated there, about +/-10 mm). This
# draws that plan, marks itself PRELIMINARY, and writes no Contract attribute,
# so nothing downstream mistakes it for a confirmed cabinet.
#
# THE OUTLINE IS THE CARCASS. The 22 mm front stands outside it and is drawn
# as a thin skin on the curved face only when "front" is asked for.

require 'json'

module UCON
  module TangramPlace
    DICT = 'UCON_TANGRAM'
    TAG  = 'UCON_TANGRAM_PRELIMINARY'
    DIR  = File.expand_path('../registry/cesar', __dir__)
    FILES = %w[tangram_h84.json tangram_h138.json].freeze

    module_function

    def mm(v)
      v.to_f.mm
    end

    # code => { 'label', 'height', 'plinth', 'outline', 'geometry', 'source' }
    def catalogue
      @catalogue ||= FILES.each_with_object({}) do |f, h|
        doc = JSON.parse(File.read(File.join(DIR, f)))
        fam = doc['data']
        fam['unit_types'].each_value do |t|
          g = t['plan_geometry'] or next
          t['codes'].each do |c|
            h[c['code']] = { 'label' => t['description'].split(' - ').first,
                             'height' => fam['height_mm'], 'plinth' => fam['plinth_h_mm'],
                             'outline' => g['outline_mm'], 'geometry' => g }
          end
        end
      end
    end

    def reload!
      @catalogue = nil
      catalogue
    end

    def material(model, name, rgb, alpha)
      m = model.materials[name] || model.materials.add(name)
      m.color = Sketchup::Color.new(*rgb)
      m.alpha = alpha
      m
    end

    def solid(ents, pts2d, z0, h, mat, name)
      g = ents.add_group
      g.name = name
      pts = pts2d.map { |x, y| Geom::Point3d.new(mm(x), mm(y), mm(z0)) }
      f = g.entities.add_face(pts)
      f.reverse! if f.normal.z < 0
      f.pushpull(mm(h))
      g.entities.grep(Sketchup::Face).each { |fc| fc.material = mat; fc.back_material = mat }
      g
    end

    def place(code, mirrored)
      rec = catalogue[code] or return UI.messagebox("#{code} has no plan in the registry.")
      model = Sketchup.active_model
      pts = rec['outline'].map { |x, y| [x.to_f, y.to_f] }
      if mirrored
        w = pts.map(&:first).max
        pts = pts.map { |x, y| [w - x, y] }.reverse
      end
      model.start_operation("Tangram #{code}", true)
      grp = model.active_entities.add_group
      grp.name = "#{code} #{rec['label']}#{mirrored ? ' (mirrored)' : ''} - PRELIMINARY"
      grp.layer = model.layers[TAG] || model.layers.add(TAG)
      m_pl  = material(model, 'UCON_TANGRAM_PLINTH', [70, 72, 76], 0.95)
      m_car = material(model, 'UCON_TANGRAM_CARCASS', [196, 170, 140], 0.9)
      solid(grp.entities, pts, 0, rec['plinth'], m_pl, 'plinth')
      solid(grp.entities, pts, rec['plinth'], rec['height'], m_car, 'carcass')
      { 'code' => code, 'label' => rec['label'], 'hand' => mirrored ? 'mirrored' : 'as drawn',
        'height_mm' => rec['height'], 'plinth_h_mm' => rec['plinth'],
        'trust' => rec['geometry']['trust'], 'source' => rec['geometry']['source'],
        'status' => 'PRELIMINARY - curve measured from the brochure, factory confirmation owed' }
        .each { |k, v| grp.set_attribute(DICT, k, v) }
      model.commit_operation
      model.selection.clear
      model.selection.add(grp)
      puts "Tangram: placed #{code} (#{rec['label']}), #{rec['height']} on #{rec['plinth']}#{mirrored ? ', mirrored' : ''}."
      grp
    rescue StandardError => e
      model&.abort_operation
      UI.messagebox("Tangram place failed: #{e.class}: #{e.message}")
      nil
    end

    def ask
      codes = catalogue.keys
      labels = codes.map { |c| "#{c}  #{catalogue[c]['label']}" }
      res = UI.inputbox(['Module', 'Hand'], [labels.first, 'as drawn'],
                        [labels.join('|'), 'as drawn|mirrored'], 'UCON Tangram - place module')
      return unless res

      place(codes[labels.index(res[0])], res[1] == 'mirrored')
    end

    unless defined?(@loaded)
      menu = UCON.respond_to?(:extensions_menu) ? UCON.extensions_menu : UI.menu('Extensions').add_submenu('UCON')
      menu.add_item('Tangram: place module') { ask }
      @loaded = true
    end
    reload!
    puts "UCON Tangram placer loaded: #{catalogue.size} curved/straight modules with a plan. Extensions > UCON > Tangram: place module."
  end
end

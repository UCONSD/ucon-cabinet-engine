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
# THE OUTLINE IS THE CARCASS. Drawn the way the box builder draws a cabinet:
# the 22 mm front 3 mm off the curved face, the plinth an 18 mm board 45 mm
# behind it following the curve, the engine's materials, black edges, and
# the arc's facet edges softened so the curve reads as a surface.
# Door height = carcass height (840); gola is not cut here.

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

    # ---- the engine's look ----------------------------------------------
    # Same materials, same numbers as the box builder (core/10_standards.rb),
    # so a Tangram module reads as one more cabinet in the run. Copied, not
    # read, so this tool never reaches into the engine; test_contract pins
    # them to the Standards so the two cannot drift.
    FRONT_T_MM        = 22.0 # FRONT_T_MM
    FRONT_GAP_MM      = 3.0  # FRONT_GAP_MM
    PLINTH_T_MM       = 18.0 # PLINTH_T_MM
    PLINTH_SETBACK_MM = 45.0 # PLINTH_SETBACK_MM, behind the carcass front

    def front_t;   FRONT_T_MM;        end
    def front_gap; FRONT_GAP_MM;      end
    def plinth_t;  PLINTH_T_MM;       end
    def setback;   PLINTH_SETBACK_MM; end

    def material(model, name, rgb)
      model.materials[name] || model.materials.add(name).tap { |m| m.color = Sketchup::Color.new(*rgb) }
    end

    # ---- plan geometry (pure Ruby, tested without SketchUp) ----------------
    TOL = 0.5

    # The FRONT of the carcass: the outline minus the straight back (y = 0)
    # and the straight sides (x = 0, x = w). What is left is the curve - plus,
    # on B, the short straight run that belongs to it - and it is the face the
    # door stands on and the plinth follows.
    def front_chain(pts)
      w = pts.map(&:first).max
      n = pts.size
      structural = (0...n).map do |i|
        a = pts[i]
        b = pts[(i + 1) % n]
        (a[1].abs < TOL && b[1].abs < TOL) ||
          ((a[0] - b[0]).abs < TOL && (a[0].abs < TOL || (a[0] - w).abs < TOL))
      end
      first = (0...n).find { |i| !structural[i] && structural[(i - 1) % n] }
      raise ArgumentError, 'outline has no front' unless first

      chain = [pts[first]]
      i = first
      until structural[i % n]
        chain << pts[(i + 1) % n]
        i += 1
        raise ArgumentError, 'front does not close' if i - first > n
      end
      # the straight side or back each end of the curve dies into
      @sides = [[pts[(first - 1) % n], pts[first]], [pts[i % n], pts[(i + 1) % n]]]
      chain
    end

    # Where line p + t*u meets the line through a-b; nil when parallel.
    def meet(p, u, a, b)
      v = [b[0] - a[0], b[1] - a[1]]
      den = u[0] * v[1] - u[1] * v[0]
      return nil if den.abs < 1e-9

      t = ((a[0] - p[0]) * v[1] - (a[1] - p[1]) * v[0]) / den
      [p[0] + u[0] * t, p[1] + u[1] * t]
    end

    def signed_area(pts)
      pts.each_with_index.sum { |a, i| b = pts[(i + 1) % pts.size]; a[0] * b[1] - b[0] * a[1] } / 2.0
    end

    # Offset a polyline by d along the outline's OUTWARD normal (d < 0 goes
    # inward), mitred at each joint so the band keeps its thickness.
    def offset(chain, d, ccw, sides = nil)
      normals = chain.each_cons(2).map do |a, b|
        dx = b[0] - a[0]
        dy = b[1] - a[1]
        l = Math.hypot(dx, dy)
        ccw ? [dy / l, -dx / l] : [-dy / l, dx / l]
      end
      chain.each_with_index.map do |p, i|
        na = normals[[i - 1, 0].max]
        nb = normals[[i, normals.size - 1].min]
        mx = na[0] + nb[0]
        my = na[1] + nb[1]
        ml = Math.hypot(mx, my)
        mx /= ml
        my /= ml
        k = d / (mx * na[0] + my * na[1])
        [p[0] + mx * k, p[1] + my * k]
      end.then { |o| sides ? trim_ends(o, sides, ccw) : o }
    end

    # An end is not cut square to the curve. Each end of an offset line is
    # brought to the side (or back) the carcass ends on: cut back where it
    # overshoots it, run on along its last segment where it falls short. So
    # the board and the door stop in the carcass's own side plane, and the
    # plinth never pokes out behind the back.
    def trim_ends(o, sides, ccw)
      o = o.dup
      [[sides[0], false], [sides[1], true]].each do |(a, b), tail|
        o.reverse! if tail
        side = ->(p) { ((b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])) * (ccw ? 1 : -1) }
        o.shift while o.size > 2 && side.(o[0]) < 0 && side.(o[1]) < 0
        u = [o[0][0] - o[1][0], o[0][1] - o[1][1]]
        hit = meet(o[1], u, a, b)
        o[0] = hit if hit
        o.reverse! if tail
      end
      o
    end

    # A band between two offsets of the front: the door (3 .. 25 out) or the
    # plinth board (45 .. 63 in).
    def band(chain, d0, d1, ccw, sides = nil)
      offset(chain, d0, ccw, sides) + offset(chain, d1, ccw, sides).reverse
    end

    def clean(pts)
      out = pts.map { |x, y| [x.to_f, y.to_f] }.each_with_object([]) do |p, a|
        a << p unless a.last && Math.hypot(p[0] - a.last[0], p[1] - a.last[1]) < 0.01
      end
      out.pop if Math.hypot(out[0][0] - out[-1][0], out[0][1] - out[-1][1]) < 0.01
      out
    end

    # carcass / front / plinth outlines in plan, for a module and a hand
    def plan_parts(outline, mirrored)
      pts = clean(outline)
      if mirrored
        w = pts.map(&:first).max
        pts = pts.map { |x, y| [w - x, y] }.reverse
      end
      ccw = signed_area(pts) > 0
      chain = front_chain(pts)
      sides = @sides
      { carcass: pts,
        front: band(chain, front_gap, front_gap + front_t, ccw, sides),
        plinth: band(chain, -setback, -(setback + plinth_t), ccw, sides) }
    end

    # ---- SketchUp ----------------------------------------------------------
    SMOOTH_DEG = 30

    def prism(ents, name, pts2d, z0, h, mat)
      g = ents.add_group
      g.name = name
      f = g.entities.add_face(pts2d.map { |x, y| Geom::Point3d.new(mm(x), mm(y), mm(z0)) })
      raise "Face creation failed for #{name}" unless f

      f.reverse! if f.normal.z < 0
      f.pushpull(mm(h))
      g.material = mat
      edge_mat = material(ents.model, 'UCON_Edge_Black', [0, 0, 0])
      g.entities.grep(Sketchup::Edge).each do |e|
        e.material = edge_mat
        fs = e.faces
        next unless fs.size == 2 && fs[0].normal.angle_between(fs[1].normal) < SMOOTH_DEG.degrees

        e.soft = true   # the arc is a surface, not a row of facets
        e.smooth = true
      end
      g
    end

    def hide_vertical_edges(g)
      g.entities.grep(Sketchup::Edge).each do |e|
        v = e.end.position - e.start.position
        e.hidden = true if v.x.abs < 0.5.mm && v.y.abs < 0.5.mm && v.z.abs > 0.5.mm
      end
    end

    def place(code, mirrored)
      rec = catalogue[code] or return UI.messagebox("#{code} has no plan in the registry.")
      model = Sketchup.active_model
      parts = plan_parts(rec['outline'], mirrored)
      pl = rec['plinth'].to_f
      h  = rec['height'].to_f
      model.start_operation("Tangram #{code}", true)
      grp = model.active_entities.add_group
      grp.name = "#{code} #{rec['label']}#{mirrored ? ' (mirrored)' : ''} - PRELIMINARY"
      grp.layer = model.layers[TAG] || model.layers.add(TAG)
      plinth = prism(grp.entities, 'PLINTH', parts[:plinth], 0, pl,
                     material(model, 'UCON_Plinth_White', [245, 245, 245]))
      hide_vertical_edges(plinth)
      prism(grp.entities, 'CARCASS', parts[:carcass], pl, h,
            material(model, 'UCON_Carcass_Light_Gray', [220, 220, 216]))
      prism(grp.entities, 'FRONT', parts[:front], pl, h,
            material(model, 'UCON_Front_White', [245, 245, 245]))
      { 'code' => code, 'label' => rec['label'], 'hand' => mirrored ? 'mirrored' : 'as drawn',
        'height_mm' => h, 'plinth_h_mm' => pl,
        'front_mm' => "#{front_t} at #{front_gap} off the carcass",
        'plinth_board_mm' => "#{plinth_t} at #{setback} behind the carcass front",
        'trust' => rec['geometry']['trust'], 'source' => rec['geometry']['source'],
        'status' => 'PRELIMINARY - curve measured from the brochure, factory confirmation owed' }
        .each { |k, v| grp.set_attribute(DICT, k, v) }
      model.commit_operation
      model.selection.clear
      model.selection.add(grp)
      puts "Tangram: placed #{code} (#{rec['label']}), #{h.round} on #{pl.round}#{mirrored ? ', mirrored' : ''}."
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

    if defined?(Sketchup) && !defined?(@loaded)
      menu = UCON.respond_to?(:extensions_menu) ? UCON.extensions_menu : UI.menu('Extensions').add_submenu('UCON')
      menu.add_item('Tangram: place module') { ask }
      @loaded = true
    end
    if defined?(Sketchup)
      reload!
      puts "UCON Tangram placer loaded: #{catalogue.size} curved/straight modules with a plan. Extensions > UCON > Tangram: place module."
    end
  end
end

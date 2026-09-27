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
#
# THE OPENING is drawn by the engine's rule, on the engine's three dashed
# tags, so the palette's plan / front / door / off buttons switch it with
# every other unit: a V on the door face, the leaf swung out 85 degrees with
# the arc of its free edge in plan, and the open leaf in space. C has two
# doors (the registry says so) and opens as a pair; the others take the
# Hinge asked for - left or right as seen standing in front of the door.
#
# F, THE FIXED END, is in the list too, and it is not a registry unit: the
# book prints no F. Drawn from the brochure plan: carcass, a fixed 22 mm
# facade 3 mm off it in two pieces with the joint at the curve, and a plinth
# round the corner - no door, nothing opens.

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
            # the door count is the registry's ('2 doors' on C), not guessed
            doors = (t['interior_confirmed'] || []).any? { |l| l =~ /\A2 doors/ } ? 2 : 1
            h[c['code']] = { 'label' => t['description'].split(' - ').first,
                             'height' => fam['height_mm'], 'plinth' => fam['plinth_h_mm'],
                             'outline' => g['outline_mm'], 'geometry' => g, 'doors' => doors }
          end
        end
      end.merge('F' => fixed_f)
    end

    # ---- F: the fixed end - NOT a registry unit ---------------------------
    # The Kitchen System prints no F: no code, no price (whole text searched
    # 2026-09-27). It exists only on the brochure's vector plan (PDF p.6), and
    # Andriy (2026-09-27): F is a FIXED element - no door, nothing opens. So it
    # lives here and not in registry/cesar, where a unit without a printed
    # code would be an invented catalog fact (domain rule 1).
    #
    # AS THE BROCHURE DRAWS IT (Andriy, 2026-09-27, on the p.6 crop), in its
    # own frame - y = 0 is the rounded face, the FRONT (flush with the M
    # doors), and y = F_D the back:
    #   FACADE  - 22 mm, 3 mm off the carcass like every front, in TWO pieces
    #             with a joint where the straight side meets the curve: a
    #             straight panel up the side x = 0, and a curved panel round
    #             the R200 corner and along y = 0 to the far side;
    #   CARCASS - behind it, 620 deep like a d.62 Maxima, the corner
    #             concentric at R175, a back panel 85 short of F_D and its
    #             18 mm side (x 282..300) running on to F_D, as the facade's
    #             side does;
    #   PLINTH  - 45 behind the carcass front, round the corner.
    # A SOLID panel and not a door as far as the drawing shows - to confirm
    # with Elda. Overall 300 x 645; at 640 the pieces lay within 7.2 mm of
    # the brochure outline (Hausdorff, measured 2026-09-27).
    # Height: the H.84 family's 840 on 60, ASSUMED - the brochure also shows F
    # at the ends of wall runs (d.35) and tall runs (d.35-67).
    # F_D IS 645, NOT THE 640 MEASURED OFF THE DRAWING. Placed in
    # Tangram_test.skp beside a Maxima BL0601 (2026-09-27), backs aligned, F's
    # face stood 5 mm behind the Maxima door plane: the brochure's 641 is a
    # drawing, and F stands in a d.62 run - 620 carcass + 3 gap + 22 front.
    F_W, F_D, F_R = 300.0, 645.0, 200.0
    F_BACK_Y  = F_D - 85.0 # the carcass back; the sides run on 85 past it
    F_SIDE_T  = 18.0  # the carcass side that runs on to F_D

    # quarter arc about the corner centre (F_R, F_R), from the side (x = c)
    # to the face (y = c); ends included
    def f_arc(r, seg = 24)
      (0..seg).map do |i|
        a = Math::PI + i * (Math::PI / 2) / seg
        [F_R + r * Math.cos(a), F_R + r * Math.sin(a)]
      end
    end

    def fixed_f
      outline = f_arc(F_R) + [[F_W, 0.0], [F_W, F_D], [0.0, F_D]]
      { 'label' => 'Tangram F - fixed rounded end (NO CODE in the book)',
        'height' => 840, 'plinth' => 60, 'doors' => 0, 'fixed' => true,
        'outline' => outline,
        'geometry' => { 'trust' => 'ILLUSTRATION - measured from the brochure plan, no printed dimension, no code',
                        'source' => 'folder-kitchen-planning-2026 PDF p.6 (vector plan)' } }
    end

    # carcass, the two facade pieces and the plinth, in mm
    def fixed_parts(_rec, mirrored)
      t = front_t
      c = front_gap + front_t # carcass face, 25 in from the facade face
      r_in = F_R - t
      r_c  = F_R - c
      side_panel = [[0.0, F_R], [t, F_R], [t, F_D], [0.0, F_D]]
      curved = f_arc(F_R) + [[F_W, 0.0], [F_W, t]] + f_arc(r_in).reverse
      carcass_face = [[c, F_BACK_Y]] + f_arc(r_c) + [[F_W, c]]
      carcass = carcass_face + [[F_W, F_D], [F_W - F_SIDE_T, F_D], [F_W - F_SIDE_T, F_BACK_Y]]
      polys = { carcass: carcass, fronts: [side_panel, curved], face: carcass_face }
      if mirrored
        flip = ->(pl) { pl.map { |x, y| [F_W - x, y] }.reverse }
        polys = { carcass: flip.(carcass), fronts: [flip.(side_panel), flip.(curved)], face: flip.(carcass_face) }
      end
      polys[:carcass] = clean(polys[:carcass])
      ccw = signed_area(polys[:carcass]) > 0
      polys.merge(plinth: band(polys[:face], -setback, -(setback + plinth_t), ccw))
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
      [[sides[0], false], [sides[1], true]].each do |side_ab, tail|
        next unless side_ab # a split between two leaves is cut square

        a, b = side_ab
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
      { carcass: pts, chain: chain, ccw: ccw, sides: sides,
        front: band(chain, front_gap, front_gap + front_t, ccw, sides),
        plinth: band(chain, -setback, -(setback + plinth_t), ccw, sides) }
    end

    # ---- the doors and how they open -------------------------------------
    # The engine's opening convention, bent onto the curve (core/70_symbols):
    #   front tag - a V on the door face, 1 mm proud: base at the hinge edge,
    #               apex at mid-height of the opening edge;
    #   plan tag  - the leaf swung out DOOR_OPEN_DEG about its hinge, plus the
    #               swing arc of its free edge, 1 mm off the floor;
    #   door tag  - the open leaf in space, as a wireframe.
    # A curved door turns on hinges like a flat one; the leaf keeps its curve.
    DOOR_OPEN_DEG = 85.0  # Symbols::DOOR_OPEN_ANGLE_DEG
    PLAN_Z_MM     = 1.0   # Symbols::PLAN_Z_MM
    TAG_FRONT = 'UCON — Opening (front)' # Symbols::TAG_FRONT
    TAG_PLAN  = 'UCON — Opening (plan)'  # Symbols::TAG_PLAN
    TAG_DOOR  = 'UCON — Opening (door)'  # Symbols::TAG_DOOR

    def arc_lengths(pl)
      pl.each_cons(2).each_with_object([0.0]) { |(a, b), acc| acc << acc.last + Math.hypot(b[0] - a[0], b[1] - a[1]) }
    end

    # Split a chain at half its length (C's two doors), the cut point shared.
    def split_half(chain)
      acc = arc_lengths(chain)
      half = acc.last / 2.0
      i = acc.index { |l| l >= half }
      a = chain[i - 1]
      b = chain[i]
      t = (half - acc[i - 1]) / (acc[i] - acc[i - 1])
      m = [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]
      return [chain[0..i], chain[i..]] if t > 0.999 # the half falls on a vertex
      return [chain[0...i], chain[i - 1..]] if t < 0.001

      [chain[0...i] + [m], [m] + chain[i..]]
    end

    # the outward normal where the curve is half-way along
    def mid_normal(chain, ccw)
      acc = arc_lengths(chain)
      i = acc.index { |l| l >= acc.last / 2.0 }
      a = chain[i - 1]
      b = chain[i]
      l = Math.hypot(b[0] - a[0], b[1] - a[1])
      ccw ? [(b[1] - a[1]) / l, -(b[0] - a[0]) / l] : [-(b[1] - a[1]) / l, (b[0] - a[0]) / l]
    end

    def rotate(p, c, ang)
      dx = p[0] - c[0]
      dy = p[1] - c[1]
      [c[0] + dx * Math.cos(ang) - dy * Math.sin(ang), c[1] + dx * Math.sin(ang) + dy * Math.cos(ang)]
    end

    # One entry per leaf, in mm, drawing nothing. hinge: 'lh' | 'rh' as seen
    # standing in front of the door (ignored for a pair: left leaf lh, right rh).
    def door_leaves(parts, doors, hinge)
      chain = parts[:chain]
      ccw = parts[:ccw]
      sides = parts[:sides]
      subs = doors == 2 ? split_half(chain) : [chain]
      leaf_sides = doors == 2 ? [[sides[0], nil], [nil, sides[1]]] : [sides]
      # the viewer's left, facing the door from outside at mid-curve
      n = mid_normal(chain, ccw)
      left = [n[1], -n[0]]
      lval = ->(p) { p[0] * left[0] + p[1] * left[1] }

      subs.each_with_index.map do |sub, i|
        sd = leaf_sides[i]
        inner = offset(sub, front_gap, ccw, sd)
        outer = offset(sub, front_gap + front_t, ccw, sd)
        proud = offset(sub, front_gap + front_t + 1, ccw, sd)
        first_is_left = lval.(sub.first) > lval.(sub.last)
        h = doors == 2 ? (i.zero? == first_is_left ? 'lh' : 'rh') : hinge
        # hinge end first
        at_first = (h == 'lh') == first_is_left
        inner, outer, proud = [inner, outer, proud].map { |pl| at_first ? pl : pl.reverse }
        piv = outer.first
        free = outer.last
        v = [free[0] - piv[0], free[1] - piv[1]]
        # the free edge starts OUT, along the leaf's own outward normal: a
        # small turn +a moves it along (-vy, vx)
        ln = mid_normal(sub, ccw)
        ang = ((-v[1] * ln[0] + v[0] * ln[1]) > 0 ? 1 : -1) * DOOR_OPEN_DEG * Math::PI / 180
        band_pts = inner + outer.reverse
        acc = arc_lengths(proud)
        { hinge: h, band: band_pts, pivot: piv, free: free, angle: ang,
          open_band: band_pts.map { |p| rotate(p, piv, ang) },
          radius: Math.hypot(v[0], v[1]),
          proud: proud, proud_s: acc.map { |l| l / acc.last } }
      end
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

    def symbol_tag(model, name)
      layer = model.layers[name] || model.layers.add(name)
      if layer.respond_to?(:line_style=) && model.respond_to?(:line_styles)
        want = model.line_styles['Dash']
        layer.line_style = want if want && layer.line_style != want
      end
      layer
    end

    def pt(x, y, z)
      Geom::Point3d.new(mm(x), mm(y), mm(z))
    end

    def symbol_group(ents, name, layer, mat)
      g = ents.add_group
      g.name = name
      yield g.entities
      g.entities.grep(Sketchup::Face).each(&:erase!)
      g.layer = layer
      g.entities.grep(Sketchup::Edge).each { |e| e.layer = layer; e.material = mat }
      g
    end

    def draw_symbols(ents, leaves, z0, h)
      model = ents.model
      mat = material(model, 'UCON_Symbol_Gray', [128, 128, 128])
      model.rendering_options['EdgeColorMode'] = 0 rescue nil
      t_front = symbol_tag(model, TAG_FRONT)
      t_plan  = symbol_tag(model, TAG_PLAN)
      t_door  = symbol_tag(model, TAG_DOOR)
      leaves.each_with_index do |lf, i|
        n = i + 1
        # V on the curved face - curves, so the dash runs on across the bend
        symbol_group(ents, "SYM_FRONT_#{n}", t_front, mat) do |e|
          e.add_curve(lf[:proud].zip(lf[:proud_s]).map { |(x, y), f| pt(x, y, z0 + f * h / 2.0) })
          e.add_curve(lf[:proud].zip(lf[:proud_s]).map { |(x, y), f| pt(x, y, z0 + h - f * h / 2.0) })
        end
        # plan: the open leaf and the swing arc of its free edge
        symbol_group(ents, "SYM_PLAN_#{n}", t_plan, mat) do |e|
          ring = lf[:open_band] + [lf[:open_band].first]
          e.add_curve(ring.map { |x, y| pt(x, y, PLAN_Z_MM) })
          c = pt(lf[:pivot][0], lf[:pivot][1], PLAN_Z_MM)
          xa = Geom::Vector3d.new(lf[:free][0] - lf[:pivot][0], lf[:free][1] - lf[:pivot][1], 0)
          a0, a1 = [0.0, lf[:angle]].minmax
          e.add_arc(c, xa, Geom::Vector3d.new(0, 0, 1), mm(lf[:radius]), a0, a1, 12)
        end
        # the open leaf in space
        symbol_group(ents, "SYM_DOOR_#{n}", t_door, mat) do |e|
          ob = lf[:open_band]
          [z0, z0 + h].each { |z| e.add_curve((ob + [ob.first]).map { |x, y| pt(x, y, z) }) }
          m = ob.size / 2
          [0, m - 1, m, ob.size - 1].each { |k| e.add_line(pt(ob[k][0], ob[k][1], z0), pt(ob[k][0], ob[k][1], z0 + h)) }
        end
      end
    end

    def hide_vertical_edges(g)
      g.entities.grep(Sketchup::Edge).each do |e|
        v = e.end.position - e.start.position
        e.hidden = true if v.x.abs < 0.5.mm && v.y.abs < 0.5.mm && v.z.abs > 0.5.mm
      end
    end

    def place(code, mirrored, hinge = 'lh')
      rec = catalogue[code] or return UI.messagebox("#{code} has no plan in the registry.")
      model = Sketchup.active_model
      parts = rec['fixed'] ? fixed_parts(rec, mirrored) : plan_parts(rec['outline'], mirrored)
      pl = rec['plinth'].to_f
      h  = rec['height'].to_f
      model.start_operation("Tangram #{code}", true)
      grp = model.active_entities.add_group
      grp.name = "#{code} #{rec['label']}#{mirrored ? ' (mirrored)' : ''} - PRELIMINARY"
      grp.layer = model.layers[TAG] || model.layers.add(TAG)
      plinth = prism(grp.entities, 'PLINTH', parts[:plinth], 0, pl,
                     material(model, 'UCON_Plinth_White', [245, 245, 245]))
      hide_vertical_edges(plinth)
      m_front = material(model, 'UCON_Front_White', [245, 245, 245])
      # F is fixed: the whole element in the front finish, and nothing opens
      prism(grp.entities, 'CARCASS', parts[:carcass], pl, h,
            material(model, 'UCON_Carcass_Light_Gray', [220, 220, 216]))
      # F: its facade in two pieces - the joint between them is the seam
      (parts[:fronts] || []).each_with_index do |pts, i|
        prism(grp.entities, i.zero? ? 'FACADE_SIDE (fixed)' : 'FACADE_CURVED (fixed)', pts, pl, h, m_front)
      end
      leaves = rec['fixed'] ? [] : door_leaves(parts, rec['doors'], hinge)
      leaves.each_with_index do |lf, i|
        prism(grp.entities, leaves.size > 1 ? "FRONT_#{i + 1}_OF_#{leaves.size}" : 'FRONT', lf[:band], pl, h, m_front)
      end
      draw_symbols(grp.entities, leaves, pl, h)
      { 'code' => code, 'label' => rec['label'], 'hand' => mirrored ? 'mirrored' : 'as drawn',
        'height_mm' => h, 'plinth_h_mm' => pl,
        'doors' => rec['doors'], 'hinge' => rec['fixed'] ? 'fixed' : leaves.map { |lf| lf[:hinge] }.join('+'),
        'front_mm' => rec['fixed'] ? "#{front_t} at #{front_gap} off the carcass, FIXED, two pieces with a joint at the curve (solid, not a door - to confirm with Elda)" : "#{front_t} at #{front_gap} off the carcass",
        'plinth_board_mm' => "#{plinth_t} at #{setback} behind the carcass front",
        'trust' => rec['geometry']['trust'], 'source' => rec['geometry']['source'],
        'status' => rec['fixed'] ?
          'PRELIMINARY - NO CODE in the Kitchen System; shape from the brochure plan; fixed (Andriy 2026-09-27); height assumed 840 on 60; code and height to Elda' :
          'PRELIMINARY - curve measured from the brochure, factory confirmation owed' }
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
      res = UI.inputbox(['Module', 'Hand', 'Hinge (1-door modules)'], [labels.first, 'as drawn', 'left'],
                        [labels.join('|'), 'as drawn|mirrored', 'left|right'], 'UCON Tangram - place module')
      return unless res

      place(codes[labels.index(res[0])], res[1] == 'mirrored', res[2] == 'right' ? 'rh' : 'lh')
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

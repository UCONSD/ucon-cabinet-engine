# UCON::RoomExtras - the pieces around the wall panels that are not panels, frames or clips: the TM door (frame, stops,
# leaves, cladding, back casing), the L-liners and the slot strips B / A at the openings, the stone plinth (by others)
# and the TM closet cabinets - as BOXES in wall-local mm (x along the wall, y from the wall face, negative into the
# room, z from the subfloor). Written 2026-10-16 for AP Capital ML Foyer from the pieces Main Kitchen built by hand
# (probes 624 / 631 / 634, read back 2026-10-16 by probe 766d):
#   DK1 (TM rev 5 = D01 profile): jambs 35 at the opening -4.3, depth -32.3 .. wall_t - 0.5; head 35 under the opening
#   head - 9; stop 32 x 44 (y -30.3..13.7) to head - 79; head stop 35 (y -31.8..23.2); leaf 43 thick (y -29.3..13.7)
#   FFL+10 .. head - 79; cladding 12 (y -44.3..-32.3) at the opening + 55.5, FFL+10 .. the panel joint; back casing
#   69.5 x 18.2 from the jamb line -35.2 at the back face -8.7..+9.5.
#   Liner (window W2 / niche): MDF 6 leg, flange 35.2 behind the panel at y -22.3..-16.3; strips MDF 6: B 6x34 at
#   y -16.3..-10.3 and A 6x17 at y -22.3..-16.3, both from 42.7 behind the panel edge; frame 46 behind the panel edge.
#   Stone: 20 thick, face = panel face (-44.3..-24.3), FFL .. 260.35, notch 10 x 10 at the top front edge.
# PURE RUBY for the pieces (headless, tested); build() needs SketchUp. The foyer's own choices are marked FOYER.
require 'json'
require_relative 'wall_panels'

module UCON
  module RoomExtras
    WP = UCON::WallPanels
    module_function

    def box(tag, name, x0, x1, y0, y1, z0, z1)
      { tag: tag, name: name, x: [x0, x1].minmax.map { |v| WP.r1(v) }, y: [y0, y1].minmax.map { |v| WP.r1(v) },
        z: [z0, z1].minmax.map { |v| WP.r1(v) } }
    end

    # -> list of boxes for one wall (spec = the wall JSON, out = WP.build(spec))
    def pieces(spec, out)
      bu = spec['build_up']; face = -bu['face'].to_f; pback = face + bu['panel_t'].to_f
      ffl = spec['levels']['ffl'].to_f
      len = spec['wall']['length'].to_f
      list = []
      spec['openings'].each do |o|
        list.concat(door(spec, o, ffl, face)) if o['kind'] == 'door'
        list.concat(liner(spec, o, ffl, face, pback, len)) if o['liner']
        list.concat(cabinet(spec, o, ffl, face)) if o['cabinet']
      end
      list.concat(strips(spec, out, pback))
      list.concat(stone(spec, out, ffl, face))
      list
    end

    # TM door as Main Kitchen DK1; FOYER: double - two leaves and two claddings meeting at the centre, stops both sides
    def door(spec, o, ffl, face)
      f = o['frame']; t = 'doors'; id = o['id']
      x0 = o['x0'].to_f; x1 = o['x1'].to_f; h = o['h'].to_f
      gs = f['gap_side'].to_f; jt = f['head'].to_f
      jy0 = f['jamb_y0'].to_f; jy1 = f['jamb_y1'].to_f; wt = f['wall_t'].to_f
      hz = h - f['gap_head'].to_f            # top of the frame head
      lt = hz - jt - 35                      # leaf top = head stop bottom (kitchen 2740 = 2819 - 79)
      ct = o['leaf']['floor_gap'].to_f + o['leaf']['h'].to_f   # cladding top = the panel joint
      cz0 = o['leaf']['floor_gap'].to_f
      fa = x0 + gs; fb = x1 - gs; c = (x0 + x1) / 2.0
      n = (o['leaf']['leaves'] || 1).to_i   # leaves of the door (model); the GRID column stays one (leaf.n)
      ls = [
        box(t, "#{id} frame jamb L", fa, fa + jt, jy0, jy1, ffl, hz),
        box(t, "#{id} frame jamb R", fb - jt, fb, jy0, jy1, ffl, hz),
        box(t, "#{id} frame head", fa, fb, jy0, jy1, hz - jt, hz),
        box(t, "#{id} head stop", fa + jt, fb - jt, -31.8, 23.2, lt, hz - jt),
        box(t, "#{id} stop L", fa + jt, fa + jt + 32, -30.3, 13.7, ffl, lt),
        box(t, "#{id} stop R", fb - jt - 32, fb - jt, -30.3, 13.7, ffl, lt),
        box(t, "#{id} back casing L", x0 - 35.2, x0 + 34.3, wt - 8.7, wt + 9.5, ffl, hz + 5.1),
        box(t, "#{id} back casing R", x1 - 34.3, x1 + 35.2, wt - 8.7, wt + 9.5, ffl, hz + 5.1),
        box(t, "#{id} back casing head", x0 - 35.2, x1 + 35.2, wt - 7.2, wt + 10.0, hz + 5.1, hz + 74.6)
      ]
      la = fa + jt + 35; lb = fb - jt - 35     # leaf edges 3 clear of the stops (DK1 stop side: O - 74.3); FOYER: stops both sides
      ca = x0 + 55.5; cb = x1 - 55.5
      jn = (o['leaf']['joint'] || 10).to_f / 2   # cladding joint at the centre (leaves 3 apart)
      if n == 2
        ls << box(t, "#{id} leaf L", la, c - 1.5, -29.3, 13.7, cz0, lt) << box(t, "#{id} leaf R", c + 1.5, lb, -29.3, 13.7, cz0, lt)
        ls << box(t, "#{id} cladding L", ca, c - jn, face, face + 12, cz0, ct) << box(t, "#{id} cladding R", c + jn, cb, face, face + 12, cz0, ct)
      else
        ls << box(t, "#{id} leaf", la, lb, -29.3, 13.7, cz0, lt) << box(t, "#{id} cladding", ca, cb, face, face + 12, cz0, ct)
      end
      ls
    end

    # FOYER: leg against the bare reveal (0..6 inside the jamb), 64 past the wall face; flange 35.2 behind the panel;
    # a jamb at a wall end has no leg; the head piece runs jamb to jamb (or to the wall end)
    def liner(spec, o, ffl, face, pback, len)
      l = o['liner']; t = 'liners'; id = o['id']; tk = l['t'].to_f; dp = l['depth'].to_f; fl = l['flange'].to_f
      x0 = o['x0'].to_f; x1 = o['x1'].to_f; h = o['h'].to_f
      ls = []
      if x0 > WP::EPS
        ls << box(t, "#{id} liner L leg", x0, x0 + tk, face, dp, ffl, h)
        ls << box(t, "#{id} liner L flange", x0 - fl, x0, pback, pback + tk, ffl, h)
      end
      if x1 < len - WP::EPS
        ls << box(t, "#{id} liner R leg", x1 - tk, x1, face, dp, ffl, h)
        ls << box(t, "#{id} liner R flange", x1, x1 + fl, pback, pback + tk, ffl, h)
      end
      ls << box(t, "#{id} liner head leg", x0, x1, face, dp, h - tk, h)
      # the head flange runs over the jamb flanges' ends (corners mitred 45 in the shop): no gap at the corner
      ha = x0 > WP::EPS ? x0 - fl : x0; hb = x1 < len - WP::EPS ? x1 + fl : x1
      ls << box(t, "#{id} liner head flange", ha, hb, pback, pback + tk, h, h + fl)
      ls
    end

    # strips B / A behind every panel edge that meets a liner (pier edges at a jamb, the bottom edge over the head)
    def strips(spec, out, pback)
      t = 'strips'; ls = []
      lo = spec['openings'].select { |o| o['liner'] && o['liner']['strips'] }   # 2026-10-17 foyer: wide flange, no strips
      out[:grid][:panels].each do |p|
        lo.each do |o|
          x0 = o['x0'].to_f; x1 = o['x1'].to_f; h = o['h'].to_f
          ztop = [p[:z1], h + 12.7].min
          if (p[:x1] - (x0 - 10)).abs < 0.05 && p[:z0] < h          # pier panel left of the opening
            ls << box(t, "#{p[:id]} strip B 6x34 | #{o['id']}", p[:x1] - 42.7, p[:x1] - 8.7, pback + 6, pback + 12, p[:z0], ztop)
            ls << box(t, "#{p[:id]} strip A 6x17 | #{o['id']}", p[:x1] - 42.7, p[:x1] - 25.7, pback, pback + 6, p[:z0], ztop)
          end
          if (p[:x0] - (x1 + 10)).abs < 0.05 && p[:z0] < h          # pier panel right of the opening
            ls << box(t, "#{p[:id]} strip B 6x34 | #{o['id']}", p[:x0] + 8.7, p[:x0] + 42.7, pback + 6, pback + 12, p[:z0], ztop)
            ls << box(t, "#{p[:id]} strip A 6x17 | #{o['id']}", p[:x0] + 25.7, p[:x0] + 42.7, pback, pback + 6, p[:z0], ztop)
          end
          if p[:x0] >= x0 - 0.05 && p[:x1] <= x1 + 0.05 && (p[:z0] - (h + o['head_gap'].to_f)).abs < 0.05   # over the head
            ls << box(t, "#{p[:id]} strip B 6x34 | #{o['id']} head", p[:x0], p[:x1], pback + 6, pback + 12, p[:z0] + 8.7, p[:z0] + 42.7)
            ls << box(t, "#{p[:id]} strip A 6x17 | #{o['id']} head", p[:x0], p[:x1], pback, pback + 6, p[:z0] + 25.7, p[:z0] + 42.7)
          end
        end
      end
      ls
    end

    # stone by others under every lower panel, to its edges; where it passes in front of a door frame its back is cut
    # to 9.5 thick (kitchen: back cut d 24.3..34.8, frame at d 32.3) - there only the part below the notch remains
    def stone(spec, out, ffl, face)
      st = spec['levels']['stone_top'] or return []
      t = 'stone'; ls = []
      sd = spec['levels']['stone'] || {}
      th = (sd['t'] || 20).to_f; nt = (sd['notch'] || 10).to_f; bc = (sd['back_cut'] || 9.5).to_f
      cuts = spec['openings'].select { |o| o['kind'] == 'door' }.map { |d| [d['x0'] + 1.8, d['x1'] - 1.8] }
      out[:grid][:panels].select { |p| (p[:z0] - st).abs < 0.05 }.each do |p|
        edges = ([p[:x0], p[:x1]] + cuts.flatten.select { |x| x > p[:x0] && x < p[:x1] }).sort
        edges.each_cons(2) do |a, b|
          mid = (a + b) / 2.0
          if cuts.any? { |c0, c1| mid > c0 && mid < c1 }
            ls << box(t, "stone under #{p[:id]} | back cut at the door frame", a, b, face, face + bc, ffl, st - nt)
          else
            ls << box(t, "stone under #{p[:id]}", a, b, face, face + th, ffl, st - nt)
            ls << box(t, "stone under #{p[:id]} | top behind the notch #{WallPanels.f1(nt)} x #{WallPanels.f1(nt)}", a, b, face + nt, face + th, st - nt, st)
          end
        end
      end
      ls
    end

    # FOYER: TM shoe cabinet as an envelope - carcass + two fronts flush with the panel face, 3 clear of the reveals
    def cabinet(spec, o, ffl, face)
      cb = o['cabinet']; t = 'cabinets'; id = o['id']
      x0 = o['x0'].to_f + cb['side_gap'].to_f; x1 = o['x1'].to_f - cb['side_gap'].to_f
      # height: WallPanels.cab_top (fit_niche: niche head - top_gap; else TM's tm_top_ffl). Width: niche - 2 x side_gap
      top = WallPanels.cab_top(spec, o) || o['h'].to_f - cb['top_gap'].to_f
      ft = cb['front_t'].to_f; dp = cb['depth'].to_f; g = cb['gap'].to_f
      zl = ffl + g; zl1 = zl + cb['lower_h'].to_f
      [box(t, "#{id} cabinet carcass (TM, envelope)", x0, x1, face + ft, face + dp, ffl, top),
       box(t, "#{id} front lower #{cb['doors'][0]} (TM)", x0, x1, face, face + ft, zl, zl1),
       box(t, "#{id} front upper #{cb['doors'][1]} (TM)", x0, x1, face, face + ft, zl1 + g, top - g)]
    end

    # ------------------------------------------------------------------ SketchUp side (ARMED only)
    TAGS = { 'doors' => '04 Doors (TM)', 'liners' => '07 Liners', 'strips' => '07 Liners - strips B / A',
             'stone' => '05 Stone plinth - by others (ref)', 'cabinets' => '09 Closet cabinets (TM, ref)' }.freeze
    COLORS = { 'doors' => [235, 225, 200], 'liners' => [250, 250, 246], 'strips' => [210, 190, 150],
               'stone' => [214, 208, 198], 'cabinets' => [200, 205, 215] }.freeze

    def build(model, pieces, prefix, origin)
      groups = {}
      pieces.group_by { |p| p[:tag] }.each do |tg, ps|
        tag = model.layers[TAGS[tg]] || model.layers.add(TAGS[tg])
        mat = model.materials["FOY #{tg}"] || model.materials.add("FOY #{tg}")
        mat.color = Sketchup::Color.new(*COLORS[tg])
        grp = model.entities.add_group; grp.name = "#{prefix} | #{TAGS[tg]}"; grp.layer = tag
        ps.each do |p|
          g = grp.entities.add_group; g.name = p[:name]; g.layer = tag; g.material = mat
          x0, x1 = p[:x]; y0, y1 = p[:y]; z0, z1 = p[:z]
          f = g.entities.add_face([[x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0]].map { |a, b, c| Geom::Point3d.new(a.mm, b.mm, c.mm) })
          f.reverse! if f.normal.z < 0
          f.pushpull((z1 - z0).mm)
          raise "#{p[:name]} not solid" unless g.manifold?
        end
        grp.transform!(origin)
        groups[tg] = grp
      end
      groups
    end
  end
end

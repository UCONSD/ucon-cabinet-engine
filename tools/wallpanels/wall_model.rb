# UCON::WallModel - the wall-panel generators' SketchUp side: READ a built wall back into the generators' shapes,
# COMPARE it with what the generators say, and WRITE panels / backing frames / clips / drilling into a model.
#
# Runs inside SketchUp only, from probes (tools/probe_inbox). Nothing in src/ requires it. The writers change the
# model, so they are called from an ARMED probe only (applied with the palette button); a dry run of them is rolled
# back by the bridge like any probe that draws its own geometry (no engine builder, no inner commit_operation).
# Probe 599 (2026-10-08) ran the writers dry under a throwaway prefix on REC -> LAU and compared them with the wall
# drawn by hand in 538 / 566 / 570 / 596.
#
# Wall-local = model axes for the walls built so far: x along the wall, z up, y = 0 at the wall face, -y toward the
# room. A wall at another position or angle needs a transformation; `origin` (a Geom::Transformation) is applied to
# every group written, default identity.
load File.join(__dir__, 'wall_panels.rb')

module UCON
  module WallModel
    WP = UCON::WallPanels
    TAGS = { panels: '03 Panels - solid 22', numbers: '03 Panels - numbers', frames: '03 Panels',
             clips: '02 Subframe - clips', drilling: '02 Subframe - drilling' }.freeze

    module_function

    def mm(v)
      v.to_f.mm
    end

    def to_mm(v)
      v.to_mm.round(2)
    end

    def wbox(ent, tr)
      b = Geom::BoundingBox.new
      8.times { |i| b.add(ent.bounds.corner(i).transform(tr)) }
      { x0: to_mm(b.min.x), x1: to_mm(b.max.x), y0: to_mm(b.min.y), y1: to_mm(b.max.y), z0: to_mm(b.min.z), z1: to_mm(b.max.z) }
    end

    # ------------------------------------------------------------------ read
    def read(model, prefix)
      e = model.entities
      pg = e.grep(Sketchup::Group).find { |g| g.name.start_with?("#{prefix} | solid panels") }
      panels = pg ? pg.entities.grep(Sketchup::Group).map { |c| { name: c.name, id: c.name[0, 3], box: wbox(c, pg.transformation) } } : []
      frames = e.grep(Sketchup::ComponentInstance).select { |i| i.name =~ /\A#{Regexp.escape(prefix)} \| backing S\d\d/ }.map do |i|
        { id: i.name[/S\d\d/], box: wbox(i, IDENTITY),
          members: i.definition.entities.grep(Sketchup::Group).map { |g| { name: g.name, box: wbox(g, i.transformation) } } }
      end.sort_by { |f| f[:id] }
      cg = e.grep(Sketchup::Group).find { |g| g.name.start_with?("#{prefix} | clips") }
      clips = cg ? cg.entities.grep(Sketchup::Group).map { |c| b = wbox(c, cg.transformation); { panel: c.name[0, 3], x: ((b[:x0] + b[:x1]) / 2).round(1), z: ((b[:z0] + b[:z1]) / 2).round(1), box: b } } : []
      dg = e.grep(Sketchup::Group).find { |g| g.name.start_with?("#{prefix} | drilling") }
      holes = dg ? dg.entities.grep(Sketchup::Group).map { |c| b = wbox(c, dg.transformation); { id: c.name[/P\d\d-H\d\d/], part: c.name.include?('panel') ? :panel : :frame, x: ((b[:x0] + b[:x1]) / 2).round(1), z: ((b[:z0] + b[:z1]) / 2).round(1), box: b } } : []
      { panels: panels, frames: frames, clips: clips, holes: holes }
    end

    # ------------------------------------------------------------------ compare
    # model read (read) against the generators (WP.build) -> list of differences, empty = the same wall
    def compare(spec, got, tol: 0.06)
      out = WP.build(spec)
      bu = spec['build_up']
      diff = []
      near = ->(a, b) { (a - b).abs <= tol }
      # panels
      want = out[:grid][:panels]
      diff << "panels: model #{got[:panels].size}, generator #{want.size}" if got[:panels].size != want.size
      want.each do |p|
        m = got[:panels].find { |x| x[:id] == p[:id] } or (diff << "#{p[:id]}: not in the model"; next)
        b = m[:box]
        diff << "#{p[:id]}: box #{[b[:x0], b[:x1], b[:z0], b[:z1]].inspect} vs #{[p[:x0], p[:x1], p[:z0], p[:z1]].inspect}" unless near.(b[:x0], p[:x0]) && near.(b[:x1], p[:x1]) && near.(b[:z0], p[:z0]) && near.(b[:z1], p[:z1])
        diff << "#{p[:id]}: y #{b[:y0]}..#{b[:y1]} vs #{-bu['face']}..#{-(bu['face'] - bu['panel_t'])}" unless near.(b[:y0], -bu['face']) && near.(b[:y1], -(bu['face'] - bu['panel_t']))
        diff << "#{p[:id]}: name #{m[:name].inspect}" unless m[:name].start_with?("#{p[:id]} #{p[:pos]} |")
      end
      # frames, member by member
      diff << "frames: model #{got[:frames].size}, generator #{out[:frames].size}" if got[:frames].size != out[:frames].size
      out[:frames].each do |f|
        m = got[:frames].find { |x| x[:id] == f[:id] } or (diff << "#{f[:id]}: not in the model"; next)
        WP.members(f).each do |w|
          mm_ = m[:members].find { |x| x[:name].sub(/\A[FS]\d\d/, f[:id]) == w[:name] }
          unless mm_
            diff << "#{w[:name]}: no such member (model has #{m[:members].map { |x| x[:name] }.join(', ')})"
            next
          end
          b = mm_[:box]
          diff << "#{w[:name]}: #{[b[:x0], b[:x1], b[:z0], b[:z1]].inspect} vs #{[w[:x0], w[:x1], w[:z0], w[:z1]].inspect}" unless near.(b[:x0], w[:x0]) && near.(b[:x1], w[:x1]) && near.(b[:z0], w[:z0]) && near.(b[:z1], w[:z1])
          diff << "#{w[:name]}: y #{b[:y0]}..#{b[:y1]} vs #{-bu['frame_t']}..0" unless near.(b[:y0], -bu['frame_t']) && near.(b[:y1], 0)
        end
        extra = m[:members].size - WP.members(f).size
        diff << "#{f[:id]}: #{extra} more members in the model" if extra.positive?
      end
      # clips
      g = out[:clips].map { |c| [c[:panel], c[:x], c[:z]] }.sort
      mo = got[:clips].map { |c| [c[:panel], c[:x], c[:z]] }.sort
      (mo - g).each { |c| diff << "clip in the model only: #{c.inspect}" }
      (g - mo).each { |c| diff << "clip in the generator only: #{c.inspect}" }
      ys = got[:clips].map { |c| [c[:box][:y0], c[:box][:y1]] }.uniq
      ys.each { |y0, y1| diff << "clips y #{y0}..#{y1} vs #{-(bu['face'] - bu['panel_t'])}..#{-bu['frame_t']}" unless near.(y0, -(bu['face'] - bu['panel_t'])) && near.(y1, -bu['frame_t']) }
      # holes
      gh = out[:holes].map { |h| [h[:id], h[:x], h[:z]] }.sort
      %i[panel frame].each do |part|
        mh = got[:holes].select { |h| h[:part] == part }.map { |h| [h[:id], h[:x], h[:z]] }.sort
        (mh - gh).each { |h| diff << "#{part} hole in the model only: #{h.inspect}" }
        (gh - mh).each { |h| diff << "#{part} hole in the generator only: #{h.inspect}" }
      end
      diff
    end

    # ------------------------------------------------------------------ write (ARMED only)
    def tag(model, key)
      model.layers[TAGS[key]] || model.layers.add(TAGS[key])
    end

    def material(model, name, rgb)
      m = model.materials[name] || model.materials.add(name)
      m.color = Sketchup::Color.new(*rgb)
      m
    end

    # a box in the x/z plane, from y_face toward +y by depth (solid group)
    def slab(ents, pts_xz, y, depth, name = nil)
      g = ents.add_group
      g.name = name if name
      f = g.entities.add_face(pts_xz.map { |x, z| Geom::Point3d.new(mm(x), mm(y), mm(z)) })
      f.reverse! if f.normal.y < 0
      f.pushpull(mm(depth))
      g
    end

    # the back slab outline of a panel with one rebate (538: back_poly); nil = fully rebated
    def back_poly(p, rb)
      x0 = p[:x0]; x1 = p[:x1]; z0 = p[:z0]; z1 = p[:z1]
      return [[x0, z0], [x1, z0], [x1, z1], [x0, z1]] unless rb
      rx0, rx1, _rz0, rz1 = rb
      full_x = rx0 <= x0 && rx1 >= x1; full_z = rz1 >= z1
      return nil if full_x && full_z
      return [[x0, rz1], [x1, rz1], [x1, z1], [x0, z1]] if full_x
      return (rx0 <= x0 ? [[rx1, z0], [x1, z0], [x1, z1], [rx1, z1]] : [[x0, z0], [rx0, z0], [rx0, z1], [x0, z1]]) if full_z
      if rx0 <= x0 then [[rx1, z0], [x1, z0], [x1, z1], [x0, z1], [x0, rz1], [rx1, rz1]]
      else [[x0, z0], [rx0, z0], [rx0, rz1], [x1, rz1], [x1, z1], [x0, z1]] end
    end

    def build_panels(model, spec, out, prefix: spec['prefix'], origin: IDENTITY)
      bu = spec['build_up']
      face = -bu['face'].to_f; t = bu['panel_t'].to_f
      dep = WP.doors(spec).map { |d| d['rebate'] && d['rebate']['depth'] }.compact.first || 0
      tp = tag(model, :panels)
      pg = model.entities.add_group; pg.name = "#{prefix} | solid panels #{WP.f1(t)} | #{out[:grid][:panels].first[:id]}-#{out[:grid][:panels].last[:id]}"; pg.layer = tp
      out[:grid][:panels].each do |p|
        raise "#{p[:id]}: #{p[:rebates].size} rebates - one per panel is drawn" if p[:rebates].size > 1
        g = pg.entities.add_group; g.layer = tp
        g.name = format('%s %s | %.1f x %.1f x %s', p[:id], p[:pos], p[:w], p[:h], WP.f1(t))
        rect = [[p[:x0], p[:z0]], [p[:x1], p[:z0]], [p[:x1], p[:z1]], [p[:x0], p[:z1]]]
        f = g.entities.add_face(rect.map { |x, z| Geom::Point3d.new(mm(x), mm(face), mm(z)) })
        f.reverse! if f.normal.y < 0
        f.pushpull(mm(t - dep))
        bp = back_poly(p, p[:rebates].first)
        if bp && dep.positive?
          bf = g.entities.add_face(bp.map { |x, z| Geom::Point3d.new(mm(x), mm(face + t - dep), mm(z)) })
          bf.reverse! if bf.normal.y < 0
          bf.pushpull(mm(dep))
        end
        raise "#{g.name} not solid" unless g.manifold?
      end
      tn = tag(model, :numbers)
      ng = model.entities.add_group; ng.name = "#{prefix} | panel numbers"; ng.layer = tn
      out[:grid][:panels].each { |p| ng.entities.add_text(p[:id], Geom::Point3d.new(mm((p[:x0] + p[:x1]) / 2), mm(face - 1), mm((p[:z0] + p[:z1]) / 2))).layer = tn }
      WP.doors(spec).each { |d| ng.entities.add_text(d['id'], Geom::Point3d.new(mm((d['x0'] + d['x1']) / 2.0), mm(face - 1), mm(d['leaf']['floor_gap'] + d['leaf']['h'] / 2.0))).layer = tn }
      [pg, ng].each { |x| x.transform!(origin) }
      [pg, ng]
    end

    def build_frames(model, spec, out, prefix: spec['prefix'], origin: IDENTITY)
      ft = spec['build_up']['frame_t'].to_f
      tp = tag(model, :frames)
      m4 = material(model, 'backing ply', [200, 200, 196]); m6 = material(model, 'backing ply 6in', [165, 165, 160])
      out[:frames].map do |f|
        dfn = model.definitions.add("#{prefix} subframe #{f[:id]}")
        WP.members(f).each do |mb|
          g = slab(dfn.entities, [[mb[:x0], mb[:z0]], [mb[:x1], mb[:z0]], [mb[:x1], mb[:z1]], [mb[:x0], mb[:z1]]], -ft, ft, mb[:name])
          g.material = mb[:w] == '6' ? m6 : m4
          raise "#{mb[:name]} not solid" unless g.manifold?
        end
        inst = model.entities.add_instance(dfn, origin)
        inst.name = "#{prefix} | backing #{f[:id]} | #{(f[:x1] - f[:x0]).round} x #{(f[:z1] - f[:z0]).round}"
        inst.layer = tp
        inst
      end
    end

    def build_clips(model, spec, out, prefix: spec['prefix'], origin: IDENTITY)
      bu = spec['build_up']; c = spec['clips']
      back = -(bu['face'] - bu['panel_t']); gap = bu['clip_gap'].to_f
      tc = tag(model, :clips)
      mats = { ok: material(model, 'clip ok', [70, 70, 70]), part: material(model, 'clip PARTIAL support', [240, 140, 20]),
               no: material(model, 'clip NO SUPPORT', [220, 30, 30]) }
      cg = model.entities.add_group; cg.layer = tc
      cg.name = "#{prefix} | clips #{c['make']} #{c['mount']} (D28 in #{WP.f1(gap)} mm gap)"
      out[:clips].each do |cl|
        g = cg.entities.add_group; g.layer = tc; g.name = "#{cl[:panel]} #{mats[cl[:support]].name}"
        ed = g.entities.add_circle(Geom::Point3d.new(mm(cl[:x]), mm(back), mm(cl[:z])), Geom::Vector3d.new(0, 1, 0), 14.mm, 24)
        f = g.entities.add_face(ed); f.reverse! if f.normal.y < 0; f.pushpull(mm(gap))
        g.material = mats[cl[:support]]
      end
      cg.transform!(origin)
      cg
    end

    def build_holes(model, spec, out, prefix: spec['prefix'], origin: IDENTITY)
      bu = spec['build_up']; c = spec['clips']
      back = -(bu['face'] - bu['panel_t']); ft = bu['frame_t'].to_f; r = c['hole_d'] / 2.0
      t = tag(model, :drilling)
      mt = material(model, "drill hole D#{WP.f1(c['hole_d'])}", [200, 0, 0])
      gg = model.entities.add_group; gg.layer = t
      gg.name = "#{prefix} | drilling D#{WP.f1(c['hole_d'])} (panel #{WP.f1(c['panel_depth'])} deep, frame #{WP.f1(c['frame_depth'])} deep)"
      cyl = lambda do |name, x, z, y0, y1|
        g = gg.entities.add_group; g.name = name; g.layer = t; g.material = mt
        ed = g.entities.add_circle(Geom::Point3d.new(mm(x), mm(y1), mm(z)), Geom::Vector3d.new(0, 1, 0), mm(r), 24)
        f = g.entities.add_face(ed); f.reverse! if f.normal.y > 0; f.pushpull(mm(y1 - y0))
        raise "#{name} not solid" unless g.manifold?
      end
      out[:holes].each do |h|
        cyl.call("#{h[:id]} panel D#{WP.f1(c['hole_d'])}x#{WP.f1(c['panel_depth'])}", h[:x], h[:z], back - c['panel_depth'], back)
        cyl.call("#{h[:id]} frame D#{WP.f1(c['hole_d'])}x#{WP.f1(c['frame_depth'])}", h[:x], h[:z], -ft, -ft + c['frame_depth'])
      end
      gg.transform!(origin)
      gg
    end

    # all four, in order; returns what was made
    def build_all(model, spec, prefix: spec['prefix'], origin: IDENTITY)
      out = WP.build(spec)
      raise "wall checks failed: #{out[:checks].join(' | ')}" unless out[:checks].empty?
      { panels: build_panels(model, spec, out, prefix: prefix, origin: origin),
        frames: build_frames(model, spec, out, prefix: prefix, origin: origin),
        clips: build_clips(model, spec, out, prefix: prefix, origin: origin),
        holes: build_holes(model, spec, out, prefix: prefix, origin: origin) }
    end
  end
end

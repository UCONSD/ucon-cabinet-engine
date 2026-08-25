# tools/kitchen_probe.rb - READ-ONLY probe #2: the ROOM and what already stands in it.
#
# Run in the SketchUp Ruby Console:
#
#   load '/Users/andriydemko/dev/ucon-cabinet-engine/tools/kitchen_probe.rb'
#
# Changes NOTHING. Writes tools/kitchen_probe_report.txt inside the repository.
#
# Probe #1 (wall_probe.rb) reported 0 engine objects, which was wrong: it looked
# for the CabinetEngine dictionary on root entities only, and did not look at the
# component DEFINITION. This one walks the whole tree and asks both.
#
# Three sections:
#   A  every object carrying CabinetEngine - all attributes, world position
#   B  the room shell - vertical faces that belong to neither a Cesar unit nor
#      an imported appliance, with their plane offsets, so walls can be paired
#   C  what stands against each wall plane, and how much of it is free
#
# Ruby 2.6-safe on purpose - the two Macs run different SketchUp versions.

module UCON
  module KitchenProbe
    MM = 25.4
    SKIP_NAME = /\A(Cesar |48 WOLF)/i     # do not descend for shell geometry
    NEAR_WALL = 60.0                      # mm: a unit this close counts as against it

    def self.mm(v); (v.to_f * MM).round(1); end
    def self.p3(p); "(#{mm(p.x)}, #{mm(p.y)}, #{mm(p.z)})"; end
    def self.v3(v); "(#{v.x.round(3)}, #{v.y.round(3)}, #{v.z.round(3)})"; end

    def self.name_of(e)
      n = e.respond_to?(:name) ? e.name.to_s : ''
      return n unless n.empty?
      return e.definition.name.to_s if e.is_a?(Sketchup::ComponentInstance)
      '(unnamed)'
    end

    def self.dict_of(e)
      d = e.attribute_dictionary('CabinetEngine')
      return [d, 'instance'] if d
      if e.is_a?(Sketchup::ComponentInstance)
        d = e.definition.attribute_dictionary('CabinetEngine')
        return [d, 'definition'] if d
      end
      [nil, nil]
    end

    def self.world_bbox(e, tr)
      bb = e.is_a?(Sketchup::ComponentInstance) ? e.definition.bounds : e.bounds
      pts = (0..7).map { |i| bb.corner(i).transform(tr * (e.is_a?(Sketchup::ComponentInstance) ? e.transformation : Geom::Transformation.new)) }
      xs = pts.map { |p| p.x.to_f }; ys = pts.map { |p| p.y.to_f }; zs = pts.map { |p| p.z.to_f }
      [Geom::Point3d.new(xs.min, ys.min, zs.min), Geom::Point3d.new(xs.max, ys.max, zs.max)]
    end

    def self.walk(ents, tr, path, acc, depth)
      return if depth > 8
      ents.each do |e|
        if e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
          nm  = name_of(e)
          sub = e.is_a?(Sketchup::Group) ? e.entities : e.definition.entities
          ntr = tr * e.transformation
          d, where = dict_of(e)
          if d
            mn, mx = world_bbox(e, tr)
            acc[:units] << { :name => nm, :dict => d, :where => where, :tr => ntr,
                             :min => mn, :max => mx, :path => path.join(' / ') }
          end
          if nm =~ SKIP_NAME
            acc[:skipped] << [nm, path.join(' / ')] unless d
            next unless d.nil? && nm =~ /WOLF/i && false
            # a Cesar unit or an imported appliance: recorded, not walked for shell faces
            next
          end
          walk(sub, ntr, path + [nm], acc, depth + 1)
        elsif e.is_a?(Sketchup::Face)
          n = e.normal.transform(tr)
          n.normalize! rescue nil
          next unless n.z.abs < 0.02
          pts = e.outer_loop.vertices.map { |v| v.position.transform(tr) }
          next if pts.empty?
          zs = pts.map { |p| p.z.to_f }
          zmin = zs.min
          low = pts.select { |p| (p.z.to_f - zmin).abs < 0.02 }
          low = pts if low.size < 2
          a = low.first
          b = low.max_by { |p| (p.x.to_f - a.x.to_f)**2 + (p.y.to_f - a.y.to_f)**2 }
          d = n.x * a.x.to_f + n.y * a.y.to_f      # plane offset along the normal
          acc[:shell] << { :n => n, :d => d, :a => a, :b => b,
                           :len => Math.sqrt((b.x.to_f - a.x.to_f)**2 + (b.y.to_f - a.y.to_f)**2),
                           :zmin => zmin, :zmax => zs.max,
                           :area => (e.area.to_f * MM * MM).round(0),
                           :path => path.join(' / ') }
        end
      end
    end

    def self.run
      model = Sketchup.active_model
      acc = { :units => [], :shell => [], :skipped => [] }
      walk(model.entities, Geom::Transformation.new, [], acc, 0)
      out = []

      out << 'UCON kitchen probe - READ-ONLY. Millimetres throughout.'
      out << "generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      out << "model: #{model.title}"
      out << ''

      # ---- A ---------------------------------------------------------------
      out << "== A. OBJECTS CARRYING CabinetEngine (#{acc[:units].size}) =="
      out << ''
      acc[:units].sort_by { |u| [u[:min].x.to_f, u[:min].y.to_f] }.each_with_index do |u, i|
        w = mm(u[:max].x.to_f - u[:min].x.to_f)
        d = mm(u[:max].y.to_f - u[:min].y.to_f)
        h = mm(u[:max].z.to_f - u[:min].z.to_f)
        ax = u[:tr].xaxis
        ang = (Math.atan2(ax.y.to_f, ax.x.to_f) * 180.0 / Math::PI).round(2)
        out << format('  [%02d] %s', i + 1, u[:name])
        out << "       attributes on the #{u[:where]}"
        out << "       world bbox #{p3(u[:min])} .. #{p3(u[:max])}   (x #{w} / y #{d} / z #{h})"
        out << "       origin #{p3(u[:tr].origin)}   rotation about Z: #{ang} deg"
        keys = []
        u[:dict].each_pair { |k, v| keys << [k, v] }
        keys.sort_by { |k, _| k.to_s }.each do |k, v|
          s = v.inspect
          s = s[0, 300] + ' ...(truncated)' if s.length > 300
          out << "         #{k} = #{s}"
        end
        out << ''
      end
      out << '  none found' if acc[:units].empty?
      out << ''

      # ---- B ---------------------------------------------------------------
      sh = acc[:shell].sort_by { |f| -f[:area] }
      out << "== B. SHELL VERTICAL FACES - Cesar units and imported appliances excluded (#{sh.size}) =="
      out << '   plane offset d = normal . point, so two faces of one wall have'
      out << '   opposite normals and |d1 + d2| = the wall thickness.'
      out << ''
      sh.first(40).each_with_index do |f, i|
        out << format('  [%02d] area=%d  normal %s  d=%s', i + 1, f[:area], v3(f[:n]), mm(f[:d]))
        out << "       plan #{p3(f[:a])} -> #{p3(f[:b])}  run=#{mm(f[:len])}  z #{mm(f[:zmin])}..#{mm(f[:zmax])}"
        out << "       path #{f[:path].empty? ? '(root)' : f[:path]}"
      end
      out << "  ... #{sh.size - 40} smaller faces not listed" if sh.size > 40
      out << ''

      # ---- C ---------------------------------------------------------------
      out << '== C. WHAT STANDS AGAINST EACH WALL PLANE =='
      out << "   A unit counts as against a plane when its nearest face is within #{NEAR_WALL.round} mm."
      out << ''
      planes = {}
      sh.each do |f|
        next if f[:area] < 300_000
        key = [f[:n].x.round(2), f[:n].y.round(2), mm(f[:d]).round(0)]
        planes[key] ||= { :n => f[:n], :d => f[:d], :faces => [] }
        planes[key][:faces] << f
      end
      planes.each do |key, pl|
        segs = pl[:faces].map { |f| [f[:a], f[:b], f[:len]] }
        total = segs.map { |s| s[2] }.inject(0.0) { |s, v| s + v }
        out << "  PLANE normal #{v3(pl[:n])}  d=#{mm(pl[:d])}   faces=#{pl[:faces].size}  total run=#{mm(total)}"
        segs.each { |a, b, l| out << "     segment #{p3(a)} -> #{p3(b)}  #{mm(l)}" }
        against = []
        acc[:units].each do |u|
          c = [ (u[:min].x.to_f + u[:max].x.to_f) / 2.0, (u[:min].y.to_f + u[:max].y.to_f) / 2.0 ]
          # distance from the unit's nearest bbox face to the plane
          cand = [u[:min], u[:max]].map { |p| pl[:n].x * p.x.to_f + pl[:n].y * p.y.to_f }
          near = cand.map { |v| (v - pl[:d]).abs }.min
          against << [u[:name], mm(near)] if mm(near) <= NEAR_WALL
        end
        if against.empty?
          out << '     nothing stands against it'
        else
          against.each { |nm, dd| out << "     #{dd} mm away: #{nm}" }
        end
        out << ''
      end

      out << "== SKIPPED CONTAINERS (not walked for shell geometry): #{acc[:skipped].size} =="
      acc[:skipped].uniq.first(30).each { |nm, pp| out << "  #{nm}   (in #{pp.empty? ? 'root' : pp})" }
      out << ''
      out << 'END'

      path = File.join(File.dirname(__FILE__), 'kitchen_probe_report.txt')
      File.open(path, 'w') { |f| f.write(out.join("\n")) }
      puts '--- UCON kitchen probe ---'
      puts "engine objects: #{acc[:units].size}   shell vertical faces: #{acc[:shell].size}   skipped containers: #{acc[:skipped].size}"
      puts "report written: #{path}"
      puts 'Nothing in the model was changed.'
      true
    end
  end
end

UCON::KitchenProbe.run

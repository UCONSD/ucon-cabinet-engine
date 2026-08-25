# tools/wall_probe.rb - READ-ONLY probe of the active SketchUp model.
#
# Run it from the SketchUp Ruby Console, one line, nothing pasted:
#
#   load '/Users/andriydemko/dev/ucon-cabinet-engine/tools/wall_probe.rb'
#
# It changes NOTHING: no entity is created, moved, deleted or re-tagged, and
# no model attribute is written. It reads geometry and writes a text report to
#
#   tools/wall_probe_report.txt
#
# which is inside the repository, so the report can be read directly instead of
# being copied out of the console. The console gets a short summary only.
#
# Everything is reported in MILLIMETRES, whatever the model's display units,
# because millimetres are what the catalog speaks. Ruby 2.6-safe on purpose:
# the SketchUp Ruby version differs between the two Macs.

module UCON
  module WallProbe
    MM_PER_INCH = 25.4
    VERTICAL_TOL = 0.02      # |normal.z| below this = a vertical face
    FLAT_TOL     = 0.98      # |normal.z| above this = a horizontal face
    MAX_FACES    = 60        # do not let a heavy model write a novel

    def self.mm(v)
      (v.to_f * MM_PER_INCH).round(1)
    end

    def self.ptxt(p)
      "(#{mm(p.x)}, #{mm(p.y)}, #{mm(p.z)})"
    end

    def self.vtxt(v)
      "(#{v.x.round(3)}, #{v.y.round(3)}, #{v.z.round(3)})"
    end

    def self.tag_of(e)
      l = e.layer
      l.nil? ? '-' : l.name.to_s
    end

    def self.mat_of(e)
      f = e.material     ? e.material.display_name     : nil
      b = e.back_material ? e.back_material.display_name : nil
      "front=#{f || '-'} back=#{b || '-'}"
    end

    # --- the walk -----------------------------------------------------------
    def self.walk(ents, tr, path, acc, depth)
      return if depth > 6
      ents.each do |e|
        if e.is_a?(Sketchup::Group)
          nm = e.name.to_s
          nm = '(unnamed group)' if nm.empty?
          acc[:containers] << [path.join(' / '), 'Group', nm, tag_of(e), e.bounds]
          walk(e.entities, tr * e.transformation, path + [nm], acc, depth + 1)
        elsif e.is_a?(Sketchup::ComponentInstance)
          nm = e.name.to_s
          nm = e.definition.name.to_s if nm.empty?
          acc[:containers] << [path.join(' / '), 'Component', nm, tag_of(e), e.bounds]
          walk(e.definition.entities, tr * e.transformation, path + [nm], acc, depth + 1)
        elsif e.is_a?(Sketchup::Face)
          collect_face(e, tr, path, acc)
        end
      end
    end

    def self.collect_face(f, tr, path, acc)
      pts = f.outer_loop.vertices.map { |v| v.position.transform(tr) }
      return if pts.empty?
      n = f.normal.transform(tr)
      n.normalize! rescue nil
      xs = pts.map { |p| p.x.to_f }
      ys = pts.map { |p| p.y.to_f }
      zs = pts.map { |p| p.z.to_f }
      rec = {
        :path   => path.join(' / '),
        :tag    => tag_of(f),
        :mat    => mat_of(f),
        :normal => n,
        :area   => (f.area.to_f * MM_PER_INCH * MM_PER_INCH).round(0),
        :min    => Geom::Point3d.new(xs.min, ys.min, zs.min),
        :max    => Geom::Point3d.new(xs.max, ys.max, zs.max),
        :pts    => pts
      }
      if n.z.abs < VERTICAL_TOL
        acc[:vertical] << rec
      elsif n.z.abs > FLAT_TOL
        acc[:horizontal] << rec
      else
        acc[:sloped] << rec
      end
    end

    # the lowest edge of a vertical face, as a plan segment
    def self.footprint(rec)
      zmin = rec[:pts].map { |p| p.z.to_f }.min
      low  = rec[:pts].select { |p| (p.z.to_f - zmin).abs < 0.02 }
      low  = rec[:pts] if low.size < 2
      a = low.first
      b = low.max_by { |p| (p.x.to_f - a.x.to_f)**2 + (p.y.to_f - a.y.to_f)**2 }
      len = Math.sqrt((b.x.to_f - a.x.to_f)**2 + (b.y.to_f - a.y.to_f)**2)
      [a, b, len]
    end

    # --- the report ---------------------------------------------------------
    def self.run
      model = Sketchup.active_model
      out   = []
      acc   = { :containers => [], :vertical => [], :horizontal => [], :sloped => [] }

      out << 'UCON wall probe - READ-ONLY. All figures in millimetres.'
      out << "generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      out << "SketchUp: #{Sketchup.version}   Ruby: #{RUBY_VERSION}"
      out << "model title: #{model.title}"
      out << "model path : #{model.path.to_s.empty? ? '(never saved)' : model.path}"
      begin
        uo = model.options['UnitsOptions']
        out << "display units: LengthUnit=#{uo['LengthUnit']} LengthFormat=#{uo['LengthFormat']}"
      rescue StandardError => e
        out << "display units: unreadable (#{e.class})"
      end
      out << ''

      walk(model.entities, Geom::Transformation.new, [], acc, 0)

      b = model.bounds
      out << '== MODEL BOUNDS =='
      out << "min #{ptxt(b.min)}   max #{ptxt(b.max)}"
      out << "size  W(x)=#{mm(b.width)}  D(y)=#{mm(b.height)}  H(z)=#{mm(b.depth)}"
      out << '  (SketchUp names these width/height/depth; z is the last one.)'
      out << ''

      out << '== TAGS =='
      model.layers.each { |l| out << "  #{l.name}#{l.visible? ? '' : '  [hidden]'}" }
      out << ''

      out << "== CONTAINERS (#{acc[:containers].size}) =="
      if acc[:containers].empty?
        out << '  none - the geometry is loose in the model root.'
      else
        acc[:containers].each do |parent, kind, nm, tag, bb|
          out << "  #{kind} \"#{nm}\"  tag=#{tag}  parent=#{parent.empty? ? '(root)' : parent}"
          out << "     bounds min #{ptxt(bb.min)} max #{ptxt(bb.max)}"
        end
      end
      out << ''

      vs = acc[:vertical].sort_by { |r| -r[:area] }
      out << "== VERTICAL FACES - the wall candidates (#{acc[:vertical].size}, largest first) =="
      out << '   Each line: area, then the plan segment of its lowest edge, then'
      out << '   the height range and the outward normal. Two faces of one wall'
      out << '   share a footprint and have opposite normals - the gap between'
      out << '   their planes is the wall thickness.'
      out << ''
      vs.first(MAX_FACES).each_with_index do |r, i|
        a, bb, len = footprint(r)
        out << format('  [%02d] area=%d mm2  tag=%s', i + 1, r[:area], r[:tag])
        out << "       plan  #{ptxt(a)} -> #{ptxt(bb)}   run=#{mm(len)}"
        out << "       z     #{mm(r[:min].z)} .. #{mm(r[:max].z)}   (height #{mm(r[:max].z.to_f - r[:min].z.to_f)})"
        out << "       normal #{vtxt(r[:normal])}   #{r[:mat]}"
        out << "       path  #{r[:path].empty? ? '(root)' : r[:path]}"
      end
      out << "  ... #{vs.size - MAX_FACES} more not listed" if vs.size > MAX_FACES
      out << ''

      hs = acc[:horizontal]
      out << "== HORIZONTAL FACES - floor / ceiling / tops (#{hs.size}) =="
      levels = Hash.new(0.0)
      hs.each { |r| levels[mm(r[:min].z)] += r[:area] }
      levels.sort_by { |z, _| z }.each do |z, area|
        out << format('  z=%s mm   total area %d mm2', z, area)
      end
      out << ''

      unless acc[:sloped].empty?
        out << "== SLOPED FACES (#{acc[:sloped].size}) - neither wall nor floor, look at these =="
        acc[:sloped].each do |r|
          out << "  area=#{r[:area]} normal #{vtxt(r[:normal])} min #{ptxt(r[:min])} max #{ptxt(r[:max])} tag=#{r[:tag]}"
        end
        out << ''
      end

      # anything the engine has already built
      built = []
      model.entities.each do |e|
        next unless e.respond_to?(:attribute_dictionary)
        d = e.attribute_dictionary('CabinetEngine')
        built << [e, d] if d
      end
      out << "== EXISTING CabinetEngine OBJECTS (#{built.size}) =="
      built.each do |e, d|
        out << "  #{d['article_code'] || '(no code)'}  status=#{d['status']}  bounds #{ptxt(e.bounds.min)} .. #{ptxt(e.bounds.max)}"
      end
      out << '  none' if built.empty?
      out << ''
      out << 'END'

      text = out.join("\n")
      path = File.join(File.dirname(__FILE__), 'wall_probe_report.txt')
      File.open(path, 'w') { |f| f.write(text) }

      puts '--- UCON wall probe ---'
      puts "vertical faces: #{acc[:vertical].size}   horizontal: #{acc[:horizontal].size}   sloped: #{acc[:sloped].size}"
      puts "containers: #{acc[:containers].size}   existing engine objects: #{built.size}"
      puts "model bounds mm: #{mm(b.width)} x #{mm(b.height)} x #{mm(b.depth)}"
      puts "report written: #{path}"
      puts 'Nothing in the model was changed.'
      text.size
    end
  end
end

UCON::WallProbe.run

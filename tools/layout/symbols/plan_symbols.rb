# tools/layout/symbols/plan_symbols.rb - 2D fixture symbols drawn in LayOut over a plan view, never in the model.
# Andriy 2026-11-04 (1791 ADU v0.7): a WC is not UCON scope - no 3D body in the model, only its centre line as data; on
# the plan it is a scale symbol taken from the shipped LayOut scrapbook (Architecture.layout, page Bath, row 3, 3rd from
# the left), normalised in <key>.json: x from the fixture centre line, y from the back (the wall) into the room, unit =
# overall depth. Elevations show the centre line and the clearance to our cabinet only.
require 'json'
module UCON
  module DrawingSet
    SYM_DIR = __dir__
    SYM_INK = [0x55, 0x57, 0x5C].freeze

    def sym_layer
      @l_sym = nil if @l_sym && @l_sym.document != @doc rescue nil
      @l_sym ||= @doc.layers.add('Fixtures by others', false)
    end

    # plan_symbol(vp, 'wc_plan', cl_x, wall_y, depth: 711, into: -1): along X, the wall at model y = wall_y, the room
    # toward y * into. Bezier control points map with the view (parallel projection = affine), so curves stay exact.
    def plan_symbol(vp, key, cl, wall, depth:, into: -1, along: :x)
      @sym_data ||= {}
      d = (@sym_data[key] ||= JSON.parse(File.read(File.join(SYM_DIR, "#{key}.json"))))
      mp = lambda do |u, v|
        a = cl + u * depth; b = wall + into * v * depth
        x, y = along == :x ? [a, b] : [b, a]
        vp.model_to_paper_point(Geom::Point3d.new(x / 25.4, y / 25.4, 0))
      end
      st = Layout::Style.new
      st.stroked = true; st.stroke_width = 0.35; st.stroke_color = color(SYM_INK); st.solid_filled = false
      made = []
      d['items'].each do |it|
        next unless it['k'] == 'path'
        path = nil; cur = nil; start = nil
        it['s'].each do |s|
          case s[0]
          when 'M' then cur = mp.(s[1], s[2]); start = cur
          when 'L'
            q = mp.(s[1], s[2])
            next if q.distance(path ? path.end_point : cur) < 1e-5
            path ? path.append_point(q) : (path = Layout::Path.new(cur, q))
          when 'C'
            path ||= Layout::Path.new(cur, Geom::Point2d.new(cur.x + 1e-4, cur.y))
            path.append_point(mp.(s[1], s[2]), mp.(s[3], s[4]), mp.(s[5], s[6]))
            cur = mp.(s[5], s[6])
          when 'Z' then path.close if path && path.respond_to?(:close)
          end
        end
        next unless path
        path.style = st
        made << path
      end
      begin
        add(Layout::Group.new(made), sym_layer)
      rescue StandardError
        made.each { |e| add(e, sym_layer) }
      end
      @log << "symbol #{key}: #{made.size} paths at CL #{cl.round}"
    rescue StandardError => e
      @log << "symbol #{key} failed: #{e.class}: #{e.message}"
    end
  end
end

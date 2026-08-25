# tools/void_probe.rb - READ-ONLY: what the front stack actually became.
#
# Select the unit, then run:
#
#   load '/Users/andriydemko/dev/ucon-cabinet-engine/tools/void_probe.rb'
#
# Changes NOTHING. Prints to the console AND writes tools/void_probe_report.txt
# inside the repository.
#
# WHY IT EXISTS. On 2026-08-25 C63640 built and the red band looked right in a
# perspective screenshot - and a screenshot cannot tell 390 from 360 plus an
# empty 30, because the ratios are 4.38 and 4.75 and the camera compresses the
# lower band by about that much. Same trap as the corner turn on 2026-08-24:
# when a symptom can point at two bodies, only a measurement says which.
#
# It reports THREE things side by side:
#   - what the registry says the stack is, in both executions
#   - what Generator.front_slabs derives from it
#   - what is ACTUALLY IN THE MODEL, measured off the drawn geometry
# A disagreement between the second and the third is a drawing bug. A
# disagreement between the first and the second is a loader bug.

module UCON
  module VoidProbe
    MM = 25.4
    module_function

    def to_mm(len); (len.to_f * MM).round(1); end

    def run
      m = Sketchup.active_model
      c = UCON::CabinetEngine::Contract
      g = UCON::CabinetEngine::Generator
      r = UCON::CabinetEngine::Registry
      out = []

      sel = m.selection.grep(Sketchup::ComponentInstance).find do |i|
        i.definition.get_attribute(c::DICTIONARY, 'code')
      end
      if sel.nil?
        puts 'Nothing with a UCON code is selected. Select the unit and run again.'
        return false
      end

      attrs = c.read(sel.definition)
      code  = attrs['code']
      out << "UNIT #{code} - #{attrs['unit_type']} - #{sel.definition.name}"
      out << "  stated: W #{attrs['width_mm']} x H #{attrs['height_mm']} x D #{attrs['depth_mm']}"
      out << "  opening_method: #{attrs['opening_method'].inspect}"
      out << ''

      unit = begin
        r.lookup(code)
      rescue StandardError => e
        out << "  registry lookup failed: #{e.message}"
        nil
      end

      if unit
        fl = unit['front_layout'] || {}
        out << "REGISTRY front_layout kind=#{fl['kind'].inspect}"
        %w[heights_mm_top_to_bottom stack_top_to_bottom gola_stack_top_to_bottom].each do |key|
          v = fl[key]
          next if v.nil? || (v.respond_to?(:empty?) && v.empty?)

          if key == 'heights_mm_top_to_bottom'
            out << "  #{key}: #{v.inspect}  (sum #{v.map(&:to_f).sum})"
          else
            line = v.map { |e| "#{e['kind']}:#{e['h_mm']}" }.join('  ')
            out << "  #{key}: #{line}  (sum #{v.map { |e| e['h_mm'].to_f }.sum})"
          end
        end
        out << ''

        out << 'DERIVED by Generator.front_slabs (the handle execution)'
        begin
          g.front_slabs(unit).sort_by { |s| -s[:z_mm] }.each do |s|
            out << format('  %-26s kind=%-8s z %7.1f .. %7.1f  h %7.1f',
                          s[:name], (s[:kind] || :front).to_s,
                          s[:z_mm], s[:z_mm] + s[:h_mm], s[:h_mm])
          end
        rescue StandardError => e
          out << "  front_slabs raised: #{e.message}"
        end
        out << ''
      end

      out << 'MEASURED off the drawn geometry, z from the unit origin'
      rows = []
      sel.definition.entities.each do |e|
        next unless e.respond_to?(:bounds)
        next if e.is_a?(Sketchup::Edge) || e.is_a?(Sketchup::Face)

        b = e.bounds
        next if b.width.to_f.zero? && b.height.to_f.zero?

        name = e.respond_to?(:name) && !e.name.to_s.empty? ? e.name : e.class.name
        rows << { name: name,
                  z0: to_mm(b.min.z), z1: to_mm(b.max.z),
                  h: to_mm(b.max.z - b.min.z),
                  role: e.get_attribute(c::DICTIONARY, 'void_role'),
                  notes: e.get_attribute(c::DICTIONARY, 'notes') }
      end
      fronts = rows.select { |x| x[:name] =~ /\A(FRONT|VOID_|APPLIANCE_OPENING)/ }
      fronts = rows if fronts.empty?
      fronts.sort_by { |x| -x[:z0] }.each do |x|
        out << format('  %-26s z %7.1f .. %7.1f  h %7.1f%s',
                      x[:name][0, 26], x[:z0], x[:z1], x[:h],
                      x[:role] ? "  void_role=#{x[:role]}" : '')
      end
      out << ''

      # THE GAPS ARE THE ANSWER. A gola execution leaves a real 30 mm of nothing
      # where the profile goes; a handle execution leaves none. Anything else is
      # a bug and it shows up here as a number nobody meant.
      ordered = fronts.sort_by { |x| x[:z0] }
      out << 'GAPS between drawn bands, bottom up'
      if ordered.length < 2
        out << '  only one band - nothing to compare'
      else
        ordered.each_cons(2) do |a, b|
          gap = (b[:z0] - a[:z1]).round(1)
          note = if gap.abs < 0.5 then 'butted'
                 elsif (gap - 30).abs < 0.5 then '30 - a gola recess'
                 elsif gap.negative? then 'OVERLAP - this is a bug'
                 else 'UNEXPECTED'
                 end
          out << format('  %-22s -> %-22s  %7.1f  %s',
                        a[:name][0, 22], b[:name][0, 22], gap, note)
        end
      end
      top = ordered.last
      bottom = ordered.first
      out << ''
      out << format('  bands span %.1f .. %.1f = %.1f, unit height %s',
                    bottom[:z0], top[:z1], (top[:z1] - bottom[:z0]),
                    attrs['height_mm'])
      short = attrs['height_mm'].to_f - (top[:z1] - bottom[:z0])
      out << if short.abs < 0.5
               '  THE FRONT COVERS THE UNIT.'
             else
               format('  SHORT BY %.1f mm - the stack and the drawing disagree.', short)
             end

      rows.select { |x| x[:role] }.each do |x|
        out << ''
        out << "VOID #{x[:name]} (#{x[:role]})"
        out << "  #{x[:notes]}"
      end

      text = out.join("\n")
      puts text
      path = File.join(File.dirname(__FILE__), 'void_probe_report.txt')
      File.open(path, 'w') { |f| f.puts text }
      puts "\nwritten to #{path}"
      true
    end
  end
end

UCON::VoidProbe.run

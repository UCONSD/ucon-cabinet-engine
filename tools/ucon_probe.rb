# frozen_string_literal: true
#
# UCON — model probe. Read-only. Changes nothing, creates nothing in the model.
#
# Moved out of the claude.ai Project 2026-08-25. Probe #4, and the only general
# one: wall_probe reports the room, kitchen_probe reports engine objects,
# side_probe explains the side rule, corner_probe the corner. This one dumps
# the whole tree with a VERTICAL MAP of distinct Z levels, which is how plinth
# tops, reveals, filler gaps and appliance voids are read off directly.
#
# Walks groups and component instances, reports every bounding box in millimetres
# together with tags, attribute dictionaries and materials, then prints a vertical
# map of the distinct Z levels so reveals and fillers can be read off directly.
#
#   load '/Users/andriydemko/dev/ucon-cabinet-engine/tools/ucon_probe.rb'
#
#   UCON::Probe.all                      # whole model, 4 levels deep
#   UCON::Probe.sel                      # selection only, 6 levels deep
#   UCON::Probe.sel(depth: 3)
#   UCON::Probe.all(name: 'fridge')      # only branches whose name matches
#   UCON::Probe.levels                   # just the vertical map of the selection
#   UCON::Probe.save                     # same as .sel but written to a .txt file
#
# Output goes to the Ruby Console. `save` also writes a file and shows the path.

require 'sketchup.rb'

module UCON
  module Probe
    extend self

    MM = 25.4

    def mm(len)
      (len.to_f * MM).round(1)
    end

    def fmt(v)
      v == v.to_i ? v.to_i.to_s : format('%.1f', v)
    end

    # ------------------------------------------------------------------ walk

    def entities_of(ent)
      case ent
      when Sketchup::ComponentInstance then ent.definition.entities
      when Sketchup::Group             then ent.entities
      end
    end

    def label(ent)
      case ent
      when Sketchup::ComponentInstance
        n = ent.name.to_s.strip
        d = ent.definition.name.to_s.strip
        n.empty? ? "C <#{d}>" : "C #{n} <#{d}>"
      when Sketchup::Group
        n = ent.name.to_s.strip
        n.empty? ? 'G (unnamed)' : "G #{n}"
      else
        ent.class.name.split('::').last
      end
    end

    def bbox_line(ent)
      b = ent.bounds
      lo = b.min
      hi = b.max
      format('x %s..%s  y %s..%s  z %s..%s   =  %s x %s x %s',
             fmt(mm(lo.x)), fmt(mm(hi.x)),
             fmt(mm(lo.y)), fmt(mm(hi.y)),
             fmt(mm(lo.z)), fmt(mm(hi.z)),
             fmt(mm(b.width)), fmt(mm(b.depth)), fmt(mm(b.height)))
    end

    def attrs_of(ent)
      out = []
      [ent, (ent.respond_to?(:definition) ? ent.definition : nil)].compact.each do |holder|
        dicts = holder.attribute_dictionaries
        next unless dicts

        dicts.each do |d|
          next if d.name.to_s.start_with?('SU_') # SketchUp internals

          d.each_pair do |k, v|
            out << "#{d.name}.#{k} = #{v.inspect}"
          end
        end
      end
      out.uniq
    end

    def material_of(ent)
      m = ent.material
      m ? m.display_name : nil
    end

    def tag_of(ent)
      l = ent.layer
      l ? l.name : nil
    end

    def walk(ent, depth, max_depth, filter, out, level_map, path = [])
      name = label(ent)
      here = path + [name]
      matched = filter.nil? || here.any? { |s| s.downcase.include?(filter) }

      if matched
        pad = '  ' * depth
        out << "#{pad}#{name}"
        out << "#{pad}    #{bbox_line(ent)}"
        t = tag_of(ent)
        out << "#{pad}    tag: #{t}" if t && t != 'Layer0' && t != 'Untagged'
        mat = material_of(ent)
        out << "#{pad}    material: #{mat}" if mat
        attrs_of(ent).each { |a| out << "#{pad}    attr: #{a}" }

        b = ent.bounds
        level_map[mm(b.min.z).round] ||= []
        level_map[mm(b.min.z).round] << "#{name} bottom"
        level_map[mm(b.max.z).round] ||= []
        level_map[mm(b.max.z).round] << "#{name} top"
      end

      return if depth >= max_depth

      ents = entities_of(ent)
      return unless ents

      kids = ents.grep(Sketchup::ComponentInstance) + ents.grep(Sketchup::Group)
      kids.sort_by! { |k| [k.bounds.min.x, k.bounds.min.z] }
      kids.each { |k| walk(k, depth + 1, max_depth, filter, out, level_map, here) }
    end

    # --------------------------------------------------------------- reports

    def vertical_map(level_map)
      out = ['', '=== VERTICAL MAP (mm from model origin) ===']
      level_map.keys.sort.each do |z|
        who = level_map[z].uniq
        who = who.first(4) + ["… +#{who.size - 4} more"] if who.size > 4
        out << format('  %8s   %s', fmt(z), who.join(' | '))
      end
      out << ''
      out << 'Gaps between consecutive levels:'
      zs = level_map.keys.sort
      zs.each_cons(2) do |a, b|
        d = b - a
        out << format('  %8s -> %-8s  %s mm', fmt(a), fmt(b), fmt(d)) if d.abs >= 0.5
      end
      out
    end

    def summary(model)
      tags = model.layers.map(&:name).sort
      defs = model.definitions.reject(&:image?).map { |d| [d.name, d.count_used_instances] }
                  .select { |_n, c| c.positive? }.sort_by { |n, _c| n }
      out = ['', '=== MODEL SUMMARY ===',
             "units: #{model.options['UnitsOptions']['LengthUnit']} (probe reports mm)",
             "tags (#{tags.size}): #{tags.join(', ')}", '', "definitions in use (#{defs.size}):"]
      defs.each { |n, c| out << format('  %-52s x%d', n[0, 52], c) }
      out
    end

    def run(roots, depth, filter, model)
      out = []
      level_map = {}
      out << "=== UCON PROBE ==="
      out << "model: #{model.title.to_s.empty? ? '(unsaved)' : model.title}"
      out << "roots: #{roots.size}, depth: #{depth}, filter: #{filter || '(none)'}"
      out << ''
      roots.each { |r| walk(r, 0, depth, filter, out, level_map) }
      out += vertical_map(level_map)
      out += summary(model)
      text = out.join("\n")
      puts text
      text
    end

    # ----------------------------------------------------------------- entry

    def all(depth: 4, name: nil)
      m = Sketchup.active_model
      roots = m.entities.grep(Sketchup::ComponentInstance) + m.entities.grep(Sketchup::Group)
      run(roots.sort_by { |e| e.bounds.min.x }, depth, name && name.downcase, m)
    end

    def sel(depth: 6, name: nil)
      m = Sketchup.active_model
      roots = m.selection.to_a.select do |e|
        e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
      end
      if roots.empty?
        UI.messagebox('Select at least one group or component, then run UCON::Probe.sel again.')
        return
      end
      run(roots.sort_by { |e| e.bounds.min.x }, depth, name && name.downcase, m)
    end

    def levels(depth: 8)
      m = Sketchup.active_model
      roots = m.selection.to_a.select do |e|
        e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
      end
      roots = m.entities.grep(Sketchup::ComponentInstance) + m.entities.grep(Sketchup::Group) if roots.empty?
      out = []
      level_map = {}
      roots.each { |r| walk(r, 0, depth, nil, out, level_map) }
      text = vertical_map(level_map).join("\n")
      puts text
      text
    end

    # Writes the probe of the current selection (or the whole model if nothing
    # is selected) to a text file, so it can be handed over whole.
    def save(depth: 6, name: nil)
      m = Sketchup.active_model
      roots = m.selection.to_a.select do |e|
        e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
      end
      roots = m.entities.grep(Sketchup::ComponentInstance) + m.entities.grep(Sketchup::Group) if roots.empty?
      text = run(roots.sort_by { |e| e.bounds.min.x }, depth, name && name.downcase, m)
      default = (m.title.to_s.empty? ? 'model' : m.title) + '_probe.txt'
      path = UI.savepanel('Save UCON probe', nil, default)
      return unless path

      path += '.txt' unless File.extname(path).downcase == '.txt'
      File.open(path, 'w') { |f| f.write(text) }
      UI.messagebox("Probe written to:\n#{path}")
      path
    end
  end
end

puts 'UCON::Probe loaded. Try: UCON::Probe.sel   or   UCON::Probe.save'

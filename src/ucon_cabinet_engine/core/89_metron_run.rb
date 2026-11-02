# frozen_string_literal: true
#
# UCON Cabinet Engine — core/89_metron_run.rb  ::  SketchUp glue for core/87_metron.rb ("Export to Metron").
#
# NO RULES LIVE HERE - same split as 86_export_run. This file finds the rooms, measures the bodies in room-local
# millimetres, reads UCON_METRON and hands plain hashes to Metron.room. What a body becomes is 87_metron's business.
#
# A ROOM is a group carrying UCON_METRON 'room' (in the 7612 bath model: the wall group 'L-BA3 Bath 3'). Its zero is
# STATED (origin_x_mm / origin_y_mm), not found: the wall groups all sit at the model origin (probe 910), so guessing a
# corner off the walls would be a guess. Membership is by position, as in the drawing set: a body whose centre lies
# within the room's width, 1500 deep from the back wall, below its height. The units are top-level instances, not
# children of the room group.
#
# MEASURED LIKE THE DRAWING SET: an instance is measured on its parts that are NOT on a UCON tag (the plan / door
# symbols on UCON tags reach the floor and 1 m into the room - probe 327), i.e. carcass + fronts.
#
# Output: <repo>/metron/export/<project>/<room>.export.json, the format of metron/export/fixtures/. It goes to the
# laptop through git (go.sh); metron/laptop/gen/room_from_skp.py turns it into the room JSON for rit_build.py.
require 'json'

module UCON
  module CabinetEngine
    module MetronRun
      module_function

      # realpath: the engine reaches Plugins through a SYMLINK, and __dir__ there is the link's side - three levels up
      # from it is SketchUp's own folder, not the repository.
      EXPORT_DIR = File.expand_path('../../../metron/export', File.realpath(__dir__))

      def mm(v)
        v.to_f * 25.4
      end

      def room_attrs(group)
        d = group.attribute_dictionary(Metron::DICTIONARY)
        d ? d.to_h : nil
      end

      def rooms(model = Sketchup.active_model)
        model.entities.grep(Sketchup::Group).select { |g| (a = room_attrs(g)) && !a['room'].to_s.empty? }
      end

      def body_bounds(inst)
        bb = Geom::BoundingBox.new
        inst.definition.entities.each do |c|
          next unless c.is_a?(Sketchup::Group) || c.is_a?(Sketchup::ComponentInstance)
          next if c.layer.name.start_with?('UCON')
          (0..7).each { |k| bb.add(c.bounds.corner(k).transform(inst.transformation)) }
        end
        bb.empty? ? inst.bounds : bb
      end

      def metron_of(ent)
        d = ent.attribute_dictionary(Metron::DICTIONARY)
        d ||= ent.definition.attribute_dictionary(Metron::DICTIONARY) if ent.respond_to?(:definition)
        d ? d.to_h : nil
      end

      # -> [room attrs, [body hashes]]
      def bodies(group, model = Sketchup.active_model)
        ra = room_attrs(group) or raise ArgumentError, "#{group.name}: no #{Metron::DICTIONARY} on the room group"
        ox = ra['origin_x_mm'].to_f; oy = ra['origin_y_mm'].to_f
        w  = ra['width_mm'].to_f; h = (ra['height_mm'] || 4000).to_f
        raise ArgumentError, "#{group.name}: width_mm is not stated" unless w.positive?
        out = []
        model.entities.each do |e|
          next if e == group
          next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
          # another ROOM - a group whose UCON_METRON names a room. A panel or a top carries UCON_METRON too (kind, code),
          # and the first version skipped them as 'rooms' (probe 911, 2026-10-29: 4 items of 7).
          next if e.is_a?(Sketchup::Group) && !(room_attrs(e) || {})['room'].to_s.empty?
          b = e.is_a?(Sketchup::ComponentInstance) ? body_bounds(e) : e.bounds
          cx = mm(b.center.x) - ox; cy = mm(b.center.y) - oy; cz = mm(b.center.z)
          next unless cx.between?(-50, w + 50) && cy.between?(-1500, 50) && cz < h
          ce = e.is_a?(Sketchup::ComponentInstance) ? (Contract.read(e.definition) || {}) : {}
          t = e.transformation
          out << { ref: e.persistent_id.to_s, name: e.name.to_s, code: ce['code'], object_class: ce['object_class'],
                   mounting: ce['mounting'], metron: metron_of(e),
                   x0: mm(b.min.x) - ox, x1: mm(b.max.x) - ox, y0: mm(b.min.y) - oy, y1: mm(b.max.y) - oy,
                   z0: mm(b.min.z), z1: mm(b.max.z),
                   rot_deg: (Math.atan2(t.xaxis.y, t.xaxis.x) * 180 / Math::PI).round }
        end
        [ra, out]
      end

      def export_room(group, model = Sketchup.active_model, dir = EXPORT_DIR)
        ra, bs = bodies(group, model)
        out = Metron.room(bs, ra)
        out['source'] = "#{File.basename(model.path.to_s)} / #{group.name}"
        proj = ra['room'].to_s.split('-').first
        path = File.join(dir, proj, "#{ra['room'].to_s.tr('-', '_')}.export.json")
        Dir.mkdir(File.dirname(path)) unless File.directory?(File.dirname(path))
        File.write(path, JSON.pretty_generate(out) + "\n")
        [path, out]
      end

      # The palette button. Selected room group(s) if any are selected, otherwise every room in the model.
      def run(model = Sketchup.active_model)
        sel = model.selection.grep(Sketchup::Group).select { |g| room_attrs(g) }
        list = sel.empty? ? rooms(model) : sel
        if list.empty?
          UI.messagebox("No room carries #{Metron::DICTIONARY} 'room' - nothing to export.")
          return nil
        end
        lines = list.map do |g|
          path, out = export_room(g, model)
          miss = out['not_exported'] ? " - NOT EXPORTED: #{out['not_exported'].map { |m| m['code'] }.join(', ')}" : ''
          "#{out['room']}: #{out['items'].size} item(s) -> #{File.basename(path)}#{miss}"
        rescue ArgumentError => e
          "#{g.name}: REFUSED - #{e.message}"
        end
        UI.messagebox("Export to Metron (#{EXPORT_DIR}):\n\n#{lines.join("\n")}")
        lines
      end
    end
  end
end

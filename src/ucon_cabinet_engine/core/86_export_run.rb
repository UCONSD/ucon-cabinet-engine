# frozen_string_literal: true
#
# UCON Cabinet Engine — core/86_export_run.rb
#
# SketchUp glue for the order schedule. Walks the model, reads the contract off
# every object, hands the attribute hashes to core/85_export.rb, writes a file.
#
# NO RULES LIVE HERE. What counts as orderable, how a row is shaped, what a
# quantity means - all of that is in 85_export, which is pure and tested. This
# file exists only because something has to touch Sketchup, and the same split
# is why 22_placement holds the placement rules while 75_place_tool clicks.

module UCON
  module CabinetEngine
    module ExportRun
      module_function

      # ONE ROW PER INSTANCE, not per definition. Two instances of one
      # definition are two cabinets standing in the kitchen and two positions on
      # the order. Collapsing them into a single line with qty 2 would be a
      # guess about how Cesar writes the sheet - and the estimate now with Elda
      # contains repeated units, so it will show which it is. Until then the
      # honest reading is that a position is a position.
      MAX_DEPTH = 8

      def objects(model = Sketchup.active_model)
        collect(model.entities, [])
      end

      # Descends into groups and into components that are NOT themselves
      # orderable. An orderable component is a leaf on purpose: a cabinet's
      # parts are geometry, not separate order lines, and the factory explodes
      # the article into components itself.
      def collect(entities, out, depth = 0)
        return out if depth > MAX_DEPTH

        entities.each do |ent|
          if ent.is_a?(Sketchup::ComponentInstance)
            attrs = Contract.read(ent.definition)
            if Export.orderable?(attrs)
              out << attrs
            else
              collect(ent.definition.entities, out, depth + 1)
            end
          elsif ent.is_a?(Sketchup::Group)
            collect(ent.entities, out, depth + 1)
          end
        end
        out
      end

      def run(model = Sketchup.active_model)
        found = objects(model)
        rows  = Export.rows(found)
        if rows.empty?
          UI.messagebox('No UCON objects in this model — nothing to export.')
          return nil
        end

        path = UI.savepanel('Save order schedule', '', default_name(model))
        return nil unless path

        path = "#{path}.csv" unless path.to_s.downcase.end_with?('.csv')
        File.write(path, Export.csv(rows))
        UI.messagebox(
          "Order schedule written:\n\n#{path}\n\n" \
          "#{found.length} object(s), #{rows.length} row(s).\n\n" \
          'Empty quantity cells are the ones no single object can answer - a ' \
          'linear-metre profile is measured along the RUN, and a handle count ' \
          'follows the fronts. The note column says which is which.'
        )
        path
      end

      def default_name(model = Sketchup.active_model)
        base = model.title.to_s.strip
        base = 'ucon' if base.empty?
        "#{base.gsub(/[^\w\-]+/, '_')}_order.csv"
      end
    end
  end
end

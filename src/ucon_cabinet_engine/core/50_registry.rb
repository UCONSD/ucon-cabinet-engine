# frozen_string_literal: true
#
# UCON Cabinet Engine — core/50_registry.rb
#
# Reads registry/cesar.json and answers "what is code B80601?".
#
# Rules as data (Object Contract §5): this file contains NO catalog facts —
# they all live in the JSON, verified against the source PDF. This file only
# knows how to look them up. Pure Ruby, no SketchUp: runs headless.
#
# The registry is re-read on every lookup. At our scale (KBs) that costs
# nothing and means an edited JSON is live on the next build — same philosophy
# as the core reload itself.

require 'json'

module UCON
  module CabinetEngine
    module Registry
      module_function

      def repo_root
        File.expand_path('../../..', __dir__)
      end

      def registry_path(manufacturer = 'cesar')
        File.join(repo_root, 'registry', "#{manufacturer}.json")
      end

      def data(manufacturer = 'cesar')
        path = registry_path(manufacturer)
        raise "Registry not found: #{path}" unless File.exist?(path)

        JSON.parse(File.read(path))
      end

      # All codes across every family and unit type.
      def codes(manufacturer = 'cesar')
        each_code(data(manufacturer)).map { |row, _, _, _| row['code'] }
      end

      # Look a code up. Returns a flat hash with everything the generator
      # needs, or raises with a list of near misses.
      def lookup(code, manufacturer = 'cesar')
        reg = data(manufacturer)
        each_code(reg) do |row, family_name, family, type_key, unit_type|
          next unless row['code'] == code

          return {
            'code'               => code,
            'manufacturer'       => reg['manufacturer'],
            'family'             => family_name,
            'height_mm'          => family['height_mm'],
            'width_mm'           => row['width_mm'],
            'depth_mm'           => row['depth_mm'],
            'unit_type'          => type_key,
            'description'        => unit_type['description'],
            'opening'            => unit_type['opening'],
            'handed'             => unit_type['handed'],
            'interior_confirmed' => unit_type['interior_confirmed'] || [],
            'front_layout'       => unit_type['front_layout'],
            'source_ref'         => "#{reg['source_pdf']} #{unit_type['source_ref']}",
            'registry_status'    => reg['registry_status']
          }
        end
        raise ArgumentError,
              "Code #{code.inspect} is not in the registry. Known codes: " +
              codes(manufacturer).sort.join(', ')
      end

      # Iterate every code row. With a block, yields
      # (row, family_name, family, type_key, unit_type); without, returns an
      # array of those tuples.
      def each_code(reg)
        tuples = []
        (reg['families'] || {}).each do |family_name, family|
          (family['unit_types'] || {}).each do |type_key, unit_type|
            (unit_type['codes'] || []).each do |row|
              tuple = [row, family_name, family, type_key, unit_type]
              block_given? ? yield(*tuple) : tuples << tuple
            end
          end
        end
        tuples
      end
    end
  end
end

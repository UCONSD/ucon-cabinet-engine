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

      def registry_dir(manufacturer = 'cesar')
        File.join(repo_root, 'registry', manufacturer)
      end

      # The catalog is stored as one file per catalog section:
      #   registry/cesar/_manifest.json  - shared facts (grammar, hardware,
      #                                    external specs, order axes)
      #   registry/cesar/<section>.json  - one catalog section: class,
      #                                    section title, family, unit types
      # One extracted catalog page = one file = one commit. The loader merges
      # everything into the same structure the old single file had, so
      # nothing downstream changes. Sections sharing a family (e.g. Sink base
      # H.78) merge their unit_types into that family; each unit type is
      # stamped with its section and class for the picker.
      #
      # Cached by mtime: unchanged files are not re-read; an edited file is
      # picked up on the next call - same hot-edit behaviour as before.
      def data(manufacturer = 'cesar')
        dir = registry_dir(manufacturer)
        raise "Registry directory not found: #{dir}" unless File.directory?(dir)

        files  = Dir.glob(File.join(dir, '*.json')).sort
        stamps = files.map { |f| [f, File.mtime(f).to_f] }.to_h
        @cache ||= {}
        cached = @cache[manufacturer]
        return cached[:data] if cached && cached[:stamps] == stamps

        manifest_path = File.join(dir, '_manifest.json')
        raise "Registry manifest missing: #{manifest_path}" unless File.exist?(manifest_path)

        merged = JSON.parse(File.read(manifest_path))
        merged['families'] ||= {}
        (files - [manifest_path]).each do |file|
          sec = JSON.parse(File.read(file))
          fam_name = sec['family']
          raise "#{file}: section file must name its 'family'" unless fam_name

          fam = merged['families'][fam_name] ||= {}
          payload = sec['data'] || {}
          (payload['unit_types'] || {}).each do |key, unit_type|
            unit_type['section'] = sec['section'] if sec['section']
            unit_type['class']   = sec['class'] if sec['class']
            (fam['unit_types'] ||= {})[key] = unit_type
          end
          payload.each { |k, v| fam[k] = v unless k == 'unit_types' }
        end

        @cache[manufacturer] = { stamps: stamps, data: merged }
        merged
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
            # How the family meets the room. Catalog-level, not per code: every
            # unit in the wall chapter hangs. Absent means floor, so no existing
            # section file has to say anything.
            'mounting'           => family['mounting'] || 'floor',
            # Which door heights this FAMILY offers, or nil when it offers no
            # such choice. The 78/75 pair belongs to the base pages; a wall
            # unit 360 tall has no version to pick.
            'door_versions'      => family['door_versions'],
            'width_mm'           => row['width_mm'],
            'depth_mm'           => row['depth_mm'],
            'unit_type'          => type_key,
            'description'        => unit_type['description'],
            'opening'            => unit_type['opening'],
            'handed'             => unit_type['handed'],
            'interior_confirmed' => unit_type['interior_confirmed'] || [],
            'front_layout'       => unit_type['front_layout'],
            'object_class'       => unit_type['object_class'] || 'cabinet',
            'geometry_kind'      => unit_type['geometry_kind'] || 'linear',
            'buildable'          => unit_type.fetch('buildable', true),
            'not_buildable_reason' => unit_type['not_buildable_reason'],
            'corner_geometry'    => row['corner_geometry'],
            'execution'          => row['execution'],
            'door_width_mm'      => row['door_width_mm'],
            'carcass_length_mm'  => row['carcass_length_mm'],
            'companions'         => unit_type['companions'] || [],
            'source_ref'         => "#{reg['source_pdf']} #{unit_type['source_ref']}",
            'registry_status'    => reg['registry_status']
          }
        end
        raise ArgumentError,
              "Code #{code.inspect} is not in the registry. Known codes: " +
              codes(manufacturer).sort.join(', ')
      end

      # Flat catalog for pickers: every code with its type, dims and source.
      def catalog(manufacturer = 'cesar')
        each_code(data(manufacturer)).map do |row, family_name, family, type_key, unit_type|
          { 'code' => row['code'], 'width_mm' => row['width_mm'],
            'depth_mm' => row['depth_mm'], 'height_mm' => family['height_mm'],
            'family' => family_name, 'type_key' => type_key,
            'description' => unit_type['description'],
            'source_ref' => unit_type['source_ref'],
            'section' => unit_type['section'], 'class' => unit_type['class'],
            'geometry_kind' => unit_type['geometry_kind'] || 'linear',
            'buildable' => unit_type.fetch('buildable', true),
            'not_buildable_reason' => unit_type['not_buildable_reason'],
            'corner_geometry' => row['corner_geometry'],
            'execution' => row['execution'],
            'door_width_mm' => row['door_width_mm'],
            'carcass_length_mm' => row['carcass_length_mm'] }
        end
      end

      # ---- catalog map (what the printed index says exists) --------------
      #
      # The registry holds what we HAVE extracted. The map in _manifest.json
      # holds what the catalog SAYS exists, read from the printed chapter
      # index. The difference between the two is the honest list of gaps, and
      # it is data — the picker renders it, it does not invent it.
      STATUSES = %w[extracted partial not_extracted planned excluded].freeze

      def catalog_map(manufacturer = 'cesar')
        data(manufacturer)['catalog_map'] || {}
      end

      def map_sections(manufacturer = 'cesar')
        catalog_map(manufacturer)['sections'] || []
      end

      # Everything the picker should show greyed out, in the order the catalog
      # prints it. Two levels only, and each is bounded by what we actually
      # read: a SECTION gap comes from the printed index; a TYPE gap comes
      # from a page we have opened. Never invent a level deeper than the
      # source we have seen.
      def gaps(manufacturer = 'cesar')
        have = catalog(manufacturer).map { |r| r['section'] }.uniq
        map_sections(manufacturer).flat_map do |sec|
          pages = sec['pages'] || []
          if have.include?(sec['section'])
            pages.reject { |pg| pg['status'] == 'extracted' }.map do |pg|
              gap_row('type', sec, pg)
            end
          else
            # One row per SECTION, never one per page: the printed index lists
            # a section once, and the picker level is the section. Pages we
            # have read hang inside it as detail.
            row = gap_row('section', sec, nil)
            row['pages'] = pages.map do |pg|
              { 'printed' => "p.#{pg['printed']}",
                'status'  => pg['status'],
                'types'   => normalize_types(pg, pg['status']),
                'note'    => pg['note'] }
            end
            [row]
          end
        end
      end

      def gap_row(level, sec, page)
        status = page ? page['status'] : sec['status']
        {
          'level'        => level,
          'class'        => sec['class'],
          'section'      => sec['section'],
          'family'       => sec['family'],
          'printed'      => page ? "p.#{page['printed']}" : "p.#{sec['printed_pages']}",
          'status'       => status,
          'types'        => normalize_types(page, status),
          'note'         => (page ? page['note'] : sec['note'])
        }
      end

      # A unit type in the map may be written either as a bare string, meaning
      # "same status as its page", or as an object with its own status and
      # reason. The second form exists because a decision is usually about a
      # POSITION, not about a whole catalog page: p.47 keeps the dishwasher
      # door while its fridge housings are excluded.
      def normalize_types(page, fallback_status)
        ((page || {})['types'] || []).map do |t|
          if t.is_a?(String)
            { 'title' => t, 'status' => fallback_status, 'note' => nil }
          else
            { 'title'  => t['title'],
              'status' => t['status'] || fallback_status,
              'note'   => t['note'] }
          end
        end
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

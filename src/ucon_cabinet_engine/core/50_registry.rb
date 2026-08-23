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
        # Which file declared each family-level key, so the collision guard can
        # name BOTH sides of a disagreement instead of just complaining.
        origin = {}
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
          merge_family_keys!(fam, payload, fam_name, File.basename(file),
                             origin[fam_name] ||= {})
        end

        @cache[manufacturer] = { stamps: stamps, data: merged }
        merged
      end

      # FAMILY-LEVEL KEYS MERGE ACROSS FILES, AND USED TO DO IT SILENTLY.
      #
      # Several section files may name the same family - three of them say
      # "H.78" - and everything outside unit_types was merged last-file-wins
      # with no complaint. Two files stating a family fact differently meant
      # one of them simply never happened, and alphabetical order decided
      # which. That is the same class of loss as a duplicated JSON key: no
      # parser reports it and nothing downstream looks wrong.
      #
      # It came within one line of biting on 2026-08-22. plinth_h_mm is a
      # family fact and three files could have carried it; it survived only
      # because it was deliberately declared in ONE of them and a test read it
      # back through a code out of each. That test defends one key. This
      # defends all of them.
      #
      # AGREEMENT IS FINE and must stay fine: every H.78 file states
      # height_mm 780, and saying the same thing twice is redundant rather
      # than wrong. Only a DISAGREEMENT raises, and the message names both
      # files, because the hard part of this bug was never the fix.
      def merge_family_keys!(fam, payload, fam_name, file, origin)
        payload.each do |k, v|
          next if k == 'unit_types'

          first = origin[k]
          if first && fam[k] != v
            raise "Registry conflict: family #{fam_name.inspect} gets #{k.inspect} " \
                  "from two section files that disagree - #{first} says " \
                  "#{fam[k].inspect} and #{file} says #{v.inspect}. A family fact " \
                  'belongs in ONE file; the other must drop it, not restate it.'
          end
          fam[k] = v
          # ||=, not =. The useful name in the error is the file that FIRST
          # stated the fact, because that is where it lives and where a reader
          # will go looking; a third file agreeing must not quietly become the
          # answer to "who says this".
          origin[k] ||= file
        end
        fam
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
            # THE SAME VALUE UNDER A SECOND NAME, and the duplication is the
            # point. 'mounting' is what this object currently IS, and a chosen
            # wall-hung option overwrites it; 'mounting_default' is what the
            # FAMILY says and never moves. Telling the two apart is what lets a
            # wall unit take the project hanging height while a base unit
            # somebody CHOSE to hang keeps its run's worktop line instead.
            'mounting_default'   => family['mounting'] || 'floor',
            # base | wall | tall, stamped onto the unit type by the loader from
            # its section file. The wall-hung fixing article differs by it: two
            # fixings for a base, four for a tall.
            'unit_class'         => unit_type['class'],
            # How tall this family's plinth is. A FAMILY fact, exactly like
            # 'mounting' above: H.78 stands on 100, H.84 on 60, and the
            # factory drawings print it. Absent means the family has not said
            # and Standards::PLINTH_H_MM is the fallback. ZERO IS NOT ABSENT -
            # it means the carcass stands on the floor with no plinth.
            'plinth_h_mm'        => family['plinth_h_mm'],
            # Whether the run's plinth carries on under this object. Only a
            # panel ever needs to say so: a cabinet gets one by standing on the
            # floor, and a panel gets one only where the drawing would
            # otherwise show a break. Absent means no.
            'plinth_continues'   => family['plinth_continues'] ? true : false,
            # Where the client's machine really begins and ends, when the
            # family knows. Absent means the old rule: floor to the top of the
            # panel, which is right for a dishwasher and wrong for a housing.
            'appliance_niche'    => family['appliance_niche'],
            # Which door heights this FAMILY offers, or nil when it offers no
            # such choice. The 78/75 pair belongs to the base pages; a wall
            # unit 360 tall has no version to pick.
            'door_versions'      => family['door_versions'],
            'width_mm'           => row['width_mm'],
            # THE WIDTH A FILLER IS ORDERED AT IS NOT IN ITS CODE. printed p.434
            # prices fillers by HEIGHT alone: one article covers every width
            # from 2,3 to 15 cm. The row states the RANGE and 'width_mm' above
            # is nil; Registry.with_ordered_width turns the range into a
            # number. Absent means the ordinary case - the catalog stated the
            # width and it is right above this line.
            'width_range_mm'     => row['width_range_mm'],
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
            # THE GUARD Generator.wall_hung_available? READS. It was written on
            # 2026-08-22 as the one way a row could refuse the hung version, and
            # the loader never carried it - so for a day the escape hatch could
            # not be reached from any data. printed p.37 is the first page that
            # needs it: 'not available wall hung', in the catalog's own words.
            'wall_hung'          => unit_type['wall_hung'],
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

      # The same corner article in the other execution: same node, same door,
      # same depth - the other end carrying the door and the 8x8.
      #
      # This is a LOOKUP, never a string edit. The letter happens to be the last
      # character today, but a code is an opaque catalog fact and building one by
      # swapping a character is exactly the habit the registry exists to prevent.
      def sibling_execution_code(code, manufacturer = 'cesar')
        me = lookup(code, manufacturer)
        return nil unless me['corner_geometry'] && me['execution']

        each_code(data(manufacturer)) do |row, _fam_name, _fam, _type_key, _unit_type|
          next if row['code'] == code
          next unless row['corner_geometry'] == me['corner_geometry']
          next unless row['execution'] && row['execution'] != me['execution']
          next unless row['door_width_mm'] == me['door_width_mm']

          return row['code']
        end
        nil
      end

      # Flat catalog for pickers: every code with its type, dims and source.
      # THE INCH SIZE A WIDTH WAS BUILT TO, or nil. Looked up, never computed:
      # 610 is the catalog rounding 24 inches (609,6) to the centimetre, so
      # dividing 610 back by 25,4 gives 24 1/16 - a size nobody ordered. The
      # six values are catalog data; printed p.418 prints them as their own
      # INCH column beside the centimetres. No metric width in this catalog
      # collides with any of them, so the width alone resolves it.
      def nominal_in(width_mm, manufacturer = 'cesar')
        return nil unless width_mm

        table = (data(manufacturer)['nominal_widths_in'] || {})['mm_to_in'] || {}
        table[width_mm.to_i.to_s]
      end

      # ---- the ordered width (printed p.434) -----------------------------
      #
      # THE THIRD ORDER AXIS OUTSIDE THE CODE, after door_version and
      # hinge_side, and the first that is a DIMENSION rather than a choice from
      # a list. A filler article covers every width from 2,3 to 15 cm; the
      # catalog prints the range and declines to print the width, exactly as it
      # prints "1 rh or lh door" and declines to print the hand.
      #
      # DELIBERATELY NOT DONE by widening Generator::INSTANCE_KEYS. That guard
      # says an object may not out-vote the registry about what article it is,
      # and it must keep saying so. A filler's width out-votes nothing: there
      # is nothing to out-vote, because the catalog never stated it.
      #
      # Pure, and raises rather than defaulting. A filler silently built at the
      # bottom of its range would be a drawing nobody could tell was wrong.
      def with_ordered_width(unit, width_mm)
        range = unit['width_range_mm']

        if range.nil?
          return unit if width_mm.nil? || width_mm.to_s.empty?

          raise ArgumentError,
                "#{unit['code']} states its own width (#{unit['width_mm']} mm). " \
                'A width is ordered only for an article whose catalog row gives ' \
                'a range instead of a width.'
        end

        lo, hi = range
        if width_mm.nil? || width_mm.to_s.empty?
          raise ArgumentError,
                "#{unit['code']} has no width in the catalog: one article covers " \
                "#{lo} to #{hi} mm and the width is stated per order. Ask for it " \
                'before building.'
        end

        w = begin
          Integer(width_mm)
        rescue ArgumentError, TypeError
          nil
        end
        if w.nil?
          raise ArgumentError,
                "A filler width is a whole number of millimetres; got #{width_mm.inspect}."
        end

        unless w >= lo && w <= hi
          raise ArgumentError,
                "#{unit['code']} is made from #{lo} to #{hi} mm; #{w} is outside " \
                'that. The range is the catalog\'s, printed on the page the row cites.'
        end

        unit.merge('width_mm' => w)
      end

      def catalog(manufacturer = 'cesar')
        each_code(data(manufacturer)).map do |row, family_name, family, type_key, unit_type|
          { 'code' => row['code'], 'width_mm' => row['width_mm'],
            'width_range_mm' => row['width_range_mm'],
            'nominal_in' => nominal_in(row['width_mm'], manufacturer),
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

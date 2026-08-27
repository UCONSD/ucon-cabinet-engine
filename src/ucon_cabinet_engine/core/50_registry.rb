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
            # WHICH BOOK THIS SECTION CAME OUT OF, 2026-08-27.
            #
            # For nine days every section file in this registry was the Kitchen
            # System, so source_pdf lived once in _manifest.json and lookup
            # pasted it in front of every source_ref. The first Linear Elements
            # code would therefore have cited the wrong volume - printed p.214
            # of a book that has no p.214 of panels - and it would have looked
            # right, because the page number is real in both.
            #
            # So it is a SECTION fact now, stamped here beside section and class
            # for the same reason they are: the unit type is what lookup can
            # see. The manifest's value stays as the default, which is honest -
            # fifty-five of the fifty-six files really are Volume 2.
            unit_type['source_pdf'] = sec['source_pdf'] if sec['source_pdf']
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

          # THE UNIT TYPE ANSWERS FIRST, THE FAMILY ONLY IF IT DOES NOT.
          # 2026-08-24: 'plinth_continues' and 'appliance_niche' below were
          # read from the family alone, and for a dishwasher panel that could
          # never work. Family H.78 is THREE merged files - the base pages, the
          # sink bases and these appliance panels - so switching the flag on
          # there to reach one machine would have drawn a plinth inside 131
          # base units and handed them a housing they do not have. The question
          # is about ONE object, so the object gets to answer it. The family
          # stays the fallback, and for USA Tall H.210 - where every member IS
          # a panel - it stays the right place to say it once.
          scoped = lambda do |key|
            unit_type.key?(key) ? unit_type[key] : family[key]
          end

          return {
            'code'               => code,
            'manufacturer'       => reg['manufacturer'],
            'family'             => family_name,
            # HEIGHT IS NORMALLY A FAMILY FACT AND SOMETIMES A ROW FACT.
            # Every section extracted before 2026-08-26 is one height family
            # per file - H.78 is 780 for all 262 of its codes - so the family
            # said it once. The end-panel pages are the first section where
            # ONE table spans sixteen heights: printed p.440 prices PB0030 at
            # H.36 and C00030 at H.234 side by side, and the height is what the
            # code IS. So the row answers first and the family stays the
            # fallback, the same precedence 'scoped' uses above for
            # plinth_continues and appliance_niche. A file that says nothing
            # per row is unaffected.
            'height_mm'          => (row['height_mm'] || family['height_mm']),
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
            'plinth_continues'   => scoped.call('plinth_continues') ? true : false,
            # Where the client's machine really begins and ends, when the
            # family knows. Absent means the old rule: floor to the top of the
            # panel, which is right for a dishwasher and wrong for a housing.
            'appliance_niche'    => scoped.call('appliance_niche'),
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
            # AND THE SAME FOR THE HEIGHT, 2026-08-27. This line is the exact
            # bug the wall_hung key had on 2026-08-22: the data was written
            # correctly in the section file and the loader did not carry it, so
            # the escape hatch could not be reached from any code. Found by a
            # check the same hour rather than by a day and a half of a wrong
            # drawing - with_ordered_height fell through its range path to the
            # modification path and recorded a cut sheet as a reduction.
            'height_range_mm'    => row['height_range_mm'],
            'points_per_m2'      => row['points_per_m2'],
            'depth_mm'           => row['depth_mm'],
            # THE LABEL BESIDE THE DEPTH, AND ONLY THE PANEL PAGES HAVE ONE.
            # An end panel's row prints two numbers - the carcass depth it
            # serves and the depth the catalog draws - and the second is what
            # depth_mm above holds. Carrying the printed words means the object
            # can say which of the two it is, instead of a reader assuming.
            'printed_depth_label' => row['printed_depth_label'],
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
            # The SECTION's book if it declared one, the manifest's otherwise.
            # See the note in data(): a registry that holds two volumes cannot
            # keep one filename for all of them.
            'source_ref'         => "#{unit_type['source_pdf'] || reg['source_pdf']} " \
                                    "#{unit_type['source_ref']}",
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
      # WHICH PROHIBITION EACH TEST STANDS FOR. The list itself is the CATALOG'S,
      # printed in the Modifications section and held in _manifest.json under
      # modifications.width_modification_prohibited_for; these are only the
      # readings of it. The keys must match that list exactly and a check pins
      # that they do, so a change to the source list breaks here rather than
      # quietly going unenforced.
      #
      # THEY MATCH THE CATALOG'S OWN WORDS against the catalog's own
      # descriptions, which is prose against prose and worth naming as such. It
      # is the weakest thing in this file. A false NO is loud - somebody is told
      # a reduction is refused and asks why - and a false YES is silent, which
      # is why the suite runs every held code past this and pins the count.
      WIDTH_MOD_FORBIDDEN = {
        'appliance units' =>
          ->(u) { %w[appliance appliance_front].include?(u['object_class'].to_s) },
        'units with interior drawers' =>
          ->(u) { u['description'].to_s =~ /interior drawer/i },
        'units with jumbo drawers' =>
          ->(u) { u['description'].to_s =~ /jumbo/i },
        'pull-out units' =>
          ->(u) { u['description'].to_s =~ /pull[-\s]?out/i },
        # NOT push-pull. The first version matched it and refused 133 codes,
        # most of them for saying 'NO push-pull device' - the description
        # naming the thing it does not have. A push-pull device is opening
        # HARDWARE anyway, not the mechanism the prohibition means: the
        # catalog's 'units with mechanisms' are the pull-outs, the Magicorner
        # and their kin. Matching a word without reading the sentence it sits
        # in is exactly the failure this file warns about two lines up.
        'units with mechanisms' =>
          ->(u) { u['description'].to_s =~ /mechanism|magicorner/i },
        'tall or wall units with framed glass doors' =>
          ->(u) { (u['front_layout'] || {})['cutout'] || u['description'].to_s =~ /glass/i }
      }.freeze

      # NOT ONE OF THE CATALOG'S PROHIBITIONS, and deliberately not in the list
      # above. WIDTH_MOD_FORBIDDEN is the book's own words about which UNITS may
      # not be cut, pinned against _manifest.json by a check; this is a category
      # error the book never had to name. An end panel's 'width_mm' is its 2,2 cm
      # THICKNESS - the dimensions its codes vary are height and depth, and one
      # code is one height at one depth. 989370 cuts a carcass down; there is
      # nothing here for it to cut, and a panel ordered 500 wide is not a wider
      # panel, it is a different article or none.
      #
      # Added 2026-08-26 with the end-panel chapter, because the census check
      # below says it in the right order: a false NO is loud and a false YES is
      # silent. 124 codes silently answering "yes, cut me" is the silent kind.
      # NARROWED 2026-08-27, and learned rule 6 called it a day early: a
      # constant chosen when there was one case is a bug waiting for the second.
      #
      # This was written on 2026-08-26 for the adjoining end side panel, where
      # width_mm really is the 22 of the board and cutting it down is nonsense.
      # The second case arrived the next morning. Linear Elements printed
      # p.214-220 prices a panel BY AREA: it has no width at all until somebody
      # orders one, the page states only the maximum sheet, and its thickness
      # lives on depth_mm. Refusing that width would refuse the article's only
      # real dimension.
      #
      # So the test is no longer the class. A panel that states a width RANGE is
      # a sheet - the range IS the statement that the width is ordered - and a
      # sheet's width is not a thickness. This is a presence, not an absence:
      # width_range_mm has meant "ask the order" everywhere in this file since
      # the fillers, and with_ordered_width already refuses to build without it.
      def width_is_a_thickness?(unit)
        return false unless (unit || {})['object_class'].to_s == 'panel'

        !sheet_panel?(unit)
      end

      # THE TWO KINDS OF PANEL, named once so nothing has to spell the test out
      # again. Both are object_class 'panel' and they are different articles out
      # of different books:
      #
      #   the ADJOINING END SIDE PANEL - Kitchen System p.440-447 - is a board
      #   beside a run. Its width IS its thickness, its depth is the carcass
      #   depth it serves plus the door, and its height is a CABINET height.
      #
      #   the SHEET - Linear Elements p.215-220 - is cut to order and priced by
      #   the square metre. It states neither width nor height, only the maximum
      #   sheet, and its thickness is on depth_mm.
      #
      # The test is the width RANGE, which is the article's own statement that
      # its width comes from the order. Not the class, not the section title,
      # not the code prefix: a fact the row carries about itself.
      def sheet_panel?(unit)
        return false unless (unit || {})['object_class'].to_s == 'panel'

        !(unit || {})['width_range_mm'].nil?
      end

      def width_modification_refusal(unit)
        return 'end panels, whose width is a thickness' if width_is_a_thickness?(unit)

        WIDTH_MOD_FORBIDDEN.each { |why, test| return why if test.call(unit) }
        nil
      end

      def with_ordered_width(unit, width_mm)
        range = unit['width_range_mm']

        if range.nil?
          return unit if width_mm.nil? || width_mm.to_s.empty?

          stated = unit['width_mm'].to_f
          asked  = width_mm.to_f
          return unit if (asked - stated).abs < 0.001

          # A WIDTH REDUCTION IS A REAL THING AND THE ENGINE COULD NOT SAY IT.
          # Elda, 2026-08-24 (Q3, closed for width): a reduced unit KEEPS THE
          # CODE of the module it was cut from and carries the variant
          # WIDTH REDUCTION with a flat surcharge - 989370 at 138 points for a
          # base or wall unit, 989380 at 227 for a tall one. The manifest has
          # held those codes since, marked 'NOT yet wired to the generator'.
          # This is the wiring. Found needed on 2026-08-25 by a wall that wanted
          # 437 from a 450 module and 874 from a 900 one.
          # A WIDER UNIT IS A REQUEST, NOT AN OPTION, and it is now drawn as one.
          #
          # This raised until 2026-08-25 evening, and the ground was sound: the
          # Modifications section prints REDUCTION only - 989370 and 989380 for
          # width, 989370 again for height - and the only increases printed
          # anywhere are a side panel's DEPTH in 50 mm steps and the combined
          # tall unit of printed p.550, which reaches H.235-278 by stacking two
          # standard carcasses under one door. Nothing read gives a carcass a
          # wider body, and nothing gives that a code or a surcharge.
          #
          # WHAT CHANGED IS THE WORKFLOW, NOT THE EVIDENCE. Andriy, 2026-08-25:
          # it is done in practice, but this factory is new to him, so the plan
          # is to DRAW it, send the LayOut sheet to Elda, have her enter it in
          # Metron by hand, and compare. The drawing is the question; Metron's
          # answer is the confirmation - exactly how width REDUCTION came to be
          # known, from estimate 2026/30831.
          #
          # So the engine draws it and refuses to dress it up: no code is
          # invented, the variant says NOT PRINTED in as many words, and
          # code_status stays PRELIMINARY. A refusal here would have meant no
          # drawing, and therefore no question, and therefore no answer.
          if asked > stated
            if (why = width_modification_refusal(unit))
              raise ArgumentError,
                    "#{unit['code']} may not be width-modified at all: the catalog " \
                    "prohibits it for #{why}."
            end
            unless asked == asked.round
              raise ArgumentError,
                    "A modified width is a whole number of millimetres; got #{width_mm.inspect}."
            end

            return unit.merge('width_mm' => asked.round,
                              'width_increased_from_mm' => stated.round)
          end

          if (why = width_modification_refusal(unit))
            raise ArgumentError,
                  "#{unit['code']} may not be width-modified: the catalog prohibits it " \
                  "for #{why}. Modifications section, held in _manifest.json under " \
                  'modifications.width_modification_prohibited_for.'
          end

          unless asked == asked.round
            raise ArgumentError,
                  "A reduced width is a whole number of millimetres; got #{width_mm.inspect}."
          end
          raise ArgumentError, "#{unit['code']} reduced to #{asked.round} is not positive" unless
            asked.positive?

          return unit.merge('width_mm' => asked.round,
                            'width_reduced_from_mm' => stated.round)
        end

        lo, hi = range
        if width_mm.nil? || width_mm.to_s.empty?
          raise ArgumentError,
                "#{unit['code']} has no width in the catalog: one article covers " \
                "#{lo} to #{hi} mm and the width is stated per order. Ask for it " \
                'before building.'
        end

        # A FLOAT USED TO WALK STRAIGHT PAST THIS GUARD. Integer("49.2") raises,
        # which is what the rescue below was written for - but Integer(49.2)
        # TRUNCATES and returns 49 without a word. So a caller that asked for
        # 49,2 got 49 built, and the only trace was a 0,2 mm gap at the wall.
        # Found 2026-08-25 building the Avenida Primavera top run, where three
        # fillers were ordered at 49,2, 69,2 and 109,3 and three were drawn at
        # 49, 69 and 109. The message below has always said what it means; the
        # code did not enforce it.
        #
        # The rule itself does not change - the catalog orders a filler in whole
        # millimetres - but a width that is not one is now REFUSED and named,
        # instead of being quietly rounded into something nobody asked for.
        asked = begin
          Float(width_mm)
        rescue ArgumentError, TypeError
          nil
        end
        if asked.nil?
          raise ArgumentError,
                "A filler width is a number of millimetres; got #{width_mm.inspect}."
        end

        # THE RULE, 2026-08-26 (Andriy, closing owed 2). A filler is ordered in
        # WHOLE millimetres and the rounding is ALWAYS UP, because up is the only
        # direction a fitter can correct: ordered wider, the excess is scribed off
        # against the wall; ordered narrower, there is a gap and nothing to close
        # it with.
        #
        # THIS REPLACES THE REFUSAL ADDED THE DAY BEFORE, and the refusal is why
        # the rule can be trusted. Before 2026-08-25 `Integer(49.2)` truncated to
        # 49 in silence, and three fillers on the Avenida Primavera top run were
        # ordered 0,2, 0,2 and 0,3 too NARROW with nothing but a gap at the wall
        # to show for it. The refusal made that visible and asked a human every
        # time. The rule answers the same question once - and it keeps the half
        # the refusal was really protecting: THE ALLOWANCE IS SAID ON THE OBJECT.
        #
        # Two widths come out of this, and they are different on purpose:
        #   width_mm       what is ORDERED - a whole number, rounded up
        #   width_clear_mm what is DRAWN - the space it actually fills
        # Generator.drawn_width_mm is the one reader of the second. Same shape as
        # the Sub-Zero panels and the plinth: the attributes are the order and the
        # geometry is the sheet.
        ordered = asked.ceil
        scribe  = (ordered - asked).round(3)

        unless ordered >= lo && ordered <= hi
          raise ArgumentError,
                "#{unit['code']} is made from #{lo} to #{hi} mm. A clear space of " \
                "#{asked} rounds up to #{ordered}, which is outside that range. The " \
                "range is the catalog's, printed on the page the row cites - so this " \
                'is two fillers or a different article, not a width nobody prints.'
        end

        return unit.merge('width_mm' => ordered) if scribe.zero?

        unit.merge('width_mm' => ordered,
                   'width_clear_mm' => asked,
                   'scribe_mm' => scribe)
      end

      # ---- HEIGHT, and what the page prints about it -------------------------
      #
      # Added 2026-08-25, the same evening as the width increase and for the
      # same wall: over the range the project needs 610 x 720 where printed
      # p.172's position prints 600 x 600.
      #
      # WHAT THE SOURCE ACTUALLY SAYS, and the asymmetry is the point:
      #
      #   HEIGHT REDUCTION is printed and priced - printed p.548, code 989370,
      #   138 points, and the row is repeated for base/wall and for TALL at the
      #   same code and the same points, where WIDTH charges tall units more
      #   (989380, 227). Held in _manifest.json under
      #   modifications.codes.height_reduction since the day the chapter was
      #   read, marked 'NOT yet wired'. This is the wiring.
      #
      #   HEIGHT INCREASE is printed nowhere, exactly like a width increase, and
      #   is drawn on the same terms: a request, marked NOT PRINTED, no code
      #   invented. See the long note above with_ordered_width.
      #
      #   AND THE EXCLUSION LIST IS FOR WIDTH ONLY. printed p.548 heads it
      #   'Units that cannot be modified in WIDTH' and names appliance units,
      #   interior/jumbo drawers, pull-outs, mechanisms and framed glass. NO
      #   SUCH LIST IS PRINTED FOR HEIGHT. So this method does NOT reuse
      #   WIDTH_MOD_FORBIDDEN wholesale - borrowing a prohibition the page did
      #   not write would be inventing catalog, which is the one thing this
      #   registry may not do. Elda Q17 asks whether the list is meant to cover
      #   height too, and until she answers, every height change carries the
      #   master rule on the object.
      #
      # ONE REFUSAL IS OURS AND IS NOT BORROWED. An appliance housing's opening
      # height is the APPLIANCE'S - that is not a catalog prohibition, it is a
      # fact this engine already holds and draws (the 600 oven niche, recovered
      # from three different family totals). Changing such a carcass's height
      # without changing what it houses would produce a stack that no longer
      # sums to its own height, and §4.2's arithmetic would catch it one step
      # later with a worse message. So it is refused here, and the reason given
      # is ours rather than the page's.
      def height_modification_refusal(unit)
        return 'an appliance housing takes its opening height from the appliance, ' \
               'not from the carcass - change the appliance, not the box' if
          %w[appliance appliance_front].include?(unit['object_class'].to_s)

        # AND THE ONE THE PAGE ITSELF PRINTS, added 2026-08-26 when the glass
        # wall units were extracted on demand. Every position in the glass
        # display chapter carries, beside the code, the sentence
        #
        #     "Cannot be reduced in width, height or depth"
        #
        # printed p.314 for H.96 and repeated at every other height of that
        # chapter. THIS IS NOT THE WIDTH LIST BORROWED. p.548 excludes 'tall or
        # wall units with framed glass doors' from WIDTH only, and borrowing a
        # prohibition the page did not write is the one thing this registry may
        # not do - the comment above with_ordered_height says exactly that about
        # Elda Q17. Here the page wrote it, in those words, next to the article.
        #
        # DEPTH is prohibited by the same sentence and is NOT wired, because this
        # engine has no depth-modification path to refuse. Said out loud so the
        # absence is a known gap rather than an oversight.
        return 'a glass display element - printed p.314 states "Cannot be reduced in ' \
               'width, height or depth" on the position itself' if
          unit['description'].to_s =~ /glass/i

        nil
      end

      def with_ordered_height(unit, height_mm)
        # ---- THE HEIGHT THAT WAS NEVER PRINTED, 2026-08-27 -------------------
        #
        # Everything below this block treats a height as a MODIFICATION: it
        # compares what was asked against what the page states and records
        # height_increased_from_mm or height_reduced_from_mm. That is right for
        # a cabinet, whose page prints a height.
        #
        # It is a lie about a sheet. Linear Elements printed p.214-220 prices a
        # panel per square metre and prints NO height - only the maximum sheet
        # it can be cut from. A panel ordered 880 tall is not an 840 modified by
        # 40; it is a board cut to 880, which is what that article is. Recording
        # it as a modification would put a surcharge code on an order line the
        # catalog never charges, and would tell a reader the factory did
        # something special.
        #
        # So a height_range_mm short-circuits the whole modification path, and
        # it mirrors width_range_mm exactly - including the refusal, which is
        # the important half: an article whose dimension comes from the order
        # must not be buildable without one.
        #
        # IT DOES NOT ROUND. with_ordered_width rounds a filler UP, because a
        # filler is scribed against a wall and up is the only direction a fitter
        # can correct. Nothing here is scribed against anything: the sheet is cut
        # to the number, and a number that is not whole millimetres is a question
        # for the person, not for this method.
        if (h_range = unit['height_range_mm'])
          lo, hi = h_range
          if height_mm.nil? || height_mm.to_s.empty?
            raise ArgumentError,
                  "#{unit['code']} has no height in the catalog: it is priced by " \
                  "the square metre and cut to size, anywhere from #{lo} to #{hi} " \
                  'mm. State the height before building.'
          end

          asked = begin
            Float(height_mm)
          rescue ArgumentError, TypeError
            nil
          end
          raise ArgumentError, "A panel height is a number of millimetres; got #{height_mm.inspect}." if asked.nil?

          unless asked == asked.round
            raise ArgumentError,
                  "A cut panel is ordered in whole millimetres; got #{height_mm.inspect}. " \
                  'Nothing here is scribed against a wall, so this is not rounded for you.'
          end
          unless asked >= lo && asked <= hi
            raise ArgumentError,
                  "#{unit['code']} is cut from a sheet #{hi} mm on that axis; #{asked.round} " \
                  'does not come out of it. That is a second panel or a different ' \
                  'material, not a height nobody prints.'
          end

          return unit.merge('height_mm' => asked.round)
        end

        return unit if height_mm.nil? || height_mm.to_s.empty?

        stated = unit['height_mm'].to_f
        asked  = height_mm.to_f
        return unit if (asked - stated).abs < 0.001

        if (why = height_modification_refusal(unit))
          raise ArgumentError,
                "#{unit['code']} may not be height-modified: #{why}."
        end
        unless asked == asked.round
          raise ArgumentError,
                "A modified height is a whole number of millimetres; got #{height_mm.inspect}."
        end
        raise ArgumentError, "#{unit['code']} at #{asked.round} is not positive" unless
          asked.positive?

        key = asked > stated ? 'height_increased_from_mm' : 'height_reduced_from_mm'
        unit.merge('height_mm' => asked.round, key => stated.round)
      end

      # CACHED ALONGSIDE data, AND FOR THE SAME REASON. catalog is a pure
      # function of data - it walks every code and flattens it - and rebuilding
      # it took 0,38 s once the registry passed 600 codes. The headless suite
      # calls it a few hundred times and went from forty seconds to over ninety.
      # The cache key is the object identity of the parsed registry, so the
      # moment data() re-reads an edited file this map misses and rebuilds:
      # hot-editing a JSON file in SketchUp behaves exactly as it did before.
      def catalog(manufacturer = 'cesar')
        reg = data(manufacturer)
        @catalog_cache ||= {}
        hit = @catalog_cache[manufacturer]
        return hit[:rows] if hit && hit[:for].equal?(reg)

        rows = build_catalog(reg, manufacturer)
        @catalog_cache[manufacturer] = { for: reg, rows: rows }
        rows
      end

      def build_catalog(reg, manufacturer)
        each_code(reg).map do |row, family_name, family, type_key, unit_type|
          { 'code' => row['code'], 'width_mm' => row['width_mm'],
            'width_range_mm' => row['width_range_mm'],
            'nominal_in' => nominal_in(row['width_mm'], manufacturer),
            # Row first, family second - see the same precedence in lookup.
            # A picker row for an end panel gets its height from the code.
            'depth_mm' => row['depth_mm'],
            'height_mm' => (row['height_mm'] || family['height_mm']),
            # THE HEIGHT CAN COME FROM THE ORDER TOO, 2026-08-27, and until the
            # Linear Elements panels arrived only the WIDTH could. A row that
            # states a height range states that it has no printed height - the
            # same sentence width_range_mm has meant since the fillers - and a
            # picker row that dropped it would show a panel with no height at
            # all and no reason given.
            'height_range_mm' => row['height_range_mm'],
            # WHAT TELLS TWO SHEETS APART ON A BUTTON. A sheet's width and
            # height are both blank and its depth is a thickness, so the picker
            # has nothing to print unless the row carries the three facts the
            # page separates them by: the lacquer or veneer GROUP, how many
            # sides are faced, and the rate. Same reason nominal_in is here -
            # display needs it and the object must never see it.
            'price_group' => row['price_group'],
            'faced_sides' => row['faced_sides'],
            'points_per_m2' => row['points_per_m2'],
            'family' => family_name, 'type_key' => type_key,
            'description' => unit_type['description'],
            # NAMED WITH ITS BOOK, like lookup's. A picker row reading
            # 'printed p.215' is ambiguous the moment the registry holds two
            # volumes, and it has held two since this line was written.
            'source_ref' => "#{unit_type['source_pdf'] || reg['source_pdf']} " \
                            "#{unit_type['source_ref']}",
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

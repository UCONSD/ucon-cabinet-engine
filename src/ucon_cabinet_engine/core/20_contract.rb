# frozen_string_literal: true
#
# UCON Cabinet Engine — core/20_contract.rb
#
# Implements UCON Object Contract v2 (revision v2.1) — docs/UCON_Object_Contract_v2.md.
# (v1, revision v1.5, is kept unedited as the historical record.)
#
# `validate!` is pure Ruby with no SketchUp dependency, so the entire rule set
# runs headlessly:  ruby tools/test_contract.rb
# `write!` is the thin SketchUp-facing wrapper around it.
#
# The contract is load-bearing. If a rule here disagrees with the document,
# the document wins and this file is the bug.

require 'json'

module UCON
  module CabinetEngine
    module Contract
      DICTIONARY     = 'CabinetEngine'
      SCHEMA_VERSION = '2'

      # §1.1 — the complete key set. A key outside this list is a contract
      # violation (§1.2), not merely an unusual choice.
      KEYS = %w[
        schema_version object_class manufacturer collection family
        unit_category unit_type geometry_kind
        height_mm depth_mm width_mm corner_geometry
        mounting mount_bottom_mm
        opening opening_method front_height_mm hinge_side
        hardware_ref hardware_source companion_refs variants
        code code_status pricing_group_ref
        status priority source_ref restrictions notes
        void_role
      ].freeze

      ALWAYS_REQUIRED = %w[
        schema_version object_class manufacturer geometry_kind code_status status
      ].freeze

      ENUMS = {
        # `void` is a RESERVATION, not a body - a span whose extent is known and
        # whose division is not yet decided. It sits beside `appliance` and
        # `appliance_front` for the same reason they are here: it is a thing the
        # drawing owns and the factory does not make. docs/Reserved_Void_Spec_v0.1.md
        'object_class'    => %w[cabinet worktop panel filler accessory appliance appliance_front corner_unit void],
        'geometry_kind'   => %w[linear corner non_dim],
        'mounting'        => %w[floor wall_hung],
        'code_status'     => %w[PRELIMINARY CONFIRMED],
        'status'          => %w[SOURCE CONTROL PLANNING CONFIRMED],
        'opening_method'  => %w[handle push_to_open gola],
        'hinge_side'      => %w[rh lh],
        'hardware_source' => %w[factory client],
        'priority'        => %w[P1 P2 P3],
        # The role decides the DATUM and the fill offer, and both are read while
        # drawing - which is what earns a key under Object Contract v2 SS4.2 rule 6.
        'void_role'       => %w[above_housing run_gap front_remainder]
      }.freeze

      # §1.4 — the two keys that hold structure rather than a scalar. They are
      # LISTS, one level deep: a line may not contain lines. SketchUp attribute
      # values may not be Hashes, so these are stored as JSON text and the
      # encoding lives here and nowhere else.
      STRUCTURED_KEYS = %w[companion_refs variants].freeze

      # §1.4 — a companion LINE. source_ref is deliberately optional: a resolved
      # code's provenance lives in the registry row that produced it, and a
      # second copy is a second thing to keep true.
      LINE_KEYS    = %w[code qty um origin source_ref variants].freeze
      VARIANT_KEYS = %w[key value source_ref].freeze
      COMPANION_UMS = %w[PZ ML MQ].freeze
      # §4.2 rule 3 — behavioural, not descriptive. An implied line is recomputed
      # on every rebuild; a chosen one survives, because a hinge-side change must
      # not evaporate somebody's kit.
      ORIGINS = %w[implied chosen].freeze

      # §3 — canonical order, deliberately not alphabetical. Tools sort by this.
      STATUS_ORDER = %w[SOURCE CONTROL PLANNING CONFIRMED].freeze

      # §1.2 — no key may carry commercial data. pricing_group_ref is the one
      # structural exception and records the group label only, never a price.
      COMMERCIAL_MARKERS = %w[
        price cost margin coefficient discount surcharge
        lead_time leadtime availability stock
      ].freeze

      module_function

      # Returns the normalized attribute hash, or raises ArgumentError naming
      # the specific contract clause that was broken.
      def validate!(attrs)
        a = normalize(attrs)

        # Commercial keys are checked BEFORE the general unknown-key check.
        # Both would reject them — KEYS is a closed allowlist — but this
        # ordering is what makes the error say *why* the key is forbidden
        # rather than merely that it is unrecognised. The distinction matters:
        # an unknown key is usually a typo, a price key is a scope breach.
        commercial = a.keys.select do |k|
          k != 'pricing_group_ref' && COMMERCIAL_MARKERS.any? { |m| k.include?(m) }
        end
        unless commercial.empty?
          raise ArgumentError,
                "Commercial data is forbidden in the contract (§1.2): #{commercial.join(', ')}"
        end

        unknown = a.keys - KEYS
        unless unknown.empty?
          raise ArgumentError,
                "Keys outside Object Contract v1 (§1.2): #{unknown.sort.join(', ')}"
        end

        missing = ALWAYS_REQUIRED.reject { |k| present?(a[k]) }
        unless missing.empty?
          raise ArgumentError, "Missing required keys (§1.1): #{missing.join(', ')}"
        end

        if a['schema_version'].to_s != SCHEMA_VERSION
          raise ArgumentError,
                "schema_version must be #{SCHEMA_VERSION.inspect}, got #{a['schema_version'].inspect}"
        end

        ENUMS.each do |key, allowed|
          next unless present?(a[key])
          next if allowed.include?(a[key].to_s)

          raise ArgumentError,
                "#{key} = #{a[key].inspect} is not one of: #{allowed.join(' / ')}"
        end

        # §1.4 — the structured keys. Validation always runs on the LOGICAL form
        # (real lists and hashes); encoding happens later, at the storage
        # boundary. The validators return the normalized value so that what is
        # written and what is read back have the same shape.
        a['companion_refs'] = validate_companions!(a['companion_refs']) if
          present?(a['companion_refs'])
        a['variants'] = validate_variants!(a['variants'], 'variants') if
          present?(a['variants'])

        # §1.1 — dimensional requirements depend on geometry_kind.
        case a['geometry_kind']
        when 'linear'
          require_keys!(a, %w[height_mm depth_mm width_mm], 'geometry_kind = linear')
        when 'corner'
          require_keys!(a, %w[height_mm depth_mm corner_geometry], 'geometry_kind = corner')
        end

        # §1.3 (v1.5) — how the object meets the room. A floor object's height
        # above the floor is its plinth and is already implied; a hung object's
        # is not derivable from anything the catalog says, so it must be stated
        # or the object is under-specified. The reverse is equally a bug: a
        # hanging height on a floor unit is a number nobody can honour.
        if a['mounting'].to_s == 'wall_hung'
          unless present?(a['mount_bottom_mm'])
            raise ArgumentError,
                  'mounting = wall_hung requires mount_bottom_mm (§1.3)'
          end
          if a['mount_bottom_mm'].to_f <= 0
            raise ArgumentError,
                  "mount_bottom_mm must be positive, got #{a['mount_bottom_mm'].inspect} (§1.3)"
          end
        elsif present?(a['mount_bottom_mm'])
          raise ArgumentError,
                'mount_bottom_mm is only meaningful with mounting = wall_hung (§1.3)'
        end

        # A VOID MUST SAY WHICH KIND IT IS, and nothing else may claim one.
        # The role decides the datum and the fill offer; a void without it is a
        # translucent box nobody can act on, which is worse than an absence
        # because it looks answered. docs/Reserved_Void_Spec_v0.1.md §3.
        if a['object_class'].to_s == 'void'
          unless present?(a['void_role'])
            raise ArgumentError, 'object_class = void requires void_role'
          end
        elsif present?(a['void_role'])
          raise ArgumentError,
                'void_role is only meaningful with object_class = void'
        end

        # §4 — a code cannot outrank the object carrying it.
        if a['code_status'].to_s == 'CONFIRMED' && a['status'].to_s != 'CONFIRMED'
          raise ArgumentError,
                'code_status = CONFIRMED requires status = CONFIRMED (§4)'
        end

        # §1.1 — source_ref is required at SOURCE and above. SOURCE is the
        # lowest level in the vocabulary, so in practice: always.
        unless present?(a['source_ref'])
          raise ArgumentError,
                'source_ref is required at status SOURCE or higher, i.e. always (§1.1)'
        end

        # §3.1 — P3 means blocked; such an object must not already claim to be
        # further along than CONTROL.
        if a['priority'].to_s == 'P3' && status_rank(a['status']) > status_rank('CONTROL')
          raise ArgumentError,
                "priority = P3 is blocked at CONTROL; status #{a['status'].inspect} is beyond it (§3.1)"
        end

        a
      end

      # Validate, then RECONCILE the CabinetEngine dictionary on the given
      # entity (a ComponentDefinition per §2) so that it holds exactly the
      # validated attribute set - present keys written, absent keys DELETED.
      #
      # The deletion half is not a refinement, it is the point. §2 says tools
      # must derive meaning only from this dictionary; if the dictionary can
      # keep a key the contract no longer carries, that sentence is false. The
      # earlier version skipped absent values instead of deleting them, and
      # because every caller works read-merge-write, a value that became empty
      # simply survived: switching a front from a gola profile to a
      # client-provided handle left hardware_ref = "GOL001" on an object whose
      # hardware_source said "client". A code nobody chose reached the record.
      #
      # Safe to reconcile because set_attribute on DICTIONARY exists in exactly
      # one place - this method. Everything else in the source only reads, and
      # only 'code'. Verified 2026-08-22; a second writer would break this.
      #
      # The get_attribute guard means an absent key that was never written
      # costs nothing: no delete call, no model dirtied, no undo entry.
      def write!(entity, attrs)
        validated = validate!(attrs)
        KEYS.each do |key|
          value = validated[key]
          if present?(value)
            # Presence is decided on the LOGICAL value and encoding happens
            # after (§1.4). Encode-then-test would persist an empty list,
            # because '[]' is a perfectly non-empty String.
            entity.set_attribute(DICTIONARY, key, encode_for_storage(key, value))
          elsif !entity.get_attribute(DICTIONARY, key).nil?
            entity.delete_attribute(DICTIONARY, key)
          end
        end
        validated
      end

      # Read the dictionary back off an entity. Tools must derive meaning only
      # from this — never from the component's name, layer, or nesting (§2).
      def read(entity)
        raw = KEYS.each_with_object({}) do |key, out|
          value = entity.get_attribute(DICTIONARY, key)
          out[key] = decode_from_storage(key, value) unless value.nil?
        end
        migrate(raw)
      end

      # §7 — read() is the migration boundary, so a model built under v1 keeps
      # opening and self-heals as objects are rebuilt. Nothing here is a guess:
      # v1 had no way to express a chosen companion, and one code in its string
      # meant one line of one piece. That is a statement about the old format's
      # expressive power, not a claim about the catalog.
      def migrate(attrs)
        out = attrs.dup
        out['schema_version'] = SCHEMA_VERSION if out.key?('schema_version')
        legacy = out['companion_refs']
        if legacy.is_a?(String)
          out['companion_refs'] =
            legacy.split(',').map { |c| c.strip }.reject { |c| c.empty? }.map do |code|
              { 'code' => code, 'qty' => 1, 'um' => 'PZ', 'origin' => 'implied' }
            end
        end
        out
      end

      def encode_for_storage(key, value)
        return value unless STRUCTURED_KEYS.include?(key)

        JSON.generate(value)
      end

      # A v1 companion_refs is a comma-joined list of codes and can never start
      # with '[', so the bracket is what tells the two apart. Do NOT hand a bare
      # legacy value to JSON.parse hoping it fails: modern json parses a bare
      # scalar happily, and '995626' would come back as the Integer 995626.
      def decode_from_storage(key, value)
        return value unless STRUCTURED_KEYS.include?(key) && value.is_a?(String)
        return value unless value.lstrip.start_with?('[')

        begin
          JSON.parse(value)
        rescue JSON::ParserError => e
          raise ArgumentError,
                "#{key} holds text that is neither the v1 shape nor valid JSON " \
                "(#{e.message}): #{value.inspect}"
        end
      end

      # §1.4 — a list of companion LINES, one level deep.
      def validate_companions!(value)
        unless value.is_a?(Array)
          raise ArgumentError,
                'companion_refs must be a list of lines (§1.4). A comma-joined string ' \
                'is the v1 shape; Contract.read lifts it and nothing else may write it.'
        end

        value.each_with_index.map do |line, i|
          at = "companion_refs[#{i}]"
          raise ArgumentError, "#{at} must be a hash (§1.4)" unless line.is_a?(Hash)

          l = normalize(line)
          unknown = l.keys - LINE_KEYS
          unless unknown.empty?
            raise ArgumentError, "#{at}: keys outside §1.4: #{unknown.sort.join(', ')}"
          end
          # §4.2 rule 4 — code MAY be nil: a chosen line whose article no longer
          # resolves goes to nil and warns, rather than keeping a stale code.
          unless l['code'].nil? || l['code'].is_a?(String)
            raise ArgumentError, "#{at}: code must be a string or nil"
          end
          # v2.1: qty MAY be nil, and that is not a loophole. A linear-metre
          # profile is measured along the RUN it travels; a handle count
          # follows the fronts. Neither is determinable from one object, and
          # the contract requiring a number there would force the model to
          # state something nobody knows. Same rule as a code that stops
          # resolving: unknown is nil, never a plausible 1.
          unless l['qty'].nil? || (l['qty'].is_a?(Numeric) && l['qty'].to_f > 0)
            raise ArgumentError,
                  "#{at}: qty must be a positive number or nil, got #{l['qty'].inspect}"
          end
          unless COMPANION_UMS.include?(l['um'].to_s)
            raise ArgumentError, "#{at}: um must be one of #{COMPANION_UMS.join(' / ')}"
          end
          unless ORIGINS.include?(l['origin'].to_s)
            raise ArgumentError, "#{at}: origin must be one of #{ORIGINS.join(' / ')}"
          end
          l['variants'] = validate_variants!(l['variants'], "#{at}.variants") if
            present?(l['variants'])
          l
        end
      end

      # §1.4 — one variant schema, used on the object and on a companion alike.
      def validate_variants!(value, where)
        raise ArgumentError, "#{where} must be a list (§1.4)" unless value.is_a?(Array)

        value.each_with_index.map do |variant, i|
          at = "#{where}[#{i}]"
          raise ArgumentError, "#{at} must be a hash (§1.4)" unless variant.is_a?(Hash)

          v = normalize(variant)
          # Checked before the unknown-key sweep for the same reason as §1.2 at
          # the top level: an unknown key is usually a typo, a price key is a
          # scope breach, and the error should say which.
          commercial = v.keys.select { |k| COMMERCIAL_MARKERS.any? { |m| k.include?(m) } }
          unless commercial.empty?
            raise ArgumentError,
                  "#{at}: commercial data is forbidden (§1.2): #{commercial.join(', ')}. " \
                  'A variant records THAT stainless steel was chosen, never what it costs.'
          end
          unknown = v.keys - VARIANT_KEYS
          unless unknown.empty?
            raise ArgumentError, "#{at}: keys outside §1.4: #{unknown.sort.join(', ')}"
          end
          %w[key value].each do |k|
            raise ArgumentError, "#{at}: #{k} is required (§1.4)" unless present?(v[k])
          end
          v
        end
      end

      def status_rank(status)
        STATUS_ORDER.index(status.to_s) || -1
      end

      def normalize(attrs)
        attrs.each_with_object({}) { |(k, v), out| out[k.to_s] = v }
      end

      def present?(value)
        return false if value.nil?
        return false if value.respond_to?(:empty?) && value.empty?

        true
      end

      def require_keys!(attrs, keys, because)
        missing = keys.reject { |k| present?(attrs[k]) }
        return if missing.empty?

        raise ArgumentError, "#{because} requires: #{missing.join(', ')}"
      end
    end
  end
end

# frozen_string_literal: true
#
# UCON Cabinet Engine — core/20_contract.rb
#
# Implements UCON Object Contract v1 (revision v1.1) — docs/UCON_Object_Contract_v1.md.
#
# `validate!` is pure Ruby with no SketchUp dependency, so the entire rule set
# runs headlessly:  ruby tools/test_contract.rb
# `write!` is the thin SketchUp-facing wrapper around it.
#
# The contract is load-bearing. If a rule here disagrees with the document,
# the document wins and this file is the bug.

module UCON
  module CabinetEngine
    module Contract
      DICTIONARY     = 'CabinetEngine'
      SCHEMA_VERSION = '1'

      # §1.1 — the complete key set. A key outside this list is a contract
      # violation (§1.2), not merely an unusual choice.
      KEYS = %w[
        schema_version object_class manufacturer collection family
        unit_category unit_type geometry_kind
        height_mm depth_mm width_mm corner_geometry
        opening opening_method front_height_mm hinge_side
        hardware_ref hardware_source
        code code_status pricing_group_ref
        status priority source_ref restrictions notes
      ].freeze

      ALWAYS_REQUIRED = %w[
        schema_version object_class manufacturer geometry_kind code_status status
      ].freeze

      ENUMS = {
        'object_class'    => %w[cabinet worktop panel filler accessory appliance_front corner_unit],
        'geometry_kind'   => %w[linear corner non_dim],
        'code_status'     => %w[PRELIMINARY CONFIRMED],
        'status'          => %w[SOURCE CONTROL PLANNING CONFIRMED],
        'opening_method'  => %w[handle push_to_open gola],
        'hinge_side'      => %w[rh lh],
        'hardware_source' => %w[factory client],
        'priority'        => %w[P1 P2 P3]
      }.freeze

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

        # §1.1 — dimensional requirements depend on geometry_kind.
        case a['geometry_kind']
        when 'linear'
          require_keys!(a, %w[height_mm depth_mm width_mm], 'geometry_kind = linear')
        when 'corner'
          require_keys!(a, %w[height_mm depth_mm corner_geometry], 'geometry_kind = corner')
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

      # Validate, then write every present key into the CabinetEngine
      # dictionary on the given entity (a ComponentDefinition per §2).
      def write!(entity, attrs)
        validated = validate!(attrs)
        validated.each do |key, value|
          next unless present?(value)

          entity.set_attribute(DICTIONARY, key, value)
        end
        validated
      end

      # Read the dictionary back off an entity. Tools must derive meaning only
      # from this — never from the component's name, layer, or nesting (§2).
      def read(entity)
        KEYS.each_with_object({}) do |key, out|
          value = entity.get_attribute(DICTIONARY, key)
          out[key] = value unless value.nil?
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

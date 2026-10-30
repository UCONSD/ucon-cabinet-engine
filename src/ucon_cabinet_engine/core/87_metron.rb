# frozen_string_literal: true
#
# UCON Cabinet Engine — core/87_metron.rb  ::  ONE ROOM OF THE MODEL -> THE ROOM JSON METRON IS BUILT FROM.
#
# Stage 2 of SketchUp -> Metron (Andriy 2026-10-29: the model is the source of truth, Metron is built from it).
# The generator on the Metron side (metron/laptop/gen/rit_build.py, stage 1, byte-exact on Bath 2 / Bath 3) reads a
# room JSON. This file writes the MODEL HALF of it: what stands where. It does NOT write the Metron half - which
# sample block a code is cloned from (`src`) and the STRUTTURA numbers (`id`) - because those belong to one estimate
# file on the laptop and the model must not know them. metron/laptop/gen/room_from_skp.py adds them.
#
# PURE RUBY, NO SKETCHUP. Input: plain hashes, one per body, in ROOM-LOCAL millimetres (x along the back wall from
# the left wall, y from the back wall into the room = negative, z from the floor). The glue that measures them out
# of a model is in the palette glue (core/90_palette, Export to Metron) - not here, same split as 85_export / 86_export_run.
#
# NOT IN THE CONTRACT. Object Contract v2 SS1.1 closes the CabinetEngine key list, and a Metron code is not a fact
# about the object but about one ordering system. So it lives in its own dictionary, UCON_METRON, on the room group
# and on the INSTANCE (two instances may share a definition and still be two Metron positions).
#
# MAPPING, by default nothing is written on a body:
#   object_class cabinet            -> kind unit, code = the engine code, x = carcass left, y = carcass bottom
#   UCON_METRON kind=unit + code    -> unit under another name (the mirror: UCON-MIR-RMU-120x070 -> SPECCHIERA)
#   UCON_METRON kind=panel + code   -> side panel standing across the wall (PAN018 / PAN022). Only the orientation
#                                      Metron has accepted is emitted: pos [right face x, bottom, 0, 270],
#                                      X = depth, Y = height. Anything else is REFUSED, not guessed.
#   UCON_METRON kind=top + code     -> TOPDRBA over a row: units = first and last unit under it (STENDI2 lists only
#                                      those), sx / dx = overhang past them, edges and sink from the attributes.
#   UCON_METRON kind=skip           -> never exported. A body with no code and no UCON_METRON is not looked at.
module UCON
  module CabinetEngine
    module Metron
      module_function

      DICTIONARY = 'UCON_METRON'
      ROOM_KEYS  = %w[room revision estimate origin_x_mm origin_y_mm width_mm depth_mm height_mm master finishes].freeze
      BODY_KEYS  = %w[kind code borsx bordx sink note].freeze
      KINDS      = %w[unit panel top skip].freeze
      TOL        = 1.0 # mm. Hand geometry lands on fractions; a refusal at 0.3 would be about SketchUp.

      # 1514.0 -> 1514, 7.04 -> 7 (SketchUp lands on fractions), 12.5 -> 12.5. Ruby 2.6: no endless def here.
      def num(v)
        (v.to_f - v.to_f.round).abs < 0.05 ? v.to_f.round : v.to_f.round(1)
      end

      # body: { ref:, code: (engine), object_class:, mounting:, metron: {kind, code, ...},
      #         x0:, x1:, y0:, y1:, z0:, z1:, rot_deg: }  -> nil (not exported) or [kind, body]
      def classify(b)
        mt = b[:metron] || {}
        kind = mt['kind'] || (b[:object_class] == 'cabinet' ? 'unit' : nil)
        return nil if kind.nil? || kind == 'skip'
        raise ArgumentError, "#{b[:ref]}: UCON_METRON kind #{kind.inspect} is not one of #{KINDS.join(' / ')}" unless KINDS.include?(kind)
        code = mt['code'] || b[:code]
        raise ArgumentError, "#{b[:ref]}: #{kind} with no code - give it UCON_METRON code" if code.to_s.empty?
        [kind, code]
      end

      def unit_item(b, code)
        h = { 'ref' => b[:ref], 'kind' => 'unit', 'code' => code, 'x' => num(b[:x0]), 'y' => num(b[:z0]) }
        # Sospesa=1 is a CABINET fact in Metron; the mirror block carries none, whatever the engine says about it.
        h['hung'] = true if b[:mounting] == 'wall_hung' && b[:object_class] == 'cabinet'
        h
      end

      def panel_item(b, code)
        unless [90, -270, 270, -90].include?(b[:rot_deg].to_i) || (b[:x1] - b[:x0]) < (b[:y1] - b[:y0])
          raise ArgumentError, "#{b[:ref]}: panel #{code} does not stand across the wall - only that orientation is known to Metron"
        end
        { 'ref' => b[:ref], 'kind' => 'panel', 'code' => code,
          'pos' => [num(b[:x1]), num(b[:z0]), 0, 270], 'X' => num(b[:y1] - b[:y0]), 'Y' => num(b[:z1] - b[:z0]) }
      end

      def top_item(b, code, units)
        under = units.select { |u| u[:x0] >= b[:x0] - TOL && u[:x1] <= b[:x1] + TOL && u[:z1] <= b[:z0] + TOL }
                     .sort_by { |u| u[:x0] }
        raise ArgumentError, "#{b[:ref]}: top #{code} has no unit under it" if under.empty?
        mt = b[:metron] || {}
        h = { 'ref' => b[:ref], 'kind' => 'top', 'code' => code,
              'units' => under.size > 1 ? [under.first[:ref], under.last[:ref]] : [under.first[:ref]],
              'sx' => num(under.first[:x0] - b[:x0]), 'dx' => num(b[:x1] - under.last[:x1]) }
        %w[borsx bordx sink].each { |k| h[k] = mt[k] if mt[k] && !mt[k].to_s.empty? }
        h
      end

      # bodies: room-local hashes as above; room: UCON_METRON of the room group (string keys)
      # -> { 'room', 'revision', 'estimate', 'items' => [...] } in the DEFAULT ORDER: units left to right, then the
      # high units (mirrors) left to right, then panels left to right, then tops. The laptop step keeps the order and
      # the ids of a previous room JSON where the items match; this order is only for what is new.
      def room(bodies, room)
        typed = bodies.map { |b| (k = classify(b)) ? [k[0], k[1], b] : nil }.compact
        unit_b = typed.select { |t| t[0] == 'unit' }.map { |t| t[2] }
        items = []
        typed.select { |t| t[0] == 'unit' }.sort_by { |_, _, b| [b[:z0].to_f > 1000 ? 1 : 0, b[:x0].to_f] }
             .each { |_, c, b| items << unit_item(b, c) }
        typed.select { |t| t[0] == 'panel' }.sort_by { |_, _, b| b[:x0].to_f }.each { |_, c, b| items << panel_item(b, c) }
        typed.select { |t| t[0] == 'top' }.sort_by { |_, _, b| b[:x0].to_f }.each { |_, c, b| items << top_item(b, c, unit_b) }
        refs = items.map { |i| i['ref'] }
        raise ArgumentError, "duplicate refs #{refs.inspect}" unless refs.uniq.size == refs.size
        { 'room' => room['room'], 'revision' => room['revision'], 'estimate' => room['estimate'],
          'source' => room['source'], 'items' => items }.reject { |_, v| v.nil? }
      end
    end
  end
end

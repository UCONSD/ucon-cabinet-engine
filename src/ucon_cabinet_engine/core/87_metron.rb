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
#
# R02 OF THE 7612 BATHS (2026-11-02) - what the designer's selection needed that R01 did not. All of it is STATED on
# the body or the room and passed through; nothing here knows a catalog. Absent keys are not emitted, so an R01
# export (and the BA2 / BA3 fixtures) is byte for byte what it was.
#   room     master, finishes      -> passed to the export (finishes parsed from the JSON string). R01 left them in the
#                                     estimate's sample file; R02 CHANGES them (RI14 instead of LE08, Guest on MAXBA
#                                     LM51), so the laptop step has to be told, not left to copy the old header.
#   unit     code LAVABO + article -> a COUNTERTOP BASIN (Cesar element LAVABO, e.g. LVB019.003). It stands on the top,
#                                     so it is never one of the units 'under' it, and it is never hung. No article ->
#                                     refused: LAVABO alone names a family of basins, not one.
#   unit     master                -> a unit ordered in another collection than the room (Guest: C91230 / C00151 on
#                                     MAX2.2 beside MAXBA vanities, as in the laundry).
#   unit     fronts = fixed        -> fronts that look like drawers and do not open (Bath 2, the unit by the toilet).
#                                     The order note only; HOW Cesar takes it is Elda's question 2 of 2026-11-02.
#   panel / top  finish            -> e.g. RR14 / LM51 on a panel, CE26 on a top.
#   top      th                    -> stated thickness, CHECKED against the body: a stated 20 on a measured 22 is refused.
#   panel    orient = along        -> a panel lying ALONG the wall (Guest: the closing front over the tall unit). Metron has
#                                     not been shown one yet; Andriy 2026-11-02: "do it in Metron as it comes out". So it is
#                                     emitted only when the body SAYS so, marked, with its distance from the wall - the
#                                     across-the-wall default still refuses an unmarked one.
#   upstand  (kind)                -> the 10 cm backsplash on the back wall, same stone as the top (Andriy 2026-11-02).
#                                     NO CESAR CODE IS KNOWN for it in the bathroom line, so the code is the generic
#                                     ALZATINA and the laptop decides the Metron form (an option of the top, or an article).
#                                     It must stand ON a top - the top's ref is emitted - and lie along the wall.
require 'json'

module UCON
  module CabinetEngine
    module Metron
      module_function

      DICTIONARY = 'UCON_METRON'
      ROOM_KEYS  = %w[room revision estimate origin_x_mm origin_y_mm width_mm depth_mm height_mm master finishes].freeze
      BODY_KEYS  = %w[kind code borsx bordx sink note article fronts master finish th].freeze
      FRONTS     = %w[fixed].freeze
      KINDS      = %w[unit panel top upstand skip].freeze
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

      def stated(mt, keys)
        keys.each_with_object({}) { |k, h| h[k] = mt[k] if mt[k] && !mt[k].to_s.empty? }
      end

      def unit_item(b, code)
        mt = b[:metron] || {}
        h = { 'ref' => b[:ref], 'kind' => 'unit', 'code' => code, 'x' => num(b[:x0]), 'y' => num(b[:z0]) }
        # Sospesa=1 is a CABINET fact in Metron; the mirror block carries none, whatever the engine says about it.
        h['hung'] = true if b[:mounting] == 'wall_hung' && b[:object_class] == 'cabinet'
        raise ArgumentError, "#{b[:ref]}: LAVABO with no article - name the basin (e.g. LVB019.003)" if code == 'LAVABO' && mt['article'].to_s.empty?
        if mt['fronts'] && !FRONTS.include?(mt['fronts'])
          raise ArgumentError, "#{b[:ref]}: fronts #{mt['fronts'].inspect} is not one of #{FRONTS.join(' / ')}"
        end
        h.merge(stated(mt, %w[article master fronts]))
      end

      def panel_item(b, code)
        mt = b[:metron] || {}
        if mt['orient'] == 'along'
          raise ArgumentError, "#{b[:ref]}: panel #{code} is marked along the wall and is not" unless (b[:x1] - b[:x0]) > (b[:y1] - b[:y0])
          return { 'ref' => b[:ref], 'kind' => 'panel', 'code' => code, 'orient' => 'along',
                   'pos' => [num(b[:x0]), num(b[:z0]), 0, 0], 'X' => num(b[:x1] - b[:x0]), 'Y' => num(b[:z1] - b[:z0]),
                   'th' => num(b[:y1] - b[:y0]), 'from_wall' => num(-b[:y1]) }.merge(stated(mt, %w[finish]))
        end
        unless [90, -270, 270, -90].include?(b[:rot_deg].to_i) || (b[:x1] - b[:x0]) < (b[:y1] - b[:y0])
          raise ArgumentError, "#{b[:ref]}: panel #{code} does not stand across the wall - only that orientation is known to Metron"
        end
        { 'ref' => b[:ref], 'kind' => 'panel', 'code' => code,
          'pos' => [num(b[:x1]), num(b[:z0]), 0, 270], 'X' => num(b[:y1] - b[:y0]), 'Y' => num(b[:z1] - b[:z0]) }
          .merge(stated(b[:metron] || {}, %w[finish]))
      end

      def top_item(b, code, units)
        # 'under' = within the top's length and below its UPPER face. Not below its lower face: a top with an integrated
        # basin measures z 708..850 in the 7612 model (probe 910) - the bowl hangs 120 below the slab and the units' 828.
        under = units.select { |u| u[:x0] >= b[:x0] - TOL && u[:x1] <= b[:x1] + TOL && u[:z1] <= b[:z1] + TOL }
                     .sort_by { |u| u[:x0] }
        raise ArgumentError, "#{b[:ref]}: top #{code} has no unit under it" if under.empty?
        mt = b[:metron] || {}
        h = { 'ref' => b[:ref], 'kind' => 'top', 'code' => code,
              'units' => under.size > 1 ? [under.first[:ref], under.last[:ref]] : [under.first[:ref]],
              'sx' => num(under.first[:x0] - b[:x0]), 'dx' => num(b[:x1] - under.last[:x1]) }
        %w[borsx bordx sink].each { |k| h[k] = mt[k] if mt[k] && !mt[k].to_s.empty? }
        if mt['th'] && (num(b[:z1] - b[:z0]) - mt['th'].to_f).abs > TOL
          raise ArgumentError, "#{b[:ref]}: top #{code} states th #{mt['th']} and measures #{num(b[:z1] - b[:z0])}"
        end
        h['th'] = num(mt['th']) if mt['th']
        h.merge(stated(mt, %w[finish]))
      end

      def finishes_of(room)
        f = room['finishes']
        return nil if f.nil? || f.to_s.empty?
        f.is_a?(String) ? JSON.parse(f) : f
      rescue JSON::ParserError => e
        raise ArgumentError, "room #{room['room']}: finishes is not JSON - #{e.message}"
      end

      def upstand_item(b, code, tops)
        raise ArgumentError, "#{b[:ref]}: upstand #{code} does not lie along the wall" unless (b[:x1] - b[:x0]) > (b[:y1] - b[:y0])
        on = tops.find { |t| (t[:z1] - b[:z0]).abs <= TOL && b[:x0] >= t[:x0] - TOL && b[:x1] <= t[:x1] + TOL }
        raise ArgumentError, "#{b[:ref]}: upstand #{code} stands on no top" unless on
        { 'ref' => b[:ref], 'kind' => 'upstand', 'code' => code, 'top' => on[:ref], 'x' => num(b[:x0]),
          'L' => num(b[:x1] - b[:x0]), 'h' => num(b[:z1] - b[:z0]), 'th' => num(b[:y1] - b[:y0]) }
          .merge(stated(b[:metron] || {}, %w[finish]))
      end

      # bodies: room-local hashes as above; room: UCON_METRON of the room group (string keys)
      # -> { 'room', 'revision', 'estimate', 'items' => [...] } in the DEFAULT ORDER: units left to right, then the
      # high units (mirrors) left to right, then panels left to right, then tops. The laptop step keeps the order and
      # the ids of a previous room JSON where the items match; this order is only for what is new.
      def room(bodies, room)
        typed = bodies.map { |b| (k = classify(b)) ? [k[0], k[1], b] : nil }.compact
        # a basin stands ON the top: it is a unit for the order and never one of the units under the top.
        unit_b = typed.select { |t| t[0] == 'unit' && t[1] != 'LAVABO' }.map { |t| t[2] }
        items = []
        # cabinets, then what stands on the tops (basins), then the high units (mirrors); left to right in each.
        typed.select { |t| t[0] == 'unit' }
             .sort_by { |_, _, b| [b[:z0].to_f > 1000 ? 2 : (b[:object_class] == 'cabinet' || b[:object_class] == 'filler' ? 0 : 1), b[:x0].to_f] }
             .each { |_, c, b| items << unit_item(b, c) }
        typed.select { |t| t[0] == 'panel' }.sort_by { |_, _, b| b[:x0].to_f }.each { |_, c, b| items << panel_item(b, c) }
        typed.select { |t| t[0] == 'top' }.sort_by { |_, _, b| b[:x0].to_f }.each { |_, c, b| items << top_item(b, c, unit_b) }
        top_b = typed.select { |t| t[0] == 'top' }.map { |t| t[2] }
        typed.select { |t| t[0] == 'upstand' }.sort_by { |_, _, b| b[:x0].to_f }.each { |_, c, b| items << upstand_item(b, c, top_b) }
        refs = items.map { |i| i['ref'] }
        raise ArgumentError, "duplicate refs #{refs.inspect}" unless refs.uniq.size == refs.size
        # NEVER A SILENT DELETION (Contract v2 SS4.2 rule 4, the same promise 85_export keeps): a body that carries an
        # engine code and reaches no Metron item is LISTED, so a filler or a tall unit nobody mapped yet cannot fall
        # out of the order without the file saying so. kind=skip is a decision and is not listed.
        missed = bodies.select { |b| classify(b).nil? && !b[:code].to_s.empty? && (b[:metron] || {})['kind'] != 'skip' }
                       .map { |b| { 'ref' => b[:ref], 'code' => b[:code], 'object_class' => b[:object_class] } }
        out = { 'room' => room['room'], 'revision' => room['revision'], 'estimate' => room['estimate'],
                'source' => room['source'], 'master' => room['master'], 'finishes' => finishes_of(room),
                'items' => items }.reject { |_, v| v.nil? }
        out['not_exported'] = missed unless missed.empty?
        out
      end
    end
  end
end

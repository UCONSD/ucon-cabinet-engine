# frozen_string_literal: true
#
# UCON Cabinet Engine — core/22_placement.rb
#
# The RULES of placement, with no SketchUp in them.
#
# Everything here is plain Ruby over [x, y, z] arrays of millimetres, so the
# whole rule set runs headlessly under `ruby tools/test_contract.rb`. The tool
# that drives a cursor (core/75_place_tool.rb) does nothing but convert between
# SketchUp objects and these numbers. That split is deliberate and matches
# 20_contract.rb: the part that can be wrong in a way nobody notices is the part
# that gets tested.
#
# Settled by experiment in SketchUp before any of it was written down — see
# the placement design note. The three findings that shape this file:
#
#   1. A wall is a GEOMETRIC fact: a face whose normal is horizontal. The wall
#      belongs to the client's model and carries no attribute of ours, so a
#      name or a tag is not available to read, and must not be.
#   2. The unit seats its BACK PLANE on the wall - not its bounding box. The
#      front slab is supposed to stand proud of the carcass.
#   3. Snaps are split across axes so they can never fight: the wall decides
#      rotation and depth, the neighbour decides position along the wall, and
#      the height is latched.
#
# Origin convention, inherited from the generator: x across the face, y depth
# (front at 0, back at +depth), z up.

module UCON
  module CabinetEngine
    module Placement
      # |normal.z| below this is a wall, above 1 - this is a floor or ceiling.
      # ~5 degrees: generous enough for hand-drawn walls, tight enough that a
      # sloped ceiling is never mistaken for one.
      NORMAL_TOL = 0.087

      # How close two ends must come before the joint closes itself, and how
      # far a neighbour's back may sit off this wall plane before it counts as
      # a different run.
      SNAP_MM         = 120
      COPLANAR_TOL_MM = 30

      # Two units are in the same row only if their depth axes point the same
      # way. 0.95 is about 18 degrees - loose enough for a wall drawn by hand,
      # tight enough to reject a return wall.
      PARALLEL_MIN = 0.95

      module_function

      # ---- vector arithmetic, kept local so this file needs nothing ---------

      # Written out longhand rather than as endless methods: this file has to
      # load under whatever Ruby the oldest supported SketchUp ships.
      def dot(a, b)
        a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
      end

      def sub(a, b)
        [a[0] - b[0], a[1] - b[1], a[2] - b[2]]
      end

      def add(a, b)
        [a[0] + b[0], a[1] + b[1], a[2] + b[2]]
      end

      def scale(v, s)
        [v[0] * s, v[1] * s, v[2] * s]
      end

      def cross(a, b)
        [a[1] * b[2] - a[2] * b[1],
         a[2] * b[0] - a[0] * b[2],
         a[0] * b[1] - a[1] * b[0]]
      end

      def normalize(v)
        length = Math.sqrt(dot(v, v))
        raise ArgumentError, 'cannot normalize a zero-length vector' if length.zero?

        scale(v, 1.0 / length)
      end

      # ---- what a face is --------------------------------------------------

      def wall?(normal)
        normalize(normal)[2].abs < NORMAL_TOL
      end

      def floor?(normal)
        normalize(normal)[2].abs > (1.0 - NORMAL_TOL)
      end

      # ---- how a unit sits on a wall ---------------------------------------

      # The unit's own axes expressed in world terms, given the wall's outward
      # normal. The depth axis points INTO the wall, up stays up, and x follows
      # from them - never chosen independently, so the frame is right-handed by
      # construction (x cross y = z) at any wall angle, not only orthogonal ones.
      def frame(normal)
        n  = normalize(normal)
        yv = scale(n, -1.0)
        zv = [0.0, 0.0, 1.0]
        { x: normalize(cross(yv, zv)), y: yv, z: zv }
      end

      # Where the unit's origin goes so that
      #   * its back plane (local y = depth) lands ON the wall, and
      #   * its RIGHT end (local x = width) sits at the point under the cursor.
      #
      # The held corner is right / top / far, fixed. Two other anchors were
      # tried and both were worse: the left edge flips sides when you cross to
      # another wall, and "wherever you grabbed it" makes the same drag feel
      # different every time.
      def origin_on_wall(wall_point, normal, depth_mm, width_mm)
        n = normalize(normal)
        f = frame(normal)
        o = add(wall_point, scale(n, depth_mm))
        add(o, scale(f[:x], -width_mm))
      end

      # ---- what this tool will and will not place --------------------------

      # nil when the unit can be placed, otherwise the reason - phrased for the
      # person holding the mouse, not for the log.
      #
      # A corner unit is refused on purpose and not for want of data: it is
      # dimensioned by its corner geometry rather than a single width (Contract
      # 1.1), its footprint is not its box, and it needs TWO walls at once.
      # Seating it against one wall would produce a plan that looks right and is
      # not, which is worse than refusing - the same rule the picker follows
      # when it lists a type it cannot honestly build.
      def refusal_for(attrs)
        code = attrs['code'] || 'This component'
        if attrs['geometry_kind'].to_s == 'corner'
          return "#{code} is a corner unit: its footprint is not its box and it " \
                 'needs two walls at once, so this tool does not place it yet ' \
                 "(roadmap M2.2). Use SketchUp's own Move tool for now."
        end
        unless attrs['width_mm'] && attrs['depth_mm']
          return "#{code} carries no width and depth in the contract, so there is " \
                 'nothing to seat against a wall.'
        end

        nil
      end

      # ---- how a unit meets its neighbour ----------------------------------

      # Does this neighbour belong to the same row? All three must hold. Without
      # the mounting test a wall unit would butt against a base unit; without
      # the parallel test a unit on a return wall would pull this one out of
      # place; without the coplanar test a run at another depth would.
      def same_row?(mounting, other_mounting, depth_axis_dot, back_offset_mm)
        return false unless mounting.to_s == other_mounting.to_s
        return false if depth_axis_dot < PARALLEL_MIN

        back_offset_mm.abs <= COPLANAR_TOL_MM
      end

      # How far this unit must slide along the wall for one of its ends to meet
      # one of a neighbour's ends. `spans` are [low, high] pairs measured along
      # the same wall axis. Either end may catch - our left onto their right, or
      # our right onto their left - and the SMALLEST correction wins, so the
      # nearest joint is the one that takes. nil when nothing is close enough.
      def pull(mine_lo, mine_hi, spans, snap_mm = SNAP_MM)
        best = nil
        spans.each do |lo, hi|
          [hi - mine_lo, lo - mine_hi].each do |delta|
            next if delta.abs > snap_mm

            best = delta if best.nil? || delta.abs < best.abs
          end
        end
        best
      end
    end
  end
end

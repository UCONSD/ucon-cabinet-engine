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

      # ---- corners: two walls, one node ------------------------------------
      #
      # A corner unit is not a wider cabinet. It occupies a NODE spanning both
      # walls, and the difference between the node and the carcass is the
      # unreachable corner depth that must stay EMPTY. Everything below follows
      # from one sentence: the wasted space belongs in the angle.

      # Where two vertical walls meet, as [x, y, 0]. Both planes are vertical,
      # so the whole thing collapses to a 2x2 solve in plan. nil when they do
      # not cross - two nearly parallel walls are the same wall seen twice, not
      # a corner, and pretending otherwise would put a unit in mid-air.
      def corner_point(point_a, normal_a, point_b, normal_b)
        na = normalize(normal_a)
        nb = normalize(normal_b)
        det = na[0] * nb[1] - na[1] * nb[0]
        return nil if det.abs < 1e-9

        da = na[0] * point_a[0] + na[1] * point_a[1]
        db = nb[0] * point_b[0] + nb[1] * point_b[1]
        [(da * nb[1] - db * na[1]) / det,
         (na[0] * db - nb[0] * da) / det,
         0.0]
      end

      # WHICH ARTICLE this wall demands. Not a preference and not a mirror: S
      # and D are different articles, and a U-shaped kitchen needs both letters
      # of one size (Andriy, 2026-08-20: "on the other side it does not go, and
      # it should not - for the other wall, a different cabinet").
      #
      # The letter is decided by something simpler than the door: WHICH WAY THE
      # WALL RUNS from the corner. The unit can only lie where the wall
      # actually continues, so if the wall runs along +x from the corner the
      # node starts at the corner and the wasted space is at the near end -
      # that is the right execution. If it runs the other way, the node ends at
      # the corner and the wasted space is at the far end - the left one.
      #
      # `wall_run` is the signed extent of the wall along the unit's x axis,
      # measured from the corner. Positive means the wall continues in +x.
      # Which way, and how far, the wall runs from the corner - measured along
      # the unit's x axis. A wall usually overhangs its corner a little on the
      # far side (its own thickness, a sloppy join), so the answer is the
      # DOMINANT side, not merely a non-zero one.
      # The corner must lie ON this wall. Two planes cross wherever they like,
      # including far past the end of either face - that is a crossing, not a
      # corner, and a unit seated there would hang off the end of the wall.
      CORNER_ON_WALL_TOL_MM = 50

      def wall_run(corner_at, wall_lo, wall_hi)
        return nil if corner_at < wall_lo - CORNER_ON_WALL_TOL_MM
        return nil if corner_at > wall_hi + CORNER_ON_WALL_TOL_MM

        forward = wall_hi - corner_at
        back    = corner_at - wall_lo
        return nil if forward <= 0 && back <= 0

        forward >= back ? forward : -back
      end

      def execution_for(wall_run)
        return nil if wall_run.nil? || wall_run.zero?

        wall_run.positive? ? 'right' : 'left'
      end

      # Origin of a corner unit whose node is seated in the angle.
      #
      #   left  execution: carcass [0, carcass], wasted [carcass, nominal]
      #                    -> the corner is the FAR end,  origin = corner - nominal
      #   right execution: wasted [-wasted, 0],  carcass [0, carcass]
      #                    -> the corner is the NEAR end, origin = corner + wasted
      #
      # Off the wall it is the ordinary rule: step forward by the carcass depth
      # so the back plane lands on it.
      def corner_origin(corner, normal, depth_mm, carcass_mm, nominal_mm, execution)
        n = normalize(normal)
        f = frame(normal)
        # SEATED ON THE PRINTED NODE, WITH NOTHING ADDED - and it briefly was
        # not. Earlier on 2026-08-24 this read `nominal_mm + FRONT_GAP_MM`,
        # because the neighbouring run's front missed the outer face of the 8x8
        # by one gap in a real kitchen and the seating looked like the cause.
        # IT WAS NOT. The mismatch is along the wall, and the body that had to
        # move was the FILLER, not the unit: its leg along the width overshot
        # by exactly the gap. Generator.corner_parts now cuts that leg to 77.
        #
        # The factory's own SketchUp export of estimate 2026/30831 agrees with
        # this line as it now stands: the corner carcass ends at exactly
        # nominal - carcass = 250 mm from the perpendicular wall, with no gap.
        slide = execution.to_s == 'left' ? -nominal_mm : (nominal_mm - carcass_mm)
        add(add(corner, scale(n, depth_mm)), scale(f[:x], slide))
      end

      # ---- how far a unit reaches, for continuing a run --------------------

      # What a unit OCCUPIES along its own x, as [low, high], including space
      # that must stay free. One measure serves two jobs: dropping the next unit
      # of a run clear of this one (the high end), and telling a neighbour snap
      # where this one really begins and ends (both).
      #
      # A straight unit reaches its width. A corner unit does not: it occupies a
      # NODE longer than its carcass, and the difference is the unreachable
      # corner depth that has to stay empty. Which side of the carcass that
      # empty space falls on is decided by the execution letter - so the letter,
      # not the box, decides how far to step.
      #
      #   left  execution: carcass [0, carcass], wasted [carcass, nominal]
      #   right execution: wasted [-wasted, 0],  carcass [0, carcass]
      #
      # Returns nil when there is not enough to say. Callers must NOT turn that
      # into a zero: reading a missing width as 0.0 is what used to drop a new
      # unit exactly on top of a corner one, silently.
      def span_mm(width_mm: nil, carcass_mm: nil, nominal_mm: nil, execution: nil)
        return [0.0, width_mm.to_f] if width_mm
        return nil unless carcass_mm && nominal_mm && execution

        wasted = nominal_mm.to_f - carcass_mm.to_f
        execution.to_s == 'left' ? [0.0, nominal_mm.to_f] : [-wasted, carcass_mm.to_f]
      end

      def run_extent_mm(width_mm: nil, carcass_mm: nil, nominal_mm: nil, execution: nil)
        span = span_mm(width_mm: width_mm, carcass_mm: carcass_mm,
                       nominal_mm: nominal_mm, execution: execution)
        span && span[1]
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
          # Corners have been placeable since 2026-08-20. They need a CORNER
          # rather than a wall, and the article follows from the wall, but the
          # tool no longer refuses them for being what they are.
          return nil if attrs['corner_geometry'] && attrs['depth_mm']

          return "#{code} is a corner unit but carries no corner_geometry."
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

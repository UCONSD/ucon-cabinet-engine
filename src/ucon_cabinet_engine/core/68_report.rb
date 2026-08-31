# frozen_string_literal: true
#
# UCON Cabinet Engine — core/68_report.rb  ::  WHAT IS IN THIS MODEL THAT NO
# RULE OWNS.
#
# 2026-08-31, and the thing that asked for it was a plinth. The fridge plinth
# read as missing for a day. It was not missing: it was drawn by hand, so it
# carried no contract, and a body with no contract is invisible to every pass
# that walks the model — Retag would not move it, the painting pass would not
# paint it, and a future contrast pass would not touch it either. Nothing was
# broken. Nobody owned it.
#
# That is a class of problem and not an incident. Every hand-drawn body in a
# real kitchen has the same standing, and the only reason this one surfaced is
# that its neighbours were black and it was white.
#
# ---- THREE BUCKETS, AND THE THIRD IS WHY THIS GETS READ TWICE --------------
#
#   OURS      — carries an object_class. Some rule owns it.
#   DECLARED  — deliberately not ours, and SAID SO by sitting on the
#               placeholder or the reserved-void tag. The client's Wolf range
#               is not a defect and must never be reported as one.
#   ORPHAN    — neither. This is the list.
#
# A report that shows the same twenty innocent objects every time is a report
# nobody opens on the fourth run. So DECLARED is not a nicety: it is the thing
# that keeps the list short enough to be read, and marking a body as declared
# is the second half of this tool even though this version does not write yet.
#
# ---- WHAT COUNTS AS ONE ORPHAN ---------------------------------------------
#
# The OUTERMOST body that owns nothing. A hand-built assembly of twenty groups
# is one thing a person has to decide about, not twenty rows.
#
# But an unclassified group that CONTAINS one of ours is not a body at all — it
# is a folder somebody made while tidying. Descend into it and report what is
# loose inside, or the report hides a real unit behind a wrapper.
#
# And a container with no geometry anywhere under it is counted and not listed.
# It is real, it is worth a number, and it is not a decision.
#
# ---- A TAG IS NOT OWNERSHIP, AND THIS IS DELIBERATE ------------------------
#
# On 2026-08-31 that plinth was given `UCON — Cabinets` and painted, by hand,
# and it STILL appears in this list — correctly. A tag makes a body visible on
# the right sheet; it does not make any rule responsible for it. Putting it on
# a UCON tag fixed how it looked and changed nothing about who owns it. If this
# report went quiet the moment a body got a tag, it would go quiet exactly when
# somebody papers over the problem it exists to find.
#
# ---- NO SKETCHUP IN THE RULES ----------------------------------------------
#
# Same division as Retag, for the same reason: `orphans`, `counts` and `html`
# are pure and are checked headless. `survey` is the only method here that has
# ever heard of a model, and it borrows Retag's two readers rather than growing
# a second copy of "read the instance, then the definition" — the rule that was
# learned the hard way on 2026-08-30 and must not be re-learned per file.

module UCON
  module CabinetEngine
    module Report
      module_function

      # Taken from the generator's own constants. Retyping either string here
      # would make a rename split into two tags that look identical in a menu —
      # the same trap Retag::TAGS names.
      def declared_tags
        [Generator::PLACEHOLDER_TAG, Generator::RESERVED_TAG]
      end

      # ---- THE PURE RULES -------------------------------------------------

      def owned?(node)
        !node[:object_class].to_s.empty?
      end

      def declared?(node)
        declared_tags.include?(node[:tag].to_s)
      end

      # Ours, anywhere at or below this node. Answers "is this a wrapper round
      # something real" rather than "is this real".
      def owns_anything?(nodes)
        Array(nodes).any? do |n|
          owned?(n) || owns_anything?(n[:children])
        end
      end

      def solid?(node)
        return true if node[:faces].to_i.positive?

        Array(node[:children]).any? { |c| solid?(c) }
      end

      # The list. Outermost unowned bodies, wrappers descended into, empties
      # left out (they are counted instead).
      def orphans(nodes)
        out = []
        Array(nodes).each do |n|
          next if owned?(n) || declared?(n)

          if owns_anything?(n[:children])
            out.concat(orphans(n[:children]))
          elsif solid?(n)
            out << n
          end
        end
        out
      end

      # Everything a person wants to see above the list, and every number in it
      # is derived from the same tree the list is, so the two cannot disagree.
      def counts(nodes)
        c = { ours: 0, declared: 0, orphans: 0, empty: 0 }
        walk = lambda do |list|
          Array(list).each do |n|
            if owned?(n)
              c[:ours] += 1
            elsif declared?(n)
              c[:declared] += 1
            elsif owns_anything?(n[:children])
              walk.call(n[:children])
            elsif solid?(n)
              c[:orphans] += 1
            else
              c[:empty] += 1
            end
          end
        end
        walk.call(nodes)
        c
      end

      # ---- THE PAGE -------------------------------------------------------
      #
      # Pure, so the wording is checkable without opening SketchUp. The size is
      # what makes a row recognisable — "600 x 780 x 620" is how a person says
      # "that is the base unit I drew by hand because I forgot it exists".
      def esc(s)
        s.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
      end

      def mm(v)
        return '—' if v.nil?

        f = v.to_f
        (f - f.round).abs < 0.05 ? f.round.to_s : format('%.1f', f)
      end

      def size_text(n)
        "#{mm(n[:w_mm])} × #{mm(n[:h_mm])} × #{mm(n[:d_mm])}"
      end

      def where_text(n)
        "x #{mm(n[:x_mm])}  y #{mm(n[:y_mm])}  z #{mm(n[:z_mm])}"
      end

      def html(items, c)
        rows = Array(items).map do |n|
          <<~ROW
            <tr onclick="sketchup.orphan_pick('#{esc(n[:id])}')">
              <td class="nm">#{esc(n[:name])}</td>
              <td class="sz">#{esc(size_text(n))}</td>
              <td class="wh">#{esc(where_text(n))}</td>
              <td class="tg">#{esc(n[:tag].to_s.empty? ? 'Layer0' : n[:tag])}</td>
              <td class="fc">#{n[:faces].to_i}</td>
            </tr>
          ROW
        end.join

        empty_line =
          if c[:orphans].to_i.zero?
            '<p class="ok">Nothing in this model is unowned. Every body either ' \
            'carries a contract or has been declared not ours.</p>'
          else
            ''
          end

        <<~HTML
          <!DOCTYPE html><html><head><meta charset="utf-8"><style>
          body{font:12px/1.45 -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;
               margin:0;padding:12px;color:#1c1c1e;background:#fff}
          h1{font-size:14px;margin:0 0 2px}
          .sub{color:#6b6b70;margin:0 0 12px}
          .sums{display:flex;gap:14px;margin:0 0 12px;flex-wrap:wrap}
          .sums div{font-size:11px;color:#6b6b70}
          .sums b{display:block;font-size:17px;color:#1c1c1e;font-weight:600}
          .sums .warn b{color:#a8321a}
          table{border-collapse:collapse;width:100%}
          th{text-align:left;font-size:10px;text-transform:uppercase;letter-spacing:.04em;
             color:#8a8a8f;border-bottom:1px solid #e4e4e7;padding:5px 8px 5px 0;font-weight:600}
          td{padding:6px 8px 6px 0;border-bottom:1px solid #f0f0f2;vertical-align:top}
          tr:hover td{background:#f5f5f7;cursor:pointer}
          .nm{font-weight:500}
          .sz,.wh{font-variant-numeric:tabular-nums;white-space:nowrap}
          .wh,.tg,.fc{color:#6b6b70}
          .ok{color:#2b6a3f;background:#f0f7f2;padding:10px;border-radius:5px}
          .note{margin-top:14px;color:#6b6b70;font-size:11px;border-top:1px solid #e4e4e7;
                padding-top:10px}
          </style></head><body>
          <h1>Bodies no rule owns</h1>
          <p class="sub">Click a row to select it in the model. This report writes nothing.</p>
          <div class="sums">
            <div class="warn">Unowned<b>#{c[:orphans].to_i}</b></div>
            <div>Ours<b>#{c[:ours].to_i}</b></div>
            <div>Declared not ours<b>#{c[:declared].to_i}</b></div>
            <div>Empty groups<b>#{c[:empty].to_i}</b></div>
          </div>
          #{empty_line}
          <table><thead><tr>
            <th>Body</th><th>W × H × D</th><th>Where</th><th>Tag</th><th>Faces</th>
          </tr></thead><tbody>#{rows}</tbody></table>
          <p class="note">A body is UNOWNED when it carries no object_class. A tag is not
          ownership: a hand-drawn body put on a UCON tag still appears here, because the tag
          decides which sheet it prints on and no rule has become responsible for it.
          DECLARED means it sits on #{esc(declared_tags.join(' or '))} — said to be somebody
          else's on purpose, and never reported as a defect.</p>
          </body></html>
        HTML
      end

      # ---- THE MODEL SIDE, and the only part that knows what SketchUp is ---

      def container?(entity)
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end

      def entities_of(entity)
        return entity.entities if entity.is_a?(Sketchup::Group)
        return entity.definition.entities if entity.is_a?(Sketchup::ComponentInstance)

        []
      end

      # Depth 4 rather than Retag's 2. Retag stops early on purpose — inside one
      # of our units the parts are not separately drawable objects. This report
      # is looking for the opposite thing, a hand-built assembly, and those nest
      # as deep as somebody's patience.
      def survey(model, depth_limit = 4)
        @index = {}
        walk(model.entities, 0, depth_limit)
      end

      def index
        @index ||= {}
      end

      def walk(ents, depth, depth_limit)
        out = []
        ents.each do |e|
          next unless container?(e)

          oc = Retag.object_class_of(e)
          b  = e.bounds
          id = e.entityID.to_s
          index[id] = e
          own = entities_of(e)
          node = {
            id:           id,
            name:         Retag.display_name(e),
            object_class: oc.to_s,
            tag:          (e.layer ? e.layer.name : ''),
            faces:        own.grep(Sketchup::Face).length,
            w_mm:         b.width.to_mm,
            h_mm:         b.depth.to_mm,
            d_mm:         b.height.to_mm,
            x_mm:         b.min.x.to_mm,
            y_mm:         b.min.y.to_mm,
            z_mm:         b.min.z.to_mm,
            children:     []
          }
          # Ours is a leaf here: its parts are not separate bodies and listing
          # them would be the census this report is not.
          node[:children] = walk(own, depth + 1, depth_limit) if oc.to_s.empty? && depth < depth_limit
          out << node
        end
        out
      end

      # ---- THE WINDOW ------------------------------------------------------

      def show(model = Sketchup.active_model)
        nodes = survey(model)
        items = orphans(nodes)
        c     = counts(nodes)

        @window ||= UI::HtmlDialog.new(
          dialog_title: 'UCON — bodies no rule owns',
          preferences_key: 'UCONOrphanReport1',
          style: UI::HtmlDialog::STYLE_UTILITY,
          width: 720, height: 460,
          min_width: 420, min_height: 240,
          resizable: true
        )
        @window.set_html(html(items, c))
        unless @wired
          @window.add_action_callback('orphan_pick') { |_, id| pick(model, id) }
          @wired = true
        end
        @window.show
        c
      end

      # SELECTS, AND THAT IS ALL. Zooming would move a camera somebody set for a
      # sheet, and this report is not allowed to cost anyone their view.
      def pick(model, id)
        e = index[id.to_s]
        return nil unless e && e.valid?

        model.selection.clear
        model.selection.add(e)
        model.active_view.invalidate
        e
      rescue StandardError
        nil
      end
    end
  end
end

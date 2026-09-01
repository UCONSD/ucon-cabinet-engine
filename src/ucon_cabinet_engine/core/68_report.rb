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

      # ---- A DIALOG OUTLIVES A CORE RELOAD, AND THAT COST AN HOUR ----------
      #
      # 2026-09-01, first press of the new Apply button: nothing happened, and
      # nothing said so. The window had been open since the day before, this
      # module still held it in @window, and `show` reused it - so the page was
      # redrawn with a button calling `orphan_assign`, INTO A DIALOG THAT HAD
      # NEVER HEARD OF IT. The JavaScript called into nothing and JavaScript
      # calling into nothing is silent.
      #
      # THE REPOSITORY ALREADY KNEW THIS: claude/findings-2026-08-27-lit-shelves.md
      # - an HtmlDialog bakes its HTML AND ITS CALLBACKS at open; reloading the
      # core replaces the Ruby and the open window keeps what it opened with.
      # That note was about HTML. The callbacks are the same fact and cost the
      # same hour, four days later.
      #
      # So the window is DROPPED AT LOAD TIME. These two lines run every time
      # this file is loaded - which is exactly what "Reload core" does - and the
      # next `show` therefore builds a new dialog whose callbacks match the Ruby
      # that just arrived. A memo that survives the thing it memoises is not a
      # cache, it is a lie with a fast path.
      begin
        @window.close if defined?(@window) && @window
      rescue StandardError
        nil
      end
      @window = nil

      # THE TAGS ARE NO LONGER A DECLARATION, 2026-09-01. Dated and added; the
      # header above stands. Until this date `declared?` meant `sits on
      # Placeholder or Reserved`, and that was the same category error this file
      # exists to name, from the other side: a tag decides which SHEET a body
      # prints on, and eight scenes already hold saved opinions about these two.
      # Declaring by tag would have cost a sheet every time.
      #
      # THE BRANCH HAD NEVER ONCE FIRED. Declared read 0 on every run: the only
      # bodies on those tags are the engine's own, they carry a class, and
      # `owned?` is asked first. Learned rule 18 - an invariant asserted sideways,
      # found out the day it stops being vacuous. Probe 54 measured it: two
      # bodies, both ours. Removing it changed the list by zero rows.
      #
      # The tags themselves are untouched and the generator still assigns them.
      # They keep one job here, and it is honest: a body sitting on one of them
      # with no recorded reason is FLAGGED, so that somebody who put it there by
      # hand expecting silence is told why it is still listed, on the row, rather
      # than discovering it as a bug.
      def declared_tags
        [Generator::PLACEHOLDER_TAG, Generator::RESERVED_TAG]
      end

      def on_a_declaring_tag?(node)
        declared_tags.include?(node[:tag].to_s)
      end

      # ---- THE PURE RULES -------------------------------------------------

      def owned?(node)
        !node[:object_class].to_s.empty?
      end

      # Not ours, and SAID SO on the body itself - core/67_declare.rb.
      def declared?(node)
        Declare.declared_reason?(node[:declared])
      end

      # Ours, hand-drawn, no contract. It leaves the list and lands in a count
      # that only a stamp can reduce.
      def debt?(node)
        node[:declared].to_s == Declare::DEBT
      end

      # What a person must still answer before a sheet can be issued.
      def blocks_sheet?(node)
        return true unless owned?(node) || declared?(node) || debt?(node)

        declared?(node) && Declare.blocks_sheet?(node[:declared], node[:installed_by])
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
          next if owned?(n) || declared?(n) || debt?(n)

          if owns_anything?(n[:children])
            out.concat(orphans(n[:children]))
          elsif solid?(n)
            out << n
          end
        end
        out
      end

      # THE OTHER TWO SECTIONS. They walk the same tree the list does and by the
      # same rules, so three sections and five numbers can never disagree about
      # one model - the argument `counts` already makes for itself.
      def debts(nodes)
        out = []
        Array(nodes).each do |n|
          next if owned?(n) || declared?(n)

          if debt?(n)
            out << n
          elsif owns_anything?(n[:children])
            out.concat(debts(n[:children]))
          end
        end
        out
      end

      def declared_rows(nodes)
        out = []
        Array(nodes).each do |n|
          next if owned?(n) || debt?(n)

          if declared?(n)
            out << n
          else
            out.concat(declared_rows(n[:children]))
          end
        end
        out
      end

      # Everything a person wants to see above the list, and every number in it
      # is derived from the same tree the list is, so the two cannot disagree.
      def counts(nodes)
        c = { ours: 0, declared: 0, debt: 0, orphans: 0, empty: 0, blocked: 0,
              by_reason: {} }
        walk = lambda do |list|
          Array(list).each do |n|
            c[:blocked] += 1 if blocks_sheet?(n) && (declared?(n) || solid?(n))
            if owned?(n)
              c[:ours] += 1
            elsif declared?(n)
              c[:declared] += 1
              r = n[:declared].to_s
              c[:by_reason][r] = c[:by_reason].fetch(r, 0) + 1
            elsif debt?(n)
              c[:debt] += 1
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

      # A body somebody put on a declaring-looking tag by hand is STILL listed,
      # and this is where that is explained - on the row, where it is felt.
      # Otherwise the change of 2026-09-01 reads as a bug the first time it is
      # met, and a person meeting it would reasonably conclude the tag is broken.
      def tag_flag(node)
        return '' unless on_a_declaring_tag?(node)

        ' <span class="flag">on a declaring tag, not declared</span>'
      end

      def html(items, c, debt_items = [], declared_items = [], said = nil)
        rows = Array(items).map do |n|
          <<~ROW
            <tr onclick="sketchup.orphan_pick('#{esc(n[:id])}')">
              <td class="ck"><input type="checkbox" class="pick" value="#{esc(n[:id])}"
                  onclick="event.stopPropagation();count()"></td>
              <td class="nm">#{esc(n[:name])}</td>
              <td class="sz">#{esc(size_text(n))}</td>
              <td class="wh">#{esc(where_text(n))}</td>
              <td class="tg">#{esc(n[:tag].to_s.empty? ? 'Layer0' : n[:tag])}#{tag_flag(n)}</td>
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
               margin:0;padding:12px 12px 96px;color:#1c1c1e;background:#fff}
          h1{font-size:14px;margin:0 0 2px}
          h2{font-size:11px;text-transform:uppercase;letter-spacing:.04em;color:#8a8a8f;
             margin:18px 0 6px;font-weight:600}
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
          .ck{width:20px}
          .ok{color:#2b6a3f;background:#f0f7f2;padding:10px;border-radius:5px}
          .said{color:#2b6a3f;background:#f0f7f2;padding:8px 10px;border-radius:5px;margin:0 0 12px}
          .flag{color:#a8321a;font-size:10px;white-space:nowrap}
          .note{margin-top:14px;color:#6b6b70;font-size:11px;border-top:1px solid #e4e4e7;
                padding-top:10px}
          #assign{position:fixed;left:0;right:0;bottom:0;background:#fafafa;
                  border-top:1px solid #e4e4e7;padding:8px 12px;display:flex;
                  gap:8px;align-items:center;flex-wrap:wrap}
          #assign select{font:12px inherit;max-width:280px}
          #prints{font-size:11px;color:#6b6b70;flex:1 1 100%}
          #prints b{color:#1c1c1e}
          button{font:12px inherit;padding:3px 10px}
          </style></head><body>
          <h1>Bodies no rule owns</h1>
          <p class="sub">Click a row to select it in the model. Tick rows and give them a
          scope below.</p>
          <div class="sums">
            <div class="warn">Unowned<b>#{c[:orphans].to_i}</b></div>
            <div>Ours, no contract<b>#{c[:debt].to_i}</b></div>
            <div>Ours<b>#{c[:ours].to_i}</b></div>
            <div>Declared not ours<b>#{c[:declared].to_i}</b></div>
            <div>Empty groups<b>#{c[:empty].to_i}</b></div>
            <div class="warn">Blocking a sheet<b>#{c[:blocked].to_i}</b></div>
          </div>
          #{empty_line}
          #{said.to_s.empty? ? '' : "<p class=\"said\">#{esc(said)}</p>"}
          <table><thead><tr>
            <th></th><th>Body</th><th>W × H × D</th><th>Where</th><th>Tag</th><th>Faces</th>
          </tr></thead><tbody>#{rows}</tbody></table>
          #{section('Ours, no contract yet — only a stamp clears these', debt_items)}
          #{section('Declared not ours', declared_items)}
          <p class="note">A body is UNOWNED when it carries no object_class. A tag is not
          ownership: a hand-drawn body put on a UCON tag still appears here, because the tag
          decides which sheet it prints on and no rule has become responsible for it.
          DECLARED means a scope reason is recorded ON THE BODY — said to be somebody else's
          on purpose, and never reported as a defect. Putting a body on
          #{esc(declared_tags.join(' or '))} does NOT declare it and never did; those tags
          decide a sheet, and a row sitting on one says so.
          OURS, NO CONTRACT is ours and hand-drawn: it leaves this list and only a stamp can
          lower that number. Nothing whose scope is undecided may go on a sheet.</p>
          <div id="assign">
            <select id="reason" onchange="refresh()">#{options}</select>
            <select id="inst" onchange="refresh()">#{installer_options}</select>
            <button onclick="apply()">Apply to <span id="n">0</span> ticked</button>
            <button onclick="clr()">Clear scope</button>
            <span id="prints"></span>
          </div>
          <script>
          var CH = #{JSON.generate(Declare.choices)};
          function ticked(){
            var out=[], b=document.querySelectorAll('.pick');
            for(var i=0;i<b.length;i++){ if(b[i].checked) out.push(b[i].value); }
            return out;
          }
          function count(){ document.getElementById('n').textContent = ticked().length; }
          function cur(){
            var r=document.getElementById('reason').value;
            for(var i=0;i<CH.length;i++){ if(CH[i].reason===r) return CH[i]; }
            return null;
          }
          function refresh(){
            var c=cur(), ins=document.getElementById('inst');
            ins.disabled = !c.asks;
            var key = c.asks ? ins.value : 'undecided';
            var p = c.prints[key];
            document.getElementById('prints').innerHTML =
              p ? ('On a sheet this prints <b>'+p+'</b>')
                : (c.asks && key==='undecided'
                    ? 'Nothing prints, and it BLOCKS the sheet until you answer who installs it.'
                    : 'Nothing prints. That is correct for this one.');
            count();
          }
          function apply(){
            var ids=ticked();
            if(!ids.length){ return; }
            var c=cur(), ins=document.getElementById('inst');
            sketchup.orphan_assign(JSON.stringify({
              ids: ids, reason: c.reason,
              installed_by: c.asks ? ins.value : 'undecided'
            }));
          }
          function clr(){
            var ids=ticked();
            if(!ids.length){ return; }
            sketchup.orphan_assign(JSON.stringify({ ids: ids, reason: '' }));
          }
          refresh();
          </script>
          </body></html>
        HTML
      end

      # The control's words are Declare's, not this file's - one table feeds the
      # chooser, the sheet and the legend, so a phrase cannot be revised in one
      # place and stay old in another.
      def options
        Declare::ALL_REASONS.map do |r|
          "<option value=\"#{esc(r)}\">#{esc(Declare::LABELS.fetch(r))}</option>"
        end.join
      end

      def installer_options
        Declare::INSTALLERS.map do |i|
          "<option value=\"#{esc(i)}\">#{esc(Declare::INSTALLER_LABELS.fetch(i))}</option>"
        end.join
      end

      # A section that is empty prints NOTHING - not an empty table and not a
      # heading over nothing. A window that shows three headings when it has one
      # thing to say teaches people to skim it.
      def section(title, list)
        rows = Array(list)
        return '' if rows.empty?

        body = rows.map do |n|
          <<~ROW
            <tr onclick="sketchup.orphan_pick('#{esc(n[:id])}')">
              <td class="nm">#{esc(n[:name])}</td>
              <td class="sz">#{esc(size_text(n))}</td>
              <td class="tg">#{esc(scope_text(n))}</td>
            </tr>
          ROW
        end.join

        "<h2>#{esc(title)}</h2><table><tbody>#{body}</tbody></table>"
      end

      def scope_text(node)
        r = node[:declared].to_s
        return '' if r.empty?

        printed = Declare.note(r, node[:installed_by])
        printed ? "#{Declare::LABELS.fetch(r, r)} → #{printed}" : Declare::LABELS.fetch(r, r)
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
            declared:     Declare.reason_of(e),
            installed_by: Declare.installed_by_of(e),
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
        page  = html(items, c, debts(nodes), declared_rows(nodes), @said)

        @window ||= UI::HtmlDialog.new(
          dialog_title: 'UCON — bodies no rule owns',
          preferences_key: 'UCONOrphanReport1',
          style: UI::HtmlDialog::STYLE_UTILITY,
          width: 720, height: 460,
          min_width: 420, min_height: 240,
          resizable: true
        )
        @window.set_html(page)
        # REGISTERED EVERY TIME, NOT ONCE. The `unless @wired` that used to stand
        # here is the other half of the bug above: after a reload the flag said
        # yes and the dialog said who.
        begin
          @window.add_action_callback('orphan_pick') { |_, id| pick(model, id) }
          # THE ONLY THING IN THIS FILE THAT WRITES, and it delegates: the rules,
          # the refusals and the four keys are Declare's. The window's job is to
          # collect a choice and hand it over, then re-read the model and redraw
          # itself from what it finds - never from what it thinks it just did.
          # Learned rule 15: a successful write is not a correct write.
          @window.add_action_callback('orphan_assign') { |_, payload| assign(model, payload) }
        end
        @window.show
        c
      end

      # Reads the choice, hands it to Declare, then SURVEYS AGAIN and redraws.
      # An empty reason means clear - a wrong declaration has to be removable or
      # the first slip is permanent and people stop pressing the button.
      def assign(model, payload)
        data = JSON.parse(payload.to_s)
        ids  = Array(data['ids']).map(&:to_s)
        ents = ids.map { |i| index[i] }.compact.select(&:valid?)
        return 0 if ents.empty?

        reason = data['reason'].to_s
        if reason.empty?
          model.start_operation('UCON — clear scope', true)
          begin
            ents.each { |e| Declare.clear!(e) }
            model.commit_operation
          rescue StandardError
            model.abort_operation
            raise
          end
        else
          Declare.apply!(model, ents,
                         reason: reason,
                         installed_by: data['installed_by'].to_s)
        end

        @said = if reason.empty?
                  "Scope cleared on #{ents.length} #{ents.length == 1 ? 'body' : 'bodies'}."
                else
                  printed = Declare.note(reason, data['installed_by'].to_s)
                  "#{ents.length} #{ents.length == 1 ? 'body' : 'bodies'} declared " \
                  "#{Declare::LABELS.fetch(reason, reason)} — " \
                  "#{printed ? "prints #{printed}" : 'prints nothing'}. Ctrl-Z undoes it."
                end
        show(model)
        ents.length
      rescue StandardError => e
        UI.messagebox("Nothing was changed.\n\n#{e.message}")
        0
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

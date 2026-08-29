# frozen_string_literal: true
#
# UCON Cabinet Engine — core/66_retag.rb  ::  A BODY THAT CANNOT BE SWITCHED OFF
# IS NOT ON A DRAWING, IT IS IN THE WAY.
#
# 2026-08-29, from 545 Avenida Primavera. The model held EIGHT SCENES — four
# walls and four island faces — every one of them saving its tag state, and
# FIFTY-SIX of the fifty-nine UCON bodies sat on Layer0. So every scene faith-
# fully saved a tag state that did not exist. A LayOut sheet is controlled by
# tags and by nothing else; without them there is one drawing of everything and
# no way to make a second.
#
# ---- WHY THIS IS A COMMAND AND NOT A LINE IN THE GENERATOR -----------------
#
# Andriy's call, 2026-08-29, and it is the worktop division of labour again:
# ONE place does a thing. Tagging at build time would have put the same decision
# in twenty call sites — every build*, every probe that draws, every hand copy —
# and a rule discovered at one call site is not a rule (2026-08-28, the shared
# definition guard that sat in the generator for weeks and never reached the
# panel). Here it is one pass over the model, re-runnable, and it says exactly
# what it did.
#
# ---- THE THREE REFUSALS, WHICH ARE THE WHOLE DESIGN ------------------------
#
# They are numbered as REFUSALS, not as rules: `rule N` is a citation into
# claude/rules.md and its four numbering schemes, and the suite fails a bare one
# on purpose. These three belong to this file alone.
#
# 1. IT NEVER TOUCHES A BODY THAT IS NOT OURS. No CabinetEngine dictionary, no
#    tag. Andriy's walls, floor, ceiling and imported appliances stay exactly
#    where he put them. The engine tags what the engine made and nothing else.
#
# 2. IT NEVER MOVES A BODY THAT ALREADY CARRIES A UCON TAG. The generator
#    already assigns three — Placeholder (not ours), Reserved void, Wasted space
#    — and those carry a fact the CLASS does not. 'Placeholder (not ours)' is a
#    statement of OWNERSHIP (Drawing_Spec: a stand-in for something that is not
#    ours has no surfaces); re-tagging an appliance to a class tag would delete
#    that statement and put a client's machine on a sheet as if we sold it.
#    Only Layer0 — the absence of a decision — is filled in.
#
# 3. AN UNKNOWN object_class IS REFUSED AND NAMED, NEVER GUESSED. If the
#    contract grows a class and this file has not learned it, the run reports
#    the class by name and leaves those bodies alone. The suite makes that
#    impossible to ship: a class in the contract with no tag here fails a check.
#
# ---- ONE TAG PER CLASS, AND THE GROUPING IS NOT OURS TO INVENT -------------
#
# The map below is MECHANICAL: it comes from the contract's own object_class
# list, not from this kitchen. Whether 'Corner units' deserves its own switch on
# a sheet, or belongs folded in with cabinets, is a DRAWING decision, it differs
# per sheet, and SketchUp already has the instrument for it — tag folders, which
# Andriy sets by hand in one drag. Inferring that grouping from one kitchen is
# the error this project has spent three weeks refusing everywhere else.
#
# The names follow the model's existing convention exactly — 'UCON — ' with an
# em dash — so the new tags sort together with the ones the generator makes.
#
# NO SKETCHUP IN THE RULES. tag_for and plan are pure and are checked headless;
# run() is the only method that has ever heard of a model.

module UCON
  module CabinetEngine
    module Retag
      module_function

      PREFIX = 'UCON — '

      # The two that the GENERATOR owns are taken from the generator's own
      # constants rather than retyped. A rename there would otherwise split into
      # two tags that look identical in a menu and behave differently, which is
      # the wall_hung bug of 2026-08-22 wearing a different hat.
      TAGS = {
        'cabinet'         => "#{PREFIX}Cabinets",
        'corner_unit'     => "#{PREFIX}Corner units",
        'filler'          => "#{PREFIX}Fillers",
        'panel'           => "#{PREFIX}Panels",
        'shelf'           => "#{PREFIX}Shelves",
        'worktop'         => "#{PREFIX}Worktops",
        'accessory'       => "#{PREFIX}Accessories",
        'appliance_front' => "#{PREFIX}Appliance fronts",
        'appliance'       => Generator::PLACEHOLDER_TAG,
        'void'            => Generator::RESERVED_TAG
      }.freeze

      # The tag a body of this class belongs on. Raises rather than returning a
      # default: a default here is a body quietly landing on the wrong sheet.
      def tag_for(object_class)
        oc = object_class.to_s
        TAGS.fetch(oc) do
          raise ArgumentError,
                "no tag is defined for object_class #{oc.inspect} — add it to " \
                'Retag::TAGS rather than letting it default onto a sheet'
        end
      end

      UNTAGGED = 'Layer0'

      # ---- THE PURE PASS --------------------------------------------------
      #
      # rows: [{ name:, object_class:, tag: }, ...] — three strings read off the
      # model, nothing else. Returns four lists and no side effect, which is why
      # every rule above is checkable without SketchUp open.
      def plan(rows)
        moves   = []
        kept    = []
        foreign = []
        refused = []

        Array(rows).each do |row|
          oc   = row[:object_class].to_s
          tag  = row[:tag].to_s
          name = row[:name].to_s

          if oc.empty?
            foreign << name                       # refusal 1 - not ours, not touched
            next
          end
          unless tag.empty? || tag == UNTAGGED
            kept << { name: name, tag: tag }      # refusal 2 - a decision already made
            next
          end

          begin
            want = tag_for(oc)
          rescue ArgumentError
            refused << { name: name, object_class: oc }   # refusal 3 - named, not guessed
            next
          end
          moves << { name: name, object_class: oc, from: (tag.empty? ? UNTAGGED : tag), to: want }
        end

        { moves: moves, kept: kept, foreign: foreign, refused: refused }
      end

      # Which tags a plan actually needs. A tag with nothing on it is a switch
      # for nothing, so none is created.
      def tags_needed(plan_result)
        plan_result[:moves].map { |m| m[:to] }.uniq.sort
      end

      # ---- THE MODEL SIDE -------------------------------------------------

      # Reading a body's class: the INSTANCE first, then its definition. That
      # order is not cosmetic — since 1.0.1 a hand copy is split from its shared
      # definition on Apply, so during the window before that the instance is the
      # only one of the two that can be right about itself.
      def object_class_of(entity)
        dict = Contract::DICTIONARY
        oc = entity.get_attribute(dict, 'object_class')
        return oc if oc

        d = (entity.respond_to?(:definition) ? entity.definition : nil)
        d ? d.get_attribute(dict, 'object_class') : nil
      rescue StandardError
        nil
      end

      def display_name(entity)
        n = entity.name.to_s
        return n unless n.empty?

        d = (entity.respond_to?(:definition) ? entity.definition : nil)
        d ? d.name.to_s : '(unnamed)'
      rescue StandardError
        '(unnamed)'
      end

      # Collects the rows. It descends into a container ONLY while that container
      # is not itself one of ours, and no deeper than two levels — the same walk
      # the 2026-08-29 census used, so the two reports are comparable by
      # construction rather than by hope. Inside one of our units the parts are
      # not separately drawable objects and must not become separate switches.
      def survey(model, depth_limit = 2)
        rows = []
        seen = {}
        walk = lambda do |ents, depth|
          ents.each do |e|
            next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)

            oc = object_class_of(e)
            if oc
              rows << { entity: e,
                        name: display_name(e),
                        object_class: oc.to_s,
                        tag: (e.layer ? e.layer.name : UNTAGGED) }
              next
            end
            next if depth >= depth_limit

            d = (e.respond_to?(:definition) ? e.definition : nil)
            next if d.nil? || seen[d.entityID]

            seen[d.entityID] = true
            walk.call(d.entities, depth + 1)
          end
        end
        walk.call(model.entities, 0)
        rows
      end

      # Bodies are SOLID. Only the symbol tags are dashed, and they are made by
      # Symbols.tag, which is where that decision belongs.
      def solid_tag(model, name)
        layer = model.layers[name] || model.layers.add(name)
        if layer.respond_to?(:line_style=) && model.respond_to?(:line_styles)
          want = model.line_styles['Solid']
          layer.line_style = want if want && layer.line_style != want
        end
        layer
      end

      # Applies the plan. One operation, so one undo undoes the whole pass.
      def run(model = Sketchup.active_model)
        rows   = survey(model)
        result = plan(rows.map { |r| { name: r[:name], object_class: r[:object_class], tag: r[:tag] } })

        # The plan decided; this only carries it out. Each row re-asks the same
        # two questions the plan asked, so a divergence would be a divergence in
        # ONE rule rather than two lists silently drifting apart.
        model.start_operation('UCON — Retag model', true)
        begin
          made = {}
          rows.each do |r|
            next unless r[:tag].to_s.empty? || r[:tag] == UNTAGGED

            want = begin
              tag_for(r[:object_class])
            rescue ArgumentError
              next
            end
            made[want] ||= solid_tag(model, want)
            r[:entity].layer = made[want]
          end
          model.commit_operation
        rescue StandardError => e
          model.abort_operation
          raise e
        end

        result
      end

      # The report Andriy reads. Deliberately says what it did NOT do as well as
      # what it did — a pass that silently leaves half the model behind is the
      # failure mode this whole file exists to make visible.
      def report(result)
        lines = []
        lines << "Tagged: #{result[:moves].size} bodies onto #{tags_needed(result).size} tags."
        tags_needed(result).each do |t|
          n = result[:moves].count { |m| m[:to] == t }
          lines << "   #{t} — #{n}"
        end
        lines << ''
        lines << "Left alone, already tagged: #{result[:kept].size}"
        lines << "Left alone, not ours (no CabinetEngine attributes): #{result[:foreign].size}"
        unless result[:refused].empty?
          lines << ''
          lines << 'REFUSED — no tag is defined for these classes, and none was guessed:'
          result[:refused].group_by { |r| r[:object_class] }.each do |oc, list|
            lines << "   #{oc} — #{list.size}"
          end
        end
        lines.join("\n")
      end
    end
  end
end

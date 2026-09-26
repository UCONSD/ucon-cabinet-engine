# frozen_string_literal: true
#
# tools/module_grid.rb - a STRETCHABLE 3D MODULE GRID for planning a run or an
# island before any catalogue unit is placed. Dev tool, not part of either
# extension: nothing in src/ requires it and it never goes into an .rbz.
#
# Load it in SketchUp's Ruby Console (Window > Ruby Console):
#
#   load '/Users/demchenkoandrew/dev/ucon-cabinet-engine/tools/module_grid.rb'
#
# Then Extensions > UCON > Module grid: new. A grid of 600 x 620 modules
# appears at the origin. Stretch it with the SCALE tool: when you let go, the
# grid redraws itself at the new size - whole 600 modules, and whatever does not
# divide by 600 becomes one RED filler cell labelled with its width. The scale
# is taken out again, so a module is always exactly 600 x 620 and never a
# stretched 600.
#
# WHAT IT IS: a planning volume, not cabinetry. No catalogue code, no Contract
# attributes, nothing the exporter reads. It asks "how many modules fit here",
# nothing else. Asked for by Andriy 2026-09-25 for the 7612 Hillside Dr island.
#
# DEFAULTS, 7612 island: module 600 wide, 620 deep (Tangram / Maxima base),
# carcass 840 on a 60 plinth = 900 to the carcass top (Tangram H.84 + 6).
# Change them per grid with Module grid: edit parameters (select the grid).
#
# Height is never taken from the scale tool: the carcass height is a
# catalogue number (H.84 or H.78), so stretching in Z is ignored and reset.
#
# Undo: a stretch and its redraw are ONE undo step.

module UCON
  module ModuleGrid
    DICT  = 'UCON_MODULE_GRID'
    TAG   = 'UCON_MODULE_GRID'
    DEFAULTS = { 'mod_w' => 600.0, 'mod_d' => 620.0, 'carcass_h' => 840.0,
                 'plinth_h' => 60.0, 'w' => 2400.0, 'd' => 1240.0 }.freeze
    EPS = 0.5 # mm; below this a remainder is rounding, not a filler

    module_function

    def mm(v)
      v.to_f.mm
    end

    def to_mm(len)
      len.to_f.to_mm
    end

    def param(defn, key)
      v = defn.get_attribute(DICT, key)
      v.nil? ? DEFAULTS[key] : v.to_f
    end

    def grid?(ent)
      ent.is_a?(Sketchup::ComponentInstance) && ent.definition.get_attribute(DICT, 'mod_w')
    end

    def material(model, name, rgb, alpha)
      m = model.materials[name] || model.materials.add(name)
      m.color = Sketchup::Color.new(*rgb)
      m.alpha = alpha
      m
    end

    def tag(model)
      model.layers[TAG] || model.layers.add(TAG)
    end

    # A box as its own group, so the cells stay separate solids.
    def box(ents, x, y, z, w, d, h, mat, name)
      g = ents.add_group
      g.name = name
      pts = [[x, y, z], [x + w, y, z], [x + w, y + d, z], [x, y + d, z]].map { |p| Geom::Point3d.new(*p) }
      f = g.entities.add_face(pts)
      f.reverse! if f.normal.z < 0
      f.pushpull(h)
      g.entities.grep(Sketchup::Face).each { |fc| fc.material = mat; fc.back_material = mat }
      g
    end

    # Rebuild the contents from the stored parameters and an overall size in mm.
    def rebuild(inst, w_mm, d_mm)
      model = inst.model
      defn  = inst.definition
      mw = param(defn, 'mod_w'); md = param(defn, 'mod_d')
      ch = param(defn, 'carcass_h'); ph = param(defn, 'plinth_h')
      w_mm = [w_mm, 1.0].max; d_mm = [d_mm, 1.0].max

      m_mod  = material(model, 'UCON_GRID_MODULE', [200, 205, 210], 0.55)
      m_fill = material(model, 'UCON_GRID_FILLER', [214, 72, 60], 0.65)
      m_pl   = material(model, 'UCON_GRID_PLINTH', [70, 72, 76], 0.9)

      ents = defn.entities
      ents.clear!

      n    = (w_mm / mw + 1e-6).floor
      rem  = w_mm - n * mw
      rem  = 0.0 if rem < EPS
      rows = [(d_mm / md + 1e-6).floor, 1].max
      drem = d_mm - rows * md
      drem = 0.0 if drem < EPS

      cells = []
      rows.times do |r|
        n.times { |i| cells << [i * mw, r * md, mw, md, false] }
        cells << [n * mw, r * md, rem, md, true] if rem > 0
      end
      cells << [0.0, rows * md, w_mm, drem, true] if drem > 0

      cells.each_with_index do |(x, y, cw, cd, filler), k|
        label = filler ? format('F %d x %d', cw.round, cd.round) : format('%d', cw.round)
        box(ents, mm(x), mm(y), 0, mm(cw), mm(cd), mm(ph), m_pl, "plinth #{k + 1}")
        box(ents, mm(x), mm(y), mm(ph), mm(cw), mm(cd), mm(ch), filler ? m_fill : m_mod, "#{k + 1}: #{label}")
        ents.add_text(label, Geom::Point3d.new(mm(x + cw / 2), mm(y + cd / 2), mm(ph + ch)))
      end

      defn.set_attribute(DICT, 'w', w_mm)
      defn.set_attribute(DICT, 'd', d_mm)
      inst.name = format('UCON grid %d x %d  (%d x %d mod%s)', w_mm.round, d_mm.round, n, rows,
                         rem > 0 || drem > 0 ? ' + filler' : '')
      puts format('UCON grid: %d x %d mm -> %d modules of %d x %d per row, %d row(s)%s%s',
                  w_mm.round, d_mm.round, n, mw.round, md.round, rows,
                  rem > 0 ? format(', filler %d wide', rem.round) : '',
                  drem > 0 ? format(', depth filler %d', drem.round) : '')
    end

    # ------------------------------------------------------------ the stretch
    class Watcher < Sketchup::EntityObserver
      def onChangeEntity(inst)
        return if ModuleGrid.busy?
        return unless inst.valid? && ModuleGrid.grid?(inst)

        t = inst.transformation
        sx = t.xaxis.length.to_f; sy = t.yaxis.length.to_f; sz = t.zaxis.length.to_f
        return if (sx - 1).abs < 1e-6 && (sy - 1).abs < 1e-6 && (sz - 1).abs < 1e-6

        # Never touch the model from inside the observer call itself: defer.
        UI.start_timer(0, false) { ModuleGrid.refit(inst) }
      end
    end

    def busy?
      @busy == true
    end

    def refit(inst)
      return unless inst.valid?

      t = inst.transformation
      sx = t.xaxis.length.to_f; sy = t.yaxis.length.to_f; sz = t.zaxis.length.to_f
      # one stretch can raise several change events; the first refit takes the
      # scale out, and every later one finds nothing to do
      return if (sx - 1).abs < 1e-6 && (sy - 1).abs < 1e-6 && (sz - 1).abs < 1e-6

      defn = inst.definition
      w_new = param(defn, 'w') * sx
      d_new = param(defn, 'd') * sy
      model = inst.model
      @busy = true
      model.start_operation('UCON grid refit', true, false, true) # merges with the scale
      begin
        inst.make_unique if defn.count_instances > 1
        inst.transformation = Geom::Transformation.axes(t.origin, t.xaxis.normalize,
                                                        t.yaxis.normalize, t.zaxis.normalize)
        rebuild(inst, w_new, d_new)
        model.commit_operation
      rescue StandardError => e
        model.abort_operation
        puts "UCON grid refit failed: #{e.class}: #{e.message}"
      ensure
        @busy = false
      end
    end

    def watch(inst)
      @watcher ||= Watcher.new
      @watched ||= {}
      return if @watched[inst.persistent_id]

      inst.add_observer(@watcher)
      @watched[inst.persistent_id] = true
    end

    def watch_all(model)
      model.entities.grep(Sketchup::ComponentInstance).each { |i| watch(i) if grid?(i) }
    end

    # -------------------------------------------------------------- commands
    def create
      model = Sketchup.active_model
      model.start_operation('UCON module grid', true)
      defn = model.definitions.add('UCON_MODULE_GRID')
      DEFAULTS.each { |k, v| defn.set_attribute(DICT, k, v) }
      inst = model.active_entities.add_instance(defn, IDENTITY)
      inst.layer = tag(model)
      @busy = true
      rebuild(inst, DEFAULTS['w'], DEFAULTS['d'])
      model.commit_operation
      model.selection.clear
      model.selection.add(inst)
      watch(inst)
    ensure
      @busy = false
    end

    def edit
      model = Sketchup.active_model
      inst = model.selection.find { |e| grid?(e) }
      return UI.messagebox('Select a UCON module grid first.') unless inst

      d = inst.definition
      keys = %w[mod_w mod_d carcass_h plinth_h w d]
      prompts = ['Module width, mm', 'Module depth, mm', 'Carcass height, mm', 'Plinth height, mm',
                 'Overall width, mm', 'Overall depth, mm']
      res = UI.inputbox(prompts, keys.map { |k| param(d, k).round.to_s }, 'UCON module grid')
      return unless res

      vals = res.map(&:to_f)
      return UI.messagebox('Every value must be above zero.') if vals.any? { |v| v <= 0 }

      model.start_operation('UCON grid parameters', true)
      @busy = true
      inst.make_unique if d.count_instances > 1
      keys.first(4).each_with_index { |k, i| inst.definition.set_attribute(DICT, k, vals[i]) }
      rebuild(inst, vals[4], vals[5])
      model.commit_operation
      watch(inst)
    ensure
      @busy = false
    end

    class AppWatch < Sketchup::AppObserver
      def onOpenModel(model)
        ModuleGrid.watch_all(model)
      end

      def onNewModel(model)
        ModuleGrid.watch_all(model)
      end
    end

    unless defined?(@loaded)
      menu = UCON.respond_to?(:extensions_menu) ? UCON.extensions_menu : UI.menu('Extensions').add_submenu('UCON')
      menu.add_item('Module grid: new') { create }
      menu.add_item('Module grid: edit parameters') { edit }
      Sketchup.add_observer(AppWatch.new)
      @loaded = true
    end
    watch_all(Sketchup.active_model) if Sketchup.active_model
    puts 'UCON module grid loaded: Extensions > UCON > Module grid: new. Stretch it with the Scale tool.'
  end
end

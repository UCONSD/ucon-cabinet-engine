# frozen_string_literal: true
#
# UCON Cabinet Engine — main.rb  ::  THE SHELL
#
# This file registers UI and nothing else.
#
# SketchUp cannot un-register a menu item once it has been added — there is no
# remove API. Anything created here is permanent for the session, which is why
# the shell is guarded, thin, and expected to stop changing almost immediately.
#
# All real work lives in core/ and is re-readable at will, either from the
# "Reload core" menu item below or from dev_reload.rb in the Ruby Console.
# That split is the whole point: iterate on core/ at console speed without ever
# restarting SketchUp or duplicating menu entries.

require 'sketchup.rb'

module UCON
  module CabinetEngine
    PLUGIN_NAME = 'UCON Cabinet Engine' unless defined?(PLUGIN_NAME)
    VERSION     = '0.6.0'               unless defined?(VERSION)

    # expand_path, not bare dirname: if SketchUp ever loads this file through a
    # relative path, the glob below silently finds nothing and the engine
    # cheerfully reports "0 file(s)" instead of failing where you can see it.
    SHELL_ROOT  = File.expand_path(File.dirname(__FILE__)) unless defined?(SHELL_ROOT)
    CORE_GLOB   = File.join(SHELL_ROOT, 'core', '**', '*.rb') unless defined?(CORE_GLOB)

    # Core files load in sorted order. Names are numerically prefixed so
    # dependency order is explicit rather than accidental.
    def self.core_files
      Dir.glob(CORE_GLOB).sort
    end

    # `load`, not `require` — require caches by path and would make reloading a
    # no-op. Re-loading a file reopens the modules and redefines the methods,
    # which is exactly what we want mid-session.
    def self.load_core
      files = core_files
      raise "No core files found under #{SHELL_ROOT}/core" if files.empty?

      # Re-loading a file re-assigns its constants, which is exactly what a
      # reload is for — but Ruby warns about every one of them, and the noise
      # buries real output. Silence warnings for the duration of the load
      # only; anything else (syntax errors, exceptions) still surfaces.
      previous_verbose = $VERBOSE
      $VERBOSE = nil
      begin
        files.each { |file| load file }
      ensure
        $VERBOSE = previous_verbose
      end
      files
    end

    load_core

    # ---- UI registration: exactly once per SketchUp session ----------------
    #
    # SketchUp cannot remove a menu item or a toolbar once added, so everything
    # here is permanent for the session and any change needs a full restart.
    # That is precisely why there is so little of it: the MENU is a cold entry
    # point and the TOOLBAR is one button, while the day-to-day surface is the
    # palette - which lives in core/ and rebuilds itself on Reload core.
    #
    # Removed 2026-08-20: "Build by code…", "Unit Properties panel…" and
    # "Reload core" all duplicated palette buttons, and "Build B80601" was a
    # relic of the days when B80601 was the only thing the engine could make.
    ICON_DIR = File.join(SHELL_ROOT, 'icons') unless defined?(ICON_DIR)

    def self.open_palette
      Palette.show
    rescue StandardError => e
      UI.messagebox("Palette failed:\n\n#{e.class}: #{e.message}")
    end

    def self.about_text
      "#{PLUGIN_NAME} #{VERSION} — #{version_line}\n\n" \
      "Geometry is exterior envelope only.\n" \
      "Output is PRELIMINARY until confirmed in writing by\n" \
      "Cesar / DzineElements (Object Contract, level 4).\n\n" \
      "Core: #{SHELL_ROOT}/core"
    end

    unless defined?(@ui_installed) && @ui_installed
      # ONE UCON submenu, shared with the appliance extension. Neither depends
      # on the other: UCON.extensions_menu is defined in core/05_panel_kit.rb
      # and in the appliance tree's panel_kit.rb, both self-guarding, so
      # whichever extension loads first builds it and the other finds it.
      # Item labels must name their own extension - load order decides the
      # order they appear in, and it is not guaranteed.
      menu = UCON.extensions_menu
      menu.add_item('Cabinet palette…') { open_palette }

      # A 'Reload probe bridge' ITEM WAS TRIED HERE AND TAKEN BACK OUT, 2026-08-28.
      # The suite pins this menu to exactly two items and gives the reason: a
      # SketchUp menu item cannot be removed once added, so every one is permanent
      # for the session and costs a RESTART to change. A dev convenience is the
      # first thing that argument excludes, and the guard was right to refuse it.
      # The button lives in the palette instead, beside Reload core - which is the
      # button that kills the bridge, so the pair sits together.
      menu.add_separator
      menu.add_item('About Cabinet Engine') { UI.messagebox(about_text) }

      command = UI::Command.new(PLUGIN_NAME) { open_palette }
      command.tooltip         = PLUGIN_NAME
      command.status_bar_text = 'Open the UCON Cabinet Engine palette'
      small = File.join(ICON_DIR, 'ucon_24.png')
      large = File.join(ICON_DIR, 'ucon_32.png')
      # A missing icon file makes SketchUp drop the whole button without a word,
      # so the button is added either way and only dressed if the files are there.
      if File.exist?(small) && File.exist?(large)
        command.small_icon = small
        command.large_icon = large
      end

      toolbar = UI::Toolbar.new(PLUGIN_NAME)
      toolbar.add_item(command)
      toolbar.restore

      @ui_installed = true
    end
  end
end

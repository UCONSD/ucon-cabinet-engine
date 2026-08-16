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
    VERSION     = '0.1.0'               unless defined?(VERSION)
    SHELL_ROOT  = File.dirname(__FILE__) unless defined?(SHELL_ROOT)
    CORE_GLOB   = File.join(SHELL_ROOT, 'core', '**', '*.rb') unless defined?(CORE_GLOB)

    # Core files are loaded in sorted order. Names are prefixed numerically so
    # dependency order is explicit rather than accidental.
    def self.core_files
      Dir.glob(CORE_GLOB).sort
    end

    # `load`, not `require` — require caches by path and would make reloading a
    # no-op. Re-loading a file simply reopens the modules and redefines the
    # methods, which is exactly what we want mid-session.
    def self.load_core
      files = core_files
      files.each { |file| load file }
      files
    end

    load_core

    # ---- UI registration: exactly once per SketchUp session ----------------
    unless defined?(@ui_installed) && @ui_installed
      menu = UI.menu('Extensions').add_submenu(PLUGIN_NAME)

      menu.add_item('Build B80601 — frozen baseline v1.0') do
        begin
          Baseline::B80601.build
        rescue StandardError => e
          UI.messagebox("Build failed:\n\n#{e.class}: #{e.message}")
        end
      end

      menu.add_separator

      menu.add_item('Reload core') do
        begin
          files = load_core
          UI.messagebox(
            "Core reloaded — #{files.length} file(s):\n\n" +
            files.map { |f| File.basename(f) }.join("\n")
          )
        rescue StandardError => e
          UI.messagebox("Reload failed:\n\n#{e.class}: #{e.message}")
        end
      end

      menu.add_item('About') do
        UI.messagebox(
          "#{PLUGIN_NAME} #{VERSION}\n\n" \
          "Output is PRELIMINARY until confirmed in writing by\n" \
          "Cesar / DzineElements (Object Contract, level 4).\n\n" \
          "Core: #{SHELL_ROOT}/core"
        )
      end

      @ui_installed = true
    end
  end
end

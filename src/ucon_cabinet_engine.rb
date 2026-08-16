# frozen_string_literal: true
#
# UCON Cabinet Engine — extension registrar.
#
# This file is what SketchUp discovers in the Plugins folder. It does nothing
# except announce the extension and point at the shell. Keep it boring.

require 'sketchup.rb'
require 'extensions.rb'

module UCON
  module CabinetEngine
    unless defined?(@extension_registered) && @extension_registered
      extension = SketchupExtension.new(
        'UCON Cabinet Engine',
        File.join(File.dirname(__FILE__), 'ucon_cabinet_engine', 'main.rb')
      )
      extension.version     = '0.1.0'
      extension.creator     = 'UCON Contemporary Interiors'
      extension.copyright   = '(c) 2026 UCONSD'
      extension.description =
        'Generates preliminary, catalog-coded placeholder cabinetry from ' \
        'manufacturer source data (Cesar first). Output is PRELIMINARY until ' \
        'confirmed by Cesar / DzineElements.'

      Sketchup.register_extension(extension, true)
      @extension_registered = true
    end
  end
end

# frozen_string_literal: true
#
# UCON Appliances — SketchUp extension loader.
#
# Install: copy this file AND the ucon_appliances/ folder into the Plugins
# folder of the SketchUp version you actually run, then restart SketchUp.
# Two things are required, not one: SketchUp finds this .rb, and this .rb
# points at the folder beside it.
#
#   ~/Library/Application Support/SketchUp <VERSION>/SketchUp/Plugins/

require 'sketchup.rb'
require 'extensions.rb'

# The version lives in lib/appliances.rb, which needs no SketchUp. Reading it
# here keeps one number in one file (learned rule 2) instead of two that drift.
require File.join(File.dirname(__FILE__), 'ucon_appliances', 'lib', 'appliances')

module UCON
  module AppliancesExtension
    ROOT = File.dirname(__FILE__)

    unless defined?(@registered)
      ex = SketchupExtension.new(
        'UCON Appliances',
        File.join(ROOT, 'ucon_appliances', 'main')
      )
      ex.description = 'Appliance housings, service zones and budget sets from the ' \
                       'manufacturer design guides. Draws the opening, flags the void ' \
                       'above it, and feeds the UCON appliance schedule.'
      ex.version = UCON::Appliances::VERSION
      ex.creator = 'UCON Contemporary Interiors'
      Sketchup.register_extension(ex, true)
      @registered = true
    end
  end
end

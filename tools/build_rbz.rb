# frozen_string_literal: true
#
# UCON — build the appliance extension's .rbz from this repository.
#
#   ruby tools/build_rbz.rb            -> build/ucon-appliances-<VERSION>.rbz
#
# WHY THIS EXISTS. The package used to live loose in ~/Downloads and the .rbz
# was built from there by hand. It moved into this repository on 2026-08-25, so
# the old .rbz is stale in a way that installs cleanly and then misbehaves: its
# lib file is lib/ucon_appliances.rb, and this tree's is lib/appliances.rb.
# Build from the repository or do not build.
#
# A .rbz is a zip with a different extension. SketchUp needs BOTH the loader
# .rb and the folder beside it, at the archive root:
#
#   ucon_appliances.rb
#   ucon_appliances/...
#
# The suite is NOT shipped: it lives in tools/ and tests the tree, not the
# installed copy.

require 'fileutils'

ROOT = File.expand_path('..', __dir__)
require File.join(ROOT, 'src', 'ucon_appliances', 'lib', 'appliances')

VERSION = UCON::Appliances::VERSION
BUILD   = File.join(ROOT, 'build')
STAGE   = File.join(BUILD, 'stage')
OUT     = File.join(BUILD, "ucon-appliances-#{VERSION}.rbz")

abort 'zip not found on PATH' if `which zip`.strip.empty?

FileUtils.rm_rf(STAGE)
FileUtils.mkdir_p(STAGE)
FileUtils.cp(File.join(ROOT, 'src', 'ucon_appliances.rb'), STAGE)
FileUtils.cp_r(File.join(ROOT, 'src', 'ucon_appliances'), STAGE)

# The generated kit must be current before anything ships with it.
kit = File.join(STAGE, 'ucon_appliances', 'panel_kit.rb')
abort 'panel_kit.rb missing — run tools/build_panel_kit.rb first' unless File.file?(kit)

# zip builds by writing a temp file and renaming it into place, and a rename is
# exactly what the Cowork device mount refuses. So it writes somewhere ordinary
# and the result is COPIED in. Harmless locally, and it means a session on the
# bridge can build the same artefact Andriy does.
require 'tmpdir'
Dir.mktmpdir do |tmp|
  staged = File.join(tmp, File.basename(OUT))
  Dir.chdir(STAGE) { system('zip', '-q', '-r', staged, '.', '-x', '.*') or abort('zip failed') }
  FileUtils.cp(staged, OUT)
end
FileUtils.rm_rf(STAGE)

puts "built #{OUT.sub("#{ROOT}/", '')}  (#{File.size(OUT)} bytes)"
puts
puts 'Install: SketchUp > Extension Manager > Install Extension, pick the .rbz,'
puts 'then restart SketchUp. First run:  Extensions > UCON > Appliances…'

# frozen_string_literal: true
#
# UCON Cabinet Engine — core/00_version.rb
#
# Loads first (00_ prefix). Two identifiers, different jobs:
#
#   CORE_VERSION — the human-declared version. Bump it on meaningful changes.
#   core_stamp   — automatic deploy stamp: the newest mtime among core files.
#                  Changes on every edit with no discipline required, so the
#                  reload dialog always tells you exactly which state of the
#                  code is in memory.
#
# No SketchUp dependency.

module UCON
  module CabinetEngine
    # Plain assignment, NO defined? guard: a guard would keep the stale value
    # across reloads, which is precisely the bug this file exists to prevent.
    # Re-assignment warnings are silenced by the reload wrappers.
    CORE_VERSION = '0.9.3'

    def self.core_stamp
      dir = File.expand_path(File.join(File.dirname(__FILE__)))
      newest = Dir.glob(File.join(dir, '**', '*.rb')).map { |f| File.mtime(f) }.max
      newest ? newest.strftime('%Y-%m-%d %H:%M:%S') : 'unknown'
    end

    def self.version_line
      "core v#{CORE_VERSION}, deployed #{core_stamp}"
    end
  end
end

# frozen_string_literal: true
#
# UCON — regenerate the vendored panel kit.
#
#   ruby tools/build_panel_kit.rb
#
# ONE authored file, design/panel_kit.css, becomes TWO vendored Ruby files —
# one per extension tree, each under its own namespace:
#
#   src/ucon_cabinet_engine/core/05_panel_kit.rb   UCON::CabinetEngine::PanelKit
#   src/ucon_appliances/panel_kit.rb               UCON::Appliances::PanelKit
#
# WHY VENDORED AND NOT SHARED. The two extensions must not require each other:
# the engine has to keep working on a machine where appliances were never
# installed, and 429 checks plus three of the seam's sixteen exist to prove it.
# A shared require would quietly make that false. So the copies are real
# copies, and a check in EACH suite asserts its copy still hashes to what the
# generator stamped. Hand-edit a vendored file and its own suite goes red.
#
# Bump KIT_VERSION below when the design changes. Both suites carry the
# expected version as a literal, so both go red until both are updated - that
# is the alarm, not a nuisance.
#
# The one thing that is genuinely SHARED rather than copied is the Extensions
# submenu, and it is shared through a namespace both extensions already
# occupy, not through a dependency: whichever loads first creates it, the
# other finds it. Neither can tell which ran.

require 'digest'

KIT_VERSION = 1

ROOT = File.expand_path('..', __dir__)
SRC  = File.join(ROOT, 'design', 'panel_kit.css')

TARGETS = [
  { path: File.join(ROOT, 'src', 'ucon_cabinet_engine', 'core', '05_panel_kit.rb'),
    open: "module UCON\n  module CabinetEngine\n    module PanelKit",
    close: "    end\n  end\nend",
    indent: '      ' },
  { path: File.join(ROOT, 'src', 'ucon_appliances', 'panel_kit.rb'),
    open: "module UCON\n  module Appliances\n    module PanelKit",
    close: "    end\n  end\nend",
    indent: '      ' }
].freeze

css = File.read(SRC)
sha = Digest::SHA256.hexdigest(css)[0, 16]

# Shared submenu root. Idempotent and self-guarding, so it does not matter
# which extension loads first or whether a shell is reloaded.
MENU_ROOT = <<~'MENU'
  # The Extensions submenu both extensions hang their items on. Defined on the
  # UCON namespace itself, which both already occupy, so neither depends on the
  # other - whichever loads first builds it and the second finds it here.
  # Memoised, so reloading a shell cannot duplicate the menu.
  module UCON
    unless respond_to?(:extensions_menu)
      def self.extensions_menu
        @extensions_menu ||= UI.menu('Extensions').add_submenu('UCON')
      end
    end
  end
MENU

TARGETS.each do |t|
  body = css.split("\n").map { |l| l.empty? ? '' : l }.join("\n")
  out = +''
  out << "# frozen_string_literal: true\n#\n"
  out << "# GENERATED - do not edit. Source: design/panel_kit.css\n"
  out << "# Regenerate with: ruby tools/build_panel_kit.rb\n"
  out << "#\n# Editing this file by hand makes this tree's suite fail, on purpose.\n#\n"
  out << MENU_ROOT
  out << "\n"
  out << t[:open] << "\n"
  out << "#{t[:indent]}KIT_VERSION = #{KIT_VERSION}\n"
  out << "#{t[:indent]}KIT_SHA = '#{sha}'\n\n"
  out << "#{t[:indent]}CSS = <<~'CSS'\n"
  body.each_line { |l| out << (l.strip.empty? ? "\n" : "#{t[:indent]}  #{l}") }
  out << "\n" unless out.end_with?("\n")
  out << "#{t[:indent]}CSS\n"
  out << t[:close] << "\n"
  File.write(t[:path], out)
  puts "wrote #{t[:path].sub("#{ROOT}/", '')}"
end

puts "KIT_VERSION #{KIT_VERSION}, sha #{sha}"

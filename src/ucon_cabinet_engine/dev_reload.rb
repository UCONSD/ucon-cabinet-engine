# UCON Cabinet Engine — Ruby Console reload helper.
#
# Paste this line into the Ruby Console once. From then on it is Up-arrow,
# Enter for every subsequent iteration:
#
#   load '/Users/demchenkoandrew/dev/ucon-cabinet-engine/src/ucon_cabinet_engine/dev_reload.rb'
#
# It re-reads every file in core/ and then builds B80601, so one keystroke
# covers edit -> reload -> rebuild.
#
# The menu item "Extensions > UCON Cabinet Engine > Reload core" reloads
# without building. Use that when you only want fresh code; use this when you
# want to see the result immediately.
#
# Nothing here touches the shell (main.rb). The shell is loaded once by
# SketchUp at startup and must not be re-loaded, or the menu duplicates.

_ucon_dir   = File.expand_path(File.dirname(__FILE__))
_ucon_files = Dir.glob(File.join(_ucon_dir, 'core', '**', '*.rb')).sort

if _ucon_files.empty?
  raise "[UCON] no core files found under #{_ucon_dir}/core - " \
        'has the repository moved?'
end

_ucon_files.each { |file| load file }

puts "[UCON] reloaded #{_ucon_files.length} core file(s): " \
     "#{_ucon_files.map { |f| File.basename(f) }.join(', ')}"

# Comment out the line below if you want reload without rebuild.
UCON::CabinetEngine::Baseline::B80601.build

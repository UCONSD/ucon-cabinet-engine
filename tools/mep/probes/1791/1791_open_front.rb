# UCON-MODEL: 1791_
# 1791_open_front (2026-11-11): makes ONE model file the FRONT document. Sketchup.open_file opens the file but leaves it behind
# on the Mac (the bridge then works on a back document - that crashed SketchUp). macOS 'open -a <this SketchUp.app> <file>' opens
# it OR brings an already-open one to the front. Checks after 4 s and logs OK / NOT FRONT. Touches no model.
# Usage: a probe sets OPEN_PATH = '...' and then loads this file. Never close a model from a probe.
OPEN_PATH = File.expand_path('~/Documents/1791_PWD_MEP.skp') unless defined?(OPEN_PATH)
LOGF = File.expand_path('~/dev/_claude/1791_open_lusso.log') unless defined?(LOGF)
raise "STOP: no file #{OPEN_PATH}" unless File.exist?(OPEN_PATH)
app = %x(ps -p #{Process.pid} -o comm=).strip[%r{\A(.*?\.app)}, 1] or raise 'STOP: SketchUp.app not found'
want = File.basename(OPEN_PATH, '.skp')
target = OPEN_PATH
UI.start_timer(1, false) do
  ok = system('open', '-a', app, target)
  UI.start_timer(4, false) do
    am = Sketchup.active_model
    front = am && File.basename(am.path.to_s, '.skp') == want
    File.open(LOGF, 'a') { |f| f.puts "#{Time.now} open_front #{want} -> #{ok.inspect}; front: #{am ? am.title : 'none'} #{front ? 'OK' : 'NOT FRONT'}" }
  end
end
puts "open_front scheduled: #{want}"

# tools/probe_bridge.rb - a POST BOX INTO THE OPEN MODEL. Dev tool, not part of
# either extension: nothing in src/ requires it, it carries no version, and it
# never goes into an .rbz. Load it by hand when you want it:
#
#   load '/Users/andriydemko/dev/ucon-cabinet-engine/tools/probe_bridge.rb'
#
# It then polls tools/probe_inbox/ every POLL_S seconds. A .rb file that
# appears there is run, its console output is captured, the result is written to
# tools/probe_outbox.txt, and the file is moved to tools/probe_inbox/done/ so it
# runs once. Stop it with UCON::ProbeBridge.stop.
#
# WHY: a probe used to mean Andriy typing a load line for every question. The
# bridge cannot type into SketchUp and SketchUp cannot see the bridge, so the
# two meet in the file system, which both can reach.
#
# ---------------------------------------------------------------------------
# EVERY RUN IS ROLLED BACK, AND THAT IS A MECHANISM RATHER THAN A PROMISE.
# The script runs inside start_operation and the ensure block ALWAYS calls
# abort_operation, so anything it drew, moved or deleted is undone by SketchUp
# itself. File writes survive the rollback, which is why a probe's report still
# arrives.
#
# THE ONE HOLE, STATED RATHER THAN HIDDEN: a script that opens and COMMITS an
# operation of its own escapes the rollback - that is how SketchUp works and no
# wrapper here can prevent it. Worse than escaping: the inner commit CLOSES the
# outer operation, so everything the probe did afterwards sticks as well.
#
# MEASURED, NOT REASONED ABOUT, 2026-08-25. 07_wall_h222_build.rb ran UNARMED
# and applied in full - six units built through Generator.build, six moved, six
# erased, all of it permanent. So a probe that touches the engine is not rolled
# back in any part, and calling this "read-only unless armed" was wrong.
#
# THE FIRST DETECTOR WAS ALSO WRONG. It compared model.modified? before and
# after, which says nothing once the model has been edited at all - and it had
# been, so the run above passed in silence. It now compares a STRUCTURAL
# fingerprint: how many entities and definitions the model holds. Those move
# when anything is built, moved or erased, whatever the modified flag says.
#
# WHAT THE ROLLBACK IS STILL GOOD FOR: a probe that only reads and prints. That
# is most of them, and for those the guarantee holds. For anything that calls
# the engine, the honest statement is that it applies, and this file says so.
#
# NARROWED 2026-08-25, later, and by measurement again. The sentence above said
# "calling this read-only unless armed was wrong", which overshot: the rollback
# holds for anything that does not call an engine builder, INCLUDING probes that
# draw. Two runs that seated a reservation with Geometry.box, Contract.write!
# and add_instance - no Generator.build anywhere - were rolled back completely,
# and a later audit found neither of them in the model, the mis-seated first one
# included. No warning printed, correctly: the fingerprint came back unchanged.
#
# So the rule is sharper than "engine work applies, reading does not". It is:
# AN INNER commit_operation CLOSES THE OUTER ONE. Generator.build has one;
# Geometry.box does not. A probe that draws its own boxes is as reversible as
# one that only prints, and a probe that builds an article is not reversible at
# all - not in the part that builds, and not in anything it does afterwards.
#
# WHAT THE FINGERPRINT DOES NOT PROVE, 2026-08-30. Dated and added; the
# paragraphs above stand. Run 115 tripped the warning - positions 382874 ->
# 382653 - and that script contained no write of any kind. Twenty-odd unarmed
# runs before it had never tripped it. The cause was Andriy building in the
# model during the two seconds between the two snapshots: the next run showed
# the definition count had gone 309 -> 313 with no probe touching it.
#
# The detector is still worth having. But the warning's own text names ONE
# cause - "the script committed an operation of its own" - and that is a guess,
# not a reading. The fingerprint proves that SOMETHING changed between two
# instants; it cannot say who. A model open in front of a person is a shared
# model, and this bridge is not the only writer in it.
#
# HOW TO TELL THE TWO APART, and it costs one drop: run a second read-only
# probe. An escaped inner commit repeats - the same script writes again. A
# person's edit does not. Learned rule 20.
#
# ARMED MODE is the deliberate exception: UCON::ProbeBridge.arm! makes the next
# ONE run commit instead of abort, and disarms itself immediately afterwards.
# It is for a script that is meant to build something. It is never sticky.
# ---------------------------------------------------------------------------

module UCON
  module ProbeBridge
    POLL_S = 2
    DIR    = File.join(File.dirname(__FILE__), 'probe_inbox')
    DONE   = File.join(DIR, 'done')
    OUT    = File.join(File.dirname(__FILE__), 'probe_outbox.txt')
    # THE OUTBOX IS OVERWRITTEN EVERY RUN, so two probes dropped together used to
    # cost the first one's answer. The log keeps all of them; the outbox stays a
    # single latest-answer file because that is the one a reader wants open.
    LOG    = File.join(File.dirname(__FILE__), 'probe_log.txt')

    class << self
      attr_reader :timer, :runs

      def start
        stop
        FileUtils_mkdir(DIR)
        FileUtils_mkdir(DONE)
        @runs ||= 0
        @armed = false
        @timer = UI.start_timer(POLL_S, true) { tick }
        Sketchup.status_text = 'UCON probe bridge: ON'
        puts "UCON probe bridge ON - watching #{DIR} every #{POLL_S}s"
        puts '  stop with UCON::ProbeBridge.stop'
        true
      end

      def stop
        UI.stop_timer(@timer) if @timer
        @timer = nil
        Sketchup.status_text = 'UCON probe bridge: off'
        true
      end

      def status
        puts(@timer ? "ON, #{@runs.to_i} run(s), armed=#{!!@armed}" : 'off')
        !@timer.nil?
      end

      # The next run COMMITS instead of aborting. One run only.
      def arm!
        @armed = true
        puts 'UCON probe bridge ARMED - the next run will COMMIT, then disarm.'
        true
      end

      private

      def FileUtils_mkdir(path)
        Dir.mkdir(path) unless File.directory?(path)
      end

      def tick
        return unless @timer

        pending = Dir.glob(File.join(DIR, '*.rb')).sort_by { |f| File.mtime(f) }
        return if pending.empty?

        pending.each { |f| run_one(f) }
      rescue StandardError => e
        # A raise inside a SketchUp timer kills the timer without a word, so it
        # is caught here and written down instead.
        write_out(["BRIDGE ERROR: #{e.class}: #{e.message}", *e.backtrace.first(8)])
      end

      def run_one(path)
        @runs = @runs.to_i + 1
        model  = Sketchup.active_model
        name   = File.basename(path)
        armed  = @armed
        @armed = false
        # A STRUCTURAL FINGERPRINT, not model.modified?. See the header: the flag
        # is already true in any model somebody has been working in, so it could
        # not tell an aborted run from an applied one.
        before = fingerprint(model)
        buf    = StringIO.new
        old    = $stdout
        head   = ["UCON probe bridge - run #{@runs}",
                  "file    : #{name}",
                  "at      : #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}",
                  "mode    : #{armed ? 'ARMED - this run COMMITS' : 'rolled back (abort_operation)'}",
                  "model   : #{File.basename(model.path.to_s.empty? ? '(unsaved)' : model.path)}",
                  # THE CODE IN MEMORY, NOT THE CODE ON DISK, and the difference
                  # has already cost one wrong conclusion: an export rule was
                  # fixed in the file, the probe ran against the version
                  # SketchUp still held, and the result read as the fix not
                  # working. core_stamp is the newest mtime among the core
                  # files, so a stamp OLDER than an edit you just made means
                  # Reload core has not been pressed.
                  "core    : #{begin
                                 UCON::CabinetEngine.version_line
                               rescue StandardError
                                 '(engine not loaded)'
                               end}",
                  '-' * 72]
        body = []

        model.start_operation("UCON probe #{name}", true)
        begin
          $stdout = buf
          load path
        rescue StandardError, ScriptError => e
          body << "RAISED: #{e.class}: #{e.message}"
          body.concat(e.backtrace.first(12).map { |l| "  #{l}" })
        ensure
          $stdout = old
          if armed
            model.commit_operation
          else
            model.abort_operation
          end
        end

        body.unshift(buf.string) unless buf.string.empty?
        after = fingerprint(model)
        if !armed && after != before
          head.insert(4, 'WARNING: THIS RUN APPLIED. THE ROLLBACK DID NOT HOLD.')
          head.insert(5, format('  entities %d -> %d, definitions %d -> %d, positions %d -> %d.',
                               before[0], after[0], before[1], after[1], before[2], after[2]))
          head.insert(6, '  The script committed an operation of its own - Generator.build does -')
          head.insert(7, '  and that commit closes the outer operation this bridge opened.')
        end

        write_out(head + body)
        File.rename(path, File.join(DONE, "#{@runs}_#{name}"))
        Sketchup.status_text = "UCON probe bridge: run #{@runs} - #{name}"
        puts "UCON probe bridge: ran #{name} -> #{OUT}"
      end

      # COUNTS ALONE MISS A MOVE, and the first version of this method said so in
      # its own comment and then shipped anyway - which is the shape of bug this
      # bridge exists to catch, so it is fixed rather than noted. The third
      # figure is the summed origin of every top-level instance, rounded to the
      # millimetre: a build or an erase moves the counts, a MOVE moves this.
      #
      # Rounded, and to a coarse unit on purpose. An exact float sum would differ on
      # nothing at all and cry wolf on every run; a millimetre is finer than any
      # move anybody makes on purpose and coarser than any noise.
      def fingerprint(model)
        pos = 0.0
        model.entities.each do |e|
          next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)

          o = e.transformation.origin
          pos += o.x.to_f + o.y.to_f + o.z.to_f
        end
        [model.entities.length, model.definitions.length, (pos * 25.4).round]
      end

      def write_out(lines)
        text = lines.join("\n")
        File.open(OUT, 'w') { |f| f.puts(text) }
        File.open(LOG, 'a') { |f| f.puts(text); f.puts("\n#{'=' * 72}\n") }
      end
    end
  end
end

require 'stringio'
UCON::ProbeBridge.start

# READ-ONLY. Run 113 - verify run 112 by asking the MODEL, not by re-reading
# run 112's own summary.
#
# Three times today a count looked right and hid a defect. So this asserts
# NAMED PROPERTIES of named bodies at named positions, and prints a verdict per
# assertion. A total appears nowhere.
begin
  m    = Sketchup.active_model
  ce   = UCON::CabinetEngine
  dict = ce::Contract::DICTIONARY
  mm   = ->(v) { v.to_mm.round(1) }

  OAKM = 'UCON_Finish_RR09_Rovere_Nordico'
  BLKM = 'UCON_Finish_LX19_Nero'
  FUMO = 'UCON_Finish_Grigio_Fumo'
  ALU  = 'UCON_Finish_Aluminium_Black'
  FAB  = 'UCON_Finish_Glass_Oak_Fabric'

  objs = []
  m.entities.each do |e|
    next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
    dfn = (e.respond_to?(:definition) ? e.definition : nil)
    oc  = (e.get_attribute(dict, 'object_class') rescue nil)
    oc ||= (dfn && (dfn.get_attribute(dict, 'object_class') rescue nil))
    next unless oc
    cd = (e.get_attribute(dict, 'code') rescue nil)
    cd ||= (dfn && (dfn.get_attribute(dict, 'code') rescue nil))
    bb = Geom::BoundingBox.new
    subs = {}
    if dfn
      dfn.entities.each do |sub|
        next unless sub.is_a?(Sketchup::Group) || sub.is_a?(Sketchup::ComponentInstance)
        nm = sub.name.to_s
        nm = sub.definition.name.to_s if nm.empty? && sub.respond_to?(:definition)
        next if nm.upcase.start_with?('SYM_')
        sb = sub.bounds
        8.times { |i| bb.add(sb.corner(i).transform(sub.transformation).transform(e.transformation)) }
        mats = sub.definition.entities.grep(Sketchup::Face).map { |f| f.material ? f.material.name : nil }
        subs[nm] = mats.uniq
      end
    end
    bb = e.bounds if bb.empty?
    objs << { code: cd.to_s, oc: oc.to_s, subs: subs, inst: (e.material ? e.material.name : nil),
              x: mm.call(bb.min.x), y: mm.call(bb.min.y), z: mm.call(bb.min.z) }
  end

  fails = []
  say = lambda do |label, ok, detail|
    puts format("  %-5s %-58s %s", ok ? 'ok' : 'FAIL', label, detail.to_s)
    fails << label unless ok
  end

  at = lambda { |code, x, y, z| objs.find { |o| o[:code] == code && (o[:x] - x).abs < 1 && (o[:y] - y).abs < 1 && (o[:z] - z).abs < 1 } }
  only = lambda { |o, nm, want| o && o[:subs][nm] == [want] }

  puts '== the split, asked of named bodies =='
  isl = [1733.8, 2333.8, 2933.8, 3533.8].map { |x| at.call('B80653', x, 1687.9, 0) }
  say.call('island: four B80653 fronts are oak', isl.all? { |o| only.call(o, 'FRONT_1_FROM_BOTTOM', OAKM) }, "#{isl.count { |o| o }}/4 found")
  ends = [at.call('DV731Q', 1711.8, 1687.9, 0), at.call('DV731Q', 4133.8, 1687.9, 0)]
  say.call('island: both ends DV731Q are oak, not carcass grey', ends.all? { |o| only.call(o, 'CARCASS', OAKM) }, '')
  backs = [[1733.8, 0], [1733.8, 764], [2933.8, 0], [2933.8, 764]].map { |x, z| at.call('DZ731Q', x, 2332.9, z) }
  say.call('island: all four DZ731Q backs are oak', backs.all? { |o| only.call(o, 'CARCASS', OAKM) }, '')
  say.call('east: the tall run end DV061Q is oak', only.call(at.call('DV061Q', 5587.5, 4915.3, 0), 'CARCASS', OAKM), '')

  tall = [at.call('C92640', 5587.5, 1915.3, 0)] + [2515.3, 3115.3, 3715.3, 4315.3].map { |y| at.call('C90635', 5587.5, y, 0) }
  say.call('east: the five tall units are oak', tall.all? { |o| only.call(o, 'FRONT', OAKM) || only.call(o, 'FRONT_1_FROM_BOTTOM', OAKM) }, '')

  up = [103, 703, 1303, 1903, 2513].map { |x| at.call('SD0631', x, 0, 2440) }
  say.call('the upper tier at 2440 is oak, all five south boxes', up.all? { |o| only.call(o, 'FRONT', OAKM) }, "#{up.count { |o| o }}/5 found")
  cust = [at.call('SD0631', 1903, 0, 1720), at.call('SD0631', 2513, 0, 1720)]
  say.call('the two CUSTOM boxes over the range are black', cust.all? { |o| only.call(o, 'FRONT', BLKM) }, '')

  au = at.call('AU110D', 0, 0, 0)
  say.call('AU110D: the door is black', only.call(au, 'FRONT', BLKM), '')
  say.call('AU110D: the 8x8 corner panel is black AT LAST', only.call(au, 'FILLER_8X8', BLKM), au ? au[:subs]['FILLER_8X8'].inspect : '')

  puts ''
  puts '== the finishes decided on 2026-08-29 that had never been drawn =='
  carc = objs.select { |o| o[:subs].key?('CARCASS') && !%w[panel shelf].include?(o[:oc]) }
  say.call('every cabinet carcass is Grigio Fumo', carc.all? { |o| o[:subs]['CARCASS'] == [FUMO] }, "#{carc.size} objects")
  pl = objs.select { |o| o[:subs].key?('PLINTH') }
  say.call('every plinth is Aluminium Black', pl.all? { |o| o[:subs]['PLINTH'] == [ALU] }, "#{pl.size} objects")
  gl = objs.select { |o| o[:code] == 'TF0641' }
  say.call('the three vitrine frames are Aluminium Black', gl.size == 3 && gl.all? { |o| o[:subs]['FRONT (frame: DECLARED)'] == [ALU] }, '')
  say.call('the three vitrine glasses carry the Oak fabric', gl.all? { |o| o[:subs]['FRONT_GLASS'] == [FAB] }, '')

  puts ''
  puts '== nothing left blank, and nothing left inheriting =='
  blank = []
  objs.each { |o| o[:subs].each { |nm, mats| blank << "#{o[:code]}/#{nm}" if mats.include?(nil) } }
  say.call('the only unpainted bodies are the appliance openings',
           blank.all? { |b| b.include?('APPLIANCE_OPENING') }, blank.reject { |b| b.include?('APPLIANCE_OPENING') }.first(6).inspect)
  inh = objs.select { |o| o[:inst] }
  say.call('no object carries an instance material any more', inh.empty?,
           inh.map { |o| "#{o[:code]}=#{o[:inst]}" }.first(6).inspect)

  puts ''
  puts(fails.empty? ? 'VERDICT: every assertion holds. The drawing carries every finish that has been decided.'
                    : "VERDICT: #{fails.size} FAILED -> #{fails.inspect}")
rescue Exception => e
  puts "PROBE FAILED: #{e.class}: #{e.message}"
  puts e.backtrace.first(12)
end

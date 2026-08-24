base = Dir.pwd
%w[10_standards 20_contract 22_placement 50_registry 85_export 60_generator 80_panel].each do |f|
  require File.join(base, 'src/ucon_cabinet_engine/core', f)
end
R = UCON::CabinetEngine::Registry; G = UCON::CabinetEngine::Generator; P = UCON::CabinetEngine::Panel
%w[PC0661 PC0631 PD0631].each do |code|
  u = R.lookup(code); a = G.attributes_for(u)
  st = P.selection_state(u, a)
  print format('%-7s available=%-5s chosen=%-5s handed=%-5s  ', code,
               st['wall_hung_available'], st['wall_hung_chosen'], st['handed'])
  begin
    patch = P.attributes_patch(u, 'opening_method' => 'handle', 'hardware_mode' => 'factory',
                                  'hardware_ref' => 'M00001', 'hinge_side' => 'rh',
                                  'wall_hung' => st['wall_hung_chosen'])
    puts "apply OK -> mounting=#{patch['mounting']} hinge=#{patch['hinge_side'].inspect}"
  rescue StandardError => e
    puts "APPLY FAILED: #{e.message}"
  end
end

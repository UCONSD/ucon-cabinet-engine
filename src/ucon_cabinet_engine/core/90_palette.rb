# frozen_string_literal: true
#
# UCON Cabinet Engine — core/90_palette.rb
#
# Floating tool palette. Lives in core, so unlike the Extensions menu it is
# fully reload-safe: new buttons appear after Reload core, no SketchUp restart
# ever needed. The menu stays as a cold entry point; day to day, this palette
# is the front door.

module UCON
  module CabinetEngine
    module Palette
      module_function

      def show
        @dialog&.close rescue nil
        @dialog = UI::HtmlDialog.new(
          dialog_title: 'UCON Cabinet Engine', preferences_key: 'UCONPalette',
          style: UI::HtmlDialog::STYLE_UTILITY, width: 240, height: 360,
          resizable: false
        )
        @dialog.set_html(html)
        @dialog.add_action_callback('build_by_code') do |_|
          input = UI.inputbox(['Article code'], ['B80601'], 'UCON — Build by code')
          if input
            code = input[0].to_s.strip.upcase
            begin
              Generator.build(code) unless code.empty?
            rescue StandardError => e
              UI.messagebox("Build failed:\n\n#{e.message}")
            end
          end
        end
        @dialog.add_action_callback('panel')  { |_| Panel.show }
        @dialog.add_action_callback('symbols') do |_, mode|
          Symbols.show_mode(Sketchup.active_model, mode.to_sym)
        end
        @dialog.add_action_callback('thin') do |_|
          Symbols.toggle_thin_lines(Sketchup.active_model)
        end
        @dialog.add_action_callback('reload') do |_|
          begin
            files = CabinetEngine.load_core
            @dialog.execute_script("setVersion(#{CabinetEngine.version_line.inspect})")
            UI.messagebox("Core reloaded — #{CabinetEngine.version_line}\n#{files.length} file(s).")
          rescue StandardError => e
            UI.messagebox("Reload failed:\n\n#{e.message}")
          end
        end
        @dialog.show
        @dialog.execute_script("setVersion(#{CabinetEngine.version_line.inspect})")
        nil
      end

      def html
        <<~HTML
          <!DOCTYPE html><html><head><meta charset="utf-8"><style>
            body{font:13px -apple-system,Helvetica,Arial;margin:0;padding:12px;background:#f5f5f4;color:#222}
            button{display:block;width:100%;margin:0 0 8px;padding:9px;border:0;border-radius:6px;
                   background:#fff;border:1px solid #d4d4d4;font-size:13px;cursor:pointer;text-align:left}
            button:hover{background:#eef2ff;border-color:#93b4f5}
            .primary{background:#2563eb;color:#fff;border-color:#2563eb}
            .primary:hover{background:#1d4ed8}
            #ver{color:#999;font-size:10px;margin-top:6px;text-align:center}
            .grp{color:#777;font-size:11px;margin:6px 0 4px}
            .row{display:flex;gap:4px}
            .seg{flex:1;margin:0;padding:6px 2px;text-align:center;font-size:12px}
          </style></head><body>
            <button class="primary" onclick="sketchup.build_by_code()">Build by code…</button>
            <button onclick="sketchup.panel()">Unit Properties panel</button>
            <button onclick="sketchup.reload()">Reload core</button>
            <div class="grp">Opening symbols</div>
            <div class="row">
              <button class="seg" onclick="sketchup.symbols('plan')">Plan</button>
              <button class="seg" onclick="sketchup.symbols('front')">Elevation</button>
              <button class="seg" onclick="sketchup.symbols('all')">All</button>
              <button class="seg" onclick="sketchup.symbols('off')">Off</button>
            </div>
            <button onclick="sketchup.thin()" style="margin-top:8px">Thin / thick lines</button>
            <div id="ver"></div>
            <script>
              function setVersion(v){document.getElementById('ver').textContent=v;}
              window.onload=function(){};
            </script>
          </body></html>
        HTML
      end
    end
  end
end

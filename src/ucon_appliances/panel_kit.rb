# frozen_string_literal: true
#
# GENERATED - do not edit. Source: design/panel_kit.css
# Regenerate with: ruby tools/build_panel_kit.rb
#
# Editing this file by hand makes this tree's suite fail, on purpose.
#
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

module UCON
  module Appliances
    module PanelKit
      KIT_VERSION = 1
      KIT_SHA = '0a2fb89d8015b9f6'

      CSS = <<~'CSS'
        /* UCON panel kit — the ONE authored copy. Everything else is generated.
         *
         * Edit this file, then run:  ruby tools/build_panel_kit.rb
         * That writes the vendored copies into both extension trees and stamps each
         * with KIT_VERSION and a content hash. Hand-editing a vendored copy makes its
         * own suite fail, which is the point.
         *
         * The two extensions must not require each other at runtime, so this is
         * VENDORED, not shared. The check is what keeps the copies honest.
         *
         * TRUST ENCODING — this is not decoration. Both panels distinguish what the
         * factory PRINTED from what we reconstructed (rule 4, PLANNING vs catalog
         * fact). The same distinction must look the same in both, or the colour means
         * two things:
         *
         *   --ok      printed, cited, verified
         *   --amber   assumed / not published — a value we substituted
         *   --red     requires a decision — the void above a housing, a refused order
         */

        :root{
          --bg:#fff; --bg-sunk:#f5f5f4; --bg-hover:#f7f9fa;
          --ink:#1c2024; --muted:#6b7480; --line:#e3e7ea; --accent:#2f3e46;
          --ok:#3f7d4e;
          --amber:#c2a24a; --amber-bg:#fff6e0; --amber-line:#ecd9a8; --amber-ink:#6b5312;
          --red:#c63a30;   --red-bg:#fdecea;   --red-line:#f2c4bf;   --red-ink:#8a2b22;
        }
        *{box-sizing:border-box;margin:0;padding:0}
        body{font:13px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",Arial,sans-serif;color:var(--ink);background:var(--bg)}
        header{padding:12px 14px 10px;border-bottom:1px solid var(--line);display:flex;align-items:baseline;gap:8px}
        header h1{font-size:13px;font-weight:600}header span{font-size:11px;color:var(--muted)}
        .ctl{padding:9px 14px;border-bottom:1px solid var(--line);display:grid;grid-template-columns:1fr 1fr;gap:8px;align-items:center}
        .ctl label{font-size:10px;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);display:block;margin-bottom:3px}
        .ctl select,.ctl input{width:100%;padding:5px 7px;border:1px solid var(--line);border-radius:5px;font:12.5px inherit}
        .tabs{display:flex;border-bottom:1px solid var(--line)}
        .tabs div{flex:1;text-align:center;padding:9px 0;font-size:12px;color:var(--muted);cursor:pointer;border-bottom:2px solid transparent}
        .tabs div.on{color:var(--ink);font-weight:600;border-bottom-color:var(--accent)}
        ul{list-style:none}
        li.item{padding:10px 14px;border-bottom:1px solid var(--line);cursor:pointer;display:flex;gap:10px}
        li.item:hover{background:var(--bg-hover)}
        .chip{font-size:10px;text-transform:uppercase;color:#fff;background:var(--accent);border-radius:3px;padding:2px 5px;flex:0 0 auto;margin-top:1px}
        .chip.sz{background:#3a4a52}.chip.wolf{background:#8c2f24}.chip.cove{background:#4a6572}
        .mdl{font-weight:600}.sub{font-size:11.5px;color:var(--muted);margin-top:1px}
        .grid{padding:10px;display:grid;grid-template-columns:repeat(3,1fr);gap:7px}
        .rowlab{padding:12px 12px 2px;font-size:12px;font-weight:600}
        .card{border:1px solid var(--line);border-radius:7px;padding:9px 8px;cursor:pointer;text-align:center}
        .card:hover{border-color:var(--accent);background:var(--bg-hover)}
        .card .lv{font-size:10px;text-transform:uppercase;color:var(--muted)}
        .card .pr{font-size:14px;font-weight:600;margin-top:3px}
        .card .mt{font-size:10.5px;color:var(--muted);margin-top:3px}
        .back{padding:9px 14px;border-bottom:1px solid var(--line);color:var(--muted);cursor:pointer;font-size:12px}
        .hd{padding:14px 14px 10px}.hd h2{font-size:15px;font-weight:600}.hd p{font-size:12px;color:var(--muted);margin-top:3px}
        .big{display:flex;border-top:1px solid var(--line);border-bottom:1px solid var(--line);margin-top:12px}
        .big div{flex:1;padding:11px 6px;text-align:center;border-right:1px solid var(--line)}
        .big div:last-child{border-right:none}
        .big .n{font-size:18px;font-weight:600}.big .n.na{color:var(--amber)}
        .big .l{font-size:10px;color:var(--muted);text-transform:uppercase;margin-top:2px}
        .big .i{font-size:10.5px;color:var(--muted);margin-top:2px}
        .sec{padding:12px 14px 0}.sec h3{font-size:10px;text-transform:uppercase;letter-spacing:.07em;color:var(--muted);margin-bottom:7px}
        .util{border:1px solid var(--line);border-radius:6px;padding:9px 10px;margin-bottom:7px}
        .dot{width:9px;height:9px;border-radius:2px;display:inline-block;margin-right:6px}
        .util .sp{font-size:11.5px;color:#3b444d;margin-top:4px}
        .util .zn{font-size:11.5px;margin-top:5px;padding-top:5px;border-top:1px dashed var(--line);color:var(--muted)}
        .util .zn b{color:var(--ink);font-weight:600}
        .warn{margin:12px 14px 0;background:var(--red-bg);border:1px solid var(--red-line);border-radius:6px;padding:9px 10px;font-size:11.5px;color:var(--red-ink)}
        .void{margin:12px 14px 0;background:var(--amber-bg);border:1px solid var(--amber-line);border-radius:6px;padding:9px 10px;font-size:11.5px;color:var(--amber-ink)}
        .note{font-size:11.5px;color:var(--muted);padding:2px 0}
        .src{margin:12px 14px;padding-top:9px;border-top:1px solid var(--line);font-size:11px;color:var(--muted);font-family:ui-monospace,Menlo,monospace}
        .acts{padding:4px 14px 14px;display:grid;grid-template-columns:1fr 1fr;gap:7px}
        button{font:12.5px inherit;padding:8px 6px;border:1px solid var(--line);background:#fff;border-radius:6px;cursor:pointer;color:var(--ink)}
        button:hover{background:#f2f5f7}button.pri{background:var(--accent);color:#fff;border-color:var(--accent)}
        button:disabled{background:var(--line);color:var(--muted);cursor:default}
        button.wide{grid-column:1/-1}
        table.li{width:100%;border-collapse:collapse;font-size:11.5px}
        table.li td{padding:6px 4px;border-bottom:1px solid var(--line);vertical-align:top}
        table.li td.r{text-align:right;white-space:nowrap}
        table.li tr.tot td{border-top:2px solid var(--accent);font-weight:600}
        footer{padding:9px 14px;border-top:1px solid var(--line);font-size:10.5px;color:var(--muted)}

        /* trust — the same rule rendered, in both panels */
        .ok,.trust-printed{color:var(--ok)}
        .no,.trust-decide{color:var(--red)}
        .trust-assumed{color:var(--amber)}
        /* an inline amber note: read this before ordering. Not an error, not a value. */
        .flag{color:var(--amber);font-size:11px;margin-top:4px}

        /* the other extension, as observed. Never as assumed. */
        .peer{font-size:10.5px;color:var(--muted)}
        .peer b{color:var(--ink);font-weight:600}
        .peer.off{color:var(--amber)}
      CSS
    end
  end
end

# frozen_string_literal: true
#
# UCON Appliances — the floating panel.
#
# The panel holds no rules and no data of its own: everything on screen is
# serialised out of lib/appliances.rb at open time. If the JSON changes, the
# panel changes with it — close and reopen, because an HtmlDialog bakes its
# HTML and its callbacks when it opens.

require File.join(File.dirname(__FILE__), 'panel_kit')

module UCON
  module AppliancesUI
    extend self

    # OBSERVATION ONLY. The appliance extension never calls into the engine -
    # that direction is what the seam exists to forbid. Asking whether a
    # constant is defined is not a dependency, and neither is saying so on
    # screen. If the engine is loaded but its seam has not picked this package
    # up yet, the remedy is a button that ALREADY EXISTS on the engine's own
    # palette, so we name it rather than reaching for it.
    def core_state
      unless defined?(UCON::CabinetEngine::CORE_VERSION)
        return { ok: false, text: 'Cabinet Engine not loaded — appliances work standalone.' }
      end

      v = UCON::CabinetEngine::CORE_VERSION
      seam = defined?(UCON::CabinetEngine::ApplianceCheck) &&
             UCON::CabinetEngine::ApplianceCheck.respond_to?(:available?) &&
             UCON::CabinetEngine::ApplianceCheck.available?
      return { ok: true, text: "Cabinet Engine #{v} — seam active." } if seam

      { ok: false,
        text: "Cabinet Engine #{v} loaded, but its seam does not see this package yet. " \
              'Press Reload core on the cabinet palette.' }
    end

    def payload
      sets = A.sets['sets'].map do |s|
        t = A.set_total(s['key'])
        s.merge('total_usd' => t['total_usd'], 'rebate_usd' => t['rebate_usd'],
                'net_usd' => t['net_usd'], 'addons' => t['addons'],
                'items' => s['items'].map do |i|
                  rec = A.find(i['model'])
                  o = rec && A.opening(i['model'])
                  i.merge('name' => rec && rec['product_name'],
                          'msrp' => A.price(i['model']),
                          'opening' => o && [o['w'], o['h'], o['d']],
                          'install_class' => rec && rec['install_class'],
                          'ada' => rec && rec['ada_variant'])
                end)
      end
      list = A.all.map do |a|
        { 'model' => a['model'], 'brand' => a['brand'], 'series' => a['series'],
          'name' => a['product_name'], 'type' => a['type'],
          'install_class' => a['install_class'], 'finish' => a['finish'],
          'installations' => A.installations_for(a['model']),
          'default' => A.default_installation(a['model']),
          'openings' => a['installations'], 'services' => a['services'],
          'ada' => a['ada_variant'], 'notes' => a['notes'],
          'msrp' => A.price(a['model']), 'setback' => A.setback_for(a['model']) }
      end
      JSON.generate('sets' => sets, 'list' => list,
                    'rules' => A.rules, 'snapshot' => A.prices['snapshot'])
    end

    def html
      <<~HTML
        <!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><style>
        #{UCON::Appliances::PanelKit::CSS}
        </style></head><body>
        <header><h1>UCON &middot; Appliances</h1><span>openings, services, sets</span></header>
        <div class="peer#{UCON::AppliancesUI.core_state[:ok] ? '' : ' off'}" style="padding:7px 14px;border-bottom:1px solid var(--line)">#{UCON::AppliancesUI.core_state[:text]}</div>
        <div class="ctl">
          <div><label>Front system</label>
            <select id="front"><option value="handle">handle</option><option value="gola">gola / grip recess</option></select></div>
          <div><label>Run top, mm from floor</label><input id="top" type="number" value="2200" step="10"></div>
        </div>
        <div class="tabs"><div id="tS" class="on" onclick="tab('s')">Sets</div><div id="tL" onclick="tab('l')">All appliances</div></div>
        <div id="s"></div><div id="l" style="display:none"><ul id="items"></ul>
          <footer id="foot"></footer></div><div id="d"></div>
        <script>
        const P = #{payload};
        const COL={power:'#e8b21e',gas:'#ce5c30',water:'#3a84c8',drain:'#6e7a8a',duct:'#8a68be'};
        const esc=s=>(s||'').replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));
        const usd=n=>n?'$'+Math.round(n).toLocaleString('en-US'):'—';
        const bc=b=>b==='Wolf'?'wolf':(b==='Cove'?'cove':'sz');
        const front=()=>document.getElementById('front').value;
        const top_=()=>parseInt(document.getElementById('top').value||'2200',10);
        function tab(t){document.getElementById('d').style.display='none';
          document.getElementById('s').style.display=t==='s'?'block':'none';
          document.getElementById('l').style.display=t==='l'?'block':'none';
          document.getElementById('tS').className=t==='s'?'on':'';document.getElementById('tL').className=t==='l'?'on':'';}
        function voidFor(h){if(h==null)return null;const v=top_()-h;
          if(v<0)return{h:v,err:true};
          const t=P.rules.void.threshold_mm;
          return{h:v,fill:v<=t?[P.rules.void.at_or_below]:P.rules.void.above};}
        function renderSets(){let h='';
          [36,48,60].forEach(w=>{h+=`<div class="rowlab">${w}" cooking</div><div class="grid">`;
            ['Core','Plus','Full'].forEach(l=>{const p=P.sets.find(x=>x.cooking_width_in===w&&x.level===l);
              h+=`<div class="card" onclick="openSet('${p.key}')"><div class="lv">${l}</div>
                  <div class="pr">${usd(p.total_usd)}</div>
                  <div class="mt">${p.items.length} items</div>
                  <div class="mt">net ${usd(p.net_usd)}</div></div>`;});h+='</div>';});
          h+=`<footer>US list MSRP, snapshot ${P.snapshot}. Not supplied by UCON — the dealer quotes.</footer>`;
          document.getElementById('s').innerHTML=h;}
        function openSet(k){const p=P.sets.find(x=>x.key===k);const g=front()==='gola';
          let blocked=[];
          const rows=p.items.map(it=>{
            let m=it.model,note='';
            if(g&&it.install_class==='undercounter'){ if(it.ada){m=it.ada;note=' &middot; ADA';}
              else {blocked.push(it.model);note=' &middot; <span class="no">no ADA version</span>';}}
            const o=it.opening?it.opening.filter(x=>x).join(' &times; '):'no opening';
            return `<tr><td><b>${esc(m)}</b>${it.qty>1?' &times;'+it.qty:''}${note}
              <div class="sub">${esc(it.name)}</div><div class="sub">${o}</div></td>
              <td class="r">${usd(it.msrp*it.qty)}</td></tr>`;}).join('');
          document.getElementById('s').style.display='none';document.getElementById('l').style.display='none';
          const d=document.getElementById('d');d.style.display='block';
          d.innerHTML=`<div class="back" onclick="tab('s')">&lsaquo; all sets</div>
            <div class="hd"><h2>${p.cooking_width_in}" cooking &middot; ${p.level}</h2>
            <p>${p.items.length} items &middot; refrigeration ${p.refrigeration_width_in}"</p>
            <div class="big"><div><div class="n">${usd(p.total_usd)}</div><div class="l">list</div><div class="i">manufacturer MSRP</div></div>
            <div><div class="n">${usd(p.rebate_usd)}</div><div class="l">rebate</div><div class="i">${p.addons} add-ons</div></div>
            <div><div class="n">${usd(p.net_usd)}</div><div class="l">net</div><div class="i">to the client</div></div></div></div>
            ${blocked.length?`<div class="warn"><b>${blocked.length} appliance(s) cannot sit under a grip recess.</b>
              ${blocked.map(esc).join(', ')} — no ADA version exists. Interrupt the profile (GOL080) or use a grip edging on the panel.</div>`:''}
            <div class="sec"><h3>Line items</h3><table class="li">${rows}
              <tr class="tot"><td>Total, US list</td><td class="r">${usd(p.total_usd)}</td></tr></table></div>
            <div class="src">US list MSRP, snapshot ${P.snapshot}.<br>Not supplied by UCON. Your dealer will quote.</div>
            <div class="acts"><button class="pri" onclick="sketchup.placeset('${p.key}|'+front()+'|'+top_())">Place all housings</button>
            <button onclick="sketchup.clear()">Clear drawn geometry</button></div>`;
          window.scrollTo(0,0);}
        function renderList(){document.getElementById('items').innerHTML=P.list.map(r=>`
          <li class="item" onclick="openItem('${r.model}')"><span class="chip ${bc(r.brand)}">${esc(r.brand)}</span>
          <span><span class="mdl">${esc(r.model)}</span>
          <div class="sub">${esc(r.name||r.type)}</div>
          <div class="sub">${r.installations.length?r.installations.join(' / '):'no opening'}</div></span></li>`).join('');
          document.getElementById('foot').textContent='A value appears here only if it is printed in the manufacturer design guide.';}
        function openItem(m){const r=P.list.find(x=>x.model===m);const inst=r.default||r.installations[0];
          const o=inst?r.openings[inst]:null;const v=o?voidFor(o.h):null;
          const cell=(x,l)=>`<div><div class="n ${x?'':'na'}">${x||'—'}</div><div class="l">${l}</div></div>`;
          const utils=r.services.map(s=>{
            const zs=(s.datum_x==='none'||!s.h)?`<div class="zn">No coordinates inside the opening — ${esc(s.note||'')}</div>`
              :`<div class="zn">Zone <b>${s.w?s.w+' &times; '+s.h:s.h+' high, full width'}</b> mm &middot;
                 <b>${s.x}</b> from ${esc(s.datum_x.replace(/_/g,' '))} &middot; bottom <b>${s.y}</b> from floor<br>${esc(s.note||'')}</div>`;
            return `<div class="util"><span class="dot" style="background:${COL[s.service]}"></span><b>${esc(s.service)}</b>
              <div class="sp">${esc(s.spec)}</div>${zs}</div>`;}).join('');
          const g=front()==='gola'&&r.install_class==='undercounter';
          document.getElementById('s').style.display='none';document.getElementById('l').style.display='none';
          const d=document.getElementById('d');d.style.display='block';
          d.innerHTML=`<div class="back" onclick="tab('l')">&lsaquo; all appliances</div>
            <div class="hd"><h2>${esc(r.model)}</h2><p>${esc(r.brand)} &middot; ${esc(r.name||r.type)}</p>
            <div class="big">${cell(o&&o.w,'width')}${cell(o&&o.h,'height')}${cell(o&&o.d,'depth')}</div></div>
            ${g&&!r.ada?`<div class="warn"><b>Cannot sit under a grip recess.</b> No ADA version of ${esc(r.model)} exists.
              Interrupt the profile (GOL080) or put a grip edging on the panel.</div>`:''}
            ${g&&r.ada?`<div class="void">Front system is gola — this will be placed as <b>${esc(r.ada)}</b>.</div>`:''}
            ${v&&v.err?`<div class="warn"><b>The run is shorter than the opening.</b> ${-v.h} mm missing.</div>`
              :(v?`<div class="void"><b>Void above: ${v.h} mm.</b> Offer ${v.fill.map(f=>f.replace(/_/g,' ')).join(' or ')},
                 ${P.rules.void.material} material.${r.setback?` Set back ${r.setback} from the cabinet front.`:''}</div>`:'')}
            <div class="sec"><h3>Services</h3>${utils}</div>
            ${r.notes&&r.notes.length?`<div class="sec"><h3>Notes</h3>${r.notes.map(n=>`<div class="note">&bull; ${esc(n)}</div>`).join('')}</div>`:''}
            <div class="src">${inst?esc(inst.replace(/_/g,' ')):'no opening'}<br>${o?esc(o.source):''}</div>
            <div class="acts">
              ${r.installations.map(i=>`<button class="${i===r.default?'pri':''}"
                 onclick="sketchup.place('${r.model}|'+'${i}'+'|'+front()+'|'+top_())">Place ${i.replace(/_/g,' ')}</button>`).join('')}
              <button class="wide" onclick="sketchup.clear()">Clear drawn geometry</button></div>`;
          window.scrollTo(0,0);}
        document.getElementById('front').addEventListener('change',()=>{tab('s');renderSets();});
        renderSets();renderList();
        </script></body></html>
      HTML
    end

    def show
      @dlg&.close
      @dlg = UI::HtmlDialog.new(
        dialog_title: 'UCON · Appliances', preferences_key: 'ucon_appliances',
        scrollable: true, resizable: true, width: 430, height: 780, min_width: 360,
        style: UI::HtmlDialog::STYLE_DIALOG
      )
      @dlg.set_html(html)
      @dlg.add_action_callback('place') do |_c, arg|
        m, inst, fs, top = arg.split('|')
        place(m, installation: inst, front_system: fs, section_top_mm: top.to_i)
        nil
      end
      @dlg.add_action_callback('placeset') do |_c, arg|
        k, fs, top = arg.split('|')
        place_set(k, front_system: fs, section_top_mm: top.to_i)
        nil
      end
      @dlg.add_action_callback('clear') { |_c| clear; nil }
      @dlg.show
    end

    unless defined?(@menu_added)
      m = UCON.extensions_menu
      m.add_item('Appliances…') { show }
      m.add_item('Clear appliance housings') { clear }
      @menu_added = true
    end
  end
end

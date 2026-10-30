#!/usr/bin/env python3
"""rit_build.py (2026-10-29) - one generator for Metron .rit from a room JSON (UCON, Cesar INTBA baths first).

Replaces per-room scripts (ba2_18_gen.py, ba3_19_gen.py ...). The room JSON is what the SketchUp
exporter will produce; for now it is written by hand from the codes sheet.

usage: python3 rit_build.py room.json out.rit
       paths in the JSON are relative to the JSON file's folder.

Room JSON:
{
  "estimate": "T_00019",
  "base": "T_00019_s_samples.rit",      # .rit of THIS estimate after SUSPEND with one sample per code
  "items": [                             # output order = list order; ids = STRUTTURA numbers
    {"id": 1, "kind": "unit",  "src": {"struct": 1}, "x": 7,   "y": 243, "hung": true},
    {"id": 5, "kind": "unit",  "src": {"struct": 1}, "x": 1057,"y": 243, "hung": true},   # clone of struct 1
    {"id": 4, "kind": "unit",  "src": {"struct": 4}, "x": 157, "y": 1250},               # mirror
    {"id": 6, "kind": "panel", "src": {"file": "T_00016_v2.rit", "code": "PAN018"},
             "pos": [7, 243, 0, 270], "X": 470, "Y": 585},
    {"id": 3, "kind": "top",   "src": {"struct": 3}, "units": [1, 5],
             "sx": 7, "dx": 7, "borsx": "BOR002", "bordx": "BOR002", "sink": "LVBF05.002"}
  ]
}

Rules built in (all verified in Metron 2026-10-28/29, see docs/metron_rules.json):
 unit  - SETTA/CNT/AGGANCIA -> absolute 'POSIZIONA M4W 0 x y 0 0', M4_FIX_Y=y; hung -> Sospesa=1;
         id != src struct -> clone: STRUTTURA and every '\\n\\' path renumbered.
 panel - block copied from another .rit (PAN018 already LE08 -> DZDX00), new STRUTTURA,
         raw 'POSIZIONA x y z angle', X/Y in the RADICE line. No path refs in panel blocks.
 top   - TOPDRBA: length via AA_SBORDO_SX/DX, wall edges via GEST_BORSX/BORDX + BORSX/BORDX(1),
         sink via GEST_LAVINC + LAVINC(1); STENDI2 = FIRST and LAST unit of the row only.
 header - VAR_SET$ $MAX_ID__ = max id. Sample blocks between the first sample and 'PATH 0'
         are replaced by the generated blocks; everything else of the base file is kept as is.
"""
import json, os, re, sys

def rd(f):
    return open(f, 'rb').read().decode('cp1252').split('\r\n')

def block_at(lines, i):
    j = i + 1
    while not (lines[j].startswith('ELEMENTO') or lines[j] == 'PATH 0'):
        j += 1
    return j

def find_struct(lines, s):
    for i, l in enumerate(lines):
        if l.startswith('ELEMENTO') and i + 1 < len(lines) and lines[i + 1] in ('STRUTTURA %d' % s, 'STRUTTURA_S %d' % s):
            return i, block_at(lines, i)
    raise SystemExit('struct %d not found' % s)

def find_code(lines, code, nth=1):
    k = 0
    for i, l in enumerate(lines):
        if l == 'ELEMENTO ' + code or l == 'ELEMENTO_S ' + code:
            k += 1
            if k == nth:
                return i, block_at(lines, i)
    raise SystemExit('code %s #%d not found' % (code, nth))

def renum(lines, old, new):
    out = []
    for l in lines:
        if l.startswith('STRUTTURA '):
            l = 'STRUTTURA %d' % new
        l = re.sub(r'(?<= )\\%d(?=\\|\s|$)' % old, r'\\%d' % new, l)
        out.append(l)
    return out

def setpos(lines, pos, fixy=None):
    out = []; done = False
    for l in lines:
        if l.startswith('SETTA ') or l.startswith('POSIZIONA '):
            if not done:
                out.append(pos); done = True
            continue
        if l.startswith('CNT ') or l == 'AGGANCIA':
            continue
        if fixy is not None:
            l = re.sub(r'M4_FIX_Y=[\d.]+', 'M4_FIX_Y=%s' % num(fixy), l)
        out.append(l)
    assert done, pos
    return out

def sosp(lines):
    return [re.sub(r'(?<= )Sospesa=0', 'Sospesa=1', l) if l.startswith('var_change 0 \\0 ') else l for l in lines]

def num(v):
    return ('%d' % v) if float(v) == int(v) else ('%g' % v)

def top(lines, it):
    sink = it.get('sink'); n = 0
    vu_old = 'VarsUser__="GEST_FNPS;GEST_SPPS"'
    vu_new = 'VarsUser__="GEST_FNPS;GEST_SPPS;GEST_BORSX;GEST_BORDX' + (';GEST_LAVINC' if sink else '') + ';AA_SBORDO_SX;AA_SBORDO_DX"'
    out = []
    for l in lines:
        if l.startswith('VAR_FIX ') and vu_old in l:
            l = l.replace(vu_old, vu_new) + ' GEST_BORSX="%s" GEST_BORDX="%s"' % (it['borsx'], it['bordx'])
            if sink:
                l += ' GEST_LAVINC="%s"' % sink
            l += ' AA_SBORDO_SX=%s AA_SBORDO_DX=%s' % (num(it['sx']), num(it['dx'])); n += 1
        if 'M2G_BCKVESTIZIONE="FNPS=' in l:
            l = re.sub(r'BORSX=BOR00\d\(\d\)', 'BORSX=%s(1)' % it['borsx'], l)
            l = re.sub(r'BORDX=BOR00\d\(\d\)', 'BORDX=%s(1)' % it['bordx'], l)
            if sink:
                l = l.replace('|LATVIS=', '|LAVINC=%s(1)|LATVIS=' % sink, 1)
            n += 1
        if l.startswith('STENDI2 '):
            u = it['units']
            l = 'STENDI2 0 \\%d 0 \\%d' % (u[0], u[-1]); n += 1
        out.append(l)
    assert n == 3, 'top: expected 3 edits, got %d' % n
    return out

def panel(lines, it):
    out = []
    pos = 'POSIZIONA ' + ' '.join(num(v) for v in it['pos'])
    for l in lines:
        if l.startswith('STRUTTURA '):
            l = 'STRUTTURA %d' % it['id']
        if l.startswith('POSIZIONA '):
            l = pos
        if l.startswith('VAR_FIX ') and 'RADICE=' in l:
            if 'X' in it: l = re.sub(r'(?<= )X=\d+', 'X=%s' % num(it['X']), l)
            if 'Y' in it: l = re.sub(r'(?<= )Y=\d+', 'Y=%s' % num(it['Y']), l)
        out.append(l)
    assert sum(l.startswith('POSIZIONA') for l in out) == 1
    assert not any(re.search(r'(?<= )\\[1-9]\d*(\\|\s|$)', l) for l in out), 'panel block has path refs (\\0 = own root, allowed)'
    return out

def build(room_path, out_path):
    R = json.load(open(room_path, encoding='utf-8'))
    d = os.path.dirname(os.path.abspath(room_path))
    L = rd(os.path.join(d, R['base']))
    assert R['estimate'] in L[0] or any(R['estimate'] in l for l in L[:40]), 'base is not estimate ' + R['estimate']
    p0 = L.index('PATH 0')
    first = min(i for i, l in enumerate(L) if l.startswith('ELEMENTO'))
    cache = {}
    blocks = []
    for it in R['items']:
        src = it['src']
        S = L if 'file' not in src else cache.setdefault(src['file'], rd(os.path.join(d, src['file'])))
        i, j = find_struct(S, src['struct']) if 'struct' in src else find_code(S, src['code'], src.get('nth', 1))
        b = S[i:j]
        k = it['kind']
        if k == 'unit':
            if it['id'] != src['struct']:
                b = renum(b, src['struct'], it['id'])
                assert not any(re.search(r'(?<= )\\%d(\\|\s|$)' % src['struct'], l) for l in b)
            b = setpos(b, 'POSIZIONA M4W 0 %s %s 0 0' % (num(it['x']), num(it['y'])), it['y'])
            if it.get('hung'):
                b = sosp(b)
        elif k == 'panel':
            b = panel(b, it)
        elif k == 'top':
            assert it['id'] == src['struct'], 'top clone not supported'
            b = top(b, it)
        else:
            raise SystemExit('unknown kind ' + k)
        blocks += b
    mx = max(it['id'] for it in R['items'])
    L = L[:first] + blocks + L[p0:]
    L = [re.sub(r'\$MAX_ID__=\d+', '$MAX_ID__=%d' % mx, l) if l.startswith('VAR_SET$ $MAX_ID__') else l for l in L]
    assert sum(l.startswith('VAR_SET$ $MAX_ID__=%d' % mx) for l in L) == 1
    open(out_path, 'wb').write('\r\n'.join(L).encode('cp1252'))
    print('written', out_path, 'items', len(R['items']), 'MAX_ID', mx)

if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2])

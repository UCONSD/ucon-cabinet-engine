#!/usr/bin/env python3
"""metron_order.py v0 (2026-10-28) - canonical ORDER LIST + fingerprint from a printed Metron estimate PDF.
Source of truth on the Metron side = the printed estimate (what the factory receives).
usage: python3 metron_order.py <estimate.pdf> [out.json]
Fingerprint: SHA-1 of canonical text, first 6 hex upper -> '#XXXXXX'.
Canonical text (one line each, in this order):
  H|<HEADER KEY>|<VALUE>                      composition finishes (block after 'MODELLO:'), sorted
  I|<CODE>|<L>|<H>|<P>|<QTY>                   each priced row (sorted by CODE,L,H,P)
  I..|V|<KEY>|<VALUE>                          variant lines of that row, sorted
  I..|S|<SUBCODE>|<TEXT>                       sub rows (fronts, kits), sorted
Prices, page headers, row numbers, notes ('Note::') are ignored -> fingerprint changes only when the ORDER changes."""
import sys, re, subprocess, hashlib, json
pdf = sys.argv[1]
txt = subprocess.run(['pdftotext', '-layout', pdf, '-'], capture_output=True, text=True).stdout
txt = txt.split('\f')
lines = []
for page in txt:
    for l in page.splitlines():
        if re.search(r'^\s*Total\s', l) or 'HEADING NOTE' in l: break
        lines.append(l)
    else:
        continue
    break
norm = lambda s: re.sub(r'\s+', ' ', s).strip().upper()
money = re.compile(r'[+]?\s?[\d.,]+\.\d\d\b')
header, items, cur, inhead = [], [], None, False
for l in lines:
    s = l.strip()
    if not s: continue
    if s.startswith('MODELLO:'): inhead = True; header.append(('MODELLO', norm(s.split(':',1)[1]))); continue
    if s.startswith('Riga Code'): inhead = False; continue
    if inhead and ':' in s:
        k, v = s.split(':', 1); header.append((norm(k), norm(v))); continue
    m = re.match(r'^\s*(\d+)\s+(\S+)\s+(.*?)\s{2,}(\d+)\s+(\d+)\s+(\d+)\s+PZ\s+(\d+)\s', l)
    if m:
        cur = {'code': m.group(2), 'L': int(m.group(4)), 'H': int(m.group(5)), 'P': int(m.group(6)), 'qty': int(m.group(7)), 'V': [], 'S': []}
        items.append(cur); continue
    if cur is None or 'Page ' in s or s.startswith(('Cesar Arredamenti', '30020', 'Tel.')): continue
    if s.startswith('Note::'): continue
    s2 = norm(money.sub('', s))
    ms = re.match(r'^([A-Z0-9]{5,})\s+(.*)$', s2)
    if ms and re.search(r'\d', ms.group(1)) and ':' not in s2:
        cur['S'].append((ms.group(1), ms.group(2))); continue
    if ':' in s2:
        k, v = s2.split(':', 1); cur['V'].append((k.strip(), v.strip())); continue
    if cur['S']:
        a, b = cur['S'][-1]; cur['S'][-1] = (a, (b + ' ' + s2).strip())
    # else: continuation of description -> ignored
canon = ['H|%s|%s' % kv for kv in sorted(header)]
for it in sorted(items, key=lambda i: (i['code'], i['L'], i['H'], i['P'])):
    base = 'I|%s|%d|%d|%d|%d' % (it['code'], it['L'], it['H'], it['P'], it['qty'])
    canon.append(base)
    canon += ['%s|V|%s|%s' % (base, k, v) for k, v in sorted(it['V'])]
    canon += ['%s|S|%s|%s' % (base, k, v) for k, v in sorted(it['S'])]
fp = '#' + hashlib.sha1('\n'.join(canon).encode()).hexdigest()[:6].upper()
out = {'source': pdf, 'fingerprint': fp, 'canonical': canon}
if len(sys.argv) > 2: json.dump(out, open(sys.argv[2], 'w'), indent=1, ensure_ascii=False)
print('\n'.join(canon)); print('FINGERPRINT', fp)

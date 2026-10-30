#!/usr/bin/env python3
"""room_from_skp.py (2026-10-29, stage 2) - the SketchUp export of one room -> the room JSON rit_build.py reads.

The model knows WHAT STANDS WHERE (core/87_metron.rb writes it: kind, code, x/y, panels, tops by `ref`).
It does not know, and must not, the two Metron facts this step adds:
  src  - which block the item is copied from: units and tops from the estimate's own sample file (base),
         panels from the first file samples_index.json names for that code;
  id   - the STRUTTURA number. First use of a sample = the sample's own number; every other item = a new number
         above everything in the base. With --prev (the room JSON of the previous revision) an item that matches
         one there by kind + code + position keeps its id AND its place in the order, so R02 changes only what
         changed - and an unchanged room rebuilds the same .rit byte for byte.

usage: python3 room_from_skp.py export.json base.rit out_room.json [--prev prev_room.json] [--index rooms/samples_index.json]
       base and index paths are written into out_room.json relative to its folder, as rit_build.py expects.
"""
import argparse, json, os, re, sys

TOL = 1.0

def samples_in_base(path):
    lines = open(path, 'rb').read().decode('cp1252').split('\r\n')
    out = {}
    for i, l in enumerate(lines[:-1]):
        m = re.match(r'ELEMENTO(?:_S)? (\S+)$', l)
        n = re.match(r'STRUTTURA(?:_S)? (\d+)$', lines[i + 1])
        if m and n:
            out.setdefault(m.group(1), []).append(int(n.group(1)))
    return out

def where(it):
    if it['kind'] == 'panel':
        return tuple(it['pos'][:2])
    if it['kind'] == 'top':
        return (it.get('sx'), it.get('dx'))
    return (it['x'], it['y'])

def same(a, b):
    if a['kind'] != b['kind'] or a['code'] != b['code']:
        return False
    return all(x is not None and y is not None and abs(float(x) - float(y)) <= TOL for x, y in zip(where(a), where(b)))

def rel(path, base_dir):
    return os.path.relpath(os.path.abspath(path), base_dir).replace(os.sep, '/')

def resolve(exp, base_path, out_path, prev=None, index=None):
    out_dir = os.path.dirname(os.path.abspath(out_path))
    samples = samples_in_base(base_path)
    idx = json.load(open(index, encoding='utf-8'))['codes'] if index else {}
    idx_dir = os.path.dirname(os.path.abspath(index)) if index else out_dir
    items = [dict(i) for i in exp['items']]
    errors = []
    # src
    for it in items:
        if it['kind'] in ('unit', 'top'):
            s = samples.get(it['code'])
            if not s:
                errors.append('%s %s: no sample in %s - place one in Metron and SUSPEND' % (it['kind'], it['code'], os.path.basename(base_path)))
                continue
            it['src'] = {'struct': s[0]}
        elif it['kind'] == 'panel':
            e = (idx.get(it['code']) or [None])[0]
            if not e:
                errors.append('panel %s: not in samples_index.json' % it['code'])
                continue
            it['src'] = {'file': rel(os.path.join(idx_dir, e['file']), out_dir), 'code': it['code']}
    if errors:
        raise SystemExit('REFUSED:\n  ' + '\n  '.join(errors))
    # ids and order
    taken = {}
    ordered = []
    if prev:
        left = list(items)
        for p in prev['items']:
            m = next((it for it in left if same(it, p)), None)
            if m:
                m['id'] = p['id']; taken[p['id']] = m; left.remove(m); ordered.append(m)
        items_new = left
    else:
        items_new = items
    top_id = max([n for v in samples.values() for n in v] + list(taken) + [0])
    used_struct = {it['src']['struct'] for it in taken.values() if 'struct' in it['src'] and it['id'] == it['src']['struct']}
    for it in items_new:
        st = it['src'].get('struct')
        if st is not None and st not in used_struct and st not in taken:
            it['id'] = st; used_struct.add(st)
        else:
            top_id += 1; it['id'] = top_id
        ordered.append(it)
    ref_id = {it['ref']: it['id'] for it in ordered}
    for it in ordered:
        if it['kind'] == 'top':
            assert it['id'] == it['src']['struct'], 'top %s: a second top of one code needs a second sample' % it['code']
            it['units'] = [ref_id[r] for r in it['units']]
    keys = ['id', 'kind', 'code', 'src', 'x', 'y', 'hung', 'pos', 'X', 'Y', 'units', 'sx', 'dx', 'borsx', 'bordx', 'sink']
    room = {'room': exp['room'], 'source': exp.get('source', 'SketchUp export'), 'estimate': exp['estimate'],
            'base': rel(base_path, out_dir),
            'items': [{k: it[k] for k in keys if k in it} for it in ordered]}
    if exp.get('revision'):
        room['revision'] = exp['revision']
    return room

if __name__ == '__main__':
    a = argparse.ArgumentParser()
    a.add_argument('export'); a.add_argument('base'); a.add_argument('out')
    a.add_argument('--prev'); a.add_argument('--index')
    o = a.parse_args()
    exp = json.load(open(o.export, encoding='utf-8'))
    prev = json.load(open(o.prev, encoding='utf-8')) if o.prev else None
    room = resolve(exp, o.base, o.out, prev, o.index)
    with open(o.out, 'w', encoding='utf-8') as f:
        f.write('{\n' + ',\n'.join('  %s: %s' % (json.dumps(k), json.dumps(v)) for k, v in room.items() if k != 'items'))
        f.write(',\n  "items": [\n' + ',\n'.join('    ' + json.dumps(i) for i in room['items']) + '\n  ]\n}\n')
    print('written', o.out, 'items', len(room['items']))

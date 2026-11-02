#!/usr/bin/env python3
"""Stage 2 acceptance without Metron: SketchUp export fixture -> room JSON -> .rit, against what is in the database.

  python3 metron/laptop/gen/test_room_from_skp.py      (from the repository root or anywhere)

For Bath 3 and Bath 2:
  1. room_from_skp(export, base, --prev hand JSON) == hand JSON with the panels 495 deep (all fields but `source`)
  2. that room JSON through rit_build.py == the hand JSON (panels 495) through rit_build.py, byte for byte; and THAT
     differs from expected/<estimate>.rit (T_00019_v2 / T_00018_v1, the R01 in the database) in exactly one line per
     panel - its X - because Andriy 2026-10-29: side panels flush with the fronts, 495, not the 470 of Metron R01.
  3. without --prev: the same items with the same src; the order and the new ids follow the default rule. For Bath 3
     the default rule IS the hand order (byte-equal too); for Bath 2 the two panels were placed right-then-left by
     hand, so only the set is compared - Metron reads blocks in any order.
"""
import hashlib, json, os, subprocess, sys, tempfile
G = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, G)
import room_from_skp as R
FIX = os.path.join(G, '..', '..', 'export', 'fixtures')
CASES = [('7612_BA3', 'T_00019', 'T_00019_s_samples.rit', 'T_00019_v2.rit', True),
         ('7612_BA2', 'T_00018', 'T_00018_s_samples.rit', 'T_00018_v1.rit', False)]
fails = []; checks = 0

def strip(room):
    return {k: v for k, v in room.items() if k not in ('source', 'revision')}

def norm_items(room):
    return sorted(json.dumps({k: v for k, v in i.items() if k not in ('id', 'units')}, sort_keys=True) for i in room['items'])

def build(room, tmp, name):
    # paths in a room JSON are relative to rooms/; written to tmp they are made absolute (nothing is written into the
    # repository - the device bridge cannot delete, and a test must leave no trace)
    rooms = os.path.join(G, 'rooms')
    room = json.loads(json.dumps(room))
    room['base'] = os.path.normpath(os.path.join(rooms, room['base']))
    for i in room['items']:
        if 'file' in i['src']:
            i['src']['file'] = os.path.normpath(os.path.join(rooms, i['src']['file']))
    p = os.path.join(tmp, name + '.json')
    json.dump(room, open(p, 'w'))
    out = os.path.join(tmp, name + '.rit')
    subprocess.check_call([sys.executable, '-I', os.path.join(G, 'rit_build.py'), p, out], stdout=subprocess.DEVNULL)
    return hashlib.md5(open(out, 'rb').read()).hexdigest()

with tempfile.TemporaryDirectory() as tmp:
    for name, est, base, expected, default_is_hand in CASES:
        exp = json.load(open(os.path.join(FIX, name + '.export.json')))
        hand = json.load(open(os.path.join(G, 'rooms', 'room_%s.json' % name)))
        r01 = open(os.path.join(G, 'expected', expected), 'rb').read().split(b'\r\n')
        npanels = 0
        for i in hand['items']:
            if i['kind'] == 'panel':
                i['X'] = 495; npanels += 1
        want = build(hand, tmp, name + '_hand495')
        got_lines = open(os.path.join(tmp, name + '_hand495.rit'), 'rb').read().split(b'\r\n')
        diff = [(a, b) for a, b in zip(r01, got_lines) if a != b]
        checks += 1
        if len(r01) != len(got_lines) or len(diff) != npanels or not all(b' X=470' in a and b' X=495' in b and a.replace(b' X=470', b' X=495') == b for a, b in diff):
            fails.append('%s: R01 -> 495 is not exactly %d X lines (%d lines differ)' % (name, npanels, len(diff)))
        out_json = os.path.join(G, 'rooms', 'x.json')
        r1 = R.resolve(exp, os.path.join(G, base), out_json, prev=hand, index=os.path.join(G, 'rooms', 'samples_index.json'))
        checks += 1
        if strip(r1) != strip(hand):
            fails.append('%s --prev: room JSON differs\n got  %s\n want %s' % (name, json.dumps(strip(r1)), json.dumps(strip(hand))))
        checks += 1
        got = build(r1, tmp, name + '_prev')
        if got != want:
            fails.append('%s --prev: .rit MD5 %s, want %s' % (name, got, want))
        r2 = R.resolve(exp, os.path.join(G, base), out_json, prev=None, index=os.path.join(G, 'rooms', 'samples_index.json'))
        checks += 1
        if norm_items(r2) != norm_items(hand):
            fails.append('%s default: item set differs' % name)
        if default_is_hand:
            checks += 1
            got = build(r2, tmp, name + '_default')
            if got != want:
                fails.append('%s default: .rit MD5 %s, want %s' % (name, got, want))
        print('%s: prev %s, default %s' % (name, 'ok' if not fails else '?', [i['id'] for i in r2['items']]))
for f in fails:
    print('  FAIL ', f)
print('%d checks, %d failures' % (checks, len(fails)))
sys.exit(1 if fails else 0)

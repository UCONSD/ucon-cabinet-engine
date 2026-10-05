#!/bin/sh
set -e

# THE SCRIPT DOES NOT KNOW WHERE THE REPOSITORY IS, AND MUST NOT.
# It was written on 2026-08-28 with an absolute path in it - ~/mnt/... - which
# is the path the CLOUD SESSION sees the repository at, over the device bridge.
# Andriy's own terminal sees the same repository at ~/dev/..., so the script
# died on its third line. Two machines, two names for one directory, and the
# only honest answer is to ask neither: cd to where THIS FILE is, which is
# <repo>/build wherever the repository happens to be sitting.
cd "$(dirname "$0")/.."

echo "===== 1. the suites, under the Ruby macOS ships ====="
/usr/bin/ruby -v
# The count line, found by what it SAYS rather than by where it sits: two of
# the three suites end with a blank line and one does not, so a tail -1 printed
# an empty line for the seam on 2026-08-28 and looked like a suite that had not
# run at all.
printf 'test_contract        '; /usr/bin/ruby tools/test_contract.rb      | grep 'checks,' | tail -1
printf 'test_appliances      '; /usr/bin/ruby tools/test_appliances.rb    | grep 'checks,' | tail -1
printf 'test_appliance_seam  '; /usr/bin/ruby tools/test_appliance_seam.rb | grep 'checks,' | tail -1

# AND THE SUMMARY LINES ABOVE ARE NOT THE CHECK. A tail cannot fail a build:
# the pipe swallows the exit status, so the suites are RUN AGAIN for their
# status, silently, and set -e stops here if any of them is red.
/usr/bin/ruby tools/test_contract.rb      > /dev/null
/usr/bin/ruby tools/test_appliances.rb    > /dev/null
/usr/bin/ruby tools/test_appliance_seam.rb > /dev/null

echo
echo "===== 2. stage, BY NAME ====="
# CLAUDE.md JOINED THE LIST 2026-09-24. It is the onboarding file every session
# reads first, and this script had never staged it: its last commit (a171615,
# 2026-08-30) was made by hand. The appliance-link note written that day would
# have sat uncommitted with nothing saying so.
# AND THIS SCRIPT STAGES ITSELF, 2026-08-28. It was not in the repository at
# all - .gitignore said `build/` while its own stated reason was only ever about
# .rbz archives, a rule wider than the reason above it. It surfaced the first
# time the laptop was opened: the one command Andriy types on every machine did
# not travel with the repository. .gitignore is here for the same reason - it
# was never in the staging list either, so a change to it could not be committed
# by the script that reads it.
# 2026-10-02 (core 1.9.21): FILES, NOT DIRECTORIES - every file this change
# touched, the README index line, the new spec and the two notes that ride
# along, by name, nothing else. `git add -A <dir>` swept an untracked spec
# into 18ee014 in silence (see below); a list cannot.
# 2026-10-03: the four open-units specs, by name. They missed 13b3871 because the
# list above was still the 1.9.21 list - the session predicted 7 files and the
# commit carried 3. The README already names them; this commit makes that true.
# 2026-10-03, S4 review fixes: the H.60 reason and the end-unit grammar text
# corrected, the 39-row table check, the grammar exemption narrowed, the
# back-to-back limits written down. 6 files predicted; the list printed 6.
# 2026-10-03, 7612-S8 (core 1.9.23): open units drawn as boards, not a solid
# block. 7 files predicted; the list printed 7.
# 2026-10-03, core 1.9.24: gola fixes found on 7612 Elevation B. 5 files
# predicted; the list printed 5.
# 2026-10-03, core 1.9.25: P-One waste bins drawn dashed. 4 files predicted;
# the list printed 4.
# 2026-10-03, docs only: Q44 revised. 2 files predicted; the list printed 2.
# 2026-10-03, core 1.9.26: finish panels in the front colour. 4 printed 4.
# 2026-10-03, evening housekeeping: the 7612 card brought up to date.
# 2 files predicted; the list must print 2. (Never run - folded into the next.)
# 2026-10-03, night: 7612 estimate request, stages 1-3 (docs only) plus the
# card entries of the evening. 6 files predicted; the list must print 6.
# 2026-10-05: the 7612 drawing set writer v1.6 and the estimate request, plus the
# two lines the suite asked for (Q52 in the status table, the handoff in
# claude/README.md). 6 files predicted; the list must print 6.
# The 2026-10-05 drawing-set commit printed 6 and is pushed (16d7497).
# 2026-10-05, core 1.9.27: catalog recon group 1, 230 codes (1332 -> 1562).
# 19 files predicted; the list must print 19.
git add registry/cesar/_manifest.json \
        registry/cesar/tall_h198_base78.json \
        registry/cesar/tall_h210_base78.json \
        registry/cesar/tall_h222_base78.json \
        registry/cesar/tall_h234_base78.json \
        registry/cesar/base_h48.json \
        registry/cesar/tall_top_h48.json \
        registry/cesar/glass_wall_h60.json \
        registry/cesar/glass_wall_h120.json \
        registry/cesar/hide_seek_h198.json \
        registry/cesar/hide_seek_h210.json \
        registry/cesar/hide_seek_h234.json \
        registry/cesar/wall_h36.json \
        src/ucon_cabinet_engine/core/00_version.rb \
        src/ucon_cabinet_engine/core/90_palette.rb \
        tools/test_contract.rb \
        claude/catalog-group1-2026-10-04.md \
        claude/README.md \
        build/go.sh

echo
# tools/probe_bridge.rb JOINED THE LIST, 2026-08-30, and it had been TRACKED and
# unstageable since the list was written: a dated correction to its header - what
# its applied-detector can and cannot prove - would have sat in the working tree
# forever, because the one command Andriy runs never staged it. Same shape as
# go.sh itself, which was not in the repository at all until 2026-08-28.
#
# tools/ is still staged BY NAME and not as a directory, on purpose: eight more
# tracked probes live there (build_panel_kit, corner_probe, kitchen_probe,
# side_probe, ucon_probe, void_probe, wall_probe, build_rbz) and an edit to any
# of them is invisible to this script too. That is a KNOWN gap, stated rather
# than half-fixed - `git add -A tools` would close it and open the stowaway hole
# the paragraph below exists to watch for.
# AND READ WHAT IS ABOUT TO GO. `git add -A <dir>` is scoped to directories, not
# to file names, so anything untracked inside them is swept up in silence. On
# 2026-08-30 commit 18ee014 carried docs/spec-template.md, placed by a different
# session, and its message says nothing about it. The file belonged here; the
# silence did not.
echo "  staged, BY NAME - a stowaway lands in this list:"
git diff --cached --name-only | sed 's/^/    /'

echo
echo "===== 3. commit ====="
git commit -F build/commit-msg.txt

echo
echo "===== 4. push, and then READ THE REFS BACK ====="
git push
LOCAL=$(cat .git/refs/heads/main)
REMOTE=$(cat .git/refs/remotes/origin/main)
echo "  local  main : $LOCAL"
echo "  origin main : $REMOTE"
if [ "$LOCAL" != "$REMOTE" ]; then
  echo "  THE PUSH DID NOT LAND. The refs still differ."
  exit 1
fi
echo "  refs agree - it is pushed."
echo
git log --oneline -1

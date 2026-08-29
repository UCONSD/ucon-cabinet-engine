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
ruby -v
# The count line, found by what it SAYS rather than by where it sits: two of
# the three suites end with a blank line and one does not, so a tail -1 printed
# an empty line for the seam on 2026-08-28 and looked like a suite that had not
# run at all.
printf 'test_contract        '; ruby tools/test_contract.rb      | grep 'checks,' | tail -1
printf 'test_appliances      '; ruby tools/test_appliances.rb    | grep 'checks,' | tail -1
printf 'test_appliance_seam  '; ruby tools/test_appliance_seam.rb | grep 'checks,' | tail -1

# AND THE SUMMARY LINES ABOVE ARE NOT THE CHECK. A tail cannot fail a build:
# the pipe swallows the exit status, so the suites are RUN AGAIN for their
# status, silently, and set -e stops here if any of them is red.
ruby tools/test_contract.rb      > /dev/null
ruby tools/test_appliances.rb    > /dev/null
ruby tools/test_appliance_seam.rb > /dev/null

echo
echo "===== 2. stage, BY NAME ====="
# AND THIS SCRIPT STAGES ITSELF, 2026-08-28. It was not in the repository at
# all - .gitignore said `build/` while its own stated reason was only ever about
# .rbz archives, a rule wider than the reason above it. It surfaced the first
# time the laptop was opened: the one command Andriy types on every machine did
# not travel with the repository. .gitignore is here for the same reason - it
# was never in the staging list either, so a change to it could not be committed
# by the script that reads it.
git add -A registry/cesar src/ucon_cabinet_engine src/ucon_cabinet_engine.rb \
        src/ucon_appliances src/ucon_appliances.rb claude docs \
        tools/test_contract.rb tools/test_appliances.rb tools/test_appliance_seam.rb \
        tools/probe_inbox_hold_71.rb tools/probe_inbox_hold_82.rb \
        tools/probe_top_measure.rb \
        .gitignore build/go.sh

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

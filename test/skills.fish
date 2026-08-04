#!/usr/bin/env fish
#
# Tests for skill linking. Run: fish test/skills.fish
#
# Each test gets a throwaway $HOME so the real ~/.agents and ~/.claude are never touched.

set -g dotfile_dir (realpath (dirname (status filename))/..)
set -g passed 0
set -g failed 0
set -g real_home $HOME

source $dotfile_dir/lib/common.fish
source $dotfile_dir/lib/skills.fish

function fail -a message
  set -g failed (math $failed + 1)
  echo -s (set_color red) "  not ok" (set_color normal) " $message"
end

function pass -a message
  set -g passed (math $passed + 1)
  echo -s (set_color green) "  ok" (set_color normal) " $message"
end

function assert_link -a link target message
  if not test -L $link
    fail "$message (not a symlink: $link)"
  else if test (realpath $link) != (realpath $target)
    fail "$message (points at "(realpath $link)", want "(realpath $target)")"
  else
    pass $message
  end
end

function assert_dir -a path message
  if test -d $path; and not test -L $path
    pass $message
  else
    fail "$message (not a real directory: $path)"
  end
end

function assert_absent -a path message
  if test -e $path; or test -L $path
    fail "$message (still exists: $path)"
  else
    pass $message
  end
end

function assert_exists -a path message
  if test -e $path
    pass $message
  else
    fail "$message (missing: $path)"
  end
end

# Builds a throwaway $HOME containing a fake skills repo with two skills, and a
# ~/.claude/skills directory. ~/.pi and ~/.omp are deliberately absent so we can
# assert unconfigured agents are skipped rather than created.
function setup
  set -g tmp (mktemp -d)
  set -gx HOME $tmp
  set -g skills_path $tmp/skills-repo

  for skill in alpha beta
    mkdir -p $skills_path/skills/$skill
    printf -- '---\nname: %s\ndescription: Test skill %s.\n---\n' $skill $skill \
      > $skills_path/skills/$skill/SKILL.md
  end

  mkdir -p $tmp/.claude/skills
end

function teardown
  set -gx HOME $real_home
  rm -rf $tmp
end

function describe -a name
  echo
  echo -s (set_color --bold) $name (set_color normal)
end

# --------------------------------------------------------------------------

describe "links authored skills into the shared store"
setup
skills_link $skills_path > /dev/null
assert_link $tmp/.agents/skills/alpha $skills_path/skills/alpha "alpha is linked into the store"
assert_link $tmp/.agents/skills/beta $skills_path/skills/beta "beta is linked into the store"
teardown

describe "fans the store out to agents that do not read it"
setup
skills_link $skills_path > /dev/null
skills_fanout > /dev/null
assert_link $tmp/.claude/skills/alpha $tmp/.agents/skills/alpha "alpha reaches Claude Code"
assert_absent $tmp/.pi/agent/skills "unconfigured agents are not created"
teardown

describe "prunes links for skills removed from the repo"
setup
skills_link $skills_path > /dev/null
skills_fanout > /dev/null
assert_link $tmp/.claude/skills/beta $tmp/.agents/skills/beta "beta is linked before we remove it"
rm -rf $skills_path/skills/beta
skills_prune > /dev/null
assert_absent $tmp/.agents/skills/beta "beta leaves the store"
assert_absent $tmp/.claude/skills/beta "beta leaves Claude Code"
assert_link $tmp/.agents/skills/alpha $skills_path/skills/alpha "alpha survives the prune"
teardown

describe "backs up a real directory standing in the way"
setup
mkdir -p $tmp/.claude/skills/alpha
echo "hand-written" > $tmp/.claude/skills/alpha/SKILL.md
skills_link $skills_path > /dev/null
skills_fanout > /dev/null
assert_link $tmp/.claude/skills/alpha $tmp/.agents/skills/alpha "alpha is replaced by the link"
set -l backup (find $tmp/.claude/skills -maxdepth 1 -name 'alpha.*.dots_backup' | head -1)
assert_exists "$backup/SKILL.md" "the displaced directory is backed up"
teardown

describe "replaces a dangling link without leaving a backup"
setup
# What an old hand-made link points at once its source moves away.
ln -s $tmp/gone/alpha $tmp/.claude/skills/alpha
skills_link $skills_path > /dev/null
skills_fanout > /dev/null
assert_link $tmp/.claude/skills/alpha $tmp/.agents/skills/alpha "the dead link is repointed"
set -l backup (find $tmp/.claude/skills -maxdepth 1 -name 'alpha.*.dots_backup' | head -1)
if test -z "$backup"
  pass "no backup is left behind"
else
  fail "no backup is left behind (created $backup)"
end
teardown

describe "leaves skills installed by npx alone"
setup
# What `npx skills add -g` leaves behind: a real copy in the store, symlinked out.
mkdir -p $tmp/.agents/skills/thirdparty
printf -- '---\nname: thirdparty\n---\n' > $tmp/.agents/skills/thirdparty/SKILL.md
ln -s ../../.agents/skills/thirdparty $tmp/.claude/skills/thirdparty
skills_link $skills_path > /dev/null
skills_fanout > /dev/null
skills_prune > /dev/null
assert_link $tmp/.agents/skills/alpha $skills_path/skills/alpha "the run did happen (alpha linked)"
assert_dir $tmp/.agents/skills/thirdparty "the npx copy stays a real directory"
assert_link $tmp/.claude/skills/thirdparty $tmp/.agents/skills/thirdparty "its fan-out link survives"
teardown

# --------------------------------------------------------------------------

echo
if test $failed -gt 0
  echo -s (set_color red) "$failed failed" (set_color normal) ", $passed passed"
  exit 1
end
echo -s (set_color green) "$passed passed" (set_color normal)

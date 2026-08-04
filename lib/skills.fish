# Agent Skills across harnesses.
#
# ~/.agents/skills is the shared store. Third-party skills land there via
# `npx skills add -g`; skills authored in $SKILLS_PATH are symlinked in beside
# them, so edits go straight to git with no reinstall step.
#
# Codex, Cursor, Gemini CLI and OpenCode read the store directly. Everything
# else needs its own link, which is what skills_fanout is for.

set -g skills_repo_url git@github.com:nickbutler/skills.git

function skills_store
  echo $HOME/.agents/skills
end

# Agents that cannot read the store themselves: name, then their skills directory.
# An agent is only wired up if its parent directory already exists.
function skills_fanout_agents
  echo claude $HOME/.claude/skills
  echo pi $HOME/.pi/agent/skills
  echo omp $HOME/.omp/agent/skills
end

# Symlink every skill in the repo into the store.
function skills_link -a skills_path
  set -l store (skills_store)
  set -l source_dir $skills_path/skills

  echo "Authored skills:"
  if not test -d $source_dir
    echo -n "  $skills_path: "
    skipped "no skills/ directory"
    echo
    return
  end

  mkdir -p $store
  for skill_path in $source_dir/*/
    set -l skill (basename $skill_path)
    echo -n "  $skill: "
    symlink_one $skill_path $store/$skill
  end
  echo
end

# Link every store entry into the agents that need their own copy.
function skills_fanout
  set -l store (skills_store)
  set -l agents (skills_fanout_agents | string split ' ')

  echo "Agent skills:"
  for i in (seq 1 2 (count $agents))
    set -l name $agents[$i]
    set -l dest_dir $agents[(math $i + 1)]

    echo -n "  $name: "
    if not test -d (dirname $dest_dir)
      skipped "not configured"
      continue
    end

    mkdir -p $dest_dir
    set -l linked 0
    set -l backups
    for entry in $store/*
      set -l backup (link_force $entry $dest_dir/(basename $entry))
      test -n "$backup"; and set -a backups $backup
      set linked (math $linked + 1)
    end
    echo -s (set_color green) "$linked linked." (set_color normal)
    for backup in $backups
      echo -s (set_color yellow) "    Backed up: $backup" (set_color normal)
    end
  end
  echo
end

# Drop links whose target has gone. A skill deleted from the repo leaves a
# dangling link in the store and in every agent; real directories (the copies
# `npx skills add` makes) and live links are left alone.
function skills_prune
  set -l dirs (skills_store)
  set -l agents (skills_fanout_agents | string split ' ')
  for i in (seq 2 2 (count $agents))
    set -a dirs $agents[$i]
  end

  set -l pruned
  for dir in $dirs
    test -d $dir; or continue
    for entry in $dir/*
      if test -L $entry; and not test -e $entry
        rm $entry
        set -a pruned (basename $entry)
      end
    end
  end

  if test (count $pruned) -gt 0
    echo "Pruned: "(string join ", " $pruned)
    echo
  end
end

# Clone the skills repo if it is missing, otherwise offer to pull.
function skills_update_repo -a skills_path
  if not test -d $skills_path/.git
    echo "Skills repo not found at $skills_path."
    read -n1 -P "Clone $skills_repo_url? [y/N] " choice < /dev/tty
    echo
    if not string match -qi y $choice
      echo "Skipped."
      echo
      return 1
    end
    git clone $skills_repo_url $skills_path; or return 1
    echo
    return
  end

  echo "Checking skills for updates..."
  git -C $skills_path fetch --quiet origin main
  set -l count (git -C $skills_path rev-list HEAD..origin/main --count)

  if test $count -eq 0
    echo "Already up to date."
    echo
    return
  end

  echo -s (set_color cyan) "$count new commit"(test $count -ne 1; and echo s)(set_color normal) " on main:"
  echo
  git -C $skills_path log HEAD..origin/main --oneline --no-decorate | while read -l line
    echo "  $line"
  end
  echo
  read -n1 -P "Pull skills updates? [y/N] " choice < /dev/tty
  echo
  if string match -qi y $choice
    git -C $skills_path pull origin main
  else
    echo "Skipped."
  end
  echo
end

function symlink_skills -a skills_path
  skills_update_repo $skills_path
  skills_link $skills_path
  skills_fanout
  skills_prune
end

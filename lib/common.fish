# Shared helpers. Sourced by bin/dots and the tests.

function ok
  echo -s (set_color green) "Ok!" (set_color normal)
end

function skipped -a reason
  echo -s (set_color yellow) "Skipped ($reason)." (set_color normal)
end

# Point $dest at $source, moving anything already there out of the way.
# Prints the backup path if it displaced something, nothing otherwise, so
# callers can report one link at a time or summarise a whole batch.
function link_force -a source_arg dest
  set -l source (realpath $source_arg)

  if test -L $dest
    set -l current (realpath $dest 2>/dev/null)
    test "$current" = "$source"; and return
    # A link whose target has gone holds nothing worth backing up.
    test -z "$current"; and rm $dest
  end

  if test -e $dest; or test -L $dest
    set -l backup_path $dest.(date +%s).dots_backup
    mv $dest $backup_path
    echo $backup_path
  end

  ln -sfn $source $dest
end

function symlink_one
  set -l backup (link_force $argv[1] $argv[2])
  test -n "$backup"; and echo -n -s (set_color yellow) "Backing up: $backup. "
  ok
end

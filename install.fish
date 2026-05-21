set dotfile_dir ~/.config/dotfiles
set script (status -f)

function ok
  echo -s (set_color green) Ok! (set_color normal)
end

function check_dotfiles
  echo Checking dotfiles repo...
  if [ -d $dotfile_dir ]
    cd $dotfile_dir
    and git pull origin master
  else
    git clone https://github.com/nickbutler/dotfiles.git $dotfile_dir
  end
end

function check_programs
  set -l warning 0

  cd $dotfile_dir/config

  for program in *
    echo -n "Checking for $program: "

    if type $program > /dev/null 2>&1
      ok
    else
      echo No $program! No $program!
      set warning 1
    end
  end

  return $warning
end

# Link a single source path to a destination.
# - Skips if destination is already correctly linked.
# - Backs up any existing file, directory, or wrong symlink before replacing.
function symlink_one
  set -l source (realpath $argv[1])
  set -l dest $argv[2]

  if test -L $dest; and test (realpath $dest 2>/dev/null) = $source
    ok
    return
  end

  if test -e $dest; or test -L $dest
    echo -n -s (set_color yellow) "Backing up. "
    mv $dest $dest.(date +%s).bak
  end

  ln -sf $source $dest
  ok
end

function symlink_configs
  set -l config_path $dotfile_dir/config

  for program_path in $config_path/*
    set -l program (basename $program_path)
    echo -n "Linking $program: "
    symlink_one $program_path ~/.config/$program
  end
  echo
end

function symlink_bin
  set -l bin_path $dotfile_dir/bin

  mkdir -p ~/.local/bin
  echo "Bin scripts:"
  for script_path in $bin_path/*
    set -l script (basename $script_path)
    echo -n "  Linking $script: "
    symlink_one $script_path ~/.local/bin/$script
  end
  echo
end

function symlink_others
  set -l optional_path $dotfile_dir/optional

  echo "Optional configs:"
  for program_path in $optional_path/*/
    set -l program (basename $program_path)
    read -n1 -P "  Link $program? [y/N] " choice
    echo
    if string match -q y $choice
      echo -n "  Linking $program: "
      symlink_one $program_path ~/.config/$program
    end
  end
  echo
end

function install_base16
  set BASE16_SHELL "$HOME/.config/base16-shell/"
  if not [ -d $BASE16_SHELL ]
    git clone https://github.com/chriskempson/base16-shell.git $BASE16_SHELL
  end
end

function continue_anyway
  echo Some programs not found.
  test (read -n1 -P 'Continue anyway? [yn] ') = 'y'
end

check_dotfiles
and check_programs
or continue_anyway
and symlink_configs
and symlink_bin
and symlink_others
and install_base16

and echo -s (set_color green) "Cool, we're done. You can run `fish` or set it as your default with `chsh -s ...`. Enjoy!"
or echo -s (set_color red) "Something went wrong. Terribly terribly wrong."

echo (set_color normal)

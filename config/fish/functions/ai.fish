function ai
  argparse f/fresh -- $argv

  # Capture piped stdin if present
  set stdin_content ""
  if not isatty stdin
    read -z stdin_content
  end

  if test -z "$stdin_content" -a (count $argv) -eq 0
    echo "Usage: ai [--fresh] <question>"
    echo "       <command> | ai [--fresh] <question>"
    echo "Example: ai what is the meaning of life"
    echo "         cat error.log | ai explain this error"
    return 1
  end

  set cache_dir ~/.cache/fish-ai
  mkdir -p $cache_dir

  # Build query from stdin + args
  set -l parts
  if test -n "$stdin_content"
    set -a parts $stdin_content
  end
  set -l arg_str (string join " " $argv)
  if test -n "$arg_str"
    set -a parts $arg_str
  end
  set query (string join "\n\n" $parts)

  set hash (echo $query | md5)
  set cache_file $cache_dir/$hash

  if not set -q _flag_fresh; and test -f $cache_file
    echo Oh, I remember this one...
    cat $cache_file | glow
    return 0
  end

  echo Beep boop, just a sec...
  set sysprompt "Be extremely concise. Format output as markdown. Answer in as few words as possible. No preamble, no filler, no explanation unless asked."
  claude --model claude-haiku-4-5 \
         --effort low \
         --system-prompt $sysprompt \
         --print "$query" \
  | tee $cache_file \
  | if type -q glow; glow; else; cat; end
end

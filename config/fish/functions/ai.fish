function ai
  if test (count $argv) -eq 0
    echo "Usage: ai <question>"
    echo "Example: ai what is the meaning of life, the universe and everything?"
    return 1
  end

  set cache_dir ~/.cache/fish-ai
  mkdir -p $cache_dir

  set query (string join " " $argv)
  set hash (echo $query | md5)
  set cache_file $cache_dir/$hash

  if test -f $cache_file
    if type -q glow; glow $cache_file; else; cat $cache_file; end
    return 0
  end

  echo Beep boop, just a sec...
  set sysprompt "Be extremely concise. Format output as markdown. Answer in as few words as possible. No preamble, no filler, no explanation unless asked."
  claude --model claude-haiku-4-5 \
         --effort low \
         --system-prompt $sysprompt \
         --print $query \
  | tee $cache_file \
  | if type -q glow; glow; else; cat; end
end

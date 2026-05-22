function ai
  if test (count $argv) -eq 0
    echo "Usage: ai <question>"
    echo "Example: ai what is the meaning of life, the universe and everything?"
    return 1
  end
  echo Beep boop, just a sec...
  set sysprompt "Be extremely concise. Answer in as few words as possible. No preamble, no filler, no explanation
  unless asked."
  claude --model claude-haiku-4-5 \
         --effort low \
         --system-prompt $sysprompt \
         --print "$argv" \
  | if type -q glow; glow; else; cat; end
end

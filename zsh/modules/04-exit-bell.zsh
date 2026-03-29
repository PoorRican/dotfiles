# Trigger terminal bell on non-zero exit code (skip SIGINT)
__exit_bell_precmd() {
  local exit_code=$?
  if [[ $exit_code -ne 0 && $exit_code -ne 130 ]]; then
    print -n '\a'
  fi
}

precmd_functions+=(__exit_bell_precmd)

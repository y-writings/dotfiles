select-history() {
  BUFFER=$(history -n 1 | fzf --exact --tac --no-sort --query="$LBUFFER" --prompt="History > ")
  CURSOR=${#BUFFER}
}
zle -N select-history

pb-kill-line() {
  zle kill-line
  print -rn -- "$CUTBUFFER" | pbcopy
}
zle -N pb-kill-line

bindkey '^r' select-history
bindkey '^K' pb-kill-line

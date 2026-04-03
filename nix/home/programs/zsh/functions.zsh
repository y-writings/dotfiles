fcd() {
    if [ -n "$1" ]; then
        cd $(dirname $1)
    fi
}

yyyymmdd() {
	date +"%Y%m%d" | pbcopy
	echo "Copied: $(pbpaste)"
}

function gr() {
    local src=$(ghq list | fzf --preview 'ls -laTp $(ghq root)/{}')
    if [ -n "${src}" ]; then
        selected="$(ghq root)/${src}"
        echo $selected
        cd $selected
    fi
}

function gitb() {
    local src=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | sed 's/^[* ] //' | fzf --preview 'git show --stat refs/heads/{} | head -n 10')
    if [ -n "${src}" ]; then
        echo $src
        echo -n $src | pbcopy  # -n で改行を除去
        echo "✅ Copied to clipboard!"
    fi
}

function gw() {
    local src=$(git worktree list | fzf)
    selected=$(echo $src | awk '{ print $1 }')
    if [ -n "${selected}" ]; then
        echo $selected
        cd $selected
    fi
}

function dlog() {
  local list
  list=$(docker compose ls -a --format json | jq -r '.[] | "[Compose] \(.Name) (\(.Status)) | \(.ConfigFiles)"' 2>/dev/null)

  [ -z "$list" ] && echo "No docker compose projects found." && return

  local selected
  # --preview 内をシングルクォートで囲み、内部の $ をエスケープしない構成にします
  # awk のフィールドセパレータを簡略化し、さらにパスに含まれる可能性のあるカンマを処理します
  selected=$(echo "$list" | fzf --ansi \
          --header "ENTER: ディレクトリに移動 / CTRL-O: 設定を閲覧" \
          --preview 'path=$(echo {} | rev | cut -d" " -f1 | rev | cut -d"," -f1); if [ -f "$path" ]; then cat "$path"; else echo "File not found: $path"; fi' \
          --bind 'ctrl-o:execute(path=$(echo {} | rev | cut -d" " -f1 | rev | cut -d"," -f1); if [ -f "$path" ]; then less "$path"; else docker inspect "$path"; fi)')

  [ -z "$selected" ] && return

  # 選択後のパス抽出（ここもしっかりと最後の単語を取得）
  local first_path
  first_path=$(echo "$selected" | rev | cut -d' ' -f1 | rev | cut -d',' -f1)

  if [ -f "$first_path" ]; then
    local target_dir
    target_dir=$(dirname "$first_path")
    cd "$target_dir"
    echo "Moved to: $target_dir"
  else
    echo "Error: Config file not found at '$first_path'"
  fi
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

function wbin() {
  if [ "${1:-}" = "cd" ]; then
    local target_dir
    target_dir="$(command wbin cd)"

    if [ -z "$target_dir" ] || [ ! -d "$target_dir" ]; then
      echo "Error: invalid directory: $target_dir" >&2
      return 1
    fi

    builtin cd -- "$target_dir"
    return
  fi

  command wbin "$@"
}

#!/usr/bin/env bash
set -eu

target_dir="${HOME}/.config/nix"
target_file="${target_dir}/user.toml"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

toml_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

build_features_toml() {
  local raw="$1"
  local -a features
  local -a normalized
  local item trimmed escaped

  IFS=',' read -r -a features <<< "$raw"

  for item in "${features[@]}"; do
    trimmed="$(trim "$item")"
    if [ -n "$trimmed" ]; then
      escaped="$(toml_escape "$trimmed")"
      normalized+=("\"${escaped}\"")
    fi
  done

  local output=""
  local i
  for i in "${!normalized[@]}"; do
    if [ "$i" -gt 0 ]; then
      output+=", "
    fi
    output+="${normalized[$i]}"
  done

  printf '[%s]' "$output"
}

prompt_yes_no() {
  local label="$1"
  local default_choice="$2"
  local answer

  while true; do
    printf '%s' "$label" >&2
    IFS= read -r answer
    answer="$(trim "$answer")"

    if [ -z "$answer" ]; then
      [ "$default_choice" = "y" ] && return 0
      return 1
    fi

    case "$answer" in
      y|Y|yes|YES|Yes)
        return 0
        ;;
      n|N|no|NO|No)
        return 1
        ;;
      *)
        echo "Please answer y or n." >&2
        ;;
    esac
  done
}

prompt_enabled_install_features() {
  local -a available_features=(
    "productivity"
    "ai-development"
    "codex"
    "masapps"
  )
  local feature
  local selected=""

  echo "enabledInstallFeatures: select with y/N" >&2
  for feature in "${available_features[@]}"; do
    if prompt_yes_no "  - ${feature}? [y/N]: " "n"; then
      if [ -n "$selected" ]; then
        selected+=","
      fi
      selected+="$feature"
    fi
  done

  printf '%s' "$selected"
}

echo "Create ~/.config/nix/user.toml interactively"

if [ -f "$target_file" ]; then
  printf '%s already exists. Overwrite? [y/N]: ' "$target_file"
  IFS= read -r overwrite
  overwrite="$(trim "$overwrite")"
  if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
    echo "Aborted."
    exit 0
  fi
fi

input_features="$(prompt_enabled_install_features)"

default_username="${USER:-}"
printf 'username [%s]: ' "$default_username"
IFS= read -r input_username
input_username="$(trim "$input_username")"

default_home="${HOME}"
printf 'home [%s]: ' "$default_home"
IFS= read -r input_home
input_home="$(trim "$input_home")"

default_dotfiles_root="$(pwd)"
printf 'dotfilesRoot [%s]: ' "$default_dotfiles_root"
IFS= read -r input_dotfiles_root
input_dotfiles_root="$(trim "$input_dotfiles_root")"

printf 'gitIdentity.name: '
IFS= read -r input_name
input_name="$(trim "$input_name")"

printf 'gitIdentity.email: '
IFS= read -r input_email
input_email="$(trim "$input_email")"

printf 'secrets.EXA_API_KEY [op://vault/item/field]: '
IFS= read -r input_exa
input_exa="$(trim "$input_exa")"

if [ -z "$input_username" ]; then
  input_username="$default_username"
fi

if [ -z "$input_home" ]; then
  input_home="$default_home"
fi

if [ -z "$input_dotfiles_root" ]; then
  input_dotfiles_root="$default_dotfiles_root"
fi

if [ -z "$input_name" ]; then
  input_name="your account"
fi

if [ -z "$input_email" ]; then
  input_email="your email"
fi

if [ -z "$input_exa" ]; then
  input_exa="op://vault/item/field"
fi

if [ -z "$input_username" ]; then
  echo "username is required" >&2
  exit 1
fi

if [ -z "$input_home" ]; then
  echo "home is required" >&2
  exit 1
fi

if [ -z "$input_dotfiles_root" ]; then
  echo "dotfilesRoot is required" >&2
  exit 1
fi

features_toml="$(build_features_toml "$input_features")"
username_toml="$(toml_escape "$input_username")"
home_toml="$(toml_escape "$input_home")"
dotfiles_root_toml="$(toml_escape "$input_dotfiles_root")"
name_toml="$(toml_escape "$input_name")"
email_toml="$(toml_escape "$input_email")"
exa_toml="$(toml_escape "$input_exa")"

mkdir -p "$target_dir"

tmp_file="$(mktemp "${TMPDIR:-/tmp}/user.toml.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

umask 077

cat > "$tmp_file" <<EOF
username = "${username_toml}"
home = "${home_toml}"
dotfilesRoot = "${dotfiles_root_toml}"
enabledInstallFeatures = ${features_toml}

[gitIdentity]
name = "${name_toml}"
email = "${email_toml}"

[secrets]
EXA_API_KEY = "${exa_toml}"
EOF

mv "$tmp_file" "$target_file"
trap - EXIT

echo "Created ${target_file}"

#!/usr/bin/env bash
set -e

echo "=== Mac Bootstrap ==="

repo_url="https://www.github.com/y-writings/dotfiles.git"
repo_dir="${HOME}/workspace/repos/github.com/y-writings/dotfiles"
repo_parent="$(dirname "$repo_dir")"
bootstrap_user="${SUDO_USER:-${USER}}"

#
# 1. Xcode Command Line Tools
#
if ! xcode-select -p &>/dev/null; then
  echo "[1/5] Installing Xcode Command Line Tools..."
  xcode-select --install

  echo "Waiting for Xcode CLT installation to complete..."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  echo "Xcode CLT installed."
else
  echo "[1/5] Xcode CLT already installed. Skipping."
fi

#
# 2. Determinate Nix
#
if ! command -v nix &>/dev/null; then
  echo "[2/5] Installing Determinate Nix..."
  installer_path="$(mktemp -t determinate-nix-install.XXXXXX.sh)"
  trap 'rm -f "$installer_path"' EXIT
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix -o "$installer_path"
  sh "$installer_path" install
  rm -f "$installer_path"
  trap - EXIT
  # Load Nix into this shell without restarting the terminal.
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  echo "Nix installed."
else
  echo "[2/5] Nix already installed. Skipping."
fi

if [ -d "$repo_dir/.git" ]; then
  echo "[3/5] Dotfiles repo already exists at $repo_dir. Skipping clone."
else
  echo "[3/5] Cloning dotfiles repo to $repo_dir..."
  mkdir -p "$repo_parent"
  git clone "$repo_url" "$repo_dir"
  echo "Dotfiles repo cloned."
fi

echo "[4/5] Running create-user-toml.sh..."
chmod +x "$repo_dir/script/create-user-toml.sh"
"$repo_dir/script/create-user-toml.sh"

echo "[5/5] Preparing existing files for nix-darwin..."
files_to_backup=()
# These files become nix-darwin-managed; nix.conf stays with Determinate Nix.
for file in /etc/nix/nix.custom.conf /etc/bashrc /etc/zshenv /etc/zshrc /etc/zprofile; do
  if [ ! -e "$file" ] && [ ! -L "$file" ]; then
    continue
  fi
  if [ -L "$file" ] && [ "$(readlink "$file")" = "/etc/static/${file#/etc/}" ]; then
    continue
  fi
  if [ ! -f "$file" ] && [ ! -L "$file" ]; then
    echo "Cannot back up $file: expected a file or symlink." >&2
    exit 1
  fi
  backup="$file.before-nix-darwin"
  if [ -e "$backup" ] || [ -L "$backup" ]; then
    echo "Cannot back up $file: $backup already exists. Move it aside and retry." >&2
    exit 1
  fi
  files_to_backup+=("$file")
done

for file in "${files_to_backup[@]}"; do
  echo "Backing up $file to $file.before-nix-darwin..."
  sudo mv -n "$file" "$file.before-nix-darwin"
  if [ -e "$file" ] || [ -L "$file" ]; then
    echo "Failed to back up $file; aborting before nix-darwin switch." >&2
    exit 1
  fi
done

echo "[5/5] Running first nix-darwin switch..."
sudo "$(command -v nix)" run nix-darwin -- switch --impure --flake "path:${repo_dir}#${bootstrap_user}-aarch64-darwin" --override-input user-config "path:${HOME}/.config/nix"

echo "=== Bootstrap complete! ==="

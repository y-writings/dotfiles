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

echo "[5/5] Running first nix-darwin switch..."
sudo nix run nix-darwin -- switch --impure --flake "path:${repo_dir}#${bootstrap_user}-aarch64-darwin" --override-input user-config "path:${HOME}/.config/nix"

echo "=== Bootstrap complete! ==="

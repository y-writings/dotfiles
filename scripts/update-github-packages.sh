#!/usr/bin/env bash

set -euo pipefail

for required_command in git jq nix nix-update nixfmt; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$required_command" >&2
    exit 1
  fi
done

cd "$(git rev-parse --show-toplevel)"

system=$(nix eval --impure --raw --expr builtins.currentSystem)
package_names=$(nix eval --json "path:.#packages.$system" --apply builtins.attrNames | jq -r '.[]')

if [[ -z "$package_names" ]]; then
  printf '%s\n' 'No GitHub packages found' >&2
  exit 1
fi

while IFS= read -r package; do
  printf 'Updating %s\n' "$package"
  nix-update "$package" --flake --system "$system" --use-github-releases --build --format
done <<< "$package_names"

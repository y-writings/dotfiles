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
# shellcheck disable=SC2016 # Nix expands ${name} inside the quoted expression.
package_update_flags=$(
  nix eval --json "path:.#packages.$system" --apply '
    packages:
    builtins.mapAttrs (
      name: package:
      let
        updateWithBulkUpdater =
          package.passthru.updateWithBulkUpdater
            or (throw "${name} must define passthru.updateWithBulkUpdater");
      in
      if builtins.isBool updateWithBulkUpdater then
        updateWithBulkUpdater
      else
        throw "${name}.passthru.updateWithBulkUpdater must be a boolean"
    ) packages
  '
)

if [[ "$(jq 'length' <<< "$package_update_flags")" -eq 0 ]]; then
  printf '%s\n' 'No GitHub packages found' >&2
  exit 1
fi

enabled_count=$(jq '[.[] | select(. == true)] | length' <<< "$package_update_flags")
if [[ "$enabled_count" -eq 0 ]]; then
  printf '%s\n' 'No GitHub packages enabled for bulk updates'
fi

while IFS=$'\t' read -r package update_with_bulk_updater; do
  if [[ "$update_with_bulk_updater" == "false" ]]; then
    printf 'Skipping %s (bulk updates disabled)\n' "$package"
    continue
  fi

  printf 'Updating %s\n' "$package"
  nix-update "$package" --flake --system "$system" --use-github-releases --build --format
done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<< "$package_update_flags")

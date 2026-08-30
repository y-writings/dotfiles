# Repository Agent Instructions

## System Activation Boundary

This repository manages the machine declaratively with Nix, nix-darwin, Home
Manager, and nix-homebrew. Requests to install, uninstall, replace, or move a
package authorize declarative configuration changes and non-mutating
verification only by default.

Non-mutating verification includes formatting, evaluation, checks, metadata
inspection, and builds that do not change the active system or user profile.

Treat commands that change the active machine as a separate activation step.
Examples include:

- `darwin-rebuild switch`
- `home-manager switch`
- `mise run rebuild`
- package installation or removal through Homebrew or another package manager
- commands executed through `sudo`

Run an activation command only when the user explicitly requests activation in
the current conversation with wording that cannot reasonably be misunderstood,
such as `rebuildして`. Do not infer activation permission from words such as
install, uninstall, replace, apply, or complete end-to-end.

If activation was not explicitly requested, complete the declarative edits and
verification, stop before activation, and report that the active machine was
not changed. OpenCode execution-time permission prompts are an additional guard,
not a substitute for this policy.

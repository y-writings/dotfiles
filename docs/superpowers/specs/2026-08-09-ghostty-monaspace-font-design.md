# Ghostty Monaspace Font Design

## Goal

Use Monaspace Neon Frozen as Ghostty's primary font while retaining the
existing Japanese glyph fallback.

## Change

In `nix/home/programs/ghostty/default.nix`, replace the primary `font-family`
entry `Cascadia Code NF` with `Monaspace Neon Frozen`. Keep
`UDEV Gothic 35NFLG` as the second entry.

No font package changes are needed because `monaspace` is already installed
through `fonts.packages`, and the repository already uses the same family name
in Zed.

## Verification

- Format and statically evaluate the Nix configuration using the repository's
  existing checks.
- Confirm the generated Ghostty configuration keeps `Monaspace Neon Frozen`
  first and `UDEV Gothic 35NFLG` second.

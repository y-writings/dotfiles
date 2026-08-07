# TypeScript LSP Alias Design

## Goal

Provide `typescript-lsp` as an interactive Zsh alias for the installed
`typescript-language-server` command.

## Design

Add the following entry to the existing `programs.zsh.shellAliases` attribute
set in `nix/home/programs/zsh/default.nix`:

```nix
"typescript-lsp" = "typescript-language-server";
```

This keeps the alias declarative and consistent with the repository's other
shell aliases. Home Manager will render it into the managed Zsh configuration
during the next rebuild. No wrapper executable, flags, or package changes are
required.

## Behavior

In an interactive Zsh session after rebuilding, invoking `typescript-lsp`
expands to `typescript-language-server`. All supplied command-line arguments
continue to the underlying command unchanged.

The alias is intentionally limited to interactive Zsh. External programs
should continue to invoke the actual `typescript-language-server` executable.

## Verification

- Format the modified Nix file with the flake formatter.
- Run the relevant flake checks or Nix evaluation.
- Confirm the generated Zsh alias maps `typescript-lsp` to `typescript-language-server`.

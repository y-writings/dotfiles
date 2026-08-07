# nvim-surround Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `vim-surround` with default-configured `nvim-surround` and
make the repository lockfile writable, active, and reproducible.

**Architecture:** Home Manager will expose the repository's Neovim directory
through an out-of-store symlink, allowing `lazy.nvim` to use its standard
config-directory lockfile. The plugin spec will use `opts = {}` so lazy.nvim
invokes `nvim-surround.setup` without overriding defaults. The lockfile will be
regenerated from installed revisions without updating unrelated plugins.

**Tech Stack:** Nix, Home Manager, Neovim, Lua, lazy.nvim, jq

---

## File Map

- Modify `nix/home/files/default.nix`: expose the Neovim config as a writable
  out-of-store symlink.
- Modify `nix/home/files/nvim/init.lua`: use lazy.nvim's standard lockfile.
- Modify `nix/home/files/nvim/lua/markdown_baseline/plugins.lua`: replace the
  surround plugin specification.
- Modify `nix/home/files/nvim/lazy-lock.json`: pin the complete active plugin
  set, including `nvim-surround`.
- Modify `biome.json`: preserve lazy.nvim's generated lockfile layout.

### Task 1: Activate The Repository Lockfile

**Files:**

- Modify: `nix/home/files/default.nix:38-41`
- Modify: `nix/home/files/nvim/init.lua:39-46`

- [ ] **Step 1: Run the configuration assertion before editing**

Run:

```bash
rg -q 'mkOutOfStoreSymlink "\$\{filesDir\}/nvim"' nix/home/files/default.nix \
  && ! rg -q "lockfile = vim.fn.stdpath\('state'\)" nix/home/files/nvim/init.lua
```

Expected: exit status 1 because the Neovim config is still an in-store source
and the state-directory lockfile override still exists.

- [ ] **Step 2: Make the Neovim config an out-of-store symlink**

Replace the existing `xdg.configFile."nvim"` block in
`nix/home/files/default.nix` with:

```nix
xdg.configFile."nvim".source =
  config.lib.file.mkOutOfStoreSymlink "${filesDir}/nvim";
```

- [ ] **Step 3: Restore lazy.nvim's standard lockfile path**

Remove this line from `nix/home/files/nvim/init.lua`:

```lua
lockfile = vim.fn.stdpath('state') .. '/lazy-lock.json',
```

The surrounding setup must remain:

```lua
require('lazy').setup({
  spec = {
    { import = 'markdown_baseline.plugins' },
  },
  checker = { enabled = false },
  change_detection = { enabled = false },
})
```

- [ ] **Step 4: Re-run the configuration assertion**

Run:

```bash
rg -q 'mkOutOfStoreSymlink "\$\{filesDir\}/nvim"' nix/home/files/default.nix \
  && ! rg -q "lockfile = vim.fn.stdpath\('state'\)" nix/home/files/nvim/init.lua
```

Expected: exit status 0.

- [ ] **Step 5: Parse the changed Nix module**

Run:

```bash
nix-instantiate --parse nix/home/files/default.nix >/dev/null
```

Expected: exit status 0 and no parser errors.

- [ ] **Step 6: Commit the lockfile-path changes**

```bash
git add nix/home/files/default.nix nix/home/files/nvim/init.lua
git commit -m "refactor(nvim): track lazy lockfile with config"
```

Expected: the commit succeeds and repository hooks pass.

### Task 2: Replace vim-surround

**Files:**

- Modify: `nix/home/files/nvim/lua/markdown_baseline/plugins.lua:66-69`

- [ ] **Step 1: Run the plugin-spec assertion before editing**

Run:

```bash
plugins='nix/home/files/nvim/lua/markdown_baseline/plugins.lua'
rg -q "'kylechui/nvim-surround'" "$plugins" \
  && rg -q 'opts = \{\}' "$plugins" \
  && ! rg -q "'tpope/vim-surround'" "$plugins"
```

Expected: exit status 1 because only `tpope/vim-surround` is declared.

- [ ] **Step 2: Replace the plugin specification**

Replace the `tpope/vim-surround` table with:

```lua
{
  'kylechui/nvim-surround',
  opts = {},
},
```

Do not add custom keymaps, options, versions, or lazy-loading conditions.

- [ ] **Step 3: Re-run the plugin-spec assertion**

Run:

```bash
plugins='nix/home/files/nvim/lua/markdown_baseline/plugins.lua'
rg -q "'kylechui/nvim-surround'" "$plugins" \
  && rg -q 'opts = \{\}' "$plugins" \
  && ! rg -q "'tpope/vim-surround'" "$plugins"
```

Expected: exit status 0.

- [ ] **Step 4: Parse the Lua plugin specification**

Run:

```bash
nvim --headless -u NONE \
  "+luafile nix/home/files/nvim/lua/markdown_baseline/plugins.lua" \
  +qa
```

Expected: exit status 0 and no Lua syntax error.

- [ ] **Step 5: Commit the plugin migration**

```bash
git add nix/home/files/nvim/lua/markdown_baseline/plugins.lua
git commit -m "feat(nvim): migrate to nvim-surround"
```

Expected: the commit succeeds and repository hooks pass.

### Task 3: Refresh lazy-lock.json

**Files:**

- Modify: `biome.json`
- Modify: `nix/home/files/nvim/lazy-lock.json`

- [ ] **Step 1: Confirm the current lockfile has the wrong plugin set**

Run:

```bash
jq -e 'keys == [
  "bullets.vim",
  "conform.nvim",
  "lazy.nvim",
  "nightfox.nvim",
  "nvim-lint",
  "nvim-lspconfig",
  "nvim-surround",
  "nvim-treesitter",
  "outline.nvim",
  "render-markdown.nvim"
]' nix/home/files/nvim/lazy-lock.json
```

Expected: exit status 1 because `kanagawa.nvim` is stale and `nightfox.nvim`
and `nvim-surround` are not both pinned.

- [ ] **Step 2: Regenerate the lockfile through a writable config path**

Run:

```bash
set -euo pipefail
temp_config="$(mktemp -d)"
trap 'rm -r "$temp_config"' EXIT
ln -s "$PWD/nix/home/files/nvim" "$temp_config/nvim"
task_check='local ok, err = pcall(function() '
task_check+='local Plugin = require("lazy.core.plugin"); '
task_check+='local Config = require("lazy.core.config"); '
task_check+='for _, plugin in pairs(Config.plugins) do '
task_check+='assert(not Plugin.has_errors(plugin), '
task_check+='"lazy task failed: " .. plugin.name) end end); '
task_check+='if not ok then vim.api.nvim_err_writeln(err); '
task_check+='vim.cmd("cquit") end'
XDG_CONFIG_HOME="$temp_config" nvim --headless \
  "+Lazy! clean" \
  "+Lazy! install" \
  "+lua $task_check" \
  +qa
```

Expected: exit status 0 with no task assertion error. lazy.nvim removes plugins
absent from the specification, installs `nvim-surround`, and writes all
installed revisions to `nix/home/files/nvim/lazy-lock.json` through the config
symlink.

- [ ] **Step 3: Verify the exact lockfile plugin set**

Run:

```bash
jq -e 'keys == [
  "bullets.vim",
  "conform.nvim",
  "lazy.nvim",
  "nightfox.nvim",
  "nvim-lint",
  "nvim-lspconfig",
  "nvim-surround",
  "nvim-treesitter",
  "outline.nvim",
  "render-markdown.nvim"
]' nix/home/files/nvim/lazy-lock.json
```

Expected: output `true` and exit status 0.

- [ ] **Step 4: Keep Biome aligned with lazy.nvim's generated layout**

Add this first entry to the `overrides` array in `biome.json`:

```json
{
  "includes": ["nix/home/files/nvim/lazy-lock.json"],
  "json": {
    "formatter": {
      "expand": "never",
      "lineWidth": 120
    }
  }
}
```

Run:

```bash
before="$(shasum -a 256 nix/home/files/nvim/lazy-lock.json)"
biome format --write nix/home/files/nvim/lazy-lock.json
after="$(shasum -a 256 nix/home/files/nvim/lazy-lock.json)"
test "$before" = "$after"
```

Expected: Biome reports `No fixes applied`, the hashes match, and the command
exits 0.

- [ ] **Step 5: Commit the refreshed lockfile and formatter override**

```bash
git add biome.json nix/home/files/nvim/lazy-lock.json
git commit -m "chore(nvim): refresh lazy lockfile"
```

Expected: the commit succeeds and repository hooks pass.

### Task 4: Verify The Complete Migration

**Files:**

- Verify: `nix/home/files/default.nix`
- Verify: `nix/home/files/nvim/init.lua`
- Verify: `nix/home/files/nvim/lua/markdown_baseline/plugins.lua`
- Verify: `nix/home/files/nvim/lazy-lock.json`

- [ ] **Step 1: Evaluate all public flake checks**

Run:

```bash
nix flake check path:. \
  --all-systems \
  --no-build \
  --no-update-lock-file \
  --keep-going
```

Expected: exit status 0 with all flake checks evaluating successfully.

- [ ] **Step 2: Start the repository config and assert default mappings**

Run:

```bash
set -euo pipefail
temp_config="$(mktemp -d)"
trap 'rm -r "$temp_config"' EXIT
ln -s "$PWD/nix/home/files/nvim" "$temp_config/nvim"
mapping_check='local ok, err = pcall(function() local mappings = { '
mapping_check+='i = { ["<C-g>s"] = "<Plug>(nvim-surround-insert)", '
mapping_check+='["<C-g>S"] = "<Plug>(nvim-surround-insert-line)" }, '
mapping_check+='n = { ys = "<Plug>(nvim-surround-normal)", '
mapping_check+='yss = "<Plug>(nvim-surround-normal-cur)", '
mapping_check+='yS = "<Plug>(nvim-surround-normal-line)", '
mapping_check+='ySS = "<Plug>(nvim-surround-normal-cur-line)", '
mapping_check+='ds = "<Plug>(nvim-surround-delete)", '
mapping_check+='cs = "<Plug>(nvim-surround-change)", '
mapping_check+='cS = "<Plug>(nvim-surround-change-line)" }, '
mapping_check+='x = { S = "<Plug>(nvim-surround-visual)", '
mapping_check+='gS = "<Plug>(nvim-surround-visual-line)" } }; '
mapping_check+='for mode, expected in pairs(mappings) do '
mapping_check+='for lhs, rhs in pairs(expected) do '
mapping_check+='assert(vim.fn.maparg(lhs, mode) == rhs, '
mapping_check+='"unexpected mapping: " .. mode .. " " .. lhs) end end; '
mapping_check+='local opts = require("nvim-surround.config").get_opts(); '
mapping_check+='assert(opts.move_cursor == "begin"); '
mapping_check+='assert(opts.highlight.duration == 0) end); '
mapping_check+='if not ok then vim.api.nvim_err_writeln(err); '
mapping_check+='vim.cmd("cquit") end'
XDG_CONFIG_HOME="$temp_config" nvim --headless \
  "+lua $mapping_check" \
  +qa
```

Expected: exit status 0 with all insert, normal, and visual default mappings
present, `move_cursor = "begin"`, and `highlight.duration = 0`.

- [ ] **Step 3: Check formatting and whitespace**

Run:

```bash
nix fmt -- nix/home/files/default.nix
git diff --check
```

Expected: both commands exit 0; `nix fmt` produces no additional semantic
change and `git diff --check` reports nothing.

- [ ] **Step 4: Inspect the final worktree without touching unrelated user changes**

Run:

```bash
git status --short
git diff origin/main...HEAD -- \
  docs/superpowers/specs/2026-08-07-nvim-surround-design.md \
  docs/superpowers/plans/2026-08-07-nvim-surround.md \
  nix/home/files/default.nix \
  nix/home/files/nvim/init.lua \
  nix/home/files/nvim/lua/markdown_baseline/plugins.lua \
  nix/home/files/nvim/lazy-lock.json
```

Expected: only the user's pre-existing VS Code and Zed changes remain
uncommitted. The branch diff contains the design, plan, Home Manager change,
plugin migration, and refreshed lockfile.

### Task 5: Publish The Pull Request

**Files:** None.

- [ ] **Step 1: Review branch state and all commits**

Run:

```bash
git status --short --branch
git log --oneline origin/main..HEAD
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
git branch -vv
```

Expected: the branch is `feat/nvim-surround`, all intended commits are present,
and unrelated uncommitted files are absent from the branch diff.

- [ ] **Step 2: Push the branch**

Run:

```bash
git push -u origin feat/nvim-surround
```

Expected: the branch is pushed and tracks `origin/feat/nvim-surround`.

- [ ] **Step 3: Create the pull request**

Run:

```bash
body=$'## Summary\n\n'
body+=$'- replace vim-surround with default-configured nvim-surround\n'
body+=$'- use tracked lazy-lock.json via a writable config symlink\n'
body+=$'- refresh the lockfile for the active plugin specification\n\n'
body+=$'## Verification\n\n'
body+=$'- `nix flake check path:. --all-systems --no-build '
body+=$'--no-update-lock-file --keep-going`\n'
body+=$'- headless Neovim default mapping assertions\n'
body+=$'- `git diff --check`'
gh pr create \
  --base main \
  --head feat/nvim-surround \
  --title "feat(nvim): migrate to nvim-surround" \
  --body "$body"
```

Expected: `gh` prints the new pull request URL.

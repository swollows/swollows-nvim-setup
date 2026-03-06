# swollows-neovim-setup

Neovim setup scripts for Debian/Ubuntu and macOS. Installs Neovim, [LazyVim](https://www.lazyvim.org/), and configures [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Gemini CLI](https://github.com/google-gemini/gemini-cli) integration with smooth cursor effects.

## What Gets Installed

| Component | Debian | macOS |
|---|---|---|
| Neovim | Built from source (latest stable tag) | Homebrew |
| LazyVim | Starter config | Starter config |
| ripgrep, fd, lazygit, node | apt + manual install | Homebrew |
| smear-cursor.nvim | Plugin | Plugin |
| neoscroll.nvim | Plugin | Plugin |
| Claude Code terminal integration | Plugin config | Plugin config |
| Gemini CLI terminal integration | Plugin config | Plugin config |

## Debian / Ubuntu

Clones the Neovim repository, checks out the latest stable release tag, builds from source, and installs system-wide.

```bash
chmod +x debian/setup.sh
./debian/setup.sh
```

### Steps performed

1. Installs build dependencies (`ninja-build`, `gettext`, `cmake`, `curl`, `build-essential`)
2. Clones or updates `https://github.com/neovim/neovim` to `~/repos/neovim`
3. Checks out the latest stable version tag (e.g. `v0.11.6`)
   ```bash
   # List all stable tags sorted by version (latest first)
   git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$'
   # Check out the latest one
   git checkout "$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1)"
   ```
4. Builds with `CMAKE_BUILD_TYPE=Release`
5. Installs to `/usr/local` via `sudo make install`
6. Installs LazyVim dependencies and starter config
7. Configures mouse, smear-cursor, neoscroll, Claude Code, and Gemini CLI keybindings

## macOS

Installs Neovim via Homebrew.

```bash
chmod +x mac/setup.sh
./mac/setup.sh
```

### Prerequisites

- [Homebrew](https://brew.sh) must be installed

### Steps performed

1. Installs Neovim via `brew install neovim`
2. Installs dependencies (`ripgrep`, `fd`, `lazygit`, `node`) via Homebrew
3. Clones LazyVim starter config
4. Configures mouse, smear-cursor, neoscroll, Claude Code, and Gemini CLI keybindings

## AI Tool Keybindings

After setup, the following keybindings are available in Neovim:

| Key | Description |
|---|---|
| `Ctrl+`` ` | Shell terminal toggle |
| `<leader>av` | Claude Code right panel (45% width) |
| `<leader>af` | Gemini CLI floating window (85% viewport) |

## Post-Install

Launch Neovim after setup to trigger automatic plugin installation:

```bash
nvim
```

LazyVim will download and configure all plugins on first launch.

## Existing Config Backup

Both scripts automatically back up any existing Neovim configuration before setup:

- `~/.config/nvim` → `~/.config/nvim.bak.<timestamp>`
- `~/.local/share/nvim` → `~/.local/share/nvim.bak.<timestamp>`
- `~/.local/state/nvim` → `~/.local/state/nvim.bak.<timestamp>`
- `~/.cache/nvim` → `~/.cache/nvim.bak.<timestamp>`

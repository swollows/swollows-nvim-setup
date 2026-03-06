#!/usr/bin/env bash
set -euo pipefail

NEOVIM_REPO="https://github.com/LazyVim/starter"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

install_neovim() {
    info "Step A: Installing Neovim via Homebrew..."

    if ! command -v brew &>/dev/null; then
        error "Homebrew is not installed. Install it first: https://brew.sh"
    fi

    brew install neovim

    info "Neovim installed at: $(which nvim)"
    nvim --version | head -3
}

setup_lazyvim() {
    info "Step B: Setting up LazyVim..."

    info "Installing LazyVim dependencies..."
    brew install ripgrep fd lazygit node

    local backup_suffix
    backup_suffix=$(date +%Y%m%d_%H%M%S)

    for dir in ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim; do
        if [ -d "$dir" ]; then
            warn "Backing up $dir to ${dir}.bak.${backup_suffix}"
            mv "$dir" "${dir}.bak.${backup_suffix}"
        fi
    done

    info "Cloning LazyVim starter config..."
    git clone "$NEOVIM_REPO" ~/.config/nvim
    rm -rf ~/.config/nvim/.git

    info "LazyVim starter installed. Plugins will be installed on first launch."
}

setup_cursor_and_ai_tools() {
    info "Step C: Configuring mouse cursor, Claude Code, and Gemini CLI..."

    cat > ~/.config/nvim/lua/plugins/mouse.lua << 'EOF'
return {
  {
    "LazyVim/LazyVim",
    opts = function()
      vim.opt.mouse = "a"
      vim.opt.mousemoveevent = true
      vim.opt.cursorline = true
      vim.opt.smoothscroll = true
      vim.opt.relativenumber = false
    end,
  },
}
EOF

    cat > ~/.config/nvim/lua/plugins/cursor.lua << 'EOF'
return {
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      stiffness = 0.8,
      trailing_stiffness = 0.5,
      trailing_exponent = 0.1,
      distance_stop_animating = 0.5,
      hide_target_hack = false,
    },
  },

  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
EOF

    cat > ~/.config/nvim/lua/plugins/ai-tools.lua << 'EOF'
return {
  {
    "folke/snacks.nvim",
    keys = {
      -- Shell terminal toggle
      {
        "<C-`>",
        function()
          Snacks.terminal.toggle(nil, {
            win = {
              position = "bottom",
              height = 0.35,
            },
          })
        end,
        mode = { "n", "t" },
        desc = "Shell terminal toggle",
      },

      -- Claude Code right panel
      {
        "<leader>av",
        function()
          Snacks.terminal.toggle("claude", {
            env = { id = "claude_right" },
            win = {
              position = "right",
              width = 0.45,
            },
          })
        end,
        mode = { "n", "t" },
        desc = "Claude Code right panel",
      },

      -- Gemini CLI floating window
      {
        "<leader>af",
        function()
          Snacks.terminal.toggle("gemini", {
            env = { id = "gemini_float" },
            win = {
              position = "float",
              width = 0.85,
              height = 0.85,
              border = "rounded",
              title = " Gemini CLI ",
              title_pos = "center",
            },
          })
        end,
        mode = { "n", "t" },
        desc = "Gemini CLI floating window",
      },
    },
  },
}
EOF

    info "Mouse cursor, smear-cursor, neoscroll, Claude Code, and Gemini CLI configuration complete."
}

main() {
    info "========================================="
    info "  Neovim Setup for macOS"
    info "========================================="
    echo

    install_neovim
    setup_lazyvim
    setup_cursor_and_ai_tools

    echo
    info "========================================="
    info "  Setup complete!"
    info "========================================="
    info ""
    info "Launch Neovim to finish plugin installation:"
    info "  nvim"
    info ""
    info "AI tool keybindings:"
    info "  <C-\`>      - Shell terminal toggle"
    info "  <leader>av - Claude Code right panel"
    info "  <leader>af - Gemini CLI floating window"
}

main "$@"

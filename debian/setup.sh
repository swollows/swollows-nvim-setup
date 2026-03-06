#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Neovim Setup Script for Debian/Ubuntu
# ==============================================================================
# This script:
#   a) Downloads the Neovim GitHub repository and checks out the latest stable tag
#   b) Installs build dependencies
#   c) Builds Neovim from source
#   d) Installs Neovim system-wide
#   e) Installs and sets up LazyVim
#   f) Configures mouse cursor, smear-cursor, neoscroll, Claude Code, and Gemini CLI integration
# ==============================================================================

NEOVIM_REPO="https://github.com/neovim/neovim.git"
NEOVIM_SRC_DIR="$HOME/repos/neovim"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ==============================================================================
# Step A: Download Neovim repository and checkout latest stable tag
# ==============================================================================
install_neovim_source() {
    info "Step A: Cloning Neovim repository..."

    if [ -d "$NEOVIM_SRC_DIR" ]; then
        warn "Neovim source directory already exists at $NEOVIM_SRC_DIR"
        info "Fetching latest changes..."
        cd "$NEOVIM_SRC_DIR"
        git fetch --tags --force
    else
        mkdir -p "$(dirname "$NEOVIM_SRC_DIR")"
        git clone "$NEOVIM_REPO" "$NEOVIM_SRC_DIR"
        cd "$NEOVIM_SRC_DIR"
    fi

    # Get the latest stable version tag (vX.Y.Z format, exclude nightly/rc)
    LATEST_TAG=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
    if [ -z "$LATEST_TAG" ]; then
        error "Could not find a stable version tag"
    fi

    info "Checking out latest stable tag: $LATEST_TAG"
    git checkout "$LATEST_TAG"
}

# ==============================================================================
# Step B: Install build dependencies
# ==============================================================================
install_build_deps() {
    info "Step B: Installing build dependencies..."

    sudo apt-get update
    sudo apt-get install -y \
        ninja-build \
        gettext \
        cmake \
        curl \
        build-essential \
        git
}

# ==============================================================================
# Step C: Build Neovim from source
# ==============================================================================
build_neovim() {
    info "Step C: Building Neovim from source..."

    cd "$NEOVIM_SRC_DIR"

    # Clean previous build artifacts if any
    make distclean || true

    # Build with Release optimization
    make CMAKE_BUILD_TYPE=Release

    info "Build complete. Verifying..."
    ./build/bin/nvim --version | head -3
}

# ==============================================================================
# Step D: Install Neovim
# ==============================================================================
install_neovim() {
    info "Step D: Installing Neovim system-wide..."

    cd "$NEOVIM_SRC_DIR"
    sudo make install

    info "Neovim installed at: $(which nvim)"
    nvim --version | head -3
}

# ==============================================================================
# Step E: Install and setup LazyVim
# ==============================================================================
setup_lazyvim() {
    info "Step E: Setting up LazyVim..."

    # Install LazyVim external dependencies
    info "Installing LazyVim dependencies (ripgrep, fd-find, lazygit, node)..."
    sudo apt-get install -y \
        ripgrep \
        fd-find \
        nodejs \
        npm

    # Install lazygit
    if ! command -v lazygit &>/dev/null; then
        info "Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
        sudo install /tmp/lazygit /usr/local/bin
        rm -f /tmp/lazygit /tmp/lazygit.tar.gz
    else
        info "lazygit already installed"
    fi

    # Backup existing Neovim config if present
    local backup_suffix
    backup_suffix=$(date +%Y%m%d_%H%M%S)

    for dir in ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim; do
        if [ -d "$dir" ]; then
            warn "Backing up $dir to ${dir}.bak.${backup_suffix}"
            mv "$dir" "${dir}.bak.${backup_suffix}"
        fi
    done

    # Clone LazyVim starter
    info "Cloning LazyVim starter config..."
    git clone https://github.com/LazyVim/starter ~/.config/nvim

    # Remove .git so user can manage their own config
    rm -rf ~/.config/nvim/.git

    info "LazyVim starter installed. Plugins will be installed on first launch."
}

# ==============================================================================
# Step F-0: Clean existing LazyVim custom settings
# ==============================================================================
clean_lazyvim_config() {
    info "Removing existing LazyVim custom settings..."

    local plugins_dir="$HOME/.config/nvim/lua/plugins"
    if [ -d "$plugins_dir" ]; then
        rm -f "$plugins_dir"/*.lua
        info "Cleared all files in $plugins_dir"
    else
        warn "$plugins_dir does not exist, skipping cleanup"
    fi
}

# ==============================================================================
# Step F: Setup mouse cursor, Claude Code, and Gemini CLI integration
# ==============================================================================
setup_cursor_and_ai_tools() {
    info "Step F: Configuring mouse cursor, Claude Code, and Gemini CLI..."

    # --- Mouse configuration ---
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

    # --- Smear cursor + Neoscroll ---
    cat > ~/.config/nvim/lua/plugins/cursor.lua << 'EOF'
return {
  -- Cursor smear effect: slides with trailing afterimage
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

  -- Smooth scrolling
  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
EOF

    # --- Claude Code & Gemini CLI integration ---
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

# ==============================================================================
# Menu
# ==============================================================================
show_menu() {
    echo
    info "========================================="
    info "  Neovim Setup for Debian/Ubuntu"
    info "========================================="
    echo
    echo "  1) Neovim installation      (build from source + LazyVim + config)"
    echo "  2) LazyVim installation      (LazyVim starter + config)"
    echo "  3) LazyVim customization     (cursor, AI tools config only)"
    echo "  4) All                       (full setup from scratch)"
    echo
    read -rp "Select an option [1-4]: " choice
    echo
}

finish_message() {
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

# ==============================================================================
# Main
# ==============================================================================
main() {
    show_menu

    case "$choice" in
        1)
            install_build_deps
            install_neovim_source
            build_neovim
            install_neovim
            setup_lazyvim
            setup_cursor_and_ai_tools
            ;;
        2)
            setup_lazyvim
            setup_cursor_and_ai_tools
            ;;
        3)
            clean_lazyvim_config
            setup_cursor_and_ai_tools
            ;;
        4)
            install_build_deps
            install_neovim_source
            build_neovim
            install_neovim
            setup_lazyvim
            setup_cursor_and_ai_tools
            ;;
        *)
            error "Invalid option: $choice"
            ;;
    esac

    finish_message
}

main "$@"

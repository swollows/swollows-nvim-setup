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
#   f) Configures mouse cursor, smear-cursor, neoscroll, and OpenCode integration
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
# Step F: Setup mouse cursor and OpenCode integration
# ==============================================================================
setup_cursor_and_opencode() {
    info "Step F: Configuring mouse cursor and OpenCode..."

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

    # --- OpenCode integration ---
    cat > ~/.config/nvim/lua/plugins/opencode.lua << 'EOF'
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

      -- OpenCode bottom panel
      {
        "<leader>ao",
        function()
          Snacks.terminal.toggle("opencode", {
            env = { id = "opencode_bottom" },
            win = {
              position = "bottom",
              height = 0.4,
            },
          })
        end,
        mode = { "n", "t" },
        desc = "OpenCode bottom panel",
      },

      -- OpenCode right panel (Cursor-style sidebar)
      {
        "<leader>av",
        function()
          Snacks.terminal.toggle("opencode", {
            env = { id = "opencode_right" },
            win = {
              position = "right",
              width = 0.45,
            },
          })
        end,
        mode = { "n", "t" },
        desc = "OpenCode right panel",
      },

      -- OpenCode floating window
      {
        "<leader>af",
        function()
          Snacks.terminal.toggle("opencode", {
            env = { id = "opencode_float" },
            win = {
              position = "float",
              width = 0.85,
              height = 0.85,
              border = "rounded",
              title = " OpenCode AI ",
              title_pos = "center",
            },
          })
        end,
        mode = { "n", "t" },
        desc = "OpenCode floating window",
      },
    },
  },
}
EOF

    info "Mouse cursor, smear-cursor, neoscroll, and OpenCode configuration complete."
}

# ==============================================================================
# Main
# ==============================================================================
main() {
    info "========================================="
    info "  Neovim Setup for Debian/Ubuntu"
    info "========================================="
    echo

    install_build_deps
    install_neovim_source
    build_neovim
    install_neovim
    setup_lazyvim
    setup_cursor_and_opencode

    echo
    info "========================================="
    info "  Setup complete!"
    info "========================================="
    info ""
    info "Launch Neovim to finish plugin installation:"
    info "  nvim"
    info ""
    info "OpenCode keybindings:"
    info "  <C-\`>      - Shell terminal toggle"
    info "  <leader>ao - OpenCode bottom panel"
    info "  <leader>av - OpenCode right panel"
    info "  <leader>af - OpenCode floating window"
}

main "$@"

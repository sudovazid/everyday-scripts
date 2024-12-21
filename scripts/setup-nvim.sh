#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Enhanced Neovim Setup for DevOps Developers...${NC}"

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}$1 is not installed. Installing...${NC}"
        sudo pacman -S --noconfirm "$1" || { echo -e "${RED}Failed to install $1. Exiting.${NC}"; exit 1; }
    fi
}

# Ensure the system is up to date
echo -e "${GREEN}Updating the system...${NC}"
sudo pacman -Syu --noconfirm || { echo -e "${RED}Failed to update the system. Exiting.${NC}"; exit 1; }

# Check and install prerequisites
echo -e "${GREEN}Checking prerequisites...${NC}"
check_command "git"
check_command "curl"

# Install essential tools
echo -e "${GREEN}Installing essential tools...${NC}"
sudo pacman -S --noconfirm neovim base-devel unzip nodejs npm python python-pip ripgrep fd cmake tree-sitter wget \
  rustup terraform docker ansible jenkins || {
    echo -e "${RED}Failed to install essential tools. Exiting.${NC}"
    exit 1
}

# Install Rust and set up environment
echo -e "${GREEN}Setting up Rust environment...${NC}"
rustup default stable
rustup component add rust-analyzer clippy rustfmt

# Install Python and Node.js providers
echo -e "${GREEN}Installing Python and Node.js providers...${NC}"
pip install --user pynvim black pylint flake8 || { echo -e "${RED}Failed to install Python tools.${NC}"; exit 1; }
npm install -g neovim pyright typescript typescript-language-server dockerfile-language-server-nodejs \
  ansible-language-server vscode-langservers-extracted || {
    echo -e "${RED}Failed to install Node.js tools.${NC}"
    exit 1
}

# Set up Neovim configuration directories
echo -e "${GREEN}Setting up Neovim configuration directories...${NC}"
mkdir -p ~/.config/nvim/{plugin,after/plugin,lua,colors}

# Install lazy.nvim plugin manager
echo -e "${GREEN}Installing lazy.nvim plugin manager...${NC}"
if [ ! -d "~/.local/share/nvim/lazy/lazy.nvim" ]; then
  git clone --filter=blob:none https://github.com/folke/lazy.nvim.git \
    --branch=stable ~/.local/share/nvim/lazy/lazy.nvim || {
    echo -e "${RED}Failed to install lazy.nvim.${NC}"
    exit 1
  }
else
  echo -e "${BLUE}lazy.nvim is already installed.${NC}"
fi

# Create init.lua
echo -e "${GREEN}Creating init.lua configuration...${NC}"
cat > ~/.config/nvim/init.lua << 'EOF'
-- Load lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specification
require("lazy").setup({
  -- Theme
  { "folke/tokyonight.nvim" },
  
  -- File Explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    config = function()
      require("neo-tree").setup({
        enable_git_status = true,
        filesystem = { filtered_items = { visible = true } },
        window = { position = "left", width = 30 },
      })
    end,
  },

  -- Fuzzy Finder
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  { "nvim-telescope/telescope-file-browser.nvim" },

  -- LSP and Auto-completion
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim", config = true },
  { "williamboman/mason-lspconfig.nvim" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "saadparwaiz1/cmp_luasnip" },
  { "L3MON4D3/LuaSnip" },

  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },

  -- Git Integration
  { "lewis6991/gitsigns.nvim" },

  -- Terminal
  { "akinsho/toggleterm.nvim", version = "*", config = true },

  -- DevOps and Language Specific Plugins
  { "hashivim/vim-terraform" }, -- Terraform
  { "fatih/vim-go" }, -- Go programming
  { "simrat39/rust-tools.nvim" }, -- Rust tools
})

-- Theme settings
vim.cmd("colorscheme tokyonight")
vim.o.background = "dark" -- Use dark mode

-- LSP setup
local lspconfig = require("lspconfig")
require("mason").setup()
require("mason-lspconfig").setup_handlers({
  function(server_name)
    lspconfig[server_name].setup({})
  end,
})

-- Auto-completion setup
local cmp = require("cmp")
cmp.setup({
  snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
  }),
})

-- Keymaps
vim.api.nvim_set_keymap("n", "<C-b>", ":Neotree toggle<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>ff", ":Telescope find_files<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>fg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>fb", ":Telescope buffers<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>t", ":ToggleTerm<CR>", { noremap = true, silent = true })
EOF

echo -e "${GREEN}Enhanced Neovim setup for DevOps complete!${NC}"

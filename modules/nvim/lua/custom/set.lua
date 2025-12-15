-- [[ Setting options ]]
-- See `:help vim.o`

-- Set highlight on search
vim.opt.hlsearch = true

-- Highlight while typing search
vim.opt.incsearch = true

-- Make relative line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.shiftwidth = 4

-- Keep these many lines always visible
vim.opt.scrolloff = 8

-- Disable mouse mode
vim.opt.mouse = ''

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = 'unnamedplus'

-- Enable break indent
vim.opt.breakindent = true

-- Should indent {<CR>} correctly
vim.opt.cindent = true

-- Save undo history
vim.opt.undofile = true
vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undodir'

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Update time of swap file
vim.opt.updatetime = 80
vim.opt.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.opt.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.opt.termguicolors = true

vim.opt.colorcolumn = '90'

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'md', 'markdown', 'txt', 'text' },
  callback = function(_)
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { 'pt_br', 'en' }
  end,
})

return {
  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdateSync',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    -- cmd = { "TSUpdateSync" },
    keys = {
      { '<c-space>', desc = 'Increment selection' },
      { '<bs>', desc = 'Decrement selection', mode = 'x' },
    },
    ---@type TSConfig
    opts = {},
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)

      vim.opt.foldmethod = 'expr'
      vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'

      -- local augroup = vim.api.nvim_create_augroup("open_folds", {})
      -- vim.api.nvim_create_autocmd({ "BufReadPost", "FileReadPost" }, {
      --     -- group = augroup,
      --     pattern = "*",
      --     command = "foldopen!",
      -- })
    end,
  },
}

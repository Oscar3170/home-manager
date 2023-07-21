-- Toggle current line or with count
vim.keymap.set('n', '<C-/>', function()
    return vim.v.count == 0
        and '<Plug>(comment_toggle_linewise_current)'
        or '<Plug>(comment_toggle_linewise_count)'
end, { expr = true })

-- Toggle in Op-pending mode
vim.keymap.set('n', '<C-/>', '<Plug>(comment_toggle_linewise)', { expr = true})

-- Toggle in VISUAL mode
vim.keymap.set('x', '<C-/>', '<Plug>(comment_toggle_linewise_visual)', { expr = true})

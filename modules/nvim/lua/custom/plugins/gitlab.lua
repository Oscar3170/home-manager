local function run_command(cmd)
  local obj = vim.system(cmd):wait()
  if obj.signal ~= 0 then
    vim.notify('Command failed: ' .. cmd .. '\n' .. obj.stderr, vim.log.levels.ERROR)
    return nil
  end

  local result = obj.stdout:gsub('\n+$', '')
  return result
end

return { -- Gitlab plugin for merge requests, CI and more
  'harrisoncramer/gitlab.nvim',
  tag = 'v4.1.1',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
    'sindrets/diffview.nvim',
    -- 'stevearc/dressing.nvim', -- Recommended but not required. Better UI for pickers.
    -- 'nvim-tree/nvim-web-devicons', -- Recommended but not required. Icons in discussion tree.
  },
  build = function()
    require('gitlab.server').build(true)
  end, -- Builds the Go binary
  config = function()
    require('gitlab').setup {
      auth_provider = function()
        if vim.g.gitlab_auth_cache then
          return unpack(vim.g.gitlab_auth_cache)
        end
        print 'GitLab Auth not cached, retrieving from 1password cli'

        local git_remote_url = run_command { 'git', 'remote', 'get-url', 'origin' }

        local op_items_out = run_command { 'op', 'item', 'list', '--tags', 'gitlab-token', '--format', 'json' }
        local items = vim.json.decode(op_items_out)

        local token_item_id = nil
        for i, item in ipairs(items) do
          for j, url in ipairs(item.urls) do
            if string.find(git_remote_url, url.href) then
              token_item_id = item.id
              vim.print('Found token item for url ', item.url.href)
            end
          end
        end

        if token_item_id == nil then
          vim.notify('Failed to find token for repo: ' .. git_remote_url, vim.log.levels.ERROR)
          return nil
        end

        local token_out = run_command { 'op', 'item', 'get', token_item_id, '--fields', 'label=gitlab-access-token,label=gitlab-url', '--reveal' }
        local token, url = unpack(vim.split(token_out, ',', { trimempty = true }))

        vim.g.gitlab_auth_cache = { token, url, nil }
        return unpack(vim.g.gitlab_auth_cache)
      end,
    }
  end,
}

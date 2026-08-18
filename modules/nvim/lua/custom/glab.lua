-- Run `glab ci` in a terminal window with a real PTY.
-- Usage:
--   :GlabCI            -> list recent pipelines (auto-refresh every 5s,
--                         reconstructed from `glab ci list -F json` with colored
--                         status). Press <CR> on one to view it.
--   :GlabCI last       -> run `glab ci view` on the latest pipeline directly
--   :GlabCI <args...>  -> run `glab ci <args...>` in a terminal
local M = {}

local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace 'glab_ci'

-- Pipeline statuses: highlight group + foreground color (GitLab-style).
-- A single source of truth shared by setup_highlights() and render().
local STATUSES = {
  success = { hl = 'GlabSuccess', fg = '#2e7d32' },
  failed = { hl = 'GlabFailed', fg = '#c91c00' },
  running = { hl = 'GlabRunning', fg = '#1976d2' },
  pending = { hl = 'GlabPending', fg = '#f9a825' },
  canceled = { hl = 'GlabCanceled', fg = '#757575' },
  skipped = { hl = 'GlabSkipped', fg = '#757575' },
  created = { hl = 'GlabCreated', fg = '#9e9e9e' },
  manual = { hl = 'GlabManual', fg = '#9e9e9e' },
}

local highlights_setup = false
local function setup_highlights()
  if highlights_setup then
    return
  end
  for _, s in pairs(STATUSES) do
    vim.api.nvim_set_hl(0, s.hl, { fg = s.fg })
  end
  -- Re-apply on colorscheme change, since a new scheme may clear them
  vim.api.nvim_create_autocmd('ColorScheme', {
    callback = function()
      for _, s in pairs(STATUSES) do
        vim.api.nvim_set_hl(0, s.hl, { fg = s.fg })
      end
    end,
  })
  highlights_setup = true
end

-- Per-buffer state: pipeline IDs keyed by 1-indexed line number, and refresh timers.
local ids = {} -- buf -> { [lnum] = pipeline_id }
local timers = {} -- buf -> uv_timer
local inflight = {} -- buf -> bool, guards against overlapping refreshes

-- Delete a buffer if it still exists.
local function delete_buf(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

-- Attach <C-w>{h,j,k,l} window navigation to a terminal buffer (terminal mode).
local function setup_term_keys(buf)
  for _, lhs in ipairs { 'h', 'j', 'k', 'l' } do
    vim.keymap.set('t', '<C-w>' .. lhs, function()
      vim.cmd.wincmd(lhs)
    end, { buffer = buf })
  end
end

-- Format a relative-time string like glab's "(about 1 day ago)" from an ISO 8601 UTC timestamp.
local function rel_time(iso)
  local y, mo, d, h, mi, s = (iso or ''):match '^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)'
  if not y then
    return ''
  end
  -- Both times are interpreted as local, so they share the same UTC-offset bias
  -- and the *difference* between them is correct.
  local then_epoch = os.time { year = y, month = mo, day = d, hour = h, min = mi, sec = s, isdst = false }
  local now_epoch = os.time(os.date '!*t')
  local diff = os.difftime(now_epoch, then_epoch)
  if diff < 0 then
    return 'in the future'
  end
  if diff < 60 then
    return 'less than a minute ago'
  end
  if diff < 3600 then
    return string.format('about %d minute%s ago', math.floor(diff / 60), diff < 120 and '' or 's')
  end
  if diff < 86400 then
    return string.format('about %d hour%s ago', math.floor(diff / 3600), diff < 7200 and '' or 's')
  end
  if diff < 2592000 then
    return string.format('about %d day%s ago', math.floor(diff / 86400), diff < 172800 and '' or 's')
  end
  return string.format('about %d month%s ago', math.floor(diff / 2592000), diff < 5184000 and '' or 's')
end

-- Stop and clean up the refresh timer for a buffer.
local function stop_timer(buf)
  if timers[buf] then
    timers[buf]:stop()
    timers[buf]:close()
    timers[buf] = nil
  end
end

-- Render parsed pipelines into the list buffer with colored status tokens.
local function render(buf, pipelines)
  local lines = {
    ' glab ci list — refreshing every 5s (press <CR> to view a pipeline, q to quit)',
    '',
  }
  local id_map = {}
  local marks = {} -- { lnum0, col_start, col_end, hl } for status highlighting

  for _, p in ipairs(pipelines) do
    local lnum = #lines + 1 -- 1-indexed line of this pipeline
    id_map[lnum] = p.id
    local status_str = string.format('(%s)', p.status)
    -- Pad columns to fixed widths so pipelines align regardless of status/id length.
    -- Padding goes outside the parens for the iid column.
    local iid_str = string.format('(#%d)', p.iid)
    local line = string.format('%-10s • #%-5d  %-7s %-12s (%s)', status_str, p.id, iid_str, p.ref, rel_time(p.created_at))
    table.insert(lines, line)
    local s = STATUSES[p.status] or STATUSES.created
    table.insert(marks, { lnum0 = lnum - 1, col_start = 0, col_end = #status_str, hl = s.hl })
  end

  ids[buf] = id_map

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false

  -- Apply colored highlights to the status tokens
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, m.lnum0, m.col_start, {
      end_col = m.col_end,
      hl_group = m.hl,
      priority = 100,
    })
  end
end

-- (Re)run `glab ci list -F json` and update the buffer asynchronously.
-- Guarded against overlapping refreshes so a slow response can't render stale data.
local function refresh(buf)
  if inflight[buf] then
    return
  end
  inflight[buf] = true
  vim.system({ 'glab', 'ci', 'list', '-F', 'json' }, { text = true }, function(obj)
    local pipelines = {}
    if obj and obj.stdout and obj.stdout ~= '' then
      local ok, data = pcall(vim.json.decode, obj.stdout)
      if ok and type(data) == 'table' then
        pipelines = data
      end
    end
    vim.schedule(function()
      inflight[buf] = nil
      if vim.api.nvim_buf_is_valid(buf) then
        render(buf, pipelines)
      end
    end)
  end)
end

-- Start (or restart) the 5s auto-refresh timer for the list buffer.
local function start_timer(buf)
  stop_timer(buf)
  local timer = uv.new_timer()
  timers[buf] = timer
  timer:start(5000, 5000, function()
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        refresh(buf)
      else
        stop_timer(buf)
      end
    end)
  end)
end

-- Open `glab ci view --pipelineid <id>` in the given window, replacing the list
-- buffer. When the process exits, restore the list buffer and resume refreshing.
-- If the window is closed before the process exits, the orphaned list buffer is
-- cleaned up so it doesn't linger.
local function view_pipeline(win, list_buf, id)
  stop_timer(list_buf)

  local term_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[term_buf].bufhidden = 'wipe'
  vim.api.nvim_win_set_buf(win, term_buf)

  -- Clean up the list buffer if it is closed while hidden behind the terminal.
  vim.api.nvim_create_autocmd('BufDelete', {
    buffer = term_buf,
    once = true,
    callback = function()
      stop_timer(list_buf)
      ids[list_buf] = nil
      delete_buf(list_buf)
    end,
  })

  vim.fn.jobstart({ 'glab', 'ci', 'view', '--pipelineid', id }, {
    term = true,
    on_exit = function(_, _, _)
      vim.schedule(function()
        -- Restore the list buffer in the window if both are still valid
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(list_buf) then
          vim.api.nvim_win_set_buf(win, list_buf)
          refresh(list_buf)
          start_timer(list_buf)
        end
        -- Clean up the terminal buffer
        delete_buf(term_buf)
      end)
    end,
  })

  setup_term_keys(term_buf)
  vim.cmd 'startinsert'
end

-- Open a horizontal split at the bottom and run `cmd` in a PTY-backed terminal.
-- Used by `:GlabCI last` and `:GlabCI <args...>`. Auto-closes on process exit.
local function open_terminal(cmd)
  vim.cmd 'botright new'
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = 'wipe'

  vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function(_, _, _)
      vim.schedule(function()
        delete_buf(buf)
      end)
    end,
  })

  setup_term_keys(buf)
  vim.cmd 'startinsert'
end

-- Open the pipeline list view with a 5s auto-refresh timer.
function M.list()
  setup_highlights()
  vim.cmd 'botright new'
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_name(buf, 'glab://ci-list')
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].swapfile = false
  -- 'hide' so the buffer survives being swapped out for the terminal when
  -- viewing a pipeline; cleanup happens via `q` / BufDelete.
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].filetype = 'glab-ci-list'

  render(buf, {})
  refresh(buf)
  start_timer(buf)

  -- Stop the timer and clean up when the list buffer is deleted
  vim.api.nvim_create_autocmd('BufDelete', {
    buffer = buf,
    callback = function()
      stop_timer(buf)
      ids[buf] = nil
    end,
  })

  -- <CR> views the pipeline under the cursor in the same window
  vim.keymap.set('n', '<CR>', function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local id = ids[buf] and ids[buf][lnum]
    if id then
      view_pipeline(win, buf, id)
    end
  end, { buffer = buf, desc = 'View pipeline under cursor' })

  -- q closes the list view
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf, desc = 'Close pipeline list' })
end

function M.run(args)
  if #args == 0 then
    -- Default: list recent pipelines and let the user pick one
    M.list()
  elseif args[1] == 'last' then
    -- Run `glab ci view` on the latest pipeline directly
    open_terminal { 'glab', 'ci', 'view' }
  else
    -- Forward extra args to `glab ci`
    open_terminal(vim.list_extend({ 'glab', 'ci' }, args))
  end
end

-- Register the :GlabCI user command, forwarding any extra args to `glab ci`
vim.api.nvim_create_user_command('GlabCI', function(opts)
  M.run(opts.fargs)
end, { nargs = '*', desc = 'Run glab ci in a terminal' })

return M

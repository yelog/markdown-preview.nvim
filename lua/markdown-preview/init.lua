local config = require('markdown-preview.config')
local utils = require('markdown-preview.utils')
local render = require('markdown-preview.render')
local M = {}
-- treesitter query
local query = ""
local regex_list = {}
M.namespace = vim.api.nvim_create_namespace "markdown_preview_namespace"
M.config = config

M.setup = function(config)
  -- merge config
  config = config or {}
  M.config = vim.tbl_deep_extend("force", M.config, config)

  -- generate query and regex
  local generate_result = utils.generate_query_regex(M.config.preview)
  query = generate_result.query
  regex_list = generate_result.regex_list

  -- highlight
  for name, previewConfig in pairs(M.config.preview) do
    if previewConfig.highlight ~= nil then
      vim.api.nvim_set_hl(0, name, previewConfig.highlight)
    end
  end

  -- conceal config
  vim.wo.conceallevel = 2
  vim.wo.cole = vim.wo.conceallevel
  if M.config.show_mode == 'insert-line' then
    vim.opt.concealcursor = 'nc'
  elseif M.config.show_mode == 'normal-line' then
    vim.opt.concealcursor = ''
  else
    vim.opt.concealcursor = 'nc'
  end

  -- 判断是否启动
  if M.config.enable then
    M.enable()
  end
end

M.render = function()
  render(M.namespace, M.config, query, regex_list)
end


M.enable = function()
  M.render();
  M.config.enable = true
  vim.cmd [[
        augroup MarkdownPreview
        autocmd FileChangedShellPost,Syntax,TextChanged,InsertLeave,TextChangedI,WinScrolled * lua require('markdown-preview').render()
        augroup END
    ]]
end

M.disable = function()
  M.config.enable = false
  vim.api.nvim_buf_clear_namespace(0, M.namespace, 0, -1)
  -- 清除事件
  vim.cmd [[
        augroup MarkdownPreview
        autocmd!
        augroup END
    ]]
end

M.toggle = function()
  if M.config.enable then
    M.disable()
  else
    M.enable()
  end
end

-- register vim command
vim.api.nvim_command [[command! MarkdownPreviewEnable lua require('markdown-preview').render()]]
vim.api.nvim_command [[command! MarkdownPreviewDisable lua require('markdown-preview').disable()]]
vim.api.nvim_command [[command! MarkdownPreviewToggle lua require('markdown-preview').toggle()]]

return M

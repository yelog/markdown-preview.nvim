local M = {}
local query = {}
M.namespace = vim.api.nvim_create_namespace "markdown_preview_namespace"
local q = require "vim.treesitter.query"

local use_legacy_query = vim.fn.has "nvim-0.9.0" ~= 1


M.config = {
  preview = {
    task_list_marker_unchecked = " ",
    task_list_marker_checked = " "
  },
}

-- 生成 Tree-sitter 查询字符串
local function generate_query()
  local queries = {}

  for name, _ in pairs(M.config.preview) do
    table.insert(queries, string.format(
      '(%s) @%s',
      name, name
    ))
  end

  return table.concat(queries, "\n")
end

M.setup = function(config)
  -- merge config
  config = config or {}
  M.config = vim.tbl_deep_extend("force", M.config, config)
  print(M.config.preview)
  -- generate query
  query = generate_query(M.config.preview)
  vim.cmd [[
        augroup MarkdownPreview
        autocmd FileChangedShellPost,Syntax,TextChanged,InsertLeave,WinScrolled * lua require('markdown-preview').repaint()
        augroup END
    ]]
end

M.repaint = function()
  -- 清理现有的高亮
  vim.api.nvim_buf_clear_namespace(0, M.namespace, 0, -1)

  -- 如果文件类型不是markdown，直接返回
  local filetype = vim.bo.filetype
  if filetype ~= "markdown" then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  -- local language_tree = vim.treesitter.get_parser(bufnr, filetype)
  -- local syntax_tree = language_tree:parse()
  -- local root = syntax_tree[1]:root()
  -- print("match markdown")
  local ts = vim.treesitter
  -- 获取解析器
  local parser = ts.get_parser(bufnr, filetype)
  -- 获取语法树
  local tree = parser:parse()[1]
  -- 获取根节点
  local root = tree:root()
  -- 测试
  -- query = [[ (task_list_marker_unchecked) @task_list_marker_unchecked ]]
  -- 生成并运行查询
  local query_obj = ts.query.parse(filetype, query)

  -- 遍历查询结果
  for id, node in query_obj:iter_captures(root, bufnr, 0, -1) do
    local name = query_obj.captures[id]
    local icon = M.config.preview[name]
    local start_row, start_col, end_row, end_col = node:range()
    print(name, start_row, start_col, end_row, end_col, icon)

    -- 获取捕获的标记文本
    local get_text_function = use_legacy_query and q.get_node_text(node, bufnr)
        or vim.treesitter.get_node_text(node, bufnr)
    local level = #vim.trim(get_text_function)
    local hl_group = name
    local bullet_hl_group = name

    local marker_text = {}
    marker_text[1] = { string.rep(" ", level - 1) .. icon, { hl_group, bullet_hl_group } }

    -- 替换原始文本
    -- vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { icon })

    -- 使用 nvim_buf_set_extmark 进行替换
    vim.api.nvim_buf_set_extmark(bufnr, M.namespace, start_row, start_col - 1, {
      end_col = 0,
      end_row = start_row + 1,
      hl_group = hl_group,
      virt_text = marker_text,
      virt_text_pos = "overlay",
      hl_eol = true,
    })
  end
  -- for _, match, metadata in iter_matches(root, bufnr, 0, -1) do
  --   for id, node in pairs(match) do
  --     print(id, node)
  --     -- local start_row, start_column, end_row, end_column =
  --     --     unpack(vim.tbl_extend("force", { node:range() }, (metadata[id] or {}).range or {}))
  --     -- 遍历 config.preivew.list, 然后打印
  --     -- M.config.preview
  --   end
  -- end
end


return M

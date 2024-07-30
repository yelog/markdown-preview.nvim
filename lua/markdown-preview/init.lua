local M = {}
local query = {}
M.namespace = vim.api.nvim_create_namespace "markdown_preview_namespace"

M.config = {
  preview = {
    task_list_marker_unchecked = { -- Task list marker unchecked
      icon = "",
      highlight = {
        fg = "#706357",
      }
    },
    task_list_marker_checked = { -- Task list marker checked
      icon = '󰄲',
      highlight = {
        fg = "#009f4d",
      }
    },
    list_marker_minus = {
      icon = '◉',
      -- icon = ''
    },
    list_marker_star = {
      icon = '✸',
      -- icon = ''
    },
    list_marker_plus = {
      icon = '○',
      -- icon = ''
    },
    block_quote_marker = { -- Block quote
      icon = "┃",
      query = { "(block_quote_marker) @block_quote_marker",
        "(block_quote (paragraph (inline (block_continuation) @block_quote_marker)))",
        "(block_quote (paragraph (block_continuation) @quote))",
        "(block_quote (block_continuation) @quote)" },
      highlight = {
        fg = "#706357",
      }
    },
    atx_h1_marker = { -- Heading 1
      icon = "󰉫",
      hl_group = "markdownH1Delimiter"
    },
    atx_h2_marker = { -- Heading 2
      icon = "󰉬",
      hl_group = "markdownH2Delimiter"
    },
    atx_h3_marker = { -- Heading 3
      icon = "󰉭",
      hl_group = "markdownH3Delimiter"
    },
    atx_h4_marker = { -- Heading 4
      icon = "󰉮",
      hl_group = "markdownH4Delimiter"
    },
    atx_h5_marker = { -- Heading 5
      icon = "󰉯",
      hl_group = "markdownH5Delimiter"
    },
    atx_h6_marker = { -- Heading 6
      icon = "󰉰",
      hl_group = "markdownH6Delimiter"
    },
  },
}

-- 生成 Tree-sitter 查询字符串
local function generate_query(preview)
  local queries = {}

  for name, content in pairs(preview) do
    if content.query == nil then
      table.insert(queries, string.format(
        '(%s) @%s',
        name, name
      ));
    else
      for _, query in ipairs(content.query) do
        table.insert(queries, query)
      end
    end
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

  -- highlight
  for name, previewConfig in pairs(M.config.preview) do
    if previewConfig.highlight ~= nil then
      vim.api.nvim_set_hl(0, name, previewConfig.highlight)
    end
  end


  vim.cmd [[
        augroup MarkdownPreview
        autocmd FileChangedShellPost,Syntax,TextChanged,InsertLeave,WinScrolled * lua require('markdown-preview').repaint()
        augroup END
    ]]
end

M.repaint = function()
  vim.wo.conceallevel = 2
  vim.wo.cole = vim.wo.conceallevel

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
    local icon = M.config.preview[name].icon
    local hl_group = M.config.preview[name].hl_group or name
    local start_row, start_col, end_row, end_col = node:range()
    -- print(name, start_row, start_col, end_row, end_col, icon)

    -- 获取捕获的标记文本
    -- local bullet_hl_group = name

    -- local marker_text = {}
    -- marker_text[1] = { string.rep(" ", level - 1) .. icon, { hl_group, bullet_hl_group } }

    -- 替换原始文本
    -- vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { icon })

    -- 使用 nvim_buf_set_extmark 进行替换
    -- vim.api.nvim_buf_set_extmark(bufnr, M.namespace, start_row, start_col, {
    --   end_line = end_row,
    --   end_col = end_col,
    --   hl_group = hl_group,
    --   conceal = "◉",
    --   priority = 0, -- To ignore conceal hl_group when focused
    --   -- virt_text = marker_text,
    --   -- virt_text = { { icon, hl_group } },
    --   -- virt_text_pos = "overlay",
    --   -- hl_eol = true,
    -- })
    -- 如果 name 是以 list_marker_ 开头
    if vim.startswith(name, "list_marker_") then
      vim.api.nvim_buf_set_extmark(bufnr, M.namespace, start_row, end_col - 2, {
        end_line = end_row,
        end_col = end_col - 1,
        conceal = icon,
        hl_group = hl_group, -- use_name
        priority = 0,        -- To ignore conceal hl_group when focused
      })
    else
      vim.api.nvim_buf_set_extmark(bufnr, M.namespace, start_row, start_col, {
        end_line = end_row,
        end_col = end_col,
        conceal = icon,
        hl_group = hl_group, -- use_name
        priority = 0,        -- To ignore conceal hl_group when focused
      })
    end
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


-- register vim command
-- vim.api.nvim_command [[command! MarkdownPreviewRepaint lua require('markdown-preview').repaint()]]

return M

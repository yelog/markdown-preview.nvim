local M = {}
-- treesitter query
local query = ""
local regex_list = {}
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
    list_marker_minus = { -- List marker minus
      icon = '',
    },
    list_marker_star = { -- List marker star
      icon = '',
    },
    list_marker_plus = { -- List marker plus
      icon = '',
    },
    inline_code = { -- List marker plus
      icon = ' ',
      hl_group = "markdownCode",
      -- regex = '`[^`]+`',
      regex = '`[^`]+`',
      replace_postion = function(start_row, start_col, end_row, end_col)
        return { { start_row, start_col, start_row, start_col + 1 },
          { end_row,   end_col - 1, end_row,   end_col } }
      end,
    },
    italic = { -- List marker plus
      icon = '',
      -- regex = '`[^`]+`',
      regex = "_[^_]+_",
      replace_postion = function(start_row, start_col, end_row, end_col)
        return { { start_row, start_col, start_row, start_col + 1 },
          { end_row,   end_col - 1, end_row,   end_col } }
      end,
    },
    bolder = { -- bolder
      icon = '',
      regex = "%*%*[^%*]+%*%*",
      replace_postion = function(start_row, start_col, end_row, end_col)
        return { { start_row, start_col, start_row, start_col + 2 },
          { end_row,   end_col - 2, end_row,   end_col } }
      end,
    },
    strikethrough = { -- strikethrough
      icon = '',
      regex = "~~[^~]+~~",
      replace_postion = function(start_row, start_col, end_row, end_col)
        return { { start_row, start_col, start_row, start_col + 2 },
          { end_row,   end_col - 2, end_row,   end_col } }
      end,
    },
    underline = { -- underline
      icon = '',
      regex = "<u>.-</u>",
      replace_postion = function(start_row, start_col, end_row, end_col)
        return { { start_row, start_col, start_row, start_col + 3 },
          { end_row,   end_col - 4, end_row,   end_col } }
      end,
    },
    mark = {
      icon = '',
      regex = "<mark>.-</mark>",
      replace_postion = function(start_row, start_col, end_row, end_col)
        return { { start_row, start_col, start_row, start_col + 6 },
          { end_row,   end_col - 7, end_row,   end_col } }
      end,
    },
    callout_note = {
      icon = '',
      highlight = {
        fg = "#00CEE3",
      },
      regex = ">%s%[!NOTE%]",
      replace_postion = function(start_row, start_col, end_row, end_col)
        return { { start_row, start_col + 1, start_row, start_col + 4 },
          { end_row,   end_col - 1,   end_row,   end_col } }
      end,
    },
    callout_info = {
      icon = '󰙎',
      highlight = {
        fg = "#11FEE3",
      },
      regex = ">%s%[!INFO%]",
      replace_postion = function(start_row, start_col, end_row, end_col)
        return { { start_row, start_col + 1, start_row, start_col + 4 },
          { end_row,   end_col - 1,   end_row,   end_col } }
      end,
    },
    markdownFootnote1 = {
      icon = '󰲠',
      regex = "%[%^1%]",
      hl_group = "markdownFootnote",
    },
    markdownFootnote2 = {
      icon = '󰲢',
      regex = "%[%^2%]",
      hl_group = "markdownFootnote",
    },
    -- code_block = { -- Code block
    --   icon = "󰊕",
    --   query = { "(fenced_code_block) @code_block",
    --     "(indented_code_block) @code_block" },
    --   highlight = {
    --     bg = "#2d2d2d",
    --   }
    -- },
    block_quote_marker = { -- Block quote
      icon = "┃",
      query = { "(block_quote_marker) @block_quote_marker",
        "(block_quote (paragraph (inline (block_continuation) @block_quote_marker)))",
        "(block_quote (paragraph (block_continuation) @block_quote_marker))",
        "(block_quote (block_continuation) @block_quote_marker)" },
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
    if (content.regex ~= nil) then
      regex_list[name] = content.regex
    elseif content.query == nil then
      table.insert(queries, string.format(
        '(%s) @%s',
        name, name
      ));
    elseif type(content.query) == "string" then
      table.insert(queries, content.query)
    elseif type(content.query) == "table" then
      for _, query_item in ipairs(content.query) do
        table.insert(queries, query_item)
      end
    end
  end

  -- 以 \n 分割, 合并查询
  query = table.concat(queries, "\n")
end

-- 查找匹配项及其位置范围
local function find_matches(bufnr, pattern)
  local matches = {}
  local lnum = 0
  for _, line in ipairs(bufnr) do
    lnum = lnum + 1
    for start_col, end_col in string.gmatch(line, "()" .. pattern .. "()") do
      table.insert(matches, {
        lnum = lnum - 1,
        start_col = start_col - 1,
        end_col = end_col - 1
      })
    end
  end
  return matches
end

M.setup = function(config)
  -- merge config
  config = config or {}
  M.config = vim.tbl_deep_extend("force", M.config, config)
  -- print(M.config.preview)
  -- generate query
  generate_query(M.config.preview)

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
  -- 生成并运行查询
  local query_obj = ts.query.parse(filetype, query)

  -- 遍历查询结果
  for id, node in query_obj:iter_captures(root, bufnr, 0, -1) do
    local name = query_obj.captures[id]
    local icon = M.config.preview[name].icon
    local hl_group = M.config.preview[name].hl_group or name
    local start_row, start_col, end_row, end_col = node:range()

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
  for name, regex in pairs(regex_list) do
    local matches = find_matches(vim.api.nvim_buf_get_lines(0, 0, -1, false), regex)
    -- print(name, #matches)
    for _, match in ipairs(matches) do
      -- print(match.lnum, match.start_col, match.end_col)

      local replace_postion_list = { { match.lnum, match.start_col, match.lnum, match.end_col } }

      if M.config.preview[name].replace_postion ~= nil then
        replace_postion_list = M.config.preview[name].replace_postion(match.lnum, match.start_col, match.lnum,
          match.end_col)
      end

      for _, replace_postion in ipairs(replace_postion_list) do
        vim.api.nvim_buf_set_extmark(bufnr, M.namespace, replace_postion[1], replace_postion[2], {
          end_line = replace_postion[3],
          end_col = replace_postion[4],
          conceal = M.config.preview[name].icon,
          hl_group = M.config.preview[name].hl_group or name,
          priority = 0,
        })
      end
      -- vim.api.nvim_buf_set_extmark(bufnr, M.namespace, match.lnum, match.start_col, {
      --   end_line = match.lnum,
      --   end_col = match.end_col,
      --   conceal = M.config.preview[name].icon,
      --   hl_group = M.config.preview[name].hl_group or name,
      --   priority = 0,
      -- })
    end
  end
end


-- register vim command
-- vim.api.nvim_command [[command! MarkdownPreviewRepaint lua require('markdown-preview').repaint()]]

return M

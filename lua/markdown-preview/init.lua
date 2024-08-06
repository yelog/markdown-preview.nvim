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
    task_list_marker_indeterminate = {
      icon = '󰡖',
      highlight = {
        fg = '#E9AD5B',
      },
      regex = '(%[%-%])',
    },
    list_marker_minus = { -- List marker minus
      icon = '',
      highlight = {
        fg = '#E9AD5B'
      }
    },
    list_marker_star = { -- List marker star
      icon = '',
      highlight = {
        fg = '#00C5DE'
      }
    },
    list_marker_plus = { -- List marker plus
      icon = '',
      highlight = {
        fg = '#9FF8BB'
      }
    },
    link = {
      icon = '',
      -- 暂时解决不了去掉方括号的问题, 先暂时保留, 还有不能匹配行首的问题
      regex = "[^!]%[[^%[%]]-%](%(.-%))",
      -- regex = "(%[)([^%[%]]-)%](.-%)",
      hl_group = 'ye_link'
    },
    image = {
      icon = { '', '' },
      -- 暂时解决不了去掉方括号的问题, 先暂时保留, 还有不能匹配行首的问题
      regex = "(!%[)[^%[%]]-(%]%(.-%))",
      -- regex = "(%[)([^%[%]]-)%](.-%)",
      hl_group = 'ye_link'
    },
    tableLine = {
      -- icon = '┃',
      icon = '│',
      regex = "[^|]+(%|)",
      hl_group = 'tableSeparator'
    },
    -- tableRow = {
    --   icon = '─',
    --   width = '',
    --   -- query = { "(pipe_table_delimiter_row (pipe_table_delimiter_cell) @tableRow)" },
    --   regex = '%-',
    --   hl_group = 'tableBorder'
    -- },
    inline_code = { -- List marker plus
      icon = ' ',
      hl_group = "markdownCode",
      regex = '(`)[^`]+(`)',
    },
    italic = { -- Italic
      regex = "([*_])[^*`~]-([*_])",
    },
    bolder = { -- bolder
      icon = '',
      regex = "(%*%*)[^%*]+(%*%*)",
    },
    strikethrough = { -- strikethrough
      regex = "(~~)[^~]+(~~)",
    },
    underline = { -- underline
      regex = "(<u>).-(</u>)",
    },
    mark = {
      regex = "(<mark>).-(</mark>)",
    },
    markdownFootnote1 = {
      icon = '󰲠',
      regex = "(%[%^1%])",
      hl_group = "markdownFootnote",
    },
    markdownFootnote2 = {
      icon = '󰲢',
      regex = "(%[%^2%])",
      hl_group = "markdownFootnote",
    },
    thematic_break = {
      icon = '─',
      whole_line = true,
      hl_group = "markdownRule",
    },
    -- code_block = { -- Code block
    --   icon = "",
    --   -- query = { "(fenced_code_block) @code_block",
    --   --   "(indented_code_block) @code_block" },
    --   regex = "(```)",
    -- },
    block_quote_marker = { -- Block quote
      -- icon = "┃",
      icon = "▋",
      query = { "(block_quote_marker) @block_quote_marker",
        "(block_quote (paragraph (inline (block_continuation) @block_quote_marker)))",
        "(block_quote (paragraph (block_continuation) @block_quote_marker))",
        "(block_quote (block_continuation) @block_quote_marker)" },
    },
    callout_note = {
      icon = { '', '' },
      regex = ">(%s%[!)NOTE(%])",
      hl_group = 'ye_quote',
    },
    callout_info = {
      icon = { '󰙎', '' },
      regex = ">(%s%[!)INFO(%])",
      hl_group = 'ye_quote',
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
-- local function find_matches(bufnr, pattern)
--   local matches = {}
--   local lnum = 0
--   for _, line in ipairs(bufnr) do
--     lnum = lnum + 1
--     for start_col, end_col in string.gmatch(line, "()" .. pattern .. "()") do
--       table.insert(matches, {
--         lnum = lnum - 1,
--         start_col = start_col - 1,
--         end_col = end_col - 1
--       })
--     end
--   end
--   return matches
-- end

-- 获取正则表达式中的捕获组数量
local function get_capture_group_count(pattern)
  local _, count = string.gsub(pattern, "%b()", "")
  return count
end

-- 查找匹配项及其捕获组和位置
local function find_matches_with_groups(bufnr, pattern)
  local matches = {}
  local capture_group_count = get_capture_group_count(pattern)
  local lnum = 0

  for _, line in ipairs(bufnr) do
    lnum = lnum + 1
    local start_pos = 1
    while start_pos <= #line do
      local captures = { string.match(line, pattern, start_pos) }
      local start_col, end_col = string.find(line, pattern, start_pos)

      if #captures == 0 then
        break
      end

      local match = { lnum = lnum - 1, groups = {}, start_col = start_col - 1, end_col = end_col - 1 }
      local current_pos = start_pos

      for i = 1, capture_group_count do
        local s, e = string.find(line, captures[i], current_pos, true)
        if s and e then
          match.groups[i] = { text = captures[i], start_col = s - 1, end_col = e - 1 }
          current_pos = e + 1
        end
      end

      -- 确定下一个匹配的起始位置，避免死循环
      start_pos = current_pos + 1

      table.insert(matches, match)
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
        autocmd FileChangedShellPost,Syntax,TextChanged,InsertLeave,TextChangedI,WinScrolled * lua require('markdown-preview').repaint()
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
  local width = vim.api.nvim_win_get_width(0)
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
    local icon = type(M.config.preview[name].icon) == "table" and M.config.preview[name].icon[1] or
        M.config.preview[name].icon
    local hl_group = M.config.preview[name].hl_group or name
    local start_row, start_col, end_row, end_col = node:range()

    if M.config.preview[name].whole_line then
      vim.api.nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
        virt_text = { { icon:rep(width), hl_group } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
      })
    elseif vim.startswith(name, "list_marker_") then
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
    local icon = M.config.preview[name].icon or '';
    local matches = find_matches_with_groups(vim.api.nvim_buf_get_lines(0, 0, -1, false), regex)
    -- if name == 'tableRow' then
    --   print(#matches)
    -- end
    for _, match in ipairs(matches) do
      -- print(match.lnum, match.start_col, match.end_col)

      -- local replace_postion_list = { { match.lnum, match.start_col, match.lnum, match.end_col } }
      --
      -- if M.config.preview[name].replace_postion ~= nil then
      --   replace_postion_list = M.config.preview[name].replace_postion(match.lnum, match.start_col, match.lnum,
      --     match.end_col)
      -- end

      if #match.groups == 0 then
        vim.api.nvim_buf_set_extmark(bufnr, M.namespace, match.lnum, match.start_col, {
          end_line = match.lnum,
          end_col = match.end_col,
          conceal = type(icon) == "table" and icon[1] or icon,
          hl_group = M.config.preview[name].hl_group or name,
          priority = 0,
        })
      else
        for i, group in ipairs(match.groups) do
          vim.api.nvim_buf_set_extmark(bufnr, M.namespace, match.lnum, group.start_col, {
            end_line = match.lnum,
            end_col = group.end_col + 1,
            conceal = type(icon) == "table" and icon[i] or icon,
            hl_group = M.config.preview[name].hl_group or name,
            priority = 0,
          })
        end
      end

      -- for _, replace_postion in ipairs(replace_postion_list) do
      --   vim.api.nvim_buf_set_extmark(bufnr, M.namespace, replace_postion[1], replace_postion[2], {
      --     end_line = replace_postion[3],
      --     end_col = replace_postion[4],
      --     conceal = icon,
      --     hl_group = M.config.preview[name].hl_group or name,
      --     priority = 0,
      --   })
      -- end
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

local M = {}
-- treesitter query
local query = ""
local regex_list = {}
M.namespace = vim.api.nvim_create_namespace "markdown_preview_namespace"

M.config = {
  enable = true,
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
      },
      icon_padding = { 0, 1 }
    },
    list_marker_star = { -- List marker star
      icon = '',
      highlight = {
        fg = '#00C5DE'
      },
      icon_padding = { 0, 1 }
    },
    list_marker_plus = { -- List marker plus
      icon = '',
      highlight = {
        fg = '#9FF8BB'
      },
      icon_padding = { 0, 1 }
    },
    link = {
      icon = { '', '' },
      -- 暂时解决不了去掉方括号的问题, 先暂时保留, 还有不能匹配行首的问题
      regex = "^[^!]-(%[)[^x]+(%]%(.-%))",
      -- regex = "([^!]%[.-%]%b()) ",
      hl_group = 'ye_link',
      icon_padding = { { 0, 1 } }
    },
    image = {
      icon = { '', '' },
      -- 暂时解决不了去掉方括号的问题, 先暂时保留, 还有不能匹配行首的问题
      regex = "(!%[)[^%[%]]-(%]%(.-%))",
      -- regex = "(%[)([^%[%]]-)%](.-%)",
      hl_group = 'ye_link',
      icon_padding = { { 0, 1 } }
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
    inline_code = { -- inline code
      icon = ' ',
      hl_group = "markdownCode",
      regex = '(`)[^`\n]+(`)',
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
    --   icon = "",
    --   query = { "(fenced_code_block) @code_block",
    --     "(indented_code_block) @code_block" },
    --   -- regex = "(```)([.\n]-)(```)",
    --   hl_fill = true,
    --   hl_group = 'ye_codeblock'
    -- },
    block_quote_marker = { -- Block quote
      -- icon = "┃",
      icon = "▋",
      query = { "(block_quote_marker) @block_quote_marker",
        "(block_quote (paragraph (inline (block_continuation) @block_quote_marker)))",
        "(block_quote (paragraph (block_continuation) @block_quote_marker))",
        "(block_quote (block_continuation) @block_quote_marker)" },
      hl_fill = true,
      hl_group = 'ye_quote'
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
      icon = "󰎦",
      hl_group = "markdownH1Delimiter"
    },
    atx_h2_marker = { -- Heading 2
      icon = "󰎩",
      hl_group = "markdownH2Delimiter"
    },
    atx_h3_marker = { -- Heading 3
      icon = "󰎬",
      hl_group = "markdownH3Delimiter"
    },
    atx_h4_marker = { -- Heading 4
      icon = "󰎮",
      hl_group = "markdownH4Delimiter"
    },
    atx_h5_marker = { -- Heading 5
      icon = "󰎰",
      hl_group = "markdownH5Delimiter"
    },
    atx_h6_marker = { -- Heading 6
      icon = "󰎵",
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

local function render_padding(icon_padding, padding_index, start_row, start_col, end_row, end_col, hl_group)
  -- 最终构建为 {{0, 0}, {0, 0}} 的格式, 如果是 icon_padding 是单个数字, 则转换为 {{0, 0}}
  -- 如果是两个数字{0, 0}, 则是 {{0,0}}, 如果已经是 {{0,0}} 格式, 则不做处理
  local final_icon_padding = {}
  if type(icon_padding) == "number" then
    final_icon_padding = { icon_padding, icon_padding }
  elseif type(icon_padding) == "table" then
    if #icon_padding == 0 or (type(icon_padding[1]) == 'number' and #icon_padding ~= 2) then
      final_icon_padding = { 0, 0 }
    elseif type(icon_padding[1]) == 'number' and type(icon_padding[2]) == 'number' then
      final_icon_padding = { icon_padding[1], icon_padding[2] }
    else
      local matchIndex = false
      for i, v in ipairs(icon_padding) do
        if i == padding_index then
          if type(v) == 'number' then
            final_icon_padding = { v, v }
          elseif type(v) == 'table' and #v == 2 and type(v[1]) == 'number' and type(v[2]) == 'number' then
            final_icon_padding = { v[1], v[2] }
          else
            final_icon_padding = { 0, 0 }
          end
          -- 结束循环
          matchIndex = true
          break
        else
        end
      end
      if not matchIndex then
        final_icon_padding = { 0, 0 }
      end
    end
  else
    final_icon_padding = { 0, 0 }
  end
  local fill_content = ' '
  if final_icon_padding[1] ~= 0 then
    vim.api.nvim_buf_set_extmark(0, M.namespace, start_row, start_col, {
      virt_text = { { fill_content:rep(final_icon_padding[1]), hl_group } },
      virt_text_pos = "inline",
      hl_mode = "combine",
    })
  end
  if final_icon_padding[2] ~= 0 then
    vim.api.nvim_buf_set_extmark(0, M.namespace, end_row, end_col, {
      virt_text = { { fill_content:rep(final_icon_padding[2]), hl_group } },
      virt_text_pos = "inline",
      hl_mode = "combine",
    })
  end
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
  vim.wo.conceallevel = 2
  vim.wo.cole = vim.wo.conceallevel
  vim.opt.concealcursor = 'n'
  if M.config.enable then
    M.enable()
  end
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
    -- 获取当前行内容
    local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
    local line_length = #line
    local icon_padding = M.config.preview[name].icon_padding

    -- set icon
    if M.config.preview[name].whole_line then
      vim.api.nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
        virt_text = { { icon:rep(width), hl_group } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
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
    local fill_content = ' '
    if M.config.preview[name].hl_fill then
      -- 从当前行尾开始, 插入空格, 直到行尾
      vim.api.nvim_buf_set_extmark(bufnr, M.namespace, start_row, line_length, {
        virt_text = { { fill_content:rep(width - line_length), hl_group } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
      })
    end
    -- 插入 padding
    render_padding(icon_padding, 0, start_row, start_col, end_row, end_col, hl_group)
  end
  for name, regex in pairs(regex_list) do
    local icon = M.config.preview[name].icon or '';
    local matches = find_matches_with_groups(vim.api.nvim_buf_get_lines(0, 0, -1, false), regex)
    for _, match in ipairs(matches) do
      if #match.groups == 0 then
        local hl_group = M.config.preview[name].hl_group or name
        vim.api.nvim_buf_set_extmark(bufnr, M.namespace, match.lnum, match.start_col, {
          end_line = match.lnum,
          end_col = match.end_col,
          conceal = type(icon) == "table" and icon[1] or icon,
          hl_group = hl_group,
          priority = 0,
        })
        render_padding(icon_padding, 0, match.start_row, match.start_col, match.end_row, match.end_col, hl_group)
      else
        for i, group in ipairs(match.groups) do
          local hl_group = M.config.preview[name].hl_group or name
          vim.api.nvim_buf_set_extmark(bufnr, M.namespace, match.lnum, group.start_col, {
            end_line = match.lnum,
            end_col = group.end_col + 1,
            conceal = type(icon) == "table" and icon[i] or icon,
            hl_group = hl_group,
            priority = 0,
          })
          render_padding(M.config.preview[name].icon_padding, i, match.lnum, group.start_col, match.lnum,
            group.end_col + 1, hl_group)
          -- print(group.text, match.lnum, group.start_col, group.end_col)
        end
      end
    end
  end
end

M.enable = function()
  M.repaint();
  M.config.enable = true
  vim.cmd [[
        augroup MarkdownPreview
        autocmd FileChangedShellPost,Syntax,TextChanged,InsertLeave,TextChangedI,WinScrolled * lua require('markdown-preview').repaint()
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
vim.api.nvim_command [[command! MarkdownPreviewEnable lua require('markdown-preview').repaint()]]
vim.api.nvim_command [[command! MarkdownPreviewDisable lua require('markdown-preview').disable()]]
vim.api.nvim_command [[command! MarkdownPreviewToggle lua require('markdown-preview').toggle()]]

return M

local utils = require('markdown-preview.utils')

local function render_padding(namespace, icon_padding, padding_index, start_row, start_col, end_row, end_col, hl_group)
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
    vim.api.nvim_buf_set_extmark(0, namespace, start_row, start_col, {
      virt_text = { { fill_content:rep(final_icon_padding[1]), hl_group } },
      virt_text_pos = "inline",
      hl_mode = "combine",
    })
  end
  if final_icon_padding[2] ~= 0 then
    vim.api.nvim_buf_set_extmark(0, namespace, end_row, end_col, {
      virt_text = { { fill_content:rep(final_icon_padding[2]), hl_group } },
      virt_text_pos = "inline",
      hl_mode = "combine",
      conceal = '^'
    })
  end
end
return function(namespace, config, query, regex_list)
  -- 清理现有的高亮
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)

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
    local icon = type(config.preview[name].icon) == "table" and config.preview[name].icon[1] or
        config.preview[name].icon
    local hl_group = config.preview[name].hl_group or name
    local start_row, start_col, end_row, end_col = node:range()
    -- 获取当前行内容
    local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
    local line_length = #line
    local icon_padding = config.preview[name].icon_padding

    -- set icon
    if config.preview[name].whole_line then
      vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, 0, {
        virt_text = { { icon:rep(width), hl_group } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
      })
    else
      vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, start_col, {
        end_line = end_row,
        end_col = end_col,
        conceal = icon,
        hl_group = hl_group, -- use_name
        priority = 0,        -- To ignore conceal hl_group when focused
      })
    end
    local fill_content = ' '
    if config.preview[name].hl_fill then
      -- 从当前行尾开始, 插入空格, 直到行尾
      vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, line_length, {
        virt_text = { { fill_content:rep(width - line_length), hl_group } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
      })
    end
    -- 插入 padding
    render_padding(namespace, icon_padding, 0, start_row, start_col, end_row, end_col, hl_group)
  end
  for name, regex in pairs(regex_list) do
    local icon = config.preview[name].icon or '';
    local matches = utils.find_matches_with_groups(vim.api.nvim_buf_get_lines(0, 0, -1, false), regex)
    local icon_padding = config.preview[name].icon_padding
    for _, match in ipairs(matches) do
      if #match.groups == 0 then
        local hl_group = config.preview[name].hl_group or name
        vim.api.nvim_buf_set_extmark(bufnr, namespace, match.lnum, match.start_col, {
          end_line = match.lnum,
          end_col = match.end_col,
          conceal = type(icon) == "table" and icon[1] or icon,
          hl_group = hl_group,
          priority = 0,
        })
        render_padding(namespace, icon_padding, 0, match.start_row, match.start_col, match.end_row, match.end_col,
          hl_group)
      else
        for i, group in ipairs(match.groups) do
          local hl_group = config.preview[name].hl_group or name
          local conceal = type(icon) == "table" and icon[i] or icon
          -- print(conceal, match.groups)
          vim.api.nvim_buf_set_extmark(bufnr, namespace, match.lnum, group.start_col, {
            end_line = match.lnum,
            end_col = group.end_col + 1,
            conceal = conceal,
            hl_group = hl_group,
            priority = 0,
          })
          render_padding(namespace, config.preview[name].icon_padding, i, match.lnum, group.start_col, match.lnum,
            group.end_col + 1, hl_group)
        end
      end
    end
  end
end

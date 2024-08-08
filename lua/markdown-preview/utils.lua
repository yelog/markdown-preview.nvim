local utils = {}

-- 获取正则表达式中的捕获组数量
utils.get_capture_group_count = function(pattern)
  local _, count = string.gsub(pattern, "%b()", "")
  return count
end


-- 查找匹配项及其捕获组和位置
utils.find_matches_with_groups = function(bufnr, pattern)
  local matches = {}
  local capture_group_count = utils.get_capture_group_count(pattern)
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


-- 生成 Tree-sitter 查询字符串
utils.generate_query_regex = function(preview)
  local regex_list = {}
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

  return {
    -- 以 \n 分割, 合并查询
    query = table.concat(queries, "\n"),
    regex_list = regex_list
  }
end

return utils

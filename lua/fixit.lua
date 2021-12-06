--
-- Fixit
--

local parsers = require('nvim-treesitter.parsers')
local tsutils= require('nvim-treesitter.ts_utils')

-- The tokens to consider.
local tokens = {
  'FIXME',
  'XXX',
  'TODO',
}

-- @param string tokenline The line that starts with a token
-- @param string The Fixit token (see tokens)
-- @return string a string compatible with a line in qflist.
local function to_qfline(comment)
  -- TODO Look at qfformat, if possible, to adhere to that.
  -- TODO Add type and location
  return {
    text = comment,
  }
end

-- @param TSNode node The comment TSNode to check...
-- @return whether or not the given text is a FiXiT comment.
--         First found token triggers `true`
local function is_fixit_comment(comment)
  for _, t in ipairs(tokens) do
    if string.match(comment, t) then
      return true
    end
  end
  return false
end

-- @return string[]  All the FIXIT comments within the given node.
local function all_comments(node, comments)
  if node:type() == "comment" then
    local comment = tsutils.get_node_text(node)[1]
    if is_fixit_comment(comment) then
      table.insert(comments, tsutils.get_node_text(node)[1])
    end
  else
    for child in node:iter_children() do
      all_comments(child, comments)
    end
  end
  return comments
end


--
-- Find all the tokens and list them in the QuickFix window.
local function list()
  local qflines = {}
  local comments = all_comments(parsers.get_tree_root(), {})
  for _, comment in ipairs(comments) do
    table.insert(qflines, to_qfline(comment))
  end
  vim.fn.setqflist(qflines)
  vim.api.nvim_command('copen')
end

local function setup()
  vim.cmd [[ command! FixitList :lua require'fixit'.list() ]]
end

return {
  setup = setup,
  list = list,
}

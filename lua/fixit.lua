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

-- @param node TSNode A node representing a fixit comment.
-- @return table a structure, compatible with the quickfix window.
local function node2qf(node)
  -- TODO Look at qfformat, if possible, to adhere to that.
  -- TODO Add type and location
  local row, col, _ = node:start()
  return {
    text = tsutils.get_node_text(node)[1],
    lnum = row + 1,
    col = col + 1,
    valid = true,
  }
end

-- @param string comment The comment to check.
-- @return bool whether or not the given text is a FiXiT comment.
--         First found token triggers `true`
local function is_fixit_comment(comment)
  for _, t in ipairs(tokens) do
    if string.match(comment, t) then
      return true
    end
  end
  return false
end

-- @param TSNode The node to check for Fixit compliance.
-- @return bool Whether or not we're dealing with a Fixit comment node.
local function is_fixit_node(node)
  return node:type() == "comment" and is_fixit_comment(tsutils.get_node_text(node)[1])
end

-- @param TSNode node The TSNode to traverse and find Fixit comments.
-- @param table qflist The list that will be filled with QuickFix items.
local function comments2qflines(node, qflist)
  if is_fixit_node(node) then
    table.insert(qflist, node2qf(node))
  else
    for child in node:iter_children() do
      comments2qflines(child, qflist)
    end
  end
end

-- Find all the tokens and list them in the QuickFix window.
local function qflist()
  local qflines = {}
  comments2qflines(parsers.get_tree_root(), qflines)
  vim.fn.setqflist(qflines)
  vim.api.nvim_command('copen')
end

local function setup()
  vim.cmd [[ command! FixitList :lua require'fixit'.qflist() ]]
end


return {
  setup = setup,
  qflist = qflist,
}

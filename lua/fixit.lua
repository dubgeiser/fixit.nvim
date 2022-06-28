--
-- Fixit
--

local parsers = require('nvim-treesitter.parsers')
local tsutils= require('nvim-treesitter.ts_utils')

-- Given a list of tokens to look out for, build and return a table with all
-- these tokens, including their most common variations to be found in code.
--
-- @param table List of tokens that Fixit should consider to be a thing to fix.
-- @return table List of the tokens and their variations.
local function build_token_variations(base_tokens)
  local tokens = {}
  for _, token in ipairs(base_tokens) do
    table.insert(tokens, token)
    table.insert(tokens, ':' .. token .. ':')
    table.insert(tokens, token .. ':')
  end
  return tokens
end

-- The tokens to consider.
-- As a word group pattern for `string.gsub`
-- This will be complemented with variations of the tokens, like `:TOKEN:` and
-- `TOKEN:` and put in the local var `tokens`
local tokens = build_token_variations {
  'FIXME',
  'XXX',
  'TODO',
}

-- @param node TSNode A node representing a fixit comment.
-- @return table a structure, compatible with the quickfix window.
local function node2qf(node, token, text)
  local row, col, _ = node:start()
  return {
    text = text,
    module = token,
    lnum = row + 1,
    col = col + 1,
    valid = true,
    filename = vim.fn.expand("%"),
  }
end

-- @param TSNode The node to check for Fixit compliance.
-- @return table qf structure or `nil` if the node couldn't be parsed.
local function parse_fixit_node(node)
  if node:type() ~= "comment" then return nil end
  local fulltext = tsutils.get_node_text(node)[1]
  local capture
  local text

  -- FIXME This can probably be simpler.
  for _, token in ipairs(tokens) do
    capture = fulltext:gmatch(token .. '%s(.*)$')
    text = capture()
    if text ~= nil then
      return node2qf(node, token, text)
    end
  end
  return nil
end

-- @param TSNode node The TSNode to traverse and find Fixit comments.
-- @param table qflist The list that will be filled with QuickFix items.
local function comments2qflines(node, qflist)
  local qf = parse_fixit_node(node)
  if qf ~= nil then
    table.insert(qflist, qf)
  else
    for child in node:iter_children() do
      comments2qflines(child, qflist)
    end
  end
end

-- Find all the tokens and list them in the QuickFix window.
local function qflist()
  if not parsers.has_parser() then
    print("Fixit: No parser for [" .. vim.bo.filetype .. "] type")
    return
  end
  local qflines = {}
  comments2qflines(parsers.get_tree_root(), qflines)
  if next(qflines) == nil then
    print('Fixit: Nothing to fix')
    return
  end
  vim.fn.setqflist({}, ' ', {
    id = "FIXIT_QF",
    title = "  Fixit",
    items = qflines,
  })
  vim.api.nvim_command('copen')
end

local function setup()
  vim.cmd [[ command! Fixit :lua require'fixit'.qflist() ]]
end


return {
  setup = setup,
  qflist = qflist,
}

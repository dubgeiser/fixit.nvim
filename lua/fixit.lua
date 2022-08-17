--
-- Fixit
--

local ts = vim.treesitter
local currbuf = vim.api.nvim_get_current_buf

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

-- String representation of the tokens that can be used to match against in our
-- Treesitter query.
local tokens_query_match = table.concat(tokens, '|')

-- @param string Text to parse out the Fixit token and the corresponding text.
-- @return table First element is the Fixit token, second the text without token.
local function parse_full_comment(fulltext)
  local capture
  local text
  for _, token in ipairs(tokens) do
    capture = fulltext:gmatch(token .. '%s(.*)$')
    text = capture()
    if text ~=nil then
      return token, text
    end
  end
end

-- @param node TSNode A node representing a fixit comment.
-- @return table a structure, compatible with the quickfix window.
local function node2qf(node)
  local row, col, _ = node:start()
  local token, text = parse_full_comment(ts.query.get_node_text(node, currbuf()))
  return {
    text = text,
    module = token,
    lnum = row + 1,
    col = col + 1,
    valid = true,
    filename = vim.fn.expand("%"),
  }
end

-- @return TSQuery The query that will collect the Fixit nodes.
local function build_query()
  -- TODO Capture the Fixit tokens directly in the query and put it in metadata.
  -- TODO Parse out the text (without the Fixit token)
  -- If both of these can be done, we remove the need for `parse_full_comment`
  return ts.parse_query(vim.bo.filetype, [[
    (
      (comment) @comment
      (#match? @comment "]]..tokens_query_match..[[")
      (#set! @comment "type" "Fixit")
    )
  ]])
end

-- Find all the comments with Fixit tokens and list them in the QuickFix window.
local function qflist()
  local language_tree = ts.get_parser(currbuf(), vim.bo.filetype)
  local syntax_tree = language_tree:parse()
  local root = syntax_tree[1]:root()
  local query = build_query()

  local qflines = {}
  for _, match, _ in query:iter_matches(root, currbuf()) do
    for _, node in pairs(match) do
      table.insert(qflines, node2qf(node))
    end
  end

  if next(qflines) == nil then
    print('Fixit: Nothing to fix')
  else
    vim.fn.setqflist({}, ' ', {
      id = "FIXIT_QF",
      title = "  Fixit",
      items = qflines,
    })
    vim.api.nvim_command('copen')
  end
end

-- Setup the Fixit plugin.
local function setup()
  vim.cmd [[ command! Fixit :lua require'fixit'.qflist() ]]
end


return {
  setup = setup,
  qflist = qflist,
}

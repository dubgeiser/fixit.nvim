--
-- Fixit
--

local ts = vim.treesitter
local currbuf = vim.api.nvim_get_current_buf

-- The tokens to consider.
-- This maps a token type to a list of Fixit tokens.
-- The type will be shown in the QuickFix window.
-- Special chars should be properly escaped so they can be used in a treesitter
-- #match? predicate.
local token_map = {
  FIX = {'FIXME', 'FIXME:'},
  TODO = {'TODO', 'TODO:', '\\\\@todo'},
  NOTE = {'NOTE', 'NOTE:', 'XXX', 'XXX:'},
}

local function build_token_query_match(token_map)
  local all_tokens = {}
  for _, tokens in pairs(token_map) do
    for _, token in ipairs(tokens) do
      table.insert(all_tokens, token)
    end
  end
  return table.concat(all_tokens, '|')
end

-- String representation of the tokens that can be used to match against in our
-- Treesitter query.
local tokens_query_match = build_token_query_match(token_map)

-- @param string Text to parse out the Fixit token and the corresponding text.
-- @return table First element is the type of Fixit token, second the text.
local function parse_full_comment(fulltext)
  local capture
  local text
  for type, tokens in pairs(token_map) do
    for _, token in ipairs(tokens) do
      local literal_token = token:gsub('\\', '', 2)
      capture = fulltext:gmatch(literal_token .. '%s(.*)$')
      text = capture()
      if text ~=nil then
        return type, text
      end
    end
  end
end

-- @param node TSNode A node representing a fixit comment.
-- @return table a structure, compatible with the quickfix window.
local function node2qf(node)
  local row, col, _ = node:start()
  local type, text = parse_full_comment(ts.query.get_node_text(node, currbuf()))
  return {
    text = text,
    module = type,
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

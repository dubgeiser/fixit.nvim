--
-- Fixit
--

local ts = vim.treesitter
local currbuf = vim.api.nvim_get_current_buf

-- The tokens to consider.
-- This maps a token type to a list of Fixit tokens.
-- Every line in the map is a table whereby the first element denotes the type
-- of Fixit (todo, note, fix, ...) and the second element is a table of all the
-- Fixit nodes to consider for that type.
-- The type will be shown in the QuickFix window, qf thinks of these as modules.
-- Fixits are grouped by type and shown in order as they are defined here.
-- Special chars should be properly escaped so they can be used in a treesitter
-- #match? predicate.
local token_map = {
  {"FIX", {'FIXME', 'FIXME:'}},
  {"TODO", {'TODO', 'TODO:', '\\\\@todo'}},
  {"NOTE", {'NOTE', 'NOTE:', 'XXX', 'XXX:', '\\\\@note'}},
}

-- Options for the plugin.
-- These are all the default options that can be overridden by passing a table
-- with options to the setup() function.
local options = {
  -- Should we integrate with Trouble plugin (https://github.com/folke/trouble.nvim)
  trouble_integration = false,
}

-- @param string Text to parse out the Fixit token and the corresponding text.
-- @param table tokens The tokens to consider for the given type.
-- @return table First element is the type of Fixit token, second the text.
local function parse_full_comment(fulltext, tokens)
  local capture
  local text
  for _, token in ipairs(tokens) do
    capture = fulltext:gmatch(token:gsub('\\', '', 2) .. '%s(.*)$')
    text = capture()
    if text ~=nil then
      return text
    end
  end
end

-- @param node TSNode A node representing a fixit comment.
-- @param string token_type The type of tokens we're converting
-- @param table tokens The tokens to consider for the given type.
-- @return table a structure, compatible with the quickfix window.
local function node2qf(node, token_type, tokens)
  local row, col, _ = node:start()
  local text = parse_full_comment(ts.query.get_node_text(node, currbuf()), tokens)
  return {
    text = text,
    module = token_type,
    lnum = row + 1,
    col = col + 1,
    valid = true,
    filename = vim.fn.expand("%"),
  }
end

-- @param table the tokens to conside
-- @return TSQuery The query that will collect the Fixit nodes.
local function build_query(tokens)
  return ts.parse_query(vim.bo.filetype, [[
    (
      (comment) @comment
      (#match? @comment "]]..table.concat(tokens, '|')..[[")
    )
  ]])
end

-- Return the root node for the document in the current buffer.
--
-- @return TSNode
local function rootnode()
  return vim.treesitter.get_parser(currbuf(), vim.bo.ft):parse()[1]:root()
end

local function build_qflines()
  local root = rootnode()
  local qflines = {}
  local query, token_type, tokens

  for _, map in ipairs(token_map) do
    token_type = map[1]
    tokens = map[2]
    query = build_query(tokens)
    for _, match, _ in query:iter_matches(root, currbuf()) do
      for _, node in pairs(match) do
        table.insert(qflines, node2qf(node, token_type, tokens))
      end
    end
  end
  return qflines
end

-- Show the Fixit items
-- @param table items List of Fixit items to show.
local function show_fixit_list(items)
  vim.fn.setqflist({}, ' ', {
    id = "FIXIT_QF",
    title = "  Fixit",
    items = items,
  })
  local command = options.trouble_integration and 'Trouble quickfix'
                  or 'horizontal bo copen'
  vim.api.nvim_command(command)
end

-- Find all the comments with Fixit tokens and list them in the QuickFix window.
local function qflist()
  local qflines = build_qflines()
  if next(qflines) == nil then
    print('Fixit: Nothing to fix')
  else
    show_fixit_list(qflines)
  end
end

-- Set the options
-- This function will error if a given option is not in the default options.
-- @param table opts The options overriding the default options.
local function set_options(opts)
  opts = opts or {}
  for k, v in pairs(opts) do
    if options[k] == nil then
      error('Unknown option ['..k..']')
    else
      options[k] = v
    end
  end
end

-- Setup the Fixit plugin.
local function setup(opts)
  set_options(opts)
  vim.cmd [[ command! Fixit :lua require'fixit'.qflist() ]]
end


return {
  setup = setup,
  qflist = qflist,
}

--
-- Fixit
--

local parsers = require('nvim-treesitter.parsers')
local ts_utils= require('nvim-treesitter.ts_utils')

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
  -- TODO Make qflist compatible.
  -- TODO Look at qfformat, if possible, to adhere to that.
  return 'FIXME | position |'..comment
end

-- @return whether or not the given text is a FiXiT comment.
local function is_fixit_comment(text)
  for _, t in ipairs(tokens) do
    if text:startswith(t) then
      return true
    end
  end
  return false
end

--
-- Find all the tokens and list them in the QuickFix window.
local function list()
  local qflines = {}
  local comments = {} -- TODO query for comments
  for _, comment in ipairs(comments) do
    if is_fixit_comment(comment) then
      table.insert(qflines, to_qfline(comment))
    end
  end
  -- TODO set qflist with qflines
end

local function setup()
  vim.cmd [[ command! FixitList :lua require'fixit'.list() ]]
end

return {
  setup = setup,
  list = list,
}

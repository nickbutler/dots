-- Options
vim.opt.autowrite = true
vim.opt.backup = false
vim.opt.breakindent = true
vim.opt.cedit = '<C-O>'
vim.opt.colorcolumn = '88'
vim.opt.commentstring = '# %s'
vim.opt.completeopt = { 'menuone', 'noinsert', 'noselect' }
vim.opt.confirm = true
vim.opt.expandtab = true
vim.opt.exrc = true
vim.opt.fileformat = 'unix'
vim.opt.foldcolumn = 'auto'
vim.opt.formatoptions:remove({ 'c', 'r', 'o' })
vim.opt.gdefault = true
vim.opt.hidden = true
vim.opt.ignorecase = true
vim.opt.inccommand = 'nosplit'
vim.opt.indentkeys:remove('0#')
vim.opt.iskeyword:append('-')
vim.opt.joinspaces = false
vim.opt.linebreak = true
vim.opt.list = true
vim.opt.listchars = { tab = '▸ ', extends = '…', precedes = '…', trail = '∙', nbsp = '∙' }
vim.opt.mouse = 'a'
vim.opt.number = true
vim.opt.pumblend = 20
vim.opt.relativenumber = true
vim.opt.report = 0
vim.opt.ruler = false
vim.opt.scrolljump = 10
vim.opt.scrolloff = 1
vim.opt.secure = true
vim.opt.shiftwidth = 2
vim.opt.showbreak = '‣'
vim.opt.showmode = false
vim.opt.signcolumn = 'yes'
vim.opt.smartcase = true
vim.opt.smarttab = true
vim.opt.softtabstop = 2
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.tabstop = 2
vim.opt.termguicolors = true
vim.opt.textwidth = 88
vim.opt.timeoutlen = 500
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 100
vim.opt.undofile = true
vim.opt.updatetime = 300
vim.opt.wildignorecase = true
vim.opt.wildmode = 'full'
vim.opt.writebackup = false

vim.g.mapleader = ' '
vim.g.ftplugin_sql_omni_key = '<C-V>'

-- Keymaps
local map = vim.keymap.set

map('n', '!',          ':!')
map('n', ':',          ';')
map('n', ';',          ':')
map('n', '<C-C>',      '<Esc>')
map('n', '<C-V>',      'v')
map('n', '<Tab>',      '<C-^>')
map('n', 'S',          ':%s::<Left>')
map('n', '[s',         '[S')
map('n', ']s',         ']S')
map('n', 'v',          '<C-V>')

-- These are overridden below by barbar once plugins load; defined here as
-- fallbacks in case barbar is absent
map('n', '<C-N>',      '<Cmd>bnext<CR>',  { silent = true })
map('n', '<C-P>',      '<Cmd>bNext<CR>',  { silent = true })
map('n', '<M-w>',      ':bw<CR>')

map('n', '<Leader>/',  '<Cmd>noh<CR>',    { silent = true })
map('n', '<Leader><Space>', ':e .<CR>')
map('n', '<Leader>-',  'yyp$v^r-')
map('n', '<Leader>=',  'yyp$v^r=')
map('n', '<Leader>O',  'O<Esc>')
map('n', '<Leader>P',  '"+P')
map('n', '<Leader>a',  'gg"+yG\'.')
map('n', '<Leader>d',  ':%g::d<Left><Left>')
map('n', '<Leader>g',  ':Git ')
map('n', '<Leader>l',  ':set wrap!<CR>')
map('n', '<Leader>o',  'o<Esc>')
map('n', '<Leader>p',  '"+p')
map('n', '<Leader>q',  'gqip')
map('n', '<Leader>r',  '<Cmd>redraw!<CR>')
map('n', '<Leader>s',  '<Cmd>GetHi<CR>')
map('n', '<Leader>v',  '$v^o')
map('n', '<Leader>w',  ':%s/\\s\\+$//e<CR>')

map('i', '<C-A>',      '<Home>')
map('i', '<C-B>',      '<Left>')
map('i', '<C-C>',      '<Esc>')
map('i', '<C-D>',      '<Del>')
map('i', '<C-E>',      '<End>')
map('i', '<C-F>',      '<Right>')
map('i', '<Tab>',      '<C-x><C-u>')

map('x', 'v',          '<C-V>')
map('x', '<C-V>',      'v')
map('x', ';',          ':')
map('x', ':',          ';')
map('x', '<',          '<gv')
map('x', '>',          '>gv')
map('x', '<CR>',       '"+y:Copy<CR>', { silent = true })
map('x', '<Leader>y',  '"+y')
map('x', '<Leader>p',  '"+p')

map('c', '<C-A>',      '<Home>')
map('c', '<C-B>',      '<Left>')
map('c', '<C-D>',      '<Del>')
map('c', '<C-E>',      '<End>')
map('c', '<C-F>',      '<Right>')
map('c', '<C-N>',      '<Down>')
map('c', '<C-P>',      '<Up>')

vim.cmd('cnoreabbrev Q q')
vim.cmd('cnoreabbrev WQ wq')
vim.cmd('cnoreabbrev x bw')

-- Plugins
local gh = function(x) return 'https://github.com/' .. x end

vim.pack.add({
  -- Dependencies
  gh('nvim-lua/plenary.nvim'),
  gh('nvim-tree/nvim-web-devicons'),

  -- Editing
  gh('tpope/vim-abolish'),
  gh('tpope/vim-repeat'),
  gh('kylechui/nvim-surround'),
  gh('tpope/vim-speeddating'),
  gh('windwp/nvim-autopairs'),

  -- Navigation / UI
  gh('romgrk/barbar.nvim'),
  gh('junegunn/fzf'),
  gh('junegunn/fzf.vim'),

  -- Markdown
  gh('dhruvasagar/vim-table-mode'),

  -- Filetypes
  gh('slim-template/vim-slim'),
  gh('aliou/bats.vim'),
  gh('earthly/earthly.vim'),
  gh('hashivim/vim-terraform'),
  gh('ollykel/v-vim'),
  gh('chrisbra/csv.vim'),

  -- Git
  gh('tpope/vim-fugitive'),
  gh('lewis6991/gitsigns.nvim'),

  -- Tools
  gh('tpope/vim-dadbod'),
  gh('tpope/vim-eunuch'),
  gh('tpope/vim-rails'),
  gh('jamessan/vim-gnupg'),
  gh('brenoprata10/nvim-highlight-colors'),

  -- Terminal / tmux
  gh('nickbutler/vim-ranger'),
  gh('nickbutler/vim-tig'),
  gh('christoomey/vim-tmux-navigator'),

  -- Theme / status
  gh('EdenEast/nightfox.nvim'),
  gh('nvim-lualine/lualine.nvim'),
})

-- Plugin config

-- auto-pairs
vim.g.AutoPairsShortcutFastWrap = '<C-]>'

-- barbar
map('n', '<C-N>',   '<Cmd>BufferNext<CR>',      { silent = true })
map('n', '<C-P>',   '<Cmd>BufferPrevious<CR>',  { silent = true })
map('n', '<M-w>',   '<Cmd>BufferClose<CR>',      { silent = true })
map('n', '<M-.>',   '<Cmd>BufferMoveNext<CR>',   { silent = true })
map('n', '<M-,>',   '<Cmd>BufferMovePrevious<CR>', { silent = true })
map('n', '1<Tab>',  '<Cmd>BufferGoto 1<CR>',    { silent = true })
map('n', '2<Tab>',  '<Cmd>BufferGoto 2<CR>',    { silent = true })
map('n', '3<Tab>',  '<Cmd>BufferGoto 3<CR>',    { silent = true })
map('n', '4<Tab>',  '<Cmd>BufferGoto 4<CR>',    { silent = true })
map('n', '5<Tab>',  '<Cmd>BufferGoto 5<CR>',    { silent = true })

-- csv.vim
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'csv',
  callback = function() vim.b.csv_arrange_align = 'l*' end,
})

-- fzf
vim.g.fzf_layout = { window = { width = 0.95, height = 0.75 } }
vim.g.fzf_history_dir = '~/.local/share/fzf-history'
vim.g.fzf_colors = {
  fg      = { 'fg', 'Normal' },
  bg      = { 'bg', 'Normal' },
  hl      = { 'fg', 'Directory' },
  ['fg+'] = { 'fg', 'Normal' },
  ['bg+'] = { 'bg', 'Visual' },
  ['hl+'] = { 'fg', 'Title' },
  info    = { 'fg', 'Comment' },
  border  = { 'fg', 'LineNr' },
  prompt  = { 'fg', 'Function' },
  pointer = { 'fg', 'Special' },
  marker  = { 'fg', 'Keyword' },
  spinner = { 'fg', 'Comment' },
  header  = { 'fg', 'Comment' },
}

map('n', '<C-s>', ':Rg ')
map('n', '<C-f>', '<Cmd>Files<CR>',    { silent = true })
map('n', '<C-b>', '<Cmd>GFiles?<CR>',  { silent = true })
map('n', '<C-h>', '<Cmd>History<CR>',  { silent = true })
map('n', '<C-q>', '<Cmd>History/<CR>', { silent = true })
map('n', '<F9>',  '<Cmd>History:<CR>', { silent = true })
map('n', '<BS>',  '<Cmd>Helptags<CR>', { silent = true })
map('i', '<C-x><C-f>', '<Plug>(fzf-complete-path)', { remap = true })

local function fzf_pwd_recent_files()
  return vim.tbl_filter(function(v)
    return not v:match('^[/~]')
  end, vim.fn['fzf#vim#_recent_files']())
end

local function pwd_history(source)
  return vim.fn['fzf#vim#history']({ source = source or fzf_pwd_recent_files() })
end

local function pwd_history_or_files()
  if vim.fn.expand('%') ~= '' then return end
  local hist = fzf_pwd_recent_files()
  if #hist > 0 then pwd_history(hist) else vim.cmd.Files() end
end

vim.api.nvim_create_user_command('PwdHistory', function() pwd_history() end, {})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'fzf',
  callback = function() vim.opt_local.winblend = 15 end,
})

-- symbols-outline
map('n', '<F6>', '<Cmd>SymbolsOutline<CR>', { silent = true })

-- vim-fugitive
map('n', '<Leader><C-G>', ':Git commit -va<CR>:Git push<CR>')
vim.api.nvim_create_autocmd('User', {
  pattern = 'FugitiveEditor',
  callback = function() vim.cmd.startinsert() end,
})

-- vim-commentary
map('n', '<C-_>',  'gcc',  { remap = true })
map('v', '<C-_>',  'gc',   { remap = true })
map('n', '<C-\\>', 'gcip', { remap = true })

-- v-vim
vim.g.v_autofmt_bufwritepre = 1
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'vlang',
  callback = function() vim.opt_local.listchars:append({ tab = '  ' }) end,
})

-- vim-ranger
vim.g.ranger_on_exit = 'bw!'
vim.g.ranger_open_mode = 'edit'

-- vim-tig
vim.g.tig_executable = 'fish -c "tmuxpasskey dont tig status"'
vim.g.tig_default_command = ''
map('n', '<C-G>', '<Cmd>Tig<CR>', { silent = true })

-- vim-tmux-navigator
vim.g.tmux_navigator_no_mappings = 1
map('n', '<C-J>', '<Cmd>TmuxNavigateDown<CR>',  { silent = true })
map('n', '<C-K>', '<Cmd>TmuxNavigateUp<CR>',    { silent = true })
map('n', '<C-L>', '<Cmd>TmuxNavigateRight<CR>', { silent = true })

-- Commands
vim.api.nvim_create_user_command('Copy', function()
  vim.fn.setreg('+', vim.trim(vim.fn.getreg('+')))
end, {})

vim.api.nvim_create_user_command('GetHi', function()
  local id = vim.fn.synID(vim.fn.line('.'), vim.fn.col('.'), 1)
  print(vim.fn.synIDattr(vim.fn.synIDtrans(id), 'name'))
end, {})

vim.api.nvim_create_user_command('Password', function(a)
  vim.cmd('read !pwgen -s ' .. a.args)
end, { nargs = '?' })

vim.api.nvim_create_user_command('TabFix', function()
  vim.cmd('%s:\t:  :')
end, {})

vim.api.nvim_create_user_command('Reload', function()
  vim.cmd.source(vim.fn.stdpath('config') .. '/init.lua')
end, { bar = true })

vim.api.nvim_create_user_command('Install', function()
  vim.cmd.Reload()
  vim.pack.update()
end, {})

-- Autocmds
vim.filetype.add({ extension = { fish = 'fish', ex = 'elixir' } })

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function() vim.opt_local.spell = true end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'ranger', 'tig' },
  callback = function()
    vim.opt_local.showtabline = 0
    vim.opt_local.laststatus = 0
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = 'no'
    vim.api.nvim_create_autocmd('BufLeave', {
      buffer = 0,
      once = true,
      callback = function()
        vim.opt.showtabline = 2
        vim.opt.laststatus = 2
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.signcolumn = 'yes'
      end,
    })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'gitcommit',
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})

vim.api.nvim_create_autocmd('BufLeave', {
  callback = function() vim.b.winview = vim.fn.winsaveview() end,
})

vim.api.nvim_create_autocmd('BufEnter', {
  callback = function()
    if vim.b.winview then vim.fn.winrestview(vim.b.winview) end
  end,
})

-- Colours
require('nightfox').setup({ options = { transparent = true } })
vim.cmd.colorscheme('nordfox')

vim.cmd [[
  highlight ErrorMsg          guibg=NONE guifg=#BF616A
  highlight WarningMsg        guibg=NONE guifg=#EBCB8B
  highlight SpellBad          guifg=NONE
  highlight Search            guibg=#3e4a5b guifg=NONE
  highlight IncSearch         guibg=#3e4a5b guifg=NONE gui=bold
  highlight DiffAdd           guibg=NONE
  highlight DiffChange        guibg=NONE
  highlight DiffDelete        guibg=NONE
  highlight DiffText          guibg=NONE
  highlight BufferCurrentSign guifg=#88C0D0
  highlight BufferInactive    guifg=#616E88 guibg=#3b4252
]]

require('config')

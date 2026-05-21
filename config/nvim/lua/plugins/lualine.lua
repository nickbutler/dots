require('lualine').setup({
  options = {
    theme = 'nordfox',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = { 'ranger', 'tig' },
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', { 'diff', symbols = { added = ' ', modified = ' ', removed = ' ' } }, 'diagnostics' },
    lualine_c = {
      { function()
          local dir = vim.fn.expand('%:~:.:h')
          if dir == '' then return '' end
          return dir
        end },
    },
    lualine_x = { 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = {},
  },
})

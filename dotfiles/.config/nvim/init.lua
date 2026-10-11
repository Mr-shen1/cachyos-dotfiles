vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 保留 Neovim 自带欢迎页，基础外观与截图接近。
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.laststatus = 2
vim.opt.showmode = false
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.conceallevel = 0
vim.opt.fillchars = { eob = " ", vert = "│" }

local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local output = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Failed to install lazy.nvim:\n" .. output)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "night", styles = { comments = { italic = false } } },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      popup_border_style = "rounded",
      window = { position = "left", width = 32 },
      filesystem = {
        follow_current_file = { enabled = true },
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },
  {
    "nvim-mini/mini.nvim",
    branch = "stable",
    lazy = false,
    config = function()
      -- 与截图类似的 Git / Diff / LSP 状态栏。
      require("mini.git").setup()
      require("mini.diff").setup()
      local statusline = require("mini.statusline")
      statusline.setup({ use_icons = false })
      -- 保留文件类型，隐藏编码、换行格式和文件大小。
      statusline.section_fileinfo = function() return vim.bo.filetype end
      -- mini.statusline 默认使用全局状态栏；这里保留文件树自己的状态栏。
      vim.opt.laststatus = 2

      local map = require("mini.map")
      map.setup({
        integrations = {
          map.gen_integration.builtin_search(),
          map.gen_integration.diagnostic(),
          map.gen_integration.diff(),
        },
        symbols = { encode = map.gen_encode_symbols.block("3x2") },
        window = { side = "right", width = 10, winblend = 25 },
      })
      vim.api.nvim_create_user_command("MapToggle", function() map.toggle() end, {})
    end,
  },
  {
    "folke/which-key.nvim",
    lazy = false,
    opts = {
      preset = "classic",
      delay = 250,
      icons = { mappings = false },
      spec = { { "<leader>t", group = "[T]oggle" } },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    cmd = "RenderMarkdown",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      enabled = false,
      heading = { sign = false },
      code = { sign = false, width = "block", right_pad = 1 },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    build = "cd app && ./install.sh",
    init = function() vim.g.mkdp_theme = "dark" end,
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}, {
  -- 用 -u 试用时，锁文件也写在这份配置旁边。
  lockfile = config_dir .. "/lazy-lock.json",
})

vim.keymap.set("n", "<leader>tf", "<cmd>Neotree toggle<CR>", { desc = "[T]oggle [F]ile tree" })
vim.keymap.set("n", "<leader>tm", "<cmd>MapToggle<CR>", { desc = "[T]oggle [M]ap" })
vim.keymap.set("n", "<leader>tp", function() require("render-markdown").toggle() end,
  { desc = "[T]oggle [P]review Markdown" })
vim.keymap.set("n", "<leader>tb", "<cmd>MarkdownPreviewToggle<CR>", { desc = "[T]oggle [B]rowser preview" })

vim.keymap.set("n", "<leader><leader>", "<cmd>Telescope find_files<CR>", { desc = "Find files" })

-- 本机 Neovim 0.12.5 已附带 markdown 与 markdown_inline 解析器。
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function() vim.treesitter.start() end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    if vim.fn.isdirectory(data.file) == 1 then
      vim.cmd.cd(data.file)
      vim.cmd.enew()
      require("neo-tree.command").execute({ action = "show", dir = data.file })
    end
  end,
})

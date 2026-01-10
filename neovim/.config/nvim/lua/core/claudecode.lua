return {
  {
    "coder/claudecode.nvim",
		lazy = true,
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("claudecode").setup()
    end
  }
}

return {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
        {
            "<leader>tt",
            "<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>",
            desc = "Diagnostics (Trouble)",
        },
    }

}

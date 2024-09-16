return {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
        local highlight = {
            "Text",
            "Love",
            "Gold",
            "Rose",
            "Pine",
            "Foam",
            "Iris",
        }

        local hooks = require "ibl.hooks"
        -- create the highlight groups in the highlight setup hook, so they are reset
        -- every time the colorscheme changes
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
            vim.api.nvim_set_hl(0, "Text", { fg = "#e0def4" })
            vim.api.nvim_set_hl(0, "Love", { fg = "#eb6f92" })
            vim.api.nvim_set_hl(0, "Gold", { fg = "#f6c177" })
            vim.api.nvim_set_hl(0, "Rose", { fg = "#ea9a97" })
            vim.api.nvim_set_hl(0, "Pine", { fg = "#3e8fb0" })
            vim.api.nvim_set_hl(0, "Foam", { fg = "#9ccfd8" })
            vim.api.nvim_set_hl(0, "Iris", { fg = "#c4a7e7" })
        end)

        require("ibl").setup { indent = { highlight = highlight } }
    end
}

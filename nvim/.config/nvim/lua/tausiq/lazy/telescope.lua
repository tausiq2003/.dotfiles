return {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
    dependencies =  {'nvim-lua/plenary.nvim'}, 
    config = function()
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        vim.keymap.set('n','<leader>ps', function()builtin.grep_string({search = vim.fn.input("Grep > ") });
        end)
        local actions = require('telescope.actions')
                require('telescope').setup({
            defaults = {
                mappings = {
                    i = {
                        ["<leader><C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,  
                    },
                    n = {  
                        ["<leader><C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                    }
                }
            }
        })
    end

}



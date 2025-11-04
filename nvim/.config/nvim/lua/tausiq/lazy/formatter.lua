return {
    "mhartington/formatter.nvim",
    config = function()

        local prettier = function()
            return {
                exe = "prettier",
                args = {"--stdin-filepath", vim.api.nvim_buf_get_name(0),
                "--tab-width", "4"},
                stdin = true
            }
        end

        local clang_format = function()
            return {
                exe = "clang-format",
                args = {
                    -- clang_format_option,
                    '--style="{BasedOnStyle: llvm, IndentWidth: 4}"',
                    '--assume-filename=' .. vim.api.nvim_buf_get_name(0),
                },
                stdin = true,
                cwd = vim.fn.expand("%:p:h"),
            }
        end

        local gofmt = function()
            return {
                exe = "gofmt",
                stdin = true
            }
        end

        local autopep8 = function()
            return {
                exe = "autopep8",
                args = {"-"},
                stdin = true
            }
        end

        require('formatter').setup({
            filetype = {
                javascript = {prettier},
                typescript = {prettier},
                javascriptreact = {prettier},  
                typescriptreact = {prettier}, 

                cpp = {clang_format},
                c = {clang_format},

                go = {gofmt},

                python = {autopep8}
            }
        })

        vim.api.nvim_exec([[
        augroup FormatAutogroup
        autocmd!
        autocmd BufWritePost *.{cpp,c,go,js,jsx,ts,tsx,py} FormatWrite
        augroup END
        ]], true)

    end
}

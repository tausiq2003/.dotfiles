return {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "mxsdev/nvim-dap-vscode-js",
    },
    config = function()
        local dap = require("dap")
        local ui = require("dapui")
        local dap_virtual_text = require("nvim-dap-virtual-text")

        dap_virtual_text.setup()
        ui.setup()

        vim.fn.sign_define("DapBreakpoint", { text = "B" })

        -- ─── C/C++/Rust ───────────────────────────────────────────
        dap.adapters.codelldb = {
            type = "server",
            port = "${port}",
            executable = {
                command = "codelldb",
                args = { "--port", "${port}" },
            }
        }

        local cpp_config = {
            {
                name = "Launch",
                type = "codelldb",
                request = "launch",
                program = function()
                    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                end,
                cwd = "${workspaceFolder}",
                stopOnEntry = false,
            },
            {
                name = "Attach to process",
                type = "codelldb",
                request = "attach",
                processId = require("dap.utils").pick_process,
                cwd = "${workspaceFolder}",
            }
        }

        dap.configurations.c = cpp_config
        dap.configurations.cpp = cpp_config
        dap.configurations.rust = cpp_config

        -- ─── Go ──────────────────────────────────────────────────
        dap.adapters.delve = {
            type = "server",
            port = "${port}",
            executable = {
                command = "dlv",
                args = { "dap", "--listen", "127.0.0.1:${port}" },
            }
        }

        dap.configurations.go = {
            {
                name = "Launch file",
                type = "delve",
                request = "launch",
                program = "${file}",
            },
            {
                name = "Launch package",
                type = "delve",
                request = "launch",
                program = function ()
                    return vim.fn.input("Path to package: ", vim.fn.getcwd() .. "/", "file")
                    
                end
            },
            {
                name = "Attach to process",
                type = "delve",
                request = "attach",
                processId = require("dap.utils").pick_process,
            }
        }

        -- ─── Python ──────────────────────────────────────────────
        dap.adapters.python = {
            type = "executable",
            command = "python",
            args = { "-m", "debugpy.adapter" },
        }

        dap.configurations.python = {
            {
                name = "Launch file",
                type = "python",
                request = "launch",
                program = "${file}",
                pythonPath = function()
                    return vim.fn.exepath("python")
                end,
            }
        }

        -- ─── JS / TS / Web ───────────────────────────────────────
        require("dap-vscode-js").setup({
            debugger_path = vim.fn.exepath("js-debug"):match("(.*/bin)/") .. "/..",
            adapters = { "pwa-node", "pwa-chrome", "node-terminal" },
        })

        local js_config = {
            {
                name = "Launch file",
                type = "pwa-node",
                request = "launch",
                program = "${file}",
                cwd = "${workspaceFolder}",
                sourceMaps = true,
            },
            {
                name = "Attach to process",
                type = "pwa-node",
                request = "attach",
                processId = require("dap.utils").pick_process,
                cwd = "${workspaceFolder}",
            },
            {
                name = "Launch Chrome",
                type = "pwa-chrome",
                request = "launch",
                url = "http://localhost:3000",
                webRoot = "${workspaceFolder}",
                sourceMaps = true,
            },
        }

        local js_langs = { "javascript", "typescript", "javascriptreact", "typescriptreact" }
        for _, lang in ipairs(js_langs) do
            dap.configurations[lang] = js_config
        end

        -- ─── UI listeners ─────────────────────────────────────────
        dap.listeners.before.attach.dapui_config = function() ui.open() end
        dap.listeners.before.launch.dapui_config = function() ui.open() end
        dap.listeners.before.event_terminated.dapui_config = function() ui.close() end
        dap.listeners.before.event_exited.dapui_config = function() ui.close() end

        -- ─── Keymaps ──────────────────────────────────────────────
        vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
        vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: Continue" })
        vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Debug: Step Into" })
        vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Debug: Step Over" })
        vim.keymap.set("n", "<leader>du", dap.step_out, { desc = "Debug: Step Out" })
        vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Debug: Open REPL" })
        vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debug: Run Last" })
        vim.keymap.set("n", "<leader>db", dap.list_breakpoints, { desc = "Debug: List Breakpoints" })
        vim.keymap.set("n", "<leader>de", function()
            dap.set_exception_breakpoints({ "all" })
        end, { desc = "Debug: Set Exception Breakpoints" })
        vim.keymap.set("n", "<leader>dq", function()
            dap.terminate()
            ui.close()
            dap_virtual_text.toggle()
        end, { desc = "Debug: Terminate" })
    end
} 

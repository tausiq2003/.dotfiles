return {
    {
        'barrett-ruth/live-server.nvim',
        -- ig don't if nixos
        -- build = 'pnpm add -g live-server',
        cmd = { 'LiveServerStart', 'LiveServerStop' },
        config = true
    }
}

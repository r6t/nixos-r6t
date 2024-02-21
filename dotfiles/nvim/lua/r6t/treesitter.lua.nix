    require'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all" (the five listed parsers should always be installed)
    -- causes nixos-related error: cannot create parser directory in read only file system blah
    -- ensure_installed = { "all" },

    highlight = {
        enable = true,
    }
    }

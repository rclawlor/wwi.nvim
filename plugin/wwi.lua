vim.api.nvim_create_user_command(
    "WhereWasI",
    function()
        require("wwi.command").where_was_i()
    end,
    {}
)

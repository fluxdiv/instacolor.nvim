local M = {}

--- Plugin Configuration
--- @class InstaColorConfig
--- @field files string[] List of file patterns to apply highlights to
--- @field hl_config table<string, vim.api.keyset.highlight> Highlight definitions
--- @field line_check fun(line: string): string|table|nil Custom function to determine highlight based on line contents. Return nil if not a match
-- Default Config
M.instacolor_config = {
    files = {},
    hl_config = {
        InstaColorDefault = {
            bg = "#000000",
        },
    },
    line_check = function(line)
        return line:match("IC([%a%d_]+)$")
    end,
}

local ns_id = vim.api.nvim_create_namespace("insta_color")

function M.set_highlights()
    for name, opts in pairs(M.instacolor_config.hl_config) do
        vim.api.nvim_set_hl(0, name, opts)
    end
end

-- auto apply highlights to matching files in config.files
function M.auto_highlight()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    for i, line in ipairs(lines) do
        local match = M.instacolor_config.line_check(line)
        if match == nil then goto continue end
        local hl_name
        if type(match) == "string" then
            if M.instacolor_config.hl_config[match] then
                hl_name = match
            end
        elseif type(match) == "table" then
            hl_name = "InstaColorCustomLineMatch" .. i
            M.instacolor_config.hl_config[hl_name] = match
            M.set_highlights()
        end

        if hl_name and M.instacolor_config.hl_config[hl_name] then
            vim.api.nvim_buf_set_extmark(0, ns_id, i-1, 0, {
                hl_eol = true,
                invalidate = true,
                line_hl_group = hl_name
            })
        end

        ::continue::

    end
end

--- @param user_config InstaColorConfig
-- Setup
function M.setup(user_config)
    M.instacolor_config = vim.tbl_extend("force", M.instacolor_config, user_config or {})
    M.set_highlights()
    if M.instacolor_config.files and #M.instacolor_config.files > 0 then
        vim.api.nvim_create_autocmd({"BufWritePost", "BufReadPost"}, {
            pattern = M.instacolor_config.files,
            callback = M.auto_highlight
        })
    end
end

return M


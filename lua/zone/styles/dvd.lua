local dvd = {}

local win, buf
local local_opts = require("zone.config").dvd
local direction = {"r", "d"}
local hl = 'Type'

local mod = require("zone.helper")

local check_touch_side = function(row, col, text_h, text_w)
    local old = direction
    local first, second = unpack(direction)
    if (row + text_h) >= vim.o.lines-2 then direction = {first, "u"} end
    if (col + text_w) >= vim.o.columns-2 then direction = {"l", second} end
    if col <= 1 then direction = {"r", second} end
    if row <= 1 then direction = {first, "d"} end
    if not vim.deep_equal(old, direction) then
        local colors = {'Identifier', 'Keyword', 'Type', 'Function'}
        hl = colors[math.random(4)]
    end
end

local get_rand = function(text_h, text_w)
    math.randomseed(os.time())
    local r = math.random(1, vim.o.lines-text_h-1)
    local c = math.random(1, vim.o.columns-text_w-1)
    return r, c
end

function dvd.start()
    local lines = local_opts.text

    local text_w = vim.api.nvim_strwidth(lines[1])
    local text_h = #lines-1
    local r, c = get_rand(text_h, text_w)

    mod.create_and_initiate(function()
        buf = vim.api.nvim_create_buf(false, true)
        win = vim.api.nvim_open_win(buf, false, {
            relative="editor", style='minimal', height=text_h,
            width=text_w, row=r, col=c
        })
        vim.api.nvim_win_set_option(win, 'winhl', 'Normal:'..hl)
        vim.api.nvim_buf_set_lines(buf, 0, #lines, false, lines)
    end, local_opts)

    mod.on_exit = function()
        pcall(vim.api.nvim_win_close, win, true)
        pcall(vim.api.nvim_buf_delete, buf, {force=true})
    end

    mod.on_each_tick(function()
        if not vim.api.nvim_win_is_valid(win) then return end
        local config = vim.api.nvim_win_get_config(win)
        local row, col = config["row"], config["col"]

        check_touch_side(row, col, text_h, text_w)

        if vim.deep_equal(direction, {"r", "d"}) then
            config["row"] = row + 1
            config["col"] = col + 1
        elseif vim.deep_equal(direction, {"r", "u"}) then
            config["row"] = row - 1
            config["col"] = col + 1
        elseif vim.deep_equal(direction, {"l", "d"}) then
            config["row"] = row + 1
            config["col"] = col - 1
        elseif vim.deep_equal(direction, {"l", "u"}) then
            config["row"] = row - 1
            config["col"] = col - 1
        end

        vim.api.nvim_win_set_option(win, 'winhl', 'Normal:'..hl)
        vim.api.nvim_win_set_config(win, config)
    end)
end

return dvd

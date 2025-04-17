local dvd = {}

local win, buf, bg_win, bg_buf
local local_opts = require("zone.config").dvd
local direction = {"r", "d"}
local hl = 'Type'

local mod = require("zone.helper")

-- check if logo touched border
local check_touch_side = function(row, col, text_h, text_w)
    local old = direction
    local first, second = unpack(direction)
    local change_color = false
    
    if (row + text_h) >= vim.o.lines-1 then 
        direction = {first, "u"}
        change_color = true
    end
    if (col + text_w) >= vim.o.columns then 
        direction = {"l", second}
        change_color = true
    end
    if col <= 1 then 
        direction = {"r", second}
        change_color = true
    end
    if row <= 1 then 
        direction = {first, "d"}
        change_color = true
    end
    
    -- change color logic (TODO: build custom randomizer to prevent same value from being randomly selected again)
    if change_color then
        local colors = {"Identifier", "Keyword", "Function", "String", "Number", "PreProc"}
        hl = colors[math.random(#colors)]
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
        -- create temp bg buffer overlaying over curr buffer
        bg_buf = vim.api.nvim_create_buf(false, true)
        
        -- fill bg buffer with empty lines
        local bg_lines = {}
        for i = 1, vim.o.lines do
            table.insert(bg_lines, string.rep(" ", vim.o.columns))
        end
        vim.api.nvim_buf_set_lines(bg_buf, 0, -1, false, bg_lines)
        
        -- create fullscreen bg window
        bg_win = vim.api.nvim_open_win(bg_buf, false, {
            relative = "editor",
            style = 'minimal',
            width = vim.o.columns,
            height = vim.o.lines,
            row = 0,
            col = 0,
            zindex = 10 -- should exist below logo
        })
        vim.api.nvim_win_set_option(bg_win, 'winhl', 'Normal:Normal')
        
        -- create DVD logo buffer and window
        buf = vim.api.nvim_create_buf(false, true)
        win = vim.api.nvim_open_win(buf, false, {
            relative = "editor", 
            style = 'minimal', 
            height = text_h,
            width = text_w, 
            row = r, 
            col = c,
            zindex = 50 -- should exist above bg
        })
        vim.api.nvim_win_set_option(win, 'winhl', 'Normal:'..hl)
        vim.api.nvim_buf_set_lines(buf, 0, #lines, false, lines)
    end, local_opts)

    -- close buffer and window
    mod.on_exit = function()
        pcall(vim.api.nvim_win_close, win, true)
        pcall(vim.api.nvim_buf_delete, buf, {force=true})
        pcall(vim.api.nvim_win_close, bg_win, true)
        pcall(vim.api.nvim_buf_delete, bg_buf, {force=true})
    end

    -- update logo pos each tick
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



-- TODO:
-- add a system to ensure random colour selector cant select currently selected colour (gives impression that colour failed to change on bounce)
-- likely have to build my own randomizer func
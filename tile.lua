local api, CHILDS, CONTENTS = ...

local json = require "json"
local helper = require "helper"
local anims = require(api.localized "anims")

local font
local white = resource.create_colored_texture(1,1,1)
local fallback_track_background = resource.create_colored_texture(.5,.5,.5,1)

local schedule = {}
local event = {}
local rooms = {}
local all_next_talks = {}
local room_next_talks = {}
local current_room
local day = 0
local time = 0
local show_language = true
local show_track = true

local M = {}

local function rgba(base, a)
    return base[1], base[2], base[3], a
end

local function log(what)
    return print("[pretalx] " .. what)
end

function M.data_trigger(path, data)
    log("received data '" .. data .. "' on " .. path)
end

function M.updated_config_json(config)
    log("running on device ".. tostring(sys.get_env "SERIAL"))
    font = resource.load_font(api.localized(config.font.asset_name))
    show_language = config.show_language
    show_track = config.show_track

    current_room = nil
    for idx, room in ipairs(config.rooms) do
        log(tostring(room.serial) .. " room '" .. room.name .. "'")
        if room.serial == sys.get_env "SERIAL" then
            log("found my room: ", room.name)
            current_room = room.name
        end
    end
end

function M.updated_schedule_json(new_schedule)
    log("new schedule")
    schedule = new_schedule.talks
end

function M.updated_event_json(new_info)
    log("new event info")
    event = new_info
end

local function wrap(str, font, size, max_w)
    local lines = {}
    local space_w = font:width(" ", size)

    local remaining = max_w
    local line = {}
    for non_space in str:gmatch("%S+") do
        local w = font:width(non_space, size)
        if remaining - w < 0 then
            lines[#lines+1] = table.concat(line, "")
            line = {}
            remaining = max_w
        end
        line[#line+1] = non_space
        line[#line+1] = " "
        remaining = remaining - w - space_w
    end
    if #line > 0 then
        lines[#lines+1] = table.concat(line, "")
    end
    return lines
end

local function check_next_talks()
    time = api.clock.unix()
    log("time is now " .. time)

    room_next_talks = {}
    all_next_talks = {}

    local min_start = time - 25 * 60

    log("my room is '" .. current_room .. "'")

    for idx = 1, #schedule do
        local talk = schedule[idx]

        -- Ignore all talks that have already ended here. We don't want
        -- to announce these.
        if talk.end_ts > time then
            -- is this in *this* room, or somewhere else?
            if current_room and talk.room == current_room then
                room_next_talks[#room_next_talks+1] = talk
            end
            all_next_talks[#all_next_talks+1] = talk
        end
    end

    local function sort_talks(a, b)
        return a.start_ts < b.start_ts or (a.start_ts == b.start_ts and a.room < b.room)
    end

    table.sort(room_next_talks, sort_talks)
    table.sort(all_next_talks, sort_talks)

    log(tostring(#all_next_talks) .. " talks to come")
    log(tostring(#room_next_talks) .. " in this room")
end

local function view_next_talk(starts, ends, config, x1, y1, x2, y2)
    local font_size = config.font_size or 70
    local show_abstract = config.next_abstract
    local track_text = config.next_track_text
    local default_color = {helper.parse_rgb(config.color or "#ffffff")}

    local a = anims.Area(x2 - x1, y2 - y1)

    local S = starts
    local E = ends

    local function text(...)
        return a.add(anims.moving_font(S, E, font, ...))
    end

    local x, y = 0, 0

    local time_size = font_size
    local title_size = font_size
    local abstract_size = math.floor(font_size * 0.8)
    local speaker_size = math.floor(font_size * 0.8)
    local track_size = math.floor(font_size * 0.6)

    local current_talk = room_next_talks[1]

    local col1 = 0
    local col2 = 35 + font:width("in XXX min", time_size)

    if #schedule == 0 then
        text(col2, y, "Fetching talks...", time_size, rgba(default_color,1))
    elseif not current_talk then
        text(col2, y, "Nope. That's it.", time_size, rgba(default_color,1))
    else
        -- Time
        text(col1, y, current_talk.start_str, time_size, rgba(default_color,1))

        -- Delta
        local delta = current_talk.start_ts - time
        local talk_time
        if delta > 180*60 then
            talk_time = string.format("in %d h", math.floor(delta/3600))
        elseif delta > 0 then
            talk_time = string.format("in %d min", math.floor(delta/60)+1)
        else
            talk_time = "Now"
        end

        local y_time = y+time_size
        text(col1, y_time, talk_time, time_size, rgba(default_color,1))

        -- Title
        local y_start = y

        local lines = wrap(current_talk.title, font, title_size, a.width - col2)
        for idx = 1, math.min(5, #lines) do
            text(col2, y, lines[idx], title_size, rgba(default_color,1))
            y = y + title_size
        end
        y = y + 20

        -- Show abstract only if it fits into the drawing area completely
        if show_abstract and a.height > (y + #lines*abstract_size + 20) then
            local lines = wrap(current_talk.abstract, font, abstract_size, a.width - col2)
            for idx = 1, #lines do
                text(col2, y, lines[idx], abstract_size, rgba(default_color,1))
                y = y + abstract_size
            end
            y = y + 20
        end

        -- Show speakers only if all of them do fit into the drawing area
        if a.height > (y + #current_talk.persons*speaker_size + 20) then
            for idx = 1, #current_talk.persons do
                text(col2, y, current_talk.persons[idx], speaker_size, rgba(default_color,.8))
                y = y + speaker_size
            end
        end

        if current_talk.track then
            local r,g,b = helper.parse_rgb(current_talk.track.color)
            if track_text then
                if a.height > y + 20 + track_size then
                    text(col2, y+20, current_talk.track.name, track_size, r,g,b,1)
                end
            else
                a.add(anims.moving_image_raw(
                    S, E, resource.create_colored_texture(r,g,b,1),
                    col2 - 25, 0,
                    col2 - 10, y
                ))
            end
        end
    end

    for now in api.frame_between(starts, ends) do
        a.draw(now, x1, y1, x2, y2)
    end
end

local function view_all_talks(starts, ends, config, x1, y1, x2, y2)
    local title_size = config.font_size or 70
    local default_color = {helper.parse_rgb(config.color or "#ffffff")}
    local show_speakers = config.all_speakers

    local a = anims.Area(x2 - x1, y2 - y1)

    local S = starts
    local E = ends

    local time_size = title_size
    local info_size = math.floor(title_size * 0.8)

    -- always leave room for 15px of track bar
    local col1 = 0
    local col2 = 35 + font:width("XXX min ago", time_size)

    local x, y = 0, 0

    local function text(...)
        return a.add(anims.moving_font(S, E, font, ...))
    end

    if #schedule == 0 then
        text(col2, y, "Fetching talks...", title_size, rgba(default_color,1))
    elseif #all_next_talks == 0 and #schedule > 0 and sys.now() > 30 then
        text(col2, y, "Nope. That's it.", title_size, rgba(default_color,1))
    end

    for idx = 1, #all_next_talks do
        local talk = all_next_talks[idx]

        local title_lines = wrap(
            talk.title,
            font, title_size, a.width - col2
        )

        local info_line = talk.room

        if show_speakers and #talk.persons then
            local joiner = ({
                de = "mit",
            })[talk.locale] or "with"
            info_line = info_line .. " " .. joiner .. " " .. table.concat(talk.persons, ", ")
        end

        local info_lines = wrap(
            info_line,
            font, info_size, a.width - col2
        )

        if y + #title_lines * title_size + 3 + #info_lines * info_size > a.height then
            break
        end

        -- time
        local talk_time
        local delta = talk.start_ts - time
        if delta > -60 and delta < 60 then
            talk_time = "Now"
        elseif delta > 30*60 then
            talk_time = talk.start_str
        elseif delta > 0 then
            talk_time = string.format("in %d min", math.floor(delta/60)+1)
        else
            talk_time = string.format("%d min ago", math.ceil(-delta/60))
        end
        local time_width = font:width(talk_time, time_size)
        text(col2 - 35 - time_width, y, talk_time, time_size, rgba(default_color, 1))

        if show_track and talk.track then
            local r,g,b = helper.parse_rgb(talk.track.color)
            a.add(anims.moving_image_raw(
                S, E, resource.create_colored_texture(r,g,b,1),
                col2 - 25, y,
                col2 - 10, y + #title_lines*title_size + 3 + #info_lines*info_size
            ))
        end

        -- title
        for idx = 1, #title_lines do
            text(col2, y, title_lines[idx], title_size, rgba(default_color,1))
            y = y + title_size
        end
        y = y + 3

        -- info
        for idx = 1, #info_lines do
            text(col2, y, info_lines[idx], info_size, rgba(default_color,.8))
            y = y + info_size
        end
        y = y + 20
    end

    for now in api.frame_between(starts, ends) do
        a.draw(now, x1, y1, x2, y2)
    end
end

local function view_room(starts, ends, config, x1, y1, x2, y2)
    local font_size = config.font_size or 70
    local align = config.room_align or "left"
    local default_color = {helper.parse_rgb(config.color or "#ffffff")}

    local a = anims.Area(x2 - x1, y2 - y1)

    local S = starts
    local E = ends

    local function text(...)
        return a.add(anims.moving_font(S, E, font, ...))
    end

    local x = 0
    local w = font:width(current_room, font_size)
    if align == "right" then
        x = a.width - w
    elseif align == "center" then
        x = (a.width - w) / 2
    end
    text(x, 0, current_room, font_size, rgba(default_color,1))

    for now in api.frame_between(starts, ends) do
        a.draw(now, x1, y1, x2, y2)
    end
end

local function view_day(starts, ends, config, x1, y1, x2, y2)
    local font_size = config.font_size or 70
    local align = config.day_align or "left"
    local template = config.day_template or "Day %d"
    local default_color = {helper.parse_rgb(config.color or "#ffffff")}

    local a = anims.Area(x2 - x1, y2 - y1)

    local S = starts
    local E = ends

    local function text(...)
        return a.add(anims.moving_font(S, E, font, ...))
    end

    local x = 0
    local line = string.format(template, day)
    local w = font:width(line, font_size)
    if align == "right" then
        x = a.width - w
    elseif align == "center" then
        x = (a.width - w) / 2
    end
    text(x, 0, line, font_size, rgba(default_color,1))

    for now in api.frame_between(starts, ends) do
        a.draw(now, x1, y1, x2, y2)
    end
end

function M.task(starts, ends, config, x1, y1, x2, y2)
    check_next_talks()
    return ({
        next_talk = view_next_talk,
        all_talks = view_all_talks,

        room = view_room,
        day = view_day,
    })[config.mode or 'all_talks'](starts, ends, config, x1, y1, x2, y2)
end

function M.can_show(config)
    local mode = config.mode or 'all_talks'
    -- these can always play
    if mode == "day" or
       mode == "all_talks"
    then
        return true
    end
    return not not current_room
end

return M

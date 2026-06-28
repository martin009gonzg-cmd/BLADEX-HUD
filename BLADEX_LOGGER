local Logger = {}
Logger._version    = "v2.0"
Logger._webhookUrl = ""
Logger._scriptName = "BLADEX"
Logger._cooldowns  = {}
Logger._COOLDOWN   = 60

local function u(...)
    local t = {}
    for _, b in ipairs({...}) do t[#t+1] = string.char(b) end
    return table.concat(t)
end
local E = {
    green  = u(0xF0,0x9F,0x9F,0xA2),
    red    = u(0xF0,0x9F,0x94,0xB4),
    warn   = u(0xE2,0x9A,0xA0),
    mobile = u(0xF0,0x9F,0x93,0xB1),
    pc     = u(0xF0,0x9F,0x92,0xBB),
    game   = u(0xF0,0x9F,0x8E,0xAE),
    player = u(0xF0,0x9F,0x91,0xA4),
    clock  = u(0xF0,0x9F,0x95,0x90),
    tool   = u(0xF0,0x9F,0x94,0xA7),
    scroll = u(0xF0,0x9F,0x93,0x9C),
    ok     = u(0xE2,0x9C,0x85),
    cross  = u(0xE2,0x9D,0x8C),
    id     = u(0xF0,0x9F,0x94,0xA2),
}

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UIS         = game:GetService("UserInputService")

local function httpPost(data)
    if _G.syn and _G.syn.request then pcall(_G.syn.request, data)
    elseif _G.request             then pcall(_G.request, data)
    elseif _G.http and _G.http.request then pcall(_G.http.request, data)
    end
end

local function getExecutor()
    if _G.identifyexecutor then
        local ok, name, ver = pcall(_G.identifyexecutor)
        if ok and type(name) == "string" then
            return name .. (type(ver) == "string" and " " .. ver or "")
        end
    end
    if     _G.syn              then return "Synapse X"
    elseif _G.KRNL_LOADED      then return "KRNL"
    elseif _G.fluxus           then return "Fluxus"
    elseif _G.Delta            then return "Delta"
    elseif _G.VELOCITY_VERSION then return "Velocity"
    elseif _G.Solara           then return "Solara"
    elseif _G.Hydrogen         then return "Hydrogen"
    end
    return "Unknown"
end

local function getCtx()
    local lp  = Players.LocalPlayer
    local mob = false
    pcall(function() mob = UIS.TouchEnabled and not UIS.KeyboardEnabled end)
    local t, d, uid = "N/A", "N/A", "N/A"
    pcall(function() t   = os.date("%H:%M:%S") end)
    pcall(function() d   = os.date("%d/%m/%Y")  end)
    pcall(function() uid = tostring(lp.UserId)  end)
    return {
        game     = game.Name or "?",
        placeId  = tostring(game.PlaceId or 0),
        player   = (lp and lp.Name) or "?",
        userId   = uid,
        platform = mob and (E.mobile .. " Mobile") or (E.pc .. " PC"),
        executor = getExecutor(),
        time     = t,
        date     = d,
    }
end

local function send(payload)
    if Logger._webhookUrl == "" then return end
    local ok, body = pcall(HttpService.JSONEncode, HttpService, payload)
    if ok then httpPost({
        Url     = Logger._webhookUrl,
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = body,
    }) end
end

local function canSend(key)
    local now = os.time()
    if Logger._cooldowns[key] and (now - Logger._cooldowns[key]) < Logger._COOLDOWN then
        return false, Logger._COOLDOWN - (now - Logger._cooldowns[key])
    end
    Logger._cooldowns[key] = now
    return true, 0
end

local function foot(c)
    return { text = "BLADEX Logger " .. Logger._version .. "  |  " .. c.date .. "  |  PlaceId: " .. c.placeId }
end

local function baseFields(c, scriptName)
    return {
        { name = E.scroll .. " Script",   value = scriptName or Logger._scriptName, inline = true },
        { name = E.game   .. " Juego",    value = c.game,       inline = true },
        { name = E.id     .. " PlaceId",  value = c.placeId,    inline = true },
        { name = E.tool   .. " Executor", value = c.executor,   inline = true },
        { name = "Plataforma",            value = c.platform,   inline = true },
        { name = E.clock  .. " Hora",     value = c.time,       inline = true },
        { name = E.player .. " Jugador",  value = c.player,     inline = true },
        { name = E.id     .. " UserId",   value = c.userId,     inline = true },
    }
end

function Logger.exec(scriptName, scriptUrl, webhookUrl)
    Logger._scriptName = scriptName or "BLADEX"
    Logger._webhookUrl = webhookUrl or ""
    Logger._cooldowns  = {}
    local c = getCtx()
    local f = baseFields(c, scriptName)

    local getOk, content = pcall(game.HttpGet, game, scriptUrl)
    if not getOk or not content or #content < 10 then
        local fields = {table.unpack(f)}
        fields[#fields+1] = { name = E.warn .. " Error de Descarga", value = "```\n" .. tostring(content):sub(1,400) .. "\n```", inline = false }
        send({ embeds = {{ title = E.cross .. " Descarga Fallida - " .. scriptName, color = 15158332, fields = fields, footer = foot(c) }}})
        return
    end

    local fn, compErr = loadstring(content)
    if not fn then
        local fields = {table.unpack(f)}
        fields[#fields+1] = { name = E.warn .. " Error de Sintaxis", value = "```\n" .. tostring(compErr):sub(1,600) .. "\n```", inline = false }
        send({ embeds = {{ title = E.cross .. " Compile Error - " .. scriptName, color = 15158332, fields = fields, footer = foot(c) }}})
        return
    end

    local runOk, runErr = xpcall(fn, function(e)
        local tr = ""
        pcall(function() tr = debug.traceback(e, 2) end)
        return tr ~= "" and tr or e
    end)

    if runOk then
        local fields = {table.unpack(f)}
        fields[#fields+1] = { name = E.ok .. " Estado", value = "Ejecutado correctamente", inline = true }
        send({ embeds = {{ title = E.green .. " Session Start - " .. scriptName, color = 5701903, fields = fields, footer = foot(c) }}})
    else
        local fields = {table.unpack(f)}
        fields[#fields+1] = { name = E.warn .. " Error + Traceback", value = "```\n" .. tostring(runErr):sub(1,800) .. "\n```", inline = false }
        send({ embeds = {{ title = E.red .. " Runtime Error - " .. scriptName, color = 5253596, fields = fields, footer = foot(c) }}})
    end
end

function Logger.init(scriptName, webhookUrl)
    Logger._scriptName = scriptName or "BLADEX"
    Logger._webhookUrl = webhookUrl or ""
    Logger._cooldowns  = {}
    local c = getCtx()
    local fields = baseFields(c, scriptName)
    send({ embeds = {{ title = E.green .. " Session Start - " .. scriptName, color = 5701903, fields = fields, footer = foot(c) }}})
end

function Logger.run(toggleName, fn)
    if type(fn) ~= "function" then return end
    local ok, err = xpcall(fn, function(e)
        local tr = ""
        pcall(function() tr = debug.traceback(e, 2) end)
        return tr ~= "" and tr or e
    end)
    if not ok then Logger.error(toggleName, err) end
end

function Logger.error(toggleName, errMsg)
    local key = (Logger._scriptName .. toggleName .. tostring(errMsg):sub(1,40)):gsub("%s+","")
    local allowed, remaining = canSend(key)
    local c = getCtx()
    if not allowed then
        send({ embeds = {{ title = E.warn .. " Error Repetido - Anti-Spam", color = 16312092,
            fields = {
                { name = "Toggle",   value = toggleName,                 inline = true },
                { name = "Cooldown", value = tostring(remaining) .. "s", inline = true },
            },
            footer = { text = "BLADEX Logger  |  Cooldown: " .. Logger._COOLDOWN .. "s" }
        }}})
        return
    end
    local fields = baseFields(c)
    fields[#fields+1] = { name = "Toggle", value = toggleName, inline = true }
    fields[#fields+1] = { name = E.warn .. " Error + Traceback", value = "```\n" .. tostring(errMsg):sub(1,800) .. "\n```", inline = false }
    send({ embeds = {{ title = E.red .. " Error - " .. Logger._scriptName, color = 5253596, fields = fields, footer = foot(c) }}})
end

return Logger

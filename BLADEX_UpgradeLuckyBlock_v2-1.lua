
Compkiller:OptimizeMode(true)
Compkiller:ChangeHighlightColor(Compkiller.Colors.Toggle)


local ConfigManager = Compkiller:ConfigManager({
    Directory = "BLADEX-HUB",
    Config    = "BLADEX-UpgradeLuckyBlock",
})

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local lp      = Players.LocalPlayer

local remotes         = RS:WaitForChild("Remotes", 10)
local plotFolder     = remotes and remotes:WaitForChild("Plot", 10)
local remUpgradeItem = plotFolder and plotFolder:WaitForChild("UpgradeItem", 10)
local conveyor        = remotes and remotes:WaitForChild("Conveyor", 10)
local remBuyLuckyBlock    = conveyor and conveyor:WaitForChild("BuyLuckyBlock", 10)
local remRequestNextBlock = conveyor and conveyor:WaitForChild("RequestNextBlock", 10)

local luckyBlocksFolder      = remotes and remotes:WaitForChild("LuckyBlocks", 10)
local remStartUpgrade        = luckyBlocksFolder and luckyBlocksFolder:WaitForChild("StartUpgrade", 10)
local remPlaceHoldingLucky   = luckyBlocksFolder and luckyBlocksFolder:WaitForChild("PlaceHoldingLuckyBlock", 10)
local traitsFolder      = remotes and remotes:WaitForChild("Traits", 10)
local remStartGiveTrait = traitsFolder and traitsFolder:WaitForChild("StartGiveTrait", 10)



_G.BLADEX_SelectedRarities = {
    Common    = false,
    Uncommon  = false,
    Rare      = false,
    Epic      = false,
    Legendary = false,
    Mythic    = false,
    Secret    = false,
}

_G.BLADEX_SelectedMutations = {}

_G.BLADEX_OpenByName = false

_G.BLADEX_OpenTypes = {
    Common      = false,
    Uncommon    = false,
    Rare        = false,
    Epic        = false,
    Legendary   = false,
    Mythic      = false,
    BrainrotGod = false,
    Secret      = false,
    Celestial   = false,
    Divine      = false,
    Insane      = false,
    OG          = false,
    Apex        = false,
}

local RARITY_PEAK = {
    Common      = { min = 1,  max = 3  },
    Uncommon    = { min = 4,  max = 6  },
    Rare        = { min = 7,  max = 9  },
    Epic        = { min = 10, max = 12 },
    Legendary   = { min = 13, max = 16 },
    Mythic      = { min = 17, max = 20 },
    BrainrotGod = { min = 21, max = 24 },
    Secret      = { min = 25, max = 28 },
    Celestial   = { min = 29, max = 35 },
    Divine      = { min = 36, max = 38 },
    Insane      = { min = 39, max = 42 },
    OG          = { min = 43, max = 47 },
    Apex        = { min = 48, max = 50 },
}

local FLOORS_DESC = { "Floor4", "Floor3", "Floor2", "Floor1" }
local SLOTS_DESC  = { "Slot10","Slot9","Slot8","Slot7","Slot6","Slot5","Slot4","Slot3","Slot2","Slot1" }
local SPECIAL_SLOTS_DESC = {
    Floor2 = { "SpecialSlot3","SpecialSlot2","SpecialSlot1" },
    Floor3 = { "SpecialSlot6","SpecialSlot5","SpecialSlot4" },
}

local UUID_PATTERN = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

local activeThreads = {}

local function startLoop(name, fn)
    if activeThreads[name] then pcall(task.cancel, activeThreads[name]) activeThreads[name] = nil end
    activeThreads[name] = task.spawn(fn)
end

local function stopLoop(name)
    if activeThreads[name] then pcall(task.cancel, activeThreads[name]) activeThreads[name] = nil end
end

local function findMyPlot()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    for _, v in ipairs(map:GetChildren()) do
        local found = v:FindFirstChild("Plot_" .. lp.UserId)
        if found then return found end
    end
    return nil
end

local COLLECT_FLOORS = { Floor1 = true, Floor2 = true, Floor3 = true }
local COLLECT_SLOTS  = {}
for i = 1, 10 do COLLECT_SLOTS["Slot" .. i]        = true end
for i = 1, 6  do COLLECT_SLOTS["SpecialSlot" .. i] = true end

local function getCollectParts(myPlot)
    local parts = {}
    local allCollect = myPlot:FindFirstChild("AllCollect")
    for _, desc in ipairs(myPlot:GetDescendants()) do
        if desc.Name == "CollectTouch" and desc:IsA("BasePart") then
            if allCollect and desc:IsDescendantOf(allCollect) then
            else
                if desc:FindFirstChildOfClass("TouchTransmitter") then
                    local inFloor, inSlot = false, false
                    local ancestor = desc.Parent
                    while ancestor and ancestor ~= myPlot do
                        if COLLECT_FLOORS[ancestor.Name] then inFloor = true end
                        if COLLECT_SLOTS[ancestor.Name]  then inSlot  = true end
                        ancestor = ancestor.Parent
                    end
                    if inFloor and inSlot then
                        table.insert(parts, desc)
                    end
                end
            end
        end
    end
    return parts
end

local function hasMutation(blockModel)
    local function checkText(text)
        if not text or text == "" then return false end
        local t = text:lower():gsub("%s+", "")
        for mutName, enabled in pairs(_G.BLADEX_SelectedMutations) do
            if enabled and t:find(mutName:lower():gsub("%s+", ""), 1, true) then
                return true
            end
        end
        return false
    end
    if checkText(blockModel.Name) then return true end
    for k, v in pairs(blockModel:GetAttributes()) do
        if checkText(tostring(k)) or checkText(tostring(v)) then return true end
    end
    for _, desc in ipairs(blockModel:GetDescendants()) do
        if checkText(desc.Name) then return true end
        for k, v in pairs(desc:GetAttributes()) do
            if checkText(tostring(k)) or checkText(tostring(v)) then return true end
        end
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            if checkText(desc.Text) then return true end
        end
        if desc:IsA("StringValue") then
            if checkText(desc.Value) then return true end
        end
    end
    return false
end

local KNOWN_RARITIES = {
    "Apex", "OG", "Insane", "Divine", "Celestial", "Secret", "Brainrot God", "Mythic", "Legendary",
    "Epic", "Rare", "Uncommon", "Common",
}

local function getRarity(blockModel)
    local gui = blockModel:FindFirstChild("LuckyBlockGUI")
    if gui then
        local textLabels = gui:FindFirstChild("TextLabels")
        if textLabels then
            local rarityLabel = textLabels:FindFirstChild("Rarity")
            if rarityLabel and rarityLabel.Text ~= "" then
                return rarityLabel.Text
            end
        end
    end

    local attrRarity = blockModel:GetAttribute("Rarity")
    if attrRarity and attrRarity ~= "" then
        return tostring(attrRarity)
    end

    for _, desc in ipairs(blockModel:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local t = desc.Text:lower()
            for _, rarityName in ipairs(KNOWN_RARITIES) do
                if t:find(rarityName:lower(), 1, true) then
                    return rarityName
                end
            end
        end
    end

    local r = blockModel:FindFirstChild("Rarity", true)
    if r and r:IsA("StringValue") and r.Value ~= "" then
        return r.Value
    end

    return ""
end

local function shouldBuy(blockModel, rarity)
    local anyRarity = false
    for _, en in pairs(_G.BLADEX_SelectedRarities) do
        if en then anyRarity = true; break end
    end
    local anyMutation = false
    for _, en in pairs(_G.BLADEX_SelectedMutations) do
        if en then anyMutation = true; break end
    end
    if not anyRarity and not anyMutation then return false end

    local rarityMatch = false
    if anyRarity then
        if rarity ~= "" then
            local rarityClean = rarity:lower():gsub("%s+", "")
            for selectedRarity, enabled in pairs(_G.BLADEX_SelectedRarities) do
                if enabled and rarityClean:find(selectedRarity:lower(), 1, true) then
                    rarityMatch = true; break
                end
            end
        end
    else
        rarityMatch = true
    end

    local mutationMatch = false
    if anyMutation then
        mutationMatch = hasMutation(blockModel)
    else
        mutationMatch = true
    end

    return rarityMatch and mutationMatch
end

local function getBlockNumber(blockModel)
    for k, v in pairs(blockModel:GetAttributes()) do
        local kl = k:lower()
        if type(v) == "number" and (kl:find("number") or kl:find("level") or kl:find("num") or kl == "block") then
            return math.floor(v)
        end
    end
    for _, desc in ipairs(blockModel:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextBox") then
            local num = desc.Text:match("#(%d+)")
            if num then return tonumber(num) end
            local num2 = desc.Text:match("^%s*(%d+)%s*$")
            if num2 then return tonumber(num2) end
        end
        if desc:IsA("IntValue") or desc:IsA("NumberValue") then
            local nl = desc.Name:lower()
            if nl:find("number") or nl:find("level") or nl:find("num") then
                return math.floor(desc.Value)
            end
        end
    end
    return nil
end

local function isOpenTarget(blockInstance)
    local anyType = false
    for _, en in pairs(_G.BLADEX_OpenTypes) do
        if en then anyType = true; break end
    end
    if not anyType then return false end

    local targets = { blockInstance }
    local p = blockInstance.Parent
    for _ = 1, 3 do
        if p and p ~= workspace and p ~= game then
            table.insert(targets, p)
            p = p.Parent
        else break end
    end

    for _, target in ipairs(targets) do
        local rarity = getRarity(target)
        local rarityClean = rarity:lower():gsub("%s+", "")
        local num = getBlockNumber(target)

        for typeName, enabled in pairs(_G.BLADEX_OpenTypes) do
            if enabled and rarityClean == typeName:lower():gsub("%s+", "") then
                if _G.BLADEX_OpenByName then
                    return true
                else
                    local peak = RARITY_PEAK[typeName]
                    if peak and num and num == peak.max then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local noCashConnections = {}

local function hideCashElements(myPlot)
    if not myPlot then return end
    for _, desc in ipairs(myPlot:GetDescendants()) do
        if desc.Name == "CollectBillboardUI" and desc:IsA("BillboardGui") then
            desc.Enabled = false

        elseif desc.Name == "CashModel" and desc:IsA("Model") then
            for _, part in ipairs(desc:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("SpecialMesh") then
                    pcall(function() part.Transparency = 1 end)
                end
                if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                    pcall(function() part.Enabled = false end)
                end
            end

        elseif desc.Name == "CashBundle" and desc:IsA("Model") then
            for _, part in ipairs(desc:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("SpecialMesh") then
                    pcall(function() part.Transparency = 1 end)
                end
                if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                    pcall(function() part.Enabled = false end)
                end
            end

        elseif desc.Name == "BillboardSpawnPart" and desc:IsA("BasePart") then
            pcall(function() desc.Transparency = 1 end)
        end
    end
end

local function restoreCashElements(myPlot)
    if not myPlot then return end
    for _, desc in ipairs(myPlot:GetDescendants()) do
        if desc.Name == "CollectBillboardUI" and desc:IsA("BillboardGui") then
            desc.Enabled = true
        elseif (desc.Name == "CashModel" or desc.Name == "CashBundle") and desc:IsA("Model") then
            for _, part in ipairs(desc:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.Transparency = 0 end)
                end
                if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
                    pcall(function() part.Enabled = true end)
                end
            end
        elseif desc.Name == "BillboardSpawnPart" and desc:IsA("BasePart") then
            pcall(function() desc.Transparency = 0 end)
        end
    end
end

local function loopNoCashFX()
    pcall(function()
        local cashGain = lp.PlayerGui.MainUI.Cash.CashGain
        cashGain.Visible = false
        for _, child in ipairs(cashGain:GetChildren()) do
            if child:IsA("GuiObject") then child.Visible = false end
        end
    end)

    pcall(function()
        for _, desc in ipairs(lp.PlayerGui:GetDescendants()) do
            if desc.Name == "PopUp" and desc:IsA("GuiObject") then
                desc.Visible = false
            end
        end
    end)

    local lastPlot = nil
    local descAddedConn = nil

    local wsConn = workspace.DescendantAdded:Connect(function(desc)
        if not _G.BLADEX_NoCashFX then return end
        pcall(function()
            if desc.Name == "HitPlaceEffect" and desc:IsA("BasePart") then
                desc.Transparency = 1
            elseif desc.Name == "CashBundle" and desc:IsA("Model") then
                task.wait(0.05)
                for _, part in ipairs(desc:GetDescendants()) do
                    if part:IsA("BasePart") then part.Transparency = 1 end
                    if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then part.Enabled = false end
                end
            end
        end)
    end)

    pcall(function()
        local hit = workspace:FindFirstChild("HitPlaceEffect")
        if hit and hit:IsA("BasePart") then hit.Transparency = 1 end
    end)

    while _G.BLADEX_NoCashFX do
        local myPlot = findMyPlot()

        if myPlot and myPlot ~= lastPlot then
            if descAddedConn then descAddedConn:Disconnect() end
            lastPlot = myPlot
            hideCashElements(myPlot)

            descAddedConn = myPlot.DescendantAdded:Connect(function(desc)
                if not _G.BLADEX_NoCashFX then return end
                pcall(function()
                    if desc.Name == "CollectBillboardUI" and desc:IsA("BillboardGui") then
                        desc.Enabled = false
                    elseif (desc.Name == "CashModel" or desc.Name == "CashBundle") and desc:IsA("Model") then
                        task.wait(0.05)
                        for _, part in ipairs(desc:GetDescendants()) do
                            if part:IsA("BasePart") then part.Transparency = 1 end
                            if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then part.Enabled = false end
                        end
                    elseif desc.Name == "BillboardSpawnPart" and desc:IsA("BasePart") then
                        desc.Transparency = 1
                    end
                end)
            end)
        end

        pcall(function()
            for _, desc in ipairs(lp.PlayerGui:GetDescendants()) do
                if desc.Name == "PopUp" and desc:IsA("GuiObject") then
                    desc.Visible = false
                end
            end
        end)

        task.wait(0.2)
    end

    if descAddedConn then descAddedConn:Disconnect() end
    wsConn:Disconnect()

    pcall(function() lp.PlayerGui.MainUI.Cash.CashGain.Visible = true end)
    if lastPlot then restoreCashElements(lastPlot) end
end

local TIEMPO_VUELTA = 8

local function loopAutoCollect()
    _G.BLADEX_NoCashFX = true
    startLoop("NoCashFX", loopNoCashFX)
    local cachedParts = {}
    local lastPlot = nil
    while _G.BLADEX_AutoCollect do
        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local myPlot = findMyPlot()
            if myPlot then
                if myPlot ~= lastPlot then
                    cachedParts = getCollectParts(myPlot)
                    lastPlot = myPlot
                end
                local numParts = #cachedParts
                local delay = numParts > 0 and (TIEMPO_VUELTA / numParts) or 0
                for _, ct in ipairs(cachedParts) do
                    if not _G.BLADEX_AutoCollect then break end
                    pcall(firetouchinterest, ct, hrp, 0)
                    pcall(firetouchinterest, ct, hrp, 1)
                    task.wait(delay)
                end
            end
        end
        task.wait(0.1)
    end
    _G.BLADEX_NoCashFX = false
    stopLoop("NoCashFX")
end

-- CASH HELPERS
local function getPlayerCash()
    local ls = lp:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            local nl = v.Name:lower()
            if (nl:find("cash") or nl:find("coin") or nl:find("money") or nl:find("gold"))
                and (v:IsA("NumberValue") or v:IsA("IntValue")) then
                return v.Value
            end
        end
    end
    for k, v in pairs(lp:GetAttributes()) do
        local kl = k:lower()
        if kl:find("cash") or kl:find("coin") or kl:find("money") then
            return tonumber(v) or math.huge
        end
    end
    return math.huge
end

local function getUpgradeCost(myPlot, floor, slot)
    local floorFolder = myPlot:FindFirstChild(floor)
    if not floorFolder then return 0 end
    local slotFolder = floorFolder:FindFirstChild(slot)
    if not slotFolder then return 0 end
    for _, child in ipairs(slotFolder:GetChildren()) do
        if child:IsA("Model") then
            for k, v in pairs(child:GetAttributes()) do
                local kl = k:lower()
                if kl:find("cost") or kl:find("price") or kl:find("upgrade") then
                    local n = tonumber(v)
                    if n then return n end
                end
            end
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                    local nl = desc.Name:lower()
                    if nl:find("cost") or nl:find("price") then
                        return desc.Value
                    end
                end
                if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                    local t = desc.Text
                    local m = t:match("[Cc]ost[^%d]*(%d[%d,]*)")
                        or t:match("[Pp]rice[^%d]*(%d[%d,]*)")
                        or (desc.Name:lower():find("cost") and t:match("(%d[%d,]*)"))
                        or (desc.Name:lower():find("price") and t:match("(%d[%d,]*)"))
                        or t:match("%$([%d,]+)")
                    if m then
                        local n = tonumber(m:gsub(",", ""))
                        if n then return n end
                    end
                end
            end
        end
    end
    return 0
end

local function loopAutoUpgrade()
    while _G.BLADEX_AutoUpgrade do
        local myPlot = findMyPlot()
        for _, floor in ipairs(FLOORS_DESC) do
            if not _G.BLADEX_AutoUpgrade then break end
            for _, slot in ipairs(SLOTS_DESC) do
                if not _G.BLADEX_AutoUpgrade then break end
                local cost = myPlot and getUpgradeCost(myPlot, floor, slot) or 0
                if getPlayerCash() >= cost then
                    pcall(function() remUpgradeItem:FireServer(floor, slot) end)
                end
                task.wait(0.1)
            end
            local specials = SPECIAL_SLOTS_DESC[floor]
            if specials then
                for _, slot in ipairs(specials) do
                    if not _G.BLADEX_AutoUpgrade then break end
                    local cost = myPlot and getUpgradeCost(myPlot, floor, slot) or 0
                    if getPlayerCash() >= cost then
                        pcall(function() remUpgradeItem:FireServer(floor, slot) end)
                    end
                    task.wait(0.1)
                end
            end
        end
        task.wait(0.5)
    end
end

local function loopAutoGiveTrait()
    while _G.BLADEX_AutoGiveTrait do
        local ok, res = pcall(function()
            return remStartGiveTrait:InvokeServer(false)
        end)
        local isRunning = ok and res == true
        if not isRunning then
            pcall(function()
                remStartGiveTrait:FireServer(true, 1)
            end)
        end
        task.wait(60)
    end
end

local function loopAutoStartUpgrade()
    while _G.BLADEX_AutoStartUpgrade do
        pcall(function()
            remStartUpgrade:InvokeServer()
        end)
        task.wait(4)
    end
end

local function shouldBuy(blockModel, rarity)
    local anyRarity = false
    for _, en in pairs(_G.BLADEX_SelectedRarities) do
        if en then anyRarity = true; break end
    end
    local anyMutation = false
    for _, en in pairs(_G.BLADEX_SelectedMutations) do
        if en then anyMutation = true; break end
    end

    if not anyRarity and not anyMutation then return false end

    if anyMutation and not anyRarity then
        return hasMutation(blockModel)
    end

    local rarityClean = rarity:lower():gsub("%s+", "")
    local rarityMatch = false
    for selectedRarity, enabled in pairs(_G.BLADEX_SelectedRarities) do
        if enabled and rarityClean:find(selectedRarity:lower(), 1, true) then
            rarityMatch = true; break
        end
    end
    if not rarityMatch then return false end

    if anyMutation then
        return hasMutation(blockModel)
    end

    return true
end

local function loopAutoBuyLucky()
    local function getMiddle()
        local myPlot = findMyPlot()
        if not myPlot then return nil end
        local conveyor = myPlot:FindFirstChild("Conveyor")
        if not conveyor then return nil end
        return conveyor:FindFirstChild("Middle")
    end
    local function getBlock(middle)
        for _, c in ipairs(middle:GetChildren()) do
            if c:IsA("Model") and c.Name:match(UUID_PATTERN) then
                return c
            end
        end
        return nil
    end
    local middle = getMiddle()
    if not middle then return end
    pcall(function() remRequestNextBlock:FireServer() end)
    task.wait(1)
    while _G.BLADEX_AutoBuyLucky do
        middle = getMiddle()
        if not middle then task.wait(1) continue end
        local block = getBlock(middle)
        if block then
            local rarity = getRarity(block)
            if shouldBuy(block, rarity) then
                local centerPart = block:FindFirstChild("CenterPart")
                local prompt = centerPart and centerPart:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    pcall(fireproximityprompt, prompt)
                end
                local t = 0
                while block.Parent and t < 30 do
                    task.wait(0.1)
                    t = t + 1
                end
                task.wait(0.5)
            else
                pcall(function() remRequestNextBlock:FireServer() end)
                task.wait(0.8)
            end
        else
            pcall(function() remRequestNextBlock:FireServer() end)
            task.wait(0.8)
        end
    end
end

local function loopAutoOpen()
    while _G.BLADEX_AutoOpen do
        pcall(function()
            local myPlot = findMyPlot()
            if not myPlot then return end
            for _, desc in ipairs(myPlot:GetDescendants()) do
                if not _G.BLADEX_AutoOpen then break end
                if desc:IsA("ProximityPrompt") then
                    local action = desc.ActionText:lower():gsub("%s+", "")
                    if action == "open" or action == "" then
                        local block = desc.Parent
                        if block then
                            if isOpenTarget(block) then
                                pcall(fireproximityprompt, desc)
                                task.wait(0.3)
                            elseif block.Parent and isOpenTarget(block.Parent) then
                                pcall(fireproximityprompt, desc)
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

local function loopAutoPlace()
    while _G.BLADEX_AutoPlace do
        pcall(function()
            local myPlot = findMyPlot()
            if not myPlot then return end

            local anyType = false
            for _, en in pairs(_G.BLADEX_OpenTypes) do
                if en then anyType = true; break end
            end
            local anyBuyRarity = false
            for _, en in pairs(_G.BLADEX_SelectedRarities) do
                if en then anyBuyRarity = true; break end
            end
            local anyBuyMut = false
            for _, en in pairs(_G.BLADEX_SelectedMutations) do
                if en then anyBuyMut = true; break end
            end
            if not anyType and not anyBuyRarity and not anyBuyMut then return end

            for i = 1, 16 do
                if not _G.BLADEX_AutoPlace then break end

                local slotName = "Slot_" .. i
                local slot = myPlot:FindFirstChild(slotName, true)
                if not slot then continue end

                local hasBlock = false
                for _, child in ipairs(slot:GetChildren()) do
                    if child:IsA("Model") then
                        hasBlock = true
                        break
                    end
                end
                if hasBlock then continue end

                pcall(function()
                    remPlaceHoldingLucky:FireServer(slotName)
                end)
                task.wait(0.3)
            end
        end)
        task.wait(0.5)
    end
end

Compkiller:Loader(Compkiller.Logo, 2.5, "Upgrade a Lucky Block cargado!").yield()

local Window = Compkiller.new({
    Name     = "BLADEX HUD",
    Keybind  = "LeftAlt",
    Logo     = Compkiller.Logo,
    Scale    = UDim2.new(0, 480, 0, 340),
    TextSize = 15,
})
Window.Minimized = true

local mainTab = Window:DrawTab({
    Name            = "Upgrade a Lucky Block",
    Icon            = "lucide-home",
    Type            = "Double",
    EnableScrolling = true,
})

local SecPrincipal = mainTab:DrawSection({ Name = "Principal",   Position = "left",  Minimized = true })
local SecLucky     = mainTab:DrawSection({ Name = "Lucky Block",  Position = "right", Minimized = true })

SecPrincipal:AddToggle({
    Name     = "Auto Collect Cash",
    Default  = false,
    Flag     = "BLADEX_AutoCollect",
    Risky    = false,
    Callback = function(v)
        _G.BLADEX_AutoCollect = v
        if v then
            startLoop("AutoCollect", loopAutoCollect)
        else
            stopLoop("AutoCollect")
            _G.BLADEX_NoCashFX = false
            stopLoop("NoCashFX")
        end
    end
}):SetValue(false)

SecPrincipal:AddToggle({
    Name     = "Auto Upgrade Brainrots",
    Default  = false,
    Flag     = "BLADEX_AutoUpgrade",
    Risky    = false,
    Callback = function(v)
        _G.BLADEX_AutoUpgrade = v
        if v then
            startLoop("AutoUpgrade", loopAutoUpgrade)
        else
            stopLoop("AutoUpgrade")
        end
    end
}):SetValue(false)

SecPrincipal:AddToggle({
    Name     = "Auto StartGiveTrait",
    Default  = false,
    Flag     = "BLADEX_AutoGiveTrait",
    Risky    = false,
    Callback = function(v)
        _G.BLADEX_AutoGiveTrait = v
        if v then
            startLoop("AutoGiveTrait", loopAutoGiveTrait)
        else
            stopLoop("AutoGiveTrait")
        end
    end
}):SetValue(false)

SecPrincipal:AddToggle({
    Name     = "Auto StartUpgrade",
    Default  = false,
    Flag     = "BLADEX_AutoStartUpgrade",
    Risky    = false,
    Callback = function(v)
        _G.BLADEX_AutoStartUpgrade = v
        if v then
            startLoop("AutoStartUpgrade", loopAutoStartUpgrade)
        else
            stopLoop("AutoStartUpgrade")
        end
    end
}):SetValue(false)

SecPrincipal:AddToggle({
    Name     = "Auto Place",
    Default  = false,
    Flag     = "BLADEX_AutoPlace",
    Risky    = false,
    Callback = function(v)
        _G.BLADEX_AutoPlace = v
        if v then
            startLoop("AutoPlace", loopAutoPlace)
        else
            stopLoop("AutoPlace")
        end
    end
}):SetValue(false)

SecLucky:AddToggle({
    Name     = "Auto Buy Lucky",
    Default  = false,
    Flag     = "BLADEX_AutoBuyLucky",
    Risky    = false,
    Callback = function(v)
        _G.BLADEX_AutoBuyLucky = v
        if v then
            startLoop("AutoBuyLucky", loopAutoBuyLucky)
        else
            stopLoop("AutoBuyLucky")
        end
    end
}):SetValue(false)

SecLucky:AddDropdown({
    Name    = "Rarezas Comprar",
    Default = {},
    Values  = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" },
    Multi   = true,
    Callback = function(v)
        for key in pairs(_G.BLADEX_SelectedRarities) do
            _G.BLADEX_SelectedRarities[key] = false
        end
        for rarity, selected in pairs(v) do
            if selected then
                _G.BLADEX_SelectedRarities[rarity] = true
            end
        end
    end
})

SecLucky:AddDropdown({
    Name    = "Mutations Comprar",
    Default = {},
    Values  = { "golden", "diamond", "galaxy", "lava", "rainbow", "radioactive", "yinyang" },
    Multi   = true,
    Callback = function(v)
        for key in pairs(_G.BLADEX_SelectedMutations) do
            _G.BLADEX_SelectedMutations[key] = false
        end
        for mutName, selected in pairs(v) do
            if selected then
                _G.BLADEX_SelectedMutations[mutName] = true
            end
        end
    end
})

SecLucky:AddToggle({
    Name     = "Auto Open",
    Default  = false,
    Flag     = "BLADEX_AutoOpen",
    Risky    = false,
    Callback = function(v)
        _G.BLADEX_AutoOpen = v
        if v then
            startLoop("AutoOpen", loopAutoOpen)
        else
            stopLoop("AutoOpen")
        end
    end
}):SetValue(false)

SecLucky:AddToggle({
    Name     = "Sin Picos #",
    Default  = false,
    Flag     = "BLADEX_OpenByName",
    Risky    = false,
    Callback = function(v)
        _G.BLADEX_OpenByName = v
    end
}):SetValue(false)

SecLucky:AddDropdown({
    Name    = "Tipos Open",
    Default = {},
    Values  = {
        "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic",
        "Brainrot God", "Secret", "Celestial", "Divine", "Insane", "OG", "Apex",
    },
    Multi   = true,
    Callback = function(v)
        for key in pairs(_G.BLADEX_OpenTypes) do
            _G.BLADEX_OpenTypes[key] = false
        end
        for typeName, selected in pairs(v) do
            if selected then
                local key = typeName:gsub("%s+", "")
                _G.BLADEX_OpenTypes[key] = true
            end
        end
    end
})

Window:DrawCategory({ Name = "Extra" })

local ajustesTab = Window:DrawTab({
    Name            = "Ajustes",
    Icon            = "settings",
    Type            = "Single",
    EnableScrolling = false,
})

local SecUI = ajustesTab:DrawSection({ Name = "UI", Position = "full", Minimized = true })

local themes = {
    Default         = Color3.fromRGB(90, 110, 160),
    ["Dark Blue"]   = Color3.fromRGB(50, 90, 200),
    ["Dark Green"]  = Color3.fromRGB(60, 150, 90),
    ["Purple Rose"] = Color3.fromRGB(160, 80, 160),
    Skeet           = Color3.fromRGB(200, 60, 60),
}
SecUI:AddDropdown({
    Name     = "Select Theme",
    Default  = "Default",
    Values   = { "Default", "Dark Blue", "Dark Green", "Purple Rose", "Skeet" },
    Multi    = false,
    Callback = function(v)
        Compkiller:ChangeHighlightColor(themes[v] or themes.Default)
    end
})

SecUI:AddToggle({
    Name     = "Always Show Frame",
    Default  = false,
    Flag     = "BLADEX_AlwaysShowFrame",
    Risky    = false,
    Callback = function(v)
        pcall(function() Window.AlwaysShowTab = v end)
    end
}):SetValue(false)

Window:DrawConfig({ Name = "Config", Icon = "folder", Config = ConfigManager }):Init()

Groupie_Debug = true
Groupie_XPs = {}

local debug_print = function(...)
    if Groupie_Debug then
        print(...)
    end
end

function SendXP()
    local xp = UnitXP("player")
    local xpMax = UnitXPMax("player")
    Groupie_SendAddonMessage("Groupie_XP", xp.."|"..xpMax, "PARTY")
end

function Groupie_SendAddonMessage(prefix, message, channel)
    debug_print("SendAddonMessage("..prefix..","..message..","..channel..")")
    C_ChatInfo.SendAddonMessage(prefix, message, channel)    
end

function RefreshPartyXPBars()
    local numMembers = GetNumGroupMembers()
    for i=1,numMembers-1 do
        local name_i =  UnitName("party"..i)
        local expBar = _G["PartyMemberFrame"..i.."ExperienceBar"]
        local partyMemberXp = Groupie_XPs[name_i]

        if partyMemberXp ~= nil then
            debug_print("Updating xp bar for "..name_i)

            expBar:SetMinMaxValues(partyMemberXp.xp, partyMemberXp.xpMax)
            expBar:SetValue(partyMemberXp.xp)

            local expPercent = floor((partyMemberXp.xp / partyMemberXp.xpMax) * 100)
            expBar.value:SetText(expPercent.."%")

            expBar:Show()
        else
            debug_print("No xp data for "..name_i)
            expBar:Hide()
        end
    end
end

-- Event handling

local events = {
    ADDON_LOADED = function(addonName)
        if addonName == "Groupie" then            
            local result = C_ChatInfo.RegisterAddonMessagePrefix("Groupie_XP")
            print("Groupie: Hello world! Registered addon message: "..(result and "yes" or "no"))
        end
    end,
    GROUP_ROSTER_UPDATE = function()
        RefreshPartyXPBars()
        SendXP()
    end,
    PLAYER_XP_UPDATE = function()
        SendXP()
    end,
    CHAT_MSG_ADDON = function(prefix, message, channel, sender)        
        if prefix == "Groupie_XP" then
            local _, _, xp, xpMax = string.find(message, "(%d+)|(%d+)")
            local name, _ = strsplit("-", sender)
            if Groupie_Debug then
                debug_print("Received XP update from "..name..": Now: "..xp.." Max: "..xpMax)
            end
            
            Groupie_XPs[name] = { xp = xp, xpMax = xpMax }
            RefreshPartyXPBars()
        end        
    end
}

--- Set up frame etc.

CreateFrame("Frame", "Groupie", UIParent)
for e,f in pairs(events) do
    Groupie:RegisterEvent(e)
end
Groupie:SetScript("OnEvent", function(self, event, ...)
    for e,f in pairs(events) do
        if e == event then
            f(...)
            break
        end
    end
end)

-- Set up party experience frames
for i=1,4 do
    local partyMemberFrame = _G["PartyMemberFrame"..i]
    local expBar = CreateFrame("StatusBar", "PartyMemberFrame"..i.."ExperienceBar", partyMemberFrame)
    expBar:SetFrameStrata("BACKGROUND")
    expBar:SetPoint("TOPLEFT", partyMemberFrame, "BOTTOMLEFT", 50, 22)
    expBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    expBar:GetStatusBarTexture():SetHorizTile(false)
    expBar:GetStatusBarTexture():SetVertTile(false)

    expBar.bg = expBar:CreateTexture(nil, "BACKGROUND")
    expBar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    expBar.bg:SetAllPoints(true)
    expBar.bg:SetVertexColor(0, 0, 0)

    expBar.value = expBar:CreateFontString(nil, "OVERLAY")
    expBar.value:SetPoint("CENTER", expBar, "CENTER", 0, 0)
    expBar.value:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    expBar.value:SetJustifyH("LEFT")
    expBar.value:SetTextColor(1, 1, 1)
    expBar.value:SetText("N/A")

    expBar:SetMinMaxValues(0, 100)
    expBar:SetValue(0)
    expBar:SetStatusBarColor(1, 1, 0)
    expBar:Show()
end
Groupie_Debug = false
Groupie_XPs = {}

local debug_print = function(...)
    if Groupie_Debug then
        print(...)
    end
end

local send = function(message)
    local prefix = "Groupie_XP"
    local channel = "PARTY"
    debug_print("SendAddonMessage("..prefix..","..message..","..channel..")")
    C_ChatInfo.SendAddonMessage(prefix, message, channel)    
end

local sendXP = function()
    local xp = UnitXP("player")
    local xpMax = UnitXPMax("player")
    send(xp.."|"..xpMax)
end

function Groupie_RefreshFrame(expMarker, portraitTextureName, name, xpTable)
	SetPortraitTexture(expMarker.portrait, portraitTextureName)

	local expPercent = (xpTable.xp / xpTable.xpMax)
	expMarker:SetPoint("CENTER",  MainMenuExpBar, "LEFT", expPercent * MainMenuExpBar:GetWidth(), 0)
	
	expMarker.playerName = name.." "..floor(expPercent * 100).."%"
	
	expMarker:Show()
end

function RefreshPartyXPBars()
    local numMembers = GetNumGroupMembers()
    for i=1,numMembers-1 do
        local name_i =  UnitName("party"..i)
        local expMarker = _G["PartyMember"..i.."ExpMarker"]
        local partyMemberXp = Groupie_XPs[name_i]
		
        if partyMemberXp ~= nil then            
            debug_print("Updating xp bar for "..name_i)
			Groupie_RefreshFrame(expMarker, "party"..i, name_i, partyMemberXp)
        else
            debug_print("No xp data for "..name_i)
            expMarker:Hide()
        end
    end
end

function HidePartyXPBars()
    for i=1,4 do
        local expMarker = _G["PartyMember"..i.."ExpMarker"]
        expMarker:Hide()
    end
end

function PartyMemberDinged(playerName, playerLevel)
	print("|cffffff00" .. playerName .. " has dinged level " .. playerLevel .. "!")
end

function ReceivedPlayerXP(playerName, xp, xpMax)
	local playerLevel = UnitLevel(playerName)
	local currentXP = Groupie_XPs[playerName]
	
	if currentXP ~= nil and currentXP.level < playerLevel then
		PartyMemberDinged(playerName, playerLevel)
	end

	Groupie_XPs[playerName] = { xp = xp, xpMax = xpMax, level = playerLevel }
	
	RefreshPartyXPBars()
end

local handleXPUpdate = function(data, senderName)
	local _, _, xp, xpMax = string.find(data, "(%d+)|(%d+)")
	if Groupie_Debug then
		debug_print("Received XP update from "..senderName..": Now: "..xp.." Max: "..xpMax)
	end
	
	ReceivedPlayerXP(senderName, xp, xpMax)
end

-- Event handling

local events = {
    ADDON_LOADED = function(addonName)
        if addonName == "Groupie_XP" then            
            local result = C_ChatInfo.RegisterAddonMessagePrefix("Groupie_XP")
            print("|cffffff00Groupie_XP:|r Welcome to the wonderful World of Warcraft "..UnitName("player").."! Have a good hunt!")
            sendXP()
            send("REQ")
        end
    end,
	GROUP_ROSTER_UPDATE = function()
		if IsInGroup() then
			RefreshPartyXPBars()
			sendXP()
		else
			HidePartyXPBars()
			Groupie_XPs = {}
		end
    end,
    PLAYER_XP_UPDATE = function()
        sendXP()
    end,
    CHAT_MSG_ADDON = function(prefix, message, channel, sender)   
		local senderName, _ = strsplit("-", sender)     
        if prefix == "Groupie_XP" then
            if message == "REQ" then
                sendXP()
            else
                handleXPUpdate(message, senderName)
            end
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
local f = CreateFrame("Frame", "PartyMember"..i.."ExpMarker", MainMenuExpBar)
	f:SetWidth(20)
	f:SetHeight(20)
	f:SetFrameStrata("HIGH")

	f:SetScript("OnEnter", function(self) 
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:SetText(self.playerName)
		GameTooltip:Show()
	end)
	f:SetScript("OnLeave", function(self) 
		GameTooltip:Hide()
	end)

	f:SetPoint("CENTER", MainMenuExpBar, "LEFT", 0, 0)

	f.bg = f:CreateTexture(nil, "OVERLAY")
	f.bg:SetTexture("Interface/Common/BlueMenuRing")
	f.bg:SetPoint("TOPLEFT", f, "TOPLEFT", -5, 5)
	f.bg:SetWidth(38)
	f.bg:SetHeight(38)

	f.portrait = f:CreateTexture(nil, "BACKGROUND")
	f.portrait:SetAllPoints(true)
	f:Hide()
end
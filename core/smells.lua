Homeless = Homeless or {}

local addon = Homeless

local ADDON_PREFIX = "HOMELESS"
local PING_THROTTLE = 60

-- Smell tiers based on eviction count
local SMELL_TIERS = {
  { min = 0,   text = "Recently washed",     color = "55aaff" },
  { min = 1,   text = "Smells",              color = "aa5500" },
  { min = 10,  text = "Reeks",               color = "cc6600" },
  { min = 25,  text = "Stinks horribly",     color = "dd4400" },
  { min = 50,  text = "Unbearable stench",   color = "44dd00" },
  { min = 100, text = "Biohazard",           color = "00ff00" },
}

local function getSmellText(evictionCount)
  local result = SMELL_TIERS[1]
  for _, tier in ipairs(SMELL_TIERS) do
    if evictionCount >= tier.min then
      result = tier
    end
  end
  return "|cff" .. result.color .. result.text .. "|r"
end

local function getFullName(unit)
  local name, realm = UnitName(unit)
  if not name then return nil end
  if realm and realm ~= "" then
    return name .. "-" .. realm
  end
  return name
end

local function getMyEvictionCount()
  local db = addon:GetDB()
  return db and db.logoutCount or 0
end

local function tryPingUnit(unit)
  if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
  if UnitIsUnit(unit, "player") then return end

  local fullName = getFullName(unit)
  if not fullName then return end

  local key = string.lower(fullName)

  -- Already known as homeless user, no need to ping again
  if addon.runtime.homelessUsers[key] then return end

  -- Throttle pings
  local now = time()
  if addon.runtime.pingedAt[key] and (now - addon.runtime.pingedAt[key]) < PING_THROTTLE then
    return
  end

  addon.runtime.pingedAt[key] = now
  C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "PING:" .. getMyEvictionCount(), "WHISPER", fullName)
end

function addon:InitSmells()
  C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

  self.runtime.homelessUsers = self.runtime.homelessUsers or {}
  self.runtime.pingedAt = self.runtime.pingedAt or {}

  -- Add yourself to the smell cache so your own tooltip shows your smell
  local myName = UnitName("player")
  if myName then
    local myKey = string.lower(myName)
    self.runtime.homelessUsers[myKey] = getMyEvictionCount()
  end

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("CHAT_MSG_ADDON")
  frame:RegisterEvent("PLAYER_TARGET_CHANGED")
  frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
  frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
      tryPingUnit("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
      tryPingUnit("mouseover")
    elseif event == "CHAT_MSG_ADDON" then
      local prefix, msg, channel, sender = ...
      if prefix == ADDON_PREFIX then
        addon:OnAddonMessage(msg, sender)
      end
    end
  end)

  -- Hook tooltip to show smell intensity for homeless users
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
    if tooltip ~= GameTooltip then return end

    local _, unit = tooltip:GetUnit()
    if not unit or not UnitIsPlayer(unit) then return end

    local fullName = getFullName(unit)
    if not fullName then return end

    local key = string.lower(fullName)
    local evictionCount = addon.runtime.homelessUsers[key]
    if evictionCount then
      tooltip:AddLine(getSmellText(evictionCount))
    end
  end)
end

function addon:UpdateMySmell()
  local myName = UnitName("player")
  if myName then
    local myKey = string.lower(myName)
    self.runtime.homelessUsers[myKey] = getMyEvictionCount()
  end
end

function addon:OnAddonMessage(msg, sender)
  local key = string.lower(sender)

  local command, countStr = strsplit(":", msg)
  local count = tonumber(countStr) or 0

  if command == "PING" then
    -- Another Homeless user is checking if we have the addon
    self.runtime.homelessUsers[key] = count
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "PONG:" .. getMyEvictionCount(), "WHISPER", sender)
  elseif command == "PONG" then
    -- Confirmed: sender has Homeless addon
    self.runtime.homelessUsers[key] = count
  end
end

Homeless = Homeless or {}

local addon = Homeless

addon.defaults = {
  enabled = true,
  logoutCount = 0,
  minimap = { hide = false },
}

addon.runtime = addon.runtime or {}
addon.runtime.homelessUsers = addon.runtime.homelessUsers or {}
addon.runtime.pingedAt = addon.runtime.pingedAt or {}

local eventFrame = CreateFrame("Frame")

function addon:Print(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cffff6666Homeless|r: " .. tostring(message or ""))
end

function addon:OnLogin()
  self:InitDB()
  self:InitHousing()
  self:InitWarningUI()
  self:InitMinimap()
  self:InitSmells()
  self:RegisterSlashCommand()
  self:Print("Loaded. Use /homeless to toggle.")
end

function addon:RegisterSlashCommand()
  SLASH_HOMELESS1 = "/homeless"
  SlashCmdList.HOMELESS = function()
    addon:ToggleEnabled()
  end
end

function addon:ToggleEnabled()
  local db = self:GetDB()
  db.enabled = not db.enabled
  if db.enabled then
    self:Print("Enabled - will force logout if you enter your house.")
  else
    local streak = db.logoutCount or 0
    if streak > 0 then
      self:Print("Disabled. Your eviction streak of " .. streak .. " has been reset. Coward.")
    else
      self:Print("Disabled - housing logout is off.")
    end
    db.lastDisabledAt = time()
    db.logoutCount = 0
    -- Track best streak
    if streak > (db.bestStreak or 0) then
      db.bestStreak = streak
    end
    self:UpdateMySmell()
    self:CancelCountdown()
  end
end

-- Stub functions in case modules fail to load
function addon:InitHousing() end
function addon:InitWarningUI() end
function addon:InitMinimap() end
function addon:InitDB() end
function addon:GetDB() return HomelessDB or {} end
function addon:CancelCountdown() end
function addon:StartEviction() end
function addon:InitSmells() end
function addon:ShowWarning() end
function addon:HideWarning() end
function addon:LockWarning() end
function addon:ActivateHearthstone() end
function addon:UpdateMySmell() end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    addon:OnLogin()
  end
end)

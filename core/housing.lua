Homeless = Homeless or {}

local addon = Homeless

local active = false

function addon:InitHousing()
  if not C_Housing then
    self:Print("Warning: C_Housing API not available. Housing detection disabled.")
    return
  end

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("HOUSE_PLOT_ENTERED")
  frame:RegisterEvent("HOUSE_PLOT_EXITED")
  frame:SetScript("OnEvent", function(_, event)
    if event == "HOUSE_PLOT_ENTERED" then
      addon:OnHousePlotEntered()
    elseif event == "HOUSE_PLOT_EXITED" then
      addon:OnHousePlotExited()
    end
  end)
end

function addon:OnHousePlotEntered()
  local db = self:GetDB()
  if not db.enabled then return end

  C_Timer.After(0.5, function()
    if C_Housing and C_Housing.IsInsideOwnHouse and C_Housing.IsInsideOwnHouse() then
      addon:StartEviction()
    end
  end)
end

function addon:OnHousePlotExited()
  self:CancelCountdown()
end

function addon:StartEviction()
  if active then return end
  active = true

  self:ShowWarning()
  PlaySound(8959, "Master")
  self:ActivateHearthstone()

  local db = self:GetDB()
  db.logoutCount = db.logoutCount + 1
  self:Print("Eviction #" .. db.logoutCount .. ". You are homeless.")
  self:UpdateMySmell()
end

function addon:CancelCountdown()
  active = false
  self:HideWarning()
end

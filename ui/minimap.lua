Homeless = Homeless or {}

local addon = Homeless

local function refreshTooltip(owner)
  local db = addon:GetDB()
  GameTooltip:ClearLines()
  GameTooltip:AddLine("Homeless")
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Current streak: " .. (db.logoutCount or 0), 1, 1, 1)
  GameTooltip:AddLine("Best streak: " .. (db.bestStreak or 0), 1, 0.84, 0)
  if db.lastDisabledAt then
    GameTooltip:AddLine("Last pardoned: " .. date("%Y-%m-%d %H:%M", db.lastDisabledAt), 0.7, 0.7, 0.7)
  end
  GameTooltip:AddLine(" ")
  if db.enabled then
    GameTooltip:AddLine("|cff00ff00Enabled|r - Click to disable", 0.8, 0.8, 0.8)
  else
    GameTooltip:AddLine("|cffff0000Disabled|r - Click to enable", 0.8, 0.8, 0.8)
  end
  GameTooltip:Show()
end

function addon:InitMinimap()
  local LDB = LibStub("LibDataBroker-1.1")
  local LDBIcon = LibStub("LibDBIcon-1.0")
  local db = self:GetDB()

  local tooltipTicker = nil

  local minimapBtn = LDB:NewDataObject("Homeless", {
    type = "launcher",
    icon = "Interface\\Icons\\INV_Misc_Key_14",
    OnClick = function(_, button)
      if button == "LeftButton" then
        addon:ToggleEnabled()
      end
    end,
    OnEnter = function(self)
      GameTooltip:SetOwner(self, "ANCHOR_NONE")
      GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
      refreshTooltip(self)
      -- Live-update the tooltip every second while hovered
      tooltipTicker = C_Timer.NewTicker(1, function()
        if GameTooltip:IsOwned(self) then
          refreshTooltip(self)
        else
          if tooltipTicker then
            tooltipTicker:Cancel()
            tooltipTicker = nil
          end
        end
      end)
    end,
    OnLeave = function(self)
      if tooltipTicker then
        tooltipTicker:Cancel()
        tooltipTicker = nil
      end
      GameTooltip:Hide()
    end,
  })

  LDBIcon:Register("Homeless", minimapBtn, db.minimap)
end

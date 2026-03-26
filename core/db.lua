Homeless = Homeless or {}

local addon = Homeless

local function ensureDefaults(db)
  if db.enabled == nil then
    db.enabled = addon.defaults.enabled
  end
  db.logoutCount = db.logoutCount or addon.defaults.logoutCount
  -- lastDisabledAt: nil by default, set when user disables the addon
  db.minimap = db.minimap or {}
  if db.minimap.hide == nil then
    db.minimap.hide = addon.defaults.minimap.hide
  end
end

function addon:InitDB()
  HomelessDB = HomelessDB or {}
  ensureDefaults(HomelessDB)
end

function addon:GetDB()
  return HomelessDB
end

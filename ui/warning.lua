Homeless = Homeless or {}

local addon = Homeless

local warningFrame = nil
local hearthButton = nil
local bindingsActive = false
local reloadText = nil

-- Hearthstone item IDs in priority order
local HEARTHSTONE_ITEMS = {
  6948,    -- Hearthstone
  140192,  -- Dalaran Hearthstone
  110560,  -- Garrison Hearthstone
  54452,   -- Ethereal Portal
  64488,   -- The Innkeeper's Daughter
  93672,   -- Dark Portal
  142542,  -- Tome of Town Portal
  162973,  -- Greatfather Winter's Hearthstone
  163045,  -- Headless Horseman's Hearthstone
  165669,  -- Lunar Elder's Hearthstone
  165670,  -- Peddlefeet's Lovely Hearthstone
  165802,  -- Noble Gardener's Hearthstone
  166746,  -- Fire Eater's Hearthstone
  166747,  -- Brewfest Reveler's Hearthstone
  168907,  -- Holographic Digitalization Hearthstone
  172179,  -- Eternal Traveler's Hearthstone
  180290,  -- Night Fae Hearthstone
  182773,  -- Necrolord Hearthstone
  183716,  -- Venthyr Sinstone
  184353,  -- Kyrian Hearthstone
  188952,  -- Dominated Hearthstone
  190196,  -- Enlightened Hearthstone
  190237,  -- Broker Translocation Matrix
  200630,  -- Ohn'ir Windsage's Hearthstone
  206195,  -- Path of the Naaru
  208704,  -- Deepdweller's Earthen Hearthstone
  209035,  -- Hearthstone of the Flame
  210455,  -- Draenic Hologem
  212337,  -- Stone of the Hearth
  228940,  -- Notorious Thread's Hearthstone
}

local BIND_KEYS = {
  "W", "A", "S", "D", "UP", "DOWN", "LEFT", "RIGHT",
  "Q", "E", "R", "F", "T", "G", "Z", "X", "C", "V",
  "SPACE", "ENTER", "ESCAPE", "TAB",
  "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
  "F1", "F2", "F3", "F4", "F5",
  "MOUSEWHEELUP", "MOUSEWHEELDOWN",
}

local function isItemReady(itemID)
  local hasItem = GetItemCount(itemID) > 0 or PlayerHasToy(itemID)
  if not hasItem then return false end
  local start, duration = GetItemCooldown(itemID)
  return start == 0 or duration <= 1.5
end

local function getAvailableHearthstone()
  for _, id in ipairs(HEARTHSTONE_ITEMS) do
    if isItemReady(id) then
      return id
    end
  end
  return nil
end

-- Class spells that can force the player out
-- Each entry: { spellID, spellName, classes }
local CLASS_ESCAPE_SPELLS = {
  -- Mage teleports (capital cities)
  { 3561,   "Teleport: Stormwind",    "MAGE" },
  { 3562,   "Teleport: Ironforge",    "MAGE" },
  { 3563,   "Teleport: Undercity",    "MAGE" },
  { 3565,   "Teleport: Darnassus",    "MAGE" },
  { 3566,   "Teleport: Thunder Bluff","MAGE" },
  { 3567,   "Teleport: Orgrimmar",    "MAGE" },
  { 32271,  "Teleport: Exodar",       "MAGE" },
  { 32272,  "Teleport: Silvermoon",   "MAGE" },
  { 49358,  "Teleport: Stonard",      "MAGE" },
  { 49359,  "Teleport: Theramore",    "MAGE" },
  { 33690,  "Teleport: Shattrath (A)","MAGE" },
  { 35715,  "Teleport: Shattrath (H)","MAGE" },
  { 53140,  "Teleport: Dalaran (Northrend)", "MAGE" },
  { 120145, "Teleport: Dalaran (Broken Isles)", "MAGE" },
  { 132621, "Teleport: Vale (A)",     "MAGE" },
  { 132627, "Teleport: Vale (H)",     "MAGE" },
  { 176242, "Teleport: Warspear",     "MAGE" },
  { 176248, "Teleport: Stormshield",  "MAGE" },
  { 224869, "Teleport: Dornogal",     "MAGE" },
  -- Demon Hunter
  { 370665, "Demonic Gateway",        "DEMONHUNTER" },
  -- Death Knight
  { 50977,  "Death Gate",             "DEATHKNIGHT" },
  -- Druid
  { 18960,  "Teleport: Moonglade",    "DRUID" },
  { 147420, "Teleport: Dreamwalk",    "DRUID" },
  -- Monk
  { 126892, "Zen Pilgrimage",         "MONK" },
  -- Shaman
  { 556,    "Astral Recall",          "SHAMAN" },
}

local function buildHearthMacro()
  local lines = {}
  -- Add class-specific escape spells first
  local _, playerClass = UnitClass("player")
  for _, entry in ipairs(CLASS_ESCAPE_SPELLS) do
    if entry[3] == playerClass and IsSpellKnown(entry[1]) then
      lines[#lines + 1] = "/cast " .. entry[2]
    end
  end
  -- Add hearthstone items the player owns
  for _, id in ipairs(HEARTHSTONE_ITEMS) do
    if GetItemCount(id) > 0 or PlayerHasToy(id) then
      lines[#lines + 1] = "/use item:" .. id
    end
  end
  if #lines == 0 then
    lines[#lines + 1] = "/use item:6948"
  end
  return table.concat(lines, "\n")
end

local EVICTION_MESSAGES = {
  "YOU ENTERED YOUR HOUSE",
  "EVICTION NOTICE SERVED",
  "THE BANK FORECLOSED",
  "THIS ISN'T YOUR HOME ANYMORE",
  "PROPERTY SEIZED",
  "LEASE TERMINATED",
  "YOU DON'T LIVE HERE",
  "TRESPASSING DETECTED",
  "VACATE IMMEDIATELY",
  "HOUSING REVOKED",
}

local function getRandomEvictionMessage()
  return EVICTION_MESSAGES[math.random(1, #EVICTION_MESSAGES)]
end

local function createWarningFrame()
  if warningFrame then return end

  warningFrame = CreateFrame("Frame", "HomelessWarningFrame", UIParent)
  warningFrame:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT")
  warningFrame:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT")
  warningFrame:SetFrameStrata("FULLSCREEN_DIALOG")
  warningFrame:SetFrameLevel(100)
  warningFrame:EnableMouse(true)

  -- Semi-transparent red background
  warningFrame.bg = warningFrame:CreateTexture(nil, "BACKGROUND")
  warningFrame.bg:SetAllPoints(true)
  warningFrame.bg:SetColorTexture(0.4, 0, 0, 0.7)

  -- Title
  warningFrame.title = warningFrame:CreateFontString(nil, "OVERLAY")
  warningFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 48, "OUTLINE")
  warningFrame.title:SetPoint("CENTER", warningFrame, "CENTER", 0, 60)
  warningFrame.title:SetTextColor(1, 0.2, 0.2, 1)
  warningFrame.title:SetText("YOU ENTERED YOUR HOUSE")

  -- Countdown text
  warningFrame.countdown = warningFrame:CreateFontString(nil, "OVERLAY")
  warningFrame.countdown:SetFont("Fonts\\FRIZQT__.TTF", 36, "OUTLINE")
  warningFrame.countdown:SetPoint("CENTER", warningFrame, "CENTER", 0, -20)
  warningFrame.countdown:SetTextColor(1, 1, 1, 1)

  -- Subtitle
  warningFrame.subtitle = warningFrame:CreateFontString(nil, "OVERLAY")
  warningFrame.subtitle:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
  warningFrame.subtitle:SetPoint("CENTER", warningFrame, "CENTER", 0, -70)
  warningFrame.subtitle:SetTextColor(1, 0.6, 0.6, 1)
  warningFrame.subtitle:SetText("LEAVE NOW!")

  -- Small reload hint text (right side)
  reloadText = warningFrame:CreateFontString(nil, "OVERLAY")
  reloadText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
  reloadText:SetPoint("RIGHT", warningFrame, "RIGHT", -20, 0)
  reloadText:SetTextColor(0.8, 0.8, 0.8, 1)
  reloadText:SetText("type /reload to close overlay")
  reloadText:Hide()

  -- Secure hearthstone button covering the entire screen
  -- Uses macro type: /sit stops movement, /use casts hearthstone
  hearthButton = CreateFrame("Button", "HomelessHearthButton", warningFrame, "SecureActionButtonTemplate")
  hearthButton:SetAllPoints(warningFrame)
  hearthButton:SetFrameLevel(101)
  hearthButton:SetAttribute("type", "macro")
  hearthButton:SetAttribute("macrotext", buildHearthMacro())
  hearthButton:RegisterForClicks("AnyUp", "AnyDown")

  -- Invisible but clickable
  local btnTex = hearthButton:CreateTexture(nil, "ARTWORK")
  btnTex:SetAllPoints(true)
  btnTex:SetColorTexture(0, 0, 0, 0)

  -- Initially hide the secure button (only shown when bindings activate)
  hearthButton:Hide()

  warningFrame:Hide()
end

local function activateBindings()
  if not hearthButton then return end

  -- Clear stale bindings from a previous entry (e.g. hearthstone teleport
  -- may not fire HOUSE_PLOT_EXITED, leaving bindingsActive true)
  if bindingsActive then
    ClearOverrideBindings(hearthButton)
    bindingsActive = false
  end

  local itemID = getAvailableHearthstone()
  if itemID then
    hearthButton:SetAttribute("macrotext", buildHearthMacro())
    hearthButton:Show()
    for _, key in ipairs(BIND_KEYS) do
      SetOverrideBindingClick(hearthButton, true, key, "HomelessHearthButton")
    end
    bindingsActive = true
  else
    hearthButton:Hide()
    if reloadText then
      reloadText:Show()
    end
  end
end

local function clearBindings()
  if hearthButton then
    hearthButton:Hide()
  end
  if not bindingsActive then return end
  if hearthButton then
    ClearOverrideBindings(hearthButton)
  end
  bindingsActive = false
end

function addon:InitWarningUI()
  createWarningFrame()
end

function addon:ShowWarning()
  if not warningFrame then createWarningFrame() end
  warningFrame.bg:SetColorTexture(0.4, 0, 0, 0.7)
  warningFrame.title:SetText(getRandomEvictionMessage())
  warningFrame.countdown:SetText("Evicting...")
  warningFrame.subtitle:SetText("LEAVE NOW!")
  if reloadText then reloadText:Show() end
  warningFrame:Show()
end

function addon:ActivateHearthstone()
  -- Called at 3 seconds remaining — override all keys to hearthstone
  -- /sit in the macro stops movement, /use casts hearthstone
  -- Held movement keys auto-trigger via key repeat
  activateBindings()
end

function addon:HideWarning()
  clearBindings()
  if reloadText then reloadText:Hide() end
  if warningFrame then
    warningFrame:Hide()
  end
end

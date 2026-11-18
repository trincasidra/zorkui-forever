
-- rStatusButton: core
-- zork, 2018

-----------------------------
-- Variables
-----------------------------

local A, L = ...

L.addonName       = A
L.dragFrames      = {}
L.addonColor      = "00FF00AA"
L.addonShortcut   = "rsb"

L.mediapath       = "interface\\addons\\"..A.."\\media\\"

local GameTooltip, C_AzeriteItem, C_IslandsQueue, C_Reputation, C_QuestLog = GameTooltip, C_AzeriteItem, C_IslandsQueue, C_Reputation, C_QuestLog


-----------------------------
-- Config
-----------------------------

local cfg = {
  scale = 0.9,
  point = { "TOP", 0, -50 },
  size = { 32, 32 },
  showOnModifier = false,
  frameVisibilityFunc = nil,
  --fader via OnShow
  fader = {
    fadeInAlpha = 1,
    fadeInDuration = 0.3,
    fadeInSmooth = "OUT",
    fadeOutAlpha = 0,
    fadeOutDuration = 0.9,
    fadeOutSmooth = "OUT",
    fadeOutDelay = 0,
    trigger = "OnShow",
  },
}
cfg.frameVisibility = cfg.showOnModifier and "[petbattle][overridebar][vehicleui][possessbar][shapeshift][combat] hide; [mod] show; hide" or "show"

-----------------------------
-- Functions
-----------------------------

local function GetProgressBar(current, maximum)
  if type(current) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then return end
  local percent = math.floor(current / maximum * 100)
  percent = math.max(0, math.min(100, percent))
  local filled = math.floor(percent / 5)
  return string.format("[%s|cff303030%s|r]", string.rep("#", filled), string.rep("#", 20 - filled))
end

local function AddProgressBar(current, maximum)
  local progressBar = GetProgressBar(current, maximum)
  if progressBar then GameTooltip:AddLine(progressBar, 1, 1, 1, 1, 1, 1) end
end

local function GetLevelText(level, current, maximum)
  if level == nil then return nil end
  if type(current) == "number" and type(maximum) == "number" and maximum > 0 and current < maximum then
    local percent = math.floor(math.max(0, current / maximum) * 100)
    if percent > 0 then return tostring(level) .. "." .. ("%02d"):format(percent) end
  end
  return tostring(level)
end

local function AddExperienceProgressBar(current, maximum, rested)
  if type(current) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then return end
  local percent = math.floor(current / maximum * 100)
  percent = math.max(0, math.min(100, percent))
  local filled = math.floor(percent / 5)
  rested = type(rested) == "number" and math.max(0, rested) or 0
  if rested > 0 then
    local restedPercent = rested / maximum * 100
    local restedSegments = math.min(20, math.ceil(restedPercent / 5))
    local displayFilled = math.max(filled, restedSegments)
    local blueSegments = math.min(restedSegments, displayFilled)
    local whiteSegments = displayFilled - blueSegments
    local bar = string.format("[%s|cff00aaff%s|r|cff303030%s|r]", string.rep("#", whiteSegments), string.rep("#", blueSegments), string.rep("#", 20 - displayFilled))
    GameTooltip:AddLine(bar, 1, 1, 1, 1, 1, 1)
  else
    AddProgressBar(current, maximum)
  end
end

local function AddNeededLine(needed, restedPercent)
  local neededText = "-" .. tostring(math.max(0, needed))
  if type(restedPercent) == "number" and restedPercent > 0 then
    local restedText = ("r: +%.1f%%"):format(restedPercent)
    GameTooltip:AddDoubleLine(restedText, neededText, 0, 0.67, 1, 1, 1, 1)
  else
    GameTooltip:AddDoubleLine(" ", neededText, 1, 1, 1, 1, 1, 1)
  end
end

local function AddSectionTitle(title, level, current, maximum, r, g, b)
  if title ~= "Level" then GameTooltip:AddLine(" ") end
  local levelText = GetLevelText(level, current, maximum)
  if levelText then
    GameTooltip:AddDoubleLine(title, levelText, r, g, b, 1, 1, 1)
  else
    GameTooltip:AddLine(title, r, g, b, 1, 1, 1)
  end
end

local function OnEnter(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  --experience
  local playerLevel, maxPlayerLevel = UnitLevel("player"), GetMaxPlayerLevel()
  if playerLevel and maxPlayerLevel and playerLevel < maxPlayerLevel and not IsXPUserDisabled() then
    local cur, max = UnitXP("player"), UnitXPMax("player")
    local rested = GetXPExhaustion() or 0
    AddSectionTitle("Level", playerLevel, cur, max, 0, 1, 0.5)
    AddExperienceProgressBar(cur, max, rested)
    AddNeededLine(max - cur, max > 0 and rested / max * 100 or nil)
  end
  --honor
  --if InActiveBattlefield() or IsInActiveWorldPVP() then
    local cur, max = UnitHonor("player"), UnitHonorMax("player")
    local lvl = UnitHonorLevel("player")
    AddSectionTitle("Honor", lvl, cur, max, 1, 0.2, 0.2)
    AddProgressBar(cur, max)
    AddNeededLine(max - cur)
  --end
  --reputation
  local reputationData = C_Reputation and C_Reputation.GetWatchedFactionData and C_Reputation.GetWatchedFactionData()
  if reputationData and reputationData.name then
    local standingLabel = _G["FACTION_STANDING_LABEL"..reputationData.reaction] or reputationData.reaction
    local min = reputationData.currentReactionThreshold
    local max = reputationData.nextReactionThreshold
    local cur = reputationData.currentStanding
    local progressCurrent, progressMaximum
    if min and max and cur then
      progressCurrent = cur - min
      progressMaximum = max - min
    end
    AddSectionTitle(reputationData.name.." Reputation", standingLabel, progressCurrent, progressMaximum, 0.8, 0.4, 1)
    if min and max and cur then
      AddProgressBar(progressCurrent, progressMaximum)
      AddNeededLine(progressMaximum - progressCurrent)
    end
  end
  --azerite
  local azeriteItem = C_AzeriteItem and C_AzeriteItem.FindActiveAzeriteItem and C_AzeriteItem.FindActiveAzeriteItem()
  if azeriteItem and C_AzeriteItem.GetAzeriteItemXPInfo and C_AzeriteItem.GetPowerLevel then
    local cur, max = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItem)
    local lvl = C_AzeriteItem.GetPowerLevel(azeriteItem)
    if cur and max and lvl then
      AddSectionTitle("Azerite", lvl, cur, max, 1, 0.85, 0.2)
      AddProgressBar(cur, max)
      AddNeededLine(max - cur)
    end
  end
  --islandweekly
  local iwqID = C_IslandsQueue and C_IslandsQueue.GetIslandsWeeklyQuestID and C_IslandsQueue.GetIslandsWeeklyQuestID()
  local isQuestCompleted = iwqID and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(iwqID)
  if isQuestCompleted then
    AddSectionTitle("Island Weekly", nil, nil, nil, 0.3, 0.65, 1)
    GameTooltip:AddDoubleLine("Status", "Finished", 1, 1, 1, 1, 1, 1)
  elseif iwqID and GetQuestObjectiveInfo then
    local _, _, _, cur, max = GetQuestObjectiveInfo(iwqID, 1, false)
    if cur and max then
      AddSectionTitle("Island Weekly", nil, nil, nil, 0.3, 0.65, 1)
      AddProgressBar(cur, max)
      AddNeededLine(max - cur)
    end
  end
  GameTooltip:Show()
end

local function OnLeave(self)
  GameTooltip:Hide()
end

local function OnClick(self)
  self.count = self.count+1
  if self.count % 2 == 0 then
    self.gem:SetTexture(L.mediapath.."chatgem_inactive")
  else
    self.gem:SetTexture(L.mediapath.."chatgem_active")
  end
end

-----------------------------
-- Init
-----------------------------

local button = CreateFrame("Button", A, UIParent, SecureHandlerStateTemplate)
button:SetScale(cfg.scale)
button:SetPoint(unpack(cfg.point))
button:SetSize(unpack(cfg.size))
button.frameVisibility = cfg.frameVisibility
button.frameVisibilityFunc = cfg.frameVisibilityFunc
local gem = button:CreateTexture(nil, "BACKGROUND",nil,-8)
gem:SetTexture(L.mediapath.."chatgem_active")
gem:SetAllPoints()
button.gem = gem
button.count = 1
RegisterStateDriver(button, cfg.frameVisibilityFunc or "visibility", cfg.frameVisibility)
button:SetScript("OnEnter", OnEnter)
button:SetScript("OnLeave", OnLeave)
button:SetScript("OnClick", OnClick)

--OnShow fader
if cfg.showOnModifier and cfg.fader then
  rLib:CreateFrameFader(button, cfg.fader)
elseif not cfg.showOnModifier then
  button:SetAlpha(1)
end

--drag frame
rLib:CreateDragFrame(button, L.dragFrames, -2, true)

--create slash commands
rLib:CreateSlashCmd(L.addonName, L.addonShortcut, L.dragFrames, L.addonColor)
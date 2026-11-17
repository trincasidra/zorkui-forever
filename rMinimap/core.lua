
-- rMinimap: core
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...

L.addonName       = A
L.dragFrames      = {}
L.addonColor      = "00FFAA00"
L.addonShortcut   = "rmm"

-----------------------------
-- Config
-----------------------------

local dummy = function() end
local unpack = unpack
local mediapath = "interface\\addons\\"..A.."\\media\\"

-----------------------------
-- Init
-----------------------------

--border art
MinimapBackdrop:Hide()
MinimapCompassTexture:Hide()

--zoom buttons
Minimap.ZoomIn:Hide()
Minimap.ZoomIn.Show = dummy
Minimap.ZoomOut:Hide()
Minimap.ZoomOut.Show = dummy

--square minimap
Minimap:SetMaskTexture(mediapath.."mask2")
Minimap:ClearAllPoints()
Minimap:SetPoint("CENTER", -10, 10)
Minimap:SetSize(280, 280)
Minimap:SetArchBlobRingScalar(0)
Minimap:SetQuestBlobRingScalar(0)
Minimap:SetTaskBlobRingScalar(0)
function GetMinimapShape() return "SQUARE" end

--hide day/night and player coords
local children = {MinimapCluster.MinimapContainer:GetChildren()}
for i, child in ipairs(children) do
  if child:GetObjectType() == "Frame" then
    child:Hide()
    child.Show = dummy
  end
end

--addon buttons
local addonButtons = {AddonCompartmentFrame:GetChildren()}
for i, child in ipairs(addonButtons) do
  if child:GetObjectType() == "Frame" then
    child:Hide()
    child.Show = dummy
  end
end
AddonCompartmentFrame:Hide()
AddonCompartmentFrame.Show = dummy
AddonCompartmentFrame:SetAlpha(0)

local pendingLayout = false

local function UpdateLayout()
  if InCombatLockdown() then
    pendingLayout = true
    return
  end

  pendingLayout = false
  local zone = MinimapCluster.ZoneTextButton
  if zone then
    zone:ClearAllPoints()
    zone:SetPoint("TOP", Minimap, "TOP", 0, -18)
    zone:SetSize(240, 16)
    zone:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    zone:DisableDrawLayer("BACKGROUND")
    if zone.BorderTop then
      zone.BorderTop:Hide()
    end
    if MinimapZoneText then
      MinimapZoneText:ClearAllPoints()
      MinimapZoneText:SetPoint("CENTER", zone, "CENTER")
      MinimapZoneText:SetWidth(240)
      MinimapZoneText:SetJustifyH("CENTER")
    end
  end

  local tracking = MinimapCluster.Tracking
  if tracking then
    tracking:ClearAllPoints()
    tracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 24, -24)
    tracking:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    if tracking.Background then
      tracking.Background:Hide()
    end
    local button = tracking.Button
    if button then
      button:DisableDrawLayer("ARTWORK")
      if not button.rMinimapIcon then
        local icon = button:CreateTexture(nil, "OVERLAY")
        icon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
        icon:SetSize(14, 14)
        icon:SetPoint("CENTER", button, "CENTER")
        button.rMinimapIcon = icon
      end
    end
  end

  if GameTimeFrame then
    GameTimeFrame:Hide()
  end

  if TimeManagerClockButton then
    TimeManagerClockButton:ClearAllPoints()
    TimeManagerClockButton:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 18)
    TimeManagerClockButton:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    if TimeManagerClockTicker then
      TimeManagerClockTicker:ClearAllPoints()
      TimeManagerClockTicker:SetPoint("CENTER", TimeManagerClockButton, "CENTER")
    end
  end
end

local events = {}

function events:PLAYER_LOGIN()
  if not TimeManagerClockButton then
    C_AddOns.LoadAddOn("Blizzard_TimeManager")
  end
  UpdateLayout()
end

function events:PLAYER_ENTERING_WORLD()
  UpdateLayout()
end

function events:ADDON_LOADED(addonName)
  if addonName == "Blizzard_TimeManager" then
    UpdateLayout()
  end
end

function events:PLAYER_REGEN_ENABLED()
  if pendingLayout then
    UpdateLayout()
  end
end

local eventFrame = CreateFrame("Frame")
for event in pairs(events) do
  eventFrame:RegisterEvent(event)
end
eventFrame:SetScript("OnEvent", function(self, event, ...)
  events[event](self, ...)
end)

if MinimapCluster.SetHeaderUnderneath then
  hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", UpdateLayout)
end

if GameTimeFrame then
  GameTimeFrame:HookScript("OnShow", UpdateLayout)
end

UpdateLayout()
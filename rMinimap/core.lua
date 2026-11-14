
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
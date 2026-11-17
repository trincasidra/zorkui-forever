
-- rUnitFramesConfig: nameplate
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...

-----------------------------
-- NamePlateCallback
-----------------------------

local function NamePlateCallback(...)
  print(...)
end
--L.C.NamePlateCallback = NamePlateCallback

-----------------------------
-- NamePlateCVars
-----------------------------

local cvars = {
  nameplateMinScale         = 1,
  nameplateMaxScale         = 1,
  nameplateMinScaleDistance = 0,
  nameplateMaxScaleDistance = 40,
  nameplateGlobalScale      = 1,
  NamePlateHorizontalScale  = 1,
  NamePlateVerticalScale    = 1,
  nameplateSelfScale        = 1,
  nameplateSelectedScale    = 1.35,
  nameplateLargerScale      = 1,
  nameplateShowFriendlyNPCs = 0,
  nameplateMinAlpha         = 0.5,
  nameplateMaxAlpha         = 0.5,
  nameplateMinAlphaDistance = 0,
  nameplateMaxAlphaDistance = 40,
  nameplateSelectedAlpha    = 1
}

L.C.NamePlateCVars = cvars

-----------------------------
-- NamePlateConfig
-----------------------------

--nameplate debuffs: oUF 14 auras are filtered by the client (aura data is secret), Lua
--CustomFilter functions are no longer supported. "HARMFUL|PLAYER" = your own debuffs,
--"HARMFUL|INCLUDE_NAME_PLATE_ONLY" = debuffs flagged for nameplates (incl. nameplate-only ones).

L.C.nameplate = {
  enabled = true,
  size = {182,32},
  point = {"CENTER"}, --relative to the nameplate base!
  scale = 1*UIParent:GetScale()*L.C.globalscale,--nameplates are not part of uiparent, they must be multiplied by uiparent scale!
  --healthbar
  healthbar = {
    --health and absorb bar cannot be disabled, they match the size of the frame
    colorTapping = true,
    colorReaction = true,
    colorClass = true,
    colorHealth = true,
    colorThreat = true,
    colorThreatInvers = true,
    frequentUpdates = true,
    name = {
      enabled = true,
      points = {
        {"LEFT",2,0},
        {"RIGHT",-2,0},
      },
      size = 16,
      align = "CENTER",
      tag = "[rUnitFramesConfig:classification][difficulty][name]|r",
    },
    debuffHighlight = false,
  },
  --raidmark
  raidmark = {
    enabled = true,
    size = {26,26},
    point = {"CENTER","TOP",0,0},
  },
  --castbar
  castbar = {
    enabled = true,
    size = {182,26},
    point = {"TOP","BOTTOM",0,-5},
    name = {
      enabled = true,
      points = {
        {"LEFT",2,0},
        {"RIGHT",-2,0},
      },
      size = 16,
    },
    icon = {
      enabled = true,
      size = {26,26},
      point = {"RIGHT","LEFT",-6,0},
    },
  },
  --debuffs
  debuffs = {
    enabled = true,
    point = {"BOTTOMLEFT","TOPLEFT",0,5},
    num = 5,
    cols = 5,
    size = 32,
    spacing = 5,
    initialAnchor = "TOPLEFT",
    growthX = "RIGHT",
    growthY = "UP",
    disableCooldown = false,
    showDuration = false,
    filter = "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY",
  },
  --buffs
  buffs = {
    enabled = true,
    point = {"LEFT","RIGHT",8,0},
    num = 3,
    cols = 3,
    size = 28,
    spacing = 5,
    initialAnchor = "LEFT",
    growthX = "RIGHT",
    growthY = "DOWN",
    disableCooldown = false,
    showStealableBorder = true,
    showDuration = false,
    showBuffIndicator = true
  },
}

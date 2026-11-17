
-- rUnitFramesConfig: party
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...

-----------------------------
-- Party Config
-----------------------------

L.C.party = {
  enabled = true,
  size = {180,26},
  point = {"CENTER",-800,200},
  scale = 1*L.C.globalscale,
  --healthbar
  healthbar = {
    --health and absorb bar cannot be disabled, they match the size of the frame
    colorDisconnected = true,
    colorClass = true,
    colorReaction = true,
    colorHealth = true,
    colorThreat = true,
    frequentUpdates = true,
    name = {
      enabled = true,
      points = {
        {"TOPLEFT",2,10},
        {"TOPRIGHT",-2,10},
      },
      size = 17,
      tag = "[name][rUnitFrames:leader][rUnitFrames:role][rUnitFramesConfig:pvpStatus]",
    },
    health = {
      enabled = true,
      point = {"RIGHT",-2,0},
      size = 16,
      tag = "[rUnitFrames:health]",
    },
    debuffHighlight = false,
  },
  --powerbar
  powerbar = {
    enabled = true,
    size = {180,5},
    point = {"TOP","BOTTOM",0,-4}, --if no relativeTo is given the frame base will be the relativeTo reference
    colorPower = true,
  },
  --raidmark
  raidmark = {
    enabled = true,
    size = {18,18},
    point = {"CENTER","TOP",0,0},
  },
  --debuffs
  debuffs = {
    enabled = true,
    point = {"LEFT","RIGHT",10,0},
    num = 5,
    cols = 5,
    size = 42,
    spacing = 5,
    initialAnchor = "TOPLEFT",
    growthX = "RIGHT",
    growthY = "DOWN",
    disableCooldown = false,
    showDuration = false,
    showDebuffBorder = true,
    showDebuffIndicator = true,
    dispelBorderStyle = Enum.CustomAuraButtonDispelTypeTextureStyle.Border
  },
  setup = {
    template = nil,
    visibility = "custom [@raid6,exists] hide;show",
    showPlayer = true,
    showParty = true,
    showRaid = false,
    point = "TOP",
    xOffset = 0,
    yOffset = -28,
  },
}

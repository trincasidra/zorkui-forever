
-- rUnitFramesConfig: raid
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...

-----------------------------
-- Raid Config
-----------------------------

L.C.raid = {
  enabled = true,
  size = {110,26},
  points = { --list of 8 points, one for each raid group
    {"CENTER",-800,200},
    {"TOP", "rUnitFramesRaidHeader1", "BOTTOM", 0, -10},
    {"TOP", "rUnitFramesRaidHeader2", "BOTTOM", 0, -10},
    {"TOP", "rUnitFramesRaidHeader3", "BOTTOM", 0, -10},
    {"TOPLEFT", "rUnitFramesRaidHeader1", "TOPRIGHT", 10, 0},
    {"TOP", "rUnitFramesRaidHeader5", "BOTTOM", 0, -10},
    {"TOP", "rUnitFramesRaidHeader6", "BOTTOM", 0, -10},
    {"TOP", "rUnitFramesRaidHeader7", "BOTTOM", 0, -10},
  },
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
        {"LEFT",2,0},
        {"RIGHT",-2,0},
      },
      size = 16,
      align = "CENTER",
      tag = "[name][rUnitFrames:role]",
    },
    debuffHighlight = false,
  },
  --raidmark
  raidmark = {
    enabled = true,
    size = {18,18},
    point = {"CENTER","TOP",0,0},
  },
  setup = {
    template = nil,
    visibility = "custom [@raid6,exists] show;hide",
    showPlayer = false,
    showParty = false,
    showRaid = true,
    point = "TOP",
    xOffset = 0,
    yOffset = -5,
  },
}

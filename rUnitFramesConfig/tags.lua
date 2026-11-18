
-- rUnitFramesConfig: tags
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...

-----------------------------
-- Tags
-----------------------------

local floor = floor
--Forever: several unit APIs can return secret values, those must not be compared/tested
local issecretvalue = issecretvalue or function() return false end

L.C.tagMethods["rUnitFramesConfig:status"] = function(unit,...)
  local inCombat = UnitAffectingCombat(unit)
  if not issecretvalue(inCombat) and inCombat then
    return "|TInterface\\CharacterFrame\\UI-StateIcon:20:20:0:0:64:64:33:64:0:31|t"
  elseif unit == "player" and IsResting() then
    return "|TInterface\\CharacterFrame\\UI-StateIcon:20:20:0:0:64:64:0:31:0:31|t"
  end
end
L.C.tagEvents["rUnitFramesConfig:status"] = "PLAYER_REGEN_DISABLED PLAYER_REGEN_ENABLED PLAYER_UPDATE_RESTING"

L.C.tagMethods["rUnitFramesConfig:classification"] = function(unit)
  local c = UnitClassification(unit)
  local l = UnitLevel(unit)
  if issecretvalue(c) then c = nil end
  if issecretvalue(l) then l = nil end
  if(c == 'worldboss' or l == -1) then
    return '|cffff0000{B}|r '
  elseif(c == 'rare') then
    return '|cffff9900{R}|r '
  elseif(c == 'rareelite') then
    return '|cffff0000{R+}|r '
  elseif(c == 'elite') then
    return '|cffff6666{E}|r '
  end
end
L.C.tagEvents["rUnitFramesConfig:classification"] = "UNIT_CLASSIFICATION_CHANGED"

local pvpIcons = {
  Alliance = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:20:20:0:0:64:64:0:38:0:38|t",
  Horde = "|TInterface\\TargetingFrame\\UI-PVP-Horde:20:20:0:0:64:64:0:38:0:38|t",
}

L.C.tagMethods["rUnitFramesConfig:pvpStatus"] = function(unit,...)
  local isPVP = UnitIsPVP(unit)
  if issecretvalue(isPVP) or not isPVP then return "" end
  local faction = UnitFactionGroup(unit)
  if issecretvalue(faction) or not faction then return "" end
  local icon = pvpIcons[faction]
  if not icon then return "" end
  return icon
end
L.C.tagEvents["rUnitFramesConfig:pvpStatus"] = "WAR_MODE_STATUS_UPDATE UNIT_FACTION PLAYER_FLAGS_CHANGED"

L.C.tagMethods["rUnitFramesConfig:pvpStatusWithTimer"] = function(unit,...)
  local isPVP = UnitIsPVP(unit)
  if issecretvalue(isPVP) or not isPVP then return "" end
  local faction = UnitFactionGroup(unit)
  if issecretvalue(faction) or not faction then return "" end
  local icon = pvpIcons[faction]
  if not icon then return "" end
  local pvpTimer = math.floor(GetPVPTimer()/1000)
  if pvpTimer < 300 then return icon.." "..pvpTimer.."s" end
  return icon
end
L.C.tagEvents["rUnitFramesConfig:pvpStatusWithTimer"] = "WAR_MODE_STATUS_UPDATE UNIT_FACTION PLAYER_FLAGS_CHANGED"

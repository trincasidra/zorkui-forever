
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

L.C.tagMethods["rUnitFramesConfig:pvpStatus"] = function(unit,...)
  if not UnitIsPVP(unit) then return "" end
  if unit ~= "player" then return " |cffff6666PvP|r" end
  local pvpTimer = math.floor(GetPVPTimer()/1000)
  if pvpTimer < 300 then return "|cffff6666PvP|r "..pvpTimer.."s" end
  return "|cffff6666PvP|r"
end
L.C.tagEvents["rUnitFramesConfig:pvpStatus"] = "WAR_MODE_STATUS_UPDATE"

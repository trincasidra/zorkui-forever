
-- oUF_SimpleConfig: tags
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

L.C.tagMethods["oUF_SimpleConfig:status"] = function(unit,...)
  local inCombat = UnitAffectingCombat(unit)
  if not issecretvalue(inCombat) and inCombat then
    return "|TInterface\\CharacterFrame\\UI-StateIcon:20:20:0:0:64:64:33:64:0:31|t"
  elseif unit == "player" and IsResting() then
    return "|TInterface\\CharacterFrame\\UI-StateIcon:20:20:0:0:64:64:0:31:0:31|t"
  end
end

L.C.tagMethods["oUF_SimpleConfig:classification"] = function(unit)
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
L.C.tagEvents["oUF_SimpleConfig:status"] = "PLAYER_REGEN_DISABLED PLAYER_REGEN_ENABLED PLAYER_UPDATE_RESTING"
L.C.tagEvents["oUF_SimpleConfig:classification"] = "UNIT_CLASSIFICATION_CHANGED"

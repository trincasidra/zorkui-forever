
-- oUF_Simple: core/tags
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...
local oUF = L.oUF or oUF

-----------------------------
-- oUF Tags
-----------------------------

--secret values: see core/functions.lua
local issecretvalue = issecretvalue or function() return false end

--add player regen to the unitless event tags
oUF.Tags.SharedEvents["PLAYER_REGEN_DISABLED"] = true
oUF.Tags.SharedEvents["PLAYER_REGEN_ENABLED"] = true
--PLAYER_ROLES_ASSIGNED has no unit payload either (oUF does not list it)
oUF.Tags.SharedEvents["PLAYER_ROLES_ASSIGNED"] = true

--tag method: oUF_Simple:health
--UnitHealth() is always secret in Forever. Returning it is fine (oUF tags and
--FontString:SetText accept secrets), but no math/formatting in Lua is possible.
--Use AbbreviateLargeNumbers(UnitHealth(unit)) if you want "12.3K" style (C side, secret-safe).
oUF.Tags.Methods["oUF_Simple:health"] = function(unit)
  if not UnitIsConnected(unit) then
    return "|cff999999Offline|r"
  end
  if(UnitIsDead(unit) or UnitIsGhost(unit)) then
    return "|cff999999Dead|r"
  end
  return UnitHealth(unit)
end
--tag event: oUF_Simple:health
oUF.Tags.Events["oUF_Simple:health"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"

--role icons
local ROLE_ICON_TANK = "|TInterface\\LFGFrame\\LFGRole:14:14:0:0:64:16:32:48:0:16|t"
local ROLE_ICON_HEALER = "|TInterface\\LFGFrame\\LFGRole:14:14:0:0:64:16:48:64:0:16|t"

--tag method: oUF_Simple:role
--UnitGroupRolesAssigned(Enum) is SecretWhenUnitIdentityRestricted: never compare a secret
oUF.Tags.Methods["oUF_Simple:role"] = function(unit)
  if UnitGroupRolesAssignedEnum and Enum.LFGRole then
    local role = UnitGroupRolesAssignedEnum(unit)
    if issecretvalue(role) then return end
    if role == Enum.LFGRole.Tank then
      return ROLE_ICON_TANK
    elseif role == Enum.LFGRole.Healer then
      return ROLE_ICON_HEALER
    end
  else
    local role = UnitGroupRolesAssigned(unit)
    if issecretvalue(role) then return end
    if role == "TANK" then
      return ROLE_ICON_TANK
    elseif role == "HEALER" then
      return ROLE_ICON_HEALER
    end
  end
end
--tag event: oUF_Simple:role
oUF.Tags.Events["oUF_Simple:role"] = "PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE"

--tag method: oUF_Simple:leader
--UnitIsGroupLeader is SecretWhenUnitIdentityRestricted: a secret boolean can't be tested
oUF.Tags.Methods["oUF_Simple:leader"] = function(unit)
  local isLeader = UnitIsGroupLeader(unit)
  if not issecretvalue(isLeader) and isLeader then
    return "|TInterface\\GroupFrame\\UI-Group-LeaderIcon:14:14:0:0|t"
  end
end
--tag event: oUF_Simple:leader
oUF.Tags.Events["oUF_Simple:leader"] = "PARTY_LEADER_CHANGED GROUP_ROSTER_UPDATE"

--load tags from the config
if L.C.tagMethods and type(L.C.tagMethods) == "table" and
   L.C.tagEvents  and type(L.C.tagEvents) == "table" then
  for key, value in next, L.C.tagMethods do
    if L.C.tagMethods[key] and L.C.tagEvents[key] then
      oUF.Tags.Methods[key] = L.C.tagMethods[key]
      oUF.Tags.Events[key] = L.C.tagEvents[key]
    end
  end
end
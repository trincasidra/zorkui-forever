
-- rUnitFrames: core/spawn
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...
local oUF = L.oUF or oUF

-----------------------------
-- Register Style
-----------------------------

if L.F.CreatePlayerStyle then oUF:RegisterStyle(A.."Player", L.F.CreatePlayerStyle) end
if L.F.CreateTargetStyle then oUF:RegisterStyle(A.."Target", L.F.CreateTargetStyle) end
if L.F.CreateTargetTargetStyle then oUF:RegisterStyle(A.."TargetTarget", L.F.CreateTargetTargetStyle) end
if L.F.CreatePetStyle then oUF:RegisterStyle(A.."Pet", L.F.CreatePetStyle) end
if L.F.CreateFocusStyle then oUF:RegisterStyle(A.."Focus", L.F.CreateFocusStyle) end
if L.F.CreateMouseoverStyle then oUF:RegisterStyle(A.."Mouseover", L.F.CreateMouseoverStyle) end
if L.F.CreatePartyStyle then oUF:RegisterStyle(A.."Party", L.F.CreatePartyStyle) end
if L.F.CreateBossStyle then oUF:RegisterStyle(A.."Boss", L.F.CreateBossStyle) end
if L.F.CreateNamePlateStyle then oUF:RegisterStyle(A.."Nameplate",L.F.CreateNamePlateStyle) end
if L.F.CreateRaidStyle then oUF:RegisterStyle(A.."Raid", L.F.CreateRaidStyle) end

-----------------------------
-- Spawn Units
-----------------------------

--spawn player
if L.F.CreatePlayerStyle then
  oUF:SetActiveStyle(A.."Player")
  local player = oUF:Spawn("player", A.."Player")
  --show/hide the frame on a given state driver
  if player.cfg.frameVisibility then
    player:Disable()
    --frameVisibility needed for rLib drag and drop
    player.frameVisibility = player.cfg.frameVisibility
    RegisterStateDriver(player, "visibility", player.cfg.frameVisibility)
  end
  --OnShow fader
  if player.cfg.fader then
    rLib:CreateFrameFader(player, player.cfg.fader)
  end
end

--spawn target
if L.F.CreateTargetStyle then
  oUF:SetActiveStyle(A.."Target")
  local target = oUF:Spawn("target", A.."Target")
  --OnShow fader
  if target.cfg.fader then
    rLib:CreateFrameFader(target, target.cfg.fader)
  end
end

--spawn targettarget
if L.F.CreateTargetTargetStyle then
  oUF:SetActiveStyle(A.."TargetTarget")
  oUF:Spawn("targettarget", A.."TargetTarget")
end

--spawn pet
if L.F.CreatePetStyle then
  oUF:SetActiveStyle(A.."Pet")
  local pet = oUF:Spawn("pet", A.."Pet")
  --show/hide the frame on a given state driver
  if pet.cfg.frameVisibility then
    pet:Disable()
    --frameVisibility needed for rLib drag and drop
    pet.frameVisibility = pet.cfg.frameVisibility
    RegisterStateDriver(pet, "visibility", pet.cfg.frameVisibility)
  end
  --OnShow fader
  if pet.cfg.fader then
    rLib:CreateFrameFader(pet, pet.cfg.fader)
  end
end

--spawn focus
if L.F.CreateFocusStyle then
  oUF:SetActiveStyle(A.."Focus")
  oUF:Spawn("focus", A.."Focus")
end

--spawn mouseover
if L.F.CreateMouseoverStyle then
  oUF:SetActiveStyle(A.."Mouseover")
  oUF:Spawn("mouseover", A.."Mouseover")
end

--initial config for header children (runs in the restricted environment)
--the header scale is set on the header itself, outside of the secure snippet
local function HeaderInitialConfig(size)
  return ([[
    self:SetWidth(%d)
    self:SetHeight(%d)
  ]]):format(size[1], size[2])
end

--spawn party
if L.F.CreatePartyStyle then
  oUF:SetActiveStyle(A.."Party")
  local setup = L.C.party.setup
  local party = oUF:SpawnHeader(
    A.."PartyHeader",
    setup.template, --nil = SecureGroupHeaderTemplate (oUF default)
    "showPlayer",    setup.showPlayer,
    "showParty",     setup.showParty,
    "showRaid",      setup.showRaid,
    "showSolo",      setup.showSolo,
    "point",         setup.point,
    "xOffset",       setup.xOffset,
    "yOffset",       setup.yOffset,
    "groupBy",       setup.groupBy,
    "groupingOrder", setup.groupingOrder,
    "oUF-initialConfigFunction", HeaderInitialConfig(L.C.party.size)
  )
  party:SetScale(L.C.party.scale)
  party:SetPoint(unpack(L.C.party.point))
  --oUF 13+: headers are hidden until a visibility driver is registered
  party:SetVisibility(setup.visibility)
end

--spawn boss frames
if L.F.CreateBossStyle then
  oUF:SetActiveStyle(A.."Boss")
  local boss = {}
  for i = 1, (MAX_BOSS_FRAMES or 5) do
    boss[i] = oUF:Spawn("boss"..i, A.."Boss"..i)
    if (i == 1) then
      boss[i]:SetPoint(unpack(L.C.boss.point))
    else
      boss[i]:SetPoint(L.C.boss.setup.point, boss[i-1], L.C.boss.setup.relativePoint, L.C.boss.setup.xOffset, L.C.boss.setup.yOffset)
    end
  end
end

--spawn nameplates
if L.F.CreateNamePlateStyle then
  oUF:SetActiveStyle(A.."Nameplate")
  local driver = oUF:SpawnNamePlates(A)
  if driver then
    if L.C.NamePlateCallback then
      driver:SetAddedCallback(L.C.NamePlateCallback)
    end
    if L.C.NamePlateCVars then
      --skip cvars that do not exist in this client (several were removed/renamed)
      local cvars = {}
      for name, value in next, L.C.NamePlateCVars do
        if C_CVar.GetCVar(name) ~= nil then
          cvars[name] = value
        end
      end
      driver:SetCVars(cvars)
    end
  end
end

--spawn raid
if L.F.CreateRaidStyle then
  oUF:SetActiveStyle(A.."Raid")
  local setup = L.C.raid.setup
  for i = 1, (NUM_RAID_GROUPS or 8) do
    local raid = oUF:SpawnHeader(
      A.."RaidHeader"..i,
      setup.template,
      "showPlayer",     setup.showPlayer,
      "showParty",      setup.showParty,
      "showRaid",       setup.showRaid,
      "point",          setup.point,
      "xOffset",        setup.xOffset,
      "yOffset",        setup.yOffset,
      "groupFilter",    tostring(i),
      "unitsPerColumn", 5,
      "oUF-initialConfigFunction", HeaderInitialConfig(L.C.raid.size)
    )
    raid:SetScale(L.C.raid.scale)
    raid:SetPoint(unpack(L.C.raid.points[i])) --config needs to provide 8 point tables, one for each raid group
    --oUF 13+: headers are hidden until a visibility driver is registered
    raid:SetVisibility(setup.visibility)
  end
end

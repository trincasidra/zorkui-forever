
-- oUF_Simple: core/style
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...
local oUF = L.oUF or oUF

-----------------------------
-- Style
-----------------------------

--fix mana color
if L.C.colors.power and L.C.colors.power.mana then
  local c = L.C.colors.power.mana
  local r, g, b
  if c.GetRGB then r, g, b = c:GetRGB() else r, g, b = unpack(c) end
  local mana = oUF:CreateColor(r, g, b)
  oUF.colors.power.MANA = mana
  oUF.colors.power[Enum.PowerType and Enum.PowerType.Mana or 0] = mana
end

local function CreateStyle(self)
  L.F.SetupFrame(self)
  L.F.SetupHeader(self)
  L.F.CreateDragFrame(self)
  self.Health = L.F.CreateHealthBar(self)
  if self.Health then
    self.Health.HealingAll = L.F.CreateHealingAll(self)
    self.Health.DamageAbsorb = L.F.CreateDamageAbsorb(self)
    self.Health.HealAbsorb = L.F.CreateHealAbsorb(self)
    self.Health.OverDamageAbsorbIndicator = L.F.CreateOverDamageAbsorbIndicator(self)
    self.Health.OverHealAbsorbIndicator = L.F.CreateOverHealAbsorbIndicator(self)
  end
  L.F.CreateNameText(self)
  L.F.CreateHealthText(self)
  self.Power = L.F.CreatePowerBar(self)
  if self.Power then
    self.Power.CostPrediction = L.F.CreateCostPrediction(self)
  end
  L.F.CreatePowerText(self)
  self.Castbar = L.F.CreateCastBar(self)
  self.AlternativePower = L.F.CreateAltPowerBar(self)
  self.AdditionalPower = L.F.CreateAdditionalPowerBar(self)
  self.Debuffs = L.F.CreateDebuffs(self)
  self.Buffs = L.F.CreateBuffs(self)
  self.RaidTargetIndicator = L.F.CreateRaidMark(self)
  self.ClassPower = L.F.CreateClassPower(self)
end
L.F.CreateStyle = CreateStyle


-- oUF_Simple: core/functions
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...

local floor, unpack = floor, unpack

--functions container
L.F = {}

-----------------------------
-- Functions
-----------------------------

--NumberFormat
local function NumberFormat(v)
  if v > 1E10 then
    return (floor(v/1E9)).."b"
  elseif v > 1E9 then
    return (floor((v/1E9)*10)/10).."b"
  elseif v > 1E7 then
    return (floor(v/1E6)).."m"
  elseif v > 1E6 then
    return (floor((v/1E6)*10)/10).."m"
  elseif v > 1E4 then
    return (floor(v/1E3)).."k"
  elseif v > 1E3 then
    return (floor((v/1E3)*10)/10).."k"
  else
    return v
  end
end
L.F.NumberFormat = NumberFormat

--CalcFrameSize
local function CalcFrameSize(numButtons,numCols,buttonWidth,buttonHeight,buttonMargin,framePadding)
  local numRows = ceil(numButtons/numCols)
  local frameWidth = numCols*buttonWidth + (numCols-1)*buttonMargin + 2*framePadding
  local frameHeight = numRows*buttonHeight + (numRows-1)*buttonMargin + 2*framePadding
  return frameWidth, frameHeight
end

--SetPoint
local function SetPoint(self,relativeTo,point)
  --adjut the setpoint function to make it possible to reference a relativeTo object that is set on runtime and it not available on config init
  local a,b,c,d,e = unpack(point)
  if not b then
    self:SetPoint(a)
  elseif b and type(b) == "string" and not _G[b] then
    self:SetPoint(a,relativeTo,b,c,d)
  else
    self:SetPoint(a,b,c,d,e)
  end
end

--SetPoints
local function SetPoints(self,relativeTo,points)
  for i, point in next, points do
    SetPoint(self,relativeTo,point)
  end
end

--CreateBackdrop
local function CreateBackdrop(self,relativeTo)
  local backdrop = L.C.backdrop
  local bd = CreateFrame("Frame", nil, self, BackdropTemplateMixin and "BackdropTemplate")
  bd:SetFrameLevel(self:GetFrameLevel()-1 or 0)
  bd:SetPoint("TOPLEFT", relativeTo or self, "TOPLEFT", -backdrop.inset, backdrop.inset)
  bd:SetPoint("BOTTOMRIGHT", relativeTo or self, "BOTTOMRIGHT", backdrop.inset, -backdrop.inset)
  bd:SetBackdrop(backdrop)
  bd:SetBackdropColor(unpack(backdrop.bgColor))
  bd:SetBackdropBorderColor(unpack(backdrop.edgeColor))
  return bd
end

--CreateIcon
local function CreateIcon(self,layer,sublevel,size,point)
  local icon = self:CreateTexture(nil,layer,nil,sublevel)
  icon:SetSize(unpack(size))
  SetPoint(icon,self,point)
  return icon
end

local function ColorHealthbarOnThreat(self,unit)
  if self.colorThreat and self.colorThreatInvers and unit and UnitThreatSituation("player", unit) == 3 then
    self:SetStatusBarColor(unpack(L.C.colors.healthbar.threatInvers))
    self.bg:SetVertexColor(unpack(L.C.colors.healthbar.threatInversBG))
  elseif self.colorThreat and unit and UnitThreatSituation(unit) == 3 then
    self:SetStatusBarColor(unpack(L.C.colors.healthbar.threat))
    self.bg:SetVertexColor(unpack(L.C.colors.healthbar.threatBG))
  end
end

--PostUpdateHealth
local function PostUpdateHealth(self, unit, min, max)
  ColorHealthbarOnThreat(self,unit)
end

--UpdateThreat
local function UpdateThreat(self,event,unit)
  if event == "PLAYER_ENTER_COMBAT" or event == "PLAYER_LEAVE_COMBAT" then
    --do natting
  elseif self.unit ~= unit then
    return
  end
  self.Health:ForceUpdate()
end
L.F.UpdateThreat = UpdateThreat

--CreateText
local function CreateText(self,font,size,outline,align,noshadow)
  local text = self:CreateFontString(nil, "ARTWORK") --"BORDER", "OVERLAY"
  text:SetFont(font or STANDARD_TEXT_FONT, size or 14, outline or "OUTLINE")
  text:SetJustifyH(align or "LEFT")
  if not noshadow then
    text:SetShadowColor(0,0,0,0.25)
    text:SetShadowOffset(1,-2)
  end
  --fix some wierd bug
  text:SetText("Bugfix")
  text:SetMaxLines(1)
  text:SetHeight(text:GetStringHeight())
  return text
end
L.F.CreateText = CreateText

--AltPowerBarOverride
local function AltPowerBarOverride(self, event, unit, powerType)
  if self.unit ~= unit or powerType ~= "ALTERNATE" then return end
  local ppmax = UnitPowerMax(unit, ALTERNATE_POWER_INDEX, true) or 0
  local ppcur = UnitPower(unit, ALTERNATE_POWER_INDEX, true)
  local _, r, g, b = GetUnitPowerBarTextureInfo(unit, 2)
  local _, ppmin = UnitPowerBarID(unit)
  local el = self.AlternativePower
  el:SetMinMaxValues(ppmin or 0, ppmax)
  el:SetValue(ppcur)
  if b then
    el:SetStatusBarColor(r, g, b)
    if el.bg then
      local mu = el.bg.multiplier or 0.3
      el.bg:SetVertexColor(r*mu, g*mu, b*mu)
    end
  else
    el:SetStatusBarColor(1, 0, 1)
    if el.bg then
      local mu = el.bg.multiplier or 0.3
      el.bg:SetVertexColor(1*mu, 0*mu, 1*mu)
    end
  end
end

--CreateAltPowerBar
local function CreateAltPowerBar(self)
  if not self.cfg.altpowerbar or not self.cfg.altpowerbar.enabled then return end
  --statusbar
  local s = CreateFrame("StatusBar", nil, self)
  s:SetStatusBarTexture(L.C.textures.statusbar)
  s:SetSize(unpack(self.cfg.altpowerbar.size))
  s:SetOrientation(self.cfg.altpowerbar.orientation or "HORIZONTAL")
  SetPoint(s,self,self.cfg.altpowerbar.point)
  --bg
  local bg = s:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(L.C.textures.statusbar)
  bg:SetAllPoints()
  if L.C.colors.power.bg then
    bg:SetVertexColor(unpack(L.C.colors.power.bg))
  end
  s.bg = bg
  --backdrop
  CreateBackdrop(s)
  --attributes
  s.Override = AltPowerBarOverride
  s.bg.multiplier = L.C.colors.bgMultiplier
  return s
end
L.F.CreateAltPowerBar = CreateAltPowerBar

--CreateAbsorbBar
local function CreateAbsorbBar(self)
  --like health the absorb bar cannot be disabled
  --statusbar
  local s = CreateFrame("StatusBar", nil, self.Health)
  s:SetAllPoints()
  s:SetOrientation(self.cfg.healthbar.orientation or "HORIZONTAL")
  s:SetStatusBarTexture(L.C.textures.absorb)
  s:SetStatusBarColor(unpack(L.C.colors.healthbar.absorb))
  s:SetReverseFill(true)
  return s
end
L.F.CreateAbsorbBar = CreateAbsorbBar

--CreateHealthBar
local function CreateHealthBar(self)
  --disabling the healthbar makes no sense, no check for enabled
  --statusbar
  local s = CreateFrame("StatusBar", nil, self)
  s:SetStatusBarTexture(L.C.textures.statusbar)
  s:SetAllPoints()
  s:SetOrientation(self.cfg.healthbar.orientation or "HORIZONTAL")
  if L.C.colors.healthbar and L.C.colors.healthbar.default then
    s:SetStatusBarColor(unpack(L.C.colors.healthbar.default))
  end
  --bg
  local bg = s:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(L.C.textures.statusbarBG)
  bg:SetAllPoints()
  if L.C.colors.healthbar and L.C.colors.healthbar.defaultBG then
    bg:SetVertexColor(unpack(L.C.colors.healthbar.defaultBG))
  end
  s.bg = bg
  --backdrop
  s.bdf = CreateBackdrop(s)
  if self.cfg.healthbar.debuffHighlight then
    self.DebuffHighlight = s.bdf
    self.DebuffHighlightBackdropBorder = true
    self.DebuffHighlightAlpha = 1
    self.DebuffHighlightFilter = self.cfg.healthbar.debuffHighlightFilter or false
  end
  --attributes
  s.colorTapping = self.cfg.healthbar.colorTapping
  s.colorDisconnected = self.cfg.healthbar.colorDisconnected
  s.colorReaction = self.cfg.healthbar.colorReaction
  s.colorClass = self.cfg.healthbar.colorClass
  s.colorHealth = self.cfg.healthbar.colorHealth
  s.colorThreat = self.cfg.healthbar.colorThreat
  s.colorThreatInvers = self.cfg.healthbar.colorThreatInvers
  s.bg.multiplier = L.C.colors.bgMultiplier
  s.frequentUpdates = self.cfg.healthbar.frequentUpdates
  --hooks
  s.PostUpdate = PostUpdateHealth
  if s.colorThreat then
    self:RegisterEvent("PLAYER_REGEN_ENABLED", L.F.UpdateThreat, true)
    self:RegisterEvent("PLAYER_REGEN_DISABLED", L.F.UpdateThreat, true)
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", L.F.UpdateThreat, false)
    self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", L.F.UpdateThreat, false)
  end
  return s
end
L.F.CreateHealthBar = CreateHealthBar

--CreateHealingAll
local function CreateHealingAll(self)
  local s = CreateFrame('StatusBar', nil, self.Health)
  s:SetPoint('TOP')
  s:SetPoint('BOTTOM')
  s:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
  s:SetWidth(200)
  s:SetStatusBarTexture(L.C.textures.statusbar)
  s:SetStatusBarColor(unpack(L.C.colors.healthbar.healPredict))
  return s
end
L.F.CreateHealingAll = CreateHealingAll

--CreateDamageAbsorb
local function CreateDamageAbsorb(self)
  local s = CreateFrame('StatusBar', nil, self.Health)
  s:SetPoint('TOP')
  s:SetPoint('BOTTOM')
  s:SetPoint('LEFT', self.Health.HealingAll:GetStatusBarTexture(), 'RIGHT')
  s:SetStatusBarTexture(L.C.textures.absorb)
  s:SetStatusBarColor(unpack(L.C.colors.healthbar.absorb))
  s:SetWidth(200)
  return s
end
L.F.CreateDamageAbsorb = CreateDamageAbsorb

--CreateHealAbsorb
local function CreateHealAbsorb(self)
  local s = CreateFrame('StatusBar', nil, self.Health)
  s:SetPoint('TOP')
  s:SetPoint('BOTTOM')
  s:SetPoint('RIGHT', self.Health:GetStatusBarTexture())
  s:SetStatusBarTexture(L.C.textures.statusbar)
  s:SetStatusBarColor(unpack(L.C.colors.healthbar.healAbsorb))
  s:SetWidth(200)
  s:SetReverseFill(true)
  return s
end
L.F.CreateHealAbsorb = CreateHealAbsorb

--CreateOverDamageAbsorbIndicator
local function CreateOverDamageAbsorbIndicator(self)
  local s = self.Health:CreateTexture(nil, "OVERLAY")
  s:SetPoint('TOP')
  s:SetPoint('BOTTOM')
  s:SetPoint('LEFT', self.Health, 'RIGHT')
  s:SetWidth(10)
  return s
end
L.F.CreateOverDamageAbsorbIndicator = CreateOverDamageAbsorbIndicator

--CreateOverHealAbsorbIndicator
local function CreateOverHealAbsorbIndicator(self)
  local s = self.Health:CreateTexture(nil, "OVERLAY")
  s:SetPoint('TOP')
  s:SetPoint('BOTTOM')
  s:SetPoint('RIGHT', self.Health, 'LEFT')
  s:SetWidth(10)
  return s
end
L.F.CreateOverHealAbsorbIndicator = CreateOverHealAbsorbIndicator

--CreateAdditionalPowerBar
local function CreateAdditionalPowerBar(self)
  if not self.cfg.addpowerbar or not self.cfg.addpowerbar.enabled then return end
  --statusbar
  local s = CreateFrame("StatusBar", nil, self)
  s:SetStatusBarTexture(L.C.textures.statusbar)
  s:SetSize(unpack(self.cfg.addpowerbar.size))
  s:SetOrientation(self.cfg.addpowerbar.orientation or "HORIZONTAL")
  SetPoint(s,self,self.cfg.addpowerbar.point)
  --bg
  local bg = s:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(L.C.textures.statusbarBG)
  bg:SetAllPoints()
  s.bg = bg
  --backdrop
  CreateBackdrop(s)
  --attributes
  s.colorPower = self.cfg.addpowerbar.colorPower
  s.bg.multiplier = L.C.colors.bgMultiplier
  return s
end
L.F.CreateAdditionalPowerBar = CreateAdditionalPowerBar

--CreateClassPower
local function CreateClassPower(self)
  if not self or not self.cfg.classpower or not self.cfg.classpower.enabled then return end
  local ss = {}
  for index = 1, 10 do
    --statusbar
    local s = CreateFrame('StatusBar', nil, self)
    s:SetStatusBarTexture(self.cfg.classpower.texture)
    s:SetOrientation(self.cfg.classpower.orientation or "HORIZONTAL")
    s:SetSize(unpack(self.cfg.classpower.size))
    local anchorTo, anchorFrom, offsetX, offsetY = unpack(self.cfg.classpower.point)
    s:SetPoint(anchorTo, self.Health, anchorFrom, offsetX + ((index - 1) * (s:GetWidth() + self.cfg.classpower.padding)), offsetY)
    --bg
    local bg = s:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(L.C.textures.statusbarBG)
    bg:SetAllPoints()
    if L.C.colors.power.bg then
      bg:SetVertexColor(unpack(L.C.colors.power.bg))
    end
    --backdrop
    CreateBackdrop(s)
    ss[index] = s
  end
  return ss
end
L.F.CreateClassPower = CreateClassPower

--CreatePowerBar
local function CreatePowerBar(self)
  if not self.cfg.powerbar or not self.cfg.powerbar.enabled then return end
  --statusbar
  local s = CreateFrame("StatusBar", nil, self)
  s:SetStatusBarTexture(L.C.textures.statusbar)
  s:SetSize(unpack(self.cfg.powerbar.size))
  s:SetOrientation(self.cfg.powerbar.orientation or "HORIZONTAL")
  SetPoint(s,self,self.cfg.powerbar.point)
  --bg
  local bg = s:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(L.C.textures.statusbarBG)
  bg:SetAllPoints()
  if L.C.colors.power.bg then
    bg:SetVertexColor(unpack(L.C.colors.power.bg))
  end
  s.bg = bg
  --backdrop
  CreateBackdrop(s)
  --attributes
  s.colorPower = self.cfg.powerbar.colorPower
  s.bg.multiplier = L.C.colors.bgMultiplier
  return s
end
L.F.CreatePowerBar = CreatePowerBar

local function CreateCostPrediction(self)
  local s = CreateFrame('StatusBar', nil, self.Power)
  s:SetReverseFill(true)
  s:SetPoint('TOP')
  s:SetPoint('BOTTOM')
  s:SetPoint('RIGHT', self.Power:GetStatusBarTexture())
  return s
end
L.F.CreateCostPrediction = CreateCostPrediction

local function SetCastBarColorShielded(self)
  self.__owner:SetStatusBarColor(unpack(L.C.colors.castbar.shielded))
  self.__owner.bg:SetVertexColor(unpack(L.C.colors.castbar.shieldedBG))
end

local function SetCastBarColorDefault(self)
  self.__owner:SetStatusBarColor(unpack(L.C.colors.castbar.default))
  self.__owner.bg:SetVertexColor(unpack(L.C.colors.castbar.defaultBG))
end

--CreateCastBar
local function CreateCastBar(self)
  if not self.cfg.castbar or not self.cfg.castbar.enabled then return end
  --statusbar
  local s = CreateFrame("StatusBar", nil, self)
  s:SetStatusBarTexture(L.C.textures.statusbar)
  s:SetFrameStrata("MEDIUM")
  s:SetSize(unpack(self.cfg.castbar.size))
  s:SetOrientation(self.cfg.castbar.orientation or "HORIZONTAL")
  SetPoint(s,self,self.cfg.castbar.point)
  s:SetStatusBarColor(unpack(L.C.colors.castbar.default))
  --bg
  local bg = s:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(L.C.textures.statusbar)
  bg:SetAllPoints()
  bg:SetVertexColor(unpack(L.C.colors.castbar.defaultBG)) --bg multiplier
  s.bg = bg
  --backdrop
  CreateBackdrop(s)
  --icon for player and target only
  if self.cfg.castbar.icon and self.cfg.castbar.icon.enabled then
    --icon
    local i = s:CreateTexture(nil,"BACKGROUND",nil,-8)
    i:SetSize(unpack(self.cfg.castbar.icon.size))
    SetPoint(i,s,self.cfg.castbar.icon.point)
    if self.cfg.castbar.icon.texCoord then
      i:SetTexCoord(unpack(self.cfg.castbar.icon.texCoord))
    else
      i:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end
    s.Icon = i
    --backdrop (for the icon)
    CreateBackdrop(s,i)
  end
  --shield
  local shield = s:CreateTexture(nil,"BACKGROUND",nil,-8)
  shield.__owner = s
  s.Shield = shield
  --use a trick here...we use the show/hide on the shield texture to recolor the castbar
  hooksecurefunc(shield,"Show",SetCastBarColorShielded)
  hooksecurefunc(shield,"Hide",SetCastBarColorDefault)
  --text
  if self.cfg.castbar.name and self.cfg.castbar.name.enabled then
    local cfg = self.cfg.castbar.name
    local name = CreateText(s,cfg.font,cfg.size,cfg.outline,cfg.align,cfg.noshadow)
    if cfg.points then
      SetPoints(name,s,cfg.points)
    else
      SetPoint(name,s,cfg.point)
    end
    s.Text = name
  end
  return s
end
L.F.CreateCastBar = CreateCastBar

local function CreateRaidMark(self)
  if not self.cfg.raidmark or not self.cfg.raidmark.enabled then return end
  return CreateIcon(self.Health,"OVERLAY",-8,self.cfg.raidmark.size,self.cfg.raidmark.point)
end
L.F.CreateRaidMark = CreateRaidMark

--CreateNameText
local function CreateNameText(self)
  if not self.cfg.healthbar or not self.cfg.healthbar.name or not self.cfg.healthbar.name.enabled then return end
  local cfg = self.cfg.healthbar.name
  local text = CreateText(self.rAbsorbBar or self.Health,cfg.font,cfg.size,cfg.outline,cfg.align,cfg.noshadow)
  if cfg.points then
    SetPoints(text,self.rAbsorbBar or self.Health,cfg.points)
  else
    SetPoint(text,self.rAbsorbBar or self.Health,cfg.point)
  end
  self:Tag(text, cfg.tag)
end
L.F.CreateNameText = CreateNameText

--CreateHealthText
local function CreateHealthText(self)
  if not self.cfg.healthbar or not self.cfg.healthbar.health or not self.cfg.healthbar.health.enabled then return end
  local cfg = self.cfg.healthbar.health
  local text = CreateText(self.rAbsorbBar or self.Health,cfg.font,cfg.size,cfg.outline,cfg.align,cfg.noshadow)
  if cfg.points then
    SetPoints(text,self.rAbsorbBar or self.Health,cfg.points)
  else
    SetPoint(text,self.rAbsorbBar or self.Health,cfg.point)
  end
  self:Tag(text, cfg.tag)
end
L.F.CreateHealthText = CreateHealthText

--CreatePowerText
local function CreatePowerText(self)
  if not self.cfg.powerbar or not self.cfg.powerbar.power or not self.cfg.powerbar.power.enabled then return end
  local cfg = self.cfg.powerbar.power
  local text = CreateText(self.Power,cfg.font,cfg.size,cfg.outline,cfg.align,cfg.noshadow)
  if cfg.points then
    SetPoints(text,self.Power,cfg.points)
  else
    SetPoint(text,self.Power,cfg.point)
  end
  self:Tag(text, cfg.tag)
end
L.F.CreatePowerText = CreatePowerText

--PostCreateAura
local function PostCreateAura(self,button)
  local bg = button:CreateTexture(nil,"BACKGROUND",nil,-8)
  bg:SetTexture(L.C.textures.aura)
  bg:SetVertexColor(0,0,0)
  bg:SetPoint("TOPLEFT", -self.size/4, self.size/4)
  bg:SetPoint("BOTTOMRIGHT", self.size/4, -self.size/4)
  button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  button.count:SetFont(STANDARD_TEXT_FONT, self.size/1.65, "OUTLINE")
  button.count:SetShadowColor(0,0,0,0.6)
  button.count:SetShadowOffset(1,-1)
  button.count:ClearAllPoints()
  button.count:SetPoint("BOTTOMRIGHT", self.size/10, -self.size/10)
  button:SetFrameStrata("LOW")
end

--CreateBuffs
local function CreateBuffs(self)
  if not self.cfg.buffs or not self.cfg.buffs.enabled then return end
  local cfg = self.cfg.buffs
  local frame = CreateFrame("Frame", nil, self)
  SetPoint(frame,self,cfg.point)
  frame.num = cfg.num
  frame.size = cfg.size
  frame.spacing = cfg.spacing
  frame.initialAnchor = cfg.initialAnchor
  frame["growth-x"] = cfg.growthX
  frame["growth-y"] = cfg.growthY
  frame.disableCooldown = cfg.disableCooldown
  frame.filter = cfg.filter
  frame.CustomFilter = cfg.CustomFilter
  frame.PostCreateIcon = cfg.PostCreateAura or PostCreateAura
  --frame.PostUpdateIcon = PostUpdateBuff
  frame:SetSize(CalcFrameSize(cfg.num,cfg.cols,cfg.size,cfg.size,cfg.spacing,0))
  --local t = frame:CreateTexture(nil,"BACKGROUND",nil,-8)
  --t:SetAllPoints()
  --t:SetColorTexture(0,1,0,0.2)
  return frame
end
L.F.CreateBuffs = CreateBuffs

--CreateDebuffs
local function CreateDebuffs(self)
  if not self.cfg.debuffs or not self.cfg.debuffs.enabled then return end
  local cfg = self.cfg.debuffs
  local frame = CreateFrame("Frame", nil, self)
  SetPoint(frame,self,cfg.point)
  frame.num = cfg.num
  frame.size = cfg.size
  frame.spacing = cfg.spacing
  frame.initialAnchor = cfg.initialAnchor
  frame["growth-x"] = cfg.growthX
  frame["growth-y"] = cfg.growthY
  frame.disableCooldown = cfg.disableCooldown
  frame.filter = cfg.filter
  frame.CustomFilter = cfg.CustomFilter
  frame.PostCreateIcon = cfg.PostCreateAura or PostCreateAura
  --frame.PostUpdateIcon = PostUpdateDebuff
  frame:SetSize(CalcFrameSize(cfg.num,cfg.cols,cfg.size,cfg.size,cfg.spacing,0))
  --local t = frame:CreateTexture(nil,"BACKGROUND",nil,-8)
  --t:SetAllPoints()
  --t:SetColorTexture(1,0,0,0.2)
  return frame
end
L.F.CreateDebuffs = CreateDebuffs

--SetupHeader
local function SetupHeader(self)
  if not self.settings.setupHeader then return end
  self:RegisterForClicks("AnyDown")
  self:SetScript("OnEnter", UnitFrame_OnEnter)
  self:SetScript("OnLeave", UnitFrame_OnLeave)
end
L.F.SetupHeader = SetupHeader

--SetupFrame
local function SetupFrame(self)
  if not self.settings.setupFrame then return end
  self:SetSize(unpack(self.cfg.size))
  SetPoint(self,nil,self.cfg.point)
  self:SetScale(self.cfg.scale)
end
L.F.SetupFrame = SetupFrame

--CreateDragFrame
local function CreateDragFrame(self)
  if not self.settings.createDrag then return end
  rLib:CreateDragFrame(self, L.dragFrames, -2, true)
end
L.F.CreateDragFrame = CreateDragFrame

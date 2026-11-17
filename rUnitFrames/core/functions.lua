
-- rUnitFrames: core/functions
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...

local floor, unpack, type = floor, unpack, type

--yikes, secrets! avoid touching them to  prevent taints
local issecretvalue = issecretvalue or function() return false end

--functions container
L.F = {}

-----------------------------
-- Functions
-----------------------------

local function CalcFrameSize(numButtons,numCols,buttonWidth,buttonHeight,buttonMargin,framePadding)
  local numRows = ceil(numButtons/numCols)
  local frameWidth = numCols*buttonWidth + (numCols-1)*buttonMargin + 2*framePadding
  local frameHeight = numRows*buttonHeight + (numRows-1)*buttonMargin + 2*framePadding
  return frameWidth, frameHeight
end

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

local function SetPoints(self,relativeTo,points)
  for i, point in next, points do
    SetPoint(self,relativeTo,point)
  end
end

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

local function CreateIconBackdrop(parent, icon)
  local backdrop = L.C.backdrop
  local inset = backdrop.inset or 5
  local iconWidth, iconHeight = icon:GetSize()
  local point, relativeTo, relativePoint, x, y = icon:GetPoint(1)
  if not point then return end

  local xOffset, yOffset = 0, 0
  if point:find("LEFT", 1, true) then
    xOffset = -inset
  elseif point:find("RIGHT", 1, true) then
    xOffset = inset
  end
  if point:find("TOP", 1, true) then
    yOffset = inset
  elseif point:find("BOTTOM", 1, true) then
    yOffset = -inset
  end

  local frame = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
  frame:SetFrameLevel(math.max(0, parent:GetFrameLevel() - 1))
  frame:SetSize(iconWidth + inset * 2, iconHeight + inset * 2)
  frame:SetPoint(point, relativeTo or parent, relativePoint or point, (x or 0) + xOffset, (y or 0) + yOffset)
  frame:SetBackdrop(backdrop)
  frame:SetBackdropColor(unpack(backdrop.bgColor))
  frame:SetBackdropBorderColor(unpack(backdrop.edgeColor))
  return frame
end

--CreateIcon
local function CreateIcon(self,layer,sublevel,size,point)
  local icon = self:CreateTexture(nil,layer,nil,sublevel)
  icon:SetSize(unpack(size))
  SetPoint(icon,self,point)
  return icon
end

--UnitThreatSituation is sometimes secret
local function GetThreatStatus(unit, mobUnit)
  local status = UnitThreatSituation(unit, mobUnit)
  if issecretvalue(status) then return end
  return status
end

--don't pass .colorThreat to oUF, it will throw as soon as the threat state is secret.
local function PostUpdateHealthColor(self, unit)
  if not unit or not self.__colorThreat then return end
  local colors = L.C.colors.healthbar
  if self.__colorThreatInvers and GetThreatStatus("player", unit) == 3 then
    self:SetStatusBarColor(unpack(colors.threatInvers))
    self.bg:SetVertexColor(unpack(colors.threatInversBG))
  elseif GetThreatStatus(unit) == 3 then
    self:SetStatusBarColor(unpack(colors.threat))
    self.bg:SetVertexColor(unpack(colors.threatBG))
  elseif colors.defaultBG then
    --reset the background in case it was tinted by a previous threat state
    self.bg:SetVertexColor(unpack(colors.defaultBG))
  end
end

local function UpdateThreat(self, event, unit)
  if unit and unit ~= self.__unit then return end
  local health = self.Health
  if health and health.ForceUpdate then
    health:ForceUpdate()
  end
end
L.F.UpdateThreat = UpdateThreat

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

--re-apply the alt power bar color
local function AltPowerBarPostUpdate(self, unit)
  local r, g, b = 1, 0, 1
  local barID = unit and UnitPowerBarID(unit)
  if barID and barID > 0 and GetUnitPowerBarTextureInfo then
    local _, tr, tg, tb = GetUnitPowerBarTextureInfo(unit, 2)
    if tb then r, g, b = tr, tg, tb end
  end
  self:SetStatusBarColor(r, g, b)
  if self.bg then
    local mu = self.bg.multiplier or 0.3
    self.bg:SetVertexColor(r*mu, g*mu, b*mu)
  end
end

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
  s.PostUpdate = AltPowerBarPostUpdate
  s.bg.multiplier = L.C.colors.bgMultiplier
  return s
end
L.F.CreateAltPowerBar = CreateAltPowerBar

--like health the absorb bar cannot be disabled
local function CreateAbsorbBar(self)
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

--disabling the healthbar makes no sense, no check for enabled
local function CreateHealthBar(self)
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
  s.frequentUpdates = self.cfg.healthbar.frequentUpdates or false
  --threat coloring is done by the layout (secret-safe), see PostUpdateHealthColor
  s.__colorThreat = self.cfg.healthbar.colorThreat
  s.__colorThreatInvers = self.cfg.healthbar.colorThreatInvers
  s.bg.multiplier = L.C.colors.bgMultiplier
  --hooks
  s.PostUpdateColor = PostUpdateHealthColor
  if s.__colorThreat then
    self:RegisterEvent("PLAYER_REGEN_ENABLED", L.F.UpdateThreat, true)
    self:RegisterEvent("PLAYER_REGEN_DISABLED", L.F.UpdateThreat, true)
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", L.F.UpdateThreat)
    self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", L.F.UpdateThreat)
  end
  return s
end
L.F.CreateHealthBar = CreateHealthBar

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

local function CreateOverDamageAbsorbIndicator(self)
  local s = self.Health:CreateTexture(nil, "OVERLAY")
  s:SetPoint('TOP')
  s:SetPoint('BOTTOM')
  s:SetPoint('LEFT', self.Health, 'RIGHT')
  s:SetWidth(10)
  return s
end
L.F.CreateOverDamageAbsorbIndicator = CreateOverDamageAbsorbIndicator

local function CreateOverHealAbsorbIndicator(self)
  local s = self.Health:CreateTexture(nil, "OVERLAY")
  s:SetPoint('TOP')
  s:SetPoint('BOTTOM')
  s:SetPoint('RIGHT', self.Health, 'LEFT')
  s:SetWidth(10)
  return s
end
L.F.CreateOverHealAbsorbIndicator = CreateOverHealAbsorbIndicator

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
  s.frequentUpdates = self.cfg.powerbar.frequentUpdates or false
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

--enemy casts are either secret or boolean, so we can't set shield from "notInterruptible"
local function UpdateCastBarShield(castbar, notInterruptible)
  local overlay, overlayBG = castbar.ShieldOverlay, castbar.ShieldOverlayBG
  if not overlay then return end
  if issecretvalue(notInterruptible) or type(notInterruptible) == "boolean" then
    overlay:SetAlphaFromBoolean(notInterruptible, 1, 0)
    overlayBG:SetAlphaFromBoolean(notInterruptible, 1, 0)
  else
    overlay:SetAlpha(0)
    overlayBG:SetAlpha(0)
  end
end

local function CastBarPostCastStart(self, unit, spellID, notInterruptible)
  UpdateCastBarShield(self, notInterruptible)
end

local function CastBarPostCastInterruptible(self, unit, spellID, notInterruptible)
  UpdateCastBarShield(self, notInterruptible)
end

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
    local i = s:CreateTexture(nil,"ARTWORK",nil,-8)
    i:SetSize(unpack(self.cfg.castbar.icon.size))
    SetPoint(i,s,self.cfg.castbar.icon.point)
    if self.cfg.castbar.icon.texCoord then
      i:SetTexCoord(unpack(self.cfg.castbar.icon.texCoord))
    else
      i:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end
    s.Icon = i
    -- Anchor the backdrop to the castbar, not the icon texture, to avoid taint.
    s.IconBackdrop = CreateIconBackdrop(s, i)
  end
  --use SetAlphaFromBoolean to be able to use secrets
  local shield = s:CreateTexture(nil,"ARTWORK",nil,1)
  shield:SetTexture(L.C.textures.statusbar)
  shield:SetAllPoints(s:GetStatusBarTexture())
  shield:SetVertexColor(unpack(L.C.colors.castbar.shielded))
  shield:SetAlpha(0)
  s.ShieldOverlay = shield
  local shieldBG = s:CreateTexture(nil,"BACKGROUND",nil,1)
  shieldBG:SetTexture(L.C.textures.statusbar)
  shieldBG:SetAllPoints()
  shieldBG:SetVertexColor(unpack(L.C.colors.castbar.shieldedBG))
  shieldBG:SetAlpha(0)
  s.ShieldOverlayBG = shieldBG
  s.PostCastStart = CastBarPostCastStart
  s.PostCastInterruptible = CastBarPostCastInterruptible
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

local function CreateHealthText(self)
  if not self.cfg.healthbar or not self.cfg.healthbar.health or not self.cfg.healthbar.health.enabled then return end
  local cfg = self.cfg.healthbar.health
  local text = CreateText(self.rAbsorbBar or self.Health,cfg.font,cfg.size,cfg.outline,cfg.align,cfg.noshadow)
  text.frequentUpdates = self.cfg.healthbar.frequentUpdates or false
  if cfg.points then
    SetPoints(text,self.rAbsorbBar or self.Health,cfg.points)
  else
    SetPoint(text,self.rAbsorbBar or self.Health,cfg.point)
  end
  self:Tag(text, cfg.tag)
end
L.F.CreateHealthText = CreateHealthText

local function CreatePowerText(self)
  if not self.cfg.powerbar or not self.cfg.powerbar.power or not self.cfg.powerbar.power.enabled then return end
  local cfg = self.cfg.powerbar.power
  local text = CreateText(self.Power,cfg.font,cfg.size,cfg.outline,cfg.align,cfg.noshadow)
  text.frequentUpdates = self.cfg.powerbar.frequentUpdates or false
  if cfg.points then
    SetPoints(text,self.Power,cfg.points)
  else
    SetPoint(text,self.Power,cfg.point)
  end
  self:Tag(text, cfg.tag)
end
L.F.CreatePowerText = CreatePowerText

local function PostCreateAuraButton(element, button)
  local size = element.size or 16
  local bg = button:CreateTexture(nil,"BACKGROUND",nil,-8)
  bg:SetTexture(L.C.textures.aura)
  bg:SetVertexColor(0,0,0)
  bg:SetPoint("TOPLEFT", -size/4, size/4)
  bg:SetPoint("BOTTOMRIGHT", size/4, -size/4)
  button.Background = bg
  if button.Border then
    button.Border:ClearAllPoints()
    button.Border:SetPoint("TOPLEFT", -size/4, size/4)
    button.Border:SetPoint("BOTTOMRIGHT", size/4, -size/4)
  end
  if button.Icon then
    button.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  end
  if button.Count then
    button.Count:SetFont(STANDARD_TEXT_FONT, size/1.65, "OUTLINE")
    button.Count:SetShadowColor(0,0,0,0.6)
    button.Count:SetShadowOffset(1,-1)
    button.Count:ClearAllPoints()
    button.Count:SetPoint("BOTTOMRIGHT", size/10, -size/10)
  end
  local duration = button.Time or button.Duration
  if duration and element.showDuration == false then
    duration:Hide()
  end
end

--auras are now client-side AuraContainers
local function CreateAuraElement(self, cfg, defaultFilter)
  --oUF renamed CreateAuras to CreateAurasElement (keep old as fallback just in case)
  local create = self.CreateAurasElement or self.CreateAuras
  if not create then return end
  local width, height = CalcFrameSize(cfg.num, cfg.cols, cfg.size, cfg.size, cfg.spacing, 0)
  local element = create(self, {
    initialAnchor = cfg.initialAnchor or "TOPLEFT",
    growthX = cfg.growthX or "RIGHT",
    growthY = cfg.growthY or "DOWN",
    layoutLimit = width, --wrap after cfg.cols buttons
  })
  element:SetSize(width, height)
  SetPoint(element, self, cfg.point)
  --duration format
  local secondsFormatter = C_StringUtil.CreateSecondsFormatter();
  secondsFormatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.None);
  secondsFormatter:SetStripIntervalWhitespace(Enum.SecondsFormatterIntervalWhitespace.Strip);
  secondsFormatter:SetMillisecondsThreshold(5);
  --button / group options (see oUF/elements/auras.lua)
  element.size = cfg.size
  element.elementSpacing = cfg.spacing
  element.lineSpacing = cfg.spacing
  element.maxFrameCount = cfg.num
  element.showCount = true
  element.durationFormatter = secondsFormatter
  element.showDuration = cfg.showDuration == true
  element.disableCooldown = cfg.disableCooldown
  element.showBuffBorder = cfg.showBuffBorder
  element.showDebuffBorder = cfg.showDebuffBorder
  element.dispelBorderStyle = cfg.dispelBorderStyle or Enum.CustomAuraButtonDispelTypeTextureStyle.Border
  element.showStealableBorder = cfg.showStealableBorder
  element.tooltipAnchor = cfg.tooltipAnchor
  element.PostCreateButton = cfg.PostCreateButton or PostCreateAuraButton
  element:AddGroup(cfg.filter or defaultFilter, {
    showDuration = cfg.showDuration == true,
    dispelBorderStyle = element.dispelBorderStyle,
  })
  return element
end

local function CreateBuffs(self)
  if not self.cfg.buffs or not self.cfg.buffs.enabled then return end
  return CreateAuraElement(self, self.cfg.buffs, "HELPFUL")
end
L.F.CreateBuffs = CreateBuffs

local function CreateDebuffs(self)
  if not self.cfg.debuffs or not self.cfg.debuffs.enabled then return end
  return CreateAuraElement(self, self.cfg.debuffs, "HARMFUL")
end
L.F.CreateDebuffs = CreateDebuffs

local function UnitFrameOnEnter(self)
  if GameTooltip:IsForbidden() then return end
  local unit = self.__unit or SecureButton_GetUnit(self)
  if not unit then return end
  GameTooltip_SetDefaultAnchor(GameTooltip, self)
  GameTooltip:SetUnit(unit)
end

local function UnitFrameOnLeave(self)
  if GameTooltip:IsForbidden() then return end
  GameTooltip:FadeOut()
end

local function SetupHeader(self)
  if not self.settings.setupHeader then return end
  --Group children are secure too; register their click buttons whenever out of combat.
  if not InCombatLockdown() then
    self:RegisterForClicks("AnyDown")
  end
  --HookScript as header children inherit SecureHandlerEnterLeaveTemplate
  self:HookScript("OnEnter", UnitFrameOnEnter)
  self:HookScript("OnLeave", UnitFrameOnLeave)
end
L.F.SetupHeader = SetupHeader

local function SetupFrame(self)
  if not self.settings.setupFrame then return end
  self:SetSize(unpack(self.cfg.size))
  --nameplate unit frames come with SetAllPoints() from oUF, clear it or the size is ignored
  self:ClearAllPoints()
  SetPoint(self,nil,self.cfg.point)
  self:SetScale(self.cfg.scale)
end
L.F.SetupFrame = SetupFrame

local function CreateDragFrame(self)
  if not self.settings.createDrag then return end
  rLib:CreateDragFrame(self, L.dragFrames, -2, true)
end
L.F.CreateDragFrame = CreateDragFrame

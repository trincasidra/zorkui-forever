local A, L = ...
local oUF = L.oUF or oUF
if not oUF then return end

local C_UnitAuras, C_CurveUtil = C_UnitAuras, C_CurveUtil
--use these two functions as aura data is sometimes secret
local GetUnitAuraInstanceIDs = C_UnitAuras and C_UnitAuras.GetUnitAuraInstanceIDs
local GetAuraDispelTypeColor = C_UnitAuras and C_UnitAuras.GetAuraDispelTypeColor
local CreateColorCurve = C_CurveUtil and C_CurveUtil.CreateColorCurve
local unpack = unpack

local FILTER_PLAYER_CAN_DISPEL = "HARMFUL|RAID"
local FILTER_HAS_DISPEL_TYPE = "HARMFUL|DISPELLABLE"

--dispel type ids, they are the x values of the color curve
local DISPEL_TYPES = {
  { id = 1, name = "Magic" },
  { id = 2, name = "Curse" },
  { id = 3, name = "Disease" },
  { id = 4, name = "Poison" },
  { id = 9, name = "Enrage" },
  { id = 11, name = "Bleed" },
}
--ids mapped to the "no highlight" color (step curves hold the previous value between points)
local NO_TYPE_IDS = { 0, 5, 10, 12 }

local origColors = {}
local origBorderColors = {}
local curves = {}

local function GetDispelColor(name)
  local c = oUF.colors.dispel and oUF.colors.dispel[name]
  if c and c.GetRGB then
    return c:GetRGB()
  end
  local d = DebuffTypeColor and DebuffTypeColor[name]
  if d then
    return d.r, d.g, d.b
  end
end

local function BuildCurve(self, r, g, b, a)
  local alpha = self.DebuffHighlightAlpha or 1
  local curve = CreateColorCurve()
  curve:SetType(Enum.LuaCurveType.Step)
  local none = CreateColor(r or 0, g or 0, b or 0, a or 1)
  for _, id in next, NO_TYPE_IDS do
    curve:AddPoint(id, none)
  end
  for _, info in next, DISPEL_TYPES do
    local dr, dg, db = GetDispelColor(info.name)
    if dr then
      curve:AddPoint(info.id, CreateColor(dr, dg, db, alpha))
    else
      curve:AddPoint(info.id, none)
    end
  end
  return curve
end

--Apply (r, g, b sometimes are secret)
local function Apply(self, r, g, b, a)
  local hl = self.DebuffHighlight
  if self.DebuffHighlightBackdrop or self.DebuffHighlightBackdropBorder then
    if self.DebuffHighlightBackdrop then
      hl:SetBackdropColor(r, g, b, a)
    end
    if self.DebuffHighlightBackdropBorder then
      hl:SetBackdropBorderColor(r, g, b, a)
    end
  else
    hl:SetVertexColor(r, g, b, a)
  end
end

local function Reset(self)
  if self.DebuffHighlightBackdrop or self.DebuffHighlightBackdropBorder then
    if self.DebuffHighlightBackdrop then
      self.DebuffHighlight:SetBackdropColor(unpack(origColors[self]))
    end
    if self.DebuffHighlightBackdropBorder then
      self.DebuffHighlight:SetBackdropBorderColor(unpack(origBorderColors[self]))
    end
  else
    self.DebuffHighlight:SetVertexColor(unpack(origColors[self]))
  end
end

local function Update(self, event, unit)
  if not unit or unit ~= self.__unit or not self.DebuffHighlightFilter then return end
  local filter = self.DebuffHighlightFilter and FILTER_PLAYER_CAN_DISPEL or FILTER_HAS_DISPEL_TYPE
  local ids = GetUnitAuraInstanceIDs(unit, filter, 1)
  local auraInstanceID = ids and ids[1]
  if auraInstanceID then
    local color = GetAuraDispelTypeColor(unit, auraInstanceID, curves[self])
    if color then
      local r, g, b = color:GetRGB()
      --alpha is ours (not secret), BackdropTemplateMixin tests "a or 1"
      Apply(self, r, g, b, self.DebuffHighlightAlpha or 1)
      return
    end
  end
  Reset(self)
end

local function Enable(self)
  if not self.DebuffHighlight then return end
  if not (GetUnitAuraInstanceIDs and GetAuraDispelTypeColor and CreateColorCurve) then return end
  local r, g, b, a
  if self.DebuffHighlightBackdrop or self.DebuffHighlightBackdropBorder then
    origColors[self] = { self.DebuffHighlight:GetBackdropColor() }
    origBorderColors[self] = { self.DebuffHighlight:GetBackdropBorderColor() }
    if self.DebuffHighlightBackdropBorder then
      r, g, b, a = unpack(origBorderColors[self])
    else
      r, g, b, a = unpack(origColors[self])
    end
  else
    origColors[self] = { self.DebuffHighlight:GetVertexColor() }
    r, g, b, a = unpack(origColors[self])
  end
  curves[self] = curves[self] or BuildCurve(self, r, g, b, a)
  self:RegisterEvent("UNIT_AURA", Update)
  return true
end

local function Disable(self)
  if self.DebuffHighlight then
    self:UnregisterEvent("UNIT_AURA", Update)
  end
end

oUF:AddElement("DebuffHighlight", Update, Enable, Disable)

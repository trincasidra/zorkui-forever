-- rStyle: core

local A, L = ...

local buttonSize = NUM_ACTIONBAR_BUTTONS or 12
local debuffColors = DebuffTypeColor or {}
local noOperation = function() end
local mediaPath = "Interface\\AddOns\\rUnitFramesConfig\\media\\"
local backdropConfig = {
  bgFile = mediaPath .. "backdrop",
  edgeFile = mediaPath .. "backdrop_edge",
  tile = false,
  tileSize = 0,
  edgeSize = 5,
  insets = {left = 5, right = 5, top = 5, bottom = 5},
}
local backdropColor = {0, 0, 0, 0.8}

local actionPrefixes = {
  "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
  "MultiBarLeftButton", "MultiBarRightButton", "MultiBar5Button",
  "MultiBar6Button", "PetActionButton", "StanceButton", "PossessButton",
  "OverrideActionBarButton", "ExtraActionButton",
}

local microButtonNames = {
  "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
  "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
  "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton",
  "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
  "ProfessionMicroButton", "PlayerSpellsMicroButton", "LegacyMicroButton",
  "HousingMicroButton",
}

local function SkinButton(button, cropIcon, debuffIndex, preserveNormal)
  if not button or not button.CreateTexture then return end
  if not button.__rStyleBackdrop then
    local backdrop = CreateFrame("Frame", nil, button, BackdropTemplateMixin and "BackdropTemplate")
    backdrop:SetAllPoints(button)
    backdrop:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
    backdrop:SetBackdrop(backdropConfig)
    backdrop:SetBackdropColor(unpack(backdropColor))
    backdrop:SetBackdropBorderColor(unpack(backdropColor))
    button.__rStyleBackdrop = backdrop
  end

  local buttonName = button.GetName and button:GetName()
  local icon = button.icon or button.Icon
  if not icon and buttonName then
    icon = _G[buttonName .. "Icon"] or _G[buttonName .. "IconTexture"]
  end
  if icon and cropIcon and not icon.__rStyleCropped then
    icon:SetTexCoord(0.125, 0.875, 0.125, 0.875)
    icon.__rStyleCropped = true
  end

  local normalTexture = button.GetNormalTexture and button:GetNormalTexture()
  if normalTexture and not preserveNormal then
    normalTexture:Hide()
    normalTexture.Show = noOperation
  end

  if buttonName then
    local auraBorder = button.Border or button.IconBorder or _G[buttonName .. "Border"] or _G[buttonName .. "IconBorder"]
    if auraBorder and auraBorder.Hide then
      auraBorder:Hide()
      auraBorder.Show = noOperation
    end
  end

  local red, green, blue = unpack(backdropColor)
  if debuffIndex and UnitAura then
    local _, _, _, dispelType = UnitAura("player", debuffIndex, "HARMFUL")
    local color = dispelType and debuffColors[dispelType]
    if color then
      red, green, blue = color.r or color[1], color.g or color[2], color.b or color[3]
    end
  end
  button.__rStyleBackdrop:SetBackdropBorderColor(red, green, blue, 0.8)
end

local function SkinActionButtons()
  for _, prefix in ipairs(actionPrefixes) do
    local limit = prefix == "PetActionButton" and (NUM_PET_ACTION_SLOTS or 10)
      or prefix == "StanceButton" and (NUM_STANCE_SLOTS or 10)
      or prefix == "PossessButton" and (NUM_POSSESS_SLOTS or 2)
      or prefix == "OverrideActionBarButton" and 6
      or prefix == "ExtraActionButton" and 1
      or buttonSize
    for index = 1, limit do SkinButton(_G[prefix .. index], true) end
  end
  SkinButton(ZoneAbilityFrame and ZoneAbilityFrame.SpellButton, true)
end

local function SkinBuffButtons()
  for index = 1, (BUFF_MAX_DISPLAY or 32) do SkinButton(_G["BuffButton" .. index], true) end
  for index = 1, (NUM_TEMP_ENCHANTS or 3) do SkinButton(_G["TempEnchant" .. index], true) end
end

local function SkinDebuffButton(button, index)
  if type(button) == "string" then button = _G[button] end
  if not button and index then button = _G["DebuffButton" .. index] end
  local buttonName = button and button.GetName and button:GetName()
  local auraIndex = index or tonumber(buttonName and buttonName:match("DebuffButton(%d+)$"))
    or (button and button.GetID and button:GetID())
  SkinButton(button, true, auraIndex)
end

local function SkinDebuffButtons()
  for index = 1, (DEBUFF_MAX_DISPLAY or 16) do SkinDebuffButton(_G["DebuffButton" .. index], index) end
end

local function HideArtwork(region)
  if not region or not region.Hide then return end
  region:Hide()
  region.Show = noOperation
end

local function SkinMicroButton(button)
  if not button then return end
  SkinButton(button, false, nil, true)
  HideArtwork(button.Background)
  HideArtwork(button.PushedBackground)
  HideArtwork(button.Shadow)
  HideArtwork(button.PushedShadow)
end

local function SkinBagButton(button)
  if not button then return end
  SkinButton(button, true)
  HideArtwork(button.Background)
  HideArtwork(button.Border)
  HideArtwork(button.IconBorder)
  if button.GetPushedTexture then
    HideArtwork(button:GetPushedTexture())
  end
end

local function SkinMicroAndBags()
  if MicroMenu then
    HideArtwork(MicroMenu.BorderArt)
    HideArtwork(MicroMenu.BackgroundArt)
  end
  if BagsBar then
    HideArtwork(BagsBar.BorderArt)
    HideArtwork(BagsBar.BackgroundArt)
    BagsBar.useDividers = false
    if BagsBar.HorizontalDividersPool then
      BagsBar.HorizontalDividersPool:ReleaseAll()
    end
    if BagsBar.VerticalDividersPool then
      BagsBar.VerticalDividersPool:ReleaseAll()
    end
  end
  for _, name in ipairs(microButtonNames) do SkinMicroButton(_G[name]) end
  if type(MICRO_BUTTONS) == "table" then
    for _, name in ipairs(MICRO_BUTTONS) do SkinMicroButton(type(name) == "string" and _G[name] or name) end
  end
  SkinBagButton(MainMenuBarBackpackButton)
  for index = 0, 3 do SkinBagButton(_G["CharacterBag" .. index .. "Slot"]) end
  SkinBagButton(CharacterReagentBag0Slot)
  SkinBagButton(KeyRingButton)
end

local function HookUpdates()
  if type(hooksecurefunc) ~= "function" then return end
  local function Hook(name, callback)
    if type(_G[name]) == "function" then hooksecurefunc(name, callback) end
  end
  Hook("ActionButton_Update", function(button) SkinButton(button, true) end)
  Hook("ActionButton_UpdateUsable", function(button) SkinButton(button, true) end)
  Hook("BuffFrame_UpdateAllBuffAnchors", SkinBuffButtons)
  Hook("DebuffButton_UpdateAnchors", SkinDebuffButton)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:SetScript("OnEvent", function(_, event, unit)
  if event == "PLAYER_LOGIN" then HookUpdates() end
  if event == "UNIT_AURA" then
    if unit ~= "player" then return end
    SkinBuffButtons()
    SkinDebuffButtons()
    return
  end
  SkinActionButtons()
  SkinBuffButtons()
  SkinDebuffButtons()
  SkinMicroAndBags()
end)
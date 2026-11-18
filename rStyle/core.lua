-- rStyle: core

local A, L = ...

local buttonSize = NUM_ACTIONBAR_BUTTONS or 12
local debuffColors = DebuffTypeColor or {}
local fallbackDebuffColors = {
  Magic = {0.2, 0.6, 1},
  Curse = {0.6, 0, 1},
  Disease = {0.6, 0.4, 0},
  Poison = {0, 0.6, 0},
  Bleed = {1, 0, 0},
}
local issecretvalue = issecretvalue or function() return false end
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

local function SkinButton(button, cropIcon, preserveNormal, auraIcon)
  if not button or not button.CreateTexture then return end
  if not button.__rStyleBackdrop then
    local backdrop = CreateFrame("Frame", nil, button, BackdropTemplateMixin and "BackdropTemplate")
    if auraIcon then
      backdrop:SetSize(40, 40)
      backdrop:SetPoint("CENTER", auraIcon, "CENTER")
    else
      backdrop:SetAllPoints(button)
    end
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
  SkinButton(button, true)
end

local function SkinDebuffButtons()
  for index = 1, (DEBUFF_MAX_DISPLAY or 16) do SkinDebuffButton(_G["DebuffButton" .. index], index) end
end

local poisonSpells = {2823, 3408, 5761, 8679, 8687, 157584}

local function IsPoisonEnchant(button)
  local info = button.buttonInfo
  if not info or not C_Item or not C_Item.GetWeaponEnchantInfo or not C_Spell or not C_Spell.GetSpellTexture then return false end
  local inventorySlot = info.ID
  if issecretvalue(inventorySlot) or type(inventorySlot) ~= "number" or inventorySlot < 16 or inventorySlot > 18 then return false end
  local enchants = C_Item.GetWeaponEnchantInfo(inventorySlot - 16)
  if not enchants or #enchants ~= 1 then return false end
  local icon = enchants[1].enchantIconID
  if issecretvalue(icon) or not icon then return false end
  for _, spellID in ipairs(poisonSpells) do
    local spellIcon = C_Spell.GetSpellTexture(spellID)
    if not issecretvalue(spellIcon) and spellIcon and icon == spellIcon then return true end
  end
  return false
end

local function SkinPlayerAuraFrames(frame)
  if not frame or not frame.auraFrames then return end
  for _, button in ipairs(frame.auraFrames) do
    if not button.isAuraAnchor and button.Icon and button.Duration then
      SkinButton(button, false, false, button.Icon)
      button.Icon:SetTexCoord(0.15, 0.85, 0.15, 0.85)
      if not button.__rStyleIconMask then
        local mask = button:CreateMaskTexture()
        mask:SetAtlas("UI-HUD-ActionBar-IconFrame-Mask", false)
        mask:SetSize(48, 48)
        mask:SetPoint("CENTER", button.Icon, "CENTER")
        button.Icon:AddMaskTexture(mask)
        button.__rStyleIconMask = mask
      end
      if button.DebuffBorder then button.DebuffBorder:Hide() end
      if button.TempEnchantBorder then button.TempEnchantBorder:Hide() end
      local auraType = button.auraType
      if issecretvalue(auraType) then auraType = nil end
      if auraType == "Debuff" or auraType == "DeadlyDebuff" then
        local dispelType = button.buttonInfo and button.buttonInfo.debuffType
        local color = not issecretvalue(dispelType) and dispelType and (debuffColors[dispelType] or fallbackDebuffColors[dispelType])
        local red, green, blue = 1, 0, 0
        if color then red, green, blue = color.r or color[1], color.g or color[2], color.b or color[3] end
        button.__rStyleBackdrop:SetBackdropBorderColor(red, green, blue, 1)
      end
      if auraType == "TempEnchant" then
        if IsPoisonEnchant(button) then
          button.__rStyleBackdrop:SetBackdropBorderColor(0.1, 0.9, 0.2, 1)
        else
          button.__rStyleBackdrop:SetBackdropBorderColor(0.7, 0.25, 0.9, 1)
        end
      end
      button.Duration:ClearAllPoints()
      button.Duration:SetPoint("TOP", button.Icon, "TOP", 0, -1)
      button.Duration:SetDrawLayer("OVERLAY", 7)
      local font, size = button.Duration:GetFont()
      if font and size then button.Duration:SetFont(font, size, "OUTLINE") end
    end
  end
end

local function SetupPlayerAuras(frame)
  if not frame or not frame.auraFrames then return end
  if not frame.__rStyleAuraHooked then
    if frame.UpdateAuraButtons then hooksecurefunc(frame, "UpdateAuraButtons", SkinPlayerAuraFrames) end
    if frame.UpdateGridLayout then hooksecurefunc(frame, "UpdateGridLayout", SkinPlayerAuraFrames) end
    frame.__rStyleAuraHooked = true
  end
  SkinPlayerAuraFrames(frame)
end

local function HideArtwork(region)
  if not region or not region.Hide then return end
  region:Hide()
  region.Show = noOperation
end

local function SkinMicroButton(button)
  if not button then return end
  SkinButton(button, false, true)
  if button.Background then button.Background:SetAlpha(0) end
  if button.PushedBackground then button.PushedBackground:SetAlpha(0) end
  if button.Shadow then button.Shadow:SetAlpha(0) end
  if button.PushedShadow then button.PushedShadow:SetAlpha(0) end
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
  SetupPlayerAuras(BuffFrame)
  SetupPlayerAuras(DebuffFrame)
end)
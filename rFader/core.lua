-- rFader: core

local A, L = ...

local cfg = L.C or {}
local buttonSize = NUM_ACTIONBAR_BUTTONS or 12
local faderGroups = {}
local hiddenAlpha = 0
local hoverAlpha = 1

local microButtonNames = {
  "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
  "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
  "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton",
  "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
}

local function AddUnique(list, value)
  if not value then return end
  for _, current in ipairs(list) do
    if current == value then return end
  end
  list[#list + 1] = value
end

local function AddNamedButtons(list, prefix, count)
  for index = 1, count or buttonSize do
    AddUnique(list, _G[prefix .. index])
  end
end

local function AddFaderGroup(frame, buttons, faderConfig)
  if not frame then return end
  for _, group in ipairs(faderGroups) do
    if group.frame == frame then
      group.config = faderConfig or group.config
      for _, button in ipairs(buttons) do AddUnique(group.buttons, button) end
      return
    end
  end
  faderGroups[#faderGroups + 1] = {
    frame = frame,
    buttons = buttons,
    config = faderConfig,
  }
end

local function FadeFrame(frame, targetAlpha)
  if not frame or frame.__rFaderTarget == targetAlpha then return end
  frame.__rFaderTarget = targetAlpha
  local animationGroup = frame.__rFaderAnimation
  if not animationGroup then
    animationGroup = frame:CreateAnimationGroup()
    local animation = animationGroup:CreateAnimation("Alpha")
    animation:SetDuration(0.18)
    animation:SetSmoothing("IN_OUT")
    animationGroup.__rFaderAlpha = animation
    frame.__rFaderAnimation = animationGroup
  end
  local animation = animationGroup.__rFaderAlpha
  animationGroup:Stop()
  animation:SetFromAlpha(frame:GetAlpha())
  animation:SetToAlpha(targetAlpha)
  animationGroup:SetScript("OnFinished", function() frame:SetAlpha(targetAlpha) end)
  animationGroup:Play()
end

local function FadeGroup(group, targetAlpha)
  FadeFrame(group.frame, targetAlpha)
end

local function GroupIsHovered(group)
  if group.frame.IsMouseOver and group.frame:IsMouseOver() then return true end
  for _, button in ipairs(group.buttons) do
    if button.IsMouseOver and button:IsMouseOver() then return true end
  end
  return false
end

local function UpdateGroupFade(group)
  local fadedAlpha = group.config and group.config.fadedAlpha
  if fadedAlpha == nil then fadedAlpha = hiddenAlpha end
  FadeGroup(group, GroupIsHovered(group) and hoverAlpha or fadedAlpha)
end

local function HookFaderGroup(group)
  local faderConfig = group.config or {}
  if faderConfig.enable == false then return end
  local fadedAlpha = faderConfig.fadedAlpha
  if fadedAlpha == nil then fadedAlpha = hiddenAlpha end
  FadeGroup(group, fadedAlpha)

  for _, button in ipairs(group.buttons) do
    if button.HookScript and not button.__rFaderHooked then
      button:HookScript("OnEnter", function() FadeGroup(group, hoverAlpha) end)
      button:HookScript("OnLeave", function()
        C_Timer.After(0.05, function() UpdateGroupFade(group) end)
      end)
      button.__rFaderHooked = true
    end
  end
  if group.frame.HookScript and not group.frame.__rFaderHooked then
    group.frame:HookScript("OnEnter", function() FadeGroup(group, hoverAlpha) end)
    group.frame:HookScript("OnLeave", function()
      C_Timer.After(0.05, function() UpdateGroupFade(group) end)
    end)
    group.frame.__rFaderHooked = true
  end
  UpdateGroupFade(group)
end

local function SetupFaders()
  local mainButtons = {}
  AddNamedButtons(mainButtons, "ActionButton")
  AddFaderGroup(_G.MainActionBar or MainMenuBar, mainButtons, cfg.mainActionBar)

  local bars = {
    {"MultiBarBottomLeft", "MultiBarBottomLeftButton", nil, "multiBarBottomLeft"},
    {"MultiBarBottomRight", "MultiBarBottomRightButton", nil, "multiBarBottomRight"},
    {"MultiBarLeft", "MultiBarLeftButton", nil, "multiBarLeft"},
    {"MultiBarRight", "MultiBarRightButton", nil, "multiBarRight"},
    {"MultiBar5", "MultiBar5Button", nil, "multiBar5"},
    {"MultiBar6", "MultiBar6Button", nil, "multiBar6"},
    {"PetActionBarFrame", "PetActionButton", nil, "petActionBar"},
    {"StanceBar", "StanceButton", "StanceBarFrame", "stanceBar"},
    {"OverrideActionBar", "OverrideActionBarButton", nil, "overrideActionBar"},
    {"ExtraActionBarFrame", "ExtraActionButton", nil, "extraActionBar"},
    {"PossessBarFrame", "PossessButton", nil, "possessBar"},
  }
  for _, bar in ipairs(bars) do
    local frame = _G[bar[1]] or (bar[3] and _G[bar[3]])
    local prefix = bar[2]
    local limit = prefix == "PetActionButton" and (NUM_PET_ACTION_SLOTS or 10)
      or prefix == "StanceButton" and (NUM_STANCE_SLOTS or 10)
      or prefix == "PossessButton" and (NUM_POSSESS_SLOTS or 2)
      or prefix == "OverrideActionBarButton" and 6
      or prefix == "ExtraActionButton" and 1
      or buttonSize
    local buttons = {}
    AddNamedButtons(buttons, prefix, limit)
    AddFaderGroup(frame, buttons, cfg[bar[4]])
  end

  local microButtons = {}
  for _, name in ipairs(microButtonNames) do AddUnique(microButtons, _G[name]) end
  if type(MICRO_BUTTONS) == "table" then
    for _, name in ipairs(MICRO_BUTTONS) do
      AddUnique(microButtons, type(name) == "string" and _G[name] or name)
    end
  end
  AddFaderGroup(_G.MicroMenu or MicroButtonAndBagsBar, microButtons, cfg.microMenu)

  local bagButtons = {}
  AddUnique(bagButtons, MainMenuBarBackpackButton)
  for index = 0, 3 do AddUnique(bagButtons, _G["CharacterBag" .. index .. "Slot"]) end
  local firstBagButton = bagButtons[1]
  local bagContainer = _G.BagsBar or (firstBagButton and firstBagButton.GetParent and firstBagButton:GetParent())
  AddFaderGroup(bagContainer, bagButtons, cfg.bagsBar)

  local statusContainers = {}
  AddUnique(statusContainers, _G.MainStatusTrackingBarContainer)
  AddUnique(statusContainers, _G.SecondaryStatusTrackingBarContainer)
  for _, container in ipairs(statusContainers) do
    local contents = {container}
    if container.GetChildren then
      for _, child in ipairs({container:GetChildren()}) do AddUnique(contents, child) end
    end
    local faderConfig = container == _G.MainStatusTrackingBarContainer and cfg.mainStatusTrackingBar or cfg.secondaryStatusTrackingBar
    AddFaderGroup(container, contents, faderConfig)
  end

  for _, group in ipairs(faderGroups) do HookFaderGroup(group) end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", SetupFaders)
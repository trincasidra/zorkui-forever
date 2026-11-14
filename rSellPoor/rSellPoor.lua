
-- rSellPoor: core
-- zork, 2018

-----------------------------
-- Variables
-----------------------------

local A, L = ...

-----------------------------
-- Functions
-----------------------------

local function OnEvent(self,event)
  if event == "MERCHANT_SHOW" then
    C_MerchantFrame.SellAllJunkItems()
  end
end

-----------------------------
-- Init
-----------------------------

--eventHandler
local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("MERCHANT_SHOW")
eventHandler:SetScript("OnEvent", OnEvent)
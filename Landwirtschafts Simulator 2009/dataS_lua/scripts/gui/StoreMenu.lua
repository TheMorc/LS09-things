StoreMenu = {}
local StoreMenu_mt = Class(StoreMenu)
function StoreMenu:new(backgroundOverlay)
  local instance = {}
  setmetatable(instance, StoreMenu_mt)
  instance.overlays = {}
  instance.overlayButtons = {}
  instance.backgroundOverlay = backgroundOverlay
  table.insert(instance.overlays, backgroundOverlay)
  instance.storeItems = {}
  instance.storeWidth = 0.95
  instance.storeItemHeight = 0.18
  instance.storeHeight = instance.storeItemHeight * 4
  instance.storeYPos = 1 - (instance.storeHeight + 0.1)
  instance.storeXPos = (1 - instance.storeWidth) / 2
  instance.imageXPos = instance.storeXPos + 0.008
  instance.imageYSpacing = 0.01
  instance.imageWidth = 0.12
  instance.imageHeight = 0.16
  instance.textSizeTitle = 0.04
  instance.textSizeDesc = 0.023
  instance.textXPos = instance.storeXPos + 0.137
  instance.textYSpacing = 0.02
  instance.priceXPos = instance.storeXPos + 0.755
  instance.buySellButtonsXPos = instance.storeXPos + 0.765
  instance.buttonWidth = 0.17
  instance.buttonHeight = 0.06
  instance.buttonYSpacing = 0.02
  instance.usedPlaces = {}
  for i = 1, table.getn(StoreItemsUtil.storeItems) do
    local dataStoreItem = StoreItemsUtil.storeItems[i]
    local storeItem = {}
    storeItem.overlayActive = Overlay:new("storeItem" .. i .. "_activeOverlay", dataStoreItem.imageActive, 0, 0, instance.imageWidth, instance.imageHeight)
    local buyButtonOverlay = Overlay:new("buy_button", "dataS/menu/store_menu_buy" .. g_languageSuffix .. ".png", 0, 0, instance.buttonWidth, instance.buttonHeight)
    local sellButtonOverlay = Overlay:new("sell_button", "dataS/menu/store_menu_sell" .. g_languageSuffix .. ".png", 0, 0, instance.buttonWidth, instance.buttonHeight)
    storeItem.buyButton = OverlayNumberedButton:new(buyButtonOverlay, dataStoreItem.id, instance.onBuy, instance)
    storeItem.sellButton = OverlayNumberedButton:new(sellButtonOverlay, dataStoreItem.id, instance.onSell, instance)
    table.insert(instance.overlayButtons, storeItem.buyButton)
    table.insert(instance.overlayButtons, storeItem.sellButton)
    table.insert(instance.storeItems, storeItem)
  end
  instance.startIndex = 1
  instance:addButton(OverlayButton:new(Overlay:new("up_button", "dataS/menu/up_button.png", 0.5 - 0.5 * instance.buttonWidth, instance.storeYPos + instance.storeHeight + instance.buttonYSpacing, instance.buttonWidth, instance.buttonHeight), instance.onScrollUp, instance))
  instance:addButton(OverlayButton:new(Overlay:new("down_button", "dataS/menu/down_button.png", 0.5 - 0.5 * instance.buttonWidth, instance.storeYPos - instance.buttonHeight - instance.buttonYSpacing, instance.buttonWidth, instance.buttonHeight), instance.onScrollDown, instance))
  instance:addButton(OverlayButton:new(Overlay:new("back_button", "dataS/menu/back_button" .. g_languageSuffix .. ".png", instance.buySellButtonsXPos, instance.buttonYSpacing, instance.buttonWidth, instance.buttonHeight), instance.onBack, instance))
  table.insert(instance.overlays, Overlay:new("background_overlay", "dataS/menu/storemenu_background.png", instance.storeXPos, instance.storeYPos, instance.storeWidth, instance.storeHeight / 2))
  table.insert(instance.overlays, Overlay:new("background_overlay", "dataS/menu/storemenu_background.png", instance.storeXPos, instance.storeYPos + 2 * instance.storeItemHeight, instance.storeWidth, instance.storeHeight / 2))
  instance.showNoMoreSpaceMessage = false
  instance.showPurchaseReadyMessage = false
  return instance
end
function StoreMenu:delete()
  for i = 1, table.getn(self.overlays) do
    self.overlays[i]:delete()
  end
  for k, v in pairs(self.storeItems) do
    v.overlayActive:delete()
    v.buyButton:delete()
    v.sellButton:delete()
  end
  for i = 1, table.getn(self.overlays) do
    self.storeItems[i]:delete()
  end
end
function StoreMenu:addItem(item)
  table.insert(self.items, item)
end
function StoreMenu:addButton(overlayButton)
  table.insert(self.overlays, overlayButton.overlay)
  table.insert(self.overlayButtons, overlayButton)
end
function StoreMenu:setStartIndex(index)
  local numStoreItems = table.getn(self.storeItems)
  self.startIndex = math.max(math.min(index, numStoreItems - 3), 1)
end
function StoreMenu:mouseEvent(posX, posY, isDown, isUp, button)
  for i = 1, table.getn(self.overlayButtons) do
    self.overlayButtons[i]:mouseEvent(posX, posY, isDown, isUp, button)
  end
  if isDown then
    if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
      self:onScrollUp()
    elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
      self:onScrollDown()
    end
  end
end
function StoreMenu:keyEvent(unicode, sym, modifier, isDown)
end
function StoreMenu:update(dt)
end
function StoreMenu:render()
  for i = 1, table.getn(self.overlays) do
    self.overlays[i]:render()
  end
  setTextBold(true)
  setTextColor(0, 0, 0, 1)
  renderText(0.025, 0.918, self.textSizeTitle, string.format(g_i18n:getText("Store")))
  setTextColor(1, 1, 1, 1)
  renderText(0.025, 0.92, self.textSizeTitle, string.format(g_i18n:getText("Store")))
  setTextAlignment(RenderText.ALIGN_RIGHT)
  setTextColor(0, 0, 0, 1)
  renderText(0.97, 0.918, self.textSizeTitle, string.format(g_i18n:getText("Capital") .. ": " .. g_i18n:getText("Currency_symbol") .. "%d", g_i18n:getCurrency(g_currentMission.missionStats.money)))
  setTextColor(1, 1, 1, 1)
  renderText(0.97, 0.92, self.textSizeTitle, string.format(g_i18n:getText("Capital") .. ": " .. g_i18n:getText("Currency_symbol") .. "%d", g_i18n:getCurrency(g_currentMission.missionStats.money)))
  setTextAlignment(RenderText.ALIGN_LEFT)
  setTextBold(false)
  local numStoreItems = table.getn(self.storeItems)
  local endIndex = math.min(self.startIndex + 3, numStoreItems)
  local buyButtonOverlay = {}
  local sellButtonOverlay = {}
  for i = 1, numStoreItems do
    local storeItem = self.storeItems[i]
    buyButtonOverlay = storeItem.buyButton.overlay
    buyButtonOverlay:setPosition(1, 1)
    sellButtonOverlay = storeItem.sellButton.overlay
    sellButtonOverlay:setPosition(1, 1)
  end
  for i = self.startIndex, endIndex do
    local storeItem = self.storeItems[i]
    local dataStoreItem = StoreItemsUtil.storeItems[i]
    local overlay = storeItem.overlayActive
    overlay:setPosition(self.imageXPos, self.storeYPos + self.storeItemHeight * (endIndex - i) + self.imageYSpacing)
    overlay:render()
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.textXPos, self.storeYPos + self.storeItemHeight * (endIndex - i) + self.textYSpacing + 0.11, self.textSizeTitle, dataStoreItem.name)
    setTextBold(false)
    renderText(self.textXPos + 0.002, self.storeYPos + self.storeItemHeight * (endIndex - i) + self.textYSpacing + 0.09, self.textSizeDesc, dataStoreItem.description)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(self.priceXPos, self.storeYPos + self.storeItemHeight * (endIndex - i) + self.textYSpacing + 0.095, self.textSizeDesc, string.format(g_i18n:getText("Currency_symbol") .. "%d", g_i18n:getCurrency(dataStoreItem.price)))
    renderText(self.priceXPos, self.storeYPos + self.storeItemHeight * (endIndex - i) + self.textYSpacing + 0.022, self.textSizeDesc, string.format(g_i18n:getText("Currency_symbol") .. "%d", g_i18n:getCurrency(self:getSellPrice(dataStoreItem))))
    setTextAlignment(RenderText.ALIGN_LEFT)
    storeItem.buyButton:setIsDisabled(g_currentMission.missionStats.money < dataStoreItem.price)
    buyButtonOverlay = storeItem.buyButton.overlay
    buyButtonOverlay:setPosition(self.buySellButtonsXPos, self.storeYPos + self.storeItemHeight * (endIndex - i) + 0.095)
    buyButtonOverlay:render()
    local filename = dataStoreItem.xmlFilename:lower()
    storeItem.sellButton:setIsDisabled(self.numOwnedVehicles[filename] == nil or self.numOwnedVehicles[filename] == 0)
    sellButtonOverlay = storeItem.sellButton.overlay
    sellButtonOverlay:setPosition(self.buySellButtonsXPos, self.storeYPos + self.storeItemHeight * (endIndex - i) + 0.022)
    sellButtonOverlay:render()
  end
  if self.showNoMoreSpaceMessage then
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextColor(0, 0, 0, 1)
    renderText(0.498, 0.697, 0.045, g_i18n:getText("StoreNoSpace"))
    renderText(0.5, 0.697, 0.045, g_i18n:getText("StoreNoSpace"))
    renderText(0.502, 0.697, 0.045, g_i18n:getText("StoreNoSpace"))
    renderText(0.498, 0.7, 0.045, g_i18n:getText("StoreNoSpace"))
    renderText(0.502, 0.7, 0.045, g_i18n:getText("StoreNoSpace"))
    renderText(0.498, 0.703, 0.045, g_i18n:getText("StoreNoSpace"))
    renderText(0.5, 0.703, 0.045, g_i18n:getText("StoreNoSpace"))
    renderText(0.502, 0.703, 0.045, g_i18n:getText("StoreNoSpace"))
    setTextColor(1, 0, 0, 1)
    renderText(0.5, 0.7, 0.045, g_i18n:getText("StoreNoSpace"))
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    setTextBold(false)
  end
  if self.showPurchaseReadyMessage then
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(0, 0, 0, 1)
    renderText(0.048, 0.033, 0.04, g_i18n:getText("StorePurchaseReady"))
    renderText(0.05, 0.033, 0.04, g_i18n:getText("StorePurchaseReady"))
    renderText(0.052, 0.033, 0.04, g_i18n:getText("StorePurchaseReady"))
    renderText(0.048, 0.03, 0.04, g_i18n:getText("StorePurchaseReady"))
    renderText(0.052, 0.03, 0.04, g_i18n:getText("StorePurchaseReady"))
    renderText(0.048, 0.027, 0.04, g_i18n:getText("StorePurchaseReady"))
    renderText(0.05, 0.027, 0.04, g_i18n:getText("StorePurchaseReady"))
    renderText(0.052, 0.027, 0.04, g_i18n:getText("StorePurchaseReady"))
    setTextColor(1, 1, 1, 1)
    renderText(0.05, 0.03, 0.04, g_i18n:getText("StorePurchaseReady"))
    setTextBold(false)
  end
end
function StoreMenu:reset()
  for i = 1, table.getn(self.overlayButtons) do
    self.overlayButtons[i]:reset()
  end
  self:setStartIndex(1)
  self.usedPlaces = {}
  self.numOwnedVehicles = {}
  for k, v in pairs(g_currentMission.vehicles) do
    local filename = v.configFileName:lower()
    self.numOwnedVehicles[filename] = Utils.getNoNil(self.numOwnedVehicles[filename], 0) + 1
  end
  self.showNoMoreSpaceMessage = false
  self.showPurchaseReadyMessage = false
end
function StoreMenu:getSellPrice(dataStoreItem)
  local sellPrice = dataStoreItem.price * 0.5
  if g_currentMission ~= nil and g_currentMission.reputation ~= nil then
    if g_currentMission.reputation >= 100 then
      sellPrice = dataStoreItem.price * 0.85
    else
      sellPrice = sellPrice + g_currentMission.reputation / 100 * dataStoreItem.price * 0.25
    end
  end
  return math.floor(sellPrice)
end
function StoreMenu:onScrollUp()
  self:setStartIndex(self.startIndex - 1)
end
function StoreMenu:onScrollDown()
  self:setStartIndex(self.startIndex + 1)
end
function StoreMenu:onBack()
  self.usedPlaces = {}
  g_currentMission.storeIsActive = false
  gameMenuSystem:playMode()
  setShowMouseCursor(false)
end
function StoreMenu:onBuy(number)
  local dataStoreItem = StoreItemsUtil.storeItems[number]
  if g_currentMission.missionStats.money >= dataStoreItem.price then
    local xmlFile = loadXMLFile("TempConfig", dataStoreItem.xmlFilename)
    local sizeWidth = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#width"), Vehicle.defaultWidth)
    local sizeLength = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#length"), Vehicle.defaultLength)
    local widthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#widthOffset"), 0)
    local lengthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#lengthOffset"), 0)
    local x, y, z, place, width, offset = PlacementUtil.getPlace(g_currentMission.storeSpawnPlaces, sizeWidth, sizeLength, widthOffset, lengthOffset, self.usedPlaces)
    if x ~= nil then
      local yRot = Utils.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
      yRot = yRot + Utils.degToRad(dataStoreItem.rotation)
      local vehicle = g_currentMission:loadVehicle(dataStoreItem.xmlFilename, x, offset, z, yRot, true)
      if vehicle ~= nil then
        PlacementUtil.markPlaceUsed(self.usedPlaces, place, width)
        g_currentMission.missionStats.money = g_currentMission.missionStats.money - dataStoreItem.price
        local filename = dataStoreItem.xmlFilename:lower()
        self.numOwnedVehicles[filename] = Utils.getNoNil(self.numOwnedVehicles[filename], 0) + 1
      end
      self.showPurchaseReadyMessage = true
    else
      self.showNoMoreSpaceMessage = true
    end
  end
end
function StoreMenu:onSell(number)
  local dataStoreItem = StoreItemsUtil.storeItems[number]
  local filename = dataStoreItem.xmlFilename:lower()
  if self.numOwnedVehicles[filename] ~= nil and self.numOwnedVehicles[filename] > 0 then
    for k, v in pairs(g_currentMission.vehicles) do
      if v.configFileName:lower() == filename then
        g_currentMission:removeVehicle(v)
        self.numOwnedVehicles[filename] = self.numOwnedVehicles[filename] - 1
        g_currentMission.missionStats.money = g_currentMission.missionStats.money + self:getSellPrice(dataStoreItem)
        break
      end
    end
  end
end

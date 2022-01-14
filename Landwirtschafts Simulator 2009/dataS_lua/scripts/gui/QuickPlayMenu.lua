QuickPlayMenu = {}
QuickPlayMenu.densityMapRevision = 2
QuickPlayMenu.defaultMoney = 1000
local QuickPlayMenu_mt = Class(QuickPlayMenu)
function QuickPlayMenu:new(backgroundOverlay)
  local instance = {}
  setmetatable(instance, QuickPlayMenu_mt)
  instance.overlays = {}
  instance.overlayButtons = {}
  instance.difficultyOverlays = {}
  instance.difficultyOverlayButtons = {}
  instance.backgroundOverlay = backgroundOverlay
  table.insert(instance.overlays, backgroundOverlay)
  instance.imageSpacing = 0.035
  instance.spacingLeft = 0.225
  instance.spacingLeftInner = 0.14
  instance.textSizeTitle = 0.04
  instance.textSizeDesc = 0.02
  instance.textTitleSpacing = 0.006
  instance.upDownButtonSpacing = 0.02
  instance.buttonWidth = 0.17
  instance.buttonHeight = 0.06
  instance.largeButtonWidth = 0.35
  instance.backPlayButtonSpacing = 0.02
  instance.briefingWidth = 0.825
  instance.briefingHeigth = instance.briefingWidth * 1.3333333333333333
  instance.briefingX = (1 - instance.briefingWidth) / 2
  instance.briefingY = -0.07
  instance.imageSize = (1 - (instance.backPlayButtonSpacing + 3 * instance.buttonHeight + 2 * instance.upDownButtonSpacing + 5 * instance.imageSpacing)) / 4
  instance.quickPlayBriefingOverlay = Overlay:new("quickPlayOverlayBriefing", "dataS/missions/mission00_briefing" .. g_languageSuffix .. ".png", instance.briefingX, instance.briefingY, instance.briefingWidth, instance.briefingHeigth)
  instance.quickPlayBriefingBackgroundOverlay = backgroundOverlay
  instance.avatars = {}
  table.insert(instance.avatars, Overlay:new("avatar01Overlay", "dataS/missions/mission00_avatar01.png", 0, 0, instance.imageSize * 0.75, instance.imageSize))
  table.insert(instance.avatars, Overlay:new("avatar01Overlay", "dataS/missions/mission00_avatar02.png", 0, 0, instance.imageSize * 0.75, instance.imageSize))
  table.insert(instance.avatars, Overlay:new("avatar01Overlay", "dataS/missions/mission00_avatar03.png", 0, 0, instance.imageSize * 0.75, instance.imageSize))
  table.insert(instance.avatars, Overlay:new("avatar01Overlay", "dataS/missions/mission00_avatar04.png", 0, 0, instance.imageSize * 0.75, instance.imageSize))
  table.insert(instance.avatars, Overlay:new("avatar01Overlay", "dataS/missions/mission00_avatar05.png", 0, 0, instance.imageSize * 0.75, instance.imageSize))
  table.insert(instance.avatars, Overlay:new("avatar01Overlay", "dataS/missions/mission00_avatar06.png", 0, 0, instance.imageSize * 0.75, instance.imageSize))
  instance.doubleClickTime = -10000
  instance.time = 0
  instance.spacingTop = instance.upDownButtonSpacing + instance.buttonHeight + instance.imageSpacing
  instance.savegames = {}
  local eof = false
  local i = 1
  repeat
    if not instance:loadSavegameFromXML(i) then
      eof = true
    end
    i = i + 1
  until eof
  instance.startIndex = 1
  instance.selectedIndex = 1
  instance:addButton(OverlayButton:new(Overlay:new("up_button", "dataS/menu/up_button.png", 0.5 - 0.5 * instance.buttonWidth, 1 - instance.upDownButtonSpacing - instance.buttonHeight, instance.buttonWidth, instance.buttonHeight), OnQuickPlayMenuScrollUp))
  instance:addButton(OverlayButton:new(Overlay:new("down_button", "dataS/menu/down_button.png", 0.5 - 0.5 * instance.buttonWidth, instance.upDownButtonSpacing + instance.backPlayButtonSpacing + instance.buttonHeight, instance.buttonWidth, instance.buttonHeight), OnQuickPlayMenuScrollDown))
  local buttonSpacingSide = 0.03
  local xPos = 1 - buttonSpacingSide - instance.backPlayButtonSpacing - instance.buttonWidth * 2
  instance:addButton(OverlayButton:new(Overlay:new("back_button", "dataS/menu/back_button" .. g_languageSuffix .. ".png", xPos, instance.backPlayButtonSpacing, instance.buttonWidth, instance.buttonHeight), OnQuickPlayMenuBack))
  xPos = xPos + instance.buttonWidth + instance.backPlayButtonSpacing
  instance:addButton(OverlayButton:new(Overlay:new("play_button", "dataS/menu/ingame_play_button" .. g_languageSuffix .. ".png", xPos, instance.backPlayButtonSpacing, instance.buttonWidth, instance.buttonHeight), OnQuickPlayMenuPlay))
  xPos = xPos + instance.buttonWidth + instance.backPlayButtonSpacing
  instance:addButton(OverlayButton:new(Overlay:new("delete_button", "dataS/menu/delete_button" .. g_languageSuffix .. ".png", buttonSpacingSide, instance.backPlayButtonSpacing, instance.buttonWidth, instance.buttonHeight), OnQuickPlayMenuDelete))
  instance:addButton(OverlayButton:new(Overlay:new("reset_vehicles_button", "dataS/menu/reset_vehicles_button" .. g_languageSuffix .. ".png", buttonSpacingSide + instance.buttonWidth + instance.backPlayButtonSpacing, instance.backPlayButtonSpacing, instance.largeButtonWidth, instance.buttonHeight), OnQuickPlayMenuResetVehicles))
  instance.selectedPositionBase = 2 * instance.buttonHeight + instance.backPlayButtonSpacing + instance.upDownButtonSpacing + 0.5 * instance.imageSpacing
  table.insert(instance.overlays, Overlay:new("background_overlay", "dataS/menu/missionmenu_background.png", instance.spacingLeft, instance.selectedPositionBase, 1 - instance.spacingLeft * 2, 4 * (instance.imageSpacing + instance.imageSize)))
  instance.selectedOverlay = Overlay:new("selected_overlay", "dataS/menu/missionmenu_selected.png", 0, 0, 1 - instance.spacingLeft * 2, instance.imageSpacing + instance.imageSize)
  table.insert(instance.overlays, instance.selectedOverlay)
  if g_isDemo then
    instance.demoLockedOverlay = Overlay:new("demoLockedOverlay", "dataS/menu/demo_locked.png", 0, 0, instance.imageSize * 0.75, instance.imageSize)
  end
  instance.difficultyGUIActive = false
  instance:addDifficultyButton(OverlayButton:new(Overlay:new("easy_button", "dataS/menu/easy_button" .. g_languageSuffix .. ".png", 0.25 - instance.buttonWidth / 2, 0.6, instance.buttonWidth, instance.buttonHeight), OnQuickPlayMenuDiff1))
  instance:addDifficultyButton(OverlayButton:new(Overlay:new("normal_button", "dataS/menu/normal_button" .. g_languageSuffix .. ".png", 0.5 - instance.buttonWidth / 2, 0.6, instance.buttonWidth, instance.buttonHeight), OnQuickPlayMenuDiff2))
  instance:addDifficultyButton(OverlayButton:new(Overlay:new("hard_button", "dataS/menu/hard_button" .. g_languageSuffix .. ".png", 0.75 - instance.buttonWidth / 2, 0.6, instance.buttonWidth, instance.buttonHeight), OnQuickPlayMenuDiff3))
  instance:addDifficultyButton(OverlayButton:new(Overlay:new("back_button", "dataS/menu/back_button" .. g_languageSuffix .. ".png", 0.5 - instance.buttonWidth / 2, 0.5, instance.buttonWidth, instance.buttonHeight), OnQuickPlayMenuDiffBack))
  return instance
end
function QuickPlayMenu:mouseEvent(posX, posY, isDown, isUp, button)
  if self.difficultyGUIActive then
    for i = 1, table.getn(self.difficultyOverlayButtons) do
      self.difficultyOverlayButtons[i]:mouseEvent(posX, posY, isDown, isUp, button)
    end
  else
    for i = 1, table.getn(self.overlayButtons) do
      self.overlayButtons[i]:mouseEvent(posX, posY, isDown, isUp, button)
    end
    if isDown then
      if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_LEFT) then
        local lastIndex = self.selectedIndex
        local clicked = false
        for i = 1, 4 do
          local height = self.imageSpacing + self.imageSize
          local pos = self.selectedPositionBase + (i - 1) * height
          if posX >= self.spacingLeft * 0.5 and posX <= 1 - self.spacingLeft and posY >= pos and posY <= pos + height then
            self.selectedIndex = 4 - i + self.startIndex
            clicked = true
          end
        end
        if clicked and lastIndex == self.selectedIndex and self.doubleClickTime + 500 > self.time then
          OnQuickPlayMenuPlay()
        end
        self.doubleClickTime = self.time
      elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
        OnQuickPlayMenuScrollUp()
      elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
        OnQuickPlayMenuScrollDown()
      end
    end
  end
end
function QuickPlayMenu:keyEvent(unicode, sym, modifier, isDown)
end
function QuickPlayMenu:update(dt)
  self.time = self.time + dt
end
function QuickPlayMenu:render()
  if not self.difficultyGUIActive then
    self.selectedOverlay:setPosition(self.spacingLeft, self.selectedPositionBase + (4 - self.selectedIndex + (self.startIndex - 1)) * (self.imageSpacing + self.imageSize))
    local numSavegames = table.getn(self.savegames)
    for i = 1, table.getn(self.overlays) do
      self.overlays[i]:render()
    end
    local textLeft = self.spacingLeft
    local endIndex = math.min(self.startIndex + 3, numSavegames)
    for i = self.startIndex, endIndex do
      local savegame = self.savegames[i]
      local overlay = self.avatars[i]
      overlay:setPosition(self.spacingLeft + 0.015, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.imageSize))
      overlay:render()
      if g_isDemo then
        self.demoLockedOverlay:setPosition(self.spacingLeft + 0.015, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.imageSize))
        self.demoLockedOverlay:render()
      end
      local savegameName = g_i18n:getText("Savegame") .. " " .. i
      setTextColor(1, 1, 1, 1)
      setTextBold(true)
      renderText(self.spacingLeft + self.spacingLeftInner, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.textSizeTitle) + 0.005, self.textSizeTitle, savegameName)
      setTextBold(false)
      local desc1, desc2
      if savegame.valid then
        local timeHoursF = savegame.stats.dayTime / 60 + 1.0E-4
        local timeHours = math.floor(timeHoursF)
        local timeMinutes = math.floor((timeHoursF - timeHours) * 60)
        local playTimeHoursF = savegame.stats.playTime / 60 + 1.0E-4
        local playTimeHours = math.floor(playTimeHoursF)
        local playTimeMinutes = math.floor((playTimeHoursF - playTimeHours) * 60)
        desc1 = g_i18n:getText("Money") .. ":\n" .. g_i18n:getText("In_game_time") .. ":\n" .. g_i18n:getText("Duration") .. ":\n" .. g_i18n:getText("Difficulty") .. ":\n" .. g_i18n:getText("Save_date") .. ":"
        desc2 = string.format("%d", g_i18n:getCurrency(savegame.stats.money)) .. " " .. g_i18n:getText("Currency_symbol") .. "\n" .. string.format("%02d:%02d", timeHours, timeMinutes) .. " h\n" .. string.format("%02d:%02d", playTimeHours, playTimeMinutes) .. " hh:mm\n" .. g_i18n:getText("Diff" .. savegame.stats.difficulty) .. "\n" .. savegame.stats.saveDate
      else
        desc1 = g_i18n:getText("This_savegame_is_currently_unused")
        desc2 = ""
      end
      renderText(self.spacingLeft + self.spacingLeftInner, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.textSizeTitle + self.textTitleSpacing + self.textSizeDesc) + 0.01, self.textSizeDesc, desc1)
      renderText(self.spacingLeft + self.spacingLeftInner + 0.14, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.textSizeTitle + self.textTitleSpacing + self.textSizeDesc) + 0.01, self.textSizeDesc, desc2)
    end
  else
    self.backgroundOverlay:render()
    for i = 1, table.getn(self.difficultyOverlays) do
      self.difficultyOverlays[i]:render()
    end
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextBold(true)
    setTextColor(0, 0, 0, 1)
    renderText(0.5, 0.697, 0.05, g_i18n:getText("ChooseDifficulty"))
    setTextColor(1, 1, 1, 1)
    renderText(0.5, 0.7, 0.05, g_i18n:getText("ChooseDifficulty"))
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
  end
end
function QuickPlayMenu:addButton(overlayButton)
  table.insert(self.overlays, overlayButton.overlay)
  table.insert(self.overlayButtons, overlayButton)
end
function QuickPlayMenu:addDifficultyButton(overlayButton)
  table.insert(self.difficultyOverlays, overlayButton.overlay)
  table.insert(self.difficultyOverlayButtons, overlayButton)
end
function QuickPlayMenu:setSelectedIndex(index)
  local numSavegames = table.getn(self.savegames)
  self.selectedIndex = math.max(math.min(index, numSavegames), 1)
  if self.selectedIndex > self.startIndex + 3 then
    self.startIndex = self.selectedIndex - 3
  elseif self.selectedIndex < self.startIndex then
    self.startIndex = self.selectedIndex
  end
end
function QuickPlayMenu:checkForDifficulty()
  local savegame = self.savegames[self.selectedIndex]
  if not savegame.valid then
    self.difficultyGUIActive = true
  else
    self:startSelectedGame(0)
  end
end
function QuickPlayMenu:backToGameSelection()
  self.difficultyGUIActive = false
  self:reset()
end
function QuickPlayMenu:startSelectedGame(difficulty)
  local savegame = self.savegames[self.selectedIndex]
  self.difficultyGUIActive = false
  if g_isDemo then
    return
  end
  local dir = self:getSavegameDirectory(self.selectedIndex)
  createFolder(dir)
  local careerVehiclesPath = getAppBasePath() .. "data/careerVehicles.xml"
  local overwrite = not savegame.valid
  copyFile(careerVehiclesPath, savegame.vehiclesXML, overwrite)
  g_missionLoaderDesc = {}
  if savegame.valid and savegame.densityMapRevision == QuickPlayMenu.densityMapRevision then
    setTerrainLoadDirectory(dir)
    g_missionLoaderDesc.growthStateDirectory = dir
  else
    setTerrainLoadDirectory("")
  end
  g_missionLoaderDesc.scriptFilename = "dataS/missions/mission00.lua"
  g_missionLoaderDesc.scriptClass = "Mission00"
  g_missionLoaderDesc.id = 0
  g_missionLoaderDesc.bronze = 0
  g_missionLoaderDesc.silver = 0
  g_missionLoaderDesc.gold = 0
  g_missionLoaderDesc.missionType = ""
  g_missionLoaderDesc.overlayBriefing = self.quickPlayBriefingOverlay
  g_missionLoaderDesc.backgroundOverlay = self.quickPlayBriefingBackgroundOverlay
  g_missionLoaderDesc.overlayBriefingMedals = nil
  g_missionLoaderDesc.stats = savegame.stats
  g_missionLoaderDesc.vehiclesXML = savegame.vehiclesXML
  g_missionLoaderDesc.resetVehicles = savegame.resetVehicles
  if difficulty ~= 0 then
    savegame.stats.difficulty = difficulty
  end
  if not savegame.valid then
    for i = 1, FruitUtil.NUM_FRUITTYPES do
      savegame.stats.farmSiloFruitAmount[i] = (3 - savegame.stats.difficulty) * math.random(8000, 9000)
    end
    savegame.stats.money = 3000 + 1000 * 3 ^ (3 - savegame.stats.difficulty)
  end
  gameMenuSystem:loadingScreenMode()
end
function QuickPlayMenu:deleteSelectedGame()
  local savegame = self.savegames[self.selectedIndex]
  savegame.valid = false
  savegame.densityMapRevision = QuickPlayMenu.densityMapRevision
  savegame.resetVehicles = false
  self:loadStatsDefaults(savegame)
  self:saveSavegameToXML(savegame, self.selectedIndex)
  saveXMLFile(g_savegameXML)
end
function QuickPlayMenu:resetVehiclesOfSelectedGame()
  local savegame = self.savegames[self.selectedIndex]
  local baseString = "savegames.quickPlay.savegame" .. self.selectedIndex
  savegame.resetVehicles = true
  setXMLBool(g_savegameXML, baseString .. "#resetVehicles", savegame.resetVehicles)
  saveXMLFile(g_savegameXML)
end
function QuickPlayMenu:saveSavegameToXML(savegame, id)
  local baseString = "savegames.quickPlay.savegame" .. id
  setXMLBool(g_savegameXML, baseString .. "#valid", savegame.valid)
  setXMLInt(g_savegameXML, baseString .. "#densityMapRevision", savegame.densityMapRevision)
  setXMLBool(g_savegameXML, baseString .. "#resetVehicles", savegame.resetVehicles)
  self:saveStatsToXML(baseString, savegame)
  local vehiclesFile = io.open(savegame.vehiclesXML, "w")
  if vehiclesFile ~= nil then
    vehiclesFile:write([[
<?xml version="1.0" encoding="iso-8859-1" standalone="no" ?>
<careerVehicles>
]])
    if g_currentMission ~= nil then
      g_currentMission:saveVehicles(vehiclesFile)
    end
    vehiclesFile:write("</careerVehicles>")
    vehiclesFile:close()
  end
end
function QuickPlayMenu:reset()
  self.doubleClickTime = -10000
  for i = 1, table.getn(self.overlayButtons) do
    self.overlayButtons[i]:reset()
  end
  for i = 1, table.getn(self.difficultyOverlayButtons) do
    self.difficultyOverlayButtons[i]:reset()
  end
end
function QuickPlayMenu:saveSelectedGame()
  local savegame = self.savegames[self.selectedIndex]
  savegame.valid = true
  savegame.densityMapRevision = QuickPlayMenu.densityMapRevision
  savegame.resetVehicles = false
  self:getStatsFromMission(savegame)
  self:saveSavegameToXML(savegame, self.selectedIndex)
  saveXMLFile(g_savegameXML)
  local dir = self:getSavegameDirectory(self.selectedIndex)
  createFolder(dir)
  local savedDensityMaps = {}
  for index, fruit in pairs(g_currentMission.fruits) do
    if fruit.id ~= 0 then
      local filename = getDensityMapFileName(fruit.id)
      if savedDensityMaps[filename] == nil then
        savedDensityMaps[filename] = true
        saveDensityMapToFile(fruit.id, dir .. "/" .. filename)
      end
      saveGrowthStateToFile(fruit.id, dir .. "/" .. getName(fruit.id) .. "_growthState.xml")
    end
    if fruit.cutShortId ~= 0 then
      local filename = getDensityMapFileName(fruit.cutShortId)
      if savedDensityMaps[filename] == nil then
        savedDensityMaps[filename] = true
        saveDensityMapToFile(fruit.cutShortId, dir .. "/" .. filename)
      end
    end
    if fruit.cutLongId ~= 0 then
      local filename = getDensityMapFileName(fruit.cutLongId)
      if savedDensityMaps[filename] == nil then
        savedDensityMaps[filename] = true
        saveDensityMapToFile(fruit.cutLongId, dir .. "/" .. filename)
      end
    end
    if fruit.windrowId ~= 0 then
      local filename = getDensityMapFileName(fruit.windrowId)
      if savedDensityMaps[filename] == nil then
        savedDensityMaps[filename] = true
        saveDensityMapToFile(fruit.windrowId, dir .. "/" .. filename)
      end
    end
  end
  local detailFilename = getDensityMapFileName(g_currentMission.terrainDetailId)
  if savedDensityMaps[detailFilename] == nil then
    savedDensityMaps[detailFilename] = true
    saveDensityMapToFile(g_currentMission.terrainDetailId, dir .. "/" .. detailFilename)
  end
  local grassFilename = getDensityMapFileName(g_currentMission.grassId)
  if savedDensityMaps[grassFilename] == nil then
    savedDensityMaps[grassFilename] = true
    saveDensityMapToFile(g_currentMission.grassId, dir .. "/" .. grassFilename)
  end
end
function QuickPlayMenu:loadSavegameFromXML(index)
  local savegame = {}
  local baseXMLName = "savegames.quickPlay.savegame" .. index
  savegame.valid = getXMLBool(g_savegameXML, baseXMLName .. "#valid")
  if savegame.valid ~= nil then
    savegame.stats = {}
    if savegame.valid then
      self:loadStatsFromXML(baseXMLName, savegame)
    else
      self:loadStatsDefaults(savegame)
    end
    savegame.densityMapRevision = Utils.getNoNil(getXMLInt(g_savegameXML, baseXMLName .. "#densityMapRevision"), 1)
    local dir = self:getSavegameDirectory(index)
    savegame.vehiclesXML = dir .. "/vehicles.xml"
    savegame.resetVehicles = Utils.getNoNil(getXMLBool(g_savegameXML, baseXMLName .. "#resetVehicles"), false)
    table.insert(self.savegames, savegame)
    return true
  end
  return false
end
function QuickPlayMenu:getSavegameDirectory(index)
  return getUserProfileAppPath() .. "savegame" .. index
end
function QuickPlayMenu:loadStatsDefaults(savegame)
  savegame.stats.fuelUsage = 0
  savegame.stats.seedUsage = 0
  savegame.stats.traveledDistance = 0
  savegame.stats.hectaresSeeded = 0
  savegame.stats.seedingDuration = 0
  savegame.stats.hectaresThreshed = 0
  savegame.stats.threshingDuration = 0
  savegame.stats.farmSiloFruitAmount = {}
  savegame.stats.fruitPrices = {}
  savegame.stats.yesterdaysFruitPrices = {}
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    savegame.stats.farmSiloFruitAmount[i] = 5000
    savegame.stats.fruitPrices[i] = FruitUtil.fruitIndexToDesc[i].pricePerLiter
    savegame.stats.yesterdaysFruitPrices[i] = FruitUtil.fruitIndexToDesc[i].yesterdaysPrice
  end
  savegame.stats.revenue = 0
  savegame.stats.expenses = 0
  savegame.stats.playTime = 0
  savegame.stats.money = QuickPlayMenu.defaultMoney
  savegame.stats.dayTime = 480
  savegame.stats.timeUntilNextRain = 0
  savegame.stats.timeUntilRainAfterNext = 0
  savegame.stats.rainTime = 0
  savegame.stats.nextRainDuration = 0
  savegame.stats.nextRainType = 0
  savegame.stats.rainTypeAfterNext = 0
  savegame.stats.nextRainValid = false
  savegame.stats.currentDay = 1
  savegame.stats.saveDate = "--.--.--"
  savegame.stats.foundBottleCount = 0
  savegame.stats.deliveredBottles = 0
  savegame.stats.foundBottles = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  savegame.stats.reputation = 0
  savegame.stats.foundInfoTriggers = "00000000000000000000"
end
function QuickPlayMenu:loadStatsFromXML(baseXMLName, savegame)
  savegame.stats.difficulty = Utils.getNoNil(getXMLInt(g_savegameXML, baseXMLName .. "#difficulty"), 1)
  savegame.stats.fuelUsage = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#fuelUsage"), 0)
  savegame.stats.seedUsage = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#seedUsage"), 0)
  savegame.stats.traveledDistance = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#traveledDistance"), 0)
  savegame.stats.hectaresSeeded = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#hectaresSeeded"), 0)
  savegame.stats.seedingDuration = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#seedingDuration"), 0)
  savegame.stats.hectaresThreshed = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#hectaresThreshed"), 0)
  savegame.stats.farmSiloFruitAmount = {}
  local siloString = Utils.getNoNil(getXMLString(g_savegameXML, baseXMLName .. "#farmSiloFruitAmount"), "5000 5000 5000 5000 5000 5000")
  local silos = Utils.splitString(" ", siloString)
  for k, v in pairs(silos) do
    savegame.stats.farmSiloFruitAmount[k] = tonumber(v)
  end
  savegame.stats.fruitPrices = {}
  local pricesString = Utils.getNoNil(getXMLString(g_savegameXML, baseXMLName .. "#fruitPrices"), "0.4 0.41 0.5 0.42 0.35 0.3")
  local prices = Utils.splitString(" ", pricesString)
  for k, v in pairs(prices) do
    savegame.stats.fruitPrices[k] = tonumber(v)
  end
  savegame.stats.yesterdaysFruitPrices = {}
  pricesString = Utils.getNoNil(getXMLString(g_savegameXML, baseXMLName .. "#yesterdaysFruitPrices"), "0.3 0.5 0.35 0.5 0.3 0.3")
  prices = Utils.splitString(" ", pricesString)
  for k, v in pairs(prices) do
    savegame.stats.yesterdaysFruitPrices[k] = tonumber(v)
  end
  savegame.stats.threshingDuration = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#threshingDuration"), 0)
  savegame.stats.farmSiloWheatAmount = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloWheatAmount"), 0)
  savegame.stats.storedWheatFarmSilo = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#storedWheatFarmSilo"), 0)
  savegame.stats.soldWheatPortSilo = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#soldWheatPortSilo"), 0)
  savegame.stats.revenue = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#revenue"), 0)
  savegame.stats.expenses = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#expenses"), 0)
  savegame.stats.playTime = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#playTime"), 0)
  savegame.stats.money = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#money"), QuickPlayMenu.defaultMoney)
  if savegame.stats.money ~= QuickPlayMenu.defaultMoney then
    local hash = getXMLString(g_savegameXML, baseXMLName .. "#money2")
    local hash2 = self:getMoneyHash(savegame.stats.money)
    if hash == nil or hash ~= hash2 then
      savegame.stats.money = QuickPlayMenu.defaultMoney
      print("Warning: invalid savegame modification detected, the money is reset to the default")
    end
  end
  savegame.stats.dayTime = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#dayTime"), 480)
  savegame.stats.timeUntilNextRain = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#timeUntilNextRain"), 0)
  savegame.stats.timeUntilRainAfterNext = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#timeUntilRainAfterNext"), 0)
  savegame.stats.rainTime = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#rainTime"), 0)
  savegame.stats.nextRainDuration = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#nextRainDuration"), 0)
  savegame.stats.nextRainType = Utils.getNoNil(getXMLInt(g_savegameXML, baseXMLName .. "#nextRainType"), 0)
  savegame.stats.rainTypeAfterNext = Utils.getNoNil(getXMLInt(g_savegameXML, baseXMLName .. "#rainTypeAfterNext"), 0)
  savegame.stats.nextRainValid = Utils.getNoNil(getXMLBool(g_savegameXML, baseXMLName .. "#nextRainValid"), false)
  savegame.stats.currentDay = Utils.getNoNil(getXMLInt(g_savegameXML, baseXMLName .. "#currentDay"), 1)
  savegame.stats.saveDate = Utils.getNoNil(getXMLString(g_savegameXML, baseXMLName .. "#saveDate"), "--.--.--")
  savegame.stats.foundBottleCount = Utils.getNoNil(getXMLInt(g_savegameXML, baseXMLName .. "#foundBottleCount"), 0)
  savegame.stats.deliveredBottles = Utils.getNoNil(getXMLInt(g_savegameXML, baseXMLName .. "#deliveredBottles"), 0)
  savegame.stats.foundBottles = Utils.getNoNil(getXMLString(g_savegameXML, baseXMLName .. "#foundBottles"), "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
  savegame.stats.reputation = Utils.getNoNil(getXMLInt(g_savegameXML, baseXMLName .. "#reputation"), 0)
  savegame.stats.foundInfoTriggers = Utils.getNoNil(getXMLString(g_savegameXML, baseXMLName .. "#foundInfoTriggers"), "00000000000000000000")
end
function QuickPlayMenu:saveStatsToXML(baseXMLName, savegame)
  setXMLInt(g_savegameXML, baseXMLName .. "#difficulty", savegame.stats.difficulty)
  setXMLFloat(g_savegameXML, baseXMLName .. "#fuelUsage", savegame.stats.fuelUsage)
  setXMLFloat(g_savegameXML, baseXMLName .. "#seedUsage", savegame.stats.seedUsage)
  setXMLFloat(g_savegameXML, baseXMLName .. "#traveledDistance", savegame.stats.traveledDistance)
  setXMLFloat(g_savegameXML, baseXMLName .. "#hectaresSeeded", savegame.stats.hectaresSeeded)
  setXMLFloat(g_savegameXML, baseXMLName .. "#seedingDuration", savegame.stats.seedingDuration)
  setXMLFloat(g_savegameXML, baseXMLName .. "#hectaresThreshed", savegame.stats.hectaresThreshed)
  setXMLFloat(g_savegameXML, baseXMLName .. "#threshingDuration", savegame.stats.threshingDuration)
  setXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloWheatAmount", savegame.stats.farmSiloWheatAmount)
  setXMLFloat(g_savegameXML, baseXMLName .. "#storedWheatFarmSilo", savegame.stats.storedWheatFarmSilo)
  setXMLFloat(g_savegameXML, baseXMLName .. "#soldWheatPortSilo", savegame.stats.soldWheatPortSilo)
  local siloString = ""
  for i = 1, table.getn(savegame.stats.farmSiloFruitAmount) do
    siloString = siloString .. savegame.stats.farmSiloFruitAmount[i] .. " "
  end
  siloString = string.sub(siloString, 1, string.len(siloString) - 1)
  setXMLString(g_savegameXML, baseXMLName .. "#farmSiloFruitAmount", siloString)
  local pricesString = ""
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    pricesString = pricesString .. savegame.stats.fruitPrices[i] .. " "
  end
  pricesString = string.sub(pricesString, 1, string.len(pricesString) - 1)
  setXMLString(g_savegameXML, baseXMLName .. "#fruitPrices", pricesString)
  pricesString = ""
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    pricesString = pricesString .. savegame.stats.yesterdaysFruitPrices[i] .. " "
  end
  pricesString = string.sub(pricesString, 1, string.len(pricesString) - 1)
  setXMLString(g_savegameXML, baseXMLName .. "#yesterdaysFruitPrices", pricesString)
  setXMLFloat(g_savegameXML, baseXMLName .. "#revenue", savegame.stats.revenue)
  setXMLFloat(g_savegameXML, baseXMLName .. "#expenses", savegame.stats.expenses)
  setXMLFloat(g_savegameXML, baseXMLName .. "#playTime", savegame.stats.playTime)
  setXMLFloat(g_savegameXML, baseXMLName .. "#money", savegame.stats.money)
  local hash = self:getMoneyHash(savegame.stats.money)
  setXMLString(g_savegameXML, baseXMLName .. "#money2", hash)
  setXMLFloat(g_savegameXML, baseXMLName .. "#dayTime", savegame.stats.dayTime)
  setXMLFloat(g_savegameXML, baseXMLName .. "#timeUntilNextRain", savegame.stats.timeUntilNextRain)
  setXMLFloat(g_savegameXML, baseXMLName .. "#timeUntilRainAfterNext", savegame.stats.timeUntilRainAfterNext)
  setXMLFloat(g_savegameXML, baseXMLName .. "#rainTime", savegame.stats.rainTime)
  setXMLFloat(g_savegameXML, baseXMLName .. "#nextRainDuration", savegame.stats.nextRainDuration)
  setXMLInt(g_savegameXML, baseXMLName .. "#nextRainType", savegame.stats.nextRainType)
  setXMLInt(g_savegameXML, baseXMLName .. "#rainTypeAfterNext", savegame.stats.rainTypeAfterNext)
  setXMLBool(g_savegameXML, baseXMLName .. "#nextRainValid", savegame.stats.nextRainValid)
  setXMLInt(g_savegameXML, baseXMLName .. "#currentDay", savegame.stats.currentDay)
  setXMLString(g_savegameXML, baseXMLName .. "#saveDate", savegame.stats.saveDate)
  setXMLInt(g_savegameXML, baseXMLName .. "#foundBottleCount", savegame.stats.foundBottleCount)
  setXMLInt(g_savegameXML, baseXMLName .. "#deliveredBottles", savegame.stats.deliveredBottles)
  setXMLString(g_savegameXML, baseXMLName .. "#foundBottles", savegame.stats.foundBottles)
  setXMLInt(g_savegameXML, baseXMLName .. "#reputation", savegame.stats.reputation)
  setXMLString(g_savegameXML, baseXMLName .. "#foundInfoTriggers", savegame.stats.foundInfoTriggers)
end
function QuickPlayMenu:getStatsFromMission(savegame)
  local litersToRefill = 0
  for k, v in pairs(g_currentMission.vehicles) do
    if v.fuelCapacity ~= nil and v.fuelFillLevel ~= nil then
      litersToRefill = litersToRefill + (v.fuelCapacity - v.fuelFillLevel)
    end
  end
  savegame.stats.difficulty = g_currentMission.missionStats.difficulty
  savegame.stats.fuelUsage = g_currentMission.missionStats.fuelUsageTotal
  savegame.stats.seedUsage = g_currentMission.missionStats.seedUsageTotal
  savegame.stats.traveledDistance = g_currentMission.missionStats.traveledDistanceTotal
  savegame.stats.hectaresSeeded = g_currentMission.missionStats.hectaresSeededTotal
  savegame.stats.seedingDuration = g_currentMission.missionStats.seedingDurationTotal
  savegame.stats.hectaresThreshed = g_currentMission.missionStats.hectaresThreshedTotal
  savegame.stats.farmSiloFruitAmount = g_currentMission.missionStats.farmSiloFruitAmount
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    savegame.stats.fruitPrices[i] = FruitUtil.fruitIndexToDesc[i].pricePerLiter
    savegame.stats.yesterdaysFruitPrices[i] = FruitUtil.fruitIndexToDesc[i].yesterdaysPrice
  end
  savegame.stats.threshingDuration = g_currentMission.missionStats.threshingDurationTotal
  savegame.stats.farmSiloWheatAmount = g_currentMission.missionStats.farmSiloWheatAmount
  savegame.stats.storedWheatFarmSilo = g_currentMission.missionStats.storedWheatFarmSiloTotal
  savegame.stats.soldWheatPortSilo = g_currentMission.missionStats.soldWheatPortSiloTotal
  savegame.stats.revenue = g_currentMission.missionStats.revenueTotal
  savegame.stats.expenses = g_currentMission.missionStats.expensesTotal + litersToRefill * g_fuelPricePerLiter
  savegame.stats.playTime = g_currentMission.missionStats.playTime
  savegame.stats.money = g_currentMission.missionStats.money - litersToRefill * g_fuelPricePerLiter
  savegame.stats.dayTime = g_currentMission.environment.dayTime / 60000
  savegame.stats.timeUntilNextRain = g_currentMission.environment.timeUntilNextRain
  savegame.stats.timeUntilRainAfterNext = g_currentMission.environment.timeUntilRainAfterNext
  savegame.stats.rainTime = g_currentMission.environment.rainTime
  savegame.stats.nextRainDuration = g_currentMission.environment.nextRainDuration
  savegame.stats.nextRainType = g_currentMission.environment.nextRainType
  savegame.stats.rainTypeAfterNext = g_currentMission.environment.rainTypeAfterNext
  savegame.stats.nextRainValid = true
  savegame.stats.currentDay = g_currentMission.environment.currentDay
  savegame.stats.foundBottleCount = g_currentMission.foundBottleCount
  savegame.stats.deliveredBottles = g_currentMission.deliveredBottles
  savegame.stats.foundBottles = g_currentMission.foundBottles
  savegame.stats.reputation = g_currentMission.reputation
  savegame.stats.foundInfoTriggers = g_currentMission.foundInfoTriggers
  if g_languageShort == "de" then
    savegame.stats.saveDate = os.date("%d.%m.%Y")
  else
    savegame.stats.saveDate = os.date("%m.%d.%Y")
  end
end
function QuickPlayMenu:getMoneyHash(money)
  local hash = getMD5(tostring(math.floor(money)))
  local ret = ""
  for i = 1, hash:len() do
    local byte = hash:byte(i)
    local modulo = (byte - 32) % 95 + 32
    ret = ret .. string.char(modulo)
  end
  return ret
end

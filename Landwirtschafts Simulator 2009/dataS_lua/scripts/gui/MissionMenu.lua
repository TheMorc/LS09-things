MissionMenu = {}
local MissionMenu_mt = Class(MissionMenu)
function MissionMenu:new(backgroundOverlay)
  local instance = {}
  setmetatable(instance, MissionMenu_mt)
  instance.overlays = {}
  instance.overlayButtons = {}
  instance.backgroundOverlay = backgroundOverlay
  table.insert(instance.overlays, backgroundOverlay)
  local xmlFile = loadXMLFile("missions.xml", "dataS/missions" .. g_languageSuffix .. ".xml")
  instance.missions = {}
  instance.imageSpacing = 0.035
  instance.spacingLeft = 0.05
  instance.textSizeTitle = 0.035
  instance.textSizeDesc = 0.023
  instance.textTitleSpacing = 0.006
  instance.upDownButtonSpacing = 0.02
  instance.buttonWidth = 0.17
  instance.buttonHeight = 0.06
  instance.backPlayButtonSpacing = 0.02
  instance.briefingX = 0
  instance.briefingY = 0.275
  instance.briefingWidth = 1
  instance.briefingHeigth = instance.briefingWidth / 2 * 1.3333333333333333
  instance.briefingMedalsY = 0.105
  instance.briefingMedalsHeigth = 0.155
  instance.doubleClickTime = 0
  self.time = 0
  instance.imageSize = (1 - (instance.backPlayButtonSpacing + 3 * instance.buttonHeight + 2 * instance.upDownButtonSpacing + 5 * instance.imageSpacing)) / 4
  instance.spacingTop = instance.upDownButtonSpacing + instance.buttonHeight + instance.imageSpacing
  local eom = false
  local i = 0
  repeat
    local mission = {}
    local baseXMLName = "missions.mission(" .. i .. ")"
    mission.id = getXMLInt(xmlFile, baseXMLName .. "#id")
    if mission.id ~= nil then
      mission.name = getXMLString(xmlFile, baseXMLName .. ".name")
      mission.desc = getXMLString(xmlFile, baseXMLName .. ".description")
      mission.lockable = Utils.getNoNil(getXMLBool(xmlFile, baseXMLName .. ".lockable"), true)
      local imageActive = getXMLString(xmlFile, baseXMLName .. ".image#active")
      mission.overlayActive = Overlay:new("mission" .. i .. "_activeOverlay", imageActive, 0, 0, instance.imageSize * 0.75, instance.imageSize)
      mission.scriptFilename = getXMLString(xmlFile, baseXMLName .. ".script#filename")
      source(mission.scriptFilename)
      mission.scriptClass = getXMLString(xmlFile, baseXMLName .. ".script#class")
      local briefing = getXMLString(xmlFile, baseXMLName .. ".briefing")
      mission.overlayBriefing = Overlay:new("mission" .. i .. "_overlayBriefing", briefing, instance.briefingX, instance.briefingY, instance.briefingWidth, instance.briefingHeigth)
      mission.bronze = getXMLFloat(xmlFile, baseXMLName .. ".bronze")
      mission.silver = getXMLFloat(xmlFile, baseXMLName .. ".silver")
      mission.gold = getXMLFloat(xmlFile, baseXMLName .. ".gold")
      mission.missionType = getXMLString(xmlFile, baseXMLName .. ".mission_type")
      if mission.missionType == "time" then
        mission.bronze = mission.bronze * 1000
        mission.silver = mission.silver * 1000
        mission.gold = mission.gold * 1000
      end
      if g_isDemo then
        if mission.id == 11 then
          table.insert(instance.missions, 1, mission)
        elseif mission.id == 13 then
          table.insert(instance.missions, 2, mission)
        else
          table.insert(instance.missions, mission)
        end
      else
        table.insert(instance.missions, mission)
      end
    else
      eom = true
    end
    i = i + 1
  until eom
  instance.startIndex = 1
  instance.selectedIndex = 1
  delete(xmlFile)
  instance.lastNumUnlocked = 0
  instance.unlockedMissions = {}
  local record = getXMLString(g_savegameXML, "savegames.missions#record")
  local count = 1
  local records = {}
  for missionRecord in string.gmatch(record, "%w+") do
    records[count] = missionRecord + 0
    count = count + 1
  end
  local finished = getXMLString(g_savegameXML, "savegames.missions#finished")
  count = 1
  for missionId in string.gmatch(finished, "%w+") do
    g_finishedMissions[missionId + 0] = 1
    g_finishedMissionsRecord[missionId + 0] = records[count]
    count = count + 1
  end
  instance:addButton(OverlayButton:new(Overlay:new("up_button", "dataS/menu/up_button.png", 0.5 - 0.5 * instance.buttonWidth, 1 - instance.upDownButtonSpacing - instance.buttonHeight, instance.buttonWidth, instance.buttonHeight), OnMissionMenuScrollUp))
  instance:addButton(OverlayButton:new(Overlay:new("down_button", "dataS/menu/down_button.png", 0.5 - 0.5 * instance.buttonWidth, instance.upDownButtonSpacing + instance.backPlayButtonSpacing + instance.buttonHeight, instance.buttonWidth, instance.buttonHeight), OnMissionMenuScrollDown))
  instance:addButton(OverlayButton:new(Overlay:new("back_button", "dataS/menu/back_button" .. g_languageSuffix .. ".png", 0.61, instance.backPlayButtonSpacing, instance.buttonWidth, instance.buttonHeight), OnMissionMenuBack))
  instance:addButton(OverlayButton:new(Overlay:new("play_button", "dataS/menu/ingame_play_button" .. g_languageSuffix .. ".png", 0.61 + instance.buttonWidth + instance.backPlayButtonSpacing, instance.backPlayButtonSpacing, instance.buttonWidth, instance.buttonHeight), OnMissionMenuPlay))
  instance.selectedPositionBase = 2 * instance.buttonHeight + instance.backPlayButtonSpacing + instance.upDownButtonSpacing + 0.5 * instance.imageSpacing
  table.insert(instance.overlays, Overlay:new("background_overlay", "dataS/menu/missionmenu_background.png", instance.spacingLeft * 0.5, instance.selectedPositionBase, 1 - instance.spacingLeft, 4 * (instance.imageSpacing + instance.imageSize)))
  instance.selectedOverlay = Overlay:new("selected_overlay", "dataS/menu/missionmenu_selected.png", 0, 0, 1 - instance.spacingLeft, instance.imageSpacing + instance.imageSize)
  table.insert(instance.overlays, instance.selectedOverlay)
  instance.emptyMedalOverlay = Overlay:new("emptyMedalOverlay", "dataS/missions/empty_medal.png", 0, 0, instance.imageSize * 0.75, instance.imageSize)
  instance.bronzeMedalOverlay = Overlay:new("bronzeMedalOverlay", "dataS/missions/bronze_medal.png", 0, 0, instance.imageSize * 0.75, instance.imageSize)
  instance.silverMedalOverlay = Overlay:new("silverMedalOverlay", "dataS/missions/silver_medal.png", 0, 0, instance.imageSize * 0.75, instance.imageSize)
  instance.goldMedalOverlay = Overlay:new("goldMedalOverlay", "dataS/missions/gold_medal.png", 0, 0, instance.imageSize * 0.75, instance.imageSize)
  if g_isDemo then
    instance.demoLockedOverlay = Overlay:new("demoLockedOverlay", "dataS/menu/demo_locked.png", 0, 0, instance.imageSize * 0.75, instance.imageSize)
  end
  return instance
end
function MissionMenu:mouseEvent(posX, posY, isDown, isUp, button)
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
        OnMissionMenuPlay()
      end
      self.doubleClickTime = self.time
    elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
      OnMissionMenuScrollUp()
    elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
      OnMissionMenuScrollDown()
    end
  end
end
function MissionMenu:keyEvent(unicode, sym, modifier, isDown)
end
function MissionMenu:update(dt)
  self.time = self.time + dt
end
function MissionMenu:render()
  self.selectedOverlay:setPosition(self.spacingLeft * 0.5, self.selectedPositionBase + (4 - self.selectedIndex + (self.startIndex - 1)) * (self.imageSpacing + self.imageSize))
  local numMissions = table.getn(self.missions)
  for i = 1, table.getn(self.overlays) do
    self.overlays[i]:render()
  end
  local textLeft = self.spacingLeft + self.imageSize * 0.75 + self.spacingLeft
  local endIndex = math.min(self.startIndex + 3, numMissions)
  for i = self.startIndex, endIndex do
    local mission = self.missions[i]
    local overlay = mission.overlayActive
    overlay:setPosition(self.spacingLeft, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.imageSize))
    overlay:render()
    if g_isDemo and mission.id ~= 11 and mission.id ~= 13 then
      self.demoLockedOverlay:setPosition(self.spacingLeft, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.imageSize))
      self.demoLockedOverlay:render()
    end
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(textLeft - 0.0025, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.textSizeTitle), self.textSizeTitle, mission.name)
    setTextBold(false)
    renderText(textLeft, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.textSizeTitle + self.textTitleSpacing + self.textSizeDesc), self.textSizeDesc, mission.desc)
    local medalOverlay = self.emptyMedalOverlay
    if mission.id ~= nil and g_finishedMissions[mission.id] ~= nil and g_finishedMissionsRecord[mission.id] ~= nil then
      local recordStr = ""
      local medalStr = ""
      if mission.missionType == "time" then
        local timeMinutesF = g_finishedMissionsRecord[mission.id] / 60000
        local timeMinutes = math.floor(timeMinutesF)
        local timeSeconds = math.floor((timeMinutesF - timeMinutes) * 60)
        local recordFloor = (timeSeconds + 60 * timeMinutes) * 1000
        if recordFloor <= mission.bronze then
          medalOverlay = self.bronzeMedalOverlay
          medalStr = "(" .. g_i18n:getText("Bronze") .. ")"
        end
        if recordFloor <= mission.silver then
          medalOverlay = self.silverMedalOverlay
          medalStr = "(" .. g_i18n:getText("Silver") .. ")"
        end
        if recordFloor <= mission.gold then
          medalOverlay = self.goldMedalOverlay
          medalStr = "(" .. g_i18n:getText("Gold") .. ")"
        end
        recordStr = string.format(g_i18n:getText("Record") .. ": %02d:%02d %s", timeMinutes, timeSeconds, medalStr)
      end
      if mission.missionType == "stacking" or mission.missionType == "strawElevatoring" then
        local record = g_finishedMissionsRecord[mission.id]
        local filename = "dataS/missions/empty_medal.png"
        if record >= mission.bronze then
          medalOverlay = self.bronzeMedalOverlay
          medalStr = "(" .. g_i18n:getText("Bronze") .. ")"
        end
        if record >= mission.silver then
          medalOverlay = self.silverMedalOverlay
          medalStr = "(" .. g_i18n:getText("Silver") .. ")"
        end
        if record >= mission.gold then
          medalOverlay = self.goldMedalOverlay
          medalStr = "(" .. g_i18n:getText("Gold") .. ")"
        end
        if mission.missionType == "stacking" then
          recordStr = string.format(g_i18n:getText("pallets") .. ": %d %s", g_finishedMissionsRecord[mission.id], medalStr)
        end
        if mission.missionType == "strawElevatoring" then
          recordStr = string.format(g_i18n:getText("bales") .. ": %d %s", g_finishedMissionsRecord[mission.id], medalStr)
        end
      end
      setTextBold(true)
      renderText(textLeft, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.textSizeTitle + self.textTitleSpacing + self.textSizeDesc * 5 - self.textTitleSpacing), self.textSizeDesc * 1.2, recordStr)
      setTextBold(false)
    end
    if medalOverlay ~= nil then
      medalOverlay:setPosition(1 - self.spacingLeft - self.imageSize * 0.75, 1 - (self.spacingTop + (self.imageSize + self.imageSpacing) * (i - self.startIndex) + self.imageSize))
      medalOverlay:render()
    end
  end
end
function MissionMenu:addButton(overlayButton)
  table.insert(self.overlays, overlayButton.overlay)
  table.insert(self.overlayButtons, overlayButton)
end
function MissionMenu:setSelectedIndex(index)
  local numMissions = table.getn(self.missions)
  self.selectedIndex = math.max(math.min(index, numMissions), 1)
  if self.selectedIndex > self.startIndex + 3 then
    self.startIndex = self.selectedIndex - 3
  elseif self.selectedIndex < self.startIndex then
    self.startIndex = self.selectedIndex
  end
end
function MissionMenu:startSelectedMission()
  local mission = self.missions[self.selectedIndex]
  if g_isDemo and mission.id ~= 11 and mission.id ~= 13 then
    return
  end
  setTerrainLoadDirectory("")
  g_missionLoaderDesc = {}
  g_missionLoaderDesc.scriptFilename = mission.scriptFilename
  g_missionLoaderDesc.scriptClass = mission.scriptClass
  g_missionLoaderDesc.id = mission.id
  g_missionLoaderDesc.bronze = mission.bronze
  g_missionLoaderDesc.silver = mission.silver
  g_missionLoaderDesc.gold = mission.gold
  g_missionLoaderDesc.missionType = mission.missionType
  g_missionLoaderDesc.overlayBriefing = mission.overlayBriefing
  g_missionLoaderDesc.overlayBriefingMedals = mission.overlayBriefingMedals
  g_missionLoaderDesc.backgroundOverlay = self.backgroundOverlay
  local stats = {}
  stats.fuelUsage = 0
  stats.seedUsage = 0
  stats.traveledDistance = 0
  stats.hectaresSeeded = 0
  stats.seedingDuration = 0
  stats.hectaresThreshed = 0
  stats.threshingDuration = 0
  stats.farmSiloFruitAmount = {}
  stats.revenue = 0
  stats.expenses = 0
  stats.playTime = 0
  stats.money = 1000
  stats.dayTime = 480
  stats.timeUntilNextRain = 0
  stats.rainTime = 0
  stats.nextRainDuration = 0
  stats.nextRainType = 0
  stats.nextRainValid = false
  g_missionLoaderDesc.stats = stats
  gameMenuSystem.medalsDisplay:setTimes(mission.bronze, mission.silver, mission.gold, mission.missionType)
  gameMenuSystem:loadingScreenMode()
end
function MissionMenu:reset()
  for i = 1, table.getn(self.overlayButtons) do
    self.overlayButtons[i]:reset()
  end
end

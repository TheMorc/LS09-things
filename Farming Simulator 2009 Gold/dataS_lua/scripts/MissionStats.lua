MissionStats = {}
MissionStats.alpha = 1
MissionStats.alphaInc = 0.05
local MissionStats_mt = Class(MissionStats)
function MissionStats:new()
  local instance = {}
  setmetatable(instance, MissionStats_mt)
  instance.difficulty = g_missionLoaderDesc.stats.difficulty
  if instance.difficulty == nil then
    instance.difficulty = 3
  end
  instance.screen = 1
  instance.textTitles = {}
  for i = 1, 4 do
    table.insert(instance.textTitles, g_i18n:getText("PDATitle" .. i))
  end
  instance.hudPDABasePosX = -0.008
  instance.hudPDABasePosY = -0.003
  instance.hudPDABaseWidth = 0.45
  instance.hudPDABaseHeight = instance.hudPDABaseWidth * 0.5625 * 1.3333333333333333
  instance.hudPDAFrameOverlay = Overlay:new("hudPDAFrameOverlay", "dataS/missions/hud_pda_frame.png", instance.hudPDABasePosX, instance.hudPDABasePosY, instance.hudPDABaseWidth, instance.hudPDABaseHeight)
  instance.hudPDABackgroundOverlay = Overlay:new("hudPDABackgroundOverlay", "dataS/missions/hud_pda_bg.png", instance.hudPDABasePosX, instance.hudPDABasePosY, instance.hudPDABaseWidth, instance.hudPDABaseHeight)
  instance.pdaMapWidth = instance.hudPDABaseWidth * 0.8
  instance.pdaMapHeight = instance.pdaMapWidth * 1.3333333333333333 / 2
  instance.pdaMapPosX = instance.hudPDABasePosX + instance.hudPDABaseWidth / 2 - instance.pdaMapWidth / 2
  instance.pdaMapPosY = instance.hudPDABasePosY + 0.11 * instance.hudPDABaseHeight
  instance.pdaMapUVs = {}
  for i = 1, 8 do
    table.insert(instance.pdaMapUVs, 0)
  end
  instance.pdaMapVisWidthMin = 0.2
  instance.pdaMapVisWidth = 0.2
  instance.pdaMapAspectRatio = 0.5
  instance.pdaMapVisHeight = instance.pdaMapVisWidth * instance.pdaMapAspectRatio
  instance.pdaMapArrowSize = instance.pdaMapWidth / 16
  instance.pdaMapArrowXPos = instance.pdaMapPosX + instance.pdaMapWidth / 2 - instance.pdaMapArrowSize / 2
  instance.pdaMapArrowYPos = instance.pdaMapPosY + instance.pdaMapHeight / 2 - instance.pdaMapArrowSize * 1.3333333333333333 / 2
  instance.pdaMapArrowRotation = 0
  instance.pdaMapArrowUVs = {}
  for i = 1, 8 do
    table.insert(instance.pdaMapArrowUVs, 0)
  end
  local iconSize = instance.pdaMapWidth / 12
  local fendtSize = instance.pdaMapWidth / 5
  local floraSize = instance.pdaMapWidth / 10
  local lighthouseSize = instance.pdaMapWidth / 28
  local bellSize = instance.pdaMapWidth / 12
  local mallSize = instance.pdaMapWidth / 11
  local millSize = instance.pdaMapWidth / 10
  local skateSize = instance.pdaMapWidth * 0.15
  instance.hotspots = {}
  table.insert(instance.hotspots, MapHotspot:new("Quaff Beer", "dataS/missions/hud_pda_spot_brewery.png", 1390, 650, iconSize, iconSize * 1.3333333333333333, false, false, 0))
  table.insert(instance.hotspots, MapHotspot:new("Fendt Station", "dataS/missions/hud_pda_spot_fendt.png", 494, 724, fendtSize, fendtSize * 1.3333333333333333 / 4, false, false, 0))
  table.insert(instance.hotspots, MapHotspot:new("Payzan Flora", "dataS/missions/hud_pda_spot_flora.png", 1472, 282, floraSize, floraSize * 1.3333333333333333, false, false, 0))
  table.insert(instance.hotspots, MapHotspot:new("Lighthouse1", "dataS/missions/hud_pda_spot_lighthouse.png", 222, 1780, lighthouseSize, lighthouseSize * 1.3333333333333333 * 4, false, false, 0))
  table.insert(instance.hotspots, MapHotspot:new("Lighthouse2", "dataS/missions/hud_pda_spot_lighthouse.png", 1820, 348, lighthouseSize, lighthouseSize * 1.3333333333333333 * 4, false, false, 0))
  table.insert(instance.hotspots, MapHotspot:new("Bell1", "dataS/missions/hud_pda_spot_bell.png", 1262, 694, bellSize, bellSize * 1.3333333333333333, false, false, 0))
  table.insert(instance.hotspots, MapHotspot:new("Bell2", "dataS/missions/hud_pda_spot_bell.png", 632, 260, bellSize, bellSize * 1.3333333333333333, false, false, 0))
  table.insert(instance.hotspots, MapHotspot:new("Seaside Shopping", "dataS/missions/hud_pda_spot_mall.png", 1016, 188, mallSize, mallSize * 1.3333333333333333, false, false, 0))
  table.insert(instance.hotspots, MapHotspot:new("Mill", "dataS/missions/hud_pda_spot_mill.png", 1839, 1216, millSize, millSize * 1.3333333333333333, false, false, 0))
  table.insert(instance.hotspots, MapHotspot:new("Skatepark", "dataS/missions/hud_pda_spot_skate.png", 898, 276, skateSize, skateSize * 1.3333333333333333 / 2, false, false, 0))
  instance.isMapZoomed = false
  instance.pdaMapArrow = Overlay:new("pdaMapArrow", "dataS/missions/pda_map_arrow.png", instance.pdaMapArrowXPos, instance.pdaMapArrowYPos, instance.pdaMapArrowSize, instance.pdaMapArrowSize * 1.3333333333333333)
  instance.pdaX = instance.hudPDABasePosX + instance.hudPDABaseWidth * 0.12
  instance.pdaY = instance.hudPDABasePosY + instance.hudPDABaseHeight - instance.hudPDABaseHeight * 0.1
  instance.pdaWidth = instance.hudPDABaseWidth * 0.745
  instance.pdaHeight = instance.hudPDABaseHeight * 0.645
  instance.pdaTopSpacing = instance.pdaHeight * 0.09
  instance.pdaTitleY = instance.pdaY - instance.pdaTopSpacing - 0.012
  instance.pdaTitleX = instance.pdaX + instance.pdaWidth * 0.05
  instance.pdaTitleTextSize = instance.pdaHeight / 8
  instance.pdaCol1 = instance.pdaX
  instance.pdaCol2 = instance.pdaX + instance.pdaWidth * 0.6
  instance.pdaHeadRow = instance.pdaY - 3 * instance.pdaTopSpacing
  instance.pdaFontSize = instance.pdaHeight / 10
  instance.pdaRowSpacing = instance.pdaFontSize * 1.15
  instance.playerXPos = 0
  instance.playerYPos = 0
  instance.playerZPos = 0
  instance.pdaCoordsXPos = instance.pdaX + instance.pdaWidth + 0.001
  instance.pdaCoordsYPos = instance.pdaY - 13 * instance.pdaTopSpacing - 0.005
  instance.pdaWeatherWidth = instance.pdaMapWidth * 0.96
  instance.pdaWeatherHeight = instance.pdaWeatherWidth * 1.3333333333333333 / 2
  instance.pdaWeatherPosX = instance.hudPDABasePosX + instance.hudPDABaseWidth / 2 - instance.pdaWeatherWidth / 2
  instance.pdaWeatherPosY = instance.hudPDABasePosY + 0.12 * instance.hudPDABaseHeight
  instance.pdaWeatherIconSize = instance.pdaWeatherWidth * 0.16666
  instance.pdaWeatherIconPosX = instance.pdaWeatherPosX + 0.042 * instance.pdaWeatherWidth
  instance.pdaWeatherIconPosY = instance.pdaWeatherPosY + 0.43 * instance.pdaWeatherHeight
  instance.pdaWeatherIconSpacing = instance.pdaWeatherWidth * 0.25
  instance.pdaWeatherTextPosX = instance.pdaWeatherPosX + 0.115 * instance.pdaWeatherWidth
  instance.pdaWeatherTextDayPosY = instance.pdaWeatherPosY + 0.81 * instance.pdaWeatherHeight
  instance.pdaWeatherTextDayTemperaturePosY = instance.pdaWeatherPosY + 0.215 * instance.pdaWeatherHeight
  instance.pdaWeatherTextNightTemperaturePosY = instance.pdaWeatherPosY + 0.04 * instance.pdaWeatherHeight
  instance.pdaWeatherTextSpacing = instance.pdaWeatherWidth * 0.25
  instance.pdaWeatherTextSize = instance.pdaWeatherWidth * 0.1
  instance.dayShownWeather = 0
  instance.dayShownPrices = 0
  instance.pdaWeatherBGOverlay = Overlay:new("pdaWeatherBGOverlay", "dataS/missions/hud_pda_weather_bg.png", instance.pdaWeatherPosX, instance.pdaWeatherPosY, instance.pdaWeatherWidth, instance.pdaWeatherHeight)
  setOverlayUVs(instance.pdaWeatherBGOverlay.overlayId, 0, 0, 0, 1, 4, 0, 4, 1)
  instance.weatherIconSun = "dataS/missions/hud_pda_weather_sun.png"
  instance.weatherIconRain = "dataS/missions/hud_pda_weather_rain.png"
  instance.weatherIconHail = "dataS/missions/hud_pda_weather_hail.png"
  instance.pdaWeatherIcons = {}
  for i = 1, 4 do
    table.insert(instance.pdaWeatherIcons, Overlay:new("pdaWeatherIcon" .. i, instance.weatherIconSun, instance.pdaWeatherIconPosX + (i - 1) * instance.pdaWeatherIconSpacing, instance.pdaWeatherIconPosY, instance.pdaWeatherIconSize, instance.pdaWeatherIconSize * 4 / 3))
  end
  instance.pdaWeatherDays = {}
  for i = 1, 7 do
    table.insert(instance.pdaWeatherDays, g_i18n:getText("Day" .. i))
  end
  instance.pdaWeatherTemperaturesDay = {}
  instance.pdaWeatherTemperaturesNight = {}
  for i = 1, 4 do
    instance.pdaWeatherTemperaturesDay[i] = 0
    instance.pdaWeatherTemperaturesNight[i] = 0
    instance.pdaWeatherTemperaturesDay[i] = math.random(17, 25)
    instance.pdaWeatherTemperaturesNight[i] = math.random(8, 16)
  end
  instance.priceArrowUp = "dataS/missions/hud_pda_priceArrow_up.png"
  instance.priceArrowFlat = "dataS/missions/hud_pda_priceArrow_flat.png"
  instance.priceArrowDown = "dataS/missions/hud_pda_priceArrow_down.png"
  FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_WHEAT].yesterdaysPrice = 0.21
  FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_RAPE].yesterdaysPrice = 0.56
  instance.priceArrowSize = instance.hudPDABaseWidth * 0.04
  instance.pdaPriceArrows = {}
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    table.insert(instance.pdaPriceArrows, Overlay:new("pdaPriceArrow" .. i, instance.priceArrowFlat, instance.pdaCol3, instance.pdaHeadRow - instance.pdaRowSpacing * i, instance.priceArrowSize, instance.priceArrowSize * 4 / 3))
  end
  instance.pdaPricesCol = {}
  instance.pdaPricesCol[1] = instance.pdaX
  instance.pdaPricesCol[2] = instance.pdaX + instance.pdaWidth * 0.3
  instance.pdaPricesCol[3] = instance.pdaX + instance.pdaWidth * 0.5
  instance.pdaPricesCol[4] = instance.pdaX + instance.pdaWidth * 0.7
  instance.pdaPricesCol[5] = instance.pdaX + instance.pdaWidth * 0.94
  instance.fuelUsageTotal = g_missionLoaderDesc.stats.fuelUsage
  instance.fuelUsageSession = 0
  instance.seedUsageTotal = g_missionLoaderDesc.stats.seedUsage
  instance.seedUsageSession = 0
  instance.traveledDistanceTotal = g_missionLoaderDesc.stats.traveledDistance
  instance.traveledDistanceSession = 0
  instance.hectaresSeededTotal = g_missionLoaderDesc.stats.hectaresSeeded
  instance.hectaresSeededSession = 0
  instance.seedingDurationTotal = g_missionLoaderDesc.stats.seedingDuration
  instance.seedingDurationSession = 0
  instance.hectaresThreshedTotal = g_missionLoaderDesc.stats.hectaresThreshed
  instance.hectaresThreshedSession = 0
  instance.threshingDurationTotal = g_missionLoaderDesc.stats.threshingDuration
  instance.threshingDurationSession = 0
  instance.farmSiloFruitAmount = g_missionLoaderDesc.stats.farmSiloFruitAmount
  instance.revenueTotal = g_missionLoaderDesc.stats.revenue
  instance.revenueSession = 0
  instance.expensesTotal = g_missionLoaderDesc.stats.expenses
  instance.expensesSession = 0
  instance.playTime = g_missionLoaderDesc.stats.playTime
  instance.playTimeSession = 0
  instance.money = g_missionLoaderDesc.stats.money
  instance.saveDate = "--.--.--"
  instance.pdaBeepSound = createSample("pdaBeepSample")
  loadSample(instance.pdaBeepSound, "data/maps/sounds/pdaBeep.wav", false)
  instance.showPDA = false
  instance.smoothSpeed = 0
  return instance
end
function MissionStats:createMapHotspot(name, imageFilename, xMapPos, yMapPos, width, height, blinking, persistent, objectId)
  local mapHotspot = MapHotspot:new(name, imageFilename, xMapPos, yMapPos, width, height, blinking, persistent, objectId)
  table.insert(self.hotspots, mapHotspot)
  return mapHotspot
end
function MissionStats:delete()
  self.hudPDABackgroundOverlay:delete()
  self.hudPDAFrameOverlay:delete()
  if self.pdaMapOverlay ~= nil then
    self.pdaMapOverlay:delete()
  end
  self.pdaMapArrow:delete()
  delete(self.pdaBeepSound)
  for k, v in pairs(self.hotspots) do
    v:delete()
  end
end
function MissionStats:loadMap(name)
  if self.pdaMapOverlay ~= nil then
    self.pdaMapOverlay:delete()
  end
  self.pdaMapOverlay = Overlay:new("pdaMapOverlay", "data/maps/" .. name .. "/pda_map.png", self.pdaMapPosX, self.pdaMapPosY, self.pdaMapWidth, self.pdaMapHeight)
end
function MissionStats:mouseEvent(posX, posY, isDown, isUp, button)
end
function MissionStats:keyEvent(unicode, sym, modifier, isDown)
end
function MissionStats:update(dt)
  if InputBinding.hasEvent(InputBinding.TOGGLE_PDA_ZOOM) then
    self.isMapZoomed = not self.isMapZoomed
  end
  local dtMinutes = dt / 60000
  self.playTime = self.playTime + dtMinutes
  self.playTimeSession = self.playTimeSession + dtMinutes
  if InputBinding.hasEvent(InputBinding.TOGGLE_PDA) then
    playSample(self.pdaBeepSound, 1, 0.3, 0)
    if self.showPDA then
      if self.screen == 4 then
        self.showPDA = false
        self.screen = 1
      else
        self.screen = self.screen + 1
      end
    else
      self.showPDA = true
      self.screen = 1
    end
  end
end
function MissionStats:draw()
  if self.showPDA then
    self.hudPDABackgroundOverlay:render()
    if self.screen == 1 then
      if g_currentMission.controlPlayer then
        self.playerXPos, self.playerYPos, self.playerZPos = getTranslation(Player.rootNode)
        self.pdaMapVisWidth = self.pdaMapVisWidthMin
        local xRot, yRot, zRot = getRotation(Player.camera)
        self.pdaMapArrowRotation = yRot
      elseif g_currentMission.currentVehicle ~= nil then
        self.playerXPos, self.playerYPos, self.playerZPos = getTranslation(g_currentMission.currentVehicle.rootNode)
        local speed = g_currentMission.currentVehicle.lastSpeed * g_currentMission.currentVehicle.speedDisplayScale * 3600
        self.smoothSpeed = self.smoothSpeed * 0.95 + speed * 0.05
        local targetSize = math.max(self.smoothSpeed / 100, self.pdaMapVisWidthMin)
        local test = self.pdaMapVisWidth - targetSize
        if math.abs(test) > 0.01 then
          self.pdaMapVisWidth = self.pdaMapVisWidth - test / 32
        end
        local dx, dy, dz = localDirectionToWorld(g_currentMission.currentVehicle.rootNode, 0, 0, 1)
        self.pdaMapArrowRotation = Utils.getYRotationFromDirection(dx, dz) + math.pi
      end
      if self.isMapZoomed then
        self.pdaMapVisWidth = 1
      end
      self.playerXPos = math.floor(self.playerXPos) + 1024
      self.playerZPos = math.floor(self.playerZPos) + 1024
      local x = self.playerXPos / 2048
      local y = self.playerZPos / 2048
      self.pdaMapVisHeight = self.pdaMapVisWidth * self.pdaMapAspectRatio
      local leftBorderReached = false
      local rightBorderReached = false
      local topBorderReached = false
      local bottomBorderReached = false
      self.pdaMapUVs[1] = x - self.pdaMapVisWidth / 2
      self.pdaMapUVs[2] = 1 - y - self.pdaMapVisHeight / 2
      self.pdaMapUVs[3] = self.pdaMapUVs[1]
      self.pdaMapUVs[4] = 1 - y + self.pdaMapVisHeight / 2
      self.pdaMapUVs[5] = x + self.pdaMapVisWidth / 2
      self.pdaMapUVs[6] = 1 - y - self.pdaMapVisHeight / 2
      self.pdaMapUVs[7] = self.pdaMapUVs[5]
      self.pdaMapUVs[8] = 1 - y + self.pdaMapVisHeight / 2
      self.pdaMapArrow.x = self.pdaMapArrowXPos
      self.pdaMapArrow.y = self.pdaMapArrowYPos
      if 0 > self.pdaMapUVs[1] then
        leftBorderReached = true
        self.pdaMapArrow.x = self.pdaMapArrowXPos + self.pdaMapWidth * self.pdaMapUVs[1] * 1 / self.pdaMapVisWidth
        if self.pdaMapArrow.x < self.pdaMapPosX - self.pdaMapArrowSize then
          self.pdaMapArrow.x = self.pdaMapPosX - self.pdaMapArrowSize
        end
        self.pdaMapUVs[1] = 0
        self.pdaMapUVs[3] = self.pdaMapUVs[1]
        self.pdaMapUVs[5] = self.pdaMapVisWidth
        self.pdaMapUVs[7] = self.pdaMapUVs[5]
      end
      if self.pdaMapUVs[1] > 1 - self.pdaMapVisWidth then
        rightBorderReached = true
        self.pdaMapArrow.x = self.pdaMapArrowXPos + self.pdaMapWidth * (self.pdaMapUVs[1] - (1 - self.pdaMapVisWidth)) * 1 / self.pdaMapVisWidth
        if self.pdaMapArrow.x > self.pdaMapPosX + self.pdaMapWidth then
          self.pdaMapArrow.x = self.pdaMapPosX + self.pdaMapWidth
        end
        self.pdaMapUVs[1] = 1 - self.pdaMapVisWidth
        self.pdaMapUVs[3] = self.pdaMapUVs[1]
        self.pdaMapUVs[5] = 1
        self.pdaMapUVs[7] = self.pdaMapUVs[5]
      end
      if 0 > self.pdaMapUVs[2] then
        bottomBorderReached = true
        self.pdaMapArrow.y = self.pdaMapArrowYPos + self.pdaMapHeight * self.pdaMapUVs[2] * 1 / self.pdaMapVisHeight
        if self.pdaMapArrow.y < self.pdaMapPosY - self.pdaMapArrowSize * 1.25 then
          self.pdaMapArrow.y = self.pdaMapPosY - self.pdaMapArrowSize * 1.25
        end
        self.pdaMapUVs[2] = 0
        self.pdaMapUVs[6] = self.pdaMapUVs[2]
        self.pdaMapUVs[4] = self.pdaMapVisHeight
        self.pdaMapUVs[8] = self.pdaMapUVs[4]
      end
      if self.pdaMapUVs[2] > 1 - self.pdaMapVisHeight then
        topBorderReached = true
        self.pdaMapArrow.y = self.pdaMapArrowYPos + self.pdaMapHeight * (self.pdaMapUVs[2] - (1 - self.pdaMapVisHeight)) * 1 / self.pdaMapVisHeight
        if self.pdaMapArrow.y > self.pdaMapPosY + self.pdaMapHeight then
          self.pdaMapArrow.y = self.pdaMapPosY + self.pdaMapHeight
        end
        self.pdaMapUVs[2] = 1 - self.pdaMapVisHeight
        self.pdaMapUVs[6] = self.pdaMapUVs[2]
        self.pdaMapUVs[4] = 1
        self.pdaMapUVs[8] = self.pdaMapUVs[4]
      end
      if self.pdaMapOverlay ~= nil then
        setOverlayUVs(self.pdaMapOverlay.overlayId, self.pdaMapUVs[1], self.pdaMapUVs[2], self.pdaMapUVs[3], self.pdaMapUVs[4], self.pdaMapUVs[5], self.pdaMapUVs[6], self.pdaMapUVs[7], self.pdaMapUVs[8])
      end
      self.pdaMapArrowUVs[1] = -0.5 * math.cos(-self.pdaMapArrowRotation) + 0.5 * math.sin(-self.pdaMapArrowRotation) + 0.5
      self.pdaMapArrowUVs[2] = -0.5 * math.sin(-self.pdaMapArrowRotation) - 0.5 * math.cos(-self.pdaMapArrowRotation) + 0.5
      self.pdaMapArrowUVs[3] = -0.5 * math.cos(-self.pdaMapArrowRotation) - 0.5 * math.sin(-self.pdaMapArrowRotation) + 0.5
      self.pdaMapArrowUVs[4] = -0.5 * math.sin(-self.pdaMapArrowRotation) + 0.5 * math.cos(-self.pdaMapArrowRotation) + 0.5
      self.pdaMapArrowUVs[5] = 0.5 * math.cos(-self.pdaMapArrowRotation) + 0.5 * math.sin(-self.pdaMapArrowRotation) + 0.5
      self.pdaMapArrowUVs[6] = 0.5 * math.sin(-self.pdaMapArrowRotation) - 0.5 * math.cos(-self.pdaMapArrowRotation) + 0.5
      self.pdaMapArrowUVs[7] = 0.5 * math.cos(-self.pdaMapArrowRotation) - 0.5 * math.sin(-self.pdaMapArrowRotation) + 0.5
      self.pdaMapArrowUVs[8] = 0.5 * math.sin(-self.pdaMapArrowRotation) + 0.5 * math.cos(-self.pdaMapArrowRotation) + 0.5
      setOverlayUVs(self.pdaMapArrow.overlayId, self.pdaMapArrowUVs[1], self.pdaMapArrowUVs[2], self.pdaMapArrowUVs[3], self.pdaMapArrowUVs[4], self.pdaMapArrowUVs[5], self.pdaMapArrowUVs[6], self.pdaMapArrowUVs[7], self.pdaMapArrowUVs[8])
      local minDistance = 1000000
      local closestHotspot = 0
      for k, currentHotspot in pairs(self.hotspots) do
        currentHotspot.visible = false
        if currentHotspot.objectId ~= 0 then
          local objectX, objectY, objectZ = getTranslation(currentHotspot.objectId)
          currentHotspot.xMapPos = objectX + 1024
          currentHotspot.yMapPos = objectZ + 1024
        end
        if (currentHotspot.persistent or currentHotspot.xMapPos / 2048 < x + self.pdaMapVisWidth / 2 and currentHotspot.xMapPos / 2048 > x - self.pdaMapVisWidth / 2) and (currentHotspot.persistent or currentHotspot.yMapPos / 2048 < y + self.pdaMapVisHeight / 2 and currentHotspot.yMapPos / 2048 > y - self.pdaMapVisHeight / 2) then
          currentHotspot.visible = true
          currentHotspot.overlayId.x = self.pdaMapPosX + self.pdaMapWidth / 2 - currentHotspot.width / 2
          currentHotspot.overlayId.y = self.pdaMapPosY + self.pdaMapHeight / 2 - currentHotspot.height / 2
          if not leftBorderReached and not rightBorderReached then
            currentHotspot.overlayId.x = currentHotspot.overlayId.x + (currentHotspot.xMapPos / 2048 - x) * 1 / self.pdaMapVisWidth * 0.36
          elseif leftBorderReached then
            currentHotspot.overlayId.x = currentHotspot.overlayId.x + (currentHotspot.xMapPos / 2048 - self.pdaMapVisWidth / 2) * 1 / self.pdaMapVisWidth * 0.36
          else
            currentHotspot.overlayId.x = currentHotspot.overlayId.x + (currentHotspot.xMapPos / 2048 - (1 - self.pdaMapVisWidth / 2)) * 1 / self.pdaMapVisWidth * 0.36
          end
          if not topBorderReached and not bottomBorderReached then
            currentHotspot.overlayId.y = currentHotspot.overlayId.y - (currentHotspot.yMapPos / 2048 - y) * 1 / self.pdaMapVisWidth * 0.36 * 1.3333333333333333
          elseif topBorderReached then
            currentHotspot.overlayId.y = currentHotspot.overlayId.y - (currentHotspot.yMapPos / 2048 - self.pdaMapVisHeight / 2) * 1 / self.pdaMapVisWidth * 0.36 * 1.3333333333333333
          else
            currentHotspot.overlayId.y = currentHotspot.overlayId.y - (currentHotspot.yMapPos / 2048 - (1 - self.pdaMapVisHeight / 2)) * 1 / self.pdaMapVisWidth * 0.36 * 1.3333333333333333
          end
        end
        if currentHotspot.persistent and currentHotspot.enabled then
          local deltaX = currentHotspot.xMapPos - self.playerXPos
          local deltaY = currentHotspot.yMapPos - self.playerZPos
          local dist = math.sqrt(deltaX ^ 2 + deltaY ^ 2)
          if minDistance > dist then
            closestHotspot = k
            minDistance = dist
          end
          local dir = 1000000
          if math.abs(deltaY) > 1.0E-4 then
            dir = deltaX / deltaY
          end
          if currentHotspot.overlayId.y > self.pdaMapPosY + self.pdaMapHeight - currentHotspot.height then
            currentHotspot.overlayId.y = self.pdaMapPosY + self.pdaMapHeight - currentHotspot.height
            currentHotspot.overlayId.x = self.pdaMapArrow.x
            currentHotspot.overlayId.x = currentHotspot.overlayId.x - dir * (self.pdaMapHeight / 2 - 1.4 * currentHotspot.height)
          end
          if currentHotspot.overlayId.y < self.pdaMapPosY - currentHotspot.height / 4 then
            currentHotspot.overlayId.y = self.pdaMapPosY - currentHotspot.height / 4
            currentHotspot.overlayId.x = self.pdaMapArrow.x
            currentHotspot.overlayId.x = currentHotspot.overlayId.x + dir * (self.pdaMapHeight / 2 - 1.125 * currentHotspot.height)
          end
          if currentHotspot.overlayId.x > self.pdaMapPosX + self.pdaMapWidth - currentHotspot.width * 0.75 then
            currentHotspot.overlayId.x = self.pdaMapPosX + self.pdaMapWidth - currentHotspot.width * 0.75
            currentHotspot.overlayId.y = self.pdaMapArrow.y
            currentHotspot.overlayId.y = currentHotspot.overlayId.y - 1 / dir * (self.pdaMapWidth / 2 + currentHotspot.width * 2)
          end
          if currentHotspot.overlayId.x < self.pdaMapPosX - currentHotspot.width / 4 then
            currentHotspot.overlayId.x = self.pdaMapPosX - currentHotspot.width / 4
            currentHotspot.overlayId.y = self.pdaMapArrow.y
            currentHotspot.overlayId.y = currentHotspot.overlayId.y + 1 / dir * (self.pdaMapWidth / 2 + currentHotspot.width * 2)
          end
        end
      end
      for k, currentHotspot in pairs(self.hotspots) do
        if currentHotspot.persistent then
          if k == closestHotspot then
            if not currentHotspot.blinking then
              currentHotspot:setBlinking(true)
            end
          elseif currentHotspot.blinking then
            currentHotspot:setBlinking(false)
          end
        end
      end
      if self.pdaMapOverlay ~= nil then
        self.pdaMapOverlay:render()
      end
      for k, v in pairs(self.hotspots) do
        v:render()
      end
      self.pdaMapArrow:render()
      setTextAlignment(RenderText.ALIGN_RIGHT)
      setTextColor(0, 0, 0, 1)
      setTextBold(true)
      renderText(self.pdaCoordsXPos, self.pdaCoordsYPos - 0.002, self.pdaFontSize, "[" .. self.playerXPos .. ", " .. self.playerZPos .. "]")
      setTextColor(0.8, 1, 0.9, 1)
      renderText(self.pdaCoordsXPos, self.pdaCoordsYPos, self.pdaFontSize, "[" .. self.playerXPos .. ", " .. self.playerZPos .. "]")
      setTextAlignment(RenderText.ALIGN_LEFT)
      setTextColor(1, 1, 1, 1)
      setTextBold(false)
    elseif self.screen == 2 then
      self.pdaWeatherBGOverlay:render()
      if self.dayShownWeather ~= g_currentMission.environment.currentDay then
        if g_currentMission.environment.dayNightCycle then
          for i = 1, 3 do
            self.pdaWeatherTemperaturesDay[i] = self.pdaWeatherTemperaturesDay[i + 1]
            self.pdaWeatherTemperaturesNight[i] = self.pdaWeatherTemperaturesNight[i + 1]
          end
          self.pdaWeatherTemperaturesDay[4] = math.random(17, 25)
          self.pdaWeatherTemperaturesNight[4] = math.random(9, 16)
          local timeUntilNextRain = g_currentMission.environment.timeUntilNextRain / 1440
          local timeUntilRainAfterNext = timeUntilNextRain + g_currentMission.environment.timeUntilRainAfterNext / 1440
          local nextRainType = self.weatherIconRain
          if g_currentMission.environment.nextRainType == 1 then
            nextRainType = self.weatherIconHail
          end
          local rainTypeAfterNext = self.weatherIconRain
          if g_currentMission.environment.rainTypeAfterNext == 1 then
            rainTypeAfterNext = self.weatherIconHail
          end
          for i = 1, 4 do
            local currentNewIcon = self.weatherIconSun
            self.pdaWeatherIcons[i]:delete()
            if i < timeUntilNextRain and timeUntilNextRain < i + 1 then
              currentNewIcon = nextRainType
              if nextRainType == self.weatherIconHail and self.pdaWeatherTemperaturesDay[i] >= 19 then
                self.pdaWeatherTemperaturesDay[i] = self.pdaWeatherTemperaturesDay[i] - 8
                self.pdaWeatherTemperaturesNight[i] = self.pdaWeatherTemperaturesDay[i] - 4
              end
            end
            if i < timeUntilRainAfterNext and timeUntilRainAfterNext < i + 1 then
              currentNewIcon = rainTypeAfterNext
              if rainTypeAfterNext == self.weatherIconHail and self.pdaWeatherTemperaturesDay[i] >= 19 then
                self.pdaWeatherTemperaturesDay[i] = self.pdaWeatherTemperaturesDay[i] - 8
                self.pdaWeatherTemperaturesNight[i] = self.pdaWeatherTemperaturesDay[i] - 4
              end
            end
            self.pdaWeatherIcons[i] = Overlay:new("pdaWeatherIcon" .. i, currentNewIcon, self.pdaWeatherIconPosX + (i - 1) * self.pdaWeatherIconSpacing, self.pdaWeatherIconPosY, self.pdaWeatherIconSize, self.pdaWeatherIconSize * 4 / 3)
          end
          self.dayShownWeather = g_currentMission.environment.currentDay
        else
          self.dayShownWeather = g_currentMission.environment.currentDay
        end
      end
      for k, v in pairs(self.pdaWeatherIcons) do
        v:render()
      end
      setTextAlignment(RenderText.ALIGN_CENTER)
      setTextColor(0, 0, 0, 1)
      setTextBold(true)
      for i = 1, 4 do
        renderText(self.pdaWeatherTextPosX + (i - 1) * self.pdaWeatherTextSpacing, self.pdaWeatherTextDayPosY - 0.002, self.pdaWeatherTextSize, self.pdaWeatherDays[math.mod(math.mod(self.dayShownWeather, 7) + i - 1, 7) + 1])
        renderText(self.pdaWeatherTextPosX + (i - 1) * self.pdaWeatherTextSpacing, self.pdaWeatherTextDayTemperaturePosY - 0.002, self.pdaWeatherTextSize * 1.2, tostring(self.pdaWeatherTemperaturesDay[i]) .. g_i18n:getText("TemperatureSymbol"))
        renderText(self.pdaWeatherTextPosX + (i - 1) * self.pdaWeatherTextSpacing, self.pdaWeatherTextNightTemperaturePosY - 0.002, self.pdaWeatherTextSize * 1.2, tostring(self.pdaWeatherTemperaturesNight[i]) .. g_i18n:getText("TemperatureSymbol"))
      end
      for i = 1, 4 do
        setTextColor(0.9, 0.95, 1, 1)
        renderText(self.pdaWeatherTextPosX + (i - 1) * self.pdaWeatherTextSpacing, self.pdaWeatherTextDayPosY, self.pdaWeatherTextSize, self.pdaWeatherDays[math.mod(math.mod(self.dayShownWeather, 7) + i - 1, 7) + 1])
        setTextColor(1, 1, 0.5, 1)
        renderText(self.pdaWeatherTextPosX + (i - 1) * self.pdaWeatherTextSpacing, self.pdaWeatherTextDayTemperaturePosY, self.pdaWeatherTextSize * 1.2, tostring(self.pdaWeatherTemperaturesDay[i]) .. g_i18n:getText("TemperatureSymbol"))
        setTextColor(0.2, 0.3, 0.7, 1)
        renderText(self.pdaWeatherTextPosX + (i - 1) * self.pdaWeatherTextSpacing, self.pdaWeatherTextNightTemperaturePosY, self.pdaWeatherTextSize * 1.2, tostring(self.pdaWeatherTemperaturesNight[i]) .. g_i18n:getText("TemperatureSymbol"))
      end
      setTextBold(false)
      setTextAlignment(RenderText.ALIGN_LEFT)
      setTextColor(1, 1, 1, 1)
    elseif self.screen == 3 then
      if self.dayShownPrices ~= g_currentMission.environment.currentDay then
        for i = 1, table.getn(self.pdaPriceArrows) do
          local currentNewArrow = self.priceArrowFlat
          local delta = FruitUtil.fruitIndexToDesc[i].pricePerLiter - FruitUtil.fruitIndexToDesc[i].yesterdaysPrice
          if 0 < delta then
            currentNewArrow = self.priceArrowUp
          elseif delta < 0 then
            currentNewArrow = self.priceArrowDown
          end
          self.pdaPriceArrows[i]:delete()
          self.pdaPriceArrows[i] = Overlay:new("pdaPriceArrow" .. i, currentNewArrow, self.pdaPricesCol[5], self.pdaHeadRow - self.pdaRowSpacing * i, self.priceArrowSize, self.priceArrowSize * 4 / 3)
        end
        self.dayShownWeather = g_currentMission.environment.currentDay
      end
      setTextColor(0.8, 1, 0.9, 1)
      local temp = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_WHEAT].name
      temp = string.upper(string.sub(temp, 1, 1)) .. string.sub(temp, 2, string.len(temp))
      local stationCounter = 0
      local printedFruitName = {}
      for k, currentTipTrigger in pairs(g_currentMission.tipTriggers) do
        if currentTipTrigger.appearsOnPDA and stationCounter < 3 then
          stationCounter = stationCounter + 1
          setTextBold(true)
          local stationName = currentTipTrigger.stationName
          if g_i18n:hasText(stationName) then
            stationName = g_i18n:getText(stationName)
          end
          renderText(self.pdaPricesCol[stationCounter + 1], self.pdaHeadRow, self.pdaFontSize * 1.125, stationName)
          setTextBold(false)
          for i = 1, FruitUtil.NUM_FRUITTYPES do
            if currentTipTrigger.acceptedFruitTypes[i] then
              local difficultyMultiplier = math.max(3 * (3 - self.difficulty), 1)
              renderText(self.pdaPricesCol[stationCounter + 1], self.pdaHeadRow - self.pdaRowSpacing * i, self.pdaFontSize, tostring(math.floor(g_i18n:getCurrency(math.ceil(FruitUtil.fruitIndexToDesc[i].pricePerLiter * 1000 * currentTipTrigger.priceMultipliers[i] * difficultyMultiplier)))))
              if not printedFruitName[i] then
                printedFruitName[i] = true
                local fruitName = FruitUtil.fruitIndexToDesc[i].name
                if g_i18n:hasText(fruitName) then
                  fruitName = g_i18n:getText(fruitName)
                end
                if i == 1 then
                  renderText(self.pdaPricesCol[1], self.pdaHeadRow - self.pdaRowSpacing * i, self.pdaFontSize, fruitName .. " " .. g_i18n:getText("PricePerTon"))
                else
                  renderText(self.pdaPricesCol[1], self.pdaHeadRow - self.pdaRowSpacing * i, self.pdaFontSize, fruitName)
                end
                self.pdaPriceArrows[i].y = self.pdaHeadRow - self.pdaRowSpacing * i
                self.pdaPriceArrows[i]:render()
              end
            end
          end
        end
      end
      setTextBold(false)
      setTextColor(1, 1, 1, 1)
    else
      setTextBold(true)
      setTextColor(0.8, 1, 0.9, 1)
      setTextBold(false)
      local yOffset = 0.01
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 1 + yOffset, self.pdaFontSize, g_i18n:getText("Wheat_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 1 + yOffset, self.pdaFontSize, string.format("%d", Utils.getNoNil(self.farmSiloFruitAmount[FruitUtil.FRUITTYPE_WHEAT], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 2 + yOffset, self.pdaFontSize, g_i18n:getText("Barley_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 2 + yOffset, self.pdaFontSize, string.format("%d", Utils.getNoNil(self.farmSiloFruitAmount[FruitUtil.FRUITTYPE_BARLEY], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 3 + yOffset, self.pdaFontSize, g_i18n:getText("Rapeseed_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 3 + yOffset, self.pdaFontSize, string.format("%d", Utils.getNoNil(self.farmSiloFruitAmount[FruitUtil.FRUITTYPE_RAPE], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 4 + yOffset, self.pdaFontSize, g_i18n:getText("Maize_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 4 + yOffset, self.pdaFontSize, string.format("%d", Utils.getNoNil(self.farmSiloFruitAmount[FruitUtil.FRUITTYPE_MAIZE], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 5 + yOffset, self.pdaFontSize, g_i18n:getText("Fuel") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 5 + yOffset, self.pdaFontSize, string.format("%d", self.fuelUsageTotal))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 6 + yOffset, self.pdaFontSize, g_i18n:getText("Capital") .. " [" .. g_i18n:getText("Currency_symbol") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 6 + yOffset, self.pdaFontSize, string.format("%d", g_i18n:getCurrency(self.money)))
      if g_currentMission.deliveredBottles ~= nil and g_currentMission.sessionDeliveredBottles ~= nil then
        renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 7 + yOffset, self.pdaFontSize, g_i18n:getText("Bottles"))
        renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 7 + yOffset, self.pdaFontSize, string.format("%d", g_currentMission.deliveredBottles))
      end
      if g_currentMission.reputation ~= nil then
        renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 8 + yOffset, self.pdaFontSize, g_i18n:getText("Reputation") .. " [%]")
        renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 8 + yOffset, self.pdaFontSize, string.format("%d", g_currentMission.reputation))
      end
      setTextColor(1, 1, 1, 1)
    end
    self.hudPDAFrameOverlay:render()
    setTextBold(true)
    setTextColor(0, 0, 0, 1)
    renderText(self.pdaTitleX, self.pdaTitleY - 0.002, self.pdaTitleTextSize, self.textTitles[self.screen])
    setTextColor(1, 1, 1, 1)
    renderText(self.pdaTitleX, self.pdaTitleY, self.pdaTitleTextSize, self.textTitles[self.screen])
    MissionStats.alpha = MissionStats.alpha + MissionStats.alphaInc
    if 1 < MissionStats.alpha then
      MissionStats.alphaInc = -MissionStats.alphaInc
      MissionStats.alpha = 1
    elseif 0 > MissionStats.alpha then
      MissionStats.alphaInc = -MissionStats.alphaInc
      MissionStats.alpha = 0
    end
  end
end
MapHotspot = {}
local MapHotspot_mt = Class(MapHotspot)
function MapHotspot:new(name, imageFilename, xMapPos, yMapPos, width, height, blinking, persistent, objectId)
  if imageFilename ~= nil then
    tempOverlayId = Overlay:new(name, imageFilename, 0, 0, width, height)
  end
  return setmetatable({
    overlayId = tempOverlayId,
    xMapPos = xMapPos,
    yMapPos = yMapPos,
    width = width,
    height = height,
    blinking = blinking,
    persistent = persistent,
    objectId = objectId,
    visible = true,
    enabled = true
  }, MapHotspot_mt)
end
function MapHotspot:delete()
  self.enabled = false
  if self.overlayId ~= nil then
    delete(self.overlayId)
  end
end
function MapHotspot:render()
  if self.visible and self.enabled then
    if self.blinking then
      self.overlayId:setColor(1, 1, 1, MissionStats.alpha)
    end
    self.overlayId:render()
  end
end
function MapHotspot:setBlinking(blinking)
  self.blinking = blinking
  if not blinking then
    self.overlayId:setColor(1, 1, 1, 1)
  end
end

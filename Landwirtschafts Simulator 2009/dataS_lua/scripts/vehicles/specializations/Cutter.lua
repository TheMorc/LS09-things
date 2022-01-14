Cutter = {}
function Cutter.prerequisitesPresent(specializations)
  return true
end
function Cutter:load(xmlFile)
  self.setReelSpeed = SpecializationUtil.callSpecializationsFunction("setReelSpeed")
  self.onStartReel = SpecializationUtil.callSpecializationsFunction("onStartReel")
  self.onStopReel = SpecializationUtil.callSpecializationsFunction("onStopReel")
  self.isReelStarted = Cutter.isReelStarted
  self.resetFruitType = SpecializationUtil.callSpecializationsFunction("resetFruitType")
  self.setFruitType = SpecializationUtil.callSpecializationsFunction("setFruitType")
  self.reelNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.reel#index"))
  self.rollNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.roll#index"))
  local indexSpikesStr = getXMLString(xmlFile, "vehicle.reelspikes#index")
  self.spikesCount = getXMLInt(xmlFile, "vehicle.reelspikes#count")
  self.spikesRootNode = Utils.indexToObject(self.components, indexSpikesStr)
  self.sideArm = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.sidearms#index"))
  self.sideArmMovable = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.sidearms#movable"), false)
  self.threshingParticleSystems = {}
  local psName = "vehicle.threshingParticleSystem"
  Utils.loadParticleSystem(xmlFile, self.threshingParticleSystems, psName, self.components, false, nil, self.baseDirectory)
  self.fruitExtraObjects = {}
  local i = 0
  while true do
    local key = string.format("vehicle.fruitExtraObjects.fruitExtraObject(%d)", i)
    local t = getXMLString(xmlFile, key .. "#fruitType")
    local index = getXMLString(xmlFile, key .. "#index")
    if t == nil or index == nil then
      break
    end
    local node = Utils.indexToObject(self.components, index)
    if node ~= nil then
      if self.currentExtraObject == nil then
        self.currentExtraObject = node
        setVisibility(node, true)
      else
        setVisibility(node, false)
      end
      self.fruitExtraObjects[t] = node
    end
    i = i + 1
  end
  self.preferedCombineSize = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.preferedCombineSize"), 1)
  self.fruitTypes = {}
  self.fruitTypes[FruitUtil.FRUITTYPE_UNKNOWN] = true
  local fruitTypes = getXMLString(xmlFile, "vehicle.fruitTypes#fruitTypes")
  if fruitTypes ~= nil then
    local types = Utils.splitString(" ", fruitTypes)
    for k, v in pairs(types) do
      local desc = FruitUtil.fruitTypes[v]
      if desc ~= nil then
        self.fruitTypes[desc.index] = true
      end
    end
  end
  self.currentFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.reelStarted = false
  self.forceLowSpeed = false
  self.speedLimitLow = 12
  self.speedLimit = 17.5
  self.speedViolationMaxTime = 50
  self.speedViolationTimer = self.speedViolationMaxTime
  self.printRainWarning = false
  self.lastArea = 0
end
function Cutter:delete()
  Utils.deleteParticleSystem(self.threshingParticleSystems)
end
function Cutter:mouseEvent(posX, posY, isDown, isUp, button)
end
function Cutter:keyEvent(unicode, sym, modifier, isDown)
end
function Cutter:update(dt)
  self.lastArea = 0
  if self.reelStarted and 0 > self.movingDirection then
    local speedLimit = self.speedLimit
    if Cutter.getUseLowSpeedLimit(self) then
      speedLimit = self.speedLimitLow
    end
    if speedLimit < self.lastSpeed * 3600 then
      self.speedViolationTimer = self.speedViolationTimer - dt
    else
      self.speedViolationTimer = self.speedViolationMaxTime
    end
    if 0 < self.speedViolationTimer then
      if g_currentMission.environment.lastRainScale <= 0.1 and g_currentMission.environment.timeSinceLastRain > 30 then
        self.printRainWarning = false
        local lowFillLevel = false
        if self.attacherVehicle ~= nil and 0 < self.attacherVehicle.grainTankFillLevel and self.attacherVehicle.grainTankFillLevel / self.attacherVehicle.grainTankCapacity <= self.attacherVehicle.minThreshold then
          lowFillLevel = true
        end
        local foundFruitType = false
        local oldFruitType = self.currentFruitType
        if self.currentFruitType == FruitUtil.FRUITTYPE_UNKNOWN or lowFillLevel then
          for fruitType, v in pairs(self.fruitTypes) do
            local isOk = true
            if self.attacherVehicle ~= nil and self.attacherVehicle.allowGrainTankFruitType ~= nil then
              isOk = self.attacherVehicle:allowGrainTankFruitType(fruitType)
            end
            if isOk then
              for k, area in pairs(self.cuttingAreas) do
                local x, y, z = getWorldTranslation(area.start)
                local x1, y1, z1 = getWorldTranslation(area.width)
                local x2, y2, z2 = getWorldTranslation(area.height)
                local area = Utils.getFruitArea(fruitType, x, z, x1, z1, x2, z2)
                if 0 < area then
                  self.currentFruitType = fruitType
                  if self.currentFruitType ~= oldFruitType then
                    Cutter.updateExtraObjects(self)
                    self.attacherVehicle:emptyGrainTankIfLowFillLevel()
                  end
                  foundFruitType = true
                  break
                end
              end
              if foundFruitType then
                break
              end
            end
          end
        end
        if self.currentFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
          local realArea = 0
          for k, area in pairs(self.cuttingAreas) do
            local x, y, z = getWorldTranslation(area.start)
            local x1, y1, z1 = getWorldTranslation(area.width)
            local x2, y2, z2 = getWorldTranslation(area.height)
            Utils.updateFruitCutShortArea(self.currentFruitType, x, z, x1, z1, x2, z2, 1)
            local area = Utils.cutFruitArea(self.currentFruitType, x, z, x1, z1, x2, z2)
            if 0 < area then
              local spray = Utils.getDensity(g_currentMission.terrainDetailId, g_currentMission.sprayChannel, x, z, x1, z1, x2, z2)
              local multi = 1
              if 0 < spray then
                multi = 2
              end
              self.lastArea = self.lastArea + area * multi
              realArea = realArea + area / g_currentMission.maxFruitValue
            end
          end
          local pixelToQm = 0.25
          local qm = realArea * pixelToQm
          local ha = qm / 10000
          g_currentMission.missionStats.hectaresThreshedTotal = g_currentMission.missionStats.hectaresThreshedTotal + ha
          g_currentMission.missionStats.hectaresThreshedSession = g_currentMission.missionStats.hectaresThreshedSession + ha
          g_currentMission.missionStats.threshingDurationTotal = g_currentMission.missionStats.threshingDurationTotal + dt / 60000
          g_currentMission.missionStats.threshingDurationSession = g_currentMission.missionStats.threshingDurationSession + dt / 60000
        end
      else
        self.printRainWarning = true
      end
    end
  else
    self.speedViolationTimer = self.speedViolationMaxTime
  end
  Utils.setEmittingState(self.threshingParticleSystems, self.reelStarted and self.lastArea > 0)
  if self.reelStarted then
    rotate(self.rollNode, -dt * self.reelSpeed * 3, 0, 0)
    if self.reelNode ~= nil then
      rotate(self.reelNode, -dt * self.reelSpeed, 0, 0)
      if self.sideArmMovable then
      end
      atx, aty, atz = getRotation(self.reelNode)
      for i = 1, self.spikesCount do
        local spike = getChildAt(self.spikesRootNode, i - 1)
        tx, ty, tz = getRotation(spike)
        setRotation(spike, -atx, aty, atz)
      end
    end
  end
end
function Cutter:draw()
  if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
    local str = "2"
    local keyStr = InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL2)
    if Cutter.getUseLowSpeedLimit(self) then
      str = "1"
      keyStr = InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL1)
    end
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), str, keyStr), 0.092, 0.048)
  end
  if self.printRainWarning then
    g_currentMission:addWarning(g_i18n:getText("Dont_do_threshing_during_rain_or_hail"), 0.018, 0.033)
  end
end
function Cutter:onDetach()
  if self.deactivateOnDetach then
    Cutter.onDeactivate(self)
  end
end
function Cutter:onLeave()
  if self.deactivateOnLeave then
    Cutter.onDeactivate(self)
  end
end
function Cutter:onDeactivate()
  self:onStopReel()
  Utils.setEmittingState(self.threshingParticleSystems, false)
  self.speedViolationTimer = self.speedViolationMaxTime
end
function Cutter:setReelSpeed(speed)
  self.reelSpeed = speed
end
function Cutter:onStartReel()
  self.reelStarted = true
end
function Cutter:onStopReel()
  self.reelStarted = false
  Utils.setEmittingState(self.threshingParticleSystems, false)
  self.speedViolationTimer = self.speedViolationMaxTime
end
function Cutter:isReelStarted()
  return self.reelStarted
end
function Cutter:resetFruitType()
  self.currentFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.lastArea = 0
end
function Cutter:setFruitType(fruitType)
  if self.currentFruitType ~= fruitType then
    self.currentFruitType = fruitType
    self.lastArea = 0
    Cutter.updateExtraObjects(self)
  end
end
function Cutter:getUseLowSpeedLimit()
  if self.forceLowSpeed or self.attacherVehicle ~= nil and self.preferedCombineSize > self.attacherVehicle.combineSize then
    return true
  end
  return false
end
function Cutter:updateExtraObjects()
  if self.currentExtraObject ~= nil then
    setVisibility(self.currentExtraObject, false)
    self.currentExtraObject = nil
  end
  if self.currentFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    local name = FruitUtil.fruitIndexToDesc[self.currentFruitType].name
    local extraObject = self.fruitExtraObjects[name]
    if extraObject ~= nil then
      setVisibility(extraObject, true)
      self.currentExtraObject = extraObject
    end
  end
end

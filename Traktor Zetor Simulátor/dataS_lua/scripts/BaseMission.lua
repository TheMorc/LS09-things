BaseMission = {}
local BaseMission_mt = Class(BaseMission)
BaseMission.STATE_INTRO = 0
BaseMission.STATE_READY = 1
BaseMission.STATE_RUNNING = 2
BaseMission.STATE_FINISHED = 3
BaseMission.STATE_FAILED = 5
BaseMission.VEHICLE_LOAD_OK = 1
BaseMission.VEHICLE_LOAD_ERROR = 2
BaseMission.VEHICLE_LOAD_DELAYED = 3
function BaseMission:new(customMt)
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, BaseMission_mt)
  end
  instance.firstTimeRun = false
  instance.waterY = -100
  instance.updateables = {}
  instance.miscTriggers = {}
  instance.tipTriggers = {}
  instance.siloTriggers = {}
  instance.gasStations = {}
  instance.barriers = {}
  instance.visualPlayerTriggers = {}
  instance.hotspotTriggers = {}
  instance.infospotTriggers = {}
  instance.currentTipTrigger = nil
  instance.trailerTipTriggers = {}
  instance.currentVehicle = nil
  instance.environment = nil
  instance.tipTriggerRangeThreshold = 1
  instance.isTipTriggerInRange = false
  instance.trailerIsTipping = false
  instance.state = BaseMission.STATE_INTRO
  instance.minTime = 0
  instance.endDelayTime = 5000
  instance.endTimeStamp = 0
  instance.bronzeTime = 0
  instance.silverTime = 0
  instance.goldTime = 0
  instance.record = 0
  instance.medalOverlay = nil
  instance.sunk = false
  instance.isFreePlayMission = false
  instance.cutterRangeThreshold = 1.5
  instance.isRunning = false
  instance.allowSteerableMoving = true
  instance.fixedCamera = false
  instance.sounds = {}
  instance.controlledVehicle = nil
  instance.controlPlayer = true
  instance.storeIsActive = false
  instance.vehicles = {}
  instance.steerables = {}
  instance.objectToTrailer = {}
  instance.attachables = {}
  instance.cutters = {}
  instance.trafficVehicles = {}
  instance.trafficVehiclesToSpawn = {}
  instance.vehiclesToDelete = {}
  instance.nodeToVehicle = {}
  instance.vehiclesToSave = {}
  instance.loadSpawnPlaces = {}
  instance.storeSpawnPlaces = {}
  instance.usedLoadPlaces = {}
  local trafficDensity = Utils.getNoNil(getXMLFloat(g_savegameXML, "savegames.settings.traffic#density"), 1)
  instance.maxNumTrafficVehicles = trafficDensity * (12 + Utils.getProfileClassId() * 4)
  instance.timeAtLastTrafficVehicleSpawn = 0
  instance.tafficVehicleSpawnInterval = Utils.getNoNil(getXMLFloat(g_savegameXML, "savegames.settings.traffic#spawnInterval"), 1000)
  instance.itemsToSave = {}
  instance.missionMaps = {}
  instance.mountThreshold = 6
  instance.preSimulateTime = 4000
  instance.disableCombineAI = true
  instance.disableTractorAI = true
  instance.time = 0
  instance.missionTime = 0
  instance.extraPrintTexts = {}
  instance.warnings = {}
  instance.warningsNumLines = {}
  instance.warningsOffsetsX = {}
  instance.warningsOffsetsY = {}
  instance.helpButtonTexts = {}
  instance.renderTime = false
  instance.missionCompletedOverlayId = nil
  instance.missionFailedOverlayId = nil
  instance.hudBaseWidth = 0.16
  instance.hudBaseHeight = 0.081
  instance.hudBasePosX = 0.8325
  instance.hudBasePosY = 1 - instance.hudBaseHeight - 0.013
  instance.hudBaseWeatherPosX = instance.hudBasePosX + 0.925 - 0.8325
  instance.hudBaseWeatherPosY = instance.hudBasePosY + 0.004
  instance.hudBaseWeatherWidth = 0.05499999999999994
  instance.hudBaseWeatherHeight = 0.07200000000000001
  instance.hudHelpBaseWidth = 0.46799999999999997
  instance.hudHelpBaseHeight = 0.1625
  instance.hudHelpBasePosX = 0.012
  instance.hudHelpBasePosY = 1 - instance.hudHelpBaseHeight - 0.013
  instance.hudMissionBasePosX = instance.hudHelpBasePosX + instance.hudHelpBaseWidth + 0.01
  instance.hudMissionBasePosY = instance.hudBasePosY
  instance.hudMissionBaseWidth = instance.hudBasePosX - (instance.hudHelpBasePosX + instance.hudHelpBaseWidth) - 0.02
  instance.hudMissionBaseHeight = instance.hudBaseHeight
  instance.hudWarningBasePosX = 0.25
  instance.hudWarningBasePosY = 0.46099999999999997
  instance.hudWarningBaseWidth = 0.506
  instance.hudWarningBaseHeight = 0.1
  instance.completeDisplayX = 0.313
  instance.completeDisplayY = 0.37250000000000005
  instance.completeDisplayWidth = 0.374
  instance.completeDisplayHeight = 0.382
  instance.hudBaseOverlay = Overlay:new("hudBaseOverlay", "dataS/missions/hud_env_base.png", instance.hudBasePosX, instance.hudBasePosY, instance.hudBaseWidth, instance.hudBaseHeight)
  instance.hudBaseSunOverlay = Overlay:new("hudBaseSunOverlay", "dataS/missions/hud_sun.png", instance.hudBaseWeatherPosX, instance.hudBaseWeatherPosY, instance.hudBaseWeatherWidth, instance.hudBaseWeatherHeight)
  instance.hudBaseRainOverlay = Overlay:new("hudBaseRainOverlay", "dataS/missions/hud_rain.png", instance.hudBaseWeatherPosX, instance.hudBaseWeatherPosY, instance.hudBaseWeatherWidth, instance.hudBaseWeatherHeight)
  instance.hudBaseHailOverlay = Overlay:new("hudBaseHailOverlay", "dataS/missions/hud_hail.png", instance.hudBaseWeatherPosX, instance.hudBaseWeatherPosY, instance.hudBaseWeatherWidth, instance.hudBaseWeatherHeight)
  instance.hudMissionBaseOverlay = Overlay:new("hudMissionBaseOverlay", "dataS/missions/hud_mission_base.png", instance.hudMissionBasePosX, instance.hudMissionBasePosY, instance.hudMissionBaseWidth, instance.hudMissionBaseHeight)
  instance.hudHelpBaseOverlay = Overlay:new("hudHelpBaseOverlay", "dataS/missions/hud_help_base.png", instance.hudHelpBasePosX, instance.hudHelpBasePosY, instance.hudHelpBaseWidth, instance.hudHelpBaseHeight)
  instance.hudWarningBaseOverlay = Overlay:new("hudHelpBaseOverlay", "dataS/missions/hud_warning_base.png", instance.hudWarningBasePosX, instance.hudWarningBasePosY, instance.hudWarningBaseWidth, instance.hudWarningBaseHeight)
  instance.hudAttachmentOverlay = Overlay:new("hudAttachmentOverlay", "dataS/missions/hud_attachment.png", 0.935, 0.18, 0.06, 0.07999999999999999)
  instance.hudTipperOverlay = Overlay:new("hudTipperOverlay", "dataS/missions/hud_tipper.png", 0.935, 0.18, 0.06, 0.07999999999999999)
  instance.hudFuelOverlay = Overlay:new("hudFuelOverlay", "dataS/missions/hud_fuel.png", 0.935, 0.18, 0.06, 0.07999999999999999)
  instance.fruitSymbolSize = 0.08
  instance.fruitSymbolX = 0.923
  instance.fruitSymbolY = 0.28
  instance.fruitOverlays = {}
  for fruitName, fruitType in pairs(FruitUtil.fruitTypes) do
    if fruitType.hudFruitOverlayFilename ~= nil then
      instance.fruitOverlays[fruitType.index] = Overlay:new("hudFruitOverlay", fruitType.hudFruitOverlayFilename, instance.fruitSymbolX, instance.fruitSymbolY, instance.fruitSymbolSize, instance.fruitSymbolSize * 1.3333333333333333)
    end
  end
  instance.showWeatherForecast = false
  instance.showHudMissionBase = false
  instance.showVehicleInfo = true
  instance.showHudEnv = true
  instance.showHelpText = true
  instance.money = 0
  instance.reputation = 0
  instance.missionStats = MissionStats:new()
  instance.fruits = {}
  instance.playerStartIsAbsolute = false
  return instance
end
function BaseMission:delete()
  setCamera(g_defaultCamera)
  Player.destroy()
  RoadUtil.delete()
  for k, v in pairs(self.vehicles) do
    v:delete()
  end
  for k, v in pairs(self.vehiclesToDelete) do
    k:delete()
  end
  for k, v in pairs(self.itemsToSave) do
    delete(v.node)
  end
  for k, v in pairs(self.missionMaps) do
    delete(v)
  end
  for k, v in pairs(g_modEventListeners) do
    v:deleteMap()
  end
  if self.environment ~= nil then
    self.environment:destroy()
    self.environment = nil
  end
  if self.missionCompletedOverlayId ~= nil then
    delete(self.missionCompletedOverlayId)
  end
  if self.missionFailedOverlayId ~= nil then
    delete(self.missionFailedOverlayId)
  end
  self.hudBaseOverlay:delete()
  self.hudBaseSunOverlay:delete()
  self.hudBaseRainOverlay:delete()
  self.hudBaseHailOverlay:delete()
  self.hudMissionBaseOverlay:delete()
  self.hudWarningBaseOverlay:delete()
  if self.medalOverlay ~= nil then
    self.medalOverlay:delete()
  end
  for k, v in pairs(self.updateables) do
    v:delete()
  end
  for k, v in pairs(self.miscTriggers) do
    v:delete()
  end
  for k, v in pairs(self.siloTriggers) do
    v:delete(dt)
  end
  self.missionStats:delete()
  delete(self.rootNode)
  g_currentMission = nil
end
function BaseMission:load()
  Player.create(self.playerStartX, self.playerStartY, self.playerStartZ, self.playerRotX, self.playerRotY, self.playerStartIsAbsolute)
  self.controlPlayer = true
  self.controlledVehicle = nil
  simulatePhysics(true)
  if self.preSimulateTime > 0 then
    extraUpdatePhysics(self.preSimulateTime)
  end
end
function BaseMission:loadMap(name)
  self.rootNode = loadI3DFile("data/maps/" .. name .. ".i3d")
  link(getRootNode(), self.rootNode)
  self.terrainRootNode = getChild(self.rootNode, "terrain")
  self.terrainDetailId = getChild(self.terrainRootNode, "terrainDetail")
  local diffGrowthScale = (self.missionStats.difficulty - 1) * 0.1 + 0.8
  local timeGrowthScale = 1 + (g_settingsTimeScale - 1) * -0.19999999999999996 / 59
  local growhtStateFactor = diffGrowthScale * timeGrowthScale
  for fruitName, fruitType in pairs(FruitUtil.fruitTypes) do
    local entry = {}
    entry.id = getChild(self.terrainRootNode, fruitName)
    entry.cutShortId = getChild(self.terrainRootNode, fruitName .. "_cut_short")
    entry.cutLongId = getChild(self.terrainRootNode, fruitName .. "_cut_long")
    entry.windrowId = getChild(self.terrainRootNode, fruitName .. "_windrow")
    local dir = g_missionLoaderDesc.growthStateDirectory
    if dir ~= nil and entry.id ~= 0 then
      loadGrowthStateFromFile(entry.id, dir .. "/" .. getName(entry.id) .. "_growthState.xml")
    end
    if entry.id ~= 0 then
      local growthStateTime = getGrowthStateTime(entry.id)
      setGrowthStateTime(entry.id, growthStateTime * growhtStateFactor)
    end
    if entry.id ~= 0 or entry.cutShortId ~= 0 or entry.cutLongId ~= 0 or entry.windrowId ~= 0 then
      self.fruits[fruitType.index] = entry
    end
  end
  self.grassId = getChild(self.terrainRootNode, "shortGrass")
  if self.grassId ~= 0 then
    local viewDistance = getFoliageViewDistance(self.grassId)
    if 0 < getNumOfChildren(self.grassId) then
      setShaderParameter(getChildAt(self.grassId, 0), "fadeStartEnd", viewDistance - 7, viewDistance - 2, 0, 0, true)
    end
  end
  self.cultivatorChannel = 0
  self.ploughChannel = 1
  self.sowingChannel = 2
  self.sprayChannel = 3
  self.numCutLongChannels = 2
  self.maxCutLongValue = 3
  self.numWindrowChannels = 2
  self.maxWindrowValue = 3
  self.maxFruitValue = 4
  self.windrowCutLongRatio = 4
  if self.environment.water ~= nil then
    local x, y, z = getWorldTranslation(self.environment.water)
    self.waterY = y
  end
  self.missionStats:loadMap(name)
  RoadUtil.delete()
  RoadUtil.init("data/maps/" .. name .. "/paths/trafficPaths.i3d")
  for k, v in pairs(g_modEventListeners) do
    v:loadMap(name)
  end
end
function BaseMission:loadMissionMap(filename)
  local node = loadI3DFile("data/maps/missions/" .. filename)
  if node ~= 0 then
    table.insert(self.missionMaps, node)
    link(getRootNode(), node)
  else
    print("Error: failed to load mission map " .. filename)
  end
  return node
end
function BaseMission:loadVehicle(filename, x, yOffset, z, yRot, save)
  local xmlFile = loadXMLFile("TempConfig", filename)
  local typeName = getXMLString(xmlFile, "vehicle#type")
  delete(xmlFile)
  local ret
  if typeName == nil then
    print("Error loadVehicle: invalid vehicle config file '" .. filename .. "', no type specified")
  else
    local typeDef = VehicleTypeUtil.vehicleTypes[typeName]
    local modsDirLen = g_modsDirectory:len()
    local baseDirectory = ""
    if filename:sub(1, modsDirLen + 1) == g_modsDirectory .. "/" then
      local modName = filename:sub(modsDirLen + 2)
      local f, l = modName:find("/")
      if f ~= nil and l ~= nil and 1 < f then
        modName = modName:sub(1, f - 1)
        if typeDef == nil then
          typeName = modName .. "." .. typeName
          typeDef = VehicleTypeUtil.vehicleTypes[typeName]
        end
        baseDirectory = g_modsDirectory .. "/" .. modName .. "/"
      end
    end
    if typeDef == nil then
      print("Error loadVehicle: unknown type '" .. typeName .. "' in '" .. filename .. "'")
    else
      local callString = "g_asd_tempVehicleClass = " .. typeDef.className
      loadstring(callString)()
      if g_asd_tempVehicleClass ~= nil then
        local vehicle = g_asd_tempVehicleClass:new(filename, baseDirectory, x, yOffset, z, yRot, typeDef.specializations)
        if vehicle ~= nil then
          if vehicle.enterReferenceNode ~= nil and vehicle.exitPoint ~= nil then
            table.insert(self.steerables, vehicle)
          end
          if vehicle.attacherJoint ~= nil then
            table.insert(self.attachables, vehicle)
          end
          if vehicle.fillRootNode ~= nil then
            self.objectToTrailer[vehicle.fillRootNode] = vehicle
          end
          for k, v in pairs(vehicle.components) do
            self.nodeToVehicle[v.node] = vehicle
          end
          if save == nil or save == true then
            table.insert(self.vehiclesToSave, vehicle)
          end
          table.insert(self.vehicles, vehicle)
        end
        ret = vehicle
      end
      g_asd_tempVehicleClass = nil
    end
  end
  return ret
end
function BaseMission:removeVehicle(vehicle)
  if vehicle == self.currentVehicle then
    self:onLeaveVehicle()
  end
  if vehicle.enterReferenceNode ~= nil and vehicle.exitPoint ~= nil then
    for i = 1, table.getn(self.steerables) do
      if self.steerables[i] == vehicle then
        table.remove(self.steerables, i)
        break
      end
    end
  end
  if vehicle.attacherJoint ~= nil then
    for i = 1, table.getn(self.attachables) do
      if self.attachables[i] == vehicle then
        table.remove(self.attachables, i)
        break
      end
    end
  end
  if vehicle.fillRootNode ~= nil then
    self.objectToTrailer[vehicle.fillRootNode] = nil
  end
  for i = 1, table.getn(self.trafficVehicles) do
    if self.trafficVehicles[i] == vehicle then
      table.remove(self.trafficVehicles, i)
      break
    end
  end
  for i = 1, table.getn(self.vehiclesToSave) do
    if self.vehiclesToSave[i] == vehicle then
      table.remove(self.vehiclesToSave, i)
      break
    end
  end
  for i = 1, table.getn(self.vehicles) do
    if self.vehicles[i] == vehicle then
      table.remove(self.vehicles, i)
      break
    end
  end
  for k, v in pairs(vehicle.components) do
    self.nodeToVehicle[v.node] = nil
  end
  self.vehiclesToDelete[vehicle] = vehicle
end
function BaseMission:addItemToSave(i3dFilename, item, childIndex)
  if childIndex == nil then
    childIndex = 0
  end
  table.insert(self.itemsToSave, {
    node = item,
    i3dFilename = i3dFilename,
    childIndex = childIndex
  })
end
function BaseMission:removeItemToSave(item)
  for i = 1, table.getn(self.itemsToSave) do
    if self.itemsToSave[i].node == item then
      table.remove(self.itemsToSave, i)
      break
    end
  end
end
function BaseMission:pauseGame()
  self.isRunning = false
  simulatePhysics(false)
end
function BaseMission:unpauseGame()
  self.isRunning = true
  simulatePhysics(true)
end
function BaseMission:toggleVehicle(delta)
  if not (not self.fixedCamera and self.allowSteerableMoving) or self.currentVehicle ~= nil and self.currentVehicle.doRefuel then
    return
  end
  local numVehicles = table.getn(self.steerables)
  if 0 < numVehicles then
    local index = 1
    local oldIndex = 1
    if not self.controlPlayer then
      for i = 1, numVehicles do
        if self.currentVehicle == self.steerables[i] then
          oldIndex = i
          index = i + delta
          if numVehicles < index then
            index = 1
          end
          if index < 1 then
            index = numVehicles
          end
          break
        end
      end
    end
    local found = false
    repeat
      if not self.steerables[index].isBroken then
        found = true
      else
        index = index + delta
        if numVehicles < index then
          index = 1
        end
        if index < 1 then
          index = numVehicles
        end
      end
    until found or index == oldIndex
    if found then
      if not self.controlPlayer then
        self:onLeaveVehicle()
      end
      self:onEnterVehicle(self.steerables[index])
    end
  end
end
function BaseMission:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isRunning then
    self.missionStats:mouseEvent(posX, posY, isDown, isUp, button)
    if self.controlPlayer then
      Player.mouseEvent(posX, posY, isDown, isUp, button)
    else
      self.controlledVehicle:mouseEvent(posX, posY, isDown, isUp, button)
    end
  end
  for k, v in pairs(g_modEventListeners) do
    v:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function BaseMission:keyEvent(unicode, sym, modifier, isDown)
  if self.isRunning then
    self.missionStats:keyEvent(unicode, sym, modifier, isDown)
    if sym == Input.KEY_tab and isDown then
      local delta = 1
      if bitAND(modifier, 1) == 1 then
        delta = -1
      end
      self:toggleVehicle(delta)
    end
    if not self.controlPlayer then
      self.controlledVehicle:keyEvent(unicode, sym, modifier, isDown)
    elseif sym == Input.KEY_shift then
      if isDown then
        Player.runningFactor = 2
      else
        Player.runningFactor = 1
      end
    end
  end
  for k, v in pairs(g_modEventListeners) do
    v:keyEvent(unicode, sym, modifier, isDown)
  end
end
function BaseMission:update(dt)
  if not self.isRunning then
    return
  end
  for k, v in pairs(self.vehiclesToDelete) do
    k:delete()
  end
  self.vehiclesToDelete = {}
  self.time = self.time + dt
  RoadUtil.update(dt)
  self:manageTrafficVehicles(dt)
  self.missionStats:update(dt)
  if InputBinding.hasEvent(InputBinding.ENTER) then
    if self.controlPlayer then
      if self.vehicleInMountRange ~= nil then
        self:onEnterVehicle(self.vehicleInMountRange)
      end
    else
      self:onLeaveVehicle()
    end
  end
  if InputBinding.hasEvent(InputBinding.TOGGLE_HELP_TEXT) then
    self.showHelpText = not self.showHelpText
  end
  for k, v in pairs(self.vehicles) do
    v:update(dt, self.controlledVehicle == v and not self.controlPlayer)
  end
  if self.controlPlayer then
    Player.update(dt)
  end
  for k, v in pairs(self.barriers) do
    v:update(dt)
  end
  self.vehicleInMountRange = self:getSteerableInRange()
  self.trailerInTipRange, self.currentTipTrigger = self:getTrailerInTipRange()
  self.cutterInMountRange = self:getCutterInRange()
  self.attachableInMountRange, self.attachableInMountRangeIndex, self.attachableInMountRangeVehicle = self:getAttachableInRange()
  if self.environment ~= nil then
    self.environment:update(dt)
  end
  for k, v in pairs(self.siloTriggers) do
    v:update(dt)
  end
  for k, v in pairs(self.tipTriggers) do
    v:update(dt)
  end
  for k, v in pairs(self.visualPlayerTriggers) do
    v:update(dt)
  end
  for k, v in pairs(self.hotspotTriggers) do
    v:update(dt)
  end
  for k, v in pairs(self.infospotTriggers) do
    v:update(dt)
  end
  for k, v in pairs(self.updateables) do
    v:update(dt)
  end
  for k, v in pairs(g_modEventListeners) do
    v:update(dt)
  end
  self.firstTimeRun = true
end
function BaseMission:draw()
  if self.isRunning then
    if self.showHudEnv then
      self.hudBaseOverlay:render()
    end
    if self.showHudMissionBase then
      self.hudMissionBaseOverlay:render()
    end
    self.missionStats:draw()
    if self.currentVehicle ~= nil and self.showVehicleInfo then
      self.currentVehicle:draw()
    end
    if self.currentVehicle ~= nil and (self.attachableInMountRange ~= nil and self.currentVehicle.attacherJoints[self.attachableInMountRangeIndex].jointIndex == 0 or self.cutterInMountRange ~= nil and self.currentVehicle.attachedCutter == nil) then
      self.hudAttachmentOverlay:render()
    end
    if self.currentVehicle ~= nil and self.trailerInTipRange ~= nil and self.currentTipTrigger ~= nil and (self.trailerInTipRange.currentFillType == FruitUtil.FRUITTYPE_UNKNOWN or self.currentTipTrigger.acceptedFruitTypes[self.trailerInTipRange.currentFillType]) then
      self.hudTipperOverlay:render()
    end
    if g_settingsHelpText and self.showHelpText then
      local renderTextsLeft = {}
      local renderTextsRight = {}
      local printText, printButton
      if self.currentVehicle ~= nil then
        if self.trailerInTipRange ~= nil then
          printText = g_i18n:getText("Dump")
          printButton = InputBinding.ATTACH
          if self.currentTipTrigger ~= nil and self.trailerInTipRange.currentFillType ~= FruitUtil.FRUITTYPE_UNKNOWN and not self.currentTipTrigger.acceptedFruitTypes[self.trailerInTipRange.currentFillType] then
            g_currentMission:addWarning(g_i18n:getText(FruitUtil.fruitIndexToDesc[self.trailerInTipRange.currentFillType].name) .. g_i18n:getText("notAcceptedHere"), 0.018, 0.033)
            printText = nil
            printButton = nil
          else
          end
        elseif self.attachableInMountRange ~= nil and self.currentVehicle.attacherJoints[self.attachableInMountRangeIndex].jointIndex == 0 or self.cutterInMountRange ~= nil and self.currentVehicle.attachedCutter == nil then
          printText = g_i18n:getText("Attach")
          printButton = InputBinding.ATTACH
        elseif self.currentVehicle.selectedImplement ~= 0 then
          local implement = self.currentVehicle.attachedImplements[self.currentVehicle.selectedImplement]
          local jointDesc = self.currentVehicle.attacherJoints[implement.jointDescIndex]
          if implement.object.allowsLowering and jointDesc.allowsLowering then
            if jointDesc.moveDown then
              printText = string.format(g_i18n:getText("lift_OBJECT"), implement.object.typeDesc)
            elseif implement.object.needsLowering then
              printText = string.format(g_i18n:getText("lower_OBJECT"), implement.object.typeDesc)
            end
          end
          printButton = InputBinding.LOWER_IMPLEMENT
        end
      elseif self.vehicleInMountRange ~= nil and self.controlPlayer then
        printText = g_i18n:getText("Enter")
        printButton = InputBinding.ENTER
      end
      if printText ~= nil and printButton ~= nil then
        local buttonName = InputBinding.getButtonName(printButton)
        local keyText = g_i18n:getText("Key") .. " " .. InputBinding.getButtonKeyName(printButton)
        if buttonName ~= nil then
          keyText = keyText .. " " .. g_i18n:getText("or") .. " " .. g_i18n:getText("Button") .. " " .. buttonName
        end
        keyText = keyText .. ":"
        table.insert(renderTextsLeft, keyText)
        table.insert(renderTextsRight, printText)
      end
      if self.environment ~= nil and self.environment.dayNightCycle and (self.environment.dayTime > 73800000 or self.environment.dayTime < 19800000) and self.currentVehicle ~= nil and not self.currentVehicle.lightsActive then
        self:addHelpButtonText(g_i18n:getText("Turn_on_lights"), InputBinding.TOGGLE_LIGHTS)
      end
      for i = 1, table.getn(self.helpButtonTexts) do
        local button = self.helpButtonTexts[i].button
        local buttonName = InputBinding.getButtonName(button)
        local keyText = g_i18n:getText("Key") .. " " .. InputBinding.getButtonKeyName(button)
        if buttonName ~= nil then
          keyText = keyText .. " " .. g_i18n:getText("or") .. " " .. g_i18n:getText("Button") .. " " .. buttonName
        end
        keyText = keyText .. ":"
        table.insert(renderTextsLeft, keyText)
        table.insert(renderTextsRight, self.helpButtonTexts[i].text)
      end
      self.helpButtonTexts = {}
      setTextColor(1, 1, 1, 1)
      setTextBold(false)
      for i = 1, table.getn(self.extraPrintTexts) do
        table.insert(renderTextsLeft, self.extraPrintTexts[i])
        table.insert(renderTextsRight, "")
      end
      self.extraPrintTexts = {}
      local num = math.min(6, table.getn(renderTextsLeft))
      local helpTextSize = 0.025
      if 1 <= num then
        self.hudHelpBaseOverlay.height = self.hudHelpBaseHeight
        self.hudHelpBaseOverlay.y = self.hudHelpBasePosY
        if 6 <= num then
          self.hudHelpBaseOverlay.height = self.hudHelpBaseOverlay.height + 2 * helpTextSize
          self.hudHelpBaseOverlay.y = self.hudHelpBaseOverlay.y - 2 * helpTextSize
        elseif 5 <= num then
          self.hudHelpBaseOverlay.height = self.hudHelpBaseOverlay.height + helpTextSize
          self.hudHelpBaseOverlay.y = self.hudHelpBaseOverlay.y - helpTextSize
        end
        self.hudHelpBaseOverlay:render()
      end
      for i = 1, num do
        local left = renderTextsLeft[i]
        local right = renderTextsRight[i]
        renderText(0.02, (4 - i) * 0.03 + (self.hudHelpBasePosY + 0.03), helpTextSize, left)
        renderText(0.24, (4 - i) * 0.03 + (self.hudHelpBasePosY + 0.03), helpTextSize, right)
      end
    end
    if 1 <= table.getn(self.warnings) then
      setTextColor(1, 0, 0, 1)
      self.hudWarningBaseOverlay:render()
      renderText(self.hudWarningBasePosX + self.warningsOffsetsX[1], self.hudWarningBasePosY + self.warningsOffsetsY[1], 0.035, self.warnings[1])
      setTextColor(1, 1, 1, 1)
    end
    self.warnings = {}
    self.warningsOffsetsX = {}
    self.warningsOffsetsY = {}
    if self.environment ~= nil then
      if self.renderTime then
        setTextColor(1, 1, 1, 1)
        self:drawTime(false, self.environment.dayTime / 3600000)
      end
      if self.showWeatherForecast and self.environment.timeUntilNextRain ~= nil then
        if self.environment.timeUntilNextRain < 720 then
          if self.environment.nextRainType == 1 then
            self.hudBaseHailOverlay:render()
          else
            self.hudBaseRainOverlay:render()
          end
        else
          self.hudBaseSunOverlay:render()
        end
      end
    end
    for k, v in pairs(g_modEventListeners) do
      v:draw()
    end
  end
end
function BaseMission:onEnterVehicle(vehicle)
  self.controlledVehicle = vehicle
  self.controlledVehicle:onEnter()
  self.controlPlayer = false
  Player.onLeave()
  g_currentMission.currentVehicle = self.controlledVehicle
end
function BaseMission:onLeaveVehicle()
  if not self.trailerIsTipping then
    if self.controlledVehicle ~= nil then
      self.controlledVehicle:onLeave()
    end
    self.controlPlayer = true
    local cx, cy, cz = getWorldTranslation(self.controlledVehicle.exitPoint)
    local dx, dy, dz = localDirectionToWorld(self.controlledVehicle.exitPoint, 0, 0, 1)
    cy = cy + 0.9
    Player.onEnter()
    Player.moveToAbsolute(cx, cy, cz)
    Player.rotY = Utils.getYRotationFromDirection(dx, dz) + math.pi
    g_currentMission.currentVehicle = nil
  end
end
function BaseMission:getTrailerInTipRange(vehicle, minDistance)
  if minDistance == nil then
    minDistance = self.tipTriggerRangeThreshold
  end
  local ret, retTrigger
  if vehicle == nil then
    vehicle = self.currentVehicle
  end
  if vehicle ~= nil then
    if vehicle.fillRootNode ~= nil and vehicle.tipReferencePoint ~= nil then
      local trailerX, trailerY, trailerZ = getWorldTranslation(vehicle.tipReferencePoint)
      local triggers = self.trailerTipTriggers[vehicle]
      if triggers ~= nil then
        for k, tipTrigger in pairs(triggers) do
          local triggerX, triggerY, triggerZ = getWorldTranslation(tipTrigger.triggerId)
          local distance = Utils.vector2Length(trailerX - triggerX, trailerZ - triggerZ)
          if minDistance > distance then
            ret = vehicle
            retTrigger = tipTrigger
            minDistance = distance
          end
        end
      end
    end
    for k, implement in pairs(vehicle.attachedImplements) do
      local tempRet, tempRetTrigger, newMinDistance = self:getTrailerInTipRange(implement.object, minDistance)
      if tempRet ~= nil and tempRetTrigger ~= nil then
        ret = tempRet
        retTrigger = tempRetTrigger
      end
      minDistance = newMinDistance
    end
  end
  return ret, retTrigger, minDistance
end
function BaseMission:getCutterInRange()
  if self.currentVehicle ~= nil and self.currentVehicle.cutterAttacherJoint ~= nil then
    local px, py, pz = getWorldTranslation(self.currentVehicle.cutterAttacherJoint.jointTransform)
    local nearestCutter
    local nearestDistance = 0.4
    for i = 1, table.getn(self.cutters) do
      local vx, vy, vz = getWorldTranslation(self.cutters[i].attacherJoint.node)
      local distance = Utils.vector2Length(px - vx, pz - vz)
      if nearestDistance > distance then
        nearestCutter = self.cutters[i]
        nearestDistance = distance
      end
    end
    return nearestCutter
  end
  return nil
end
function BaseMission:getSteerableInRange()
  local px, py, pz = getWorldTranslation(Player.rootNode)
  local nearestVehicle
  local nearestDistance = self.mountThreshold
  for i = 1, table.getn(self.steerables) do
    if not self.steerables[i].isBroken then
      local vx, vy, vz = getWorldTranslation(self.steerables[i].enterReferenceNode)
      local distance = Utils.vector2Length(px - vx, pz - vz)
      if nearestDistance > distance then
        nearestVehicle = self.steerables[i]
        nearestDistance = distance
      end
    end
  end
  return nearestVehicle
end
function BaseMission:getAttachableInRange(vehicle, nearestDistance)
  if vehicle == nil then
    vehicle = self.currentVehicle
  end
  if nearestDistance == nil then
    nearestDistance = 1.3
  end
  if vehicle ~= nil then
    local nearestAttachable
    local nearestIndex = 0
    local nearestVehicle
    for j = 1, table.getn(vehicle.attacherJoints) do
      local jointDesc = vehicle.attacherJoints[j]
      if jointDesc.jointIndex ~= 0 then
        local attached = vehicle.attachedImplements[vehicle:getAttachedIndexFromJointDescIndex(j)].object
        local a, index, v, d = self:getAttachableInRange(attached, nearestDistance)
        if a ~= nil then
          nearestDistance = d
          nearestVehicle = v
          nearestIndex = index
          nearestAttachable = a
        end
      else
        local px, py, pz = getWorldTranslation(jointDesc.jointTransform)
        for k, attachable in pairs(self.attachables) do
          local attacherJoint = attachable.attacherJoint
          if attachable.attacherVehicle == nil and attacherJoint.jointType == jointDesc.jointType then
            local vx, vy, vz = getWorldTranslation(attacherJoint.node)
            local distance = Utils.vector3Length(px - vx, py - vy, pz - vz)
            if nearestDistance > distance then
              nearestAttachable = attachable
              nearestDistance = distance
              nearestIndex = j
              nearestVehicle = vehicle
            end
          end
        end
      end
    end
    return nearestAttachable, nearestIndex, nearestVehicle, nearestDistance
  end
  return nil
end
function BaseMission:drawTime(big, timeHoursF)
  local timeHours = math.floor(timeHoursF)
  local timeMinutes = math.floor((timeHoursF - timeHours) * 60)
  setTextBold(true)
  local offsetX = 0
  local offsetY = 0
  local fontSize = 0.04
  if big then
    offsetX = 0.0125
    offsetY = -0.01
    fontSize = 0.06
  end
  renderText(self.hudBasePosX + 0.007 + offsetX, self.hudBasePosY + 0.02 + offsetY, fontSize, string.format("%02d:%02d", timeHours, timeMinutes))
end
function BaseMission:drawMissionCompleted()
  if self.missionFailedOverlayId == nil then
    self.missionCompletedOverlayId = createOverlay("mission_completed", "dataS/missions/mission_completed" .. g_languageSuffix .. ".png")
  end
  renderOverlay(self.missionCompletedOverlayId, self.completeDisplayX, self.completeDisplayY, self.completeDisplayWidth, self.completeDisplayHeight)
  if self.medalOverlay ~= nil then
    self.medalOverlay:render()
  end
  local timePosX = self.completeDisplayX + self.completeDisplayWidth * 0.275
  local timePosY = self.completeDisplayY + self.completeDisplayHeight * 0.25
  setTextBold(true)
  local time = self.record / 60000
  local timeHours = math.floor(time)
  local timeMinutes = math.floor((time - timeHours) * 60)
  renderText(timePosX, timePosY, 0.045, g_i18n:getText("Time") .. string.format(": %02d:%02d", timeHours, timeMinutes))
  setTextBold(false)
end
function BaseMission:drawMissionFailed()
  if self.missionFailedOverlayId == nil then
    self.missionFailedOverlayId = createOverlay("mission_failed", "dataS/missions/mission_failed" .. g_languageSuffix .. ".png")
  end
  BaseMission:drawCentered(self.missionFailedOverlayId, 0.5, 0.175)
end
function BaseMission:drawCentered(overlayId, width, height)
  renderOverlay(overlayId, 0.5 - width / 2, 0.5 - height / 2, width, height)
end
function BaseMission:onSunkVehicle()
  if not self.isFreePlayMission then
    self.sunk = true
  end
end
function BaseMission:finishMission(record)
  if g_finishedMissions[self.missionId] == nil then
    g_finishedMissions[self.missionId] = 1
  end
  if g_finishedMissionsRecord[self.missionId] == nil or record < g_finishedMissionsRecord[self.missionId] then
    g_finishedMissionsRecord[self.missionId] = record
  end
  local finishedStr = ""
  local recordStr = ""
  for k, v in pairs(g_finishedMissions) do
    finishedStr = finishedStr .. k .. " "
    recordStr = recordStr .. math.floor(g_finishedMissionsRecord[k]) .. " "
  end
  setXMLString(g_savegameXML, "savegames.missions#finished", finishedStr)
  setXMLString(g_savegameXML, "savegames.missions#record", recordStr)
  saveXMLFile(g_savegameXML)
  local medalPosX = self.completeDisplayX + self.completeDisplayWidth * 0.295
  local medalPosY = self.completeDisplayY + self.completeDisplayHeight * 0.38
  local medalHeight = 0.204
  self.record = record
  local recordFloor = math.floor(record)
  local timeMinutesF = record / 60000
  local timeMinutes = math.floor(timeMinutesF)
  local timeSeconds = math.floor((timeMinutesF - timeMinutes) * 60)
  local recordFloor = (timeSeconds + 60 * timeMinutes) * 1000
  local filename = "dataS/missions/empty_medal.png"
  if recordFloor <= self.bronzeTime then
    filename = "dataS/missions/bronze_medal.png"
  end
  if recordFloor <= self.silverTime then
    filename = "dataS/missions/silver_medal.png"
  end
  if recordFloor <= self.goldTime then
    filename = "dataS/missions/gold_medal.png"
  end
  self.medalOverlay = Overlay:new("emptyMedalOverlay", filename, medalPosX, medalPosY, medalHeight * 0.75, medalHeight)
end
function BaseMission:setMissionInfo(missionId, bronzeTime, silverTime, goldTime, missionType)
  self.missionId = missionId
  self.minTime = bronzeTime
  self.bronzeTime = bronzeTime
  self.silverTime = silverTime
  self.goldTime = goldTime
  self.missionType = missionType
end
function BaseMission:addHelpButtonText(text, button)
  table.insert(self.helpButtonTexts, {text = text, button = button})
end
function BaseMission:addExtraPrintText(text)
  table.insert(self.extraPrintTexts, text)
end
function BaseMission:addWarning(text, offsetX, offsetY)
  table.insert(self.warnings, text)
  table.insert(self.warningsOffsetsX, offsetX)
  table.insert(self.warningsOffsetsY, offsetY)
end
function BaseMission:getSiloAmount(fillType)
  return Utils.getNoNil(self.missionStats.farmSiloFruitAmount[fillType], 0)
end
function BaseMission:setSiloAmount(fillType, amount)
  self.missionStats.farmSiloFruitAmount[fillType] = amount
end
function BaseMission:manageTrafficVehicles(dt)
  local numToAdd = table.getn(self.trafficVehiclesToSpawn)
  local numTrafficVehicles = table.getn(self.trafficVehicles) + numToAdd
  if numTrafficVehicles < self.maxNumTrafficVehicles and self.timeAtLastTrafficVehicleSpawn + self.tafficVehicleSpawnInterval < self.time then
    self.timeAtLastTrafficVehicleSpawn = self.time
    local filename = TrafficVehicleUtil.getRandomTrafficVehicle()
    local xmlFile = loadXMLFile("TempConfig", filename)
    local spawnTestRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.spawnTest#radius"), 15)
    delete(xmlFile)
    local spawnTestInterval = 1000
    local sequence, loopIndex = RoadUtil.getRandomRoadSequence()
    if sequence ~= nil then
      table.insert(self.trafficVehiclesToSpawn, {
        filename = filename,
        spawnTestNextTime = 0,
        spawnTestRadius = spawnTestRadius,
        spawnTestInterval = spawnTestInterval,
        sequence = sequence,
        loopIndex = loopIndex
      })
    else
      self.maxNumTrafficVehicles = 0
    end
  end
  if 0 < numToAdd then
    for i = numToAdd, 1, -1 do
      local spawn = self.trafficVehiclesToSpawn[i]
      if self.time > spawn.spawnTestNextTime then
        self.spawnCollisionsFound = false
        local road = spawn.sequence[1].road2
        local timePos = spawn.sequence[1].timePos2
        local direction = spawn.sequence[1].directionOnRoad2
        local x, y, z = PathVehicle.getTrackPosition(road, timePos, direction)
        local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 300, z)
        if PathVehicle.isVehicleAllowedToChange(x, terrainHeight, z, 50, 100) then
          overlapSphere(x, terrainHeight, z, spawn.spawnTestRadius, "spawnCollisionTestCallback", self)
        else
          self.spawnCollisionsFound = true
        end
        if self.spawnCollisionsFound then
          spawn.spawnTestNextTime = self.time + spawn.spawnTestInterval
        else
          table.remove(self.trafficVehiclesToSpawn, i)
          local vehicle = self:loadVehicle(spawn.filename, 0, 0.5, 0, 0, false)
          table.insert(self.trafficVehicles, vehicle)
          vehicle:followSequence(spawn.sequence, spawn.loopIndex, true)
          break
        end
      end
    end
  end
end
function BaseMission:spawnCollisionTestCallback(transformId)
  if self.nodeToVehicle[transformId] ~= nil then
    self.spawnCollisionsFound = true
  end
end
function BaseMission:onCreateLoadSpawnPlace(id)
  local place = PlacementUtil.createPlace(id)
  table.insert(g_currentMission.loadSpawnPlaces, place)
end
function BaseMission:onCreateStoreSpawnPlace(id)
  local place = PlacementUtil.createPlace(id)
  table.insert(g_currentMission.storeSpawnPlaces, place)
end
function BaseMission:increaseReputation(value)
  local wasNot100 = self.reputation < 100
  self.reputation = self.reputation + value
  if self.inGameIcon ~= nil and wasNot100 then
    if self.inGameIcon.fileName ~= "dataS/missions/repmedal.png" then
      self.inGameIcon:setIcon("dataS/missions/repmedal.png")
    end
    self.inGameIcon:setText("+" .. value .. "%")
    self.inGameIcon:showIcon(2000)
  end
  if self.reputation >= 100 then
    self.reputation = 100
    if self.inGameMessage ~= nil and self.messages ~= nil then
      if wasNot100 then
        self.inGameMessage:showMessage(self.messages[100].title, self.messages[100].content, self.messages[100].duration, true)
      else
        self.inGameMessage:showMessage(self.messages[101].title, self.messages[101].content, self.messages[101].duration, true)
      end
      return
    end
  end
end

Mission00 = {}
local Mission00_mt = Class(Mission00, BaseMission)
function Mission00:new()
  local instance = Mission00:superClass():new(Mission00_mt)
  instance.playerStartX = 161.5
  instance.playerStartY = 0.1
  instance.playerStartZ = 111
  instance.playerRotX = 0
  instance.playerRotY = Utils.degToRad(180)
  instance.renderTime = true
  instance.isFreePlayMission = true
  instance.vehiclesToSpawn = {}
  instance.foundBottleCount = 0
  instance.deliveredBottles = 0
  instance.foundBottles = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  instance.foundInfoTriggers = "00000000000000000000"
  instance.missionMapBottleTriggers = {}
  instance.missionMapGlassContainerTriggers = {}
  instance.disableCombineAI = false
  instance.disableTractorAI = false
  return instance
end
function Mission00:delete()
  self.inGameMessage:delete()
  self.inGameIcon:delete()
  delete(self.bottlePickupSound)
  delete(self.bottleDropSound)
  for i = 1, table.getn(self.missionMapBottleTriggers) do
    removeTrigger(self.missionMapBottleTriggers[i])
  end
  for i = 1, table.getn(self.missionMapGlassContainerTriggers) do
    removeTrigger(self.missionMapGlassContainerTriggers[i])
  end
  Mission00:superClass().delete(self)
end
function Mission00:load()
  g_mission00StartPoint = nil
  self.environment = Environment:new("data/sky/sky_day_night.i3d", true, 8, true, true)
  self.environment.timeScale = g_settingsTimeScale
  self.showWeatherForecast = true
  self:loadMap("map01")
  self.missionMapBottles = self:superClass().loadMissionMap(self, "collectableBottles.i3d")
  self.missionMapGlassContainers = self:superClass().loadMissionMap(self, "glassContainers.i3d")
  local bottleTriggerParentId = getChild(self.missionMapBottles, "CollectableBottles")
  if bottleTriggerParentId ~= 0 then
    local numChildren = getNumOfChildren(bottleTriggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(bottleTriggerParentId, i)
      id = getChildAt(id, 0)
      addTrigger(id, "bottleTriggerCallback", self)
      self.missionMapBottleTriggers[i + 1] = id
    end
  end
  local glassContainerTriggerParentId = getChild(self.missionMapGlassContainers, "GlassContainers")
  if glassContainerTriggerParentId ~= 0 then
    local numChildren = getNumOfChildren(glassContainerTriggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(glassContainerTriggerParentId, i)
      id = getChildAt(id, 0)
      addTrigger(id, "glassContainerTriggerCallback", self)
      local x, y, z = getWorldTranslation(id)
      self.missionStats:createMapHotspot(tostring(id), "dataS/missions/hud_pda_spot_gc.png", x + 1024, z + 1024, self.missionStats.pdaMapArrowSize, self.missionStats.pdaMapArrowSize * 1.3333333333333333, false, false, 0)
      self.missionMapGlassContainerTriggers[i + 1] = id
    end
  end
  self.bottlePickupSound = createSample("bottlePickupSound")
  loadSample(self.bottlePickupSound, "data/maps/sounds/bottlePickupSound.wav", false)
  self.bottleDropSound = createSample("bottleDropSound")
  loadSample(self.bottleDropSound, "data/maps/sounds/bottleDropSound.wav", false)
  self.missionMapPalletTrigger = self:superClass().loadMissionMap(self, "mission_stacking/palletMarker.i3d")
  self.inGameMessage = InGameMessage:new()
  self.inGameIcon = InGameIcon:new()
  self.missionMapInfo = self:superClass().loadMissionMap(self, "careerInfoTriggers.i3d")
  local missionMapInfoTriggers = {}
  local infoTriggerParentId = getChild(self.missionMapInfo, "infoTriggers")
  if infoTriggerParentId ~= 0 then
    local numChildren = getNumOfChildren(infoTriggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(infoTriggerParentId, i)
      id = getChildAt(id, 0)
      missionMapInfoTriggers[i + 1] = id
    end
  end
  self.messages = {}
  local xmlFile = loadXMLFile("messages.xml", "dataS/missions/messages_career" .. g_languageSuffix .. ".xml")
  local eom = false
  local i = 0
  repeat
    local message = {}
    local baseXMLName = string.format("messages.message(%d)", i)
    message.id = getXMLInt(xmlFile, baseXMLName .. "#id")
    if message.id ~= nil then
      message.title = getXMLString(xmlFile, baseXMLName .. ".title")
      message.content = getXMLString(xmlFile, baseXMLName .. ".content")
      message.duration = getXMLInt(xmlFile, baseXMLName .. ".duration")
      self.messages[message.id] = message
    else
      eom = true
    end
    i = i + 1
  until eom
  delete(xmlFile)
  self:superClass().loadMissionMap(self, "saucer.i3d")
  self:loadVehicles(g_missionLoaderDesc.vehiclesXML, g_missionLoaderDesc.resetVehicles)
  self.environment.dayTime = g_missionLoaderDesc.stats.dayTime * 1000 * 60
  if g_missionLoaderDesc.stats.nextRainValid then
    self.environment.timeUntilNextRain = g_missionLoaderDesc.stats.timeUntilNextRain
    self.environment.timeUntilRainAfterNext = g_missionLoaderDesc.stats.timeUntilRainAfterNext
    self.environment.rainTime = g_missionLoaderDesc.stats.rainTime
    self.environment.nextRainDuration = g_missionLoaderDesc.stats.nextRainDuration
    self.environment.nextRainType = g_missionLoaderDesc.stats.nextRainType
    self.environment.rainTypeAfterNext = g_missionLoaderDesc.stats.rainTypeAfterNext
  end
  self.environment.currentDay = g_missionLoaderDesc.stats.currentDay
  self.foundBottleCount = g_missionLoaderDesc.stats.foundBottleCount
  self.deliveredBottles = g_missionLoaderDesc.stats.deliveredBottles
  self.foundBottles = g_missionLoaderDesc.stats.foundBottles
  self.sessionDeliveredBottles = 0
  for i = 1, string.len(self.foundBottles) do
    if string.sub(self.foundBottles, i, i) == "1" then
      local triggerId = self.missionMapBottleTriggers[i]
      removeTrigger(triggerId)
      local parentId = getParent(triggerId)
      delete(triggerId)
      setVisibility(parentId, false)
    end
  end
  self.reputation = g_missionLoaderDesc.stats.reputation
  self.foundInfoTriggers = g_missionLoaderDesc.stats.foundInfoTriggers
  for i = 1, string.len(self.foundInfoTriggers) do
    if string.sub(self.foundInfoTriggers, i, i) == "1" then
      local triggerId = missionMapInfoTriggers[i]
      removeTrigger(triggerId)
      local parentId = getParent(triggerId)
      setVisibility(parentId, false)
    end
  end
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    FruitUtil.fruitIndexToDesc[i].pricePerLiter = g_missionLoaderDesc.stats.fruitPrices[i]
    FruitUtil.fruitIndexToDesc[i].yesterdaysPrice = g_missionLoaderDesc.stats.yesterdaysFruitPrices[i]
  end
  if g_mission00StartPoint ~= nil then
    local x, y, z = getTranslation(g_mission00StartPoint)
    local dirX, dirY, dirZ = localDirectionToWorld(g_mission00StartPoint, 0, 0, -1)
    self.playerStartX = x
    self.playerStartY = y
    self.playerStartZ = z
    self.playerRotX = 0
    self.playerRotY = Utils.getYRotationFromDirection(dirX, dirZ)
    self.playerStartIsAbsolute = true
  end
  Mission00:superClass().load(self)
end
function Mission00:mouseEvent(posX, posY, isDown, isUp, button)
  Mission00:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
  self.inGameMessage:mouseEvent(posX, posY, isDown, isUp, button)
  self.inGameIcon:mouseEvent(posX, posY, isDown, isUp, button)
end
function Mission00:keyEvent(unicode, sym, modifier, isDown)
  Mission00:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function Mission00:update(dt)
  if self.firstTimeRun then
    local numToSpawn = table.getn(self.vehiclesToSpawn)
    if 0 < numToSpawn then
      local xmlFile = loadXMLFile("VehiclesXML", g_missionLoaderDesc.vehiclesXML)
      for i = 1, numToSpawn do
        local key = self.vehiclesToSpawn[i].xmlKey
        local filename = getXMLString(xmlFile, key .. "#filename")
        if filename ~= nil then
          local vehicle = self:loadVehicle(filename, 0, 0, 0, 0)
          if vehicle ~= nil then
            local r = vehicle:loadFromAttributesAndNodes(xmlFile, key, true)
            if r ~= BaseMission.VEHICLE_LOAD_OK then
              print("Warning: corrupt savegame, vehicle " .. filename .. " could not be loaded")
              self:removeVehicle(vehicle)
            end
          end
        end
      end
      delete(xmlFile)
      self.vehiclesToSpawn = {}
      self.usedLoadPlaces = {}
    end
  end
  Mission00:superClass().update(self, dt)
  if self.environment.dayTime > 72000000 or self.environment.dayTime < 21600000 then
    self.environment.timeScale = g_settingsTimeScale * 4
  else
    self.environment.timeScale = g_settingsTimeScale
  end
  self.inGameMessage:update(dt)
  self.inGameIcon:update(dt)
end
function Mission00:draw()
  Mission00:superClass().draw(self)
  self.inGameMessage:draw()
  self.inGameIcon:draw()
end
function Mission00:loadVehicles(xmlFilename, resetVehicles)
  local xmlFile = loadXMLFile("VehiclesXML", xmlFilename)
  local vehicleI = 0
  while true do
    local key = string.format("careerVehicles.vehicle(%d)", vehicleI)
    local filename = getXMLString(xmlFile, key .. "#filename")
    if filename == nil then
      break
    end
    local vehicle = self:loadVehicle(filename, 0, 0, 0, 0)
    if vehicle ~= nil then
      local r = vehicle:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
      if r == BaseMission.VEHICLE_LOAD_ERROR then
        print("Warning: corrupt savegame, vehicle " .. filename .. " could not be loaded")
        self:removeVehicle(vehicle)
      elseif r == BaseMission.VEHICLE_LOAD_DELAYED then
        table.insert(self.vehiclesToSpawn, {xmlKey = key})
        self:removeVehicle(vehicle)
      end
    end
    vehicleI = vehicleI + 1
  end
  local i = 0
  while true do
    local key = string.format("careerVehicles.item(%d)", i)
    local filename = getXMLString(xmlFile, key .. "#filename")
    if filename == nil then
      break
    end
    local rootNode = Utils.loadSharedI3DFile(filename)
    local childIndex = getXMLInt(xmlFile, key .. "#childIndex")
    if childIndex == nil then
      childIndex = 0
    end
    local node = getChildAt(rootNode, childIndex)
    if node ~= nil and node ~= 0 then
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#position"))
      local xRot, yRot, zRot = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#rotation"))
      if x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil then
        print("Warning: corrupt savegame, item " .. filename .. " could not be loaded")
      else
        setTranslation(node, x, y, z)
        setRotation(node, xRot, yRot, zRot)
        link(getRootNode(), node)
        self:addItemToSave(filename, node, childIndex)
      end
      delete(rootNode)
    end
    i = i + 1
  end
  delete(xmlFile)
end
function Mission00:saveVehicles(file)
  for k, vehicle in pairs(self.vehiclesToSave) do
    file:write("    <vehicle filename=\"" .. Utils.encodeToHTML(vehicle.configFileName) .. "\"")
    local attributes, nodes = vehicle:getSaveAttributesAndNodes("       ")
    if attributes ~= nil and attributes ~= "" then
      file:write(" " .. attributes)
    end
    if nodes ~= nil and nodes ~= "" then
      file:write(">\n" .. nodes .. [[

    </vehicle>
]])
    else
      file:write("/>\n")
    end
  end
  for k, item in pairs(self.itemsToSave) do
    file:write("    <item filename=\"" .. Utils.encodeToHTML(item.i3dFilename) .. "\"")
    local x, y, z = getTranslation(item.node)
    local xRot, yRot, zRot = getRotation(item.node)
    file:write(" position=\"" .. x .. " " .. y .. " " .. z .. "\" rotation=\"" .. xRot .. " " .. yRot .. " " .. zRot .. "\" childIndex=\"" .. item.childIndex .. "\" />\n")
  end
end
function Mission00:bottleTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.controlPlayer and otherId == Player.rootNode then
    removeTrigger(triggerId)
    local bottleName = getName(triggerId)
    local bottleNumber = tonumber(string.sub(bottleName, string.len(bottleName) - 2, string.len(bottleName)))
    self.foundBottles = string.sub(self.foundBottles, 1, bottleNumber - 1) .. "1" .. string.sub(self.foundBottles, bottleNumber + 1, string.len(self.foundBottles))
    local parentId = getParent(triggerId)
    delete(triggerId)
    setVisibility(parentId, false)
    if self.inGameIcon.fileName ~= "dataS/missions/bottle.png" then
      self.inGameIcon:setIcon("dataS/missions/bottle.png")
    end
    self.inGameIcon:setText("+1")
    self.inGameIcon:showIcon(2000)
    if self.bottlePickupSound ~= nil then
      playSample(self.bottlePickupSound, 1, 1, 0)
    end
    self.foundBottleCount = self.foundBottleCount + 1
  end
end
function Mission00:glassContainerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.controlPlayer and otherId == Player.rootNode and self.foundBottleCount > 0 then
    self.missionStats.money = self.missionStats.money + self.foundBottleCount
    self.deliveredBottles = self.deliveredBottles + self.foundBottleCount
    self.sessionDeliveredBottles = self.sessionDeliveredBottles + self.foundBottleCount
    if self.bottleDropSound ~= nil then
      playSample(self.bottleDropSound, 1, 0.5, 0)
    end
    self:increaseReputation(self.foundBottleCount)
    self.foundBottleCount = 0
  end
end
function Mission00:infospotTouched(triggerId)
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName) - 1))
  self.foundInfoTriggers = string.sub(self.foundInfoTriggers, 1, triggerNumber - 1) .. "1" .. string.sub(self.foundInfoTriggers, triggerNumber + 1)
  if self.messages[triggerNumber] ~= nil then
    self.inGameMessage:showMessage(self.messages[triggerNumber].title, self.messages[triggerNumber].content, self.messages[triggerNumber].duration, false)
  end
end
function Mission00:onCreateStartPoint(id)
  g_mission00StartPoint = id
end

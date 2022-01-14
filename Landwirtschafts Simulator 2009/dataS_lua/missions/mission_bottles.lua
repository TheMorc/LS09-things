MissionBottles = {}
local MissionBottles_mt = Class(MissionBottles, BaseMission)
function MissionBottles:new()
  local instance = MissionBottles:superClass():new(MissionBottles_mt)
  instance.playerStartX = 380.305
  instance.playerStartY = -0.8
  instance.playerStartZ = -397.912
  instance.playerRotX = 0
  instance.playerRotY = Utils.degToRad(45.7)
  instance.foundBottleCount = 0
  instance.deliveredBottles = 0
  instance.neededBottles = 10
  instance.pdaBottles = {}
  instance.bottleTriggers = {}
  instance.glassContainerTriggers = {}
  instance.frameCount = 0
  instance.messages = {}
  local xmlFile = loadXMLFile("messages.xml", "dataS/missions/messages_bottles" .. g_languageSuffix .. ".xml")
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
      instance.messages[message.id] = message
    else
      eom = true
    end
    i = i + 1
  until eom
  delete(xmlFile)
  instance.state = BaseMission.STATE_WAITING
  return instance
end
function MissionBottles:delete()
  self.inGameMessage:delete()
  self.inGameIcon:delete()
  delete(self.bottlePickupSound)
  delete(self.bottleDropSound)
  for i = 0, table.getn(self.bottleTriggers) do
    removeTrigger(self.bottleTriggers[i])
  end
  for i = 0, table.getn(self.glassContainerTriggers) do
    removeTrigger(self.glassContainerTriggers[i])
  end
  MissionBottles:superClass().delete(self)
end
function MissionBottles:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14.25)
  self.environment.timeScale = 1
  MissionBottles:superClass().loadMap(self, "map01")
  setFog("exp2", 0.0025, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  self.missionMapGlassContainers = self:superClass().loadMissionMap(self, "glassContainers.i3d")
  self.missionMap = self:superClass().loadMissionMap(self, "mission_bottles/mission_bottles.i3d")
  local glassContainerTriggerParentId = getChild(self.missionMapGlassContainers, "GlassContainers")
  if glassContainerTriggerParentId ~= 0 then
    local numChildren = getNumOfChildren(glassContainerTriggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(glassContainerTriggerParentId, i)
      id = getChildAt(id, 0)
      addTrigger(id, "glassContainerTriggerCallback", self)
      if g_currentMission ~= nil then
        local x, y, z = getWorldTranslation(id)
        g_currentMission.missionStats:createMapHotspot(tostring(id), "dataS/missions/hud_pda_spot_gc.png", x + 1024, z + 1024, g_currentMission.missionStats.pdaMapArrowSize, g_currentMission.missionStats.pdaMapArrowSize * 1.3333333333333333, false, false, 0)
      end
      self.glassContainerTriggers[i] = id
    end
  end
  local bottleTriggerParentId = getChild(self.missionMap, "CollectableBottles")
  if bottleTriggerParentId ~= 0 then
    local numChildren = getNumOfChildren(bottleTriggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(bottleTriggerParentId, i)
      if g_currentMission ~= nil then
        local x, y, z = getTranslation(id)
        self.pdaBottles[id] = g_currentMission.missionStats:createMapHotspot(tostring(id), "dataS/missions/hud_pda_spot_bottle.png", x + 1024, z + 1024, g_currentMission.missionStats.pdaMapArrowSize * 0.6, g_currentMission.missionStats.pdaMapArrowSize * 0.8 * 1.3333333333333333, false, false, id)
      end
      id = getChildAt(id, 0)
      addTrigger(id, "bottleTriggerCallback", self)
      self.bottleTriggers[i] = id
    end
  end
  self:loadVehicle("data/vehicles/steerable/fendt/fendt936BBvario.xml", 361.75, 0.5, -391, Utils.degToRad(-90))
  self.bottlePickupSound = createSample("bottlePickupSound")
  loadSample(self.bottlePickupSound, "data/maps/sounds/bottlePickupSound.wav", false)
  self.bottleDropSound = createSample("bottleDropSound")
  loadSample(self.bottleDropSound, "data/maps/sounds/bottleDropSound.wav", false)
  MissionBottles:superClass().load(self)
  self.inGameMessage = InGameMessage:new()
  self.inGameIcon = InGameIcon:new()
  self.showHudMissionBase = true
  self.state = BaseMission.STATE_RUNNING
end
function MissionBottles:mouseEvent(posX, posY, isDown, isUp, button)
  self.inGameMessage:mouseEvent(posX, posY, isDown, isUp, button)
  self.inGameIcon:mouseEvent(posX, posY, isDown, isUp, button)
  MissionBottles:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionBottles:keyEvent(unicode, sym, modifier, isDown)
  MissionBottles:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionBottles:update(dt)
  MissionBottles:superClass().update(self, dt)
  self.inGameMessage:update(dt)
  self.inGameIcon:update(dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      if self.missionTime > self.minTime then
        self.state = BaseMission.STATE_FAILED
        self.endTime = self.time
        self.endTimeStamp = self.time + self.endDelayTime
      end
      self.frameCount = self.frameCount + 1
      if self.frameCount > 60 then
        if self.state ~= BaseMission.STATE_FINISHED and self.deliveredBottles >= self.neededBottles then
          self.state = BaseMission.STATE_FINISHED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
          MissionBottles:superClass().finishMission(self, self.endTime)
          MissionBottles:superClass().drawMissionCompleted(self)
        end
        if self.state ~= BaseMission.STATE_FAILED and self.missionTime > self.minTime then
          self.state = BaseMission.STATE_FAILED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
        end
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionBottles:draw()
  MissionBottles:superClass().draw(self)
  if self.isRunning then
    local time = self.minTime - self.missionTime
    if time < 60000 then
      setTextColor(1, 0, 0, 1)
      if time < 0 then
        time = 0
      end
    end
    MissionBottles:superClass().drawTime(self, true, time / 60000)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.005, 0.94, 0.04, g_i18n:getText("bottlesMissionGoal1"))
    renderText(self.hudMissionBasePosX + 0.005, 0.9099999999999999, 0.04, g_i18n:getText("bottlesMissionGoal2"))
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(self.hudMissionBasePosX + self.hudMissionBaseWidth - 0.01, 0.94, 0.04, string.format("%d", self.foundBottleCount))
    renderText(self.hudMissionBasePosX + self.hudMissionBaseWidth - 0.01, 0.9099999999999999, 0.04, string.format("%d", self.deliveredBottles))
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionBottles:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionBottles:superClass().drawMissionFailed(self)
    end
    self.inGameMessage:draw()
    self.inGameIcon:draw()
  end
end
function MissionBottles:bottleTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and g_currentMission.controlPlayer then
    removeTrigger(triggerId)
    local parentId = getParent(triggerId)
    self.pdaBottles[parentId]:delete()
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
function MissionBottles:glassContainerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and g_currentMission.controlPlayer and self.foundBottleCount > 0 then
    self.deliveredBottles = self.deliveredBottles + self.foundBottleCount
    self:increaseReputation(self.foundBottleCount)
    self.foundBottleCount = 0
    if self.bottleDropSound ~= nil then
      playSample(self.bottleDropSound, 1, 0.5, 0)
    end
  end
end
function MissionBottles:infospotTouched(triggerId)
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName) - 1))
  if self.messages[triggerNumber] ~= nil then
    self.inGameMessage:showMessage(self.messages[triggerNumber].title, self.messages[triggerNumber].content, self.messages[triggerNumber].duration, false)
  end
end

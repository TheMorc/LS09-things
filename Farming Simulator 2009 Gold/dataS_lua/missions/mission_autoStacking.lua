MissionAutoStacking = {}
local MissionAutoStacking_mt = Class(MissionAutoStacking, BaseMission)
function MissionAutoStacking:new()
  local instance = MissionAutoStacking:superClass():new(MissionAutoStacking_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = 562
  instance.playerStartY = 0.1
  instance.playerStartZ = 296.1
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(51)
  instance.baleCount = 0
  instance.neededBales = 20
  instance.state = BaseMission.STATE_WAITING
  instance.showHudEnv = false
  instance.missionTriggers = {}
  instance.missionBales = {}
  instance.missionBalesCount = 0
  instance.frameCount = 0
  return instance
end
function MissionAutoStacking:delete()
  for k, triggerId in pairs(self.missionTriggers) do
    if triggerId ~= nil then
      removeTrigger(triggerId)
    end
  end
  MissionAutoStacking:superClass().delete(self)
end
function MissionAutoStacking:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  local obj = self.missionBales[otherId]
  if obj ~= nil then
    if onEnter then
      obj.inTriggerCount = obj.inTriggerCount + 1
    elseif onLeave then
      obj.inTriggerCount = obj.inTriggerCount - 1
    end
  end
end
function MissionAutoStacking:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14)
  self.environment.timeScale = 1
  MissionAutoStacking:superClass().loadMap(self, "map01")
  self.missionMap = MissionAutoStacking:superClass().loadMissionMap(self, "mission_autoStacking/mission_autoStacking.i3d")
  local triggerParentId = getChild(self.missionMap, "farmTriggers")
  if triggerParentId ~= 0 then
    local numChildren = getNumOfChildren(triggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(triggerParentId, i)
      addTrigger(id, "triggerCallback", self)
      table.insert(self.missionTriggers, id)
    end
  end
  local transformGroupId = getChild(self.missionMap, "autoStacking")
  if transformGroupId ~= 0 then
    local numChildren = getNumOfChildren(transformGroupId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(transformGroupId, i)
      g_currentMission:addItemToSave("data/maps/models/objects/strawbale/strawbaleBaler.i3d", id, 0)
      self.missionBales[id] = {}
      self.missionBales[id].inTriggerCount = 0
    end
  end
  setFog("exp", 0.002, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  local tractor = self:loadVehicle("data/vehicles/steerable/fendt/fendt716vario.xml", 554, 5, 283, Utils.degToRad(180))
  local autoStacker = self:loadVehicle("data/vehicles/trailers/baleLoader.xml", 554, 5, 291, Utils.degToRad(180))
  local cutBarleyId = g_currentMission.fruits[FruitUtil.FRUITTYPE_BARLEY].cutShortId
  setDensityMaskedParallelogram(cutBarleyId, 545, 192, 92, 0, 0, 88, 0, 1, self.terrainDetailId, self.sowingChannel, 1, 1)
  MissionAutoStacking:superClass().load(self)
  self.inGameMessage = InGameMessage:new()
  self.showHudMissionBase = true
  self.state = BaseMission.STATE_RUNNING
end
function MissionAutoStacking:mouseEvent(posX, posY, isDown, isUp, button)
  self.inGameMessage:mouseEvent(posX, posY, isDown, isUp, button)
  MissionAutoStacking:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionAutoStacking:keyEvent(unicode, sym, modifier, isDown)
  MissionAutoStacking:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionAutoStacking:update(dt)
  MissionAutoStacking:superClass().update(self, dt)
  self.inGameMessage:update(dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      self.frameCount = self.frameCount + 1
      if self.frameCount > 10 then
        self.missionBalesCount = 0
        for k, v in pairs(self.missionBales) do
          if 0 < v.inTriggerCount then
            self.missionBalesCount = self.missionBalesCount + 1
          end
        end
        if self.missionTime > self.minTime then
          self.state = BaseMission.STATE_FAILED
          self.endTime = self.time
          self.endTimeStamp = self.time + self.endDelayTime
        end
        if self.state ~= BaseMission.STATE_FINISHED and self.missionBalesCount >= self.neededBales then
          self.state = BaseMission.STATE_FINISHED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
          MissionAutoStacking:superClass().finishMission(self, self.endTime)
          MissionAutoStacking:superClass().drawMissionCompleted(self)
        end
        self.frameCount = 0
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionAutoStacking:draw()
  MissionAutoStacking:superClass().draw(self)
  if self.isRunning then
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.005, 0.926, 0.035, g_i18n:getText("autoStackingMissionGoal") .. string.format(" %d", self.missionBalesCount))
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionAutoStacking:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionAutoStacking:superClass().drawMissionFailed(self)
    end
    self.inGameMessage:draw()
  end
end

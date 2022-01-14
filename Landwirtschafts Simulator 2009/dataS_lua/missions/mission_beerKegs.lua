MissionBeerKegs = {}
local MissionBeerKegs_mt = Class(MissionBeerKegs, BaseMission)
function MissionBeerKegs:new()
  local instance = MissionBeerKegs:superClass():new(MissionBeerKegs_mt)
  instance.state = BaseMission.STATE_RUNNING
  instance.playerStartX = -591
  instance.playerStartY = -0.7
  instance.playerStartZ = -430.5
  instance.playerRotX = Utils.degToRad(1)
  instance.playerRotY = Utils.degToRad(90)
  instance.obstacleCount = 0
  instance.minTime = 420001
  instance.frameCount = 0
  instance.missionTriggers = {}
  return instance
end
function MissionBeerKegs:delete()
  for k, triggerId in pairs(self.missionTriggers) do
    if triggerId ~= nil then
      removeTrigger(triggerId)
    end
  end
  MissionBeerKegs:superClass().delete(self)
end
function MissionBeerKegs:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  local obj = self.obstacles[otherId]
  if obj ~= nil then
    if onEnter then
      obj.inTriggerCount = obj.inTriggerCount + 1
    elseif onLeave then
      obj.inTriggerCount = obj.inTriggerCount - 1
    end
  end
end
function MissionBeerKegs:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 15)
  self.environment.timeScale = 1
  MissionBeerKegs:superClass().loadMap(self, "map01")
  self.missionMap = MissionBeerKegs:superClass().loadMissionMap(self, "mission_beerKegs/mission_beerKegs.i3d")
  setFog("exp2", 0.0025, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  local triggerParentId = getChild(self.missionMap, "mission_beerKegs_triggers")
  if triggerParentId ~= 0 then
    local numChildren = getNumOfChildren(triggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(triggerParentId, i)
      addTrigger(id, "triggerCallback", self)
      table.insert(self.missionTriggers, id)
    end
  end
  self.obstacles = {}
  local obstaclesParentId = getChild(self.missionMap, "obstacles")
  if obstaclesParentId ~= 0 then
    local numChildren = getNumOfChildren(obstaclesParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(obstaclesParentId, i)
      self.obstacles[id] = {}
      self.obstacles[id].inTriggerCount = 0
    end
  end
  self:loadVehicle("data/vehicles/steerable/fendt/fendt716vario.xml", -597.97467, 5, -431.69217, Utils.degToRad(240))
  self:loadVehicle("data/vehicles/tools/plow01.xml", -602.06775, 5, -434.07663, Utils.degToRad(60))
  MissionBeerKegs:superClass().load(self)
  g_currentMission.missionStats.showPDA = false
  self.showHudMissionBase = true
end
function MissionBeerKegs:mouseEvent(posX, posY, isDown, isUp, button)
  MissionBeerKegs:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionBeerKegs:keyEvent(unicode, sym, modifier, isDown)
  MissionBeerKegs:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionBeerKegs:update(dt)
  MissionBeerKegs:superClass().update(self, dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      self.frameCount = self.frameCount + 1
      if self.frameCount > 10 then
        self.obstacleCount = 0
        for k, v in pairs(self.obstacles) do
          if 0 < v.inTriggerCount then
            self.obstacleCount = self.obstacleCount + 1
          end
        end
        if self.state ~= BaseMission.STATE_FINISHED and self.obstacleCount == 0 then
          self.state = BaseMission.STATE_FINISHED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
          MissionBeerKegs:superClass().finishMission(self, self.endTime)
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
function MissionBeerKegs:draw()
  MissionBeerKegs:superClass().draw(self)
  if self.isRunning then
    local time = self.minTime - self.missionTime
    if time < 60000 then
      setTextColor(1, 0, 0, 1)
      if time < 0 then
        time = 0
      end
    end
    MissionBeerKegs:superClass().drawTime(self, true, time / 60000)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.005, 0.926, 0.04, g_i18n:getText("beerKegsMissionGoal") .. string.format(" %d", self.obstacleCount))
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionBeerKegs:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionBeerKegs:superClass().drawMissionFailed(self)
    end
  end
end

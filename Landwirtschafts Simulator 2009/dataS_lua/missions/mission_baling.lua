MissionBaling = {}
local MissionBaling_mt = Class(MissionBaling, BaseMission)
function MissionBaling:new()
  local instance = MissionBaling:superClass():new(MissionBaling_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = 557.2
  instance.playerStartY = -0.8
  instance.playerStartZ = 296.1
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(51)
  instance.baleCount = 0
  instance.neededBales = 20
  instance.state = BaseMission.STATE_WAITING
  instance.showHudEnv = false
  return instance
end
function MissionBaling:delete()
  self.inGameMessage:delete()
  MissionBaling:superClass().delete(self)
end
function MissionBaling:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14)
  self.environment.timeScale = 1
  MissionBaling:superClass().loadMap(self, "map01")
  setFog("exp", 0.002, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  local tractor = self:loadVehicle("data/vehicles/steerable/fendt/fendt716vario.xml", 549, 5, 283, Utils.degToRad(180))
  local baler = self:loadVehicle("data/vehicles/trailers/fendt1290s.xml", 549, 5, 289, Utils.degToRad(180))
  baler.fillScale = 1.3
  tractor:attachImplement(baler, 4)
  local cutBarleyId = g_currentMission.fruits[FruitUtil.FRUITTYPE_BARLEY].cutShortId
  setDensityMaskedParallelogram(cutBarleyId, 545, 192, 92, 0, 0, 88, 0, 1, self.terrainDetailId, self.sowingChannel, 1, 1)
  for i = 0, 12 do
    Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_BARLEY, 548 + i * 7, 277, 548 + i * 7 + 2, 277, 548 + i * 7, 194, 3, true)
  end
  MissionBaling:superClass().load(self)
  self.inGameMessage = InGameMessage:new()
  self.showHudMissionBase = true
  self.state = BaseMission.STATE_RUNNING
end
function MissionBaling:mouseEvent(posX, posY, isDown, isUp, button)
  self.inGameMessage:mouseEvent(posX, posY, isDown, isUp, button)
  MissionBaling:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionBaling:keyEvent(unicode, sym, modifier, isDown)
  MissionBaling:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionBaling:update(dt)
  MissionBaling:superClass().update(self, dt)
  self.inGameMessage:update(dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      if self.missionTime > self.minTime then
        self.state = BaseMission.STATE_FAILED
        self.endTime = self.time
        self.endTimeStamp = self.time + self.endDelayTime
      end
      if self.state ~= BaseMission.STATE_FINISHED and self.baleCount >= self.neededBales then
        self.state = BaseMission.STATE_FINISHED
        self.endTime = self.missionTime
        self.endTimeStamp = self.time + self.endDelayTime
        MissionBaling:superClass().finishMission(self, self.endTime)
        MissionBaling:superClass().drawMissionCompleted(self)
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionBaling:draw()
  MissionBaling:superClass().draw(self)
  if self.isRunning then
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.005, 0.926, 0.04, g_i18n:getText("balingMissionGoal") .. string.format(" %d", self.baleCount))
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionBaling:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionBaling:superClass().drawMissionFailed(self)
    end
    self.inGameMessage:draw()
  end
end

MissionGrassMowing = {}
local MissionGrassMowing_mt = Class(MissionGrassMowing, BaseMission)
function MissionGrassMowing:new()
  local instance = MissionGrassMowing:superClass():new(MissionGrassMowing_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = 246
  instance.playerStartY = 0.1
  instance.playerStartZ = 270
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(142)
  instance.remainingGrassAmount = 8000
  instance.state = BaseMission.STATE_WAITING
  instance.showHudEnv = false
  return instance
end
function MissionGrassMowing:delete()
  self.inGameMessage:delete()
  MissionGrassMowing:superClass().delete(self)
end
function MissionGrassMowing:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14)
  self.environment.timeScale = 1
  MissionGrassMowing:superClass().loadMap(self, "map01")
  setFog("exp", 0.002, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  local disc = self:loadVehicle("data/vehicles/tools/novacat306f.xml", 244, 5, 279, Utils.degToRad(270))
  local tractor = self:loadVehicle("data/vehicles/steerable/fendt/fendt936BBvario.xml", 239, 5, 279, Utils.degToRad(90))
  self.trailer = self:loadVehicle("data/vehicles/trailers/euroboss330t.xml", 230, 5, 279, Utils.degToRad(90))
  self.trailer.fillScale = 2
  local grassDesc = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_GRASS]
  grassDesc.literPerQm = 5
  MissionGrassMowing:superClass().load(self)
  self.inGameMessage = InGameMessage:new()
  self.showHudMissionBase = true
  self.state = BaseMission.STATE_RUNNING
end
function MissionGrassMowing:mouseEvent(posX, posY, isDown, isUp, button)
  self.inGameMessage:mouseEvent(posX, posY, isDown, isUp, button)
  MissionGrassMowing:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionGrassMowing:keyEvent(unicode, sym, modifier, isDown)
  MissionGrassMowing:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionGrassMowing:update(dt)
  MissionGrassMowing:superClass().update(self, dt)
  self.inGameMessage:update(dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      if (self.trailer.tipState == Trailer.TIPSTATE_OPENING or self.trailer.tipState == Trailer.TIPSTATE_OPEN) and self.trailer.lastFillDelta < 0 then
        self.remainingGrassAmount = self.remainingGrassAmount + self.trailer.lastFillDelta
        if 0 > self.remainingGrassAmount then
          self.remainingGrassAmount = 0
        end
      end
      if self.missionTime > self.minTime then
        self.state = BaseMission.STATE_FAILED
        self.endTime = self.time
        self.endTimeStamp = self.time + self.endDelayTime
      end
      if self.state ~= BaseMission.STATE_FINISHED and self.remainingGrassAmount == 0 then
        self.state = BaseMission.STATE_FINISHED
        self.endTime = self.missionTime
        self.endTimeStamp = self.time + self.endDelayTime
        MissionGrassMowing:superClass().finishMission(self, self.endTime)
        MissionGrassMowing:superClass().drawMissionCompleted(self)
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionGrassMowing:draw()
  MissionGrassMowing:superClass().draw(self)
  if self.isRunning then
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.004, 0.929, 0.029, g_i18n:getText("mowingGrassMissionGoal") .. string.format(" %d", self.remainingGrassAmount))
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionGrassMowing:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionGrassMowing:superClass().drawMissionFailed(self)
    end
    self.inGameMessage:draw()
  end
end
